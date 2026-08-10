import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../5r findings/picker/5r_members_location_picker.dart';
import '../analytics_selector_bar.dart';
import 'accident_location_tab.dart';
import 'accident_members_tab.dart';
import 'accident_recurring_tab.dart';

class _C {
  static const textPrimary     = Color(0xFF0C4A6E);
  static const textSecondary   = Color(0xFF64748B);
  static const red             = Color(0xFFEF4444);
  static const green           = Color(0xFF10B981);
  static const orange          = Color(0xFFF97316);
}

class AnalyticsAccidentTab extends StatefulWidget {
  final String lang;
  const AnalyticsAccidentTab({super.key, required this.lang});

  @override
  State<AnalyticsAccidentTab> createState() => AnalyticsAccidentTabState();
}

class AnalyticsAccidentTabState extends State<AnalyticsAccidentTab>
    with TickerProviderStateMixin implements AnalyticsSubTabController {

  @override
  void setActiveSubTab(int index) {
    if (index < 0 || index >= _tabController.length) return;
    if (_tabController.index == index) return;
    _tabController.animateTo(index);
  }
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  int _activeTabIndex = 0;

  // FILTER STATE
  int    _selectedMonthIndex = DateTime.now().month - 1;
  String _filterMode         = 'monthly';
  DateTime? _selectedDate;
  String  _selectedMemberLocationLevel = 'Lokasi';
  String? _selectedMemberLocationId;
  String? _selectedMemberLocationName;
  String  _selectedLocationLevel = 'Lokasi';
  DateTime? _lastUpdated;

  // SPECIFIC LOCATION FILTER (Location Tab)
  String? _selectedSpecificLocationId;
  String? _selectedSpecificLocationName;

  // CHART
  bool _isChartExpanded = false;

  // POPUP GUARD
  bool _isMonthPickerOpen = false;

  // DATA FUTURES
  final _membersTabKey = GlobalKey<AccidentMembersTabState>();
  final _locationTabKey = GlobalKey<AccidentLocationTabState>();
  final _recurringTabKey = GlobalKey<AccidentRecurringTabState>();

  late List<String> _translatedMonths;
  late List<String> _translatedLocationLevels;
  final _levelBackends = ['Lokasi', 'Unit', 'Subunit', 'Area'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _initLists();
    _fetchAll();
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

  void _fetchAll({bool fromTabFilter = false}) {
    setState(() => _lastUpdated = DateTime.now());

    _membersTabKey.currentState?.fetchData(
      filterMode:            _filterMode,
      selectedMonthIndex:    _selectedMonthIndex,
      selectedDate:          _selectedDate,
      selectedLocationLevel: _selectedMemberLocationLevel,
      selectedLocationId:    _selectedMemberLocationId,
    );

    _locationTabKey.currentState?.fetchData(
      filterMode:         _filterMode,
      selectedMonthIndex: _selectedMonthIndex,
      selectedDate:       _selectedDate,
      levelBackend:       _levelBackend,
      specificLocationId: _selectedSpecificLocationId,
    );
  }

  void _onTabChanged() {
    if (!mounted) return;
    final idx = _tabController.index;
    if (_activeTabIndex == idx) return;
    setState(() => _activeTabIndex = idx);
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
      _buildConditionalChart(),
      Expanded(child: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildMembersTab(),
          _buildLocationTab(),
          _buildRecurringTab(),
        ],
      )),
    ]);
  }

  Widget _buildConditionalChart() {
    if (_activeTabIndex == 2) return const SizedBox.shrink();

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
      key:                    _membersTabKey,
      lang:                   widget.lang,
      filterMode:             _filterMode,
      selectedMonthIndex:     _selectedMonthIndex,
      selectedDate:           _selectedDate,
      selectedLocationLevel:  _selectedMemberLocationLevel,
      selectedLocationId:     _selectedMemberLocationId,
      selectedLocationName:   _selectedMemberLocationName,
      lastUpdatedText:        _lastUpdatedText,
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
      showLocationPicker: _showMemberLocationPicker,
      onResetLocation: () {
        setState(() {
          _selectedMemberLocationLevel = 'Lokasi';
          _selectedMemberLocationId = null;
          _selectedMemberLocationName = null;
        });
        _fetchAll(fromTabFilter: true);
      },
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
      selectedLocationId:       _selectedSpecificLocationId,
      selectedLocationName:     _selectedSpecificLocationName,
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
      onResetLevel: () {
        setState(() {
          _selectedLocationLevel = _translatedLocationLevels[0];
          _selectedSpecificLocationId = null;
          _selectedSpecificLocationName = null;
        });
        _fetchAll(fromTabFilter: true);
      },
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
    if (_isMonthPickerOpen) return;
    _isMonthPickerOpen = true;

    String tempMode = _filterMode;
    int tempMonthIdx = _selectedMonthIndex;
    DateTime tempDate = _selectedDate ?? DateTime.now();

    const accent = Color(0xFF1D72F3); // BIRU - samain persis dgn 5R & KTS

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.68, maxWidth: 340),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.25), width: 1.5)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_month_rounded, color: accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_t('Pilih Bulan', 'Select Month', '选择月份'),
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, fontSize: 15, color: accent)),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 18),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: const Color(0xFFF1F5F9)),
            // TOGGLE
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withValues(alpha: 0.2))),
                padding: const EdgeInsets.all(4),
                child: Row(children: ['monthly', 'daily'].map((mode) {
                  final isSel = tempMode == mode;
                  final label = mode == 'monthly'
                      ? _t('Bulanan', 'Monthly', '按月')
                      : _t('Harian', 'Daily', '按日');
                  final icon = mode == 'monthly'
                      ? Icons.calendar_view_month_rounded
                      : Icons.event_rounded;
                  return Expanded(child: GestureDetector(
                    onTap: () => setSt(() => tempMode = mode),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSel ? accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(9)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 15,
                              color: isSel ? Colors.white : const Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(label, style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: isSel ? Colors.white : const Color(0xFF64748B))),
                        ],
                      ),
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
                          color: isSel ? accent : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isSel ? accent : const Color(0xFFDBEAFE),
                              width: isSel ? 1.5 : 1),
                          boxShadow: isSel ? [BoxShadow(
                              color: accent.withValues(alpha: 0.3),
                              blurRadius: 6, offset: const Offset(0, 2))] : []),
                        child: Center(child: Text(_translatedMonths[i], style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                            color: isSel ? Colors.white : const Color(0xFF0C4A6E)))),
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
                  accent: accent,
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
      {required Color accent, required VoidCallback onConfirm}) {
    final now = DateTime.now();
    final locale = widget.lang == 'ID' ? 'id_ID' : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
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
          GestureDetector(
            onTap: () => setIn(() => displayedMonth = DateTime(year, month - 1)),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.chevron_left_rounded, size: 18, color: accent),
            ),
          ),
          Text(monthLabel, style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0C4A6E))),
          GestureDetector(
            onTap: isCurrentMonth
                ? null
                : () => setIn(() => displayedMonth = DateTime(year, month + 1)),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isCurrentMonth
                    ? Colors.grey.shade100
                    : accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.chevron_right_rounded,
                  size: 18,
                  color: isCurrentMonth ? Colors.grey.shade400 : accent),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: dayLabels.map((d) => Expanded(child: Center(
            child: Text(d, style: GoogleFonts.poppins(
                fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)))))).toList()),
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
                  color: isSel ? accent : isToday ? accent.withValues(alpha: 0.12) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday && !isSel ? Border.all(color: accent, width: 1.2) : null),
                child: Center(child: Text('$day', style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: isSel || isToday ? FontWeight.w700 : FontWeight.w600,
                    color: isSel ? Colors.white : isFut ? const Color(0xFFBDBDBD) : const Color(0xFF0C4A6E)))),
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
              backgroundColor: accent, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(_t('Terapkan', 'Apply', '应用'),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ),
      ]);
    });
  }

  void _showMemberLocationPicker() async {
    final result = await showMemberLocationFilterDialog(
      context,
      lang: widget.lang,
      initialLevel: _selectedMemberLocationLevel,
      initialId: _selectedMemberLocationId,
    );
    if (result == null || !mounted) return;
    setState(() {
      _selectedMemberLocationLevel = result['level'] ?? _selectedMemberLocationLevel;
      _selectedMemberLocationId    = result['id'];
      _selectedMemberLocationName  = result['name'];
    });
    _fetchAll(fromTabFilter: true);
  }

  // LEVEL & SPECIFIC LOCATION PICKER
  void _showLevelPicker() async {
    String tempLevelLabel = _selectedLocationLevel;
    String? tempSelectedId = _selectedSpecificLocationId;
    final searchCtrl = TextEditingController();
    final Map<String, List<Map<String, String>>> dataByLevel = {
      for (final l in _translatedLocationLevels) l: <Map<String, String>>[],
    };
    bool loading = true;
    int currentPage = 1;
    const int itemsPerPage = 7;
    const headerAccent = Color(0xFF1D72F3); // BIRU - HEADER POPUP

    IconData levelIcon(String label) {
      final idx = _translatedLocationLevels.indexOf(label).clamp(0, 3);
      return [
        Icons.location_city_rounded,
        Icons.business_rounded,
        Icons.layers_rounded,
        Icons.place_rounded,
      ][idx];
    }

    IconData parentIcon(String label) {
      final idx = _translatedLocationLevels.indexOf(label).clamp(0, 3);
      return [
        Icons.location_city_rounded,
        Icons.location_city_rounded, // Unit -> parent Lokasi
        Icons.business_rounded,      // Subunit -> parent Unit
        Icons.layers_rounded,        // Area -> parent Subunit
      ][idx];
    }

    Color levelColor(String label) {
      final idx = _translatedLocationLevels.indexOf(label).clamp(0, 3);
      return [
        const Color(0xFF10B981),
        const Color(0xFF6366F1),
        const Color(0xFFFBBF24),
        const Color(0xFFF472B6),
      ][idx];
    }

    Color parentColorFor(String label) {
      final idx = _translatedLocationLevels.indexOf(label).clamp(0, 3);
      return [
        const Color(0xFF10B981),
        const Color(0xFF10B981), // parent Unit = warna Lokasi
        const Color(0xFF6366F1), // parent Subunit = warna Unit
        const Color(0xFFFBBF24), // parent Area = warna Subunit
      ][idx];
    }

    Future<void> fetchLevel(String levelLabel, void Function(void Function()) setSt) async {
      final backendLevel = _levelBackends[
          _translatedLocationLevels.indexOf(levelLabel).clamp(0, 3)];
      final levelLower = backendLevel.toLowerCase();
      try {
        List<Map<String, String>> result = [];
        if (levelLower == 'lokasi') {
          final res = await _supabase.from('lokasi').select('id_lokasi, nama_lokasi').order('nama_lokasi');
          result = List<Map<String, dynamic>>.from(res)
              .map((e) => {'id': e['id_lokasi']?.toString() ?? '', 'name': e['nama_lokasi']?.toString() ?? '-', 'parent': ''})
              .toList();
        } else if (levelLower == 'unit') {
          final res = await _supabase.from('unit').select('id_unit, nama_unit, lokasi(nama_lokasi)').order('nama_unit');
          result = List<Map<String, dynamic>>.from(res)
              .map((e) => {
                    'id': e['id_unit']?.toString() ?? '',
                    'name': e['nama_unit']?.toString() ?? '-',
                    'parent': (e['lokasi'] as Map<String, dynamic>?)?['nama_lokasi']?.toString() ?? '',
                  })
              .toList();
        } else if (levelLower == 'subunit') {
          final res = await _supabase.from('subunit').select('id_subunit, nama_subunit, unit(nama_unit)').order('nama_subunit');
          result = List<Map<String, dynamic>>.from(res)
              .map((e) => {
                    'id': e['id_subunit']?.toString() ?? '',
                    'name': e['nama_subunit']?.toString() ?? '-',
                    'parent': (e['unit'] as Map<String, dynamic>?)?['nama_unit']?.toString() ?? '',
                  })
              .toList();
        } else {
          final res = await _supabase.from('area').select('id_area, nama_area, subunit(nama_subunit)').order('nama_area');
          result = List<Map<String, dynamic>>.from(res)
              .map((e) => {
                    'id': e['id_area']?.toString() ?? '',
                    'name': e['nama_area']?.toString() ?? '-',
                    'parent': (e['subunit'] as Map<String, dynamic>?)?['nama_subunit']?.toString() ?? '',
                  })
              .toList();
        }
        dataByLevel[levelLabel] = result;
      } catch (e) {
        debugPrint('Error fetching level items: $e');
        dataByLevel[levelLabel] = [];
      }
      loading = false;
      setSt(() {});
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          if (loading && (dataByLevel[tempLevelLabel]?.isEmpty ?? true)) {
            fetchLevel(tempLevelLabel, setSt);
          }

          final q = searchCtrl.text.trim().toLowerCase();
          final items = dataByLevel[tempLevelLabel] ?? [];
          final filteredItems = q.isEmpty
              ? items
              : items.where((e) => (e['name'] ?? '').toLowerCase().contains(q)).toList();
          final currentLevelColor = levelColor(tempLevelLabel);

          final totalPages = filteredItems.isEmpty ? 1 : (filteredItems.length / itemsPerPage).ceil();
          final safePage = currentPage.clamp(1, totalPages);
          final startIdx = (safePage - 1) * itemsPerPage;
          final endIdx = (startIdx + itemsPerPage) > filteredItems.length ? filteredItems.length : startIdx + itemsPerPage;
          final pageItems = filteredItems.isEmpty ? <Map<String, String>>[] : filteredItems.sublist(startIdx, endIdx);

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 340,
              height: MediaQuery.of(context).size.height * 0.78,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: currentLevelColor.withValues(alpha: 0.25), width: 1.5),
              ),
              child: Column(children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: headerAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.tune_rounded, color: headerAccent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_t('Pilih Lokasi', 'Select Location', '选择位置'),
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15, color: headerAccent)),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 18),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: const Color(0xFFF1F5F9)),
                // TAB LEVEL
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Row(
                    children: List.generate(_translatedLocationLevels.length, (index) {
                      final lvl = _translatedLocationLevels[index];
                      final isActiveTab = lvl == tempLevelLabel;
                      final lvlColor = levelColor(lvl);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            tempLevelLabel = lvl;
                            tempSelectedId = null;
                            searchCtrl.clear();
                            currentPage = 1;
                            loading = true;
                            setSt(() {});
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isActiveTab ? lvlColor : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isActiveTab ? lvlColor : const Color(0xFFE2E8F0)),
                              boxShadow: isActiveTab
                                  ? [BoxShadow(color: lvlColor.withValues(alpha: 0.30), blurRadius: 8, offset: const Offset(0, 3))]
                                  : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(levelIcon(lvl), size: 15, color: isActiveTab ? Colors.white : lvlColor),
                                const SizedBox(height: 3),
                                Text(lvl,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: isActiveTab ? Colors.white : const Color(0xFF475569))),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 10),
                // SEARCH
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: currentLevelColor.withValues(alpha: 0.35), width: 1.3),
                    ),
                    child: TextField(
                      controller: searchCtrl,
                      textAlignVertical: TextAlignVertical.center,
                      onChanged: (_) => setSt(() { currentPage = 1; }),
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: _t('Cari...', 'Search...', '搜索...'),
                        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFFBDBDBD)),
                        prefixIcon: Icon(Icons.search_rounded, color: currentLevelColor, size: 18),
                        suffixIcon: searchCtrl.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () => setSt(() { searchCtrl.clear(); currentPage = 1; }),
                                child: Container(
                                  margin: const EdgeInsets.all(10),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFEF4444)),
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE0F2FE)),
                // LIST
                Expanded(
                  child: loading
                      ? _buildLevelPickerShimmer()
                      : Column(children: [
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                              children: [
                                // ALL CARD
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    setState(() {
                                      _selectedLocationLevel = tempLevelLabel;
                                      _selectedSpecificLocationId = null;
                                      _selectedSpecificLocationName = null;
                                    });
                                    _fetchAll(fromTabFilter: true);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: tempSelectedId == null ? const Color(0xFFE0F2FE) : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: tempSelectedId == null ? currentLevelColor : const Color(0xFFE2E8F0),
                                          width: tempSelectedId == null ? 1.5 : 1),
                                      boxShadow: [BoxShadow(color: currentLevelColor.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
                                    ),
                                    child: Row(children: [
                                      Container(
                                        width: 44, height: 44,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(color: currentLevelColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                                        child: Icon(Icons.map_rounded, size: 20, color: currentLevelColor),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text('${_t('Semua', 'All', '全部')} ($tempLevelLabel)',
                                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0F172A))),
                                      ),
                                      if (tempSelectedId == null)
                                        Icon(Icons.check_circle_rounded, color: currentLevelColor, size: 20)
                                      else
                                        Icon(Icons.chevron_right_rounded, color: currentLevelColor, size: 20),
                                    ]),
                                  ),
                                ),
                                if (filteredItems.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                                      Image.asset(
                                        'assets/images/team_illustration.png',
                                        height: 110,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 84, height: 84,
                                          decoration: BoxDecoration(color: currentLevelColor.withValues(alpha: 0.08), shape: BoxShape.circle),
                                          child: Icon(Icons.search_off_rounded, size: 36, color: currentLevelColor.withValues(alpha: 0.4)),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(_t('Tidak ada data untuk level ini.', 'No data for this level.', '此级别没有数据。'),
                                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: currentLevelColor),
                                          textAlign: TextAlign.center),
                                      if (q.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        GestureDetector(
                                          onTap: () => setSt(() { searchCtrl.clear(); currentPage = 1; }),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                            decoration: BoxDecoration(
                                              color: currentLevelColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(30),
                                              border: Border.all(color: currentLevelColor.withValues(alpha: 0.35)),
                                            ),
                                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                                              Icon(Icons.refresh_rounded, size: 14, color: currentLevelColor),
                                              const SizedBox(width: 6),
                                              Text(
                                                widget.lang == 'EN' ? 'Clear search' : widget.lang == 'ZH' ? '清除搜索' : 'Hapus pencarian',
                                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: currentLevelColor),
                                              ),
                                            ]),
                                          ),
                                        ),
                                      ],
                                    ]),
                                  )
                                else
                                  ...pageItems.map((item) {
                                    final isSel = item['id'] == tempSelectedId;
                                    final parent = item['parent'] ?? '';
                                    final pColor = parentColorFor(tempLevelLabel);
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        setState(() {
                                          _selectedLocationLevel = tempLevelLabel;
                                          _selectedSpecificLocationId = item['id'];
                                          _selectedSpecificLocationName = item['name'];
                                        });
                                        _fetchAll(fromTabFilter: true);
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isSel ? const Color(0xFFE0F2FE) : Colors.white,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: isSel ? currentLevelColor : const Color(0xFFE2E8F0), width: isSel ? 1.5 : 1),
                                          boxShadow: [BoxShadow(color: currentLevelColor.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
                                        ),
                                        child: Row(children: [
                                          Container(
                                            width: 44, height: 44,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(color: currentLevelColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                                            child: Icon(levelIcon(tempLevelLabel), size: 20, color: currentLevelColor),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(item['name'] ?? '-',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0F172A))),
                                                const SizedBox(height: 4),
                                                if (tempLevelLabel == _translatedLocationLevels[0])
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: currentLevelColor.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(20),
                                                      border: Border.all(color: currentLevelColor.withValues(alpha: 0.4)),
                                                    ),
                                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                                      Icon(levelIcon(tempLevelLabel), size: 10, color: currentLevelColor),
                                                      const SizedBox(width: 3),
                                                      Text(tempLevelLabel, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: currentLevelColor)),
                                                    ]),
                                                  )
                                                else if (parent.isNotEmpty)
                                                  Row(children: [
                                                    Icon(parentIcon(tempLevelLabel), size: 11, color: pColor),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(parent,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(fontSize: 10.5, color: pColor, fontWeight: FontWeight.w600)),
                                                    ),
                                                  ]),
                                              ],
                                            ),
                                          ),
                                          if (isSel)
                                            Icon(Icons.check_circle_rounded, color: currentLevelColor, size: 20)
                                          else
                                            Icon(Icons.chevron_right_rounded, color: currentLevelColor, size: 20),
                                        ]),
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                          if (totalPages > 1 && filteredItems.isNotEmpty)
                            _LevelPagePickerIndicator(
                              currentPage: safePage,
                              totalPages: totalPages,
                              color: currentLevelColor,
                              onPageChanged: (p) => setSt(() => currentPage = p),
                            ),
                        ]),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLevelPickerShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 150, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(height: 10, width: 90, color: Colors.white),
                ],
              ),
            ),
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

