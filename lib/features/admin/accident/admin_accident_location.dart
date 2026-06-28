import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class _C {
  static const primary       = Color(0xFFEF4444);
  static const textPrimary   = Color(0xFF0C4A6E);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted     = Color(0xFFBDBDBD);
  static const divider       = Color(0xFFE0F2FE);
  static const red           = Color(0xFFEF4444);
  static const orange        = Color(0xFFF97316);
}

class AdminLocationData {
  final String  name;
  final String  pic;
  final String? value;
  const AdminLocationData({
    required this.name,
    required this.pic,
    this.value,
  });
}

class AdminAccidentLocationTab extends StatefulWidget {
  final String lang;

  const AdminAccidentLocationTab({
    super.key,
    required this.lang,
  });

  @override
  State<AdminAccidentLocationTab> createState() =>
      AdminAccidentLocationTabState();
}

class AdminAccidentLocationTabState
    extends State<AdminAccidentLocationTab> {
  final _supabase = Supabase.instance.client;

  // FILTER STATE
  String    _filterMode         = 'monthly';
  int       _selectedMonthIndex = DateTime.now().month - 1;
  DateTime? _selectedDate;
  String    _selectedLocationLevel = '';
  DateTime? _lastUpdated;

  late List<String> _translatedMonths;
  late List<String> _translatedLocationLevels;
  final _levelBackends = ['Lokasi', 'Unit', 'Subunit', 'Area'];

  // DATA
  Future<List<AdminLocationData>>? _locationFuture;

  // CHART
  bool _isChartExpanded = false;

  @override
  void initState() {
    super.initState();
    _initLists();
    _fetchData();
  }

  void _initLists() {
    final locale = _locale;
    _translatedMonths = List.generate(
        12, (i) => DateFormat.MMM(locale).format(DateTime(2000, i + 1)));
    _translatedLocationLevels = [
      _t('Lokasi', 'Location', '位置'),
      _t('Unit', 'Unit', '单元'),
      _t('Subunit', 'Sub-unit', '子单元'),
      _t('Area', 'Area', '区域'),
    ];
    _selectedLocationLevel = _translatedLocationLevels[0];
  }

  String get _locale => widget.lang == 'ID'
      ? 'id_ID'
      : widget.lang == 'EN'
          ? 'en_US'
          : 'zh_CN';

  String _t(String id, String en, String zh) {
    if (widget.lang == 'ID') return id;
    if (widget.lang == 'ZH') return zh;
    return en;
  }

  String get _levelBackend {
    final idx = _translatedLocationLevels
        .indexOf(_selectedLocationLevel)
        .clamp(0, 3);
    return _levelBackends[idx];
  }

  String get _activeDateLabel {
    if (_filterMode == 'daily' && _selectedDate != null) {
      return DateFormat('d MMM yyyy', _locale).format(_selectedDate!);
    }
    return DateFormat('MMMM yyyy', _locale)
        .format(DateTime(DateTime.now().year, _selectedMonthIndex + 1));
  }

  String get _lastUpdatedText {
    if (_lastUpdated == null) {
      return _t('Memuat data...', 'Loading data...', '加载数据...');
    }
    final fmt = DateFormat('d MMM yyyy HH:mm',
            widget.lang == 'ID' ? 'id_ID' : 'en_US')
        .format(_lastUpdated!);
    return '${_t('Terakhir diperbarui pada', 'Last updated at', '最后更新于')} $fmt (GMT+7)';
  }

  String get _monthLabel {
    if (_filterMode == 'daily' && _selectedDate != null) {
      return DateFormat('d MMM yyyy', _locale).format(_selectedDate!);
    }
    return DateFormat.MMM(_locale)
        .format(DateTime(2000, _selectedMonthIndex + 1));
  }

  void _fetchData() {
    setState(() {
      _lastUpdated = DateTime.now();
      if (_filterMode == 'daily' && _selectedDate != null) {
        _locationFuture = _fetchLocationDaily(_selectedDate!, _levelBackend);
      } else {
        final month = _selectedMonthIndex + 1;
        final year  = DateTime.now().year;
        _locationFuture = _fetchLocation(month, year, _levelBackend);
      }
    });
  }

  Future<List<AdminLocationData>> _fetchLocation(
      int month, int year, String level) async {
    try {
      final ll      = level.toLowerCase();
      final idCol   = _idColFor(ll);
      final nameCol = _nameColFor(ll);

      final locations = await _supabase.from(ll).select('$idCol, $nameCol');
      final reportRes = await _supabase
          .from('accident_report')
          .select(idCol)
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at',
              DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String())
          .not(idCol, 'is', null);

      final Map<String, int> countMap = {};
      for (final t in reportRes) {
        final id = t[idCol]?.toString() ?? '';
        if (id.isEmpty) continue;
        countMap[id] = (countMap[id] ?? 0) + 1;
      }

      final picRes = await _supabase
          .from('User')
          .select('$idCol, nama')
          .not(idCol, 'is', null);
      final Map<String, String> picMap = {};
      for (final p in picRes) {
        final locId = p[idCol]?.toString() ?? '';
        if (locId.isEmpty || picMap.containsKey(locId)) continue;
        picMap[locId] = p['nama']?.toString() ?? _t('PIC belum diatur', 'PIC not set', 'PIC未设置');
      }

      return (locations as List<dynamic>).map<AdminLocationData>((loc) {
        final id = loc[idCol]?.toString() ?? '';
        return AdminLocationData(
          name:  loc[nameCol]?.toString() ?? '-',
          pic:   picMap[id] ?? _t('PIC belum diatur', 'PIC not set', 'PIC未设置'),
          value: (countMap[id] ?? 0).toString(),
        );
      }).toList()
        ..sort((a, b) =>
            (int.tryParse(b.value ?? '0') ?? 0)
                .compareTo(int.tryParse(a.value ?? '0') ?? 0));
    } catch (e) {
      return [];
    }
  }

  Future<List<AdminLocationData>> _fetchLocationDaily(
      DateTime date, String level) async {
    try {
      final start   = DateTime(date.year, date.month, date.day);
      final end     = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final ll      = level.toLowerCase();
      final idCol   = _idColFor(ll);
      final nameCol = _nameColFor(ll);

      final locations  = await _supabase.from(ll).select('$idCol, $nameCol');
      final reportList = await _supabase
          .from('accident_report')
          .select(idCol)
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());

      final Map<String, int> countMap = {};
      for (final t in reportList) {
        final id = t[idCol]?.toString() ?? '';
        if (id.isEmpty) continue;
        countMap[id] = (countMap[id] ?? 0) + 1;
      }

      return (locations as List<dynamic>).map<AdminLocationData>((loc) {
        final id = loc[idCol]?.toString() ?? '';
        return AdminLocationData(
          name:  loc[nameCol]?.toString() ?? '-',
          pic:   '-',
          value: (countMap[id] ?? 0).toString(),
        );
      }).toList()
        ..sort((a, b) =>
            (int.tryParse(b.value ?? '0') ?? 0)
                .compareTo(int.tryParse(a.value ?? '0') ?? 0));
    } catch (e) {
      return [];
    }
  }

  String _idColFor(String ll) =>
      {'lokasi': 'id_lokasi', 'unit': 'id_unit',
       'subunit': 'id_subunit', 'area': 'id_area'}[ll] ?? 'id_lokasi';

  String _nameColFor(String ll) =>
      {'lokasi': 'nama_lokasi', 'unit': 'nama_unit',
       'subunit': 'nama_subunit', 'area': 'nama_area'}[ll] ?? 'nama_lokasi';

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // FILTER ROW
      _buildFilterRow(),

      // LAST UPDATED
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _lastUpdatedText,
            style: GoogleFonts.poppins(
                fontSize: 11, color: _C.textSecondary, height: 1.4),
          ),
        ),
      ),

      // CHART TOGGLE
      _buildChartToggle(),

      // ANIMATED CHART
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: _isChartExpanded ? _buildPieChartSection() : const SizedBox.shrink(),
      ),

      // TABLE HEADER
      _buildTableHeader(),

      // LIST
      Expanded(child: _buildList()),
    ]);
  }

  Widget _buildFilterRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(children: [
        // DATE FILTER
        _buildFilterBtn(
          label: _monthLabel,
          isActive: true,
          icon: Icons.calendar_month_rounded,
          onTap: _showMonthPicker,
        ),
        const SizedBox(width: 10),
        // LEVEL FILTER
        Expanded(
          child: _buildFilterBtn(
            label: _selectedLocationLevel,
            onTap: _showLevelPicker,
          ),
        ),
      ]),
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
          color: isActive ? _C.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? _C.primary
                : _C.primary.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _C.primary.withValues(alpha: 0.10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : _C.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Icon(icon,
              color: isActive ? Colors.white : _C.primary, size: 18),
        ]),
      ),
    );
  }

  Widget _buildChartToggle() {
    return GestureDetector(
      onTap: () => setState(() => _isChartExpanded = !_isChartExpanded),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: _C.primary.withValues(alpha: 0.4), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: _C.primary.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          Icon(Icons.pie_chart_rounded, size: 16, color: _C.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _t(
                'Grafik $_activeDateLabel',
                'Chart $_activeDateLabel',
                '$_activeDateLabel 图表',
              ),
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _C.primary),
            ),
          ),
          AnimatedRotation(
            turns: _isChartExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 250),
            child: Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: _C.primary),
          ),
        ]),
      ),
    );
  }

  Widget _buildPieChartSection() {
    if (_locationFuture == null) return _buildChartShimmer();
    return FutureBuilder<List<AdminLocationData>>(
      future: _locationFuture,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildChartShimmer();
        }
        final data     = snap.data ?? [];
        final totalAll = data.fold<int>(
            0, (s, l) => s + (int.tryParse(l.value ?? '0') ?? 0));
        final topCount = data.isNotEmpty
            ? (int.tryParse(data.first.value ?? '0') ?? 0)
            : 0;
        final others = totalAll - topCount;
        return _buildPieChart(
          totalPrimary:   topCount,
          totalSecondary: others,
          colorPrimary:   _C.primary,
          colorSecondary: _C.orange,
          labelPrimary: data.isNotEmpty
              ? data.first.name
              : _t('Teratas', 'Top', '最高'),
          labelSecondary:
              _t('Lokasi Lainnya', 'Other Locations', '其他位置'),
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
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPieChart({
    required int      totalPrimary,
    required int      totalSecondary,
    required Color    colorPrimary,
    required Color    colorSecondary,
    required String   labelPrimary,
    required String   labelSecondary,
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
        border: Border.all(color: _C.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // HEADER
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(Icons.pie_chart_rounded, size: 14, color: _C.primary),
            const SizedBox(width: 6),
            Text(
              _t(
                'Ringkasan $_activeDateLabel',
                'Summary $_activeDateLabel',
                '$_activeDateLabel 摘要',
              ),
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _C.primary),
            ),
          ]),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _C.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_t('Total', 'Total', '总计')}: $total',
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _C.primary),
            ),
          ),
        ]),
        const SizedBox(height: 12),

        if (total == 0)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(children: [
                Icon(Icons.pie_chart_outline,
                    size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 6),
                Text(
                  _t('Tidak ada data', 'No data', '暂无数据'),
                  style: GoogleFonts.poppins(
                      color: _C.textSecondary, fontSize: 12),
                ),
              ]),
            ),
          )
        else
          Row(children: [
            SizedBox(
              width: 130,
              height: 130,
              child: CustomPaint(
                painter: _AdminPieChartPainter(
                  primaryValue:   totalPrimary.toDouble(),
                  secondaryValue: totalSecondary.toDouble(),
                  colorPrimary:   colorPrimary,
                  colorSecondary: colorSecondary,
                ),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      '$total',
                      style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _C.textPrimary),
                    ),
                    Text(
                      _t('Total', 'Total', '总计'),
                      style: GoogleFonts.poppins(
                          fontSize: 9, color: _C.textSecondary),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(children: [
                _buildPieCard(
                    colorPrimary, labelPrimary, totalPrimary, total, iconPrimary),
                const SizedBox(height: 8),
                _buildPieCard(
                    colorSecondary, labelSecondary, totalSecondary, total, iconSecondary),
              ]),
            ),
          ]),
      ]),
    );
  }

  Widget _buildPieCard(
      Color color, String label, int value, int total, IconData icon) {
    final pct =
        total > 0 ? (value / total * 100).toStringAsFixed(1) : '0.0';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? value / total : 0,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 3,
              ),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$value',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _C.textPrimary)),
          Text('$pct%',
              style: GoogleFonts.poppins(
                  fontSize: 9,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: const Color(0xFFF8FAFF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        SizedBox(
          width: 40,
          child: Text(
            _t('Rank', 'Rank', '排名'),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _C.textSecondary,
                letterSpacing: 0.2),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            _t('Lokasi', 'Location', '位置'),
            textAlign: TextAlign.left,
            style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _C.textSecondary,
                letterSpacing: 0.2),
          ),
        ),
        SizedBox(
          width: 70,
          child: Text(
            _t('Laporan', 'Reports', '报告'),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _C.textSecondary,
                letterSpacing: 0.2),
          ),
        ),
      ]),
    );
  }

  Widget _buildList() {
    if (_locationFuture == null) return _buildShimmer();
    return FutureBuilder<List<AdminLocationData>>(
      future: _locationFuture,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildShimmer();
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return Center(
            child: Text(
              _t('Tidak ada data lokasi.', 'No location data.', '没有位置数据。'),
              style: GoogleFonts.poppins(color: _C.textSecondary),
            ),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: list.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: _C.divider, indent: 16),
          itemBuilder: (_, i) => _buildLocationRow(i + 1, list[i]),
        );
      },
    );
  }

  Widget _buildLocationRow(int rank, AdminLocationData loc) {
    final count = int.tryParse(loc.value ?? '0') ?? 0;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        // RANK
        SizedBox(
          width: 40,
          child: Text(
            '$rank',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 13,
                color: _C.textSecondary,
                fontWeight: FontWeight.w500),
          ),
        ),
        // LOCATION INFO
        Expanded(
          flex: 3,
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _C.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.location_city_rounded,
                  color: _C.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  loc.name,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _C.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  loc.pic,
                  style: GoogleFonts.poppins(
                      fontSize: 11.5, color: _C.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ]),
            ),
          ]),
        ),
        // COUNT
        SizedBox(
          width: 70,
          child: Text(
            loc.value ?? '0',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: count > 0 ? _C.red : _C.textMuted,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: 8,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: _C.divider, indent: 16),
        itemBuilder: (_, __) => Container(
          color: Colors.white,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            SizedBox(
                width: 40,
                child:
                    Center(child: _shimmerBox(height: 14, width: 20))),
            Expanded(
              flex: 3,
              child: Row(children: [
                _shimmerBox(height: 38, width: 38, borderRadius: 10),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmerBox(height: 14, width: double.infinity),
                        const SizedBox(height: 4),
                        _shimmerBox(height: 12, width: 100),
                      ]),
                ),
              ]),
            ),
            SizedBox(
                width: 70,
                child:
                    Center(child: _shimmerBox(height: 14, width: 20))),
          ]),
        ),
      ),
    );
  }

  Widget _shimmerBox(
      {double? width,
      required double height,
      bool isCircle = false,
      double borderRadius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
            isCircle ? height / 2 : borderRadius),
      ),
    );
  }

  void _showMonthPicker() async {
    String   tempMode     = _filterMode;
    int      tempMonthIdx = _selectedMonthIndex;
    DateTime tempDate     = _selectedDate ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) =>
          StatefulBuilder(builder: (ctx, setSt) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(context).size.height * 0.65,
              maxWidth: 340),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFFE0F2FE), width: 1.5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // HEADER
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2FE),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_month_rounded,
                    color: _C.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _t('Pilih Bulan', 'Select Month', '选择月份'),
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _C.textPrimary),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 18, color: _C.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                  padding: EdgeInsets.zero,
                ),
              ]),
            ),
            // TOGGLE MODE
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0F2FE)),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: ['monthly', 'daily'].map((mode) {
                    final isSel = tempMode == mode;
                    final label = mode == 'monthly'
                        ? _t('Bulanan', 'Monthly', '按月')
                        : _t('Harian', 'Daily', '按日');
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setSt(() => tempMode = mode),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSel
                                ? _C.primary
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSel
                                    ? Colors.white
                                    : _C.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // CONTENT
            if (tempMode == 'monthly')
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: 12,
                  itemBuilder: (_, i) {
                    final isSel = i == tempMonthIdx;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _filterMode         = 'monthly';
                          _selectedMonthIndex = i;
                          _selectedDate       = null;
                        });
                        _fetchData();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: isSel
                              ? _C.primary
                              : const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSel
                                ? _C.primary
                                : const Color(0xFFE0F2FE),
                            width: isSel ? 1.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _translatedMonths[i],
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: isSel
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSel
                                  ? Colors.white
                                  : _C.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _buildDailyCalendar(
                  tempDate,
                  (d) => setSt(() => tempDate = d),
                  onConfirm: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _filterMode         = 'daily';
                      _selectedDate       = tempDate;
                      _selectedMonthIndex = tempDate.month - 1;
                    });
                    _fetchData();
                  },
                ),
              ),
          ]),
        ),
      )),
    );
  }

  Widget _buildDailyCalendar(
    DateTime selectedDate,
    ValueChanged<DateTime> onChange, {
    required VoidCallback onConfirm,
  }) {
    final now          = DateTime.now();
    final year         = now.year;
    final month        = now.month;
    final daysInMonth  = DateUtils.getDaysInMonth(year, month);
    final firstWeekday = DateTime(year, month, 1).weekday % 7;
    final monthLabel   = DateFormat('MMMM yyyy', _locale)
        .format(DateTime(year, month));
    final dayLabels = widget.lang == 'ZH'
        ? ['日', '一', '二', '三', '四', '五', '六']
        : widget.lang == 'ID'
            ? ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
            : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return StatefulBuilder(builder: (_, setIn) => Column(children: [
      Text(
        monthLabel,
        style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _C.textPrimary),
      ),
      const SizedBox(height: 10),
      Row(
        children: dayLabels
            .map((d) => Expanded(
                  child: Center(
                    child: Text(d,
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _C.textSecondary)),
                  ),
                ))
            .toList(),
      ),
      const SizedBox(height: 6),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        itemCount: firstWeekday + daysInMonth,
        itemBuilder: (_, i) {
          if (i < firstWeekday) return const SizedBox();
          final day   = i - firstWeekday + 1;
          final date  = DateTime(year, month, day);
          final isSel = selectedDate.day == day &&
              selectedDate.month == month;
          final isToday = now.day == day && now.month == month;
          final isFut   = date.isAfter(now);
          return GestureDetector(
            onTap: isFut ? null : () => setIn(() => onChange(date)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isSel
                    ? _C.primary
                    : isToday
                        ? const Color(0xFFE0F2FE)
                        : Colors.transparent,
                shape: BoxShape.circle,
                border: isToday && !isSel
                    ? Border.all(color: _C.primary, width: 1.2)
                    : null,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight:
                        isSel || isToday ? FontWeight.bold : FontWeight.normal,
                    color: isSel
                        ? Colors.white
                        : isFut
                            ? _C.textMuted
                            : _C.textPrimary,
                  ),
                ),
              ),
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
            backgroundColor: _C.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          child: Text(
            _t('Terapkan', 'Apply', '应用'),
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ),
    ]));
  }

  void _showLevelPicker() async {
    await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(context).size.height * 0.5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFFE0F2FE), width: 1.5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // HEADER
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2FE),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(children: [
                const Icon(Icons.tune_rounded,
                    color: _C.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _t('Pilih Level', 'Select Level', '选择级别'),
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _C.textPrimary),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 18, color: _C.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                  padding: EdgeInsets.zero,
                ),
              ]),
            ),
            // LIST
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: _translatedLocationLevels.length,
                itemBuilder: (_, i) {
                  final lbl   = _translatedLocationLevels[i];
                  final isSel = lbl == _selectedLocationLevel;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _selectedLocationLevel = lbl);
                      _fetchData();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel
                            ? const Color(0xFFE0F2FE)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSel
                              ? _C.primary
                              : const Color(0xFFE0F2FE),
                          width: 1,
                        ),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Text(
                            lbl,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: isSel
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSel
                                  ? _C.primary
                                  : _C.textPrimary,
                            ),
                          ),
                        ),
                        if (isSel)
                          const Icon(Icons.check_circle_rounded,
                              color: _C.primary, size: 16),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _AdminPieChartPainter extends CustomPainter {
  final double primaryValue;
  final double secondaryValue;
  final Color  colorPrimary;
  final Color  colorSecondary;

  const _AdminPieChartPainter({
    required this.primaryValue,
    required this.secondaryValue,
    required this.colorPrimary,
    required this.colorSecondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total       = primaryValue + secondaryValue;
    final center      = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.55;
    const gapAngle    = 0.04;

    if (total == 0) {
      canvas.drawCircle(
        center,
        (outerRadius + innerRadius) / 2,
        Paint()
          ..color = const Color(0xFFE2E8F0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = outerRadius - innerRadius,
      );
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

      // SHADOW
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: outerRadius),
            startAngle, sweepAngle, false)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill
          ..maskFilter =
              const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // ARC
      canvas.drawArc(
        Rect.fromCircle(
            center: center,
            radius: (outerRadius + innerRadius) / 2),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = color
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