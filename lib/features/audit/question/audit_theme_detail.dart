import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class _C {
  static const primary   = Color(0xFF1D72F3);
  static const primaryLt = Color(0xFFE3EFFE);
  static const red       = Color(0xFFEF4444);
  static const textMain  = Color(0xFF1E3A8A);
  static const divider   = Color(0xFFE2E8F0);
  static const surface   = Color(0xFFF8FAFC);
}

class AuditThemeDetailScreen extends StatelessWidget {
  final String lang;
  final Map<String, dynamic> item;
  final String jenisAuditLabel;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;

  const AuditThemeDetailScreen({
    super.key,
    required this.lang,
    required this.item,
    required this.jenisAuditLabel,
    required this.onEdit,
    required this.onDelete,
  });

  String _t(String en, String id, String zh) {
    if (lang == 'EN') return en;
    if (lang == 'ZH') return zh;
    return id;
  }

  Widget _sectionLabel(IconData icon, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _C.primaryLt,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: _C.primary),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
              fontSize: 12.5, fontWeight: FontWeight.w700, color: _C.primary),
        ),
      ],
    );
  }

  Widget _valueCard(String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.divider),
      ),
      child: Text(
        value,
        style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: _C.textMain,
            height: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final urutan = item['urutan']?.toString() ?? '-';
    final namaId = item['nama_tema_id']?.toString().trim();
    final namaEn = item['nama_tema_en']?.toString().trim();
    final namaZh = item['nama_tema_zh']?.toString().trim();

    return Scaffold(
      backgroundColor: _C.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _C.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('Theme Detail', 'Detail Tema', '主题详情'),
          style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w700, color: _C.primary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // AUDIT TYPE
          _sectionLabel(Icons.category_rounded,
              _t('Audit Type', 'Jenis Audit', '审计类型')),
          _valueCard(jenisAuditLabel),
          const SizedBox(height: 18),

          // ORDER
          _sectionLabel(Icons.sort_rounded, _t('Order', 'Urutan', '顺序')),
          _valueCard(urutan),
          const SizedBox(height: 18),

          // THEME NAME - INDONESIA
          _sectionLabel(
              Icons.edit_note_rounded,
              _t('Theme Name (Indonesian)', 'Nama Tema (Indonesia)',
                  '主题名称（印尼语）')),
          _valueCard((namaId == null || namaId.isEmpty) ? '-' : namaId),
          const SizedBox(height: 18),

          // THEME NAME - ENGLISH
          _sectionLabel(
              Icons.language_rounded,
              _t('Theme Name (English)', 'Nama Tema (Inggris)',
                  '主题名称（英语）')),
          _valueCard((namaEn == null || namaEn.isEmpty) ? '-' : namaEn),
          const SizedBox(height: 18),

          // THEME NAME - MANDARIN
          _sectionLabel(
              Icons.translate_rounded,
              _t('Theme Name (Mandarin)', 'Nama Tema (Mandarin)',
                  '主题名称（中文）')),
          _valueCard((namaZh == null || namaZh.isEmpty) ? '-' : namaZh),
          const SizedBox(height: 28),

          // ACTION BUTTONS
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onEdit(item);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _C.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.edit_outlined,
                            color: _C.primary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _t('Edit', 'Edit', '编辑'),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: _C.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onDelete(item);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _C.red.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delete_outline_rounded,
                            color: _C.red, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _t('Delete', 'Hapus', '删除'),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: _C.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}