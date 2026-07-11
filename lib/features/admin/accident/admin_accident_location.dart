import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class _C {
  static const textPrimary    = Color(0xFF0C4A6E);
  static const textSecondary  = Color(0xFF64748B);
  static const textMuted      = Color(0xFFBDBDBD);
  static const divider        = Color(0xFFE0F2FE);
  static const red            = Color(0xFFEF4444);
  static const orange         = Color(0xFFF97316);
  static const redLight       = Color(0xFFFEE2E2);
  static const redBorderLight = Color(0xFFFCA5A5);
}

class LocationData {
  final String  name;
  final String  pic;
  final String? value;
  const LocationData({required this.name, required this.pic, this.value});
}

class AdminAccidentLocationTab extends StatefulWidget {
  final String lang;
  const AdminAccidentLocationTab({super.key, required this.lang});

  @override
  State<AdminAccidentLocationTab> createState() =>
      _AdminAccidentLocationTabState();
}

class _AdminAccidentLocationTabState extends State<AdminAccidentLocationTab> {
  final _supabase = Supabase.instance.client;

  // FILTER STATE
  int    _selectedMonthIndex = DateTime.now().month - 1;
  String _filterMode         = 'monthly';
  DateTime? _selectedDate;
  DateTime? _lastUpdated;

  // LOCATION LEVEL FILTER
  String  _selectedLocationLevel = 'Lokasi';
  String? _selectedSpecificLocationId;
  String? _selectedSpecificLocationName;

  // CHART
  bool _isChartExpanded = false;

  // POPUP GUARD (mencegah popup terbuka dobel)
  bool _isMonthPickerOpen = false;
  bool _isLevelPickerOpen = false;

  late List<String> _translatedMonths;
  late List<String> _translatedLocationLevels;
  final _levelBackends = ['Lokasi', 'Unit', 'Subunit', 'Area'];

  Future<List<LocationData>>? locationFuture;

  @override
  void initState() {
    super.initState();
    _initLists();
    fetchData();
  }

