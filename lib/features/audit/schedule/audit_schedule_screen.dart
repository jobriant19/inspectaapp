import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../user/home/alert/required_field_alert.dart';
import 'audit_assign_auditor.dart';
import 'audit_pick_auditor.dart';
import 'audit_pick_period.dart';
import 'audit_pick_time.dart';
import 'audit_pick_type.dart';
import 'audit_schedule_popup.dart';

const double _kAssignCardHeight = 128;

class _SC {
  static const primary   = Color(0xFF8B5CF6);
  static const primaryLt = Color(0xFFEDE9FE);
  static const red       = Color(0xFFEF4444);
  static const textMain  = Color(0xFF1E3A8A);
  static const textSub   = Color(0xFF64748B);
  static const divider   = Color(0xFFE2E8F0);
  static const surface   = Color(0xFFF8FAFC);
}

class AuditScheduleData {
  final String idSchedule;
  final String idAuditor;
  final String auditorName;
  final String? auditorImage;
  final String? auditorJabatan;
  final DateTime periodeMulai;
  final DateTime periodeSelesai;
  final String? catatan;
  final String? idJenisAudit;
  final String? notifTime;

  const AuditScheduleData({
    required this.idSchedule,
    required this.idAuditor,
    required this.auditorName,
    this.auditorImage,
    this.auditorJabatan,
    required this.periodeMulai,
    required this.periodeSelesai,
    this.catatan,
    this.idJenisAudit,
    this.notifTime,
  });
}

class _AuditorAssignment {
  final Map<String, dynamic> auditor;
  final String levelType;
  final String idRef;
  final String locationName;

  const _AuditorAssignment({
    required this.auditor,
    required this.levelType,
    required this.idRef,
    required this.locationName,
  });
}

class AuditScheduleScreen extends StatefulWidget {
  final String lang;

  const AuditScheduleScreen({
    super.key,
    required this.lang,
  });

  @override
  State<AuditScheduleScreen> createState() => _AuditScheduleScreenState();
}

class _AuditScheduleScreenState extends State<AuditScheduleScreen> {
  final _supabase = Supabase.instance.client;

  DateTime?                _periodeAwal;
  DateTime?                _periodeAkhir;
  final _catatanCtrl     = TextEditingController();

  List<_AuditorAssignment>   _assignments      = [];

  List<Map<String, dynamic>> _jenisAuditList = [];
  String? _selectedJenisAuditId;

