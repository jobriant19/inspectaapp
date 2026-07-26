import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../audit_result_detail_screen.dart';

class _SBC {
  static const filterAccent   = Color(0xFF1D72F3);
  static const locationAccent = Color(0xFF10B981);
  static const unitAccent     = Color(0xFF6366F1);
  static const subunitAccent  = Color(0xFFFBBF24);

  static const primary    = Color(0xFF8B5CF6);
  static const green      = Color(0xFF10B981);
  static const amber      = Color(0xFFF59E0B);
  static const red        = Color(0xFFEF4444);
  static const blue       = Color(0xFF0EA5E9);
  static const textMain   = Color(0xFF1D72F3);
  static const textSub    = Color(0xFF64748B);
  static const divider    = Color(0xFFE2E8F0);
  static const surface    = Color(0xFFF8FAFC);
}

class _SubunitItem {
  final String id;
  final String name;
  final String? description;
  final String? descriptionEn;
  final String? descriptionZh;
  final String? imageUrl;
  String? schedulePeriode;
  String? scheduleAuditorName;
  String? scheduleAuditorImage;
  String? scheduleJenisAuditName;
  double? latestScore;
  String? latestAuditDate;
  String? picName;
  String? picImage;
  final String? idUnit;
  final String? idLokasi;
  bool latestIsFinalized;
  double? latestFinalScore;

  _SubunitItem({
    required this.id,
    required this.name,
    this.description,
    this.descriptionEn,
    this.descriptionZh,
    this.imageUrl,
    this.schedulePeriode,
    this.scheduleAuditorName,
    this.scheduleAuditorImage,
    this.scheduleJenisAuditName,
    this.latestScore,
    this.latestAuditDate,
    this.picName,
    this.picImage,
    this.idUnit,
    this.idLokasi,
    this.latestIsFinalized = false,
    this.latestFinalScore,
  });

