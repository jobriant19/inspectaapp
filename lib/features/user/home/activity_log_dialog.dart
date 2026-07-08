import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/utils/jabatan_helper.dart';

class ActivityLogDialog extends StatefulWidget {
  final String lang;
  final String userName;
  final String userRole;
  final String? userImage;
  final int userPoin;
  final Map<String, dynamic>? initialLatestLog;
  final List<Map<String, dynamic>>? initialLogs;
  final bool? isVerificator;
  final int? userJabatanId;

  const ActivityLogDialog({
    super.key,
    required this.lang,
    required this.userName,
    required this.userRole,
    required this.userPoin,
    this.userImage,
    this.initialLatestLog,
    this.initialLogs,
    this.isVerificator,
    this.userJabatanId,
  });

  @override
  State<ActivityLogDialog> createState() => _ActivityLogDialogState();
}

class _ActivityLogDialogState extends State<ActivityLogDialog> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  int _monthlyPoin = 0;

  @override
  void initState() {
    super.initState();

    if (widget.initialLogs != null && widget.initialLogs!.isNotEmpty) {
      _logs = List<Map<String, dynamic>>.from(widget.initialLogs!);
      _monthlyPoin = _sumPoin(_logs);
      _isLoading = false;
    } else if (widget.initialLatestLog != null) {
      _logs = [Map<String, dynamic>.from(widget.initialLatestLog!)];
      _isLoading = false;
    }
    _fetchLogs();
    _fetchMonthlyPoin();
  }

  int _sumPoin(List<Map<String, dynamic>> logs) {
    int total = 0;
    for (final log in logs) {
      total += ((log['poin'] as num?)?.toInt() ?? 0);
    }
    return total;
  }

  Future<void> _fetchLogs() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
      final startOfNextMonth = DateTime(now.year, now.month + 1, 1).toIso8601String();

      final data = await Supabase.instance.client
          .from('log_poin')
          .select('poin, deskripsi, tipe_aktivitas, created_at')
          .eq('id_user', userId)
          .gte('created_at', startOfMonth)
          .lt('created_at', startOfNextMonth)
          .order('created_at', ascending: false);

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

  Future<void> _fetchMonthlyPoin() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
      final startOfNextMonth =
          DateTime(now.year, now.month + 1, 1).toIso8601String();

      final List<dynamic> logs = await Supabase.instance.client
          .from('log_poin')
          .select('poin')
          .eq('id_user', userId)
          .gte('created_at', startOfMonth)
          .lt('created_at', startOfNextMonth);

      int total = 0;
      for (final log in logs) {
        total += ((log['poin'] as num?)?.toInt() ?? 0);
      }

      if (mounted) setState(() => _monthlyPoin = total);
    } catch (_) {}
  }

  String _getTxt(String key) {
    final Map<String, Map<String, String>> texts = {
      'EN': {
        'title': 'Your Activity Log History',
        'close': 'Close',
        'empty': 'No activity yet.',
        'total_points': 'Total Points This Month',
      },
      'ID': {
        'title': 'Riwayat Log Aktivitas Anda',
        'close': 'Tutup',
        'empty': 'Belum ada aktivitas.',
        'total_points': 'Total Poin Bulan Ini',
      },
      'ZH': {
        'title': '您的活动日志历史',
        'close': '关闭',
        'empty': '暂无活动。',
        'total_points': '本月总积分',
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

  Color _darken(Color color, [double amount = 0.16]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  String _formatDate(String? raw) {
    if (raw == null) return '-';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '-';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) {
      return widget.lang == 'ZH'
          ? '刚刚'
          : widget.lang == 'EN'
              ? 'Just now'
              : 'Baru saja';
    }
    if (diff.inHours < 1) {
      return widget.lang == 'ZH'
          ? '${diff.inMinutes}分钟前'
          : widget.lang == 'EN'
              ? '${diff.inMinutes} min ago'
              : '${diff.inMinutes} menit lalu';
    }
    if (diff.inDays < 1) {
      return widget.lang == 'ZH'
          ? '${diff.inHours}小时前'
          : widget.lang == 'EN'
              ? '${diff.inHours} hr ago'
              : '${diff.inHours} jam lalu';
    }
    if (diff.inDays < 7) {
      return widget.lang == 'ZH'
          ? '${diff.inDays}天前'
          : widget.lang == 'EN'
              ? '${diff.inDays} days ago'
              : '${diff.inDays} hari lalu';
    }
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  Widget _buildLogList() {
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
                  color: iconColor.withValues(alpha:0.1),
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
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 10, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha:0.1),
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
    final fireColor = _getFireColor(_monthlyPoin);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.12),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: JabatanHelper.getCardGradient(
                    isVerificatorFlag: widget.isVerificator,
                    idJabatan: widget.userJabatanId,
                  ),
                  stops: const [0.0, 0.35, 0.65, 1.0],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // AVATAR
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyan.withValues(alpha:0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFF1D72F3),
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
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Builder(
                              builder: (context) {
                                final String displayRole = (widget.isVerificator == true &&
                                        !widget.userRole.toLowerCase().contains('verif'))
                                    ? (widget.lang == 'ZH' ? '验证者' : 'Verificator')
                                    : widget.userRole;
                                final Color badgeColor = JabatanHelper.getPrimaryColor(
                                  isVerificatorFlag: widget.isVerificator,
                                  idJabatan: widget.userJabatanId,
                                );
                                final IconData badgeIcon = JabatanHelper.getRoleIcon(
                                  isVerificatorFlag: widget.isVerificator,
                                  idJabatan: widget.userJabatanId,
                                );
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [badgeColor, _darken(badgeColor)],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.75), width: 1.1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: badgeColor.withValues(alpha: 0.35),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(badgeIcon, size: 11.5, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          displayRole,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        constraints: const BoxConstraints(minWidth: 96),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              fireColor.withValues(alpha: 0.85),
                              fireColor,
                              _darken(fireColor, 0.22),
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.75),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: fireColor.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_fire_department_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 5),
                                Text(
                                  '$_monthlyPoin',
                                  style: GoogleFonts.poppins(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _getTxt('total_points'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(9, 8, 16, 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.history_rounded,
                                color: Color(0xFF0F172A), size: 15),
                          ),
                          const SizedBox(width: 9),
                          Text(
                            _getTxt('title'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // LOG LIST
            SizedBox(height: 340, child: _buildLogList()),

            // FOOTER
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
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D72F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _getTxt('close'),
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800, fontSize: 14.5),
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