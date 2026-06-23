import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/services/gemini_recurring_service.dart';

class _C {
  static const primary         = Color(0xFF0EA5E9);
  static const textPrimary     = Color(0xFF0C4A6E);
  static const textSecondary   = Color(0xFF64748B);
  static const textMuted       = Color(0xFFBDBDBD);
  static const divider         = Color(0xFFE0F2FE);
  static const selfHighlight   = Color(0xFFFFF7ED);
  static const selfHighlightBorder = Color(0xFFFED7AA);
  static const red             = Color(0xFFEF4444);
  static const amber           = Color(0xFFF59E0B);
  static const green           = Color(0xFF10B981);
  static const orange          = Color(0xFFF97316);
}

class _MemberData {
  final String name;
  final String? unitName;
  final int findings;
  final int completed;
  final bool isSelf;
  final String? avatarUrl;
  final Color? avatarColor;
  const _MemberData({
    required this.name,
    this.unitName,
    required this.findings,
    required this.completed,
    this.isSelf = false,
    this.avatarUrl,
    this.avatarColor,
  });
}

class _LocationData {
  final String name;
  final String pic;
  final String? value;
  const _LocationData({required this.name, required this.pic, this.value});
}

// ─── Widget utama ─────────────────────────────────────────────────────────────
class AnalyticsAccidentTab extends StatefulWidget {
  final String lang;
  const AnalyticsAccidentTab({super.key, required this.lang});

  @override
  State<AnalyticsAccidentTab> createState() => _AnalyticsAccidentTabState();
}

