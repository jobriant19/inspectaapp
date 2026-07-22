import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
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
  bool _isLoading = true;
  int _currentPage = 1;
  static const int _perPage = 6;

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

  void _editReport(Map<String, dynamic> report) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => ReportDetailScreen(lang: _currentLang, report: report, startInEditing: true),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut, reverseCurve: Curves.easeIn);
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(curved),
            child: child,
          );
        },
      ),
    );
    if (result == true) _fetchReports();
  }

  Future<void> _deleteReport(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(color: Color(0xFFFFEBEB), shape: BoxShape.circle),
                child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 38),
              ),
              const SizedBox(height: 20),
              Text(
                _currentLang == 'EN' ? 'Delete?' : _currentLang == 'ZH' ? '删除？' : 'Hapus?',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${_currentLang == 'EN' ? 'Are you sure you want to delete report' : _currentLang == 'ZH' ? '确定要删除报告' : 'Yakin ingin menghapus laporan'} "$title"?',
                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B), height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 18),
                  label: Text(
                    _currentLang == 'EN' ? 'Delete' : _currentLang == 'ZH' ? '删除' : 'Hapus',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _currentLang == 'EN' ? 'Cancel' : _currentLang == 'ZH' ? '取消' : 'Batal',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF64748B)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;
    try {
      await Supabase.instance.client.from('help_reports').delete().eq('id', id);
      _fetchReports();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
      // ignore: unused_local_variable
      final _ = 0;
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

        final replyImageUrl = newReport['admin_reply_image'] as String?;
        if (replyImageUrl != null && replyImageUrl.isNotEmpty) {
          try {
            final path = replyImageUrl.split('/report_images/').last;
            final signedReplyUrl = await Supabase.instance.client.storage
                .from('report_images')
                .createSignedUrl(path, 3600);
            newReport['signed_admin_reply_image'] = signedReplyUrl;
          } catch (e) {
            newReport['signed_admin_reply_image'] = null;
          }
        }

        reportsWithSignedUrls.add(newReport);
      }

      if (mounted) {
        setState(() {
          _reports = reportsWithSignedUrls;
          _currentPage = 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
            pageBuilder: (_, __, ___) => ReportDetailScreen(lang: _currentLang),
            transitionsBuilder: (_, animation, __, child) {
              final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut, reverseCurve: Curves.easeIn);
              return SlideTransition(
                position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(curved),
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
            BoxShadow(color: const Color(0xFF1D72F3).withValues(alpha:0.35), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(getTxt('report_issue'),
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(getTxt('report_subtitle'),
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha:0.85))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              height: 160,
              errorBuilder: (_, __, ___) => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D72F3).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.inbox_outlined, size: 64, color: Color(0xFF1D72F3)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              getTxt('empty_title'),
              style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1D72F3)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              getTxt('empty_subtitle'),
              style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.grey.shade500, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16, width: 140, color: Colors.white),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(height: 22, width: 60, color: Colors.white),
                      const SizedBox(width: 8),
                      Container(height: 22, width: 70, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(height: 18, width: 110, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final signedImageUrl = report['signed_image_url'] as String?;
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

    final statusLabel = getTxt(status == 'Dikirim' ? 'sent' : status == 'Dilihat' ? 'viewed' : 'completed');

    String dateStr = '';
    if (createdAt != null) {
      try { dateStr = DateFormat('d MMM yyyy, HH:mm').format(DateTime.parse(createdAt).toLocal()); } catch (_) {}
    }

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 350),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (_, __, ___) => ReportDetailScreen(lang: _currentLang, report: report),
            transitionsBuilder: (_, animation, __, child) {
              final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut, reverseCurve: Curves.easeIn);
              return SlideTransition(
                position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(curved),
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border(left: BorderSide(color: statusColor, width: 3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: (signedImageUrl != null && signedImageUrl.isNotEmpty) ? () => _openImageViewer(signedImageUrl) : null,
                    child: (signedImageUrl != null && signedImageUrl.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              signedImageUrl,
                              width: 88, height: 88, fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 88, height: 88, color: const Color(0xFFEFF6FF),
                                child: const Icon(Icons.image_not_supported, size: 30),
                              ),
                            ),
                          )
                        : Container(
                            width: 88, height: 88,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: const Color(0xFFEFF6FF)),
                            child: Icon(Icons.flag_outlined, color: Colors.grey.shade400, size: 32),
                          ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report['title'] ?? '',
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
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
                              priority.toLowerCase() == 'fatal' ? Colors.red.shade400 : const Color(0xFF1D72F3),
                              _priorityIcon(priority),
                            ),
                            _buildTag(statusLabel, statusColor, _statusIcon(status)),
                          ],
                        ),
                        if (dateStr.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 11, color: Colors.grey.shade500),
                                const SizedBox(width: 5),
                                Text(dateStr, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (status == 'Dikirim')
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _editReport(report),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha:0.10),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 17),
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _deleteReport(report['id'].toString(), report['title'] ?? ''),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha:0.10),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 17),
                          ),
                        ),
                      ],
                    )
                  else
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha:0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(text, style: GoogleFonts.poppins(color: color, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = _reports.isEmpty ? 1 : (_reports.length / _perPage).ceil();
    final safePage = _currentPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * _perPage;
    final endIdx = (startIdx + _perPage) > _reports.length ? _reports.length : startIdx + _perPage;
    final pageData = _reports.isEmpty ? <Map<String, dynamic>>[] : _reports.sublist(startIdx, endIdx);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1D72F3)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          getTxt('title'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1D72F3), fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        shadowColor: Colors.black.withValues(alpha:0.08),
        iconTheme: const IconThemeData(color: Color(0xFF1D72F3)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchReports,
              color: const Color(0xFF1D72F3),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReportButton(context),
                    const SizedBox(height: 28),
                    Text(
                      getTxt('history'),
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1D72F3)),
                    ),
                    const SizedBox(height: 14),
                    if (_isLoading)
                      ...List.generate(3, (_) => _buildShimmerCard())
                    else if (_reports.isEmpty)
                      _buildEmptyState()
                    else
                      ...pageData.map((r) => _buildReportCard(r)),
                  ],
                ),
              ),
            ),
          ),
          if (!_isLoading && _reports.isNotEmpty && totalPages > 1)
            _HelpCenterPageIndicator(
              currentPage: safePage,
              totalPages: totalPages,
              onPageChanged: (p) => setState(() => _currentPage = p),
              color: const Color(0xFF1D72F3),
            ),
        ],
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
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
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

