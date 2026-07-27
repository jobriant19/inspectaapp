import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'admin_verification_config.dart';
import 'admin_verification_findings.dart';
import 'admin_verification_accidents.dart';

class AdminVerificationScreen extends StatefulWidget {
  final String lang;
  const AdminVerificationScreen({super.key, required this.lang});

  @override
  State<AdminVerificationScreen> createState() =>
      _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  static const Color _primaryColor = Color(0xFF0F766E);

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

  String t(String id, String en, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  AdminVerificationConfigTab(lang: widget.lang),
                  AdminVerificationFindingsTab(lang: widget.lang),
                  AdminVerificationAccidentsTab(lang: widget.lang),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: _primaryColor),
          ),
          Expanded(
            child: Center(
              child: Text(
                t('Manajemen Verifikasi', 'Verification Management', '验证管理'),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final labels = [
      t('Konfigurasi', 'Config', '配置'),
      t('Temuan', 'Findings', '发现'),
      t('Kecelakaan', 'Accidents', '事故'),
    ];
    final icons = [
      Icons.settings_rounded,
      Icons.assignment_turned_in_rounded,
      Icons.health_and_safety_rounded,
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(3),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: _primaryColor,
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: _primaryColor,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11),
          dividerColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: List.generate(3, (i) => Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icons[i], size: 13),
                const SizedBox(width: 4),
                Text(labels[i]),
              ],
            ),
          )),
        ),
      ),
    );
  }
}