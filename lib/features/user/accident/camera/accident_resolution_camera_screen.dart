import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';

class AccidentSolutionCameraWarmupService {
  AccidentSolutionCameraWarmupService._();
  static final AccidentSolutionCameraWarmupService instance =
      AccidentSolutionCameraWarmupService._();

  CameraController? controller;
  List<CameraDescription>? cameras;
  int selectedCameraIndex = 0;
  bool isWarming = false;

  bool get isReady => controller != null && controller!.value.isInitialized;

  Future<void> warmUp() async {
    if (isReady || isWarming) return;
    isWarming = true;
    try {
      cameras ??= await availableCameras();
      if (cameras == null || cameras!.isEmpty) return;
      final newController = CameraController(
        cameras![selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await newController.initialize();
      controller = newController;
    } catch (e) {
      debugPrint('Error warming up Accident Solution camera: $e');
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

class AccidentSolutionCameraScreen extends StatefulWidget {
  const AccidentSolutionCameraScreen({super.key});

  @override
  State<AccidentSolutionCameraScreen> createState() =>
      _AccidentSolutionCameraScreenState();
}

class _AccidentSolutionCameraScreenState
    extends State<AccidentSolutionCameraScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _flashEnabled = false;
  bool _flashSupported = false;
  final ImagePicker _picker = ImagePicker();

  static const Color _kAccent = Color(0xFF16A34A);

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
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final warm = AccidentSolutionCameraWarmupService.instance;

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
      debugPrint('Error initializing Accident Solution camera: $e');
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
      debugPrint('Error setting Accident Solution camera: ${e.code}\n${e.description}');
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

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _cameraController == null || _cameraController!.value.isTakingPicture) return;
    try {
      final XFile picture = await _cameraController!.takePicture();
      if (mounted) Navigator.pop(context, picture);
    } on CameraException catch (e) {
      debugPrint('Error taking Accident Solution picture: ${e.code}\n${e.description}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.description}')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image == null) return;
      if (mounted) Navigator.pop(context, image);
    } catch (e) {
      debugPrint('Error picking Accident Solution image: $e');
    }
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
          builder: (context, opacity, child) => Opacity(opacity: opacity, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: Lottie.asset(
                  'assets/lottie/camera_loading.json',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(_kAccent),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _AccidentSolutionPulsingText(text: 'Menyiapkan kamera...', color: _kAccent),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool ready = _isCameraInitialized && _cameraController != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (ready) CameraPreview(_cameraController!) else _buildLoadingView(),

          if (ready) ...[
            // TOP BAR
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
                      _AccidentSolutionCameraIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context, null),
                        size: 52,
                      ),
                      const SizedBox(width: 10),
                      // LABEL: ACCIDENT SOLUTION PHOTO 
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _kAccent.withValues(alpha: 0.6), width: 1.2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(CupertinoIcons.checkmark_shield_fill, color: _kAccent, size: 20),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'ACCIDENT SOLUTION PHOTO',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    letterSpacing: 0.3,
                                  ),
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  maxLines: 2,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _AccidentSolutionFlashButton(
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
                        Colors.black.withValues(alpha: 0.75),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _AccidentSolutionCameraIconButton(
                        icon: Icons.photo_library_rounded,
                        onTap: _pickFromGallery,
                        size: 52,
                      ),
                      GestureDetector(
                        onTap: _takePicture,
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
                      _AccidentSolutionCameraIconButton(
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
        ],
      ),
    );
  }
}

class _AccidentSolutionCameraIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _AccidentSolutionCameraIconButton({
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
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}

class _AccidentSolutionFlashButton extends StatelessWidget {
  final bool supported;
  final bool enabled;
  final VoidCallback onTap;

  const _AccidentSolutionFlashButton({
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
              color: enabled ? Colors.yellow.withValues(alpha: 0.20) : Colors.black.withValues(alpha: 0.50),
              shape: BoxShape.circle,
              border: Border.all(
                color: enabled ? Colors.yellow : Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: Colors.yellow.withValues(alpha: 0.30),
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

class _AccidentSolutionPulsingText extends StatefulWidget {
  final String text;
  final Color color;

  const _AccidentSolutionPulsingText({required this.text, required this.color});

  @override
  State<_AccidentSolutionPulsingText> createState() => _AccidentSolutionPulsingTextState();
}

class _AccidentSolutionPulsingTextState extends State<_AccidentSolutionPulsingText> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Text(
        widget.text,
        style: GoogleFonts.poppins(
          color: widget.color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}