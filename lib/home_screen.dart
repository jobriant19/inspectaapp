import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'explore_screen.dart';
import 'analytics_screen.dart';
import 'ranking_screen.dart';
import 'profile_screen.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _lang = 'EN';

  // Data User
  String _userName = "Loading...";
  String _userRole = "Loading...";
  int _userPoin = 0;
  String? _userImage;

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

      Map<String, dynamic>? userRow;

      for (int i = 0; i < 3; i++) {
        userRow = await Supabase.instance.client
            .from('User')
            .select('nama, email, poin, gambar_user, id_jabatan')
            .eq('id_user', userAuth.id)
            .maybeSingle();

        if (userRow != null) break; 
        await Future.delayed(const Duration(milliseconds: 800)); 
      }

      // Ambil metadata dari Google (Sebagai cadangan jika foto di DB kosong)
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

      String roleName = 'Staff';
      final int? idJabatan = userRow['id_jabatan'];

      if (idJabatan != null) {
        final jabatanRow = await Supabase.instance.client
            .from('jabatan') 
            .select('nama_jabatan')
            .eq('id_jabatan', idJabatan)
            .maybeSingle();
        roleName = jabatanRow?['nama_jabatan'] ?? 'Staff';
      }

      // --- PERBAIKAN: Cek apakah string gambar dari DB kosong ("") ---
      String? dbImage = userRow['gambar_user'];
      if (dbImage != null && dbImage.trim().isEmpty) dbImage = null;

      if (!mounted) return;
      setState(() {
        _userName = userRow?['nama'] ?? metaName ?? 'User';
        _userPoin = userRow?['poin'] ?? 0;
        _userImage = dbImage ?? metaImage; // Gunakan foto dari DB, jika kosong pakai Google
        _userRole = roleName;
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
      backgroundColor: const Color(0xFFFAFAFA), // Warna dasar putih bersih
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
                  padding: const EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
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
                          border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
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
                              errorBuilder: (c, e, s) => const Icon(Icons.shield, color: Color(0xFF00C9E4), size: 35),
                            ),

                            // KANAN: Notifikasi & Foto Profil Saja
                            Row(
                              children: [
                                // Tombol Notifikasi
                                GestureDetector(
                                  onTap: () {
                                    // Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationScreen(lang: _lang)));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00C9E4).withOpacity(0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                                    ),
                                    child: const Icon(
                                      Icons.notifications_active_outlined, 
                                      color: Colors.white, 
                                      size: 20
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Foto Profil Saja (Bisa di-klik)
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => ProfileScreen(lang: _lang)),
                                    ).then((_) => _fetchUserData());
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(20), 
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04), 
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Kiri: Nama dan Jabatan
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _userRole,
                                style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          
                          // Kanan: Poin
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.stars_rounded, color: Colors.orange, size: 20),
                                const SizedBox(width: 5),
                                Text(
                                  "$_userPoin Pts", 
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_currentIndex == 0) // Jarak hanya jika Info Card muncul
                  const SizedBox(height: 10),  // Jarak spasi sebelum konten halaman

                // --- KONTEN HALAMAN (BERUBAH SESUAI TAB) ---
                Expanded(child: pages[_currentIndex]),
              ],
            ),
          ),
        ],
      ),

      // --- TAMBAHAN: Agar konten berada di belakang nav bar (Efek Floating) ---
      extendBody: true, 

      // --- BOTTOM NAVIGATION BAR (CUSTOM PREMIUM FLOATING + FAB) ---
      bottomNavigationBar: Container(
        height: 100, // Total tinggi area (termasuk tombol + yang menyembul)
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
                    color: const Color(0xFF00C9E4).withOpacity(0.15), // Shadow biru tipis
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
                  const SizedBox(width: 50), // Jarak ruang kosong di tengah untuk tombol +
                  _buildNavItem(Icons.pie_chart_outline, Icons.pie_chart, 2),
                  _buildNavItem(Icons.emoji_events_outlined, Icons.emoji_events, 3),
                ],
              ),
            ),

            // 2. Tombol + Melayang di Tengah
            Positioned(
              top: 0, // Mengangkat tombol agar menyembul di atas kotak putih
              child: GestureDetector(
                onTap: () {
                  // TODO: Aksi ketika tombol + diklik (Bisa navigasi ke layar tambah tugas)
                  debugPrint("Tombol + diklik!");
                },
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C9E4), // Warna biru cerah sama seperti header
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

  // --- WIDGET HELPER: Untuk Ikon Navigasi Bawah Kustom ---
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
              color: isActive ? const Color(0xFF00C9E4).withOpacity(0.15) : Colors.transparent,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/login_illustration.png',
            height: 150,
            errorBuilder: (c, e, s) => const Icon(Icons.image, size: 100),
          ),
          const SizedBox(height: 20),
          const Text(
            "Welcome to Inspecta!",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text("Make Your Discipline day!"),
        ],
      ),
    );
  }
}
