import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '5r findings/analytics_5r_tab.dart';
import 'kts production/analytics_kts_tab.dart';
import 'accident report/analytics_accident_tab.dart';
import 'preventif_maintenance/analytics_preventif_tab.dart';
import 'analytics_selector_bar.dart';

class AnalyticsScreen extends StatefulWidget {
  final String lang;
  const AnalyticsScreen({super.key, required this.lang});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _selectedFindingType = '5R';
  int _selectedSubTabIndex = 0;

  static const String _defaultFindingType = '5R';
  static const int _defaultSubTabIndex = 0;

  final _fiveRKey = GlobalKey<Analytics5RTabState>();
  final _ktsKey = GlobalKey<KTSAnalyticsTabState>();
  final _accidentKey = GlobalKey<AnalyticsAccidentTabState>();

  AnalyticsSubTabController? _currentController() {
    switch (_selectedFindingType) {
      case '5R':
        return _fiveRKey.currentState;
      case 'KTS Production':
        return _ktsKey.currentState;
      case 'Accident':
        return _accidentKey.currentState;
      default:
        return null;
    }
  }

  void _handleMainTypeChanged(String key) {
    final sameBranch = _selectedFindingType == key;
    setState(() {
      _selectedFindingType = key;
      _selectedSubTabIndex = _defaultSubTabIndex;
    });
    if (sameBranch) {
      _currentController()?.setActiveSubTab(_defaultSubTabIndex);
    }
  }

  void _handleSubTabChanged(int index) {
    setState(() => _selectedSubTabIndex = index);
    _currentController()?.setActiveSubTab(index);
  }

  void _handleResetToDefault() {
    _handleMainTypeChanged(_defaultFindingType);
  }

  void _handleSubTabResetToDefault() {
    setState(() => _selectedSubTabIndex = _defaultSubTabIndex);
    _currentController()?.setActiveSubTab(_defaultSubTabIndex);
  }

  String _preventifLabel() {
    if (widget.lang == 'ZH') return '预防性维护';
    return 'Preventive Maintenance';
  }

  List<AnalyticsMainTypeMeta> _mainTypes() => [
        AnalyticsMainTypeMeta(
          key: '5R',
          label: widget.lang == 'ZH' ? '5R 发现' : '5R Finding',
          icon: Icons.search_rounded,
          color: const Color(0xFF0EA5E9),
          borderColor: const Color(0xFF7DD3FC),
        ),
        const AnalyticsMainTypeMeta(
          key: 'KTS Production',
          label: 'KTS Production',
          icon: Icons.precision_manufacturing_rounded,
          color: Color(0xFFF59E0B),
          borderColor: Color(0xFFFCD34D),
        ),
        AnalyticsMainTypeMeta(
          key: 'Accident',
          label: widget.lang == 'ZH' ? '事故报告' : 'Accident Report',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFEF4444),
          borderColor: const Color(0xFFFCA5A5),
        ),
        AnalyticsMainTypeMeta(
          key: 'Preventif',
          label: _preventifLabel(),
          icon: Icons.build_circle_rounded,
          color: const Color(0xFF1D4ED8),
          borderColor: const Color(0xFFBFDBFE),
        ),
      ];

  List<AnalyticsSubTabMeta> _subTabsFor(String type) {
    switch (type) {
      case '5R':
        return [
          AnalyticsSubTabMeta(
            label: widget.lang == 'EN' ? 'Members' : widget.lang == 'ZH' ? '成员' : 'Anggota',
            icon: Icons.groups_rounded,
          ),
          AnalyticsSubTabMeta(
            label: widget.lang == 'EN' ? 'Inspection' : widget.lang == 'ZH' ? '检查' : 'Inspeksi',
            icon: Icons.fact_check_rounded,
          ),
          AnalyticsSubTabMeta(
            label: widget.lang == 'EN' ? 'Location' : widget.lang == 'ZH' ? '位置' : 'Lokasi',
            icon: Icons.map,
          ),
          AnalyticsSubTabMeta(
            label: widget.lang == 'EN'
                ? 'Recurring Finding'
                : widget.lang == 'ZH'
                    ? '重复发现'
                    : 'Temuan Berulang',
            icon: Icons.repeat_rounded,
          ),
        ];
      case 'KTS Production':
        return [
          AnalyticsSubTabMeta(
            label: widget.lang == 'EN' ? 'Members' : widget.lang == 'ZH' ? '成员' : 'Anggota',
            icon: Icons.groups_rounded,
          ),
          AnalyticsSubTabMeta(
            label: widget.lang == 'EN' ? 'Cause' : widget.lang == 'ZH' ? '原因' : 'Penyebab',
            icon: Icons.psychology_rounded,
          ),
          AnalyticsSubTabMeta(
            label: widget.lang == 'EN'
                ? 'Recurring KTS'
                : widget.lang == 'ZH'
                    ? '重复发现'
                    : 'Temuan Berulang',
            icon: Icons.repeat_rounded,
          ),
        ];
      case 'Accident':
        return [
          AnalyticsSubTabMeta(
            label: widget.lang == 'EN' ? 'Members' : widget.lang == 'ZH' ? '成员' : 'Anggota',
            icon: Icons.groups_rounded,
          ),
          AnalyticsSubTabMeta(
            label: widget.lang == 'EN' ? 'Location' : widget.lang == 'ZH' ? '位置' : 'Lokasi',
            icon: Icons.map,
          ),
          AnalyticsSubTabMeta(
            label: widget.lang == 'EN'
                ? 'Recurring Accident'
                : widget.lang == 'ZH'
                    ? '重复事故'
                    : 'Kecelakaan Berulang',
            icon: Icons.repeat_rounded,
          ),
        ];
      default:
        return const [];
    }
  }

  Widget _buildSelectorBar() {
    return AnalyticsSelectorBar(
      lang: widget.lang,
      mainTypes: _mainTypes(),
      selectedMainKey: _selectedFindingType,
      onMainTypeChanged: _handleMainTypeChanged,
      subTabs: _subTabsFor(_selectedFindingType),
      selectedSubTabIndex: _selectedSubTabIndex,
      onSubTabChanged: _handleSubTabChanged,
      defaultMainKey: _defaultFindingType,
      defaultSubTabIndex: _defaultSubTabIndex,
      onResetToDefault: _handleResetToDefault,
      onSubTabResetToDefault: _handleSubTabResetToDefault,
    );
  }

  @override
  Widget build(BuildContext context) {
    // KTS PRODUCTION
    if (_selectedFindingType == 'KTS Production') {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(children: [
          _buildSelectorBar(),
          Expanded(
            child: KTSAnalyticsTab(
              key: _ktsKey,
              lang: widget.lang,
              userId: _supabase.auth.currentUser?.id ?? '',
              onTabChanged: () {},
            ),
          ),
        ]),
      );
    }

    // ACCIDENT REPORT
    if (_selectedFindingType == 'Accident') {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(children: [
          _buildSelectorBar(),
          Expanded(
            child: AnalyticsAccidentTab(key: _accidentKey, lang: widget.lang),
          ),
        ]),
      );
    }

    // PREVENTIF MAINTENANCE
    if (_selectedFindingType == 'Preventif') {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(children: [
          _buildSelectorBar(),
          Expanded(
            child: AnalyticsPreventifTab(lang: widget.lang),
          ),
        ]),
      );
    }

    // 5R Finding (DEFAULT)
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        _buildSelectorBar(),
        Expanded(
          child: Analytics5RTab(key: _fiveRKey, lang: widget.lang),
        ),
      ]),
    );
  }
}