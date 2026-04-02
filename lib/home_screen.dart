import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'explore_screen.dart';
import 'analytics_screen.dart';
import 'ranking_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';

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

  // Dictionary Translate untuk Navigation Bar
  final Map<String, Map<String, String>> _navText = {
    'EN': {'home': 'Home', 'explore': 'Explore', 'analytics': 'Analytics', 'ranking': 'Ranking'},
    'ID': {'home': 'Beranda', 'explore': 'Telusuri', 'analytics': 'Analitik', 'ranking': 'Peringkat'},
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
      if (userAuth != null) {
        // Join tabel User dan Jabatan
        final data = await Supabase.instance.client
            .from('User')
            .select('nama, poin, Jabatan(nama_jabatan)')
            .eq('id_user', userAuth.id)
            .single();

        setState(() {
          _userName = data['nama'] ?? 'User';
          _userPoin = data['poin'] ?? 0;
          _userRole = data['Jabatan'] != null ? data['Jabatan']['nama_jabatan'] : '-';
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  String getTxt(String key) => _navText[_lang]![key] ?? key;

  @override
  Widget build(BuildContext context) {
    // List Layar yang akan ditampilkan
    final List<Widget> pages = [
      _buildHomeContent(),     // 0: Beranda
      ExploreScreen(lang: _lang),   // 1: Telusuri
      AnalyticsScreen(lang: _lang), // 2: Analitik
      RankingScreen(lang: _lang),   // 3: Peringkat
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER CUSTOM ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // KIRI: Logo
                  Image.asset('assets/images/logo.png', height: 40, errorBuilder: (c,e,s) => const Icon(Icons.shield, color: Colors.blue)),
                  
                  // TENGAH: Poin
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFFFF4E5), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        const Icon(Icons.stars, color: Colors.orange, size: 20),
                        const SizedBox(width: 5),
                        Text("$_userPoin Pts", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                      ],
                    ),
                  ),

                  // KANAN: Notifikasi & Profil
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none, color: Colors.black87),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationScreen(lang: _lang))),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(lang: _lang))).then((_) => _fetchUserData()); // Refresh saat kembali
                        },
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(_userName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                Text(_userRole, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(width: 8),
                            const CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0xFF00C9E4),
                              child: Icon(Icons.person, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
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
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home), label: getTxt('home')),
          BottomNavigationBarItem(icon: const Icon(Icons.explore_outlined), activeIcon: const Icon(Icons.explore), label: getTxt('explore')),
          BottomNavigationBarItem(icon: const Icon(Icons.bar_chart_outlined), activeIcon: const Icon(Icons.bar_chart), label: getTxt('analytics')),
          BottomNavigationBarItem(icon: const Icon(Icons.leaderboard_outlined), activeIcon: const Icon(Icons.leaderboard), label: getTxt('ranking')),
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
          Image.asset('assets/images/login_illustration.png', height: 150, errorBuilder: (c,e,s) => const Icon(Icons.image, size: 100)), 
          const SizedBox(height: 20),
          const Text("Welcome to Inspecta!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Make Your Discipline day!"),
        ],
      ),
    );
  }
}