  String? descriptionFor(String lang) {
    if (lang == 'EN') {
      return (descriptionEn != null && descriptionEn!.isNotEmpty) ? descriptionEn : description;
    }
    if (lang == 'ZH') {
      return (descriptionZh != null && descriptionZh!.isNotEmpty) ? descriptionZh : description;
    }
    return description;
  }
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

class _AuditSubunitScreenState extends State<AuditSubunitScreen>
    with AutomaticKeepAliveClientMixin {
  final _supabase = Supabase.instance.client;

  @override
  bool get wantKeepAlive => true;

  List<_SubunitItem> _data = [];
  bool _loading = true;
  String _search = '';
  final TextEditingController _searchCtrl = TextEditingController();
  _SubunitHierarchyFilter? _filter;
  bool _hasSchedule = false;
  bool _isFilterSheetOpen = false;
  bool _isLocationPickerOpen = false;
  bool _isUnitPickerOpen = false;

  int _currentPage = 1;
  static const int _itemsPerPage = 5;

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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSubunits() async {
    setState(() => _loading = true);
    try {
      final rows = await _supabase
          .from('subunit')
          .select(
              'id_subunit, nama_subunit, gambar_subunit, deskripsi_subunit, '
              'deskripsi_subunit_en, deskripsi_subunit_zh, id_pic, id_unit, id_lokasi')
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
                .select('id_ref, nilai_audit, nilai_final, is_finalized, tanggal_audit')
                .eq('level_type', 'subunit')
                .inFilter('id_ref', ids)
                .order('tanggal_audit', ascending: false)
            : Future.value(<dynamic>[]),
        picIds.isNotEmpty
            ? _supabase
                .from('User')
                .select('id_user, nama, gambar_user')
                .inFilter('id_user', picIds)
            : Future.value(<dynamic>[]),
      ]);

      final Map<String, Map<String, dynamic>> auditMap = {};
      for (final a in futures[0]) {
        final ref = a['id_ref'].toString();
        if (!auditMap.containsKey(ref)) auditMap[ref] = a as Map<String, dynamic>;
      }

      final Map<String, String> picMap = {};
      final Map<String, String?> picImageMap = {};
      for (final p in futures[1]) {
        picMap[p['id_user'].toString()] = p['nama'] ?? '-';
        picImageMap[p['id_user'].toString()] = p['gambar_user']?.toString();
      }

      final scheduleRows = ids.isNotEmpty
          ? await _supabase
              .from('audit_schedule')
              .select(
                  'id_ref, periode_mulai, periode_selesai, id_jenis_audit, '
                  'User_Auditor:User!fk_audit_schedule_auditor(nama, gambar_user), '
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
        String? scheduleAuditorImage;
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
          scheduleAuditorImage = auditorData?['gambar_user']?.toString();

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
          descriptionEn: r['deskripsi_subunit_en']?.toString(),
          descriptionZh: r['deskripsi_subunit_zh']?.toString(),
          imageUrl: r['gambar_subunit']?.toString(),
          latestScore: audit != null
              ? double.tryParse(audit['nilai_audit']?.toString() ?? '')
              : null,
          latestAuditDate: audit?['tanggal_audit']?.toString(),
          picName: r['id_pic'] != null ? picMap[r['id_pic'].toString()] : null,
          picImage: r['id_pic'] != null ? picImageMap[r['id_pic'].toString()] : null,
          idUnit: r['id_unit']?.toString(),
          idLokasi: r['id_lokasi']?.toString(),
          latestIsFinalized: audit?['is_finalized'] == true,
          latestFinalScore: audit != null
              ? double.tryParse(audit['nilai_final']?.toString() ?? '')
              : null,
          schedulePeriode: schedulePeriode,
          scheduleAuditorName: scheduleAuditorName,
          scheduleAuditorImage: scheduleAuditorImage,
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

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('dd MMM yyyy').format(dt);
  }

  String? _lokasiIdForItem(_SubunitItem item) {
    if (item.idLokasi != null && item.idLokasi!.isNotEmpty) return item.idLokasi;
    final unit = _allUnit.firstWhere(
      (u) => u['id_unit']?.toString() == item.idUnit,
      orElse: () => {},
    );
    return unit['id_lokasi']?.toString();
  }

  List<_SubunitItem> _applyFilter(List<_SubunitItem> items) {
    final filter = _filter;
    if (filter == null) return items;
    List<_SubunitItem> result = items;

    if (filter.idUnit != null) {
      result = result.where((i) => i.idUnit == filter.idUnit).toList();
    } else if (filter.idLokasi != null) {
      result = result.where((i) => _lokasiIdForItem(i) == filter.idLokasi).toList();
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

  Future<void> _showLocationPickerDialog(
    BuildContext parentCtx,
    String? currentId,
    void Function(String? id, String? name) onSelected,
  ) async {
    if (_isLocationPickerOpen) return;
    _isLocationPickerOpen = true;
    String searchQuery = '';
    await showDialog(
      context: parentCtx,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setPickerState) {
          final filteredLokasi = searchQuery.isEmpty
              ? _allLokasi
              : _allLokasi
                  .where((l) => (l['nama_lokasi']?.toString() ?? '')
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()))
                  .toList();

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(ctx).size.height * 0.50,
                maxHeight: MediaQuery.of(ctx).size.height * 0.50,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: _SBC.locationAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.location_city_rounded, color: _SBC.locationAccent, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _t('Select Location', 'Pilih Lokasi', '选择位置'),
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _SBC.locationAccent),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        onChanged: (v) => setPickerState(() => searchQuery = v),
                        style: GoogleFonts.poppins(fontSize: 13, color: _SBC.textMain),
                        decoration: InputDecoration(
                          hintText: _t('Search location…', 'Cari lokasi…', '搜索位置…'),
                          hintStyle: GoogleFonts.poppins(fontSize: 12, color: _SBC.textSub),
                          prefixIcon: const Icon(Icons.search_rounded, color: _SBC.locationAccent, size: 18),
                          filled: true,
                          fillColor: _SBC.surface,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: _SBC.divider)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: _SBC.divider)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: _SBC.locationAccent, width: 1.5)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        children: [
                          _PickerTile(
                            name: _t('All Locations', 'Semua Lokasi', '所有位置'),
                            icon: Icons.apps_rounded,
                            color: _SBC.locationAccent,
                            isSelected: currentId == null,
                            onTap: () {
                              onSelected(null, null);
                              Navigator.pop(ctx);
                            },
                          ),
                          const SizedBox(height: 8),
                          ...filteredLokasi.map((l) {
                            final id   = l['id_lokasi']?.toString() ?? '';
                            final name = l['nama_lokasi']?.toString() ?? '-';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _PickerTile(
                                name: name,
                                icon: Icons.location_city_rounded,
                                color: _SBC.locationAccent,
                                isSelected: currentId == id,
                                onTap: () {
                                  onSelected(id, name);
                                  Navigator.pop(ctx);
                                },
                              ),
                            );
                          }),
                          if (filteredLokasi.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: [
                                  Image.asset(
                                    'assets/images/team_illustration.png',
                                    height: 120,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 96,
                                      height: 96,
                                      decoration: BoxDecoration(
                                        color: _SBC.locationAccent.withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.location_off_rounded,
                                          size: 42, color: _SBC.locationAccent.withValues(alpha: 0.4)),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    _t('No Location Found', 'Lokasi Tidak Ditemukan', '未找到位置'),
                                    style: GoogleFonts.poppins(
                                        fontSize: 13.5, fontWeight: FontWeight.w700, color: _SBC.locationAccent),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _t(
                                        'Try a different keyword to find the location you\'re looking for.',
                                        'Coba kata kunci lain untuk menemukan lokasi yang Anda cari.',
                                        '尝试使用其他关键词查找您需要的位置。'),
                                    style: GoogleFonts.poppins(fontSize: 11.5, color: _SBC.textSub, height: 1.4),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    _isLocationPickerOpen = false;
  }

  Future<void> _showUnitPickerDialog(
    BuildContext parentCtx,
    List<Map<String, dynamic>> unitList,
    String? currentId,
    void Function(String? id, String? name) onSelected,
  ) async {
    if (_isUnitPickerOpen) return;
    _isUnitPickerOpen = true;
    String searchQuery = '';
    await showDialog(
      context: parentCtx,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setPickerState) {
          final filteredUnit = searchQuery.isEmpty
              ? unitList
              : unitList
                  .where((u) => (u['nama_unit']?.toString() ?? '')
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()))
                  .toList();

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(ctx).size.height * 0.50,
                maxHeight: MediaQuery.of(ctx).size.height * 0.50,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: _SBC.unitAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.business_rounded, color: _SBC.unitAccent, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _t('Select Unit', 'Pilih Unit', '选择单元'),
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _SBC.unitAccent),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        onChanged: (v) => setPickerState(() => searchQuery = v),
                        style: GoogleFonts.poppins(fontSize: 13, color: _SBC.textMain),
                        decoration: InputDecoration(
                          hintText: _t('Search unit…', 'Cari unit…', '搜索单元…'),
                          hintStyle: GoogleFonts.poppins(fontSize: 12, color: _SBC.textSub),
                          prefixIcon: const Icon(Icons.search_rounded, color: _SBC.unitAccent, size: 18),
                          filled: true,
                          fillColor: _SBC.surface,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: _SBC.divider)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: _SBC.divider)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: _SBC.unitAccent, width: 1.5)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        children: [
                          _PickerTile(
                            name: _t('All Units', 'Semua Unit', '所有单元'),
                            icon: Icons.apps_rounded,
                            color: _SBC.unitAccent,
                            isSelected: currentId == null,
                            onTap: () {
                              onSelected(null, null);
                              Navigator.pop(ctx);
                            },
                          ),
                          const SizedBox(height: 8),
                          ...filteredUnit.map((u) {
                            final id   = u['id_unit']?.toString() ?? '';
                            final name = u['nama_unit']?.toString() ?? '-';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _PickerTile(
                                name: name,
                                icon: Icons.business_rounded,
                                color: _SBC.unitAccent,
                                isSelected: currentId == id,
                                onTap: () {
                                  onSelected(id, name);
                                  Navigator.pop(ctx);
                                },
                              ),
                            );
                          }),
                          if (filteredUnit.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: [
                                  Image.asset(
                                    'assets/images/team_illustration.png',
                                    height: 120,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 96,
                                      height: 96,
                                      decoration: BoxDecoration(
                                        color: _SBC.unitAccent.withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.business_rounded,
                                          size: 42, color: _SBC.unitAccent.withValues(alpha: 0.4)),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    _t('No Unit Found', 'Unit Tidak Ditemukan', '未找到单元'),
                                    style: GoogleFonts.poppins(
                                        fontSize: 13.5, fontWeight: FontWeight.w700, color: _SBC.unitAccent),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _t(
                                        'Try a different keyword to find the unit you\'re looking for.',
                                        'Coba kata kunci lain untuk menemukan unit yang Anda cari.',
                                        '尝试使用其他关键词查找您需要的单元。'),
                                    style: GoogleFonts.poppins(fontSize: 11.5, color: _SBC.textSub, height: 1.4),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    _isUnitPickerOpen = false;
  }

  Future<void> _showFilterSheet() async {
    if (_isFilterSheetOpen) return;
    _isFilterSheetOpen = true;
    await _loadFilterData();
    if (!mounted) {
      _isFilterSheetOpen = false;
      return;
    }

    final current = _filter;

    String? selectedLokasiId = current?.idLokasi;
    String? selectedLokasiName = current?.namaLokasi;
    String? selectedUnitId = current?.idUnit;
    String? selectedUnitName = current?.namaUnit;
    String? selectedAuditStatus = current?.auditStatus;
    double? selectedMinScore = current?.minScore;
    double? selectedMaxScore = current?.maxScore;

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final scoreRanges = [
            {'label': _t('All Scores', 'Semua Nilai', '所有分数'), 'min': null, 'max': null},
            {'label': '≥ 80% (${_t('Good', 'Baik', '良好')})', 'min': 80.0, 'max': null},
            {'label': '60–79% (${_t('Fair', 'Cukup', '一般')})', 'min': 60.0, 'max': 79.9},
            {'label': '< 60% (${_t('Poor', 'Kurang', '较差')})', 'min': null, 'max': 59.9},
          ];

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: _SBC.filterAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.filter_alt_rounded, color: _SBC.filterAccent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _t('Filter', 'Filter', '筛选'),
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _SBC.filterAccent),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            selectedLokasiId = null;
                            selectedLokasiName = null;
                            selectedUnitId = null;
                            selectedUnitName = null;
                            selectedAuditStatus = null;
                            selectedMinScore = null;
                            selectedMaxScore = null;
                          });
                        },
                        child: Text(_t('Reset', 'Reset', '重置'),
                            style: GoogleFonts.poppins(color: _SBC.red, fontWeight: FontWeight.w600, fontSize: 12.5)),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: StatefulBuilder(
                      builder: (ctx2, setInner) {
                        final filteredUnitForPicker = selectedLokasiId == null
                            ? _allUnit
                            : _allUnit.where((u) => u['id_lokasi']?.toString() == selectedLokasiId).toList();

                        Widget scoreChip(Map<String, dynamic> range) {
                          final min = range['min'] as double?;
                          final max = range['max'] as double?;
                          final isSelected = selectedMinScore == min && selectedMaxScore == max;
                          Color chipColor = _SBC.filterAccent;
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
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LOCATION SELECT
                            Row(
                              children: [
                                Icon(Icons.location_city_rounded, size: 14, color: _SBC.locationAccent),
                                const SizedBox(width: 6),
                                Text(_t('Location', 'Lokasi', '位置'),
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _SBC.locationAccent)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _showLocationPickerDialog(ctx2, selectedLokasiId, (id, name) {
                                setInner(() {
                                  selectedLokasiId = id;
                                  selectedLokasiName = name;
                                  if (selectedUnitId != null) {
                                    final stillValid = _allUnit.any((u) =>
                                        u['id_unit']?.toString() == selectedUnitId &&
                                        (id == null || u['id_lokasi']?.toString() == id));
                                    if (!stillValid) {
                                      selectedUnitId = null;
                                      selectedUnitName = null;
                                    }
                                  }
                                });
                              }),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedLokasiId != null ? _SBC.locationAccent.withValues(alpha: 0.08) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedLokasiId != null ? _SBC.locationAccent : Colors.grey.shade300,
                                    width: selectedLokasiId != null ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.apartment_rounded, size: 16,
                                        color: selectedLokasiId != null ? _SBC.locationAccent : _SBC.textSub),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        selectedLokasiName ?? _t('All Locations', 'Semua Lokasi', '所有位置'),
                                        style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: selectedLokasiId != null ? _SBC.locationAccent : _SBC.textMain),
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded, size: 18,
                                        color: selectedLokasiId != null ? _SBC.locationAccent : _SBC.textSub),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // UNIT SELECT
                            Row(
                              children: [
                                Icon(Icons.business_rounded, size: 14, color: _SBC.unitAccent),
                                const SizedBox(width: 6),
                                Text(_t('Unit', 'Unit', '单元'),
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _SBC.unitAccent)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _showUnitPickerDialog(ctx2, filteredUnitForPicker, selectedUnitId, (id, name) {
                                setInner(() {
                                  selectedUnitId = id;
                                  selectedUnitName = name;
                                });
                              }),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedUnitId != null ? _SBC.unitAccent.withValues(alpha: 0.08) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedUnitId != null ? _SBC.unitAccent : Colors.grey.shade300,
                                    width: selectedUnitId != null ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.business_rounded, size: 16,
                                        color: selectedUnitId != null ? _SBC.unitAccent : _SBC.textSub),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        selectedUnitName ?? _t('All Units', 'Semua Unit', '所有单元'),
                                        style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: selectedUnitId != null ? _SBC.unitAccent : _SBC.textMain),
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded, size: 18,
                                        color: selectedUnitId != null ? _SBC.unitAccent : _SBC.textSub),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),

