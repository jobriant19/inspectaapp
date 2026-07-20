import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'report_detail_screen.dart';
import 'package:intl/intl.dart';

class HelpCenterScreen extends StatefulWidget {
  final String lang;
  const HelpCenterScreen({super.key, required this.lang});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  late String _currentLang;
  List<Map<String, dynamic>> _reports = [];

  final Map<String, Map<String, String>> _txt = {
    'EN': {
      'title': 'Help Center',
      'report_issue': 'Report an Issue',
      'report_subtitle': 'Let us know about bugs or problems you encounter.',
      'history': 'Your Report History',
      'empty_title': 'No Reports Yet',
      'empty_subtitle': 'Your submitted reports will appear here.',
      'fatal': 'Fatal',
      'normal': 'Normal',
      'sent': 'Sent',
      'viewed': 'Viewed',
      'completed': 'Completed',
      'close': 'Close',
    },
    'ID': {
      'title': 'Pusat Bantuan',
      'report_issue': 'Laporkan Kendala',
      'report_subtitle': 'Beri tahu kami bug atau masalah yang Anda temui.',
      'history': 'Riwayat Laporan Anda',
      'empty_title': 'Belum Ada Laporan',
      'empty_subtitle': 'Laporan yang Anda kirim akan muncul di sini.',
      'fatal': 'Fatal',
      'normal': 'Normal',
      'sent': 'Dikirim',
      'viewed': 'Dilihat',
      'completed': 'Selesai',
      'close': 'Tutup',
    },
    'ZH': {
      'title': '帮助中心',
      'report_issue': '报告问题',
      'report_subtitle': '让我们知道您遇到的错误或问题。',
      'history': '您的报告历史',
      'empty_title': '尚无报告',
      'empty_subtitle': '您提交的报告将显示在此处。',
      'fatal': '致命',
      'normal': '普通',
      'sent': '已发送',
      'viewed': '已查看',
      'completed': '已完成',
      'close': '关闭',
    },
  };

  String getTxt(String key) => _txt[_currentLang]?[key] ?? key;

  IconData _priorityIcon(String p) =>
      p.toLowerCase() == 'fatal' ? Icons.warning_amber_rounded : Icons.info_outline_rounded;

  IconData _statusIcon(String s) {
    switch (s) {
      case 'Dikirim':
        return Icons.send_rounded;
      case 'Dilihat':
        return Icons.visibility_rounded;
      case 'Selesai':
        return Icons.check_circle_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  void _openImageViewer(String url) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha:0.95),
        pageBuilder: (_, __, ___) => _FullImageViewerHC(imageUrl: url, closeLabel: getTxt('close')),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _currentLang = widget.lang;
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    if (!mounted) return;
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final response = await Supabase.instance.client
          .from('help_reports')
          .select('id, title, description, priority, status, image_url, created_at, edited_at, admin_reply, replied_at, admin_reply_image')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final reportsWithSignedUrls = <Map<String, dynamic>>[];
      for (var report in response) {
        final newReport = Map<String, dynamic>.from(report);
        final imageUrl = newReport['image_url'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            final path = imageUrl.split('/report_images/').last;
            final signedUrl = await Supabase.instance.client.storage
                .from('report_images')
                .createSignedUrl(path, 3600);
            newReport['signed_image_url'] = signedUrl;
          } catch (e) {
            newReport['signed_image_url'] = null;
          }
        }
        reportsWithSignedUrls.add(newReport);
      }

