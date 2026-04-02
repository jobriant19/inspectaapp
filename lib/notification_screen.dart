import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  final String lang;
  const NotificationScreen({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    String title = lang == 'ID' ? 'Notifikasi' : lang == 'ZH' ? '通知' : 'Notifications';
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: const Color(0xFF00C9E4)),
      body: Center(child: Text("No $title yet.", style: const TextStyle(color: Colors.grey))),
    );
  }
}