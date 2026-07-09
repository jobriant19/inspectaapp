import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KtsFindingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String lang;
  final VoidCallback onTap;

  const KtsFindingCard({
    super.key,
    required this.data,
    required this.lang,
    required this.onTap,
  });

  static const Map<String, Map<String, String>> _texts = {
    'ID': {
      'resolved': 'Selesai',
      'unresolved': 'Belum Selesai',
      'order': 'No. Order',
      'qty': 'Jumlah',
      'poin_label': 'Poin',
    },
    'EN': {
      'resolved': 'Finished',
      'unresolved': 'Unfinished',
      'order': 'Order No.',
      'qty': 'Qty',
      'poin_label': 'Pts',
    },
    'ZH': {
      'resolved': '已完成',
      'unresolved': '未完成',
      'order': '订单号',
      'qty': '数量',
      'poin_label': '积分',
    },
  };

  String _t(String key) => _texts[lang]?[key] ?? key;

  String? _getSectionName(Map<String, dynamic> data) {
    final penyelesaianData = data['penyelesaian'];
    Map<String, dynamic>? sectionMap;
    if (penyelesaianData is Map<String, dynamic> &&
        penyelesaianData['section'] is Map<String, dynamic>) {
      sectionMap = penyelesaianData['section'] as Map<String, dynamic>;
    }
    if (sectionMap == null) return null;

    switch (lang) {
      case 'EN':
        return (sectionMap['nama_section_en'] ?? sectionMap['nama_section_id'])?.toString();
      case 'ZH':
        return (sectionMap['nama_section_zh'] ?? sectionMap['nama_section_id'])?.toString();
      default:
        return sectionMap['nama_section_id']?.toString();
    }
  }

  String? _getCauseFactorName(Map<String, dynamic> data) {
    final penyelesaianData = data['penyelesaian'];
    if (penyelesaianData is Map<String, dynamic> &&
        penyelesaianData['faktor_penyebab'] is Map<String, dynamic>) {
      final faktorMap = penyelesaianData['faktor_penyebab'] as Map<String, dynamic>;
      return faktorMap['nama_subkategoritemuan']?.toString();
    }
    return null;
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    final dt = value is DateTime ? value : DateTime.tryParse(value.toString());
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Widget _buildPoinBadge(int poin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF2DD4BF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0D9488).withValues(alpha: 0.35), blurRadius: 7, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded, size: 13, color: Colors.white),
          const SizedBox(width: 3),
          Text('$poin', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(width: 2),
          Text(_t('poin_label'), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 9.5)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = (data['status_temuan'] ?? '').toString();
    final s = status.toLowerCase();
    final isResolved = s == 'selesai' || s == 'closed' || s == 'teratasi' ||
        s == 'done' || s == 'completed';

    final statusColor =
        isResolved ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final statusBg =
        isResolved ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6);
    final statusIcon =
        isResolved ? Icons.check_circle_rounded : Icons.pending_actions_rounded;
    final statusText = isResolved ? _t('resolved') : _t('unresolved');

    final imageUrl = (data['gambar_temuan'] ?? '').toString();
    final itemImg = data['item_produksi']?['gambar_item'];
    final displayImageUrl = itemImg ?? imageUrl;

    final title = (data['judul_temuan'] ?? '-').toString();
    final poin = int.tryParse((data['poin_temuan'] ?? 0).toString()) ?? 0;
    final noOrder = (data['no_order'] ?? '-').toString();
    final qty = data['jumlah_item'] ?? 0;
    final dateStr = _formatDate(data['created_at']);
    final causeFactorName = _getCauseFactorName(data);
    final sectionName = _getSectionName(data);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha:0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.black.withValues(alpha:0.15), width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.5),
                  child: displayImageUrl.isNotEmpty
                      ? Image.network(
                          displayImageUrl,
                          width: 92,
                          height: 92,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildItemIcon(),
                        )
                      : _buildItemIcon(),
                ),
              ),
              const SizedBox(width: 12),

              // CONTENT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.3,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBBF24).withValues(alpha:0.15),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: const Color(0xFFFBBF24), width: 1.2),
                          ),
                          child: Text(
                            'KTS',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFFBBF24),
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (poin > 0) _buildPoinBadge(poin),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // FAKTOR PENYEBAB & SECTION (keduanya dari data penyelesaian/solusi)
                    if (isResolved && (causeFactorName != null || sectionName != null))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          children: [
                            if (causeFactorName != null)
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F3FF),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.tag_rounded, size: 11, color: Color(0xFF7C3AED)),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          causeFactorName,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: const Color(0xFF7C3AED),
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (causeFactorName != null && sectionName != null)
                              const SizedBox(width: 6),
                            if (sectionName != null)
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFEFF),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.dashboard_rounded, size: 11, color: Color(0xFF0891B2)),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          sectionName,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: const Color(0xFF0891B2),
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                    // CHIPS: ORDER & QUANTITY
                    Row(
                      children: [
                        _buildChip(
                          Icons.confirmation_number_outlined,
                          '${_t('order')}: $noOrder',
                          const Color(0xFFFEF9C3),
                          const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 6),
                        _buildChip(
                          Icons.production_quantity_limits_rounded,
                          '$qty pcs',
                          const Color(0xFFF0FDF4),
                          const Color(0xFF22C55E),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // TIME BADGE
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded,
                              size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 5),
                          Text(
                            dateStr,
                            style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: const Color(0xFF475569),
                                fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: statusColor.withValues(alpha: 0.35))),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 13, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildItemIcon() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child:
          const Icon(Icons.build_rounded, color: Color(0xFFD97706), size: 28),
    );
  }
}