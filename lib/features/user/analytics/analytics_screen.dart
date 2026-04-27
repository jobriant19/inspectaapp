import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../finding/finding_detail_screen.dart'; // adjust path as needed

// ─── Warna & Tema ──────────────────────────────────────────────────────────
class _AppColors {
  static const primary = Color(0xFF0EA5E9);
  static const primaryDark = Color(0xFF0369A1);
  static const primaryLight = Color(0xFFE0F2FE);
  static const accent = Color(0xFF38BDF8);
  static const surface = Color(0xFFF0F9FF);
  static const cardBg = Colors.white;
  static const textPrimary = Color(0xFF0C4A6E);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFFBDBDBD);
  static const divider = Color(0xFFE0F2FE);
  static const selfHighlight = Color(0xFFFFF7ED);
  static const selfHighlightBorder = Color(0xFFFED7AA);
  static const chipSelected = Color(0xFF0369A1);
  static const chipUnselected = Colors.white;
  static const targetBlue = Color(0xFF0EA5E9);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
}

// ─── Model Data ──────────────────────────────────────────────────────────────
class MemberData {
  final String name;
  final String? unitName;
  final int findings;
  final int completed;
  final bool isSelf;
  final String? avatarUrl;
  final Color? avatarColor;

  const MemberData({
    required this.name,
    this.unitName,
    required this.findings,
    required this.completed,
    this.isSelf = false,
    this.avatarUrl,
    this.avatarColor,
  });
}

class InspectionData {
  final String name;
  final int findings;
  final bool isSelf;

  const InspectionData({
    required this.name,
    required this.findings,
    this.isSelf = false,
  });
}

class LocationData {
  final String name;
  final String pic;
  final String? value;

  const LocationData({
    required this.name,
    required this.pic,
    this.value,
  });
}

class RecurringTopic {
  final String topic;
  final String locationArea;
  final int total;
  final String? imageUrl;
  final List<Map<String, dynamic>> findings;

  const RecurringTopic({
    required this.topic,
    required this.locationArea,
    required this.total,
    this.imageUrl,
    required this.findings,
  });
}

// ─── Main Screen ──────────────────────────────────────────────────────────────
class AnalyticsScreen extends StatefulWidget {
  final String lang;
  const AnalyticsScreen({super.key, required this.lang});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient _supabase = Supabase.instance.client;

  final Map<String, Map<String, String>> _texts = {
    'ID': {
      'anggota': 'Anggota', 'inspeksi': 'Inspeksi', 'lokasi': 'Lokasi',
      'temuan_berulang': 'Temuan Berulang', 'memuat_data': 'Memuat data...',
      'diperbarui_pada': 'Terakhir diperbarui pada', 'semua_grup': 'Semua Penemu', 'semua_grup_anggota': 'Semua Grup',
      'gagal_muat_anggota': 'Gagal memuat data Anggota',
      'gagal_muat_inspeksi': 'Gagal memuat data Inspeksi',
      'gagal_muat_lokasi': 'Gagal memuat data Lokasi',
      'tidak_ada_data_anggota': 'Tidak ada data anggota.',
      'tidak_ada_temuan_role': 'Tidak ada temuan untuk role',
      'tidak_ada_data_level': 'Tidak ada data untuk level',
      'nama': 'Nama', 'temuan': 'Temuan', 'selesai': 'Selesai',
      'target_bulanan': 'Target Bulanan', 'saya': 'Saya', 'rank': 'Rank',
      'periode_audit': 'Periode audit: ', 'topik': 'Topik',
      'belum_memiliki_temuan': 'belum\nmemiliki temuan berulang',
      'eksekutif': 'Eksekutif', 'profesional': 'Profesional', 'visitor': 'Visitor',
      'level_lokasi': 'Lokasi', 'level_unit': 'Unit',
      'level_subunit': 'Subunit', 'level_area': 'Area',
      'pilih_bulan': 'Pilih Bulan', 'pilih_grup': 'Pilih Grup',
      'pilih_level': 'Pilih Level', 'pilih_lokasi': 'Pilih Lokasi',
      'pilih_periode': 'Pilih Periode', 'pilih_penemu': 'Pilih Penemu',
      'cari': 'Cari...', 'dari': 'Dari', 'sampai': 'Sampai',
      'terapkan': 'Terapkan', 'total': 'Total',
      'penemu': 'Penemu', 'periode': 'Periode',
      'daftar_temuan': 'Daftar Temuan', 'di_sekitar': 'Di sekitar',
    },
    'EN': {
      'anggota': 'Members', 'inspeksi': 'Inspection', 'lokasi': 'Location',
      'temuan_berulang': 'Recurring Findings', 'memuat_data': 'Loading data...',
      'diperbarui_pada': 'Last updated at', 'semua_grup': 'All Finders', 'semua_grup_anggota': 'All Groups',
      'gagal_muat_anggota': 'Failed to load Member data',
      'gagal_muat_inspeksi': 'Failed to load Inspection data',
      'gagal_muat_lokasi': 'Failed to load Location data',
      'tidak_ada_data_anggota': 'No member data available.',
      'tidak_ada_temuan_role': 'No findings for role',
      'tidak_ada_data_level': 'No data for level',
      'nama': 'Name', 'temuan': 'Findings', 'selesai': 'Completed',
      'target_bulanan': 'Monthly Target', 'saya': 'Me', 'rank': 'Rank',
      'periode_audit': 'Audit period: ', 'topik': 'Topic',
      'belum_memiliki_temuan': 'does not have\nrecurring findings yet',
      'eksekutif': 'Executive', 'profesional': 'Professional', 'visitor': 'Visitor',
      'level_lokasi': 'Location', 'level_unit': 'Unit',
      'level_subunit': 'Sub-unit', 'level_area': 'Area',
      'pilih_bulan': 'Select Month', 'pilih_grup': 'Select Group',
      'pilih_level': 'Select Level', 'pilih_lokasi': 'Select Location',
      'pilih_periode': 'Select Period', 'pilih_penemu': 'Select Finder',
      'cari': 'Search...', 'dari': 'From', 'sampai': 'To',
      'terapkan': 'Apply', 'total': 'Total',
      'penemu': 'Finder', 'periode': 'Period',
      'daftar_temuan': 'Finding List', 'di_sekitar': 'Around',
    },
    'ZH': {
      'anggota': '成员', 'inspeksi': '检查', 'lokasi': '位置',
      'temuan_berulang': '重复发现', 'memuat_data': '加载数据...',
      'diperbarui_pada': '最后更新于', 'semua_grup': '所有发现者', 'semua_grup_anggota': '所有组',
      'gagal_muat_anggota': '加载成员数据失败',
      'gagal_muat_inspeksi': '加载检查数据失败',
      'gagal_muat_lokasi': '加载位置数据失败',
      'tidak_ada_data_anggota': '没有成员数据。',
      'tidak_ada_temuan_role': '没有角色的发现',
      'tidak_ada_data_level': '没有级别的数据',
      'nama': '名称', 'temuan': '发现', 'selesai': '已完成',
      'target_bulanan': '每月目标', 'saya': '我', 'rank': '排名',
      'periode_audit': '审计期间: ', 'topik': '话题',
      'belum_memiliki_temuan': '还没有\n重复的发现',
      'eksekutif': '行政', 'profesional': '专业', 'visitor': '访客',
      'level_lokasi': '位置', 'level_unit': '单元',
      'level_subunit': '子单元', 'level_area': '区域',
      'pilih_bulan': '选择月份', 'pilih_grup': '选择组',
      'pilih_level': '选择级别', 'pilih_lokasi': '选择位置',
      'pilih_periode': '选择期间', 'pilih_penemu': '选择发现者',
      'cari': '搜索...', 'dari': '从', 'sampai': '到',
      'terapkan': '应用', 'total': '总计',
      'penemu': '发现者', 'periode': '期间',
      'daftar_temuan': '发现列表', 'di_sekitar': '周围',
    },
  };

  String getTxt(String key) => _texts[widget.lang]?[key] ?? key;

