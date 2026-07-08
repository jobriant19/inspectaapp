import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuditSelfieWarmupService {
  AuditSelfieWarmupService._();
  static final AuditSelfieWarmupService instance = AuditSelfieWarmupService._();

  CameraController? controller;
  List<CameraDescription>? cameras;
  int selectedCameraIndex = 0;
  bool flashSupported = false;
  bool isWarming = false;

  bool get isReady => controller != null && controller!.value.isInitialized;

  Future<void> warmUp() async {
    if (isReady || isWarming) return;
    isWarming = true;
    try {
      cameras ??= await availableCameras();
      if (cameras == null || cameras!.isEmpty) return;

      int idx = cameras!.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
      if (idx < 0) idx = 0;
      selectedCameraIndex = idx;

      final newController = CameraController(
        cameras![selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await newController.initialize();

      bool flashOk = false;
      if (!kIsWeb) {
        try {
          await newController.setFlashMode(FlashMode.off);
          flashOk = true;
        } catch (_) {}
      }

      controller = newController;
      flashSupported = flashOk;
    } catch (e) {
      debugPrint('Error warming up audit selfie camera: $e');
    } finally {
      isWarming = false;
    }
  }

  CameraController? takeController() {
    final c = controller;
    controller = null;
    return c;
  }

  Future<void> release() async {
    await controller?.dispose();
    controller = null;
  }
}

class AuditSelfieScreen extends StatefulWidget {
  final String lang;
  final String locationName;
  final String levelType;
  final String idRef;

  const AuditSelfieScreen({
    super.key,
    required this.lang,
    required this.locationName,
    required this.levelType,
    required this.idRef,
  });

  @override
  State<AuditSelfieScreen> createState() => _AuditSelfieScreenState();
}

class _AuditSelfieScreenState extends State<AuditSelfieScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _flashEnabled = false;
  bool _flashSupported = false;
  // ignore: unused_field
  bool _isRetaking = false;

  Uint8List? _capturedBytes;
  bool _uploading = false;
  String? _errorMsg;

  IconData get _locationLevelIcon {
    switch (widget.levelType) {
      case 'area': return Icons.place_rounded;
      case 'subunit': return Icons.layers_rounded;
      case 'unit': return Icons.business_rounded;
      default: return Icons.location_city_rounded;
    }
  }

  Color get _locationLevelColor {
    switch (widget.levelType) {
      case 'area': return const Color(0xFFF472B6);
      case 'subunit': return const Color(0xFFFBBF24);
      case 'unit': return const Color(0xFF6366F1);
      default: return const Color(0xFF10B981);
    }
  }

  static const _primary = Color(0xFF14B8A6);

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final warm = AuditSelfieWarmupService.instance;
    if (warm.isReady) {
      _cameras = warm.cameras ?? [];
      _selectedCameraIndex = warm.selectedCameraIndex;
      _controller = warm.takeController();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _flashEnabled = false;
          _flashSupported = warm.flashSupported;
          _errorMsg = null;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _errorMsg = null;
        _isCameraInitialized = false;
      });
    }

    try {
      _cameras = await availableCameras();
      if (!mounted) return;

      if (_cameras.isEmpty) {
        setState(() => _errorMsg = _t(
              'No camera detected. Make sure your webcam is connected and allowed.',
              'Tidak ada kamera terdeteksi. Pastikan webcam terhubung dan diizinkan.',
              '未检测到摄像头，请确保摄像头已连接并授予权限。',
            ));
        return;
      }

      _selectedCameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      if (_selectedCameraIndex < 0) _selectedCameraIndex = 0;

      await _startCamera(_selectedCameraIndex);
    } catch (e) {
      print('🚨 DETAIL ERROR KAMERA: $e');
      if (mounted) {
        setState(() => _errorMsg = _t(
              'Camera access failed. Please ensure camera permission is allowed in your browser settings.',
              'Akses kamera gagal. Pastikan izin kamera sudah diaktifkan di pengaturan browser Anda.',
              '摄像头访问失败。请确保在浏览器设置中已授予权限。',
            ));
      }
    }
  }

  Future<void> _startCamera(int index) async {
    await _controller?.dispose();
    if (mounted) {
      setState(() {
        _isCameraInitialized = false;
        _flashSupported = false;
      });
    }

    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = controller;

    try {
      await controller.initialize();

      // Cek dukungan flash (hanya Android; web tidak mendukung torch)
      bool flashOk = false;
      if (!kIsWeb) {
        try {
          await controller.setFlashMode(FlashMode.off);
          flashOk = true;
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _flashEnabled = false;
          _flashSupported = flashOk;
          _errorMsg = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMsg = _t(
              'Camera error. Please retry.',
              'Error kamera. Silakan coba lagi.',
              '摄像头错误，请重试。',
            ));
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _toggleFlash() async {
    if (_controller == null || !_isCameraInitialized) return;
    try {
      await _controller!
          .setFlashMode(_flashEnabled ? FlashMode.off : FlashMode.torch);
      if (mounted) setState(() => _flashEnabled = !_flashEnabled);
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    final next = (_selectedCameraIndex + 1) % _cameras.length;
    if (mounted) {
      setState(() {
        _selectedCameraIndex = next;
        _capturedBytes = null;
      });
    }
    await _startCamera(next);
  }

  Future<void> _capture() async {
    if (_controller == null || !_isCameraInitialized) return;
    try {
      final xfile = await _controller!.takePicture();
      final bytes = await xfile.readAsBytes();
      // Pause preview setelah capture agar controller tetap valid untuk resume
      try {
        await _controller!.pausePreview();
      } catch (_) {}
      if (mounted) setState(() => _capturedBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            _t('Failed to capture photo.', 'Gagal mengambil foto.', '拍照失败。')),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Future<void> _uploadAndProceed() async {
    if (_capturedBytes == null) return;
    if (mounted) setState(() => _uploading = true);

    try {
      final sb = Supabase.instance.client;
      final userId = sb.auth.currentUser?.id ?? 'unknown';
      final ts = DateTime.now().millisecondsSinceEpoch;
      final path =
          'selfies/${widget.levelType}/${widget.idRef}/$userId-$ts.jpg';

      await sb.storage.from('audit-selfie').uploadBinary(
            path,
            _capturedBytes!,
            fileOptions:
                const FileOptions(contentType: 'image/jpeg', upsert: false),
          );

      final url = sb.storage.from('audit-selfie').getPublicUrl(path);
      if (mounted) Navigator.pop(context, url);
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            _t('Upload failed: $e', 'Upload gagal: $e', '上传失败: $e')),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildCameraOrPreview(),
          _buildAppBar(),
          _buildBottomControls(),
          if (_uploading) _buildUploadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              _buildCircleIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _locationLevelColor.withOpacity(0.6),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_locationLevelIcon, color: _locationLevelColor, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Text(
                            widget.locationName.toUpperCase(),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const SizedBox(width: 52),
            ],
          ),
        ),
      ),
    );
  }

  /// Tombol ikon bulat konsisten (dipakai AppBar).
  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 52 * 0.35),
      ),
    );
  }

  Widget _buildCameraOrPreview() {
    if (_capturedBytes != null) {
      return Positioned.fill(
          child: Image.memory(_capturedBytes!, fit: BoxFit.cover));
    }

    if (_errorMsg != null) {
      return Positioned.fill(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.no_photography_outlined,
                    color: Colors.white38, size: 64),
                const SizedBox(height: 16),
                Text(
                  _errorMsg!,
                  style:
                      GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: _initCamera,
                  icon: const Icon(Icons.refresh_rounded,
                      color: _primary, size: 18),
                  label: Text(
                    _t('Retry', 'Coba Lagi', '重试'),
                    style: GoogleFonts.poppins(
                        color: _primary, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_controller == null || !_isCameraInitialized) {
      return const Positioned.fill(child: ColoredBox(color: Colors.black));
    }

    return Positioned.fill(child: CameraPreview(_controller!));
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(32, 20, 32, 44),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.80),
              Colors.transparent,
            ],
          ),
        ),
        child: _capturedBytes == null
            ? _buildCaptureRow()
            : _buildConfirmButtons(),
      ),
    );
  }

  // Layout: [switch camera]  [○ shutter]  [flash]
  Widget _buildCaptureRow() {
    final canCapture = _isCameraInitialized && _errorMsg == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hint text dengan badge background agar lebih terbaca
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12, width: 1),
          ),
          child: Text(
            _t(
              'Take a selfie as proof of your audit location',
              'Ambil selfie sebagai bukti kehadiran di lokasi audit',
              '拍摄自拍照作为审计位置证明',
            ),
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 11.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Kiri: Switch camera ──
            _buildCircleButton(
              icon: Icons.flip_camera_ios_rounded,
              enabled: _isCameraInitialized && _cameras.length > 1,
              onTap: _switchCamera,
              tooltip: _t('Switch Camera', 'Ganti Kamera', '切换摄像头'),
              label: _t('Switch', 'Ganti', '切换'),
            ),

            // ── Tengah: Shutter ──
            _buildShutterButton(canCapture),

            // ── Kanan: Flash ──
            _buildFlashButton(),
          ],
        ),
      ],
    );
  }

  /// Shutter button — lingkaran putih besar dengan ring teal saat aktif.
  Widget _buildShutterButton(bool canCapture) {
    return GestureDetector(
      onTap: canCapture ? _capture : null,
      child: AnimatedOpacity(
        opacity: canCapture ? 1.0 : 0.35,
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: canCapture ? _primary : Colors.white54,
                  width: 3.5,
                ),
                boxShadow: canCapture
                    ? [
                        BoxShadow(
                          color: _primary.withOpacity(0.35),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: canCapture ? Colors.white : Colors.white38,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _t('Capture', 'Foto', '拍照'),
              style: GoogleFonts.poppins(
                color: Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashButton() {
    final supported = _flashSupported && _isCameraInitialized;
    final active = supported && _flashEnabled;

    return Tooltip(
      message: supported
          ? _t('Flash', 'Flash', '闪光灯')
          : _t('Flash not available', 'Flash tidak tersedia', '不支持闪光灯'),
      child: GestureDetector(
        onTap: supported ? _toggleFlash : null,
        child: Opacity(
          opacity: supported ? 1.0 : 0.35,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: active
                      ? Colors.yellow.withOpacity(0.20)
                      : Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active ? Colors.yellow : Colors.white38,
                    width: 1.5,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: Colors.yellow.withOpacity(0.30),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  active ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: active ? Colors.yellow : Colors.white70,
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _t('Flash', 'Flash', '闪光'),
                style: GoogleFonts.poppins(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    Color iconColor = Colors.white,
    required bool enabled,
    required VoidCallback onTap,
    required String tooltip,
    String? label,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.35,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white38, width: 1.5),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              if (label != null) ...[
                const SizedBox(height: 6),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _uploading
                ? null
                : () async {
                    setState(() {
                      _capturedBytes = null;
                      _isRetaking = true;
                    });

                    await _startCamera(_selectedCameraIndex);

                    if (mounted) setState(() => _isRetaking = false);
                  },
            icon: const Icon(Icons.replay_rounded, size: 18),
            label: Text(
              _t('Retake', 'Ambil Ulang', '重拍'),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _uploading ? null : _uploadAndProceed,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(
              _t('Use Photo', 'Gunakan Foto', '使用照片'),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: _primary),
              const SizedBox(height: 16),
              Text(
                _t('Uploading photo…', 'Mengunggah foto…', '正在上传照片…'),
                style:
                    GoogleFonts.poppins(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}