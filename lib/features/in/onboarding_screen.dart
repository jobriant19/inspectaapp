import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class _OnboardingSlide {
  final String? imageUrl;
  final String? assetPath;
  final Map<String, String> title;
  final Map<String, String> desc;
  final int sortOrder;

  const _OnboardingSlide({
    this.imageUrl,
    this.assetPath,
    required this.title,
    required this.desc,
    this.sortOrder = 0,
  });

  factory _OnboardingSlide.fromDb(Map<String, dynamic> row) {
    return _OnboardingSlide(
      imageUrl: row['image_url'] as String?,
      title: {
        'id': (row['title_id'] ?? '').toString(),
        'en': (row['title_en'] ?? '').toString(),
        'zh': (row['title_zh'] ?? '').toString(),
      },
      desc: {
        'id': (row['description_id'] ?? '').toString(),
        'en': (row['description_en'] ?? '').toString(),
        'zh': (row['description_zh'] ?? '').toString(),
      },
      sortOrder: (row['sort_order'] as int?) ?? 0,
    );
  }
}

const List<_OnboardingSlide> _kDefaultSlides = [
  _OnboardingSlide(
    assetPath: 'assets/images/onboarding1.png',
    title: {
      'id': 'Selamat Datang di Inspecta',
      'en': 'Welcome to Inspecta',
      'zh': '欢迎来到 Inspecta',
    },
    desc: {
      'id': 'Pantau, laporkan, dan selesaikan masalah dengan disiplin dan efisien.',
      'en': 'Monitor, report, and resolve issues with discipline and efficiency.',
      'zh': '有纪律、高效率地监控、报告和解决问题。',
    },
  ),
  _OnboardingSlide(
    assetPath: 'assets/images/onboarding2.png',
    title: {
      'id': 'Analitik Real-time',
      'en': 'Real-time Analytics',
      'zh': '实时分析',
    },
    desc: {
      'id': 'Dapatkan wawasan instan dengan dasbor analitik canggih kami.',
      'en': 'Get instant insights with our advanced analytics dashboard.',
      'zh': '通过我们先进的分析仪表板即时获取洞察。',
    },
  ),
  _OnboardingSlide(
    assetPath: 'assets/images/onboarding3.png',
    title: {
      'id': 'Naiki Peringkat',
      'en': 'Climb the Ranks',
      'zh': '攀登排行榜',
    },
    desc: {
      'id': 'Dapatkan poin untuk setiap tugas dan lihat nama Anda di papan peringkat.',
      'en': 'Earn points for every task and see your name on the leaderboard.',
      'zh': '每项任务都能获得积分，并在排行榜上看到您的名字。',
    },
  ),
  _OnboardingSlide(
    assetPath: 'assets/images/onboarding4.png',
    title: {
      'id': 'Rayakan Pencapaian',
      'en': 'Celebrate Achievements',
      'zh': '庆祝成就',
    },
    desc: {
      'id': 'Buka hadiah dan rayakan pencapaian bersama tim Anda.',
      'en': 'Unlock rewards and celebrate milestones with your team.',
      'zh': '解锁奖励，与团队一起庆祝里程碑。',
    },
  ),
];

class OnboardingScreen extends StatefulWidget {
  final String? initialAppName;
  final String? initialAppLogoUrl;
  final String? initialTaglineId;
  final String? initialTaglineEn;
  final String? initialTaglineZh;
  final List<Map<String, dynamic>>? initialSlides;

