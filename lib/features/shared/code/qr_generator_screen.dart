import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QRGeneratorScreen extends StatefulWidget {
  final String lang;
  final String levelName; // e.g., 'lokasi', 'unit'
  final int levelId;
  final String itemName;

  const QRGeneratorScreen({
    super.key,
    required this.lang,
    required this.levelName,
    required this.levelId,
    required this.itemName,
  });

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  late final String _qrData;
  bool _isSaving = false;

  // Kamus Bahasa
  final Map<String, Map<String, String>> texts = {
    'EN': {
      'title': 'Generate QR Code',
      'save_button': 'Save QR to Database',
      'saving': 'Saving...',
      'save_success': 'QR Code successfully saved!',
      'save_failed': 'Failed to save QR Code. Please try again.',
      'info': 'Scan this QR to directly select this location.',
    },
    'ID': {
      'title': 'Buat Kode QR',
      'save_button': 'Simpan QR ke Database',
      'saving': 'Menyimpan...',
      'save_success': 'Kode QR berhasil disimpan!',
      'save_failed': 'Gagal menyimpan Kode QR. Silakan coba lagi.',
      'info': 'Pindai QR ini untuk memilih lokasi ini secara langsung.',
    },
    'ZH': {
      'title': '生成二维码',
      'save_button': '保存二维码到数据库',
      'saving': '保存中...',
      'save_success': '二维码已成功保存！',
      'save_failed': '二维码保存失败。请再试一次。',
      'info': '扫描此二维码可直接选择此位置。',
    }
  };
  String getTxt(String key) => texts[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    // Membuat data JSON yang akan dienkripsi ke dalam QR code
    // Format ini penting untuk dibaca oleh scanner nantinya
    _qrData = jsonEncode({
      'v': 1, // Versi data, untuk pengembangan di masa depan
      'type': widget.levelName,
      'id': widget.levelId,
    });
  }

  Future<void> _saveQrCode() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      await supabase.from(widget.levelName).update({
        'qrcode': _qrData,
      }).eq('id_${widget.levelName}', widget.levelId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(getTxt('save_success')),
              backgroundColor: Colors.green),
        );
        // Kembali ke halaman sebelumnya dengan hasil true untuk refresh
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${getTxt('save_failed')}: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getTxt('title')),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.itemName.toUpperCase(),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _qrData,
                  version: QrVersions.auto,
                  size: 250.0,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                getTxt('info'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 40),
              _isSaving
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _saveQrCode,
                      icon: const Icon(Icons.save),
                      label: Text(getTxt('save_button')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}