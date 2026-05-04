import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_about_screen.dart';
import 'admin_legal_screen.dart';
import 'admin_news_screen.dart';

class AdminSettingsScreen extends StatelessWidget {
  final String lang;
  const AdminSettingsScreen({super.key, required this.lang});

  static const _bg = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final menus = [
      _SettingMenu(
        title: lang == 'EN' ? 'About Inspecta' : 'Tentang Inspecta',
        subtitle: lang == 'EN'
            ? 'App name, version, website'
            : 'Nama aplikasi, versi, website',
        icon: Icons.info_outline_rounded,
        color: const Color(0xFF6366F1),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdminAboutScreen(lang: lang)),
        ),
      ),
      _SettingMenu(
        title: lang == 'EN' ? 'Terms & Conditions' : 'Syarat dan Ketentuan',
        subtitle: lang == 'EN'
            ? 'Manage terms per language'
            : 'Kelola syarat per bahasa',
        icon: Icons.gavel_rounded,
        color: const Color(0xFF0891B2),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminLegalScreen(
              lang: lang,
              docType: 'terms_conditions',
              title: lang == 'EN' ? 'Terms & Conditions' : 'Syarat dan Ketentuan',
            ),
          ),
        ),
      ),
      _SettingMenu(
        title: lang == 'EN' ? 'Privacy Policy' : 'Kebijakan Privasi',
        subtitle: lang == 'EN'
            ? 'Manage privacy policy per language'
            : 'Kelola kebijakan privasi per bahasa',
        icon: Icons.shield_outlined,
        color: const Color(0xFF059669),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminLegalScreen(
              lang: lang,
              docType: 'privacy_policy',
              title: lang == 'EN' ? 'Privacy Policy' : 'Kebijakan Privasi',
            ),
          ),
        ),
      ),
      _SettingMenu(
        title: lang == 'EN' ? 'Latest News' : 'Kabar Terbaru',
        subtitle: lang == 'EN'
            ? 'Updates & maintenance notices'
            : 'Pembaruan & pemberitahuan pemeliharaan',
        icon: Icons.campaign_outlined,
        color: const Color(0xFFF59E0B),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdminNewsScreen(lang: lang)),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.06),
        title: Text(
          lang == 'EN' ? 'App Settings' : 'Pengaturan Aplikasi',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: const Color(0xFF1E3A8A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.settings_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang == 'EN' ? 'App Settings' : 'Pengaturan Aplikasi',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lang == 'EN'
                              ? 'Manage app content & information'
                              : 'Kelola konten & informasi aplikasi',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              lang == 'EN' ? 'Content Management' : 'Manajemen Konten',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black45,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            // Menu cards
            ...menus.map((menu) => _buildMenuCard(context, menu)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, _SettingMenu menu) {
    return GestureDetector(
      onTap: menu.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: menu.color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(menu.icon, color: menu.color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.title,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    menu.subtitle,
                    style: GoogleFonts.poppins(
                        color: Colors.black38, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: menu.color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  color: menu.color, size: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingMenu {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SettingMenu({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}