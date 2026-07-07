import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../user/finding/camera/camera_finding_screen.dart';

class QrWarmupService {
  QrWarmupService._();
  static final QrWarmupService instance = QrWarmupService._();

  MobileScannerController? controller;
  Future<void>? _warmupFuture;
  bool isWarming = false;

  bool get isReady => controller != null && controller!.value.isInitialized;

  Future<void> warmUp() {
    if (isReady) return Future.value();
    if (_warmupFuture != null) return _warmupFuture!;
    _warmupFuture = _doWarmUp();
    return _warmupFuture!;
  }

  Future<void> _doWarmUp() async {
    isWarming = true;
    try {
      final c = MobileScannerController(torchEnabled: false, facing: CameraFacing.back);
      await c.start();
      controller = c;
    } catch (e) {
      debugPrint('Error warming up QR scanner: $e');
      controller = null;
    } finally {
      isWarming = false;
      _warmupFuture = null;
    }
  }

  MobileScannerController? takeController() {
    final c = controller;
    controller = null;
    return c;
  }

  Future<void> release() async {
    if (_warmupFuture != null) {
      await _warmupFuture;
    }
    await controller?.dispose();
    controller = null;
  }
}

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
  MobileScannerController? _cameraController;
  bool _isCameraReady = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _prepareController();
  }

  Future<void> _prepareController() async {
    final warm = QrWarmupService.instance;
    await warm.warmUp();
    if (!mounted) return;
    setState(() {
      _cameraController = warm.takeController() ??
          MobileScannerController(torchEnabled: false, facing: CameraFacing.back);
      _isCameraReady = true;
    });
  }

  final Map<String, Map<String, String>> texts = {
    'EN': {
      'title': 'Scan Specific Location',
      'instruction': 'Point the camera at the QR code',
      'instruction_sub': 'Make sure the code is inside the frame and well lit',
      'gallery_error': 'Could not scan image from gallery.',
      'invalid_qr': 'Invalid or unsupported QR Code.',
      'location_not_found': 'Specific location not found.',
      'error_title': 'Scan Failed',
      'ok_button': 'Close',
    },
    'ID': {
      'title': 'Pindai Lokasi Spesifik',
      'instruction': 'Arahkan kamera ke kode QR',
      'instruction_sub': 'Pastikan kode berada dalam kotak dan cahaya cukup terang',
      'gallery_error': 'Tidak dapat memindai gambar dari galeri.',
      'invalid_qr': 'Kode QR tidak valid atau tidak didukung.',
      'location_not_found': 'Lokasi spesifik tidak ditemukan.',
      'error_title': 'Gagal Memindai',
      'ok_button': 'Tutup',
    },
    'ZH': {
      'title': '扫描特定位置',
      'instruction': '将摄像头对准二维码',
      'instruction_sub': '请确保二维码在框内且光线充足',
      'gallery_error': '无法从图库中扫描图像。',
      'invalid_qr': '无效或不支持的二维码。',
      'location_not_found': '未找到特定位置。',
      'error_title': '扫描失败',
      'ok_button': '关闭',
    },
  };

  String getTxt(String key) => texts[widget.lang]?[key] ?? key;

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _switchCamera() async {
    final controller = _cameraController;
    if (controller == null || !_isCameraReady) return;
    try {
      await controller.switchCamera();
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing || !_isCameraReady || capture.barcodes.isEmpty) return;

    final String? rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null) {
      _showError(getTxt('invalid_qr'));
      return;
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(rawValue);
    } catch (e) {
      _showError(getTxt('invalid_qr'));
      return;
    }

    final String? type = data['type'];
    final String? id = data['id']?.toString();
    final int? version = data['v'];

    if (type == null || id == null || id.isEmpty ||
        !['lokasi', 'unit', 'subunit', 'area'].contains(type)) {
      _showError(getTxt('invalid_qr'));
      return;
    }

    setState(() => _isProcessing = true);
    await _cameraController?.stop();

    unawaited(CameraWarmupService.instance.warmUp());

    if (!mounted) return;

    Widget destination;
    if (version == 2) {
      destination = CameraFindingScreen(
        lang: widget.lang,
        isProMode: widget.isProMode,
        isVisitorMode: widget.isVisitorMode,
        selectedLocationName: data['name']?.toString() ?? '',
        selectedLocationId: data['idL']?.toString(),
        selectedUnitId: data['idU']?.toString(),
        selectedSubunitId: data['idS']?.toString(),
        selectedAreaId: data['idA']?.toString(),
      );
    } else {
      destination = CameraFindingScreen(
        lang: widget.lang,
        isProMode: widget.isProMode,
        isVisitorMode: widget.isVisitorMode,
        selectedLocationName: '',
        qrType: type,
        qrId: id,
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destination),
    ).then((_) {
      // Nyalakan ulang scanner ketika kembali ke layar ini (baik karena user
      // menekan back dari kamera, maupun karena lokasi tidak ditemukan).
      if (mounted) {
        setState(() => _isProcessing = false);
        _cameraController?.start();
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;

    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    const redColor = Color(0xFFEF4444);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon X merah
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: redColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: redColor, size: 36),
                ),
                const SizedBox(height: 18),
                Text(
                  getTxt('error_title'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                // Tombol "Close" di tengah
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: redColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      CameraWarmupService.instance.release();
                      if (mounted) {
                        _cameraController?.start();
                      }
                    },
                    child: Text(
                      getTxt('ok_button'),
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scanSize = (screenWidth * 0.78).clamp(260.0, 340.0);
    const accentColor = Color(0xFF1D72F3);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isCameraReady && _cameraController != null)
            MobileScanner(
              controller: _cameraController!,
              onDetect: _handleBarcode,
              placeholderBuilder: (context, child) => Container(color: Colors.black),
              errorBuilder: (context, error, child) => Container(
                color: Colors.black,
                child: Center(
                  child: Icon(Icons.no_photography_rounded, color: Colors.white54, size: 48),
                ),
              ),
            )
          else
            Container(color: Colors.black),
          _buildScanOverlay(scanSize),

          Center(
            child: SizedBox(
              width: scanSize,
              height: scanSize,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  ..._buildCornerAccents(accentColor),
                ],
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  children: [
                    _CircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: accentColor.withValues(alpha: 0.6), width: 1.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.qr_code_scanner_rounded, color: accentColor, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  getTxt('title').toUpperCase(),
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.visible,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _CircleIconButton(
                      icon: Icons.flip_camera_android_rounded,
                      onTap: _switchCamera,
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.2),
                boxShadow: [
                  BoxShadow(color: accentColor.withValues(alpha: 0.15), blurRadius: 14, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.center_focus_strong_rounded, color: accentColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          getTxt('instruction'),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          getTxt('instruction_sub'),
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w400,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay(double scanSize) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ClipPath(
            clipper: _ScanHoleClipper(scanSize),
            child: Container(color: Colors.black.withValues(alpha: 0.35)),
          );
        },
      ),
    );
  }

  List<Widget> _buildCornerAccents(Color color) {
    const double length = 28;
    const double thickness = 4;
    BorderRadius br(double tl, double tr, double bl, double br) =>
        BorderRadius.only(
          topLeft: Radius.circular(tl),
          topRight: Radius.circular(tr),
          bottomLeft: Radius.circular(bl),
          bottomRight: Radius.circular(br),
        );

    Widget corner({required Alignment align, required BorderRadius radius, required List<BoxSide> sides}) {
      return Align(
        alignment: align,
        child: Container(
          width: length,
          height: length,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border(
              top: sides.contains(BoxSide.top) ? BorderSide(color: color, width: thickness) : BorderSide.none,
              bottom: sides.contains(BoxSide.bottom) ? BorderSide(color: color, width: thickness) : BorderSide.none,
              left: sides.contains(BoxSide.left) ? BorderSide(color: color, width: thickness) : BorderSide.none,
              right: sides.contains(BoxSide.right) ? BorderSide(color: color, width: thickness) : BorderSide.none,
            ),
          ),
        ),
      );
    }

    return [
      corner(align: Alignment.topLeft, radius: br(24, 0, 0, 0), sides: const [BoxSide.top, BoxSide.left]),
      corner(align: Alignment.topRight, radius: br(0, 24, 0, 0), sides: const [BoxSide.top, BoxSide.right]),
      corner(align: Alignment.bottomLeft, radius: br(0, 0, 24, 0), sides: const [BoxSide.bottom, BoxSide.left]),
      corner(align: Alignment.bottomRight, radius: br(0, 0, 0, 24), sides: const [BoxSide.bottom, BoxSide.right]),
    ];
  }
}

enum BoxSide { top, bottom, left, right }

class _ScanHoleClipper extends CustomClipper<Path> {
  final double holeSize;
  _ScanHoleClipper(this.holeSize);

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final holeRect = Rect.fromCenter(center: center, width: holeSize, height: holeSize);
    final holeRRect = RRect.fromRectAndRadius(holeRect, const Radius.circular(24));

    return Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(holeRRect);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return oldClipper is _ScanHoleClipper && oldClipper.holeSize != holeSize;
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 52 * 0.45),
      ),
    );
  }
}