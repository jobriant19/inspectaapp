import 'package:flutter/material.dart';

import '../terms/admin_terms_conditions.dart';

class AdminPrivacyPolicyScreen extends StatelessWidget {
  final String lang;
  final List<Map<String, dynamic>>? initialDocs;

  const AdminPrivacyPolicyScreen({
    super.key,
    required this.lang,
    this.initialDocs,
  });

  @override
  Widget build(BuildContext context) {
    return AdminLegalDocScreen(
      lang: lang,
      docType: 'privacy_policy',
      primaryColor: const Color(0xFF059669),
      headerIcon: Icons.shield_outlined,
      titleId: 'Kebijakan Privasi',
      titleEn: 'Privacy Policy',
      titleZh: '隐私政策',
      initialDocs: initialDocs,
    );
  }
}