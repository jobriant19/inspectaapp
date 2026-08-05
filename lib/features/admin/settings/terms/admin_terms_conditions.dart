import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/translation_service.dart';
import '../../../user/home/alert/required_field_alert.dart';

class AdminTermsConditionsScreen extends StatelessWidget {
  final String lang;
  final List<Map<String, dynamic>>? initialDocs;

  const AdminTermsConditionsScreen({
    super.key,
    required this.lang,
    this.initialDocs,
  });

  @override
  Widget build(BuildContext context) {
    return AdminLegalDocScreen(
      lang: lang,
      docType: 'terms_conditions',
      primaryColor: const Color(0xFF0891B2),
      headerIcon: Icons.gavel_rounded,
      titleId: 'Syarat dan Ketentuan',
      titleEn: 'Terms & Conditions',
      titleZh: '条款和条件',
      initialDocs: initialDocs,
    );
  }
}

class AdminLegalDocScreen extends StatefulWidget {
  final String lang;
  final String docType;
  final Color primaryColor;
  final IconData headerIcon;
  final String titleId;
  final String titleEn;
  final String titleZh;
  final List<Map<String, dynamic>>? initialDocs;

  const AdminLegalDocScreen({
    super.key,
    required this.lang,
    required this.docType,
    required this.primaryColor,
    required this.headerIcon,
    required this.titleId,
    required this.titleEn,
    required this.titleZh,
    this.initialDocs,
  });

  @override
  State<AdminLegalDocScreen> createState() => _AdminLegalDocScreenState();
}

class _AdminLegalDocScreenState extends State<AdminLegalDocScreen> {
  static const _bg = Color(0xFFF8FAFC);
  static const int _perPage = 7;

  static const List<Map<String, String>> _tabLangs = [
    {'code': 'ID', 'label': 'Indonesia', 'flag': '🇮🇩'},
    {'code': 'EN', 'label': 'English', 'flag': '🇺🇸'},
    {'code': 'ZH', 'label': '中文', 'flag': '🇨🇳'},
  ];

  List<Map<String, dynamic>> _sections = [];
  bool _isLoading = true;
  String _activeTab = 'ID';
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  int _currentPage = 1;

  Color get _primary => widget.primaryColor;

  String get _pageTitle {
    if (widget.lang == 'EN') return widget.titleEn;
    if (widget.lang == 'ZH') return widget.titleZh;
    return widget.titleId;
  }

