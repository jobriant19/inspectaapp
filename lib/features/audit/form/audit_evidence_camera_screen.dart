import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuditEvidenceCameraScreen extends StatefulWidget {
  final String lang;
  final String questionText;

  const AuditEvidenceCameraScreen({
    super.key,
    required this.lang,
    required this.questionText,
  });

  @override
  State<AuditEvidenceCameraScreen> createState() =>
      _AuditEvidenceCameraScreenState();
}

class _AuditEvidenceCameraScreenState extends State<AuditEvidenceCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;

  _CamStatus _status = _CamStatus.loading;

  bool _flashEnabled = false;
  bool _flashSupported = false;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  final _supabase = Supabase.instance.client;

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _status = _CamStatus.loading;
    _cameraController?.dispose();
    _cameraController = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _tearDownCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        await _setCamera(_selectedCameraIndex);
      } else {
        if (mounted) setState(() => _status = _CamStatus.error);
      }
    } catch (e) {
      debugPrint('Error init camera: $e');
      if (mounted) setState(() => _status = _CamStatus.error);
    }
  }

  Future<void> _tearDownCamera() async {
    if (mounted) {
      setState(() => _status = _CamStatus.loading);
    } else {
      _status = _CamStatus.loading;
    }
    await Future.delayed(Duration.zero);
    final old = _cameraController;
    _cameraController = null;
    await old?.dispose();
  }

  Future<void> _setCamera(int index) async {
    await _tearDownCamera();
    if (!mounted) return;

    final newCtrl = CameraController(
      _cameras![index],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await newCtrl.initialize();
      if (!mounted) {
        await newCtrl.dispose();
        return;
      }
      _cameraController = newCtrl;
      setState(() {
        _flashEnabled = false;
        _status = _CamStatus.ready;
      });
      await _checkFlashSupport();
    } on CameraException catch (e) {
      debugPrint('Error set camera: ${e.code}\n${e.description}');
      await newCtrl.dispose();
      if (mounted) setState(() => _status = _CamStatus.error);
    }
  }

  void _switchCamera() {
    if (_cameras == null || _cameras!.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    _setCamera(_selectedCameraIndex);
  }

  Future<void> _checkFlashSupport() async {
    final c = _cameraController;
    if (c == null || !c.value.isInitialized) return;
    try {
      await c.setFlashMode(FlashMode.off);
      if (mounted) setState(() => _flashSupported = true);
    } catch (_) {
      if (mounted) setState(() => _flashSupported = false);
    }
  }

  Future<void> _toggleFlash() async {
    final c = _cameraController;
    if (c == null || !c.value.isInitialized || !_flashSupported) return;
    try {
      final next = _flashEnabled ? FlashMode.off : FlashMode.torch;
      await c.setFlashMode(next);
      if (mounted) setState(() => _flashEnabled = !_flashEnabled);
    } catch (_) {}
  }

  Future<void> _uploadAndReturn(XFile imageFile) async {
    if (!mounted) return;
    setState(() => _isUploading = true);
    try {
      final bytes = await imageFile.readAsBytes();
      final fileName = 'evidence_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'audit_evidence/$fileName';

      await _supabase.storage.from('audit-evidence').uploadBinary(
            storagePath,
            bytes,
            fileOptions:
                const FileOptions(contentType: 'image/jpeg', upsert: true),
          );

      final publicUrl =
          _supabase.storage.from('audit-evidence').getPublicUrl(storagePath);

      if (mounted) Navigator.pop(context, publicUrl);
    } catch (e) {
      debugPrint('Upload evidence error: $e');
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_t('Upload failed. Try again.',
              'Gagal mengunggah. Coba lagi.', '上传失败，请重试。')),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  Future<void> _takePicture() async {
    final c = _cameraController;
    if (_status != _CamStatus.ready ||
        c == null ||
        !c.value.isInitialized ||
        c.value.isTakingPicture) { return; }
    try {
      final XFile picture = await c.takePicture();
      await _uploadAndReturn(picture);
    } on CameraException catch (e) {
      debugPrint('Error take picture: ${e.code}\n${e.description}');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 85);
      if (image == null) return;
      await _uploadAndReturn(image);
    } catch (e) {
      debugPrint('Error pick image: $e');
    }
  }

  // ── Loading screen bergaya audit_selfie_screen ──
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Lottie.asset(
                'assets/lottie/camera_loading.json',
                fit: BoxFit.contain,
                frameRate: FrameRate.max,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.camera_alt_rounded,
                  size: 90,
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _t('Loading Camera', 'Memuat Kamera', '正在加载相机'),
              style: const TextStyle(
                color: Color(0xFF6366F1),
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _t(
                'Preparing camera for evidence photo…',
                'Menyiapkan kamera untuk foto bukti…',
                '正在准备证据拍摄相机…',
              ),
              style: const TextStyle(
                color: Color(0xFF818CF8),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: Color(0xFFE0E7FF),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error screen ──
  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1E3A8A), size: 20),
          onPressed: () => Navigator.pop(context, null),
        ),
        title: Text(
          _t('Evidence Photo', 'Foto Bukti', '证据照片'),
          style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E3A8A)),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_rounded,
                  size: 56, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _t(
                  'Camera not available.\nYou can still upload from gallery.',
                  'Kamera tidak tersedia.\nAnda tetap bisa unggah dari galeri.',
                  '摄像头不可用，\n您仍可从相册上传。',
                ),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library_rounded),
                label: Text(_t('Open Gallery', 'Buka Galeri', '打开相册')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Loading ──
    if (_status == _CamStatus.loading) return _buildLoadingScreen();

    // ── Error ──
    if (_status == _CamStatus.error || _cameraController == null) {
      return _buildErrorScreen();
    }

    // ── Kamera siap ──
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),

          // ── Top bar ──
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  children: [
                    _IconBtn(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context, null)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha:0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withValues(alpha:0.25),
                              width: 1.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.photo_camera_back_rounded,
                                color: Color(0xFFEF4444), size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _t('AUDIT EVIDENCE PHOTO',
                                    'FOTO BUKTI AUDIT', '审计证据照片'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _IconBtn(
                      icon: _flashEnabled
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      onTap: _flashSupported ? _toggleFlash : null,
                      highlight: _flashEnabled,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Subtitle pertanyaan ──
          Positioned(
            top: 90, left: 16, right: 16,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha:0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.questionText,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.white70),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),

          // ── Bottom controls ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha:0.75),
                      Colors.transparent
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _IconBtn(
                        icon: Icons.photo_library_rounded,
                        onTap: _pickFromGallery),
                    GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        width: 76, height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Container(
                            decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle),
                          ),
                        ),
                      ),
                    ),
                    _IconBtn(
                        icon: Icons.flip_camera_ios_rounded,
                        onTap: _switchCamera),
                  ],
                ),
              ),
            ),
          ),

          // ── Loading overlay saat upload ──
          if (_isUploading)
            Container(
              color: Colors.black.withValues(alpha:0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: Lottie.asset(
                        'assets/lottie/uploading.json',
                        fit: BoxFit.contain,
                        frameRate: FrameRate.max,
                        errorBuilder: (_, __, ___) => const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _t('Uploading…', 'Mengunggah…', '上传中…'),
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _CamStatus { loading, ready, error }

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool highlight;
  const _IconBtn(
      {required this.icon, required this.onTap, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.35 : 1.0,
        child: Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: highlight
                ? Colors.yellow.withValues(alpha:0.2)
                : Colors.black.withValues(alpha:0.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: highlight
                  ? Colors.yellow
                  : Colors.white.withValues(alpha:0.2),
              width: highlight ? 1.5 : 1,
            ),
          ),
          child: Icon(icon,
              color: highlight ? Colors.yellow : Colors.white, size: 23),
        ),
      ),
    );
  }
}