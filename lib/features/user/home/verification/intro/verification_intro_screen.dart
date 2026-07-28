import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../executive_verification_screen.dart';
import 'verification_intro_first.dart';
import 'verification_intro_fourth.dart';
import 'verification_intro_second.dart';
import 'verification_intro_third.dart';

class VerificationIntroScreen extends StatefulWidget {
  final String lang;
  final int? userJabatanId;
  final Function(int)? onPointEarned;

  const VerificationIntroScreen({
    super.key,
    required this.lang,
    this.userJabatanId,
    this.onPointEarned,
  });

  @override
  State<VerificationIntroScreen> createState() =>
      _VerificationIntroScreenState();
}

class _VerificationIntroScreenState extends State<VerificationIntroScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _bgAnimCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const Map<String, Map<String, String>> _txt = {
    'EN': {
      'title': 'Verification Rules',
      'next': 'Next',
      'start': 'Start Verifying',
      'skip': 'Skip',
      // Slide 1
      's1_title': 'What is Verification?',
      's1_body':
          'Verification is a feature designed to maintain the integrity of findings through a democratic voting system.',
      's1_sub': 'Every finding is reviewed by multiple verifiers',
      's1_finding': 'Finding',
      's1_completion': 'Completion',
      // Slide 3
      's3_title': 'How Voting Works',
      's3_majority': 'MAJORITY',
      's3_majority_desc': 'The majority vote determines the final result (Valid/Invalid)',
      's3_minority': 'MINORITY',
      's3_minority_desc': 'The minority vote receives a -5 point penalty',
      's3_majority_sub': 'Determines final outcome',
      's3_minority_sub': 'Gets -5 point penalty',
      // Slide 4
      's4_title': 'Points & Penalty',
      's4_match': 'Vote matches the majority',
      's4_match_pts': '+10 Points',
      's4_mismatch': 'Vote is in the minority',
      's4_mismatch_pts': '-5 Points',
      's4_note': 'Results can be seen in the Mountain dashboard',
      // Slide 5
      's5_title': 'Time Limit',
      's5_body':
          'Each verification must be completed within 2 minutes of starting. Make sure you read the finding carefully!',
      's5_timer': '2 Minutes',
      's5_sub': 'Per verification session',
      's5_urgent': 'Stay focused!',
    },
    'ID': {
      'title': 'Peraturan Verifikasi',
      'next': 'Lanjut',
      'start': 'Mulai Verifikasi',
      'skip': 'Lewati',
      's1_title': 'Apa itu Verifikasi?',
      's1_body':
          'Verifikasi adalah fitur yang bertujuan menjaga integritas temuan melalui sistem voting demokratis.',
      's1_sub': 'Setiap temuan ditinjau oleh beberapa verifier',
      's1_finding': 'Temuan',
      's1_completion': 'Penyelesaian',
      's3_title': 'Cara Voting',
      's3_majority': 'MAYORITAS',
      's3_majority_desc': 'Suara mayoritas menentukan hasil akhir (Valid/Tidak Valid)',
      's3_minority': 'MINORITAS',
      's3_minority_desc': 'Suara minoritas mendapat penalti -5 poin',
      's3_majority_sub': 'Menentukan hasil akhir',
      's3_minority_sub': 'Mendapat penalti -5 poin',
      's4_title': 'Poin & Penalti',
      's4_match': 'Suara masuk mayoritas',
      's4_match_pts': '+10 Poin',
      's4_mismatch': 'Suara masuk minoritas',
      's4_mismatch_pts': '-5 Poin',
      's4_note': 'Hasil dapat dilihat di dashboard The Mountain',
      's5_title': 'Batas Waktu',
      's5_body':
          'Setiap verifikasi harus diselesaikan dalam 2 menit setelah dimulai. Pastikan Anda membaca temuan dengan teliti!',
      's5_timer': '2 Menit',
      's5_sub': 'Per sesi verifikasi',
      's5_urgent': 'Tetap fokus!',
    },
    'ZH': {
      'title': '验证规则',
      'next': '下一步',
      'start': '开始验证',
      'skip': '跳过',
      's1_title': '什么是验证？',
      's1_body': '验证是一项旨在通过民主投票系统维护发现完整性的功能。',
      's1_sub': '每个发现由多个验证员审查',
      's1_finding': '发现',
      's1_completion': '完成',
      's3_title': '投票方式',
      's3_majority': '多数',
      's3_majority_desc': '多数票决定最终结果（有效/无效）',
      's3_minority': '少数',
      's3_minority_desc': '少数票将受到-5积分的惩罚',
      's3_majority_sub': '决定最终结果',
      's3_minority_sub': '获得-5积分惩罚',
      's4_title': '积分与惩罚',
      's4_match': '投票属于多数',
      's4_match_pts': '+10积分',
      's4_mismatch': '投票属于少数',
      's4_mismatch_pts': '-5积分',
      's4_note': '结果可在The Mountain仪表板上查看',
      's5_title': '时间限制',
      's5_body': '每次验证必须在开始后2分钟内完成。请确保您仔细阅读发现内容！',
      's5_timer': '2分钟',
      's5_sub': '每次验证会话',
      's5_urgent': '保持专注！',
    },
  };

  String t(String key) => _txt[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _bgAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgAnimCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToVerification();
    }
  }

  void _goToVerification() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ExecVerificationScreen(
          lang: widget.lang,
          userJabatanId: widget.userJabatanId,
          onPointEarned: widget.onPointEarned,
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // ANIMATED BACKGROUND
            _AnimatedBackground(controller: _bgAnimCtrl),

            // MAIN CONTENT
            SafeArea(
              child: Column(
                children: [
                  // HEADER
                  _buildHeader(),

                  // PAGE VIEW
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (i) =>
                          setState(() => _currentPage = i),
                      children: [
                        _buildSlide1(),
                        _buildSlide2(),
                        _buildSlide3(),
                        _buildSlide4(),
                        _buildSlide5(),
                      ],
                    ),
                  ),

                  // Bottom controls
                  _buildBottomControls(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFF1D72F3).withValues(alpha:0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF1D72F3).withValues(alpha:0.3), width: 1),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 16, color: Color(0xFF1D72F3)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              t('title'),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1D72F3),
                letterSpacing: 0.3,
              ),
            ),
          ),
          GestureDetector(
            onTap: _goToVerification,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.grey.shade300, width: 1),
              ),
              child: Text(
                t('skip'),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
          // PAGE INDICATORS DOT
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final bool isActive = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isActive
                    ? const Color(0xFF1D72F3)
                    : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // NEXT / START BUTTON
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D72F3),
                foregroundColor: Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                shadowColor: const Color(0xFF1D72F3).withValues(alpha:0.45),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentPage == 4 ? t('start') : t('next'),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _currentPage == 4
                        ? Icons.verified_rounded
                        : Icons.arrow_forward_rounded,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide1() {
    return _SlideWrapper(
      child: VerificationIntroFirstSlide(lang: widget.lang),
    );
  }

  Widget _buildSlide2() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: VerifierRolesSlide(lang: widget.lang),
    );
  }

  Widget _buildSlide3() {
    return _SlideWrapper(
      child: VerificationIntroThirdSlide(lang: widget.lang),
    );
  }

  Widget _buildSlide4() {
    return _SlideWrapper(
      child: VerificationIntroFourthSlide(lang: widget.lang),
    );
  }

  Widget _buildSlide5() {
    return _SlideWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _TimerIllustrationEnhanced(),
          const SizedBox(height: 24),
          _SlideTitle(t('s5_title')),
          const SizedBox(height: 14),
          _SlideBody(t('s5_body')),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SlideWrapper extends StatelessWidget {
  final Widget child;
  const _SlideWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: child,
    );
  }
}

