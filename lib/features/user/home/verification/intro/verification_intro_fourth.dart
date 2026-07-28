import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VerificationIntroFourthSlide extends StatelessWidget {
  final String lang;
  const VerificationIntroFourthSlide({super.key, required this.lang});

  static const Map<String, Map<String, String>> _txt = {
    'EN': {
      'title': 'Points & Penalty',
      'subtitle': 'Join the majority to earn points',
      'match': 'Your vote matches the majority',
      'match_pts': '+10 Points',
      'mismatch': 'Your vote is in the minority',
      'mismatch_pts': '-5 Points',
      'note': 'Results can be seen in the Mountain dashboard',
    },
    'ID': {
      'title': 'Poin & Penalti',
      'subtitle': 'Bergabunglah dengan mayoritas untuk mendapatkan poin',
      'match': 'Suara Anda masuk mayoritas',
      'match_pts': '+10 Poin',
      'mismatch': 'Suara Anda masuk minoritas',
      'mismatch_pts': '-5 Poin',
      'note': 'Hasil dapat dilihat di dashboard The Mountain',
    },
    'ZH': {
      'title': '积分与惩罚',
      'subtitle': '加入多数派以获得积分',
      'match': '您的投票属于多数',
      'match_pts': '+10积分',
      'mismatch': '您的投票属于少数',
      'mismatch_pts': '-5积分',
      'note': '结果可在The Mountain仪表板上查看',
    },
  };

  String t(String key) => _txt[lang]?[key] ?? key;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _PointsIllustrationEnhanced(),
        const SizedBox(height: 24),

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
        const SizedBox(height: 8),

        // SUBTITLE
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 15, color: Colors.grey.shade800),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                t('subtitle'),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // MATCH -> GET BONUS POINT
        _PointCardEnhanced(
          icon: Icons.thumb_up_rounded,
          color: const Color(0xFF059669),
          bgColor: const Color(0xFFECFDF5),
          borderColor: const Color(0xFF6EE7B7),
          label: t('match'),
          points: t('match_pts'),
        ),
        const SizedBox(height: 14),

        // MISMATCH -> PENALTY POINT
        _PointCardEnhanced(
          icon: Icons.thumb_down_rounded,
          color: const Color(0xFFDC2626),
          bgColor: const Color(0xFFFFF1F2),
          borderColor: const Color(0xFFFCA5A5),
          label: t('mismatch'),
          points: t('mismatch_pts'),
        ),
        const SizedBox(height: 20),

        // DASHBOARD NOTE
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1D72F3).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF1D72F3).withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D72F3).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.dashboard_rounded,
                    size: 15, color: Color(0xFF1D72F3)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t('note'),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF1D72F3),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PointCardEnhanced extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final String label;
  final String points;

  const _PointCardEnhanced({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.label,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
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

class _PointsIllustrationEnhanced extends StatefulWidget {
  const _PointsIllustrationEnhanced();

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
              // OUTER GLOW RING
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF1D72F3).withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // CENTER RING
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF1D72F3).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
              // MAIN CIRCLE
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D72F3), Color(0xFF0891B2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1D72F3).withValues(alpha: 0.5),
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