  // ─── State untuk Filter ──────────────────────────────────────────────────
  int _selectedMonthIndex = DateTime.now().month - 1;
  String? _selectedUnitId;
  String _selectedInspectionRole = 'Eksekutif';
  String _selectedLocationLevel = 'Lokasi';
  DateTime? _lastUpdated;

  // Recurring findings filter
  DateTime _recurringFrom = DateTime(DateTime.now().year - 1, DateTime.now().month);
  DateTime _recurringTo = DateTime.now();
  String? _recurringUserId;
  String _recurringUserName = '';

  // ─── State untuk Data ────────────────────────────────────────────────────
  Future<List<MemberData>>? _anggotaFuture;
  Future<List<InspectionData>>? _inspeksiFuture;
  Future<List<LocationData>>? _lokasiFuture;
  Future<List<RecurringTopic>>? _recurringFuture;

  List<Map<String, dynamic>> _unitList = [];
  int _targetAnggota = 30;
  int _targetInspeksi = 2;

  late List<String> _translatedMonths;
  late List<String> _translatedRoles;
  late List<String> _translatedLocationLevels;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initLocaleDependentLists();
    _fetchUnits().then((_) => _fetchAllData());
    _fetchTarget();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initLocaleDependentLists();
  }

  void _initLocaleDependentLists() {
    final locale = widget.lang == 'ID' ? 'id_ID' : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');
    _translatedMonths = List.generate(12, (i) =>
        DateFormat.MMM(locale).format(DateTime(2000, i + 1)));

    final rolesBackend = ['Eksekutif', 'Profesional', 'Visitor'];
    _translatedRoles = [getTxt('eksekutif'), getTxt('profesional'), getTxt('visitor')];
    final selectedRoleIndex = rolesBackend.indexOf(_selectedInspectionRole);
    if (selectedRoleIndex != -1) _selectedInspectionRole = _translatedRoles[selectedRoleIndex];

    final locationLevelsBackend = ['Lokasi', 'Unit', 'Subunit', 'Area'];
    _translatedLocationLevels = [
      getTxt('level_lokasi'), getTxt('level_unit'),
      getTxt('level_subunit'), getTxt('level_area'),
    ];
    final selectedLevelIndex = locationLevelsBackend.indexOf(_selectedLocationLevel);
    if (selectedLevelIndex != -1) _selectedLocationLevel = _translatedLocationLevels[selectedLevelIndex];
  }

  Future<void> _fetchUnits() async {
    try {
      final response = await _supabase.from('unit').select('id_unit, nama_unit');
      if (mounted) setState(() => _unitList = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint('Error fetching units: $e');
    }
  }

  Future<void> _fetchTarget() async {
    try {
      final month = _selectedMonthIndex + 1;
      final year = DateTime.now().year;
      final data = await _supabase
          .from('target_bulanan')
          .select()
          .eq('bulan', month)
          .eq('tahun', year)
          .maybeSingle();
      if (mounted && data != null) {
        setState(() {
          _targetAnggota = data['target_anggota'] ?? 30;
          _targetInspeksi = data['target_inspeksi'] ?? 2;
        });
      }
    } catch (e) {
      debugPrint('Error fetching target: $e');
    }
  }

  int get _selectedMonth => _selectedMonthIndex + 1;

  void _fetchAllData() {
    final roleBackendValue = ['Eksekutif', 'Profesional', 'Visitor'][_translatedRoles.indexOf(_selectedInspectionRole)];
    final levelBackendValue = ['Lokasi', 'Unit', 'Subunit', 'Area'][_translatedLocationLevels.indexOf(_selectedLocationLevel)];
    setState(() {
      _lastUpdated = DateTime.now();
      final month = _selectedMonth;
      final year = DateTime.now().year;
      _anggotaFuture = _fetchAnggotaData(month, year, _selectedUnitId);
      _inspeksiFuture = _fetchInspeksiData(month, year, roleBackendValue);
      _lokasiFuture = _fetchLokasiData(month, year, levelBackendValue);
    });
  }

  void _fetchRecurring() {
    setState(() {
      _recurringFuture = _fetchRecurringData();
    });
  }

  Future<List<MemberData>> _fetchAnggotaData(int month, int year, String? unitId) async {
    try {
      final List<dynamic> response = await _supabase.rpc('get_anggota_stats', params: {
        'selected_month': month, 'selected_year': year, 'selected_unit_id': unitId
      });
      return response.map((item) => MemberData(
        name: item['nama'] as String,
        unitName: item['unit_nama'] as String?,
        findings: item['temuan'] as int,
        completed: item['selesai'] as int,
        isSelf: item['user_id'] == _supabase.auth.currentUser?.id,
        avatarUrl: item['avatar_url'] as String?,
        avatarColor: const Color(0xFF0EA5E9),
      )).toList();
    } catch (e) {
      debugPrint('Error fetching Anggota: $e');
      return [];
    }
  }

  Future<List<InspectionData>> _fetchInspeksiData(int month, int year, String role) async {
    try {
      final List<dynamic> response = await _supabase.rpc('get_inspeksi_stats', params: {
        'selected_month': month, 'selected_year': year, 'role_type': role.toLowerCase(),
      });
      return response.map((item) => InspectionData(
        name: item['nama'] as String,
        findings: item['temuan'] as int,
      )).toList();
    } catch (e) {
      debugPrint('Error fetching Inspeksi: $e');
      return [];
    }
  }

  Future<List<LocationData>> _fetchLokasiData(int month, int year, String level) async {
    try {
      final List<dynamic> response = await _supabase.rpc('get_lokasi_stats', params: {
        'selected_month': month, 'selected_year': year, 'level_name': level.toLowerCase(),
      });
      return response.map((item) => LocationData(
        name: item['nama_item'] as String,
        pic: item['nama_pic'] as String,
        value: (item['nilai_temuan'] as int).toString(),
      )).toList();
    } catch (e) {
      debugPrint('Error fetching Lokasi: $e');
      return [];
    }
  }

  Future<List<RecurringTopic>> _fetchRecurringData() async {
    try {
      // Fetch findings from temuan table grouped by judul_temuan (similar topics)
      var query = _supabase
          .from('temuan')
          .select('''
            id_temuan, judul_temuan, gambar_temuan, created_at, status_temuan,
            poin_temuan, target_waktu_selesai, jenis_temuan,
            id_lokasi, id_unit, id_subunit, id_area, id_penanggung_jawab,
            lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area),
            kategoritemuan(nama_kategoritemuan),
            is_pro, is_visitor, is_eksekutif,
            penyelesaian!temuan_id_penyelesaian_fkey(*, User_Solver:User!id_user(nama, gambar_user)),
            User_Creator:User!id_user(nama, gambar_user),
            User_PIC:id_penanggung_jawab(nama, gambar_user),
            subkategoritemuan:id_subkategoritemuan_uuid(id_subkategoritemuan, nama_subkategoritemuan)
          ''')
          .gte('created_at', _recurringFrom.toIso8601String())
          .lte('created_at', DateTime(_recurringTo.year, _recurringTo.month + 1, 0, 23, 59, 59).toIso8601String());

      if (_recurringUserId != null) {
        query = query.eq('id_user', _recurringUserId!);
      }

      final List<dynamic> response = await query.order('created_at', ascending: false);
      final findings = List<Map<String, dynamic>>.from(response);

      // Group by similar judul_temuan (normalize)
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final f in findings) {
        final key = (f['judul_temuan'] as String).trim().toLowerCase();
        grouped.putIfAbsent(key, () => []).add(f);
      }

      // Only recurring (count >= 2)
      final List<RecurringTopic> result = [];
      grouped.forEach((key, items) {
        if (items.length >= 2) {
          final first = items.first;
          String location = '';
          if (first['area'] != null) location = first['area']['nama_area'] ?? '';
          else if (first['subunit'] != null) location = first['subunit']['nama_subunit'] ?? '';
          else if (first['unit'] != null) location = first['unit']['nama_unit'] ?? '';
          else if (first['lokasi'] != null) location = first['lokasi']['nama_lokasi'] ?? '';

          result.add(RecurringTopic(
            topic: first['judul_temuan'] as String,
            locationArea: location,
            total: items.length,
            imageUrl: first['gambar_temuan'] as String?,
            findings: items,
          ));
        }
      });

      result.sort((a, b) => b.total.compareTo(a.total));
      return result;
    } catch (e) {
      debugPrint('Error fetching Recurring: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _lastUpdatedText {
    if (_lastUpdated == null) return getTxt('memuat_data');
    final formattedDate = DateFormat('d MMM yyyy HH:mm',
        widget.lang == 'ID' ? 'id_ID' : 'en_US').format(_lastUpdated!);
    return '${getTxt('diperbarui_pada')} $formattedDate (GMT+7)';
  }

  // ─── Shimmer Helpers ──────────────────────────────────────────────────────
  Widget _buildShimmerBox({double? width, required double height, bool isCircle = false, double borderRadius = 8}) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCircle ? height / 2 : borderRadius),
      ),
    );
  }

  Widget _buildAnggotaShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!,
      child: ListView.separated(
        padding: EdgeInsets.zero, itemCount: 10,
        separatorBuilder: (_, __) => Divider(height: 1, color: _AppColors.divider, indent: 16),
        itemBuilder: (_, __) => Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(children: [
            Expanded(flex: 3, child: Row(children: [
              _buildShimmerBox(height: 34, width: 34, isCircle: true),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildShimmerBox(height: 14, width: 120),
                const SizedBox(height: 4),
                _buildShimmerBox(height: 12, width: 80),
              ])),
            ])),
            Expanded(flex: 1, child: Center(child: _buildShimmerBox(height: 14, width: 20))),
            Expanded(flex: 1, child: Center(child: _buildShimmerBox(height: 14, width: 20))),
          ]),
        ),
      ),
    );
  }

  Widget _buildInspeksiShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!,
      child: ListView.separated(
        padding: EdgeInsets.zero, itemCount: 10,
        separatorBuilder: (_, __) => Divider(height: 1, color: _AppColors.divider, indent: 16),
        itemBuilder: (_, __) => Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Expanded(flex: 3, child: Row(children: [
              _buildShimmerBox(height: 34, width: 34, isCircle: true),
              const SizedBox(width: 10),
              Expanded(child: _buildShimmerBox(height: 14)),
            ])),
            Expanded(flex: 1, child: Center(child: _buildShimmerBox(height: 14, width: 20))),
          ]),
        ),
      ),
    );
  }

  Widget _buildLokasiShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!,
      child: ListView.separated(
        padding: EdgeInsets.zero, itemCount: 8,
        separatorBuilder: (_, __) => Divider(height: 1, color: _AppColors.divider, indent: 16),
        itemBuilder: (_, __) => Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            SizedBox(width: 40, child: Center(child: _buildShimmerBox(height: 14, width: 20))),
            Expanded(flex: 3, child: Row(children: [
              _buildShimmerBox(height: 38, width: 38, borderRadius: 10),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildShimmerBox(height: 14, width: double.infinity),
                const SizedBox(height: 4),
                _buildShimmerBox(height: 12, width: 100),
              ])),
            ])),
            SizedBox(width: 50, child: Center(child: _buildShimmerBox(height: 14, width: 20))),
          ]),
        ),
      ),
    );
  }

  // ─── Filter Popup Helpers ─────────────────────────────────────────────────

  /// Generic popup with search + list
  Future<T?> _showSearchPopup<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required String Function(T) labelOf,
    required T? selected,
  }) {
    final ctrl = TextEditingController();
    List<T> filtered = List.from(items);
    return showDialog<T>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _AppColors.primaryLight, width: 1.5),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
                decoration: BoxDecoration(
                  color: _AppColors.primaryLight,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(children: [
                  Icon(Icons.tune_rounded, color: _AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(title, style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15, color: _AppColors.textPrimary))),
                  IconButton(icon: const Icon(Icons.close, size: 18, color: _AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
                ]),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: TextField(
                  controller: ctrl,
                  onChanged: (q) {
                    setSt(() {
                      filtered = items.where((e) =>
                          labelOf(e).toLowerCase().contains(q.toLowerCase())).toList();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: getTxt('cari'),
                    hintStyle: const TextStyle(fontSize: 13, color: _AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search, color: _AppColors.primary, size: 18),
                    filled: true, fillColor: _AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: _AppColors.primaryLight)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: _AppColors.primaryLight)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: _AppColors.primary, width: 1.5)),
                  ),
                ),
              ),
              // List
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    final lbl = labelOf(item);
                    final isSel = item == selected || lbl == (selected != null ? labelOf(selected!) : null);
                    return InkWell(
                      onTap: () => Navigator.pop(ctx, item),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSel ? _AppColors.primaryLight : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSel ? _AppColors.primary : _AppColors.divider, width: 1),
                        ),
                        child: Row(children: [
                          Expanded(child: Text(lbl, style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel ? _AppColors.primary : _AppColors.textPrimary,
                          ))),
                          if (isSel) const Icon(Icons.check_circle_rounded, color: _AppColors.primary, size: 16),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // Month picker popup
  void _showMonthPicker(VoidCallback onChanged) async {
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
                maxWidth: 320,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _AppColors.primaryLight, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                    decoration: BoxDecoration(
                      color: _AppColors.primaryLight,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_month_rounded, color: _AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(getTxt('pilih_bulan'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _AppColors.textPrimary))),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: _AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                      ),
                    ]),
                  ),
                  // Grid 4 baris x 3 kolom
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: 12,
                      itemBuilder: (_, i) {
                        final isSelected = i == _selectedMonthIndex;
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() => _selectedMonthIndex = i);
                            _fetchTarget().then((_) => onChanged());
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: isSelected ? _AppColors.primary : _AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? _AppColors.primary : _AppColors.divider,
                                width: isSelected ? 1.5 : 1,
                              ),
                              boxShadow: isSelected ? [BoxShadow(
                                color: _AppColors.primary.withOpacity(0.3),
                                blurRadius: 6, offset: const Offset(0, 2),
                              )] : [],
                            ),
                            child: Center(
                              child: Text(
                                _translatedMonths[i],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : _AppColors.textPrimary,
                                ),
                              ),
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
        },
      ),
    );
  }

  // Group picker popup
  void _showGroupPicker() async {
    final allItem = {'id_unit': null, 'nama_unit': getTxt('semua_grup_anggota')};
    final items = [allItem, ..._unitList];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          final ctrl = TextEditingController();
          List<Map<String, dynamic>> filtered = List.from(items);

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _AppColors.primaryLight, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                    decoration: BoxDecoration(
                      color: _AppColors.primaryLight,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.group_rounded, color: _AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(getTxt('pilih_grup'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _AppColors.textPrimary))),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: _AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                      ),
                    ]),
                  ),
                  // Search
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    child: StatefulBuilder(
                      builder: (_, setInner) => TextField(
                        controller: ctrl,
                        onChanged: (q) {
                          setInner(() {
                            filtered = items.where((e) =>
                              (e['nama_unit'] as String).toLowerCase().contains(q.toLowerCase())
                            ).toList();
                          });
                          setSt(() {});
                        },
                        decoration: InputDecoration(
                          hintText: getTxt('cari'),
                          hintStyle: const TextStyle(fontSize: 13, color: _AppColors.textMuted),
                          prefixIcon: const Icon(Icons.search, color: _AppColors.primary, size: 18),
                          filled: true, fillColor: _AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: _AppColors.divider)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: _AppColors.divider)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: _AppColors.primary, width: 1.5)),
                        ),
                      ),
                    ),
                  ),
                  // List
                  Flexible(
                    child: StatefulBuilder(
                      builder: (_, __) => ListView.builder(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final item = filtered[i];
                          final lbl = item['nama_unit'] as String;
                          final id = item['id_unit']?.toString();
                          final isSelected = id == _selectedUnitId ||
                            (id == null && _selectedUnitId == null);
                          return InkWell(
                            onTap: () {
                              Navigator.pop(ctx);
                              setState(() => _selectedUnitId = id);
                              _fetchAllData();
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? _AppColors.primaryLight : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? _AppColors.primary : _AppColors.divider,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: isSelected ? _AppColors.primary : _AppColors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(child: Text(
                                    lbl.isNotEmpty ? lbl[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 15,
                                      color: isSelected ? Colors.white : _AppColors.primary,
                                    ),
                                  )),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(lbl, style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? _AppColors.primary : _AppColors.textPrimary,
                                ))),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded,
                                    color: _AppColors.primary, size: 18),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Inspection role picker popup
  void _showRolePicker() async {
    final result = await _showSearchPopup<String>(
      context: context,
      title: getTxt('eksekutif') + ' / ' + getTxt('profesional') + ' / ' + getTxt('visitor'),
      items: _translatedRoles,
      labelOf: (e) => e,
      selected: _selectedInspectionRole,
    );
    if (result != null && mounted) {
      setState(() => _selectedInspectionRole = result);
      _fetchAllData();
    }
  }

  // Location level picker popup
  void _showLevelPicker() async {
    final result = await _showSearchPopup<String>(
      context: context,
      title: getTxt('pilih_level'),
      items: _translatedLocationLevels,
      labelOf: (e) => e,
      selected: _selectedLocationLevel,
    );
    if (result != null && mounted) {
      setState(() => _selectedLocationLevel = result);
      _fetchAllData();
    }
  }

  // Location picker (using FullLocationPickerBottomSheet style but as popup)
  void _showLocationPickerForFilter() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AnalyticsLocationPickerSheet(lang: widget.lang),
    );
    if (result != null && mounted) {
      // apply location filter
      setState(() {
        _selectedLocationLevel = _translatedLocationLevels[result['level'] as int];
      });
      _fetchAllData();
    }
  }

  // Recurring period picker
  void _showPeriodPicker() async {
    DateTime tempFrom = _recurringFrom;
    DateTime tempTo = _recurringTo;
    final locale = widget.lang == 'ID' ? 'id_ID' : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _AppColors.primaryLight, width: 1.5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.date_range_rounded, color: _AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(getTxt('pilih_periode'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _AppColors.textPrimary))),
              IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
            ]),
            const SizedBox(height: 16),
            // From
            Text(getTxt('dari'), style: const TextStyle(fontSize: 12, color: _AppColors.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _buildYearMonthPicker(tempFrom, locale, (d) => setSt(() => tempFrom = d)),
            const SizedBox(height: 14),
            // To
            Text(getTxt('sampai'), style: const TextStyle(fontSize: 12, color: _AppColors.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _buildYearMonthPicker(tempTo, locale, (d) => setSt(() => tempTo = d)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() { _recurringFrom = tempFrom; _recurringTo = tempTo; });
                  Navigator.pop(ctx);
                  _fetchRecurring();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(getTxt('terapkan')),
              ),
            ),
          ]),
        ),
      )),
    );
  }

  Widget _buildYearMonthPicker(DateTime current, String locale, ValueChanged<DateTime> onChange) {
    final months = List.generate(12, (i) => DateFormat.MMM(locale).format(DateTime(2000, i + 1)));
    final years = List.generate(5, (i) => DateTime.now().year - 2 + i);
    return Row(children: [
      // Month
      Expanded(
        flex: 3,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _AppColors.surface, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _AppColors.primaryLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: current.month - 1,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: _AppColors.primary),
              style: const TextStyle(fontSize: 13, color: _AppColors.textPrimary, fontWeight: FontWeight.w600),
              dropdownColor: Colors.white,
              items: List.generate(12, (i) => DropdownMenuItem(value: i, child: Text(months[i]))),
              onChanged: (v) { if (v != null) onChange(DateTime(current.year, v + 1)); },
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      // Year
      Expanded(
        flex: 2,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _AppColors.surface, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _AppColors.primaryLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: current.year,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: _AppColors.primary),
              style: const TextStyle(fontSize: 13, color: _AppColors.textPrimary, fontWeight: FontWeight.w600),
              dropdownColor: Colors.white,
              items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
              onChanged: (v) { if (v != null) onChange(DateTime(v, current.month)); },
            ),
          ),
        ),
      ),
    ]);
  }

  // Recurring user picker
  void _showUserPicker() async {
    try {
      final response = await _supabase
          .from('User')
          .select('id_user, nama, gambar_user, jabatan!User_id_jabatan_fkey(nama_jabatan)')
          .order('nama');
      final users = List<Map<String, dynamic>>.from(response);
      final allItem = {'id_user': null, 'nama': getTxt('pilih_penemu'), 'gambar_user': null, 'jabatan': null};
      final items = [allItem, ...users];
      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSt) {
            final ctrl = TextEditingController();
            List<Map<String, dynamic>> filtered = List.from(items);

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _AppColors.primaryLight, width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                      decoration: BoxDecoration(
                        color: _AppColors.primaryLight,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.person_search_rounded, color: _AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(getTxt('pilih_penemu'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _AppColors.textPrimary))),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: _AppColors.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                          padding: EdgeInsets.zero,
                        ),
                      ]),
                    ),
                    // Search
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                      child: StatefulBuilder(
                        builder: (_, setInner) => TextField(
                          controller: ctrl,
                          onChanged: (q) {
                            setInner(() {
                              filtered = items.where((e) =>
                                (e['nama'] as String).toLowerCase().contains(q.toLowerCase())
                              ).toList();
                            });
                            setSt(() {});
                          },
                          decoration: InputDecoration(
                            hintText: getTxt('cari'),
                            hintStyle: const TextStyle(fontSize: 13, color: _AppColors.textMuted),
                            prefixIcon: const Icon(Icons.search, color: _AppColors.primary, size: 18),
                            filled: true, fillColor: _AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: _AppColors.divider)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: _AppColors.divider)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: _AppColors.primary, width: 1.5)),
                          ),
                        ),
                      ),
                    ),
                    // Count label
                    Padding(
                      padding: const EdgeInsets.only(left: 14, bottom: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('${filtered.length} ${widget.lang == 'ID' ? 'penemu' : widget.lang == 'ZH' ? '发现者' : 'finders'}',
                          style: const TextStyle(fontSize: 11, color: _AppColors.textSecondary)),
                      ),
                    ),
                    // List
                    Flexible(
                      child: StatefulBuilder(
                        builder: (_, __) => ListView.builder(
                          padding: const EdgeInsets.only(bottom: 12),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final item = filtered[i];
                            final name = item['nama'] as String;
                            final id = item['id_user']?.toString();
                            final avatarUrl = item['gambar_user'] as String?;
                            final role = (item['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'] as String?;
                            final isSelected = id == _recurringUserId ||
                              (id == null && _recurringUserId == null);
                            final isAll = id == null;

                            return InkWell(
                              onTap: () {
                                Navigator.pop(ctx);
                                setState(() {
                                  _recurringUserId = id;
                                  _recurringUserName = isAll
                                      ? (widget.lang == 'ID' ? 'Semua Penemu' : widget.lang == 'ZH' ? '所有发现者' : 'All Finders')
                                      : name;
                                });
                                _fetchRecurring();
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? _AppColors.primaryLight : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? _AppColors.primary : _AppColors.divider,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(children: [
                                  // Avatar
                                  if (isAll)
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(
                                        color: isSelected ? _AppColors.primary : _AppColors.surface,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: _AppColors.primaryLight)),
                                      child: Icon(Icons.group_rounded,
                                        color: isSelected ? Colors.white : _AppColors.primary, size: 20),
                                    )
                                  else if (avatarUrl != null && avatarUrl.isNotEmpty)
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: NetworkImage(avatarUrl),
                                      onBackgroundImageError: (_, __) {},
                                      backgroundColor: _AppColors.primaryLight,
                                    )
                                  else
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: isSelected ? _AppColors.primary : _AppColors.primaryLight,
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 15,
                                          color: isSelected ? Colors.white : _AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(isAll
                                          ? (widget.lang == 'ID' ? 'Semua Penemu' : widget.lang == 'ZH' ? '所有发现者' : 'All Finders')
                                          : name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? _AppColors.primary : _AppColors.textPrimary,
                                        )),
                                      if (role != null && role.isNotEmpty)
                                        Text(role, style: const TextStyle(
                                          fontSize: 11, color: _AppColors.textSecondary)),
                                    ],
                                  )),
                                  if (isSelected)
                                    const Icon(Icons.check_circle_rounded,
                                      color: _AppColors.primary, size: 18),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } catch (e) {
      debugPrint('Error fetching users: $e');
    }
  }

  // ─── Filter Button Widget ─────────────────────────────────────────────────
  Widget _buildFilterButton({
    required String label,
    required VoidCallback onTap,
    IconData icon = Icons.keyboard_arrow_down_rounded,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _AppColors.primary, width: 1.2),
          boxShadow: [BoxShadow(color: _AppColors.primary.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(child: Text(label, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: _AppColors.textPrimary),
            overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 4),
          Icon(icon, color: _AppColors.primary, size: 18),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        _buildTabBar(),
        Expanded(child: TabBarView(
          controller: _tabController,
          children: [
            _buildAnggotaTab(),
            _buildInspeksiTab(),
            _buildLokasiTab(),
            _buildTemuanBerulangTab(),
          ],
        )),
      ]),
    );
  }

  // ── Tab Bar ────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
  final tabs = [getTxt('anggota'), getTxt('inspeksi'), getTxt('lokasi'), getTxt('temuan_berulang')];
  return Container(
    color: Colors.transparent,
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
    child: TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      indicator: BoxDecoration(
        color: _AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      labelColor: Colors.white,
      unselectedLabelColor: _AppColors.primary,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
      dividerColor: Colors.transparent,
      // Background putih untuk tab tidak aktif
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      tabs: tabs.map((t) => Tab(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent, // dihandle oleh indicator & unselected style
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(t),
        ),
      )).toList(),
    ),
  );
}

  Widget _buildLastUpdatedTextWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(_lastUpdatedText,
        style: const TextStyle(fontSize: 11, color: _AppColors.textSecondary, height: 1.4)),
    );
  }

  // ── Anggota Tab ────────────────────────────────────────────────────────────
  Widget _buildAnggotaTab() {
    return Column(children: [
      // Filter row — proportional width
      Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          _buildFilterButton(
            label: _translatedMonths[_selectedMonthIndex],
            onTap: () => _showMonthPicker(_fetchAllData),
          ),
          const SizedBox(width: 10),
          Expanded(child: _buildFilterButton(
            label: _selectedUnitId == null
                ? getTxt('semua_grup_anggota')
                : (_unitList.firstWhere(
                    (u) => u['id_unit'].toString() == _selectedUnitId,
                    orElse: () => {'nama_unit': getTxt('semua_grup')})['nama_unit'] as String),
            onTap: _showGroupPicker,
          )),
        ]),
      ),
      _buildLastUpdatedTextWidget(),
      Expanded(child: FutureBuilder<List<MemberData>>(
        future: _anggotaFuture,
        builder: (context, snapshot) {
          if (_anggotaFuture == null || snapshot.connectionState == ConnectionState.waiting) {
            return _buildAnggotaShimmer();
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(getTxt('tidak_ada_data_anggota')));
          }
          final memberList = snapshot.data!;
          final self = memberList.firstWhere(
            (m) => m.isSelf,
            orElse: () => MemberData(name: getTxt('saya'), findings: 0, completed: 0, isSelf: true),
          );
          return Column(children: [
            _buildTableHeader(
              [getTxt('nama'), getTxt('temuan'), getTxt('selesai')],
              flex: [3, 1, 1],
            ),
            _buildTargetRow([getTxt('target_bulanan'), '$_targetAnggota', '$_targetAnggota']),
            Expanded(child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: memberList.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: _AppColors.divider, indent: 16),
              itemBuilder: (_, i) => _buildMemberRow(memberList[i]),
            )),
            _buildSelfPinnedRow(self),
          ]);
        },
      )),
    ]);
  }

  // ── Inspeksi Tab ───────────────────────────────────────────────────────────
  Widget _buildInspeksiTab() {
    // Mapping warna per role (konsisten dengan explore_screen filter)
    const Map<String, Color> roleColors = {
      'Eksekutif': Color(0xFFEF4444),
      'Executive': Color(0xFFEF4444),
      '行政': Color(0xFFEF4444),
      'Profesional': Color(0xFFF59E0B),
      'Professional': Color(0xFFF59E0B),
      '专业': Color(0xFFF59E0B),
      'Visitor': Color(0xFF3B82F6),
      '访客': Color(0xFF3B82F6),
    };

    return Column(children: [
      Container(
        color: Colors.transparent,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          _buildFilterButton(
            label: _translatedMonths[_selectedMonthIndex],
            onTap: () => _showMonthPicker(_fetchAllData),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: _translatedRoles.map((r) {
                final isSelected = _selectedInspectionRole == r;
                final activeColor = roleColors[r] ?? _AppColors.primary;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: r != _translatedRoles.last ? 6 : 0,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedInspectionRole = r);
                        _fetchAllData();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 38,
                        decoration: BoxDecoration(
                          color: isSelected ? activeColor : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? activeColor : _AppColors.divider,
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(
                                  color: activeColor.withOpacity(0.28),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            r,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : _AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ]),
      ),
      _buildLastUpdatedTextWidget(),
      _buildTableHeader([getTxt('nama'), getTxt('temuan')], flex: [3, 1]),
      _buildTargetRow([getTxt('target_bulanan'), '$_targetInspeksi']),
      Expanded(child: FutureBuilder<List<InspectionData>>(
        future: _inspeksiFuture,
        builder: (context, snapshot) {
          if (_inspeksiFuture == null || snapshot.connectionState == ConnectionState.waiting) {
            return _buildInspeksiShimmer();
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('${getTxt('tidak_ada_temuan_role')} "$_selectedInspectionRole".'));
          }
          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: snapshot.data!.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: _AppColors.divider, indent: 16),
            itemBuilder: (_, i) => _buildInspectionRow(snapshot.data![i]),
          );
        },
      )),
    ]);
  }

  // ── Lokasi Tab ─────────────────────────────────────────────────────────────
  Widget _buildLokasiTab() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          _buildFilterButton(
            label: _translatedMonths[_selectedMonthIndex],
            onTap: () => _showMonthPicker(_fetchAllData),
          ),
          const SizedBox(width: 10),
          Expanded(child: _buildFilterButton(
            label: _selectedLocationLevel,
            onTap: _showLevelPicker,
          )),
        ]),
      ),
      _buildAuditPeriodBanner(),
      _buildLastUpdatedTextWidget(),
      _buildTableHeader([getTxt('rank'), getTxt('lokasi'), getTxt('temuan')], flex: [1, 3, 1], isLocation: true),
      Expanded(child: FutureBuilder<List<LocationData>>(
        future: _lokasiFuture,
        builder: (context, snapshot) {
          if (_lokasiFuture == null || snapshot.connectionState == ConnectionState.waiting) {
            return _buildLokasiShimmer();
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('${getTxt('tidak_ada_data_level')} "$_selectedLocationLevel".'));
          }
          final locationList = snapshot.data!;
          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: locationList.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: _AppColors.divider, indent: 16),
            itemBuilder: (_, i) => _buildLocationRow(i + 1, locationList[i]),
          );
        },
      )),
    ]);
  }

  // ── Temuan Berulang Tab ────────────────────────────────────────────────────
  Widget _buildTemuanBerulangTab() {
    final locale = widget.lang == 'ID' ? 'id_ID' : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');
    final fromLabel = DateFormat('MMM yyyy', locale).format(_recurringFrom);
    final toLabel = DateFormat('MMM yyyy', locale).format(_recurringTo);
    final periodLabel = '$fromLabel - $toLabel';

    // Lazy init
    if (_recurringFuture == null) {
      _recurringFuture = _fetchRecurringData();
    }

    return Column(children: [
      Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          Expanded(child: _buildFilterButton(
            label: periodLabel,
            onTap: _showPeriodPicker,
            icon: Icons.calendar_month_rounded,
          )),
          const SizedBox(width: 10),
          Expanded(child: _buildFilterButton(
            label: _recurringUserName.isEmpty ? getTxt('semua_grup') : _recurringUserName,
            onTap: _showUserPicker,
          )),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Align(alignment: Alignment.centerLeft,
          child: Text(getTxt('topik'), style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: _AppColors.textPrimary))),
      ),
      const Divider(height: 1, color: _AppColors.divider),
      Expanded(child: FutureBuilder<List<RecurringTopic>>(
        future: _recurringFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _AppColors.primary));
          }
          final topics = snapshot.data ?? [];
          if (topics.isEmpty) {
            final name = _recurringUserName.isEmpty ? '' : _recurringUserName;
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 72, height: 72,
                  decoration: BoxDecoration(color: _AppColors.primaryLight, shape: BoxShape.circle),
                  child: Icon(Icons.search_off_rounded, size: 36, color: _AppColors.primary.withOpacity(0.5))),
                const SizedBox(height: 16),
                Text(
                  name.isEmpty ? getTxt('tidak_ada_data_anggota')
                      : '$name ${getTxt('belum_memiliki_temuan')}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: _AppColors.textSecondary, height: 1.5)),
              ],
            ));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: topics.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) => _buildRecurringTopicCard(topics[i]),
          );
        },
      )),
    ]);
  }

  Widget _buildRecurringTopicCard(RecurringTopic topic) {
    return GestureDetector(
      onTap: () => _showRecurringDetail(topic),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _AppColors.primaryLight, width: 1.5),
          boxShadow: [BoxShadow(color: _AppColors.primary.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            child: Container(
              width: 80, height: 80,
              color: _AppColors.primaryLight,
              child: topic.imageUrl != null && topic.imageUrl!.isNotEmpty
                  ? Image.network(topic.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: _AppColors.textMuted))
                  : const Icon(Icons.image_outlined, color: _AppColors.textMuted, size: 32),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(topic.topic,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _AppColors.textPrimary),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_rounded, size: 13, color: _AppColors.primary),
                const SizedBox(width: 3),
                Expanded(child: Text('${getTxt('di_sekitar')} ${topic.locationArea}',
                  style: const TextStyle(fontSize: 12, color: _AppColors.textSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ]),
          )),
          // Total badge
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _AppColors.primaryLight, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(getTxt('total'), style: const TextStyle(fontSize: 9, color: _AppColors.textSecondary)),
              Text('${topic.total}', style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900, color: _AppColors.primary)),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showRecurringDetail(RecurringTopic topic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(topic.topic, style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: _AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.location_on_rounded, size: 13, color: _AppColors.primary),
                    const SizedBox(width: 3),
                    Text('${getTxt('di_sekitar')} ${topic.locationArea}',
                      style: const TextStyle(fontSize: 12, color: _AppColors.textSecondary)),
                  ]),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                  child: Text('${getTxt('total')}: ${topic.total}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: _AppColors.primary)),
                ),
              ]),
            ),
            const Divider(height: 1, color: _AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Align(alignment: Alignment.centerLeft,
                child: Text('${getTxt('daftar_temuan')} (${topic.total})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _AppColors.textPrimary))),
            ),
            Expanded(child: ListView.separated(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: topic.findings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final data = topic.findings[i];
                return _buildRecurringFindingCard(data);
              },
            )),
          ]),
        ),
      ),
    );
  }

  Widget _buildRecurringFindingCard(Map<String, dynamic> data) {
    final imageUrl = (data['gambar_temuan'] ?? '').toString();
    final title = (data['judul_temuan'] ?? '-').toString();
    final status = (data['status_temuan'] ?? '').toString();
    final s = status.toLowerCase();
    final isFinished = ['selesai', 'done', 'completed', 'closed'].any((e) => s.contains(e));
    final isPro = data['is_pro'] == true;
    final isVisitor = data['is_visitor'] == true;
    final isEksekutif = data['is_eksekutif'] == true;
    final poin = int.tryParse((data['poin_temuan'] ?? 0).toString()) ?? 0;
    final isKts = (data['jenis_temuan'] ?? '') == 'KTS Production';

    final tanggal = () {
      final v = data['created_at'];
      if (v == null) return '-';
      final dt = v is DateTime ? v : DateTime.tryParse(v.toString());
      if (dt == null) return '-';
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }();

    String location = '';
    if (data['area'] != null) location = data['area']['nama_area'] ?? '';
    else if (data['subunit'] != null) location = data['subunit']['nama_subunit'] ?? '';
    else if (data['unit'] != null) location = data['unit']['nama_unit'] ?? '';
    else if (data['lokasi'] != null) location = data['lokasi']['nama_lokasi'] ?? '';

    final statusColor = isFinished ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final statusBg = isFinished ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
    final statusIcon = isFinished ? Icons.check_circle_rounded : Icons.pending_actions_rounded;
    final statusText = isFinished
        ? (widget.lang == 'ID' ? 'Selesai' : widget.lang == 'ZH' ? '已完成' : 'Finished')
        : (widget.lang == 'ID' ? 'Belum Selesai' : widget.lang == 'ZH' ? '未完成' : 'Unfinished');

    List<Widget> badges = [];
    if (isPro) badges.add(_buildBadge('PROFESIONAL', const Color.fromARGB(255, 255, 244, 45), Colors.black));
    if (isVisitor) badges.add(_buildBadge('VISITOR', const Color(0xFF3B82F6), Colors.white));
    if (isEksekutif) badges.add(_buildBadge('EKSEKUTIF', const Color(0xFFEF4444), Colors.white));

    List<String> inspTypes = [];
    if (isPro) inspTypes.add('pro');
    if (isVisitor) inspTypes.add('visitor');
    if (isEksekutif) inspTypes.add('eksekutif');
    inspTypes.sort();
    final combinationKey = inspTypes.join('+');

    Color borderColor;
    if (isKts) {
      borderColor = const Color(0xFFFDE68A);
    } else if (combinationKey.isNotEmpty) {
      borderColor = const Color(0xFF38BDF8);
    } else {
      borderColor = const Color(0xFF38BDF8);
    }

    // Deadline indicator
    Widget? timeIndicator;
    if (isFinished) {
      final penyelesaianData = data['penyelesaian'] as Map<String, dynamic>?;
      String completionDateText = '-';
      if (penyelesaianData != null) {
        final v = penyelesaianData['tanggal_selesai'];
        if (v != null) {
          final dt = DateTime.tryParse(v.toString());
          if (dt != null) completionDateText = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
        }
      }
      timeIndicator = Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: statusBg,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)),
        ),
        child: Row(children: [
          Icon(Icons.event_available_rounded, size: 13, color: statusColor),
          const SizedBox(width: 5),
          Text(
            '${widget.lang == 'ID' ? 'Selesai pada' : widget.lang == 'ZH' ? '完成于' : 'Completed on'} $completionDateText',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
          ),
        ]),
      );
    } else {
      final deadline = DateTime.tryParse(data['target_waktu_selesai']?.toString() ?? '');
      if (deadline != null) {
        final now = DateTime.now();
        final difference = deadline.difference(now);
        Color timeColor;
        String timeText;
        IconData timeIcon;
        if (difference.isNegative) {
          timeColor = Colors.red.shade700;
          timeIcon = Icons.warning_amber_rounded;
          final abs = difference.abs();
          if (abs.inDays > 0) timeText = '${abs.inDays} ${getTxt('hari_terlewat')}';
          else if (abs.inHours > 0) timeText = '${abs.inHours} ${getTxt('jam_terlewat')}';
          else timeText = '${abs.inMinutes} ${getTxt('menit_terlewat')}';
        } else {
          final sisaHari = difference.inDays;
          if (sisaHari == 0) {
            timeColor = Colors.orange.shade800;
            timeIcon = Icons.today_rounded;
            timeText = getTxt('deadline_hari_ini');
          } else {
            timeColor = Colors.green.shade800;
            timeIcon = Icons.timer_outlined;
            timeText = '$sisaHari ${getTxt('hari_tersisa')}';
          }
        }
        timeIndicator = Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: timeColor.withOpacity(0.08),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)),
          ),
          child: Row(children: [
            Icon(timeIcon, size: 13, color: timeColor),
            const SizedBox(width: 5),
            Text(timeText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: timeColor)),
          ]),
        );
      }
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => FindingDetailScreen(initialData: data, lang: widget.lang))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [BoxShadow(
            color: borderColor.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 11, 11, 11),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Image
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.black.withOpacity(0.12), width: 1.5)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11.5),
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.grey))
                        : const Icon(Icons.image_outlined, color: Colors.grey, size: 26),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Content
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Text(title,
                    style: const TextStyle(fontSize: 14, height: 1.3, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    maxLines: 2, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 6),
                  // Jenis label
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isKts ? const Color(0xFFFBBF24) : const Color(0xFF38BDF8)).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isKts ? const Color(0xFFFBBF24) : const Color(0xFF38BDF8), width: 1.1)),
                    child: Text(isKts ? 'KTS' : '5R', style: TextStyle(
                      color: isKts ? const Color(0xFFFBBF24) : const Color(0xFF38BDF8),
                      fontWeight: FontWeight.w900, fontSize: 9)),
                  ),
                  if (poin > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFFF6B3D)]),
                        borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.local_fire_department_rounded, size: 10, color: Colors.white),
                        const SizedBox(width: 2),
                        Text('$poin', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
                      ]),
                    ),
                  ],
                ]),
                const SizedBox(height: 5),
                if (badges.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(bottom: 4),
                    child: Wrap(spacing: 4, runSpacing: 3, children: badges)),
                Row(children: [
                  const Icon(Icons.place_rounded, size: 12, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Expanded(child: Text(location,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.calendar_today_rounded, size: 11, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(tanggal, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(16)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(statusIcon, size: 11, color: statusColor),
                      const SizedBox(width: 3),
                      Text(statusText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                    ]),
                  ),
                ]),
              ])),
            ]),
          ),
          if (timeIndicator != null) timeIndicator,
        ]),
      ),
    );
  }

  Widget _buildBadge(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 8, fontWeight: FontWeight.w900)),
    );
  }

  // ─── Table Widgets ────────────────────────────────────────────────────────
  Widget _buildTableHeader(List<String> cols, {required List<int> flex, bool isLocation = false}) {
    return Container(
      color: const Color(0xFFF8FAFF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: isLocation
          ? Row(children: [
              SizedBox(
                width: 40,
                child: Text(cols[0],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600,
                    color: _AppColors.textSecondary, letterSpacing: 0.2)),
              ),
              Expanded(
                flex: 3,
                child: Text(cols[1],
                  textAlign: TextAlign.left,   // <-- left agar sejajar dengan isi lokasi
                  style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600,
                    color: _AppColors.textSecondary, letterSpacing: 0.2)),
              ),
              SizedBox(
                width: 50,
                child: Text(cols[2],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600,
                    color: _AppColors.textSecondary, letterSpacing: 0.2)),
              ),
            ])
          : Row(
              children: List.generate(cols.length, (i) {
                // Kolom pertama (Name) rata kiri, sisanya center
                final isFirst = i == 0;
                return Expanded(
                  flex: flex[i],
                  child: Padding(
                    padding: EdgeInsets.only(left: isFirst ? 44 : 0), // 34 avatar + 10 gap
                    child: Text(
                      cols[i],
                      textAlign: isFirst ? TextAlign.left : TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600,
                        color: _AppColors.textSecondary, letterSpacing: 0.2),
                    ),
                  ),
                );
              }),
            ),
    );
  }

  Widget _buildTargetRow(List<String> vals) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: _AppColors.primaryLight,
        border: Border(bottom: BorderSide(color: _AppColors.divider)),
      ),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.only(left: 44), // sejajar dengan nama (avatar 34 + gap 10)
            child: Text(
              vals[0],
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: _AppColors.primary),
            ),
          ),
        ),
        ...vals.sublist(1).map((v) => Expanded(
          flex: 1,
          child: Text(v,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: _AppColors.primary)),
        )),
      ]),
    );
  }

  Widget _buildMemberRow(MemberData m) {
    final target = _targetAnggota;
    final findingsColor = m.findings >= target ? const Color(0xFF16A34A) : _AppColors.textPrimary;
    final completedColor = m.completed >= target ? const Color(0xFF16A34A) : _AppColors.textPrimary;

    return Container(
      color: m.isSelf ? _AppColors.selfHighlight : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          _Avatar(name: m.name, avatarUrl: m.avatarUrl, color: m.avatarColor, size: 34),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _AppColors.textPrimary),
              overflow: TextOverflow.ellipsis),
            if (m.unitName != null && m.unitName!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(m.unitName!, style: const TextStyle(fontSize: 11, color: _AppColors.textSecondary),
                overflow: TextOverflow.ellipsis),
            ],
          ])),
        ])),
        Expanded(flex: 1, child: Text('${m.findings}', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: findingsColor))),
        Expanded(flex: 1, child: Text('${m.completed}', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: completedColor))),
      ]),
    );
  }

  Widget _buildSelfPinnedRow(MemberData self) {
  final target = _targetAnggota;
  final findingsColor = self.findings >= target ? const Color(0xFF16A34A) : _AppColors.textSecondary;
  final completedColor = self.completed >= target ? const Color(0xFF16A34A) : _AppColors.textSecondary;

  return Container(
    decoration: BoxDecoration(
      color: _AppColors.selfHighlight,
      border: Border(top: BorderSide(color: _AppColors.selfHighlightBorder, width: 1.5)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, -2))],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      // Kolom Name — flex 3, SAMA persis dengan _buildMemberRow
      Expanded(
        flex: 3,
        child: Row(children: [
          _Avatar(name: self.name, avatarUrl: self.avatarUrl, color: self.avatarColor, size: 34),
          const SizedBox(width: 10),
          Expanded(child: Text(
            self.name,
            style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: _AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          )),
        ]),
      ),
      // Kolom Findings — flex 1, SAMA dengan header & member row
      Expanded(
        flex: 1,
        child: Text(
          '${self.findings}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5, fontWeight: FontWeight.w600, color: findingsColor),
        ),
      ),
      // Kolom Completed — flex 1, SAMA dengan header & member row
      Expanded(
        flex: 1,
        child: Text(
          '${self.completed}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5, fontWeight: FontWeight.w600, color: completedColor),
        ),
      ),
    ]),
  );
}

  Widget _buildInspectionRow(InspectionData item) {
    final target = _targetInspeksi;
    final findingsColor = item.findings >= target
        ? const Color(0xFF16A34A)
        : _AppColors.textPrimary;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        // Kolom Name — flex 3, struktur SAMA dengan header
        Expanded(
          flex: 3,
          child: Row(children: [
            _Avatar(name: item.name, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _AppColors.textPrimary,
                ),
              ),
            ),
          ]),
        ),
        // Kolom Findings — flex 1, center, SAMA dengan header
        Expanded(
          flex: 1,
          child: Text(
            '${item.findings}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: findingsColor,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildAuditPeriodBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(Icons.calendar_today_rounded, size: 15, color: _AppColors.primary),
        const SizedBox(width: 8),
        Text(getTxt('periode_audit'), style: TextStyle(fontSize: 13, color: _AppColors.textSecondary)),
        const Text('13 Apr - 19 Apr 2026',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _AppColors.primaryDark)),
      ]),
    );
  }

  Widget _buildLocationRow(int rank, LocationData loc) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        SizedBox(width: 40, child: Text('$rank', textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: _AppColors.textSecondary, fontWeight: FontWeight.w500))),
        Expanded(flex: 3, child: Row(children: [
          Container(width: 38, height: 38,
            decoration: BoxDecoration(color: _AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.location_city_rounded, color: _AppColors.primary, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(loc.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _AppColors.textPrimary),
              overflow: TextOverflow.ellipsis),
            Text(loc.pic, style: const TextStyle(fontSize: 11.5, color: _AppColors.textSecondary),
              overflow: TextOverflow.ellipsis),
          ])),
        ])),
        SizedBox(width: 50, child: Text(loc.value ?? '0', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: (int.tryParse(loc.value ?? '0') ?? 0) > 0 ? _AppColors.primaryDark : _AppColors.textMuted))),
      ]),
    );
  }
}

