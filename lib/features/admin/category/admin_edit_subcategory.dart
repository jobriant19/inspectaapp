import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/translation_service.dart';
import '../../user/home/alert/required_field_alert.dart';
import 'admin_add_subcategory.dart';

class _C {
  static const red      = Color(0xFFEF4444);
  static const textMain = Color(0xFF1E3A8A);
  static const textSub  = Color(0xFF64748B);
  static const divider  = Color(0xFFE2E8F0);
  static const surface  = Color(0xFFF8FAFC);
}

class AdminEditSubcategoryDialog extends StatefulWidget {
  final String lang;
  final bool isKts;
  final Color color;
  final Map<String, dynamic> item;
  final List<Map<String, dynamic>> kategoriList;
  final Future<void> Function() onSaved;

  const AdminEditSubcategoryDialog({
    super.key,
    required this.lang,
    required this.isKts,
    required this.color,
    required this.item,
    required this.kategoriList,
    required this.onSaved,
  });

  @override
  State<AdminEditSubcategoryDialog> createState() => _AdminEditSubcategoryDialogState();
}

class _AdminEditSubcategoryDialogState extends State<AdminEditSubcategoryDialog> {
  final _supabase = Supabase.instance.client;
  late final TextEditingController _namaCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _poinCtrl;

  String? _selKatId;
  String? _selKatName;
  bool _isSaving = false;

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  IconData get _typeIcon =>
      widget.isKts ? Icons.precision_manufacturing_rounded : Icons.cleaning_services_rounded;

  String get _typeLabel => widget.isKts ? 'KTS Production' : '5R Finding';

  String _localizedNamaSub(Map<String, dynamic> item) {
    switch (widget.lang) {
      case 'EN':
        return (item['nama_subkategoritemuan_en'] ?? item['nama_subkategoritemuan'] ?? '').toString();
      case 'ZH':
        return (item['nama_subkategoritemuan_zh'] ?? item['nama_subkategoritemuan'] ?? '').toString();
      default:
        return (item['nama_subkategoritemuan'] ?? '').toString();
    }
  }

  String _localizedDeskSub(Map<String, dynamic> item) {
    switch (widget.lang) {
      case 'EN':
        return (item['deskripsi_subkategoritemuan_en'] ?? item['deskripsi_subkategoritemuan'] ?? '').toString();
      case 'ZH':
        return (item['deskripsi_subkategoritemuan_zh'] ?? item['deskripsi_subkategoritemuan'] ?? '').toString();
      default:
        return (item['deskripsi_subkategoritemuan'] ?? '').toString();
    }
  }

