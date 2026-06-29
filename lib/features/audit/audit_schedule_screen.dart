import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'audit_schedule_popup.dart';

// ─── Colour constants ───────────────────────
class _SC {
  static const primary   = Color(0xFF8B5CF6);
  static const primaryLt = Color(0xFFEDE9FE);
  static const red       = Color(0xFFEF4444);
  static const textMain  = Color(0xFF1E3A8A);
  static const textSub   = Color(0xFF64748B);
  static const divider   = Color(0xFFE2E8F0);
  static const surface   = Color(0xFFF8FAFC);
}

// ─── Model schedule yang ada ──────────────────────────────────────────────────
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

// ─── Model assignment auditor ke lokasi spesifik ─────────────────────────────
class _AuditorAssignment {
  final Map<String, dynamic> auditor;
  final String levelType; // 'lokasi' | 'unit' | 'subunit' | 'area'
  final String idRef;
  final String locationName;

  const _AuditorAssignment({
    required this.auditor,
    required this.levelType,
    required this.idRef,
    required this.locationName,
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class AuditScheduleScreen extends StatefulWidget {
  final String lang;
  final String levelType;
  final String idRef;
  final String locationName;

  const AuditScheduleScreen({
    super.key,
    required this.lang,
    required this.levelType,
    required this.idRef,
    required this.locationName,
  });

  @override
  State<AuditScheduleScreen> createState() => _AuditScheduleScreenState();
}

class _AuditScheduleScreenState extends State<AuditScheduleScreen> {
  final _supabase = Supabase.instance.client;

  // ── Form state ──
  DateTime?                _periodeAwal;
  DateTime?                _periodeAkhir;
  final _catatanCtrl     = TextEditingController();
  final _searchCtrl      = TextEditingController();

  // ── Data ──
  List<Map<String, dynamic>> _auditors         = [];
  List<Map<String, dynamic>> _filteredAuditors = [];
  // ✅ MULTI-AUDITOR: ganti _existingSchedule jadi list assignments
  List<_AuditorAssignment>   _assignments      = [];

  List<Map<String, dynamic>> _jenisAuditList = [];
  String? _selectedJenisAuditId;

  // ✅ Data hierarki untuk popup lokasi assignment
  List<Map<String, dynamic>> _allLokasi  = [];
  List<Map<String, dynamic>> _allUnit    = [];
  List<Map<String, dynamic>> _allSubunit = [];
  List<Map<String, dynamic>> _allArea    = [];

  // ── UI state ──
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

  // ─── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    _initLoad();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredAuditors = q.isEmpty
          ? _auditors
          : _auditors
              .where((u) => u['nama'].toString().toLowerCase().contains(q))
              .toList();
    });
  }

