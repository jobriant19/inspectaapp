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

  const VerificationIntroScreen({
    super.key,
    required this.lang,
    this.userJabatanId,
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
      's3_valid': 'VALID',
      's3_valid_desc': 'The majority vote determines the final result (Valid/Invalid)',
      's3_invalid': 'INVALID',
      's3_invalid_desc': 'The minority vote receives a -5 point penalty',
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
      's2_title': 'Peran Verifier',
      's2_exec': 'Eksekutif',
      's2_exec_desc': 'Meninjau temuan & penyelesaian umum',
      's2_hrd': 'HRD',
      's2_hrd_desc': 'Memverifikasi laporan kecelakaan saja',
      's2_verif': 'Verificator',
      's2_verif_desc': 'Verifier umum dengan hak voting',
      's2_note': '3 Verificator ditugaskan per temuan',
      's3_title': 'Cara Voting',
      's3_valid': 'VALID',
      's3_valid_desc': 'Suara mayoritas menentukan hasil akhir (Valid/Tidak Valid)',
      's3_invalid': 'TIDAK VALID',
      's3_invalid_desc': 'Suara minoritas mendapat penalti -5 poin',
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
    },
    'ZH': {
      'title': '验证规则',
      'next': '下一步',
      'start': '开始验证',
      'skip': '跳过',
      's1_title': '什么是验证？',
      's1_body': '验证是一项旨在通过民主投票系统维护发现完整性的功能。',
      's1_sub': '每个发现由多个验证员审查',
      's2_title': '验证员角色',
      's2_exec': '高管',
      's2_exec_desc': '审查一般发现和完成情况',
      's2_hrd': 'HRD',
      's2_hrd_desc': '仅验证事故报告',
      's2_verif': '验证员',
      's2_verif_desc': '具有投票权的一般验证员',
      's2_note': '每个发现分配3名验证员',
      's3_title': '投票方式',
      's3_valid': '有效',
      's3_valid_desc': '多数票决定最终结果（有效/无效）',
      's3_invalid': '无效',
      's3_invalid_desc': '少数票将受到-5积分的惩罚',
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
  // ══════════════════════════════════════════
  Widget _buildSlide1() {
    return _SlideWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ilustrasi voting
          _VotingIllustration(isValid: null),
          const SizedBox(height: 32),
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
  // ══════════════════════════════════════════
  Widget _buildSlide3() {
    return _SlideWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SlideTitle(t('s3_title')),
          const SizedBox(height: 24),

          // Valid
          _VotingResultCard(
            label: t('s3_valid'),
            desc: t('s3_valid_desc'),
            color: const Color(0xFF4ADE80),
            isValid: true,
          ),
          const SizedBox(height: 16),

          // Divider "VS"
          Row(children: [
            Expanded(
                child: Divider(color: Colors.white.withOpacity(0.1))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'VS',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
            Expanded(
                child: Divider(color: Colors.grey.shade200)),
          ]),
          const SizedBox(height: 16),

          // Invalid
          _VotingResultCard(
            label: t('s3_invalid'),
            desc: t('s3_invalid_desc'),
            color: const Color(0xFFFF6B6B),
            isValid: false,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // SLIDE 4 — Poin & Penalti
  // ══════════════════════════════════════════
  Widget _buildSlide4() {
    return _SlideWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ilustrasi poin
          _PointsIllustration(),
          const SizedBox(height: 28),
          _SlideTitle(t('s4_title')),
          const SizedBox(height: 20),

          // Match — dapat poin
          _PointCard(
            icon: Icons.thumb_up_rounded,
            color: const Color(0xFF4ADE80),
            label: t('s4_match'),
            points: t('s4_match_pts'),
            isPositive: true,
          ),
          const SizedBox(height: 12),

          // Mismatch — penalti
          _PointCard(
            icon: Icons.thumb_down_rounded,
            color: const Color(0xFFFF6B6B),
            label: t('s4_mismatch'),
            points: t('s4_mismatch_pts'),
            isPositive: false,
          ),
          const SizedBox(height: 20),

          _InfoChip(
            icon: Icons.dashboard_rounded,
            label: t('s4_note'),
            color: Colors.white54,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // SLIDE 5 — Batas Waktu
  // ══════════════════════════════════════════
  Widget _buildSlide5() {
    return _SlideWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Jam animatif
          _TimerIllustration(),
          const SizedBox(height: 28),
          _SlideTitle(t('s5_title')),
          const SizedBox(height: 14),
          _SlideBody(t('s5_body')),
          const SizedBox(height: 24),

          // Badge waktu besar
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00C9E4), Color(0xFF0891B2)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00C9E4).withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(children: [
              Text(
                t('s5_timer'),
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Text(
                t('s5_sub'),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ]),
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

/// Kartu hasil voting di slide 3
class _VotingResultCard extends StatelessWidget {
  final String label;
  final String desc;
  final Color color;
  final bool isValid;
  const _VotingResultCard(
      {required this.label,
      required this.desc,
      required this.color,
      required this.isValid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          // Mini voter icons
          _MiniVoterGroup(
            count: 4,
            totalCount: 6,
            color: color,
            isValid: isValid,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  desc,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.4,
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

/// Kartu poin di slide 4
class _PointCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String points;
  final bool isPositive;
  const _PointCard(
      {required this.icon,
      required this.color,
      required this.label,
      required this.points,
      required this.isPositive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            points,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ILUSTRASI CUSTOM (digambar dengan Canvas/Widget)
// ══════════════════════════════════════════════════════════════

/// Ilustrasi voting dengan orang-orang — slide 1
class _VotingIllustration extends StatelessWidget {
  final bool? isValid;
  const _VotingIllustration({this.isValid});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Kotak temuan
          Positioned(
            top: 0,
            child: Container(
              width: 140,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFF00C9E4).withOpacity(0.4),
                    width: 1.5),
              ),
              child: Center(
                child: Text(
                  'Temuan',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00C9E4),
                  ),
                ),
              ),
            ),
          ),
          // Orang-orang verifier
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
                  child: _VerifierAvatar(color: colors[i], size: 32),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini group voter icons untuk slide 3
class _MiniVoterGroup extends StatelessWidget {
  final int count;
  final int totalCount;
  final Color color;
  final bool isValid;
  const _MiniVoterGroup(
      {required this.count,
      required this.totalCount,
      required this.color,
      required this.isValid});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: List.generate(totalCount, (i) {
          final bool isActive = i < count;
          return _VerifierAvatar(
            color: isActive ? color : Colors.white24,
            size: 26,
          );
        }),
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

/// Ilustrasi poin — slide 4
class _PointsIllustration extends StatefulWidget {
  @override
  State<_PointsIllustration> createState() => _PointsIllustrationState();
}

class _PointsIllustrationState extends State<_PointsIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _bounce = Tween<double>(begin: -6, end: 6).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _bounce.value),
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF00C9E4), Color(0xFF0891B2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C9E4).withOpacity(0.4),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(Icons.emoji_events_rounded,
              color: Colors.white, size: 52),
        ),
      ),
    );
  }
}

/// Ilustrasi timer — slide 5
class _TimerIllustration extends StatefulWidget {
  @override
  State<_TimerIllustration> createState() => _TimerIllustrationState();
}

class _TimerIllustrationState extends State<_TimerIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 5))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ring background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00C9E4).withOpacity(0.08),
              border: Border.all(
                  color: const Color(0xFF00C9E4).withOpacity(0.2),
                  width: 2),
            ),
          ),
          // Spinning arc
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Transform.rotate(
              angle: _ctrl.value * 2 * math.pi,
              child: CustomPaint(
                size: const Size(120, 120),
                painter: _ArcPainter(
                  color: const Color(0xFF00C9E4),
                  strokeWidth: 4,
                  sweepAngle: math.pi * 1.5,
                ),
              ),
            ),
          ),
          // Timer icon & text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_rounded,
                  color: Color(0xFF00C9E4), size: 32),
              Text(
                '5:00',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
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