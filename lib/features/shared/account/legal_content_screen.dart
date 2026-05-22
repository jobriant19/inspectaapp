import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LegalContentScreen extends StatefulWidget {
  final String lang;
  final String docType;
  final String title;
  // Konten bisa langsung di-pass jika sudah di-prefetch
  final String? initialContent;

  const LegalContentScreen({
    super.key,
    required this.lang,
    required this.docType,
    required this.title,
    this.initialContent,
  });

  @override
  State<LegalContentScreen> createState() => _LegalContentScreenState();
}

class _LegalContentScreenState extends State<LegalContentScreen> {
  late String _content;

  @override
  void initState() {
    super.initState();
    // Langsung pakai konten dari parameter jika ada
    _content = widget.initialContent ?? '';
    // Hanya fetch jika konten belum tersedia
    if (_content.isEmpty) {
      _fetchLegalContent();
    }
  }

  Future<void> _fetchLegalContent() async {
    try {
      final response = await Supabase.instance.client
          .from('legal_documents')
          .select('content')
          .eq('doc_type', widget.docType)
          .eq('lang_code', widget.lang)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _content = response != null
              ? (response['content'] ?? '')
              : 'Content not found for selected language.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _content = 'An error occurred: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1D72F3)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D72F3),
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.08),
        iconTheme: const IconThemeData(color: Color(0xFF1D72F3)),
        centerTitle: true,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dekoratif
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D72F3), Color(0xFF00C9E4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1D72F3).withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.article_rounded,
                    color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Konten teks
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1D72F3).withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _content.isEmpty
                // Placeholder garis abu saat konten sedang dimuat
                ? Column(
                    children: [
                      const SizedBox(height: 8),
                      ...List.generate(
                        8,
                        (i) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          height: 14,
                          width: i % 4 == 3
                              ? double.infinity * 0.55
                              : double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  )
                : SelectableText(
                    _content,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      color: Color(0xFF334155),
                    ),
                    textAlign: TextAlign.justify,
                  ),
          ),
        ],
      ),
    );
  }
}