import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '5R/admin_5r_body.dart';
import 'accident/admin_accident_body.dart';
import 'home/admin_home_body.dart';
import 'kts/admin_kts_body.dart';
import 'preventif/admin_preventif_body.dart';
import 'profile/admin_profile_screen.dart';

class AdminShellScreen extends StatefulWidget {
  final int initialIndex;
  final String? initialLang;
  final String? initialUserName;
  final String? initialUserImage;
  final int? initialTotalUsers;
  final int? initialTotalLokasi;
  final int? initialTotalKategori;
  final int? initialTotalTemuan;

  const AdminShellScreen({
    super.key,
    this.initialIndex = 0,
    this.initialLang,
    this.initialUserName,
    this.initialUserImage,
    this.initialTotalUsers,
    this.initialTotalLokasi,
    this.initialTotalKategori,
    this.initialTotalTemuan,
  });

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  late int _activeIndex;
  String _lang = 'ID';
  String _adminName = 'Admin';
  String? _adminImage;
  bool _fromRight = true;
  String? _appLogoUrl;

  static const _accentByIndex = <int, Color>{
    0: Color.fromARGB(255, 29, 199, 97), // home
    1: Color(0xFF0EA5E9), // 5R
    2: Color(0xFFF59E0B), // KTS
    3: Color(0xFFEF4444), // Accident
    4: Color(0xFF6366F1), // Preventif
  };

  @override
  void initState() {
    super.initState();
    _activeIndex = widget.initialIndex;
    _lang = widget.initialLang ?? 'ID';
    _adminName = widget.initialUserName ?? 'Admin';
    _adminImage = widget.initialUserImage;
    if (widget.initialLang == null) _loadLanguage();
    _fetchAppLogo();
  }

  Future<void> _fetchAppLogo() async {
    try {
      final res = await Supabase.instance.client
          .from('app_info')
          .select('logo_url')
          .order('id')
          .limit(1)
          .maybeSingle();
      final url = res?['logo_url'] as String?;
      if (mounted && url != null && url.isNotEmpty) {
        setState(() => _appLogoUrl = url);
        precacheImage(CachedNetworkImageProvider(url), context).catchError((_) {});
      }
    } catch (e) {
      debugPrint('Error fetching app logo (admin): $e');
    }
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _lang = prefs.getString('lang') ?? 'ID');
  }

  void _onNavTap(int index) {
    if (index == _activeIndex) return;
    setState(() {
      _fromRight = index > _activeIndex;
      _activeIndex = index;
    });
  }

  void _onLangChanged(String newLang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', newLang);
    if (mounted) setState(() => _lang = newLang);
  }

  Widget _buildBody() {
    switch (_activeIndex) {
      case 0:
        return AdminHomeBody(
          key: const ValueKey('home'),
          lang: _lang,
          initialUserName: _adminName,
          initialUserImage: _adminImage,
          initialTotalUsers: widget.initialTotalUsers,
          initialTotalLokasi: widget.initialTotalLokasi,
          initialTotalKategori: widget.initialTotalKategori,
          initialTotalTemuan: widget.initialTotalTemuan,
        );
      case 1:
        return Admin5RBody(key: const ValueKey('5r'), lang: _lang);
      case 2:
        return AdminKtsBody(key: const ValueKey('kts'), lang: _lang);
      case 3:
        return AdminAccidentBody(key: const ValueKey('accident'), lang: _lang);
      case 4:
        return AdminPreventifBody(key: const ValueKey('preventif'), lang: _lang);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
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
            bottom: 100,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF10B981).withValues(alpha: 0.07),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Column(
            children: [
              // HEADER
              SafeArea(bottom: false, child: _buildHeader()),
              // BODY
              Expanded(
                child: ClipRect(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    transitionBuilder: (child, animation) {
                      final offsetTween = Tween<Offset>(
                        begin: Offset(_fromRight ? 0.06 : -0.06, 0),
                        end: Offset.zero,
                      );
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: animation.drive(offsetTween),
                          child: child,
                        ),
                      );
                    },
                    layoutBuilder: (currentChild, previousChildren) => Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    ),
                    child: _buildBody(),
                  ),
                ),
              ),
            ],
          ),
          // BOTTOM NAVBAR
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
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
          (_appLogoUrl != null && _appLogoUrl!.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: _appLogoUrl!,
                  height: 36,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Image(
                    image: AssetImage('assets/images/logo1.png'),
                    height: 36,
                    gaplessPlayback: true,
                  ),
                  errorWidget: (_, __, ___) => const Image(
                    image: AssetImage('assets/images/logo1.png'),
                    height: 36,
                    gaplessPlayback: true,
                  ),
                )
              : Image(
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
                        parent: animation, curve: Curves.easeInOut));
                    return SlideTransition(position: slide, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              ).then((result) {
                if (result != null && result is Map) {
                  setState(() {
                    _adminName = (result['name'] as String?) ?? _adminName;
                    _adminImage = (result['image'] as String?) ?? _adminImage;
                  });
                }
              });
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
    const langs = [
      {'code': 'ID', 'flag': '🇮🇩', 'label': 'Bahasa Indonesia'},
      {'code': 'EN', 'flag': '🇺🇸', 'label': 'English'},
      {'code': 'ZH', 'flag': '🇨🇳', 'label': '中文'},
    ];
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black.withValues(alpha: 0.45),
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _lang == 'EN'
                              ? 'Select Language'
                              : _lang == 'ZH'
                                  ? '选择语言'
                                  : 'Pilih Bahasa',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: const Color.fromARGB(255, 29, 199, 97),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close_rounded,
                              size: 18, color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...langs.map((l) {
                    final isSelected = _lang == l['code'];
                    return GestureDetector(
                      onTap: () {
                        _onLangChanged(l['code']!);
                        Navigator.pop(ctx);
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
                        child: Row(
                          children: [
                            Text(l['flag']!, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                l['label']!,
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
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF059669).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: const Color(0xFF059669).withValues(alpha: 0.25)),
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
                fontSize: 11,
                fontWeight: FontWeight.w700,
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

  Widget _buildBottomNavBar(double bottomPadding) {
    const inactiveColor = Color(0xFF94A3B8);
    final double safeBottom = bottomPadding > 0 ? bottomPadding : 8;
    final activeColor = _accentByIndex[_activeIndex]!;

    final items = [
      _NavItem(0, 'Beranda', 'Home', '首页', Icons.home_rounded, Icons.home_outlined),
      _NavItem(1, '5R', '5R', '5R', Icons.search_rounded, Icons.search_outlined),
      _NavItem(2, 'KTS', 'KTS', 'KTS', Icons.precision_manufacturing_rounded,
          Icons.precision_manufacturing_outlined),
      _NavItem(3, 'Accident', 'Accident', '事故', Icons.warning_rounded,
          Icons.warning_amber_outlined),
      _NavItem(4, 'Preventif', 'Preventive', '预防', Icons.build_circle_rounded,
          Icons.build_circle_outlined),
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
              final isActive = _activeIndex == item.index;
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
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive
                              ? activeColor.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          isActive ? item.activeIcon : item.inactiveIcon,
                          size: 24,
                          color: isActive ? activeColor : inactiveColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive ? activeColor : inactiveColor,
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

  const _NavItem(this.index, this.labelID, this.labelEN, this.labelZH,
      this.activeIcon, this.inactiveIcon);
}