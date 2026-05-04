import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Digunakan untuk Terms & Conditions maupun Privacy Policy
class AdminLegalScreen extends StatefulWidget {
  final String lang;
  final String docType;   // 'terms_conditions' atau 'privacy_policy'
  final String title;

  const AdminLegalScreen({
    super.key,
    required this.lang,
    required this.docType,
    required this.title,
  });

  @override
  State<AdminLegalScreen> createState() => _AdminLegalScreenState();
}

class _AdminLegalScreenState extends State<AdminLegalScreen> {
  static const _bg = Color(0xFFF8FAFC);
  static const _primary = Color(0xFF0891B2);

  // 3 bahasa: ID, EN, ZH
  final _langs = [
    {'code': 'ID', 'label': 'Indonesia', 'flag': '🇮🇩'},
    {'code': 'EN', 'label': 'English', 'flag': '🇺🇸'},
    {'code': 'ZH', 'label': '中文', 'flag': '🇨🇳'},
  ];

  // Data per bahasa
  Map<String, Map<String, dynamic>?> _docs = {
    'ID': null,
    'EN': null,
    'ZH': null,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('legal_documents')
          .select()
          .eq('doc_type', widget.docType)
          .order('lang_code');

      final Map<String, Map<String, dynamic>?> docs = {
        'ID': null,
        'EN': null,
        'ZH': null,
      };
      for (final row in List<Map<String, dynamic>>.from(res)) {
        final code = row['lang_code']?.toString();
        if (code != null && docs.containsKey(code)) {
          docs[code] = row;
        }
      }

      if (mounted) {
        setState(() {
          _docs = docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditDialog(String langCode, Map<String, dynamic>? existing) {
    final isEdit = existing != null;
    final langInfo = _langs.firstWhere((l) => l['code'] == langCode);
    final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
    final contentCtrl =
        TextEditingController(text: existing?['content'] ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    langInfo['flag']!,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit
                              ? (widget.lang == 'EN' ? 'Edit' : 'Ubah')
                              : (widget.lang == 'EN' ? 'Add' : 'Tambah'),
                          style: GoogleFonts.poppins(
                            color: Colors.black45,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          langInfo['label']!,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF1E3A8A),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
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
              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade100),
              const SizedBox(height: 14),

              // Title
              _dialogLabel(widget.lang == 'EN' ? 'Title' : 'Judul'),
              const SizedBox(height: 6),
              _dialogField(titleCtrl, Icons.title_rounded, maxLines: 1),
              const SizedBox(height: 14),

              // Content
              _dialogLabel(widget.lang == 'EN' ? 'Content' : 'Isi Konten'),
              const SizedBox(height: 6),
              _dialogField(contentCtrl, Icons.article_outlined, maxLines: 8),
              const SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        widget.lang == 'EN' ? 'Cancel' : 'Batal',
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
                        Navigator.pop(ctx);
                        await _saveDoc(
                          langCode: langCode,
                          existing: existing,
                          title: titleCtrl.text.trim(),
                          content: contentCtrl.text.trim(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: Text(
                        widget.lang == 'EN' ? 'Save' : 'Simpan',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveDoc({
    required String langCode,
    required Map<String, dynamic>? existing,
    required String title,
    required String content,
  }) async {
    try {
      final payload = {
        'doc_type': widget.docType,
        'lang_code': langCode,
        'title': title,
        'content': content,
      };
      if (existing == null) {
        await Supabase.instance.client.from('legal_documents').insert(payload);
      } else {
        await Supabase.instance.client
            .from('legal_documents')
            .update({'title': title, 'content': content})
            .eq('id', existing['id']);
      }
      _showSnack(widget.lang == 'EN' ? 'Saved!' : 'Tersimpan!');
      _load();
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  Future<void> _deleteDoc(int id, String langCode) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(
              widget.lang == 'EN' ? 'Delete?' : 'Hapus?',
              style: GoogleFonts.poppins(
                  color: const Color(0xFF1E3A8A),
                  fontWeight: FontWeight.bold),
            ),
            content: Text(
              widget.lang == 'EN'
                  ? 'Delete $langCode document?'
                  : 'Hapus dokumen $langCode?',
              style: GoogleFonts.poppins(color: Colors.black54),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(widget.lang == 'EN' ? 'Cancel' : 'Batal',
                    style: TextStyle(color: Colors.grey.shade500)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444)),
                child: Text(widget.lang == 'EN' ? 'Delete' : 'Hapus',
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;
    try {
      await Supabase.instance.client
          .from('legal_documents')
          .delete()
          .eq('id', id);
      _showSnack(widget.lang == 'EN' ? 'Deleted.' : 'Dihapus.');
      _load();
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
        foregroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: const Color(0xFF1E3A8A),
          ),
        ),
      ),
      body: _isLoading
          ? _buildShimmer()
          : RefreshIndicator(
              onRefresh: _load,
              color: _primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _primary.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: _primary, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.lang == 'EN'
                                  ? 'Manage content for each language (ID, EN, ZH)'
                                  : 'Kelola konten untuk setiap bahasa (ID, EN, ZH)',
                              style: GoogleFonts.poppins(
                                  color: _primary, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Card per bahasa
                    ..._langs.map((langInfo) {
                      final code = langInfo['code']!;
                      final doc = _docs[code];
                      return _buildLangCard(code, langInfo, doc);
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
    Map<String, dynamic>? doc,
  ) {
    final hasDoc = doc != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasDoc
              ? _primary.withOpacity(0.15)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header bahasa ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
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
                        hasDoc
                            ? (widget.lang == 'EN'
                                ? 'Content available'
                                : 'Konten tersedia')
                            : (widget.lang == 'EN'
                                ? 'No content yet'
                                : 'Belum ada konten'),
                        style: GoogleFonts.poppins(
                          color: hasDoc
                              ? const Color(0xFF10B981)
                              : Colors.black38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasDoc
                        ? const Color(0xFF10B981).withOpacity(0.10)
                        : Colors.orange.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hasDoc
                        ? (widget.lang == 'EN' ? 'Set' : 'Ada')
                        : (widget.lang == 'EN' ? 'Empty' : 'Kosong'),
                    style: GoogleFonts.poppins(
                      color: hasDoc
                          ? const Color(0xFF10B981)
                          : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Preview konten (jika ada) ──
          if (hasDoc) ...[
            Divider(
                color: Colors.grey.shade100, height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc['title'] ?? '',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doc['content'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        color: Colors.black38, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],

          // ── Action buttons ──
          Divider(color: Colors.grey.shade100, height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(
                      hasDoc ? Icons.edit_outlined : Icons.add_rounded,
                      size: 15,
                      color: _primary,
                    ),
                    label: Text(
                      hasDoc
                          ? (widget.lang == 'EN' ? 'Edit' : 'Ubah')
                          : (widget.lang == 'EN' ? 'Add' : 'Tambah'),
                      style: GoogleFonts.poppins(
                          color: _primary, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _primary),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _showEditDialog(code, doc),
                  ),
                ),
                if (hasDoc) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 15, color: Color(0xFFEF4444)),
                    label: Text(
                      widget.lang == 'EN' ? 'Delete' : 'Hapus',
                      style: GoogleFonts.poppins(
                          color: const Color(0xFFEF4444),
                          fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _deleteDoc(doc['id'], code),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogLabel(String label) => Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.black54,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      );

  Widget _dialogField(TextEditingController ctrl, IconData icon,
      {int maxLines = 1}) {
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
          prefixIcon: maxLines == 1
              ? Icon(icon, color: Colors.black38, size: 18)
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            3,
            (_) => Container(
              height: 140,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor:
          isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }
}