                            if (_hasSchedule) ...[
                              Row(
                                children: [
                                  Icon(Icons.fact_check_rounded, size: 14, color: _SBC.textSub),
                                  const SizedBox(width: 6),
                                  Text(_t('Audit Status', 'Status Audit', '审计状态'),
                                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _SBC.textSub)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _FilterChipItem(
                                      label: _t('All', 'Semua', '全部'),
                                      isSelected: selectedAuditStatus == null,
                                      color: _SBC.filterAccent,
                                      onTap: () => setInner(() => selectedAuditStatus = null),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _FilterChipItem(
                                      label: _t('Audited', 'Sudah Diaudit', '已审计'),
                                      isSelected: selectedAuditStatus == 'audited',
                                      color: _SBC.green,
                                      onTap: () => setInner(() => selectedAuditStatus = 'audited'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _FilterChipItem(
                                      label: _t('Not Audited', 'Belum Diaudit', '未审计'),
                                      isSelected: selectedAuditStatus == 'not_audited',
                                      color: _SBC.amber,
                                      onTap: () => setInner(() => selectedAuditStatus = 'not_audited'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],

                            Row(
                              children: [
                                Icon(Icons.leaderboard_rounded, size: 14, color: _SBC.textSub),
                                const SizedBox(width: 6),
                                Text(_t('Score Range', 'Rentang Nilai', '分数范围'),
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _SBC.textSub)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: scoreChip(scoreRanges[0])),
                                const SizedBox(width: 8),
                                Expanded(child: scoreChip(scoreRanges[1])),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: scoreChip(scoreRanges[2])),
                                const SizedBox(width: 8),
                                Expanded(child: scoreChip(scoreRanges[3])),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          final hasFilter = selectedLokasiId != null ||
                              selectedUnitId != null ||
                              selectedAuditStatus != null ||
                              selectedMinScore != null ||
                              selectedMaxScore != null;
                          _filter = hasFilter
                              ? _SubunitHierarchyFilter(
                                  idLokasi:    selectedLokasiId,
                                  namaLokasi:  selectedLokasiName,
                                  idUnit:      selectedUnitId,
                                  namaUnit:    selectedUnitName,
                                  auditStatus: selectedAuditStatus,
                                  minScore:    selectedMinScore,
                                  maxScore:    selectedMaxScore,
                                )
                              : null;
                          _currentPage = 1;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _SBC.filterAccent,
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
              ),
            ),
          );
        },
      ),
    );
    _isFilterSheetOpen = false;
  }

