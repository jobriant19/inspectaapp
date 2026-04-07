import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'explore_screen.dart';
import 'analytics_screen.dart';
import 'notification_screen.dart';
import 'qr_scanner_screen.dart';
import 'ranking_screen.dart';
import 'profile_screen.dart';
import 'camera_finding_screen.dart';
import 'location_screen.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _lang = 'EN';
  bool _isProMode = false;

  // Data User
  String _userName = "Loading...";
  String _userRole = "Loading...";
  int _userPoin = 0;
  String? _userImage;
  int? _userUnitId;
  int? _userLokasiId;

  // Dictionary Translate untuk Navigation Bar
  final Map<String, Map<String, String>> _navText = {
    'EN': {
      'home': 'Home',
      'explore': 'Explore',
      'analytics': 'Analytics',
      'ranking': 'Ranking',
    },
    'ID': {
      'home': 'Beranda',
      'explore': 'Telusuri',
      'analytics': 'Analitik',
      'ranking': 'Peringkat',
    },
    'ZH': {'home': '主页', 'explore': '探索', 'analytics': '分析', 'ranking': '排名'},
  };

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _fetchUserData();
  }

  Future<void> _loadLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _lang = prefs.getString('lang') ?? 'EN';
    });
  }

  Future<void> _fetchUserData() async {
    try {
      final userAuth = Supabase.instance.client.auth.currentUser;
      if (userAuth == null) return;
      final userRow = await Supabase.instance.client
          .from('User')
          .select('nama, email, poin, gambar_user, id_unit, id_lokasi, jabatan(nama_jabatan)')
          .eq('id_user', userAuth.id)
          .maybeSingle();

      // Ambil metadata dari Google Sebagai cadangan jika foto di DB kosong
      final String? metaName = userAuth.userMetadata?['full_name'] ?? userAuth.userMetadata?['name'];
      final String? metaImage = userAuth.userMetadata?['avatar_url'] ?? userAuth.userMetadata?['picture'];

      if (userRow == null) {
        if (!mounted) return;
        setState(() {
          _userName = metaName ?? 'User';
          _userPoin = 0;
          _userImage = metaImage;
          _userRole = 'Staff';
        });
        return;
      }

      // Parsing Jabatan dari relasi tabel
      String roleName = 'Staff';
      if (userRow['jabatan'] != null && userRow['jabatan']['nama_jabatan'] != null) {
        roleName = userRow['jabatan']['nama_jabatan'];
      }

      String? dbImage = userRow['gambar_user'];
      if (dbImage != null && dbImage.trim().isEmpty) dbImage = null;

      if (!mounted) return;
      setState(() {
        _userName = userRow['nama'] ?? metaName ?? 'User';
        _userPoin = userRow['poin'] ?? 0;
        _userImage = dbImage ?? metaImage;
        _userRole = roleName;
        _userUnitId = userRow['id_unit'];
        _userLokasiId = userRow['id_lokasi'];
      });
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  String getTxt(String key) => _navText[_lang]![key] ?? key;

  @override
  Widget build(BuildContext context) {
    // List Layar yang akan ditampilkan
    final List<Widget> pages = [
      _buildHomeContent(), // 0: Beranda
      ExploreScreen(lang: _lang), // 1: Telusuri
      AnalyticsScreen(lang: _lang), // 2: Analitik
      RankingScreen(lang: _lang), // 3: Peringkat
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // --- 1. EFEK BACKGROUND BERCAK BIRU CERAH (BLOB GRADIENT) ---
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00C9E4).withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00C9E4).withOpacity(0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // --- 2. KONTEN UTAMA APLIKASI ---
          SafeArea(
            child: Column(
              children: [
                // ==========================================
                // --- BAGIAN 1: HEADER (LOGO, NOTIF, FOTO) ---
                // ==========================================
                Padding(
                  padding: const EdgeInsets.only(
                    left: 15,
                    right: 15,
                    top: 15,
                    bottom: 10,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.7),
                              const Color(0xFF00C9E4).withOpacity(0.15),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.9),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00C9E4).withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // KIRI: Logo
                            Image.asset(
                              'assets/images/logo.png',
                              height: 40,
                              errorBuilder: (c, e, s) => const Icon(
                                Icons.shield,
                                color: Color(0xFF00C9E4),
                                size: 35,
                              ),
                            ),

                            // KANAN: Notifikasi & Foto Profil Saja
                            Row(
                              children: [
                                // Tombol Notifikasi
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            NotificationScreen(lang: _lang),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF00C9E4,
                                      ).withOpacity(0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.8),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.notifications_active_outlined,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Foto Profil Saja Bisa Klik untuk ke Profile Screen
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(lang: _lang)))
                                    .then((_) => _fetchUserData());
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                    ),
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: const Color(0xFF00C9E4),
                                      backgroundImage: _userImage != null ? NetworkImage(_userImage!) : null,
                                      child: _userImage == null ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ==========================================
                // --- BAGIAN 2: INFO CARD (NAMA, JABATAN, POIN) ---
                // ==========================================
                if (_currentIndex == 0) // Hanya muncul jika berada di tab Home (index 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00C9E4), Color(0xFF0075FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0075FF).withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // --- Elemen Dekorasi Background ---
                          Positioned(
                            right: -30,
                            top: -40,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.15),
                              ),
                            ),
                          ),
                          Positioned(
                            left: -20,
                            bottom: -50,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          ),

                          // --- Konten Utama Info Card ---
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // KIRI: Nama dan Jabatan Premium
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _userName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight:
                                              FontWeight.w900, 
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black26,
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      // Badge Jabatan (Glassmorphism effect)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.5,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          _userRole,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // KANAN: Poin Eksklusif
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFDF00),
                                        Color(0xFFD4AF37),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.9),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFD4AF37,
                                        ).withOpacity(0.6),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.workspace_premium_rounded,
                                        color: Colors.white,
                                        size: 26,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black26,
                                            blurRadius: 2,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "$_userPoin P",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          fontSize: 16,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black26,
                                              blurRadius: 2,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_currentIndex == 0) // Jarak hanya jika Info Card muncul
                  const SizedBox(
                    height: 10,
                  ),
                // --- KONTEN HALAMAN BERUBAH SESUAI TAB ---
                Expanded(child: pages[_currentIndex]),
              ],
            ),
          ),
        ],
      ),

      extendBody: true,

      // --- BOTTOM NAVIGATION BAR (CUSTOM PREMIUM FLOATING + FAB) ---
      bottomNavigationBar: Container(
        height: 100,
        padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // 1. Kotak Latar Belakang Putih Melayang
            Container(
              height: 65,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF00C9E4,
                    ).withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.home_outlined, Icons.home_rounded, 0),
                  _buildNavItem(Icons.explore_outlined, Icons.explore, 1),
                  const SizedBox(
                    width: 50,
                  ), // Jarak ruang kosong di tengah untuk tombol +
                  _buildNavItem(Icons.pie_chart_outline, Icons.pie_chart, 2),
                  _buildNavItem(
                    Icons.emoji_events_outlined,
                    Icons.emoji_events,
                    3,
                  ),
                ],
              ),
            ),

            // 2. Tombol + Melayang di Tengah
            Positioned(
              top: 0, 
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true, // Agar bisa full screen jika data banyak
                    backgroundColor: Colors.transparent,
                    builder: (context) => LocationBottomSheet(
                      lang: _lang,
                      isProMode: _isProMode,
                      userUnitId: _userUnitId,
                      userLokasiId: _userLokasiId,
                      userRole: _userRole,
                    ),
                  );
                },
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF00C9E4,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C9E4).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER Untuk Ikon Navigasi Bawah Kustom ---
  Widget _buildNavItem(IconData outlineIcon, IconData filledIcon, int index) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 50,
        height: 65,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.all(isActive ? 10 : 0),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF00C9E4).withOpacity(0.15)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? filledIcon : outlineIcon,
              size: 28,
              color: isActive ? const Color(0xFF00C9E4) : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }

  // Desain Konten Beranda Asli
  Widget _buildHomeContent() {
    // Dictionary Bahasa khusus untuk area konten beranda
    final Map<String, Map<String, String>> homeTexts = {
      'EN': {
        'inspeksi': 'Inspection',
        'pro_mode': 'Professional Mode',
        'telusur': 'Browse & Manage',
        'lokasi': 'Location',
        'laporan': 'Accident Report',
        'hint': 'Click the + button to add a new finding.',
      },
      'ID': {
        'inspeksi': 'Inspeksi',
        'pro_mode': 'Mode Profesional',
        'telusur': 'Telusur & Atur',
        'lokasi': 'Lokasi',
        'laporan': 'Laporan Kecelakaan',
        'hint': 'Klik tombol + untuk memasukkan temuan baru.',
      },
      'ZH': {
        'inspeksi': '检查', // Jiǎnchá
        'pro_mode': '专业模式', // Zhuānyè móshì
        'telusur': '浏览与管理', // Liúlǎn yǔ guǎnlǐ
        'lokasi': '地点', // Dìdiǎn
        'laporan': '事故报告', // Shìgù bàogào
        'hint': '点击 + 按钮添加新发现。', // Diǎnjī + ànniǔ...
      },
    };

    String getHomeTxt(String key) => homeTexts[_lang]?[key] ?? key;

    // Future Builder untuk mengambil daftar Temuan
    Widget recentFindingsWidget = FutureBuilder<List<dynamic>>(
      future: Supabase.instance.client
          .from('Temuan')
          .select('judul_temuan, gambar_temuan, status_temuan, created_at, lokasi(nama_lokasi)')
          .order('created_at', ascending: false)
          .limit(5), 
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); 
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Temuan Terbaru",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final temuan = snapshot.data![index];
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            temuan['gambar_temuan'] ?? '',
                            height: 90, width: double.infinity, fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(height: 90, color: Colors.grey.shade300, child: const Icon(Icons.image_not_supported)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                temuan['judul_temuan'],
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                temuan['lokasi'] != null ? temuan['lokasi']['nama_lokasi'] : 'Unknown',
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Colors.black54),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
          ],
        );
      },
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // 1. BAGIAN: INSPEKSI (MODE PROFESIONAL)
          // ==========================================
          if (_userRole == 'Eksekutif') ...[
            Text(
              getHomeTxt('inspeksi'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.assignment_ind_outlined,
                        color: Color(0xFF1E3A8A),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        getHomeTxt('pro_mode'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                  Switch.adaptive(
                    value: _isProMode,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.orange.shade300,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade300,
                    onChanged: (value) {
                      setState(() {
                        _isProMode = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
          ],

          // ==========================================
          // 2. BAGIAN: TELUSUR & ATUR
          // ==========================================
          Text(
            getHomeTxt('telusur'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),

          // Tombol Lokasi
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 2,
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.lightBlue,
                  size: 24,
                ),
              ),
              title: Text(
                getHomeTxt('lokasi'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.black38,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LocationScreen(
                      lang: _lang,
                      isProMode: _isProMode,
                      userRole: _userRole,
                      userUnitId: _userUnitId,
                      userLokasiId: _userLokasiId,
                    ),
                  ),
                );
              },
            ),
          ),

          // Tombol Laporan Kecelakaan
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 2,
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 24,
                ),
              ),
              title: Text(
                getHomeTxt('laporan'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.black38,
              ),
              onTap: () {
                // TODO: Navigasi ke Layar Laporan Kecelakaan
              },
            ),
          ),
          const SizedBox(height: 25),

          recentFindingsWidget,

          // ==========================================
          // 3. BAGIAN: ILUSTRASI & TEKS PETUNJUK BAWAH
          // ==========================================
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/images/team_illustration.png',
                  height: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.people_alt_outlined,
                    size: 100,
                    color: Colors.black12,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  getHomeTxt('hint'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGET BOTTOM SHEET: PILIH LOKASI (Lokasi -> Unit -> Subunit -> Area)
// ============================================================================
class LocationBottomSheet extends StatefulWidget {
  final String lang;
  final bool isProMode; 
  final int? userUnitId;
  final int? userLokasiId;
  final String userRole;

  const LocationBottomSheet({
    super.key,
    required this.lang,
    required this.isProMode,
    required this.userRole,
    this.userUnitId,
    this.userLokasiId,
  });

  @override
  State<LocationBottomSheet> createState() => _LocationBottomSheetState();
}

class _LocationBottomSheetState extends State<LocationBottomSheet> {
  int _currentLevel = 0; // 0: Lokasi, 1: Unit, 2: Subunit, 3: Area
  bool _isLoading = true;
  List<dynamic> _currentData = [];
  List<dynamic> _filteredData = [];
  String _searchQuery = "";

  List<Map<String, dynamic>> _navigationHistory = [];

  bool get _hasFullAccess => widget.isProMode || widget.userRole == 'Eksekutif';

  // --- HELPER METHODS UNTUK MENGAMBIL NAMA KOLOM SECARA DINAMIS ---
  String _getTableName(int level) => ['lokasi', 'unit', 'subunit', 'area'][level];
  String _getIdColumn(int level) => 'id_${_getTableName(level)}';
  String _getNameColumn(int level) => 'nama_${_getTableName(level)}';
  String _getChildColumn(int level) => level < 3 ? ['unit', 'subunit', 'area'][level] : '';

  @override
  void initState() {
    super.initState();
    _currentLevel = 0;
    _fetchData();
  }

  Future<void> _fetchData({int? parentId, String? parentName}) async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      List<dynamic> data = [];

      if (_currentLevel == 0) {
        data = await supabase.from('lokasi').select('id_lokasi, nama_lokasi, unit(id_unit), is_star');
      } else if (_currentLevel == 1) {
        if (_hasFullAccess) {
          data = await supabase.from('unit').select('id_unit, nama_unit, subunit(id_subunit), is_star').eq('id_lokasi', parentId!);
        } else {
          if (widget.userUnitId != null) {
            data = await supabase.from('unit').select('id_unit, nama_unit, subunit(id_subunit), is_star').eq('id_lokasi', parentId!).eq('id_unit', widget.userUnitId!);
          } else { data = []; }
        }
      } else if (_currentLevel == 2) {
        data = await supabase.from('subunit').select('id_subunit, nama_subunit, area(id_area), is_star').eq('id_unit', parentId!);
      } else if (_currentLevel == 3) {
        data = await supabase.from('area').select('id_area, nama_area, is_star').eq('id_subunit', parentId!);
      }

      if (mounted) {
        setState(() {
          _currentData = data;
          _filteredData = List.from(data);
          _sortData();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching locations: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onItemTapped(Map<String, dynamic> item) {
    if (_currentLevel == 3) {
      Navigator.pop(context, item);
      return;
    }

    setState(() {
      _navigationHistory.add({
        'level': _currentLevel,
        'id': item[_getIdColumn(_currentLevel)], 
        'name': item[_getNameColumn(_currentLevel)], 
      });
      _currentLevel++;
      _searchQuery = ""; 
    });

    // Panggil ulang fetch data untuk level selanjutnya
    _fetchData(
      parentId: item[_getIdColumn(_currentLevel - 1)],
      parentName: item[_getNameColumn(_currentLevel - 1)],
    );
  }

  void _goBack() {
    if (_navigationHistory.isEmpty) return;

    setState(() {
      _navigationHistory.removeLast();
      _currentLevel--;
      _searchQuery = "";
    });

    if (_navigationHistory.isEmpty) {
      _currentLevel = 0;
      _fetchData(); 
    } else {
      final prev = _navigationHistory.last;
      _fetchData(parentId: prev['id'], parentName: prev['name']);
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredData = _currentData.where((item) {
        String name = item[_getNameColumn(_currentLevel)].toString().toLowerCase();
        return name.contains(_searchQuery);
      }).toList();
      _sortData();
    });
  }

  void _sortData() {
    _filteredData.sort((a, b) {
      int isStarA = a['is_star'] ?? 0;
      int isStarB = b['is_star'] ?? 0;

      if (isStarA == 1 && isStarB == 0) return -1;
      if (isStarA == 0 && isStarB == 1) return 1;
      
      final nameCol = _getNameColumn(_currentLevel);
      final nameA = a[nameCol].toString().toLowerCase();
      final nameB = b[nameCol].toString().toLowerCase();
      return nameA.compareTo(nameB);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, Map<String, String>> bottomSheetTexts = {
      'EN': {
        'pilih_lokasi': 'Choose Finding Location',
        'cari': 'Search location',
        'semua': 'All Locations',
        'unit_saya': 'My Unit',
        'kosong': 'Data not found.',
        'sub': 'Sub-locations',
      },
      'ID': {
        'pilih_lokasi': 'Pilih Lokasi Temuan',
        'cari': 'Cari lokasi',
        'semua': 'Semua Lokasi',
        'unit_saya': 'Unit Saya',
        'kosong': 'Data tidak ditemukan.',
        'sub': 'Sub-lokasi',
      },
    };

    String getBsTxt(String key) => bottomSheetTexts[widget.lang]?[key] ?? key;

    String currentParentName = _navigationHistory.isEmpty
        ? (!_hasFullAccess ? getBsTxt('unit_saya') : getBsTxt('semua'))
        : _navigationHistory.last['name'];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Text(
              getBsTxt('pilih_lokasi'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.black12),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            onChanged: _onSearch,
                            decoration: InputDecoration(
                              hintText: getBsTxt('cari'),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen()));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F8FC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.qr_code_scanner, color: Color(0xFF1E3A8A)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            child: Row(
              children: [
                if (_navigationHistory.isNotEmpty)
                  GestureDetector(
                    onTap: _goBack,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.arrow_back_ios, size: 18, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                Text(
                  currentParentName.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C9E4)))
                : _filteredData.isEmpty
                ? Center(child: Text(getBsTxt('kosong'), style: const TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredData.length,
                    itemBuilder: (context, index) {
                      final item = _filteredData[index];
                      
                      // AMBIL DATA DENGAN NAMA KOLOM (AMAN DARI ERROR)
                      final String idCol = _getIdColumn(_currentLevel);
                      final String nameCol = _getNameColumn(_currentLevel);
                      final String childCol = _getChildColumn(_currentLevel);

                      final int itemId = item[idCol] as int;
                      final String itemName = item[nameCol].toString();

                      int subCount = 0;
                      if (_currentLevel < 3) {
                        final listSub = item[childCol] as List<dynamic>?;
                        subCount = listSub?.length ?? 0;
                      }

                      return GestureDetector(
                        onTap: () => _onItemTapped(item),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6FAFE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.domain, color: Colors.lightBlue, size: 28),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      itemName,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
                                    ),
                                    if (_currentLevel < 3)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.account_tree_outlined, size: 14, color: Colors.black54),
                                            const SizedBox(width: 5),
                                            Text(
                                              "$subCount ${getBsTxt('sub')}",
                                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              
                              // AREA TOMBOL AKSI (BINTANG & KAMERA)
                              Row(
                                children: [
                                  // TOMBOL BINTANG
                                  GestureDetector(
                                    onTap: () async {
                                      int currentStar = item['is_star'] ?? 0;
                                      int newStar = currentStar == 1 ? 0 : 1;

                                      String tableName = _getTableName(_currentLevel);

                                      setState(() {
                                        item['is_star'] = newStar;
                                        _sortData();
                                      });

                                      await Supabase.instance.client
                                          .from(tableName)
                                          .update({'is_star': newStar})
                                          .eq(idCol, itemId);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        (item['is_star'] ?? 0) == 1
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        color: Colors.amber,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // TOMBOL KAMERA
                                  GestureDetector(
                                    onTap: () {
                                      int? idL, idU, idS, idA;

                                      if (_currentLevel == 0) { idL = itemId; }
                                      else if (_currentLevel == 1) { idL = _navigationHistory[0]['id']; idU = itemId; }
                                      else if (_currentLevel == 2) { idL = _navigationHistory[0]['id']; idU = _navigationHistory[1]['id']; idS = itemId; }
                                      else if (_currentLevel == 3) { idL = _navigationHistory[0]['id']; idU = _navigationHistory[1]['id']; idS = _navigationHistory[2]['id']; idA = itemId; }

                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CameraFindingScreen(
                                            locationName: itemName,
                                            idLokasi: idL, idUnit: idU, idSubunit: idS, idArea: idA,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00C9E4).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.camera_alt, color: Color(0xFF00C9E4), size: 24),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
