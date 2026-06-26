import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../admin_profile_screen.dart';
import 'admin_home_button_access.dart';
import 'admin_home_info_card.dart';
import 'admin_home_management_menu.dart';

class AdminHomeScreen extends StatefulWidget {
  final String? initialUserName;
  final String? initialUserImage;
  final int? initialTotalUsers;
  final int? initialTotalLokasi;
  final int? initialTotalKategori;
  final int? initialTotalTemuan;
  final int? initialTemuanBelum;
  final int? initialTemuanSelesai;

  const AdminHomeScreen({
    super.key,
    this.initialUserName,
    this.initialUserImage,
    this.initialTotalUsers,
    this.initialTotalLokasi,
    this.initialTotalKategori,
    this.initialTotalTemuan,
    this.initialTemuanBelum,
    this.initialTemuanSelesai,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with TickerProviderStateMixin {
  String _lang = 'ID';
  String _adminName = 'Admin';
  String _adminJabatan = 'Admin';
  String? _adminImage;
  bool _isLoadingStats = true;

  // Stats
  int _totalUsers = 0;
  int _totalLokasi = 0;
  int _totalKategori = 0;
  int _totalTemuan = 0;

  // BOTTOM NAV STATE
  int _activeNavIndex = 0;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 0),
      value: 1.0,
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

    if (widget.initialUserName != null) {
      _adminName = widget.initialUserName!;
    }
    _adminImage = widget.initialUserImage;

    if (widget.initialTotalUsers != null) {
      _totalUsers    = widget.initialTotalUsers!;
      _totalLokasi   = widget.initialTotalLokasi ?? 0;
      _totalKategori = widget.initialTotalKategori ?? 0;
      _totalTemuan   = widget.initialTotalTemuan ?? 0;
      _isLoadingStats = false;
    }

    _loadLanguage().then((_) async {
      GoogleFonts.pendingFonts([
        GoogleFonts.poppins(),
        GoogleFonts.sourceCodePro(),
      ]).catchError((_) => <void>[]);

      _fetchStats();
    });

    _loadAdminInfo();
    // Preload bgadmin segera saat widget pertama kali build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(
        const AssetImage('assets/images/bgadmin.png'),
        context,
      ).catchError((_) {});
      precacheImage(
        const AssetImage('assets/images/logo1.png'),
        context,
      ).catchError((_) {});
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _lang = prefs.getString('lang') ?? 'ID';
      });
    }
  }

  Future<void> _fetchStats({bool showLoading = false}) async {
    if (showLoading) setState(() => _isLoadingStats = true);
    try {
      final results = await Future.wait([
        Supabase.instance.client.from('User').count(),
        Supabase.instance.client.from('lokasi').count(),
        Supabase.instance.client.from('kategoritemuan').count(),
        Supabase.instance.client.from('temuan').count(),
        Supabase.instance.client
            .from('temuan')
            .count()
            .eq('status_temuan', 'Belum'),
        Supabase.instance.client
            .from('temuan')
            .count()
            .eq('status_temuan', 'Selesai'),
      ]);

      if (mounted) {
        setState(() {
          _totalUsers    = results[0];
          _totalLokasi   = results[1];
          _totalKategori = results[2];
          _totalTemuan   = results[3];
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching admin stats: $e');
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
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
                SafeArea(
                  bottom: false,
                  child: _buildHeader(),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _fetchStats(showLoading: false),
                    color: const Color(0xFF059669),
                    backgroundColor: Colors.white,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 90 + MediaQuery.of(context).padding.bottom),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AdminHomeInfoCard(
                            adminName: _adminName,
                            adminJabatan: _adminJabatan,
                            lang: _lang,
                            isLoadingStats: _isLoadingStats,
                            totalUsers: _totalUsers,
                            totalLokasi: _totalLokasi,
                            totalKategori: _totalKategori,
                            totalTemuan: _totalTemuan,
                          ),
                          const SizedBox(height: 16),
                          AdminHomeButtonAccess(lang: _lang),
                          const SizedBox(height: 24),
                          _buildSectionLabel(
                            _lang == 'EN'
                                ? 'Management Menu'
                                : _lang == 'ZH'
                                    ? '管理菜单'
                                    : 'Menu Manajemen',
                          ),
                          const SizedBox(height: 14),
                          AdminHomeManagementMenu(
                            lang: _lang,
                            onRefreshStats: () => _fetchStats(),
                          ),
                        ],
                      ),
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

          // ── Tombol Pilihan Bahasa ──
          _buildLangSwitcher(),
          const SizedBox(width: 10),

          // ── Avatar → AdminProfileScreen ──
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
              ).then((_) {
                _fetchStats();
                _loadAdminInfo();
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

  // ── Widget Pemilih Bahasa ──
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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
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
                      final prefs =
                          await SharedPreferences.getInstance();
                      await prefs.setString('lang', l['code']!);
                      if (mounted) {
                        setState(() {
                          _lang = l['code']!;
                        });
                      }
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
                      child: Row(
                        children: [
                          Text(l['flag']!,
                              style: const TextStyle(fontSize: 24)),
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
                                color:  Color(0xFF059669), size: 20),
                        ],
                      ),
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
              _lang == 'ID'
                  ? '🇮🇩'
                  : _lang == 'EN'
                      ? '🇺🇸'
                      : '🇨🇳',
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
                size: 14, color:  Color(0xFF059669)),
          ],
        ),
      ),
    );
  }

  Future<void> _loadAdminInfo() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final row = await Supabase.instance.client
          .from('User')
          .select('nama, gambar_user, jabatan!User_id_jabatan_fkey(nama_jabatan)')
          .eq('id_user', userId)
          .maybeSingle();
      if (row != null && mounted) {
        setState(() {
          _adminName    = row['nama'] ?? _adminName;
          _adminImage   = row['gambar_user'] ?? _adminImage;
          _adminJabatan = row['jabatan']?['nama_jabatan'] ?? 'Admin';
        });
      }
    } catch (e) {
      debugPrint('Error loading admin info: $e');
    }
  }

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
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
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E3A8A), // ← gelap agar terbaca
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar(double bottomPadding) {
    const activeColor = Color.fromARGB(255, 29, 199, 97);
    const inactiveColor = Color(0xFF94A3B8);
    final double safeBottom = bottomPadding > 0 ? bottomPadding : 8;

    final items = [
      _NavItem(
        index: 0,
        labelID: 'Beranda',
        labelEN: 'Home',
        labelZH: '首页',
        activeIcon: Icons.home_rounded,
        inactiveIcon: Icons.home_outlined,
      ),
      _NavItem(
        index: 1,
        labelID: '5R',
        labelEN: '5R',
        labelZH: '5R',
        activeIcon: Icons.search_rounded,
        inactiveIcon: Icons.search_outlined,
      ),
      _NavItem(
        index: 2,
        labelID: 'KTS',
        labelEN: 'KTS',
        labelZH: 'KTS',
        activeIcon: Icons.precision_manufacturing_rounded,
        inactiveIcon: Icons.precision_manufacturing_outlined,
      ),
      _NavItem(
        index: 3,
        labelID: 'Accident',
        labelEN: 'Accident',
        labelZH: '事故',
        activeIcon: Icons.warning_rounded,
        inactiveIcon: Icons.warning_amber_outlined,
      ),
      _NavItem(
        index: 4,
        labelID: 'Preventif',
        labelEN: 'Preventive',
        labelZH: '预防',
        activeIcon: Icons.build_circle_rounded,
        inactiveIcon: Icons.build_circle_outlined,
      ),
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
        padding: EdgeInsets.only(
          top: 8,
          bottom: safeBottom,
        ),
        child: SizedBox(
          height: 56,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: items.map((item) {
              final isActive = _activeNavIndex == item.index;
              final label = _lang == 'EN'
                  ? item.labelEN
                  : _lang == 'ZH'
                      ? item.labelZH
                      : item.labelID;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeNavIndex = item.index),
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
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
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

class LocationFilter {
  final String? id;
  final String displayName;
  const LocationFilter({this.id, required this.displayName});
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