  const OnboardingScreen({
    super.key,
    this.initialAppName,
    this.initialAppLogoUrl,
    this.initialTaglineId,
    this.initialTaglineEn,
    this.initialTaglineZh,
    this.initialSlides,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedLanguage = 'EN';
  Timer? _timer;

  bool _isDialogOpen = false;

  late List<_OnboardingSlide> _slides;

  @override
  void initState() {
    super.initState();
    _slides = (widget.initialSlides != null && widget.initialSlides!.isNotEmpty)
        ? (widget.initialSlides!.map((e) => _OnboardingSlide.fromDb(e)).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)))
        : List.of(_kDefaultSlides);
    _startAutoSlideTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _warmUpAssets());
  }

  Future<void> _warmUpAssets() async {
    if (!mounted) return;
    final futures = <Future<void>>[];
    for (final s in _slides) {
      if (s.assetPath != null) {
        futures.add(precacheImage(AssetImage(s.assetPath!), context).catchError((_) {}));
      } else if (s.imageUrl != null && s.imageUrl!.isNotEmpty) {
        futures.add(precacheImage(CachedNetworkImageProvider(s.imageUrl!), context).catchError((_) {}));
      }
    }
    await Future.wait(futures);
  }

  void _startAutoSlideTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (!mounted || !_pageController.hasClients || _isDialogOpen) {
        return;
      }
      try {
        final int actualPage = _pageController.page?.round() ?? _currentPage;
        final int lastIndex = _slides.length - 1;
        final int nextPage = actualPage < lastIndex ? actualPage + 1 : 0;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeIn,
        );
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  static const Map<String, Map<String, String>> _uiText = {
    'EN': {
      'get_started': 'Get Started',
      'skip': 'Skip',
      'next': 'Next',
      'select_language': 'Select Language',
    },
    'ID': {
      'get_started': 'Mulai',
      'skip': 'Lewati',
      'next': 'Berikutnya',
      'select_language': 'Pilih Bahasa',
    },
    'ZH': {
      'get_started': '开始使用',
      'skip': '跳过',
      'next': '下一步',
      'select_language': '选择语言',
    },
  };

  static const Map<String, Map<String, String>> _permissionText = {
    'EN': {
      'location_title': 'Allow Location Access',
      'location_desc':
          'Inspecta uses your location to verify you are at PT ATMI Solo before creating findings or resolutions.',
      'camera_title': 'Allow Camera Access',
      'camera_desc':
          'Inspecta uses your camera to capture photo evidence for findings and resolutions.',
      'allow': 'Allow',
      'not_now': 'Not Now',
    },
    'ID': {
      'location_title': 'Izinkan Akses Lokasi',
      'location_desc':
          'Inspecta menggunakan lokasi Anda untuk memverifikasi bahwa Anda berada di PT ATMI Solo sebelum membuat temuan atau penyelesaian.',
      'camera_title': 'Izinkan Akses Kamera',
      'camera_desc':
          'Inspecta menggunakan kamera Anda untuk mengambil foto bukti temuan dan penyelesaian.',
      'allow': 'Izinkan',
      'not_now': 'Nanti Saja',
    },
    'ZH': {
      'location_title': '允许访问位置',
      'location_desc': 'Inspecta 使用您的位置信息，在创建发现或解决方案之前验证您是否在PT ATMI Solo。',
      'camera_title': '允许访问相机',
      'camera_desc': 'Inspecta 使用您的相机拍摄发现和解决方案的照片证据。',
      'allow': '允许',
      'not_now': '暂不',
    },
  };

  String _permTxt(String key) =>
      _permissionText[_selectedLanguage]?[key] ?? _permissionText['EN']![key]!;

  TextStyle _localizedStyle({
    required double fontSize,
    required FontWeight fontWeight,
    Color? color,
    double? height,
  }) {
    if (_selectedLanguage == 'ZH') {
      return GoogleFonts.notoSansSc(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );
    }
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  String getTxt(String key) => _uiText[_selectedLanguage]?[key] ?? _uiText['EN']![key]!;

  List<Widget> _buildPages() {
    final langKey = _selectedLanguage.toLowerCase();
    return List.generate(_slides.length, (i) {
      final s = _slides[i];
      return _buildPage(
        imageUrl: s.imageUrl,
        assetPath: s.assetPath,
        title: s.title[langKey] ?? s.title['en'] ?? '',
        description: s.desc[langKey] ?? s.desc['en'] ?? '',
        isFirst: i == 0,
      );
    });
  }

  void _navigateToLogin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    await prefs.setString('lang', _selectedLanguage);

    if (!mounted) return;

    await _requestLocationWithRationale();

    if (!mounted) return;

    await _requestCameraWithRationale();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            initialLang: _selectedLanguage,
            initialAppName: widget.initialAppName,
            initialAppLogoUrl: widget.initialAppLogoUrl,
            initialTaglineId: widget.initialTaglineId,
            initialTaglineEn: widget.initialTaglineEn,
            initialTaglineZh: widget.initialTaglineZh,
          ),
        ),
      );
    }
  }

  Future<void> _requestLocationWithRationale() async {
    final Completer<void> completer = Completer<void>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildPermissionDialog(
        ctx: ctx,
        icon: Icons.location_on_rounded,
        iconBackgroundColor: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF1D72F3),
        title: _permTxt('location_title'),
        description: _permTxt('location_desc'),
        buttonLabel: _permTxt('allow'),
        skipLabel: _permTxt('not_now'),
        onAllow: () async {
          Navigator.of(ctx).pop();
          try {
            await Permission.location.request();
          } catch (_) {}
          if (!completer.isCompleted) completer.complete();
        },
        onSkip: () {
          Navigator.of(ctx).pop();
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );

    return completer.future;
  }

  Future<void> _requestCameraWithRationale() async {
    final Completer<void> completer = Completer<void>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildPermissionDialog(
        ctx: ctx,
        icon: Icons.camera_alt_rounded,
        iconBackgroundColor: const Color(0xFFE0F7FA),
        iconColor: const Color(0xFF00ACC1),
        title: _permTxt('camera_title'),
        description: _permTxt('camera_desc'),
        buttonLabel: _permTxt('allow'),
        skipLabel: _permTxt('not_now'),
        onAllow: () async {
          Navigator.of(ctx).pop();
          try {
            await Permission.camera.request();
          } catch (_) {}
          if (!completer.isCompleted) completer.complete();
        },
        onSkip: () {
          Navigator.of(ctx).pop();
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );

    return completer.future;
  }

  Widget _buildPermissionDialog({
    required BuildContext ctx,
    required IconData icon,
    required Color iconBackgroundColor,
    required Color iconColor,
    required String title,
    required String description,
    required String buttonLabel,
    required String skipLabel,
    required VoidCallback onAllow,
    required VoidCallback onSkip,
  }) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 38),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: _localizedStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: _localizedStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAllow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  buttonLabel,
                  style: _localizedStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onSkip,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  skipLabel,
                  style: _localizedStyle(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF64748B)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.0,
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: OverflowBox(
                    minWidth: 0,
                    minHeight: 0,
                    maxWidth: 500,
                    maxHeight: 500,
                    alignment: Alignment.topLeft,
                    child: Wrap(
                      children: const [
                        Text('🇺🇸🇮🇩🇨🇳', style: TextStyle(fontSize: 22)),
                        Text('🇺🇸🇮🇩🇨🇳', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _showLanguagePicker(),
                    child: _buildLangButton(),
                  ),
                  TextButton(
                    onPressed: _navigateToLogin,
                    child: Text(
                      getTxt('skip'),
                      style: _localizedStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: RepaintBoundary(
                child: PageView(
                  controller: _pageController,
                  allowImplicitScrolling: true,
                  onPageChanged: (int page) {
                    _currentPage = page;
                  },
                  children: _buildPages(),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, _) {
                    final int page = _pageController.hasClients
                        ? (_pageController.page?.round() ?? _currentPage)
                        : _currentPage;
                    final int lastIndex = _slides.length - 1;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _slides.length,
                            (index) => _buildDot(index: index, currentPage: page),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: double.infinity,
                          height: 55,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: const Color(0xFF1D72F3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1D72F3).withValues(alpha:0.4),
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
                            onPressed: () {
                              if (page == lastIndex) {
                                _navigateToLogin();
                              } else {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            child: Text(
                              page == lastIndex ? getTxt('get_started') : getTxt('next'),
                              style: _localizedStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
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

  Widget _buildPage({
    String? imageUrl,
    String? assetPath,
    required String title,
    required String description,
    bool isFirst = false,
  }) {
    final double imgHeight = isFirst ? 300 : 250;
    final Widget image = (imageUrl != null && imageUrl.isNotEmpty)
        ? CachedNetworkImage(
            imageUrl: imageUrl,
            height: imgHeight,
            fit: BoxFit.contain,
            placeholder: (c, u) => SizedBox(height: imgHeight),
            errorWidget: (c, u, e) => Icon(Icons.image, size: imgHeight * 0.8, color: Colors.grey),
          )
        : Image.asset(
            assetPath ?? 'assets/images/onboarding1.png',
            height: imgHeight,
            errorBuilder: (c, e, s) => Icon(Icons.image, size: imgHeight * 0.8, color: Colors.grey),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          image,
          SizedBox(height: isFirst ? 28 : 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: _localizedStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          const SizedBox(height: 15),
          Text(
            description,
            textAlign: TextAlign.center,
            style: _localizedStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDot({required int index, required int currentPage}) {
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
        width: currentPage == index ? 24 : 8,
        decoration: BoxDecoration(
          color: currentPage == index ? const Color(0xFF1D72F3) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }

  void _showLanguagePicker() async {
    if (_isDialogOpen) return;
    _isDialogOpen = true;
    _timer?.cancel();

    const langs = [
      {'code': 'EN', 'flag': '🇺🇸', 'label': 'English'},
      {'code': 'ID', 'flag': '🇮🇩', 'label': 'Indonesia'},
      {'code': 'ZH', 'flag': '🇨🇳', 'label': '中文'},
    ];
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D72F3).withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        getTxt('select_language'),
                        style: _localizedStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: const Color(0xFF1D72F3),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF1D72F3)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  children: langs.map((l) {
                    final isSelected = _selectedLanguage == l['code'];
                    return GestureDetector(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('lang', l['code']!);
                        if (mounted) setState(() => _selectedLanguage = l['code']!);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1D72F3).withValues(alpha: 0.08)
                              : const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1D72F3)
                                : const Color(0xFFE0E7FF),
                            width: isSelected ? 1.6 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE0E7FF)),
                              ),
                              child: Text(l['flag']!, style: const TextStyle(fontSize: 22)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                l['label']!,
                                style: _localizedStyle(
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  fontSize: 15,
                                  color: isSelected
                                      ? const Color(0xFF1D72F3)
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF1D72F3), size: 20),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    _isDialogOpen = false;
    if (mounted) _startAutoSlideTimer();
  }

  Widget _buildLangButton() {
    const flagMap = {'EN': '🇺🇸', 'ID': '🇮🇩', 'ZH': '🇨🇳'};
    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1D72F3).withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D72F3).withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(flagMap[_selectedLanguage] ?? '🇺🇸', style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            _selectedLanguage,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D72F3),
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF1D72F3)),
        ],
      ),
    );
  }
}