import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'accident_location_tab.dart';
import 'accident_members_tab.dart';
import 'accident_recurring_tab.dart';

class _C {
  static const primary         = Color(0xFF0EA5E9);
  static const textPrimary     = Color(0xFF0C4A6E);
  static const textSecondary   = Color(0xFF64748B);
  static const textMuted       = Color(0xFFBDBDBD);
  static const red             = Color(0xFFEF4444);
  static const green           = Color(0xFF10B981);
  static const orange          = Color(0xFFF97316);
}

class AnalyticsAccidentTab extends StatefulWidget {
  final String lang;
  const AnalyticsAccidentTab({super.key, required this.lang});

  @override
  State<AnalyticsAccidentTab> createState() => _AnalyticsAccidentTabState();
}

class _AnalyticsAccidentTabState extends State<AnalyticsAccidentTab>
    with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  int _activeTabIndex = 0;

  // FILTER STATE
  int    _selectedMonthIndex = DateTime.now().month - 1;
  String _filterMode         = 'monthly';
  DateTime? _selectedDate;
  String? _selectedUnitId;
  String  _selectedLocationLevel = 'Lokasi';
  DateTime? _lastUpdated;

  // CHART
  bool _isChartExpanded      = false;
  bool _isChartLoadingForTab = false;

  // DATA FUTURES
  final _membersTabKey = GlobalKey<AccidentMembersTabState>();
  final _locationTabKey = GlobalKey<AccidentLocationTabState>();
  final _recurringTabKey = GlobalKey<AccidentRecurringTabState>();

  List<Map<String, dynamic>> _unitList = [];
  late List<String> _translatedMonths;
  late List<String> _translatedLocationLevels;
  final _levelBackends = ['Lokasi', 'Unit', 'Subunit', 'Area'];

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
    _selectedLocationLevel = _translatedLocationLevels[0];
  }

  // FETCH HELPERS
  Future<void> _fetchUnits() async {
    try {
      final res = await _supabase.from('unit').select('id_unit, nama_unit');
      if (mounted) setState(() => _unitList = List<Map<String, dynamic>>.from(res));
    } catch (e) { debugPrint('fetchUnits: $e'); }
  }

  void _fetchAll({bool fromTabFilter = false}) {
    if (!fromTabFilter) _isChartLoadingForTab = false;

    setState(() => _lastUpdated = DateTime.now());

    _membersTabKey.currentState?.fetchData(
      filterMode:         _filterMode,
      selectedMonthIndex: _selectedMonthIndex,
      selectedDate:       _selectedDate,
      selectedUnitId:     _selectedUnitId,
    );

    _locationTabKey.currentState?.fetchData(
      filterMode:         _filterMode,
      selectedMonthIndex: _selectedMonthIndex,
      selectedDate:       _selectedDate,
      levelBackend:       _levelBackend,
    );
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

  // LEVEL HELPER
  String get _levelBackend {
    final idx = _translatedLocationLevels.indexOf(_selectedLocationLevel).clamp(0, 3);
    return _levelBackends[idx];
  }

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

  // MONTH LABEL
  String get _activeDateLabel {
    final locale = widget.lang == 'ID' ? 'id_ID'
        : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    if (_filterMode == 'daily' && _selectedDate != null) {
      return DateFormat('d MMM yyyy', locale).format(_selectedDate!);
    }
    return DateFormat('MMMM yyyy', locale)
        .format(DateTime(DateTime.now().year, _selectedMonthIndex + 1));
  }

  // BUILD
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

  Widget _buildConditionalChart() {
    if (_activeTabIndex == 2) return const SizedBox.shrink();
    if (_isChartLoadingForTab)  return _buildChartShimmer();

    return Column(children: [
      // TOGGLE BUTTON
      GestureDetector(
        onTap: () => setState(() => _isChartExpanded = !_isChartExpanded),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.red.withValues(alpha:0.4), width: 1.2),
            boxShadow: [BoxShadow(color: _C.red.withValues(alpha:0.08), blurRadius: 6, offset: const Offset(0, 2))],
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
      // ANIMATED PIE CHART BODY
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

  // MEMBERS PIE CHART
  Widget _buildMembersPieChart() {
    final future = _membersTabKey.currentState?.currentFuture;
    if (future == null) return _buildChartShimmer();
    return FutureBuilder<List<MemberData>>(
      future: future,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildChartShimmer();
        }
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

  // LOCATION PIE CHART
  Widget _buildLocationPieChart() {
    final future = _locationTabKey.currentState?.currentFuture;
    if (future == null) return _buildChartShimmer();
    return FutureBuilder<List<LocationData>>(
      future: future,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildChartShimmer();
        }
        final data     = snap.data ?? [];
        final totalAll = data.fold<int>(
            0, (s, l) => s + (int.tryParse(l.value ?? '0') ?? 0));
        final topCount = data.isNotEmpty
            ? (int.tryParse(data.first.value ?? '0') ?? 0) : 0;
        final others   = totalAll - topCount;
        return _buildPieChart(
          totalPrimary:   topCount,
          totalSecondary: others,
          colorPrimary:   _C.red,
          colorSecondary: _C.orange,
          labelPrimary:   data.isNotEmpty
              ? data.first.name : _t('Teratas', 'Top', '最高'),
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

  // GENERIC PIE CHART
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
        border: Border.all(color: _C.red.withValues(alpha:0.25)),
        boxShadow: [BoxShadow(color: _C.red.withValues(alpha:0.07), blurRadius: 10, offset: const Offset(0, 4))],
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
              color: _C.red.withValues(alpha:0.1),
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
        color: color.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: color.withValues(alpha:0.15), shape: BoxShape.circle),
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
              backgroundColor: color.withValues(alpha:0.15),
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

  // MEMBERS TAB
  Widget _buildMembersTab() {
    return AccidentMembersTab(
      key:                _membersTabKey,
      lang:               widget.lang,
      filterMode:         _filterMode,
      selectedMonthIndex: _selectedMonthIndex,
      selectedDate:       _selectedDate,
      selectedUnitId:     _selectedUnitId,
      unitList:           _unitList,
      lastUpdatedText:    _lastUpdatedText,
      buildFilterBtn: ({
        required String    label,
        required VoidCallback onTap,
        IconData             icon    = Icons.keyboard_arrow_down_rounded,
        bool                 isActive = false,
      }) =>
          _buildFilterBtn(
              label: label, onTap: onTap, icon: icon, isActive: isActive),
      showMonthPicker: (_) => _showMonthPicker(
        () => _fetchAll(fromTabFilter: true),
      ),
      showGroupPicker: _showGroupPicker,
    );
  }

  // LOCATION TAB
  Widget _buildLocationTab() {
    return AccidentLocationTab(
      key:                      _locationTabKey,
      lang:                     widget.lang,
      filterMode:               _filterMode,
      selectedMonthIndex:       _selectedMonthIndex,
      selectedDate:             _selectedDate,
      selectedLocationLevel:    _selectedLocationLevel,
      translatedLocationLevels: _translatedLocationLevels,
      levelBackends:            _levelBackends,
      lastUpdatedText:          _lastUpdatedText,
      buildFilterBtn: ({
        required String    label,
        required VoidCallback onTap,
        IconData           icon     = Icons.keyboard_arrow_down_rounded,
        bool               isActive = false,
      }) =>
          _buildFilterBtn(
              label: label, onTap: onTap, icon: icon, isActive: isActive),
      showMonthPicker: (_) => _showMonthPicker(
        () => _fetchAll(fromTabFilter: true),
      ),
      showLevelPicker: _showLevelPicker,
    );
  }

  // RECURRING ACCIDENT TAB
  Widget _buildRecurringTab() {
    return AccidentRecurringTab(
      key:  _recurringTabKey,
      lang: widget.lang,
      buildFilterBtn: ({
        required String    label,
        required VoidCallback onTap,
        IconData           icon     = Icons.keyboard_arrow_down_rounded,
        bool               isActive = false,
      }) =>
          _buildFilterBtn(
              label: label, onTap: onTap, icon: icon, isActive: isActive),
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
              color: _C.red.withValues(alpha:0.10), blurRadius: 6, offset: const Offset(0, 2))],
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

  // MONTH / DAILY PICKER
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
            // HEADER
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
            // TOGGLE
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
            // CONTENT
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
    final locale = widget.lang == 'ID' ? 'id_ID' : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    final dayLabels = widget.lang == 'ZH'
        ? ['日','一','二','三','四','五','六']
        : widget.lang == 'ID'
            ? ['Min','Sen','Sel','Rab','Kam','Jum','Sab']
            : ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];

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
          Text(monthLabel, style: const TextStyle(
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
            final isSel   = selectedDate.year == year &&
                selectedDate.month == month && selectedDate.day == day;
            final isToday = now.year == year && now.month == month && now.day == day;
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
      ]);
    });
  }

  // GROUP PICKER
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
            // HEADER
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
            // SEARCH
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

  // LEVEL PICKER
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
}

// PIE CHART PAINTER
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

      // SHADOW
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: outerRadius), startAngle, sweepAngle, false)
        ..close();
      canvas.drawPath(path,
        Paint()..color = color.withValues(alpha:0.2)
              ..style = PaintingStyle.fill
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

      // ARC
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