import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_about_screen.dart';
import 'admin_legal_screen.dart';
import 'admin_news_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  final String lang;
  const AdminSettingsScreen({super.key, required this.lang});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  static const _bg = Color(0xFFF8FAFC);

  Map<String, dynamic>? _cachedAppInfo;
  Map<String, List<Map<String, dynamic>>> _cachedLegal = {};
  List<Map<String, dynamic>> _cachedNews = [];

  @override
  void initState() {
    super.initState();
    _prefetchAppInfo();
    _prefetchLegal();
    _prefetchNews();
  }

  Future<void> _prefetchAppInfo() async {
    try {
      final res = await Supabase.instance.client
          .from('app_info')
          .select()
          .order('id')
          .limit(1)
          .maybeSingle();
      if (mounted) setState(() => _cachedAppInfo = res);
    } catch (e) {
      debugPrint('Prefetch app_info error: $e');
    }
  }

  Future<void> _prefetchLegal() async {
    try {
      final res = await Supabase.instance.client
          .from('legal_documents')
          .select()
          .order('lang_code')
          .order('section_order');
      if (!mounted) return;
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final row in List<Map<String, dynamic>>.from(res)) {
        final key = row['doc_type']?.toString() ?? '';
        grouped.putIfAbsent(key, () => []).add(row);
      }
      setState(() => _cachedLegal = grouped);
    } catch (e) {
      debugPrint('Prefetch legal error: $e');
    }
  }

  Future<void> _prefetchNews() async {
    try {
      final res = await Supabase.instance.client
          .from('latest_news')
          .select()
          .order('published_at', ascending: false);
      if (mounted) {
        setState(() => _cachedNews =
            List<Map<String, dynamic>>.from(res));
      }
    } catch (e) {
      debugPrint('Prefetch news error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    PageRoute<T> slideRoute<T>(Widget screen) {
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

    final menus = [
      _SettingMenu(
        title: widget.lang == 'EN'
            ? 'About Inspecta'
            : widget.lang == 'ZH'
                ? '关于 Inspecta'
                : 'Tentang Inspecta',
        subtitle: widget.lang == 'EN'
            ? 'App name, version, website'
            : widget.lang == 'ZH'
                ? '应用名称、版本、网站'
                : 'Nama aplikasi, versi, website',
        icon: Icons.info_outline_rounded,
        color: const Color(0xFF1D72F3),
        onTap: () => Navigator.push(
          context,
          slideRoute(AdminAboutScreen(
            lang: widget.lang,
            initialData: _cachedAppInfo,
          )),
        ),
      ),
      _SettingMenu(
        title: widget.lang == 'EN'
            ? 'Terms & Conditions'
            : widget.lang == 'ZH'
                ? '条款与条件'
                : 'Syarat dan Ketentuan',
        subtitle: widget.lang == 'EN'
            ? 'Manage terms per language'
            : widget.lang == 'ZH'
                ? '按语言管理条款'
                : 'Kelola syarat per bahasa',
        icon: Icons.gavel_rounded,
        color: const Color(0xFF0891B2),
        onTap: () => Navigator.push(
          context,
          slideRoute(AdminLegalScreen(
            lang: widget.lang,
            docType: 'terms_conditions',
            title: widget.lang == 'EN'
                ? 'Terms & Conditions'
                : widget.lang == 'ZH'
                    ? '条款与条件'
                    : 'Syarat dan Ketentuan',
            initialDocs: _cachedLegal['terms_conditions'],
          )),
        ),
      ),
      _SettingMenu(
        title: widget.lang == 'EN'
            ? 'Privacy Policy'
            : widget.lang == 'ZH'
                ? '隐私政策'
                : 'Kebijakan Privasi',
        subtitle: widget.lang == 'EN'
            ? 'Manage privacy policy per language'
            : widget.lang == 'ZH'
                ? '按语言管理隐私政策'
                : 'Kelola kebijakan privasi per bahasa',
        icon: Icons.shield_outlined,
        color: const Color(0xFF059669),
        onTap: () => Navigator.push(
          context,
          slideRoute(AdminLegalScreen(
            lang: widget.lang,
            docType: 'privacy_policy',
            title: widget.lang == 'EN'
                ? 'Privacy Policy'
                : widget.lang == 'ZH'
                    ? '隐私政策'
                    : 'Kebijakan Privasi',
            initialDocs: _cachedLegal['privacy_policy'],
          )),
        ),
      ),
      _SettingMenu(
        title: widget.lang == 'EN'
            ? 'Latest News'
            : widget.lang == 'ZH'
                ? '最新消息'
                : 'Kabar Terbaru',
        subtitle: widget.lang == 'EN'
            ? 'Updates & maintenance notices'
            : widget.lang == 'ZH'
                ? '更新与维护通知'
                : 'Pembaruan & pemberitahuan pemeliharaan',
        icon: Icons.campaign_outlined,
        color: const Color(0xFFF59E0B),
        onTap: () => Navigator.push(
          context,
          slideRoute(AdminNewsScreen(
            lang: widget.lang,
            initialData: _cachedNews.isEmpty ? null : _cachedNews,
          )),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFEF4444),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        shadowColor: Colors.black.withValues(alpha:0.06),
        title: Text(
          widget.lang == 'EN'
              ? 'App Settings'
              : widget.lang == 'ZH'
                  ? '应用设置'
                  : 'Pengaturan Aplikasi',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: const Color(0xFFEF4444),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER INFO
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
                    color: const Color(0xFFEF4444).withValues(alpha:0.3),
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
                      color: Colors.white.withValues(alpha:0.2),
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
                          widget.lang == 'EN'
                              ? 'App Settings'
                              : widget.lang == 'ZH'
                                  ? '应用设置'
                                  : 'Pengaturan Aplikasi',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.lang == 'EN'
                              ? 'Manage app content & information'
                              : widget.lang == 'ZH'
                                  ? '管理应用内容与信息'
                                  : 'Kelola konten & informasi aplikasi',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha:0.8),
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
              widget.lang == 'EN'
                  ? 'Content Management'
                  : widget.lang == 'ZH'
                      ? '内容管理'
                      : 'Manajemen Konten',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black45,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            // MENU CARDS
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
          border: Border.all(color: Colors.black.withValues(alpha:0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.04),
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
                color: menu.color.withValues(alpha:0.10),
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
                    style:
                        GoogleFonts.poppins(color: Colors.black38, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: menu.color.withValues(alpha:0.08),
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