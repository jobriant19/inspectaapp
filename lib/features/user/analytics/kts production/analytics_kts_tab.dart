import 'package:flutter/material.dart';
import '../analytics_selector_bar.dart';
import 'kts_cause_tab.dart';
import 'kts_members_tab.dart';
import 'kts_recurring_tab.dart';

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
  State<KTSAnalyticsTab> createState() => KTSAnalyticsTabState();
}

class KTSAnalyticsTabState extends State<KTSAnalyticsTab>
    with TickerProviderStateMixin implements AnalyticsSubTabController {
  late TabController _tabController;

  @override
  void setActiveSubTab(int index) {
    if (index < 0 || index >= _tabController.length) return;
    if (_tabController.index == index) return;
    _tabController.animateTo(index);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              KtsMembersTab(lang: widget.lang, userId: widget.userId),
              KtsPenyebabTab(lang: widget.lang),
              KtsRecurringTab(lang: widget.lang),
            ],
          ),
        ),
      ],
    );
  }
}