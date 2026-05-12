import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:intl/intl.dart';

// ─── Import screen admin lainnya ───
import '../audit/audit_location_screen.dart';
import '../user/leaderboard/leaderboard_detail_screen.dart';
import 'admin_help_reports_screen.dart';
import 'admin_poin_screen.dart';
import 'admin_profile_screen.dart';
import 'settings/admin_settings_screen.dart';
import 'admin_user_screen.dart';
import 'admin_location_screen.dart';
import 'admin_category_screen.dart';
// Import login screen untuk logout
import '../auth/login_screen.dart';

// ============================================================
// ADMIN HOME SCREEN
// ============================================================
class AdminHomeScreen extends StatefulWidget {
  final String? initialUserName;
  final String? initialUserImage;
  // ── Stats awal agar 4 card langsung muncul tanpa shimmer ──
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
  final _bgImageProvider = const AssetImage('assets/images/bgadmin.png');

  // Stats
  int _totalUsers = 0;
  int _totalLokasi = 0;
  int _totalKategori = 0;
  int _totalTemuan = 0;
  int _temuanBelum = 0;
  int _temuanSelesai = 0;

  // ── Leaderboard State (Analytics Style) ──
  String _lbFindingType = '5R';
  int _lbSelectedMonthIndex = DateTime.now().month - 1;
  String _lbFilterMode = 'monthly';
  DateTime? _lbSelectedDate;
  String? _lbSelectedUnitId;
  String _lbSelectedInspectionRole = 'Eksekutif';
  String _lbSelectedLocationLevel = 'Lokasi';
  DateTime? _lbLastUpdated;
  int _lbChartRefreshKey = 0;
  bool _lbIsChartExpanded = false;
  bool _lbIsChartLoadingForTab = false;
  int _lbActiveTabIndex = 0;
  int _lbCurrentTabCount = 4;
  late TabController _lbTabController;
  LocationFilter _lbLocation = LocationFilter(displayName: 'Semua Lokasi');

  // Target chart per-tab (baru)
  int _lbChartTargetTemuan       = 2;
  int _lbChartTargetPenyelesaian = 2;
  int _lbChartTargetLokasi       = 5;
  int _lbChartTargetUnit         = 5;
  int _lbChartTargetSubunit      = 5;
  int _lbChartTargetArea         = 5;

  // Audit lokasi future (baru)
  Future<List<Map<String, dynamic>>>? _lbAuditLokasiFuture;

  // Recurring Leaderboard filter
  DateTime _lbRecurringFrom = DateTime(DateTime.now().year - 1, DateTime.now().month);
  DateTime _lbRecurringTo = DateTime.now();
  String? _lbRecurringUserId;
  String _lbRecurringUserName = '';

  // Leaderboard Futures
  Future<List<Map<String, dynamic>>>? _lbAnggotaFuture;
  Future<List<Map<String, dynamic>>>? _lbInspeksiFuture;
  Future<List<Map<String, dynamic>>>? _lbLokasiFuture;
  Future<List<Map<String, dynamic>>>? _lbRecurringFuture;
  Future<List<Map<String, dynamic>>>? _lbAccidentAnggotaFuture;
  Future<List<Map<String, dynamic>>>? _lbAccidentLokasiFuture;
  Future<List<Map<String, dynamic>>>? _lbAccidentRecurringFuture;
  Future<List<Map<String, dynamic>>>? _lbKtsAnggotaFuture;

  // Chart Futures
  Future<List<_LbChartBarData>>? _lbChartFuture;
  Future<List<_LbChartBarData>>? _lbRecurringChartFuture;
  int _lbRecurringChartRefreshKey = 0;

  // Target
  int _lbTargetAnggota = 2;
  int _lbTargetInspeksi = 2;

  List<Map<String, dynamic>> _lbUnitList = [];
  late List<String> _lbTranslatedMonths;
  late List<String> _lbTranslatedRoles;
  late List<String> _lbTranslatedLocationLevels;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _lbTabController = TabController(length: 4, vsync: this);
    _lbTabController.addListener(_lbOnTabChanged);

    if (widget.initialUserName != null) {
      _adminName = widget.initialUserName!;
    }
    _adminImage = widget.initialUserImage;

    if (widget.initialTotalUsers != null) {
      _totalUsers    = widget.initialTotalUsers!;
      _totalLokasi   = widget.initialTotalLokasi ?? 0;
      _totalKategori = widget.initialTotalKategori ?? 0;
      _totalTemuan   = widget.initialTotalTemuan ?? 0;
      _temuanBelum   = widget.initialTemuanBelum ?? 0;
      _temuanSelesai = widget.initialTemuanSelesai ?? 0;
      _isLoadingStats = false; // ← langsung tampil, skip shimmer
    }