class _LevelPagePickerIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Color color;
  final ValueChanged<int> onPageChanged;

  const _LevelPagePickerIndicator({
    required this.currentPage,
    required this.totalPages,
    required this.color,
    required this.onPageChanged,
  });

  static const int _maxVisibleButtons = 5;

  List<int> _visiblePageNumbers() {
    if (totalPages <= _maxVisibleButtons) {
      return List.generate(totalPages, (i) => i + 1);
    }
    int start = currentPage - 2;
    int end = currentPage + 2;
    if (start < 1) { start = 1; end = _maxVisibleButtons; }
    else if (end > totalPages) { end = totalPages; start = totalPages - (_maxVisibleButtons - 1); }
    return List.generate(end - start + 1, (i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    final bool canPrev = currentPage > 1;
    final bool canNext = currentPage < totalPages;
    final pageNumbers = _visiblePageNumbers();

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        GestureDetector(
          onTap: canPrev ? () => onPageChanged(currentPage - 1) : null,
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: canPrev ? color.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: canPrev ? color : Colors.grey.shade400),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(children: [
            for (final p in pageNumbers) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => p == currentPage ? null : onPageChanged(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p == currentPage ? color : color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: p == currentPage ? null : Border.all(color: color.withValues(alpha: 0.25)),
                    ),
                    child: Text('$p',
                        style: GoogleFonts.poppins(color: p == currentPage ? Colors.white : color, fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              ),
              if (p != pageNumbers.last) const SizedBox(width: 8),
            ],
          ]),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: canNext ? () => onPageChanged(currentPage + 1) : null,
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: canNext ? color.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_forward_ios_rounded, size: 15, color: canNext ? color : Colors.grey.shade400),
          ),
        ),
      ]),
    );
  }
}