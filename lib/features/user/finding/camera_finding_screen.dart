import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'add_finding_flow_screen.dart';

class CameraFindingScreen extends StatefulWidget {
  final String lang;
  final bool isProMode;
  final bool isVisitorMode;

  final String selectedLocationName;
  final String? selectedLocationId;
  final String? selectedUnitId;
  final String? selectedSubunitId;
  final String? selectedAreaId;
  final VoidCallback? onFindingSaved;

  const CameraFindingScreen({
    super.key,
    required this.lang,
    required this.isProMode,
    required this.isVisitorMode,
    required this.selectedLocationName,
    this.selectedLocationId,
    this.selectedUnitId,
    this.selectedSubunitId,
    this.selectedAreaId,
    this.onFindingSaved,
  });

  @override
  State<CameraFindingScreen> createState() => _CameraFindingScreenState();
}

class _CameraFindingScreenState extends State<CameraFindingScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  final ImagePicker _picker = ImagePicker();

  // ── Teks terlokalisasi ──
  String _txt(String key) {
    const Map<String, Map<String, String>> texts = {
      'EN': {
        'choose_location': 'Choose Finding Location',
        'loading_camera': 'Loading Camera',
        'preparing': 'Preparing lens for you...',
      },
      'ID': {
        'choose_location': 'Pilih Lokasi Temuan',
        'loading_camera': 'Memuat Kamera',
        'preparing': 'Menyiapkan lensa untuk Anda...',
      },
      'ZH': {
        'choose_location': '选择发现位置',
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
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
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
      debugPrint('Error initializing camera: $e');
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
      if (mounted) setState(() => _isCameraInitialized = true);
    } on CameraException catch (e) {
      debugPrint('Error setting camera: ${e.code}\n${e.description}');
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

  Future<void> _navigateToForm(XFile imageXFile) async {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddFindingFlowScreen(
          lang: widget.lang,
          isProMode: widget.isProMode,
          isVisitorMode: widget.isVisitorMode,
          initialImageXFile: imageXFile,
          preSelectedLocationName: widget.selectedLocationName,
          preSelectedLocationId: widget.selectedLocationId,
          preSelectedUnitId: widget.selectedUnitId,
          preSelectedSubunitId: widget.selectedSubunitId,
          preSelectedAreaId: widget.selectedAreaId,
          onFindingSaved: widget.onFindingSaved,
        ),
      ),
    ).then((result) {
      if (!mounted) return;
      if (result == true) Navigator.pop(context, true);
    });
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized ||
        _cameraController == null ||
        _cameraController!.value.isTakingPicture) return;
    try {
      final XFile picture = await _cameraController!.takePicture();
      await _navigateToForm(picture);
    } on CameraException catch (e) {
      debugPrint('Error taking picture: ${e.code}\n${e.description}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.description}')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      await _navigateToForm(image);
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _cameraController == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: _CameraLoadingScreen(
          loadingCamera: _txt('loading_camera'),
          preparing: _txt('preparing'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Preview ──
          CameraPreview(_cameraController!),

          // ── Top bar ──
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
                    // Tombol kembali — lebih besar
                    _CameraIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context, null),
                      size: 52,
                    ),
                    const SizedBox(width: 10),
                    // Label lokasi — di tengah, lebih besar
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.25), width: 1.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: Color(0xFF00C9E4), size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                widget.selectedLocationName.toUpperCase(),
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
                    // Spacer agar lokasi benar-benar terpusat
                    const SizedBox(width: 10),
                    const SizedBox(width: 52), // mirror lebar tombol back
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom controls ──
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
                      Colors.black.withOpacity(0.75),
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

// ── Tombol ikon kamera yang konsisten ──
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
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}

// ── Loading screen dengan Lottie + teks biru ──
class _CameraLoadingScreen extends StatefulWidget {
  final String loadingCamera;
  final String preparing;

  const _CameraLoadingScreen({
    required this.loadingCamera,
    required this.preparing,
  });

  @override
  State<_CameraLoadingScreen> createState() => _CameraLoadingScreenState();
}

class _CameraLoadingScreenState extends State<_CameraLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lottie — cache agar langsung muncul
              SizedBox(
                width: 220,
                height: 220,
                child: _LottieLoader(),
              ),
              const SizedBox(height: 20),
              Text(
                widget.loadingCamera,
                style: const TextStyle(
                  color: Color(0xFF0284C7),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.preparing,
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 140,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: Color(0xFFBAE6FD),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LottieLoader extends StatelessWidget {
  const _LottieLoader();

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/lottie/camera_loading.json',
      fit: BoxFit.contain,
      frameRate: FrameRate.max,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Lottie error: $error');
        return const Icon(
          Icons.camera_alt_rounded,
          size: 90,
          color: Color(0xFF0284C7),
        );
      },
    );
  }
}