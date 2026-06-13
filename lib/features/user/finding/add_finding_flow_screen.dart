import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../core/utils/image_picker_helper.dart';
import 'camera_finding_screen.dart';

class AddFindingFlowScreen extends StatefulWidget {
  final String lang;
  final bool isProMode;
  final bool isVisitorMode;
  final XFile initialImageXFile;

  final String? preSelectedLocationName;
  final String? preSelectedLocationId;
  final String? preSelectedUnitId;
  final String? preSelectedSubunitId;
  final String? preSelectedAreaId;
  final VoidCallback? onFindingSaved; 

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
    this.onFindingSaved,
  });

  @override
  State<AddFindingFlowScreen> createState() => _AddFindingFlowScreenState();
}

class _AddFindingFlowScreenState extends State<AddFindingFlowScreen> {
  XFile? _imageXFile;
  bool _isSaving = false;
  bool _isVisitorUser = false; // Track if logged-in user is visitor

  // Camera state
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  final ImagePicker _picker = ImagePicker();

  // Form controllers
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _visitorNameCtrl = TextEditingController();
  final _visitorCompanyCtrl = TextEditingController();

  // Form data
  Map<String, dynamic>? _selectedLocation;
  Map<String, dynamic>? _selectedCategory;
  Map<String, dynamic>? _selectedAssignee;
  DateTime? _selectedDueDate;
  String? _selectedEscalation;

  Map<String, dynamic>? _currentUserProfile;
  bool _isLoadingUserProfile = true;

  late Map<String, String> _texts;

  @override
  void initState() {
    super.initState();
    _setupTranslations();
    _imageXFile = widget.initialImageXFile;
    // ── Pre-fill lokasi dari CameraFindingScreen ──
    if (widget.preSelectedLocationName != null &&
        widget.preSelectedLocationName!.trim().isNotEmpty) {
      _selectedLocation = {
        if (widget.preSelectedLocationId != null)
          'id_lokasi': widget.preSelectedLocationId,
        if (widget.preSelectedUnitId != null)
          'id_unit': widget.preSelectedUnitId,
        if (widget.preSelectedSubunitId != null)
          'id_subunit': widget.preSelectedSubunitId,
        if (widget.preSelectedAreaId != null)
          'id_area': widget.preSelectedAreaId,
        'nama': widget.preSelectedLocationName!.trim(),
      };
    }
    _initCamera();
    _loadCurrentUserProfile();
    _refreshLocationBreadcrumb();
  }

  /// Load current user profile (for default PIC and location filtering)
  Future<void> _loadCurrentUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final profile = await Supabase.instance.client
        .from('User')
        .select('id_user, nama, is_visitor, id_jabatan, id_lokasi, id_unit, id_subunit, id_area, jabatan!User_id_jabatan_fkey(nama_jabatan)')
        .eq('id_user', user.id)
        .single();
      if (mounted) {
        setState(() {
          _currentUserProfile = profile;
          _isVisitorUser = profile['is_visitor'] == true;
          _isLoadingUserProfile = false;
          // Set default PIC to current logged-in user
          if (_selectedAssignee == null) {
            _selectedAssignee = {
              'id_user': profile['id_user'],
              'nama': profile['nama'],
              'jabatan': profile['jabatan'],
            };
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading user profile: $e");
      if (mounted) setState(() => _isLoadingUserProfile = false);
    }
  }

  /// Bangun nama lokasi lengkap (Lokasi / Unit / Subunit / Area)
  /// berdasarkan ID yang sudah dipilih sebelumnya di CameraFindingScreen.
  Future<void> _refreshLocationBreadcrumb() async {
    final idLokasi  = _selectedLocation?['id_lokasi']?.toString();
    final idUnit    = _selectedLocation?['id_unit']?.toString();
    final idSubunit = _selectedLocation?['id_subunit']?.toString();
    final idArea    = _selectedLocation?['id_area']?.toString();

    if (idLokasi == null && idUnit == null && idSubunit == null && idArea == null) {
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      final parts = <String>[];

      if (idLokasi != null) {
        final d = await supabase.from('lokasi')
            .select('nama_lokasi').eq('id_lokasi', idLokasi).maybeSingle();
        if (d?['nama_lokasi'] != null) parts.add(d!['nama_lokasi'].toString());
      }
      if (idUnit != null) {
        final d = await supabase.from('unit')
            .select('nama_unit').eq('id_unit', idUnit).maybeSingle();
        if (d?['nama_unit'] != null) parts.add(d!['nama_unit'].toString());
      }
      if (idSubunit != null) {
        final d = await supabase.from('subunit')
            .select('nama_subunit').eq('id_subunit', idSubunit).maybeSingle();
        if (d?['nama_subunit'] != null) parts.add(d!['nama_subunit'].toString());
      }
      if (idArea != null) {
        final d = await supabase.from('area')
            .select('nama_area').eq('id_area', idArea).maybeSingle();
        if (d?['nama_area'] != null) parts.add(d!['nama_area'].toString());
      }

      if (mounted && parts.isNotEmpty) {
        setState(() {
          _selectedLocation = {
            ...(_selectedLocation ?? {}),
            'nama': parts.join(' / '),
          };
        });
      }
    } catch (e) {
      debugPrint('Error building location breadcrumb: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _visitorNameCtrl.dispose();
    _visitorCompanyCtrl.dispose();
    super.dispose();
  }

  // ================================================
  // Camera Logic
  // ================================================
  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        await _setCamera(_selectedCameraIndex);
      }
    } catch (e) {
      debugPrint("Error init camera: $e");
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
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint("Error setting camera: $e");
    }
  }

  void _switchCamera() {
    if (_cameras == null || _cameras!.length < 2) return;
    _selectedCameraIndex = _selectedCameraIndex == 0 ? 1 : 0;
    setState(() => _isCameraInitialized = false);
    _setCamera(_selectedCameraIndex);
  }

  Future<void> _processImage(XFile imageFile) async {
    setState(() => _imageXFile = imageFile);
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
      final image = await ImagePickerHelper.pickImageFromGallery();
      if (image == null) return;
      await _processImage(image);
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // ================================================
  // Save Logic - FIXED column name issue
  // ================================================
  Future<void> _saveFinding({bool createNewAfter = false}) async {
    if (_titleCtrl.text.trim().isEmpty) {
      _showSnackBar(_texts['err_title']!, isError: true);
      return;
    }
    if (_selectedCategory == null) {
      _showSnackBar(_texts['err_category']!, isError: true);
      return;
    }
    if (_imageXFile == null) return;

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final bool isExecutive =
          (_currentUserProfile?['id_jabatan'] == 1);

      // 1. Upload image
      final imageBytes = await _imageXFile!.readAsBytes();
      final fileName =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('temuan_images').uploadBinary(
        fileName,
        imageBytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );
      final imageUrl =
          supabase.storage.from('temuan_images').getPublicUrl(fileName);

      // 2. Prepare data - only include columns that exist in schema
      final Map<String, dynamic> dataToInsert = {
        'id_user': user.id,
        'judul_temuan': _titleCtrl.text.trim(),
        'deskripsi_temuan': _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
        'gambar_temuan': imageUrl,
        'status_temuan': 'Belum',
        'id_lokasi': _selectedLocation?['id_lokasi'],
        'id_unit': _selectedLocation?['id_unit'],
        'id_subunit': _selectedLocation?['id_subunit'],
        'id_area': _selectedLocation?['id_area'],
        'id_kategoritemuan_uuid': _selectedCategory?['id_kategoritemuan_uuid'],
        'id_subkategoritemuan_uuid': _selectedCategory?['id_subkategoritemuan_uuid'],
        'poin_temuan': _selectedCategory?['poin'] ?? 10,
        'is_pro': widget.isProMode,
        'is_visitor': widget.isVisitorMode,
        'is_eksekutif': isExecutive,
        'jenis_temuan': '5R',
      };

      // PIC
      if (_selectedAssignee != null) {
        dataToInsert['id_penanggung_jawab'] = _selectedAssignee!['id_user'];
      }

      // Due date
      if (_selectedDueDate != null) {
        dataToInsert['target_waktu_selesai'] =
            _selectedDueDate!.toIso8601String();
      }

      // Escalation (Pro only)
      if (widget.isProMode && _selectedEscalation != null) {
        dataToInsert['eskalasi'] = _selectedEscalation;
      }

      // Visitor fields
      if (_isVisitorUser) {
        if (_visitorNameCtrl.text.trim().isNotEmpty) {
          dataToInsert['nama_visitor'] = _visitorNameCtrl.text.trim();
        }
        if (_visitorCompanyCtrl.text.trim().isNotEmpty) {
          dataToInsert['perusahaan_visitor'] =
              _visitorCompanyCtrl.text.trim();
        }
      }

      // 3. Insert to temuan
      await supabase.from('temuan').insert(dataToInsert);

      // 4. Kirim FCM ke penanggung jawab jika bukan diri sendiri
      if (_selectedAssignee != null) {
        final assigneeId = _selectedAssignee!['id_user']?.toString();
        final currentUserId = user.id;
        if (assigneeId != null && assigneeId != currentUserId) {
          try {
            final assigneeData = await supabase
                .from('User')
                .select('fcm_token, nama')
                .eq('id_user', assigneeId)
                .maybeSingle();
            final fcmToken = assigneeData?['fcm_token']?.toString();
            if (fcmToken != null && fcmToken.trim().isNotEmpty) {
              final notifTitle = widget.lang == 'EN'
                  ? '📋 New Finding Assigned to You'
                  : widget.lang == 'ZH'
                      ? '📋 新发现已分配给您'
                      : '📋 Temuan Baru Ditugaskan ke Anda';
              final notifBody = _titleCtrl.text.trim();
              await supabase.functions.invoke(
                'send-fcm-v1',
                body: {
                  'token': fcmToken.trim(),
                  'title': notifTitle,
                  'body': notifBody,
                  'data': {
                    'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                    'route': 'findings',
                  },
                },
              );
              debugPrint('✅ FCM sent to assignee: ${assigneeData?['nama']}');
            }
          } catch (e) {
            debugPrint('❌ FCM assignee error: $e');
          }
        }
      }
      
      if (mounted) setState(() => _isSaving = false);

      await _showSaveSuccessDialog();

      if (!mounted) return;

      if (createNewAfter) {
        Navigator.pop(context, 'new');
      } else {
        // Panggil callback refresh HomeScreen SEBELUM pop
        widget.onFindingSaved?.call();
        // Pop kembali ke CameraFindingScreen
        Navigator.pop(context, true);
      }

    } catch (e) {
      debugPrint("Error saving finding: $e");
      String errorMsg = _texts['save_fail']!;
      final errStr = e.toString();
      if (errStr.contains('log_poin') || errStr.contains('42501')) {
        errorMsg =
            '${_texts['save_fail']!}: RLS policy error on log_poin. Run SQL fix.';
      } else if (errStr.contains('storage')) {
        errorMsg = '${_texts['save_fail']!}: Image upload failed.';
      } else {
        errorMsg = '${_texts['save_fail']!}: $e';
      }
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar(errorMsg, isError: true);
      }
    }
  }

