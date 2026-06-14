import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Layar kamera khusus untuk mengambil bukti foto jawaban "No" pada audit.
/// Setelah foto diambil/dipilih, otomatis di-upload ke Supabase Storage
/// dan mengembalikan public URL via Navigator.pop(context, url).
class AuditEvidenceCameraScreen extends StatefulWidget {
  final String lang;
  final String questionText;

  const AuditEvidenceCameraScreen({
    super.key,
    required this.lang,
    required this.questionText,
  });

  @override
  State<AuditEvidenceCameraScreen> createState() => _AuditEvidenceCameraScreenState();
}

class _AuditEvidenceCameraScreenState extends State<AuditEvidenceCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
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
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _cameraController;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      c.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        await _setCamera(_selectedCameraIndex);
      }
    } catch (e) {
      debugPrint('Error init camera: $e');
    }
  }

  Future<void> _setCamera(int index) async {
    if (_cameraController != null) await _cameraController!.dispose();
    _cameraController = CameraController(
      _cameras![index],
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _flashEnabled = false;
        });
      }
      await _checkFlashSupport();
    } on CameraException catch (e) {
      debugPrint('Error set camera: ${e.code}\n${e.description}');
    }
  }

  void _switchCamera() {
    if (_cameras == null || _cameras!.length < 2) return;
    setState(() {
      _isCameraInitialized = false;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    });
    _setCamera(_selectedCameraIndex);
  }

  Future<void> _checkFlashSupport() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      await _cameraController!.setFlashMode(FlashMode.off);
      if (mounted) setState(() => _flashSupported = true);
    } catch (_) {
      if (mounted) setState(() => _flashSupported = false);
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || !_flashSupported) return;
    try {
      final next = _flashEnabled ? FlashMode.off : FlashMode.torch;
      await _cameraController!.setFlashMode(next);
      if (mounted) setState(() => _flashEnabled = !_flashEnabled);
    } catch (_) {}
  }

  // ── Upload ke Supabase Storage ──
  // ── Upload ke Supabase Storage (web & mobile safe via bytes) ──
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
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );

      final publicUrl = _supabase.storage.from('audit-evidence').getPublicUrl(storagePath);

      if (mounted) Navigator.pop(context, publicUrl);
    } catch (e) {
      debugPrint('Upload evidence error: $e');
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_t('Upload failed. Try again.', 'Gagal mengunggah. Coba lagi.', '上传失败，请重试。')),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _cameraController == null || _cameraController!.value.isTakingPicture) return;
    try {
      final XFile picture = await _cameraController!.takePicture();
      await _uploadAndReturn(picture); // ✅ ganti dari picture.path
    } on CameraException catch (e) {
      debugPrint('Error take picture: ${e.code}\n${e.description}');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image == null) return;
      await _uploadAndReturn(image); // ✅ ganti dari image.path
    } catch (e) {
      debugPrint('Error pick image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _cameraController == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(_t('Evidence Photo', 'Foto Bukti', '证据照片'),
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A8A))),
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }

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
                    _IconBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context, null)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.photo_camera_back_rounded, color: Color(0xFFEF4444), size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _t('AUDIT EVIDENCE PHOTO', 'FOTO BUKTI AUDIT', '审计证据照片'),
                                style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700,
                                  fontSize: 13, letterSpacing: 0.5,
                                ),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _IconBtn(
                      icon: _flashEnabled ? Icons.flash_on_rounded : Icons.flash_off_rounded,
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.questionText,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
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
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.75), Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _IconBtn(icon: Icons.photo_library_rounded, onTap: _pickFromGallery),
                    GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        width: 76, height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                        ),
                      ),
                    ),
                    _IconBtn(icon: Icons.flip_camera_ios_rounded, onTap: _switchCamera),
                  ],
                ),
              ),
            ),
          ),

          // ── Loading overlay saat upload ──
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 12),
                    Text(_t('Uploading...', 'Mengunggah...', '上传中...'),
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool highlight;
  const _IconBtn({required this.icon, required this.onTap, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.35 : 1.0,
        child: Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: highlight ? Colors.yellow.withOpacity(0.2) : Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: highlight ? Colors.yellow : Colors.white.withOpacity(0.2),
              width: highlight ? 1.5 : 1,
            ),
          ),
          child: Icon(icon, color: highlight ? Colors.yellow : Colors.white, size: 23),
        ),
      ),
    );
  }
}