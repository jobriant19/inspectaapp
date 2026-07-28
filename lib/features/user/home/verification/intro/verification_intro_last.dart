import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VerificationIntroLastSlide extends StatefulWidget {
  final String lang;

  const VerificationIntroLastSlide({
    super.key,
    required this.lang,
  });

  @override
  State<VerificationIntroLastSlide> createState() =>
      _VerificationIntroLastSlideState();
}

class _VerificationIntroLastSlideState
    extends State<VerificationIntroLastSlide> with TickerProviderStateMixin {
  late AnimationController _rotCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  int _displaySeconds = 120;
  Timer? _demoTimer;

  static const Map<String, Map<String, String>> _txt = {
    'EN': {
      's5_title': 'Time Limit',
      's5_body':
          'Complete every verification within 2 minutes. Read each finding carefully so your decision is accurate.',
      's5_urgent': 'Stay focused!',
      's5_urgent_desc': 'Less than a minute left, finish quickly.',
      's5_normal_desc': 'Take your time, but stay within the limit.',
    },
    'ID': {
      's5_title': 'Batas Waktu',
      's5_body':
          'Selesaikan setiap verifikasi dalam waktu 2 menit. Baca setiap temuan dengan teliti agar keputusan Anda tepat.',
      's5_urgent': 'Tetap fokus!',
      's5_urgent_desc': 'Waktu tersisa kurang dari 1 menit, segera selesaikan.',
      's5_normal_desc': 'Ambil waktu secukupnya, namun tetap dalam batas waktu.',
    },
    'ZH': {
      's5_title': '时间限制',
      's5_body': '每次验证必须在2分钟内完成。请仔细阅读每项发现，以确保您的判断准确。',
      's5_urgent': '保持专注！',
      's5_urgent_desc': '剩余时间不足1分钟，请尽快完成。',
      's5_normal_desc': '请合理安排时间，并留意时间限制。',
    },
  };

  String t(String key) => _txt[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _rotCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _demoTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_displaySeconds > 0) {
          _displaySeconds--;
        } else {
          _displaySeconds = 120;
        }
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
    final bool isUrgent = _displaySeconds <= 60;
    final Color mainColor =
        isUrgent ? const Color(0xFFDC2626) : const Color(0xFF1D72F3);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_rotCtrl, _pulseCtrl]),
          builder: (_, __) => _TimerIllustration(
            displaySeconds: _displaySeconds,
            mainColor: mainColor,
            isUrgent: isUrgent,
            rotValue: _rotCtrl.value,
            pulseValue: _pulse.value,
          ),
        ),
        const SizedBox(height: 14),

        // TITLE
        Text(
          t('s5_title'),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1D72F3),
            height: 1.2,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),

        // SUBTITLE
        Text(
          t('s5_body'),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            height: 1.65,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 20),

        // INFO CARD / WARNING
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: mainColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: mainColor.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(
                isUrgent
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline_rounded,
                color: mainColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('s5_urgent'),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: mainColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isUrgent ? t('s5_urgent_desc') : t('s5_normal_desc'),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimerIllustration extends StatelessWidget {
  final int displaySeconds;
  final Color mainColor;
  final bool isUrgent;
  final double rotValue;
  final double pulseValue;

  const _TimerIllustration({
    required this.displaySeconds,
    required this.mainColor,
    required this.isUrgent,
    required this.rotValue,
    required this.pulseValue,
  });

  @override
  Widget build(BuildContext context) {
    final int minutes = displaySeconds ~/ 60;
    final int seconds = displaySeconds % 60;
    final double progress = displaySeconds / 120.0;

    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: pulseValue,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    mainColor.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: mainColor.withValues(alpha: 0.06),
              border:
                  Border.all(color: mainColor.withValues(alpha: 0.15), width: 2),
            ),
          ),
          Transform.rotate(
            angle: rotValue * 2 * math.pi,
            child: CustomPaint(
              size: const Size(140, 140),
              painter: _ArcPainter(
                color: mainColor.withValues(alpha: 0.35),
                strokeWidth: 3,
                sweepAngle: math.pi * 0.8,
              ),
            ),
          ),
          CustomPaint(
            size: const Size(130, 130),
            painter: _ProgressArcPainter(
              color: mainColor,
              strokeWidth: 5,
              progress: progress,
            ),
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  mainColor.withValues(alpha: 0.9),
                  mainColor.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: mainColor.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_rounded, color: Colors.white, size: 28),
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
                opacity: pulseValue > 1.04 ? 1.0 : 0.3,
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
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double sweepAngle;
  const _ArcPainter({
    required this.color,
    required this.strokeWidth,
    required this.sweepAngle,
  });

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
      size.height - strokeWidth,
    );
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
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressArcPainter old) =>
      old.progress != progress || old.color != color;
}