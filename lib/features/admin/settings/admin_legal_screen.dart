import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminLegalScreen extends StatefulWidget {
  final String lang;
  final String docType;
  final String title;
  final List<Map<String, dynamic>>? initialDocs;

  const AdminLegalScreen({
    super.key,
    required this.lang,
    required this.docType,
    required this.title,
    this.initialDocs,
  });

  @override
  State<AdminLegalScreen> createState() => _AdminLegalScreenState();
}

class _AdminLegalScreenState extends State<AdminLegalScreen> {
  static const _bg = Color(0xFFF8FAFC);

  Color get _appBarColor => widget.docType == 'privacy_policy'
      ? const Color(0xFF059669)
      : const Color(0xFF0891B2);

  Color get _primary => _appBarColor;

  final _langs = [
    {'code': 'ID', 'label': 'Indonesia', 'flag': '🇮🇩'},
    {'code': 'EN', 'label': 'English',   'flag': '🇺🇸'},
    {'code': 'ZH', 'label': '中文',       'flag': '🇨🇳'},
  ];

  Map<String, List<Map<String, dynamic>>> _docs = {
    'ID': [], 'EN': [], 'ZH': [],
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialDocs != null) {
      _applyDocs(widget.initialDocs!);
    }
    _loadSilent();
  }

  void _applyDocs(List<Map<String, dynamic>> flat) {
    final Map<String, List<Map<String, dynamic>>> grouped = {
      'ID': [], 'EN': [], 'ZH': [],
    };
    for (final row in flat) {
      final code = row['lang_code']?.toString() ?? '';
      if (grouped.containsKey(code)) {
        grouped[code]!.add(row);
      }
    }
    for (final key in grouped.keys) {
      grouped[key]!.sort((a, b) =>
          (a['section_order'] as int? ?? 1)
              .compareTo(b['section_order'] as int? ?? 1));
    }
    if (mounted) setState(() => _docs = grouped);
  }

  Future<void> _loadSilent() async {
    try {
      final res = await Supabase.instance.client
          .from('legal_documents')
          .select()
          .eq('doc_type', widget.docType)
          .order('lang_code')
          .order('section_order');
      if (mounted) _applyDocs(List<Map<String, dynamic>>.from(res));
    } catch (e) {
      debugPrint('AdminLegalScreen background load error: $e');
    }
  }

  int _nextOrder(String langCode) {
    final sections = _docs[langCode] ?? [];
    if (sections.isEmpty) return 1;
    final maxOrder = sections
        .map((s) => s['section_order'] as int? ?? 0)
        .reduce((a, b) => a > b ? a : b);
    return maxOrder + 1;
  }

  void _showSectionDialog({
    required String langCode,
    Map<String, dynamic>? existing,
  }) {
    final isEdit = existing != null;
    final langInfo = _langs.firstWhere((l) => l['code'] == langCode);
    final titleCtrl =
        TextEditingController(text: existing?['title'] ?? '');
    final contentCtrl =
        TextEditingController(text: existing?['content'] ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.88,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // STICKY HEADER
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(langInfo['flag']!,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit
                                  ? (widget.lang == 'EN'
                                      ? 'Edit Section'
                                      : 'Ubah Bagian')
                                  : (widget.lang == 'EN'
                                      ? 'Add New Section'
                                      : 'Tambah Bagian Baru'),
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF1E3A8A),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              langInfo['label']!,
                              style: GoogleFonts.poppins(
                                  color: Colors.black38, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.close,
                              size: 18, color: Colors.grey.shade500),
                        ),
                      ),
                    ],
                  ),
                ),

                // SCROLLABLE BODY
                Flexible(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TITLE LABEL
                        Text(
                          widget.lang == 'EN' ? 'Title' : 'Judul',
                          style: GoogleFonts.poppins(
                            color: Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildDialogField(titleCtrl,
                            maxLines: 1,
                            hint: widget.lang == 'EN'
                                ? 'Section title...'
                                : 'Judul bagian...'),
                        const SizedBox(height: 16),

                        // DESCRIPTION LABEL
                        Text(
                          widget.lang == 'EN'
                              ? 'Description'
                              : 'Deskripsi',
                          style: GoogleFonts.poppins(
                            color: Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildDialogField(contentCtrl,
                            maxLines: 7,
                            hint: widget.lang == 'EN'
                                ? 'Section content...'
                                : 'Isi bagian...'),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // STICKY FOOTER
                Container(
                  padding:
                      const EdgeInsets.fromLTRB(20, 10, 20, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.04),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: isSaving
                      ? Center(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            child: CircularProgressIndicator(
                                color: _primary),
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: Colors.grey.shade300),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 13),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  widget.lang == 'EN'
                                      ? 'Cancel'
                                      : 'Batal',
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (titleCtrl.text.trim().isEmpty ||
                                      contentCtrl.text.trim().isEmpty) {
                                    return;
                                  }
                                  setDlg(() => isSaving = true);
                                  await _saveSection(
                                    langCode: langCode,
                                    existing: existing,
                                    title: titleCtrl.text.trim(),
                                    content: contentCtrl.text.trim(),
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primary,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 13),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                  elevation: 2,
                                ),
                                child: Text(
                                  widget.lang == 'EN'
                                      ? 'Save'
                                      : 'Simpan',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
    );
  }

  Future<void> _saveSection({
    required String langCode,
    required Map<String, dynamic>? existing,
    required String title,
    required String content,
  }) async {
    try {
      if (existing == null) {
        final order = _nextOrder(langCode);
        await Supabase.instance.client.from('legal_documents').insert({
          'doc_type'     : widget.docType,
          'lang_code'    : langCode,
          'title'        : title,
          'content'      : content,
          'section_order': order,
        });
      } else {
        await Supabase.instance.client
            .from('legal_documents')
            .update({'title': title, 'content': content})
            .eq('id', existing['id']);
      }
      _showSnack(widget.lang == 'EN' ? 'Saved!' : 'Tersimpan!');
      _loadSilent();
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  Future<void> _deleteSection(int id, String langCode) async {
    final ok = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (_) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28)),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFEBEB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_forever_rounded,
                        color: Color(0xFFEF4444), size: 34),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.lang == 'EN'
                        ? 'Delete Section?'
                        : widget.lang == 'ZH'
                            ? '删除部分？'
                            : 'Hapus Bagian?',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.lang == 'EN'
                        ? 'This section will be permanently deleted.'
                        : widget.lang == 'ZH'
                            ? '此部分将被永久删除。'
                            : 'Bagian ini akan dihapus secara permanen.',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        height: 1.5),
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
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        widget.lang == 'EN'
                            ? 'Delete'
                            : widget.lang == 'ZH'
                                ? '删除'
                                : 'Hapus',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFFE2E8F0), width: 1.5),
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        widget.lang == 'EN'
                            ? 'Cancel'
                            : widget.lang == 'ZH'
                                ? '取消'
                                : 'Batal',
                        style: GoogleFonts.poppins(
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600),
                      ),
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
      await Supabase.instance.client
          .from('legal_documents')
          .delete()
          .eq('id', id);
      _showSnack(
          widget.lang == 'EN' ? 'Section deleted.' : 'Bagian dihapus.');
      _loadSilent();
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _appBarColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: _appBarColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: _appBarColor,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSilent,
        color: _primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // INFO BANNER
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha:0.06),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: _primary.withValues(alpha:0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: _primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.lang == 'EN'
                            ? 'Each language can have multiple sections. Tap + to add.'
                            : 'Setiap bahasa dapat memiliki beberapa bagian. Ketuk + untuk menambah.',
                        style: GoogleFonts.poppins(
                            color: _primary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // CARD PER LANGUAGE
              ..._langs.map((langInfo) {
                final code = langInfo['code']!;
                final sections = _docs[code] ?? [];
                return _buildLangCard(code, langInfo, sections);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangCard(
    String code,
    Map<String, String> langInfo,
    List<Map<String, dynamic>> sections,
  ) {
    final hasSections = sections.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasSections
              ? _primary.withValues(alpha:0.18)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // LANGUAGE HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(
              children: [
                Text(langInfo['flag']!,
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        langInfo['label']!,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1E3A8A),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        hasSections
                            ? '${sections.length} ${widget.lang == 'EN' ? 'section(s)' : 'bagian'}'
                            : (widget.lang == 'EN'
                                ? 'No sections yet'
                                : 'Belum ada bagian'),
                        style: GoogleFonts.poppins(
                          color: hasSections
                              ? const Color(0xFF10B981)
                              : Colors.black38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // STATUS BADGE
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasSections
                        ? const Color(0xFF10B981).withValues(alpha:0.10)
                        : Colors.orange.withValues(alpha:0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hasSections
                        ? (widget.lang == 'EN' ? 'Set' : 'Ada')
                        : (widget.lang == 'EN' ? 'Empty' : 'Kosong'),
                    style: GoogleFonts.poppins(
                      color: hasSections
                          ? const Color(0xFF10B981)
                          : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // ADD SECTION BUTTON
                GestureDetector(
                  onTap: () => _showSectionDialog(langCode: code),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withValues(alpha:0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // SECTIONS LIST
          if (hasSections) ...[
            Divider(
                color: Colors.grey.shade100, height: 1, thickness: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sections.length,
              separatorBuilder: (_, __) => Divider(
                  color: Colors.grey.shade100, height: 1, thickness: 1),
              itemBuilder: (_, i) =>
                  _buildSectionTile(sections[i], code, i + 1),
            ),
          ],

          if (!hasSections) ...[
            Divider(
                color: Colors.grey.shade100, height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => _showSectionDialog(langCode: code),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha:0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _primary.withValues(alpha:0.2),
                        style: BorderStyle.solid),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline_rounded,
                          color: _primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        widget.lang == 'EN'
                            ? 'Add first section'
                            : 'Tambah bagian pertama',
                        style: GoogleFonts.poppins(
                            color: _primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // TITLE PER SECTION
  Widget _buildSectionTile(
      Map<String, dynamic> section, String langCode, int index) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SECTION ORDERED NUMBER
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha:0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$index',
                style: GoogleFonts.poppins(
                  color: _primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // CONTEN
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section['title'] ?? '',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  section['content'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      color: Colors.black38, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // EDIT BUTTON
          GestureDetector(
            onTap: () => _showSectionDialog(
                langCode: langCode, existing: section),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha:0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.edit_outlined,
                  color: _primary, size: 15),
            ),
          ),
          const SizedBox(width: 6),
          // DELETE BUTTON
          GestureDetector(
            onTap: () =>
                _deleteSection(section['id'] as int, langCode),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha:0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444), size: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(
    TextEditingController ctrl, {
    int maxLines = 1,
    String? hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: GoogleFonts.poppins(
            color: const Color(0xFF1E3A8A), fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.poppins(color: Colors.black26, fontSize: 12),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              vertical: 12, horizontal: 14),
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline
                : Icons.check_circle_outline,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(msg,
                  style: GoogleFonts.poppins(color: Colors.white))),
        ],
      ),
      backgroundColor:
          isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }
}