import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/image_picker_helper.dart';
import 'camera/camera_finding_screen.dart';

class ResolutionCameraScreen extends StatefulWidget {
  final String lang;
  const ResolutionCameraScreen({super.key, this.lang = 'ID'});

  @override
  State<ResolutionCameraScreen> createState() => _ResolutionCameraScreenState();
}

class _ResolutionCameraScreenState extends State<ResolutionCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _flashEnabled = false;
  bool _flashSupported = false;

  String _txt(String key) {
    const Map<String, Map<String, String>> texts = {
      'EN': {
        'title': 'Resolution Proof',
        'loading_camera': 'Loading Camera',
        'preparing': 'Preparing lens for you...',
      },
      'ID': {
        'title': 'Bukti Resolusi',
        'loading_camera': 'Memuat Kamera',
        'preparing': 'Menyiapkan lensa untuk Anda...',
      },
      'ZH': {
        'title': '分辨率证明',
        'loading_camera': '正在加载相机',
        'preparing': '正在为您准备镜头...',
      },
    };
    return texts[widget.lang]?[key] ?? texts['ID']![key]!;
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
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cameraController!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final warm = CameraWarmupService.instance;

    if (warm.isReady) {
      _cameras = warm.cameras;
      _selectedCameraIndex = warm.selectedCameraIndex;
      _cameraController = warm.takeController();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _flashEnabled = false;
        });
      }
      await _checkFlashSupport();
      return;
    }

    try {
      _cameras = warm.cameras ?? await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        await _setCamera(_selectedCameraIndex);
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _setCamera(int index) async {
    await _cameraController?.dispose();
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
    } catch (e) {
      debugPrint('Error setting camera: $e');
    }
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

  void _switchCamera() {
    if (_cameras == null || _cameras!.length < 2) return;
    setState(() {
      _isCameraInitialized = false;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    });
    _setCamera(_selectedCameraIndex);
  }

  Future<void> _processAndReturnImage(XFile image) async {
    if (!mounted) return;
    Navigator.pop(context, image);
  }

  @override
  Widget build(BuildContext context) {
    final bool ready = _isCameraInitialized && _cameraController != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (!ready)
            const SizedBox.shrink()
          else
            GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity!.abs() > 200) {
                  _switchCamera();
                }
              },
              child: CameraPreview(_cameraController!),
            ),

          // TOP BAR
          if (ready)
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
                    // BACK BUTTON
                    _CameraIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context, null),
                      size: 52,
                    ),
                    const SizedBox(width: 10),
                    // RESOLUTION PROOF LABEL
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha:0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withValues(alpha:0.25), width: 1.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.high_quality_rounded,
                                color: Color(0xFF00C9E4), size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _txt('title').toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
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
                    _FlashButton(
                      supported: _flashSupported && _isCameraInitialized,
                      enabled: _flashEnabled,
                      onTap: _toggleFlash,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // BOTTOM CONTROLS
          if (ready)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
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
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _CameraIconButton(
                      icon: Icons.photo_library_rounded,
                      onTap: () async {
                        final image = await ImagePickerHelper.pickImageFromGallery();
                        if (image != null) await _processAndReturnImage(image);
                      },
                      size: 52,
                    ),
                    GestureDetector(
                      onTap: () async {
                        if (_cameraController == null ||
                            !_cameraController!.value.isInitialized) { return; }
                        try {
                          final image = await _cameraController!.takePicture();
                          await _processAndReturnImage(image);
                        } catch (e) {
                          debugPrint('Error taking picture: $e');
                        }
                      },
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _CameraIconButton(
                      icon: Icons.flip_camera_ios_rounded,
                      onTap: _switchCamera,
                      size: 52,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _CameraIconButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha:0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha:0.2), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}

class _FlashButton extends StatelessWidget {
  final bool supported;
  final bool enabled;
  final VoidCallback onTap;

  const _FlashButton({
    required this.supported,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: supported ? (enabled ? 'Flash On' : 'Flash Off') : 'Flash N/A',
      child: GestureDetector(
        onTap: supported ? onTap : null,
        child: Opacity(
          opacity: supported ? 1.0 : 0.35,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: enabled
                  ? Colors.yellow.withValues(alpha:0.20)
                  : Colors.black.withValues(alpha:0.50),
              shape: BoxShape.circle,
              border: Border.all(
                color: enabled
                    ? Colors.yellow
                    : Colors.white.withValues(alpha:0.2),
                width: 1.5,
              ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: Colors.yellow.withValues(alpha:0.30),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              enabled ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: enabled ? Colors.yellow : Colors.white,
              size: 52 * 0.45,
            ),
          ),
        ),
      ),
    );
  }
}