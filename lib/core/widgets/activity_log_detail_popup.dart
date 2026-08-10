import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActivityLogDetailPopup {
  ActivityLogDetailPopup._();

  static IconData _getTipeIcon(String tipe, bool isPositive) {
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
        return isPositive ? Icons.star_rounded : Icons.remove_circle_outline_rounded;
    }
  }

  static String _formatFullDate(dynamic value, String lang) {
    if (value == null) return '-';
    DateTime? dt = value is DateTime ? value : DateTime.tryParse(value.toString());
    if (dt == null) return '-';
    dt = dt.toLocal();

    const bulanIdFull = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    const bulanEnFull = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const bulanZhFull = [
      '', '一月', '二月', '三月', '四月', '五月', '六月',
      '七月', '八月', '九月', '十月', '十一月', '十二月'
    ];

    final jam = dt.hour.toString().padLeft(2, '0');
    final menit = dt.minute.toString().padLeft(2, '0');
    if (lang == 'ZH') return '${dt.year}年${bulanZhFull[dt.month]}${dt.day}日 $jam:$menit';
    if (lang == 'EN') return '${dt.day} ${bulanEnFull[dt.month]} ${dt.year}, $jam:$menit';
    return '${dt.day} ${bulanIdFull[dt.month]} ${dt.year}, $jam:$menit';
  }

  static void show({
    required BuildContext context,
    required String lang,
    required String nama,
    required String deskripsi,
    required int poin,
    required String tipeAktivitas,
    required dynamic createdAt,
  }) {
    final bool isPositive = poin >= 0;
    final Color color = isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final IconData icon = _getTipeIcon(tipeAktivitas, isPositive);
    final String tanggal = _formatFullDate(createdAt, lang);

    final Map<String, Map<String, String>> txt = {
      'ID': {'poin': 'poin'},
      'EN': {'poin': 'points'},
      'ZH': {'poin': '积分'},
    };
    String t(String k) => txt[lang]?[k] ?? txt['ID']![k]!;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Center(
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300, minWidth: 300),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // CLOSE X BUTTON
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // ICON
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.08)],
                      ),
                      border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(height: 14),

                  // NAME
                  Text(
                    nama,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      height: 1.3,
                    ),
                  ),

                  // DESCRIPTION
                  if (deskripsi.trim().isNotEmpty && deskripsi.trim() != nama.trim()) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        deskripsi,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // POINT BADGE
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive ? Icons.add_circle_rounded : Icons.remove_circle_rounded,
                          size: 17,
                          color: color,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '${poin.abs()} ${t('poin')}',
                          style: GoogleFonts.poppins(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // TIME
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF64748B)),
                        const SizedBox(width: 5),
                        Text(
                          tanggal,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}