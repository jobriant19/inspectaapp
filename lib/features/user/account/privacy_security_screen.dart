import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'legal_content_screen.dart';

class PrivacySecurityScreen extends StatefulWidget {
  final String lang;
  const PrivacySecurityScreen({super.key, required this.lang});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  // Cache konten — di-fetch saat layar ini dibuka
  String? _termsContent;
  String? _privacyContent;

  static const Map<String, Map<String, String>> _txt = {
    'EN': {
      'title': 'Privacy & Security',
      'terms': 'Terms and Conditions',
      'privacy': 'Privacy Policy',
      'terms_sub': 'Read our terms of use',
      'privacy_sub': 'How we handle your data',
    },
    'ID': {
      'title': 'Privasi dan Keamanan',
      'terms': 'Syarat dan Ketentuan',
      'privacy': 'Kebijakan Privasi',
      'terms_sub': 'Baca syarat penggunaan kami',
      'privacy_sub': 'Cara kami mengelola data Anda',
    },
    'ZH': {
      'title': '隐私与安全',
      'terms': '条款和条件',
      'privacy': '隐私政策',
      'terms_sub': '阅读我们的使用条款',
      'privacy_sub': '我们如何处理您的数据',
    },
  };

  String getTxt(String key) => _txt[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    // Pre-fetch kedua dokumen di background
    // sehingga saat tile diklik, konten sudah siap
    _prefetchLegalContent();
  }

  Future<void> _prefetchLegalContent() async {
    try {
      final results = await Future.wait([
        Supabase.instance.client
            .from('legal_documents')
            .select('content')
            .eq('doc_type', 'terms_conditions')
            .eq('lang_code', widget.lang)
            .maybeSingle(),
        Supabase.instance.client
            .from('legal_documents')
            .select('content')
            .eq('doc_type', 'privacy_policy')
            .eq('lang_code', widget.lang)
            .maybeSingle(),
      ]);

      if (mounted) {
        setState(() {
          _termsContent   = results[0]?['content'] ?? '';
          _privacyContent = results[1]?['content'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error prefetching legal content: $e');
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
          getTxt('title'),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D72F3),
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha:0.08),
        iconTheme: const IconThemeData(color: Color(0xFF1D72F3)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            _buildOptionTile(
              context,
              icon: Icons.article_outlined,
              title: getTxt('terms'),
              subtitle: getTxt('terms_sub'),
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 350),
                    reverseTransitionDuration: const Duration(milliseconds: 300),
                    pageBuilder: (_, __, ___) => LegalContentScreen(
                      lang: widget.lang,
                      docType: 'terms_conditions',
                      title: getTxt('terms'),
                      initialContent: _termsContent,
                    ),
                    transitionsBuilder: (_, animation, __, child) {
                      final curved = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                        reverseCurve: Curves.easeIn,
                      );
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(curved),
                        child: child,
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _buildOptionTile(
              context,
              icon: Icons.shield_outlined,
              title: getTxt('privacy'),
              subtitle: getTxt('privacy_sub'),
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 350),
                    reverseTransitionDuration: const Duration(milliseconds: 300),
                    pageBuilder: (_, __, ___) => LegalContentScreen(
                      lang: widget.lang,
                      docType: 'privacy_policy',
                      title: getTxt('privacy'),
                      initialContent: _privacyContent,
                    ),
                    transitionsBuilder: (_, animation, __, child) {
                      final curved = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                        reverseCurve: Curves.easeIn,
                      );
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(curved),
                        child: child,
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1D72F3).withValues(alpha:0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF1D72F3), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}