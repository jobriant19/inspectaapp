import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class AdminHomeInfoCard extends StatelessWidget {
  final String adminName;
  final String adminJabatan;
  final String lang;
  final bool isLoadingStats;
  final int totalUsers;
  final int totalLokasi;
  final int totalKategori;
  final int totalTemuan;

  const AdminHomeInfoCard({
    super.key,
    required this.adminName,
    required this.adminJabatan,
    required this.lang,
    required this.isLoadingStats,
    required this.totalUsers,
    required this.totalLokasi,
    required this.totalKategori,
    required this.totalTemuan,
  });

  static final _bgImageProvider = const AssetImage('assets/images/bgadmin.png');

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // BACKGROUND IMAGE
            Positioned.fill(
              child: Image(
                image: _bgImageProvider,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF065F46), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            // TEXT AREA DARK OVERLAY
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha:0.55),
                      Colors.black.withValues(alpha:0.0),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            // CIRCLE DECORATION
            Positioned(
              top: -30, right: -20,
              child: Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha:0.06),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOP LINE: WELCOME + CLOCK
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // LEFT: WELCOME TEXT + ROLE BADGE
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  lang == 'EN' ? 'Hello, '
                                      : lang == 'ZH' ? '你好, '
                                      : 'Halo, ',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha:0.90),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha:0.6),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    adminName,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha:0.7),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            AdminHomeBadge(lang: lang, jabatan: adminJabatan),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // RIGHT: ANALOG CLOCK + DIGITAL + DATE
                      AdminHomeClockWidget(lang: lang),
                    ],
                  ),
                ),
                Container(height: 1, color: Colors.white.withValues(alpha:0.18)),
                // STATS
                isLoadingStats
                    ? _buildStatsShimmer()
                    : _buildBannerStats(),
                const SizedBox(height: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsShimmer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade50,
        child: Row(
          children: List.generate(4, (_) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBannerStats() {
    final stats = [
      _BannerStatItem(
        label: lang == 'EN' ? 'Users' : lang == 'ZH' ? '用户' : 'Pengguna',
        value: totalUsers,
        icon: Icons.people_rounded,
        color: const Color(0xFF3B82F6),
      ),
      _BannerStatItem(
        label: lang == 'EN' ? 'Locations' : lang == 'ZH' ? '位置' : 'Lokasi',
        value: totalLokasi,
        icon: Icons.location_city_rounded,
        color: const Color(0xFF10B981),
      ),
      _BannerStatItem(
        label: lang == 'EN' ? 'Categories' : lang == 'ZH' ? '类别' : 'Kategori',
        value: totalKategori,
        icon: Icons.category_rounded,
        color: const Color(0xFFF59E0B),
      ),
      _BannerStatItem(
        label: lang == 'EN' ? 'Findings' : lang == 'ZH' ? '发现' : 'Temuan',
        value: totalTemuan,
        icon: Icons.assignment_rounded,
        color: const Color(0xFFEF4444),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      child: Row(
        children: stats.map((s) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: s.color,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: s.color.withValues(alpha:0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(s.icon, color: Colors.white.withValues(alpha:0.90), size: 18),
                  const SizedBox(height: 5),
                  Text(
                    '${s.value}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.label,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha:0.88),
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BannerStatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _BannerStatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class AdminHomeBadge extends StatefulWidget {
  final String lang;
  final String jabatan;
  const AdminHomeBadge({super.key, required this.lang, required this.jabatan});

  @override
  State<AdminHomeBadge> createState() => _AdminHomeBadgeState();
}

class _AdminHomeBadgeState extends State<AdminHomeBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
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
      builder: (_, child) {
        final t = _ctrl.value < 0.5
            ? _ctrl.value * 2
            : (1 - _ctrl.value) * 2;
        final borderColor = Color.lerp(
          const Color(0xFF34D399),
          const Color(0xFF38BDF8),
          t,
        )!;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha:0.38),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: borderColor.withValues(alpha:0.35),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded,
              color: Color(0xFF34D399), size: 12),
          const SizedBox(width: 5),
          Text(
            widget.jabatan,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha:0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// DIGITAL + ANALOG CLOCK WIDGET
class AdminHomeClockWidget extends StatefulWidget {
  final String lang;
  const AdminHomeClockWidget({super.key, required this.lang});

  @override
  State<AdminHomeClockWidget> createState() => _AdminHomeClockWidgetState();
}

class _AdminHomeClockWidgetState extends State<AdminHomeClockWidget> {
  late DateTime _now;
  late Timer _timer;
  final bool _fontReady = true;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1),
        (_) { if (mounted) setState(() => _now = DateTime.now()); });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _pad(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final h = _pad(_now.hour);
    final m = _pad(_now.minute);
    final s = _pad(_now.second);
    final year = _now.year.toString();

    final String dayStr;
    final String monStr;

    if (widget.lang == 'ID') {
      const daysID = ['Min','Sen','Sel','Rab','Kam','Jum','Sab'];
      const monsID = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agt','Sep','Okt','Nov','Des'];
      dayStr = daysID[_now.weekday % 7];
      monStr = monsID[_now.month - 1];
    } else if (widget.lang == 'ZH') {
      const daysZH = ['日','一','二','三','四','五','六'];
      const monsZH = ['1月','2月','3月','4月','5月','6月','7月','8月','9月','10月','11月','12月'];
      dayStr = '周${daysZH[_now.weekday % 7]}';
      monStr = monsZH[_now.month - 1];
    } else {
      const daysEN = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
      const monsEN = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      dayStr = daysEN[_now.weekday % 7];
      monStr = monsEN[_now.month - 1];
    }

    final date = _pad(_now.day);
    final String dateLabel;
    if (widget.lang == 'ID') {
      dateLabel = '$dayStr, $date $monStr $year';
    } else if (widget.lang == 'ZH') {
      dateLabel = '$year年$monStr$date日 $dayStr';
    } else {
      dateLabel = '$dayStr, $date $monStr $year';
    }

    final timeStyle = _fontReady
        ? GoogleFonts.sourceCodePro(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            shadows: [Shadow(color: Colors.black.withValues(alpha:0.6), blurRadius: 6)])
        : const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800,
            letterSpacing: 1.5, fontFamily: 'monospace');

    final secStyle = _fontReady
        ? GoogleFonts.sourceCodePro(
            color: const Color(0xFF6EE7B7), fontSize: 15, fontWeight: FontWeight.w800,
            letterSpacing: 1,
            shadows: [Shadow(color: const Color(0xFF059669).withValues(alpha:0.8), blurRadius: 8)])
        : const TextStyle(color: Color(0xFF6EE7B7), fontSize: 15, fontWeight: FontWeight.w800,
            letterSpacing: 1, fontFamily: 'monospace');

    final dateStyle = _fontReady
        ? GoogleFonts.poppins(
            color: Colors.white.withValues(alpha:0.85), fontSize: 8.5, fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            shadows: [Shadow(color: Colors.black.withValues(alpha:0.5), blurRadius: 4)])
        : TextStyle(color: Colors.white.withValues(alpha:0.85), fontSize: 8.5,
            fontWeight: FontWeight.w600, letterSpacing: 0.3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha:0.38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha:0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 54, height: 54,
            child: CustomPaint(painter: AdminClockPainter(now: _now)),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$h:$m', style: timeStyle),
                  Text(':', style: _fontReady
                      ? GoogleFonts.sourceCodePro(
                          color: Colors.white.withValues(alpha:0.70),
                          fontSize: 14, fontWeight: FontWeight.w700)
                      : TextStyle(color: Colors.white.withValues(alpha:0.70),
                          fontSize: 14, fontWeight: FontWeight.w700,
                          fontFamily: 'monospace')),
                  Text(s, style: secStyle),
                ],
              ),
              const SizedBox(height: 3),
              Text(dateLabel, style: dateStyle),
            ],
          ),
        ],
      ),
    );
  }
}

// ANALOG CLOCK PAINTER
class AdminClockPainter extends CustomPainter {
  final DateTime now;
  const AdminClockPainter({required this.now});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2 - 2;
    final center = Offset(cx, cy);
    const pi2 = 6.283185307;

    canvas.drawCircle(center, r,
        Paint()..color = Colors.white.withValues(alpha:0.10));
    canvas.drawCircle(center, r,
        Paint()
          ..color = Colors.white.withValues(alpha:0.30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * pi2 - pi2 / 4;
      final isMajor = i % 3 == 0;
      final outer = r - 1;
      final inner = isMajor ? r - 6 : r - 4;
      canvas.drawLine(
        Offset(cx + inner * _cos(angle), cy + inner * _sin(angle)),
        Offset(cx + outer * _cos(angle), cy + outer * _sin(angle)),
        Paint()
          ..color = isMajor
              ? Colors.white.withValues(alpha:0.90)
              : Colors.white.withValues(alpha:0.45)
          ..strokeWidth = isMajor ? 1.8 : 1.0
          ..strokeCap = StrokeCap.round,
      );
    }

    final hourAngle =
        ((now.hour % 12) + now.minute / 60) / 12 * pi2 - pi2 / 4;
    canvas.drawLine(center,
        Offset(cx + (r * 0.45) * _cos(hourAngle), cy + (r * 0.45) * _sin(hourAngle)),
        Paint()..color = Colors.white..strokeWidth = 2.5..strokeCap = StrokeCap.round);

    final minAngle = (now.minute + now.second / 60) / 60 * pi2 - pi2 / 4;
    canvas.drawLine(center,
        Offset(cx + (r * 0.65) * _cos(minAngle), cy + (r * 0.65) * _sin(minAngle)),
        Paint()..color = Colors.white.withValues(alpha:0.90)..strokeWidth = 1.8..strokeCap = StrokeCap.round);

    final secAngle = now.second / 60 * pi2 - pi2 / 4;
    canvas.drawLine(
        Offset(cx - (r * 0.15) * _cos(secAngle), cy - (r * 0.15) * _sin(secAngle)),
        Offset(cx + (r * 0.80) * _cos(secAngle), cy + (r * 0.80) * _sin(secAngle)),
        Paint()..color = const Color(0xFF34D399)..strokeWidth = 1.2..strokeCap = StrokeCap.round);

    canvas.drawCircle(center, 3, Paint()..color = const Color(0xFF34D399));
    canvas.drawCircle(center, 1.5, Paint()..color = Colors.white);
  }

  double _cos(double a) => math.cos(a);
  double _sin(double a) => math.sin(a);

  @override
  bool shouldRepaint(covariant AdminClockPainter old) =>
      old.now.second != now.second;
}