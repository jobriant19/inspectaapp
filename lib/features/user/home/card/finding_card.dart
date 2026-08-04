import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FindingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String lang;
  final VoidCallback onTap;

  const FindingCard({super.key, required this.data, required this.lang, required this.onTap});

  Map<String, dynamic> _locationBadgeInfo(Map<String, dynamic> item) {
    if (item['area'] != null && item['area']['nama_area'] != null) {
      return {
        'label': item['area']['nama_area'].toString(),
        'icon': Icons.place_rounded,
        'color': const Color(0xFFF472B6),
      };
    }
    if (item['subunit'] != null && item['subunit']['nama_subunit'] != null) {
      return {
        'label': item['subunit']['nama_subunit'].toString(),
        'icon': Icons.layers_rounded,
        'color': const Color(0xFFFBBF24),
      };
    }
    if (item['unit'] != null && item['unit']['nama_unit'] != null) {
      return {
        'label': item['unit']['nama_unit'].toString(),
        'icon': Icons.business_rounded,
        'color': const Color(0xFF6366F1),
      };
    }
    if (item['lokasi'] != null && item['lokasi']['nama_lokasi'] != null) {
      return {
        'label': item['lokasi']['nama_lokasi'].toString(),
        'icon': Icons.location_city_rounded,
        'color': const Color(0xFF10B981),
      };
    }
    return {
      'label': '-',
      'icon': Icons.location_off_rounded,
      'color': const Color(0xFF94A3B8),
    };
  }

  Widget _buildLocationBadge(Map<String, dynamic> data) {
    final loc = _locationBadgeInfo(data);
    final Color color = loc['color'] as Color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(loc['icon'] as IconData, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              loc['label'] as String,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    final dt = value is DateTime ? value : DateTime.tryParse(value.toString());
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _inspectionLabel(String key) {
    const labels = {
      'pro': {'ID': 'PROFESIONAL', 'EN': 'PROFESSIONAL', 'ZH': '专业'},
      'visitor': {'ID': 'PENGUNJUNG', 'EN': 'VISITOR', 'ZH': '访客'},
      'eksekutif': {'ID': 'EKSEKUTIF', 'EN': 'EXECUTIVE', 'ZH': '行政'},
    };
    return labels[key]?[lang] ?? labels[key]!['ID']!;
  }

  Widget _buildInspectionBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildPoinBadge(int poin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF2DD4BF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0D9488).withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text('$poin', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = (data['gambar_temuan'] ?? '').toString();
    final title = (data['judul_temuan'] ?? '-').toString();
    final tanggal = _formatDate(data['created_at']);
    final poin = int.tryParse((data['poin_temuan'] ?? 0).toString()) ?? 0;
    final status = (data['status_temuan'] ?? '').toString();
    final isPro = data['is_pro'] == true;
    final isVisitor = data['is_visitor'] == true;
    final isEksekutif = data['is_eksekutif'] == true;
    final s = status.toLowerCase();
    final isFinished = ['selesai', 'done', 'completed', 'closed'].any((e) => s.contains(e));
    final Map<String, List<String>> statusLabels = {
      'ID': ['Selesai', 'Belum Selesai'],
      'EN': ['Finished', 'Unfinished'],
      'ZH': ['已完成', '未完成'],
    };
    final labels = statusLabels[lang] ?? statusLabels['ID']!;
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
    if (inspectionTypes.contains('pro')) badges.add(_buildInspectionBadge(_inspectionLabel('pro'), const Color.fromARGB(255, 255, 244, 45), Colors.black));
    if (inspectionTypes.contains('visitor')) badges.add(_buildInspectionBadge(_inspectionLabel('visitor'), const Color(0xFF3B82F6), Colors.white));
    if (inspectionTypes.contains('eksekutif')) badges.add(_buildInspectionBadge(_inspectionLabel('eksekutif'), const Color(0xFFEF4444), Colors.white));

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
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [BoxShadow(color: borderColor.withValues(alpha:0.18), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.black.withValues(alpha:0.15), width: 1.5)),
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
                            // FINDING TYPE LABEL + POIN BADGE
                            Wrap(
                              alignment: WrapAlignment.end,
                              runAlignment: WrapAlignment.end,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                () {
                                  final jenis = (data['jenis_temuan'] ?? '').toString();
                                  final isKts = jenis == 'KTS Production';
                                  final labelText = isKts ? 'KTS' : '5R';
                                  final labelColor = isKts ? const Color(0xFFFBBF24) : const Color(0xFF38BDF8);
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: labelColor.withValues(alpha:0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: labelColor, width: 1.2),
                                    ),
                                    child: Text(
                                      labelText,
                                      style: GoogleFonts.poppins(
                                        color: labelColor,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                      ),
                                    ),
                                  );
                                }(),
                                if (poin > 0) _buildPoinBadge(poin),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (badges.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 6.0), child: Wrap(spacing: 6, runSpacing: 4, children: badges)),
                        // LOCATION BADGE
                        Row(children: [
                          Flexible(child: _buildLocationBadge(data)),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // TIME BADGE
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_month_rounded, size: 15, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tanggal,
                      maxLines: 1,
                      softWrap: false,
                      style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF475569), fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 5),
                      Text(statusText, style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: statusColor)),
                    ]),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}