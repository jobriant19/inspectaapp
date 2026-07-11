import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../5R/admin_5r_inspection.dart';
import '../5R/admin_5r_location.dart';
import '../5R/admin_5r_members.dart';
import '../5R/admin_5r_recurring.dart';

/// Konten tab 5R tanpa Scaffold/header/bottomnav.
/// Header & bottom navbar sekarang dikelola oleh AdminShellScreen.
class Admin5RBody extends StatefulWidget {
  final String lang;
  const Admin5RBody({super.key, required this.lang});

  @override
  State<Admin5RBody> createState() => _Admin5RBodyState();
}

class _Admin5RBodyState extends State<Admin5RBody>
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
                lang == 'ZH' ? '5R 发现报告' : '5R Findings Report',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0EA5E9),
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
              Admin5RMembersTab(lang: lang),
              Admin5RInspectionTab(lang: lang),
              Admin5RLocationTab(lang: lang),
              Admin5RRecurringTab(lang: lang),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(String lang) {
    const activeColor = Color(0xFF0EA5E9);
    final tabLabels = lang == 'EN'
        ? ['Members', 'Inspection', 'Location', 'Recurring Findings']
        : lang == 'ZH'
            ? ['成员', '检查', '位置', '重复发现']
            : ['Anggota', 'Inspeksi', 'Lokasi', 'Temuan Berulang'];

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