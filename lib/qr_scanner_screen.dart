import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'camera_finding_screen.dart';

class QRScannerScreen extends StatefulWidget {
  final String lang;
  final bool isProMode;
  final bool isVisitorMode;

  const QRScannerScreen({
    super.key,
    required this.lang,
    required this.isProMode,
    required this.isVisitorMode,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _cameraController = MobileScannerController(
    torchEnabled: false,
    facing: CameraFacing.back,
  );
  bool _isProcessing = false;

  // Kamus Bahasa
  final Map<String, Map<String, String>> texts = {
    'EN': {
      'title': 'Scan Location QR',
      'instruction': 'Point the camera at the QR code',
      'gallery_error': 'Could not scan image from gallery.',
      'invalid_qr': 'Invalid or unsupported QR Code.',
      'fetching_data': 'Fetching location data...',
      'location_not_found': 'Location not found.',
      'error_title': 'Scan Failed',
      'ok_button': 'OK',
    },
    'ID': {
      'title': 'Pindai QR Lokasi',
      'instruction': 'Arahkan kamera ke kode QR',
      'gallery_error': 'Tidak dapat memindai gambar dari galeri.',
      'invalid_qr': 'Kode QR tidak valid atau tidak didukung.',
      'fetching_data': 'Mengambil data lokasi...',
      'location_not_found': 'Lokasi tidak ditemukan.',
      'error_title': 'Gagal Memindai',
      'ok_button': 'Tutup',
    },
    'ZH': {
      'title': '扫描位置二维码',
      'instruction': '将摄像头对准二维码',
      'gallery_error': '无法从图库中扫描图像。',
      'invalid_qr': '无效或不支持的二维码。',
      'fetching_data': '正在获取位置数据...',
      'location_not_found': '未找到位置。',
      'error_title': '扫描失败',
      'ok_button': '好的',
    },
  };

  String getTxt(String key) => texts[widget.lang]?[key] ?? key;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing || capture.barcodes.isEmpty) return;

    await _cameraController.stop();
    setState(() => _isProcessing = true);

    final String? rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null) {
      _showError(getTxt('invalid_qr'));
      return;
    }

    try {
      final Map<String, dynamic> data = jsonDecode(rawValue);
      final String? type = data['type'];
      final int? id = data['id'];
      final int? version = data['v'];

      if (type == null || id == null || version != 1 ||
          !['lokasi', 'unit', 'subunit', 'area'].contains(type)) {
        _showError(getTxt('invalid_qr'));
        return;
      }

      await _fetchLocationAndNavigate(type, id);
    } catch (e) {
      _showError(getTxt('invalid_qr'));
    }
  }

  Future<void> _fetchLocationAndNavigate(String type, int id) async {
    if (!mounted) return;

    final supabase = Supabase.instance.client;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(getTxt('fetching_data')),
      backgroundColor: Colors.blue,
    ));

    try {
      String locationName = '';
      int? locationId, unitId, subunitId, areaId;

      if (type == 'lokasi') {
        final data = await supabase.from('lokasi').select('id_lokasi, nama_lokasi').eq('id_lokasi', id).single();
        locationId = data['id_lokasi'];
        locationName = data['nama_lokasi'] ?? 'Lokasi';
      } else if (type == 'unit') {
        final data = await supabase.from('unit').select('id_unit, nama_unit, lokasi(id_lokasi, nama_lokasi)').eq('id_unit', id).single();
        unitId = data['id_unit'];
        final lokasi = data['lokasi'];
        locationId = lokasi?['id_lokasi'];
        locationName = '${lokasi?['nama_lokasi'] ?? ''} / ${data['nama_unit'] ?? ''}';
      } else if (type == 'subunit') {
        final data = await supabase.from('subunit').select('id_subunit, nama_subunit, unit(id_unit, nama_unit, lokasi(id_lokasi, nama_lokasi))').eq('id_subunit', id).single();
        subunitId = data['id_subunit'];
        final unit = data['unit'];
        final lokasi = unit?['lokasi'];
        unitId = unit?['id_unit'];
        locationId = lokasi?['id_lokasi'];
        locationName = '${lokasi?['nama_lokasi'] ?? ''} / ${unit?['nama_unit'] ?? ''} / ${data['nama_subunit'] ?? ''}';
      } else if (type == 'area') {
        final data = await supabase.from('area').select('id_area, nama_area, subunit(id_subunit, nama_subunit, unit(id_unit, nama_unit, lokasi(id_lokasi, nama_lokasi)))').eq('id_area', id).single();
        areaId = data['id_area'];
        final subunit = data['subunit'];
        final unit = subunit?['unit'];
        final lokasi = unit?['lokasi'];
        subunitId = subunit?['id_subunit'];
        unitId = unit?['id_unit'];
        locationId = lokasi?['id_lokasi'];
        locationName = '${lokasi?['nama_lokasi'] ?? ''} / ${unit?['nama_unit'] ?? ''} / ${subunit?['nama_subunit'] ?? ''} / ${data['nama_area'] ?? ''}';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => CameraFindingScreen(
          lang: widget.lang,
          isProMode: widget.isProMode,
          isVisitorMode: widget.isVisitorMode,
          selectedLocationName: locationName,
          selectedLocationId: locationId,
          selectedUnitId: unitId,
          selectedSubunitId: subunitId,
          selectedAreaId: areaId,
        ),
      ));
    } catch (e) {
      _showError("${getTxt('location_not_found')}");
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(getTxt('error_title')),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text(getTxt('ok_button')),
              onPressed: () {
                Navigator.of(context).pop();
                if (mounted) {
                  _cameraController.start();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(getTxt('title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: _handleBarcode,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.8), width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                getTxt('instruction'),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}