class _AnalyticsAccidentTabState extends State<AnalyticsAccidentTab>
    with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;

  // ── Tab controller ──────────────────────────────────────────────────────────
  late TabController _tabController;
  int _activeTabIndex = 0;

  // ── Filter state ────────────────────────────────────────────────────────────
  int    _selectedMonthIndex = DateTime.now().month - 1;
  String _filterMode         = 'monthly';   // 'monthly' | 'daily'
  DateTime? _selectedDate;
  String? _selectedUnitId;
  String  _selectedLocationLevel = 'Lokasi'; // backend value
  DateTime? _lastUpdated;

  // Recurring filter
  DateTime _recurringFrom    = DateTime(DateTime.now().year - 1, DateTime.now().month);
  DateTime _recurringTo      = DateTime.now();
  String?  _recurringUserId;
  String   _recurringUserName = '';

  // ── Chart ────────────────────────────────────────────────────────────────────
  bool _isChartExpanded      = false;
  bool _isChartLoadingForTab = false;

  // ── Data futures ─────────────────────────────────────────────────────────────
  Future<List<_MemberData>>?           _membersFuture;
  Future<List<_LocationData>>?         _locationFuture;
  Future<List<Map<String, dynamic>>>?  _recurringFuture;

  // ── Unit list (untuk grup filter) ────────────────────────────────────────────
  List<Map<String, dynamic>> _unitList = [];

  // ── Terjemahan ────────────────────────────────────────────────────────────────
  late List<String> _translatedMonths;
  late List<String> _translatedLocationLevels;

  // Level backend list
  final _levelBackends = ['Lokasi', 'Unit', 'Subunit', 'Area'];

  // ────────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _initLists();
    _fetchUnits().then((_) => _fetchAll());
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _initLists() {
    final locale = widget.lang == 'ID' ? 'id_ID'
        : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    _translatedMonths = List.generate(
        12, (i) => DateFormat.MMM(locale).format(DateTime(2000, i + 1)));
    _translatedLocationLevels = [
      _t('Lokasi', 'Location', '位置'),
      _t('Unit', 'Unit', '单元'),
      _t('Subunit', 'Sub-unit', '子单元'),
      _t('Area', 'Area', '区域'),
    ];
    // Sinkronkan _selectedLocationLevel ke translated value pertama
    _selectedLocationLevel = _translatedLocationLevels[0];
  }

  // ─── Fetch helpers ──────────────────────────────────────────────────────────
  Future<void> _fetchUnits() async {
    try {
      final res = await _supabase.from('unit').select('id_unit, nama_unit');
      if (mounted) setState(() => _unitList = List<Map<String, dynamic>>.from(res));
    } catch (e) { debugPrint('fetchUnits: $e'); }
  }

  void _fetchAll({bool fromTabFilter = false}) {
    if (!fromTabFilter) _isChartLoadingForTab = false;
    final month = _selectedMonthIndex + 1;
    final year  = DateTime.now().year;

    setState(() {
      _lastUpdated = DateTime.now();
      if (_filterMode == 'daily' && _selectedDate != null) {
        _membersFuture  = _fetchMembersDaily(_selectedDate!, _selectedUnitId);
        _locationFuture = _fetchLocationDaily(_selectedDate!, _levelBackend);
      } else {
        _membersFuture  = _fetchMembers(month, year, _selectedUnitId);
        _locationFuture = _fetchLocation(month, year, _levelBackend);
      }
      _recurringFuture = _fetchRecurring();
    });
  }

  void _onTabChanged() {
    if (!mounted || _tabController.indexIsChanging) return;
    final idx = _tabController.index;
    if (_activeTabIndex == idx) return;
    setState(() {
      _isChartLoadingForTab = true;
      _activeTabIndex = idx;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _isChartLoadingForTab = false);
    });
  }

  // ─── Level helper ───────────────────────────────────────────────────────────
  String get _levelBackend {
    final idx = _translatedLocationLevels.indexOf(_selectedLocationLevel).clamp(0, 3);
    return _levelBackends[idx];
  }

  // ─── Members (monthly) ──────────────────────────────────────────────────────
  Future<List<_MemberData>> _fetchMembers(int month, int year, String? unitId) async {
    try {
      var q = _supabase.from('accident_report')
          .select('id_pelapor, status, id_unit')
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at', DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String());
      if (unitId != null) q = q.eq('id_unit', unitId);
      final List<dynamic> res = await q;
      return _groupMembersFromReports(res);
    } catch (e) { return []; }
  }

  // ─── Members (daily) ────────────────────────────────────────────────────────
  Future<List<_MemberData>> _fetchMembersDaily(DateTime date, String? unitId) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end   = DateTime(date.year, date.month, date.day, 23, 59, 59);
      var q = _supabase.from('accident_report')
          .select('id_pelapor, status')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());
      if (unitId != null) q = q.eq('id_unit', unitId);
      final List<dynamic> res = await q;
      return _groupMembersFromReports(res);
    } catch (e) { return []; }
  }

  Future<List<_MemberData>> _groupMembersFromReports(List<dynamic> reports) async {
    if (reports.isEmpty) return [];
    final Map<String, Map<String, dynamic>> grouped = {};
    for (final item in reports) {
      final uid = item['id_pelapor']?.toString() ?? '';
      if (uid.isEmpty) continue;
      grouped.putIfAbsent(uid, () => {'temuan': 0, 'selesai': 0});
      grouped[uid]!['temuan'] = (grouped[uid]!['temuan'] as int) + 1;
      if ((item['status'] ?? '') == 'Selesai') {
        grouped[uid]!['selesai'] = (grouped[uid]!['selesai'] as int) + 1;
      }
    }
    final userIds = grouped.keys.toList();
    final List<dynamic> usersRes = await _supabase
        .from('User')
        .select('id_user, nama, gambar_user, id_unit, unit!user_id_unit_fkey(nama_unit)')
        .inFilter('id_user', userIds);
    final currentUserId = _supabase.auth.currentUser?.id;
    return usersRes.map((u) {
      final uid   = u['id_user']?.toString() ?? '';
      final stats = grouped[uid] ?? {'temuan': 0, 'selesai': 0};
      return _MemberData(
        name:      u['nama'] as String? ?? '-',
        unitName:  (u['unit'] as Map<String, dynamic>?)?['nama_unit'] as String?,
        findings:  stats['temuan'] as int,
        completed: stats['selesai'] as int,
        isSelf:    uid == currentUserId,
        avatarUrl: u['gambar_user'] as String?,
        avatarColor: _C.red,
      );
    }).toList()..sort((a, b) => b.findings.compareTo(a.findings));
  }

  // ─── Location (monthly) ─────────────────────────────────────────────────────
  Future<List<_LocationData>> _fetchLocation(int month, int year, String level) async {
    try {
      final ll = level.toLowerCase();
      final idCol   = _idColFor(ll);
      final nameCol = _nameColFor(ll);

      final List<dynamic> locations = await _supabase.from(ll).select('$idCol, $nameCol');
      final List<dynamic> reportRes = await _supabase
          .from('accident_report')
          .select(idCol)
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at', DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String())
          .not(idCol, 'is', null);

      final Map<String, int> countMap = {};
      for (final t in reportRes) {
        final id = t[idCol]?.toString() ?? '';
        if (id.isEmpty) continue;
        countMap[id] = (countMap[id] ?? 0) + 1;
      }
      final List<dynamic> picRes = await _supabase
          .from('User').select('$idCol, nama').not(idCol, 'is', null);
      final Map<String, String> picMap = {};
      for (final p in picRes) {
        final locId = p[idCol]?.toString() ?? '';
        if (locId.isEmpty || picMap.containsKey(locId)) continue;
        picMap[locId] = p['nama']?.toString() ?? 'PIC belum diatur';
      }
      return locations.map<_LocationData>((loc) {
        final id = loc[idCol]?.toString() ?? '';
        return _LocationData(
          name:  loc[nameCol]?.toString() ?? '-',
          pic:   picMap[id] ?? 'PIC belum diatur',
          value: (countMap[id] ?? 0).toString(),
        );
      }).toList()
        ..sort((a, b) => (int.tryParse(b.value ?? '0') ?? 0)
            .compareTo(int.tryParse(a.value ?? '0') ?? 0));
    } catch (e) { return []; }
  }

  // ─── Location (daily) ───────────────────────────────────────────────────────
  Future<List<_LocationData>> _fetchLocationDaily(DateTime date, String level) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end   = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final ll    = level.toLowerCase();
      final idCol   = _idColFor(ll);
      final nameCol = _nameColFor(ll);
      final locations  = await _supabase.from(ll).select('$idCol, $nameCol');
      final reportList = await _supabase.from('accident_report').select(idCol)
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());
      final Map<String, int> countMap = {};
      for (final t in reportList) {
        final id = t[idCol]?.toString() ?? '';
        if (id.isEmpty) continue;
        countMap[id] = (countMap[id] ?? 0) + 1;
      }
      return (locations as List<dynamic>).map((loc) => _LocationData(
        name:  loc[nameCol]?.toString() ?? '-',
        pic:   '-',
        value: (countMap[loc[idCol]?.toString() ?? ''] ?? 0).toString(),
      )).toList()
        ..sort((a, b) => (int.tryParse(b.value ?? '0') ?? 0)
            .compareTo(int.tryParse(a.value ?? '0') ?? 0));
    } catch (e) { return []; }
  }

  // ─── Recurring ──────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _fetchRecurring() async {
    try {
      var q = _supabase.from('accident_report').select('''
        id_laporan, judul, deskripsi, foto_bukti, created_at, status,
        tanggal_kejadian, tingkat_keparahan, penyebab, tindakan_diambil,
        id_lokasi, id_unit, id_subunit, id_area, id_pelapor,
        lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area),
        User_Pelapor:User!accident_report_id_pelapor_fkey(nama, gambar_user)
      ''')
        .gte('created_at', _recurringFrom.toIso8601String())
        .lte('created_at', DateTime(
            _recurringTo.year, _recurringTo.month + 1, 0, 23, 59, 59).toIso8601String());
      if (_recurringUserId != null) q = q.eq('id_pelapor', _recurringUserId!);
      final List<dynamic> res = await q.order('created_at', ascending: false);
      final reports = List<Map<String, dynamic>>.from(res);
      if (reports.isEmpty) return [];

      final groups = await GeminiRecurringService.instance.analyzeAccidents(
        reports,
        fromDate:     _recurringFrom,
        toDate:       _recurringTo,
        filterUserId: _recurringUserId,
      );
      return groups.map((g) => {
        'topic':           g.topic,
        'locationArea':    g.locationArea,
        'total':           g.total,
        'imageUrl':        g.imageUrl,
        'reports':         g.reports,
        'severityPattern': g.severityPattern,
        'similarityScore': g.similarityScore,
        'aiReason':        g.reason,
      }).toList();
    } catch (e) { return []; }
  }

  // ─── Column helpers ─────────────────────────────────────────────────────────
  String _idColFor(String ll)   => {'lokasi':'id_lokasi','unit':'id_unit','subunit':'id_subunit','area':'id_area'}[ll] ?? 'id_lokasi';
  String _nameColFor(String ll) => {'lokasi':'nama_lokasi','unit':'nama_unit','subunit':'nama_subunit','area':'nama_area'}[ll] ?? 'nama_lokasi';

  // ─── i18n helper ────────────────────────────────────────────────────────────
  String _t(String id, String en, String zh) {
    if (widget.lang == 'ID') return id;
    if (widget.lang == 'ZH') return zh;
    return en;
  }

  String get _lastUpdatedText {
    if (_lastUpdated == null) return _t('Memuat data...', 'Loading data...', '加载数据...');
    final fmt = DateFormat('d MMM yyyy HH:mm',
        widget.lang == 'ID' ? 'id_ID' : 'en_US').format(_lastUpdated!);
    return '${_t('Terakhir diperbarui pada', 'Last updated at', '最后更新于')} $fmt (GMT+7)';
  }

  // ─── Month label ─────────────────────────────────────────────────────────────
  String get _activeDateLabel {
    final locale = widget.lang == 'ID' ? 'id_ID'
        : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    if (_filterMode == 'daily' && _selectedDate != null) {
      return DateFormat('d MMM yyyy', locale).format(_selectedDate!);
    }
    return DateFormat('MMMM yyyy', locale)
        .format(DateTime(DateTime.now().year, _selectedMonthIndex + 1));
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildTabBar(),
      _buildConditionalChart(),
      Expanded(child: TabBarView(
        controller: _tabController,
        children: [
          _buildMembersTab(),
          _buildLocationTab(),
          _buildRecurringTab(),
        ],
      )),
    ]);
  }

  // ─── Tab bar ─────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    final labels = [
      _t('Anggota', 'Members', '成员'),
      _t('Lokasi', 'Location', '位置'),
      _t('Kecelakaan Berulang', 'Recurring Accident', '重复事故'),
    ];
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.all(3),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(color: _C.red, borderRadius: BorderRadius.circular(8)),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: _C.red,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5),
          dividerColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: labels.map((t) => Tab(child: Text(t))).toList(),
        ),
      ),
    );
  }

  // ─── Conditional chart (hidden on Recurring tab) ─────────────────────────────
  Widget _buildConditionalChart() {
    if (_activeTabIndex == 2) return const SizedBox.shrink();
    if (_isChartLoadingForTab)  return _buildChartShimmer();

    return Column(children: [
      // Toggle button
      GestureDetector(
        onTap: () => setState(() => _isChartExpanded = !_isChartExpanded),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.red.withOpacity(0.4), width: 1.2),
            boxShadow: [BoxShadow(color: _C.red.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            Icon(Icons.bar_chart_rounded, size: 16, color: _C.red),
            const SizedBox(width: 8),
            Expanded(child: Text(
              _t('Grafik $_activeDateLabel', 'Chart $_activeDateLabel', '$_activeDateLabel 图表'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _C.red),
            )),
            AnimatedRotation(
              turns: _isChartExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              child: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: _C.red),
            ),
          ]),
        ),
      ),
      // Animated pie chart body
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: _isChartExpanded
            ? (_activeTabIndex == 0
                ? _buildMembersPieChart()
                : _buildLocationPieChart())
            : const SizedBox.shrink(),
      ),
    ]);
  }

  // ─── Members pie chart ────────────────────────────────────────────────────────
  Widget _buildMembersPieChart() {
    return FutureBuilder<List<_MemberData>>(
      future: _membersFuture,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) return _buildChartShimmer();
        final data       = snap.data ?? [];
        final totalRep   = data.fold<int>(0, (s, m) => s + m.findings);
        final totalDone  = data.fold<int>(0, (s, m) => s + m.completed);
        return _buildPieChart(
          totalPrimary:   totalRep,
          totalSecondary: totalDone,
          colorPrimary:   _C.red,
          colorSecondary: _C.green,
          labelPrimary:   _t('Laporan', 'Reports', '报告'),
          labelSecondary: _t('Selesai', 'Completed', '已完成'),
          iconPrimary:    Icons.warning_amber_rounded,
          iconSecondary:  Icons.check_circle_outline_rounded,
        );
      },
    );
  }

  // ─── Location pie chart ───────────────────────────────────────────────────────
  Widget _buildLocationPieChart() {
    return FutureBuilder<List<_LocationData>>(
      future: _locationFuture,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) return _buildChartShimmer();
        final data        = snap.data ?? [];
        final totalAll    = data.fold<int>(0, (s, l) => s + (int.tryParse(l.value ?? '0') ?? 0));
        final topCount    = data.isNotEmpty ? (int.tryParse(data.first.value ?? '0') ?? 0) : 0;
        final others      = totalAll - topCount;
        return _buildPieChart(
          totalPrimary:   topCount,
          totalSecondary: others,
          colorPrimary:   _C.red,
          colorSecondary: _C.orange,
          labelPrimary:   data.isNotEmpty ? data.first.name : _t('Teratas', 'Top', '最高'),
          labelSecondary: _t('Lokasi Lainnya', 'Other Locations', '其他位置'),
          iconPrimary:    Icons.location_on_rounded,
          iconSecondary:  Icons.more_horiz_rounded,
        );
      },
    );
  }

  Widget _buildChartShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        height: 158,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── Generic pie chart ────────────────────────────────────────────────────────
  Widget _buildPieChart({
    required int    totalPrimary,
    required int    totalSecondary,
    required Color  colorPrimary,
    required Color  colorSecondary,
    required String labelPrimary,
    required String labelSecondary,
    required IconData iconPrimary,
    required IconData iconSecondary,
  }) {
    final total = totalPrimary + totalSecondary;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.red.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: _C.red.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const Icon(Icons.pie_chart_rounded, size: 14, color: _C.red),
            const SizedBox(width: 6),
            Text(
              _t('Ringkasan $_activeDateLabel', 'Summary $_activeDateLabel', '$_activeDateLabel 摘要'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _C.red),
            ),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _C.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_t('Total', 'Total', '总计')}: $total',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _C.red),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        if (total == 0)
          Center(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(children: [
              Icon(Icons.pie_chart_outline, size: 40, color: Colors.grey.shade300),
              const SizedBox(height: 6),
              Text(_t('Tidak ada data', 'No data', '暂无数据'),
                  style: const TextStyle(color: _C.textSecondary, fontSize: 12)),
            ]),
          ))
        else
          Row(children: [
            SizedBox(
              width: 130, height: 130,
              child: CustomPaint(
                painter: _PieChartPainter(
                  primaryValue:   totalPrimary.toDouble(),
                  secondaryValue: totalSecondary.toDouble(),
                  colorPrimary:   colorPrimary,
                  colorSecondary: colorSecondary,
                ),
                child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$total', style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: _C.textPrimary)),
                  Text(_t('Total', 'Total', '总计'),
                      style: const TextStyle(fontSize: 9, color: _C.textSecondary)),
                ])),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(children: [
              _buildPieCard(colorPrimary,   labelPrimary,   totalPrimary,   total, iconPrimary),
              const SizedBox(height: 8),
              _buildPieCard(colorSecondary, labelSecondary, totalSecondary, total, iconSecondary),
            ])),
          ]),
      ]),
    );
  }

  Widget _buildPieCard(Color color, String label, int value, int total, IconData icon) {
    final pct = total > 0 ? (value / total * 100).toStringAsFixed(1) : '0.0';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? value / total : 0,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 3,
            ),
          ),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$value', style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800, color: _C.textPrimary)),
          Text('$pct%', style: TextStyle(
              fontSize: 9, color: color, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  TAB: MEMBERS
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildMembersTab() {
    return Column(children: [
      // Filter row
      Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          _buildFilterBtn(
            label: _filterMode == 'daily' && _selectedDate != null
                ? DateFormat('d MMM yyyy',
                    widget.lang == 'ID' ? 'id_ID' : widget.lang == 'EN' ? 'en_US' : 'zh_CN')
                    .format(_selectedDate!)
                : _translatedMonths[_selectedMonthIndex],
            isActive: true,
            onTap: () => _showMonthPicker(() => _fetchAll(fromTabFilter: true)),
          ),
          const SizedBox(width: 10),
          Expanded(child: _buildFilterBtn(
            label: _selectedUnitId == null
                ? _t('Semua Grup', 'All Groups', '所有组')
                : (_unitList.firstWhere(
                    (u) => u['id_unit'].toString() == _selectedUnitId,
                    orElse: () => {'nama_unit': _t('Semua Grup', 'All Groups', '所有组')})
                    ['nama_unit'] as String),
            onTap: _showGroupPicker,
          )),
        ]),
      ),
      _buildLastUpdated(),
      // Header
      _buildTableHeader([
        _t('Nama', 'Name', '名称'),
        _t('Laporan', 'Reports', '报告'),
        _t('Selesai', 'Completed', '已完成'),
      ], flex: [3, 1, 1]),
      // List
      Expanded(child: _membersFuture == null
          ? _buildMemberShimmer()
          : FutureBuilder<List<_MemberData>>(
              future: _membersFuture,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) return _buildMemberShimmer();
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return Center(child: Text(
                    _t('Tidak ada data anggota.', 'No member data.', '没有成员数据。'),
                    style: const TextStyle(color: _C.textSecondary)));
                }
                final self = list.firstWhere(
                  (m) => m.isSelf,
                  orElse: () => _MemberData(
                    name: _t('Saya', 'Me', '我'),
                    findings: 0, completed: 0, isSelf: true),
                );
                return Column(children: [
                  Expanded(child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: _C.divider, indent: 16),
                    itemBuilder: (_, i) => _buildMemberRow(list[i]),
                  )),
                  _buildSelfPinnedRow(self),
                ]);
              },
            )),
    ]);
  }

  Widget _buildMemberRow(_MemberData m) {
    return Container(
      color: m.isSelf ? _C.selfHighlight : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          _Avatar(name: m.name, avatarUrl: m.avatarUrl, color: m.avatarColor, size: 34),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.name, style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500, color: _C.textPrimary),
                overflow: TextOverflow.ellipsis),
            if (m.unitName != null && m.unitName!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(m.unitName!, style: const TextStyle(fontSize: 11, color: _C.textSecondary),
                  overflow: TextOverflow.ellipsis),
            ],
          ])),
        ])),
        Expanded(flex: 1, child: Text('${m.findings}', textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _C.textPrimary))),
        Expanded(flex: 1, child: Text('${m.completed}', textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _C.textPrimary))),
      ]),
    );
  }

  Widget _buildSelfPinnedRow(_MemberData self) {
    return Container(
      decoration: BoxDecoration(
        color: _C.selfHighlight,
        border: const Border(top: BorderSide(color: _C.selfHighlightBorder, width: 1.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, -2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          _Avatar(name: self.name, avatarUrl: self.avatarUrl, color: self.avatarColor, size: 34),
          const SizedBox(width: 10),
          Expanded(child: Text(self.name, style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: _C.textPrimary),
              overflow: TextOverflow.ellipsis)),
        ])),
        Expanded(flex: 1, child: Text('${self.findings}', textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _C.textSecondary))),
        Expanded(flex: 1, child: Text('${self.completed}', textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _C.textSecondary))),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  TAB: LOCATION
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildLocationTab() {
    return Column(children: [
      Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          _buildFilterBtn(
            label: _filterMode == 'daily' && _selectedDate != null
                ? DateFormat('d MMM yyyy',
                    widget.lang == 'ID' ? 'id_ID' : widget.lang == 'EN' ? 'en_US' : 'zh_CN')
                    .format(_selectedDate!)
                : _translatedMonths[_selectedMonthIndex],
            isActive: true,
            onTap: () => _showMonthPicker(() => _fetchAll(fromTabFilter: true)),
          ),
          const SizedBox(width: 10),
          Expanded(child: _buildFilterBtn(
            label: _selectedLocationLevel,
            onTap: _showLevelPicker,
          )),
        ]),
      ),
      _buildLastUpdated(),
      _buildTableHeader([
        _t('Rank', 'Rank', '排名'),
        _t('Lokasi', 'Location', '位置'),
        _t('Laporan', 'Reports', '报告'),
      ], flex: [1, 3, 1], isLocation: true),
      Expanded(child: _locationFuture == null
          ? _buildLocationShimmer()
          : FutureBuilder<List<_LocationData>>(
              future: _locationFuture,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) return _buildLocationShimmer();
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return Center(child: Text(
                    _t('Tidak ada data lokasi.', 'No location data.', '没有位置数据。'),
                    style: const TextStyle(color: _C.textSecondary)));
                }
                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: _C.divider, indent: 16),
                  itemBuilder: (_, i) => _buildLocationRow(i + 1, list[i]),
                );
              },
            )),
    ]);
  }

  Widget _buildLocationRow(int rank, _LocationData loc) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        SizedBox(width: 40, child: Text('$rank', textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: _C.textSecondary, fontWeight: FontWeight.w500))),
        Expanded(flex: 3, child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: _C.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.location_city_rounded, color: _C.red, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(loc.name, style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _C.textPrimary),
                overflow: TextOverflow.ellipsis),
            Text(loc.pic, style: const TextStyle(fontSize: 11.5, color: _C.textSecondary),
                overflow: TextOverflow.ellipsis),
          ])),
        ])),
        SizedBox(width: 70, child: Text(loc.value ?? '0', textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: (int.tryParse(loc.value ?? '0') ?? 0) > 0 ? _C.red : _C.textMuted))),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  TAB: RECURRING
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildRecurringTab() {
    final locale    = widget.lang == 'ID' ? 'id_ID' : widget.lang == 'ZH' ? 'zh_CN' : 'en_US';
    final fromLabel = DateFormat('MMM yyyy', locale).format(_recurringFrom);
    final toLabel   = DateFormat('MMM yyyy', locale).format(_recurringTo);

    return Column(children: [
      // Filter row
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          Expanded(child: _buildFilterBtn(
            label: '$fromLabel - $toLabel',
            icon: Icons.calendar_month_rounded,
            onTap: _showPeriodPicker,
          )),
          const SizedBox(width: 10),
          Expanded(child: _buildFilterBtn(
            label: _recurringUserName.isEmpty
                ? _t('Semua Penemu', 'All Finders', '所有发现者')
                : _recurringUserName,
            onTap: _showUserPicker,
          )),
        ]),
      ),
      // Title
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Align(alignment: Alignment.centerLeft,
          child: Text(
            _t('Laporan Kecelakaan Berulang', 'Recurring Accident Reports', '重复事故报告'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _C.textPrimary),
          )),
      ),
      const Divider(height: 1, color: _C.divider),
      // List
      Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _recurringFuture,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) return _buildRecurringShimmer();
          final groups = snap.data ?? [];
          if (groups.isEmpty) return _buildRecurringEmpty();
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _AccidentRecurringCard(
              group: groups[i],
              lang: widget.lang,
              onTap: () => _showRecurringDetail(context, groups[i]),
            ),
          );
        },
      )),
    ]);
  }

  Widget _buildRecurringEmpty() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 72, height: 72,
        decoration: const BoxDecoration(color: Color(0xFFFEF2F2), shape: BoxShape.circle),
        child: Icon(Icons.warning_amber_rounded, size: 36, color: _C.red.withOpacity(0.5)),
      ),
      const SizedBox(height: 16),
      Text(
        _t('Tidak ada laporan kecelakaan berulang.',
           'No recurring accident reports.', '没有重复的事故报告。'),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, color: _C.textSecondary, height: 1.5),
      ),
    ]));
  }

  // ─── Recurring detail bottom sheet ───────────────────────────────────────────
  void _showRecurringDetail(BuildContext context, Map<String, dynamic> group) {
    final topic   = group['topic'] as String;
    final reports = group['reports'] as List<Map<String, dynamic>>;
    final locale  = widget.lang == 'ID' ? 'id_ID' : widget.lang == 'ZH' ? 'zh_CN' : 'en_US';
    final listLabel  = _t('Daftar Laporan', 'Report List', '报告列表');
    final totalLabel = _t('Total', 'Total', '总计');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                Expanded(child: Text(topic, style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: _C.textPrimary))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                  child: Text('$totalLabel: ${reports.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: _C.red)),
                ),
              ]),
            ),
            const Divider(height: 1, color: _C.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Align(alignment: Alignment.centerLeft,
                child: Text('$listLabel (${reports.length})', style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _C.textPrimary))),
            ),
            Expanded(child: ListView.separated(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: reports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _AccidentReportCard(
                  data: reports[i], lang: widget.lang, locale: locale),
            )),
          ]),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  SHARED UI HELPERS
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildLastUpdated() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(_lastUpdatedText,
          style: const TextStyle(fontSize: 11, color: _C.textSecondary, height: 1.4)),
    );
  }

  Widget _buildFilterBtn({
    required String label,
    required VoidCallback onTap,
    IconData icon = Icons.keyboard_arrow_down_rounded,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color:  isActive ? _C.red : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _C.red : const Color(0xFFFCA5A5),
            width: 1.5,
          ),
          boxShadow: [BoxShadow(
              color: _C.red.withOpacity(0.10), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(child: Text(label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : _C.red),
              overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 4),
          Icon(icon, color: isActive ? Colors.white : _C.red, size: 18),
        ]),
      ),
    );
  }

  Widget _buildTableHeader(List<String> cols, {required List<int> flex, bool isLocation = false}) {
    return Container(
      color: const Color(0xFFF8FAFF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: isLocation
          ? Row(children: [
              SizedBox(width: 40, child: Text(cols[0], textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                      color: _C.textSecondary, letterSpacing: 0.2))),
              Expanded(flex: 3, child: Text(cols[1], textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                      color: _C.textSecondary, letterSpacing: 0.2))),
              SizedBox(width: 70, child: Text(cols[2], textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                      color: _C.textSecondary, letterSpacing: 0.2))),
            ])
          : Row(children: List.generate(cols.length, (i) => Expanded(
              flex: flex[i],
              child: Padding(
                padding: EdgeInsets.only(left: i == 0 ? 44 : 0),
                child: Text(cols[i],
                    textAlign: i == 0 ? TextAlign.left : TextAlign.center,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                        color: _C.textSecondary, letterSpacing: 0.2)),
              )))),
    );
  }

  // ─── Shimmer widgets ──────────────────────────────────────────────────────────
  Widget _buildMemberShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!,
      child: ListView.separated(
        padding: EdgeInsets.zero, itemCount: 10,
        separatorBuilder: (_, __) => const Divider(height: 1, color: _C.divider, indent: 16),
        itemBuilder: (_, __) => Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(children: [
            Expanded(flex: 3, child: Row(children: [
              _shimmerBox(height: 34, width: 34, isCircle: true),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _shimmerBox(height: 14, width: 120),
                const SizedBox(height: 4),
                _shimmerBox(height: 12, width: 80),
              ])),
            ])),
            Expanded(flex: 1, child: Center(child: _shimmerBox(height: 14, width: 20))),
            Expanded(flex: 1, child: Center(child: _shimmerBox(height: 14, width: 20))),
          ]),
        ),
      ),
    );
  }

  Widget _buildLocationShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!,
      child: ListView.separated(
        padding: EdgeInsets.zero, itemCount: 8,
        separatorBuilder: (_, __) => const Divider(height: 1, color: _C.divider, indent: 16),
        itemBuilder: (_, __) => Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            SizedBox(width: 40, child: Center(child: _shimmerBox(height: 14, width: 20))),
            Expanded(flex: 3, child: Row(children: [
              _shimmerBox(height: 38, width: 38, borderRadius: 10),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _shimmerBox(height: 14, width: double.infinity),
                const SizedBox(height: 4),
                _shimmerBox(height: 12, width: 100),
              ])),
            ])),
            SizedBox(width: 70, child: Center(child: _shimmerBox(height: 14, width: 20))),
          ]),
        ),
      ),
    );
  }

  Widget _buildRecurringShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => Container(
          height: 80,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _shimmerBox({double? width, required double height,
      bool isCircle = false, double borderRadius = 8}) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCircle ? height / 2 : borderRadius),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  FILTER DIALOGS
  // ════════════════════════════════════════════════════════════════════════════

  // ─── Month / Daily picker ─────────────────────────────────────────────────────
  void _showMonthPicker(VoidCallback onChanged) async {
    String tempMode = _filterMode;
    int tempMonthIdx = _selectedMonthIndex;
    DateTime tempDate = _selectedDate ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.65, maxWidth: 340),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0F2FE), width: 1.5)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2FE),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              child: Row(children: [
                const Icon(Icons.calendar_month_rounded, color: _C.red, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  _t('Pilih Bulan', 'Select Month', '选择月份'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _C.textPrimary))),
                IconButton(icon: const Icon(Icons.close, size: 18, color: _C.textSecondary),
                    onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
              ]),
            ),
            // Toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0F2FE))),
                padding: const EdgeInsets.all(4),
                child: Row(children: ['monthly','daily'].map((mode) {
                  final isSel = tempMode == mode;
                  final label = mode == 'monthly'
                      ? _t('Bulanan', 'Monthly', '按月')
                      : _t('Harian', 'Daily', '按日');
                  return Expanded(child: GestureDetector(
                    onTap: () => setSt(() => tempMode = mode),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSel ? _C.red : Colors.transparent,
                        borderRadius: BorderRadius.circular(9)),
                      child: Center(child: Text(label, style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: isSel ? Colors.white : _C.textSecondary))),
                    ),
                  ));
                }).toList()),
              ),
            ),
            // Content
            if (tempMode == 'monthly')
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, crossAxisSpacing: 10,
                      mainAxisSpacing: 10, childAspectRatio: 2.2),
                  itemCount: 12,
                  itemBuilder: (_, i) {
                    final isSel = i == tempMonthIdx;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _filterMode = 'monthly';
                          _selectedMonthIndex = i;
                          _selectedDate = null;
                        });
                        onChanged();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: isSel ? _C.red : const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isSel ? _C.red : const Color(0xFFE0F2FE),
                              width: isSel ? 1.5 : 1)),
                        child: Center(child: Text(_translatedMonths[i], style: TextStyle(
                            fontSize: 13, fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            color: isSel ? Colors.white : _C.textPrimary))),
                      ),
                    );
                  },
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _buildDailyCalendar(tempDate,
                  (d) => setSt(() => tempDate = d),
                  onConfirm: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _filterMode = 'daily';
                      _selectedDate = tempDate;
                      _selectedMonthIndex = tempDate.month - 1;
                    });
                    onChanged();
                  },
                ),
              ),
          ]),
        ),
      )),
    );
  }

  Widget _buildDailyCalendar(DateTime selectedDate, ValueChanged<DateTime> onChange,
      {required VoidCallback onConfirm}) {
    final now = DateTime.now();
    final year = now.year; final month = now.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstWeekday = DateTime(year, month, 1).weekday % 7;
    final locale = widget.lang == 'ID' ? 'id_ID' : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    final monthLabel = DateFormat('MMMM yyyy', locale).format(DateTime(year, month));
    final dayLabels = widget.lang == 'ZH'
        ? ['日','一','二','三','四','五','六']
        : widget.lang == 'ID'
            ? ['Min','Sen','Sel','Rab','Kam','Jum','Sab']
            : ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];

    return StatefulBuilder(builder: (_, setIn) => Column(children: [
      Text(monthLabel, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: _C.textPrimary)),
      const SizedBox(height: 10),
      Row(children: dayLabels.map((d) => Expanded(child: Center(
          child: Text(d, style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: _C.textSecondary))))).toList()),
      const SizedBox(height: 6),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, crossAxisSpacing: 4, mainAxisSpacing: 4, childAspectRatio: 1),
        itemCount: firstWeekday + daysInMonth,
        itemBuilder: (_, i) {
          if (i < firstWeekday) return const SizedBox();
          final day  = i - firstWeekday + 1;
          final date = DateTime(year, month, day);
          final isSel   = selectedDate.day == day && selectedDate.month == month;
          final isToday = now.day == day && now.month == month;
          final isFut   = date.isAfter(now);
          return GestureDetector(
            onTap: isFut ? null : () => setIn(() => onChange(date)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isSel ? _C.red : isToday ? const Color(0xFFE0F2FE) : Colors.transparent,
                shape: BoxShape.circle,
                border: isToday && !isSel ? Border.all(color: _C.red, width: 1.2) : null),
              child: Center(child: Text('$day', style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSel || isToday ? FontWeight.bold : FontWeight.normal,
                  color: isSel ? Colors.white : isFut ? _C.textMuted : _C.textPrimary))),
            ),
          );
        },
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.red, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          child: Text(_t('Terapkan', 'Apply', '应用'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ),
    ]));
  }

  // ─── Group picker ─────────────────────────────────────────────────────────────
  void _showGroupPicker() async {
    final allItem = {'id_unit': null, 'nama_unit': _t('Semua Grup', 'All Groups', '所有组')};
    final items   = [allItem, ..._unitList];
    final ctrl    = TextEditingController();
    List<Map<String, dynamic>> filtered = List.from(items);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0F2FE), width: 1.5)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2FE),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              child: Row(children: [
                const Icon(Icons.group_rounded, color: _C.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(_t('Pilih Grup', 'Select Group', '选择组'),
                    style: const TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 15, color: _C.textPrimary))),
                IconButton(icon: const Icon(Icons.close, size: 18, color: _C.textSecondary),
                    onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
              ]),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: TextField(
                controller: ctrl,
                onChanged: (q) => setSt(() {
                  filtered = items.where((e) =>
                      (e['nama_unit'] as String).toLowerCase().contains(q.toLowerCase())).toList();
                }),
                decoration: InputDecoration(
                  hintText: _t('Cari...', 'Search...', '搜索...'),
                  hintStyle: const TextStyle(fontSize: 13, color: _C.textMuted),
                  prefixIcon: const Icon(Icons.search, color: _C.primary, size: 18),
                  filled: true, fillColor: const Color(0xFFF0F9FF),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Color(0xFFE0F2FE))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Color(0xFFE0F2FE))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: _C.primary, width: 1.5)),
                ),
              ),
            ),
            Flexible(child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final item  = filtered[i];
                final lbl   = item['nama_unit'] as String;
                final id    = item['id_unit']?.toString();
                final isSel = id == _selectedUnitId || (id == null && _selectedUnitId == null);
                return InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _selectedUnitId = id);
                    _fetchAll(fromTabFilter: true);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFFE0F2FE) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isSel ? _C.primary : const Color(0xFFE0F2FE),
                          width: isSel ? 1.5 : 1)),
                    child: Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: isSel ? _C.primary : const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(10)),
                        child: Center(child: Text(
                          lbl.isNotEmpty ? lbl[0].toUpperCase() : '?',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                              color: isSel ? Colors.white : _C.primary))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(lbl, style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          color: isSel ? _C.primary : _C.textPrimary))),
                      if (isSel) const Icon(Icons.check_circle_rounded, color: _C.primary, size: 18),
                    ]),
                  ),
                );
              },
            )),
          ]),
        ),
      )),
    );
  }

  // ─── Level picker ─────────────────────────────────────────────────────────────
  void _showLevelPicker() async {
    await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0F2FE), width: 1.5)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2FE),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              child: Row(children: [
                const Icon(Icons.tune_rounded, color: _C.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(_t('Pilih Level', 'Select Level', '选择级别'),
                    style: const TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 15, color: _C.textPrimary))),
                IconButton(icon: const Icon(Icons.close, size: 18, color: _C.textSecondary),
                    onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
              ]),
            ),
            Flexible(child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: _translatedLocationLevels.length,
              itemBuilder: (_, i) {
                final lbl   = _translatedLocationLevels[i];
                final isSel = lbl == _selectedLocationLevel;
                return InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _selectedLocationLevel = lbl);
                    _fetchAll(fromTabFilter: true);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFFE0F2FE) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: isSel ? _C.primary : const Color(0xFFE0F2FE), width: 1)),
                    child: Row(children: [
                      Expanded(child: Text(lbl, style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          color: isSel ? _C.primary : _C.textPrimary))),
                      if (isSel) const Icon(Icons.check_circle_rounded, color: _C.primary, size: 16),
                    ]),
                  ),
                );
              },
            )),
          ]),
        ),
      ),
    );
  }

  // ─── Period picker (Recurring) ────────────────────────────────────────────────
  void _showPeriodPicker() async {
    DateTime tempFrom = _recurringFrom;
    DateTime tempTo   = _recurringTo;
    final locale = widget.lang == 'ID' ? 'id_ID' : widget.lang == 'EN' ? 'en_US' : 'zh_CN';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0F2FE), width: 1.5)),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.date_range_rounded, color: _C.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(_t('Pilih Periode', 'Select Period', '选择期间'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _C.textPrimary))),
              IconButton(icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
            ]),
            const SizedBox(height: 16),
            Text(_t('Dari', 'From', '从'),
                style: const TextStyle(fontSize: 12, color: _C.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _buildYearMonthPicker(tempFrom, locale, (d) => setSt(() => tempFrom = d)),
            const SizedBox(height: 14),
            Text(_t('Sampai', 'To', '到'),
                style: const TextStyle(fontSize: 12, color: _C.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _buildYearMonthPicker(tempTo, locale, (d) => setSt(() => tempTo = d)),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () {
                setState(() { _recurringFrom = tempFrom; _recurringTo = tempTo; });
                Navigator.pop(ctx);
                setState(() => _recurringFuture = _fetchRecurring());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(_t('Terapkan', 'Apply', '应用')),
            )),
          ]),
        ),
      )),
    );
  }

  Widget _buildYearMonthPicker(DateTime current, String locale, ValueChanged<DateTime> onChange) {
    final months = List.generate(12, (i) => DateFormat.MMM(locale).format(DateTime(2000, i + 1)));
    final years  = List.generate(5, (i) => DateTime.now().year - 2 + i);

    Widget dropdown<T>({required T value, required List<T> items,
        required String Function(T) label, required ValueChanged<T?> onChanged}) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0F2FE))),
        child: DropdownButtonHideUnderline(child: DropdownButton<T>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: _C.primary),
          style: const TextStyle(fontSize: 13, color: _C.textPrimary, fontWeight: FontWeight.w600),
          dropdownColor: Colors.white,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(label(e)))).toList(),
          onChanged: onChanged,
        )),
      );
    }

    return Row(children: [
      Expanded(flex: 3, child: dropdown<int>(
        value: current.month - 1,
        items: List.generate(12, (i) => i),
        label: (i) => months[i],
        onChanged: (v) { if (v != null) onChange(DateTime(current.year, v + 1)); },
      )),
      const SizedBox(width: 8),
      Expanded(flex: 2, child: dropdown<int>(
        value: current.year,
        items: years,
        label: (y) => '$y',
        onChanged: (v) { if (v != null) onChange(DateTime(v, current.month)); },
      )),
    ]);
  }

  // ─── User picker (Recurring) ──────────────────────────────────────────────────
  void _showUserPicker() async {
    try {
      final res = await _supabase
          .from('User')
          .select('id_user, nama, gambar_user, jabatan!User_id_jabatan_fkey(nama_jabatan)')
          .order('nama');
      final users   = List<Map<String, dynamic>>.from(res);
      final allItem = {'id_user': null, 'nama': _t('Semua Penemu', 'All Finders', '所有发现者'),
          'gambar_user': null, 'jabatan': null};
      final items   = [allItem, ...users];
      if (!mounted) return;

      final ctrl = TextEditingController();
      List<Map<String, dynamic>> filtered = List.from(items);

      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0F2FE), width: 1.5)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                child: Row(children: [
                  const Icon(Icons.person_search_rounded, color: _C.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_t('Pilih Penemu', 'Select Finder', '选择发现者'),
                      style: const TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 15, color: _C.textPrimary))),
                  IconButton(icon: const Icon(Icons.close, size: 18, color: _C.textSecondary),
                      onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: TextField(
                  controller: ctrl,
                  onChanged: (q) => setSt(() {
                    filtered = items.where((e) =>
                        (e['nama'] as String).toLowerCase().contains(q.toLowerCase())).toList();
                  }),
                  decoration: InputDecoration(
                    hintText: _t('Cari...', 'Search...', '搜索...'),
                    hintStyle: const TextStyle(fontSize: 13, color: _C.textMuted),
                    prefixIcon: const Icon(Icons.search, color: _C.primary, size: 18),
                    filled: true, fillColor: const Color(0xFFF0F9FF),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFFE0F2FE))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFFE0F2FE))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: _C.primary, width: 1.5)),
                  ),
                ),
              ),
              Flexible(child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final item      = filtered[i];
                  final name      = item['nama'] as String;
                  final id        = item['id_user']?.toString();
                  final avatarUrl = item['gambar_user'] as String?;
                  final role      = (item['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'] as String?;
                  final isSel     = id == _recurringUserId || (id == null && _recurringUserId == null);
                  final isAll     = id == null;

                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _recurringUserId   = id;
                        _recurringUserName = isAll
                            ? _t('Semua Penemu', 'All Finders', '所有发现者') : name;
                        _recurringFuture = _fetchRecurring();
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFFE0F2FE) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isSel ? _C.primary : const Color(0xFFE0F2FE),
                            width: isSel ? 1.5 : 1)),
                      child: Row(children: [
                        if (isAll)
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: isSel ? _C.primary : const Color(0xFFF0F9FF),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE0F2FE))),
                            child: Icon(Icons.group_rounded,
                                color: isSel ? Colors.white : _C.primary, size: 20))
                        else if (avatarUrl != null && avatarUrl.isNotEmpty)
                          CircleAvatar(radius: 20, backgroundImage: NetworkImage(avatarUrl),
                              backgroundColor: const Color(0xFFE0F2FE))
                        else
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: isSel ? _C.primary : const Color(0xFFE0F2FE),
                            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                                    color: isSel ? Colors.white : _C.primary))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(isAll ? _t('Semua Penemu', 'All Finders', '所有发现者') : name,
                              style: TextStyle(fontSize: 13,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                  color: isSel ? _C.primary : _C.textPrimary)),
                          if (role != null && role.isNotEmpty)
                            Text(role, style: const TextStyle(fontSize: 11, color: _C.textSecondary)),
                        ])),
                        if (isSel) const Icon(Icons.check_circle_rounded, color: _C.primary, size: 18),
                      ]),
                    ),
                  );
                },
              )),
            ]),
          ),
        )),
      );
    } catch (e) { debugPrint('showUserPicker: $e'); }
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  SUB-WIDGETS (tetap sama persis dengan accident_recurring_tab.dart lama)
// ════════════════════════════════════════════════════════════════════════════

