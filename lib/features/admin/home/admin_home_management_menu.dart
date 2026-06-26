import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../audit/audit_location_screen.dart';
import '../admin_help_reports_screen.dart';
import '../admin_verification_screen.dart';
import '../settings/admin_settings_screen.dart';
import '../admin_location_screen.dart';
import '../admin_category_screen.dart';
import '../target/admin_poin_target_screen.dart';
import '../user/admin_user_screen.dart';

class AdminHomeManagementMenu extends StatelessWidget {
  final String lang;
  final VoidCallback onRefreshStats;

  const AdminHomeManagementMenu({
    super.key,
    required this.lang,
    required this.onRefreshStats,
  });

  PageRoute<T> _slideRoute<T>(Widget screen) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, animation, __) => screen,
      transitionsBuilder: (_, animation, __, child) {
        final slide = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ));
        return SlideTransition(position: slide, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menus = [
      _MenuItem(
        label: lang == 'EN'
            ? 'User\nManagement'
            : lang == 'ZH'
                ? '用户\n管理'
                : 'Kelola\nPengguna',
        icon: Icons.manage_accounts_rounded,
        gradient: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
        shadow: const Color(0xFF6366F1),
        onTap: () => Navigator.push(
          context,
          _slideRoute(AdminUserScreen(lang: lang)),
        ).then((_) => onRefreshStats()),
      ),
      _MenuItem(
        label: lang == 'EN'
            ? 'Location\nManagement'
            : lang == 'ZH'
                ? '位置\n管理'
                : 'Kelola\nLokasi',
        icon: Icons.location_on_rounded,
        gradient: const [Color(0xFF10B981), Color(0xFF059669)],
        shadow: const Color(0xFF10B981),
        onTap: () => Navigator.push(
          context,
          _slideRoute(AdminLocationScreen(lang: lang)),
        ).then((_) => onRefreshStats()),
      ),
      _MenuItem(
        label: lang == 'EN'
            ? 'Category\nManagement'
            : lang == 'ZH'
                ? '类别\n管理'
                : 'Kelola\nKategori',
        icon: Icons.category_rounded,
        gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        shadow: const Color(0xFFF59E0B),
        onTap: () => Navigator.push(
          context,
          _slideRoute(AdminCategoryScreen(lang: lang)),
        ).then((_) => onRefreshStats()),
      ),
      _MenuItem(
        label: lang == 'EN'
            ? 'App\nSettings'
            : lang == 'ZH'
                ? '应用\n设置'
                : 'Pengaturan\nAplikasi',
        icon: Icons.settings_rounded,
        gradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
        shadow: const Color(0xFFEF4444),
        onTap: () => Navigator.push(
          context,
          _slideRoute(AdminSettingsScreen(lang: lang)),
        ).then((_) => onRefreshStats()),
      ),
      _MenuItem(
        label: lang == 'EN'
            ? 'Points &\n5R Target'
            : lang == 'ZH'
                ? '积分与\n5R目标'
                : 'Poin &\nTarget 5R',
        icon: Icons.stars_rounded,
        gradient: const [
          Color.fromARGB(255, 245, 229, 11),
          Color.fromARGB(255, 217, 175, 6)
        ],
        shadow: const Color.fromARGB(255, 245, 233, 11),
        onTap: () => Navigator.push(
          context,
          _slideRoute(AdminPoinTargetScreen(lang: lang)),
        ),
      ),
      _MenuItem(
        label: lang == 'EN'
            ? 'Help\nReports'
            : lang == 'ZH'
                ? '帮助\n报告'
                : 'Laporan\nBantuan',
        icon: Icons.support_agent_rounded,
        gradient: const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
        shadow: const Color(0xFF0EA5E9),
        onTap: () => Navigator.push(
          context,
          _slideRoute(AdminHelpReportsScreen(lang: lang)),
        ),
      ),
      _MenuItem(
        label: lang == 'EN'
            ? 'Audit\nLocation'
            : lang == 'ZH'
                ? '审计\n位置'
                : 'Audit\nLokasi',
        icon: Icons.fact_check_rounded,
        gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        shadow: const Color(0xFF8B5CF6),
        onTap: () => Navigator.push(
          context,
          _slideRoute(AuditLocationScreen(lang: lang)),
        ).then((_) => onRefreshStats()),
      ),
      _MenuItem(
        label: lang == 'EN'
            ? 'Verification\nSettings'
            : lang == 'ZH'
                ? '验证\n设置'
                : 'Pengaturan\nVerifikasi',
        icon: Icons.verified_user_rounded,
        gradient: const [Color(0xFF0F766E), Color(0xFF0D9488)],
        shadow: const Color(0xFF0F766E),
        onTap: () => Navigator.push(
          context,
          _slideRoute(AdminVerificationScreen(lang: lang)),
        ).then((_) => onRefreshStats()),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemCount: menus.length,
      itemBuilder: (_, i) => _buildMenuCard(context, menus[i]),
    );
  }

  Widget _buildMenuCard(BuildContext context, _MenuItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: item.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: item.shadow.withValues(alpha:0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(item.icon,
                  size: 70, color: Colors.white.withValues(alpha:0.15)),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: Colors.white, size: 22),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            lang == 'EN'
                                ? 'Manage'
                                : lang == 'ZH'
                                    ? '管理'
                                    : 'Kelola',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha:0.75),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios,
                              size: 9,
                              color: Colors.white.withValues(alpha:0.75)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final Color shadow;
  final VoidCallback onTap;

  const _MenuItem({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.shadow,
    required this.onTap,
  });
}