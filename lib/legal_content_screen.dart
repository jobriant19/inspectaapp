import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';

class LegalContentScreen extends StatefulWidget {
  final String lang;
  final String docType; // 'terms_conditions' atau 'privacy_policy'

  const LegalContentScreen({
    super.key,
    required this.lang,
    required this.docType,
  });

  @override
  State<LegalContentScreen> createState() => _LegalContentScreenState();
}

class _LegalContentScreenState extends State<LegalContentScreen> {
  bool _isLoading = true;
  String _title = 'Loading...';
  String _content = '';

  @override
  void initState() {
    super.initState();
    _fetchLegalContent();
  }

  Future<void> _fetchLegalContent() async {
    try {
      final response = await Supabase.instance.client
          .from('legal_documents')
          .select('title, content')
          .eq('doc_type', widget.docType)
          .eq('lang_code', widget.lang)
          .maybeSingle();

      if (mounted) {
        setState(() {
          if (response != null) {
            _title = response['title'];
            _content = response['content'];
          } else {
            // Fallback jika konten tidak ditemukan
            _title = 'Not Found';
            _content = 'The requested content could not be found for the selected language.';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _title = 'Error';
          _content = 'An error occurred while fetching the content: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingSkeleton()
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SelectableText(
                _content,
                style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF334155)),
                textAlign: TextAlign.justify,
              ),
            ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(15, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          )),
        ),
      ),
    );
  }
}