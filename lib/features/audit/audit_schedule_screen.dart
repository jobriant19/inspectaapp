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
  Map<String, dynamic>?    _selectedAuditor;
  final _catatanCtrl     = TextEditingController();
  final _searchCtrl      = TextEditingController();

  // ── Data ──
  List<Map<String, dynamic>> _auditors         = [];
  List<Map<String, dynamic>> _filteredAuditors = [];
  AuditScheduleData?         _existingSchedule;

  List<Map<String, dynamic>> _jenisAuditList = [];
  String? _selectedJenisAuditId;

  // ── UI state ──
  bool _loadingInit = true; // true saat fetch awal (schedule + auditors)
  bool _saving      = false;

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

  // ─── Init: fetch schedule + auditors paralel ─────────────────────────────
  Future<void> _initLoad() async {
    try {
      final results = await Future.wait([
        _fetchExistingSchedule(),
        _fetchAuditors(),
        _supabase.from('jenis_audit').select().order('urutan'), // ✅ BARU
      ]);

      final schedule = results[0] as AuditScheduleData?;
      final auditors = results[1] as List<Map<String, dynamic>>;
      final jenisAudit = List<Map<String, dynamic>>.from(results[2] as List); // ✅ BARU

      if (!mounted) return;
      setState(() {
        _auditors         = auditors;
        _filteredAuditors = auditors;
        _existingSchedule = schedule;
        _jenisAuditList   = jenisAudit; // ✅ BARU

        if (schedule != null) {
          _periodeAwal  = schedule.periodeMulai;
          _periodeAkhir = schedule.periodeSelesai;
          _catatanCtrl.text = schedule.catatan ?? '';
          _selectedJenisAuditId = schedule.idJenisAudit; // ✅ BARU

          final match = auditors.firstWhere(
            (u) => u['id_user']?.toString() == schedule.idAuditor,
            orElse: () => {
              'id_user':      schedule.idAuditor,
              'nama':         schedule.auditorName,
              'gambar_user':  schedule.auditorImage,
              'jabatan':      schedule.auditorJabatan != null
                  ? {'nama_jabatan': schedule.auditorJabatan}
                  : null,
            },
          );
          _selectedAuditor = match;
        }

        _loadingInit = false;
      });
    } catch (e) {
      debugPrint('AuditScheduleScreen init error: $e');
      if (mounted) setState(() => _loadingInit = false);
    }
  }

  Future<AuditScheduleData?> _fetchExistingSchedule() async {
    final rows = await _supabase
        .from('audit_schedule')
        .select(
            'id_schedule, id_auditor, periode_mulai, periode_selesai, catatan, id_jenis_audit, '
            'User_Auditor:User!fk_audit_schedule_auditor(nama, gambar_user, jabatan!User_id_jabatan_fkey(nama_jabatan))')
        .eq('level_type', widget.levelType)
        .eq('id_ref', widget.idRef)
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .limit(1);

    if ((rows as List).isEmpty) return null;
    final r          = rows.first as Map<String, dynamic>;
    final auditorData = r['User_Auditor'] as Map<String, dynamic>?;
    final jabatanData = auditorData?['jabatan'] as Map<String, dynamic>?;

    return AuditScheduleData(
      idSchedule:     r['id_schedule'].toString(),
      idAuditor:      r['id_auditor'].toString(),
      auditorName:    auditorData?['nama']?.toString() ?? '-',
      auditorImage:   auditorData?['gambar_user']?.toString(),
      auditorJabatan: jabatanData?['nama_jabatan']?.toString(),
      periodeMulai:   DateTime.parse(r['periode_mulai'].toString()),
      periodeSelesai: DateTime.parse(r['periode_selesai'].toString()),
      catatan:        r['catatan']?.toString(),
      idJenisAudit:   r['id_jenis_audit']?.toString(), // ✅ BARU
    );
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

  // ─── Save / Update ───────────────────────────────────────────────────────
  Future<void> _save() async {
    if (_selectedJenisAuditId == null) { // ✅ BARU
      _showError(_t('Please select audit type.',
          'Pilih jenis audit terlebih dahulu.', '请选择审计类型。'));
      return;
    }
    if (_selectedAuditor == null) {
      _showError(_t('Please select an auditor.',
          'Pilih auditor terlebih dahulu.', '请选择审计员。'));
      return;
    }
    if (_periodeAwal == null) {
      _showError(_t('Please select audit period.',
          'Pilih periode audit terlebih dahulu.', '请选择审计期间。'));
      return;
    }

    setState(() => _saving = true);
    try {
      final payload = {
        'level_type':      widget.levelType,
        'id_ref':          widget.idRef,
        'id_auditor':      _selectedAuditor!['id_user'],
        'id_jenis_audit':  _selectedJenisAuditId, // ✅ BARU
        'periode_mulai':   _periodeAwal!.toIso8601String().split('T').first,
        'periode_selesai': _periodeAkhir!.toIso8601String().split('T').first,
        'status':          'pending',
        'catatan': _catatanCtrl.text.trim().isEmpty
            ? null
            : _catatanCtrl.text.trim(),
      };

      if (_existingSchedule != null) {
        // ✅ UPDATE
        await _supabase
            .from('audit_schedule')
            .update(payload)
            .eq('id_schedule', _existingSchedule!.idSchedule);
      } else {
        // ✅ INSERT
        await _supabase.from('audit_schedule').insert(payload);
      }

      if (!mounted) return;
      setState(() => _saving = false);

      await showAuditSchedulePopup(context, isSuccess: true, lang: widget.lang);
      if (mounted) Navigator.pop(context); // kembali & trigger refresh
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

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')} '
      '${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][dt.month - 1]} '
      '${dt.year}';

  // ─── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isUpdate = _existingSchedule != null;

    return Scaffold(
      backgroundColor: _SC.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _SC.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUpdate
                  ? _t('Update Schedule', 'Perbarui Jadwal', '更新计划')
                  : _t('Schedule Audit', 'Jadwalkan Audit', '安排审计'),
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _SC.primary),
            ),
            Text(
              widget.locationName,
              style: GoogleFonts.poppins(fontSize: 11, color: _SC.textSub),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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

                        // ── Assign Auditor ─────────────────────────────
                        Text(
                          _t('Assign Auditor', 'Pilih Auditor', '分配审计员'),
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _SC.textSub),
                        ),
                        const SizedBox(height: 8),

                        // Selected auditor chip
                        if (_selectedAuditor != null) ...[
                          _SelectedAuditorChip(
                            user: _selectedAuditor!,
                            onClear: () =>
                                setState(() => _selectedAuditor = null),
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Search field
                        TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: _t('Search auditor…', 'Cari auditor…',
                                '搜索审计员…'),
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
                                borderSide:
                                    const BorderSide(color: _SC.divider)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide:
                                    const BorderSide(color: _SC.divider)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                    color: _SC.primary, width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ✅ Auditor list dalam SizedBox scrollable
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: _filteredAuditors.length,
                            itemBuilder: (_, i) {
                              final u = _filteredAuditors[i];
                              final isSelected =
                                  _selectedAuditor?['id_user'] ==
                                      u['id_user'];
                              return _AuditorTile(
                                user: u,
                                isSelected: isSelected,
                                onTap: () =>
                                    setState(() => _selectedAuditor = u),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

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

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _SelectedAuditorChip extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onClear;
  const _SelectedAuditorChip({required this.user, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final jabatan =
        (user['jabatan'] as Map<String, dynamic>?)?['nama_jabatan']
            ?.toString();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _Avatar(user: user, radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['nama'] ?? '',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _SC.textMain)),
                if (jabatan != null)
                  Text(jabatan,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: _SC.textSub)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close_rounded,
                size: 16, color: _SC.textSub),
          ),
        ],
      ),
    );
  }
}

class _AuditorTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isSelected;
  final VoidCallback onTap;
  const _AuditorTile(
      {required this.user,
      required this.isSelected,
      required this.onTap});

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
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8B5CF6).withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8B5CF6)
                : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
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
                          color: isSelected
                              ? const Color(0xFF8B5CF6)
                              : _SC.textMain)),
                  if (jabatan != null)
                    Text(jabatan,
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: _SC.textSub)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF8B5CF6), size: 18),
          ],
        ),
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