// ─── Card grup recurring ──────────────────────────────────────────────────────
class _AccidentRecurringCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final String lang;
  final VoidCallback onTap;
  const _AccidentRecurringCard({required this.group, required this.lang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final topic       = group['topic'] as String? ?? '-';
    final locationArea = group['locationArea'] as String? ?? '';
    final total       = group['total'] as int? ?? 0;
    final imageUrl    = group['imageUrl'] as String?;
    final severity    = group['severityPattern'] as String? ?? topic;

    Color color; IconData icon;
    final s = severity.toLowerCase();
    if (s.contains('berat') || s.contains('heavy') || s.contains('重')) {
      color = _C.red; icon = Icons.dangerous_rounded;
    } else if (s.contains('menengah') || s.contains('medium') || s.contains('中')) {
      color = _C.amber; icon = Icons.warning_amber_rounded;
    } else {
      color = _C.green; icon = Icons.info_outline_rounded;
    }

    final totalLabel = lang == 'ID' ? 'Total' : lang == 'ZH' ? '总计' : 'Total';
    final sevLabel   = lang == 'ID' ? 'Pola: $severity'
        : lang == 'ZH' ? '模式: $severity' : 'Pattern: $severity';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            child: Container(
              width: 80, height: 80,
              color: color.withOpacity(0.1),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(icon, color: color, size: 32))
                  : Icon(icon, color: color, size: 32),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(topic, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.repeat_rounded, size: 12, color: color.withOpacity(0.7)),
                const SizedBox(width: 3),
                Expanded(child: Text(sevLabel,
                    style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              if (locationArea.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.location_on_rounded, size: 12, color: _C.textSecondary),
                  const SizedBox(width: 3),
                  Expanded(child: Text(locationArea,
                      style: const TextStyle(fontSize: 11, color: _C.textSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              ],
            ]),
          )),
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.3))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(totalLabel, style: TextStyle(fontSize: 9, color: color.withOpacity(0.7))),
              Text('$total', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w900, color: color)),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Card individual accident report ─────────────────────────────────────────