  String _localizedKatNama(Map<String, dynamic> item) {
    switch (widget.lang) {
      case 'EN':
        return (item['nama_kategoritemuan_en'] ?? item['nama_kategoritemuan'] ?? '-').toString();
      case 'ZH':
        return (item['nama_kategoritemuan_zh'] ?? item['nama_kategoritemuan'] ?? '-').toString();
      default:
        return (item['nama_kategoritemuan'] ?? '-').toString();
    }
  }

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: _localizedNamaSub(widget.item));
    _descCtrl = TextEditingController(text: _localizedDeskSub(widget.item));
    _poinCtrl = TextEditingController(text: (widget.item['poin_subkategoritemuan'] ?? 0).toString());
    _selKatId = widget.item['id_kategoritemuan']?.toString();

    final parent = widget.item['kategoritemuan'];
    if (parent is Map<String, dynamic>) {
      _selKatName = _localizedKatNama(parent);
    } else {
      final match = widget.kategoriList.firstWhere(
        (k) => k['id_kategoritemuan'].toString() == _selKatId,
        orElse: () => {},
      );
      _selKatName = match.isNotEmpty ? _localizedKatNama(match) : null;
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _descCtrl.dispose();
    _poinCtrl.dispose();
    super.dispose();
  }

  void _openCategoryPicker() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AdminSubcategoryCategoryPickerDialog(
        lang: widget.lang,
        isKts: widget.isKts,
        color: widget.color,
        items: widget.kategoriList,
        selectedId: _selKatId,
        onSelect: (id, name) {
          setState(() {
            _selKatId = id;
            _selKatName = name;
          });
        },
      ),
    );
  }

  Future<void> _handleSave() async {
    final namaSource = _namaCtrl.text.trim();
    final descSource = _descCtrl.text.trim();

    final missing = <MissingFieldItem>[];
    if (namaSource.isEmpty) {
      missing.add(MissingFieldItem(
          icon: Icons.list_alt_rounded, label: _t('Sub-Category Name', 'Nama Sub-Kategori', '子分类名称')));
    }
    if (_selKatId == null) {
      missing.add(MissingFieldItem(
          icon: Icons.category_rounded, label: _t('Select Category', 'Pilih Kategori', '选择分类')));
    }
    if (missing.isNotEmpty) {
      RequiredFieldAlert.show(context, lang: widget.lang, missingFields: missing);
      return;
    }

    final bool namaChanged = namaSource != _localizedNamaSub(widget.item);
    final bool descChanged = descSource != _localizedDeskSub(widget.item);
    final bool needsTranslate = namaChanged || (descChanged && descSource.isNotEmpty);

    setState(() => _isSaving = true);

    Map<String, String> namaAll = {
      'id': (widget.item['nama_subkategoritemuan'] ?? namaSource).toString(),
      'en': (widget.item['nama_subkategoritemuan_en'] ?? namaSource).toString(),
      'zh': (widget.item['nama_subkategoritemuan_zh'] ?? namaSource).toString(),
    };
    Map<String, String> descAll = {
      'id': (widget.item['deskripsi_subkategoritemuan'] ?? '').toString(),
      'en': (widget.item['deskripsi_subkategoritemuan_en'] ?? '').toString(),
      'zh': (widget.item['deskripsi_subkategoritemuan_zh'] ?? '').toString(),
    };

    if (descChanged && descSource.isEmpty) {
      descAll = {'id': '', 'en': '', 'zh': ''};
    }

    if (needsTranslate) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AdminSubcategoryTranslatingDialog(color: widget.color, lang: widget.lang),
        );
      }
      try {
        if (namaChanged) {
          namaAll = await TranslationHelper.instance.translateDescriptionAllLangs(namaSource, widget.lang);
        }
        if (descChanged && descSource.isNotEmpty) {
          descAll = await TranslationHelper.instance.translateDescriptionAllLangs(descSource, widget.lang);
        }
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
      } catch (e) {
        debugPrint('Error translating subkategori: $e');
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        if (namaChanged) namaAll = {'id': namaSource, 'en': namaSource, 'zh': namaSource};
        if (descChanged && descSource.isNotEmpty) descAll = {'id': descSource, 'en': descSource, 'zh': descSource};
      }
    }

    final data = {
      'id_kategoritemuan': _selKatId,
      'nama_subkategoritemuan': namaAll['id'],
      'nama_subkategoritemuan_en': namaAll['en'],
      'nama_subkategoritemuan_zh': namaAll['zh'],
      'deskripsi_subkategoritemuan': descAll['id']!.isEmpty ? null : descAll['id'],
      'deskripsi_subkategoritemuan_en': descAll['en']!.isEmpty ? null : descAll['en'],
      'deskripsi_subkategoritemuan_zh': descAll['zh']!.isEmpty ? null : descAll['zh'],
      'poin_subkategoritemuan': int.tryParse(_poinCtrl.text.trim()) ?? 0,
    };

    try {
      await _supabase.from('subkategoritemuan').update(data).eq('id_subkategoritemuan', widget.item['id_subkategoritemuan']);
      if (mounted) Navigator.pop(context);
      await widget.onSaved();
    } catch (e) {
      debugPrint('Error update subkategori: $e');
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildCategoryPickerField() {
    final hasValue = _selKatId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(_typeIcon, size: 14, color: widget.color),
          const SizedBox(width: 6),
          Text(_t('Select Category', 'Pilih Kategori', '选择分类'),
              style: GoogleFonts.poppins(
                  color: widget.color, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
          const SizedBox(width: 3),
          Text('*', style: GoogleFonts.poppins(color: _C.red, fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _openCategoryPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: hasValue ? widget.color.withValues(alpha: 0.4) : _C.divider),
            ),
            child: Row(children: [
              Icon(Icons.category_rounded, size: 16, color: hasValue ? widget.color : Colors.black26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasValue ? (_selKatName ?? '-') : _t('Select Category', 'Pilih Kategori', '选择分类'),
                  style: GoogleFonts.poppins(
                    color: hasValue ? _C.textMain : Colors.black38,
                    fontSize: 13,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black45),
            ]),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 22, 20, 16),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(_typeIcon, color: widget.color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_t('Edit Sub-Category', 'Edit Sub-Kategori', '编辑子分类'),
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: widget.color)),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _C.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 16, color: _C.red),
                  ),
                ),
              ]),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: widget.color.withValues(alpha: 0.20)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_typeIcon, color: widget.color, size: 13),
                        const SizedBox(width: 5),
                        Text(_typeLabel,
                            style:
                                GoogleFonts.poppins(color: widget.color, fontSize: 11, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryPickerField(),
                    const SizedBox(height: 16),
                    Row(children: [
                      Icon(Icons.list_alt_rounded, size: 14, color: widget.color),
                      const SizedBox(width: 6),
                      Text(_t('Sub-Category Name', 'Nama Sub-Kategori', '子分类名称'),
                          style: GoogleFonts.poppins(
                              color: widget.color, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                      const SizedBox(width: 3),
                      Text('*', style: GoogleFonts.poppins(color: _C.red, fontSize: 13, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                          color: _C.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.divider)),
                      child: TextField(
                        controller: _namaCtrl,
                        style: GoogleFonts.poppins(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          hintText: _t('Sub-Category Name', 'Nama Sub-Kategori', '子分类名称'),
                          hintStyle: GoogleFonts.poppins(color: Colors.black26, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      Icon(Icons.notes_rounded, size: 14, color: widget.color),
                      const SizedBox(width: 6),
                      Text(_t('Description', 'Deskripsi', '描述'),
                          style: GoogleFonts.poppins(
                              color: widget.color, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                    ]),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                          color: _C.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.divider)),
                      child: TextField(
                        controller: _descCtrl,
                        maxLines: 3,
                        style: GoogleFonts.poppins(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          hintText: _t('Optional', 'Opsional', '可选'),
                          hintStyle: GoogleFonts.poppins(color: Colors.black26, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _t('Name & description will be auto-translated to ID / EN / ZH.',
                          'Nama & deskripsi akan diterjemahkan otomatis ke ID / EN / ZH.',
                          '名称和描述将自动翻译为印尼语/英语/中文。'),
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _C.textSub),
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      Icon(Icons.star_rounded, size: 14, color: widget.color),
                      const SizedBox(width: 6),
                      Text(_t('Points', 'Poin', '积分'),
                          style: GoogleFonts.poppins(
                              color: widget.color, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                    ]),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                          color: _C.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.divider)),
                      child: TextField(
                        controller: _poinCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.poppins(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: GoogleFonts.poppins(color: Colors.black26, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: BoxDecoration(
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, -2))]),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _C.divider),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13)),
                    child: Text(_t('Cancel', 'Batal', '取消'),
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _C.textSub)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: widget.color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13)),
                    child: _isSaving
                        ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const SizedBox(
                                width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            const SizedBox(width: 8),
                            Text(_t('Saving...', 'Menyimpan...', '保存中...'),
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                          ])
                        : Text(_t('Save', 'Simpan', '保存'),
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}