import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'executive_verification_screen.dart';

// ============================================================
// VERIFICATION INTRO SCREEN
// Layar pengantar sebelum masuk ke halaman verifikasi.
// Menampilkan aturan & informasi verifikasi dalam bentuk
// slide animatif yang menarik.
//
// CARA PAKAI di home_content.dart:
//   onTap: () {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => VerificationIntroScreen(
//           lang: widget.lang,
//           userJabatanId: widget.userJabatanId,
//         ),
//       ),
//     );
//   },
// ============================================================

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

  // id_jabatan HRD — sesuaikan dengan data Anda
  static const int _hrdJabatanId = 5;

  bool get _isHrd => widget.userJabatanId == _hrdJabatanId;

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
      // Slide 2
      's2_title': 'Verifier Roles',
      's2_exec': 'Executive',
      's2_exec_desc': 'Reviews general findings & completions',
      's2_hrd': 'HRD',
      's2_hrd_desc': 'Verifies accident reports only',
      's2_verif': 'Verificator',
      's2_verif_desc': 'General verifier with voting rights',
      's2_note': '3 Verificators are assigned per finding',
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
          'Each verification must be completed within 5 minutes of starting. Make sure you read the finding carefully!',
      's5_timer': '5 Minutes',
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
      's2_title': 'Peran Verifier',
      's2_exec': 'Eksekutif',
      's2_exec_desc': 'Meninjau temuan & penyelesaian umum',
      's2_hrd': 'HRD',
      's2_hrd_desc': 'Memverifikasi laporan kecelakaan saja',
      's2_verif': 'Verificator',
      's2_verif_desc': 'Verifier umum dengan hak voting',
      's2_note': '3 Verificator ditugaskan per temuan',
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
          'Setiap verifikasi harus diselesaikan dalam 5 menit setelah dimulai. Pastikan Anda membaca temuan dengan teliti!',
      's5_timer': '5 Menit',
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
      's2_title': '验证员角色',
      's2_exec': '高管',
      's2_exec_desc': '审查一般发现和完成情况',
      's2_hrd': 'HRD',
      's2_hrd_desc': '仅验证事故报告',
      's2_verif': '验证员',
      's2_verif_desc': '具有投票权的一般验证员',
      's2_note': '每个发现分配3名验证员',
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
      's5_body': '每次验证必须在开始后5分钟内完成。请确保您仔细阅读发现内容！',
      's5_timer': '5分钟',
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
          onPointEarned: widget.onPointEarned, // TAMBAH INI
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
      backgroundColor: const Color(0xFFF0F7FF),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // ── Animated background ──
            _AnimatedBackground(controller: _bgAnimCtrl),

            // ── Main content ──
            SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(),

                  // Page view
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
                color: const Color(0xFF00C9E4).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF00C9E4).withOpacity(0.3), width: 1),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 16, color: Color(0xFF1E3A8A)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              t('title'),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E3A8A),
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
          // Page indicator dots
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
                      ? const Color(0xFF00C9E4)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Next / Start button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C9E4),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                shadowColor: const Color(0xFF00C9E4).withOpacity(0.4),
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

  // ══════════════════════════════════════════
  // SLIDE 1 — Apa itu Verifikasi?
  // MODIFIKASI: Tambah 2 kotak (Temuan & Penyelesaian)
  // ══════════════════════════════════════════
  Widget _buildSlide1() {
    return _SlideWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ilustrasi dua kotak: Temuan & Penyelesaian
          _FindingCompletionIllustration(
            findingLabel: t('s1_finding'),
            completionLabel: t('s1_completion'),
          ),
          const SizedBox(height: 28),
          _SlideTitle(t('s1_title')),
          const SizedBox(height: 14),
          _SlideBody(t('s1_body')),
          const SizedBox(height: 20),
          _InfoChip(
            icon: Icons.how_to_vote_rounded,
            label: t('s1_sub'),
            color: const Color(0xFF00C9E4),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // SLIDE 2 — Peran Verifier
  // ══════════════════════════════════════════
  Widget _buildSlide2() {
    return _SlideWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SlideTitle(t('s2_title')),
          const SizedBox(height: 24),

          // Kartu 3 peran
          _RoleCard(
            icon: Icons.workspace_premium_rounded,
            color: const Color(0xFF00C9E4),
            role: t('s2_exec'),
            desc: t('s2_exec_desc'),
          ),
          const SizedBox(height: 12),
          _RoleCard(
            icon: Icons.health_and_safety_rounded,
            color: const Color(0xFFFF6B6B),
            role: t('s2_hrd'),
            desc: t('s2_hrd_desc'),
          ),
          const SizedBox(height: 12),
          _RoleCard(
            icon: Icons.fact_check_rounded,
            color: const Color(0xFF4ADE80),
            role: t('s2_verif'),
            desc: t('s2_verif_desc'),
          ),
          const SizedBox(height: 20),

          // Note 3 verificator
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF4ADE80).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF4ADE80).withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.group_rounded,
                  color: Color(0xFF4ADE80), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('s2_note'),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF4ADE80),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // SLIDE 3 — Cara Voting
  // MODIFIKASI: Ganti VALID/INVALID → MAYORITAS/MINORITAS
  // dengan tampilan lebih jelas dan informatif
  // ══════════════════════════════════════════
  Widget _buildSlide3() {
    return _SlideWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SlideTitle(t('s3_title')),
          const SizedBox(height: 8),
          Text(
            widget.lang == 'ID'
                ? 'Hasil voting ditentukan oleh suara terbanyak'
                : widget.lang == 'ZH'
                    ? '投票结果由多数票决定'
                    : 'Voting outcome is determined by the majority',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),

          // Mayoritas card
          _VotingGroupCard(
            label: t('s3_majority'),
            desc: t('s3_majority_desc'),
            subLabel: t('s3_majority_sub'),
            color: const Color(0xFF059669),
            bgColor: const Color(0xFFECFDF5),
            borderColor: const Color(0xFF6EE7B7),
            icon: Icons.how_to_vote_rounded,
            filledCount: 4,
            totalCount: 6,
            isMajority: true,
          ),
          const SizedBox(height: 12),

          // VS divider
          Row(children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.grey.shade300],
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                'VS',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade500,
                  letterSpacing: 1,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade300, Colors.transparent],
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Minoritas card
          _VotingGroupCard(
            label: t('s3_minority'),
            desc: t('s3_minority_desc'),
            subLabel: t('s3_minority_sub'),
            color: const Color(0xFFDC2626),
            bgColor: const Color(0xFFFFF1F2),
            borderColor: const Color(0xFFFCA5A5),
            icon: Icons.remove_circle_outline_rounded,
            filledCount: 2,
            totalCount: 6,
            isMajority: false,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // SLIDE 4 — Poin & Penalti
  // MODIFIKASI: Tampilan lebih jelas & menarik
  // ══════════════════════════════════════════
  Widget _buildSlide4() {
    return _SlideWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ilustrasi poin yang lebih menarik
          _PointsIllustrationEnhanced(),
          const SizedBox(height: 24),
          _SlideTitle(t('s4_title')),
          const SizedBox(height: 6),
          Text(
            widget.lang == 'ID'
                ? 'Bergabunglah dengan mayoritas untuk mendapatkan poin'
                : widget.lang == 'ZH'
                    ? '加入多数派以获得积分'
                    : 'Join the majority to earn points',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),

          // Match — dapat poin (lebih besar & jelas)
          _PointCardEnhanced(
            icon: Icons.thumb_up_rounded,
            color: const Color(0xFF059669),
            bgColor: const Color(0xFFECFDF5),
            borderColor: const Color(0xFF6EE7B7),
            label: t('s4_match'),
            points: t('s4_match_pts'),
            isPositive: true,
          ),
          const SizedBox(height: 12),

          // Mismatch — penalti (lebih besar & jelas)
          _PointCardEnhanced(
            icon: Icons.thumb_down_rounded,
            color: const Color(0xFFDC2626),
            bgColor: const Color(0xFFFFF1F2),
            borderColor: const Color(0xFFFCA5A5),
            label: t('s4_mismatch'),
            points: t('s4_mismatch_pts'),
            isPositive: false,
          ),
          const SizedBox(height: 20),

          // Note dashboard
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF1E3A8A).withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.dashboard_rounded,
                    size: 16, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t('s4_note'),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w500,
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

  // ══════════════════════════════════════════
  // SLIDE 5 — Batas Waktu
  // MODIFIKASI: Timer animasi lebih menarik
  // ══════════════════════════════════════════
  Widget _buildSlide5() {
    return _SlideWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Timer animasi yang jauh lebih menarik
          _TimerIllustrationEnhanced(),
          const SizedBox(height: 24),
          _SlideTitle(t('s5_title')),
          const SizedBox(height: 14),
          _SlideBody(t('s5_body')),
          const SizedBox(height: 24),

          // Badge waktu utama — lebih menarik
          _AnimatedTimerBadge(
            timerLabel: t('s5_timer'),
            subLabel: t('s5_sub'),
            urgentLabel: t('s5_urgent'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ══════════════════════════════════════════════════════════════

/// Wrapper untuk setiap slide — padding konsisten
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
        color: const Color(0xFF1E3A8A),
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
        color: Colors.grey.shade600,
        height: 1.6,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// BARU: Ilustrasi 2 kotak Temuan & Penyelesaian (Slide 1)
// ══════════════════════════════════════════════════════════════
class _FindingCompletionIllustration extends StatefulWidget {
  final String findingLabel;
  final String completionLabel;
  const _FindingCompletionIllustration({
    required this.findingLabel,
    required this.completionLabel,
  });

  @override
  State<_FindingCompletionIllustration> createState() =>
      _FindingCompletionIllustrationState();
}

class _FindingCompletionIllustrationState
    extends State<_FindingCompletionIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -4, end: 4)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, __) {
        return SizedBox(
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Verifier avatars di bawah
              Positioned(
                bottom: 0,
                child: Row(
                  children: List.generate(6, (i) {
                    final colors = [
                      const Color(0xFF00C9E4),
                      const Color(0xFF4ADE80),
                      const Color(0xFF00C9E4),
                      const Color(0xFFFF6B6B),
                      const Color(0xFF4ADE80),
                      const Color(0xFF00C9E4),
                    ];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _VerifierAvatar(color: colors[i], size: 28),
                    );
                  }),
                ),
              ),

              // 2 Kotak: Temuan & Penyelesaian — mengambang
              Positioned(
                top: Transform.translate(
                  offset: Offset(0, _floatAnim.value),
                  child: const SizedBox(),
                ).hashCode.isEven ? 0 : 0,
                child: Transform.translate(
                  offset: Offset(0, _floatAnim.value),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Kotak Temuan
                      Container(
                        width: 120,
                        height: 68,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFE53E3E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B6B).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_rounded,
                                color: Colors.white70, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              widget.findingLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Panah connector
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C9E4).withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF00C9E4).withOpacity(0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Color(0xFF00C9E4),
                          ),
                        ),
                      ),

                      // Kotak Penyelesaian
                      Container(
                        width: 120,
                        height: 68,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4ADE80).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white70, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              widget.completionLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

// ══════════════════════════════════════════════════════════════
// BARU: Kartu Voting Mayoritas/Minoritas (Slide 3)
// Lebih jelas dan informatif dibanding versi lama
// ══════════════════════════════════════════════════════════════
class _VotingGroupCard extends StatelessWidget {
  final String label;
  final String desc;
  final String subLabel;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final IconData icon;
  final int filledCount;
  final int totalCount;
  final bool isMajority;

  const _VotingGroupCard({
    required this.label,
    required this.desc,
    required this.subLabel,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.icon,
    required this.filledCount,
    required this.totalCount,
    required this.isMajority,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Badge label
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Icon(icon, color: Colors.white, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ]),
              ),
              const Spacer(),
              // Persentase
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isMajority ? '≥ 50%' : '< 50%',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Voter icons bar
          Row(
            children: List.generate(totalCount, (i) {
              final bool active = i < filledCount;
              return Padding(
                padding: const EdgeInsets.only(right: 5),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200 + (i * 50)),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? color.withOpacity(0.15)
                        : Colors.grey.shade200,
                    border: Border.all(
                      color: active ? color : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 17,
                    color: active ? color : Colors.grey.shade400,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),

          // Deskripsi
          Text(
            desc,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: const Color(0xFF1E3A8A),
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),

          // Sub-label dengan icon
          Row(children: [
            Icon(
              isMajority
                  ? Icons.check_circle_rounded
                  : Icons.warning_amber_rounded,
              size: 13,
              color: color,
            ),
            const SizedBox(width: 5),
            Text(
              subLabel,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// BARU: Point card yang lebih jelas untuk Slide 4
// ══════════════════════════════════════════════════════════════
class _PointCardEnhanced extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final String label;
  final String points;
  final bool isPositive;

  const _PointCardEnhanced({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.label,
    required this.points,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isPositive ? 'Suara mayoritas' : 'Suara minoritas',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ]),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              points,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// BARU: Ilustrasi poin yang lebih menarik untuk Slide 4
// ══════════════════════════════════════════════════════════════
class _PointsIllustrationEnhanced extends StatefulWidget {
  @override
  State<_PointsIllustrationEnhanced> createState() =>
      _PointsIllustrationEnhancedState();
}

class _PointsIllustrationEnhancedState
    extends State<_PointsIllustrationEnhanced>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounce;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _bounce = Tween<double>(begin: -6, end: 6)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _scale = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _bounce.value),
        child: Transform.scale(
          scale: _scale.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow ring luar
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00C9E4).withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Ring tengah
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00C9E4).withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              // Main circle
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C9E4), Color(0xFF0891B2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C9E4).withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    color: Colors.white, size: 40),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// BARU: Timer illustration yang jauh lebih menarik (Slide 5)
// ══════════════════════════════════════════════════════════════
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
  int _displaySeconds = 300; // 5 menit simulasi
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

    // Simulasi countdown untuk ilustrasi
    _demoTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_displaySeconds > 0) _displaySeconds--;
        else _displaySeconds = 300;
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
    final double progress = _displaySeconds / 300.0;
    final bool isUrgent = _displaySeconds <= 60;
    final Color mainColor =
        isUrgent ? const Color(0xFFDC2626) : const Color(0xFF00C9E4);

    return AnimatedBuilder(
      animation: Listenable.merge([_rotCtrl, _pulseCtrl]),
      builder: (_, __) {
        return SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outermost glow
              Transform.scale(
                scale: _pulse.value,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        mainColor.withOpacity(0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Outer ring background
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: mainColor.withOpacity(0.06),
                  border: Border.all(
                      color: mainColor.withOpacity(0.15), width: 2),
                ),
              ),

              // Progress arc (spinning)
              Transform.rotate(
                angle: _rotCtrl.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(140, 140),
                  painter: _ArcPainter(
                    color: mainColor.withOpacity(0.35),
                    strokeWidth: 3,
                    sweepAngle: math.pi * 0.8,
                  ),
                ),
              ),

              // Progress arc (progress-based, static)
              CustomPaint(
                size: const Size(130, 130),
                painter: _ProgressArcPainter(
                  color: mainColor,
                  strokeWidth: 5,
                  progress: progress,
                ),
              ),

              // Inner circle
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      mainColor.withOpacity(0.9),
                      mainColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: mainColor.withOpacity(0.5),
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

              // Tanda urgent (berkedip) jika <=60 detik
              if (isUrgent)
                Positioned(
                  top: 8,
                  right: 8,
                  child: AnimatedOpacity(
                    opacity: _pulse.value > 1.04 ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 300),
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

// ══════════════════════════════════════════════════════════════
// BARU: Badge waktu animatif untuk Slide 5
// ══════════════════════════════════════════════════════════════
class _AnimatedTimerBadge extends StatefulWidget {
  final String timerLabel;
  final String subLabel;
  final String urgentLabel;

  const _AnimatedTimerBadge({
    required this.timerLabel,
    required this.subLabel,
    required this.urgentLabel,
  });

  @override
  State<_AnimatedTimerBadge> createState() => _AnimatedTimerBadgeState();
}

class _AnimatedTimerBadgeState extends State<_AnimatedTimerBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _shimmer = Tween<double>(begin: -1.0, end: 2.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0891B2), Color(0xFF00C9E4), Color(0xFF0E7490)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C9E4).withOpacity(0.45),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Shimmer overlay
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        begin: Alignment(_shimmer.value - 1, 0),
                        end: Alignment(_shimmer.value, 0),
                        colors: [
                          Colors.white.withOpacity(0),
                          Colors.white.withOpacity(0.12),
                          Colors.white.withOpacity(0),
                        ],
                      ).createShader(bounds);
                    },
                    child: Container(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Content
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer_rounded,
                          color: Colors.white70, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        widget.timerLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Progress bar demo
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          widget.urgentLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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
}

// ══════════════════════════════════════════════════════════════
// EXISTING WIDGETS (tidak diubah)
// ══════════════════════════════════════════════════════════════

/// Kartu peran verifier di slide 2
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String role;
  final String desc;
  const _RoleCard(
      {required this.icon,
      required this.color,
      required this.role,
      required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                Text(
                  desc,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 13, color: color.withOpacity(0.5)),
        ],
      ),
    );
  }
}

/// Avatar verifier kecil
class _VerifierAvatar extends StatelessWidget {
  final Color color;
  final double size;
  const _VerifierAvatar({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Icon(Icons.person_rounded, size: size * 0.55, color: color),
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

// BARU: Progress arc painter untuk timer ilustrasi
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
    // Background arc
    final bgPaint = Paint()
      ..color = color.withOpacity(0.15)
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

/// Animated gradient background
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
                      const Color(0xFF00C9E4).withOpacity(0.12),
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
                      const Color(0xFF1E3A8A).withOpacity(0.07),
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
                      const Color(0xFF0891B2).withOpacity(0.06 * (1 - t)),
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