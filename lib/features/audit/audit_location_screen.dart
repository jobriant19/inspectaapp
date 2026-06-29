import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'audit_question_manager_screen.dart';
import 'audit_result_detail_screen.dart';
import 'audit_schedule_screen.dart';

// ─── Colour constants ────────────────────────────────────────────────────────
class _C {
  static const primary    = Color(0xFF8B5CF6);
  static const primaryLt  = Color(0xFFEDE9FE);
  static const green      = Color(0xFF10B981);
  static const amber      = Color(0xFFF59E0B);
  static const red        = Color(0xFFEF4444);
  static const blue       = Color(0xFF0EA5E9);
  static const textMain   = Color(0xFF1E3A8A);
  static const textSub    = Color(0xFF64748B);
  static const divider    = Color(0xFFE2E8F0);
  static const surface    = Color(0xFFF8FAFC);
}

// ─── Model ───────────────────────────────────────────────────────────────────
class _LocationItem {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  String? schedulePeriode;
  String? scheduleAuditorName;
  String? scheduleJenisAuditName; // ✅ BARU
  double? latestScore;
  String? latestAuditDate;
  String? picName;
  final String? idParent;

  _LocationItem({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.schedulePeriode,
    this.scheduleAuditorName,
    this.scheduleJenisAuditName, // ✅ BARU
    this.latestScore,
    this.latestAuditDate,
    this.picName,
    this.idParent,
  });
}

// Model filter hierarki
class _HierarchyFilter {
  final String? idLokasi;
  final String? namaLokasi;
  final String? idUnit;
  final String? namaUnit;
  final String? idSubunit;
  final String? namaSubunit;
  // Filter audit
  final String? auditStatus;
  final double? minScore;
  final double? maxScore;

  const _HierarchyFilter({
    this.idLokasi,
    this.namaLokasi,
    this.idUnit,
    this.namaUnit,
    this.idSubunit,
    this.namaSubunit,
    this.auditStatus,
    this.minScore,
    this.maxScore,
  });
}

// ─── Main Screen ─────────────────────────────────────────────────────────────
class AuditLocationScreen extends StatefulWidget {
  final String lang;
  const AuditLocationScreen({super.key, required this.lang});

  @override
  State<AuditLocationScreen> createState() => _AuditLocationScreenState();
}