  Future<void> _showSaveSuccessDialog() async {
    if (!mounted) return;
    final completer = Completer<void>();

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (dialogContext) {
        Future.delayed(const Duration(milliseconds: 3000), () {
          if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
            if (!completer.isCompleted) completer.complete();
          }
        });

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 36),
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF16A34A).withOpacity(0.1),
                      border: Border.all(
                        color: const Color(0xFF16A34A).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF16A34A),
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.lang == 'EN'
                        ? 'Finding Saved!'
                        : widget.lang == 'ZH'
                            ? '发现已保存！'
                            : 'Temuan Tersimpan!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF16A34A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.lang == 'EN'
                        ? 'Your finding has been successfully saved.'
                        : widget.lang == 'ZH'
                            ? '您的发现已成功保存。'
                            : 'Temuan Anda berhasil disimpan.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 0.0),
                      duration: const Duration(milliseconds: 3000),
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 4,
                        backgroundColor:
                            const Color(0xFF16A34A).withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF16A34A)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      if (!completer.isCompleted) completer.complete();
    });

    await completer.future;
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ================================================
  // Picker Methods
  // ================================================
  void _showLocationPicker() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FullLocationPickerBottomSheet(
        lang: widget.lang,
        isProMode: widget.isProMode,
        userRole: _currentUserProfile?['jabatan']?['nama_jabatan'] ?? 'Staff',
        userLokasiId: _currentUserProfile?['id_lokasi']?.toString(),
        userUnitId: _currentUserProfile?['id_unit']?.toString(),
        userSubunitId: _currentUserProfile?['id_subunit']?.toString(),
        userAreaId: _currentUserProfile?['id_area']?.toString(),
        // ── Teruskan pre-selection ──
        preSelectedLokasiId: _selectedLocation?['id_lokasi']?.toString(),
        preSelectedUnitId: _selectedLocation?['id_unit']?.toString(),
        preSelectedSubunitId: _selectedLocation?['id_subunit']?.toString(),
        preSelectedAreaId: _selectedLocation?['id_area']?.toString(),
      ),
    );

    if (result != null) {
      setState(() => _selectedLocation = result);
      if (_selectedAssignee != null &&
          _selectedAssignee!['id_user'] != _currentUserProfile?['id_user']) {
        setState(() => _selectedAssignee = null);
      }
      // result dari FullLocationPickerBottomSheet sudah berisi 'nama' (join dari _selectItem)
      // tapi belum mengandung level di atasnya, jadi refresh breadcrumb penuh:
      await _refreshLocationBreadcrumb();
    }
  }

  void _showCategoryPicker() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => CategoryPickerBottomSheet(lang: widget.lang),
    );
    if (result != null) setState(() => _selectedCategory = result);
  }

  void _showAssigneePicker() async {
    // Prioritas: lokasi temuan yang dipilih → lokasi user login → null (tampilkan semua)
    final String? lokasiId = (_selectedLocation?['id_lokasi'] != null
            ? _selectedLocation!['id_lokasi'].toString()
            : null) ??
        _currentUserProfile?['id_lokasi']?.toString();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => AssigneePickerBottomSheet(
        lang: widget.lang,
        locationId: lokasiId,
        unitId: null,
        currentUserId: _currentUserProfile?['id_user']?.toString(),
      ),
    );
    if (result != null) setState(() => _selectedAssignee = result);
  }

  void _showDueDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: _texts['due_date_title'],
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF00C9E4),
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (pickedDate != null) setState(() => _selectedDueDate = pickedDate);
  }

  void _showEscalationPicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => EscalationPickerBottomSheet(lang: widget.lang),
    );
    if (result != null) setState(() => _selectedEscalation = result);
  }

  // ================================================
  // Build
  // ================================================
  @override
  Widget build(BuildContext context) {
    return _imageXFile != null ? _buildFormUI() : _buildCameraUI();
  }

  Widget _buildCameraUI() {
    if (!_isCameraInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF00C9E4)),
              const SizedBox(height: 16),
              Text(
                widget.lang == 'EN'
                    ? 'Initializing camera...'
                    : widget.lang == 'ZH'
                        ? '正在初始化相机...'
                        : 'Memuat kamera...',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: Colors.white, size: 26),
              onPressed: () {
                if (_imageXFile != null) {
                  // Ada foto sebelumnya → kembali ke form
                  setState(() => _imageXFile = widget.initialImageXFile);
                } else {
                  // Belum ada foto → pop keluar dari screen ini
                  Navigator.pop(context);
                }
              },
            ),
          ),
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
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                        color: Colors.white24, shape: BoxShape.circle),
                    child: const Icon(Icons.photo_library, color: Colors.white),
                  ),
                ),
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    width: 75,
                    height: 75,
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
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                        color: Colors.white24, shape: BoxShape.circle),
                    child:
                        const Icon(Icons.flip_camera_ios, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormUI() {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.0),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.black12,
          surfaceTintColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E3A8A)),
            onPressed: () => Navigator.pop(context, null),
          ),
          title: Text(
            _texts['title']!,
            style: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: Colors.grey.shade200, height: 1),
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Card
                  _buildSectionTitle(_texts['location']!),
                  _buildPickerCard(
                    icon: Icons.location_on_outlined,
                    text: _selectedLocation?['nama'] ?? _texts['select_location']!,
                    onTap: _showLocationPicker,
                    hasValue: _selectedLocation != null,
                  ),
                  const SizedBox(height: 20),

                  // Image Section
                  if (_imageXFile != null) ...[
                    _buildSectionTitle(_texts['photo']!),
                    _buildImageCard(),
                    const SizedBox(height: 20),
                  ],

                  // Visitor Fields - shown right after photo if user is visitor
                  if (_isVisitorUser) ...[
                    _buildVisitorSection(),
                    const SizedBox(height: 20),
                  ],

                  // Title
                  _buildSectionTitle(_texts['form_title']!, isRequired: true),
                  _buildTextField(
                    controller: _titleCtrl,
                    hint: _texts['form_title_hint']!,
                    icon: Icons.title_outlined,
                  ),
                  const SizedBox(height: 20),

                  // Notes
                  _buildSectionTitle(_texts['notes']!),
                  _buildTextField(
                    controller: _notesCtrl,
                    hint: _texts['notes_hint']!,
                    icon: Icons.notes_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  // Category
                  _buildSectionTitle(_texts['category']!, isRequired: true),
                  _buildPickerCard(
                    icon: Icons.category_outlined,
                    text: _selectedCategory?['nama'] ?? _texts['select_category']!,
                    onTap: _showCategoryPicker,
                    hasValue: _selectedCategory != null,
                  ),
                  const SizedBox(height: 20),

                  // Due Date
                  _buildSectionTitle(_texts['due_date']!, isOptional: true),
                  _buildPickerCard(
                    icon: Icons.calendar_today_outlined,
                    text: _selectedDueDate != null
                        ? DateFormat('EEE, d MMM yyyy').format(_selectedDueDate!)
                        : _texts['select_date']!,
                    onTap: _showDueDatePicker,
                    hasValue: _selectedDueDate != null,
                  ),
                  const SizedBox(height: 20),

                  // Assignee - ALWAYS VISIBLE (not just Pro mode)
                  _buildSectionTitle(_texts['assignee']!, isOptional: true),
                  _buildPickerCard(
                    icon: Icons.person_outline,
                    text: _selectedAssignee?['nama'] ?? _texts['select_assignee']!,
                    onTap: _showAssigneePicker,
                    hasValue: _selectedAssignee != null,
                  ),
                  const SizedBox(height: 20),

                  // Pro Mode fields
                  if (widget.isProMode) ...[
                    _buildProModeDivider(),
                    const SizedBox(height: 16),
                    _buildSectionTitle(_texts['escalation']!, isOptional: true),
                    _buildPickerCard(
                      icon: Icons.escalator_warning_outlined,
                      text: _selectedEscalation ?? _texts['select_level']!,
                      onTap: _showEscalationPicker,
                      hasValue: _selectedEscalation != null,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Action Buttons
                  // Action Buttons — selalu tampil, loading pakai overlay
              _buildActionButtons(),
              const SizedBox(height: 40),
            ],
          ),
        ),
            // ── Loading Overlay ──
          if (_isSaving) _buildBeamLoadingOverlay(),
        ],
      ),
    ),
    );
  }

  Widget _buildBeamLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.55),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C9E4).withOpacity(0.3),
                blurRadius: 40,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Animasi cahaya senter biru ──
              SizedBox(
                width: 100, height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ring luar
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.7, end: 1.15),
                      duration: const Duration(milliseconds: 1000),
                      builder: (_, v, __) => Transform.scale(
                        scale: v,
                        child: Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00C9E4).withOpacity(0.06),
                            border: Border.all(
                              color: const Color(0xFF00C9E4).withOpacity(0.15),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Ring tengah
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.85, end: 1.05),
                      duration: const Duration(milliseconds: 700),
                      builder: (_, v, __) => Transform.scale(
                        scale: v,
                        child: Container(
                          width: 65, height: 65,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00C9E4).withOpacity(0.12),
                          ),
                        ),
                      ),
                    ),
                    // Progress circular di tengah
                    const SizedBox(
                      width: 46, height: 46,
                      child: CircularProgressIndicator(
                        color: Color(0xFF00C9E4),
                        strokeWidth: 3.5,
                      ),
                    ),
                    // Ikon di tengah
                    const Icon(Icons.save_outlined, color: Color(0xFF00C9E4), size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _texts['saving']!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E3A8A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _texts['lang'] == 'EN'
                    ? 'Please wait...'
                    : 'Mohon tunggu...',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            kIsWeb
                ? Image.network(
                    _imageXFile!.path,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(_imageXFile!.path),
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
            // Dark gradient overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Retake button — kembali ke kamera internal, tidak push CameraFindingScreen baru
            Positioned(
              bottom: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.pop(context, null),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.camera_alt, color: Colors.white, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        _texts['retake']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitorSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3A8A).withOpacity(0.05),
            const Color(0xFF00C9E4).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF00C9E4).withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C9E4).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.badge_outlined,
                    color: Color(0xFF00C9E4), size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                _texts['visitor_info']!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _visitorNameCtrl,
            hint: _texts['visitor_name_hint']!,
            icon: Icons.person_outline,
            label: _texts['visitor_name']!,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _visitorCompanyCtrl,
            hint: _texts['visitor_company_hint']!,
            icon: Icons.business_outlined,
            label: _texts['visitor_company']!,
          ),
        ],
      ),
    );
  }

  Widget _buildProModeDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium,
                  color: Color(0xFF1E3A8A), size: 14),
              const SizedBox(width: 4),
              Text(
                'PRO',
                style: TextStyle(
                  color: const Color(0xFF1E3A8A),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }

  Widget _buildSavingIndicator() {
    // Tidak digunakan lagi — loading pakai overlay
    return const SizedBox.shrink();
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _saveFinding(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C9E4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 2,
              shadowColor: const Color(0xFF00C9E4).withOpacity(0.4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save_outlined, size: 20),
                const SizedBox(width: 8),
                Text(_texts['btn_save']!,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _saveFinding(createNewAfter: true),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF00C9E4), width: 1.5),
              foregroundColor: const Color(0xFF00C9E4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_outline, size: 20),
                const SizedBox(width: 8),
                Text(_texts['btn_save_new']!,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title,
      {bool isRequired = false, bool isOptional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1E3A8A))),
          if (isRequired)
            const Text(' *',
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          if (isOptional)
            Text(' (${_texts['optional']})',
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? label,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF00C9E4), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildPickerCard({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool hasValue = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue
                ? const Color(0xFF00C9E4).withOpacity(0.5)
                : Colors.grey.shade200,
            width: hasValue ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon,
                color: hasValue
                    ? const Color(0xFF00C9E4)
                    : const Color(0xFF1E3A8A),
                size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  color: hasValue ? Colors.black87 : Colors.grey.shade500,
                  fontWeight:
                      hasValue ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down,
                color: hasValue
                    ? const Color(0xFF00C9E4)
                    : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // ================================================
  // Translations
  // ================================================
  void _setupTranslations() {
    const Map<String, Map<String, String>> translationData = {
      'EN': {
        'title': 'Add Finding',
        'photo': 'Photo',
        'retake': 'Retake',
        'location': 'Location',
        'select_location': 'Select Location',
        'form_title': 'Title',
        'form_title_hint': 'Object and problem of the finding...',
        'notes': 'Notes',
        'notes_hint': 'Additional explanation...',
        'category': 'Category',
        'select_category': 'Select Finding Category',
        'btn_save': 'Save Finding',
        'btn_save_new': 'Save & Add New Finding',
        'optional': 'Optional',
        'assignee': 'Person in Charge',
        'select_assignee': 'Select PIC',
        'due_date': 'Completion Deadline',
        'select_date': 'Select Date',
        'escalation': 'Escalation',
        'select_level': 'Select Level',
        'err_24h': 'Image cannot be older than 24 hours!',
        'err_title': 'Title is required!',
        'err_category': 'Category is required!',
        'save_success': 'Finding saved successfully!',
        'save_fail': 'Failed to save finding',
        'saving': 'Saving your finding...',
        'due_date_title': 'SELECT DATE',
        'visitor_info': 'Visitor Information',
        'visitor_name': 'Visitor Name',
        'visitor_name_hint': 'Enter visitor full name...',
        'visitor_company': 'Company / Institution',
        'visitor_company_hint': 'Enter company or institution name...',
      },
      'ID': {
        'title': 'Masukkan Temuan',
        'photo': 'Foto',
        'retake': 'Ulangi',
        'location': 'Lokasi',
        'select_location': 'Pilih Lokasi',
        'form_title': 'Judul',
        'form_title_hint': 'Tulis objek dan masalah temuan...',
        'notes': 'Catatan',
        'notes_hint': 'Tulis penjelasan tambahan...',
        'category': 'Kategori',
        'select_category': 'Pilih Kategori Temuan',
        'btn_save': 'Simpan Temuan',
        'btn_save_new': 'Simpan & Buat Temuan Baru',
        'optional': 'Opsional',
        'assignee': 'Penanggung Jawab',
        'select_assignee': 'Pilih Penanggung Jawab',
        'due_date': 'Batas Waktu Penyelesaian',
        'select_date': 'Pilih Tanggal',
        'escalation': 'Eskalasi',
        'select_level': 'Pilih Level',
        'err_24h': 'Gambar tidak boleh lebih dari 24 jam yang lalu!',
        'err_title': 'Judul wajib diisi!',
        'err_category': 'Kategori wajib diisi!',
        'save_success': 'Temuan berhasil disimpan!',
        'save_fail': 'Gagal menyimpan temuan',
        'saving': 'Menyimpan temuan Anda...',
        'due_date_title': 'PILIH TANGGAL',
        'visitor_info': 'Informasi Pengunjung',
        'visitor_name': 'Nama Pengunjung',
        'visitor_name_hint': 'Masukkan nama lengkap pengunjung...',
        'visitor_company': 'Perusahaan / Institusi',
        'visitor_company_hint': 'Masukkan nama perusahaan atau institusi...',
      },
      'ZH': {
        'title': '输入发现',
        'photo': '照片',
        'retake': '重拍',
        'location': '地点',
        'select_location': '选择地点',
        'form_title': '标题',
        'form_title_hint': '编写发现的对象和问题...',
        'notes': '笔记',
        'notes_hint': '编写附加说明...',
        'category': '类别',
        'select_category': '选择发现类别',
        'btn_save': '保存发现',
        'btn_save_new': '保存并添加新发现',
        'optional': '可选的',
        'assignee': '负责人',
        'select_assignee': '选择负责人',
        'due_date': '完成截止日期',
        'select_date': '选择日期',
        'escalation': '升级',
        'select_level': '选择级别',
        'err_24h': '图片不能超过24小时！',
        'err_title': '标题为必填项！',
        'err_category': '类别为必填项！',
        'save_success': '发现已成功保存！',
        'save_fail': '保存发现失败',
        'saving': '正在保存您的发现...',
        'due_date_title': '选择日期',
        'visitor_info': '访客信息',
        'visitor_name': '访客姓名',
        'visitor_name_hint': '输入访客全名...',
        'visitor_company': '公司/机构',
        'visitor_company_hint': '输入公司或机构名称...',
      },
    };
    _texts = translationData[widget.lang] ?? translationData['EN']!;
  }
}

// ==================================================================
// BOTTOM SHEET: CATEGORY PICKER (with Shimmer)
// ==================================================================
class CategoryPickerBottomSheet extends StatefulWidget {
  final String lang;
  const CategoryPickerBottomSheet({super.key, required this.lang});

  @override
  State<CategoryPickerBottomSheet> createState() =>
      _CategoryPickerBottomSheetState();
}

class _CategoryPickerBottomSheetState
    extends State<CategoryPickerBottomSheet> {
  List<Map<String, dynamic>> _allCategories = [];
  List<Map<String, dynamic>> _filteredCategories = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // Color palette for categories
  static const List<Color> _categoryColors = [
    Color(0xFF1E3A8A), // Deep Blue
    Color(0xFF0891B2), // Cyan
    Color(0xFF059669), // Green
    Color(0xFFD97706), // Amber
    Color(0xFFDC2626), // Red
    Color(0xFF7C3AED), // Purple
    Color(0xFFDB2777), // Pink
  ];

  static const List<Color> _categoryLightColors = [
    Color(0xFFEFF6FF),
    Color(0xFFECFEFF),
    Color(0xFFECFDF5),
    Color(0xFFFFFBEB),
    Color(0xFFFEF2F2),
    Color(0xFFF5F3FF),
    Color(0xFFFDF2F8),
  ];

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

  Future<void> _fetchCategories() async {
    try {
      // Filter hanya jenis_kategori = '5R'
      final response = await Supabase.instance.client
          .from('kategoritemuan')
          .select('*, subkategoritemuan(*)')
          .eq('jenis_kategori', '5R'); // FILTER JENIS 5R
      final data = List<Map<String, dynamic>>.from(response);
      if (mounted) {
        setState(() {
          _allCategories = data;
          _filteredCategories = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCategories = _allCategories.where((category) {
        final categoryName =
            category['nama_kategoritemuan'].toString().toLowerCase();
        final subcategories =
            List<Map<String, dynamic>>.from(category['subkategoritemuan']);
        return categoryName.contains(query) ||
            subcategories.any((sub) => sub['nama_subkategoritemuan']
                .toString()
                .toLowerCase()
                .contains(query));
      }).toList();
    });
  }

  IconData _getIconForCategory(String categoryName) {
    switch (categoryName) {
      case 'Ringkas':
        return Icons.delete_sweep_outlined;
      case 'Rapi':
        return Icons.fact_check_outlined;
      case 'Resik':
        return Icons.cleaning_services_outlined;
      case 'Rawat':
        return Icons.construction_outlined;
      case 'Tindakan Tidak Aman':
        return Icons.warning_amber_rounded;
      case 'Kondisi Tidak Aman':
        return Icons.dangerous_outlined;
      case 'Lainnya':
        return Icons.more_horiz_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header shimmer
              Container(
                height: 60,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
              const Divider(height: 1),
              // Sub items shimmer
              ...List.generate(
                  2,
                  (_) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 12),
                            Container(height: 12, width: 160, color: Colors.white),
                          ],
                        ),
                      )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.category_outlined,
                      color: Color(0xFF1E3A8A), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.lang == 'ID'
                            ? 'Pilih Kategori'
                            : 'Select Category',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      Text(
                        widget.lang == 'ID'
                            ? 'Pilih kategori & subkategori temuan'
                            : 'Choose finding category & subcategory',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.lang == 'ID'
                    ? 'Cari kategori atau subkategori...'
                    : 'Search category or subcategory...',
                hintStyle:
                    TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon:
                    const Icon(Icons.search, color: Color(0xFF1E3A8A)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(
                      color: Color(0xFF00C9E4), width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
            ),
          ),

          // Count indicator
          if (!_isLoading)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_filteredCategories.length} ${widget.lang == 'ID' ? 'kategori ditemukan' : 'categories found'}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            ),

          // List
          Expanded(
            child: _isLoading
                ? _buildShimmerLoading()
                : _filteredCategories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off,
                                size: 48,
                                color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text(
                              widget.lang == 'ID'
                                  ? 'Kategori tidak ditemukan'
                                  : 'Category not found',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: _filteredCategories.length,
                        itemBuilder: (context, index) {
                          final category = _filteredCategories[index];
                          final subcategories =
                              List<Map<String, dynamic>>.from(
                                  category['subkategoritemuan']);
                          final colorIndex = index % _categoryColors.length;
                          final mainColor = _categoryColors[colorIndex];
                          final lightColor =
                              _categoryLightColors[colorIndex];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: mainColor.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(
                                color: mainColor.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category Header
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: lightColor,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color:
                                              mainColor.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          _getIconForCategory(
                                              category['nama_kategoritemuan']),
                                          color: mainColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          category['nama_kategoritemuan'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: mainColor,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color:
                                              mainColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${subcategories.length}',
                                          style: TextStyle(
                                            color: mainColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Subcategories
                                ...subcategories
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final i = entry.key;
                                  final sub = entry.value;
                                  final isLast =
                                      i == subcategories.length - 1;

                                  return InkWell(
                                    onTap: () {
                                      Navigator.pop(context, {
                                        'id_kategoritemuan_uuid':
                                            sub['id_kategoritemuan_uuid'],
                                        'id_subkategoritemuan_uuid':
                                            sub['id_subkategoritemuan_uuid'],
                                        'nama':
                                            sub['nama_subkategoritemuan'],
                                        'poin':
                                            sub['poin_subkategoritemuan'],
                                      });
                                    },
                                    borderRadius: isLast
                                        ? const BorderRadius.vertical(
                                            bottom: Radius.circular(16))
                                        : BorderRadius.zero,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        border: !isLast
                                            ? Border(
                                                bottom: BorderSide(
                                                    color: Colors
                                                        .grey.shade100,
                                                    width: 1))
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: mainColor
                                                  .withOpacity(0.5),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              sub['nama_subkategoritemuan'],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          // Points badge
                                          if (sub['poin_subkategoritemuan'] !=
                                              null)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.amber
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        20),
                                                border: Border.all(
                                                    color: Colors.amber
                                                        .withOpacity(0.3)),
                                              ),
                                              child: Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.local_fire_department_rounded,
                                                      size: 10,
                                                      color: Colors.amber),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    '${sub['poin_subkategoritemuan']}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.amber,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          const SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_ios,
                                              size: 12,
                                              color:
                                                  Colors.grey.shade400),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
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

// ==================================================================
// BOTTOM SHEET: ASSIGNEE PICKER (with Shimmer, always loads all users at id_lokasi=1)
// ==================================================================
class AssigneePickerBottomSheet extends StatefulWidget {
  final String lang;
  final String? locationId;
  final String? unitId;
  final String? currentUserId;

  const AssigneePickerBottomSheet({
    super.key,
    required this.lang,
    this.locationId,
    this.unitId,
    this.currentUserId,
  });

  @override
  State<AssigneePickerBottomSheet> createState() =>
      _AssigneePickerBottomSheetState();
}

class _AssigneePickerBottomSheetState
    extends State<AssigneePickerBottomSheet> {
  // ── Filter hierarki ──
  List<Map<String, dynamic>> _lokasiList = [];
  List<Map<String, dynamic>> _unitList = [];
  List<Map<String, dynamic>> _subunitList = [];
  List<Map<String, dynamic>> _areaList = [];

  String? _selLokasiId;
  String? _selUnitId;
  String? _selSubunitId;
  String? _selAreaId;

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoadingLocations = true;
  bool _isLoadingUsers = false;

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    _loadLocations();
    _loadUsers(lokasiId: widget.locationId);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    try {
      final data = await Supabase.instance.client
          .from('lokasi').select('id_lokasi, nama_lokasi').order('nama_lokasi');
      if (mounted) {
        setState(() {
          _lokasiList = List<Map<String, dynamic>>.from(data);
          // Pre-select jika ada locationId dari parent
          if (widget.locationId != null) {
            final found = _lokasiList.where(
                (l) => l['id_lokasi'].toString() == widget.locationId).toList();
            if (found.isNotEmpty) {
              _selLokasiId = widget.locationId;
              _fetchUnit(widget.locationId!).then((units) {
                if (mounted) setState(() => _unitList = units);
              });
            }
          }
          _isLoadingLocations = false;
        });
      }
    } catch (e) {
      debugPrint('Error load locations: $e');
      if (mounted) setState(() => _isLoadingLocations = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUnit(String lokasiId) async {
    final res = await Supabase.instance.client
        .from('unit').select('id_unit, nama_unit')
        .eq('id_lokasi', lokasiId).order('nama_unit');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> _fetchSubunit(String unitId) async {
    final res = await Supabase.instance.client
        .from('subunit').select('id_subunit, nama_subunit')
        .eq('id_unit', unitId).order('nama_subunit');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> _fetchArea(String subunitId) async {
    final res = await Supabase.instance.client
        .from('area').select('id_area, nama_area')
        .eq('id_subunit', subunitId).order('nama_area');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> _loadUsers({String? lokasiId, String? unitId,
      String? subunitId, String? areaId}) async {
    setState(() => _isLoadingUsers = true);
    try {
      dynamic query = Supabase.instance.client
          .from('User')
          .select('id_user, nama, jabatan!User_id_jabatan_fkey(nama_jabatan), gambar_user');

      if (areaId != null) query = query.eq('id_area', areaId);
      else if (subunitId != null) query = query.eq('id_subunit', subunitId);
      else if (unitId != null) query = query.eq('id_unit', unitId);
      else if (lokasiId != null) query = query.eq('id_lokasi', lokasiId);

      final data = await query.order('nama');
      List<Map<String, dynamic>> users = List<Map<String, dynamic>>.from(data);

      if (widget.currentUserId != null) {
        users.sort((a, b) {
          if (a['id_user'] == widget.currentUserId) return -1;
          if (b['id_user'] == widget.currentUserId) return 1;
          return (a['nama'] as String).compareTo(b['nama'] as String);
        });
      }

      if (mounted) {
        setState(() {
          _allUsers = users;
          _filteredUsers = users;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      debugPrint('Error load users: $e');
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  void _applyFilter() {
    _loadUsers(
      lokasiId: _selLokasiId,
      unitId: _selUnitId,
      subunitId: _selSubunitId,
      areaId: _selAreaId,
    );
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers
          .where((u) => u['nama'].toString().toLowerCase().contains(q))
          .toList();
    });
  }

  Widget _buildFilterChips({
    required String label,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String nameKey,
    required String? selectedId,
    required Function(String id) onSelect,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: const Color(0xFF00C9E4)),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A8A))),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final id = item[idKey].toString();
            final name = item[nameKey] as String;
            final isSelected = selectedId == id;
            return GestureDetector(
              onTap: () => onSelect(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF00C9E4) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00C9E4)
                        : const Color(0xFFBAE6FD),
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: const Color(0xFF00C9E4).withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ] : null,
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF1E3A8A),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasFilter = _selLokasiId != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_outline,
                      color: Color(0xFF1E3A8A), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.lang == 'ZH' ? '选择负责人'
                        : widget.lang == 'EN' ? 'Select Person in Charge'
                        : 'Pilih Penanggung Jawab',
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A)),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey.shade400),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Filter Section
          Container(
            color: const Color(0xFFF0F9FF),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: Color(0xFF0EA5E9)),
                    const SizedBox(width: 6),
                    Text(
                      widget.lang == 'EN' ? 'Filter Location'
                          : widget.lang == 'ZH' ? '筛选位置' : 'Filter Lokasi',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E3A8A)),
                    ),
                    const Spacer(),
                    if (hasFilter)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selLokasiId = null;
                            _selUnitId = null;
                            _selSubunitId = null;
                            _selAreaId = null;
                            _unitList = [];
                            _subunitList = [];
                            _areaList = [];
                          });
                          _loadUsers();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFFBAE6FD)),
                          ),
                          child: Text(
                            widget.lang == 'EN' ? 'Reset'
                                : widget.lang == 'ZH' ? '重置' : 'Reset',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0369A1)),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Lokasi chips
                _isLoadingLocations
                    ? const Center(child: CircularProgressIndicator(
                        color: Color(0xFF00C9E4), strokeWidth: 2))
                    : _buildFilterChips(
                        label: widget.lang == 'EN' ? 'Location'
                            : widget.lang == 'ZH' ? '位置' : 'Lokasi',
                        icon: Icons.location_city_rounded,
                        items: _lokasiList,
                        idKey: 'id_lokasi',
                        nameKey: 'nama_lokasi',
                        selectedId: _selLokasiId,
                        onSelect: (id) async {
                          final units = await _fetchUnit(id);
                          setState(() {
                            _selLokasiId = id;
                            _selUnitId = null;
                            _selSubunitId = null;
                            _selAreaId = null;
                            _unitList = units;
                            _subunitList = [];
                            _areaList = [];
                          });
                          _applyFilter();
                        },
                      ),

                if (_selLokasiId != null && _unitList.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildFilterChips(
                    label: 'Unit',
                    icon: Icons.business_rounded,
                    items: _unitList,
                    idKey: 'id_unit',
                    nameKey: 'nama_unit',
                    selectedId: _selUnitId,
                    onSelect: (id) async {
                      final subs = await _fetchSubunit(id);
                      setState(() {
                        _selUnitId = id;
                        _selSubunitId = null;
                        _selAreaId = null;
                        _subunitList = subs;
                        _areaList = [];
                      });
                      _applyFilter();
                    },
                  ),
                ],

                if (_selUnitId != null && _subunitList.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildFilterChips(
                    label: 'Sub-Unit',
                    icon: Icons.layers_rounded,
                    items: _subunitList,
                    idKey: 'id_subunit',
                    nameKey: 'nama_subunit',
                    selectedId: _selSubunitId,
                    onSelect: (id) async {
                      final areas = await _fetchArea(id);
                      setState(() {
                        _selSubunitId = id;
                        _selAreaId = null;
                        _areaList = areas;
                      });
                      _applyFilter();
                    },
                  ),
                ],

                if (_selSubunitId != null && _areaList.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildFilterChips(
                    label: 'Area',
                    icon: Icons.place_rounded,
                    items: _areaList,
                    idKey: 'id_area',
                    nameKey: 'nama_area',
                    selectedId: _selAreaId,
                    onSelect: (id) {
                      setState(() => _selAreaId = id);
                      _applyFilter();
                    },
                  ),
                ],
              ],
            ),
          ),

          Divider(color: Colors.grey.shade100, height: 1),

          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: widget.lang == 'ZH' ? '搜索成员...'
                    : widget.lang == 'EN' ? 'Search member...' : 'Cari anggota...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF1E3A8A), size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.cancel_rounded,
                            color: Colors.grey.shade400, size: 18),
                        onPressed: () { _searchCtrl.clear(); _onSearch(); },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF00C9E4), width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: Row(
              children: [
                Icon(Icons.group_outlined, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text(
                  '${_filteredUsers.length} ${widget.lang == 'EN' ? 'members' : 'anggota'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

          Divider(color: Colors.grey.shade100, height: 12),

          // User List
          Expanded(
            child: _isLoadingUsers
                ? const Center(child: CircularProgressIndicator(
                    color: Color(0xFF00C9E4), strokeWidth: 2))
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.group_off_rounded,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              widget.lang == 'EN' ? 'No users found' : 'Tidak ada pengguna',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (_, i) {
                          final user = _filteredUsers[i];
                          final isMe = user['id_user'] == widget.currentUserId;
                          final String name = user['nama'] ?? '';
                          final String role = user['jabatan']?['nama_jabatan'] ?? '';
                          final String? avatarUrl = user['gambar_user'];
                          final String initial = name.isNotEmpty
                              ? name[0].toUpperCase() : '?';

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => Navigator.pop(context, user),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? const Color(0xFF00C9E4).withOpacity(0.06)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isMe
                                        ? const Color(0xFF00C9E4).withOpacity(0.3)
                                        : Colors.grey.shade100,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: const Color(0xFF1E3A8A)
                                              .withOpacity(0.08),
                                          backgroundImage: avatarUrl != null
                                              ? NetworkImage(avatarUrl) : null,
                                          child: avatarUrl == null
                                              ? Text(initial,
                                                  style: const TextStyle(
                                                      color: Color(0xFF1E3A8A),
                                                      fontWeight: FontWeight.bold))
                                              : null,
                                        ),
                                        if (isMe)
                                          Positioned(
                                            bottom: 0, right: 0,
                                            child: Container(
                                              width: 14, height: 14,
                                              decoration: const BoxDecoration(
                                                  color: Color(0xFF00C9E4),
                                                  shape: BoxShape.circle),
                                              child: const Icon(Icons.check,
                                                  color: Colors.white, size: 10),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(name,
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 14,
                                                        color: Color(0xFF1A1A2E))),
                                              ),
                                              if (isMe)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF00C9E4)
                                                        .withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: const Text('Me',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: Color(0xFF0891B2),
                                                        fontWeight: FontWeight.w700),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          if (role.isNotEmpty)
                                            Text(role,
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade500)),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios_rounded,
                                        size: 14, color: Colors.grey.shade300),
                                  ],
                                ),
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

