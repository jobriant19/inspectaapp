import 'package:flutter/material.dart';

class RankingScreen extends StatelessWidget {
  final String lang;
  const RankingScreen({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    String text = lang == 'ID' ? 'Halaman Peringkat' : lang == 'ZH' ? '排名页面' : 'Ranking Page';
    return Center(child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)));
  }
}