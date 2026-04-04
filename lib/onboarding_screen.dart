import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedLanguage = 'EN';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Memulai timer untuk auto scroll setiap 5 detik
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < 3) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeIn,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Hentikan timer saat widget dihancurkan
    _pageController.dispose();
    super.dispose();
  }

  // --- Teks Multi-Bahasa untuk Onboarding ---
  final Map<String, Map<String, String>> _onboardingText = {
    'EN': {
      'title1': 'Welcome to Inspecta',
      'desc1': 'Monitor, report, and resolve issues with discipline and efficiency.',
      'title2': 'Real-time Analytics',
      'desc2': 'Get instant insights with our advanced analytics dashboard.',
      'title3': 'Climb the Ranks',
      'desc3': 'Earn points for every task and see your name on the leaderboard.',
      'title4': 'Celebrate Achievements',
      'desc4': 'Unlock rewards and celebrate milestones with your team.',
      'get_started': 'Get Started',
      'skip': 'Skip'
    },
    'ID': {
      'title1': 'Selamat Datang di Inspecta',
      'desc1': 'Pantau, laporkan, dan selesaikan masalah dengan disiplin dan efisien.',
      'title2': 'Analitik Real-time',
      'desc2': 'Dapatkan wawasan instan dengan dasbor analitik canggih kami.',
      'title3': 'Naiki Peringkat',
      'desc3': 'Dapatkan poin untuk setiap tugas dan lihat nama Anda di papan peringkat.',
      'title4': 'Rayakan Pencapaian',
      'desc4': 'Buka hadiah dan rayakan pencapaian bersama tim Anda.',
      'get_started': 'Mulai',
      'skip': 'Lewati'
    },
    'ZH': {
      'title1': '欢迎来到 Inspecta',
      'desc1': '有纪律、高效率地监控、报告和解决问题。',
      'title2': '实时分析',
      'desc2': '通过我们先进的分析仪表板即时获取洞察。',
      'title3': '攀登排行榜',
      'desc3': '每项任务都能获得积分，并在排行榜上看到您的名字。',
      'title4': '庆祝成就',
      'desc4': '解锁奖励，与团队一起庆祝里程碑。',
      'get_started': '开始使用',
      'skip': '跳过'
    },
  };

  String getTxt(String key) => _onboardingText[_selectedLanguage]![key] ?? key;

  // Data untuk setiap halaman onboarding
  List<Widget> _buildPages() {
    return [
      _buildPage(
        imagePath: 'assets/images/onboarding1.png',
        title: getTxt('title1'),
        description: getTxt('desc1'),
      ),
      _buildPage(
        imagePath: 'assets/images/onboarding2.png',
        title: getTxt('title2'),
        description: getTxt('desc2'),
      ),
      _buildPage(
        imagePath: 'assets/images/onboarding3.png',
        title: getTxt('title3'),
        description: getTxt('desc3'),
      ),
      _buildPage(
        imagePath: 'assets/images/onboarding4.png',
        title: getTxt('title4'),
        description: getTxt('desc4'),
      ),
    ];
  }

  void _navigateToLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    await prefs.setString('lang', _selectedLanguage);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // --- Tombol Skip & Dropdown Bahasa ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Container(
                      height: 35,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 10)],
                      ),
                      child: DropdownButton<String>(
                        value: _selectedLanguage,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.black87),
                        items: const [
                          DropdownMenuItem(value: 'EN', child: Text('🇬🇧 English')),
                          DropdownMenuItem(value: 'ID', child: Text('🇮🇩 Indonesia')),
                          DropdownMenuItem(value: 'ZH', child: Text('🇨🇳 中文')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedLanguage = value!;
                          });
                        },
                      ),
                    ),
                  TextButton(
                    onPressed: _navigateToLogin,
                    child: Text(
                      getTxt('skip'),
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            // --- Konten Halaman Scroll ---
            Expanded(
              flex: 3,
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: _buildPages(),
              ),
            ),
            // --- Dot Indicator & Tombol ---
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Dot Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) => _buildDot(index: index)),
                    ),
                    const Spacer(),
                    // Tombol Get Started
                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF00C9E4),
                            Color(0xFF42E27A),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF42E27A).withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: _navigateToLogin,
                        child: Text(
                          getTxt('get_started'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk membuat satu halaman onboarding
  Widget _buildPage({required String imagePath, required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 250, errorBuilder: (c,e,s) => const Icon(Icons.image, size: 200, color: Colors.grey)),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 15),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }

  // Widget untuk membuat dot indicator
  Widget _buildDot({required int index}) {
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 8),
        height: 8,
        width: _currentPage == index ? 24 : 8,
        decoration: BoxDecoration(
          color: _currentPage == index ? const Color(0xFF00C9E4) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }
}