class _SlideTitle extends StatelessWidget {
  final String text;
  const _SlideTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF1D72F3),
        height: 1.2,
      ),
    );
  }
}

class _SlideBody extends StatelessWidget {
  final String text;
  const _SlideBody(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
        height: 1.6,
      ),
    );
  }
}

class _TimerIllustrationEnhanced extends StatefulWidget {
  @override
  State<_TimerIllustrationEnhanced> createState() =>
      _TimerIllustrationEnhancedState();
}

class _TimerIllustrationEnhancedState
    extends State<_TimerIllustrationEnhanced>
    with TickerProviderStateMixin {
  late AnimationController _rotCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  int _displaySeconds = 120;
  Timer? _demoTimer;

  @override
  void initState() {
    super.initState();
    _rotCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _demoTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_displaySeconds > 0) { _displaySeconds--; }
        else { _displaySeconds = 120; }
      });
    });
  }

  @override
  void dispose() {
    _rotCtrl.dispose();
    _pulseCtrl.dispose();
    _demoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int minutes = _displaySeconds ~/ 60;
    final int seconds = _displaySeconds % 60;
    final double progress = _displaySeconds / 120.0;
    final bool isUrgent = _displaySeconds <= 60;
    final Color mainColor =
        isUrgent ? const Color(0xFFDC2626) : const Color(0xFF1D72F3);

    return AnimatedBuilder(
      animation: Listenable.merge([_rotCtrl, _pulseCtrl]),
      builder: (_, __) {
        return SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // OUTERMOST GLOW
              Transform.scale(
                scale: _pulse.value,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        mainColor.withValues(alpha:0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // OUTER RING BACKGROUND
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: mainColor.withValues(alpha:0.06),
                  border: Border.all(
                      color: mainColor.withValues(alpha:0.15), width: 2),
                ),
              ),

              // PROGRESS ARC (SPINNING)
              Transform.rotate(
                angle: _rotCtrl.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(140, 140),
                  painter: _ArcPainter(
                    color: mainColor.withValues(alpha:0.35),
                    strokeWidth: 3,
                    sweepAngle: math.pi * 0.8,
                  ),
                ),
              ),

              // PROGRESS ARC (PROGRESS-BASED, STATIC)
              CustomPaint(
                size: const Size(130, 130),
                painter: _ProgressArcPainter(
                  color: mainColor,
                  strokeWidth: 5,
                  progress: progress,
                ),
              ),

              // INNER CIRCLE
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      mainColor.withValues(alpha:0.9),
                      mainColor.withValues(alpha:0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: mainColor.withValues(alpha:0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_rounded,
                        color: Colors.white, size: 28),
                    const SizedBox(height: 2),
                    Text(
                      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              if (isUrgent)
                Positioned(
                  top: 8,
                  right: 8,
                  child: AnimatedOpacity(
                    opacity: _pulse.value > 1.04 ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 120),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.priority_high_rounded,
                          color: Colors.white, size: 12),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double sweepAngle;
  const _ArcPainter(
      {required this.color,
      required this.strokeWidth,
      required this.sweepAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth);
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProgressArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double progress;

  const _ProgressArcPainter({
    required this.color,
    required this.strokeWidth,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // BACKGROUND ARC
    final bgPaint = Paint()
      ..color = color.withValues(alpha:0.15)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, bgPaint);

    // Progress arc
    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
        rect, -math.pi / 2, 2 * math.pi * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressArcPainter old) =>
      old.progress != progress || old.color != color;
}

class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return Stack(
          children: [
            Positioned(
              top: -80 + (t * 40),
              left: -60 + (t * 30),
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF1D72F3).withValues(alpha:0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100 + (t * 50),
              right: -80 + (t * 40),
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF1E3A8A).withValues(alpha:0.07),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.35,
              left: MediaQuery.of(context).size.width * 0.5 - 100,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF0891B2).withValues(alpha:0.06 * (1 - t)),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}