  void _showDetail(_SubunitItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SubunitDetailSheet(lang: widget.lang, item: item),
      ),
    );
  }

  Widget _buildInitial(String name) {
    return Container(
      color: _SBC.subunitAccent.withValues(alpha: 0.12),
      child: Center(
        child: Icon(Icons.layers_rounded, color: _SBC.subunitAccent, size: 28),
      ),
    );
  }

  Widget _buildCard(_SubunitItem item) {
    final rawScore = item.latestScore;
    final isFinalized = item.latestIsFinalized;
    final needsFix = rawScore != null && !isFinalized && rawScore < 100;
    final displayScore = isFinalized ? (item.latestFinalScore ?? rawScore) : rawScore;
    final scoreColor = isFinalized ? _SBC.amber : _scoreColor(rawScore);
    final hasPic = item.picName != null && item.picName!.isNotEmpty;
    final hasSchedulePeriode = item.schedulePeriode != null && item.schedulePeriode!.isNotEmpty;
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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                            ? Image.network(item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildInitial(item.name))
                            : _buildInitial(item.name),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(item.name,
                                  style: GoogleFonts.poppins(
                                      fontSize: 15, fontWeight: FontWeight.w700, color: _SBC.subunitAccent),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor: hasPic
                                        ? _SBC.subunitAccent.withValues(alpha: 0.15)
                                        : _SBC.textSub.withValues(alpha: 0.12),
                                    backgroundImage: (item.picImage != null && item.picImage!.isNotEmpty)
                                        ? NetworkImage(item.picImage!)
                                        : null,
                                    child: (item.picImage == null || item.picImage!.isEmpty)
                                        ? Icon(
                                            hasPic ? Icons.person_rounded : Icons.person_off_rounded,
                                            size: 12,
                                            color: hasPic ? _SBC.subunitAccent : _SBC.textSub,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      hasPic
                                          ? item.picName!
                                          : _t('No PIC assigned', 'Belum ada PIC', '暂无负责人'),
                                      style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          fontStyle: hasPic ? FontStyle.normal : FontStyle.italic,
                                          color: hasPic ? Colors.black87 : _SBC.textSub),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    hasSchedulePeriode ? Icons.event_rounded : Icons.event_busy_rounded,
                                    size: 13,
                                    color: hasSchedulePeriode ? _SBC.blue : _SBC.textSub,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      hasSchedulePeriode
                                          ? item.schedulePeriode!
                                          : _t('Not scheduled', 'Belum dijadwalkan', '未安排'),
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          fontStyle: hasSchedulePeriode ? FontStyle.normal : FontStyle.italic,
                                          color: hasSchedulePeriode ? _SBC.blue : _SBC.textSub),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Align(
                          alignment: Alignment.center,
                          child: needsFix
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _SBC.amber.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _SBC.amber.withValues(alpha: 0.4), width: 1),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.build_rounded, size: 14, color: _SBC.amber),
                                      const SizedBox(height: 2),
                                      Text(_t('Needs Fix', 'Perlu Perbaikan', '需要修复'),
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                              fontSize: 8, fontWeight: FontWeight.w700, color: _SBC.amber)),
                                    ],
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: scoreColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: scoreColor.withValues(alpha: 0.4), width: 1),
                                  ),
                                  child: Text(
                                    displayScore != null ? '${displayScore.toStringAsFixed(0)}%' : '-',
                                    style: GoogleFonts.poppins(
                                        fontSize: 14, fontWeight: FontWeight.w800, color: scoreColor),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  decoration: BoxDecoration(
                    color: _SBC.surface,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_t('Auditor', 'Auditor', '审计员'),
                                style: GoogleFonts.poppins(
                                    fontSize: 9.5, fontWeight: FontWeight.w600, color: _SBC.textSub)),
                            const SizedBox(height: 4),
                            if (item.scheduleAuditorName != null)
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor: _SBC.blue.withValues(alpha: 0.15),
                                    backgroundImage: (item.scheduleAuditorImage != null &&
                                            item.scheduleAuditorImage!.isNotEmpty)
                                        ? NetworkImage(item.scheduleAuditorImage!)
                                        : null,
                                    child: (item.scheduleAuditorImage == null ||
                                            item.scheduleAuditorImage!.isEmpty)
                                        ? const Icon(Icons.person_rounded, size: 11, color: _SBC.blue)
                                        : null,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(item.scheduleAuditorName!,
                                        style: GoogleFonts.poppins(
                                            fontSize: 11, fontWeight: FontWeight.w600, color: _SBC.blue),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              )
                            else
                              Text('-',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11, fontWeight: FontWeight.w600, color: _SBC.textSub)),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 1,
                        height: 34,
                        color: _SBC.divider,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_t('Last Audited', 'Terakhir Diaudit', '上次审计'),
                                style: GoogleFonts.poppins(
                                    fontSize: 9.5, fontWeight: FontWeight.w600, color: _SBC.textSub)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 12, color: _SBC.textSub),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    item.latestAuditDate != null
                                        ? _formatDate(item.latestAuditDate!)
                                        : _t('Never audited', 'Belum pernah diaudit', '从未审计'),
                                    style: GoogleFonts.poppins(
                                        fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
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
              ],
            ),
            if (item.scheduleJenisAuditName != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _SBC.subunitAccent,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(15),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.fact_check_rounded, size: 11, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(item.scheduleJenisAuditName!,
                          style: GoogleFonts.poppins(
                              fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
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
    final bool isFiltering = _search.isNotEmpty || _filter != null;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              height: 170,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _SBC.subunitAccent.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.location_off_rounded, size: 56, color: _SBC.subunitAccent.withValues(alpha: 0.4)),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              isFiltering
                  ? _t('No matching subunits', 'Subunit Tidak Ditemukan', '未找到匹配子单元')
                  : _t('No subunits yet', 'Belum Ada Subunit', '暂无子单元'),
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _SBC.subunitAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isFiltering
                  ? _t(
                      'Try adjusting your search keyword or filter to find what you\'re looking for.',
                      'Coba ubah kata kunci pencarian atau filter untuk menemukan yang Anda cari.',
                      '尝试调整搜索关键词或筛选条件以查找您需要的内容。')
                  : _t(
                      'Subunits will show up here as soon as they\'re added to the system.',
                      'Subunit akan muncul di sini setelah ditambahkan ke sistem.',
                      '添加子单元后将显示在此处。'),
              style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: _SBC.textSub, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (isFiltering) ...[
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => setState(() {
                  _search = '';
                  _filter = null;
                  _currentPage = 1;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: _SBC.subunitAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _SBC.subunitAccent.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 15, color: _SBC.subunitAccent),
                      const SizedBox(width: 6),
                      Text(_t('Clear search & filter', 'Hapus pencarian & filter', '清除搜索与筛选'),
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _SBC.subunitAccent)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final query = _search.toLowerCase();
    final filtered = _applyFilter(_data);
    final items = query.isEmpty
        ? filtered
        : filtered.where((i) => i.name.toLowerCase().contains(query)).toList();

    final int totalPages = items.isEmpty ? 1 : (items.length / _itemsPerPage).ceil();
    if (_currentPage > totalPages) _currentPage = totalPages;
    if (_currentPage < 1) _currentPage = 1;
    final pageItems = items
        .skip((_currentPage - 1) * _itemsPerPage)
        .take(_itemsPerPage)
        .toList();

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
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() {
                      _search = v;
                      _currentPage = 1;
                    }),
                    style: GoogleFonts.poppins(fontSize: 14, color: _SBC.textMain),
                    decoration: InputDecoration(
                      hintText: _t('Search…', 'Cari…', '搜索…'),
                      hintStyle: GoogleFonts.poppins(fontSize: 13, color: _SBC.textSub),
                      prefixIcon: const Icon(Icons.search_rounded, color: _SBC.filterAccent, size: 20),
                      suffixIcon: _search.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                setState(() {
                                  _search = '';
                                  _currentPage = 1;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.all(10),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _SBC.red.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded,
                                    size: 14, color: _SBC.red),
                              ),
                            )
                          : null,
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
                          borderSide: const BorderSide(color: _SBC.filterAccent, width: 1.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _filter != null ? _SBC.filterAccent : _SBC.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _filter != null ? _SBC.filterAccent : _SBC.divider),
                    ),
                    child: Icon(
                      Icons.filter_list_rounded,
                      color: _filter != null ? Colors.white : _SBC.filterAccent,
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
                  color: _SBC.filterAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _SBC.filterAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt_rounded, size: 14, color: _SBC.filterAccent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(filterLabel,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: _SBC.filterAccent, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _filter = null;
                        _currentPage = 1;
                      }),
                      child: const Icon(Icons.close_rounded, size: 14, color: _SBC.filterAccent),
                    ),
                  ],
                ),
              ),
            ),

          Expanded(
            child: _loading
                ? _buildShimmer()
                : items.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _fetchSubunits,
                        color: _SBC.subunitAccent,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16, top: 4),
                          itemCount: pageItems.length,
                          itemBuilder: (_, i) => _buildCard(pageItems[i]),
                        ),
                      ),
          ),

          if (!_loading && items.isNotEmpty && totalPages > 1)
            _SubunitPageIndicator(
              currentPage: _currentPage,
              totalPages: totalPages,
              onPageChanged: (p) => setState(() => _currentPage = p),
            ),
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
  int _shimmerCount = 3;

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

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('dd MMMM yyyy').format(dt);
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
          _shimmerCount = _history.isNotEmpty ? _history.length : _shimmerCount;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _SBC.subunitAccent, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('Subunit Detail', 'Detail Subunit', '子单元详情'),
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _SBC.subunitAccent),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? Image.network(item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                                color: _SBC.subunitAccent.withValues(alpha: 0.12),
                                child: Icon(Icons.layers_rounded, color: _SBC.subunitAccent, size: 32),
                              ))
                      : Container(
                          color: _SBC.subunitAccent.withValues(alpha: 0.12),
                          child: Icon(Icons.layers_rounded, color: _SBC.subunitAccent, size: 32),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.w700, color: _SBC.subunitAccent),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (item.descriptionFor(widget.lang) != null && item.descriptionFor(widget.lang)!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(item.descriptionFor(widget.lang)!,
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w600, height: 1.4),
                          maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              if (item.latestScore != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _scoreColor(item.latestScore).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _scoreColor(item.latestScore).withValues(alpha: 0.4)),
                  ),
                  child: Text('${item.latestScore!.toStringAsFixed(0)}%',
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w800, color: _scoreColor(item.latestScore))),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.grey.shade100, thickness: 1.5),
          const SizedBox(height: 10),

          Row(
            children: [
              Icon(Icons.info_rounded, size: 15, color: _SBC.subunitAccent),
              const SizedBox(width: 6),
              Text(_t('Information', 'Informasi', '信息'),
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _SBC.subunitAccent)),
            ],
          ),
          const SizedBox(height: 8),

          _DetailInfoTile(
            icon: Icons.person_rounded,
            iconColor: _SBC.green,
            label: _t('Person in Charge', 'Penanggung Jawab', '负责人'),
            child: item.picName != null && item.picName!.isNotEmpty
                ? Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: _SBC.green.withValues(alpha: 0.15),
                        backgroundImage: (item.picImage != null && item.picImage!.isNotEmpty)
                            ? NetworkImage(item.picImage!)
                            : null,
                        child: (item.picImage == null || item.picImage!.isEmpty)
                            ? Icon(Icons.person_rounded, size: 13, color: _SBC.green)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item.picName!,
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  )
                : Text('-',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
          ),

          if (item.scheduleJenisAuditName != null)
            _DetailInfoTile(
              icon: Icons.fact_check_rounded,
              iconColor: _SBC.subunitAccent,
              label: _t('Audit Type', 'Tipe Audit', '审计类型'),
              child: Text(item.scheduleJenisAuditName!,
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
            ),

          if (item.schedulePeriode != null)
            _DetailInfoTile(
              icon: Icons.event_rounded,
              iconColor: _SBC.blue,
              label: _t('Audit Period', 'Periode Audit', '审计周期'),
              child: Text(item.schedulePeriode!,
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
            ),

          if (item.scheduleAuditorName != null)
            _DetailInfoTile(
              icon: Icons.assignment_ind_rounded,
              iconColor: _SBC.primary,
              label: _t('Scheduled Auditor', 'Auditor Terjadwal', '预定审计员'),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: _SBC.primary.withValues(alpha: 0.15),
                    backgroundImage: (item.scheduleAuditorImage != null &&
                            item.scheduleAuditorImage!.isNotEmpty)
                        ? NetworkImage(item.scheduleAuditorImage!)
                        : null,
                    child: (item.scheduleAuditorImage == null || item.scheduleAuditorImage!.isEmpty)
                        ? Icon(Icons.person_rounded, size: 13, color: _SBC.primary)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item.scheduleAuditorName!,
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 4),
          Divider(color: Colors.grey.shade100, thickness: 1.5),
          const SizedBox(height: 10),

          Row(
            children: [
              Icon(Icons.history_rounded, size: 15, color: _SBC.subunitAccent),
              const SizedBox(width: 6),
              Text(_t('Audit History', 'Riwayat Audit', '审计历史'),
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _SBC.subunitAccent)),
            ],
          ),
          const SizedBox(height: 10),

          if (_loading)
            Shimmer.fromColors(
              baseColor: Colors.grey.shade200,
              highlightColor: Colors.grey.shade50,
              child: Column(
                children: List.generate(_shimmerCount, (_) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  height: 106,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                )),
              ),
            )
          else if (_history.isEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _SBC.divider),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/team_illustration.png',
                    height: 140,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: _SBC.subunitAccent.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.history_toggle_off_rounded, size: 46, color: _SBC.subunitAccent.withValues(alpha: 0.4)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _t('No audit history yet', 'Belum Ada Riwayat Audit', '暂无审计历史'),
                    style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w700, color: _SBC.subunitAccent),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _t(
                        'This subunit hasn\'t been audited yet. Once an audit is completed, the results will appear here.',
                        'Subunit ini belum pernah diaudit. Hasil audit akan muncul di sini setelah selesai dilakukan.',
                        '该子单元尚未进行审计。审计完成后结果将显示在此处。'),
                    style: GoogleFonts.poppins(fontSize: 12, color: _SBC.textSub, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final row = _history[i];
                final score = double.tryParse(row['nilai_audit']?.toString() ?? '');
                final scoreFinal = double.tryParse(row['nilai_final']?.toString() ?? '');
                final isFinalized = row['is_finalized'] == true;
                final needsFix = score != null && !isFinalized && score < 100;
                final displayScore = isFinalized ? (scoreFinal ?? score) : score;
                final auditorData = row['Auditor'] as Map<String, dynamic>?;
                final auditor = auditorData?['nama']?.toString() ?? '-';
                final auditorImage = auditorData?['gambar_user']?.toString();
                final date = row['tanggal_audit']?.toString() ?? '';
                final formattedDate = date.isNotEmpty ? _formatDate(date) : '-';
                final color = isFinalized ? _SBC.amber : _scoreColor(score);
                final idResult = row['id_result']?.toString() ?? '';

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AuditResultDetailScreen(
                          lang: widget.lang,
                          idResult: idResult,
                          locationName: item.name,
                          levelType: 'subunit',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: needsFix
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.build_rounded, size: 16, color: _SBC.amber),
                                      const SizedBox(height: 2),
                                      Text(_t('Needs\nFix', 'Perlu\nPerbaikan', '需要\n修复'),
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                              fontSize: 7.5, fontWeight: FontWeight.w700, color: _SBC.amber)),
                                    ],
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        displayScore != null ? '${displayScore.toStringAsFixed(0)}%' : '-',
                                        style: GoogleFonts.poppins(
                                            fontSize: 13, fontWeight: FontWeight.w800, color: color),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person_rounded, size: 13, color: _SBC.blue),
                                  const SizedBox(width: 5),
                                  Text(_t('Auditor', 'Auditor', '审计员'),
                                      style: GoogleFonts.poppins(
                                          fontSize: 10.5, fontWeight: FontWeight.w700, color: _SBC.blue)),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 11,
                                    backgroundColor: _SBC.blue.withValues(alpha: 0.15),
                                    backgroundImage: (auditorImage != null && auditorImage.isNotEmpty)
                                        ? NetworkImage(auditorImage)
                                        : null,
                                    child: (auditorImage == null || auditorImage.isEmpty)
                                        ? Icon(Icons.person_rounded, size: 12, color: _SBC.blue)
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(auditor,
                                        style: GoogleFonts.poppins(
                                            fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.event_available_rounded, size: 13, color: _SBC.amber),
                                  const SizedBox(width: 5),
                                  Text(_t('Audited At', 'Diaudit Pada', '审计日期'),
                                      style: GoogleFonts.poppins(
                                          fontSize: 10.5, fontWeight: FontWeight.w700, color: _SBC.amber)),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(formattedDate,
                                  style: GoogleFonts.poppins(
                                      fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                            decoration: BoxDecoration(
                              color: _SBC.subunitAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _SBC.subunitAccent.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.open_in_new_rounded, size: 12, color: _SBC.subunitAccent),
                                const SizedBox(width: 4),
                                Text(_t('Detail', 'Detail', '详情'),
                                    style: GoogleFonts.poppins(
                                        fontSize: 11, fontWeight: FontWeight.w700, color: _SBC.subunitAccent)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _DetailInfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget child;
  final Color? labelColor;
  const _DetailInfoTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.child,
    // ignore: unused_element_parameter
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: labelColor ?? iconColor, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PickerTile({
    required this.name,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? color : _SBC.textSub),
            const SizedBox(width: 10),
            Expanded(
              child: Text(name,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? color : _SBC.textMain)),
            ),
            if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 18),
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
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : _SBC.textSub,
          ),
        ),
      ),
    );
  }
}

