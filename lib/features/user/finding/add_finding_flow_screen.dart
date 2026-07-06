import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/utils/image_picker_helper.dart';
import 'finding_location_filter.dart';
import 'finding_pick_category.dart';
import 'finding_pick_deadline.dart';
import 'finding_pick_pic.dart';

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
        .select('id_user, nama, gambar_user, is_visitor, is_verificator, id_jabatan, id_lokasi, id_unit, id_subunit, id_area, jabatan!User_id_jabatan_fkey(nama_jabatan)')
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
              'gambar_user': profile['gambar_user'],
              'id_jabatan': profile['id_jabatan'],
              'is_verificator': profile['is_verificator'],
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
      barrierColor: Colors.black.withValues(alpha:0.55),
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
                    color: const Color(0xFF16A34A).withValues(alpha:0.3),
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
                      color: const Color(0xFF16A34A).withValues(alpha:0.1),
                      border: Border.all(
                        color: const Color(0xFF16A34A).withValues(alpha:0.3),
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
                            const Color(0xFF16A34A).withValues(alpha:0.1),
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
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha:0.4),
      builder: (ctx) => FindingLocationFilterScreen(
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
    final result = await showFindingPickCategoryDialog(context, lang: widget.lang);
    if (result != null) setState(() => _selectedCategory = result);
  }

  void _showAssigneePicker() async {
    final result = await showFindingPickPicDialog(
      context,
      lang: widget.lang,
      currentUserId: _currentUserProfile?['id_user']?.toString(),
      selectedUserId: _selectedAssignee?['id_user']?.toString(),
    );
    if (result != null) setState(() => _selectedAssignee = result);
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1D72F3)),
            onPressed: () => Navigator.pop(context, null),
          ),
          title: Text(
            _texts['title']!,
            style: GoogleFonts.poppins(
                color: Color(0xFF1D72F3),
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
                  _buildIconSectionTitle(Icons.map_rounded, _texts['location']!, isRequired: true),
                  _buildLocationPickerCard(),
                  const SizedBox(height: 20),

                  // Image Section
                  if (_imageXFile != null) ...[
                    _buildIconSectionTitle(Icons.photo_camera_rounded, _texts['photo']!, isRequired: true),
                    _buildImageCard(),
                    const SizedBox(height: 20),
                  ],

                  // Visitor Fields - shown right after photo if user is visitor
                  if (_isVisitorUser) ...[
                    _buildVisitorSection(),
                    const SizedBox(height: 20),
                  ],

                  // Title
                  _buildIconSectionTitle(Icons.edit_note_rounded, _texts['form_title']!, isRequired: true),
                  _buildTextField(
                    controller: _titleCtrl,
                    hint: _texts['form_title_hint']!,
                  ),
                  const SizedBox(height: 20),

                  // Notes
                  _buildIconSectionTitle(Icons.sticky_note_2_outlined, _texts['notes']!, isRequired: true),
                  _buildTextField(
                    controller: _notesCtrl,
                    hint: _texts['notes_hint']!,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  // Category
                  _buildIconSectionTitle(Icons.category_outlined, _texts['category']!, isRequired: true),
                  _buildCategoryPickerCard(),
                  const SizedBox(height: 20),

                  // Due Date
                  _buildIconSectionTitle(Icons.calendar_today_outlined, _texts['due_date']!, isRequired: true),
                  FindingDeadlinePickerCard(
                    lang: widget.lang,
                    selectedDate: _selectedDueDate,
                    onDateSelected: (date) => setState(() => _selectedDueDate = date),
                  ),
                  const SizedBox(height: 20),

                  // Assignee - ALWAYS VISIBLE (not just Pro mode)
                  _buildIconSectionTitle(Icons.person_outline, _texts['assignee']!, isRequired: true),
                  FindingPicPickerCard(
                    lang: widget.lang,
                    selectedUser: _selectedAssignee,
                    onTap: _showAssigneePicker,
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
      color: Colors.black.withValues(alpha:0.55),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C9E4).withValues(alpha:0.3),
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
                            color: const Color(0xFF00C9E4).withValues(alpha:0.06),
                            border: Border.all(
                              color: const Color(0xFF00C9E4).withValues(alpha:0.15),
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
                            color: const Color(0xFF00C9E4).withValues(alpha:0.12),
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
        border: Border.all(color: const Color(0xFF1D72F3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.12),
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
                      Colors.black.withValues(alpha:0.6),
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
                    color: Colors.black.withValues(alpha:0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha:0.3), width: 1),
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
            const Color(0xFF1E3A8A).withValues(alpha:0.05),
            const Color(0xFF00C9E4).withValues(alpha:0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF00C9E4).withValues(alpha:0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C9E4).withValues(alpha:0.15),
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
            color: const Color(0xFF1E3A8A).withValues(alpha:0.08),
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _saveFinding(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D72F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              elevation: 2,
              shadowColor: const Color(0xFF1D72F3).withValues(alpha:0.4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save_outlined, size: 20),
                const SizedBox(width: 8),
                Text(_texts['btn_save']!,
                    style: GoogleFonts.poppins(
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
              side: const BorderSide(color: Color(0xFF1D72F3), width: 1.5),
              foregroundColor: const Color(0xFF1D72F3),
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_outline, size: 20),
                const SizedBox(width: 8),
                Text(_texts['btn_save_new']!,
                    style: GoogleFonts.poppins(
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

  Widget _buildIconSectionTitle(IconData icon, String title,
      {bool isRequired = false, bool isOptional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1D72F3)),
          const SizedBox(width: 6),
          Text(title,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: const Color(0xFF1D72F3))),
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
    IconData? icon,
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
        prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF1E3A8A), size: 20) : null,
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

  Widget _buildLocationPickerCard() {
    final bool hasValue = _selectedLocation != null;

    // Tentukan level lokasi yang dipilih (Lokasi/Unit/Sub-Unit/Area)
    // agar icon & warna konsisten dengan popup Select Location.
    int levelIndex = 0;
    IconData levelIcon = Icons.location_city_rounded;
    if (hasValue) {
      if (_selectedLocation?['id_area'] != null) {
        levelIndex = 3;
        levelIcon = Icons.place_rounded;
      } else if (_selectedLocation?['id_subunit'] != null) {
        levelIndex = 2;
        levelIcon = Icons.layers_outlined;
      } else if (_selectedLocation?['id_unit'] != null) {
        levelIndex = 1;
        levelIcon = Icons.business_rounded;
      } else {
        levelIndex = 0;
        levelIcon = Icons.location_city_rounded;
      }
    }

    const List<Color> levelColors = [
      Color(0xFF10B981), // Lokasi
      Color(0xFF6366F1), // Unit
      Color(0xFFFBBF24), // Sub-Unit
      Color(0xFFF472B6), // Area
    ];

    final Color activeColor =
        hasValue ? levelColors[levelIndex] : const Color(0xFF1D72F3);

    return GestureDetector(
      onTap: _showLocationPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasValue ? activeColor.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? activeColor.withValues(alpha: 0.5) : Colors.grey.shade200,
            width: hasValue ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(hasValue ? levelIcon : Icons.map_rounded, color: activeColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedLocation?['nama'] ?? _texts['select_location']!,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: hasValue ? FontWeight.w700 : FontWeight.normal,
                  color: hasValue ? const Color(0xFF0F172A) : Colors.grey.shade500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              hasValue ? Icons.arrow_forward_ios_rounded : Icons.arrow_drop_down,
              size: hasValue ? 16 : 24,
              color: activeColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPickerCard() {
    final bool hasValue = _selectedCategory != null;
    final String kategoriNama = _selectedCategory?['kategori_nama'] ?? '';
    final String subkategoriNama = _selectedCategory?['subkategori_nama'] ?? '';
    final IconData icon = hasValue
        ? FindingPickCategoryDialog.getIconForCategory(kategoriNama)
        : Icons.category_outlined;
    final Color iconColor = hasValue
        ? FindingPickCategoryDialog.getColorForCategory(kategoriNama)
        : const Color(0xFF1E3A8A);

    return GestureDetector(
      onTap: _showCategoryPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? iconColor.withValues(alpha: 0.5) : Colors.grey.shade200,
            width: hasValue ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            // Icon hanya muncul jika sudah ada kategori terpilih
            if (hasValue) ...[
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: hasValue
                  ? RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: kategoriNama,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: iconColor,
                            ),
                          ),
                          TextSpan(
                            text: ' - $subkategoriNama',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      _texts['select_category']!,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.grey.shade500,
                      ),
                    ),
            ),
            Icon(Icons.arrow_drop_down,
                color: hasValue ? iconColor : Colors.grey.shade400),
          ],
        ),
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
                ? const Color(0xFF00C9E4).withValues(alpha:0.5)
                : Colors.grey.shade200,
            width: hasValue ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.04),
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
        'title': 'Add 5R Finding',
        'photo': '5R Finding Photo',
        'retake': 'Retake',
        'location': 'Specific Location',
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
        'title': 'Buat Temuan 5R',
        'photo': 'Foto Temuan 5R',
        'retake': 'Ulangi',
        'location': 'Lokasi Spesifik',
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
        'title': '输入5R发现',
        'photo': '5R发现照片',
        'retake': '重拍',
        'location': '具体地点',
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
                    color: const Color(0xFF1E3A8A).withValues(alpha:0.08),
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