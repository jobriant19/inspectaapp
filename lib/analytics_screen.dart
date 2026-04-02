import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  final String lang;
  const AnalyticsScreen({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    String text = lang == 'ID' ? 'Halaman Analitik' : lang == 'ZH' ? '分析页面' : 'Analytics Page';
    return Center(child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)));
  }
}