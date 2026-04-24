import 'package:flutter/material.dart';

class FindingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String lang;
  final VoidCallback onTap;

  const FindingCard({super.key, required this.data, required this.lang, required this.onTap});

  String _formatLocation(Map<String, dynamic> item) {
    if (item['area'] != null && item['area']['nama_area'] != null) return item['area']['nama_area'].toString();
    if (item['subunit'] != null && item['subunit']['nama_subunit'] != null) return item['subunit']['nama_subunit'].toString();
    if (item['unit'] != null && item['unit']['nama_unit'] != null) return item['unit']['nama_unit'].toString();
    if (item['lokasi'] != null && item['lokasi']['nama_lokasi'] != null) return item['lokasi']['nama_lokasi'].toString();
    return '-';
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    final dt = value is DateTime ? value : DateTime.tryParse(value.toString());
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Widget _buildInspectionBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = (data['gambar_temuan'] ?? '').toString();
    final title = (data['judul_temuan'] ?? '-').toString();
    final lokasi = _formatLocation(data);
    final tanggal = _formatDate(data['created_at']);
    final poin = int.tryParse((data['poin_temuan'] ?? 0).toString()) ?? 0;
    final status = (data['status_temuan'] ?? '').toString();
    final isPro = data['is_pro'] == true;
    final isVisitor = data['is_visitor'] == true;
    final isEksekutif = data['is_eksekutif'] == true;
    final s = status.toLowerCase();
    final isFinished = ['selesai', 'done', 'completed', 'closed'].any((e) => s.contains(e));
    final Map<String, List<String>> _statusLabels = {
      'ID': ['Selesai', 'Belum Selesai'],
      'EN': ['Finished', 'Unfinished'],
      'ZH': ['已完成', '未完成'],
    };
    final labels = _statusLabels[lang] ?? _statusLabels['ID']!;
    final String statusText = isFinished ? labels[0] : labels[1];

    late Color statusColor;
    late Color statusBg;
    late IconData statusIcon;
    if (isFinished) {
      statusColor = const Color(0xFF16A34A); statusBg = const Color(0xFFF0FDF4); statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = const Color(0xFFDC2626); statusBg = const Color(0xFFFEF2F2); statusIcon = Icons.pending_actions_rounded;
    }

    List<Widget> badges = [];
    List<String> inspectionTypes = [];
    if (isPro) inspectionTypes.add('pro');
    if (isVisitor) inspectionTypes.add('visitor');
    if (isEksekutif) inspectionTypes.add('eksekutif');
    if (inspectionTypes.contains('pro')) badges.add(_buildInspectionBadge('PROFESIONAL', const Color.fromARGB(255, 255, 244, 45), Colors.black));
    if (inspectionTypes.contains('visitor')) badges.add(_buildInspectionBadge('VISITOR', const Color(0xFF3B82F6), Colors.white));
    if (inspectionTypes.contains('eksekutif')) badges.add(_buildInspectionBadge('EKSEKUTIF', const Color(0xFFEF4444), Colors.white));

    inspectionTypes.sort();
    String combinationKey = inspectionTypes.join('+');
    final Color borderColor;
    switch (combinationKey) {
      case 'eksekutif+pro+visitor': borderColor = const Color(0xFF38BDF8); break;
      case 'pro+visitor': borderColor = const Color(0xFF38BDF8); break;
      case 'eksekutif+pro': borderColor = const Color(0xFF38BDF8); break;
      case 'eksekutif+visitor': borderColor = const Color(0xFF38BDF8); break;
      case 'pro': borderColor = const Color(0xFF38BDF8); break;
      case 'visitor': borderColor = const Color(0xFF38BDF8); break;
      case 'eksekutif': borderColor = const Color(0xFF38BDF8); break;
      default: borderColor = const Color(0xFF38BDF8);
    }

    return GestureDetector(
      onTap: () {
        // Import FindingDetailScreen di file ini jika perlu
        // Navigator.of(context).push(...).then((_) => onTap());
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [BoxShadow(color: borderColor.withOpacity(0.18), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 92, height: 92,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.black.withOpacity(0.15), width: 1.5)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.5),
                  child: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.grey))
                      : const Icon(Icons.image_outlined, color: Colors.grey, size: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, height: 1.3, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))),
                        const SizedBox(width: 8),
                        // Label jenis temuan
                        () {
                          final jenis = (data['jenis_temuan'] ?? '').toString();
                          final isKts = jenis == 'KTS Production';
                          final labelText = isKts ? 'KTS' : '5R';
                          final labelColor = isKts ? const Color(0xFFFBBF24) : const Color(0xFF38BDF8);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: labelColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: labelColor, width: 1.2),
                            ),
                            child: Text(
                              labelText,
                              style: TextStyle(
                                color: labelColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }(),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFFF6B3D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.local_fire_department_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text('$poin', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                            const SizedBox(width: 3),
                            const Text('Poin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 10)),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (badges.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 6.0), child: Wrap(spacing: 6, runSpacing: 4, children: badges)),
                    Row(children: [
                      const Icon(Icons.place_rounded, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 5),
                      Expanded(child: Text(lokasi, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)))),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 5),
                      Text(tanggal, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(statusIcon, size: 13, color: statusColor),
                          const SizedBox(width: 4),
                          Text(statusText, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: statusColor)),
                        ]),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}