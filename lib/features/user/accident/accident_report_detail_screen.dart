import 'package:flutter/material.dart';

class AccidentReportDetailScreen extends StatelessWidget {
  final String lang;
  final Map<String, dynamic> report;

  const AccidentReportDetailScreen({
    super.key,
    required this.lang,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final String imageUrl = report['gambar_url'] ?? '';
    final String category = report['kategori'] ?? 'N/A';
    final String status = report['status'] ?? 'Baru';
    final String description = report['deskripsi'] ?? 'Tidak ada deskripsi.';
    final String reporter = report['nama_pelapor'] ?? 'Anonim';
    final DateTime createdAt = DateTime.parse(report['created_at']);
    final String date = '${createdAt.day}/${createdAt.month}/${createdAt.year}';

    // Status Styling
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'Selesai':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Dalam Penanganan':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_top;
        break;
      default: // 'Baru'
        statusColor = Colors.red;
        statusIcon = Icons.new_releases;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(category, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  height: 250,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey, size: 60),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(icon: Icons.person, title: 'Dilaporkan oleh', content: reporter),
                  _buildDetailRow(icon: Icons.calendar_today, title: 'Tanggal Laporan', content: date),
                  _buildDetailRow(icon: statusIcon, title: 'Status', content: status, contentColor: statusColor),
                  const Divider(height: 32),
                  const Text('Deskripsi Insiden', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(fontSize: 16, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String content,
    Color? contentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: contentColor ?? Colors.black,
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