    _loadLanguage().then((_) {
      _fetchStats();
      _initLbLocale();
      _lbFetchUnits().then((_) {
        _lbFetchAllData();
        setState(() => _lbIsChartLoadingForTab = false);
      });
      _lbFetchTarget();
      _animCtrl.forward();
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
    _lbTabController.removeListener(_lbOnTabChanged);
    _lbTabController.dispose();
    super.dispose();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _lang = prefs.getString('lang') ?? 'ID';
        // Update display name lokasi leaderboard sesuai bahasa
        _lbLocation = LocationFilter(
          displayName: leaderboardTexts[_lang]?['all_locations'] ??
              leaderboardTexts['ID']!['all_locations']!,
        );
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
          _totalUsers    = results[0] as int;
          _totalLokasi   = results[1] as int;
          _totalKategori = results[2] as int;
          _totalTemuan   = results[3] as int;
          _temuanBelum   = results[4] as int;
          _temuanSelesai = results[5] as int;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching admin stats: $e');
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _lang == 'EN' ? 'Logout' : _lang == 'ZH' ? '退出登录' : 'Keluar',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          _lang == 'EN'
              ? 'Are you sure you want to logout?'
              : _lang == 'ZH'
                  ? '您确定要退出登录吗？'
                  : 'Apakah Anda yakin ingin keluar?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_lang == 'EN' ? 'Cancel' : _lang == 'ZH' ? '取消' : 'Batal',
                  style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(_lang == 'EN' ? 'Logout' : _lang == 'ZH' ? '退出' : 'Keluar',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // ← putih/cerah
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // Background gradient blob — warna lebih lembut
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    const Color(0xFF059669).withOpacity(0.10),
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
                    const Color(0xFF10B981).withOpacity(0.07),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => _fetchStats(showLoading: false),
                      color: const Color(0xFF059669),
                      backgroundColor: Colors.white,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWelcomeBanner(),           // ← sudah gabung stats
                            const SizedBox(height: 28),
                            _buildSectionLabel(
                              _lang == 'EN'
                                  ? 'Management Menu'
                                  : _lang == 'ZH'
                                      ? '管理菜单'
                                      : 'Menu Manajemen',
                            ),
                            const SizedBox(height: 14),
                            _buildMenuGrid(),
                            const SizedBox(height: 28),
                            _buildSectionLabel(
                              _lang == 'EN'
                                  ? 'Leaderboard'
                                  : _lang == 'ZH'
                                      ? '排行榜'
                                      : 'Papan Peringkat',
                            ),
                            const SizedBox(height: 14),
                            _buildAdminLeaderboard(), // ← section baru
                          ],
                        ),
                      ),
                    ),
                  ),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo1.png',
            height: 36,
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
                    color: const Color(0xFF059669).withOpacity(0.35),
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
                    color: const Color(0xFF1E3A8A),
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
                          _lbLocation = LocationFilter(
                            displayName:
                                leaderboardTexts[_lang]?[
                                        'all_locations'] ??
                                    'Semua Lokasi',
                          );
                        });
                        _lbFetchAllData();
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF059669).withOpacity(0.08)
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
          color: const Color(0xFF059669).withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFF059669).withOpacity(0.25)),
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

  Widget _buildStatsShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
        ),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
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

  // ══════════════════════════════════════════════════════
  // LEADERBOARD METHODS (sama persis dari leaderboard_detail_screen.dart)
  // ══════════════════════════════════════════════════════

  String _getTxt(String key) =>
      leaderboardTexts[_lang]?[key] ??
      leaderboardTexts['ID']![key] ??
      key;

  Widget _buildWelcomeBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // ── Background image — gaplessPlayback agar langsung muncul tanpa flash ──
            Positioned.fill(
              child: Image(
                image: _bgImageProvider,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                frameBuilder: (_, child, frame, wasSynchronouslyLoaded) {
                  // Jika sudah di-cache, tampil langsung tanpa animasi
                  if (wasSynchronouslyLoaded || frame != null) return child;
                  // Fallback gradient sementara menunggu decode
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF065F46), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF065F46), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            // ── Overlay gelap HANYA di area teks agar terbaca ──
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.black.withOpacity(0.0),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            // ── Dekorasi lingkaran ──
            Positioned(
              top: -30, right: -20,
              child: Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Baris atas: welcome + jam ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── Kiri: teks welcome + badge jabatan ──
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Welcome + nama dalam 1 baris
                            Row(
                              children: [
                                Text(
                                  _lang == 'EN' ? 'Hello, '
                                      : _lang == 'ZH' ? '你好, '
                                      : 'Halo, ',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withOpacity(0.90),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.6),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    _adminName,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.7),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            // Badge jabatan dari DB (via _AnimatedAdminBadge)
                            _AnimatedAdminBadge(lang: _lang, jabatan: _adminJabatan),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // ── Kanan: jam analog + digital + tanggal ──
                      _DigitalClockWidget(lang: _lang),
                    ],
                  ),
                ),
                // ── Divider ──
                Container(height: 1, color: Colors.white.withOpacity(0.18)),
                // ── 4 Stats Card ──
                _isLoadingStats
                    ? _buildBannerStatsShimmer()
                    : _buildBannerStats(),
                const SizedBox(height: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Shimmer stats dalam banner ──
  Widget _buildBannerStatsShimmer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: List.generate(4, (_) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── 4 Stats dalam banner ──
  Widget _buildBannerStats() {
    final stats = [
      _BannerStat(
        label: _lang == 'EN' ? 'Users' : _lang == 'ZH' ? '用户' : 'Pengguna',
        value: _totalUsers,
        icon: Icons.people_rounded,
        color: const Color(0xFF3B82F6),
        iconBg: const Color(0xFF3B82F6),
      ),
      _BannerStat(
        label: _lang == 'EN' ? 'Locations' : _lang == 'ZH' ? '位置' : 'Lokasi',
        value: _totalLokasi,
        icon: Icons.location_city_rounded,
        color: const Color(0xFF10B981),
        iconBg: const Color(0xFF10B981),
      ),
      _BannerStat(
        label: _lang == 'EN' ? 'Categories' : _lang == 'ZH' ? '类别' : 'Kategori',
        value: _totalKategori,
        icon: Icons.category_rounded,
        color: const Color(0xFFF59E0B),
        iconBg: const Color(0xFFF59E0B),
      ),
      _BannerStat(
        label: _lang == 'EN' ? 'Findings' : _lang == 'ZH' ? '发现' : 'Temuan',
        value: _totalTemuan,
        icon: Icons.assignment_rounded,
        color: const Color(0xFFEF4444),
        iconBg: const Color(0xFFEF4444),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      child: Row(
        children: stats.map((s) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: s.color,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: s.color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(s.icon, color: Colors.white.withOpacity(0.90), size: 18),
                  const SizedBox(height: 5),
                  Text(
                    '${s.value}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.label,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.88),
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
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

  Widget _buildMenuGrid() {
    final menus = [
      _MenuItem(
        label: _lang == 'EN'
            ? 'User\nManagement'
            : _lang == 'ZH'
                ? '用户\n管理'
                : 'Kelola\nPengguna',
        icon: Icons.manage_accounts_rounded,
        gradient: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
        shadow: const Color(0xFF6366F1),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminUserScreen(lang: _lang),
          ),
        ).then((_) => _fetchStats()),
      ),
      _MenuItem(
        label: _lang == 'EN'
            ? 'Location\nManagement'
            : _lang == 'ZH'
                ? '位置\n管理'
                : 'Kelola\nLokasi',
        icon: Icons.location_on_rounded,
        gradient: const [Color(0xFF10B981), Color(0xFF059669)],
        shadow: const Color(0xFF10B981),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminLocationScreen(lang: _lang),
          ),
        ).then((_) => _fetchStats()),
      ),
      _MenuItem(
        label: _lang == 'EN'
            ? 'Category\nManagement'
            : _lang == 'ZH'
                ? '类别\n管理'
                : 'Kelola\nKategori',
        icon: Icons.category_rounded,
        gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        shadow: const Color(0xFFF59E0B),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminCategoryScreen(lang: _lang),
          ),
        ).then((_) => _fetchStats()),
      ),
      _MenuItem(
        label: _lang == 'EN'
            ? 'App\nSettings'
            : _lang == 'ZH'
                ? '应用\n设置'
                : 'Pengaturan\nAplikasi',
        icon: Icons.settings_rounded,
        gradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
        shadow: const Color(0xFFEF4444),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminSettingsScreen(lang: _lang),
          ),
        ).then((_) => _fetchStats()),
      ),
      // ── 2 MENU BARU ──
      _MenuItem(
        label: _lang == 'EN'
            ? 'Point\nConfiguration'
            : _lang == 'ZH'
                ? '积分\n配置'
                : 'Konfigurasi\nPoin',
        icon: Icons.stars_rounded,
        gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        shadow: const Color(0xFF8B5CF6),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminPoinScreen(lang: _lang),
          ),
        ),
      ),
      _MenuItem(
        label: _lang == 'EN'
            ? 'Help\nReports'
            : _lang == 'ZH'
                ? '帮助\n报告'
                : 'Laporan\nBantuan',
        icon: Icons.support_agent_rounded,
        gradient: const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
        shadow: const Color(0xFF0EA5E9),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminHelpReportsScreen(lang: _lang),
          ),
        ),
      ),
      _MenuItem(
        label: _lang == 'EN'
            ? 'Audit\nLocation'
            : _lang == 'ZH'
                ? '审计\n位置'
                : 'Audit\nLokasi',
        icon: Icons.fact_check_rounded,
        gradient: const [Color(0xFF0EA5E9), Color(0xFF0369A1)],
        shadow: const Color(0xFF0EA5E9),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AuditLocationScreen(lang: _lang),
          ),
        ).then((_) => _fetchStats()),
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
      itemBuilder: (_, i) => _buildMenuCard(menus[i]),
    );
  }

  Widget _buildMenuCard(_MenuItem item) {
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
              color: item.shadow.withOpacity(0.35),
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
                  size: 70, color: Colors.white.withOpacity(0.15)),
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
                      color: Colors.white.withOpacity(0.2),
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
                            _lang == 'EN' ? 'Manage' : _lang == 'ZH' ? '管理' : 'Kelola',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.75),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios,
                              size: 9, color: Colors.white.withOpacity(0.75)),
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

  // ════════════════════════════════════════════════
  // LEADERBOARD — ANALYTICS STYLE METHODS
  // ════════════════════════════════════════════════

  void _initLbLocale() {
    final locale = _lang == 'ID' ? 'id_ID' : (_lang == 'EN' ? 'en_US' : 'zh_CN');
    _lbTranslatedMonths = List.generate(12, (i) =>
        DateFormat.MMM(locale).format(DateTime(2000, i + 1)));
    _lbTranslatedRoles = [
      _lang == 'ID' ? 'Eksekutif' : _lang == 'ZH' ? '行政' : 'Executive',
      _lang == 'ID' ? 'Profesional' : _lang == 'ZH' ? '专业' : 'Professional',
      _lang == 'ID' ? 'Visitor' : _lang == 'ZH' ? '访客' : 'Visitor',
    ];
    _lbTranslatedLocationLevels = [
      _lang == 'ID' ? 'Lokasi' : _lang == 'ZH' ? '位置' : 'Location',
      _lang == 'ID' ? 'Unit' : 'Unit',
      _lang == 'ID' ? 'Subunit' : _lang == 'ZH' ? '子单元' : 'Sub-unit',
      _lang == 'ID' ? 'Area' : _lang == 'ZH' ? '区域' : 'Area',
    ];
  }

  Future<void> _lbFetchUnits() async {
    try {
      final response = await Supabase.instance.client.from('unit').select('id_unit, nama_unit');
      if (mounted) setState(() => _lbUnitList = List<Map<String, dynamic>>.from(response));
    } catch (e) { debugPrint('Error fetching lb units: $e'); }
  }

  Future<void> _lbFetchTarget() async {
    try {
      final month = _lbSelectedMonthIndex + 1;
      final year = DateTime.now().year;
      final data = await Supabase.instance.client
          .from('target_bulanan').select()
          .eq('bulan', month).eq('tahun', year).maybeSingle();
      if (mounted && data != null) {
        setState(() {
          _lbTargetAnggota  = data['target_anggota']  ?? 2;
          _lbTargetInspeksi = data['target_inspeksi'] ?? 2;
          // target chart per-tab
          _lbChartTargetTemuan       = data['target_anggota']  ?? 2;
          _lbChartTargetPenyelesaian = data['target_inspeksi'] ?? 2;
          _lbChartTargetLokasi       = data['target_lokasi']   ?? 5;
          _lbChartTargetUnit         = data['target_unit']     ?? 5;
          _lbChartTargetSubunit      = data['target_subunit']  ?? 5;
          _lbChartTargetArea         = data['target_area']     ?? 5;
        });
      }
    } catch (e) { debugPrint('Error fetching lb target: $e'); }
  }

  void _lbRebuildTabControllerIfNeeded(int newCount) {
    if (_lbCurrentTabCount == newCount) {
      _lbActiveTabIndex = _lbTabController.index;
      return;
    }
    _lbActiveTabIndex = 0;
    _lbTabController.removeListener(_lbOnTabChanged);
    _lbTabController.dispose();
    _lbTabController = TabController(length: newCount, vsync: this);
    _lbCurrentTabCount = newCount;
    _lbTabController.addListener(_lbOnTabChanged);
  }

  void _lbFetchAllData({bool fromTabFilter = false}) {
    if (!fromTabFilter) _lbIsChartLoadingForTab = false;

    final roleBackend = ['Eksekutif', 'Profesional', 'Visitor'][
        _lbTranslatedRoles.indexOf(_lbSelectedInspectionRole).clamp(0, 2)];
    final levelBackend = ['Lokasi', 'Unit', 'Subunit', 'Area'][
        _lbTranslatedLocationLevels.indexOf(_lbSelectedLocationLevel).clamp(0, 3)];

    final int newTabCount = _lbFindingType == 'KTS Production' ? 2
        : _lbFindingType == 'Accident' ? 3
        : 4;

    if (!fromTabFilter && _lbCurrentTabCount != newTabCount) _lbActiveTabIndex = 0;
    _lbRebuildTabControllerIfNeeded(newTabCount);

    setState(() {
      _lbLastUpdated = DateTime.now();
      final month = _lbSelectedMonthIndex + 1;
      final year = DateTime.now().year;

      if (_lbFindingType == '5R') {
        if (_lbFilterMode == 'daily' && _lbSelectedDate != null) {
          _lbAnggotaFuture   = _lbFetchAnggotaDaily(_lbSelectedDate!);
          _lbInspeksiFuture  = _lbFetchInspeksiDaily(_lbSelectedDate!, roleBackend);
          _lbLokasiFuture    = _lbFetchLokasiDaily(_lbSelectedDate!, levelBackend);
        } else {
          _lbAnggotaFuture       = _lbFetchAnggota(month, year);
          _lbInspeksiFuture      = _lbFetchInspeksi(month, year, roleBackend);
          _lbLokasiFuture        = _lbFetchLokasi(month, year, levelBackend);
          _lbAuditLokasiFuture   = _lbFetchAuditLokasi(month, year, levelBackend);
        }
        _lbRecurringFuture = _lbFetchRecurring(ktsOnly: false);
      } else if (_lbFindingType == 'KTS Production') {
        if (_lbFilterMode == 'daily' && _lbSelectedDate != null) {
          _lbKtsAnggotaFuture = _lbFetchKtsAnggotaDaily(_lbSelectedDate!);
        } else {
          _lbKtsAnggotaFuture = _lbFetchKtsAnggota(month, year);
        }
        _lbRecurringFuture = _lbFetchRecurring(ktsOnly: true);
      } else {
        if (_lbFilterMode == 'daily' && _lbSelectedDate != null) {
          _lbAccidentAnggotaFuture = _lbFetchAccidentAnggotaDaily(_lbSelectedDate!);
          _lbAccidentLokasiFuture  = _lbFetchAccidentLokasiDaily(_lbSelectedDate!, levelBackend);
        } else {
          _lbAccidentAnggotaFuture = _lbFetchAccidentAnggota(month, year);
          _lbAccidentLokasiFuture  = _lbFetchAccidentLokasi(month, year, levelBackend);
        }
        _lbAccidentRecurringFuture = _lbFetchAccidentRecurring();
      }
      _lbChartFuture = _lbFetchChartData(month, year);
      _lbChartRefreshKey++;
      _lbRecurringChartFuture = _lbFetchRecurringChart();
      _lbRecurringChartRefreshKey++;
    });
  }

  void _lbOnTabChanged() {
    if (!mounted) return;
    if (_lbTabController.indexIsChanging) return;
    final newIdx = _lbTabController.index;
    if (_lbActiveTabIndex == newIdx) return;

    final month = _lbSelectedMonthIndex + 1;
    final year = DateTime.now().year;
    setState(() {
      _lbIsChartLoadingForTab = true;
      _lbActiveTabIndex = newIdx;
    });

    _lbFetchChartData(month, year).then((res) {
      if (!mounted) return;
      setState(() {
        _lbChartFuture = Future.value(res);
        _lbChartRefreshKey++;
        _lbIsChartLoadingForTab = false;
      });
    });
  }

  // ── Fetch Methods ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _lbFetchAnggota(int month, int year) async {
    try {
      var q = Supabase.instance.client.from('User')
          .select('id_user, nama, gambar_user, id_unit, unit!user_id_unit_fkey(nama_unit)');
      if (_lbSelectedUnitId != null) q = q.eq('id_unit', _lbSelectedUnitId!);
      final users = await q;
      if (users.isEmpty) return [];
      final userIds = (users as List).map((u) => u['id_user'].toString()).toList();
      final temuanRes = await Supabase.instance.client.from('temuan')
          .select('id_user, id_penyelesaian')
          .neq('jenis_temuan', 'KTS Production')
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at', DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String())
          .inFilter('id_user', userIds);
      final Map<String, Map<String, int>> stats = {};
      for (final t in temuanRes) {
        final uid = t['id_user']?.toString() ?? '';
        if (uid.isEmpty) continue;
        stats.putIfAbsent(uid, () => {'temuan': 0, 'selesai': 0});
        stats[uid]!['temuan'] = stats[uid]!['temuan']! + 1;
        if (t['id_penyelesaian'] != null) stats[uid]!['selesai'] = stats[uid]!['selesai']! + 1;
      }
      final result = (users as List).map<Map<String, dynamic>>((u) {
        final uid = u['id_user']?.toString() ?? '';
        final s = stats[uid] ?? {'temuan': 0, 'selesai': 0};
        return {
          'nama': u['nama'] ?? '-',
          'unitName': (u['unit'] as Map<String, dynamic>?)?['nama_unit'],
          'findings': s['temuan']!,
          'completed': s['selesai']!,
          'avatarUrl': u['gambar_user'],
          'isSelf': uid == Supabase.instance.client.auth.currentUser?.id,
        };
      }).toList();
      result.sort((a, b) => (b['findings'] as int).compareTo(a['findings'] as int));
      return result;
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> _lbFetchInspeksi(int month, int year, String role) async {
    try {
      final roleCol = role == 'Eksekutif' ? 'is_eksekutif'
          : role == 'Profesional' ? 'is_pro' : 'is_visitor';
      final res = await Supabase.instance.client.from('temuan')
          .select('id_user, User_Creator:User!temuan_id_user_fkey(nama)')
          .neq('jenis_temuan', 'KTS Production')
          .eq(roleCol, true)
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at', DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String());
      final Map<String, Map<String, dynamic>> grouped = {};
      for (final item in res) {
        final user = item['User_Creator'] as Map<String, dynamic>?;
        if (user == null) continue;
        final uid = item['id_user']?.toString() ?? '';
        grouped.putIfAbsent(uid, () => {'nama': user['nama'] ?? '-', 'findings': 0});
        grouped[uid]!['findings'] = (grouped[uid]!['findings'] as int) + 1;
      }
      final result = grouped.values.toList();
      result.sort((a, b) => (b['findings'] as int).compareTo(a['findings'] as int));
      return result;
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> _lbFetchLokasi(int month, int year, String level) async {
    try {
      final levelLower = level.toLowerCase();
      final idMap = {'lokasi': 'id_lokasi', 'unit': 'id_unit', 'subunit': 'id_subunit', 'area': 'id_area'};
      final nameMap = {'lokasi': 'nama_lokasi', 'unit': 'nama_unit', 'subunit': 'nama_subunit', 'area': 'nama_area'};
      final idCol = idMap[levelLower] ?? 'id_lokasi';
      final nameCol = nameMap[levelLower] ?? 'nama_lokasi';
      final locations = await Supabase.instance.client.from(levelLower).select('$idCol, $nameCol');
      final temuanRes = await Supabase.instance.client.from('temuan')
          .select(idCol).neq('jenis_temuan', 'KTS Production')
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at', DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String())
          .not(idCol, 'is', null);
      final Map<String, int> countMap = {};
      for (final t in temuanRes) {
        final id = t[idCol]?.toString() ?? '';
        if (id.isEmpty) continue;
        countMap[id] = (countMap[id] ?? 0) + 1;
      }
      final result = (locations as List).map<Map<String, dynamic>>((loc) {
        final id = loc[idCol]?.toString() ?? '';
        return {'name': loc[nameCol]?.toString() ?? '-', 'value': countMap[id] ?? 0};
      }).toList();
      result.sort((a, b) => (b['value'] as int).compareTo(a['value'] as int));
      return result;
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> _lbFetchKtsAnggota(int month, int year) async {
    try {
      final res = await Supabase.instance.client.from('temuan')
          .select('id_user, id_penyelesaian, User_Creator:User!temuan_id_user_fkey(nama, gambar_user, id_unit, unit!user_id_unit_fkey(nama_unit))')
          .eq('jenis_temuan', 'KTS Production')
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at', DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String());
      if (res.isEmpty) return [];
      final Map<String, Map<String, dynamic>> grouped = {};
      for (final t in res) {
        final user = t['User_Creator'] as Map<String, dynamic>?;
        if (user == null) continue;
        final uid = t['id_user']?.toString() ?? '';
        if (uid.isEmpty) continue;
        if (_lbSelectedUnitId != null && user['id_unit']?.toString() != _lbSelectedUnitId) continue;
        grouped.putIfAbsent(uid, () => {'nama': user['nama'] ?? '-', 'gambar_user': user['gambar_user'],
          'unitName': (user['unit'] as Map<String, dynamic>?)?['nama_unit'], 'findings': 0, 'completed': 0});
        grouped[uid]!['findings'] = (grouped[uid]!['findings'] as int) + 1;
        if (t['id_penyelesaian'] != null) grouped[uid]!['completed'] = (grouped[uid]!['completed'] as int) + 1;
      }
      final result = grouped.values.toList();
      result.sort((a, b) => (b['findings'] as int).compareTo(a['findings'] as int));
      return result;
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> _lbFetchAccidentAnggota(int month, int year) async {
    try {
      var q = Supabase.instance.client.from('accident_report')
          .select('id_pelapor, status, id_unit')
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at', DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String());
      if (_lbSelectedUnitId != null) q = q.eq('id_unit', _lbSelectedUnitId!);
      final response = await q;
      if (response.isEmpty) return [];
      final Map<String, Map<String, dynamic>> grouped = {};
      for (final item in response) {
        final uid = item['id_pelapor']?.toString() ?? '';
        if (uid.isEmpty) continue;
        grouped.putIfAbsent(uid, () => {'findings': 0, 'completed': 0});
        grouped[uid]!['findings'] = (grouped[uid]!['findings'] as int) + 1;
        if ((item['status'] ?? '') == 'Selesai') grouped[uid]!['completed'] = (grouped[uid]!['completed'] as int) + 1;
      }
      final userIds = grouped.keys.toList();
      final usersRes = await Supabase.instance.client.from('User')
          .select('id_user, nama, gambar_user, id_unit, unit!user_id_unit_fkey(nama_unit)')
          .inFilter('id_user', userIds);
      final result = (usersRes as List).map<Map<String, dynamic>>((u) {
        final uid = u['id_user']?.toString() ?? '';
        final stats = grouped[uid] ?? {'findings': 0, 'completed': 0};
        return {'nama': u['nama'] ?? '-', 'unitName': (u['unit'] as Map<String, dynamic>?)?['nama_unit'],
          'findings': stats['findings'], 'completed': stats['completed'],
          'avatarUrl': u['gambar_user'],
          'isSelf': uid == Supabase.instance.client.auth.currentUser?.id};
      }).toList();
      result.sort((a, b) => (b['findings'] as int).compareTo(a['findings'] as int));
      return result;
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> _lbFetchAccidentLokasi(int month, int year, String level) async {
    try {
      final levelLower = level.toLowerCase();
      final idMap = {'lokasi': 'id_lokasi', 'unit': 'id_unit', 'subunit': 'id_subunit', 'area': 'id_area'};
      final nameMap = {'lokasi': 'nama_lokasi', 'unit': 'nama_unit', 'subunit': 'nama_subunit', 'area': 'nama_area'};
      final idCol = idMap[levelLower] ?? 'id_lokasi';
      final nameCol = nameMap[levelLower] ?? 'nama_lokasi';
      final locations = await Supabase.instance.client.from(levelLower).select('$idCol, $nameCol');
      final reportRes = await Supabase.instance.client.from('accident_report')
          .select(idCol)
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at', DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String())
          .not(idCol, 'is', null);
      final Map<String, int> countMap = {};
      for (final t in reportRes) {
        final id = t[idCol]?.toString() ?? '';
        if (id.isEmpty) continue;
        countMap[id] = (countMap[id] ?? 0) + 1;
      }
      final result = (locations as List).map<Map<String, dynamic>>((loc) {
        final id = loc[idCol]?.toString() ?? '';
        return {'name': loc[nameCol]?.toString() ?? '-', 'value': countMap[id] ?? 0};
      }).toList();
      result.sort((a, b) => (b['value'] as int).compareTo(a['value'] as int));
      return result;
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> _lbFetchRecurring({bool ktsOnly = false}) async {
    try {
      var q = Supabase.instance.client.from('temuan')
          .select('id_temuan, judul_temuan, gambar_temuan, created_at, kategoritemuan(nama_kategoritemuan), jenis_temuan')
          .gte('created_at', _lbRecurringFrom.toIso8601String())
          .lte('created_at', DateTime(_lbRecurringTo.year, _lbRecurringTo.month + 1, 0, 23, 59, 59).toIso8601String());
      if (ktsOnly) { q = q.eq('jenis_temuan', 'KTS Production'); }
      else { q = q.neq('jenis_temuan', 'KTS Production'); }
      if (_lbRecurringUserId != null) q = q.eq('id_user', _lbRecurringUserId!);
      final res = await q.order('created_at', ascending: false);
      final findings = List<Map<String, dynamic>>.from(res);
      if (findings.isEmpty) return [];
      // Simple grouping by judul similarity (shortened version)
      final Map<String, List<Map<String, dynamic>>> groups = {};
      for (final f in findings) {
        final key = (f['judul_temuan'] ?? '').toString().toLowerCase().trim().split(' ').take(3).join(' ');
        groups.putIfAbsent(key, () => []).add(f);
      }
      final result = <Map<String, dynamic>>[];
      groups.forEach((key, items) {
        if (items.length < 2) return;
        result.add({'topic': items.first['judul_temuan'] ?? '-', 'total': items.length,
          'imageUrl': items.first['gambar_temuan'], 'findings': items});
      });
      result.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
      return result;
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> _lbFetchAccidentRecurring() async {
    try {
      var q = Supabase.instance.client.from('accident_report')
          .select('id_laporan, judul, foto_bukti, created_at, status, tingkat_keparahan')
          .gte('created_at', _lbRecurringFrom.toIso8601String())
          .lte('created_at', DateTime(_lbRecurringTo.year, _lbRecurringTo.month + 1, 0, 23, 59, 59).toIso8601String());
      if (_lbRecurringUserId != null) q = q.eq('id_pelapor', _lbRecurringUserId!);
      final res = await q.order('created_at', ascending: false);
      final reports = List<Map<String, dynamic>>.from(res);
      if (reports.isEmpty) return [];
      final Map<String, List<Map<String, dynamic>>> groups = {};
      for (final r in reports) {
        final key = (r['tingkat_keparahan'] ?? '').toString().toLowerCase();
        groups.putIfAbsent(key, () => []).add(r);
      }
      final result = <Map<String, dynamic>>[];
      groups.forEach((key, items) {
        if (items.length < 2) return;
        result.add({'topic': items.first['tingkat_keparahan'] ?? '-', 'total': items.length,
          'imageUrl': items.first['foto_bukti'], 'reports': items});
      });
      result.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
      return result;
    } catch (e) { return []; }
  }

  // ── Daily Fetch Methods ──────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _lbFetchAnggotaDaily(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end   = DateTime(date.year, date.month, date.day, 23, 59, 59);
      var q = Supabase.instance.client.from('User')
          .select('id_user, nama, gambar_user, id_unit, unit!user_id_unit_fkey(nama_unit)');
      if (_lbSelectedUnitId != null) q = q.eq('id_unit', _lbSelectedUnitId!);
      final users = await q;
      if (users.isEmpty) return [];
      final userIds = (users as List).map((u) => u['id_user'].toString()).toList();
      final temuanRes = await Supabase.instance.client.from('temuan')
          .select('id_user, id_penyelesaian')
          .neq('jenis_temuan', 'KTS Production')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .inFilter('id_user', userIds);
      final Map<String, Map<String, int>> stats = {};
      for (final t in temuanRes) {
        final uid = t['id_user']?.toString() ?? '';
        if (uid.isEmpty) continue;
        stats.putIfAbsent(uid, () => {'temuan': 0, 'selesai': 0});
        stats[uid]!['temuan'] = stats[uid]!['temuan']! + 1;
        if (t['id_penyelesaian'] != null) stats[uid]!['selesai'] = stats[uid]!['selesai']! + 1;
      }
      final result = (users as List)
          .where((u) => stats.containsKey(u['id_user']?.toString() ?? ''))
          .map<Map<String, dynamic>>((u) {
        final uid = u['id_user']?.toString() ?? '';
        final s = stats[uid]!;
        return {
          'nama': u['nama'] ?? '-',
          'unitName': (u['unit'] as Map<String, dynamic>?)?['nama_unit'],
          'findings': s['temuan']!,
          'completed': s['selesai']!,
          'avatarUrl': u['gambar_user'],
          'isSelf': uid == Supabase.instance.client.auth.currentUser?.id,
        };
      }).toList();
      result.sort((a, b) => (b['findings'] as int).compareTo(a['findings'] as int));
      return result;
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> _lbFetchInspeksiDaily(DateTime date, String role) async {
    try {
      final start  = DateTime(date.year, date.month, date.day);
      final end    = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final roleCol = role == 'Eksekutif' ? 'is_eksekutif'
          : role == 'Profesional' ? 'is_pro' : 'is_visitor';
      final res = await Supabase.instance.client.from('temuan')
          .select('id_user, User_Creator:User!temuan_id_user_fkey(nama)')
          .neq('jenis_temuan', 'KTS Production')
          .eq(roleCol, true)
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());
      final Map<String, Map<String, dynamic>> grouped = {};
      for (final item in res) {
        final user = item['User_Creator'] as Map<String, dynamic>?;
        if (user == null) continue;
        final uid = item['id_user']?.toString() ?? '';
        grouped.putIfAbsent(uid, () => {'nama': user['nama'] ?? '-', 'findings': 0});
        grouped[uid]!['findings'] = (grouped[uid]!['findings'] as int) + 1;
      }
      final result = grouped.values.toList();
      result.sort((a, b) => (b['findings'] as int).compareTo(a['findings'] as int));
      return result;
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> _lbFetchLokasiDaily(DateTime date, String level) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end   = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final levelLower = level.toLowerCase();
      final idMap   = {'lokasi': 'id_lokasi', 'unit': 'id_unit', 'subunit': 'id_subunit', 'area': 'id_area'};
      final nameMap = {'lokasi': 'nama_lokasi', 'unit': 'nama_unit', 'subunit': 'nama_subunit', 'area': 'nama_area'};
      final idCol   = idMap[levelLower] ?? 'id_lokasi';
      final nameCol = nameMap[levelLower] ?? 'nama_lokasi';
      final locations  = await Supabase.instance.client.from(levelLower).select('$idCol, $nameCol');
      final temuanRes  = await Supabase.instance.client.from('temuan')
          .select(idCol).neq('jenis_temuan', 'KTS Production')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .not(idCol, 'is', null);
      final Map<String, int> countMap = {};
      for (final t in temuanRes) {
        final id = t[idCol]?.toString() ?? '';
        if (id.isEmpty) continue;
        countMap[id] = (countMap[id] ?? 0) + 1;
      }
      final result = (locations as List).map<Map<String, dynamic>>((loc) {
        final id = loc[idCol]?.toString() ?? '';
        return {'name': loc[nameCol]?.toString() ?? '-', 'value': countMap[id] ?? 0};
      }).toList();
      result.sort((a, b) => (b['value'] as int).compareTo(a['value'] as int));
      return result;
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> _lbFetchKtsAnggotaDaily(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end   = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final res = await Supabase.instance.client.from('temuan')
          .select('id_user, id_penyelesaian, User_Creator:User!temuan_id_user_fkey(nama, gambar_user, id_unit, unit!user_id_unit_fkey(nama_unit))')
          .eq('jenis_temuan', 'KTS Production')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());
      if (res.isEmpty) return [];
      final Map<String, Map<String, dynamic>> grouped = {};
      for (final t in res) {
        final user = t['User_Creator'] as Map<String, dynamic>?;
        if (user == null) continue;
        final uid = t['id_user']?.toString() ?? '';
        if (uid.isEmpty) continue;
        if (_lbSelectedUnitId != null && user['id_unit']?.toString() != _lbSelectedUnitId) continue;
        grouped.putIfAbsent(uid, () => {'nama': user['nama'] ?? '-', 'gambar_user': user['gambar_user'],
          'unitName': (user['unit'] as Map<String, dynamic>?)?['nama_unit'], 'findings': 0, 'completed': 0});
        grouped[uid]!['findings'] = (grouped[uid]!['findings'] as int) + 1;
        if (t['id_penyelesaian'] != null) grouped[uid]!['completed'] = (grouped[uid]!['completed'] as int) + 1;
      }
      final result = grouped.values.toList();
      result.sort((a, b) => (b['findings'] as int).compareTo(a['findings'] as int));
      return result;
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> _lbFetchAccidentAnggotaDaily(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end   = DateTime(date.year, date.month, date.day, 23, 59, 59);
      var q = Supabase.instance.client.from('accident_report')
          .select('id_pelapor, status')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());
      if (_lbSelectedUnitId != null) q = q.eq('id_unit', _lbSelectedUnitId!);
      final response = await q;
      if (response.isEmpty) return [];
      final Map<String, Map<String, dynamic>> grouped = {};
      for (final item in response) {
        final uid = item['id_pelapor']?.toString() ?? '';
        if (uid.isEmpty) continue;
        grouped.putIfAbsent(uid, () => {'findings': 0, 'completed': 0});
        grouped[uid]!['findings'] = (grouped[uid]!['findings'] as int) + 1;
        if ((item['status'] ?? '') == 'Selesai') grouped[uid]!['completed'] = (grouped[uid]!['completed'] as int) + 1;
      }
      final userIds = grouped.keys.toList();
      final usersRes = await Supabase.instance.client.from('User')
          .select('id_user, nama, gambar_user, id_unit, unit!user_id_unit_fkey(nama_unit)')
          .inFilter('id_user', userIds);
      final result = (usersRes as List).map<Map<String, dynamic>>((u) {
        final uid = u['id_user']?.toString() ?? '';
        final stats = grouped[uid] ?? {'findings': 0, 'completed': 0};
        return {'nama': u['nama'] ?? '-', 'unitName': (u['unit'] as Map<String, dynamic>?)?['nama_unit'],
          'findings': stats['findings'], 'completed': stats['completed'],
          'avatarUrl': u['gambar_user'],
          'isSelf': uid == Supabase.instance.client.auth.currentUser?.id};
      }).toList();
      result.sort((a, b) => (b['findings'] as int).compareTo(a['findings'] as int));
      return result;
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> _lbFetchAccidentLokasiDaily(DateTime date, String level) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end   = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final levelLower = level.toLowerCase();
      final idMap   = {'lokasi': 'id_lokasi', 'unit': 'id_unit', 'subunit': 'id_subunit', 'area': 'id_area'};
      final nameMap = {'lokasi': 'nama_lokasi', 'unit': 'nama_unit', 'subunit': 'nama_subunit', 'area': 'nama_area'};
      final idCol   = idMap[levelLower] ?? 'id_lokasi';
      final nameCol = nameMap[levelLower] ?? 'nama_lokasi';
      final locations = await Supabase.instance.client.from(levelLower).select('$idCol, $nameCol');
      final reportRes = await Supabase.instance.client.from('accident_report')
          .select(idCol)
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .not(idCol, 'is', null);
      final Map<String, int> countMap = {};
      for (final t in reportRes) {
        final id = t[idCol]?.toString() ?? '';
        if (id.isEmpty) continue;
        countMap[id] = (countMap[id] ?? 0) + 1;
      }
      final result = (locations as List).map<Map<String, dynamic>>((loc) {
        final id = loc[idCol]?.toString() ?? '';
        return {'name': loc[nameCol]?.toString() ?? '-', 'value': countMap[id] ?? 0};
      }).toList();
      result.sort((a, b) => (b['value'] as int).compareTo(a['value'] as int));
      return result;
    } catch (e) { return []; }
  }

  // ── Audit Lokasi Fetch ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _lbFetchAuditLokasi(int month, int year, String level) async {
    try {
      final levelLower = level.toLowerCase();
      final idMap   = {'lokasi': 'id_lokasi', 'unit': 'id_unit', 'subunit': 'id_subunit', 'area': 'id_area'};
      final nameMap = {'lokasi': 'nama_lokasi', 'unit': 'nama_unit', 'subunit': 'nama_subunit', 'area': 'nama_area'};
      final idCol   = idMap[levelLower] ?? 'id_lokasi';
      final nameCol = nameMap[levelLower] ?? 'nama_lokasi';

      final locations = await Supabase.instance.client.from(levelLower)
          .select('$idCol, $nameCol, id_pic');

      final startOfMonth = DateTime(year, month, 1).toIso8601String().split('T').first;
      final endOfMonth   = DateTime(year, month + 1, 0).toIso8601String().split('T').first;

      final auditRows = await Supabase.instance.client
          .from('audit_result')
          .select('id_ref, nilai_audit, tanggal_audit')
          .eq('level_type', levelLower)
          .gte('tanggal_audit', startOfMonth)
          .lte('tanggal_audit', endOfMonth)
          .order('tanggal_audit', ascending: false);

      final Map<String, Map<String, dynamic>> auditMap = {};
      for (final a in auditRows) {
        final ref = a['id_ref'].toString();
        if (!auditMap.containsKey(ref)) auditMap[ref] = a;
      }

      final picIds = (locations as List)
          .where((l) => l['id_pic'] != null)
          .map((l) => l['id_pic'].toString())
          .toSet().toList();
      final Map<String, String> picMap = {};
      if (picIds.isNotEmpty) {
        final picRows = await Supabase.instance.client
            .from('User').select('id_user, nama').inFilter('id_user', picIds);
        for (final p in picRows) {
          picMap[p['id_user'].toString()] = p['nama']?.toString() ?? '-';
        }
      }

      final result = (locations as List).map<Map<String, dynamic>>((loc) {
        final id    = loc[idCol]?.toString() ?? '';
        final audit = auditMap[id];
        return {
          'id':         id,
          'name':       loc[nameCol]?.toString() ?? '-',
          'pic':        loc['id_pic'] != null
              ? (picMap[loc['id_pic'].toString()] ?? 'PIC belum diatur')
              : 'PIC belum diatur',
          'auditScore': audit != null
              ? double.tryParse(audit['nilai_audit']?.toString() ?? '')
              : null,
          'auditDate':  audit?['tanggal_audit']?.toString(),
        };
      }).toList();

      result.sort((a, b) {
        final sa = a['auditScore'] as double?;
        final sb = b['auditScore'] as double?;
        if (sa == null && sb == null) return 0;
        if (sa == null) return 1;
        if (sb == null) return -1;
        return sb.compareTo(sa);
      });
      return result;
    } catch (e) { return []; }
  }

  Future<List<_LbChartBarData>> _lbFetchChartData(int month, int year) async {
    try {
      final daysInMonth = DateUtils.getDaysInMonth(year, month);
      final bool isDaily = _lbFilterMode == 'daily' && _lbSelectedDate != null;
      final startDt = isDaily
          ? DateTime(_lbSelectedDate!.year, _lbSelectedDate!.month, _lbSelectedDate!.day)
          : DateTime(year, month, 1);
      final endDt = isDaily
          ? DateTime(_lbSelectedDate!.year, _lbSelectedDate!.month, _lbSelectedDate!.day, 23, 59, 59)
          : DateTime(year, month + 1, 0, 23, 59, 59);

      List<_LbChartBarData> buildDaily(List<dynamic> res, {bool isAccident = false}) {
        if (isDaily) {
          return [_LbChartBarData(
            date: _lbSelectedDate!.day,
            temuan: res.length,
            penyelesaian: isAccident
                ? res.where((t) => t['status'] == 'Selesai').length
                : res.where((t) => t['id_penyelesaian'] != null).length,
          )];
        }
        final Map<int, int> pMap = {}, sMap = {};
        for (final t in res) {
          final dt = DateTime.tryParse(t['created_at']?.toString() ?? '');
          if (dt == null) continue;
          pMap[dt.day] = (pMap[dt.day] ?? 0) + 1;
          final done = isAccident ? (t['status'] == 'Selesai') : (t['id_penyelesaian'] != null);
          if (done) sMap[dt.day] = (sMap[dt.day] ?? 0) + 1;
        }
        return List.generate(daysInMonth, (i) => _LbChartBarData(
          date: i + 1, temuan: pMap[i + 1] ?? 0, penyelesaian: sMap[i + 1] ?? 0));
      }

      if (_lbFindingType == 'Accident') {
        if (_lbActiveTabIndex == 2) return [];
        final res = await Supabase.instance.client.from('accident_report')
            .select('created_at, status')
            .gte('created_at', startDt.toIso8601String())
            .lte('created_at', endDt.toIso8601String());
        return buildDaily(res, isAccident: true);
      } else if (_lbFindingType == 'KTS Production') {
        if (_lbActiveTabIndex == 1) return [];
        var q = Supabase.instance.client.from('temuan')
            .select('created_at, id_penyelesaian, id_user')
            .eq('jenis_temuan', 'KTS Production')
            .gte('created_at', startDt.toIso8601String())
            .lte('created_at', endDt.toIso8601String());
        if (_lbSelectedUnitId != null) {
          final usersInUnit = await Supabase.instance.client
              .from('User').select('id_user').eq('id_unit', _lbSelectedUnitId!);
          final uids = (usersInUnit as List).map((u) => u['id_user'].toString()).toList();
          if (uids.isEmpty) return List.generate(isDaily ? 1 : daysInMonth,
            (i) => _LbChartBarData(date: isDaily ? _lbSelectedDate!.day : i + 1, temuan: 0, penyelesaian: 0));
          q = q.inFilter('id_user', uids);
        }
        return buildDaily(await q);
      } else {
        if (_lbActiveTabIndex == 3) return [];
        if (_lbActiveTabIndex == 0) {
          var q = Supabase.instance.client.from('temuan')
              .select('created_at, id_penyelesaian, id_user')
              .neq('jenis_temuan', 'KTS Production')
              .gte('created_at', startDt.toIso8601String())
              .lte('created_at', endDt.toIso8601String());
          if (_lbSelectedUnitId != null) {
            final usersInUnit = await Supabase.instance.client
                .from('User').select('id_user').eq('id_unit', _lbSelectedUnitId!);
            final uids = (usersInUnit as List).map((u) => u['id_user'].toString()).toList();
            if (uids.isEmpty) return List.generate(isDaily ? 1 : daysInMonth,
              (i) => _LbChartBarData(date: isDaily ? _lbSelectedDate!.day : i + 1, temuan: 0, penyelesaian: 0));
            q = q.inFilter('id_user', uids);
          }
          return buildDaily(await q);
        } else if (_lbActiveTabIndex == 1) {
          final roleBackend = ['Eksekutif', 'Profesional', 'Visitor'][
              _lbTranslatedRoles.indexOf(_lbSelectedInspectionRole).clamp(0, 2)];
          var q = Supabase.instance.client.from('temuan')
              .select('created_at, id_penyelesaian')
              .neq('jenis_temuan', 'KTS Production')
              .gte('created_at', startDt.toIso8601String())
              .lte('created_at', endDt.toIso8601String());
          if (roleBackend == 'Eksekutif') q = q.eq('is_eksekutif', true);
          else if (roleBackend == 'Profesional') q = q.eq('is_pro', true);
          else q = q.eq('is_visitor', true);
          return buildDaily(await q);
        } else {
          // Tab Lokasi (index 2): monthly → audit score, daily → temuan count
          if (!isDaily) {
            final levelBackend = ['lokasi', 'unit', 'subunit', 'area'][
                _lbTranslatedLocationLevels.indexOf(_lbSelectedLocationLevel).clamp(0, 3)];
            final startStr = DateTime(year, month, 1).toIso8601String().split('T').first;
            final endStr   = DateTime(year, month + 1, 0).toIso8601String().split('T').first;
            final auditRes = await Supabase.instance.client
                .from('audit_result')
                .select('tanggal_audit, nilai_audit')
                .eq('level_type', levelBackend)
                .gte('tanggal_audit', startStr)
                .lte('tanggal_audit', endStr);
            final Map<int, List<double>> dayScores = {};
            for (final a in auditRes) {
              final dt = DateTime.tryParse(a['tanggal_audit']?.toString() ?? '');
              if (dt == null) continue;
              final score = double.tryParse(a['nilai_audit']?.toString() ?? '');
              if (score == null) continue;
              dayScores.putIfAbsent(dt.day, () => []).add(score);
            }
            return List.generate(daysInMonth, (i) {
              final day = i + 1;
              final scores = dayScores[day] ?? [];
              final avg = scores.isEmpty
                  ? 0
                  : (scores.reduce((a, b) => a + b) / scores.length).round();
              return _LbChartBarData(date: day, temuan: avg, penyelesaian: 0);
            });
          }
          final levelBackend = ['lokasi', 'unit', 'subunit', 'area'][
              _lbTranslatedLocationLevels.indexOf(_lbSelectedLocationLevel).clamp(0, 3)];
          final idColMap = {'lokasi': 'id_lokasi', 'unit': 'id_unit', 'subunit': 'id_subunit', 'area': 'id_area'};
          final idCol = idColMap[levelBackend] ?? 'id_lokasi';
          final res = await Supabase.instance.client.from('temuan')
              .select('created_at, id_penyelesaian')
              .neq('jenis_temuan', 'KTS Production')
              .gte('created_at', startDt.toIso8601String())
              .lte('created_at', endDt.toIso8601String())
              .not(idCol, 'is', null);
          return buildDaily(res);
        }
      }
    } catch (e) { return []; }
  }

  Future<List<_LbChartBarData>> _lbFetchRecurringChart() async {
    try {
      final fromStr = _lbRecurringFrom.toIso8601String();
      final toStr = DateTime(_lbRecurringTo.year, _lbRecurringTo.month + 1, 0, 23, 59, 59).toIso8601String();
      final Map<String, int> pMap = {}, sMap = {};
      if (_lbFindingType == 'Accident') {
        final res = await Supabase.instance.client.from('accident_report')
            .select('created_at, status').gte('created_at', fromStr).lte('created_at', toStr);
        for (final t in res) {
          final dt = DateTime.tryParse(t['created_at']?.toString() ?? '');
          if (dt == null) continue;
          final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
          pMap[key] = (pMap[key] ?? 0) + 1;
          if (t['status'] == 'Selesai') sMap[key] = (sMap[key] ?? 0) + 1;
        }
      } else {
        var q = Supabase.instance.client.from('temuan')
            .select('created_at, id_penyelesaian').gte('created_at', fromStr).lte('created_at', toStr);
        if (_lbFindingType == 'KTS Production') q = q.eq('jenis_temuan', 'KTS Production');
        else q = q.neq('jenis_temuan', 'KTS Production');
        final res = await q;
        for (final t in res) {
          final dt = DateTime.tryParse(t['created_at']?.toString() ?? '');
          if (dt == null) continue;
          final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
          pMap[key] = (pMap[key] ?? 0) + 1;
          if (t['id_penyelesaian'] != null) sMap[key] = (sMap[key] ?? 0) + 1;
        }
      }
      final result = <_LbChartBarData>[];
      DateTime cur = DateTime(_lbRecurringFrom.year, _lbRecurringFrom.month);
      final endM = DateTime(_lbRecurringTo.year, _lbRecurringTo.month);
      int idx = 1;
      while (!cur.isAfter(endM)) {
        final key = '${cur.year}-${cur.month.toString().padLeft(2, '0')}';
        result.add(_LbChartBarData(date: idx++, temuan: pMap[key] ?? 0, penyelesaian: sMap[key] ?? 0));
        cur = DateTime(cur.year, cur.month + 1);
      }
      return result;
    } catch (e) { return []; }
  }

  // ── UI Methods ────────────────────────────────────────────────────────────────

  String get _lbLastUpdatedText {
    if (_lbLastUpdated == null) return _lang == 'ID' ? 'Memuat data...' : 'Loading data...';
    final formattedDate = DateFormat('d MMM yyyy HH:mm',
        _lang == 'ID' ? 'id_ID' : 'en_US').format(_lbLastUpdated!);
    final prefix = _lang == 'ID' ? 'Terakhir diperbarui pada'
        : _lang == 'ZH' ? '最后更新于' : 'Last updated at';
    return '$prefix $formattedDate (GMT+7)';
  }

  Color _lbActiveColor() {
    if (_lbFindingType == 'KTS Production') return const Color(0xFFF59E0B);
    if (_lbFindingType == 'Accident') return const Color(0xFFEF4444);
    return const Color(0xFF059669);
  }

  Widget _lbBuildFilterButton({
    required String label,
    required VoidCallback onTap,
    IconData icon = Icons.keyboard_arrow_down_rounded,
    bool isActive = false,
    Color? activeColor,
  }) {
    final color = activeColor ?? _lbActiveColor();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? color : color.withOpacity(0.4), width: 1.5),
          boxShadow: [BoxShadow(color: color.withOpacity(0.10), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(child: Text(label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : color,
          ), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 4),
          Icon(icon, color: isActive ? Colors.white : color, size: 18),
        ]),
      ),
    );
  }

  Widget _lbBuildChartShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 4, 0, 8),
        height: 80,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _lbBuildTableShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Column(
        children: List.generate(5, (_) => Container(
          height: 52,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
        )),
      ),
    );
  }

  Widget _lbBuildCollapsibleChart() {
    final activeColor = _lbActiveColor();
    final locale = _lang == 'ID' ? 'id_ID' : (_lang == 'EN' ? 'en_US' : 'zh_CN');
    final monthLabel = _lbFilterMode == 'daily' && _lbSelectedDate != null
        ? DateFormat('d MMM yyyy', locale).format(_lbSelectedDate!)
        : DateFormat('MMMM yyyy', locale)
            .format(DateTime(DateTime.now().year, _lbSelectedMonthIndex + 1));

    final bool isRecurringTab =
        (_lbFindingType == '5R' && _lbActiveTabIndex == 3) ||
        (_lbFindingType == 'KTS Production' && _lbActiveTabIndex == 1) ||
        (_lbFindingType == 'Accident' && _lbActiveTabIndex == 2);
    if (isRecurringTab) return const SizedBox.shrink();
    if (_lbIsChartLoadingForTab) return _lbBuildChartShimmer();

    // KTS Production tab 0 → Pie Chart
    if (_lbFindingType == 'KTS Production' && _lbActiveTabIndex == 0) {
      return Column(children: [
        GestureDetector(
          onTap: () => setState(() => _lbIsChartExpanded = !_lbIsChartExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: activeColor.withOpacity(0.4), width: 1.2),
              boxShadow: [BoxShadow(color: activeColor.withOpacity(0.07), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              Icon(Icons.bar_chart_rounded, size: 16, color: activeColor),
              const SizedBox(width: 8),
              Expanded(child: Text(
                _lang == 'ID' ? 'Grafik $monthLabel' : 'Chart $monthLabel',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: activeColor))),
              AnimatedRotation(turns: _lbIsChartExpanded ? 0.5 : 0, duration: const Duration(milliseconds: 250),
                child: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: activeColor)),
            ]),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
          child: _lbIsChartExpanded
              ? FutureBuilder<List<Map<String, dynamic>>>(
                  future: _lbKtsAnggotaFuture,
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) return _lbBuildChartShimmer();
                    final data = snap.data ?? [];
                    final totalFindings  = data.fold<int>(0, (s, m) => s + ((m['findings'] as int?) ?? 0));
                    final totalCompleted = data.fold<int>(0, (s, m) => s + ((m['completed'] as int?) ?? 0));
                    return _lbBuildPieChart(
                      totalPrimary: totalFindings, totalSecondary: totalCompleted,
                      colorPrimary: const Color(0xFFF59E0B), colorSecondary: const Color(0xFF10B981),
                      labelPrimary: _lang == 'ID' ? 'Temuan' : 'Findings',
                      labelSecondary: _lang == 'ID' ? 'Selesai' : 'Completed',
                      activeColor: activeColor, monthLabel: monthLabel,
                    );
                  })
              : const SizedBox.shrink(),
        ),
      ]);
    }

    // Accident tab 0 → Pie Chart
    if (_lbFindingType == 'Accident' && _lbActiveTabIndex == 0) {
      return Column(children: [
        GestureDetector(
          onTap: () => setState(() => _lbIsChartExpanded = !_lbIsChartExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: activeColor.withOpacity(0.4), width: 1.2),
              boxShadow: [BoxShadow(color: activeColor.withOpacity(0.07), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              Icon(Icons.bar_chart_rounded, size: 16, color: activeColor),
              const SizedBox(width: 8),
              Expanded(child: Text(
                _lang == 'ID' ? 'Grafik $monthLabel' : 'Chart $monthLabel',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: activeColor))),
              AnimatedRotation(turns: _lbIsChartExpanded ? 0.5 : 0, duration: const Duration(milliseconds: 250),
                child: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: activeColor)),
            ]),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
          child: _lbIsChartExpanded
              ? FutureBuilder<List<Map<String, dynamic>>>(
                  future: _lbAccidentAnggotaFuture,
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) return _lbBuildChartShimmer();
                    final data = snap.data ?? [];
                    final totalReports   = data.fold<int>(0, (s, m) => s + ((m['findings'] as int?) ?? 0));
                    final totalCompleted = data.fold<int>(0, (s, m) => s + ((m['completed'] as int?) ?? 0));
                    return _lbBuildPieChart(
                      totalPrimary: totalReports, totalSecondary: totalCompleted,
                      colorPrimary: const Color(0xFFEF4444), colorSecondary: const Color(0xFF10B981),
                      labelPrimary: _lang == 'ID' ? 'Laporan' : 'Reports',
                      labelSecondary: _lang == 'ID' ? 'Selesai' : 'Completed',
                      activeColor: activeColor, monthLabel: monthLabel,
                    );
                  })
              : const SizedBox.shrink(),
        ),
      ]);
    }

    // Accident tab 1 → Pie Chart Lokasi
    if (_lbFindingType == 'Accident' && _lbActiveTabIndex == 1) {
      return Column(children: [
        GestureDetector(
          onTap: () => setState(() => _lbIsChartExpanded = !_lbIsChartExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: activeColor.withOpacity(0.4), width: 1.2),
              boxShadow: [BoxShadow(color: activeColor.withOpacity(0.07), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              Icon(Icons.bar_chart_rounded, size: 16, color: activeColor),
              const SizedBox(width: 8),
              Expanded(child: Text(
                _lang == 'ID' ? 'Grafik $monthLabel' : 'Chart $monthLabel',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: activeColor))),
              AnimatedRotation(turns: _lbIsChartExpanded ? 0.5 : 0, duration: const Duration(milliseconds: 250),
                child: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: activeColor)),
            ]),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
          child: _lbIsChartExpanded
              ? FutureBuilder<List<Map<String, dynamic>>>(
                  future: _lbAccidentLokasiFuture,
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) return _lbBuildChartShimmer();
                    final data = snap.data ?? [];
                    final totalReports = data.fold<int>(0, (s, l) => s + ((l['value'] as int?) ?? 0));
                    final topLoc = data.isNotEmpty ? data.first : null;
                    final topCount = topLoc != null ? ((topLoc['value'] as int?) ?? 0) : 0;
                    return _lbBuildPieChart(
                      totalPrimary: topCount, totalSecondary: totalReports - topCount,
                      colorPrimary: const Color(0xFFEF4444), colorSecondary: const Color(0xFFF97316),
                      labelPrimary: topLoc != null ? (topLoc['name'] as String? ?? '-') : (_lang == 'ID' ? 'Teratas' : 'Top'),
                      labelSecondary: _lang == 'ID' ? 'Lokasi Lainnya' : 'Other Locations',
                      activeColor: activeColor, monthLabel: monthLabel,
                    );
                  })
              : const SizedBox.shrink(),
        ),
      ]);
    }

    // Default → Bar Chart dengan target line
    return Column(children: [
      GestureDetector(
        onTap: () => setState(() => _lbIsChartExpanded = !_lbIsChartExpanded),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: activeColor.withOpacity(0.4), width: 1.2),
            boxShadow: [BoxShadow(color: activeColor.withOpacity(0.07), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            Icon(Icons.bar_chart_rounded, size: 16, color: activeColor),
            const SizedBox(width: 8),
            Expanded(child: Text(
              _lang == 'ID' ? 'Grafik $monthLabel' : _lang == 'ZH' ? '$monthLabel 图表' : 'Chart $monthLabel',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: activeColor))),
            AnimatedRotation(turns: _lbIsChartExpanded ? 0.5 : 0, duration: const Duration(milliseconds: 250),
              child: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: activeColor)),
          ]),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
        child: _lbIsChartExpanded
            ? FutureBuilder<List<_LbChartBarData>>(
                key: ValueKey('lb-chart-$_lbChartRefreshKey'),
                future: _lbChartFuture,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) return _lbBuildChartShimmer();
                  final data = snap.data ?? [];
                  if (data.isEmpty || data.every((d) => d.temuan == 0 && d.penyelesaian == 0)) {
                    return Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: activeColor.withOpacity(0.2))),
                      child: Center(child: Text(
                        _lang == 'ID' ? 'Tidak ada data grafik' : 'No chart data',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
                    );
                  }
                  return _lbRenderBarChartWithTarget(data, activeColor);
                })
            : const SizedBox.shrink(),
      ),
    ]);
  }

  Widget _lbBuildPieChart({
    required int totalPrimary, required int totalSecondary,
    required Color colorPrimary, required Color colorSecondary,
    required String labelPrimary, required String labelSecondary,
    required Color activeColor, required String monthLabel,
  }) {
    final total = totalPrimary + totalSecondary;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: activeColor.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: activeColor.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(Icons.pie_chart_rounded, size: 14, color: activeColor),
            const SizedBox(width: 6),
            Text(_lang == 'ID' ? 'Ringkasan $monthLabel' : 'Summary $monthLabel',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: activeColor)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: activeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('Total: $total',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: activeColor)),
          ),
        ]),
        const SizedBox(height: 12),
        if (total == 0)
          Center(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(children: [
              Icon(Icons.pie_chart_outline, size: 40, color: Colors.grey.shade300),
              const SizedBox(height: 6),
              Text(_lang == 'ID' ? 'Tidak ada data' : 'No data',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            ]),
          ))
        else
          Row(children: [
            SizedBox(width: 120, height: 120,
              child: CustomPaint(
                painter: _LbPieChartPainter(
                  primaryValue: totalPrimary.toDouble(),
                  secondaryValue: totalSecondary.toDouble(),
                  colorPrimary: colorPrimary, colorSecondary: colorSecondary,
                ),
                child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$total', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0C4A6E))),
                  Text(_lang == 'ID' ? 'Total' : 'Total', style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                ])),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(children: [
              _lbPieInfoCard(color: colorPrimary, label: labelPrimary, value: totalPrimary, total: total,
                icon: _lbFindingType == 'Accident' ? Icons.warning_amber_rounded : Icons.search_rounded),
              const SizedBox(height: 8),
              _lbPieInfoCard(color: colorSecondary, label: labelSecondary, value: totalSecondary, total: total,
                icon: Icons.check_circle_outline_rounded),
            ])),
          ]),
      ]),
    );
  }

  Widget _lbPieInfoCard({required Color color, required String label, required int value, required int total, required IconData icon}) {
    final percent = total > 0 ? (value / total * 100).toStringAsFixed(1) : '0.0';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, size: 12, color: color)),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 3),
          ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? value / total : 0,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 3)),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0C4A6E))),
          Text('$percent%', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  Widget _lbRenderBarChartWithTarget(List<_LbChartBarData> data, Color activeColor) {
    const colorPenyelesaian = Color(0xFF10B981);
    const double chartH   = 120.0;
    const double barGroupW = 28.0;
    const double barW      = 8.0;
    const double leftW     = 28.0;

    // Hitung target sesuai tab aktif
    int tTarget = _lbTargetAnggota, pTarget = _lbTargetAnggota;
    if (_lbFindingType == '5R') {
      switch (_lbActiveTabIndex) {
        case 0: tTarget = _lbChartTargetTemuan;       pTarget = _lbChartTargetTemuan; break;
        case 1: tTarget = _lbChartTargetPenyelesaian; pTarget = _lbChartTargetPenyelesaian; break;
        case 2:
          final levelIdx = _lbTranslatedLocationLevels.indexOf(_lbSelectedLocationLevel).clamp(0, 3);
          final levelLower = ['lokasi','unit','subunit','area'][levelIdx];
          switch (levelLower) {
            case 'unit':    tTarget = _lbChartTargetUnit;    pTarget = _lbChartTargetUnit;    break;
            case 'subunit': tTarget = _lbChartTargetSubunit; pTarget = _lbChartTargetSubunit; break;
            case 'area':    tTarget = _lbChartTargetArea;    pTarget = _lbChartTargetArea;    break;
            default:        tTarget = _lbChartTargetLokasi;  pTarget = _lbChartTargetLokasi;
          }
        break;
      }
    }

    final bool showTarget = _lbFindingType == '5R' && _lbActiveTabIndex != 3 && tTarget > 0;

    int maxVal = math.max(tTarget, pTarget).clamp(1, 99999);
    for (final d in data) {
      if (d.temuan > maxVal) maxVal = d.temuan;
      if (d.penyelesaian > maxVal) maxVal = d.penyelesaian;
    }
    maxVal = ((maxVal / 5).ceil() * 5).clamp(1, 9999);
    double valToY(int v) => chartH - (v / maxVal * chartH).clamp(0.0, chartH);
    final yStep  = (maxVal / 4).ceil().clamp(1, 99999);
    final yLabels = List.generate(5, (i) => i * yStep);
    final locale  = _lang == 'ID' ? 'id_ID' : (_lang == 'EN' ? 'en_US' : 'zh_CN');

    // Legend
    final bool isLocationAuditTab = _lbFindingType == '5R' && _lbActiveTabIndex == 2
        && !(_lbFilterMode == 'daily' && _lbSelectedDate != null);

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(0, 10, 8, 6),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: activeColor.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: activeColor.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 32, bottom: 6),
          child: Wrap(spacing: 10, children: [
            if (isLocationAuditTab)
              _lbLegendItem(activeColor, _lang == 'ID' ? 'Rata-rata Nilai Audit' : 'Avg Audit Score')
            else ...[
              _lbLegendItem(activeColor,
                _lbFindingType == 'Accident' ? (_lang == 'ID' ? 'Laporan' : 'Reports') : (_lang == 'ID' ? 'Temuan' : 'Findings')),
              _lbLegendItem(colorPenyelesaian, _lang == 'ID' ? 'Selesai' : 'Completed'),
              if (showTarget) ...[
                _lbLegendDash(const Color(0xFFEF4444),
                  _lbActiveTabIndex == 0 ? (_lang == 'ID' ? 'Target Anggota' : 'Member Target')
                      : _lbActiveTabIndex == 1 ? (_lang == 'ID' ? 'Target Inspeksi' : 'Inspection Target')
                      : (_lang == 'ID' ? 'Target Lokasi' : 'Location Target')),
                _lbLegendDash(const Color(0xFFF59E0B), _lang == 'ID' ? 'Target Selesai' : 'Completion Target'),
              ],
            ],
          ]),
        ),
        SizedBox(
          height: chartH + 28,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: leftW, height: chartH,
              child: Stack(children: yLabels.map((v) {
                final top = valToY(v);
                if (top < 0 || top > chartH) return const SizedBox.shrink();
                return Positioned(top: top - 7, right: 2,
                  child: Text(v >= 1000 ? '${(v/1000).toStringAsFixed(1)}k' : '$v',
                    style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))));
              }).toList()),
            ),
            Expanded(child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: data.length * barGroupW + 8,
                child: Stack(children: [
                  ...yLabels.map((v) => Positioned(top: valToY(v), left: 0, right: 0,
                    child: Container(height: 1, color: const Color(0xFFE0F2FE)))),
                  if (showTarget) ...[
                    Positioned(top: valToY(tTarget), left: 0, right: 0,
                      child: CustomPaint(painter: _LbDashedLine(const Color(0xFFEF4444)), child: const SizedBox(height: 2))),
                    Positioned(top: valToY(pTarget), left: 0, right: 0,
                      child: CustomPaint(painter: _LbDashedLine(const Color(0xFFF59E0B)), child: const SizedBox(height: 2))),
                  ],
                  ...data.asMap().entries.map((entry) {
                    final i  = entry.key;
                    final d  = entry.value;
                    final x  = i * barGroupW + 4.0;
                    final tH = (d.temuan / maxVal * chartH).clamp(0.0, chartH);
                    final pH = (d.penyelesaian / maxVal * chartH).clamp(0.0, chartH);
                    final dateLabel = DateFormat('d/M', locale)
                        .format(DateTime(DateTime.now().year, _lbSelectedMonthIndex + 1, d.date));
                    return Positioned(left: x, top: 0,
                      child: SizedBox(width: barGroupW, height: chartH + 28,
                        child: Column(children: [
                          SizedBox(height: chartH, child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(width: barW, height: tH, decoration: BoxDecoration(
                                color: activeColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(3)))),
                              const SizedBox(width: 2),
                              if (!isLocationAuditTab)
                                Container(width: barW, height: pH, decoration: BoxDecoration(
                                  color: colorPenyelesaian, borderRadius: const BorderRadius.vertical(top: Radius.circular(3)))),
                            ],
                          )),
                          const SizedBox(height: 3),
                          Text(dateLabel, style: const TextStyle(fontSize: 7.5, color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                        ]),
                      ),
                    );
                  }),
                ]),
              ),
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _lbLegendDash(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    SizedBox(width: 14, child: CustomPaint(painter: _LbDashedLine(color), child: const SizedBox(height: 2))),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
  ]);

  Widget _lbRenderBarChart(List<_LbChartBarData> data, Color activeColor) {
    const colorPenyelesaian = Color(0xFF10B981);
    const double chartH = 120.0;
    const double barGroupW = 28.0;
    const double barW = 8.0;
    const double leftW = 28.0;

    int maxVal = 1;
    for (final d in data) {
      if (d.temuan > maxVal) maxVal = d.temuan;
      if (d.penyelesaian > maxVal) maxVal = d.penyelesaian;
    }
    maxVal = ((maxVal / 5).ceil() * 5).clamp(1, 9999);
    double valToY(int v) => chartH - (v / maxVal * chartH).clamp(0.0, chartH);
    final yStep = (maxVal / 4).ceil().clamp(1, 99999);
    final yLabels = List.generate(5, (i) => i * yStep);
    final locale = _lang == 'ID' ? 'id_ID' : (_lang == 'EN' ? 'en_US' : 'zh_CN');

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(0, 10, 8, 6),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: activeColor.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: activeColor.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 32, bottom: 6),
          child: Wrap(spacing: 10, children: [
            _lbLegendItem(activeColor,
              _lbFindingType == 'Accident' ? (_lang == 'ID' ? 'Laporan' : 'Reports')
                  : (_lang == 'ID' ? 'Temuan' : 'Findings')),
            _lbLegendItem(colorPenyelesaian, _lang == 'ID' ? 'Selesai' : 'Completed'),
          ]),
        ),
        SizedBox(
          height: chartH + 28,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: leftW, height: chartH,
              child: Stack(children: yLabels.map((v) {
                final top = valToY(v);
                if (top < 0 || top > chartH) return const SizedBox.shrink();
                return Positioned(top: top - 7, right: 2,
                  child: Text(v >= 1000 ? '${(v/1000).toStringAsFixed(1)}k' : '$v',
                    style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))));
              }).toList()),
            ),
            Expanded(child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: data.length * barGroupW + 8,
                child: Stack(children: [
                  ...yLabels.map((v) => Positioned(top: valToY(v), left: 0, right: 0,
                    child: Container(height: 1, color: const Color(0xFFE0F2FE)))),
                  ...data.asMap().entries.map((entry) {
                    final i = entry.key;
                    final d = entry.value;
                    final x = i * barGroupW + 4.0;
                    final tH = (d.temuan / maxVal * chartH).clamp(0.0, chartH);
                    final pH = (d.penyelesaian / maxVal * chartH).clamp(0.0, chartH);
                    final dateLabel = DateFormat('d/M', locale)
                        .format(DateTime(DateTime.now().year, _lbSelectedMonthIndex + 1, d.date));
                    return Positioned(left: x, top: 0,
                      child: SizedBox(width: barGroupW, height: chartH + 28,
                        child: Column(children: [
                          SizedBox(height: chartH, child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(width: barW, height: tH, decoration: BoxDecoration(
                                color: activeColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(3)))),
                              const SizedBox(width: 2),
                              Container(width: barW, height: pH, decoration: BoxDecoration(
                                color: colorPenyelesaian, borderRadius: const BorderRadius.vertical(top: Radius.circular(3)))),
                            ],
                          )),
                          const SizedBox(height: 3),
                          Text(dateLabel, style: const TextStyle(fontSize: 7.5, color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                        ]),
                      ),
                    );
                  }),
                ]),
              ),
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _lbLegendItem(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
  ]);

  Widget _lbBuildTableHeader() {
    final activeColor = _lbActiveColor();
    final isLokasi = (_lbFindingType == '5R' && _lbActiveTabIndex == 2) ||
        (_lbFindingType == 'Accident' && _lbActiveTabIndex == 1);
    final namaLabel = _lang == 'ID' ? 'Nama' : _lang == 'ZH' ? '名称' : 'Name';
    final temuanLabel = _lbFindingType == 'Accident'
        ? (_lang == 'ID' ? 'Laporan' : 'Reports')
        : (_lang == 'ID' ? 'Temuan' : 'Findings');
    final selesaiLabel = _lang == 'ID' ? 'Selesai' : _lang == 'ZH' ? '已完成' : 'Completed';
    final lokasiLabel = _lang == 'ID' ? 'Lokasi' : _lang == 'ZH' ? '位置' : 'Location';
    final jumlahLabel = _lang == 'ID' ? 'Jumlah' : 'Count';

    return Container(
      color: activeColor.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        Expanded(flex: 3, child: Text(isLokasi ? lokasiLabel : namaLabel,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: activeColor))),
        if (!isLokasi) ...[
          SizedBox(width: 60, child: Text(temuanLabel, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: activeColor))),
          SizedBox(width: 60, child: Text(selesaiLabel, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: activeColor))),
        ] else
          SizedBox(width: 60, child: Text(jumlahLabel, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: activeColor))),
      ]),
    );
  }

  Widget _lbBuildTargetRow() {
    final activeColor = _lbActiveColor();
    final targetLabel = _lang == 'ID' ? 'Target Bulanan' : _lang == 'ZH' ? '每月目标' : 'Monthly Target';
    final isLokasi = (_lbFindingType == '5R' && _lbActiveTabIndex == 2) ||
        (_lbFindingType == 'Accident' && _lbActiveTabIndex == 1);
    if (isLokasi) return const SizedBox.shrink();
    final target = _lbActiveTabIndex == 1 ? _lbTargetInspeksi : _lbTargetAnggota;
    return Container(
      color: activeColor.withOpacity(0.05),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        Expanded(flex: 3, child: Text(targetLabel,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: activeColor))),
        SizedBox(width: 60, child: Text('$target', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: activeColor))),
        SizedBox(width: 60, child: Text('$target', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: activeColor))),
      ]),
    );
  }

  Widget _lbBuildMemberRow(Map<String, dynamic> m, int rank) {
    final activeColor = _lbActiveColor();
    final findings = m['findings'] as int? ?? 0;
    final completed = m['completed'] as int? ?? 0;
    final isSelf = m['isSelf'] as bool? ?? false;
    final target = _lbActiveTabIndex == 1 ? _lbTargetInspeksi : _lbTargetAnggota;
    final fColor = findings >= target ? const Color(0xFF16A34A) : const Color(0xFF0C4A6E);
    final cColor = completed >= target ? const Color(0xFF16A34A) : const Color(0xFF64748B);

    Widget badge;
    if (rank == 1) badge = const Text('🥇', style: TextStyle(fontSize: 18));
    else if (rank == 2) badge = const Text('🥈', style: TextStyle(fontSize: 18));
    else if (rank == 3) badge = const Text('🥉', style: TextStyle(fontSize: 18));
    else badge = Text('$rank', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600));

    final avatarUrl = m['avatarUrl'] as String?;
    final name = m['nama'] as String? ?? '-';
    final unitName = m['unitName'] as String?;

    return Container(
      color: isSelf ? const Color(0xFFFFF7ED) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        SizedBox(width: 28, child: Center(child: badge)),
        const SizedBox(width: 6),
        Expanded(flex: 3, child: Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
            backgroundColor: activeColor.withOpacity(0.15),
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: activeColor))
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0C4A6E)),
                overflow: TextOverflow.ellipsis),
            if (unitName != null && unitName.isNotEmpty)
              Text(unitName, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
          ])),
        ])),
        SizedBox(width: 60, child: Text('$findings', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fColor))),
        SizedBox(width: 60, child: Text('$completed', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cColor))),
      ]),
    );
  }

  Widget _lbBuildLokasiRow(Map<String, dynamic> loc, int rank) {
    final activeColor = _lbActiveColor();
    final value = loc['value'] as int? ?? 0;
    Widget badge;
    if (rank == 1) badge = const Text('🥇', style: TextStyle(fontSize: 18));
    else if (rank == 2) badge = const Text('🥈', style: TextStyle(fontSize: 18));
    else if (rank == 3) badge = const Text('🥉', style: TextStyle(fontSize: 18));
    else badge = Text('$rank', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600));
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        SizedBox(width: 28, child: Center(child: badge)),
        const SizedBox(width: 6),
        Expanded(flex: 3, child: Row(children: [
          Container(width: 32, height: 32,
            decoration: BoxDecoration(color: activeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.location_city_rounded, color: activeColor, size: 18)),
          const SizedBox(width: 8),
          Expanded(child: Text(loc['name'] as String? ?? '-',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0C4A6E)),
            overflow: TextOverflow.ellipsis)),
        ])),
        SizedBox(width: 60, child: Text('$value', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: value > 0 ? activeColor : const Color(0xFF94A3B8)))),
      ]),
    );
  }

  Widget _lbBuildAuditLokasiRow(Map<String, dynamic> loc, int rank, Color activeColor) {
    final score = loc['auditScore'] as double?;
    Color scoreColor;
    if (score == null)        scoreColor = const Color(0xFF94A3B8);
    else if (score >= 80)     scoreColor = const Color(0xFF10B981);
    else if (score >= 60)     scoreColor = const Color(0xFFF59E0B);
    else                      scoreColor = const Color(0xFFEF4444);

    Widget badge;
    if (rank == 1)      badge = const Text('🥇', style: TextStyle(fontSize: 18));
    else if (rank == 2) badge = const Text('🥈', style: TextStyle(fontSize: 18));
    else if (rank == 3) badge = const Text('🥉', style: TextStyle(fontSize: 18));
    else                badge = Text('$rank', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600));

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        SizedBox(width: 28, child: Center(child: badge)),
        const SizedBox(width: 6),
        Expanded(flex: 3, child: Row(children: [
          Container(width: 32, height: 32,
            decoration: BoxDecoration(color: scoreColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.location_city_rounded, color: scoreColor, size: 18)),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(loc['name'] as String? ?? '-',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0C4A6E)),
              overflow: TextOverflow.ellipsis),
            Text(loc['pic'] as String? ?? '-',
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
            if (loc['auditDate'] != null) ...[
              const SizedBox(height: 2),
              ClipRRect(borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: score != null ? score / 100 : 0,
                  backgroundColor: scoreColor.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor), minHeight: 4)),
            ],
          ])),
        ])),
        SizedBox(width: 60, child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text(score != null ? '${score.toStringAsFixed(0)}%' : '-',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: scoreColor)),
          if (loc['auditDate'] != null)
            Text((loc['auditDate'] as String).substring(0, 10),
              style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
        ])),
      ]),
    );
  }

  Widget _lbBuildRecurringCard(Map<String, dynamic> item) {
    final activeColor = _lbActiveColor();
    final topic = item['topic'] as String? ?? '-';
    final total = item['total'] as int? ?? 0;
    final imageUrl = item['imageUrl'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: activeColor.withOpacity(0.25), width: 1.2),
        boxShadow: [BoxShadow(color: activeColor.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
          child: Container(width: 64, height: 64,
            color: activeColor.withOpacity(0.1),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.image_outlined, color: activeColor, size: 24))
                : Icon(Icons.repeat_rounded, color: activeColor, size: 24)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(topic,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0C4A6E)),
          maxLines: 2, overflow: TextOverflow.ellipsis)),
        Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: activeColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: activeColor.withOpacity(0.3)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_lang == 'ID' ? 'Total' : 'Total',
              style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
            Text('$total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: activeColor)),
          ]),
        ),
      ]),
    );
  }

  // ── Month Picker for Leaderboard ──────────────────────────────────────────────
  void _lbShowMonthPicker() async {
    String tempMode  = _lbFilterMode;
    int tempMonthIdx = _lbSelectedMonthIndex;
    DateTime tempDate = _lbSelectedDate ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65, maxWidth: 320),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _lbActiveColor().withOpacity(0.3), width: 1.5)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                decoration: BoxDecoration(color: _lbActiveColor().withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                child: Row(children: [
                  Icon(Icons.calendar_month_rounded, color: _lbActiveColor(), size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_lang == 'ID' ? 'Pilih Bulan' : 'Select Month',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _lbActiveColor()))),
                  IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
                ]),
              ),
              // Toggle Monthly / Daily
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Container(
                  decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0F2FE))),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: ['monthly', 'daily'].map((mode) {
                      final isSel = tempMode == mode;
                      final label = mode == 'monthly'
                          ? (_lang == 'ID' ? 'Bulanan' : 'Monthly')
                          : (_lang == 'ID' ? 'Harian' : 'Daily');
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setSt(() => tempMode = mode),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200), height: 36,
                            decoration: BoxDecoration(
                              color: isSel ? _lbActiveColor() : Colors.transparent,
                              borderRadius: BorderRadius.circular(9)),
                            child: Center(child: Text(label, style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: isSel ? Colors.white : const Color(0xFF64748B)))),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Grid bulan (monthly) atau kalender (daily)
              if (tempMode == 'monthly')
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  child: GridView.builder(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.2),
                    itemCount: 12,
                    itemBuilder: (_, i) {
                      final isSelected = i == tempMonthIdx;
                      final activeColor = _lbActiveColor();
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() { _lbFilterMode = 'monthly'; _lbSelectedMonthIndex = i; _lbSelectedDate = null; });
                          _lbFetchTarget().then((_) => _lbFetchAllData(fromTabFilter: true));
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: isSelected ? activeColor : const Color(0xFFF8FAFF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? activeColor : const Color(0xFFE0F2FE), width: 1.2)),
                          child: Center(child: Text(_lbTranslatedMonths[i],
                            style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF0C4A6E)))),
                        ),
                      );
                    },
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  child: _lbBuildDailyCalendar(tempDate, (d) => setSt(() => tempDate = d),
                    onConfirm: () {
                      Navigator.pop(ctx);
                      setState(() { _lbFilterMode = 'daily'; _lbSelectedDate = tempDate; _lbSelectedMonthIndex = tempDate.month - 1; });
                      _lbFetchAllData(fromTabFilter: true);
                    }),
                ),
            ]),
          ),
        );
      }),
    );
  }

  Widget _lbBuildDailyCalendar(DateTime selectedDate, ValueChanged<DateTime> onDateChanged, {required VoidCallback onConfirm}) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final firstWeekday = DateTime(now.year, now.month, 1).weekday % 7;
    final locale = _lang == 'ID' ? 'id_ID' : (_lang == 'EN' ? 'en_US' : 'zh_CN');
    final monthLabel = DateFormat('MMMM yyyy', locale).format(DateTime(now.year, now.month));
    final dayLabels = _lang == 'ID'
        ? ['Min','Sen','Sel','Rab','Kam','Jum','Sab']
        : ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
    final activeColor = _lbActiveColor();

    return StatefulBuilder(builder: (_, setInner) => Column(children: [
      Text(monthLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0C4A6E))),
      const SizedBox(height: 8),
      Row(children: dayLabels.map((d) => Expanded(
        child: Center(child: Text(d, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))))).toList()),
      const SizedBox(height: 4),
      GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: 3, mainAxisSpacing: 3, childAspectRatio: 1),
        itemCount: firstWeekday + daysInMonth,
        itemBuilder: (_, i) {
          if (i < firstWeekday) return const SizedBox();
          final day = i - firstWeekday + 1;
          final date = DateTime(now.year, now.month, day);
          final isSelected = selectedDate.year == date.year && selectedDate.month == date.month && selectedDate.day == date.day;
          final isToday = now.day == day && now.month == date.month;
          final isFuture = date.isAfter(now);
          return GestureDetector(
            onTap: isFuture ? null : () => setInner(() => onDateChanged(date)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : isToday ? activeColor.withOpacity(0.12) : Colors.transparent,
                shape: BoxShape.circle,
                border: isToday && !isSelected ? Border.all(color: activeColor, width: 1.2) : null),
              child: Center(child: Text('$day', style: TextStyle(
                fontSize: 12, fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : isFuture ? const Color(0xFFBDBDBD) : const Color(0xFF0C4A6E)))),
            ),
          );
        },
      ),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: onConfirm,
        style: ElevatedButton.styleFrom(backgroundColor: activeColor, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 10)),
        child: Text(_lang == 'ID' ? 'Terapkan' : 'Apply',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      )),
    ]));
  }

  // ── Group Picker for Leaderboard ──────────────────────────────────────────────
  void _lbShowGroupPicker() async {
    final allItem = {'id_unit': null, 'nama_unit': _lang == 'ID' ? 'Semua Grup' : _lang == 'ZH' ? '所有组' : 'All Groups'};
    final items = [allItem, ..._lbUnitList];
    final activeColor = _lbActiveColor();

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: activeColor.withOpacity(0.3), width: 1.5)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
              decoration: BoxDecoration(color: activeColor.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
              child: Row(children: [
                Icon(Icons.group_rounded, color: activeColor, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(_lang == 'ID' ? 'Pilih Grup' : 'Select Group',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: activeColor))),
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
              ]),
            ),
            Flexible(child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 10),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                final lbl = item['nama_unit'] as String;
                final id = item['id_unit']?.toString();
                final isSelected = id == _lbSelectedUnitId || (id == null && _lbSelectedUnitId == null);
                return InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _lbSelectedUnitId = id);
                    _lbFetchAllData(fromTabFilter: true);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? activeColor.withOpacity(0.08) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? activeColor : Colors.grey.shade200, width: isSelected ? 1.5 : 1)),
                    child: Row(children: [
                      Expanded(child: Text(lbl, style: TextStyle(fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? activeColor : const Color(0xFF0C4A6E)))),
                      if (isSelected) Icon(Icons.check_circle_rounded, color: activeColor, size: 16),
                    ]),
                  ),
                );
              },
            )),
          ]),
        ),
      ),
    );
  }

  void _lbShowRolePicker() async {
    final activeColor = _lbActiveColor();
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: activeColor.withOpacity(0.3))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
              decoration: BoxDecoration(color: activeColor.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
              child: Row(children: [
                Icon(Icons.badge_rounded, color: activeColor, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(_lang == 'ID' ? 'Pilih Role' : 'Select Role',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: activeColor))),
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
              ]),
            ),
            ..._lbTranslatedRoles.map((r) {
              final isSelected = _lbSelectedInspectionRole == r;
              return InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _lbSelectedInspectionRole = r);
                  _lbFetchAllData(fromTabFilter: true);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? activeColor.withOpacity(0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? activeColor : Colors.grey.shade200, width: isSelected ? 1.5 : 1)),
                  child: Row(children: [
                    Expanded(child: Text(r, style: TextStyle(fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? activeColor : const Color(0xFF0C4A6E)))),
                    if (isSelected) Icon(Icons.check_circle_rounded, color: activeColor, size: 16),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  void _lbShowLevelPicker() async {
    final activeColor = _lbActiveColor();
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: activeColor.withOpacity(0.3))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
              decoration: BoxDecoration(color: activeColor.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
              child: Row(children: [
                Icon(Icons.layers_rounded, color: activeColor, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(_lang == 'ID' ? 'Pilih Level' : 'Select Level',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: activeColor))),
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
              ]),
            ),
            ..._lbTranslatedLocationLevels.map((lvl) {
              final isSelected = _lbSelectedLocationLevel == lvl;
              return InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _lbSelectedLocationLevel = lvl);
                  _lbFetchAllData(fromTabFilter: true);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? activeColor.withOpacity(0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? activeColor : Colors.grey.shade200, width: isSelected ? 1.5 : 1)),
                  child: Row(children: [
                    Expanded(child: Text(lvl, style: TextStyle(fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? activeColor : const Color(0xFF0C4A6E)))),
                    if (isSelected) Icon(Icons.check_circle_rounded, color: activeColor, size: 16),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  // ── MAIN BUILD — Leaderboard Section ─────────────────────────────────────────

  Widget _buildAdminLeaderboard() {
    const findingTypes = [
      {'key': '5R', 'label': '5R Finding', 'icon': Icons.search_rounded},
      {'key': 'KTS Production', 'label': 'KTS Production', 'icon': Icons.precision_manufacturing_rounded},
      {'key': 'Accident', 'label': 'Accident Report', 'icon': Icons.warning_amber_rounded},
    ];
    const activeColors = {
      '5R': Color(0xFF059669),
      'KTS Production': Color(0xFFF59E0B),
      'Accident': Color(0xFFEF4444),
    };
    const borderColors = {
      '5R': Color(0xFF6EE7B7),
      'KTS Production': Color(0xFFFCD34D),
      'Accident': Color(0xFFFCA5A5),
    };

    final activeColor = _lbActiveColor();
    final List<String> tabLabels;
    if (_lbFindingType == 'KTS Production') {
      tabLabels = [_lang == 'ID' ? 'Anggota' : 'Members', _lang == 'ID' ? 'Temuan Berulang' : 'Recurring'];
    } else if (_lbFindingType == 'Accident') {
      tabLabels = [
        _lang == 'ID' ? 'Anggota' : 'Members',
        _lang == 'ID' ? 'Lokasi' : 'Location',
        _lang == 'ID' ? 'Berulang' : 'Recurring',
      ];
    } else {
      tabLabels = [
        _lang == 'ID' ? 'Anggota' : 'Members',
        _lang == 'ID' ? 'Inspeksi' : 'Inspection',
        _lang == 'ID' ? 'Lokasi' : 'Location',
        _lang == 'ID' ? 'Temuan Berulang' : 'Recurring',
      ];
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Finding Type Selector ──
      Row(
        children: findingTypes.map((t) {
          final key = t['key'] as String;
          final isSelected = _lbFindingType == key;
          final aColor = activeColors[key]!;
          final bColor = isSelected ? aColor : borderColors[key]!;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: key != 'Accident' ? 6 : 0),
              child: GestureDetector(
                onTap: () {
                  if (_lbFindingType != key) {
                    setState(() {
                      _lbFindingType = key;
                      _lbIsChartExpanded = false;
                      _lbActiveTabIndex = 0;
                      _lbRecurringFuture = null;
                      _lbAccidentRecurringFuture = null;
                    });
                    _lbFetchAllData();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected ? aColor : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: bColor, width: 1.5),
                    boxShadow: isSelected ? [BoxShadow(
                      color: aColor.withOpacity(0.28), blurRadius: 8, offset: const Offset(0, 3))] : [],
                  ),
                  child: Center(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(t['icon'] as IconData, size: 12,
                          color: isSelected ? Colors.white : aColor),
                      const SizedBox(width: 4),
                      Flexible(child: Text(t['label'] as String,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : aColor),
                        maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
                    ]),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 10),

      // ── Tab Bar ──
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.all(3),
        child: TabBar(
          controller: _lbTabController,
          isScrollable: tabLabels.length > 4,
          tabAlignment: tabLabels.length > 4 ? TabAlignment.center : TabAlignment.fill,
          indicator: BoxDecoration(color: activeColor, borderRadius: BorderRadius.circular(8)),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: activeColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          dividerColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: tabLabels.map((t) => Tab(child: Text(t))).toList(),
        ),
      ),
      const SizedBox(height: 8),

      // ── Conditional Chart ──
      _lbBuildCollapsibleChart(),
      const SizedBox(height: 8),

      // ── Tab Content ──
      SizedBox(
        height: 420,
        child: TabBarView(
          controller: _lbTabController,
          children: _lbFindingType == 'KTS Production'
              ? [_lbBuildAnggotaTabContent(), _lbBuildRecurringTabContent()]
              : _lbFindingType == 'Accident'
                  ? [_lbBuildAnggotaTabContent(), _lbBuildLokasiTabContent(), _lbBuildRecurringTabContent()]
                  : [_lbBuildAnggotaTabContent(), _lbBuildInspeksiTabContent(),
                    _lbBuildLokasiTabContent(), _lbBuildRecurringTabContent()],
        ),
      ),
    ]);
  }

  Widget _lbBuildAnggotaTabContent() {
    final activeColor = _lbActiveColor();
    final locale = _lang == 'ID' ? 'id_ID' : (_lang == 'EN' ? 'en_US' : 'zh_CN');
    final monthLabel = _lbTranslatedMonths[_lbSelectedMonthIndex];
    return Column(children: [
      // Filter row
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          _lbBuildFilterButton(
            label: _lbFilterMode == 'daily' && _lbSelectedDate != null
                ? DateFormat('d MMM yyyy', _lang == 'ID' ? 'id_ID' : 'en_US').format(_lbSelectedDate!)
                : monthLabel,
            isActive: true, activeColor: activeColor,
            onTap: _lbShowMonthPicker),
          const SizedBox(width: 8),
          Expanded(child: _lbBuildFilterButton(
            label: _lbSelectedUnitId == null
                ? (_lang == 'ID' ? 'Semua Grup' : 'All Groups')
                : (_lbUnitList.firstWhere((u) => u['id_unit']?.toString() == _lbSelectedUnitId,
                    orElse: () => {'nama_unit': 'Grup'})['nama_unit'] as String),
            activeColor: activeColor, onTap: _lbShowGroupPicker)),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(_lbLastUpdatedText,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
      ),
      _lbBuildTableHeader(),
      _lbBuildTargetRow(),
      Expanded(child: Builder(builder: (context) {
        final future = _lbFindingType == 'KTS Production' ? _lbKtsAnggotaFuture
            : _lbFindingType == 'Accident' ? _lbAccidentAnggotaFuture
            : _lbAnggotaFuture;
        if (future == null) return _lbBuildTableShimmer();
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) return _lbBuildTableShimmer();
            final data = snap.data ?? [];
            if (data.isEmpty) return Center(child: Text(
              _lang == 'ID' ? 'Tidak ada data anggota.' : 'No member data.',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)));
            return ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: data.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE0F2FE)),
              itemBuilder: (_, i) => _lbBuildMemberRow(data[i], i + 1),
            );
          },
        );
      })),
    ]);
  }

  Widget _lbBuildInspeksiTabContent() {
    final activeColor = _lbActiveColor();
    final Map<String, Color> roleColors = {
      'Eksekutif': const Color(0xFFEF4444), 'Executive': const Color(0xFFEF4444), '行政': const Color(0xFFEF4444),
      'Profesional': const Color(0xFFF59E0B), 'Professional': const Color(0xFFF59E0B), '专业': const Color(0xFFF59E0B),
      'Visitor': const Color(0xFF3B82F6), '访客': const Color(0xFF3B82F6),
    };
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          _lbBuildFilterButton(
            label: _lbFilterMode == 'daily' && _lbSelectedDate != null
                ? DateFormat('d MMM yyyy', _lang == 'ID' ? 'id_ID' : 'en_US').format(_lbSelectedDate!)
                : _lbTranslatedMonths[_lbSelectedMonthIndex],
            isActive: true, activeColor: activeColor, onTap: _lbShowMonthPicker),
          const SizedBox(width: 8),
          Expanded(child: Row(
            children: _lbTranslatedRoles.map((r) {
              final isSelected = _lbSelectedInspectionRole == r;
              final rColor = roleColors[r] ?? activeColor;
              return Expanded(child: Padding(
                padding: EdgeInsets.only(right: r != _lbTranslatedRoles.last ? 6 : 0),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _lbSelectedInspectionRole = r);
                    _lbFetchAllData(fromTabFilter: true);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected ? rColor : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? rColor : Colors.grey.shade300, width: 1.2),
                      boxShadow: isSelected ? [BoxShadow(color: rColor.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))] : [],
                    ),
                    child: Center(child: Text(r,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : const Color(0xFF64748B)),
                      textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ),
                ),
              ));
            }).toList(),
          )),
        ]),
      ),
      _lbBuildTableHeader(),
      _lbBuildTargetRow(),
      Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _lbInspeksiFuture,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return _lbBuildTableShimmer();
          final data = snap.data ?? [];
          if (data.isEmpty) return Center(child: Text(
            _lang == 'ID' ? 'Tidak ada data.' : 'No data.',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)));
          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE0F2FE)),
            itemBuilder: (_, i) {
              final item = data[i];
              final findings = item['findings'] as int? ?? 0;
              final target = _lbTargetInspeksi;
              final fColor = findings >= target ? const Color(0xFF16A34A) : const Color(0xFF0C4A6E);
              return Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(children: [
                  SizedBox(width: 28, child: Center(child: i < 3
                    ? Text(['🥇','🥈','🥉'][i], style: const TextStyle(fontSize: 16))
                    : Text('${i+1}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)))),
                  const SizedBox(width: 6),
                  Expanded(flex: 3, child: Text(item['nama'] as String? ?? '-',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0C4A6E)),
                    overflow: TextOverflow.ellipsis)),
                  SizedBox(width: 60, child: Text('$findings', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fColor))),
                  const SizedBox(width: 60),
                ]),
              );
            },
          );
        },
      )),
    ]);
  }

  Widget _lbBuildLokasiTabContent() {
    final activeColor = _lbActiveColor();
    final bool use5RAudit = _lbFindingType == '5R'
        && !(_lbFilterMode == 'daily' && _lbSelectedDate != null);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          _lbBuildFilterButton(
            label: _lbFilterMode == 'daily' && _lbSelectedDate != null
                ? DateFormat('d MMM yyyy', _lang == 'ID' ? 'id_ID' : 'en_US').format(_lbSelectedDate!)
                : _lbTranslatedMonths[_lbSelectedMonthIndex],
            isActive: true, activeColor: activeColor, onTap: _lbShowMonthPicker),
          const SizedBox(width: 8),
          Expanded(child: _lbBuildFilterButton(
            label: _lbSelectedLocationLevel, activeColor: activeColor, onTap: _lbShowLevelPicker)),
        ]),
      ),
      // Header tabel
      Container(
        color: activeColor.withOpacity(0.08),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          SizedBox(width: 28, child: Text(_lang == 'ID' ? 'Rank' : 'Rank',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: activeColor))),
          const SizedBox(width: 6),
          Expanded(flex: 3, child: Text(_lang == 'ID' ? 'Lokasi' : 'Location',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: activeColor))),
          SizedBox(width: 60, child: Text(
            use5RAudit ? (_lang == 'ID' ? 'Nilai' : 'Score')
                : (_lang == 'ID' ? 'Jumlah' : 'Count'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: activeColor))),
        ]),
      ),
      Expanded(child: Builder(builder: (context) {
        if (use5RAudit) {
          if (_lbAuditLokasiFuture == null) return _lbBuildTableShimmer();
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _lbAuditLokasiFuture,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) return _lbBuildTableShimmer();
              final data = snap.data ?? [];
              if (data.isEmpty) return Center(child: Text(
                _lang == 'ID' ? 'Tidak ada data lokasi.' : 'No location data.',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)));
              return ListView.separated(
                padding: EdgeInsets.zero, itemCount: data.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE0F2FE)),
                itemBuilder: (_, i) => _lbBuildAuditLokasiRow(data[i], i + 1, activeColor),
              );
            },
          );
        }
        // Temuan count
        final future = _lbFindingType == 'Accident' ? _lbAccidentLokasiFuture : _lbLokasiFuture;
        if (future == null) return _lbBuildTableShimmer();
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) return _lbBuildTableShimmer();
            final data = snap.data ?? [];
            if (data.isEmpty) return Center(child: Text(
              _lang == 'ID' ? 'Tidak ada data lokasi.' : 'No location data.',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)));
            return ListView.separated(
              padding: EdgeInsets.zero, itemCount: data.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE0F2FE)),
              itemBuilder: (_, i) => _lbBuildLokasiRow(data[i], i + 1),
            );
          },
        );
      })),
    ]);
  }

  Widget _lbBuildRecurringTabContent() {
    final activeColor = _lbActiveColor();
    final locale = _lang == 'ID' ? 'id_ID' : (_lang == 'EN' ? 'en_US' : 'zh_CN');
    final fromLabel = DateFormat('MMM yyyy', locale).format(_lbRecurringFrom);
    final toLabel = DateFormat('MMM yyyy', locale).format(_lbRecurringTo);
    final periodLabel = '$fromLabel - $toLabel';
    final topicLabel = _lang == 'ID' ? 'Topik Berulang' : _lang == 'ZH' ? '重复话题' : 'Recurring Topics';

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Expanded(child: _lbBuildFilterButton(
            label: periodLabel, activeColor: activeColor,
            icon: Icons.calendar_month_rounded, onTap: _lbShowPeriodPicker)),
          const SizedBox(width: 8),
          Expanded(child: _lbBuildFilterButton(
            label: _lbRecurringUserName.isEmpty
                ? (_lang == 'ID' ? 'Semua Penemu' : 'All Finders')
                : _lbRecurringUserName,
            activeColor: activeColor, onTap: _lbShowUserPicker)),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Align(alignment: Alignment.centerLeft,
          child: Text(topicLabel, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: activeColor))),
      ),
      const Divider(height: 1, color: Color(0xFFE0F2FE)),
      Expanded(child: Builder(builder: (context) {
        final future = _lbFindingType == 'Accident' ? _lbAccidentRecurringFuture : _lbRecurringFuture;
        if (future == null) {
          return _lbBuildTableShimmer();
        }
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) return _lbBuildTableShimmer();
            final data = snap.data ?? [];
            if (data.isEmpty) return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 56, height: 56,
                  decoration: BoxDecoration(color: activeColor.withOpacity(0.08), shape: BoxShape.circle),
                  child: Icon(Icons.search_off_rounded, size: 28, color: activeColor.withOpacity(0.5))),
                const SizedBox(height: 12),
                Text(_lang == 'ID' ? 'Belum ada temuan berulang.' : 'No recurring findings.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ));
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: data.length,
              itemBuilder: (_, i) => _lbBuildRecurringCard(data[i]),
            );
          },
        );
      })),
    ]);
  }

  void _lbShowPeriodPicker() async {
    DateTime tempFrom = _lbRecurringFrom;
    DateTime tempTo = _lbRecurringTo;
    final locale = _lang == 'ID' ? 'id_ID' : (_lang == 'EN' ? 'en_US' : 'zh_CN');
    final activeColor = _lbActiveColor();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: activeColor.withOpacity(0.3))),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.date_range_rounded, color: activeColor, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(_lang == 'ID' ? 'Pilih Periode' : 'Select Period',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: activeColor))),
              IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
            ]),
            const SizedBox(height: 14),
            Text(_lang == 'ID' ? 'Dari' : 'From',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _lbYearMonthPicker(tempFrom, locale, (d) => setSt(() => tempFrom = d)),
            const SizedBox(height: 12),
            Text(_lang == 'ID' ? 'Sampai' : 'To',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _lbYearMonthPicker(tempTo, locale, (d) => setSt(() => tempTo = d)),
            const SizedBox(height: 18),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () {
                setState(() { _lbRecurringFrom = tempFrom; _lbRecurringTo = tempTo; });
                Navigator.pop(ctx);
                _lbFetchAllData(fromTabFilter: true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: activeColor,
                foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(_lang == 'ID' ? 'Terapkan' : 'Apply'),
            )),
          ]),
        ),
      )),
    );
  }

  Widget _lbYearMonthPicker(DateTime current, String locale, ValueChanged<DateTime> onChange) {
    final months = List.generate(12, (i) => DateFormat.MMM(locale).format(DateTime(2000, i + 1)));
    final years = List.generate(5, (i) => DateTime.now().year - 2 + i);
    return Row(children: [
      Expanded(flex: 3, child: Container(
        height: 40, padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBAE6FD))),
        child: DropdownButtonHideUnderline(child: DropdownButton<int>(
          value: current.month - 1,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF0EA5E9)),
          style: const TextStyle(fontSize: 13, color: Color(0xFF0C4A6E), fontWeight: FontWeight.w600),
          dropdownColor: Colors.white,
          items: List.generate(12, (i) => DropdownMenuItem(value: i, child: Text(months[i]))),
          onChanged: (v) { if (v != null) onChange(DateTime(current.year, v + 1)); },
        )),
      )),
      const SizedBox(width: 8),
      Expanded(flex: 2, child: Container(
        height: 40, padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBAE6FD))),
        child: DropdownButtonHideUnderline(child: DropdownButton<int>(
          value: current.year,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF0EA5E9)),
          style: const TextStyle(fontSize: 13, color: Color(0xFF0C4A6E), fontWeight: FontWeight.w600),
          dropdownColor: Colors.white,
          items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
          onChanged: (v) { if (v != null) onChange(DateTime(v, current.month)); },
        )),
      )),
    ]);
  }

  void _lbShowUserPicker() async {
    try {
      final response = await Supabase.instance.client.from('User')
          .select('id_user, nama, gambar_user').order('nama');
      final users = List<Map<String, dynamic>>.from(response);
      final allItem = {'id_user': null, 'nama': _lang == 'ID' ? 'Semua Penemu' : 'All Finders', 'gambar_user': null};
      final items = [allItem, ...users];
      if (!mounted) return;
      final activeColor = _lbActiveColor();

      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
          List<Map<String, dynamic>> filtered = List.from(items);
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: activeColor.withOpacity(0.3), width: 1.5)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                  decoration: BoxDecoration(color: activeColor.withOpacity(0.08),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                  child: Row(children: [
                    Icon(Icons.person_search_rounded, color: activeColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_lang == 'ID' ? 'Pilih Penemu' : 'Select Finder',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: activeColor))),
                    IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: StatefulBuilder(builder: (_, setInner) => TextField(
                    onChanged: (q) => setInner(() {
                      filtered = items.where((e) =>
                          (e['nama'] as String).toLowerCase().contains(q.toLowerCase())).toList();
                      setSt(() {});
                    }),
                    decoration: InputDecoration(
                      hintText: _lang == 'ID' ? 'Cari...' : 'Search...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: Icon(Icons.search, color: activeColor, size: 18),
                      filled: true, fillColor: const Color(0xFFF0F9FF),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFFBAE6FD))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFFBAE6FD))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: activeColor, width: 1.5)),
                    ),
                  )),
                ),
                Flexible(child: StatefulBuilder(builder: (_, __) => ListView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    final name = item['nama'] as String;
                    final id = item['id_user']?.toString();
                    final avatarUrl = item['gambar_user'] as String?;
                    final isSelected = id == _lbRecurringUserId || (id == null && _lbRecurringUserId == null);
                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _lbRecurringUserId = id;
                          _lbRecurringUserName = id == null
                              ? (_lang == 'ID' ? 'Semua Penemu' : 'All Finders') : name;
                        });
                        _lbFetchAllData(fromTabFilter: true);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? activeColor.withOpacity(0.08) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? activeColor : Colors.grey.shade200,
                            width: isSelected ? 1.5 : 1)),
                        child: Row(children: [
                          id == null
                            ? Container(width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: isSelected ? activeColor : activeColor.withOpacity(0.1),
                                  shape: BoxShape.circle),
                                child: Icon(Icons.group_rounded,
                                  color: isSelected ? Colors.white : activeColor, size: 18))
                            : CircleAvatar(radius: 18,
                                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                    ? NetworkImage(avatarUrl) : null,
                                backgroundColor: activeColor.withOpacity(0.12),
                                child: (avatarUrl == null || avatarUrl.isEmpty)
                                    ? Text(name[0].toUpperCase(),
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: activeColor))
                                    : null),
                          const SizedBox(width: 10),
                          Expanded(child: Text(
                            id == null ? (_lang == 'ID' ? 'Semua Penemu' : 'All Finders') : name,
                            style: TextStyle(fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? activeColor : const Color(0xFF0C4A6E)))),
                          if (isSelected) Icon(Icons.check_circle_rounded, color: activeColor, size: 16),
                        ]),
                      ),
                    );
                  },
                ))),
              ]),
            ),
          );
        }),
      );
    } catch (e) { debugPrint('Error fetching lb users: $e'); }
  }
}

