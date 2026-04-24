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
    },
    'EN': {
      'resolved': 'Finished',
      'unresolved': 'Unfinished',
      'order': 'Order No.',
      'qty': 'Qty',
    },
    'ZH': {
      'resolved': '已完成',
      'unresolved': '未完成',
      'order': '订单号',
      'qty': '数量',
    },
  };

  String _t(String key) => _texts[lang]?[key] ?? key;

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    final dt = value is DateTime ? value : DateTime.tryParse(value.toString());
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
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
    final subKategori =
        data['subkategoritemuan']?['nama_subkategoritemuan'] ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withOpacity(0.12),
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
              // Gambar
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.black.withOpacity(0.15), width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.5),
                  child: displayImageUrl.isNotEmpty
                      ? Image.network(
                          displayImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildItemIcon(),
                        )
                      : _buildItemIcon(),
                ),
              ),
              const SizedBox(width: 12),

              // Konten
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Baris judul + badge KTS + poin
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
                        const SizedBox(width: 6),
                        // Badge KTS
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFBBF24).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                                color: const Color(0xFFFBBF24), width: 1.2),
                          ),
                          child: const Text(
                            'KTS',
                            style: TextStyle(
                              color: Color(0xFFFBBF24),
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        // Poin
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFFF6B3D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 12,
                                  color: Colors.white),
                              const SizedBox(width: 3),
                              Text('$poin',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11)),
                              const SizedBox(width: 2),
                              const Text('Poin',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 9)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Sub kategori
                    if (subKategori.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.folder_rounded,
                                size: 11, color: Color(0xFF7C3AED)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                subKategori,
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

                    // Chips: Order & Qty
                    Row(
                      children: [
                        _buildChip(
                          Icons.tag_rounded,
                          '${_t('order')}: $noOrder',
                          const Color(0xFFFEF9C3),
                          const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 6),
                        _buildChip(
                          Icons.inventory_2_outlined,
                          '$qty pcs',
                          const Color(0xFFF0FDF4),
                          const Color(0xFF22C55E),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Tanggal & Status
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 12, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(18)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 11, color: statusColor),
                              const SizedBox(width: 3),
                              Text(
                                statusText,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor),
                              ),
                            ],
                          ),
                        ),
                      ],
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
              style: TextStyle(
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