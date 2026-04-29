import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
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

class _CameraFindingScreenState extends State<CameraFindingScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  final ImagePicker _picker = ImagePicker();

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
  
  // Menangani siklus hidup aplikasi (jika app ke background)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
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
      } else {
        debugPrint("No camera found on this device.");
      }
    } catch (e) {
      debugPrint("Error initializing camera discovery: $e");
    }
  }

  Future<void> _setCamera(int index) async {
    // Hentikan controller lama jika ada
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }
    
    _cameraController = CameraController(
      _cameras![index],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } on CameraException catch (e) {
      debugPrint("Error setting camera: ${e.code}\n${e.description}");
      // Tambahkan umpan balik ke user jika perlu
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

  // FUNGSI UTAMA UNTUK NAVIGASI
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
      if (result == true) {
        // Teruskan sinyal sukses ke LocationBottomSheet → HomeScreen
        Navigator.pop(context, true);
      }
      // Jika result == 'new', user mau buat temuan baru
      // CameraFindingScreen sudah kembali aktif, tidak perlu action
    });
  }

  // AKSI UNTUK MENGAMBIL FOTO DARI KAMERA
  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _cameraController == null || _cameraController!.value.isTakingPicture) {
      return;
    }
    
    try {
      // Ambil gambar
      final XFile picture = await _cameraController!.takePicture();
      // Panggil fungsi navigasi
      await _navigateToForm(picture);
    } on CameraException catch (e) {
      debugPrint("Error taking picture: ${e.code}\n${e.description}");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.description}")));
    }
  }

  // AKSI UNTUK MEMILIH GAMBAR DARI GALERI
  Future<void> _pickFromGallery() async {
    try {
      // Ambil gambar
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return; // User membatalkan pemilihan

      // Panggil fungsi navigasi yang sama
      await _navigateToForm(image);
    } catch (e) {
      debugPrint("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error picking image: $e")));
    }
  }

  // TIDAK ADA LAGI FUNGSI _showUploadDialog, KARENA SUDAH DIHAPUS.

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _cameraController == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _CameraLoadingScreen(lang: widget.lang),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: CameraPreview(_cameraController!),
          ),

          // Top Bar (Lokasi & Back Button)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context, null),
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  widget.selectedLocationName.toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Spacer untuk menyeimbangkan tombol back
                  ],
                ),
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Tombol Galeri
                GestureDetector(
                  onTap: _pickFromGallery,
                  child: Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                    child: const Icon(Icons.photo_library, color: Colors.white),
                  ),
                ),
                
                // Tombol Shutter Kamera
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    width: 75, height: 75,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),

                // Tombol Flip Kamera
                GestureDetector(
                  onTap: _switchCamera,
                  child: Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                    child: const Icon(Icons.flip_camera_ios, color: Colors.white),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ============================================================
// WIDGET: Loading kamera yang menarik
// ============================================================
class _CameraLoadingScreen extends StatelessWidget {
  final String lang;
  const _CameraLoadingScreen({this.lang = 'ID'});

  String get _title {
    switch (lang) {
      case 'EN': return 'Loading Camera';
      case 'ZH': return '正在加载相机';
      default:   return 'Memuat Kamera';
    }
  }

  String get _subtitle {
    switch (lang) {
      case 'EN': return 'Preparing lens for you...';
      case 'ZH': return '正在为您准备镜头...';
      default:   return 'Menyiapkan lensa untuk Anda...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0E1A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Ikon kamera dalam ring ──
            _PulsingCameraIcon(),
            const SizedBox(height: 32),
            // ── Teks loading ──
            Text(
              _title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 28),
            // ── Progress bar tipis ──
            SizedBox(
              width: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor:
                      const Color(0xFF00C9E4).withOpacity(0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF00C9E4)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ikon kamera berdenyut ──
class _PulsingCameraIcon extends StatefulWidget {
  @override
  State<_PulsingCameraIcon> createState() => _PulsingCameraIconState();
}

class _PulsingCameraIconState extends State<_PulsingCameraIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Transform.scale(
        scale: _pulse.value,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00C9E4).withOpacity(0.12),
            border: Border.all(
              color: const Color(0xFF00C9E4).withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C9E4)
                    .withOpacity(0.2 * _pulse.value),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.camera_alt_rounded,
            color: Color(0xFF00C9E4),
            size: 42,
          ),
        ),
      ),
    );
  }
}

// ── Widget dot animasi ──
class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final value = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity = value < 0.5
                ? value * 2
                : (1.0 - value) * 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00C9E4).withOpacity(0.3 + opacity * 0.7),
              ),
            );
          }),
        );
      },
    );
  }
}