class _SubunitPageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const _SubunitPageIndicator({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  static const Color _mainColor = _SBC.subunitAccent;
  static const int _maxVisibleButtons = 5;

  List<int> _visiblePageNumbers() {
    if (totalPages <= _maxVisibleButtons) {
      return List.generate(totalPages, (i) => i + 1);
    }
    int start = currentPage - 2;
    int end = currentPage + 2;
    if (start < 1) {
      start = 1;
      end = _maxVisibleButtons;
    } else if (end > totalPages) {
      end = totalPages;
      start = totalPages - (_maxVisibleButtons - 1);
    }
    return List.generate(end - start + 1, (i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    final bool canPrev = currentPage > 1;
    final bool canNext = currentPage < totalPages;
    final pageNumbers = _visiblePageNumbers();

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Container(
        // Container solid putih menutupi seluruh area (termasuk celah
        // safe-area di bawah, baik gesture nav, 3-button nav, maupun device
        // tanpa navbar bawaan), supaya indikator selalu full visible.
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _mainColor.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: _mainColor.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildArrowButton(
                icon: Icons.arrow_back_ios_new_rounded,
                enabled: canPrev,
                onTap: () {
                  if (!canPrev) return;
                  onPageChanged(currentPage - 1);
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    for (final p in pageNumbers) ...[
                      Expanded(child: _buildPageNumberButton(p)),
                      if (p != pageNumbers.last) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _buildArrowButton(
                icon: Icons.arrow_forward_ios_rounded,
                enabled: canNext,
                onTap: () {
                  if (!canNext) return;
                  onPageChanged(currentPage + 1);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageNumberButton(int page) {
    final bool isActive = page == currentPage;
    return GestureDetector(
      onTap: () {
        if (page == currentPage) return;
        onPageChanged(page);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? _mainColor : _mainColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? null
              : Border.all(color: _mainColor.withValues(alpha: 0.25)),
        ),
        child: Text(
          '$page',
          style: GoogleFonts.poppins(
            color: isActive ? Colors.white : _mainColor,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: enabled ? _mainColor.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 15,
          color: enabled ? _mainColor : Colors.grey.shade400,
        ),
      ),
    );
  }
}