  void _initLists() {
    final locale = widget.lang == 'ID'
        ? 'id_ID'
        : widget.lang == 'EN'
            ? 'en_US'
            : 'zh_CN';
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

  String get _levelBackend {
    final idx =
        _translatedLocationLevels.indexOf(_selectedLocationLevel).clamp(0, 3);
    return _levelBackends[idx];
  }

  String _t(String id, String en, String zh) {
    if (widget.lang == 'ID') return id;
    if (widget.lang == 'ZH') return zh;
    return en;
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

  String get _activeDateLabel {
    final locale = widget.lang == 'ID'
        ? 'id_ID'
        : widget.lang == 'EN'
            ? 'en_US'
            : 'zh_CN';
    if (_filterMode == 'daily' && _selectedDate != null) {
      return DateFormat('d MMM yyyy', locale).format(_selectedDate!);
    }
    return DateFormat('MMMM yyyy', locale)
        .format(DateTime(DateTime.now().year, _selectedMonthIndex + 1));
  }

  String get _monthLabel {
    final locale = widget.lang == 'ID'
        ? 'id_ID'
        : widget.lang == 'EN'
            ? 'en_US'
            : 'zh_CN';
    return DateFormat.MMM(locale)
        .format(DateTime(2000, _selectedMonthIndex + 1));
  }

  // FETCH TRIGGER
  void fetchData() {
    final month = _selectedMonthIndex + 1;
    final year  = DateTime.now().year;

    setState(() {
      _lastUpdated = DateTime.now();
      if (_filterMode == 'daily' && _selectedDate != null) {
        locationFuture = _fetchLocationDaily(
            _selectedDate!, _levelBackend, _selectedSpecificLocationId);
      } else {
        locationFuture = _fetchLocation(
            month, year, _levelBackend, _selectedSpecificLocationId);
      }
    });
  }

  // MONTHLY FETCH
  Future<List<LocationData>> _fetchLocation(
      int month, int year, String level, String? specificLocationId) async {
    try {
      final ll      = level.toLowerCase();
      final idCol   = _idColFor(ll);
      final nameCol = _nameColFor(ll);

      var locQuery = _supabase.from(ll).select('$idCol, $nameCol, id_pic');
      if (specificLocationId != null) {
        locQuery = locQuery.eq(idCol, specificLocationId);
      }
      final List<dynamic> locations = await locQuery;
      final List<dynamic> reportRes = await _supabase
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

      final picIds = locations
          .map((loc) => loc['id_pic']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      final Map<String, String> picMap = {};
      if (picIds.isNotEmpty) {
        final List<dynamic> picRes = await _supabase
            .from('User')
            .select('id_user, nama')
            .inFilter('id_user', picIds);
        for (final p in picRes) {
          final userId = p['id_user']?.toString() ?? '';
          if (userId.isEmpty) continue;
          picMap[userId] = p['nama']?.toString() ?? 'PIC belum diatur';
        }
      }

      return locations.map<LocationData>((loc) {
        final id    = loc[idCol]?.toString() ?? '';
        final picId = loc['id_pic']?.toString();
        return LocationData(
          name: loc[nameCol]?.toString() ?? '-',
          pic: (picId != null && picMap.containsKey(picId))
              ? picMap[picId]!
              : 'PIC belum diatur',
          value: (countMap[id] ?? 0).toString(),
        );
      }).toList()
        ..sort((a, b) => (int.tryParse(b.value ?? '0') ?? 0)
            .compareTo(int.tryParse(a.value ?? '0') ?? 0));
    } catch (e) {
      return [];
    }
  }

  // DAILY FETCH
  Future<List<LocationData>> _fetchLocationDaily(
      DateTime date, String level, String? specificLocationId) async {
    try {
      final start   = DateTime(date.year, date.month, date.day);
      final end     = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final ll      = level.toLowerCase();
      final idCol   = _idColFor(ll);
      final nameCol = _nameColFor(ll);

      var locQuery = _supabase.from(ll).select('$idCol, $nameCol, id_pic');
      if (specificLocationId != null) {
        locQuery = locQuery.eq(idCol, specificLocationId);
      }
      final locations  = await locQuery;
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

      final picIds = (locations as List<dynamic>)
          .map((loc) => loc['id_pic']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      final Map<String, String> picMap = {};
      if (picIds.isNotEmpty) {
        final List<dynamic> picRes = await _supabase
            .from('User')
            .select('id_user, nama')
            .inFilter('id_user', picIds);
        for (final p in picRes) {
          final userId = p['id_user']?.toString() ?? '';
          if (userId.isEmpty) continue;
          picMap[userId] = p['nama']?.toString() ?? 'PIC belum diatur';
        }
      }

      return locations.map<LocationData>((loc) {
        final picId = loc['id_pic']?.toString();
        return LocationData(
          name: loc[nameCol]?.toString() ?? '-',
          pic: (picId != null && picMap.containsKey(picId))
              ? picMap[picId]!
              : 'PIC belum diatur',
          value: (countMap[loc[idCol]?.toString() ?? ''] ?? 0).toString(),
        );
      }).toList()
        ..sort((a, b) => (int.tryParse(b.value ?? '0') ?? 0)
            .compareTo(int.tryParse(a.value ?? '0') ?? 0));
    } catch (e) {
      return [];
    }
  }

  // COLUMN HELPER
  String _idColFor(String ll) => {
        'lokasi': 'id_lokasi',
        'unit': 'id_unit',
        'subunit': 'id_subunit',
        'area': 'id_area',
      }[ll] ??
      'id_lokasi';

  String _nameColFor(String ll) => {
        'lokasi': 'nama_lokasi',
        'unit': 'nama_unit',
        'subunit': 'nama_subunit',
        'area': 'nama_area',
      }[ll] ??
      'nama_lokasi';

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildConditionalChart(),
      // FILTER ROW
      Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          Expanded(child: _buildLocationTimeFilterButton()),
          const SizedBox(width: 10),
          Expanded(child: _buildLocationLevelFilterButton()),
        ]),
      ),
      _buildLastUpdatedWidget(),
      _buildTableHeader(),
      Expanded(
        child: locationFuture == null
            ? _buildShimmer()
            : FutureBuilder<List<LocationData>>(
                future: locationFuture,
                builder: (_, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return _buildShimmer();
                  }
                  final list = snap.data ?? [];
                  if (list.isEmpty) {
                    return Center(
                        child: Text(
                            _t('Tidak ada data lokasi.', 'No location data.',
                                '没有位置数据。'),
                            style: const TextStyle(color: _C.textSecondary)));
                  }
                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, color: _C.divider, indent: 16),
                    itemBuilder: (_, i) => _buildLocationRow(i + 1, list[i]),
                  );
                },
              ),
      ),
    ]);
  }

  // CHART TOGGLE + PIE CHART
  Widget _buildConditionalChart() {
    return Column(children: [
      GestureDetector(
        onTap: () => setState(() => _isChartExpanded = !_isChartExpanded),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.red.withValues(alpha: 0.4), width: 1.2),
            boxShadow: [
              BoxShadow(
                  color: _C.red.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(children: [
            Icon(Icons.bar_chart_rounded, size: 16, color: _C.red),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
              _t('Grafik $_activeDateLabel', 'Chart $_activeDateLabel',
                  '$_activeDateLabel 图表'),
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: _C.red),
            )),
            AnimatedRotation(
              turns: _isChartExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              child: const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 20, color: _C.red),
            ),
          ]),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: _isChartExpanded
            ? _buildLocationPieChart()
            : const SizedBox.shrink(),
      ),
    ]);
  }

  Widget _buildLocationPieChart() {
    final future = locationFuture;
    if (future == null) return _buildChartShimmer();
    return FutureBuilder<List<LocationData>>(
      future: future,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildChartShimmer();
        }
        final data = snap.data ?? [];
        final totalAll = data.fold<int>(
            0, (s, l) => s + (int.tryParse(l.value ?? '0') ?? 0));
        final topCount = data.isNotEmpty
            ? (int.tryParse(data.first.value ?? '0') ?? 0)
            : 0;
        final others = totalAll - topCount;
        return _buildPieChart(
          totalPrimary: topCount,
          totalSecondary: others,
          colorPrimary: _C.red,
          colorSecondary: _C.orange,
          labelPrimary:
              data.isNotEmpty ? data.first.name : _t('Teratas', 'Top', '最高'),
          labelSecondary:
              _t('Lokasi Lainnya', 'Other Locations', '其他位置'),
          iconPrimary: Icons.location_on_rounded,
          iconSecondary: Icons.more_horiz_rounded,
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
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPieChart({
    required int totalPrimary,
    required int totalSecondary,
    required Color colorPrimary,
    required Color colorSecondary,
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
        border: Border.all(color: _C.red.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: _C.red.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const Icon(Icons.pie_chart_rounded, size: 14, color: _C.red),
            const SizedBox(width: 6),
            Text(
              _t('Ringkasan $_activeDateLabel', 'Summary $_activeDateLabel',
                  '$_activeDateLabel 摘要'),
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: _C.red),
            ),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _C.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_t('Total', 'Total', '总计')}: $total',
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: _C.red),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        if (total == 0)
          Center(
              child: Padding(
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
              width: 130,
              height: 130,
              child: CustomPaint(
                painter: _PieChartPainter(
                  primaryValue: totalPrimary.toDouble(),
                  secondaryValue: totalSecondary.toDouble(),
                  colorPrimary: colorPrimary,
                  colorSecondary: colorSecondary,
                ),
                child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$total',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _C.textPrimary)),
                  Text(_t('Total', 'Total', '总计'),
                      style:
                          const TextStyle(fontSize: 9, color: _C.textSecondary)),
                ])),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(children: [
              _buildPieCard(
                  colorPrimary, labelPrimary, totalPrimary, total, iconPrimary),
              const SizedBox(height: 8),
              _buildPieCard(colorSecondary, labelSecondary, totalSecondary,
                  total, iconSecondary),
            ])),
          ]),
      ]),
    );
  }

  Widget _buildPieCard(
      Color color, String label, int value, int total, IconData icon) {
    final pct = total > 0 ? (value / total * 100).toStringAsFixed(1) : '0.0';
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
          decoration:
              BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style:
                  TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
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
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$value',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: _C.textPrimary)),
          Text('$pct%',
              style:
                  TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  // TIME FILTER BUTTON
  Widget _buildLocationTimeFilterButton() {
    final isActive = _filterMode == 'daily';
    final modeLabel =
        _filterMode == 'daily' ? _t('Harian', 'Daily', '按日') : _t('Bulanan', 'Monthly', '按月');
    final valueLabel = _filterMode == 'daily' && _selectedDate != null
        ? DateFormat('d MMM yyyy',
                widget.lang == 'ID' ? 'id_ID' : widget.lang == 'EN' ? 'en_US' : 'zh_CN')
            .format(_selectedDate!)
        : _monthLabel;

    return GestureDetector(
      onTap: () => _showMonthPicker(fetchData),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? _C.red : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _C.red : _C.redBorderLight,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
                color: _C.red.withValues(alpha: 0.10),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month_rounded, size: 15,
                    color: isActive ? Colors.white : _C.red),
                const SizedBox(width: 5),
                Flexible(
                  child: Text('$modeLabel · $valueLabel',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : _C.red)),
                ),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded,
              color: isActive ? Colors.white : _C.red, size: 18),
        ]),
      ),
    );
  }

  // LEVEL FILTER BUTTON
  Widget _buildLocationLevelFilterButton() {
    final hasSpecificLocation = _selectedSpecificLocationName != null &&
        _selectedSpecificLocationName!.isNotEmpty;
    final isActive = hasSpecificLocation ||
        _selectedLocationLevel != _translatedLocationLevels[0];
    final label =
        hasSpecificLocation ? _selectedSpecificLocationName! : _selectedLocationLevel;

    return GestureDetector(
      onTap: _showLevelPicker,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? _C.red : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _C.red : _C.redBorderLight,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
                color: _C.red.withValues(alpha: 0.10),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          Expanded(
            child: Text(label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : _C.red)),
          ),
          Icon(Icons.keyboard_arrow_down_rounded,
              color: isActive ? Colors.white : _C.red, size: 18),
        ]),
      ),
    );
  }

  // LAST UPDATED
  Widget _buildLastUpdatedWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _C.redLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.access_time_filled_rounded, size: 13, color: _C.red),
            const SizedBox(width: 6),
            Text(_lastUpdatedText,
                style: const TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w600, color: _C.textPrimary)),
          ]),
        ),
      ),
    );
  }

  // PIC BADGE
  Widget _buildPicBadge(String picName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _C.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.red.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.assignment_ind_rounded, size: 10, color: _C.red),
        const SizedBox(width: 3),
        Flexible(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: 'PIC : ',
                  style: TextStyle(
                      fontSize: 9.5, fontWeight: FontWeight.w700, color: _C.red)),
              TextSpan(
                  text: picName,
                  style: TextStyle(
                      fontSize: 9.5, fontWeight: FontWeight.w700, color: _C.red)),
            ]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }

  // TABLE HEADER
  Widget _buildTableHeader() {
    return Container(
      color: const Color(0xFFF8FAFF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        SizedBox(
          width: 40,
          child: Text(_t('Rank', 'Rank', '排名'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                  color: _C.textSecondary, letterSpacing: 0.2)),
        ),
        Expanded(
          flex: 3,
          child: Text(_t('Lokasi', 'Location', '位置'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                  color: _C.textSecondary, letterSpacing: 0.2)),
        ),
        SizedBox(
          width: 70,
          child: Text(_t('Laporan', 'Reports', '报告'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                  color: _C.textSecondary, letterSpacing: 0.2)),
        ),
      ]),
    );
  }

  // LOCATION ROW
  Widget _buildLocationRow(int rank, LocationData loc) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        SizedBox(
          width: 40,
          child: Text('$rank',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: _C.textSecondary, fontWeight: FontWeight.w500)),
        ),
        Expanded(
            flex: 3,
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: _C.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.location_city_rounded, color: _C.red, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(loc.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: _C.textPrimary),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                _buildPicBadge(loc.pic),
              ])),
            ])),
        SizedBox(
          width: 70,
          child: Text(loc.value ?? '0',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: (int.tryParse(loc.value ?? '0') ?? 0) > 0
                      ? _C.red
                      : _C.textMuted)),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            SizedBox(width: 40, child: Center(child: _shimmerBox(height: 14, width: 20))),
            Expanded(
                flex: 3,
                child: Row(children: [
                  _shimmerBox(height: 38, width: 38, borderRadius: 10),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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

  Widget _shimmerBox(
      {double? width, required double height, bool isCircle = false, double borderRadius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCircle ? height / 2 : borderRadius),
      ),
    );
  }

  // MONTH / DAILY PICKER
  void _showMonthPicker(VoidCallback onChanged) async {
    if (_isMonthPickerOpen) return;
    _isMonthPickerOpen = true;

    String tempMode = _filterMode;
    int tempMonthIdx = _selectedMonthIndex;
    DateTime tempDate = _selectedDate ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSt) => Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.65, maxWidth: 340),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE0F2FE), width: 1.5)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    // HEADER
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                      decoration: const BoxDecoration(
                          color: Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                      child: Row(children: [
                        const Icon(Icons.calendar_month_rounded, color: _C.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_t('Pilih Bulan', 'Select Month', '选择月份'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: _C.textPrimary))),
                        IconButton(
                            icon: const Icon(Icons.close, size: 18, color: _C.textSecondary),
                            onPressed: () => Navigator.pop(ctx),
                            padding: EdgeInsets.zero),
                      ]),
                    ),
                    // TOGGLE
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Container(
                        decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE0F2FE))),
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
                                  color: isSel ? _C.red : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9)),
                              child: Center(
                                  child: Text(label,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isSel ? Colors.white : _C.textSecondary))),
                            ),
                          ));
                        }).toList()),
                      ),
                    ),
                    // CONTENT
                    if (tempMode == 'monthly')
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 2.2),
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
                                child: Center(
                                    child: Text(_translatedMonths[i],
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight:
                                                isSel ? FontWeight.bold : FontWeight.w500,
                                            color: isSel ? Colors.white : _C.textPrimary))),
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
    _isMonthPickerOpen = false;
  }

  Widget _buildDailyCalendar(DateTime selectedDate, ValueChanged<DateTime> onChange,
      {required VoidCallback onConfirm}) {
    final now = DateTime.now();
    final locale =
        widget.lang == 'ID' ? 'id_ID' : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    final dayLabels = widget.lang == 'ZH'
        ? ['日', '一', '二', '三', '四', '五', '六']
        : widget.lang == 'ID'
            ? ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
            : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    DateTime displayedMonth = DateTime(selectedDate.year, selectedDate.month);

    return StatefulBuilder(builder: (_, setIn) {
      final year  = displayedMonth.year;
      final month = displayedMonth.month;
      final daysInMonth    = DateUtils.getDaysInMonth(year, month);
      final firstWeekday   = DateTime(year, month, 1).weekday % 7;
      final monthLabel     = DateFormat('MMMM yyyy', locale).format(DateTime(year, month));
      final isCurrentMonth = year == now.year && month == now.month;

      return Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
            onPressed: () => setIn(() => displayedMonth = DateTime(year, month - 1)),
            icon: const Icon(Icons.chevron_left_rounded, color: _C.red, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
          Text(monthLabel,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _C.textPrimary)),
          IconButton(
            onPressed: isCurrentMonth
                ? null
                : () => setIn(() => displayedMonth = DateTime(year, month + 1)),
            icon: Icon(Icons.chevron_right_rounded,
                color: isCurrentMonth ? _C.textMuted : _C.red, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
        ]),
        const SizedBox(height: 10),
        Row(
            children: dayLabels
                .map((d) => Expanded(
                    child: Center(
                        child: Text(d,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _C.textSecondary)))))
                .toList()),
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
            final isSel = selectedDate.year == year &&
                selectedDate.month == month &&
                selectedDate.day == day;
            final isToday = now.year == year && now.month == month && now.day == day;
            final isFut   = date.isAfter(now);
            return GestureDetector(
              onTap: isFut ? null : () => setIn(() => onChange(date)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                    color: isSel
                        ? _C.red
                        : isToday
                            ? const Color(0xFFE0F2FE)
                            : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isToday && !isSel ? Border.all(color: _C.red, width: 1.2) : null),
                child: Center(
                    child: Text('$day',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel || isToday ? FontWeight.bold : FontWeight.normal,
                            color: isSel
                                ? Colors.white
                                : isFut
                                    ? _C.textMuted
                                    : _C.textPrimary))),
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
              backgroundColor: _C.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(_t('Terapkan', 'Apply', '应用'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ),
      ]);
    });
  }

  // LEVEL & SPECIFIC LOCATION PICKER
  void _showLevelPicker() async {
    if (_isLevelPickerOpen) return;
    _isLevelPickerOpen = true;

    String tempLevelLabel = _selectedLocationLevel;
    String? tempSelectedId = _selectedSpecificLocationId;
    final searchCtrl = TextEditingController();
    List<Map<String, dynamic>> items = [];
    bool levelDropdownOpen = false;

    final GlobalKey levelBtnKey = GlobalKey();
    final GlobalKey stackKey = GlobalKey();
    double dropdownTop = 102;
    double dropdownRight = 14;

    IconData levelIcon(String label) {
      final idx = _translatedLocationLevels.indexOf(label).clamp(0, 3);
      return [
        Icons.location_city_rounded, // LOCATION
        Icons.business_rounded, // UNIT
        Icons.layers_rounded, // SUBUNIT
        Icons.place_rounded, // AREA
      ][idx];
    }

    Color levelColor(String label) {
      final idx = _translatedLocationLevels.indexOf(label).clamp(0, 3);
      return [
        const Color(0xFF10B981), // LOCATION
        const Color(0xFF6366F1), // UNIT
        const Color(0xFFFBBF24), // SUBUNIT
        const Color(0xFFF472B6), // AREA
      ][idx];
    }

    Future<List<Map<String, dynamic>>> fetchItemsForLevel(String levelLabel) async {
      final levelBackend =
          _levelBackends[_translatedLocationLevels.indexOf(levelLabel).clamp(0, 3)];
      final levelLower = levelBackend.toLowerCase();
      final idMap = {
        'lokasi': 'id_lokasi',
        'unit': 'id_unit',
        'subunit': 'id_subunit',
        'area': 'id_area'
      };
      final nameMap = {
        'lokasi': 'nama_lokasi',
        'unit': 'nama_unit',
        'subunit': 'nama_subunit',
        'area': 'nama_area'
      };
      final idCol = idMap[levelLower] ?? 'id_lokasi';
      final nameCol = nameMap[levelLower] ?? 'nama_lokasi';
      try {
        final res = await _supabase.from(levelLower).select('$idCol, $nameCol').order(nameCol);
        return List<Map<String, dynamic>>.from(res)
            .map((e) => {'id': e[idCol]?.toString() ?? '', 'name': e[nameCol]?.toString() ?? '-'})
            .toList();
      } catch (e) {
        debugPrint('Error fetching level items: $e');
        return [];
      }
    }

    // FETCH DATA DULU SEBELUM DIALOG DIBUKA
    items = await fetchItemsForLevel(tempLevelLabel);

    if (!mounted) {
      _isLevelPickerOpen = false;
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          final query = searchCtrl.text.trim().toLowerCase();
          final filteredItems = query.isEmpty
              ? items
              : items.where((e) => (e['name'] as String).toLowerCase().contains(query)).toList();
          final currentLevelColor = levelColor(tempLevelLabel);

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 340,
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE0F2FE), width: 1.5)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(key: stackKey, clipBehavior: Clip.none, children: [
                  Column(children: [
                    // HEADER
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                      decoration: const BoxDecoration(
                          color: Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                      child: Row(children: [
                        const Icon(Icons.tune_rounded, color: _C.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_t('Pilih Lokasi', 'Select Location', '选择位置'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: _C.textPrimary))),
                        IconButton(
                            icon: const Icon(Icons.close, size: 18, color: _C.textSecondary),
                            onPressed: () => Navigator.pop(ctx),
                            padding: EdgeInsets.zero),
                      ]),
                    ),
                    // SEARCH + LEVEL DROPDOWN TRIGGER
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _C.red.withValues(alpha: 0.35), width: 1.3),
                              boxShadow: [
                                BoxShadow(
                                    color: _C.red.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: TextField(
                              controller: searchCtrl,
                              onChanged: (_) => setSt(() {}),
                              style: const TextStyle(
                                  fontSize: 13, color: _C.textPrimary, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                hintText: _t('Cari...', 'Search...', '搜索...'),
                                hintStyle: const TextStyle(fontSize: 12.5, color: _C.textMuted),
                                prefixIcon: const Icon(Icons.search_rounded, color: _C.red, size: 19),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          key: levelBtnKey,
                          onTap: () {
                            final btnBox = levelBtnKey.currentContext!.findRenderObject() as RenderBox;
                            final stackBox = stackKey.currentContext!.findRenderObject() as RenderBox;
                            final btnPos = btnBox.localToGlobal(Offset.zero, ancestor: stackBox);
                            setSt(() {
                              dropdownTop = btnPos.dy + btnBox.size.height + 6;
                              dropdownRight = stackBox.size.width - (btnPos.dx + btnBox.size.width);
                              levelDropdownOpen = !levelDropdownOpen;
                            });
                          },
                          child: Container(
                            width: 132,
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: currentLevelColor,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                    color: currentLevelColor.withValues(alpha: 0.30),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3))
                              ],
                            ),
                            child: Row(children: [
                              Icon(levelIcon(tempLevelLabel), color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                  child: Text(tempLevelLabel,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white))),
                              AnimatedRotation(
                                turns: levelDropdownOpen ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: const Icon(Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white, size: 18),
                              ),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                    const Divider(height: 1, color: _C.divider),
                    // HASIL
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        children: [
                          // OPSI "SEMUA"
                          InkWell(
                            onTap: () {
                              Navigator.pop(ctx);
                              setState(() {
                                _selectedLocationLevel = tempLevelLabel;
                                _selectedSpecificLocationId = null;
                                _selectedSpecificLocationName = null;
                              });
                              fetchData();
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: tempSelectedId == null
                                    ? currentLevelColor.withValues(alpha: 0.10)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: tempSelectedId == null ? currentLevelColor : _C.divider,
                                    width: tempSelectedId == null ? 1.5 : 1),
                              ),
                              child: Row(children: [
                                Icon(Icons.apps_rounded,
                                    size: 18,
                                    color: tempSelectedId == null ? currentLevelColor : _C.textSecondary),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text('${_t('Semua', 'All', '全部')} ($tempLevelLabel)',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: tempSelectedId == null
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: tempSelectedId == null
                                                ? currentLevelColor
                                                : _C.textPrimary))),
                                if (tempSelectedId == null)
                                  Icon(Icons.check_circle_rounded, color: currentLevelColor, size: 18),
                              ]),
                            ),
                          ),
                          if (filteredItems.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                    _t('Tidak ada data untuk level ini.', 'No data for this level.',
                                        '此级别没有数据。'),
                                    style: const TextStyle(fontSize: 12.5, color: _C.textSecondary)),
                              ),
                            )
                          else
                            ...filteredItems.map((item) {
                              final isSel = item['id'] == tempSelectedId;
                              return InkWell(
                                onTap: () {
                                  Navigator.pop(ctx);
                                  setState(() {
                                    _selectedLocationLevel = tempLevelLabel;
                                    _selectedSpecificLocationId = item['id'] as String;
                                    _selectedSpecificLocationName = item['name'] as String;
                                  });
                                  fetchData();
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSel ? currentLevelColor.withValues(alpha: 0.10) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: isSel ? currentLevelColor : _C.divider,
                                        width: isSel ? 1.5 : 1),
                                  ),
                                  child: Row(children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: isSel ? currentLevelColor : const Color(0xFFF8FAFF),
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Icon(levelIcon(tempLevelLabel),
                                          size: 17, color: isSel ? Colors.white : currentLevelColor),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(item['name'] as String,
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      isSel ? FontWeight.bold : FontWeight.w500,
                                                  color: isSel ? currentLevelColor : _C.textPrimary),
                                              overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                            decoration: BoxDecoration(
                                              color: currentLevelColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                  color: currentLevelColor.withValues(alpha: 0.4)),
                                            ),
                                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                                              Icon(levelIcon(tempLevelLabel),
                                                  size: 9, color: currentLevelColor),
                                              const SizedBox(width: 3),
                                              Text(tempLevelLabel,
                                                  style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w700,
                                                      color: currentLevelColor)),
                                            ]),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    if (isSel)
                                      Icon(Icons.check_circle_rounded, color: currentLevelColor, size: 18),
                                  ]),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ]),

                  // BARRIER
                  if (levelDropdownOpen)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => setSt(() => levelDropdownOpen = false),
                        child: Container(color: Colors.transparent),
                      ),
                    ),

                  // DROPDOWN PANEL
                  if (levelDropdownOpen)
                    Positioned(
                      top: dropdownTop,
                      right: dropdownRight,
                      width: 132,
                      child: Material(
                        elevation: 10,
                        borderRadius: BorderRadius.circular(12),
                        shadowColor: Colors.black.withValues(alpha: 0.25),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _C.divider),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: _translatedLocationLevels.map((lvl) {
                              final isSel = lvl == tempLevelLabel;
                              final color = levelColor(lvl);
                              return InkWell(
                                onTap: () async {
                                  tempLevelLabel = lvl;
                                  tempSelectedId = null;
                                  searchCtrl.clear();
                                  levelDropdownOpen = false;
                                  items = [];
                                  setSt(() {});
                                  final res = await fetchItemsForLevel(lvl);
                                  items = res;
                                  setSt(() {});
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: isSel ? color.withValues(alpha: 0.12) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(children: [
                                    Icon(levelIcon(lvl), size: 16, color: isSel ? color : _C.textSecondary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(lvl,
                                            style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                                color: isSel ? color : _C.textPrimary))),
                                    if (isSel) Icon(Icons.check_rounded, size: 15, color: color),
                                  ]),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          );
        },
      ),
    );
    _isLevelPickerOpen = false;
  }
}

// PIE CHART PAINTER
class _PieChartPainter extends CustomPainter {
  final double primaryValue;
  final double secondaryValue;
  final Color colorPrimary;
  final Color colorSecondary;
  const _PieChartPainter({
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
            ..strokeWidth = outerRadius - innerRadius);
      return;
    }

    final segments = [
      {'value': primaryValue, 'color': colorPrimary},
      {'value': secondaryValue, 'color': colorSecondary},
    ];
    double startAngle = -90 * (math.pi / 180);

    for (final seg in segments) {
      final value = seg['value'] as double;
      final color = seg['color'] as Color;
      if (value <= 0) continue;
      final sweepAngle = (value / total) * 2 * math.pi - gapAngle;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: outerRadius), startAngle, sweepAngle, false)
        ..close();
      canvas.drawPath(
          path,
          Paint()
            ..color = color.withValues(alpha: 0.2)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: (outerRadius + innerRadius) / 2),
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