class _AuditLocationScreenState extends State<AuditLocationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _supabase = Supabase.instance.client;

  // Level → data
  final _data = <String, List<_LocationItem>>{
    'lokasi': [], 'unit': [], 'subunit': [], 'area': [],
  };
  final _loading = <String, bool>{
    'lokasi': true, 'unit': true, 'subunit': true, 'area': true,
  };
  final _search = <String, String>{
    'lokasi': '', 'unit': '', 'subunit': '', 'area': '',
  };

  // ✅ BARU: state filter hierarki per level
  final _filterHierarchy = <String, _HierarchyFilter?>{
    'lokasi': null, 'unit': null, 'subunit': null, 'area': null,
  };

  // ✅ BARU: cek apakah level memiliki schedule (untuk filter audit status)
  final _hasSchedule = <String, bool>{
    'lokasi': false, 'unit': false, 'subunit': false, 'area': false,
  };

  // ✅ BARU: cache data lokasi/unit/subunit untuk dropdown filter
  List<Map<String, dynamic>> _allLokasi   = [];
  List<Map<String, dynamic>> _allUnit     = [];
  List<Map<String, dynamic>> _allSubunit  = [];
  bool _filterDataLoaded = false;

  static const _levels = ['lokasi', 'unit', 'subunit', 'area'];

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  List<String> get _tabLabels => [
    _t('Location', 'Lokasi', '位置'),
    _t('Unit', 'Unit', '单元'),
    _t('Sub-Unit', 'Sub-Unit', '子单元'),
    _t('Area', 'Area', '区域'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(_onTab);
    // Fetch semua level sekaligus di background agar pindah tab tidak loading
    for (final level in _levels) {
      _fetchLevel(level);
    }
  }

  @override
  void dispose() {
    _tabCtrl.removeListener(_onTab);
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onTab() {
    if (_tabCtrl.indexIsChanging) return;
    final level = _levels[_tabCtrl.index];
    // Hanya fetch jika data benar-benar belum pernah dimuat
    if (_data[level]!.isEmpty && _loading[level] == true) {
      _fetchLevel(level);
    }
  }

  Future<void> _fetchLevel(String level) async {
    setState(() => _loading[level] = true);
    try {
      final idCol   = 'id_$level';
      final nameCol = 'nama_$level';

      // Fetch location list
      final rows = await _supabase
        .from(level)
        .select('$idCol, $nameCol, gambar_$level, deskripsi_$level, id_pic'
            '${level == 'unit' ? ', id_lokasi' : ''}'
            '${level == 'subunit' ? ', id_unit' : ''}'
            '${level == 'area' ? ', id_subunit' : ''}')
        .order(nameCol);

      // Fetch latest audit result per location
      // Fetch audit result + PIC paralel (mengurangi latensi)
      final ids = rows.map((r) => r[idCol].toString()).toList();
      final picIds = rows
          .where((r) => r['id_pic'] != null)
          .map((r) => r['id_pic'].toString())
          .toSet()
          .toList();

      final futures = await Future.wait([
        // Audit result
        ids.isNotEmpty
            ? _supabase
                .from('audit_result')
                .select('id_ref, nilai_audit, tanggal_audit')
                .eq('level_type', level)
                .inFilter('id_ref', ids)
                .order('tanggal_audit', ascending: false)
            : Future.value(<dynamic>[]),
        // PIC names
        picIds.isNotEmpty
            ? _supabase
                .from('User')
                .select('id_user, nama')
                .inFilter('id_user', picIds)
            : Future.value(<dynamic>[]),
      ]);

      final Map<String, Map<String, dynamic>> auditMap = {};
      for (final a in futures[0]) {
        final ref = a['id_ref'].toString();
        if (!auditMap.containsKey(ref)) auditMap[ref] = a as Map<String, dynamic>;
      }

      final Map<String, String> picMap = {};
      for (final p in futures[1]) {
        picMap[p['id_user'].toString()] = p['nama'] ?? '-';
      }

      // ✅ BARU: Fetch pending schedule per item
      final scheduleRows = ids.isNotEmpty
          ? await _supabase
              .from('audit_schedule')
              .select(
                  'id_ref, periode_mulai, periode_selesai, id_jenis_audit, '
                  'User_Auditor:User!fk_audit_schedule_auditor(nama), '
                  'JenisAudit:jenis_audit(nama_id, nama_en, nama_zh)')
              .eq('level_type', level)
              .inFilter('id_ref', ids)
              .eq('status', 'pending')
              .order('created_at', ascending: false)
          : <dynamic>[];

      final Map<String, Map<String, dynamic>> scheduleMap = {};
      for (final s in scheduleRows) {
        final ref = s['id_ref'].toString();
        if (!scheduleMap.containsKey(ref)) scheduleMap[ref] = s as Map<String, dynamic>;
      }

      _hasSchedule[level] = scheduleRows.isNotEmpty;

      final items = rows.map<_LocationItem>((r) {
        final id = r[idCol].toString();
        final audit = auditMap[id];
        final schedule = scheduleMap[id];

        String? parentId;
        if (level == 'unit')    parentId = r['id_lokasi']?.toString();
        if (level == 'subunit') parentId = r['id_unit']?.toString();
        if (level == 'area')    parentId = r['id_subunit']?.toString();

        // ✅ Format periode schedule jika ada
        String? schedulePeriode;
        String? scheduleAuditorName;
        String? scheduleJenisAuditName; // ✅ BARU
        if (schedule != null) {
          final mulai   = DateTime.tryParse(schedule['periode_mulai']?.toString() ?? '');
          final selesai = DateTime.tryParse(schedule['periode_selesai']?.toString() ?? '');
          if (mulai != null && selesai != null) {
            schedulePeriode =
                '${DateFormat('dd MMM').format(mulai)} – ${DateFormat('dd MMM yyyy').format(selesai)}';
          }
          final auditorData = schedule['User_Auditor'] as Map<String, dynamic>?;
          scheduleAuditorName = auditorData?['nama']?.toString();

          // ✅ BARU: nama jenis audit sesuai bahasa
          final jenisData = schedule['JenisAudit'] as Map<String, dynamic>?;
          if (jenisData != null) {
            scheduleJenisAuditName = widget.lang == 'EN'
                ? jenisData['nama_en']?.toString()
                : widget.lang == 'ZH'
                    ? jenisData['nama_zh']?.toString()
                    : jenisData['nama_id']?.toString();
          }
        }

        return _LocationItem(
          id: id,
          name: r[nameCol]?.toString() ?? '-',
          description: r['deskripsi_$level']?.toString(),
          imageUrl: r['gambar_$level']?.toString(),
          latestScore: audit != null
              ? double.tryParse(audit['nilai_audit']?.toString() ?? '')
              : null,
          latestAuditDate: audit?['tanggal_audit']?.toString(),
          picName: r['id_pic'] != null ? picMap[r['id_pic'].toString()] : null,
          idParent: parentId,
          schedulePeriode: schedulePeriode,
          scheduleAuditorName: scheduleAuditorName,
          scheduleJenisAuditName: scheduleJenisAuditName, // ✅ BARU
        );
      }).toList();

      if (mounted) {
        setState(() {
          _data[level] = items;
          _loading[level] = false;
        });
      }
    } catch (e) {
      debugPrint('Audit fetch error [$level]: $e');
      if (mounted) setState(() => _loading[level] = false);
    }
  }

  Color _scoreColor(double? score) {
    if (score == null) return _C.textSub;
    if (score >= 80) return _C.green;
    if (score >= 60) return _C.amber;
    return _C.red;
  }

  String _scoreLabel(double? score) {
    if (score == null) return _t('No audit', 'Belum diaudit', '未审计');
    if (score >= 80) return _t('Good', 'Baik', '良好');
    if (score >= 60) return _t('Fair', 'Cukup', '一般');
    return _t('Poor', 'Kurang', '较差');
  }

  Widget _buildCard(_LocationItem item, String level) {
    final score = item.latestScore;
    final scoreColor = _scoreColor(score);
    return GestureDetector(
      onTap: () => _showDetail(item, level),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.divider, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? Image.network(item.imageUrl!,
                            width: 56, height: 56, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildInitial(item.name))
                        : _buildInitial(item.name),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _C.textMain),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        if (item.picName != null) ...[
                          const SizedBox(height: 3),
                          Row(children: [
                            const Icon(Icons.person_outline_rounded,
                                size: 12, color: _C.textSub),
                            const SizedBox(width: 4),
                            Expanded(
                                child: Text(item.picName!,
                                    style: GoogleFonts.poppins(
                                        fontSize: 11, color: _C.textSub),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
                          ]),
                        ],
                        // ✅ BARU: Badge jenis audit
                        if (item.scheduleJenisAuditName != null) ...[
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _C.primary.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _C.primary.withValues(alpha:0.35)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.fact_check_rounded, size: 11, color: _C.primary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    item.scheduleJenisAuditName!,
                                    style: GoogleFonts.poppins(
                                        fontSize: 10, fontWeight: FontWeight.w600, color: _C.primary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Badge periode schedule
                        if (item.schedulePeriode != null) ...[
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _C.blue.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: _C.blue.withValues(alpha:0.35)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.event_rounded,
                                    size: 11, color: _C.blue),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    item.schedulePeriode!,
                                    style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: _C.blue),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: scoreColor.withValues(alpha:0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: scoreColor.withValues(alpha:0.4), width: 1),
                        ),
                        child: Text(
                          score != null
                              ? '${score.toStringAsFixed(0)}%'
                              : '-',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: scoreColor),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(_scoreLabel(score),
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: scoreColor)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ BARU: Assign auditor info jika ada schedule
                  if (item.scheduleAuditorName != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.assignment_ind_outlined,
                            size: 12, color: _C.blue),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${_t('Auditor', 'Auditor', '审计员')}: ${item.scheduleAuditorName!}',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: _C.blue),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                  ],
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 12, color: _C.textSub),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.latestAuditDate != null
                              ? '${_t('Last audit', 'Terakhir diaudit', '上次审计')}: ${_formatDate(item.latestAuditDate!)}'
                              : _t('Never audited', 'Belum pernah diaudit', '从未审计'),
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: _C.textSub),
                        ),
                      ),
                      _SmallButton(
                        label: _t('Questions', 'Pertanyaan', '问题'),
                        color: _C.primary,
                        icon: Icons.help_outline_rounded,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AuditQuestionManagerScreen(
                              lang: widget.lang,
                              levelType: level,
                              idRef: item.id,
                              locationName: item.name,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SmallButton(
                        label: _t('Audit', 'Audit', '审计'),
                        color: _C.green,
                        icon: Icons.assignment_turned_in_outlined,
                        onTap: () => _openAuditForm(item, level),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitial(String name) {
    final initials = name.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    return Container(
      width: 56, height: 56,
      color: _C.primaryLt,
      child: Center(
        child: Text(initials,
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _C.primary)),
      ),
    );
  }

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('dd MMM yyyy').format(dt);
  }

  Future<void> _openAuditForm(_LocationItem item, String level) async {
    final qRows = await _supabase
        .from('audit_question')
        .select('id_question')
        .eq('level_type', level)
        .eq('id_ref', item.id)
        .eq('is_active', true)
        .limit(1);
    final qCount = (qRows as List).length;

    if (!mounted) return;

    if (qCount == 0) {
      // Popup dialog jika belum ada pertanyaan aktif
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: _C.amber.withValues(alpha:0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.help_outline_rounded,
                    color: _C.amber, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                _t('No Questions', 'Belum Ada Pertanyaan', '暂无问题'),
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _C.textMain),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _t(
                  'No active questions found.\nPlease add questions first via the Questions button.',
                  'Belum ada pertanyaan aktif.\nSilakan tambahkan pertanyaan terlebih dahulu melalui tombol Pertanyaan.',
                  '尚无活动问题。\n请先通过"问题"按钮添加问题。',
                ),
                style: GoogleFonts.poppins(fontSize: 13, color: _C.textSub),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _C.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        _t('Cancel', 'Batal', '取消'),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, color: _C.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AuditQuestionManagerScreen(
                              lang: widget.lang,
                              levelType: level,
                              idRef: item.id,
                              locationName: item.name,
                            ),
                          ),
                        ).then((_) => _fetchLevel(level));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        _t('Add Now', 'Tambah Sekarang', '立即添加'),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuditScheduleScreen(
          lang: widget.lang,
          levelType: level,
          idRef: item.id,
          locationName: item.name,
        ),
      ),
    );
    // Auto-refresh setelah kembali
    _fetchLevel(level);
  }

  void _showDetail(_LocationItem item, String level) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AuditDetailSheet(
        lang: widget.lang,
        item: item,
        level: level,
      ),
    );
  }

  // ✅ BARU: Load semua lokasi/unit/subunit untuk keperluan dropdown filter
  Future<void> _loadFilterData() async {
    if (_filterDataLoaded) return;
    try {
      final results = await Future.wait([
        _supabase.from('lokasi').select('id_lokasi, nama_lokasi').order('nama_lokasi'),
        _supabase.from('unit').select('id_unit, nama_unit, id_lokasi').order('nama_unit'),
        _supabase.from('subunit').select('id_subunit, nama_subunit, id_unit').order('nama_subunit'),
      ]);
      if (mounted) {
        setState(() {
          _allLokasi   = List<Map<String, dynamic>>.from(results[0]);
          _allUnit     = List<Map<String, dynamic>>.from(results[1]);
          _allSubunit  = List<Map<String, dynamic>>.from(results[2]);
          _filterDataLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading filter data: $e');
    }
  }

  // ✅ BARU: Tampilkan bottom sheet filter untuk tab tertentu
  Future<void> _showFilterSheet(String level) async {
    await _loadFilterData();
    if (!mounted) return;

    final _HierarchyFilter? current = _filterHierarchy[level];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          String? selectedLokasiId  = current?.idLokasi;
          String? selectedUnitId    = current?.idUnit;
          String? selectedSubunitId = current?.idSubunit;
          String? selectedAuditStatus = current?.auditStatus;
          double? selectedMinScore    = current?.minScore;
          double? selectedMaxScore    = current?.maxScore;

          List<Map<String, dynamic>> filteredUnit = selectedLokasiId == null
              ? _allUnit
              : _allUnit.where((u) => u['id_lokasi']?.toString() == selectedLokasiId).toList();

          List<Map<String, dynamic>> filteredSubunit = selectedUnitId == null
              ? _allSubunit
              : _allSubunit.where((s) => s['id_unit']?.toString() == selectedUnitId).toList();

          final scoreRanges = [
            {'label': _t('All Scores', 'Semua Nilai', '所有分数'), 'min': null, 'max': null},
            {'label': '≥ 80% (${_t('Good', 'Baik', '良好')})', 'min': 80.0, 'max': null},
            {'label': '60–79% (${_t('Fair', 'Cukup', '一般')})', 'min': 60.0, 'max': 79.9},
            {'label': '< 60% (${_t('Poor', 'Kurang', '较差')})', 'min': null, 'max': 59.9},
          ];

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _t('Filter', 'Filter', '筛选'),
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _C.textMain),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _filterHierarchy[level] = null);
                          Navigator.pop(ctx);
                        },
                        child: Text(_t('Reset', 'Reset', '重置'),
                            style: GoogleFonts.poppins(color: _C.red, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: StatefulBuilder(
                      builder: (ctx2, setInner) {
                        filteredUnit = selectedLokasiId == null
                            ? _allUnit
                            : _allUnit.where((u) => u['id_lokasi']?.toString() == selectedLokasiId).toList();
                        filteredSubunit = selectedUnitId == null
                            ? _allSubunit
                            : _allSubunit.where((s) => s['id_unit']?.toString() == selectedUnitId).toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Filter Lokasi ──
                            Text(_t('Location', 'Lokasi', '位置'),
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _C.textSub)),
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              _FilterChipItem(
                                label: _t('All', 'Semua', '全部'),
                                isSelected: selectedLokasiId == null,
                                color: _C.primary,
                                onTap: () => setInner(() {
                                  selectedLokasiId  = null;
                                  selectedUnitId    = null;
                                  selectedSubunitId = null;
                                }),
                              ),
                              ..._allLokasi.map((lok) {
                                final id   = lok['id_lokasi']?.toString() ?? '';
                                final nama = lok['nama_lokasi']?.toString() ?? '';
                                return _FilterChipItem(
                                  label: nama,
                                  isSelected: selectedLokasiId == id,
                                  color: _C.primary,
                                  onTap: () => setInner(() {
                                    selectedLokasiId  = id;
                                    selectedUnitId    = null;
                                    selectedSubunitId = null;
                                  }),
                                );
                              }),
                            ]),
                            const SizedBox(height: 16),

                            // ── Filter Unit ──
                            if ((level == 'subunit' || level == 'area') ||
                                (level == 'unit' && selectedLokasiId != null)) ...[
                              Text(_t('Unit', 'Unit', '单元'),
                                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _C.textSub)),
                              const SizedBox(height: 8),
                              Wrap(spacing: 8, runSpacing: 8, children: [
                                _FilterChipItem(
                                  label: _t('All', 'Semua', '全部'),
                                  isSelected: selectedUnitId == null,
                                  color: _C.blue,
                                  onTap: () => setInner(() {
                                    selectedUnitId    = null;
                                    selectedSubunitId = null;
                                  }),
                                ),
                                ...filteredUnit.map((unit) {
                                  final id   = unit['id_unit']?.toString() ?? '';
                                  final nama = unit['nama_unit']?.toString() ?? '';
                                  return _FilterChipItem(
                                    label: nama,
                                    isSelected: selectedUnitId == id,
                                    color: _C.blue,
                                    onTap: () => setInner(() {
                                      selectedUnitId    = id;
                                      selectedSubunitId = null;
                                    }),
                                  );
                                }),
                              ]),
                              const SizedBox(height: 16),
                            ],

                            // ── Filter Sub-Unit (untuk subunit tab & area tab) ──
                            // subunit tab: tampil jika lokasi dipilih (filter berdasarkan unit yg ada di lokasi itu)
                            // area tab: tampil selalu, filter berdasarkan unit jika dipilih
                            if ((level == 'subunit' && selectedLokasiId != null) ||
                                level == 'area') ...[
                              Text(_t('Sub-Unit', 'Sub-Unit', '子单元'),
                                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _C.textSub)),
                              const SizedBox(height: 8),
                              Wrap(spacing: 8, runSpacing: 8, children: [
                                _FilterChipItem(
                                  label: _t('All', 'Semua', '全部'),
                                  isSelected: selectedSubunitId == null,
                                  color: _C.green,
                                  onTap: () => setInner(() => selectedSubunitId = null),
                                ),
                                ...filteredSubunit.map((sub) {
                                  final id   = sub['id_subunit']?.toString() ?? '';
                                  final nama = sub['nama_subunit']?.toString() ?? '';
                                  return _FilterChipItem(
                                    label: nama,
                                    isSelected: selectedSubunitId == id,
                                    color: _C.green,
                                    onTap: () => setInner(() => selectedSubunitId = id),
                                  );
                                }),
                              ]),
                              const SizedBox(height: 16),
                            ],

                            const Divider(),
                            const SizedBox(height: 8),

                            // ── Filter Status Audit ──
                            if (_hasSchedule[level] == true) ...[
                              Text(_t('Audit Status', 'Status Audit', '审计状态'),
                                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _C.textSub)),
                              const SizedBox(height: 8),
                              Wrap(spacing: 8, runSpacing: 8, children: [
                                _FilterChipItem(
                                  label: _t('All', 'Semua', '全部'),
                                  isSelected: selectedAuditStatus == null,
                                  color: _C.primary,
                                  onTap: () => setInner(() => selectedAuditStatus = null),
                                ),
                                _FilterChipItem(
                                  label: _t('Audited', 'Sudah Diaudit', '已审计'),
                                  isSelected: selectedAuditStatus == 'audited',
                                  color: _C.green,
                                  onTap: () => setInner(() => selectedAuditStatus = 'audited'),
                                ),
                                _FilterChipItem(
                                  label: _t('Not Audited', 'Belum Diaudit', '未审计'),
                                  isSelected: selectedAuditStatus == 'not_audited',
                                  color: _C.amber,
                                  onTap: () => setInner(() => selectedAuditStatus = 'not_audited'),
                                ),
                              ]),
                              const SizedBox(height: 16),
                            ],

                            // ── Filter Range Nilai ──
                            Text(_t('Score Range', 'Rentang Nilai', '分数范围'),
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _C.textSub)),
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, runSpacing: 8, children: scoreRanges.map((range) {
                              final min = range['min'] as double?;
                              final max = range['max'] as double?;
                              final isSelected = selectedMinScore == min && selectedMaxScore == max;
                              Color chipColor = _C.primary;
                              if (min == 80.0) chipColor = _C.green;
                              else if (min == 60.0) chipColor = _C.amber;
                              else if (max == 59.9) chipColor = _C.red;
                              return _FilterChipItem(
                                label: range['label'] as String,
                                isSelected: isSelected,
                                color: chipColor,
                                onTap: () => setInner(() {
                                  selectedMinScore = min;
                                  selectedMaxScore = max;
                                }),
                              );
                            }).toList()),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final lokasiNama = _allLokasi
                            .firstWhere((l) => l['id_lokasi']?.toString() == selectedLokasiId, orElse: () => {})['nama_lokasi']?.toString();
                        final unitNama = _allUnit
                            .firstWhere((u) => u['id_unit']?.toString() == selectedUnitId, orElse: () => {})['nama_unit']?.toString();
                        final subunitNama = _allSubunit
                            .firstWhere((s) => s['id_subunit']?.toString() == selectedSubunitId, orElse: () => {})['nama_subunit']?.toString();

                        setState(() {
                          final hasFilter = selectedLokasiId != null ||
                              selectedUnitId != null ||
                              selectedSubunitId != null ||
                              selectedAuditStatus != null ||
                              selectedMinScore != null ||
                              selectedMaxScore != null;
                          _filterHierarchy[level] = hasFilter
                              ? _HierarchyFilter(
                                  idLokasi:    selectedLokasiId,
                                  namaLokasi:  lokasiNama,
                                  idUnit:      selectedUnitId,
                                  namaUnit:    unitNama,
                                  idSubunit:   selectedSubunitId,
                                  namaSubunit: subunitNama,
                                  auditStatus: selectedAuditStatus,
                                  minScore:    selectedMinScore,
                                  maxScore:    selectedMaxScore,
                                )
                              : null;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(_t('Apply Filter', 'Terapkan Filter', '应用筛选'),
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Terapkan filter hierarki pada list item
  List<_LocationItem> _applyHierarchyFilter(List<_LocationItem> items, String level) {
    final filter = _filterHierarchy[level];
    if (filter == null) return items;

    List<_LocationItem> result = items;

    // ── Filter Hierarki ──
    if (level == 'lokasi') {
      // Lokasi tidak punya parent, tapi bisa filter by audit status/score saja
    } else if (level == 'unit') {
      if (filter.idLokasi != null) {
        result = result.where((i) => i.idParent == filter.idLokasi).toList();
      }
    } else if (level == 'subunit') {
      // Subunit filter berdasarkan unit (idParent = id_unit)
      if (filter.idUnit != null) {
        result = result.where((i) => i.idParent == filter.idUnit).toList();
      } else if (filter.idLokasi != null) {
        final validUnitIds = _allUnit
            .where((u) => u['id_lokasi']?.toString() == filter.idLokasi)
            .map((u) => u['id_unit']?.toString() ?? '')
            .toSet();
        result = result.where((i) => validUnitIds.contains(i.idParent)).toList();
      }
    } else if (level == 'area') {
      // Area filter berdasarkan subunit (idParent = id_subunit)
      if (filter.idSubunit != null) {
        result = result.where((i) => i.idParent == filter.idSubunit).toList();
      } else if (filter.idUnit != null) {
        final validSubIds = _allSubunit
            .where((s) => s['id_unit']?.toString() == filter.idUnit)
            .map((s) => s['id_subunit']?.toString() ?? '')
            .toSet();
        result = result.where((i) => validSubIds.contains(i.idParent)).toList();
      } else if (filter.idLokasi != null) {
        final validUnitIds = _allUnit
            .where((u) => u['id_lokasi']?.toString() == filter.idLokasi)
            .map((u) => u['id_unit']?.toString() ?? '')
            .toSet();
        final validSubIds = _allSubunit
            .where((s) => validUnitIds.contains(s['id_unit']?.toString()))
            .map((s) => s['id_subunit']?.toString() ?? '')
            .toSet();
        result = result.where((i) => validSubIds.contains(i.idParent)).toList();
      }
    }

    // ── Filter Audit Status ──
    if (filter.auditStatus == 'audited') {
      result = result.where((i) => i.latestScore != null).toList();
    } else if (filter.auditStatus == 'not_audited') {
      result = result.where((i) => i.latestScore == null).toList();
    }

    // ── Filter Range Nilai ──
    if (filter.minScore != null || filter.maxScore != null) {
      result = result.where((i) {
        final score = i.latestScore;
        if (score == null) return false;
        if (filter.minScore != null && score < filter.minScore!) return false;
        if (filter.maxScore != null && score > filter.maxScore!) return false;
        return true;
      }).toList();
    }

    return result;
  }

  Widget _buildTab(String level) {
    final raw = _data[level]!;
    final query = _search[level]!.toLowerCase();
    final filter = _filterHierarchy[level];

    // ✅ Terapkan filter hierarki dulu, baru search
    final filtered = _applyHierarchyFilter(raw, level);
    final items = query.isEmpty
        ? filtered
        : filtered
            .where((i) => i.name.toLowerCase().contains(query))
            .toList();

    // ✅ Label filter aktif
    String? filterLabel;
    if (filter != null) {
      final parts = <String>[
        if (filter.namaLokasi != null) filter.namaLokasi!,
        if (filter.namaUnit != null) filter.namaUnit!,
        if (filter.namaSubunit != null) filter.namaSubunit!,
        if (filter.auditStatus == 'audited') _t('Audited', 'Sudah Diaudit', '已审计'),
        if (filter.auditStatus == 'not_audited') _t('Not Audited', 'Belum Diaudit', '未审计'),
        if (filter.minScore != null || filter.maxScore != null) ...[
          if (filter.minScore == 80.0 && filter.maxScore == null) '≥80%',
          if (filter.minScore == 60.0 && filter.maxScore == 79.9) '60-79%',
          if (filter.minScore == null && filter.maxScore == 59.9) '<60%',
        ],
      ];
      if (parts.isNotEmpty) filterLabel = parts.join(' · ');
    }

    return Column(
      children: [
        // Search bar + Filter button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _search[level] = v),
                  style: GoogleFonts.poppins(fontSize: 14, color: _C.textMain),
                  decoration: InputDecoration(
                    hintText: _t('Search…', 'Cari…', '搜索…'),
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 13, color: _C.textSub),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: _C.primary, size: 20),
                    filled: true,
                    fillColor: _C.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: _C.divider)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: _C.divider)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(
                            color: _C.primary, width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showFilterSheet(level),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: filter != null
                        ? _C.primary
                        : _C.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: filter != null ? _C.primary : _C.divider,
                    ),
                  ),
                  child: Icon(
                    Icons.filter_list_rounded,
                    color: filter != null ? Colors.white : _C.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ✅ BARU: Label filter aktif
        if (filterLabel != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _C.primary.withValues(alpha:0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _C.primary.withValues(alpha:0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_rounded,
                      size: 14, color: _C.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(filterLabel,
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: _C.primary,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _filterHierarchy[level] = null),
                    child: const Icon(Icons.close_rounded,
                        size: 14, color: _C.primary),
                  ),
                ],
              ),
            ),
          ),

        // Stats row
        if (!(_loading[level]!))
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: _StatsRow(items: raw, lang: widget.lang),
          ),

        // List
        Expanded(
          child: _loading[level]!
              ? _buildShimmer()
              : items.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: () => _fetchLevel(level),
                      color: _C.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                            bottom: 100, top: 4),
                        itemCount: items.length,
                        itemBuilder: (_, i) =>
                            _buildCard(items[i], level),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 110,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_rounded,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(_t('No data found', 'Tidak ada data', '没有数据'),
              style: GoogleFonts.poppins(
                  fontSize: 14, color: _C.textSub)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _C.primary, size: 20),   // ← ungu
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('Audit Location', 'Audit Lokasi', '审计位置'),
          style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _C.primary),   // ← ungu
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(3),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  color: _C.primary,   // ← ungu
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: _C.primary,   // ← ungu
                labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 11.5),
                unselectedLabelStyle:
                    GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11.5),
                dividerColor: Colors.transparent,
                overlayColor:
                    WidgetStateProperty.all(Colors.transparent),
                tabs: _tabLabels
                    .map((l) => Tab(child: Text(l)))
                    .toList(),
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: _levels.map((l) => _buildTab(l)).toList(),
      ),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final List<_LocationItem> items;
  final String lang;
  const _StatsRow({required this.items, required this.lang});

  String _t(String en, String id, String zh) {
    if (lang == 'EN') return en;
    if (lang == 'ZH') return zh;
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final audited = items.where((i) => i.latestScore != null).length;
    final avgScore = audited > 0
        ? items
                .where((i) => i.latestScore != null)
                .map((i) => i.latestScore!)
                .reduce((a, b) => a + b) /
            audited
        : 0.0;

    // ✅ FIX: Gunakan Row dengan Expanded agar proporsional & tidak overflow
    return Row(
      children: [
        Expanded(
          child: _StatChip(
              label: _t('Total', 'Total', '总计'),
              value: '${items.length}',
              color: _C.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatChip(
              label: _t('Audited', 'Diaudit', '已审计'),
              value: '$audited',
              color: _C.green),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatChip(
              label: _t('Avg Score', 'Rata-rata', '平均分'),
              value: audited > 0 ? '${avgScore.toStringAsFixed(0)}%' : '-',
              color: _C.amber),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: width: double.infinity agar mengisi Expanded penuh
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: color.withValues(alpha:0.8)),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─── Small action button ──────────────────────────────────────────────────────
class _SmallButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _SmallButton(
      {required this.label,
      required this.color,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha:0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

// ─── Detail Bottom Sheet ──────────────────────────────────────────────────────
class _AuditDetailSheet extends StatefulWidget {
  final String lang;
  final _LocationItem item;
  final String level;
  const _AuditDetailSheet(
      {required this.lang, required this.item, required this.level});

  @override
  State<_AuditDetailSheet> createState() => _AuditDetailSheetState();
}

class _AuditDetailSheetState extends State<_AuditDetailSheet> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Color _scoreColor(double? score) {
    if (score == null) return _C.textSub;
    if (score >= 80) return _C.green;
    if (score >= 60) return _C.amber;
    return _C.red;
  }

  Future<void> _fetchHistory() async {
    try {
      final rows = await _supabase
          .from('audit_result')
          .select(
              'id_result, nilai_audit, nilai_final, is_finalized, '
              'tanggal_audit, catatan_audit, selfie_url, created_at, '
              'Auditor:User!fk_audit_result_auditor(nama, gambar_user)')
          .eq('level_type', widget.level)
          .eq('id_ref', widget.item.id)
          .order('tanggal_audit', ascending: false)
          .limit(20);
      if (mounted) {
        setState(() {
          _history = List<Map<String, dynamic>>.from(rows);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.item.name,
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _C.textMain)),
                  ),
                  if (widget.item.latestScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _scoreColor(widget.item.latestScore)
                            .withValues(alpha:0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                          '${widget.item.latestScore!.toStringAsFixed(0)}%',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _scoreColor(widget.item.latestScore))),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    _t('Riwayat Audit', 'Audit History', '审计历史'),
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _C.textMain)),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _C.primary))
                  : _history.isEmpty
                      ? Center(
                          child: Text(
                              _t('Belum ada riwayat audit', 'No audit history', '无审计历史'),
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: _C.textSub)))
                      : ListView.separated(
                          controller: ctrl,
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: _history.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final row = _history[i];
                            final score = double.tryParse(
                                row['nilai_audit']?.toString() ?? '');
                            final scoreFinal = double.tryParse(
                                row['nilai_final']?.toString() ?? '');
                            final isFinalized = row['is_finalized'] == true;
                            final displayScore =
                                isFinalized ? scoreFinal : score;
                            final auditorData = row['Auditor']
                                as Map<String, dynamic>?;
                            final auditor =
                                auditorData?['nama']?.toString() ?? '-';
                            final date =
                                row['tanggal_audit']?.toString() ?? '';
                            final color = _scoreColor(displayScore);
                            final idResult =
                                row['id_result']?.toString() ?? '';

                            return GestureDetector(
                              onTap: () {
                                Navigator.pop(context); // tutup bottom sheet
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AuditResultDetailScreen(
                                      lang: widget.lang,
                                      idResult: idResult,
                                      locationName: widget.item.name,
                                      levelType: widget.level,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha:0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: color.withValues(alpha:0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 52, height: 52,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha:0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              displayScore != null
                                                  ? '${displayScore.toStringAsFixed(0)}%'
                                                  : '-',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: color),
                                            ),
                                            if (isFinalized)
                                              Text(
                                                _t('Final', 'Final', '最终'),
                                                style: GoogleFonts.poppins(
                                                    fontSize: 8,
                                                    color: color),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(auditor,
                                              style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: _C.textMain)),
                                          Text(date,
                                              style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: _C.textSub)),
                                        ],
                                      ),
                                    ),
                                    // Tombol lihat detail
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _C.primary.withValues(alpha:0.1),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                            color: _C.primary.withValues(alpha:0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                              Icons.open_in_new_rounded,
                                              size: 12,
                                              color: _C.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            _t('Detail', 'Detail', '详情'),
                                            style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: _C.primary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ BARU: Widget chip untuk pilihan filter
class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : _C.textSub,
          ),
        ),
      ),
    );
  }
}