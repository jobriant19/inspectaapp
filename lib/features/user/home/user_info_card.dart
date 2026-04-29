import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/jabatan_helper.dart';

class UserInfoCard extends StatefulWidget {
  final String userName;
  final String userRole;
  final String? userImage;
  final int userPoin;
  final String userLocationName;
  final Map<String, dynamic>? latestLogPoin;
  final bool isLatestLogLoading;
  final String lang;
  final bool? isVerificator;
  final int? userJabatanId;
  final VoidCallback onViewMoreTap;

  const UserInfoCard({
    super.key,
    required this.userName,
    required this.userRole,
    required this.userPoin,
    required this.userLocationName,
    required this.lang,
    required this.onViewMoreTap,
    this.userImage,
    this.latestLogPoin,
    this.isLatestLogLoading = false,
    this.isVerificator,
    this.userJabatanId,
  });

  @override
  State<UserInfoCard> createState() => _UserInfoCardState();
}

class _UserInfoCardState extends State<UserInfoCard> {
  int _monthlyPoin = 0;
  bool _isLoadingMonthly = true;

  @override
  void initState() {
    super.initState();
    _fetchMonthlyPoin();
  }

  @override
  void didUpdateWidget(UserInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Hanya fetch ulang ketika nilai FINAL poin berubah.
    // Karena sekarang UserInfoCard menerima _userPoin (bukan _displayedPoin),
    // ini hanya dipanggil SEKALI saat poin benar-benar berubah di database.
    if (oldWidget.userPoin != widget.userPoin) {
      _fetchMonthlyPoin();
    }
  }

  Future<void> _fetchMonthlyPoin() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final now = DateTime.now();
      final startOfMonth =
          DateTime(now.year, now.month, 1).toIso8601String();
      final endOfMonth =
          DateTime(now.year, now.month + 1, 1).toIso8601String();

      final List<dynamic> logs = await supabase
          .from('log_poin')
          .select('poin')
          .eq('id_user', userId)
          .gte('created_at', startOfMonth)
          .lt('created_at', endOfMonth);

      int total = 0;
      for (final log in logs) {
        total += ((log['poin'] as num?)?.toInt() ?? 0);
      }

      if (mounted) {
        setState(() {
          _monthlyPoin = total;
          _isLoadingMonthly = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching monthly poin: $e');
      if (mounted) {
        setState(() {
          _monthlyPoin = widget.userPoin;
          _isLoadingMonthly = false;
        });
      }
    }
  }

  // ── Warna api berdasarkan poin ──
  Color _getFireColor(int points) {
    if (points >= 1000) return const Color(0xFFEF4444);
    if (points >= 500) return const Color(0xFFF97316);
    if (points >= 100) return const Color(0xFF22C55E);
    if (points > 0) return const Color(0xFF3B82F6);
    return Colors.grey.shade400;
  }

  double _getPointProgress(int points) {
    const maxPoints = 2000;
    return (points / maxPoints).clamp(0.0, 1.0);
  }

  String _getTxt(String key) {
    final Map<String, Map<String, String>> texts = {
      'EN': {
        'activity_log': 'Activity Log',
        'view_more': 'View More',
        'latest_activity': 'Location:',
      },
      'ID': {
        'activity_log': 'Log Aktivitas',
        'view_more': 'Lihat Detail',
        'latest_activity': 'Lokasi:',
      },
      'ZH': {
        'activity_log': '活动日志',
        'view_more': '查看更多',
        'latest_activity': '位置:',
      },
    };
    return texts[widget.lang]?[key] ?? key;
  }

  Widget _buildLatestLog() {
    if (widget.latestLogPoin == null) return const SizedBox();

    // Aman: ambil poin sebagai num lalu konversi ke int
    final int poin = (widget.latestLogPoin!['poin'] as num).toInt();
    final String deskripsi = (widget.latestLogPoin!['deskripsi'] ?? '').toString();
    final bool isPositive = poin >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getTxt('activity_log'),
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Icon(
              isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline,
              size: 13,
              color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${isPositive ? '+' : ''}$poin • $deskripsi',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fireColor = _getFireColor(_monthlyPoin);
    final pointProgress = _getPointProgress(_monthlyPoin);

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: JabatanHelper.getCardGradient(
            isVerificatorFlag: widget.isVerificator,
            idJabatan: widget.userJabatanId,
          ),
          stops: const [0.0, 0.35, 0.65, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── BARIS ATAS: Avatar + Nama + Role | Lokasi di kanan ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF00C9E4),
                  backgroundImage: widget.userImage != null
                      ? CachedNetworkImageProvider(widget.userImage!)
                      : null,
                  child: widget.userImage == null
                      ? const Icon(Icons.person, color: Colors.white, size: 26)
                      : null,
                ),
              ),
              const SizedBox(width: 12),

              // Nama + Role (mengisi ruang fleksibel)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      // Fallback: jika isVerificator true tapi userRole belum terupdate
                      (widget.isVerificator == true &&
                          !widget.userRole.toLowerCase().contains('verif'))
                          ? (widget.lang == 'ZH' ? '验证者' : 'Verificator')
                          : widget.userRole,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // ── LOKASI di sisi kanan nama (sejajar vertikal) ──
              Container(
                constraints: const BoxConstraints(maxWidth: 130),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.place_rounded,
                      size: 13,
                      color: Color(0xFF0EA5E9),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        widget.userLocationName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── PROGRESS BAR POIN ──
          LayoutBuilder(
            builder: (context, constraints) {
              final double fireIconSize = 26.0;
              final double circlePadding = 6.0;
              final double totalSize = fireIconSize + (circlePadding * 2);
              final double rawLeft = constraints.maxWidth * pointProgress;
              final double clampedLeft =
                  rawLeft.clamp(0.0, constraints.maxWidth - totalSize);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Track bar
                  Container(
                    margin: EdgeInsets.only(top: totalSize / 2),
                    width: double.infinity,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          width: rawLeft.clamp(0.0, constraints.maxWidth),
                          decoration: BoxDecoration(
                            color: fireColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Fire icon indicator
                  Positioned(
                    left: clampedLeft,
                    top: 0,
                    child: Column(
                      children: [
                        Container(
                          width: totalSize,
                          height: totalSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: fireColor.withOpacity(0.15),
                            border: Border.all(
                              color: fireColor.withOpacity(0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: fireColor.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.local_fire_department_rounded,
                              color: fireColor,
                              size: fireIconSize,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _isLoadingMonthly ? '... P' : '$_monthlyPoin P',
                          style: GoogleFonts.poppins(
                            color: fireColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 40),

          // ── BARIS BAWAH: Log terbaru + Tombol View More ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Kiri: Log aktivitas terbaru
              Expanded(
                child: widget.isLatestLogLoading
                    ? Row(
                        children: [
                          Container(
                            width: 12, height: 12,
                            margin: const EdgeInsets.only(right: 6),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF00C9E4),
                            ),
                          ),
                          Text('...', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                        ],
                      )
                    : widget.latestLogPoin == null
                        ? Text(
                            '-',
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                          )
                        : _buildLatestLog(),
              ),
              const SizedBox(width: 8),

              // Kanan: Tombol View More
              ElevatedButton(
                onPressed: widget.onViewMoreTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getTxt('view_more'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}