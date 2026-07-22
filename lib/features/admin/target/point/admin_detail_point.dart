import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDetailPointScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  final String lang;
  final String Function(Map<String, dynamic>) namaFn;
  final String Function(Map<String, dynamic>) deskripsiFn;
  final void Function(Map<String, dynamic>) onEdit;

  const AdminDetailPointScreen({
    super.key,
    required this.item,
    required this.lang,
    required this.namaFn,
    required this.deskripsiFn,
    required this.onEdit,
  });

  Widget _sectionLabel(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.poppins(color: color, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final poin = (item['poin'] as int?) ?? 0;
    final isBonus = poin >= 0;
    final isAktif = item['is_aktif'] as bool? ?? true;

    final color = isBonus ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final colorDark = isBonus ? const Color(0xFF16A34A) : const Color(0xFFB91C1C);
    final colorSoft = isBonus ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);

    final nama = namaFn(item);
    final deskripsi = deskripsiFn(item);
    final kode = (item['kode'] ?? '').toString();
    final keterangan = item['keterangan'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          lang == 'EN' ? 'Point Detail' : lang == 'ZH' ? '积分详情' : 'Detail Poin',
          style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // HERO POINT BADGE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, colorDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    isBonus ? Icons.add_circle_rounded : Icons.remove_circle_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${isBonus ? '+' : ''}$poin',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBonus
                        ? (lang == 'EN' ? 'Bonus Point' : lang == 'ZH' ? '奖励积分' : 'Poin Bonus')
                        : (lang == 'EN' ? 'Penalty Point' : lang == 'ZH' ? '处罚积分' : 'Poin Penalti'),
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // NAME + STATUS
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    nama,
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1D72F3)),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isAktif ? const Color(0xFF22C55E).withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isAktif ? const Color(0xFF22C55E).withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAktif ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                        size: 13,
                        color: isAktif ? const Color(0xFF16A34A) : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAktif
                            ? (lang == 'EN' ? 'Active' : lang == 'ZH' ? '启用' : 'Aktif')
                            : (lang == 'EN' ? 'Inactive' : lang == 'ZH' ? '禁用' : 'Nonaktif'),
                        style: GoogleFonts.poppins(
                            fontSize: 11, fontWeight: FontWeight.w700, color: isAktif ? const Color(0xFF16A34A) : Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // CODE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.code_rounded, size: 14, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 6),
                  Text(
                    kode,
                    style: GoogleFonts.robotoMono(fontSize: 13, color: const Color(0xFFE2E8F0), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.grey.shade100, thickness: 1.5),
            const SizedBox(height: 16),

            // DESCRIPTION
            _sectionLabel(Icons.notes_rounded, lang == 'EN' ? 'Description' : lang == 'ZH' ? '描述' : 'Deskripsi', color),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Text(
                deskripsi.isEmpty ? '-' : deskripsi,
                style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600, height: 1.5),
              ),
            ),

            // NOTE
            if (keterangan != null && keterangan.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionLabel(
                  Icons.sticky_note_2_rounded, lang == 'EN' ? 'Note' : lang == 'ZH' ? '备注' : 'Keterangan', color),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  keterangan,
                  style: GoogleFonts.poppins(color: Colors.black54, fontSize: 12, fontStyle: FontStyle.italic, height: 1.4),
                ),
              ),
            ],
            const SizedBox(height: 28),

            // EDIT BUTTON
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onEdit(item);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D72F3).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF1D72F3).withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.edit_rounded, color: Color(0xFF1D72F3), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        lang == 'EN' ? 'Edit Configuration' : lang == 'ZH' ? '编辑配置' : 'Edit Konfigurasi',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF1D72F3)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}