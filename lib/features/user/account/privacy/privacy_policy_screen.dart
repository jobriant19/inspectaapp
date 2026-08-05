import 'package:flutter/material.dart';
import '../terms/terms_conditions_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  final String lang;
  const PrivacyPolicyScreen({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    return LegalDocScreen(
      lang: lang,
      docType: 'privacy_policy',
      primaryColor: const Color(0xFF1D72F3),
      headerIcon: Icons.privacy_tip_outlined,
      titleId: 'Kebijakan Privasi',
      titleEn: 'Privacy Policy',
      titleZh: '隐私政策',
    );
  }
}