  // ─── Init ────────────────────────────────────────────────────────────────────
  Future<void> _initLoad() async {
    try {
      final results = await Future.wait([
        _fetchExistingSchedules(),
        _fetchAuditors(),
        _supabase.from('jenis_audit').select().order('urutan'),
        // ✅ Load hierarki sekaligus
        _supabase.from('lokasi').select('id_lokasi, nama_lokasi').order('nama_lokasi'),
        _supabase.from('unit').select('id_unit, nama_unit, id_lokasi').order('nama_unit'),
        _supabase.from('subunit').select('id_subunit, nama_subunit, id_unit').order('nama_subunit'),
        _supabase.from('area').select('id_area, nama_area, id_subunit').order('nama_area'),
      ]);

      final assignments = results[0] as List<_AuditorAssignment>;
      final auditors    = results[1] as List<Map<String, dynamic>>;
      final jenisAudit  = List<Map<String, dynamic>>.from(results[2] as List);

      if (!mounted) return;
      setState(() {
        _auditors         = auditors;
        _filteredAuditors = auditors;
        _assignments      = assignments;
        _jenisAuditList   = jenisAudit;
        _allLokasi        = List<Map<String, dynamic>>.from(results[3] as List);
        _allUnit          = List<Map<String, dynamic>>.from(results[4] as List);
        _allSubunit       = List<Map<String, dynamic>>.from(results[5] as List);
        _allArea          = List<Map<String, dynamic>>.from(results[6] as List);

        // Restore periode & settings dari schedule pertama jika ada
        if (assignments.isNotEmpty) {
          // Ambil periode dari schedule yang sudah ada di DB
          // (akan di-fetch terpisah jika diperlukan)
        }

        _loadingInit = false;
      });

      // ✅ Fetch periode & jenis audit dari schedule yang ada (ambil 1 untuk prefill)
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
          .eq('level_type', widget.levelType)
          .eq('status', 'pending')
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
            _selectedJenisAuditId = r['id_jenis_audit'].toString();
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

  // ✅ Fetch semua assignment (multi-auditor) untuk level ini
  Future<List<_AuditorAssignment>> _fetchExistingSchedules() async {
    final rows = await _supabase
        .from('audit_schedule')
        .select(
            'id_schedule, id_auditor, id_ref, level_type, periode_mulai, '
            'periode_selesai, catatan, id_jenis_audit, notif_time, '
            'User_Auditor:User!fk_audit_schedule_auditor(id_user, nama, gambar_user, '
            'jabatan!User_id_jabatan_fkey(nama_jabatan))')
        .eq('level_type', widget.levelType)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    final List<_AuditorAssignment> list = [];
    for (final r in rows as List) {
      final auditorData = r['User_Auditor'] as Map<String, dynamic>?;
      if (auditorData == null) continue;

      // Cari nama lokasi dari id_ref dan level_type
      final locationName = await _resolveLocationName(
          r['level_type'].toString(), r['id_ref'].toString());

      list.add(_AuditorAssignment(
        auditor: {
          'id_user':     auditorData['id_user'],
          'nama':        auditorData['nama'],
          'gambar_user': auditorData['gambar_user'],
          'jabatan':     auditorData['jabatan'],
          'id_schedule': r['id_schedule'], // simpan untuk update/delete
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
          .select('$nameCol')
          .eq(idCol, idRef)
          .single();
      return row[nameCol]?.toString() ?? '-';
    } catch (_) {
      return '-';
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAuditors() async {
    final rows = await _supabase
        .from('User')
        .select(
            'id_user, nama, gambar_user, jabatan!User_id_jabatan_fkey(nama_jabatan)')
        .order('nama');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  // ─── Date picker: hanya Senin ────────────────────────────────────────────
  Future<void> _pickStartDate() async {
    final now             = DateTime.now();
    final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
    final firstMonday     = now.add(
        Duration(days: daysUntilMonday == 0 ? 0 : daysUntilMonday));

    final picked = await showDatePicker(
      context: context,
      initialDate: _periodeAwal ?? firstMonday,
      firstDate:   firstMonday,
      lastDate:    DateTime(now.year + 2),
      selectableDayPredicate: (day) => day.weekday == DateTime.monday,
      builder: (c, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: _SC.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _periodeAwal  = picked;
        _periodeAkhir = picked.add(const Duration(days: 6));
      });
    }
  }

  // ─── Time picker notifikasi ───────────────────────────────────────────────
  Future<void> _pickNotifTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notifTime,
      builder: (c, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: _SC.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _notifTime = picked);
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} WIB';

  // ─── Save / Update ───────────────────────────────────────────────────────
  Future<void> _save() async {
    if (_selectedJenisAuditId == null) {
      _showError(_t('Please select audit type.',
          'Pilih jenis audit terlebih dahulu.', '请选择审计类型。'));
      return;
    }
    if (_periodeAwal == null) {
      _showError(_t('Please select audit period.',
          'Pilih periode audit terlebih dahulu.', '请选择审计期间。'));
      return;
    }
    if (_assignments.isEmpty) {
      _showError(_t('Please assign at least one auditor.',
          'Tambahkan minimal satu auditor.', '请至少分配一名审计员。'));
      return;
    }

    setState(() => _saving = true);
    try {
      final notifTimeStr =
          '${_notifTime.hour.toString().padLeft(2, '0')}:${_notifTime.minute.toString().padLeft(2, '0')}';

      // ✅ Upsert setiap assignment
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

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _SC.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ✅ Popup pilih lokasi untuk auditor yang dipilih
  Future<void> _showLocationPickerForAuditor(
      Map<String, dynamic> auditor) async {
    String? selectedLevel;
    String? selectedId;
    String? selectedName;

    // Set awal: tab lokasi
    String activeTab = 'lokasi';

    // Cek lokasi yang sudah terpakai
    final usedKeys =
        _assignments.map((a) => '${a.levelType}_${a.idRef}').toSet();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final tabs = ['lokasi', 'unit', 'subunit', 'area'];
          final tabLabels = [
            _t('Location', 'Lokasi', '位置'),
            _t('Unit', 'Unit', '单元'),
            _t('Sub-Unit', 'Sub-Unit', '子单元'),
            _t('Area', 'Area', '区域'),
          ];

          List<Map<String, dynamic>> currentList() {
            switch (activeTab) {
              case 'unit':    return _allUnit;
              case 'subunit': return _allSubunit;
              case 'area':    return _allArea;
              default:        return _allLokasi;
            }
          }

          String idKey(Map<String, dynamic> item) {
            switch (activeTab) {
              case 'unit':    return item['id_unit']?.toString() ?? '';
              case 'subunit': return item['id_subunit']?.toString() ?? '';
              case 'area':    return item['id_area']?.toString() ?? '';
              default:        return item['id_lokasi']?.toString() ?? '';
            }
          }

          String nameKey(Map<String, dynamic> item) {
            switch (activeTab) {
              case 'unit':    return item['nama_unit']?.toString() ?? '';
              case 'subunit': return item['nama_subunit']?.toString() ?? '';
              case 'area':    return item['nama_area']?.toString() ?? '';
              default:        return item['nama_lokasi']?.toString() ?? '';
            }
          }

          final auditorName = auditor['nama']?.toString() ?? '-';
          final jabatan = (auditor['jabatan'] as Map<String, dynamic>?)?['nama_jabatan']?.toString();

          return Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.88),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('Select Audit Location', 'Pilih Lokasi Audit', '选择审计位置'),
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _SC.textMain),
                      ),
                      const SizedBox(height: 8),
                      // Info auditor
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _SC.primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _SC.primary.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            _Avatar(user: auditor, radius: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(auditorName,
                                      style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _SC.textMain)),
                                  if (jabatan != null)
                                    Text(jabatan,
                                        style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: _SC.textSub)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _SC.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _t('Auditor', 'Auditor', '审计员'),
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Tab selector level
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: tabs.asMap().entries.map((e) {
                        final isActive = activeTab == e.value;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setSheet(() {
                              activeTab     = e.value;
                              selectedLevel = null;
                              selectedId    = null;
                              selectedName  = null;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? _SC.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                tabLabels[e.key],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? Colors.white
                                      : _SC.textSub,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // List lokasi
                Flexible(
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: currentList().length,
                    itemBuilder: (_, i) {
                      final item = currentList()[i];
                      final id   = idKey(item);
                      final name = nameKey(item);
                      final key  = '${activeTab}_$id';
                      final isUsed     = usedKeys.contains(key);
                      final isSelected = selectedLevel == activeTab &&
                          selectedId == id;

                      return GestureDetector(
                        onTap: isUsed
                            ? null
                            : () => setSheet(() {
                                  selectedLevel = activeTab;
                                  selectedId    = id;
                                  selectedName  = name;
                                }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isUsed
                                ? Colors.grey.shade50
                                : isSelected
                                    ? _SC.primary.withValues(alpha: 0.08)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isUsed
                                  ? Colors.grey.shade200
                                  : isSelected
                                      ? _SC.primary
                                      : Colors.grey.shade200,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Level badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isUsed
                                      ? Colors.grey.shade200
                                      : _SC.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  tabLabels[tabs.indexOf(activeTab)],
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: isUsed
                                        ? Colors.grey
                                        : _SC.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isUsed
                                        ? Colors.grey
                                        : isSelected
                                            ? _SC.primary
                                            : _SC.textMain,
                                  ),
                                ),
                              ),
                              if (isUsed)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _t('Assigned', 'Sudah Diatur', '已分配'),
                                    style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w600),
                                  ),
                                )
                              else if (isSelected)
                                const Icon(Icons.check_circle_rounded,
                                    color: _SC.primary, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Tombol Confirm & Cancel
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.fromLTRB(
                      16,
                      10,
                      16,
                      MediaQuery.of(ctx).padding.bottom + 14),
                  child: Row(
                    children: [
                      // Cancel
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _SC.primary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: Text(
                            _t('Cancel', 'Batal', '取消'),
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: _SC.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Confirm
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: selectedId == null
                              ? null
                              : () {
                                  // Tambah assignment
                                  setState(() {
                                    _assignments.add(_AuditorAssignment(
                                      auditor: Map<String, dynamic>.from(
                                          auditor),
                                      levelType:    selectedLevel!,
                                      idRef:        selectedId!,
                                      locationName: selectedName!,
                                    ));
                                  });
                                  Navigator.pop(ctx);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _SC.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                Colors.grey.shade200,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: Text(
                            _t('Confirm Assignment',
                                'Konfirmasi Penugasan', '确认分配'),
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')} '
      '${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][dt.month - 1]} '
      '${dt.year}';

  // ─── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_null_comparison
    final isUpdate = _assignments != null;

    return Scaffold(
      backgroundColor: _SC.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _SC.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('Audit Schedule', 'Jadwal Audit', '审计计划'),
          // ← sesuaikan teks dengan yang ada di file aslinya
          style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _SC.primary),
        ),
      ),

      // ✅ Loading overlay saat init fetch
      body: _loadingInit
          ? const Center(
              child: CircularProgressIndicator(color: _SC.primary))
          : Column(
              children: [
                // ── Bagian atas: Periode + Auditor search (scrollable) ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Jenis Audit ──────────────────────────────
                        Text(
                          _t('Audit Type', 'Jenis Audit', '审计类型'),
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _SC.textSub),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _jenisAuditList.map((j) {
                            final id = j['id_jenis_audit'].toString();
                            final isSelected = _selectedJenisAuditId == id;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedJenisAuditId = id),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                decoration: BoxDecoration(
                                  color: isSelected ? _SC.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? _SC.primary : Colors.grey.shade300,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Text(
                                  _jenisAuditLabel(j),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.white : _SC.textSub,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // ── Periode Audit ──────────────────────────────
                        Text(
                          _t('Audit Period', 'Periode Audit', '审计期间'),
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _SC.textSub),
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

                        // ── Assign Auditor (Multi) ────────────────────────
                        Text(
                          _t('Assign Auditors', 'Pilih Auditor', '分配审计员'),
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _SC.textSub),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _t(
                            'Each auditor is assigned to one specific location.',
                            'Setiap auditor ditugaskan ke satu lokasi spesifik.',
                            '每位审计员分配到一个具体位置。',
                          ),
                          style: GoogleFonts.poppins(
                              fontSize: 10.5, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 10),

                        // ✅ Daftar assignment yang sudah dikonfirmasi
                        if (_assignments.isNotEmpty) ...[
                          ..._assignments.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final a   = entry.value;
                            final auditorName = a.auditor['nama']?.toString() ?? '-';
                            final jabatan = (a.auditor['jabatan'] as Map<String, dynamic>?)?['nama_jabatan']?.toString();
                            final levelLabel = {
                              'lokasi': _t('Location', 'Lokasi', '位置'),
                              'unit': _t('Unit', 'Unit', '单元'),
                              'subunit': _t('Sub-Unit', 'Sub-Unit', '子单元'),
                              'area': _t('Area', 'Area', '区域'),
                            }[a.levelType] ?? a.levelType;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _SC.primary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _SC.primary.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  _Avatar(user: a.auditor, radius: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(auditorName,
                                            style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: _SC.textMain)),
                                        if (jabatan != null)
                                          Text(jabatan,
                                              style: GoogleFonts.poppins(
                                                  fontSize: 11, color: _SC.textSub)),
                                        const SizedBox(height: 4),
                                        // Badge lokasi yang ditugaskan
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                                color: const Color(0xFF10B981)
                                                    .withValues(alpha: 0.35)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.location_on_rounded,
                                                  size: 10,
                                                  color: Color(0xFF10B981)),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  '$levelLabel: ${a.locationName}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(0xFF10B981),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Tombol hapus assignment
                                  GestureDetector(
                                    onTap: () => setState(() => _assignments.removeAt(idx)),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: _SC.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: _SC.red.withValues(alpha: 0.3)),
                                      ),
                                      child: const Icon(Icons.close_rounded,
                                          size: 14, color: _SC.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                        ],

                        // Search field + list auditor (untuk tambah auditor baru)
                        Text(
                          _t('Add Auditor', 'Tambah Auditor', '添加审计员'),
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _SC.textSub),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: _t(
                                'Search auditor…', 'Cari auditor…', '搜索审计员…'),
                            hintStyle: GoogleFonts.poppins(
                                fontSize: 12, color: _SC.textSub),
                            prefixIcon: const Icon(Icons.search_rounded,
                                color: _SC.primary, size: 18),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(color: _SC.divider)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(color: _SC.divider)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                    color: _SC.primary, width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // ✅ List auditor — klik langsung buka popup lokasi
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: _filteredAuditors.length,
                            itemBuilder: (_, i) {
                              final u = _filteredAuditors[i];
                              // Cek apakah auditor sudah ada di assignments
                              final alreadyAssigned = _assignments.any(
                                  (a) => a.auditor['id_user']?.toString() ==
                                      u['id_user']?.toString());
                              return _AuditorTileSelectable(
                                user: u,
                                isAssigned: alreadyAssigned,
                                onTap: alreadyAssigned
                                    ? null
                                    : () => _showLocationPickerForAuditor(u),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Waktu Notifikasi ───────────────────────────────
                        Text(
                          _t('Reminder Time', 'Waktu Pengingat', '提醒时间'),
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _SC.textSub),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _t(
                            'Daily reminder for auditor for 7 days if audit not yet submitted.',
                            'Pengingat harian ke auditor selama 7 hari jika audit belum disubmit.',
                            '若未提交审计，将每天提醒审计员，持续7天。',
                          ),
                          style: GoogleFonts.poppins(
                              fontSize: 10.5, color: Colors.grey.shade500),
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

                        // ── Notes ──────────────────────────────────────
                        Text(
                          _t('Notes (optional)', 'Catatan (opsional)',
                              '备注（可选）'),
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _SC.textSub),
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

                // ── Save Button (fixed bottom) ─────────────────────────
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
}

class _Avatar extends StatelessWidget {
  final Map<String, dynamic> user;
  final double radius;
  const _Avatar({required this.user, required this.radius});

  @override
  Widget build(BuildContext context) {
    final initials = (user['nama'] as String? ?? '')
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    return CircleAvatar(
      radius: radius,
      backgroundColor: _SC.primaryLt,
      backgroundImage: user['gambar_user'] != null
          ? NetworkImage(user['gambar_user'] as String)
          : null,
      child: user['gambar_user'] == null
          ? Text(initials,
              style: GoogleFonts.poppins(
                  fontSize: radius * 0.65,
                  fontWeight: FontWeight.w700,
                  color: _SC.primary))
          : null,
    );
  }
}

// ✅ Tile auditor untuk mode multi-select (klik buka popup lokasi)
class _AuditorTileSelectable extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isAssigned;
  final VoidCallback? onTap;
  const _AuditorTileSelectable({
    required this.user,
    required this.isAssigned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final jabatan =
        (user['jabatan'] as Map<String, dynamic>?)?['nama_jabatan']
            ?.toString();
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isAssigned
              ? const Color(0xFF10B981).withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isAssigned
                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                : Colors.grey.shade200,
            width: isAssigned ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            _Avatar(user: user, radius: 15),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['nama'] ?? '',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isAssigned
                              ? const Color(0xFF10B981)
                              : _SC.textMain)),
                  if (jabatan != null)
                    Text(jabatan,
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: _SC.textSub)),
                ],
              ),
            ),
            if (isAssigned)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 12, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      'Assigned',
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF10B981)),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _SC.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+ Assign',
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _SC.primary),
                ),
              ),
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
                    fontWeight: FontWeight.w600,
                    color: _SC.textSub)),
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
                          : FontWeight.normal,
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