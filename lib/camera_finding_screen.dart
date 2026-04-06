import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CameraFindingScreen extends StatefulWidget {
  final String locationName;
  final int? idLokasi;
  final int? idUnit;
  final int? idSubunit;
  final int? idArea;

  const CameraFindingScreen({
    super.key,
    required this.locationName,
    this.idLokasi,
    this.idUnit,
    this.idSubunit,
    this.idArea,
  });

  @override
  State<CameraFindingScreen> createState() => _CameraFindingScreenState();
}

class _CameraFindingScreenState extends State<CameraFindingScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _setCamera(_selectedCameraIndex);
    }
  }

  Future<void> _setCamera(int index) async {
    _cameraController = CameraController(
      _cameras![index],
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    if (mounted) setState(() => _isCameraInitialized = true);
  }

  void _switchCamera() {
    if (_cameras == null || _cameras!.length < 2) return;
    _selectedCameraIndex = _selectedCameraIndex == 0 ? 1 : 0;
    _isCameraInitialized = false;
    _setCamera(_selectedCameraIndex);
  }

  Future<void> _takePicture() async {
    if (!_cameraController!.value.isInitialized) return;
    try {
      final XFile picture = await _cameraController!.takePicture();
      _showUploadDialog(File(picture.path));
    } catch (e) {
      debugPrint("Error taking picture: $e");
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final File file = File(image.path);
      
      // Validasi Maksimal 24 Jam
      final DateTime lastModified = file.lastModifiedSync();
      final difference = DateTime.now().difference(lastModified);

      if (difference.inHours > 24) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gambar tidak boleh lebih dari 24 jam yang lalu!"),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      _showUploadDialog(file);
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showUploadDialog(File imageFile) {
    final TextEditingController titleCtrl = TextEditingController();
    final TextEditingController descCtrl = TextEditingController();
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20, right: 20, top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Detail Temuan",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ),
                  const SizedBox(height: 15),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(imageFile, height: 150, width: double.infinity, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: "Judul Temuan", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: "Deskripsi", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C9E4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isUploading
                          ? null
                          : () async {
                              if (titleCtrl.text.isEmpty) return;
                              setStateModal(() => isUploading = true);

                              try {
                                final supabase = Supabase.instance.client;
                                final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
                                
                                // Upload ke Storage Supabase temuan_images
                                await supabase.storage.from('temuan_images').upload(fileName, imageFile);
                                final imageUrl = supabase.storage.from('temuan_images').getPublicUrl(fileName);

                                // Insert ke Tabel Temuan
                                await supabase.from('Temuan').insert({
                                  'id_lokasi': widget.idLokasi,
                                  'id_unit': widget.idUnit,
                                  'id_subunit': widget.idSubunit,
                                  'id_area': widget.idArea,
                                  'judul_temuan': titleCtrl.text,
                                  'deskripsi_temuan': descCtrl.text,
                                  'gambar_temuan': imageUrl,
                                  'status_temuan': 'Open',
                                  'poin_temuan': 10, // Default Poin
                                });

                                if (!mounted) return;
                                Navigator.pop(ctx); // Tutup Dialog
                                Navigator.pop(context, true); // Kembali ke Home & Refetch
                              } catch (e) {
                                debugPrint("Upload error: $e");
                                setStateModal(() => isUploading = false);
                              }
                            },
                      child: isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Upload Temuan", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera View
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(_cameraController!),
          ),

          // 2. Top Bar (Lokasi & Back Button)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                                  widget.locationName.toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),

          // 3. Bottom Controls
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