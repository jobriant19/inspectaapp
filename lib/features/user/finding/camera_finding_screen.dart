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
  final int? selectedLocationId;
  final int? selectedUnitId;
  final int? selectedSubunitId;
  final int? selectedAreaId;

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

  // FUNGSI UTAMA UNTUK NAVIGASI (DIPAKAI OLEH KEDUA SUMBER GAMBAR)
  Future<void> _navigateToForm(XFile imageXFile) async {
    if (!mounted) return;

    // DIHAPUS: Validasi 24 jam dihapus karena file.lastModified() tidak berfungsi di web.
    // Anda bisa menambahkan kembali validasi ini dengan logika yang lebih kompleks jika sangat dibutuhkan,
    // tetapi untuk memperbaiki fungsionalitas inti, kita nonaktifkan dulu.
    
    // Langsung navigasi ke AddFindingFlowScreen dengan membawa XFile
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFindingFlowScreen(
          lang: widget.lang,
          isProMode: widget.isProMode,
          isVisitorMode: widget.isVisitorMode,
          // DIUBAH: Mengirim XFile, bukan File. Nama parameter juga kita ubah.
          initialImageXFile: imageXFile, 
          preSelectedLocationName: widget.selectedLocationName,
          preSelectedLocationId: widget.selectedLocationId,
          preSelectedUnitId: widget.selectedUnitId,
          preSelectedSubunitId: widget.selectedSubunitId,
          preSelectedAreaId: widget.selectedAreaId,
        ),
      ),
    );
    
    if (result == true) {
      if (mounted) Navigator.pop(context, true);
    }
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
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
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
                      onPressed: () => Navigator.pop(context),
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