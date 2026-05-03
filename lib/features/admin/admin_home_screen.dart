import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Import screen admin lainnya ───
import 'admin_profile_screen.dart';
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
    if (mounted) setState(() => _lang = prefs.getString('lang') ?? 'ID');
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
          _lang == 'EN' ? 'Logout' : 'Keluar',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          _lang == 'EN'
              ? 'Are you sure you want to logout?'
              : 'Apakah Anda yakin ingin keluar?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_lang == 'EN' ? 'Cancel' : 'Batal',
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(_lang == 'EN' ? 'Logout' : 'Keluar',
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
                            _buildWelcomeBanner(),
                            const SizedBox(height: 24),
                            _isLoadingStats
                                ? _buildStatsShimmer()   // ← shimmer saat loading
                                : _buildStatsGrid(),
                            const SizedBox(height: 28),
                            _buildSectionLabel(
                              _lang == 'EN' ? 'Management Menu' : 'Menu Manajemen',
                            ),
                            const SizedBox(height: 14),
                            _buildMenuGrid(),
                            const SizedBox(height: 28),
                            _buildSectionLabel(
                              _lang == 'EN' ? 'Finding Overview' : 'Ringkasan Temuan',
                            ),
                            const SizedBox(height: 14),
                            _buildTemuanOverview(),
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
          // Logo — sama seperti home_screen.dart
          Image.asset(
            'assets/images/logo1.png',
            height: 38,
            errorBuilder: (_, __, ___) => Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Admin Panel',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E3A8A),
            ),
          ),
          const Spacer(),
          // Avatar — tap buka AdminProfileScreen
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
                // Refresh data setelah kembali dari profile
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
                  radius: 17,
                  backgroundColor: const Color(0xFF6366F1),
                  backgroundImage: _adminImage != null
                      ? CachedNetworkImageProvider(_adminImage!)
                      : null,
                  child: _adminImage == null
                      ? const Icon(Icons.person, color: Colors.white, size: 18)
                      : null,
                ),
              ),
            ),
          ),
        ],
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

  Widget _buildWelcomeBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lang == 'EN'
                      ? 'Welcome back,'
                      : 'Selamat datang kembali,',
                  style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8), fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  _adminName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_rounded,
                          color: Colors.white, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        'Super Admin',
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
          Image.asset(
            'assets/images/logo.png',
            width: 80,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      _StatItem(
        label: _lang == 'EN' ? 'Total Users' : 'Total Pengguna',
        value: _totalUsers,
        icon: Icons.people_rounded,
        color: const Color(0xFF22D3EE),
        bgColor: const Color(0xFF164E63),
      ),
      _StatItem(
        label: _lang == 'EN' ? 'Locations' : 'Lokasi',
        value: _totalLokasi,
        icon: Icons.location_city_rounded,
        color: const Color(0xFF34D399),
        bgColor: const Color(0xFF064E3B),
      ),
      _StatItem(
        label: _lang == 'EN' ? 'Categories' : 'Kategori',
        value: _totalKategori,
        icon: Icons.category_rounded,
        color: const Color(0xFFFBBF24),
        bgColor: const Color(0xFF78350F),
      ),
      _StatItem(
        label: _lang == 'EN' ? 'Total Findings' : 'Total Temuan',
        value: _totalTemuan,
        icon: Icons.assignment_rounded,
        color: const Color(0xFFF472B6),
        bgColor: const Color(0xFF831843),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) => _buildStatCard(stats[i]),
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,  // ← putih
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: item.color.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.10), // ← lebih lembut
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.value}',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: item.color,
                ),
              ),
              Text(
                item.label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.black45,  // ← gelap sedikit agar terbaca di bg putih
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
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
        label: _lang == 'EN' ? 'User\nManagement' : 'Kelola\nPengguna',
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
        label: _lang == 'EN' ? 'Location\nManagement' : 'Kelola\nLokasi',
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
        label: _lang == 'EN' ? 'Category\nManagement' : 'Kelola\nKategori',
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
        label: _lang == 'EN' ? 'App\nSettings' : 'Pengaturan\nAplikasi',
        icon: Icons.settings_rounded,
        gradient: const [Color(0xFFEC4899), Color(0xFFDB2777)],
        shadow: const Color(0xFFEC4899),
        onTap: () => _showComingSoon(),
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
                            _lang == 'EN' ? 'Manage' : 'Kelola',
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
                _lang == 'EN' ? 'Pending' : 'Belum',
                _temuanBelum,
                const Color(0xFFEF4444),
              ),
              _buildTemuanBadge(
                _lang == 'EN' ? 'In Progress' : 'Proses',
                prosesTemuan < 0 ? 0 : prosesTemuan,
                const Color(0xFFF59E0B),
              ),
              _buildTemuanBadge(
                _lang == 'EN' ? 'Done' : 'Selesai',
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