import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VerificationIntroFirstSlide extends StatelessWidget {
  final String lang;
  const VerificationIntroFirstSlide({super.key, required this.lang});

  static const Map<String, Map<String, String>> _txt = {
    'EN': {
      'title': 'What is Verification?',
      'body':
          'Verification is a feature designed to maintain the integrity of findings through a democratic voting system.',
      'sub': 'Every finding is reviewed by multiple verifiers',
      'finding': 'Finding',
      'completion': 'Completion',
    },
    'ID': {
      'title': 'Apa itu Verifikasi?',
      'body':
          'Verifikasi adalah fitur yang bertujuan menjaga integritas temuan melalui sistem voting demokratis.',
      'sub': 'Setiap temuan ditinjau oleh beberapa verifier',
      'finding': 'Temuan',
      'completion': 'Penyelesaian',
    },
    'ZH': {
      'title': '什么是验证？',
      'body': '验证是一项旨在通过民主投票系统维护发现完整性的功能。',
      'sub': '每个发现由多个验证员审查',
      'finding': '发现',
      'completion': '完成',
    },
  };

  String t(String key) => _txt[lang]?[key] ?? key;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FindingCompletionIllustration(
          findingLabel: t('finding'),
          completionLabel: t('completion'),
        ),
        const SizedBox(height: 28),
        Text(
          t('title'),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1D72F3),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          t('body'),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),
        _InfoChip(
          icon: Icons.how_to_vote_rounded,
          label: t('sub'),
          color: const Color(0xFF1D72F3),
        ),
      ],
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
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha:0.25)),
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
              Positioned(
                bottom: 0,
                child: Row(
                  children: List.generate(6, (i) {
                    final colors = [
                      const Color(0xFF1D72F3),
                      const Color(0xFF4ADE80),
                      const Color(0xFF1D72F3),
                      const Color(0xFFFF6B6B),
                      const Color(0xFF4ADE80),
                      const Color(0xFF1D72F3),
                    ];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _VerifierAvatar(color: colors[i], size: 28),
                    );
                  }),
                ),
              ),

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
                      // FINDING
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
                              color: const Color(0xFFFF6B6B).withValues(alpha:0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_rounded,
                                color: Colors.white, size: 20),
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

                      // CONNECTOR ARROW
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D72F3).withValues(alpha:0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF1D72F3).withValues(alpha:0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Color(0xFF1D72F3),
                          ),
                        ),
                      ),

                      // SOLUTION 
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
                              color: const Color(0xFF4ADE80).withValues(alpha:0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 20),
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
        color: color.withValues(alpha:0.2),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Icon(Icons.person_rounded, size: size * 0.55, color: color),
    );
  }
}