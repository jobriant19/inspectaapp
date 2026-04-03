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
   String _userEmail = "";
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

      // 1) Ambil user TANPA join dulu (menghindari error relasi)
      final userRow = await Supabase.instance.client
          .from('User')
          .select('nama, email, poin, gambar_user, id_jabatan')
          .eq('id_user', userAuth.id)
          .maybeSingle();

      if (userRow == null) {
        // Fallback jika row belum sempat terinsert
        if (!mounted) return;
        setState(() {
          _userName = userAuth.userMetadata?['full_name'] ?? 'User';
          _userEmail = userAuth.email ?? '';
          _userPoin = 0;
          _userImage = userAuth.userMetadata?['avatar_url'];
          _userRole = 'Staff';
        });
        return;
      }

      // 2) Ambil nama jabatan dari tabel jabatan berdasarkan id_jabatan
      String roleName = '-';
      final int? idJabatan = userRow['id_jabatan'];

      if (idJabatan != null) {
        final jabatanRow = await Supabase.instance.client
            .from(
              'jabatan',
            ) // PENTING: gunakan nama tabel asli di DB (umumnya lowercase)
            .select('nama_jabatan')
            .eq('id_jabatan', idJabatan)
            .maybeSingle();

        roleName = jabatanRow?['nama_jabatan'] ?? '-';
      }

      if (!mounted) return;
      setState(() {
        _userName =
            userRow['nama'] ?? userAuth.userMetadata?['full_name'] ?? 'User';
        _userEmail = userRow['email'] ?? userAuth.email ?? '';
        _userPoin = userRow['poin'] ?? 0;
        _userImage =
            userRow['gambar_user'] ?? userAuth.userMetadata?['avatar_url'];
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
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER CUSTOM (GLASSMORPHISM) ---
            Padding(
              padding: const EdgeInsets.only(
                left: 15,
                right: 15,
                top: 15,
                bottom: 5,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                        0.4,
                      ), // Warna kaca semi transparan
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
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
                            color: Colors.blue,
                            size: 35,
                          ),
                        ),

                        const Spacer(),

                        // TENGAH: Poin
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.stars,
                                color: Colors.orange,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "$_userPoin Pts",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // KANAN: Notifikasi & Profil
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileScreen(lang: _lang),
                              ),
                            ).then((_) => _fetchUserData());
                          },
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _userName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    _userRole,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              // FOTO PROFIL
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFF00C9E4),
                                backgroundImage: _userImage != null
                                    ? NetworkImage(_userImage!)
                                    : null,
                                child: _userImage == null
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 20,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // --- KONTEN HALAMAN (BERUBAH SESUAI TAB) ---
            Expanded(child: pages[_currentIndex]),
          ],
        ),
      ),

      // --- BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF00C9E4),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: getTxt('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.explore_outlined),
            activeIcon: const Icon(Icons.explore),
            label: getTxt('explore'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart_outlined),
            activeIcon: const Icon(Icons.bar_chart),
            label: getTxt('analytics'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.leaderboard_outlined),
            activeIcon: const Icon(Icons.leaderboard),
            label: getTxt('ranking'),
          ),
        ],
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
