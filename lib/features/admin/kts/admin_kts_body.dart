import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../kts/admin_kts_cause.dart';
import '../kts/admin_kts_members.dart';
import '../kts/admin_kts_recurring.dart';

class AdminKtsBody extends StatefulWidget {
  final String lang;
  const AdminKtsBody({super.key, required this.lang});

  @override
  State<AdminKtsBody> createState() => _AdminKtsBodyState();
}

class _AdminKtsBodyState extends State<AdminKtsBody>
    with TickerProviderStateMixin {
  late TabController _tabController;

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
    final lang = widget.lang;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TITLE
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF34D399)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                lang == 'EN'
                    ? 'KTS Production Report'
                    : lang == 'ZH'
                        ? 'KTS 生产报告'
                        : 'Laporan KTS Produksi',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // TAB BAR
        _buildTabBar(lang),

        // TAB CONTENT
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              AdminKtsMembersTab(lang: lang),
              AdminKtsCauseTab(lang: lang),
              AdminKtsRecurringTab(lang: lang),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(String lang) {
    const activeColor = Color(0xFFF59E0B);
    final tabLabels = lang == 'EN'
        ? ['Members', 'Cause', 'Recurring KTS']
        : lang == 'ZH'
            ? ['成员', '原因', '重复KTS']
            : ['Anggota', 'Penyebab', 'KTS Berulang'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicator: BoxDecoration(
            color: activeColor,
            borderRadius: BorderRadius.circular(9),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: activeColor,
          labelStyle:
              GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 11.5),
          unselectedLabelStyle:
              GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11.5),
          dividerColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: tabLabels
              .map((t) => Tab(child: Text(t, textAlign: TextAlign.center)))
              .toList(),
        ),
      ),
    );
  }
}