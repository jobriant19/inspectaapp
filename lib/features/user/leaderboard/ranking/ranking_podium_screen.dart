import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'ranking_screen.dart' show RankMember;

class _PodiumColors {
  static const gold = Color(0xFFFFC700);
  static const goldDark = Color(0xFFE08E00);
  static const silver = Color(0xFFCBD5E1);
  static const silverDark = Color(0xFF8492A6);
  static const bronze = Color(0xFFE39257);
  static const bronzeDark = Color(0xFFB5652E);
}

class RankingPodiumScreen extends StatefulWidget {
  final Future<List<RankMember>>? leaderboardFuture;
  final String lang;
  final bool isDaily;
  final DateTime? selectedDay;

  const RankingPodiumScreen({
    super.key,
    required this.leaderboardFuture,
    required this.lang,
    this.isDaily = false,
    this.selectedDay,
  });

  @override
  State<RankingPodiumScreen> createState() => _RankingPodiumScreenState();
}

class _RankingPodiumScreenState extends State<RankingPodiumScreen>
    with TickerProviderStateMixin {
  late AnimationController _master;

  final List<Offset> _starSpecs = const [
    Offset(0.10, 0.10),
    Offset(0.24, 0.20),
    Offset(0.40, 0.08),
    Offset(0.58, 0.16),
    Offset(0.74, 0.06),
    Offset(0.88, 0.18),
  ];

  @override
  void initState() {
    super.initState();
    _master = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _master.dispose();
    super.dispose();
  }

  String get _noPodiumTitle {
    switch (widget.lang) {
      case 'EN':
        return 'No Ranking Data Yet';
      case 'ZH':
        return '暂无排名数据';
      default:
        return 'Belum Ada Data Peringkat';
    }
  }

  String get _noPodiumSubtitle {
    if (widget.isDaily) {
      switch (widget.lang) {
        case 'EN':
          return 'Rankings will appear here once\nactivity is recorded for this day.';
        case 'ZH':
          return '当天一旦有活动记录，\n排名将显示在此处。';
        default:
          return 'Peringkat akan muncul di sini setelah\nada aktivitas tercatat pada tanggal ini.';
      }
    }
    switch (widget.lang) {
      case 'EN':
        return 'Rankings will appear here once\nactivity is recorded this month.';
      case 'ZH':
        return '本月一旦有活动记录，\n排名将显示在此处。';
      default:
        return 'Peringkat akan muncul di sini setelah\nada aktivitas tercatat bulan ini.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      height: 350,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return AnimatedBuilder(
              animation: _master,
              builder: (context, _) {
                final t = _master.value;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // SKY BACKGROUND
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF1E88E5),
                              Color(0xFF42A5F5),
                              Color(0xFF64B5F6),
                              Color(0xFFA9D6F5),
                              Color(0xFFEAF6FF),
                            ],
                            stops: [0.0, 0.2, 0.48, 0.78, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0.35, -0.75),
                            radius: 1.35,
                            colors: [
                              Colors.white.withValues(alpha: 0.42),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.65],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(-0.6, 0.85),
                            radius: 1.2,
                            colors: [
                              const Color(0xFF06344A).withValues(alpha: 0.30),
                              const Color(0xFF06344A).withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.75],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.05,
                            colors: [
                              Colors.transparent,
                              const Color(0xFF0B4A63).withValues(alpha: 0.25),
                            ],
                            stops: const [0.65, 1.0],
                          ),
                        ),
                      ),
                    ),

                    ..._starSpecs.asMap().entries.map((entry) {
                      final i = entry.key;
                      final pos = entry.value;
                      final phase = i * 0.8;
                      final twinkle = 0.25 +
                          0.45 * (0.5 + 0.5 * sin(t * 2 * pi * 2.5 + phase));
                      return Positioned(
                        left: (pos.dx * w).clamp(6.0, w - 6),
                        top: (pos.dy * h * 0.45).clamp(6.0, h * 0.4),
                        child: Opacity(
                          opacity: twinkle.clamp(0.0, 1.0),
                          child: const Icon(Icons.brightness_1,
                              size: 4, color: Colors.white),
                        ),
                      );
                    }),

                    Positioned(
                      top: 6,
                      right: 24,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.6),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _buildMountainScene(w, h),
                    ),
                    _buildDriftingCloud(
                      w: w,
                      baseLeftFrac: 0.04,
                      baseTop: h * 0.14,
                      width: 60,
                      speed: 1,
                      phase: 0.0,
                      t: t,
                    ),
                    _buildDriftingCloud(
                      w: w,
                      baseLeftFrac: 0.28,
                      baseTop: h * 0.22,
                      width: 48,
                      speed: 1,
                      phase: 0.35,
                      t: t,
                    ),
                    _buildDriftingCloud(
                      w: w,
                      baseLeftFrac: 0.58,
                      baseTop: h * 0.13,
                      width: 72,
                      speed: 1,
                      phase: 0.6,
                      t: t,
                    ),
                    _buildDriftingCloud(
                      w: w,
                      baseLeftFrac: 0.84,
                      baseTop: h * 0.20,
                      width: 54,
                      speed: 1,
                      phase: 0.85,
                      t: t,
                    ),

                    _buildFlyingPlane(
                      w: w,
                      topBase: h * 0.09,
                      speedMultiplier: 2,
                      phaseOffset: 0.0,
                      scale: 1.0,
                      t: t,
                    ),
                    _buildFlyingPlane(
                      w: w,
                      topBase: h * 0.22,
                      speedMultiplier: 1,
                      phaseOffset: 0.5,
                      scale: 0.65,
                      t: t,
                    ),

                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.4),
                              Colors.white.withValues(alpha: 0.6),
                              Colors.white.withValues(alpha: 0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // PODIUM
                    FutureBuilder<List<RankMember>>(
                      future: widget.leaderboardFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData &&
                            snapshot.connectionState ==
                                ConnectionState.waiting) {
                          return const _PodiumShimmerPlaceholder();
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Align(
                            alignment: const Alignment(0, -0.25),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 28),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B3550).withValues(alpha: 0.78),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.16),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.5)),
                                    ),
                                    child: Icon(
                                      widget.isDaily
                                          ? Icons.today_rounded
                                          : Icons.emoji_events_outlined,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _noPodiumTitle,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black87,
                                          blurRadius: 6,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _noPodiumSubtitle,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      height: 1.4,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black87,
                                          blurRadius: 5,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final members = snapshot.data!;
                        RankMember? top1, top2, top3;
                        try {
                          top1 = members.firstWhere((m) => m.rank == 1);
                        } catch (_) {}
                        try {
                          top2 = members.firstWhere((m) => m.rank == 2);
                        } catch (_) {}
                        try {
                          top3 = members.firstWhere((m) => m.rank == 3);
                        } catch (_) {}

                        return Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (top2 != null)
                                  _PodiumMember(
                                      member: top2,
                                      position: 2,
                                      t: t,
                                      phase: 1.0)
                                else
                                  const SizedBox(width: 96),
                                if (top1 != null)
                                  _PodiumMember(
                                      member: top1,
                                      position: 1,
                                      t: t,
                                      phase: 0.0)
                                else
                                  const SizedBox(width: 112),
                                if (top3 != null)
                                  _PodiumMember(
                                      member: top3,
                                      position: 3,
                                      t: t,
                                      phase: 2.0)
                                else
                                  const SizedBox(width: 96),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDriftingCloud({
    required double w,
    required double baseLeftFrac,
    required double baseTop,
    required double width,
    required double speed,
    required double phase,
    required double t,
  }) {
    final left = (baseLeftFrac * w).clamp(0.0, w - width);
    final bob = 3 * sin(t * 2 * pi * speed + phase * 2 * pi);
    return Positioned(
      left: left,
      top: baseTop + bob,
      child: _volumetricCloud(width),
    );
  }

  Widget _volumetricCloud(double width) {
    final h = width * 0.58;
    final totalH = h + 26;
    return SizedBox(
      width: width * 1.1,
      height: totalH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: width * 0.02,
            bottom: h * 0.16,
            child: Container(
              width: width,
              height: h * 0.48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFE7F1F5)],
                ),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          Positioned(left: 0, bottom: h * 0.32, child: _cloudPuff(width * 0.36)),
          Positioned(left: width * 0.16, bottom: h * 0.48, child: _cloudPuff(width * 0.44)),
          Positioned(left: width * 0.40, bottom: h * 0.58, child: _cloudPuff(width * 0.52)),
          Positioned(left: width * 0.64, bottom: h * 0.44, child: _cloudPuff(width * 0.42)),
          Positioned(right: 0, bottom: h * 0.30, child: _cloudPuff(width * 0.34)),
        ],
      ),
    );
  }

  Widget _cloudPuff(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [Colors.white, const Color(0xFFE3EEF2)],
          stops: const [0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildMountainScene(double w, double h) {
    final mh = h * 0.52;
    return SizedBox(
      width: w,
      height: mh,
      child: Image.asset(
        'assets/images/hill.png',
        width: w,
        height: mh,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildFlyingPlane({
    required double w,
    required double topBase,
    required double speedMultiplier,
    required double phaseOffset,
    required double scale,
    required double t,
  }) {
    final planeW = 34 * scale;
    final progress = ((t * speedMultiplier + phaseOffset) % 1.0);
    final travel = w + planeW * 2.5;
    final x = -planeW * 1.5 + progress * travel;
    final bob = 3 * sin(progress * 2 * pi * 3);

    return Positioned(
      left: x,
      top: topBase + bob,
      child: _MiniPlane(scale: scale),
    );
  }
}

class _MiniPlane extends StatelessWidget {
  final double scale;
  const _MiniPlane({required this.scale});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34 * scale,
      height: 16 * scale,
      child: CustomPaint(painter: _PlanePainter()),
    );
  }
}

class _PlanePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.55, h * 0.92), width: w * 0.55, height: h * 0.14),
      shadowPaint,
    );
    final trailPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.75),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.40, w * 0.34, h * 0.20));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h * 0.40, w * 0.34, h * 0.20),
        const Radius.circular(5),
      ),
      trailPaint,
    );
    final bodyPath = Path()
      ..moveTo(w * 0.30, h * 0.30)
      ..lineTo(w * 0.86, h * 0.42)
      ..lineTo(w * 1.00, h * 0.50)
      ..lineTo(w * 0.86, h * 0.58)
      ..lineTo(w * 0.30, h * 0.70)
      ..quadraticBezierTo(w * 0.18, h * 0.50, w * 0.30, h * 0.30)
      ..close();
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0xFF244A5C).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, const Color(0xFFCFE0E8)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(bodyPath, bodyPaint);
    final liveryPaint = Paint()
      ..color = const Color(0xFF0EA5E9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.06
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.32, h * 0.53),
      Offset(w * 0.82, h * 0.47),
      liveryPaint,
    );
    final wingTopPath = Path()
      ..moveTo(w * 0.42, h * 0.38)
      ..lineTo(w * 0.30, h * 0.02)
      ..lineTo(w * 0.52, h * 0.40)
      ..close();
    canvas.drawPath(wingTopPath, Paint()..color = const Color(0xFFF3F8FA));
    canvas.drawPath(
      wingTopPath,
      Paint()
        ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final wingBottomPath = Path()
      ..moveTo(w * 0.46, h * 0.62)
      ..lineTo(w * 0.34, h * 0.98)
      ..lineTo(w * 0.58, h * 0.62)
      ..close();
    canvas.drawPath(wingBottomPath, Paint()..color = const Color(0xFFB8CBD4));
    canvas.drawPath(
      wingBottomPath,
      Paint()
        ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    final tailPath = Path()
      ..moveTo(w * 0.24, h * 0.30)
      ..lineTo(w * 0.14, h * 0.06)
      ..lineTo(w * 0.31, h * 0.34)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = const Color(0xFF0369A1));
    for (double i = 0; i < 4; i++) {
      final center = Offset(w * (0.48 + i * 0.095), h * 0.485);
      canvas.drawCircle(center, h * 0.055, Paint()..color = Colors.white);
      canvas.drawCircle(
          center, h * 0.045, Paint()..color = const Color(0xFF1D4ED8));
    }
    final noseGradient = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, const Color(0xFF9FB9C6)],
      ).createShader(Rect.fromCenter(
          center: Offset(w * 0.93, h * 0.50), width: w * 0.16, height: h * 0.55));
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.93, h * 0.50), width: w * 0.14, height: h * 0.5),
      noseGradient,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PodiumMember extends StatelessWidget {
  final RankMember member;
  final int position;
  final double t;
  final double phase;

  const _PodiumMember({
    required this.member,
    required this.position,
    required this.t,
    required this.phase,
  });

  bool get _isFirst => position == 1;

  double get _platformHeight =>
      _isFirst ? 132.0 : (position == 2 ? 100.0 : 84.0);
  double get _avatarSize => _isFirst ? 74.0 : (position == 2 ? 60.0 : 56.0);
  double get _columnWidth => _isFirst ? 112.0 : 96.0;

  List<Color> get _medalGradient {
    if (position == 1) return [_PodiumColors.gold, _PodiumColors.goldDark];
    if (position == 2) {
      return [_PodiumColors.silver, _PodiumColors.silverDark];
    }
    return [_PodiumColors.bronze, _PodiumColors.bronzeDark];
  }

  Color get _medalSolid => _medalGradient.first;

  @override
  Widget build(BuildContext context) {
    final ringAngle = (t * 2 * pi * 1.0) + phase;
    final bob = 2.5 * sin(t * 2 * pi * 1.6 + phase);
    final crownScale = _isFirst ? 1.0 + 0.08 * sin(t * 2 * pi * 2.2) : 1.0;
    final crownGlow = _isFirst ? 0.5 + 0.5 * sin(t * 2 * pi * 2.2) : 0.0;

    final ringSize = _avatarSize + 16;
    final avatarAreaHeight = ringSize + (_isFirst ? 36 : 20);

    return SizedBox(
      width: _columnWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // AVATAR
          SizedBox(
            height: avatarAreaHeight,
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                Transform.translate(
                  offset: Offset(0, bob),
                  child: SizedBox(
                    width: ringSize,
                    height: ringSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.rotate(
                          angle: ringAngle,
                          child: Container(
                            width: ringSize,
                            height: ringSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  _medalSolid,
                                  Colors.white,
                                  _medalGradient.last,
                                  Colors.white,
                                  _medalSolid,
                                ],
                                stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: ringSize - 8,
                          height: ringSize - 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                        _PodiumAvatar(
                          name: member.name,
                          avatarUrl: member.avatarUrl,
                          size: _avatarSize,
                          borderColor: _medalSolid,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: -12,
                  child: _isFirst
                      ? Transform.scale(
                          scale: crownScale,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: _medalGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: _medalSolid.withValues(
                                      alpha: 0.65 + 0.25 * crownGlow),
                                  blurRadius: 14 + 6 * crownGlow,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        )
                      : Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _medalGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: _medalSolid.withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${member.rank}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          SizedBox(
            width: _columnWidth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _medalSolid, width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  member.name,
                  maxLines: 1,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF0C4A6E),
                    fontSize: _isFirst ? 15.5 : 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
          Container(
            height: _platformHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _medalGradient,
              ),
              border: const Border(
                top: BorderSide(color: Colors.white, width: 2),
              ),
              boxShadow: [
                BoxShadow(
                  color: _medalSolid.withValues(alpha: 0.55),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 6,
                  top: 8,
                  bottom: 8,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '${member.rank}',
                    style: GoogleFonts.poppins(
                      fontSize: _isFirst ? 42 : 32,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                      letterSpacing: -1,
                      shadows: const [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
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
}
class _PodiumAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double size;
  final Color borderColor;

  const _PodiumAvatar({
    required this.name,
    this.avatarUrl,
    required this.size,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: CircleAvatar(
        radius: size / 2,
        backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
            ? NetworkImage(avatarUrl!)
            : null,
        backgroundColor: const Color(0xFF0EA5E9),
        onBackgroundImageError: avatarUrl != null ? (_, __) {} : null,
        child: (avatarUrl == null || avatarUrl!.isEmpty)
            ? Text(
                name
                    .trim()
                    .split(' ')
                    .take(2)
                    .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                    .join(),
                style: TextStyle(
                  fontSize: size * 0.35,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }
}

class _PodiumShimmerPlaceholder extends StatelessWidget {
  const _PodiumShimmerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF0369A1).withValues(alpha: 0.5),
      highlightColor: const Color(0xFF0EA5E9).withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildShimmerBlock(height: 100, avatarSize: 58),
            _buildShimmerBlock(height: 130, avatarSize: 68),
            _buildShimmerBlock(height: 100, avatarSize: 58),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBlock({
    required double height,
    required double avatarSize,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: avatarSize,
          width: avatarSize,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: height,
          width: 95,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
          ),
        ),
      ],
    );
  }
}