import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../audit_result_detail_screen.dart';

class _SBC {
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

class _SubunitItem {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  String? schedulePeriode;
  String? scheduleAuditorName;
  String? scheduleJenisAuditName;
  double? latestScore;
  String? latestAuditDate;
  String? picName;
  final String? idUnit;

  _SubunitItem({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.schedulePeriode,
    this.scheduleAuditorName,
    this.scheduleJenisAuditName,
    this.latestScore,
    this.latestAuditDate,
    this.picName,
    this.idUnit,
  });
}

class _SubunitHierarchyFilter {
  final String? idLokasi;
  final String? namaLokasi;
  final String? idUnit;
  final String? namaUnit;
  final String? auditStatus;
  final double? minScore;
  final double? maxScore;

  const _SubunitHierarchyFilter({
    this.idLokasi,
    this.namaLokasi,
    this.idUnit,
    this.namaUnit,
    this.auditStatus,
    this.minScore,
    this.maxScore,
  });
}

class AuditSubunitScreen extends StatefulWidget {
  final String lang;
  final VoidCallback? onScheduleChanged;
  const AuditSubunitScreen({super.key, required this.lang, this.onScheduleChanged});

  @override
  State<AuditSubunitScreen> createState() => _AuditSubunitScreenState();
}

class _AuditSubunitScreenState extends State<AuditSubunitScreen> {
  final _supabase = Supabase.instance.client;

  List<_SubunitItem> _data = [];
  bool _loading = true;
  String _search = '';
  _SubunitHierarchyFilter? _filter;
  bool _hasSchedule = false;

  List<Map<String, dynamic>> _allLokasi = [];
  List<Map<String, dynamic>> _allUnit   = [];
  bool _filterDataLoaded = false;

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  @override
  void initState() {
    super.initState();
    _fetchSubunits();
  }