class _HelpCenterPageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final Color color;

  const _HelpCenterPageIndicator({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.color,
  });

  static const int _maxVisibleButtons = 5;

  List<int> _visiblePageNumbers() {
    if (totalPages <= _maxVisibleButtons) {
      return List.generate(totalPages, (i) => i + 1);
    }
    int start = currentPage - 2;
    int end = currentPage + 2;
    if (start < 1) {
      start = 1;
      end = _maxVisibleButtons;
    } else if (end > totalPages) {
      end = totalPages;
      start = totalPages - (_maxVisibleButtons - 1);
    }
    return List.generate(end - start + 1, (i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    final bool canPrev = currentPage > 1;
    final bool canNext = currentPage < totalPages;
    final pageNumbers = _visiblePageNumbers();

    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double bottomSpacing = bottomInset > 0 ? bottomInset + 10 : 16;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(15, 8, 15, bottomSpacing),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            _arrowButton(
              icon: Icons.arrow_back_ios_new_rounded,
              enabled: canPrev,
              onTap: () { if (!canPrev) return; onPageChanged(currentPage - 1); },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  for (final p in pageNumbers) ...[
                    Expanded(child: _pageButton(p)),
                    if (p != pageNumbers.last) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            _arrowButton(
              icon: Icons.arrow_forward_ios_rounded,
              enabled: canNext,
              onTap: () { if (!canNext) return; onPageChanged(currentPage + 1); },
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageButton(int page) {
    final bool isActive = page == currentPage;
    return GestureDetector(
      onTap: () { if (page == currentPage) return; onPageChanged(page); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: isActive ? null : Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(
          '$page',
          style: GoogleFonts.poppins(color: isActive ? Colors.white : color, fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ),
    );
  }

  Widget _arrowButton({required IconData icon, required bool enabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: enabled ? color : Colors.grey.shade400),
      ),
    );
  }
}