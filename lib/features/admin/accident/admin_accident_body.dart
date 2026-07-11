import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../accident/admin_accident_location.dart';
import '../accident/admin_accident_members.dart';
import '../accident/admin_accident_recurring.dart';

/// Konten tab Accident tanpa Scaffold/header/bottomnav.
/// Header & bottom navbar sekarang dikelola oleh AdminShellScreen.
class AdminAccidentBody extends StatefulWidget {
  final String lang;
  const AdminAccidentBody({super.key, required this.lang});

  @override
  State<AdminAccidentBody> createState() => _AdminAccidentBodyState();
}

class _AdminAccidentBodyState extends State<AdminAccidentBody>
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
                    ? 'Accident Report'
                    : lang == 'ZH'
                        ? '事故报告'
                        : 'Laporan Kecelakaan',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFEF4444),
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
              AdminAccidentMembersTab(lang: lang),
              AdminAccidentLocationTab(lang: lang),
              AdminAccidentRecurringTab(lang: lang),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(String lang) {
    const activeColor = Color(0xFFEF4444);
    final tabLabels = lang == 'EN'
        ? ['Members', 'Location', 'Recurring Accident']
        : lang == 'ZH'
            ? ['成员', '位置', '重复事故']
            : ['Anggota', 'Lokasi', 'Kecelakaan Berulang'];

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