  Future<void> _fetchSubunits() async {
    setState(() => _loading = true);
    try {
      final rows = await _supabase
          .from('subunit')
          .select('id_subunit, nama_subunit, gambar_subunit, deskripsi_subunit, id_pic, id_unit')
          .order('nama_subunit');

      final ids = rows.map((r) => r['id_subunit'].toString()).toList();
      final picIds = rows
          .where((r) => r['id_pic'] != null)
          .map((r) => r['id_pic'].toString())
          .toSet()
          .toList();

      final futures = await Future.wait([
        ids.isNotEmpty
            ? _supabase
                .from('audit_result')
                .select('id_ref, nilai_audit, tanggal_audit')
                .eq('level_type', 'subunit')
                .inFilter('id_ref', ids)
                .order('tanggal_audit', ascending: false)
            : Future.value(<dynamic>[]),
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

      final scheduleRows = ids.isNotEmpty
          ? await _supabase
              .from('audit_schedule')
              .select(
                  'id_ref, periode_mulai, periode_selesai, id_jenis_audit, '
                  'User_Auditor:User!fk_audit_schedule_auditor(nama), '
                  'JenisAudit:jenis_audit(nama_id, nama_en, nama_zh)')
              .eq('level_type', 'subunit')
              .inFilter('id_ref', ids)
              .eq('status', 'pending')
              .order('created_at', ascending: false)
          : <dynamic>[];

      final Map<String, Map<String, dynamic>> scheduleMap = {};
      for (final s in scheduleRows) {
        final ref = s['id_ref'].toString();
        if (!scheduleMap.containsKey(ref)) scheduleMap[ref] = s as Map<String, dynamic>;
      }
      _hasSchedule = scheduleRows.isNotEmpty;

      final items = rows.map<_SubunitItem>((r) {
        final id = r['id_subunit'].toString();
        final audit = auditMap[id];
        final schedule = scheduleMap[id];

        String? schedulePeriode;
        String? scheduleAuditorName;
        String? scheduleJenisAuditName;
        if (schedule != null) {
          final mulai   = DateTime.tryParse(schedule['periode_mulai']?.toString() ?? '');
          final selesai = DateTime.tryParse(schedule['periode_selesai']?.toString() ?? '');
          if (mulai != null && selesai != null) {
            schedulePeriode =
                '${DateFormat('dd MMM').format(mulai)} – ${DateFormat('dd MMM yyyy').format(selesai)}';
          }
          final auditorData = schedule['User_Auditor'] as Map<String, dynamic>?;
          scheduleAuditorName = auditorData?['nama']?.toString();

          final jenisData = schedule['JenisAudit'] as Map<String, dynamic>?;
          if (jenisData != null) {
            scheduleJenisAuditName = widget.lang == 'EN'
                ? jenisData['nama_en']?.toString()
                : widget.lang == 'ZH'
                    ? jenisData['nama_zh']?.toString()
                    : jenisData['nama_id']?.toString();
          }
        }

        return _SubunitItem(
          id: id,
          name: r['nama_subunit']?.toString() ?? '-',
          description: r['deskripsi_subunit']?.toString(),
          imageUrl: r['gambar_subunit']?.toString(),
          latestScore: audit != null
              ? double.tryParse(audit['nilai_audit']?.toString() ?? '')
              : null,
          latestAuditDate: audit?['tanggal_audit']?.toString(),
          picName: r['id_pic'] != null ? picMap[r['id_pic'].toString()] : null,
          idUnit: r['id_unit']?.toString(),
          schedulePeriode: schedulePeriode,
          scheduleAuditorName: scheduleAuditorName,
          scheduleJenisAuditName: scheduleJenisAuditName,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _data = items;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Audit subunit fetch error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadFilterData() async {
    if (_filterDataLoaded) return;
    try {
      final results = await Future.wait([
        _supabase.from('lokasi').select('id_lokasi, nama_lokasi').order('nama_lokasi'),
        _supabase.from('unit').select('id_unit, nama_unit, id_lokasi').order('nama_unit'),
      ]);
      if (mounted) {
        setState(() {
          _allLokasi = List<Map<String, dynamic>>.from(results[0]);
          _allUnit   = List<Map<String, dynamic>>.from(results[1]);
          _filterDataLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading filter data: $e');
    }
  }

  Color _scoreColor(double? score) {
    if (score == null) return _SBC.textSub;
    if (score >= 80) return _SBC.green;
    if (score >= 60) return _SBC.amber;
    return _SBC.red;
  }

  String _scoreLabel(double? score) {
    if (score == null) return _t('No audit', 'Belum diaudit', '未审计');
    if (score >= 80) return _t('Good', 'Baik', '良好');
    if (score >= 60) return _t('Fair', 'Cukup', '一般');
    return _t('Poor', 'Kurang', '较差');
  }

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('dd MMM yyyy').format(dt);
  }

  List<_SubunitItem> _applyFilter(List<_SubunitItem> items) {
    final filter = _filter;
    if (filter == null) return items;
    List<_SubunitItem> result = items;

    if (filter.idUnit != null) {
      result = result.where((i) => i.idUnit == filter.idUnit).toList();
    } else if (filter.idLokasi != null) {
      final validUnitIds = _allUnit
          .where((u) => u['id_lokasi']?.toString() == filter.idLokasi)
          .map((u) => u['id_unit']?.toString() ?? '')
          .toSet();
      result = result.where((i) => validUnitIds.contains(i.idUnit)).toList();
    }

    if (filter.auditStatus == 'audited') {
      result = result.where((i) => i.latestScore != null).toList();
    } else if (filter.auditStatus == 'not_audited') {
      result = result.where((i) => i.latestScore == null).toList();
    }
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

  Future<void> _showFilterSheet() async {
    await _loadFilterData();
    if (!mounted) return;

    final current = _filter;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          String? selectedLokasiId = current?.idLokasi;
          String? selectedUnitId = current?.idUnit;
          String? selectedAuditStatus = current?.auditStatus;
          double? selectedMinScore = current?.minScore;
          double? selectedMaxScore = current?.maxScore;

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
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _SBC.textMain),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _filter = null);
                          Navigator.pop(ctx);
                        },
                        child: Text(_t('Reset', 'Reset', '重置'),
                            style: GoogleFonts.poppins(color: _SBC.red, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: StatefulBuilder(
                      builder: (ctx2, setInner) {
                        final filteredUnit = selectedLokasiId == null
                            ? _allUnit
                            : _allUnit.where((u) => u['id_lokasi']?.toString() == selectedLokasiId).toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_t('Location', 'Lokasi', '位置'),
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _SBC.textSub)),
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              _FilterChipItem(
                                label: _t('All', 'Semua', '全部'),
                                isSelected: selectedLokasiId == null,
                                color: _SBC.primary,
                                onTap: () => setInner(() {
                                  selectedLokasiId = null;
                                  selectedUnitId = null;
                                }),
                              ),
                              ..._allLokasi.map((lok) {
                                final id   = lok['id_lokasi']?.toString() ?? '';
                                final nama = lok['nama_lokasi']?.toString() ?? '';
                                return _FilterChipItem(
                                  label: nama,
                                  isSelected: selectedLokasiId == id,
                                  color: _SBC.primary,
                                  onTap: () => setInner(() {
                                    selectedLokasiId = id;
                                    selectedUnitId = null;
                                  }),
                                );
                              }),
                            ]),
                            const SizedBox(height: 16),

                            Text(_t('Unit', 'Unit', '单元'),
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _SBC.textSub)),
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              _FilterChipItem(
                                label: _t('All', 'Semua', '全部'),
                                isSelected: selectedUnitId == null,
                                color: _SBC.blue,
                                onTap: () => setInner(() => selectedUnitId = null),
                              ),
                              ...filteredUnit.map((unit) {
                                final id   = unit['id_unit']?.toString() ?? '';
                                final nama = unit['nama_unit']?.toString() ?? '';
                                return _FilterChipItem(
                                  label: nama,
                                  isSelected: selectedUnitId == id,
                                  color: _SBC.blue,
                                  onTap: () => setInner(() => selectedUnitId = id),
                                );
                              }),
                            ]),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),

                            if (_hasSchedule) ...[
                              Text(_t('Audit Status', 'Status Audit', '审计状态'),
                                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _SBC.textSub)),
                              const SizedBox(height: 8),
                              Wrap(spacing: 8, runSpacing: 8, children: [
                                _FilterChipItem(
                                  label: _t('All', 'Semua', '全部'),
                                  isSelected: selectedAuditStatus == null,
                                  color: _SBC.primary,
                                  onTap: () => setInner(() => selectedAuditStatus = null),
                                ),
                                _FilterChipItem(
                                  label: _t('Audited', 'Sudah Diaudit', '已审计'),
                                  isSelected: selectedAuditStatus == 'audited',
                                  color: _SBC.green,
                                  onTap: () => setInner(() => selectedAuditStatus = 'audited'),
                                ),
                                _FilterChipItem(
                                  label: _t('Not Audited', 'Belum Diaudit', '未审计'),
                                  isSelected: selectedAuditStatus == 'not_audited',
                                  color: _SBC.amber,
                                  onTap: () => setInner(() => selectedAuditStatus = 'not_audited'),
                                ),
                              ]),
                              const SizedBox(height: 16),
                            ],

                            Text(_t('Score Range', 'Rentang Nilai', '分数范围'),
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _SBC.textSub)),
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, runSpacing: 8, children: scoreRanges.map((range) {
                              final min = range['min'] as double?;
                              final max = range['max'] as double?;
                              final isSelected = selectedMinScore == min && selectedMaxScore == max;
                              Color chipColor = _SBC.primary;
                              if (min == 80.0) { chipColor = _SBC.green; }
                              else if (min == 60.0) { chipColor = _SBC.amber; }
                              else if (max == 59.9) { chipColor = _SBC.red; }
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

                        setState(() {
                          final hasFilter = selectedLokasiId != null ||
                              selectedUnitId != null ||
                              selectedAuditStatus != null ||
                              selectedMinScore != null ||
                              selectedMaxScore != null;
                          _filter = hasFilter
                              ? _SubunitHierarchyFilter(
                                  idLokasi:    selectedLokasiId,
                                  namaLokasi:  lokasiNama,
                                  idUnit:      selectedUnitId,
                                  namaUnit:    unitNama,
                                  auditStatus: selectedAuditStatus,
                                  minScore:    selectedMinScore,
                                  maxScore:    selectedMaxScore,
                                )
                              : null;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _SBC.primary,
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

  void _showDetail(_SubunitItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubunitDetailSheet(lang: widget.lang, item: item),
    );
  }

  Widget _buildInitial(String name) {
    final initials = name.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    return Container(
      width: 56, height: 56,
      color: _SBC.primaryLt,
      child: Center(
        child: Text(initials,
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700, color: _SBC.primary)),
      ),
    );
  }

  Widget _buildCard(_SubunitItem item) {
    final score = item.latestScore;
    final scoreColor = _scoreColor(score);
    return GestureDetector(
      onTap: () => _showDetail(item),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _SBC.divider, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
                                fontSize: 14, fontWeight: FontWeight.w700, color: _SBC.textMain),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (item.picName != null) ...[
                          const SizedBox(height: 3),
                          Row(children: [
                            const Icon(Icons.person_outline_rounded, size: 12, color: _SBC.textSub),
                            const SizedBox(width: 4),
                            Expanded(
                                child: Text(item.picName!,
                                    style: GoogleFonts.poppins(fontSize: 11, color: _SBC.textSub),
                                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ]),
                        ],
                        if (item.scheduleJenisAuditName != null) ...[
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _SBC.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _SBC.primary.withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.fact_check_rounded, size: 11, color: _SBC.primary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(item.scheduleJenisAuditName!,
                                      style: GoogleFonts.poppins(
                                          fontSize: 10, fontWeight: FontWeight.w600, color: _SBC.primary),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (item.schedulePeriode != null) ...[
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _SBC.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _SBC.blue.withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.event_rounded, size: 11, color: _SBC.blue),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(item.schedulePeriode!,
                                      style: GoogleFonts.poppins(
                                          fontSize: 10, fontWeight: FontWeight.w600, color: _SBC.blue),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: scoreColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: scoreColor.withValues(alpha: 0.4), width: 1),
                        ),
                        child: Text(
                          score != null ? '${score.toStringAsFixed(0)}%' : '-',
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w800, color: scoreColor),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(_scoreLabel(score),
                          style: GoogleFonts.poppins(
                              fontSize: 10, fontWeight: FontWeight.w600, color: scoreColor)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              decoration: BoxDecoration(
                color: _SBC.surface,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.scheduleAuditorName != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.assignment_ind_outlined, size: 12, color: _SBC.blue),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${_t('Auditor', 'Auditor', '审计员')}: ${item.scheduleAuditorName!}',
                            style: GoogleFonts.poppins(fontSize: 11, color: _SBC.blue),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                  ],
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: _SBC.textSub),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.latestAuditDate != null
                              ? '${_t('Last audit', 'Terakhir diaudit', '上次审计')}: ${_formatDate(item.latestAuditDate!)}'
                              : _t('Never audited', 'Belum pernah diaudit', '从未审计'),
                          style: GoogleFonts.poppins(fontSize: 11, color: _SBC.textSub),
                        ),
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(_t('No data found', 'Tidak ada data', '没有数据'),
              style: GoogleFonts.poppins(fontSize: 14, color: _SBC.textSub)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.toLowerCase();
    final filtered = _applyFilter(_data);
    final items = query.isEmpty
        ? filtered
        : filtered.where((i) => i.name.toLowerCase().contains(query)).toList();

    String? filterLabel;
    if (_filter != null) {
      final parts = <String>[
        if (_filter!.namaLokasi != null) _filter!.namaLokasi!,
        if (_filter!.namaUnit != null) _filter!.namaUnit!,
        if (_filter!.auditStatus == 'audited') _t('Audited', 'Sudah Diaudit', '已审计'),
        if (_filter!.auditStatus == 'not_audited') _t('Not Audited', 'Belum Diaudit', '未审计'),
        if (_filter!.minScore != null || _filter!.maxScore != null) ...[
          if (_filter!.minScore == 80.0 && _filter!.maxScore == null) '≥80%',
          if (_filter!.minScore == 60.0 && _filter!.maxScore == 79.9) '60-79%',
          if (_filter!.minScore == null && _filter!.maxScore == 59.9) '<60%',
        ],
      ];
      if (parts.isNotEmpty) filterLabel = parts.join(' · ');
    }

    return Material(
      type: MaterialType.transparency,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: GoogleFonts.poppins(fontSize: 14, color: _SBC.textMain),
                    decoration: InputDecoration(
                      hintText: _t('Search…', 'Cari…', '搜索…'),
                      hintStyle: GoogleFonts.poppins(fontSize: 13, color: _SBC.textSub),
                      prefixIcon: const Icon(Icons.search_rounded, color: _SBC.primary, size: 20),
                      filled: true,
                      fillColor: _SBC.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: _SBC.divider)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: _SBC.divider)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: _SBC.primary, width: 1.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _filter != null ? _SBC.primary : _SBC.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _filter != null ? _SBC.primary : _SBC.divider),
                    ),
                    child: Icon(
                      Icons.filter_list_rounded,
                      color: _filter != null ? Colors.white : _SBC.primary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (filterLabel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _SBC.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _SBC.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt_rounded, size: 14, color: _SBC.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(filterLabel,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: _SBC.primary, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _filter = null),
                      child: const Icon(Icons.close_rounded, size: 14, color: _SBC.primary),
                    ),
                  ],
                ),
              ),
            ),

          if (!_loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: _SubunitStatsRow(items: _data, lang: widget.lang),
            ),

          Expanded(
            child: _loading
                ? _buildShimmer()
                : items.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _fetchSubunits,
                        color: _SBC.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100, top: 4),
                          itemCount: items.length,
                          itemBuilder: (_, i) => _buildCard(items[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _SubunitStatsRow extends StatelessWidget {
  final List<_SubunitItem> items;
  final String lang;
  const _SubunitStatsRow({required this.items, required this.lang});

  String _t(String en, String id, String zh) {
    if (lang == 'EN') return en;
    if (lang == 'ZH') return zh;
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final audited = items.where((i) => i.latestScore != null).length;
    final avgScore = audited > 0
        ? items.where((i) => i.latestScore != null).map((i) => i.latestScore!).reduce((a, b) => a + b) / audited
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: _SubunitStatChip(label: _t('Total', 'Total', '总计'), value: '${items.length}', color: _SBC.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SubunitStatChip(label: _t('Audited', 'Diaudit', '已审计'), value: '$audited', color: _SBC.green),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SubunitStatChip(
              label: _t('Avg Score', 'Rata-rata', '平均分'),
              value: audited > 0 ? '${avgScore.toStringAsFixed(0)}%' : '-',
              color: _SBC.amber),
        ),
      ],
    );
  }
}

class _SubunitStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SubunitStatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.poppins(fontSize: 10, color: color.withValues(alpha: 0.8)),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _SubunitDetailSheet extends StatefulWidget {
  final String lang;
  final _SubunitItem item;
  const _SubunitDetailSheet({required this.lang, required this.item});

  @override
  State<_SubunitDetailSheet> createState() => _SubunitDetailSheetState();
}

class _SubunitDetailSheetState extends State<_SubunitDetailSheet> {
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
    if (score == null) return _SBC.textSub;
    if (score >= 80) return _SBC.green;
    if (score >= 60) return _SBC.amber;
    return _SBC.red;
  }

  Future<void> _fetchHistory() async {
    try {
      final rows = await _supabase
          .from('audit_result')
          .select(
              'id_result, nilai_audit, nilai_final, is_finalized, '
              'tanggal_audit, catatan_audit, selfie_url, created_at, '
              'Auditor:User!fk_audit_result_auditor(nama, gambar_user)')
          .eq('level_type', 'subunit')
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
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.item.name,
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _SBC.textMain)),
                  ),
                  if (widget.item.latestScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _scoreColor(widget.item.latestScore).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${widget.item.latestScore!.toStringAsFixed(0)}%',
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w800, color: _scoreColor(widget.item.latestScore))),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(_t('Riwayat Audit', 'Audit History', '审计历史'),
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _SBC.textMain)),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _SBC.primary))
                  : _history.isEmpty
                      ? Center(
                          child: Text(_t('Belum ada riwayat audit', 'No audit history', '无审计历史'),
                              style: GoogleFonts.poppins(fontSize: 13, color: _SBC.textSub)))
                      : ListView.separated(
                          controller: ctrl,
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: _history.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final row = _history[i];
                            final score = double.tryParse(row['nilai_audit']?.toString() ?? '');
                            final scoreFinal = double.tryParse(row['nilai_final']?.toString() ?? '');
                            final isFinalized = row['is_finalized'] == true;
                            final displayScore = isFinalized ? scoreFinal : score;
                            final auditorData = row['Auditor'] as Map<String, dynamic>?;
                            final auditor = auditorData?['nama']?.toString() ?? '-';
                            final date = row['tanggal_audit']?.toString() ?? '';
                            final color = _scoreColor(displayScore);
                            final idResult = row['id_result']?.toString() ?? '';

                            return GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AuditResultDetailScreen(
                                      lang: widget.lang,
                                      idResult: idResult,
                                      locationName: widget.item.name,
                                      levelType: 'subunit',
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: color.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 52, height: 52,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              displayScore != null ? '${displayScore.toStringAsFixed(0)}%' : '-',
                                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800, color: color),
                                            ),
                                            if (isFinalized)
                                              Text(_t('Final', 'Final', '最终'),
                                                  style: GoogleFonts.poppins(fontSize: 8, color: color)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(auditor,
                                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _SBC.textMain)),
                                          Text(date, style: GoogleFonts.poppins(fontSize: 11, color: _SBC.textSub)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _SBC.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: _SBC.primary.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.open_in_new_rounded, size: 12, color: _SBC.primary),
                                          const SizedBox(width: 4),
                                          Text(_t('Detail', 'Detail', '详情'),
                                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: _SBC.primary)),
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
            color: isSelected ? Colors.white : _SBC.textSub,
          ),
        ),
      ),
    );
  }
}