class _AccidentReportCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String lang;
  final String locale;
  const _AccidentReportCard({required this.data, required this.lang, required this.locale});

  @override
  Widget build(BuildContext context) {
    final judul    = (data['judul']             ?? '-').toString();
    final status   = (data['status']            ?? '').toString();
    final tingkat  = (data['tingkat_keparahan'] ?? '').toString();
    final penyebab = (data['penyebab']          ?? '').toString();
    final fotoUrl  = (data['foto_bukti']        ?? '').toString();
    final isSelesai = status == 'Selesai';

    final tanggal = () {
      final v = data['created_at'];
      if (v == null) return '-';
      final dt = v is DateTime ? v : DateTime.tryParse(v.toString());
      return dt != null ? DateFormat('dd/MM/yyyy', locale).format(dt) : '-';
    }();

    String location = '';
    if      (data['area']    != null) location = (data['area']    as Map)['nama_area']    ?? '';
    else if (data['subunit'] != null) location = (data['subunit'] as Map)['nama_subunit'] ?? '';
    else if (data['unit']    != null) location = (data['unit']    as Map)['nama_unit']    ?? '';
    else if (data['lokasi']  != null) location = (data['lokasi']  as Map)['nama_lokasi']  ?? '';

    final statusColor = isSelesai ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final statusBg    = isSelesai ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
    final statusText  = isSelesai
        ? (lang == 'ID' ? 'Selesai' : lang == 'ZH' ? '已完成' : 'Resolved') : status;

    Color sevColor;
    final tl = tingkat.toLowerCase();
    if      (tl.contains('berat')    || tl.contains('heavy'))  sevColor = _C.red;
    else if (tl.contains('menengah') || tl.contains('medium')) sevColor = _C.amber;
    else                                                         sevColor = _C.green;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sevColor.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: sevColor.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sevColor.withOpacity(0.3), width: 1.5)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.5),
                child: fotoUrl.isNotEmpty
                    ? Image.network(fotoUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported, color: Colors.grey))
                    : Container(color: const Color(0xFFF8FAFC),
                        child: const Icon(Icons.warning_amber_rounded,
                            color: Colors.grey, size: 28)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(judul,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: _C.textPrimary),
                    maxLines: 2, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 6),
                if (tingkat.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: sevColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: sevColor, width: 1)),
                    child: Text(tingkat, style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w800, color: sevColor)),
                  ),
              ]),
              const SizedBox(height: 4),
              if (location.isNotEmpty)
                Row(children: [
                  const Icon(Icons.place_rounded, size: 11, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 3),
                  Expanded(child: Text(location,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.calendar_today_rounded, size: 10, color: Color(0xFF94A3B8)),
                const SizedBox(width: 3),
                Text(tanggal, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                  child: Text(statusText, style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                ),
              ]),
            ])),
          ]),
        ),
        if (penyebab.isNotEmpty && penyebab != '-')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: sevColor.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14))),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, size: 12, color: sevColor),
              const SizedBox(width: 5),
              Expanded(child: Text(penyebab,
                  style: TextStyle(fontSize: 11, color: sevColor.withOpacity(0.9),
                      fontWeight: FontWeight.w500),
                  maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]),
          ),
      ]),
    );
  }
}

