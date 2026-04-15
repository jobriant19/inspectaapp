import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'accident_report_form_screen.dart'; // File form yang akan kita buat
import 'accident_report_detail_screen.dart'; // File detail yang akan kita buat

class AccidentReportListScreen extends StatefulWidget {
  final String lang;
  const AccidentReportListScreen({super.key, required this.lang});

  @override
  State<AccidentReportListScreen> createState() => _AccidentReportListScreenState();
}

class _AccidentReportListScreenState extends State<AccidentReportListScreen> {
  late Future<List<Map<String, dynamic>>> _reportsFuture;
  final Map<String, Map<String, String>> _text = {
    'EN': {
      'title': 'Accident Reports',
      'add_report': 'Add Report',
      'delete': 'Delete',
      'edit': 'Edit',
      'confirm_delete': 'Confirm Deletion',
      'confirm_delete_msg': 'Are you sure you want to delete this report? This action cannot be undone.',
      'cancel': 'Cancel',
      'empty_title': 'No Reports Found',
      'empty_subtitle': 'Press the + button to add a new accident report.',
      'by': 'by',
      'empty_info': 'Report any work-related accidents or near misses to help improve safety for everyone. Your report makes a difference.',
    },
    'ID': {
      'title': 'Laporan Kecelakaan',
      'add_report': 'Tambah Laporan',
      'delete': 'Hapus',
      'edit': 'Ubah',
      'confirm_delete': 'Konfirmasi Penghapusan',
      'confirm_delete_msg': 'Apakah Anda yakin ingin menghapus laporan ini? Tindakan ini tidak dapat dibatalkan.',
      'cancel': 'Batal',
      'empty_title': 'Tidak Ada Laporan',
      'empty_subtitle': 'Tekan tombol + untuk menambahkan laporan kecelakaan baru.',
      'by': 'oleh',
      'empty_info': 'Laporkan setiap kecelakaan kerja atau nyaris celaka (near miss) untuk membantu meningkatkan keselamatan bagi semua. Laporan Anda sangat berarti.',
    },
    'ZH': {
      'title': '事故报告',
      'add_report': '添加报告',
      'delete': '删除',
      'edit': '编辑',
      'confirm_delete': '确认删除',
      'confirm_delete_msg': '您确定要删除此报告吗？此操作无法撤销。',
      'cancel': '取消',
      'empty_title': '未找到任何报告',
      'empty_subtitle': '按 + 按钮添加新的事故报告。',
      'by': '由',
      'empty_info': '报告任何与工作相关的事故或未遂事故，以帮助改善每个人的安全。您的报告至关重要。',
    },
  };

  String getTxt(String key) => _text[widget.lang]![key] ?? key;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _fetchReports();
  }

  Future<List<Map<String, dynamic>>> _fetchReports() async {
    final response = await Supabase.instance.client
        .from('laporan_kecelakaan')
        .select()
        .order('created_at', ascending: false);
    return response;
  }

  void _refreshReports() {
    setState(() {
      _reportsFuture = _fetchReports();
    });
  }

  void _navigateAndRefresh() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccidentReportFormScreen(lang: widget.lang),
      ),
    );
    if (result == true) {
      _refreshReports();
    }
  }

  Future<void> _deleteReport(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getTxt('confirm_delete')),
        content: Text(getTxt('confirm_delete_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(getTxt('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(getTxt('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client.from('laporan_kecelakaan').delete().eq('id', id);
        _refreshReports();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Laporan berhasil dihapus.'), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal menghapus laporan: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(getTxt('title'), style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final reports = snapshot.data;
          
          if (reports == null || reports.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/team_illustration.png',
                      height: 180,
                      errorBuilder: (c,e,s) => const Icon(Icons.report_off_outlined, size: 100, color: Colors.grey)
                    ),
                    const SizedBox(height: 24),
                    Text(
                      getTxt('empty_title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      getTxt('empty_info'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _navigateAndRefresh,
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(getTxt('add_report')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C9E4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return _buildReportCard(report);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: ElevatedButton.icon(
                  onPressed: _navigateAndRefresh,
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(getTxt('add_report')),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color(0xFF00C9E4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final String imageUrl = report['gambar_url'] ?? '';
    final String category = report['kategori'] ?? 'N/A';
    final String status = report['status'] ?? 'Baru';
    final String reporter = report['nama_pelapor'] ?? 'Anonim';
    final DateTime createdAt = DateTime.parse(report['created_at']);
    final String date = '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    final bool isOwner = report['id_user'] == Supabase.instance.client.auth.currentUser?.id;

    // Status Styling
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'Selesai':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Dalam Penanganan':
        statusColor = Colors.orange.shade700;
        statusIcon = Icons.hourglass_top;
        break;
      default: // 'Baru'
        statusColor = Colors.red;
        statusIcon = Icons.new_releases;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => AccidentReportDetailScreen(lang: widget.lang, report: report),
        ));
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        color: const Color(0xFFF8F9FF), // Warna latar biru sangat muda
        clipBehavior: Clip.antiAlias, // Penting agar gambar mengikuti border radius
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 50),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16), // Padding diperbesar agar lebih lega
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kategori di sebelah kiri
                      Expanded(
                        child: Text(
                          category,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status di sebelah kanan
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 14),
                            const SizedBox(width: 6),
                            Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${getTxt('by')} $reporter • $date',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (isOwner)
              Container(
                color: Colors.grey.withOpacity(0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.edit, size: 18, color: Color(0xFF1E3A8A)),
                        label: Text(getTxt('edit'), style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AccidentReportFormScreen(lang: widget.lang, initialData: report),
                            ),
                          );
                          if (result == true) {
                            _refreshReports();
                          }
                        },
                      ),
                    ),
                    Container(height: 30, width: 1, color: Colors.grey.shade300), // Garis pemisah vertikal
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        label: Text(getTxt('delete'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        onPressed: () => _deleteReport(report['id']),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}