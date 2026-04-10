import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'explore_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AddFindingFlowScreen extends StatefulWidget {
  final String lang;
  final bool isProMode;
  final bool isVisitorMode;
  final XFile initialImageXFile;

  final String? preSelectedLocationName;
  final int? preSelectedLocationId;
  final int? preSelectedUnitId;
  final int? preSelectedSubunitId;
  final int? preSelectedAreaId;

  const AddFindingFlowScreen({
    super.key,
      required this.lang,
      required this.isProMode,
      required this.isVisitorMode,
      required this.initialImageXFile, 
      this.preSelectedLocationName,
      this.preSelectedLocationId,
      this.preSelectedUnitId,
      this.preSelectedSubunitId,
      this.preSelectedAreaId,
  });

  @override
  State<AddFindingFlowScreen> createState() => _AddFindingFlowScreenState();
}

class _AddFindingFlowScreenState extends State<AddFindingFlowScreen> {
  // State untuk alur
  XFile? _imageXFile; 
  bool _isSaving = false;

  // State untuk kamera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  final ImagePicker _picker = ImagePicker();

  // State untuk data form
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Lokasi
  Map<String, dynamic>? _selectedLocation;
  // Kategori
  Map<String, dynamic>? _selectedCategory;
  // Penanggung Jawab (Pro)
  Map<String, dynamic>? _selectedAssignee;
  // Batas Waktu (Pro)
  DateTime? _selectedDueDate;
  // Eskalasi (Pro)
  String? _selectedEscalation;

  // Dictionary untuk terjemahan
  late Map<String, String> _texts;

  @override
  void initState() {
    super.initState();
    _setupTranslations();
    _imageXFile = widget.initialImageXFile;
    if (widget.preSelectedLocationId != null) {
      setState(() {
        _selectedLocation = {
          'id_lokasi': widget.preSelectedLocationId,
          'id_unit': widget.preSelectedUnitId,
          'id_subunit': widget.preSelectedSubunitId,
          'id_area': widget.preSelectedAreaId,
          'nama': widget.preSelectedLocationName,
        };
      });
    }
    _initCamera();
  }

  // Mengambil nama lokasi default saat layar pertama kali dibuka
  // Future<void> _fetchDefaultLocation() async {
  //   if (widget.defaultLocationId == null) return;
  //   try {
  //     final data = await Supabase.instance.client
  //         .from('lokasi')
  //         .select('id_lokasi, nama_lokasi, id_unit')
  //         .eq('id_lokasi', widget.defaultLocationId!)
  //         .maybeSingle();
  //     if (data != null) {
  //       setState(() {
  //         _selectedLocation = {
  //           'id_lokasi': data['id_lokasi'],
  //           'nama': data['nama_lokasi'],
  //           'id_unit': data['id_unit'],
  //         };
  //       });
  //     }
  //   } catch (e) {
  //     debugPrint("Error fetching default location: $e");
  //   }
  // }