      if (mounted) {
        setState(() {
          _reports = reportsWithSignedUrls;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildReportButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 350),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (_, __, ___) =>
                ReportDetailScreen(lang: _currentLang),
            transitionsBuilder: (_, animation, __, child) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
                reverseCurve: Curves.easeIn,
              );
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              );
            },
          ),
        );
        if (result == true) _fetchReports();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1D72F3), Color(0xFF00C9E4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1D72F3).withValues(alpha:0.35),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.support_agent,
                  color: Colors.white, size: 32),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getTxt('report_issue'),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    getTxt('report_subtitle'),
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha:0.85)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildReportList() {
    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            Icon(Icons.inbox_outlined,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(
              getTxt('empty_title'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D72F3),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              getTxt('empty_subtitle'),
              style: TextStyle(
                  fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _reports.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return _buildReportCard(_reports[index]);
      },
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final signedImageUrl = report['signed_image_url'] as String?;
    final adminReply = report['admin_reply'] as String?;
    final adminReplyImage = report['admin_reply_image'] as String?;
    final repliedAt = report['replied_at'] as String?;
    final createdAt = report['created_at'] as String?;
    final status = report['status'] as String? ?? 'Dikirim';
    final priority = report['priority'] as String? ?? 'Normal';

    Color statusColor;
    switch (status) {
      case 'Dilihat':
        statusColor = Colors.orange.shade400;
        break;
      case 'Selesai':
        statusColor = Colors.green.shade500;
        break;
      default:
        statusColor = const Color(0xFF1D72F3);
    }

    final statusLabel = getTxt(status == 'Dikirim'
        ? 'sent'
        : status == 'Dilihat'
            ? 'viewed'
            : 'completed');

    String dateStr = '';
    if (createdAt != null) {
      try {
        dateStr = DateFormat('d MMM yyyy, HH:mm').format(DateTime.parse(createdAt).toLocal());
      } catch (_) {}
    }

    String repliedStr = '';
    if (repliedAt != null) {
      try {
        repliedStr = DateFormat('d MMM yyyy, HH:mm').format(DateTime.parse(repliedAt).toLocal());
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 350),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (_, __, ___) =>
                ReportDetailScreen(lang: _currentLang, report: report),
            transitionsBuilder: (_, animation, __, child) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
                reverseCurve: Curves.easeIn,
              );
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              );
            },
          ),
        );
        if (result == true) _fetchReports();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha:0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
          border: Border(left: BorderSide(color: statusColor, width: 3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: (signedImageUrl != null && signedImageUrl.isNotEmpty)
                        ? () => _openImageViewer(signedImageUrl)
                        : null,
                    child: (signedImageUrl != null && signedImageUrl.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              signedImageUrl,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported, size: 70),
                            ),
                          )
                        : Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: const Color(0xFFEFF6FF),
                            ),
                            child: Icon(Icons.flag_outlined,
                                color: Colors.grey.shade400, size: 30),
                          ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report['title'] ?? '',
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF334155)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildTag(
                              getTxt(priority.toLowerCase() == 'fatal' ? 'fatal' : 'normal'),
                              priority.toLowerCase() == 'fatal'
                                  ? Colors.red.shade400
                                  : const Color(0xFF1D72F3),
                              _priorityIcon(priority),
                            ),
                            _buildTag(statusLabel, statusColor, _statusIcon(status)),
                          ],
                        ),
                        if (dateStr.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 11, color: Colors.grey.shade500),
                                const SizedBox(width: 5),
                                Text(
                                  dateStr,
                                  style: GoogleFonts.poppins(
                                      fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                ],
              ),
              if (adminReply != null && adminReply.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha:0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha:0.15),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Icon(Icons.support_agent_rounded,
                                size: 13, color: Color(0xFF10B981)),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            _currentLang == 'EN'
                                ? 'Admin Reply'
                                : _currentLang == 'ZH'
                                    ? '管理员回复'
                                    : 'Balasan Admin',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF10B981)),
                          ),
                          if (repliedStr.isNotEmpty) ...[
                            const Spacer(),
                            Icon(Icons.access_time_rounded, size: 11, color: Colors.grey.shade500),
                            const SizedBox(width: 3),
                            Text(repliedStr,
                                style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    color: Colors.grey.shade500)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(adminReply,
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: const Color(0xFF334155), height: 1.5)),
                      if (adminReplyImage != null &&
                          adminReplyImage.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _openImageViewer(adminReplyImage),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  adminReplyImage,
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.image_not_supported,
                                      size: 40),
                                ),
                              ),
                              Positioned(
                                right: 8, bottom: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha:0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.zoom_out_map_rounded, size: 14, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha:0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: GoogleFonts.poppins(
                  color: color, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1D72F3)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          getTxt('title'),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D72F3),
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha:0.08),
        iconTheme: const IconThemeData(color: Color(0xFF1D72F3)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReports,
        color: const Color(0xFF1D72F3),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportButton(context),
              const SizedBox(height: 28),
              Text(
                getTxt('history'),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1D72F3),
                ),
              ),
              const SizedBox(height: 14),
              _buildReportList(),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullImageViewerHC extends StatelessWidget {
  final String imageUrl;
  final String closeLabel;

  const _FullImageViewerHC({required this.imageUrl, required this.closeLabel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black.withValues(alpha:0.001)),
            ),
          ),
          Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.white54, size: 60),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.3), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(closeLabel, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}