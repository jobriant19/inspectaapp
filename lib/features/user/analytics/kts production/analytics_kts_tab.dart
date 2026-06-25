import 'package:flutter/material.dart';
import 'kts_cause_tab.dart';
import 'kts_kasie_tab.dart';
import 'kts_members_tab.dart';
import 'kts_recurring_tab.dart';

class _KTSAppColors {
  static const primary = Color(0xFFF59E0B);
}

class KTSAnalyticsTab extends StatefulWidget {
  final String lang;
  final String userId;
  final VoidCallback? onTabChanged;
  
  const KTSAnalyticsTab({
    super.key,
    required this.lang,
    required this.userId,
    this.onTabChanged,
  });

  @override
  State<KTSAnalyticsTab> createState() => _KTSAnalyticsTabState();
}

class _KTSAnalyticsTabState extends State<KTSAnalyticsTab>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // KTS TAB BAR: MEMBERS, CAUSE, KASIE, RECURRING FINDINGS
  Widget _buildKTSTabBar() {
    final tabLabels = [
      widget.lang == 'ID' ? 'Anggota' : widget.lang == 'ZH' ? '成员' : 'Members',
      widget.lang == 'ID' ? 'Penyebab' : widget.lang == 'ZH' ? '原因' : 'Cause',
      widget.lang == 'ID' ? 'Kasi' : widget.lang == 'ZH' ? '科长' : 'Kasie',
      widget.lang == 'ID' ? 'Temuan Berulang' : widget.lang == 'ZH' ? '重复发现' : 'Recurring KTS',
    ];
    final activeColor = _KTSAppColors.primary;

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(3),
        child: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabAlignment: TabAlignment.fill,
          indicator: BoxDecoration(
            color: activeColor,
            borderRadius: BorderRadius.circular(8),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: activeColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10.5),
          dividerColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: tabLabels.map((t) => Tab(child: Text(t, textAlign: TextAlign.center))).toList(),
        ),
      ),
    );
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildKTSTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              KtsMembersTab(lang: widget.lang, userId: widget.userId),
              KtsPenyebabTab(lang: widget.lang),
              KtsKasieTab(lang: widget.lang),
              KtsRecurringTab(lang: widget.lang),
            ],
          ),
        ),
      ],
    );
  }
}