// ─── Analytics Location Picker Sheet ─────────────────────────────────────────
class _AnalyticsLocationPickerSheet extends StatefulWidget {
  final String lang;
  const _AnalyticsLocationPickerSheet({required this.lang});

  @override
  State<_AnalyticsLocationPickerSheet> createState() => _AnalyticsLocationPickerSheetState();
}

class _AnalyticsLocationPickerSheetState extends State<_AnalyticsLocationPickerSheet> {
  int _level = 0;
  bool _isLoading = true;
  List<dynamic> _data = [];
  List<dynamic> _filtered = [];
  final List<Map<String, dynamic>> _history = [];
  final _searchCtrl = TextEditingController();

  static const _idCols = ['id_lokasi', 'id_unit', 'id_subunit', 'id_area'];
  static const _namCols = ['nama_lokasi', 'nama_unit', 'nama_subunit', 'nama_area'];
  static const _tables = ['lokasi', 'unit', 'subunit', 'area'];
  static const _parentCols = ['', 'id_lokasi', 'id_unit', 'id_subunit'];

  String get _idCol => _idCols[_level];
  String get _nameCol => _namCols[_level];

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty ? List.from(_data)
          : _data.where((item) => item[_nameCol].toString().toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _fetch({dynamic parentId}) async {
    setState(() => _isLoading = true);
    _searchCtrl.clear();
    try {
      final supabase = Supabase.instance.client;
      final table = _tables[_level];
      var q = supabase.from(table).select('${_idCols[_level]}, ${_namCols[_level]}');
      if (_level > 0 && parentId != null) {
        q = q.eq(_parentCols[_level], parentId);
      }
      final data = await q.order(_namCols[_level]);
      if (mounted) {
        setState(() { _data = data; _filtered = List.from(data); _isLoading = false; });
      }
    } catch (e) {
      debugPrint('Location fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goDeeper(Map<String, dynamic> item) {
    if (_level >= 3) return;
    _history.add({'level': _level, 'id': item[_idCol], 'name': item[_nameCol]});
    setState(() => _level++);
    _fetch(parentId: item[_idCols[_level - 1]]);
  }

  void _select(Map<String, dynamic> item) {
    final parts = [..._history.map((h) => h['name'].toString()), item[_nameCol].toString()];
    Navigator.pop(context, {
      'id': item[_idCol],
      'name': parts.join(' / '),
      'level': _level,
    });
  }

  void _goBack() {
    if (_history.isEmpty) { Navigator.pop(context); return; }
    _history.removeLast();
    setState(() => _level--);
    _fetch(parentId: _history.isEmpty ? null : _history.last['id']);
  }

  @override
  Widget build(BuildContext context) {
    final lvlLabels = {'EN': ['Location', 'Unit', 'Sub-Unit', 'Area'],
      'ID': ['Lokasi', 'Unit', 'Sub-Unit', 'Area'], 'ZH': ['地点', '单位', '子单位', '区域']};
    final labels = lvlLabels[widget.lang] ?? lvlLabels['ID']!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        Container(
          margin: const EdgeInsets.only(top: 10), width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(children: [
            IconButton(
              icon: Icon(_history.isEmpty ? Icons.close : Icons.arrow_back_ios_new_rounded,
                  color: _AppColors.primary, size: 20),
              onPressed: _goBack),
            Expanded(child: Text(
              _history.isEmpty ? labels[_level] : _history.last['name'].toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _AppColors.textPrimary),
              textAlign: TextAlign.center)),
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
              child: Text('${_filtered.length}',
                style: const TextStyle(color: _AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13))),
          ]),
        ),
        // Breadcrumb
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: List.generate(4, (i) {
            final isActive = i == _level;
            final isPast = i < _level;
            return Row(children: [
              GestureDetector(
                onTap: isPast ? () {
                  final steps = _level - i;
                  for (int s = 0; s < steps; s++) { if (_history.isNotEmpty) _history.removeLast(); }
                  setState(() => _level = i);
                  _fetch(parentId: _history.isEmpty ? null : _history.last['id']);
                } : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? _AppColors.primary : isPast ? _AppColors.primaryLight : const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(20)),
                  child: Text(labels[i], style: TextStyle(
                    color: isActive ? Colors.white : isPast ? _AppColors.primary : Colors.grey.shade300,
                    fontSize: 11, fontWeight: isActive ? FontWeight.bold : FontWeight.normal))),
              ),
              if (i < 3) Icon(Icons.chevron_right, size: 12,
                  color: i < _level ? _AppColors.primary : Colors.grey.shade300),
            ]);
          })),
        ),
        const SizedBox(height: 8),
        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: _AppColors.surface, borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _AppColors.primaryLight)),
            child: Row(children: [
              const Icon(Icons.search_rounded, color: _AppColors.primary),
              const SizedBox(width: 10),
              Expanded(child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.lang == 'EN' ? 'Search...' : widget.lang == 'ZH' ? '搜索...' : 'Cari...',
                  border: InputBorder.none, isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14)),
              )),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _AppColors.primary))
            : _filtered.isEmpty
                ? const Center(child: Text('No data', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final item = _filtered[i];
                      final name = item[_nameCol]?.toString() ?? '-';
                      final isLastLevel = _level == 3;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _AppColors.primaryLight),
                          boxShadow: [BoxShadow(color: _AppColors.primary.withOpacity(0.06),
                              blurRadius: 6, offset: const Offset(0, 2))]),
                        child: InkWell(
                          onTap: isLastLevel ? () => _select(item) : () => _goDeeper(item),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                                child: Icon([Icons.location_city, Icons.workspaces, Icons.layers, Icons.place][_level],
                                  color: _AppColors.primary, size: 18)),
                              const SizedBox(width: 12),
                              Expanded(child: Text(name,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _AppColors.textPrimary))),
                              GestureDetector(
                                onTap: () => _select(item),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _AppColors.primaryLight, borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _AppColors.primary)),
                                  child: Text(widget.lang == 'EN' ? 'Select' : widget.lang == 'ZH' ? '选择' : 'Pilih',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _AppColors.primary))),
                              ),
                              if (!isLastLevel) ...[
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _goDeeper(item),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(color: _AppColors.surface, borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.chevron_right, color: Colors.grey, size: 18))),
                              ],
                            ]),
                          ),
                        ),
                      );
                    })),
      ]),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String name;
  final Color? color;
  final double size;
  final String? avatarUrl;

  const _Avatar({required this.name, this.color, this.size = 36, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(avatarUrl!),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }
    return _buildInitialsContainer();
  }

  Widget _buildInitials() {
    final initials = name.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    final bg = color ?? _AppColors.primary;
    return Text(initials,
      style: TextStyle(fontSize: size * 0.35, fontWeight: FontWeight.w700, color: bg));
  }

  Widget _buildInitialsContainer() {
    final bg = color ?? _AppColors.primary;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: bg.withOpacity(0.15), shape: BoxShape.circle,
        border: Border.all(color: bg.withOpacity(0.3), width: 1)),
      child: Center(child: _buildInitials()),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _AppColors.primary : _AppColors.divider, width: 1.5),
          boxShadow: selected ? [BoxShadow(color: _AppColors.primary.withOpacity(0.3),
              blurRadius: 6, offset: const Offset(0, 2))] : null,
        ),
        child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _AppColors.textSecondary)),
      ),
    );
  }
}