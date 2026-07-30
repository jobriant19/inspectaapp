import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/translation_service.dart';
import '../../user/home/alert/required_field_alert.dart';

class AdminAddCategoryDialog extends StatefulWidget {
  final String lang;
  final bool isKts;
  final Color color;
  final Future<void> Function() onSaved;

  const AdminAddCategoryDialog({
    super.key,
    required this.lang,
    required this.isKts,
    required this.color,
    required this.onSaved,
  });

  @override
  State<AdminAddCategoryDialog> createState() => _AdminAddCategoryDialogState();
}

class _AdminAddCategoryDialogState extends State<AdminAddCategoryDialog> {
  final _namaCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _poinCtrl = TextEditingController(text: '0');

  bool _isSaving = false;

  IconData get _badgeIcon =>
      widget.isKts ? Icons.precision_manufacturing_rounded : Icons.cleaning_services_rounded;

  String get _badgeLabel => widget.isKts ? 'KTS Production' : '5R Finding';

  @override
  void dispose() {
    _namaCtrl.dispose();
    _descCtrl.dispose();
    _poinCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final namaSource = _namaCtrl.text.trim();
    final descSource = _descCtrl.text.trim();

    if (namaSource.isEmpty) {
      RequiredFieldAlert.show(
        context,
        lang: widget.lang,
        missingFields: [
          MissingFieldItem(
            icon: Icons.category_rounded,
            label: widget.lang == 'EN'
                ? 'Category Name'
                : widget.lang == 'ZH'
                    ? '分类名称'
                    : 'Nama Kategori',
          ),
        ],
      );
      return;
    }

    setState(() => _isSaving = true);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _CategoryTranslatingDialog(color: widget.color, lang: widget.lang),
      );
    }

    Map<String, String> namaAll = {'id': namaSource, 'en': namaSource, 'zh': namaSource};
    Map<String, String> descAll = {'id': '', 'en': '', 'zh': ''};

    try {
      namaAll = await TranslationHelper.instance.translateDescriptionAllLangs(namaSource, widget.lang);
      if (descSource.isNotEmpty) {
        descAll = await TranslationHelper.instance.translateDescriptionAllLangs(descSource, widget.lang);
      }
    } catch (e) {
      debugPrint('Error translating kategori: $e');
      namaAll = {'id': namaSource, 'en': namaSource, 'zh': namaSource};
      descAll = descSource.isEmpty
          ? {'id': '', 'en': '', 'zh': ''}
          : {'id': descSource, 'en': descSource, 'zh': descSource};
    }

    if (mounted) Navigator.of(context, rootNavigator: true).pop();

    final data = {
      'nama_kategoritemuan': namaAll['id'],
      'nama_kategoritemuan_en': namaAll['en'],
      'nama_kategoritemuan_zh': namaAll['zh'],
      'deskripsi_kategoritemuan': descAll['id']!.isEmpty ? null : descAll['id'],
      'deskripsi_kategoritemuan_en': descAll['en']!.isEmpty ? null : descAll['en'],
      'deskripsi_kategoritemuan_zh': descAll['zh']!.isEmpty ? null : descAll['zh'],
      'poin_kategoritemuan': int.tryParse(_poinCtrl.text.trim()) ?? 0,
      'jenis_kategori': widget.isKts ? 'KTS' : '5R',
    };

    try {
      await Supabase.instance.client.from('kategoritemuan').insert(data);
      if (mounted) Navigator.pop(context);
      await widget.onSaved();
    } catch (e) {
      debugPrint('Error save kategori: $e');
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.category_rounded, color: widget.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.lang == 'EN'
                        ? 'Add Category'
                        : widget.lang == 'ZH'
                            ? '添加分类'
                            : 'Tambah Kategori',
                    style: GoogleFonts.poppins(color: widget.color, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                // CLOSE BUTTON
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close, size: 18, color: Color(0xFFEF4444)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // BADGE TYPE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: widget.color.withValues(alpha: 0.20)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_badgeIcon, color: widget.color, size: 13),
                  const SizedBox(width: 5),
                  Text(_badgeLabel,
                      style: GoogleFonts.poppins(color: widget.color, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade100, thickness: 1.5),
            const SizedBox(height: 14),

            _buildField(
              label: widget.lang == 'EN' ? 'Category Name' : widget.lang == 'ZH' ? '分类名称' : 'Nama Kategori',
              icon: Icons.category_rounded,
              ctrl: _namaCtrl,
              required: true,
            ),
            _buildField(
              label: widget.lang == 'EN' ? 'Description' : widget.lang == 'ZH' ? '描述' : 'Deskripsi',
              icon: Icons.notes_rounded,
              ctrl: _descCtrl,
              maxLines: 3,
            ),
            _buildField(
              label: widget.lang == 'EN' ? 'Points' : widget.lang == 'ZH' ? '积分' : 'Poin',
              icon: Icons.star_rounded,
              ctrl: _poinCtrl,
              keyboardType: TextInputType.number,
            ),

            // BUTTONS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      foregroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      widget.lang == 'EN' ? 'Cancel' : widget.lang == 'ZH' ? '取消' : 'Batal',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      shadowColor: widget.color.withValues(alpha: 0.3),
                    ),
                    child: _isSaving
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.lang == 'EN' ? 'Saving...' : widget.lang == 'ZH' ? '保存中...' : 'Menyimpan...',
                                style: GoogleFonts.poppins(
                                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          )
                        : Text(
                            widget.lang == 'EN' ? 'Save' : widget.lang == 'ZH' ? '保存' : 'Simpan',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController ctrl,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: widget.color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                  color: widget.color, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3),
            ),
            if (required) ...[
              const SizedBox(width: 3),
              Text('*',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: GoogleFonts.poppins(color: Colors.black26, fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _CategoryTranslatingDialog extends StatefulWidget {
  final Color color;
  final String lang;
  const _CategoryTranslatingDialog({required this.color, required this.lang});

  @override
  State<_CategoryTranslatingDialog> createState() => _CategoryTranslatingDialogState();
}

class _CategoryTranslatingDialogState extends State<_CategoryTranslatingDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.lang) {
      case 'EN':
        return 'Translating...';
      case 'ZH':
        return '翻译中...';
      default:
        return 'Menerjemahkan...';
    }
  }

  String get _subtitle {
    switch (widget.lang) {
      case 'EN':
        return 'Converting to Indonesian, English & Mandarin';
      case 'ZH':
        return '正在转换为印尼语、英语和中文';
      default:
        return 'Mengubah ke Bahasa Indonesia, Inggris & Mandarin';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = 0.90 + (_controller.value * 0.12);
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color, widget.color.withValues(alpha: 0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: widget.color.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: const Icon(Icons.translate_rounded, color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              _title,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _subtitle,
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B), height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: 150,
                height: 6,
                child: LinearProgressIndicator(
                  backgroundColor: widget.color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}