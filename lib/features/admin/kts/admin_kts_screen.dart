import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../accident/admin_accident_screen.dart';
import '../admin_profile_screen.dart';
import '../home/admin_home_screen.dart';
import '../5R/admin_5r_screen.dart';
import '../preventif/admin_preventif_screen.dart';
import 'admin_kts_cause.dart';
import 'admin_kts_kasie.dart';
import 'admin_kts_members.dart';

class AdminKtsScreen extends StatefulWidget {
  final String lang;
  final String? adminName;
  final String? adminImage;

  const AdminKtsScreen({
    super.key,
    required this.lang,
    this.adminName,
    this.adminImage,
  });

  @override
  State<AdminKtsScreen> createState() => _AdminKtsScreenState();
}

class _AdminKtsScreenState extends State<AdminKtsScreen>
    with TickerProviderStateMixin {
  late String _lang;
  String _adminName = 'Admin';
  String? _adminImage;
  final int _activeNavIndex = 2;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _lang = widget.lang;
    _adminName = widget.adminName ?? 'Admin';
    _adminImage = widget.adminImage;
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _activeNavIndex) return;
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        _slideRoute(
          AdminHomeScreen(
            initialUserName: _adminName,
            initialUserImage: _adminImage,
          ),
          fromRight: false,
        ),
      );
      return;
    }
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        _slideRoute(
          Admin5RScreen(
            lang: _lang,
            adminName: _adminName,
            adminImage: _adminImage,
          ),
          fromRight: false,
        ),
      );
      return;
    }
    if (index == 3) {
      Navigator.pushReplacement(
        context,
        _slideRoute(
          AdminAccidentScreen(
            lang: _lang,
            adminName: _adminName,
            adminImage: _adminImage,
          ),
          fromRight: true,
        ),
      );
      return;
    }
    if (index == 4) {
      Navigator.pushReplacement(
        context,
        _slideRoute(
          AdminPreventifScreen(
            lang: _lang,
            adminName: _adminName,
            adminImage: _adminImage,
          ),
          fromRight: true,
        ),
      );
      return;
    }
  }

  PageRouteBuilder<T> _slideRoute<T>(Widget screen, {bool fromRight = true}) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => screen,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );
        final begin = fromRight
            ? const Offset(1.0, 0.0)
            : const Offset(-1.0, 0.0);
        return SlideTransition(
          position: Tween<Offset>(begin: begin, end: Offset.zero)
              .animate(curved),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // BACKGROUND BLOBS
          Positioned(
            top: -80, right: -60,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF059669).withValues(alpha: 0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: 100, left: -80,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF34D399).withValues(alpha: 0.07),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // MAIN COLUMN
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: _buildHeader(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TITLE
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 4, height: 20,
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
                            _lang == 'EN'
                                ? 'KTS Production Report'
                                : _lang == 'ZH'
                                    ? 'KTS 生产报告'
                                    : 'Laporan KTS Produksi',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // TAB BAR
                    _buildTabBar(),

                    // CONTENT TAB
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          AdminKtsMembersTab(lang: _lang),
                          AdminKtsCauseTab(lang: _lang),
                          AdminKtsKasieTab(lang: _lang),
                          _buildPlaceholderTab(
                            _lang == 'EN' ? 'Recurring KTS' : _lang == 'ZH' ? '重复KTS' : 'KTS Berulang',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // BOTTOM NAVBAR
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _buildBottomNavBar(bottomPadding),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Image(
            image: const AssetImage('assets/images/logo1.png'),
            height: 36,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF34D399)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Admin Panel',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color.fromARGB(255, 29, 199, 97),
            ),
          ),
          const Spacer(),
          _buildLangSwitcher(),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, animation, __) => AdminProfileScreen(
                    lang: _lang,
                    initialUserName: _adminName,
                    initialUserImage: _adminImage,
                  ),
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
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF34D399), Color(0xFF38BDF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF6366F1),
                  backgroundImage: _adminImage != null
                      ? CachedNetworkImageProvider(_adminImage!)
                      : null,
                  child: _adminImage == null
                      ? const Icon(Icons.person, color: Colors.white, size: 16)
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangSwitcher() {
    final langs = [
      {'code': 'ID', 'flag': '🇮🇩'},
      {'code': 'EN', 'flag': '🇺🇸'},
      {'code': 'ZH', 'flag': '🇨🇳'},
    ];
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _lang == 'EN' ? 'Select Language'
                      : _lang == 'ZH' ? '选择语言' : 'Pilih Bahasa',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 16,
                    color: const Color.fromARGB(255, 29, 199, 97),
                  ),
                ),
                const SizedBox(height: 16),
                ...langs.map((l) {
                  final isSelected = _lang == l['code'];
                  final labels = {
                    'ID': 'Bahasa Indonesia',
                    'EN': 'English',
                    'ZH': '中文',
                  };
                  return GestureDetector(
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('lang', l['code']!);
                      if (mounted) setState(() => _lang = l['code']!);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF059669).withValues(alpha: 0.08)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF059669)
                              : Colors.grey.shade200,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Text(l['flag']!, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            labels[l['code']]!,
                            style: GoogleFonts.poppins(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 15,
                              color: isSelected
                                  ? const Color(0xFF059669)
                                  : const Color.fromARGB(255, 7, 139, 97),
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF059669), size: 20),
                      ]),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF059669).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFF059669).withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _lang == 'ID' ? '🇮🇩' : _lang == 'EN' ? '🇺🇸' : '🇨🇳',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 4),
            Text(
              _lang,
              style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: const Color(0xFF059669),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 14, color: Color(0xFF059669)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    const activeColor = Color.fromARGB(255, 29, 199, 97);

    final tabLabels = _lang == 'EN'
        ? ['Members', 'Cause', 'Kasie', 'Recurring KTS']
        : _lang == 'ZH'
            ? ['成员', '原因', '部门主管', '重复KTS']
            : ['Anggota', 'Penyebab', 'Kasie', 'KTS Berulang'];

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
          labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w700, fontSize: 11.5),
          unselectedLabelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 11.5),
          dividerColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: tabLabels
              .map((t) => Tab(child: Text(t, textAlign: TextAlign.center)))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildPlaceholderTab(String label) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.precision_manufacturing_rounded,
              size: 48,
              color: const Color.fromARGB(255, 29, 199, 97).withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color.fromARGB(255, 29, 199, 97),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _lang == 'EN'
                ? 'Content coming soon'
                : _lang == 'ZH'
                    ? '内容即将推出'
                    : 'Konten segera hadir',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(double bottomPadding) {
    const inactiveColor = Color(0xFF94A3B8);
    final double safeBottom = bottomPadding > 0 ? bottomPadding : 8;

    final items = [
      _NavItem(
          index: 0, labelID: 'Beranda', labelEN: 'Home', labelZH: '首页',
          activeIcon: Icons.home_rounded, inactiveIcon: Icons.home_outlined),
      _NavItem(
          index: 1, labelID: '5R', labelEN: '5R', labelZH: '5R',
          activeIcon: Icons.search_rounded, inactiveIcon: Icons.search_outlined),
      _NavItem(
          index: 2, labelID: 'KTS', labelEN: 'KTS', labelZH: 'KTS',
          activeIcon: Icons.precision_manufacturing_rounded,
          inactiveIcon: Icons.precision_manufacturing_outlined),
      _NavItem(
          index: 3, labelID: 'Accident', labelEN: 'Accident', labelZH: '事故',
          activeIcon: Icons.warning_rounded,
          inactiveIcon: Icons.warning_amber_outlined),
      _NavItem(
          index: 4, labelID: 'Preventif', labelEN: 'Preventive', labelZH: '预防',
          activeIcon: Icons.build_circle_rounded,
          inactiveIcon: Icons.build_circle_outlined),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(top: 8, bottom: safeBottom),
        child: SizedBox(
          height: 56,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: items.map((item) {
              final isActive = _activeNavIndex == item.index;
              const Color itemActiveColor = Color.fromARGB(255, 29, 199, 97);
              final label = _lang == 'EN'
                  ? item.labelEN
                  : _lang == 'ZH'
                      ? item.labelZH
                      : item.labelID;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _onNavTap(item.index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive
                              ? itemActiveColor.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          isActive ? item.activeIcon : item.inactiveIcon,
                          size: 24,
                          color: isActive ? itemActiveColor : inactiveColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive ? itemActiveColor : inactiveColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final int index;
  final String labelID;
  final String labelEN;
  final String labelZH;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const _NavItem({
    required this.index,
    required this.labelID,
    required this.labelEN,
    required this.labelZH,
    required this.activeIcon,
    required this.inactiveIcon,
  });
}