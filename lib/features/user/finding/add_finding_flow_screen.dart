import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'camera_finding_screen.dart';

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
    if (widget.preSelectedLocationId != null) {
      _selectedLocation = {
        'id_lokasi': widget.preSelectedLocationId,
        'id_unit': widget.preSelectedUnitId,
        'id_subunit': widget.preSelectedSubunitId,
        'id_area': widget.preSelectedAreaId,
        'nama': widget.preSelectedLocationName,
      };
    }
    _initCamera();
    _loadCurrentUserProfile();
  }

  /// Load current user profile (for default PIC and location filtering)
  Future<void> _loadCurrentUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final profile = await Supabase.instance.client
          .from('User')
          .select('id_user, nama, is_visitor, id_jabatan, id_lokasi, id_unit, id_subunit, id_area, jabatan(nama_jabatan)')
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
      final image = await _picker.pickImage(source: ImageSource.gallery);
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

      await _showSaveSuccessDialog();

      if (createNewAfter) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CameraFindingScreen(
                lang: widget.lang,
                isProMode: widget.isProMode,
                isVisitorMode: widget.isVisitorMode,
                selectedLocationName: _selectedLocation?['nama'] ??
                    _texts['select_location']!,
                selectedLocationId: _selectedLocation?['id_lokasi'],
                selectedUnitId: _selectedLocation?['id_unit'],
                selectedSubunitId: _selectedLocation?['id_subunit'],
                selectedAreaId: _selectedLocation?['id_area'],
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          // Pop AddFindingFlowScreen dengan true
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint("Error saving finding: $e");
      // Provide user-friendly error message
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
        _showSnackBar(errorMsg, isError: true);
        setState(() => _isSaving = false);
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
        // Auto close setelah 3 detik
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
    if (_currentUserProfile == null) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FullLocationPickerBottomSheet(
        lang: widget.lang,
        isProMode: widget.isProMode,
        userRole: _currentUserProfile!['jabatan']?['nama_jabatan'] ?? 'Staff',
        userUnitId: _currentUserProfile!['id_unit'],
        userLokasiId: _currentUserProfile!['id_lokasi'],
        userSubunitId: _currentUserProfile!['id_subunit'],
        userAreaId: _currentUserProfile!['id_area'],
      ),
    );

    if (result != null) {
      setState(() => _selectedLocation = result);
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
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => AssigneePickerBottomSheet(
        lang: widget.lang,
        // Always use locationId = 1 (PT ATMI SOLO) as specified
        locationId: 1,
        unitId: null,
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
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00C9E4))),
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
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
              onPressed: () {
                // If we have an image already, go back to form
                // If not, pop to wherever we came from
                if (widget.initialImageXFile.path.isNotEmpty) {
                  setState(() => _imageXFile = widget.initialImageXFile);
                } else {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () {
            // Back from form -> go to CameraFindingScreen with location
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CameraFindingScreen(
                  lang: widget.lang,
                  isProMode: widget.isProMode,
                  isVisitorMode: widget.isVisitorMode,
                  selectedLocationName: _selectedLocation?['nama'] ??
                      widget.preSelectedLocationName ??
                      '',
                  selectedLocationId:
                      _selectedLocation?['id_lokasi'] ??
                          widget.preSelectedLocationId,
                  selectedUnitId:
                      _selectedLocation?['id_unit'] ?? widget.preSelectedUnitId,
                  selectedSubunitId:
                      _selectedLocation?['id_subunit'] ??
                          widget.preSelectedSubunitId,
                  selectedAreaId:
                      _selectedLocation?['id_area'] ?? widget.preSelectedAreaId,
                ),
              ),
            );
          },
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
            // Retake button - navigates to CameraFindingScreen WITH location
            Positioned(
              bottom: 10,
              right: 10,
              child: GestureDetector(
                onTap: () {
                  // Navigate to CameraFindingScreen with preserved location
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraFindingScreen(
                        lang: widget.lang,
                        isProMode: widget.isProMode,
                        isVisitorMode: widget.isVisitorMode,
                        selectedLocationName: _selectedLocation?['nama'] ??
                            widget.preSelectedLocationName ??
                            '',
                        selectedLocationId: _selectedLocation?['id_lokasi'] ??
                            widget.preSelectedLocationId,
                        selectedUnitId: _selectedLocation?['id_unit'] ??
                            widget.preSelectedUnitId,
                        selectedSubunitId: _selectedLocation?['id_subunit'] ??
                            widget.preSelectedSubunitId,
                        selectedAreaId: _selectedLocation?['id_area'] ??
                            widget.preSelectedAreaId,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.camera_alt,
                          color: Colors.white, size: 15),
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
      final response = await Supabase.instance.client
          .from('kategoritemuan')
          .select('*, subkategoritemuan(*)');
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
  final int? locationId;
  final int? unitId;
  const AssigneePickerBottomSheet(
      {super.key, required this.lang, this.locationId, this.unitId});

  @override
  State<AssigneePickerBottomSheet> createState() =>
      _AssigneePickerBottomSheetState();
}

class _AssigneePickerBottomSheetState
    extends State<AssigneePickerBottomSheet> {
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    try {
      // Always fetch all users where id_lokasi = 1 (PT ATMI SOLO)
      final response = await Supabase.instance.client
          .from('User')
          .select('id_user, nama, jabatan(nama_jabatan)')
          .eq('id_lokasi', 1)
          .order('nama');
      final data = List<Map<String, dynamic>>.from(response);
      if (mounted) {
        setState(() {
          _allUsers = data;
          _filteredUsers = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching users: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers
          .where((user) =>
              user['nama'].toString().toLowerCase().contains(query))
          .toList();
    });
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.builder(
        itemCount: 6,
        itemBuilder: (_, __) => ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.white),
          title: Container(
              height: 14, width: 120, color: Colors.white),
          subtitle: Container(
              height: 10, width: 80, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lang == 'ID'
                          ? 'Pilih Penanggung Jawab'
                          : 'Select PIC',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A)),
                    ),
                    Text(
                      'PT ATMI SOLO',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.lang == 'ID'
                    ? 'Cari anggota...'
                    : 'Search member...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (!_isLoading)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_filteredUsers.length} ${widget.lang == 'ID' ? 'anggota' : 'members'}',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? _buildShimmerList()
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Text(widget.lang == 'ID'
                            ? 'Tidak ada pengguna ditemukan'
                            : 'No users found'))
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final String name = user['nama'] ?? '';
                          final String role =
                              user['jabatan']?['nama_jabatan'] ?? '';
                          final String initial =
                              name.isNotEmpty ? name[0].toUpperCase() : '?';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  const Color(0xFF1E3A8A).withOpacity(0.1),
                              child: Text(
                                initial,
                                style: const TextStyle(
                                    color: Color(0xFF1E3A8A),
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            subtitle: role.isNotEmpty ? Text(role) : null,
                            trailing: const Icon(Icons.arrow_forward_ios,
                                size: 14, color: Colors.grey),
                            onTap: () => Navigator.pop(context, user),
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
// ==================================================================
class FullLocationPickerBottomSheet extends StatefulWidget {
  final String lang;
  final bool isProMode;
  final String userRole;
  final int? userUnitId;
  final int? userLokasiId;
  final int? userSubunitId;
  final int? userAreaId;

  const FullLocationPickerBottomSheet({
    super.key,
    required this.lang,
    required this.isProMode,
    required this.userRole,
    this.userUnitId,
    this.userLokasiId,
    this.userSubunitId,
    this.userAreaId,
  });

  @override
  State<FullLocationPickerBottomSheet> createState() =>
      _FullLocationPickerBottomSheetState();
}

class _FullLocationPickerBottomSheetState
    extends State<FullLocationPickerBottomSheet> {
  int _currentLevel = 0;
  bool _isLoading = true;
  List<dynamic> _currentData = [];
  List<dynamic> _filteredData = [];
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _navHistory = [];

  // Pro mode OR Eksekutif = full access
  bool get _hasFullAccess =>
      widget.isProMode || widget.userRole == 'Eksekutif';

  late Map<String, String> texts;

  @override
  void initState() {
    super.initState();
    _setupTranslations();
    _searchController.addListener(_onSearchChanged);
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setupTranslations() {
    final Map<String, Map<String, String>> data = {
      'EN': {
        'title_lokasi': 'LOCATION',
        'title_unit': 'UNIT',
        'title_subunit': 'SUB-UNIT',
        'title_area': 'AREA',
        'search_lokasi': 'Search location...',
        'search_unit': 'Search unit...',
        'search_subunit': 'Search sub-unit...',
        'search_area': 'Search area...',
        'select': 'Select',
        'sublokasi': 'Sub-locations',
        'empty': 'No data found',
        'my_location': 'My Location',
      },
      'ID': {
        'title_lokasi': 'LOKASI',
        'title_unit': 'UNIT',
        'title_subunit': 'SUB-UNIT',
        'title_area': 'AREA',
        'search_lokasi': 'Cari lokasi...',
        'search_unit': 'Cari unit...',
        'search_subunit': 'Cari sub-unit...',
        'search_area': 'Cari area...',
        'select': 'Pilih',
        'sublokasi': 'Sublokasi',
        'empty': 'Data tidak ditemukan',
        'my_location': 'Lokasi Saya',
      },
      'ZH': {
        'title_lokasi': '地点',
        'title_unit': '单位',
        'title_subunit': '子单位',
        'title_area': '区域',
        'search_lokasi': '搜索地点...',
        'search_unit': '搜索单位...',
        'search_subunit': '搜索子单位...',
        'search_area': '搜索区域...',
        'select': '选择',
        'sublokasi': '子位置',
        'empty': '未找到数据',
        'my_location': '我的位置',
      },
    };
    texts = data[widget.lang] ?? data['ID']!;
  }

  String _getLevelName([int? level]) =>
      ['lokasi', 'unit', 'subunit', 'area'][level ?? _currentLevel];

  String _getLevelTitle([int? level]) {
    final l = level ?? _currentLevel;
    return texts[['title_lokasi', 'title_unit', 'title_subunit', 'title_area'][l]] ?? '';
  }

  String _getSearchHint() {
    return texts[['search_lokasi', 'search_unit', 'search_subunit', 'search_area'][_currentLevel]] ?? '';
  }

  Future<void> _fetchData({int? parentId}) async {
    setState(() => _isLoading = true);
    _searchController.clear();
    try {
      final supabase = Supabase.instance.client;
      List<dynamic> data = [];

      if (_currentLevel == 0) {
        if (_hasFullAccess) {
          // Pro/Executive: show ALL locations
          data = await supabase
              .from('lokasi')
              .select('id_lokasi, nama_lokasi')
              .order('nama_lokasi');
        } else {
          // Regular user: only their location
          if (widget.userLokasiId != null) {
            data = await supabase
                .from('lokasi')
                .select('id_lokasi, nama_lokasi')
                .eq('id_lokasi', widget.userLokasiId!);
          }
        }
      } else if (_currentLevel == 1) {
        if (_hasFullAccess) {
          data = await supabase
              .from('unit')
              .select('id_unit, nama_unit, id_lokasi')
              .eq('id_lokasi', parentId!)
              .order('nama_unit');
        } else {
          // Regular: only their unit
          if (widget.userUnitId != null) {
            data = await supabase
                .from('unit')
                .select('id_unit, nama_unit, id_lokasi')
                .eq('id_lokasi', parentId!)
                .eq('id_unit', widget.userUnitId!);
          }
        }
      } else if (_currentLevel == 2) {
        if (_hasFullAccess) {
          data = await supabase
              .from('subunit')
              .select('id_subunit, nama_subunit, id_unit')
              .eq('id_unit', parentId!)
              .order('nama_subunit');
        } else {
          if (widget.userSubunitId != null) {
            data = await supabase
                .from('subunit')
                .select('id_subunit, nama_subunit, id_unit')
                .eq('id_unit', parentId!)
                .eq('id_subunit', widget.userSubunitId!);
          } else {
            data = await supabase
                .from('subunit')
                .select('id_subunit, nama_subunit, id_unit')
                .eq('id_unit', parentId!)
                .order('nama_subunit');
          }
        }
      } else if (_currentLevel == 3) {
        if (_hasFullAccess) {
          data = await supabase
              .from('area')
              .select('id_area, nama_area, id_subunit')
              .eq('id_subunit', parentId!)
              .order('nama_area');
        } else {
          if (widget.userAreaId != null) {
            data = await supabase
                .from('area')
                .select('id_area, nama_area, id_subunit')
                .eq('id_subunit', parentId!)
                .eq('id_area', widget.userAreaId!);
          } else {
            data = await supabase
                .from('area')
                .select('id_area, nama_area, id_subunit')
                .eq('id_subunit', parentId!)
                .order('nama_area');
          }
        }
      }

      if (mounted) {
        setState(() {
          _currentData = data;
          _filteredData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading location picker: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredData = _currentData.where((item) {
        final name =
            item['nama_${_getLevelName()}']?.toString().toLowerCase() ?? '';
        return name.contains(query);
      }).toList();
    });
  }

  void _goBack() {
    if (_navHistory.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final prev = _navHistory.removeLast();
    setState(() => _currentLevel--);
    _fetchData(parentId: _navHistory.isEmpty ? null : _navHistory.last['id']);
  }

  void _navigateDeeper(Map<String, dynamic> item) {
    if (_currentLevel >= 3) return;
    final tName = _getLevelName();
    _navHistory.add({
      'level': _currentLevel,
      'id': item['id_$tName'],
      'name': item['nama_$tName'],
    });
    setState(() => _currentLevel++);
    _fetchData(parentId: item['id_${_getLevelName(_currentLevel - 1)}']);
  }

  void _selectItem(Map<String, dynamic> item) {
    final tName = _getLevelName();
    final Map<String, dynamic> result = {};

    // Build ID hierarchy from navigation history
    for (final h in _navHistory) {
      result['id_${_getLevelName(h['level'])}'] = h['id'];
    }
    result['id_$tName'] = item['id_$tName'];

    // Build display name (full path)
    final parts = _navHistory.map((h) => h['name'] as String).toList();
    parts.add(item['nama_$tName']);
    result['nama'] = parts.join(' / ');

    Navigator.pop(context, result);
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Level indicator breadcrumb
  Widget _buildBreadcrumb() {
    final levels = [
      texts['title_lokasi']!,
      texts['title_unit']!,
      texts['title_subunit']!,
      texts['title_area']!,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = i == _currentLevel;
          final isPast = i < _currentLevel;
          return Row(
            children: [
              GestureDetector(
                onTap: isPast
                    ? () {
                        // Navigate back to that level
                        final stepsBack = _currentLevel - i;
                        for (int s = 0; s < stepsBack; s++) {
                          if (_navHistory.isNotEmpty) _navHistory.removeLast();
                        }
                        setState(() => _currentLevel = i);
                        _fetchData(
                            parentId: _navHistory.isEmpty
                                ? null
                                : _navHistory.last['id']);
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF1E3A8A)
                        : isPast
                            ? const Color(0xFF1E3A8A).withOpacity(0.1)
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    levels[i],
                    style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : isPast
                              ? const Color(0xFF1E3A8A)
                              : Colors.grey.shade400,
                      fontSize: 11,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
              if (i < 3)
                Icon(Icons.chevron_right,
                    size: 16,
                    color: i < _currentLevel
                        ? const Color(0xFF1E3A8A)
                        : Colors.grey.shade300),
            ],
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastLevel = _currentLevel == 3;
    final itemCount = _filteredData.length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // App Bar Row
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _navHistory.isEmpty ? Icons.close : Icons.arrow_back_ios,
                    color: const Color(0xFF1E3A8A),
                    size: 20,
                  ),
                  onPressed: _goBack,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _navHistory.isEmpty
                            ? _getLevelTitle()
                            : _navHistory.last['name'],
                        style: const TextStyle(
                          color: Color(0xFF1E3A8A),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (!_hasFullAccess)
                        Text(
                          texts['my_location']!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                // Item count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$itemCount',
                    style: const TextStyle(
                        color: Color(0xFF1E3A8A),
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Breadcrumb navigation
          Container(
            color: Colors.white,
            child: _buildBreadcrumb(),
          ),

          // Divider
          Container(
              height: 1, color: Colors.grey.shade200),

          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _getSearchHint(),
                hintStyle:
                    TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFF1E3A8A), size: 20),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(
                      color: Color(0xFF00C9E4), width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              ),
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : _filteredData.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_off,
                                size: 48,
                                color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text(
                              texts['empty']!,
                              style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _filteredData.length,
                        itemBuilder: (context, index) {
                          final item = _filteredData[index];
                          final tName = _getLevelName();
                          final name = item['nama_$tName'] ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: isLastLevel
                                    ? () => _selectItem(item)
                                    : () => _navigateDeeper(item),
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  child: Row(
                                    children: [
                                      // Level icon
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E3A8A)
                                              .withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          [
                                            Icons.location_city,
                                            Icons.business,
                                            Icons.layers_outlined,
                                            Icons.place,
                                          ][_currentLevel],
                                          color: const Color(0xFF1E3A8A),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: Color(0xFF1A1A2E),
                                          ),
                                        ),
                                      ),
                                      // Select button
                                      TextButton(
                                        onPressed: () => _selectItem(item),
                                        style: TextButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFFE0F7FA),
                                          foregroundColor:
                                              const Color(0xFF0891B2),
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 6),
                                          minimumSize: Size.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: Text(
                                          texts['select']!,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      // Drill down arrow (if not last level)
                                      if (!isLastLevel) ...[
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () =>
                                              _navigateDeeper(item),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      8),
                                            ),
                                            child: Icon(
                                              Icons.chevron_right,
                                              color: Colors.grey.shade500,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
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