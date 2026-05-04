import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:intl/intl.dart';

// ─── Import screen admin lainnya ───
import '../user/leaderboard/leaderboard_detail_screen.dart';
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

  const AdminHomeScreen({
    super.key,
    this.initialUserName,
    this.initialUserImage,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  String _lang = 'ID';
  String _adminName = 'Admin';
  String? _adminImage;
  bool _isLoadingStats = true;

  // Stats
  int _totalUsers = 0;
  int _totalLokasi = 0;
  int _totalKategori = 0;
  int _totalTemuan = 0;
  int _temuanBelum = 0;
  int _temuanSelesai = 0;

  // ── Leaderboard State ──
  Future<List<LeaderboardMember>>? _leaderboardFuture;
  Future<List<DailyChartData>>?    _chartFuture;
  Future<ChartTarget>?             _chartTargetFuture;
  Future<DailyChartData>?          _dailyPieFuture;
  FilterType _lbFilterType = FilterType.monthly;
  DateTime   _lbDate       = DateTime.now();
  LocationFilter _lbLocation = const LocationFilter(displayName: 'Semua Lokasi');

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

    if (widget.initialUserName != null) {
      _adminName = widget.initialUserName!;
    }
    _adminImage = widget.initialUserImage;

    _loadLanguage().then((_) {
      _fetchStats();
      _fetchLeaderboardData(); // ← tambahkan
      _animCtrl.forward();
    });

    _loadAdminInfo();
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
        // Update display name lokasi leaderboard sesuai bahasa
        _lbLocation = LocationFilter(
          displayName: leaderboardTexts[_lang]?['all_locations'] ??
              leaderboardTexts['ID']!['all_locations']!,
        );
      });
    }
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoadingStats = true);
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
                    const Color(0xFF6366F1).withOpacity(0.12),
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
                    const Color(0xFF8B5CF6).withOpacity(0.08),
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
                      onRefresh: _fetchStats,
                      color: const Color(0xFF6366F1),
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
                                  ? 'Finding Overview'
                                  : _lang == 'ZH'
                                      ? '发现概览'
                                      : 'Ringkasan Temuan',
                            ),
                            const SizedBox(height: 14),
                            _buildTemuanOverview(),
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
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
              color: const Color(0xFF1E3A8A),
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
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
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
                        _fetchLeaderboardData();
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6366F1).withOpacity(0.08)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6366F1)
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
                                    ? const Color(0xFF6366F1)
                                    : const Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF6366F1), size: 20),
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
          color: const Color(0xFF6366F1).withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFF6366F1).withOpacity(0.25)),
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
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 14, color: Color(0xFF6366F1)),
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
          .select('nama, gambar_user')
          .eq('id_user', userId)
          .maybeSingle();
      if (row != null && mounted) {
        setState(() {
          _adminName = row['nama'] ?? _adminName;
          _adminImage = row['gambar_user'] ?? _adminImage;
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

  void _fetchLeaderboardData() {
    final now = DateTime.now();
    setState(() {
      if (_lbFilterType == FilterType.monthly) {
        _dailyPieFuture = null;
        _chartTargetFuture = Supabase.instance.client
            .rpc('get_chart_target', params: {
          'selected_month': _lbDate.month,
          'selected_year': _lbDate.year,
          'selected_unit_id': _lbLocation.idUnit,
        }).then((response) {
          final List<dynamic> data = response;
          if (data.isEmpty) {
            return const ChartTarget(
                targetTemuan: 5, targetPenyelesaian: 4);
          }
          return ChartTarget(
            targetTemuan: data[0]['target_temuan'] as int,
            targetPenyelesaian: data[0]['target_penyelesaian'] as int,
          );
        }).catchError((_) =>
            const ChartTarget(targetTemuan: 5, targetPenyelesaian: 4));

        _chartFuture = Supabase.instance.client
            .rpc('get_daily_chart_data', params: {
          'selected_month': _lbDate.month,
          'selected_year': _lbDate.year,
          'selected_unit_id': _lbLocation.idUnit,
          'selected_lokasi_id': _lbLocation.idLokasi,
          'selected_subunit_id': _lbLocation.idSubunit,
          'selected_area_id': _lbLocation.idArea,
        }).then((response) {
          final List<dynamic> data = response;
          return data
              .map((item) => DailyChartData(
                    date: item['tanggal'] as int,
                    temuan: item['temuan'] as int,
                    penyelesaian: item['penyelesaian'] as int,
                  ))
              .toList();
        });

        _leaderboardFuture = _fetchMonthlyLeaderboard();
      } else {
        _chartTargetFuture = null;
        _chartFuture = null;

        _dailyPieFuture = Supabase.instance.client
            .rpc('get_daily_chart_data', params: {
          'selected_month': _lbDate.month,
          'selected_year': _lbDate.year,
          'selected_unit_id': _lbLocation.idUnit,
          'selected_lokasi_id': _lbLocation.idLokasi,
          'selected_subunit_id': _lbLocation.idSubunit,
          'selected_area_id': _lbLocation.idArea,
        }).then((response) {
          final List<dynamic> data = response;
          final selectedDay = _lbDate.day;
          final found = data.firstWhere(
            (item) => (item['tanggal'] as int) == selectedDay,
            orElse: () => {
              'tanggal': selectedDay,
              'temuan': 0,
              'penyelesaian': 0
            },
          );
          return DailyChartData(
            date: found['tanggal'] as int,
            temuan: found['temuan'] as int,
            penyelesaian: found['penyelesaian'] as int,
          );
        });

        _leaderboardFuture = _fetchDailyLeaderboard();
      }
    });
  }

  Future<List<LeaderboardMember>> _fetchMonthlyLeaderboard() async {
    try {
      final startOfMonth =
          DateTime(_lbDate.year, _lbDate.month, 1).toIso8601String();
      final endOfMonth =
          DateTime(_lbDate.year, _lbDate.month + 1, 1).toIso8601String();

      final List<dynamic> logData = await Supabase.instance.client
          .from('log_poin')
          .select('id_user, poin')
          .gte('created_at', startOfMonth)
          .lt('created_at', endOfMonth);

      final Map<String, int> monthlyMap = {};
      for (final log in logData) {
        final uid = log['id_user']?.toString() ?? '';
        if (uid.isEmpty) continue;
        final p = (log['poin'] as num?)?.toInt() ?? 0;
        monthlyMap[uid] = (monthlyMap[uid] ?? 0) + p;
      }
      if (monthlyMap.isEmpty) return [];

      var userQuery = Supabase.instance.client
          .from('User')
          .select('id_user, nama, gambar_user')
          .inFilter('id_user', monthlyMap.keys.toList())
          .or('is_visitor.is.null,is_visitor.eq.false');

      if (_lbLocation.idArea != null) {
        userQuery = userQuery.eq('id_area', _lbLocation.idArea!);
      } else if (_lbLocation.idSubunit != null) {
        userQuery = userQuery.eq('id_subunit', _lbLocation.idSubunit!);
      } else if (_lbLocation.idUnit != null) {
        userQuery = userQuery.eq('id_unit', _lbLocation.idUnit!);
      } else if (_lbLocation.idLokasi != null) {
        userQuery = userQuery.eq('id_lokasi', _lbLocation.idLokasi!);
      }

      final List<dynamic> userData = await userQuery;
      final List<Map<String, dynamic>> combined = [];
      for (final user in userData) {
        final uid = user['id_user']?.toString() ?? '';
        combined.add({
          'uid': uid,
          'nama': user['nama'] as String,
          'gambar_user': user['gambar_user'] as String?,
          'poin': monthlyMap[uid] ?? 0,
        });
      }
      combined.sort(
          (a, b) => (b['poin'] as int).compareTo(a['poin'] as int));
      return combined.asMap().entries.map((e) {
        final item = e.value;
        return LeaderboardMember(
          idUser: item['uid'] as String,
          rank: e.key + 1,
          name: item['nama'] as String,
          avatarUrl: item['gambar_user'] as String?,
          score: item['poin'] as int,
          monthlyPoints: item['poin'] as int,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error monthly leaderboard: $e');
      return [];
    }
  }

  Future<List<LeaderboardMember>> _fetchDailyLeaderboard() async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_lbDate);
      final startOfDay = '${dateStr}T00:00:00.000Z';
      final endOfDay = '${dateStr}T23:59:59.999Z';

      final List<dynamic> logData = await Supabase.instance.client
          .from('log_poin')
          .select('id_user, poin')
          .gte('created_at', startOfDay)
          .lte('created_at', endOfDay);

      final Map<String, int> dailyMap = {};
      for (final log in logData) {
        final uid = log['id_user']?.toString() ?? '';
        if (uid.isEmpty) continue;
        final p = (log['poin'] as num?)?.toInt() ?? 0;
        dailyMap[uid] = (dailyMap[uid] ?? 0) + p;
      }
      if (dailyMap.isEmpty) return [];

      var userQuery = Supabase.instance.client
          .from('User')
          .select('id_user, nama, gambar_user')
          .inFilter('id_user', dailyMap.keys.toList())
          .or('is_visitor.is.null,is_visitor.eq.false');

      if (_lbLocation.idArea != null) {
        userQuery = userQuery.eq('id_area', _lbLocation.idArea!);
      } else if (_lbLocation.idSubunit != null) {
        userQuery = userQuery.eq('id_subunit', _lbLocation.idSubunit!);
      } else if (_lbLocation.idUnit != null) {
        userQuery = userQuery.eq('id_unit', _lbLocation.idUnit!);
      } else if (_lbLocation.idLokasi != null) {
        userQuery = userQuery.eq('id_lokasi', _lbLocation.idLokasi!);
      }

      final List<dynamic> userData = await userQuery;
      final List<Map<String, dynamic>> combined = [];
      for (final user in userData) {
        final uid = user['id_user']?.toString() ?? '';
        final dp = dailyMap[uid] ?? 0;
        if (dp > 0) {
          combined.add({
            'uid': uid,
            'nama': user['nama'] as String,
            'gambar_user': user['gambar_user'] as String?,
            'poin': dp,
          });
        }
      }
      combined.sort(
          (a, b) => (b['poin'] as int).compareTo(a['poin'] as int));
      return combined.asMap().entries.map((e) {
        final item = e.value;
        return LeaderboardMember(
          idUser: item['uid'] as String,
          rank: e.key + 1,
          name: item['nama'] as String,
          avatarUrl: item['gambar_user'] as String?,
          score: item['poin'] as int,
          monthlyPoints: item['poin'] as int,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error daily leaderboard: $e');
      return [];
    }
  }

  Widget _buildWelcomeBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D6EE8), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D6EE8).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Dekorasi lingkaran latar
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: 60,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Baris atas: teks sambutan ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _lang == 'EN'
                                ? 'Welcome back,'
                                : _lang == 'ZH'
                                    ? '欢迎回来，'
                                    : 'Selamat datang kembali,',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _adminName,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.shield_rounded,
                                    color: Colors.white, size: 13),
                                const SizedBox(width: 5),
                                Text(
                                  _lang == 'EN'
                                      ? 'Super Admin'
                                      : _lang == 'ZH'
                                          ? '超级管理员'
                                          : 'Super Admin',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Ikon admin di pojok kanan
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.25)),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Divider ──
              Container(
                height: 1,
                color: Colors.white.withOpacity(0.15),
              ),

              // ── 4 Stats Card di bawah ──
              _isLoadingStats
                  ? _buildBannerStatsShimmer()
                  : _buildBannerStats(),

              const SizedBox(height: 4),
            ],
          ),
        ],
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
        label: _lang == 'EN'
            ? 'Users'
            : _lang == 'ZH'
                ? '用户'
                : 'Pengguna',
        value: _totalUsers,
        icon: Icons.people_rounded,
        color: const Color(0xFF3B82F6),
        iconBg: const Color(0xFFDEEFFB),
      ),
      _BannerStat(
        label: _lang == 'EN'
            ? 'Locations'
            : _lang == 'ZH'
                ? '位置'
                : 'Lokasi',
        value: _totalLokasi,
        icon: Icons.location_city_rounded,
        color: const Color(0xFF10B981),
        iconBg: const Color(0xFFD1FAE5),
      ),
      _BannerStat(
        label: _lang == 'EN'
            ? 'Categories'
            : _lang == 'ZH'
                ? '类别'
                : 'Kategori',
        value: _totalKategori,
        icon: Icons.category_rounded,
        color: const Color(0xFFF59E0B),
        iconBg: const Color(0xFFFEF3C7),
      ),
      _BannerStat(
        label: _lang == 'EN'
            ? 'Findings'
            : _lang == 'ZH'
                ? '发现'
                : 'Temuan',
        value: _totalTemuan,
        icon: Icons.assignment_rounded,
        color: const Color(0xFFEF4444),
        iconBg: const Color(0xFFFEE2E2),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Row(
        children: stats.map((s) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: s.iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(s.icon, color: s.color, size: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${s.value}',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1E3A8A),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.label,
                    style: GoogleFonts.poppins(
                      color: Colors.black54,
                      fontSize: 9,
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
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
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

  // ══════════════════════════════════════════════════════
  // LEADERBOARD SECTION WIDGET
  // ══════════════════════════════════════════════════════

  Widget _buildAdminLeaderboard() {
    return Column(
      children: [
        // ── Filter Monthly/Daily ──
        Row(
          children: [
            _lbTabButton(
              FilterType.monthly,
              Icons.calendar_month_rounded,
              _getTxt('monthly'),
            ),
            const SizedBox(width: 8),
            _lbTabButton(
              FilterType.daily,
              Icons.calendar_today_rounded,
              _getTxt('daily'),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Filter tanggal (daily saja) ──
        if (_lbFilterType == FilterType.daily) ...[
          GestureDetector(
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: _lbDate,
                firstDate: DateTime(now.year - 1),
                lastDate: now,
                builder: (c, child) => Theme(
                  data: ThemeData.light().copyWith(
                    colorScheme: const ColorScheme.light(
                        primary: Color(0xFF6366F1)),
                  ),
                  child: child!,
                ),
              );
              if (picked != null && picked != _lbDate) {
                setState(() => _lbDate = picked);
                _fetchLeaderboardData();
              }
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 14, color: Color(0xFF6366F1)),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('d MMM yyyy',
                            _lang == 'ID'
                                ? 'id_ID'
                                : _lang == 'ZH'
                                    ? 'zh'
                                    : 'en_US')
                        .format(_lbDate),
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF1E3A8A),
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // ── Chart ──
        _lbFilterType == FilterType.monthly
            ? _buildLbMonthlyChart()
            : _buildLbDailyPieChart(),

        const SizedBox(height: 14),

        // ── Leaderboard Table ──
        _buildLbTable(),
      ],
    );
  }

  Widget _lbTabButton(FilterType type, IconData icon, String label) {
    final isActive = _lbFilterType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _lbFilterType = type);
          _fetchLeaderboardData();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6366F1) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF6366F1)
                  : const Color(0xFFBAE6FD),
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color:
                          const Color(0xFF6366F1).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color:
                      isActive ? Colors.white : Colors.black45),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLbMonthlyChart() {
    return FutureBuilder<ChartTarget>(
      future: _chartTargetFuture,
      builder: (context, targetSnap) {
        final target = targetSnap.data ??
            const ChartTarget(targetTemuan: 5, targetPenyelesaian: 4);
        return FutureBuilder<List<DailyChartData>>(
          future: _chartFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting ||
                targetSnap.connectionState == ConnectionState.waiting) {
              return _lbChartShimmer();
            }
            if (!snap.hasData || snap.data!.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(_getTxt('no_chart_data'),
                      style: const TextStyle(color: Color(0xFF64748B))),
                ),
              );
            }
            return _buildLbBarChart(snap.data!, target);
          },
        );
      },
    );
  }

  Widget _buildLbDailyPieChart() {
    return FutureBuilder<DailyChartData>(
      future: _dailyPieFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _lbChartShimmer();
        }
        final data = snap.data;
        final totalTemuan = data?.temuan ?? 0;
        final totalPenyelesaian = data?.penyelesaian ?? 0;
        final total = totalTemuan + totalPenyelesaian;

        const Color colorTemuan = Color(0xFF0EA5E9);
        const Color colorPenyelesaian = Color(0xFF10B981);
        const Color colorEmpty = Color(0xFFE2E8F0);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getTxt('chart_title_daily'),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0C4A6E),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      DateFormat('d MMM yyyy',
                              _lang == 'ID'
                                  ? 'id_ID'
                                  : _lang == 'ZH'
                                      ? 'zh'
                                      : 'en_US')
                          .format(_lbDate),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0369A1),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (total == 0)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Icon(Icons.pie_chart_outline,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text(_getTxt('no_daily_data'),
                            style: const TextStyle(
                                color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CustomPaint(
                        painter: _PieChartPainter(
                          temuanValue: totalTemuan.toDouble(),
                          penyelesaianValue:
                              totalPenyelesaian.toDouble(),
                          colorTemuan: colorTemuan,
                          colorPenyelesaian: colorPenyelesaian,
                          colorEmpty: colorEmpty,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$total',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0C4A6E))),
                              Text(_getTxt('total'),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _buildPieInfoCard(
                            color: colorTemuan,
                            label: _getTxt('temuan'),
                            value: totalTemuan,
                            total: total,
                            icon: Icons.search_rounded,
                          ),
                          const SizedBox(height: 10),
                          _buildPieInfoCard(
                            color: colorPenyelesaian,
                            label: _getTxt('penyelesaian'),
                            value: totalPenyelesaian,
                            total: total,
                            icon: Icons.check_circle_outline_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Reuse method _buildPieInfoCard dari leaderboard_detail_screen ──
  Widget _buildPieInfoCard({
    required Color color,
    required String label,
    required int value,
    required int total,
    required IconData icon,
  }) {
    final percent =
        total > 0 ? (value / total * 100).toStringAsFixed(1) : '0.0';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? value / total : 0,
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$value',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0C4A6E))),
              Text('$percent%',
                  style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLbBarChart(List<DailyChartData> data, ChartTarget target) {
    const double chartHeight = 160.0;
    const double barGroupWidth = 28.0;
    const double barWidth = 8.0;
    const double labelHeight = 28.0;
    const double leftAxisWidth = 32.0;

    const Color colorTemuan = Color(0xFF0EA5E9);
    const Color colorPenyelesaian = Color(0xFF10B981);
    const Color colorTargetTemuan = Color(0xFFEF4444);
    const Color colorTargetPenyelesaian = Color(0xFFF59E0B);

    int maxVal = target.targetTemuan > target.targetPenyelesaian
        ? target.targetTemuan
        : target.targetPenyelesaian;
    for (final d in data) {
      if (d.temuan > maxVal) maxVal = d.temuan;
      if (d.penyelesaian > maxVal) maxVal = d.penyelesaian;
    }
    maxVal = ((maxVal / 5).ceil() * 5).clamp(5, 9999);

    double valToY(int val) =>
        chartHeight - (val / maxVal * chartHeight).clamp(0, chartHeight);

    final yLabels = List.generate(6, (i) => (maxVal / 5 * i).round());

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 12, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 6),
            child: Text(
              _getTxt('chart_title'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0C4A6E),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8),
            child: Wrap(spacing: 8, runSpacing: 4, children: [
              _lbLegendItem(colorTemuan, _getTxt('temuan')),
              _lbLegendItem(colorPenyelesaian, _getTxt('penyelesaian')),
              _lbLegendDash(colorTargetTemuan,
                  '${_getTxt('target')} ${_getTxt('temuan')}'),
              _lbLegendDash(colorTargetPenyelesaian,
                  '${_getTxt('target')} ${_getTxt('penyelesaian')}'),
            ]),
          ),
          SizedBox(
            height: chartHeight + labelHeight + 8,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: leftAxisWidth,
                  height: chartHeight,
                  child: Stack(
                    children: yLabels.map((v) {
                      final top = valToY(v);
                      return Positioned(
                        top: top - 8,
                        right: 4,
                        child: Text('$v',
                            style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF94A3B8))),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: data.length * barGroupWidth + 8,
                      child: Stack(
                        children: [
                          ...yLabels.map((v) {
                            final top = valToY(v);
                            return Positioned(
                              top: top,
                              left: 0,
                              right: 0,
                              child: Container(
                                  height: 1,
                                  color: const Color(0xFFE2E8F0)),
                            );
                          }),
                          Positioned(
                            top: valToY(target.targetTemuan),
                            left: 0,
                            right: 0,
                            child: CustomPaint(
                              painter:
                                  _LbDashedLinePainter(colorTargetTemuan),
                              child: const SizedBox(height: 2),
                            ),
                          ),
                          Positioned(
                            top: valToY(target.targetPenyelesaian),
                            left: 0,
                            right: 0,
                            child: CustomPaint(
                              painter: _LbDashedLinePainter(
                                  colorTargetPenyelesaian),
                              child: const SizedBox(height: 2),
                            ),
                          ),
                          ...data.asMap().entries.map((entry) {
                            final i = entry.key;
                            final d = entry.value;
                            final x = i * barGroupWidth + 4.0;
                            final temuanH =
                                (d.temuan / maxVal * chartHeight)
                                    .clamp(0.0, chartHeight);
                            final penyelesaianH =
                                (d.penyelesaian / maxVal * chartHeight)
                                    .clamp(0.0, chartHeight);
                            return Positioned(
                              left: x,
                              top: 0,
                              child: SizedBox(
                                width: barGroupWidth,
                                height:
                                    chartHeight + labelHeight + 8,
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: chartHeight,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: barWidth,
                                            height: temuanH,
                                            decoration: BoxDecoration(
                                              color: colorTemuan,
                                              borderRadius:
                                                  const BorderRadius
                                                      .vertical(
                                                      top: Radius
                                                          .circular(3)),
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          Container(
                                            width: barWidth,
                                            height: penyelesaianH,
                                            decoration: BoxDecoration(
                                              color: colorPenyelesaian,
                                              borderRadius:
                                                  const BorderRadius
                                                      .vertical(
                                                      top: Radius
                                                          .circular(3)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: labelHeight,
                                      child: Text(
                                        DateFormat('d MMM',
                                                _lang == 'ID'
                                                    ? 'id_ID'
                                                    : _lang == 'ZH'
                                                        ? 'zh'
                                                        : 'en_US')
                                            .format(DateTime(
                                                _lbDate.year,
                                                _lbDate.month,
                                                d.date)),
                                        style: const TextStyle(
                                          fontSize: 7.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF334155),
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
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
    );
  }

  Widget _buildLbTable() {
    const Color primaryColor = Color(0xFF6366F1);
    const Color primaryLight = Color(0xFFEDE9FE);
    const Color borderColor  = Color(0xFFE2E8F0);
    const Color textPrimary  = Color(0xFF1E3A8A);
    const Color textSecondary = Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: primaryLight,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 44),
                Expanded(
                  child: Text(
                    _getTxt('name_col'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                    _lang == 'ID'
                        ? 'Poin Bulan Ini'
                        : _lang == 'ZH'
                            ? '本月积分'
                            : 'Monthly Pts',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Target row
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              border: Border(
                  bottom: BorderSide(color: borderColor, width: 0.5)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 44),
                Expanded(
                  child: Text(
                    _getTxt('monthly_target'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 90,
                  child: Text(
                    '1000',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Data
          FutureBuilder<List<LeaderboardMember>>(
            future: _leaderboardFuture,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Column(
                  children: List.generate(
                    5,
                    (_) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade200,
                      highlightColor: Colors.grey.shade50,
                      child: Container(
                        height: 56,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                );
              }
              if (!snap.hasData || snap.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      _getTxt('no_rank_data'),
                      style: const TextStyle(color: textSecondary),
                    ),
                  ),
                );
              }
              return Column(
                children: snap.data!
                    .map((item) => _buildLbRankRow(item))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLbRankRow(LeaderboardMember item) {
    const Color gold    = Color(0xFFF59E0B);
    const Color silver  = Color(0xFF94A3B8);
    const Color bronze  = Color(0xFFCD7F32);
    const Color primary = Color(0xFF6366F1);
    const Color textPrimary = Color(0xFF1E3A8A);
    const Color textSecondary = Color(0xFF64748B);
    const Color border  = Color(0xFFE2E8F0);
    const Color primaryLight = Color(0xFFEDE9FE);

    Color? leftBorder;
    Color bgColor    = Colors.white;
    Color scoreColor = primary;
    Widget badge;
    String? subLabel;

    if (item.rank == 1) {
      leftBorder = gold;
      bgColor    = const Color(0xFFFFFBEB);
      scoreColor = gold;
      badge      = const Text('🥇', style: TextStyle(fontSize: 20));
      subLabel   = _getTxt('first_class');
    } else if (item.rank == 2) {
      leftBorder = silver;
      bgColor    = const Color(0xFFF8FAFC);
      scoreColor = silver;
      badge      = const Text('🥈', style: TextStyle(fontSize: 20));
      subLabel   = _getTxt('business_class');
    } else if (item.rank == 3) {
      leftBorder = bronze;
      bgColor    = const Color(0xFFFDF6EE);
      scoreColor = bronze;
      badge      = const Text('🥉', style: TextStyle(fontSize: 20));
      subLabel   = _getTxt('premium_class');
    } else {
      badge = SizedBox(
        width: 28,
        child: Text(
          '${item.rank}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textSecondary,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: border, width: 0.5),
          left: leftBorder != null
              ? BorderSide(color: leftBorder, width: 3)
              : BorderSide.none,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 44, child: Center(child: badge)),
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundImage: (item.avatarUrl != null &&
                          item.avatarUrl!.isNotEmpty)
                      ? NetworkImage(item.avatarUrl!)
                      : null,
                  backgroundColor: primaryLight,
                  child: (item.avatarUrl == null ||
                          item.avatarUrl!.isEmpty)
                      ? Text(
                          item.name
                              .trim()
                              .split(' ')
                              .take(2)
                              .map((w) =>
                                  w.isNotEmpty ? w[0].toUpperCase() : '')
                              .join(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: item.rank <= 3
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subLabel != null)
                        Text(
                          subLabel,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: scoreColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              '${item.monthlyPoints}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: scoreColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lbLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10.5, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _lbLegendDash(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          child: CustomPaint(
            painter: _LbDashedLinePainter(color),
            child: const SizedBox(height: 2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10.5, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _lbChartShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildTemuanOverview() {
    final total = _totalTemuan == 0 ? 1 : _totalTemuan;
    final prosesTemuan = _totalTemuan - _temuanBelum - _temuanSelesai;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, // ← putih
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTemuanBadge(
                _lang == 'EN' ? 'Pending' : _lang == 'ZH' ? '待处理' : 'Belum',
                _temuanBelum,
                const Color(0xFFEF4444),
              ),
              _buildTemuanBadge(
                _lang == 'EN' ? 'In Progress' : _lang == 'ZH' ? '处理中' : 'Proses',
                prosesTemuan < 0 ? 0 : prosesTemuan,
                const Color(0xFFF59E0B),
              ),
              _buildTemuanBadge(
                _lang == 'EN' ? 'Done' : _lang == 'ZH' ? '已完成' : 'Selesai',
                _temuanSelesai,
                const Color(0xFF10B981),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Flexible(
                    flex: (_temuanBelum * 100 ~/ total).clamp(0, 100),
                    child: Container(color: const Color(0xFFEF4444)),
                  ),
                  Flexible(
                    flex: (prosesTemuan < 0
                            ? 0
                            : prosesTemuan * 100 ~/ total)
                        .clamp(0, 100),
                    child: Container(color: const Color(0xFFF59E0B)),
                  ),
                  Flexible(
                    flex: (_temuanSelesai * 100 ~/ total).clamp(0, 100),
                    child: Container(color: const Color(0xFF10B981)),
                  ),
                  if (_totalTemuan == 0)
                    Flexible(
                      flex: 100,
                      child: Container(color: Colors.black12),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _lang == 'EN'
                ? 'Total $_totalTemuan findings recorded'
                : _lang == 'ZH'
                    ? '共记录 $_totalTemuan 项发现'
                    : 'Total $_totalTemuan temuan tercatat',
            style: GoogleFonts.poppins(color: Colors.black38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTemuanBadge(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Center(
            child: Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: GoogleFonts.poppins(color: Colors.black45, fontSize: 12)),
      ],
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _lang == 'EN' ? 'Coming Soon!' : 'Segera Hadir!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
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

// ── Dashed line painter untuk chart leaderboard ──
class _LbDashedLinePainter extends CustomPainter {
  final Color color;
  _LbDashedLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Pie chart painter (reuse dari leaderboard_detail_screen) ──
class _PieChartPainter extends CustomPainter {
  final double temuanValue;
  final double penyelesaianValue;
  final Color colorTemuan;
  final Color colorPenyelesaian;
  final Color colorEmpty;

  _PieChartPainter({
    required this.temuanValue,
    required this.penyelesaianValue,
    required this.colorTemuan,
    required this.colorPenyelesaian,
    required this.colorEmpty,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = temuanValue + penyelesaianValue;
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.55;

    if (total == 0) {
      final paint = Paint()
        ..color = colorEmpty
        ..style = PaintingStyle.stroke
        ..strokeWidth = outerRadius - innerRadius;
      canvas.drawCircle(
          center, (outerRadius + innerRadius) / 2, paint);
      return;
    }

    double startAngle = -90 * (3.14159265 / 180);
    const double gapAngle = 0.04;

    final segments = [
      {'value': temuanValue, 'color': colorTemuan},
      {'value': penyelesaianValue, 'color': colorPenyelesaian},
    ];

    for (final seg in segments) {
      final value = seg['value'] as double;
      final color = seg['color'] as Color;
      if (value <= 0) continue;

      final sweepAngle = (value / total) * 2 * 3.14159265 - gapAngle;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = outerRadius - innerRadius
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(
            center: center, radius: (outerRadius + innerRadius) / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}