// ─── Pie chart painter ────────────────────────────────────────────────────────
class _PieChartPainter extends CustomPainter {
  final double primaryValue;
  final double secondaryValue;
  final Color  colorPrimary;
  final Color  colorSecondary;
  const _PieChartPainter({
    required this.primaryValue, required this.secondaryValue,
    required this.colorPrimary, required this.colorSecondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total       = primaryValue + secondaryValue;
    final center      = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.55;
    const gapAngle    = 0.04;

    if (total == 0) {
      canvas.drawCircle(center, (outerRadius + innerRadius) / 2,
        Paint()..color = const Color(0xFFE2E8F0)
              ..style = PaintingStyle.stroke
              ..strokeWidth = outerRadius - innerRadius);
      return;
    }

    final segments = [
      {'value': primaryValue,   'color': colorPrimary},
      {'value': secondaryValue, 'color': colorSecondary},
    ];
    double startAngle = -90 * (math.pi / 180);

    for (final seg in segments) {
      final value = seg['value'] as double;
      final color = seg['color'] as Color;
      if (value <= 0) continue;
      final sweepAngle = (value / total) * 2 * math.pi - gapAngle;

      // Shadow
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: outerRadius), startAngle, sweepAngle, false)
        ..close();
      canvas.drawPath(path,
        Paint()..color = color.withOpacity(0.2)
              ..style = PaintingStyle.fill
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

      // Arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: (outerRadius + innerRadius) / 2),
        startAngle, sweepAngle, false,
        Paint()..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = outerRadius - innerRadius
              ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// ─── Avatar helper ────────────────────────────────────────────────────────────
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
      );
    }
    final initials = name.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    final bg = color ?? _C.primary;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: bg.withOpacity(0.15), shape: BoxShape.circle,
        border: Border.all(color: bg.withOpacity(0.3), width: 1)),
      child: Center(child: Text(initials,
          style: TextStyle(fontSize: size * 0.35, fontWeight: FontWeight.w700, color: bg))),
    );
  }
}