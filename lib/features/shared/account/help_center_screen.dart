import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'report_detail_screen.dart';

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
    },
  };

  String getTxt(String key) => _txt[_currentLang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _currentLang = widget.lang;
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final response = await Supabase.instance.client
          .from('help_reports')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // List baru untuk menampung report dengan signed URL
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
            print("Error creating signed URL in Help Center: $e");
            newReport['signed_image_url'] = null;
          }
        }
        reportsWithSignedUrls.add(newReport);
      }

      if (mounted) {
        setState(() {
          _reports = reportsWithSignedUrls;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching reports: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildReportButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ReportDetailScreen(lang: _currentLang)),
        );
        if (result == true) _fetchReports();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.support_agent, color: Colors.white, size: 40),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(getTxt('report_issue'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(getTxt('report_subtitle'), style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildReportList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)));
    }
    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(getTxt('empty_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
            const SizedBox(height: 8),
            Text(getTxt('empty_subtitle'), style: TextStyle(fontSize: 16, color: Colors.grey.shade600), textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _reports.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final report = _reports[index];
        // Cukup panggil _buildReportCard dengan data report
        return _buildReportCard(report);
      },
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    // Ambil URL langsung dari 'image_url'
    final signedImageUrl = report['signed_image_url'] as String?;

    return GestureDetector(
      onTap: () async {
        // Kirim 'report' yang sudah berisi 'image_url'
        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => ReportDetailScreen(lang: _currentLang, report: report)));
        if (result == true) _fetchReports();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Row(
          children: [
            // Gunakan imageUrl di sini
            if (signedImageUrl != null && signedImageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(signedImageUrl, width: 70, height: 70, fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 70),
                ),
              )
            else
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey.shade100),
                child: Icon(Icons.flag_outlined, color: Colors.grey.shade400, size: 30),
              ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTag(getTxt(report['priority'].toLowerCase()), report['priority'].toLowerCase() == 'fatal' ? Colors.red.shade400 : Colors.blue.shade400),
                      const SizedBox(width: 8),
                      _buildTag(getTxt(report['status'].toLowerCase()), Colors.grey.shade600),
                    ],
                  )
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(getTxt('title'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        backgroundColor: Colors.transparent, elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)), centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReports,
        color: const Color(0xFF1E3A8A),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportButton(context),
              const SizedBox(height: 30),
              Text(getTxt('history'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
              const SizedBox(height: 15),
              _buildReportList(),
            ],
          ),
        ),
      ),
    );
  }
}