// ==================================================================
// BOTTOM SHEET: ESCALATION PICKER
// ==================================================================
class EscalationPickerBottomSheet extends StatelessWidget {
  final String lang;
  const EscalationPickerBottomSheet({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Map<String, String>>> levels = {
      'ID': [
        {'title': 'Level Umum', 'desc': 'Eskalasi temuan umum'},
        {
          'title': 'Level Harian',
          'desc': 'Eskalasi ke level anggota dan ketua'
        },
        {
          'title': 'Level Mingguan',
          'desc': 'Eskalasi ke level ketua lokasi atau divisi'
        },
        {
          'title': 'Level Bulanan',
          'desc': 'Eskalasi ke level ketua dan manajemen'
        },
      ],
      'EN': [
        {'title': 'General Level', 'desc': 'General finding escalation'},
        {
          'title': 'Daily Level',
          'desc': 'Escalate to member and leader level'
        },
        {
          'title': 'Weekly Level',
          'desc': 'Escalate to location or division head level'
        },
        {
          'title': 'Monthly Level',
          'desc': 'Escalate to leader and management level'
        },
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
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            lang == 'ID' ? 'Level Eskalasi' : 'Escalation Level',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...currentLevels.map((level) => ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.trending_up,
                      color: Color(0xFF1E3A8A), size: 18),
                ),
                title: Text(level['title']!,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(level['desc']!),
                onTap: () => Navigator.pop(context, level['title']),
              )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(lang == 'ID' ? 'Reset' : 'Reset'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ==================================================================
// BOTTOM SHEET: FULL LOCATION PICKER
// - 4 tab independen: Lokasi / Unit / Sub-Unit / Area
// - Klik tab → load data level tersebut (lazy load)
// - Search global: mencari di semua level sekaligus
// - Aturan pro/non-pro tetap berlaku
// ==================================================================
class FullLocationPickerBottomSheet extends StatefulWidget {
  final String lang;
  final bool isProMode;
  final String userRole;
  final String? userLokasiId;
  final String? userUnitId;
  final String? userSubunitId;
  final String? userAreaId;

  // Pre-selection dari form (bisa dari CameraFindingScreen)
  final String? preSelectedLokasiId;
  final String? preSelectedUnitId;
  final String? preSelectedSubunitId;
  final String? preSelectedAreaId;

  const FullLocationPickerBottomSheet({
    super.key,
    required this.lang,
    required this.isProMode,
    required this.userRole,
    this.userLokasiId,
    this.userUnitId,
    this.userSubunitId,
    this.userAreaId,
    this.preSelectedLokasiId,
    this.preSelectedUnitId,
    this.preSelectedSubunitId,
    this.preSelectedAreaId,
  });

  @override
  State<FullLocationPickerBottomSheet> createState() =>
      _FullLocationPickerBottomSheetState();
}

class _FullLocationPickerBottomSheetState
    extends State<FullLocationPickerBottomSheet>
    with SingleTickerProviderStateMixin {

  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();

  // ── Data mentah per level (null = belum pernah di-load) ──
  List<Map<String, dynamic>>? _lokasiData;
  List<Map<String, dynamic>>? _unitData;
  List<Map<String, dynamic>>? _subunitData;
  List<Map<String, dynamic>>? _areaData;

  // ── Hasil search global (null = belum search) ──
  List<_SearchResult>? _searchResults;

  bool _isSearching = false;

  // ── Loading state per level ──
  final _loading = {0: false, 1: false, 2: false, 3: false};

  bool get _isProAccess =>
      widget.isProMode || widget.userRole == 'Eksekutif';

  // ── Helper teks ──
  String _t(String id, String en, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  static const _tabIcons = [
    Icons.location_city_rounded,
    Icons.business_rounded,
    Icons.layers_outlined,
    Icons.place_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this)
      ..addListener(_onTabChanged);
    _searchCtrl.addListener(_onSearchChanged);
    // Load tab pertama langsung
    _loadTabData(0);
  }

  @override
  void dispose() {
    _tabCtrl.removeListener(_onTabChanged);
    _tabCtrl.dispose();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabCtrl.indexIsChanging) return;
    _loadTabData(_tabCtrl.index);
  }

  // ── Load data saat tab diklik, skip jika sudah pernah load ──
  Future<void> _loadTabData(int tabIndex) async {
    if (_getDataForTab(tabIndex) != null) return;

    setState(() => _loading[tabIndex] = true);

    try {
      final supabase = Supabase.instance.client;
      List<dynamic> raw = [];

      switch (tabIndex) {
        case 0: // Lokasi
          if (_isProAccess) {
            raw = await supabase
                .from('lokasi')
                .select('id_lokasi, nama_lokasi')
                .order('nama_lokasi');
          } else if (widget.userLokasiId != null) {
            // Non-pro: hanya lokasi milik user
            raw = await supabase
                .from('lokasi')
                .select('id_lokasi, nama_lokasi')
                .eq('id_lokasi', widget.userLokasiId!);
          }
          break;

        case 1: // Unit
          if (_isProAccess) {
            raw = await supabase
                .from('unit')
                .select('id_unit, nama_unit, id_lokasi')
                .order('nama_unit');
          } else if (widget.userLokasiId != null) {
            // Non-pro: hanya unit di lokasi user
            // Jika user punya unit spesifik, tampilkan hanya itu
            if (widget.userUnitId != null) {
              raw = await supabase
                  .from('unit')
                  .select('id_unit, nama_unit, id_lokasi')
                  .eq('id_lokasi', widget.userLokasiId!)
                  .eq('id_unit', widget.userUnitId!)
                  .order('nama_unit');
            } else {
              raw = await supabase
                  .from('unit')
                  .select('id_unit, nama_unit, id_lokasi')
                  .eq('id_lokasi', widget.userLokasiId!)
                  .order('nama_unit');
            }
          }
          break;

        case 2: // Subunit
          if (_isProAccess) {
            raw = await supabase
                .from('subunit')
                .select('id_subunit, nama_subunit, id_unit, id_lokasi')
                .order('nama_subunit');
          } else if (widget.userLokasiId != null) {
            // Non-pro: filter by lokasi, unit, dan subunit user
            var q = supabase
                .from('subunit')
                .select('id_subunit, nama_subunit, id_unit, id_lokasi')
                .eq('id_lokasi', widget.userLokasiId!);
            if (widget.userUnitId != null) {
              q = q.eq('id_unit', widget.userUnitId!);
            }
            if (widget.userSubunitId != null) {
              q = q.eq('id_subunit', widget.userSubunitId!);
            }
            raw = await q.order('nama_subunit');
          }
          break;

        case 3: // Area
          if (_isProAccess) {
            raw = await supabase
                .from('area')
                .select('id_area, nama_area, id_subunit, id_unit, id_lokasi')
                .order('nama_area');
          } else if (widget.userLokasiId != null) {
            // Non-pro: filter by lokasi, unit, subunit, dan area user
            var q = supabase
                .from('area')
                .select('id_area, nama_area, id_subunit, id_unit, id_lokasi')
                .eq('id_lokasi', widget.userLokasiId!);
            if (widget.userUnitId != null) {
              q = q.eq('id_unit', widget.userUnitId!);
            }
            if (widget.userSubunitId != null) {
              q = q.eq('id_subunit', widget.userSubunitId!);
            }
            if (widget.userAreaId != null) {
              q = q.eq('id_area', widget.userAreaId!);
            }
            raw = await q.order('nama_area');
          }
          break;
      }

      if (!mounted) return;
      final list = List<Map<String, dynamic>>.from(raw);
      setState(() {
        switch (tabIndex) {
          case 0: _lokasiData  = list; break;
          case 1: _unitData    = list; break;
          case 2: _subunitData = list; break;
          case 3: _areaData    = list; break;
        }
        _loading[tabIndex] = false;
      });
    } catch (e) {
      debugPrint('Error load tab $tabIndex: $e');
      if (mounted) setState(() => _loading[tabIndex] = false);
    }
  }

  List<Map<String, dynamic>>? _getDataForTab(int index) {
    return [_lokasiData, _unitData, _subunitData, _areaData][index];
  }

  // ── Search global — cari di semua level ──
  Future<void> _onSearchChanged() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() { _searchResults = null; _isSearching = false; });
      return;
    }

    setState(() => _isSearching = true);

    // Pastikan semua level sudah di-load
    for (int i = 0; i < 4; i++) {
      await _loadTabData(i);
    }

    final qLow = q.toLowerCase();
    final results = <_SearchResult>[];

    void addFromList(
      List<Map<String, dynamic>>? data,
      int tabIndex,
      String idKey,
      String nameKey,
      String levelLabel,
    ) {
      if (data == null) return;
      for (final item in data) {
        final name = (item[nameKey] ?? '').toString();
        if (name.toLowerCase().contains(qLow)) {
          results.add(_SearchResult(
            tabIndex: tabIndex,
            id: item[idKey]?.toString() ?? '',
            name: name,
            levelLabel: levelLabel,
            raw: item,
          ));
        }
      }
    }

    addFromList(_lokasiData,  0, 'id_lokasi',  'nama_lokasi',  _t('Lokasi',   'Location', '地点'));
    addFromList(_unitData,    1, 'id_unit',    'nama_unit',    'Unit');
    addFromList(_subunitData, 2, 'id_subunit', 'nama_subunit', 'Sub-Unit');
    addFromList(_areaData,    3, 'id_area',    'nama_area',    'Area');

    if (mounted) setState(() { _searchResults = results; _isSearching = false; });
  }

  // ── Pilih item dan kembalikan result map ──
  void _selectItem({
    required int tabIndex,
    required Map<String, dynamic> raw,
  }) {
    final Map<String, dynamic> result = {};
    final parts = <String>[];

    switch (tabIndex) {
      case 0:
        result['id_lokasi'] = raw['id_lokasi'];
        parts.add(raw['nama_lokasi'] ?? '');
        break;
      case 1:
        result['id_lokasi'] = raw['id_lokasi'];
        result['id_unit']   = raw['id_unit'];
        parts.add(raw['nama_unit'] ?? '');
        break;
      case 2:
        result['id_lokasi']  = raw['id_lokasi'];
        result['id_unit']    = raw['id_unit'];
        result['id_subunit'] = raw['id_subunit'];
        parts.add(raw['nama_subunit'] ?? '');
        break;
      case 3:
        result['id_lokasi']  = raw['id_lokasi'];
        result['id_unit']    = raw['id_unit'];
        result['id_subunit'] = raw['id_subunit'];
        result['id_area']    = raw['id_area'];
        parts.add(raw['nama_area'] ?? '');
        break;
    }

    result['nama'] = parts.join(' / ');
    Navigator.pop(context, result);
  }

  // ── Build satu baris item ──
  Widget _buildItem({
    required int tabIndex,
    required Map<String, dynamic> raw,
    required String displayName,
    required bool isSelected,
    String? subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF00C9E4).withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF00C9E4).withOpacity(0.45)
              : Colors.grey.shade200,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selectItem(tabIndex: tabIndex, raw: raw),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF00C9E4).withOpacity(0.12)
                        : const Color(0xFF1E3A8A).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _tabIcons[tabIndex],
                    color: isSelected
                        ? const Color(0xFF00C9E4)
                        : const Color(0xFF1E3A8A),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF00C9E4)
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                      if (subtitle != null)
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _selectItem(tabIndex: tabIndex, raw: raw),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFE0F7FA),
                    foregroundColor: const Color(0xFF0891B2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Text(
                    _t('Pilih', 'Select', '选择'),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Konten search results ──
  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 48),
          child: CircularProgressIndicator(
              color: Color(0xFF00C9E4), strokeWidth: 2),
        ),
      );
    }

    final results = _searchResults ?? [];
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 44, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Text(
                _t('Tidak ada hasil', 'No results found', '没有结果'),
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    final labels = [
      _t('Lokasi', 'Location', '地点'),
      'Unit', 'Sub-Unit', 'Area',
    ];

    // Kelompokkan per level
    final grouped = <int, List<_SearchResult>>{};
    for (final r in results) {
      grouped.putIfAbsent(r.tabIndex, () => []).add(r);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 4),
            child: Row(children: [
              Icon(_tabIcons[entry.key],
                  size: 13, color: const Color(0xFF00C9E4)),
              const SizedBox(width: 6),
              Text(
                labels[entry.key],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${entry.value.length}',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A)),
                ),
              ),
            ]),
          ),
          for (final r in entry.value)
            _buildItem(
              tabIndex: r.tabIndex,
              raw: r.raw,
              displayName: r.name,
              isSelected: false,
            ),
        ],
      ],
    );
  }

  // ── Konten per tab ──
  Widget _buildTabContent(int tabIndex) {
    final isLoading = _loading[tabIndex] == true;
    final data = _getDataForTab(tabIndex);

    if (isLoading || data == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 48),
          child: CircularProgressIndicator(
              color: Color(0xFF00C9E4), strokeWidth: 2),
        ),
      );
    }

    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_rounded,
                  size: 44, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Text(
                _t('Data tidak tersedia', 'No data available', '没有数据'),
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    // Key & name per tab
    final keys = [
      ('id_lokasi', 'nama_lokasi'),
      ('id_unit',   'nama_unit'),
      ('id_subunit','nama_subunit'),
      ('id_area',   'nama_area'),
    ];
    final preSelected = [
      widget.preSelectedLokasiId,
      widget.preSelectedUnitId,
      widget.preSelectedSubunitId,
      widget.preSelectedAreaId,
    ];
    final (idKey, nameKey) = keys[tabIndex];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: data.length,
      itemBuilder: (_, i) {
        final item = data[i];
        final id   = item[idKey]?.toString() ?? '';
        final name = item[nameKey]?.toString() ?? '';
        return _buildItem(
          tabIndex: tabIndex,
          raw: item,
          displayName: name,
          isSelected: id == preSelected[tabIndex],
        );
      },
    );
  }

  // ── Tab label dengan dot indicator jika ada pre-selection ──
  Widget _buildTabLabel(String label, String? preSelectedId) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700)),
          if (preSelectedId != null) ...[
            const SizedBox(width: 4),
            Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(
                  color: Color(0xFF00C9E4), shape: BoxShape.circle),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSearchActive = _searchCtrl.text.trim().isNotEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Handle ──
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close,
                      color: Color(0xFF1E3A8A), size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _t('PILIH LOKASI', 'SELECT LOCATION', '选择地点'),
                        style: const TextStyle(
                          color: Color(0xFF1E3A8A),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (!_isProAccess)
                        Text(
                          _t('Lokasi Saya', 'My Location', '我的位置'),
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade600),
                        ),
                    ],
                  ),
                ),
                // Badge jumlah item di tab aktif
                if (!isSearchActive)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_getDataForTab(_tabCtrl.index)?.length ?? 0}',
                      style: const TextStyle(
                          color: Color(0xFF1E3A8A),
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),

          // ── 4 Tab (selalu tampil) ──
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabCtrl,
              isScrollable: false,
              indicatorColor: const Color(0xFF00C9E4),
              indicatorWeight: 2.5,
              labelColor: const Color(0xFF00C9E4),
              unselectedLabelColor: Colors.grey.shade500,
              tabs: [
                _buildTabLabel(
                    _t('Lokasi', 'Location', '地点'),
                    widget.preSelectedLokasiId),
                _buildTabLabel('Unit', widget.preSelectedUnitId),
                _buildTabLabel('Sub-Unit', widget.preSelectedSubunitId),
                _buildTabLabel('Area', widget.preSelectedAreaId),
              ],
            ),
          ),

          Divider(color: Colors.grey.shade200, height: 1),

          // ── Search bar global ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: _t(
                  'Cari lokasi, unit, sub-unit, area...',
                  'Search location, unit, sub-unit, area...',
                  '搜索地点、单位、子单位、区域...',
                ),
                hintStyle: TextStyle(
                    color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFF1E3A8A), size: 20),
                suffixIcon: isSearchActive
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: Colors.grey.shade400, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(
                        color: Color(0xFF00C9E4), width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
            ),
          ),

          Divider(color: Colors.grey.shade100, height: 1),

          // ── Konten: search results ATAU tab view ──
          Expanded(
            child: isSearchActive
                ? _buildSearchResults()
                : TabBarView(
                    controller: _tabCtrl,
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(4, _buildTabContent),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Model ringan untuk hasil search global ──
class _SearchResult {
  final int tabIndex;
  final String id;
  final String name;
  final String levelLabel;
  final Map<String, dynamic> raw;

  const _SearchResult({
    required this.tabIndex,
    required this.id,
    required this.name,
    required this.levelLabel,
    required this.raw,
  });
}