// ── Animated Admin Badge (border stroke animasi seperti Google) ──
class _AnimatedAdminBadge extends StatefulWidget {
  final String lang;
  final String jabatan;
  const _AnimatedAdminBadge({required this.lang, required this.jabatan});

  @override
  State<_AnimatedAdminBadge> createState() => _AnimatedAdminBadgeState();
}

class _AnimatedAdminBadgeState extends State<_AnimatedAdminBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = _ctrl.value < 0.5
            ? _ctrl.value * 2
            : (1 - _ctrl.value) * 2;
        final borderColor = Color.lerp(
          const Color(0xFF34D399),
          const Color(0xFF38BDF8),
          t,
        )!;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            // Latar gelap semi-transparan agar teks terbaca di atas gambar
            color: Colors.black.withOpacity(0.38),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: borderColor.withOpacity(0.35),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded,
              color: Color(0xFF34D399), size: 12),
          const SizedBox(width: 5),
          Text(
            widget.jabatan,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Digital Clock Widget real-time (Analog + Digital) ──
class _DigitalClockWidget extends StatefulWidget {
  final String lang;
  const _DigitalClockWidget({required this.lang});

  @override
  State<_DigitalClockWidget> createState() => _DigitalClockWidgetState();
}

class _DigitalClockWidgetState extends State<_DigitalClockWidget> {
  late DateTime _now;
  late Timer _timer;

  static const _days   = ['SUN','MON','TUE','WED','THU','FRI','SAT'];
  static const _months = ['JAN','FEB','MAR','APR','MAY','JUN',
                           'JUL','AUG','SEP','OCT','NOV','DEC'];

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1),
        (_) { if (mounted) setState(() => _now = DateTime.now()); });
  }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  String _pad(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final h    = _pad(_now.hour);
    final m    = _pad(_now.minute);
    final s    = _pad(_now.second);
    final year = _now.year.toString();

    // ── Nama hari & bulan sesuai bahasa ──
    final String dayStr;
    final String monStr;

    if (widget.lang == 'ID') {
      const daysID  = ['Min','Sen','Sel','Rab','Kam','Jum','Sab'];
      const monsID  = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agt','Sep','Okt','Nov','Des'];
      dayStr = daysID[_now.weekday % 7];
      monStr = monsID[_now.month - 1];
    } else if (widget.lang == 'ZH') {
      const daysZH  = ['日','一','二','三','四','五','六'];
      const monsZH  = ['1月','2月','3月','4月','5月','6月','7月','8月','9月','10月','11月','12月'];
      dayStr = '周${daysZH[_now.weekday % 7]}';
      monStr = monsZH[_now.month - 1];
    } else {
      const daysEN  = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
      const monsEN  = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      dayStr = daysEN[_now.weekday % 7];
      monStr = monsEN[_now.month - 1];
    }

    final date = _pad(_now.day);

    // Format keterangan waktu sesuai bahasa
    final String dateLabel;
    if (widget.lang == 'ID') {
      dateLabel = '$dayStr, $date $monStr $year';
    } else if (widget.lang == 'ZH') {
      dateLabel = '$year年$monStr$date日 $dayStr';
    } else {
      dateLabel = '$dayStr, $date $monStr $year';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Kiri: Jam Analog ──
          SizedBox(
            width: 54,
            height: 54,
            child: CustomPaint(
              painter: _AnalogClockPainter(now: _now),
            ),
          ),
          const SizedBox(width: 10),
          // ── Kanan: Digital + tanggal di bawah ──
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HH:MM besar + :SS lebih besar & jelas
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$h:$m',
                    style: GoogleFonts.sourceCodePro(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  // Separator titik dua
                  Text(
                    ':',
                    style: GoogleFonts.sourceCodePro(
                      color: Colors.white.withOpacity(0.70),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // Detik — ukuran lebih besar & warna hijau terang
                  Text(
                    s,
                    style: GoogleFonts.sourceCodePro(
                      color: const Color(0xFF6EE7B7), // hijau lebih terang
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF059669).withOpacity(0.8),
                          blurRadius: 8,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              // Keterangan waktu sesuai bahasa
              Text(
                dateLabel,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Analog Clock Painter ──
class _AnalogClockPainter extends CustomPainter {
  final DateTime now;
  const _AnalogClockPainter({required this.now});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2 - 2;
    final center = Offset(cx, cy);
    const pi2 = 6.283185307;

    // ── Background lingkaran ──
    canvas.drawCircle(
      center, r,
      Paint()..color = Colors.white.withOpacity(0.10),
    );

    // ── Ring luar ──
    canvas.drawCircle(
      center, r,
      Paint()
        ..color = Colors.white.withOpacity(0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // ── Tick marks (12 jam) ──
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * pi2 - pi2 / 4;
      final isMajor = i % 3 == 0;
      final outer = r - 1;
      final inner = isMajor ? r - 6 : r - 4;
      canvas.drawLine(
        Offset(cx + inner * cos(angle), cy + inner * sin(angle)),
        Offset(cx + outer * cos(angle), cy + outer * sin(angle)),
        Paint()
          ..color = isMajor
              ? Colors.white.withOpacity(0.90)
              : Colors.white.withOpacity(0.45)
          ..strokeWidth = isMajor ? 1.8 : 1.0
          ..strokeCap = StrokeCap.round,
      );
    }

    // ── Jarum jam (hour) ──
    final hourAngle =
        ((now.hour % 12) + now.minute / 60) / 12 * pi2 - pi2 / 4;
    canvas.drawLine(
      center,
      Offset(cx + (r * 0.45) * cos(hourAngle),
             cy + (r * 0.45) * sin(hourAngle)),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // ── Jarum menit (minute) ──
    final minAngle =
        (now.minute + now.second / 60) / 60 * pi2 - pi2 / 4;
    canvas.drawLine(
      center,
      Offset(cx + (r * 0.65) * cos(minAngle),
             cy + (r * 0.65) * sin(minAngle)),
      Paint()
        ..color = Colors.white.withOpacity(0.90)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );

    // ── Jarum detik (second) — hijau cerah ──
    final secAngle = now.second / 60 * pi2 - pi2 / 4;
    // ekor kecil ke belakang
    canvas.drawLine(
      Offset(cx - (r * 0.15) * cos(secAngle),
             cy - (r * 0.15) * sin(secAngle)),
      Offset(cx + (r * 0.80) * cos(secAngle),
             cy + (r * 0.80) * sin(secAngle)),
      Paint()
        ..color = const Color(0xFF34D399)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    // ── Titik tengah ──
    canvas.drawCircle(center, 3,
        Paint()..color = const Color(0xFF34D399));
    canvas.drawCircle(center, 1.5,
        Paint()..color = Colors.white);
  }

  double cos(double a) => math.cos(a);
  double sin(double a) => math.sin(a);

  @override
  bool shouldRepaint(covariant _AnalogClockPainter old) =>
      old.now.second != now.second;
}

// ─── Data models ───
class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
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

// ── Data model untuk stats dalam banner ──
class _BannerStat {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color iconBg;

  const _BannerStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.iconBg,
  });
}

class LocationFilter {
  final String? id;
  final String displayName;
  const LocationFilter({this.id, required this.displayName});
}

class _LbPieChartPainter extends CustomPainter {
  final double primaryValue;
  final double secondaryValue;
  final Color colorPrimary;
  final Color colorSecondary;

  _LbPieChartPainter({required this.primaryValue, required this.secondaryValue,
    required this.colorPrimary, required this.colorSecondary});

  @override
  void paint(Canvas canvas, Size size) {
    final total = primaryValue + secondaryValue;
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2;
    final innerR = outerR * 0.55;
    const colorEmpty = Color(0xFFE2E8F0);

    if (total == 0) {
      canvas.drawCircle(center, (outerR + innerR) / 2,
        Paint()..color = colorEmpty..style = PaintingStyle.stroke..strokeWidth = outerR - innerR);
      return;
    }

    double startAngle = -1.5707963;
    const double gap = 0.04;
    final segs = [
      {'v': primaryValue,   'c': colorPrimary},
      {'v': secondaryValue, 'c': colorSecondary},
    ];
    for (final seg in segs) {
      final v = seg['v'] as double;
      final c = seg['c'] as Color;
      if (v <= 0) continue;
      final sweep = (v / total) * 6.2831853 - gap;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: (outerR + innerR) / 2),
        startAngle, sweep, false,
        Paint()..color = c..style = PaintingStyle.stroke..strokeWidth = outerR - innerR..strokeCap = StrokeCap.butt,
      );
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class _LbDashedLine extends CustomPainter {
  final Color color;
  _LbDashedLine(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 5, 0), paint);
      x += 8;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _LbChartBarData {
  final int date;
  final int temuan;
  final int penyelesaian;
  _LbChartBarData({required this.date, required this.temuan, required this.penyelesaian});
}