  bool _loadingInit = true;
  bool _saving      = false;
  TimeOfDay _notifTime = const TimeOfDay(hour: 9, minute: 0);

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  String _jenisAuditLabel(Map<String, dynamic> j) {
    if (widget.lang == 'EN') return j['nama_en']?.toString() ?? '-';
    if (widget.lang == 'ZH') return j['nama_zh']?.toString() ?? '-';
    return j['nama_id']?.toString() ?? '-';
  }

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  @override
  void dispose() {
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _initLoad() async {
    try {
      final results = await Future.wait<dynamic>([
        _fetchExistingSchedules(),
        _supabase.from('jenis_audit').select().order('urutan'),
        _supabase.from('lokasi').select('id_lokasi, nama_lokasi').order('nama_lokasi'),
        _supabase.from('unit').select('id_unit, nama_unit, id_lokasi').order('nama_unit'),
        _supabase.from('subunit').select('id_subunit, nama_subunit, id_unit').order('nama_subunit'),
        _supabase.from('area').select('id_area, nama_area, id_subunit').order('nama_area'),
      ]);

      final assignments = results[0] as List<_AuditorAssignment>;
      final jenisAudit  = List<Map<String, dynamic>>.from(results[1] as List);

      if (!mounted) return;
      setState(() {
        _assignments      = assignments;
        _jenisAuditList   = jenisAudit;
        _loadingInit      = false;
      });

      await _prefillPeriodeFromDB();
    } catch (e) {
      debugPrint('AuditScheduleScreen init error: $e');
      if (mounted) setState(() => _loadingInit = false);
    }
  }

  Future<void> _prefillPeriodeFromDB() async {
    try {
      final rows = await _supabase
          .from('audit_schedule')
          .select('periode_mulai, periode_selesai, id_jenis_audit, notif_time')
          .eq('status', 'pending')
          .gte('periode_selesai', _todayStr())
          .order('created_at', ascending: false)
          .limit(1);
      if ((rows as List).isNotEmpty && mounted) {
        final r = rows.first;
        final mulai   = DateTime.tryParse(r['periode_mulai']?.toString() ?? '');
        final selesai = DateTime.tryParse(r['periode_selesai']?.toString() ?? '');
        setState(() {
          if (mulai != null)   _periodeAwal  = mulai;
          if (selesai != null) _periodeAkhir = selesai;
          if (r['id_jenis_audit'] != null)
            { _selectedJenisAuditId = r['id_jenis_audit'].toString(); }
          if (r['notif_time'] != null) {
            final parts = r['notif_time'].toString().split(':');
            if (parts.length >= 2) {
              _notifTime = TimeOfDay(
                hour:   int.tryParse(parts[0]) ?? 9,
                minute: int.tryParse(parts[1]) ?? 0,
              );
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<List<_AuditorAssignment>> _fetchExistingSchedules() async {
    final rows = await _supabase
        .from('audit_schedule')
        .select(
            'id_schedule, id_auditor, id_ref, level_type, periode_mulai, '
            'periode_selesai, catatan, id_jenis_audit, notif_time, '
            'User_Auditor:User!fk_audit_schedule_auditor(id_user, nama, gambar_user, '
            'jabatan!User_id_jabatan_fkey(nama_jabatan))')
        .eq('status', 'pending')
        .gte('periode_selesai', _todayStr())
        .order('created_at', ascending: false);

    final List<_AuditorAssignment> list = [];
    for (final r in rows as List) {
      final auditorData = r['User_Auditor'] as Map<String, dynamic>?;
      if (auditorData == null) continue;

      final locationName = await _resolveLocationName(
          r['level_type'].toString(), r['id_ref'].toString());

      list.add(_AuditorAssignment(
        auditor: {
          'id_user':     auditorData['id_user'],
          'nama':        auditorData['nama'],
          'gambar_user': auditorData['gambar_user'],
          'jabatan':     auditorData['jabatan'],
          'id_schedule': r['id_schedule'],
        },
        levelType:    r['level_type'].toString(),
        idRef:        r['id_ref'].toString(),
        locationName: locationName,
      ));
    }
    return list;
  }

  Future<String> _resolveLocationName(String level, String idRef) async {
    try {
      final idCol   = 'id_$level';
      final nameCol = 'nama_$level';
      final row = await _supabase
          .from(level)
          .select(nameCol)
          .eq(idCol, idRef)
          .single();
      return row[nameCol]?.toString() ?? '-';
    } catch (_) {
      return '-';
    }
  }

  Future<void> _pickAuditType() async {
    final picked = await showAuditTypePicker(
      context: context,
      lang: widget.lang,
      jenisAuditList: _jenisAuditList,
      selectedId: _selectedJenisAuditId,
    );
    if (picked != null) {
      setState(() => _selectedJenisAuditId = picked['id_jenis_audit'].toString());
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showAuditPeriodPicker(
      context: context,
      lang: widget.lang,
      initialDate: _periodeAwal,
    );
    if (picked != null) {
      setState(() {
        _periodeAwal  = picked;
        _periodeAkhir = picked.add(const Duration(days: 6));
      });
    }
  }

  Future<void> _pickNotifTime() async {
    final picked = await showAuditTimePicker(
      context: context,
      lang: widget.lang,
      initialTime: _notifTime,
    );
    if (picked != null) setState(() => _notifTime = picked);
  }

  String _fmtTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} WIB';

  Future<void> _openViewAllAuditors() async {
    final initial = _assignments
        .map((a) => AuditAssignmentData(
              auditor: a.auditor,
              levelType: a.levelType,
              idRef: a.idRef,
              locationName: a.locationName,
            ))
        .toList();

    final result = await showAuditAssignAuditorPopup(
      context: context,
      lang: widget.lang,
      initialAssignments: initial,
    );

    if (result != null) {
      setState(() {
        _assignments = result
            .map((r) => _AuditorAssignment(
                  auditor: r.auditor,
                  levelType: r.levelType,
                  idRef: r.idRef,
                  locationName: r.locationName,
                ))
            .toList();
      });
    }
  }

  Future<void> _save() async {
    final List<MissingFieldItem> missing = [];
    if (_selectedJenisAuditId == null) {
      missing.add(MissingFieldItem(
        icon: Icons.assignment_rounded,
        label: _t('Audit Type', 'Jenis Audit', '审计类型'),
      ));
    }
    if (_periodeAwal == null) {
      missing.add(MissingFieldItem(
        icon: Icons.date_range_rounded,
        label: _t('Audit Period', 'Periode Audit', '审计期间'),
      ));
    }
    if (_assignments.isEmpty) {
      missing.add(MissingFieldItem(
        icon: Icons.groups_rounded,
        label: _t('Assign Auditors', 'Pilih Auditor', '分配审计员'),
      ));
    }
    if (missing.isNotEmpty) {
      await RequiredFieldAlert.show(
        context,
        lang: widget.lang,
        missingFields: missing,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final notifTimeStr =
          '${_notifTime.hour.toString().padLeft(2, '0')}:${_notifTime.minute.toString().padLeft(2, '0')}';

      for (final a in _assignments) {
        final payload = {
          'level_type':      a.levelType,
          'id_ref':          a.idRef,
          'id_auditor':      a.auditor['id_user'],
          'id_jenis_audit':  _selectedJenisAuditId,
          'periode_mulai':   _periodeAwal!.toIso8601String().split('T').first,
          'periode_selesai': _periodeAkhir!.toIso8601String().split('T').first,
          'status':          'pending',
          'notif_time':      notifTimeStr,
          'catatan': _catatanCtrl.text.trim().isEmpty
              ? null
              : _catatanCtrl.text.trim(),
        };

        final idSchedule = a.auditor['id_schedule']?.toString();
        if (idSchedule != null && idSchedule.isNotEmpty) {
          await _supabase
              .from('audit_schedule')
              .update(payload)
              .eq('id_schedule', idSchedule);
        } else {
          await _supabase.from('audit_schedule').insert(payload);
        }
      }

      if (!mounted) return;
      setState(() => _saving = false);

      await showAuditSchedulePopup(context, isSuccess: true, lang: widget.lang);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        await showAuditSchedulePopup(context, isSuccess: false, lang: widget.lang);
      }
    }
  }

  Future<void> _openAuditorPicker() async {
    final initial = _assignments
        .map((a) => AuditAssignmentData(
              auditor: a.auditor,
              levelType: a.levelType,
              idRef: a.idRef,
              locationName: a.locationName,
            ))
        .toList();

    final result = await showAuditPickAuditorPopup(
      context: context,
      lang: widget.lang,
      initialAssignments: initial,
    );

    if (result != null) {
      setState(() {
        _assignments = result
            .map((r) => _AuditorAssignment(
                  auditor: r.auditor,
                  levelType: r.levelType,
                  idRef: r.idRef,
                  locationName: r.locationName,
                ))
            .toList();
      });
    }
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')} '
      '${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][dt.month - 1]} '
      '${dt.year}';

  @override
  Widget build(BuildContext context) {
    final isUpdate = _assignments.any((a) => a.auditor['id_schedule'] != null);

    return Scaffold(
      backgroundColor: _SC.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _SC.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('Audit Schedule', 'Jadwal Audit', '审计计划'),
          style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _SC.primary),
        ),
      ),

      body: _loadingInit
          ? _buildLoadingShimmer()
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // AUDIT TYPE
                        _SectionLabel(
                          icon: Icons.assignment_rounded,
                          text: _t('Audit Type', 'Jenis Audit', '审计类型'),
                          isRequired: true,
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickAuditType,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedJenisAuditId != null ? _SC.primary : _SC.divider,
                                width: _selectedJenisAuditId != null ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: _SC.primaryLt,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: const Icon(Icons.assignment_turned_in_rounded,
                                      color: _SC.primary, size: 16),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _selectedJenisAuditId != null
                                        ? _jenisAuditLabel(_jenisAuditList.firstWhere(
                                            (j) => j['id_jenis_audit'].toString() == _selectedJenisAuditId,
                                            orElse: () => {}))
                                        : _t('Select audit type…', 'Pilih jenis audit…', '选择审计类型…'),
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _selectedJenisAuditId != null ? _SC.textMain : Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  _t('Change', 'Ubah', '更改'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _SC.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // AUDIT PERIOD
                        _SectionLabel(
                          icon: Icons.date_range_rounded,
                          text: _t('Audit Period', 'Periode Audit', '审计期间'),
                          isRequired: true,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _DateField(
                                label: _t('Start (Monday)', 'Mulai (Senin)',
                                    '开始（周一）'),
                                value: _periodeAwal != null
                                    ? _fmt(_periodeAwal!)
                                    : null,
                                placeholder:
                                    _t('Pick Monday', 'Pilih Senin', '选择周一'),
                                onTap: _pickStartDate,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.arrow_forward_rounded,
                                  color: _SC.textSub, size: 18),
                            ),
                            Expanded(
                              child: _DateField(
                                label: _t('End (Sunday)', 'Selesai (Minggu)',
                                    '结束（周日）'),
                                value: _periodeAkhir != null
                                    ? _fmt(_periodeAkhir!)
                                    : null,
                                placeholder:
                                    _t('Auto-filled', 'Otomatis', '自动填充'),
                                onTap: () {},
                                enabled: false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ASSIGN AUDITOR
                        _SectionLabel(
                          icon: Icons.groups_rounded,
                          text: _t('Assign Auditors', 'Pilih Auditor', '分配审计员'),
                          isRequired: true,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _t(
                            'Each auditor is assigned to one specific location.',
                            'Setiap auditor ditugaskan ke satu lokasi spesifik.',
                            '每位审计员分配到一个具体位置。',
                          ),
                          style: GoogleFonts.poppins(
                              fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 10),

                        // ASSIGN AUDITOR LIST
                        if (_assignments.isNotEmpty) ...[
                          SizedBox(
                            height: _assignments.length > 1
                                ? _kAssignCardHeight * 2
                                : _kAssignCardHeight,
                            child: ListView.builder(
                              physics: const ClampingScrollPhysics(),
                              itemCount: _assignments.length,
                              itemBuilder: (_, idx) {
                                final a = _assignments[idx];
                                return AuditAssignmentCard(
                                  assignment: AuditAssignmentData(
                                    auditor: a.auditor,
                                    levelType: a.levelType,
                                    idRef: a.idRef,
                                    locationName: a.locationName,
                                  ),
                                  lang: widget.lang,
                                  onRemove: () => setState(() => _assignments.removeAt(idx)),
                                );
                              },
                            ),
                          ),
                          if (_assignments.length > 2) ...[
                            const SizedBox(height: 2),
                            GestureDetector(
                              onTap: _openViewAllAuditors,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _t('View All (${_assignments.length})',
                                          'Lihat Semua (${_assignments.length})',
                                          '查看全部 (${_assignments.length})'),
                                      style: GoogleFonts.poppins(
                                          fontSize: 12, fontWeight: FontWeight.w700, color: _SC.primary),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: _SC.primary),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                        ],

                        // ADD AUDITOR BUTTON
                        GestureDetector(
                          onTap: _openAuditorPicker,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: _SC.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _SC.primary.withValues(alpha: 0.4),
                                  width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.person_add_alt_1_rounded,
                                    color: _SC.primary, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  _t('Add Auditor', 'Tambah Auditor', '添加审计员'),
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _SC.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // REMINDER TIME
                        _SectionLabel(
                          icon: Icons.notifications_active_rounded,
                          text: _t('Reminder Time', 'Waktu Pengingat', '提醒时间'),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _t(
                            'Daily reminder for auditor for 7 days if audit not yet submitted.',
                            'Pengingat harian ke auditor selama 7 hari jika audit belum disubmit.',
                            '若未提交审计，将每天提醒审计员，持续7天。',
                          ),
                          style: GoogleFonts.poppins(
                              fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickNotifTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: _SC.primary.withValues(alpha:0.5),
                                  width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                    Icons.notifications_active_rounded,
                                    color: _SC.primary,
                                    size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _fmtTime(_notifTime),
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _SC.textMain),
                                  ),
                                ),
                                Text(
                                  _t('Change', 'Ubah', '更改'),
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: _SC.primary,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // NOTES
                        _SectionLabel(
                          icon: Icons.sticky_note_2_rounded,
                          text: _t('Notes (optional)', 'Catatan (opsional)', '备注（可选）'),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _catatanCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: _t('Add notes…', 'Tambahkan catatan…',
                                '添加备注…'),
                            hintStyle: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: _SC.divider)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: _SC.divider)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: _SC.primary, width: 1.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // SAVE BUTTON 
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      MediaQuery.of(context).padding.bottom + 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _SC.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(
                              isUpdate
                                  ? _t('Update Schedule',
                                      'Perbarui Jadwal', '更新计划')
                                  : _t('Save Schedule', 'Simpan Jadwal',
                                      '保存计划'),
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingShimmer() {
    Widget block({double height = 46, double width = double.infinity, double radius = 12}) {
      return Container(
        width: width,
        height: height,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            block(height: 14, width: 100, radius: 6),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: block(height: 34, radius: 20)),
                const SizedBox(width: 8),
                Expanded(child: block(height: 34, radius: 20)),
                const SizedBox(width: 8),
                Expanded(child: block(height: 34, radius: 20)),
              ],
            ),
            const SizedBox(height: 16),
            block(height: 14, width: 110, radius: 6),
            const SizedBox(height: 8),
            block(height: 56),
            const SizedBox(height: 16),
            block(height: 14, width: 130, radius: 6),
            const SizedBox(height: 8),
            block(height: 80),
            block(height: 80),
            block(height: 80),
            const SizedBox(height: 16),
            block(height: 14, width: 120, radius: 6),
            const SizedBox(height: 8),
            block(height: 52),
            const SizedBox(height: 16),
            block(height: 60),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;
  final bool enabled;

  const _DateField({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : _SC.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value != null ? _SC.primary : _SC.divider,
            width: value != null ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.black)),
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 12,
                    color: value != null ? _SC.primary : Colors.grey),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    value ?? placeholder,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: value != null
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color:
                          value != null ? _SC.textMain : Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isRequired;
  const _SectionLabel({
    required this.icon,
    required this.text,
    this.isRequired = false,
  });

  static const double _fontSize = 12;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: _fontSize + 2, color: _SC.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: _fontSize,
            fontWeight: FontWeight.w700,
            color: _SC.primary,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 2),
          Text(
            '*',
            style: GoogleFonts.poppins(
              fontSize: _fontSize,
              fontWeight: FontWeight.w700,
              color: _SC.red,
            ),
          ),
        ],
      ],
    );
  }
}