  @override
  void dispose() {
    _cameraController?.dispose();
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  //================================================
  // Logika Kamera (diadaptasi dari camera_finding_screen.dart)
  //================================================
  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      await _setCamera(_selectedCameraIndex);
    }
  }

  Future<void> _setCamera(int index) async {
    // Hentikan controller lama jika ada
    await _cameraController?.dispose();
    
    _cameraController = CameraController(
      _cameras![index],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }
  }

  void _switchCamera() {
    if (_cameras == null || _cameras!.length < 2) return;
    _selectedCameraIndex = _selectedCameraIndex == 0 ? 1 : 0;
    setState(() => _isCameraInitialized = false);
    _setCamera(_selectedCameraIndex);
  }

  Future<void> _processImage(XFile imageFile) async {
    // final file = File(imageFile.path);
    // final lastModified = await file.lastModified();
    // final difference = DateTime.now().difference(lastModified);

    // if (difference.inHours > 24) {
    //   if (!mounted) return;
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text(_texts['err_24h']!), backgroundColor: Colors.red),
    //   );
    //   return;
    // }
    setState(() {
      _imageXFile = imageFile; 
    });
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _cameraController!.value.isTakingPicture) return;
    try {
      final picture = await _cameraController!.takePicture();
      await _processImage(picture);
    } catch (e) {
      debugPrint("Error taking picture: $e");
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      await _processImage(image);
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  //================================================
  // Logika Penyimpanan
  //================================================
  Future<void> _saveFinding({bool createNewAfter = false}) async {
    // Validasi
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_texts['err_title']!)));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_texts['err_category']!)));
      return;
    }
    if (_imageXFile == null) return;

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw 'User not logged in';

      // --- LOGIKA BARU DIMULAI DI SINI ---
      
      // Cek apakah user adalah Eksekutif (id_jabatan = 1)
      final userProfile = await supabase
          .from('User')
          .select('id_jabatan')
          .eq('id_user', user.id)
          .single();
      final bool isExecutive = (userProfile['id_jabatan'] == 1);
      
      // --- AKHIR LOGIKA BARU ---

      // 1. Upload gambar
      final imageBytes = await _imageXFile!.readAsBytes();
      final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage.from('temuan_images').uploadBinary(
          fileName,
          imageBytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'), 
        );

      final imageUrl = supabase.storage.from('temuan_images').getPublicUrl(fileName);

      // 2. Siapkan data untuk insert
      final Map<String, dynamic> dataToInsert = {
        'id_user': user.id,
        'judul_temuan': _titleCtrl.text.trim(),
        'deskripsi_temuan': _notesCtrl.text.trim(),
        'gambar_temuan': imageUrl,
        'status_temuan': 'Belum',
        'id_lokasi': _selectedLocation?['id_lokasi'],
        'id_unit': _selectedLocation?['id_unit'],
        'id_subunit': _selectedLocation?['id_subunit'],
        'id_area': _selectedLocation?['id_area'],
        'id_kategoritemuan': _selectedCategory?['id_kategoritemuan'],
        'id_subkategoritemuan': _selectedCategory?['id_subkategoritemuan'],
        'poin_temuan': _selectedCategory?['poin'] ?? 10,
        
        // --- PENAMBAHAN KOLOM BOOLEAN ---
        'is_pro': widget.isProMode,
        'is_visitor': widget.isVisitorMode,
        'is_eksekutif': isExecutive,
        // --- AKHIR PENAMBAHAN ---
      };

      // Tambahkan data Pro Mode jika ada
      if(widget.isProMode) {
        dataToInsert['id_penanggung_jawab'] = _selectedAssignee?['id_user'];
        dataToInsert['target_waktu_selesai'] = _selectedDueDate?.toIso8601String();
        dataToInsert['eskalasi'] = _selectedEscalation;
      }

      // 3. Insert ke tabel temuan
      await supabase.from('temuan').insert(dataToInsert);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_texts['save_success']!), backgroundColor: Colors.green),
      );

      if (createNewAfter) {
        // Reset form untuk temuan baru
        setState(() {
          _imageXFile = null;
          _titleCtrl.clear();
          _notesCtrl.clear();
          _selectedCategory = null;
          _selectedAssignee = null;
          _selectedDueDate = null;
          _selectedEscalation = null;
          _isSaving = false;
        });
      } else {
        // Kembali ke layar sebelumnya (home) dengan status sukses
        if(mounted) Navigator.pop(context, true);
      }

    } catch (e) {
      debugPrint("Error saving finding: $e");
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_texts['save_fail']!}: $e'), backgroundColor: Colors.red)
        );
        setState(() => _isSaving = false);
      }
    }
  }

  //================================================
  // Picker & Dialog Methods
  //================================================
  void _showLocationPicker() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FilterLocationBottomSheet(lang: widget.lang),
    );

    if (result != null) {
      final locationDetails = await _getLocationDetails(result['id'], result['level'], result['name']); // <--- Tambahkan result['name'] di sini
      setState(() {
        _selectedLocation = locationDetails;
      });
    }
  }

  Future<Map<String, dynamic>> _getLocationDetails(int id, int level, String originalName) async {
      Map<String, dynamic> details = {'id': id, 'nama': 'Loading...'};
      try {
          if (level == 0) { // Lokasi
              final res = await Supabase.instance.client.from('lokasi').select('id_lokasi, nama_lokasi, id_unit').eq('id_lokasi', id).single();
              details = {'id_lokasi': res['id_lokasi'], 'nama': res['nama_lokasi'], 'id_unit': res['id_unit']};
          } else if (level == 1) { // Unit
              final res = await Supabase.instance.client.from('unit').select('id_unit, nama_unit, id_lokasi').eq('id_unit', id).single();
              final lok = await Supabase.instance.client.from('lokasi').select('nama_lokasi').eq('id_lokasi', res['id_lokasi']).single();
              details = {'id_unit': res['id_unit'], 'id_lokasi': res['id_lokasi'], 'nama': '${lok['nama_lokasi']} / ${res['nama_unit']}'};
          } else if (level == 2) { // Subunit
              final res = await Supabase.instance.client.from('subunit').select('id_subunit, nama_subunit, id_unit').eq('id_subunit', id).single();
              final unit = await Supabase.instance.client.from('unit').select('nama_unit, id_lokasi').eq('id_unit', res['id_unit']).single();
              final lok = await Supabase.instance.client.from('lokasi').select('nama_lokasi').eq('id_lokasi', unit['id_lokasi']).single();
              details = {'id_subunit': res['id_subunit'], 'id_unit': res['id_unit'], 'id_lokasi': unit['id_lokasi'], 'nama': '${lok['nama_lokasi']} / ${unit['nama_unit']} / ${res['nama_subunit']}'};
          } else if (level == 3) { // Area
              final res = await Supabase.instance.client.from('area').select('id_area, nama_area, id_subunit').eq('id_area', id).single();
              final sub = await Supabase.instance.client.from('subunit').select('nama_subunit, id_unit').eq('id_subunit', res['id_subunit']).single();
              final unit = await Supabase.instance.client.from('unit').select('nama_unit, id_lokasi').eq('id_unit', sub['id_unit']).single();
              final lok = await Supabase.instance.client.from('lokasi').select('nama_lokasi').eq('id_lokasi', unit['id_lokasi']).single();
              details = {'id_area': res['id_area'], 'id_subunit': res['id_subunit'], 'id_unit': sub['id_unit'], 'id_lokasi': unit['id_lokasi'], 'nama': '${lok['nama_lokasi']} / ... / ${res['nama_area']}'};
          }
      } catch (e) {
          debugPrint("Error getting location details: $e");
          details['nama'] = originalName; // Fallback to original name
      }
      return details;
  }

  void _showCategoryPicker() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => CategoryPickerBottomSheet(lang: widget.lang),
    );
    if (result != null) {
      setState(() => _selectedCategory = result);
    }
  }

  void _showAssigneePicker() async {
     final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => AssigneePickerBottomSheet(
        lang: widget.lang,
        locationId: _selectedLocation?['id_lokasi'],
        unitId: _selectedLocation?['id_unit'],
      ),
    );
    if (result != null) {
      setState(() => _selectedAssignee = result);
    }
  }

  void _showDueDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: _texts['due_date_title'],
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00C9E4), // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() => _selectedDueDate = pickedDate);
    }
  }

  void _showEscalationPicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => EscalationPickerBottomSheet(lang: widget.lang),
    );
    if (result != null) {
      setState(() => _selectedEscalation = result);
    }
  }

  //================================================
  // Build Methods
  //================================================
  @override
  Widget build(BuildContext context) {
    // Tampilkan UI Form jika gambar sudah ada, jika tidak, tampilkan UI Kamera
    return _imageXFile != null ? _buildFormUI() : _buildCameraUI();
  }

  Widget _buildCameraUI() {
    if (!_isCameraInitialized) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),
          // Tombol back
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Kontrol bawah
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: _pickFromGallery,
                  child: Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                    child: const Icon(Icons.photo_library, color: Colors.white),
                  ),
                ),
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    width: 75, height: 75,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: Colors.white,
                    ),
                  ),
                ),
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

  Widget _buildFormUI() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          // Kembali ke tampilan kamera, bukan pop
          onPressed: () => setState(() => _imageXFile = null),
        ),
        title: Text(_texts['title']!, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lokasi
            _buildSectionTitle(_texts['location']!),
            _buildPickerCard(
              icon: Icons.location_on_outlined,
              text: _selectedLocation?['nama'] ?? _texts['select_location']!,
              onTap: _showLocationPicker,
            ),
            const SizedBox(height: 16),

            // Gambar
            if (_imageXFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: kIsWeb
                  ? Image.network( // Untuk Web
                      _imageXFile!.path,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.file( // Untuk Mobile (Android/iOS)
                      File(_imageXFile!.path),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 16),
            
            // Judul
            _buildSectionTitle(_texts['form_title']!, isRequired: true),
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: _texts['form_title_hint']!,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Catatan
            _buildSectionTitle(_texts['notes']!),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: _texts['notes_hint']!,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Kategori
            _buildSectionTitle(_texts['category']!, isRequired: true),
            _buildPickerCard(
              icon: Icons.category_outlined,
              text: _selectedCategory?['nama'] ?? _texts['select_category']!,
              onTap: _showCategoryPicker,
            ),
            const SizedBox(height: 24),
            
            // --- PRO MODE FIELDS ---
            if (widget.isProMode) ...[
              const Divider(),
              const SizedBox(height: 16),
              // Penanggung Jawab
              _buildSectionTitle(_texts['assignee']!, isOptional: true),
              _buildPickerCard(
                icon: Icons.person_outline,
                text: _selectedAssignee?['nama'] ?? _texts['select_assignee']!,
                onTap: _showAssigneePicker,
              ),
              const SizedBox(height: 16),

              // Batas Waktu
              _buildSectionTitle(_texts['due_date']!, isOptional: true),
              _buildPickerCard(
                icon: Icons.calendar_today_outlined,
                text: _selectedDueDate != null
                  ? DateFormat('EEE, d MMM yyyy').format(_selectedDueDate!)
                  : _texts['select_date']!,
                onTap: _showDueDatePicker,
              ),
              const SizedBox(height: 16),

              // Eskalasi
              _buildSectionTitle(_texts['escalation']!, isOptional: true),
               _buildPickerCard(
                icon: Icons.escalator_warning_outlined,
                text: _selectedEscalation ?? _texts['select_level']!,
                onTap: _showEscalationPicker,
              ),
              const SizedBox(height: 24),
            ],

            // --- ACTION BUTTONS ---
            if (_isSaving)
              const Center(child: CircularProgressIndicator())
            else
              _buildActionButtons(),
            
            const SizedBox(height: 40),

          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (widget.isProMode) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _saveFinding(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C9E4),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_texts['btn_save']!, style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _saveFinding(createNewAfter: true),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF00C9E4)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_texts['btn_save_new']!, style: const TextStyle(color: Color(0xFF00C9E4), fontSize: 16)),
            ),
          ),
        ],
      );
    } else {
       return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _saveFinding(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C9E4),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_texts['btn_save']!, style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
          );
    }
  }

  Widget _buildSectionTitle(String title, {bool isRequired = false, bool isOptional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          if (isRequired)
            const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
          if (isOptional)
             Text(' (${_texts['optional']})', style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildPickerCard({required IconData icon, required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1E3A8A)),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  //================================================
  // Terjemahan
  //================================================
  void _setupTranslations() {
    const Map<String, Map<String, String>> translationData = {
      'EN': {
        'title': 'Add Finding',
        'location': 'Location',
        'select_location': 'Select Location',
        'form_title': 'Title',
        'form_title_hint': 'Object and problem of the finding...',
        'notes': 'Notes',
        'notes_hint': 'Additional explanation...',
        'category': 'Category',
        'select_category': 'Select Finding Category',
        'btn_save': 'Save Finding',
        'optional': 'Optional',
        'assignee': 'Person in Charge',
        'select_assignee': 'Select PIC',
        'due_date': 'Completion Deadline',
        'select_date': 'Select Date',
        'escalation': 'Escalation',
        'select_level': 'Select Level',
        'btn_save_new': 'Save & Add New Finding',
        'err_24h': 'Image cannot be older than 24 hours!',
        'err_title': 'Title is required!',
        'err_category': 'Category is required!',
        'save_success': 'Finding saved successfully!',
        'save_fail': 'Failed to save finding',
        'due_date_title': 'SELECT DATE',
      },
      'ID': {
        'title': 'Masukkan Temuan',
        'location': 'Lokasi',
        'select_location': 'Pilih Lokasi',
        'form_title': 'Judul',
        'form_title_hint': 'Tulis objek dan masalah temuan...',
        'notes': 'Catatan',
        'notes_hint': 'Tulis penjelasan tambahan...',
        'category': 'Kategori',
        'select_category': 'Pilih Kategori Temuan',
        'btn_save': 'Simpan Temuan',
        'optional': 'Opsional',
        'assignee': 'Penanggung Jawab',
        'select_assignee': 'Pilih Penanggung Jawab',
        'due_date': 'Batas Waktu Penyelesaian',
        'select_date': 'Pilih Tanggal',
        'escalation': 'Eskalasi',
        'select_level': 'Pilih Level',
        'btn_save_new': 'Simpan & Buat Temuan Baru',
        'err_24h': 'Gambar tidak boleh lebih dari 24 jam yang lalu!',
        'err_title': 'Judul wajib diisi!',
        'err_category': 'Kategori wajib diisi!',
        'save_success': 'Temuan berhasil disimpan!',
        'save_fail': 'Gagal menyimpan temuan',
        'due_date_title': 'PILIH TANGGAL',
      },
      'ZH': {
        'title': '输入发现',
        'location': '地点',
        'select_location': '选择地点',
        'form_title': '标题',
        'form_title_hint': '编写发现的对象和问题...',
        'notes': '笔记',
        'notes_hint': '编写附加说明...',
        'category': '类别',
        'select_category': '选择发现类别',
        'btn_save': '保存发现',
        'optional': '可选的',
        'assignee': '负责人',
        'select_assignee': '选择负责人',
        'due_date': '完成截止日期',
        'select_date': '选择日期',
        'escalation': '升级',
        'select_level': '选择级别',
        'btn_save_new': '保存并添加新发现',
        'err_24h': '图片不能超过24小时！',
        'err_title': '标题为必填项！',
        'err_category': '类别为必填项！',
        'save_success': '发现已成功保存！',
        'save_fail': '保存发现失败',
        'due_date_title': '选择日期',
      },
    };
    _texts = translationData[widget.lang] ?? translationData['EN']!;
  }
}

//==================================================================
// BOTTOM SHEET UNTUK MEMILIH KATEGORI
//==================================================================
class CategoryPickerBottomSheet extends StatefulWidget {
  final String lang;
  const CategoryPickerBottomSheet({super.key, required this.lang});

  @override
  State<CategoryPickerBottomSheet> createState() => _CategoryPickerBottomSheetState();
}

class _CategoryPickerBottomSheetState extends State<CategoryPickerBottomSheet> {
  // State untuk data, loading, dan search
  List<Map<String, dynamic>> _allCategories = [];
  List<Map<String, dynamic>> _filteredCategories = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Mengambil data dari Supabase
  Future<void> _fetchCategories() async {
    try {
      final response = await Supabase.instance.client
          .from('kategoritemuan')
          // Ambil data kategori beserta subkategorinya
          .select('*, subkategoritemuan(*)');

      final data = List<Map<String, dynamic>>.from(response);
      setState(() {
        _allCategories = data;
        _filteredCategories = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fungsi untuk filtering berdasarkan input search
  void _filterCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCategories = _allCategories.where((category) {
        final categoryName = category['nama_kategoritemuan'].toString().toLowerCase();
        final subcategories = List<Map<String, dynamic>>.from(category['subkategoritemuan']);
        
        // Tampilkan jika nama kategori utama cocok, ATAU jika salah satu subkategorinya cocok
        return categoryName.contains(query) || 
               subcategories.any((sub) => sub['nama_subkategoritemuan'].toString().toLowerCase().contains(query));
      }).toList();
    });
  }

  // BARU: Helper untuk mencocokkan NAMA KATEGORI dengan IKON
  // Logika ikon sekarang ada di sini, bukan di database.
  IconData _getIconForCategory(String categoryName) {
    switch (categoryName) {
      case 'Ringkas': return Icons.delete_sweep_outlined;
      case 'Rapi': return Icons.fact_check_outlined;
      case 'Resik': return Icons.cleaning_services_outlined;
      case 'Rawat': return Icons.construction_outlined;
      case 'Tindakan Tidak Aman': return Icons.warning_amber_rounded;
      case 'Kondisi Tidak Aman': return Icons.dangerous_outlined;
      case 'Lainnya': return Icons.more_horiz_outlined;
      default: return Icons.category_outlined; // Ikon default jika tidak ada yang cocok
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI baru yang estetik dan fungsional
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.lang == 'ID' ? 'Pilih Kategori' : 'Select Category',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.lang == 'ID' ? 'Cari kategori...' : 'Search category...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
            ),
          ),

          // Konten List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCategories.isEmpty
                    ? Center(child: Text(widget.lang == 'ID' ? 'Kategori tidak ditemukan' : 'Category not found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filteredCategories.length,
                        itemBuilder: (context, index) {
                          final category = _filteredCategories[index];
                          final subcategories = List<Map<String, dynamic>>.from(category['subkategoritemuan']);
                          
                          // Custom Card untuk setiap kategori
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            shadowColor: Colors.blueGrey.withOpacity(0.2),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Kategori Utama
                                  Row(
                                    children: [
                                      // Panggil helper untuk mendapatkan ikon berdasarkan nama
                                      Icon(_getIconForCategory(category['nama_kategoritemuan']), color: const Color(0xFF1E3A8A)),
                                      const SizedBox(width: 12),
                                      Text(
                                        category['nama_kategoritemuan'],
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A)),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20, thickness: 1),
                                  
                                  // List Subkategori
                                  ...subcategories.map((sub) {
                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                                      dense: true,
                                      title: Text(sub['nama_subkategoritemuan']),
                                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                      onTap: () {
                                        Navigator.pop(context, {
                                          'id_kategoritemuan': sub['id_kategoritemuan'],
                                          'id_subkategoritemuan': sub['id_subkategoritemuan'],
                                          'nama': sub['nama_subkategoritemuan'],
                                          'poin': sub['poin_subkategoritemuan'],
                                        });
                                      },
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

//==================================================================
// BOTTOM SHEET UNTUK MEMILIH PENANGGUNG JAWAB (PRO MODE)
//==================================================================
class AssigneePickerBottomSheet extends StatefulWidget {
  final String lang;
  final int? locationId;
  final int? unitId;
  const AssigneePickerBottomSheet({super.key, required this.lang, this.locationId, this.unitId});

  @override
  State<AssigneePickerBottomSheet> createState() => _AssigneePickerBottomSheetState();
}

class _AssigneePickerBottomSheetState extends State<AssigneePickerBottomSheet> {
  Future<List<Map<String, dynamic>>>? _usersFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
  }

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    var query = Supabase.instance.client.from('User').select('id_user, nama');
    
    // Filter berdasarkan lokasi & unit jika ada
    if(widget.locationId != null) {
      query = query.eq('id_lokasi', widget.locationId!);
    }
    if(widget.unitId != null) {
      query = query.eq('id_unit', widget.unitId!);
    }
    
    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.lang == 'ID' ? 'Pilih Penanggung Jawab' : 'Select PIC',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: widget.lang == 'ID' ? 'Cari anggota...' : 'Search member...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const Divider(height: 24),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text(widget.lang == 'ID' ? 'Tidak ada pengguna ditemukan' : 'No users found'));
                }
                
                final filteredUsers = snapshot.data!
                    .where((user) => user['nama'].toLowerCase().contains(_searchQuery))
                    .toList();

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(user['nama'].substring(0, 1))),
                      title: Text(user['nama']),
                      onTap: () => Navigator.pop(context, user),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

//==================================================================
// BOTTOM SHEET UNTUK MEMILIH LEVEL ESKALASI (PRO MODE)
//==================================================================
class EscalationPickerBottomSheet extends StatelessWidget {
  final String lang;
  const EscalationPickerBottomSheet({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Map<String,String>>> levels = {
      'ID': [
        {'title': 'Level Umum', 'desc': 'Eskalasi temuan umum'},
        {'title': 'Level Harian', 'desc': 'Eskalasi ke level anggota dan ketua'},
        {'title': 'Level Mingguan', 'desc': 'Eskalasi ke level ketua lokasi atau divisi'},
        {'title': 'Level Bulanan', 'desc': 'Eskalasi ke level ketua dan manajemen'},
      ],
      'EN': [
        {'title': 'General Level', 'desc': 'General finding escalation'},
        {'title': 'Daily Level', 'desc': 'Escalate to member and leader level'},
        {'title': 'Weekly Level', 'desc': 'Escalate to location or division head level'},
        {'title': 'Monthly Level', 'desc': 'Escalate to leader and management level'},
      ],
       'ZH': [
        {'title': '一般级别', 'desc': '一般发现升级'},
        {'title': '每日级别', 'desc': '升级至成员和领导级别'},
        {'title': '每周级别', 'desc': '升级至地点或部门负责人级别'},
        {'title': '每月级别', 'desc': '升级至领导和管理层级别'},
      ],
    };

    final currentLevels = levels[lang] ?? levels['EN']!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            lang == 'ID' ? 'Level Eskalasi' : 'Escalation Level',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...currentLevels.map((level) => ListTile(
            title: Text(level['title']!, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(level['desc']!),
            onTap: () => Navigator.pop(context, level['title']),
          )).toList(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(lang == 'ID' ? 'Reset' : 'Reset'),
            ),
          ),
        ],
      ),
    );
  }
}