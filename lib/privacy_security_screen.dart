import 'package:flutter/material.dart';
import 'legal_content_screen.dart';

class PrivacySecurityScreen extends StatelessWidget {
  final String lang;

  const PrivacySecurityScreen({super.key, required this.lang});

  // Kamus terjemahan lokal untuk halaman ini
  static const Map<String, Map<String, String>> _txt = {
    'EN': {
      'title': 'Privacy & Security',
      'terms': 'Terms and Conditions',
      'privacy': 'Privacy Policy',
    },
    'ID': {
      'title': 'Privasi dan Keamanan',
      'terms': 'Syarat dan Ketentuan',
      'privacy': 'Kebijakan Privasi',
    },
    'ZH': {
      'title': '隐私与安全',
      'terms': '条款和条件',
      'privacy': '隐私政策',
    },
  };

  String getTxt(String key) => _txt[lang]?[key] ?? key;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(getTxt('title'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            _buildOptionTile(
              context,
              icon: Icons.article_outlined,
              title: getTxt('terms'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LegalContentScreen(lang: lang, docType: 'terms_conditions')),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              context,
              icon: Icons.shield_outlined,
              title: getTxt('privacy'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LegalContentScreen(lang: lang, docType: 'privacy_policy')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk membuat tile yang konsisten dan menarik
  Widget _buildOptionTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1E3A8A)),
            const SizedBox(width: 15),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}