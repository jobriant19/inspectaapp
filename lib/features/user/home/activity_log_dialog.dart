import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';

class ActivityLogDialog extends StatefulWidget {
  final String lang;
  final String userName;
  final String userRole;
  final String? userImage;
  final int userPoin;
  // ✅ TAMBAHAN: data log terbaru yang sudah ada di HomeScreen
  final Map<String, dynamic>? initialLatestLog;

  const ActivityLogDialog({
    super.key,
    required this.lang,
    required this.userName,
    required this.userRole,
    required this.userPoin,
    this.userImage,
    this.initialLatestLog, // ✅ opsional
  });

  @override
  State<ActivityLogDialog> createState() => _ActivityLogDialogState();
}

class _ActivityLogDialogState extends State<ActivityLogDialog> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // ✅ Tampilkan data awal langsung jika tersedia, tanpa tunggu fetch
    if (widget.initialLatestLog != null) {
      _logs = [Map<String, dynamic>.from(widget.initialLatestLog!)];
      _isLoading = false;
    }

    // Tetap fetch data lengkap di background
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('log_poin')
          .select('poin, deskripsi, tipe_aktivitas, created_at')
          .eq('id_user', userId)
          .order('created_at', ascending: false)
          .limit(25);

      if (mounted) {
        setState(() {
          _logs = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getTxt(String key) {
    final Map<String, Map<String, String>> texts = {
      'EN': {
        'title': 'Activity Log',
        'close': 'Close',
        'empty': 'No activity yet.',
        'total_points': 'Total Points',
        'subtitle': 'Your point history',
      },
      'ID': {
        'title': 'Log Aktivitas',
        'close': 'Tutup',
        'empty': 'Belum ada aktivitas.',
        'total_points': 'Total Poin',
        'subtitle': 'Riwayat poin Anda',
      },
      'ZH': {
        'title': '活动日志',
        'close': '关闭',
        'empty': '暂无活动。',
        'total_points': '总积分',
        'subtitle': '您的积分历史',
      },
    };
    return texts[widget.lang]?[key] ?? key;
  }

  Color _getFireColor(int points) {
    if (points >= 1000) return const Color(0xFFEF4444);
    if (points >= 500) return const Color(0xFFF97316);
    if (points >= 100) return const Color(0xFF22C55E);
    if (points > 0) return const Color(0xFF3B82F6);
    return Colors.grey.shade400;
  }

  IconData _getTipeIcon(String tipe, bool isPositive) {
    switch (tipe) {
      case 'login_pertama':
        return Icons.celebration_rounded;
      case 'login_harian':
        return Icons.today_rounded;
      case 'login_pertama_hari_ini':
        return Icons.emoji_events_rounded;
      case 'penalti':
        return Icons.warning_amber_rounded;
      default:
        return isPositive
            ? Icons.star_rounded
            : Icons.remove_circle_outline_rounded;
    }
  }

  Color _getTipeColor(String tipe, bool isPositive) {
    switch (tipe) {
      case 'login_pertama':
        return const Color(0xFFEC4899);
      case 'login_harian':
        return const Color(0xFF3B82F6);
      case 'login_pertama_hari_ini':
        return const Color(0xFFF59E0B);
      case 'penalti':
        return const Color(0xFFEF4444);
      default:
        return isPositive
            ? const Color(0xFF16A34A)
            : const Color(0xFFDC2626);
    }
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  Widget _buildLogList() {
    // ✅ Shimmer hanya muncul jika benar-benar belum ada data sama sekali
    if (_isLoading && _logs.isEmpty) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade50,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          itemCount: 6,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 10,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(
              _getTxt('empty'),
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      physics: const BouncingScrollPhysics(),
      itemCount: _logs.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Colors.grey.shade100, indent: 52),
      itemBuilder: (context, index) {
        final log = _logs[index];
        final int poin = (log['poin'] as num).toInt();
        final bool isPositive = poin >= 0;
        final String tipe = (log['tipe_aktivitas'] ?? '').toString();
        final String desc = (log['deskripsi'] ?? '').toString();
        final String dateStr = _formatDate(log['created_at']);

        final IconData icon = _getTipeIcon(tipe, isPositive);
        final Color iconColor = _getTipeColor(tipe, isPositive);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withOpacity(0.1),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPositive ? '+$poin' : '$poin',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fireColor = _getFireColor(widget.userPoin);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── HEADER ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3A8A), Color(0xFF0EA5E9)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar — pakai CachedNetworkImage agar dari cache
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          // ✅ Gunakan NetworkImage biasa — gambar sudah di cache
                          // oleh precacheImage yang dipanggil sebelum navigasi
                          backgroundImage: widget.userImage != null
                              ? NetworkImage(widget.userImage!)
                              : null,
                          child: widget.userImage == null
                              ? const Icon(Icons.person,
                                  color: Colors.white, size: 30)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 14),
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
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.userRole,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.local_fire_department_rounded,
                                color: fireColor, size: 22),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.userPoin}',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _getTxt('total_points'),
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.history_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        _getTxt('title'),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• ${_getTxt('subtitle')}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── DAFTAR LOG ──
            SizedBox(height: 340, child: _buildLogList()),

            // ── FOOTER ──
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(28)),
                border: Border(
                    top: BorderSide(color: Colors.grey.shade100, width: 1)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                          color: const Color(0xFF1E3A8A).withOpacity(0.2)),
                    ),
                  ),
                  child: Text(
                    _getTxt('close'),
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}