  String _t3(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  String _titleKey(String tab) =>
      tab == 'EN' ? 'title_en' : (tab == 'ZH' ? 'title_zh' : 'title');
  String _contentKey(String tab) =>
      tab == 'EN' ? 'content_en' : (tab == 'ZH' ? 'content_zh' : 'content');

  @override
  void initState() {
    super.initState();
    if (widget.initialDocs != null) {
      _sections = _sorted(widget.initialDocs!);
      _isLoading = false;
    }
    _loadSilent();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _sorted(List<Map<String, dynamic>> raw) {
    final list = List<Map<String, dynamic>>.from(raw);
    list.sort((a, b) {
      final da = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(1970);
      final db = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(1970);
      return da.compareTo(db);
    });
    return list;
  }

  Future<void> _loadSilent() async {
    try {
      final res = await Supabase.instance.client
          .from('legal_documents')
          .select()
          .eq('doc_type', widget.docType)
          .order('created_at');
      if (mounted) {
        setState(() {
          _sections = _sorted(List<Map<String, dynamic>>.from(res));
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('${widget.docType} load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _sections;
    final key = _titleKey(_activeTab);
    return _sections.where((s) => (s[key] ?? '').toString().toLowerCase().contains(q)).toList();
  }

  void _showSectionDialog({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final tabInfo = _tabLangs.firstWhere((l) => l['code'] == _activeTab);
    final titleCtrl = TextEditingController(
        text: isEdit ? (existing[_titleKey(_activeTab)] ?? '').toString() : '');
    final contentCtrl = TextEditingController(
        text: isEdit ? (existing[_contentKey(_activeTab)] ?? '').toString() : '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(dialogCtx).size.height * 0.88),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(tabInfo['flag']!, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Icon(widget.headerIcon, size: 18, color: const Color(0xFF1D72F3)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit
                                ? _t3('Edit Section', 'Ubah Bagian', '编辑部分')
                                : _t3('Add New Section', 'Tambah Bagian Baru', '添加新部分'),
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF1D72F3),
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          Text(tabInfo['label']!,
                              style: GoogleFonts.poppins(color: Colors.black38, fontSize: 11)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(dialogCtx),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),
              ),

              // BODY
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel(Icons.short_text_rounded, _t3('Title', 'Judul', '标题')),
                      const SizedBox(height: 6),
                      _buildDialogField(titleCtrl,
                          maxLines: 1,
                          hint: _t3('Section title...', 'Judul bagian...', '部分标题...')),
                      const SizedBox(height: 16),
                      _fieldLabel(Icons.notes_rounded, _t3('Description', 'Deskripsi', '描述')),
                      const SizedBox(height: 6),
                      _buildDialogField(contentCtrl,
                          maxLines: 7,
                          hint: _t3('Section content...', 'Isi bagian...', '部分内容...')),
                      const SizedBox(height: 6),
                      Text(
                        _t3(
                          'Will be auto-translated to the other 2 languages.',
                          'Akan diterjemahkan otomatis ke 2 bahasa lainnya.',
                          '将自动翻译为其他两种语言。',
                        ),
                        style: GoogleFonts.poppins(
                            fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // FOOTER
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(_t3('Cancel', 'Batal', '取消'),
                            style: GoogleFonts.poppins(
                                color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => _onSaveTapped(
                          dialogCtx: dialogCtx,
                          existing: existing,
                          titleCtrl: titleCtrl,
                          contentCtrl: contentCtrl,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: Text(_t3('Save', 'Simpan', '保存'),
                            style:
                                GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
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

  Widget _fieldLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 13, color: _primary),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.poppins(
                color: _primary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        const SizedBox(width: 3),
        Text('*',
            style: GoogleFonts.poppins(
                color: const Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildDialogField(TextEditingController ctrl, {int maxLines = 1, String? hint}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.black26, fontSize: 12),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        ),
      ),
    );
  }

  Future<void> _onSaveTapped({
    required BuildContext dialogCtx,
    required Map<String, dynamic>? existing,
    required TextEditingController titleCtrl,
    required TextEditingController contentCtrl,
  }) async {
    final title = titleCtrl.text.trim();
    final content = contentCtrl.text.trim();

    final missing = <MissingFieldItem>[];
    if (title.isEmpty) {
      missing.add(MissingFieldItem(
          icon: Icons.short_text_rounded, label: _t3('Title', 'Judul', '标题')));
    }
    if (content.isEmpty) {
      missing.add(MissingFieldItem(
          icon: Icons.notes_rounded, label: _t3('Description', 'Deskripsi', '描述')));
    }
    if (missing.isNotEmpty) {
      RequiredFieldAlert.show(context, lang: widget.lang, missingFields: missing);
      return;
    }

    final sourceLang = _activeTab;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _LegalTranslatingDialog(color: _primary, lang: widget.lang),
      );
    }

    Map<String, String> titleAll = {'id': title, 'en': title, 'zh': title};
    Map<String, String> contentAll = {'id': content, 'en': content, 'zh': content};
    try {
      final results = await Future.wait<Map<String, String>>([
        TranslationHelper.instance.translateDescriptionAllLangs(title, sourceLang),
        TranslationHelper.instance.translateDescriptionAllLangs(content, sourceLang),
      ]);
      titleAll = results[0];
      contentAll = results[1];
    } catch (e) {
      debugPrint('${widget.docType} translate error: $e');
    }

    if (mounted) Navigator.of(context, rootNavigator: true).pop();

    final data = {
      'doc_type': widget.docType,
      'title': titleAll['id']!.isEmpty ? null : titleAll['id'],
      'title_en': titleAll['en']!.isEmpty ? null : titleAll['en'],
      'title_zh': titleAll['zh']!.isEmpty ? null : titleAll['zh'],
      'content': contentAll['id']!.isEmpty ? null : contentAll['id'],
      'content_en': contentAll['en']!.isEmpty ? null : contentAll['en'],
      'content_zh': contentAll['zh']!.isEmpty ? null : contentAll['zh'],
    };

    try {
      if (existing == null) {
        await Supabase.instance.client.from('legal_documents').insert(data);
      } else {
        await Supabase.instance.client
            .from('legal_documents')
            .update(data)
            .eq('id', existing['id']);
      }
      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
      _showResultPopup(success: true, message: _t3('Saved!', 'Tersimpan!', '已保存！'));
      _loadSilent();
    } catch (e) {
      _showResultPopup(success: false, message: 'Error: $e');
    }
  }

  Future<void> _deleteSection(int id) async {
    final ok = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (_) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration:
                        const BoxDecoration(color: Color(0xFFFFEBEB), shape: BoxShape.circle),
                    child: const Icon(Icons.delete_forever_rounded,
                        color: Color(0xFFEF4444), size: 34),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _t3('Delete Section?', 'Hapus Bagian?', '删除部分？'),
                    style: GoogleFonts.poppins(
                        fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _t3(
                      'This section will be permanently deleted from all languages.',
                      'Bagian ini akan dihapus secara permanen dari semua bahasa.',
                      '此部分将从所有语言中永久删除。',
                    ),
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: const Color(0xFF64748B), height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_t3('Delete', 'Hapus', '删除'),
                          style:
                              GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_t3('Cancel', 'Batal', '取消'),
                          style: GoogleFonts.poppins(
                              color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;

    if (!ok) return;
    try {
      await Supabase.instance.client.from('legal_documents').delete().eq('id', id);
      _showResultPopup(success: true, message: _t3('Section deleted.', 'Bagian dihapus.', '部分已删除。'));
      _loadSilent();
    } catch (e) {
      _showResultPopup(success: false, message: 'Error: $e');
    }
  }

  void _showResultPopup({required bool success, required String message}) {
    if (!mounted) return;
    final Color mainColor = success ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final Color bgColor = success ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
    final IconData icon = success ? Icons.check_circle_rounded : Icons.error_rounded;
    final String title =
        success ? _t3('Success!', 'Berhasil!', '成功！') : _t3('Failed!', 'Gagal!', '失败！');

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: success ? 'success' : 'error',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.80, end: 1.0)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) {
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (ctx.mounted && Navigator.of(ctx).canPop()) {
            Navigator.of(ctx).pop();
          }
        });

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: mainColor.withValues(alpha: 0.25),
                    blurRadius: 40,
                    spreadRadius: 4,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: mainColor.withValues(alpha: 0.25), width: 2),
                    ),
                    child: Icon(icon, color: mainColor, size: 44),
                  ),
                  const SizedBox(height: 18),
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.w800, color: mainColor)),
                  const SizedBox(height: 8),
                  Text(message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 0.0),
                      duration: const Duration(milliseconds: 2000),
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 4,
                        backgroundColor: mainColor.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(mainColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: GestureDetector(
        onTap: () => _showSectionDialog(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primary, _primary.withValues(alpha: 0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: _primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_t3('Add New Section', 'Tambah Bagian Baru', '添加新部分'),
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text(_t3('Tap to add a new section', 'Ketuk untuk menambah bagian baru', '点击添加新部分'),
                        style: GoogleFonts.poppins(
                            fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabChip(Map<String, String> info) {
    final isActive = info['code'] == _activeTab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _activeTab = info['code']!;
          _currentPage = 1;
        }),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? _primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isActive ? _primary : Colors.grey.shade300, width: isActive ? 1.5 : 1),
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: _primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3)),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(info['flag']!, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(info['label']!,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() {
            _search = v;
            _currentPage = 1;
          }),
          textAlignVertical: TextAlignVertical.center,
          style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 14),
          decoration: InputDecoration(
            hintText: _t3('Search section...', 'Cari bagian...', '搜索部分...'),
            hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 20),
            suffixIcon: _search.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() {
                        _search = '';
                        _currentPage = 1;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFEF4444)),
                    ),
                  )
                : null,
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildCountBadge(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.list_alt_rounded, size: 13, color: _primary),
              const SizedBox(width: 5),
              Text('$count ${_t3('sections', 'bagian', '部分')}',
                  style:
                      GoogleFonts.poppins(color: _primary, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
          height: 78,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isFiltering = _search.isNotEmpty;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              height: 140,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                isFiltering ? Icons.search_off_rounded : widget.headerIcon,
                size: 80,
                color: _primary.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltering
                  ? _t3('No matching sections', 'Bagian Tidak Ditemukan', '未找到匹配部分')
                  : _t3('No sections yet', 'Belum Ada Bagian', '暂无部分'),
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: _primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isFiltering
                  ? _t3(
                      'Try adjusting your search keyword to find what you\'re looking for.',
                      'Coba ubah kata kunci pencarian untuk menemukan yang Anda cari.',
                      '尝试调整搜索关键词以查找您需要的内容。')
                  : _t3(
                      'Sections will show up here as soon as they\'re added.',
                      'Bagian akan muncul di sini setelah ditambahkan.',
                      '添加部分后将显示在此处。'),
              style: GoogleFonts.poppins(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black45, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (isFiltering) ...[
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() {
                    _search = '';
                    _currentPage = 1;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _primary.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 15, color: _primary),
                      const SizedBox(width: 6),
                      Text(_t3('Clear search', 'Hapus pencarian', '清除搜索'),
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w700, color: _primary)),
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

  Widget _buildSectionCard(Map<String, dynamic> section, int number) {
    final title = (section[_titleKey(_activeTab)] ?? '').toString();
    final content = (section[_contentKey(_activeTab)] ?? '').toString();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
            child: Center(
              child: Text('$number',
                  style: GoogleFonts.poppins(
                      color: _primary, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.isEmpty ? '-' : title,
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF1E3A8A), fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(content.isEmpty ? '-' : content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(color: Colors.black45, fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showSectionDialog(existing: section),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 15),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _deleteSection(section['id'] as int),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 15),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final totalPages = filtered.isEmpty ? 1 : (filtered.length / _perPage).ceil();
    if (_currentPage > totalPages) _currentPage = totalPages;
    if (_currentPage < 1) _currentPage = 1;
    final start = (_currentPage - 1) * _perPage;
    final end = (start + _perPage).clamp(0, filtered.length);
    final pageItems = filtered.isEmpty ? <Map<String, dynamic>>[] : filtered.sublist(start, end);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: _primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_pageTitle,
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: _primary)),
      ),
      body: Column(
        children: [
          _buildAddButton(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(children: _tabLangs.map(_buildTabChip).toList()),
          ),
          _buildSearchField(),
          const SizedBox(height: 10),
          _buildCountBadge(filtered.length),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : pageItems.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadSilent,
                        color: _primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: pageItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _buildSectionCard(pageItems[i], start + i + 1),
                        ),
                      ),
          ),
          if (!_isLoading && totalPages > 1)
            _LegalPageIndicator(
              currentPage: _currentPage,
              totalPages: totalPages,
              color: _primary,
              onPageChanged: (p) => setState(() => _currentPage = p),
            ),
        ],
      ),
    );
  }
}

class _LegalTranslatingDialog extends StatefulWidget {
  final Color color;
  final String lang;
  const _LegalTranslatingDialog({required this.color, required this.lang});

  @override
  State<_LegalTranslatingDialog> createState() => _LegalTranslatingDialogState();
}

class _LegalTranslatingDialogState extends State<_LegalTranslatingDialog>
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
                    BoxShadow(
                        color: widget.color.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: const Icon(Icons.translate_rounded, color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(height: 22),
            Text(_title,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(_subtitle,
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B), height: 1.4),
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

class _LegalPageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Color color;
  final ValueChanged<int> onPageChanged;

  const _LegalPageIndicator({
    required this.currentPage,
    required this.totalPages,
    required this.color,
    required this.onPageChanged,
  });

  static const int _maxVisibleButtons = 5;

  List<int> _visiblePageNumbers() {
    if (totalPages <= _maxVisibleButtons) {
      return List.generate(totalPages, (i) => i + 1);
    }
    int start = currentPage - 2;
    int end = currentPage + 2;
    if (start < 1) {
      start = 1;
      end = _maxVisibleButtons;
    } else if (end > totalPages) {
      end = totalPages;
      start = totalPages - (_maxVisibleButtons - 1);
    }
    return List.generate(end - start + 1, (i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    final bool canPrev = currentPage > 1;
    final bool canNext = currentPage < totalPages;
    final pageNumbers = _visiblePageNumbers();

    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double bottomSpacing = bottomInset > 0 ? bottomInset + 10 : 16;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomSpacing),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            _arrowButton(
              icon: Icons.arrow_back_ios_new_rounded,
              enabled: canPrev,
              onTap: () {
                if (canPrev) onPageChanged(currentPage - 1);
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  for (final p in pageNumbers) ...[
                    Expanded(child: _pageButton(p)),
                    if (p != pageNumbers.last) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            _arrowButton(
              icon: Icons.arrow_forward_ios_rounded,
              enabled: canNext,
              onTap: () {
                if (canNext) onPageChanged(currentPage + 1);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageButton(int page) {
    final bool isActive = page == currentPage;
    return GestureDetector(
      onTap: () {
        if (page != currentPage) onPageChanged(page);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: isActive ? null : Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text('$page',
            style: GoogleFonts.poppins(
                color: isActive ? Colors.white : color, fontWeight: FontWeight.w800, fontSize: 13)),
      ),
    );
  }

  Widget _arrowButton({required IconData icon, required bool enabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: enabled ? color : Colors.grey.shade400),
      ),
    );
  }
}