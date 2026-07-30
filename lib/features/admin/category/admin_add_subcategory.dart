import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/translation_service.dart';
import '../../user/home/alert/required_field_alert.dart';
import 'admin_category_indicator.dart';

class _C {
  static const red      = Color(0xFFEF4444);
  static const textMain = Color(0xFF1E3A8A);
  static const textSub  = Color(0xFF64748B);
  static const divider  = Color(0xFFE2E8F0);
  static const surface  = Color(0xFFF8FAFC);
}

class AdminAddSubcategoryDialog extends StatefulWidget {
  final String lang;
  final bool isKts;
  final Color color;
  final List<Map<String, dynamic>> kategoriList;
  final Future<void> Function() onSaved;

  const AdminAddSubcategoryDialog({
    super.key,
    required this.lang,
    required this.isKts,
    required this.color,
    required this.kategoriList,
    required this.onSaved,
  });

  @override
  State<AdminAddSubcategoryDialog> createState() => _AdminAddSubcategoryDialogState();
}

class _AdminAddSubcategoryDialogState extends State<AdminAddSubcategoryDialog> {
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

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _poinCtrl = TextEditingController(text: '0');
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
          icon: Icons.list_alt_rounded,
          label: _t('Sub-Category Name', 'Nama Sub-Kategori', '子分类名称')));
    }
    if (_selKatId == null) {
      missing.add(MissingFieldItem(
          icon: Icons.category_rounded,
          label: _t('Select Category', 'Pilih Kategori', '选择分类')));
    }
    if (missing.isNotEmpty) {
      RequiredFieldAlert.show(context, lang: widget.lang, missingFields: missing);
      return;
    }

    setState(() => _isSaving = true);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AdminSubcategoryTranslatingDialog(color: widget.color, lang: widget.lang),
      );
    }

    Map<String, String> namaAll = {'id': namaSource, 'en': namaSource, 'zh': namaSource};
    Map<String, String> descAll = {'id': '', 'en': '', 'zh': ''};

    try {
      namaAll = await TranslationHelper.instance.translateDescriptionAllLangs(namaSource, widget.lang);
      if (descSource.isNotEmpty) {
        descAll = await TranslationHelper.instance.translateDescriptionAllLangs(descSource, widget.lang);
      }
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    } catch (e) {
      debugPrint('Error translating subkategori: $e');
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      namaAll = {'id': namaSource, 'en': namaSource, 'zh': namaSource};
      if (descSource.isNotEmpty) descAll = {'id': descSource, 'en': descSource, 'zh': descSource};
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
      await _supabase.from('subkategoritemuan').insert(data);
      if (mounted) Navigator.pop(context);
      await widget.onSaved();
    } catch (e) {
      debugPrint('Error save subkategori: $e');
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
                  child: Text(_t('Add Sub-Category', 'Tambah Sub-Kategori', '添加子分类'),
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

class AdminSubcategoryTranslatingDialog extends StatefulWidget {
  final Color color;
  final String lang;
  const AdminSubcategoryTranslatingDialog({super.key, required this.color, required this.lang});

  @override
  State<AdminSubcategoryTranslatingDialog> createState() => _AdminSubcategoryTranslatingDialogState();
}

class _AdminSubcategoryTranslatingDialogState extends State<AdminSubcategoryTranslatingDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
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
            Text(_title,
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(_subtitle,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B), height: 1.4),
                textAlign: TextAlign.center),
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

class AdminSubcategoryCategoryPickerDialog extends StatefulWidget {
  final String lang;
  final bool isKts;
  final Color color;
  final List<Map<String, dynamic>> items;
  final String? selectedId;
  final void Function(String id, String name) onSelect;

  const AdminSubcategoryCategoryPickerDialog({
    super.key,
    required this.lang,
    required this.isKts,
    required this.color,
    required this.items,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  State<AdminSubcategoryCategoryPickerDialog> createState() => _AdminSubcategoryCategoryPickerDialogState();
}

class _AdminSubcategoryCategoryPickerDialogState extends State<AdminSubcategoryCategoryPickerDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];
  int _currentPage = 1;

  String _t(String en, String id, String zh) => widget.lang == 'EN' ? en : widget.lang == 'ZH' ? zh : id;

  IconData get _typeIcon =>
      widget.isKts ? Icons.precision_manufacturing_rounded : Icons.cleaning_services_rounded;

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyFilter);
    _searchCtrl.dispose();
    super.dispose();
  }

  String _localizedNama(Map<String, dynamic> item) {
    switch (widget.lang) {
      case 'EN':
        return (item['nama_kategoritemuan_en'] ?? item['nama_kategoritemuan'] ?? '-').toString();
      case 'ZH':
        return (item['nama_kategoritemuan_zh'] ?? item['nama_kategoritemuan'] ?? '-').toString();
      default:
        return (item['nama_kategoritemuan'] ?? '-').toString();
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.items
          : widget.items.where((e) => _localizedNama(e).toLowerCase().contains(q)).toList();
      _currentPage = 1;
    });
  }

  void _resetSearch() {
    _searchCtrl.clear();
    setState(() => _currentPage = 1);
  }

  Widget _buildCategoryCard(Map<String, dynamic> item) {
    final id = item['id_kategoritemuan']?.toString() ?? '';
    final name = _localizedNama(item);
    final isSel = id == widget.selectedId;

    return GestureDetector(
      onTap: () {
        widget.onSelect(id, name);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSel ? widget.color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSel ? widget.color : Colors.grey.shade200, width: isSel ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.category_rounded, size: 18, color: widget.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF1E3A8A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: widget.color.withValues(alpha: 0.25)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_typeIcon, size: 10, color: widget.color),
                      const SizedBox(width: 4),
                      Text(widget.isKts ? 'KTS' : '5R',
                          style: GoogleFonts.poppins(color: widget.color, fontSize: 9.5, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ],
              ),
            ),
            if (isSel)
              Icon(Icons.check_circle_rounded, color: widget.color, size: 20)
            else
              Icon(Icons.chevron_right_rounded, color: widget.color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isSearching = _searchCtrl.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              height: 100,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: Icon(Icons.search_off_rounded, size: 34, color: widget.color.withValues(alpha: 0.5)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _t('No categories found', 'Kategori tidak ditemukan', '未找到分类'),
              style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A8A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? _t('Try a different keyword.', 'Coba kata kunci lain.', '请尝试其他关键词。')
                  : _t('No categories available.', 'Tidak ada kategori tersedia.', '没有可用分类。'),
              style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF64748B), height: 1.4),
              textAlign: TextAlign.center,
            ),
            if (isSearching) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _resetSearch,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: widget.color.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 14, color: widget.color),
                      const SizedBox(width: 6),
                      Text(_t('Clear search', 'Hapus pencarian', '清除搜索'),
                          style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: widget.color)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = _filtered.isEmpty ? 1 : (_filtered.length / kAdminCategorySelectPageSize).ceil();
    final safePage = _currentPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * kAdminCategorySelectPageSize;
    final endIdx = (startIdx + kAdminCategorySelectPageSize) > _filtered.length
        ? _filtered.length
        : startIdx + kAdminCategorySelectPageSize;
    final pageItems = _filtered.isEmpty ? <Map<String, dynamic>>[] : _filtered.sublist(startIdx, endIdx);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: SizedBox(
        width: 440,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration:
                          BoxDecoration(color: widget.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                      child: Icon(_typeIcon, color: widget.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _t('SELECT CATEGORY', 'PILIH KATEGORI', '选择分类'),
                        style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w800, color: widget.color),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: const Color(0xFFFFEBEB), borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: const Color(0xFFF1F5F9)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: widget.color.withValues(alpha: 0.3), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, size: 20, color: widget.color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E3A8A)),
                          decoration: InputDecoration(
                            hintText: _t('Search Category...', 'Cari Kategori...', '搜索分类...'),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 13),
                            hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
                          ),
                        ),
                      ),
                      if (_searchCtrl.text.isNotEmpty)
                        GestureDetector(
                          onTap: _resetSearch,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.15), shape: BoxShape.circle),
                            child: Icon(Icons.close_rounded, size: 14, color: widget.color),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Container(height: 1, color: const Color(0xFFF1F5F9)),
              Expanded(
                child: _filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        children: pageItems.map(_buildCategoryCard).toList(),
                      ),
              ),
              if (_filtered.isNotEmpty && totalPages > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: AdminCategoryPageIndicator(
                    currentPage: safePage,
                    totalPages: totalPages,
                    onPageChanged: (p) => setState(() => _currentPage = p),
                    color: widget.color,
                    horizontalMargin: 0,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}