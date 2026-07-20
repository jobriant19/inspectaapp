import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/utils/image_picker_helper.dart';
import '../../../user/home/alert/required_field_alert.dart';

typedef AddNewsSaveCallback = Future<void> Function({
  required Map<String, dynamic>? existing,
  required String type,
  required DateTime publishedAt,
  required String titleId,
  required String titleEn,
  required String titleZh,
  required String contentId,
  required String contentEn,
  required String contentZh,
  Uint8List? imageBytes,
  String? imageExt,
  String? existingImageUrl,
  required int displayDurationDays,
});

class AdminAddNewsScreen extends StatefulWidget {
  final String lang;
  final Map<String, dynamic>? item;
  final AddNewsSaveCallback onSave;

  const AdminAddNewsScreen({
    super.key,
    required this.lang,
    required this.item,
    required this.onSave,
  });

  @override
  State<AdminAddNewsScreen> createState() => _AdminAddNewsScreenState();
}

class _AdminAddNewsScreenState extends State<AdminAddNewsScreen> {
  static const _primary = Color(0xFF1D72F3);

  bool get _isEdit => widget.item != null;

  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '7');

  String _selectedType = 'update';
  DateTime _selectedDate = DateTime.now();

  Uint8List? _pickedImageBytes;
  String? _pickedImageExt;
  String? _existingImageUrl;

  bool _isSaving = false;

  String? _titleId, _titleEn, _titleZh;
  String? _contentId, _contentEn, _contentZh;

  @override
  void initState() {
    super.initState();
    final d = widget.item;
    if (d != null) {
      _selectedType = (d['type'] ?? 'update').toString().toLowerCase();
      _selectedDate = d['published_at'] != null
          ? DateTime.tryParse(d['published_at'].toString()) ?? DateTime.now()
          : DateTime.now();
      _durationCtrl.text = (d['display_duration_days'] ?? 7).toString();
      _existingImageUrl = d['image_url'];

      _titleCtrl.text = d['title_en'] ?? d['title_id'] ?? '';
      _contentCtrl.text = d['content_en'] ?? d['content_id'] ?? '';

      _titleId = d['title_id'];
      _titleEn = d['title_en'];
      _titleZh = d['title_zh'];
      _contentId = d['content_id'];
      _contentEn = d['content_en'];
      _contentZh = d['content_zh'];
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<bool> _autoTranslate() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    try {
      final results = await Future.wait([
        TranslationHelper.instance.translateDescriptionAllLangs(title, widget.lang),
        TranslationHelper.instance.translateDescriptionAllLangs(content, widget.lang),
      ]);

      if (!mounted) return false;

      final titleResult = results[0];
      final contentResult = results[1];

      setState(() {
        _titleId = (titleResult['id'] ?? '').isEmpty ? title : titleResult['id'];
        _titleEn = (titleResult['en'] ?? '').isEmpty ? title : titleResult['en'];
        _titleZh = (titleResult['zh'] ?? '').isEmpty ? title : titleResult['zh'];
        _contentId = (contentResult['id'] ?? '').isEmpty ? content : contentResult['id'];
        _contentEn = (contentResult['en'] ?? '').isEmpty ? content : contentResult['en'];
        _contentZh = (contentResult['zh'] ?? '').isEmpty ? content : contentResult['zh'];
      });

      return true;
    } catch (e) {
      debugPrint('❌ Translate error: $e');
      return false;
    }
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    final hasImage = _pickedImageBytes != null || (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);

    final List<MissingFieldItem> missing = [];
    if (!hasImage) {
      missing.add(MissingFieldItem(
        icon: Icons.image_rounded,
        label: widget.lang == 'EN' ? 'Image' : widget.lang == 'ZH' ? '图片' : 'Gambar',
      ));
    }
    if (title.isEmpty) {
      missing.add(MissingFieldItem(
        icon: Icons.edit_note_rounded,
        label: widget.lang == 'EN' ? 'Title' : widget.lang == 'ZH' ? '标题' : 'Judul',
      ));
    }
    if (content.isEmpty) {
      missing.add(MissingFieldItem(
        icon: Icons.sticky_note_2_outlined,
        label: widget.lang == 'EN' ? 'Content' : widget.lang == 'ZH' ? '内容' : 'Konten',
      ));
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
        builder: (_) => _TranslatingDialog(color: _primary, lang: widget.lang),
      );
    }

    final translateOk = await _autoTranslate();

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (!translateOk || _titleId == null) {
      setState(() => _isSaving = false);
      _showSnack(
        widget.lang == 'EN'
            ? 'Translation failed. Please check your connection.'
            : widget.lang == 'ZH'
                ? '翻译失败，请检查网络。'
                : 'Terjemahan gagal. Periksa koneksi Anda.',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = false);

    if (mounted) Navigator.of(context).pop();

    await widget.onSave(
      existing: widget.item,
      type: _selectedType,
      publishedAt: _selectedDate,
      titleId: _titleId!,
      titleEn: _titleEn!,
      titleZh: _titleZh!,
      contentId: _contentId ?? content,
      contentEn: _contentEn ?? content,
      contentZh: _contentZh ?? content,
      imageBytes: _pickedImageBytes,
      imageExt: _pickedImageExt,
      existingImageUrl: _existingImageUrl,
      displayDurationDays: int.tryParse(_durationCtrl.text) ?? 7,
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Widget _dlgLabel(IconData icon, String label, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: _primary,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      );

  Widget _typeChip(String type, ValueChanged<String> onTap) {
    final isActive = type == _selectedType;
    final color = type == 'update' ? const Color(0xFF6366F1) : const Color(0xFFF59E0B);
    final icon = type == 'update' ? Icons.update_rounded : Icons.build_rounded;
    final label = type == 'update' ? 'Update' : 'Maintenance';

    return GestureDetector(
      onTap: () => onTap(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: isActive ? 0 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: isActive ? Colors.white : color),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.poppins(
                  color: isActive ? Colors.white : color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return SizedBox(
      height: 130,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, color: Colors.grey.shade400, size: 38),
          const SizedBox(height: 8),
          Text(
            widget.lang == 'EN'
                ? 'Tap to choose image from gallery'
                : widget.lang == 'ZH'
                    ? '点击从相册选择图片'
                    : 'Ketuk untuk pilih gambar dari galeri',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEdit
              ? (widget.lang == 'EN' ? 'Edit News' : widget.lang == 'ZH' ? '编辑新闻' : 'Edit Berita')
              : (widget.lang == 'EN' ? 'Add News' : widget.lang == 'ZH' ? '添加新闻' : 'Tambah Berita'),
          style: GoogleFonts.poppins(
            color: _primary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TYPE
                _dlgLabel(Icons.category_rounded,
                    widget.lang == 'EN' ? 'Type' : widget.lang == 'ZH' ? '类型' : 'Tipe'),
                Row(children: [
                  _typeChip('update', (v) => setState(() => _selectedType = v)),
                  const SizedBox(width: 10),
                  _typeChip('maintenance', (v) => setState(() => _selectedType = v)),
                ]),
                const SizedBox(height: 20),

                // PUBLISHED DATE
                _dlgLabel(
                  Icons.calendar_today_rounded,
                  widget.lang == 'EN' ? 'Published Date' : widget.lang == 'ZH' ? '发布日期' : 'Tanggal Tayang',
                ),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      builder: (c, child) => Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(primary: _primary),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_rounded, color: Colors.black38, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: GoogleFonts.poppins(
                            color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),

                // POP UP DURATION
                _dlgLabel(
                  Icons.timer_rounded,
                  widget.lang == 'EN'
                      ? 'Popup Display Duration (days)'
                      : widget.lang == 'ZH'
                          ? '弹窗显示天数'
                          : 'Durasi Tampil Popup (hari)',
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () {
                        final c = int.tryParse(_durationCtrl.text) ?? 7;
                        if (c > 1) setState(() => _durationCtrl.text = (c - 1).toString());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Icon(Icons.remove_rounded, color: _primary, size: 20),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _durationCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        final c = int.tryParse(_durationCtrl.text) ?? 7;
                        setState(() => _durationCtrl.text = (c + 1).toString());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Icon(Icons.add_rounded, color: _primary, size: 20),
                      ),
                    ),
                  ]),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_rounded, size: 16, color: _primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.lang == 'EN'
                              ? 'This news will automatically pop up for ${_durationCtrl.text} days after the published date.'
                              : widget.lang == 'ZH'
                                  ? '此新闻将在发布日期后的 ${_durationCtrl.text} 天内自动弹出显示。'
                                  : 'Berita ini akan muncul otomatis dalam bentuk popup selama ${_durationCtrl.text} hari sejak tanggal tayang.',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF475569),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // IMAGE
                _dlgLabel(
                  Icons.image_rounded,
                  widget.lang == 'EN' ? 'Image' : widget.lang == 'ZH' ? '图片' : 'Gambar',
                  required: true,
                ),
                GestureDetector(
                  onTap: () async {
                    final picked = await ImagePickerHelper.pickImageFromGallery();
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      final ext = picked.name.split('.').last.toLowerCase();
                      setState(() {
                        _pickedImageBytes = bytes;
                        _pickedImageExt = ext == 'png' ? 'png' : 'jpg';
                        _existingImageUrl = null;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 130),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _pickedImageBytes != null || _existingImageUrl != null
                            ? _primary.withValues(alpha: 0.5)
                            : Colors.grey.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: _pickedImageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Stack(children: [
                              Image.memory(_pickedImageBytes!,
                                  width: double.infinity, height: 160, fit: BoxFit.cover),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.edit_rounded, color: Colors.white, size: 13),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.lang == 'EN' ? 'Change' : 'Ganti',
                                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _pickedImageBytes = null;
                                    _pickedImageExt = null;
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                        color: Colors.red.shade400, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ]),
                          )
                        : _existingImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Stack(children: [
                                  Image.network(_existingImageUrl!,
                                      width: double.infinity,
                                      height: 160,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _imagePlaceholder()),
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.55),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.edit_rounded, color: Colors.white, size: 13),
                                          const SizedBox(width: 4),
                                          Text(
                                            widget.lang == 'EN' ? 'Change' : 'Ganti',
                                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _existingImageUrl = null;
                                        _pickedImageBytes = null;
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                            color: Colors.red.shade400, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ),
                                ]),
                              )
                            : _imagePlaceholder(),
                  ),
                ),
                const SizedBox(height: 24),

                // TITLE
                _dlgLabel(
                  Icons.edit_note_rounded,
                  widget.lang == 'EN' ? 'Title' : widget.lang == 'ZH' ? '标题' : 'Judul',
                  required: true,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _titleCtrl,
                    maxLines: 1,
                    style: GoogleFonts.poppins(
                        color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: widget.lang == 'EN'
                          ? 'Enter news title...'
                          : widget.lang == 'ZH'
                              ? '输入新闻标题...'
                              : 'Masukkan judul berita...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 16),

                // CONTENT
                _dlgLabel(
                  Icons.sticky_note_2_outlined,
                  widget.lang == 'EN' ? 'Content' : widget.lang == 'ZH' ? '内容' : 'Konten',
                  required: true,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _contentCtrl,
                    maxLines: 6,
                    style: GoogleFonts.poppins(
                        color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: widget.lang == 'EN'
                          ? 'Enter news content...'
                          : widget.lang == 'ZH'
                              ? '输入新闻内容...'
                              : 'Masukkan konten berita...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // SAVE BUTTON
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    disabledBackgroundColor: _primary.withValues(alpha: 0.5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _isEdit
                              ? (widget.lang == 'EN'
                                  ? 'Update News'
                                  : widget.lang == 'ZH'
                                      ? '更新新闻'
                                      : 'Perbarui Berita')
                              : (widget.lang == 'EN'
                                  ? 'Save News'
                                  : widget.lang == 'ZH'
                                      ? '保存新闻'
                                      : 'Simpan Berita'),
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TranslatingDialog extends StatefulWidget {
  final Color color;
  final String lang;
  const _TranslatingDialog({required this.color, required this.lang});

  @override
  State<_TranslatingDialog> createState() => _TranslatingDialogState();
}

class _TranslatingDialogState extends State<_TranslatingDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
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
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.translate_rounded, color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              _title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
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