import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../home/alert/required_field_alert.dart';
import 'accident_result_popup.dart';
import 'camera/accident_camera_screen.dart';
import 'picker/accident_pick_affected.dart';
import 'picker/accident_pick_cause.dart';
import 'picker/accident_pick_date.dart';
import 'picker/accident_pick_location.dart';
import 'picker/accident_pick_severity.dart';
import 'picker/accident_pick_time.dart';
import 'picker/accident_pick_witness.dart';

class AccidentReportFormScreen extends StatefulWidget {
  final String lang;
  final Map<String, dynamic>? existingReport;

  const AccidentReportFormScreen(
      {super.key, required this.lang, this.existingReport});

  @override
  State<AccidentReportFormScreen> createState() =>
      _AccidentReportFormScreenState();
}

class _AccidentReportFormScreenState
    extends State<AccidentReportFormScreen> {
  bool get _isEdit => widget.existingReport != null;
  bool _isSaving = false;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _actionCtrl = TextEditingController();

  DateTime? _incidentDate;
  TimeOfDay? _incidentTime;
  String? _selectedCause;
  String? _selectedSeverity;
  Map<String, dynamic>? _selectedLocation;
  Map<String, dynamic>? _selectedVictim;
  String? _victimManualName;
  Map<String, dynamic>? _selectedSupervisor;
  Map<String, dynamic>? _selectedWitness;
  String? _witnessManualName;
  String? _currentUserLokasiId;
  String? _currentUserAreaId;
  String? _currentUserSubunitId;
  String? _currentUserUnitId;
  // ignore: unused_field
  bool _isLoadingCurrentUser = true;
  XFile? _imageFile;
  String? _existingImageUrl;

  Map<String, String> get t => _formTxt[widget.lang] ?? _formTxt['ID']!;

  static const Map<String, Map<String, String>> _formTxt = {
    'ID': {
      'create_title': 'Buat Laporan Kecelakaan',
      'edit_title': 'Edit Laporan Kecelakaan',
      'who_involved': 'Siapa yang Terlibat',
      'who_sub': 'Identifikasi pihak yang terluka dan yang menyaksikan',
      'victim': 'Pihak Terdampak',
      'select_victim': 'Pilih Pihak Terdampak',
      'supervisor': 'Supervisor',
      'witness': 'Saksi',
      'select_witness': 'Pilih Saksi',
      'detail_title': 'Detail Kecelakaan',
      'detail_sub': 'Berikan bukti foto dan detail kejadian',
      'photo': 'Foto Bukti',
      'add_photo': 'Tambah Foto Bukti',
      'title_field': 'Judul',
      'title_hint': 'Contoh: Tergelincir di area gudang',
      'desc': 'Deskripsi Detail Kejadian',
      'desc_hint': 'Ceritakan kejadian secara rinci...',
      'date': 'Tanggal Kejadian',
      'pick_date': 'Pilih Tanggal',
      'time': 'Waktu Kejadian',
      'pick_time': 'Pilih Waktu',
      'location': 'Lokasi Kejadian',
      'pick_location': 'Pilih Lokasi',
      'cause': 'Penyebab Kecelakaan',
      'pick_cause': 'Pilih Penyebab Kecelakaan',
      'severity': 'Tingkat Keparahan',
      'pick_severity': 'Pilih Tingkat Keparahan',
      'dept': 'Departemen Terdampak',
      'dept_hint': 'Contoh: Marketing',
      'action': 'Tindakan yang Diambil',
      'action_hint': 'Contoh: Dibawa ke rumah sakit',
      'submit': 'Kirim Laporan',
      'update': 'Perbarui Laporan',
      'err_title': 'Judul wajib diisi!',
      'err_victim': 'Pihak terdampak wajib dipilih!',
      'err_date': 'Tanggal kejadian wajib diisi!',
      'err_time': 'Waktu kejadian wajib diisi!',
      'err_location': 'Lokasi kejadian wajib diisi!',
      'err_cause': 'Penyebab wajib dipilih!',
      'err_severity': 'Tingkat keparahan wajib dipilih!',
      'err_desc': 'Deskripsi wajib diisi!',
      'err_photo': 'Foto bukti wajib diunggah!',
      'success': 'Laporan berhasil dikirim!',
      'success_edit': 'Laporan berhasil diperbarui!',
      'fail': 'Gagal mengirim laporan',
      'saving': 'Mengirim laporan...',
      'cancel': 'Batal',
    },
    'EN': {
      'create_title': 'Create Accident Report',
      'edit_title': 'Edit Accident Report',
      'who_involved': 'Who Was Involved',
      'who_sub': 'Identify who was injured and who witnessed',
      'victim': 'Affected Party',
      'select_victim': 'Select Affected Party',
      'supervisor': 'Supervisor',
      'witness': 'Witness',
      'select_witness': 'Select Witness',
      'detail_title': 'Accident Details',
      'detail_sub': 'Provide photo evidence and incident details',
      'photo': 'Evidence Photo',
      'add_photo': 'Add Evidence Photo',
      'title_field': 'Title',
      'title_hint': 'Example: Slipped in warehouse area',
      'desc': 'Detailed Description',
      'desc_hint': 'Describe the incident in detail...',
      'date': 'Incident Date',
      'pick_date': 'Pick Date',
      'time': 'Incident Time',
      'pick_time': 'Pick Time',
      'location': 'Incident Location',
      'pick_location': 'Pick Location',
      'cause': 'Accident Cause',
      'pick_cause': 'Select Accident Cause',
      'severity': 'Severity Level',
      'pick_severity': 'Select Severity',
      'dept': 'Affected Department',
      'dept_hint': 'Example: Marketing',
      'action': 'Action Taken',
      'action_hint': 'Example: Victim taken to hospital',
      'submit': 'Submit Report',
      'update': 'Update Report',
      'err_title': 'Title is required!',
      'err_victim': 'Affected party is required!',
      'err_date': 'Incident date is required!',
      'err_time': 'Incident time is required!',
      'err_location': 'Incident location is required!',
      'err_cause': 'Cause is required!',
      'err_severity': 'Severity is required!',
      'err_desc': 'Description is required!',
      'err_photo': 'Evidence photo is required!',
      'success': 'Report submitted successfully!',
      'success_edit': 'Report updated successfully!',
      'fail': 'Failed to submit report',
      'saving': 'Submitting report...',
      'cancel': 'Cancel',
    },
    'ZH': {
      'create_title': '创建事故报告',
      'edit_title': '编辑事故报告',
      'who_involved': '涉及人员',
      'who_sub': '确认受伤人员和目击者',
      'victim': '受影响方',
      'select_victim': '选择受影响方',
      'supervisor_hint': '请先选择受影响方',
      'witness': '目击者',
      'select_witness': '选择目击者',
      'detail_title': '事故详情',
      'detail_sub': '提供照片证据和事故详情',
      'photo': '证据照片',
      'add_photo': '添加证据照片',
      'title_field': '标题',
      'title_hint': '例如：在仓库区域滑倒',
      'desc': '详细描述',
      'desc_hint': '详细描述事故经过...',
      'date': '事故日期',
      'pick_date': '选择日期',
      'time': '事故时间',
      'pick_time': '选择时间',
      'location': '事故地点',
      'pick_location': '选择地点',
      'cause': '事故原因',
      'pick_cause': '选择事故原因',
      'severity': '严重程度',
      'pick_severity': '选择严重程度',
      'dept': '受影响部门',
      'dept_hint': '例如：市场部',
      'action': '采取的措施',
      'action_hint': '例如：受害者被送往医院',
      'submit': '提交报告',
      'update': '更新报告',
      'err_title': '标题为必填项！',
      'err_victim': '受影响方为必选项！',
      'err_date': '事故日期为必填项！',
      'err_time': '事故时间为必填项！',
      'err_location': '事故地点为必填项！',
      'err_cause': '原因为必选项！',
      'err_severity': '严重程度为必选项！',
      'err_desc': '描述为必填项！',
      'err_photo': '证据照片为必填项！',
      'success': '报告提交成功！',
      'success_edit': '报告更新成功！',
      'fail': '提交报告失败',
      'saving': '正在提交报告...',
      'cancel': '取消',
    },
  };

  // ── Lifecycle ──────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadCurrentUserLokasi();
    if (_isEdit) _populateData();
    AccidentCameraWarmupService.instance.warmUp();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _deptCtrl.dispose();
    _actionCtrl.dispose();
    AccidentCameraWarmupService.instance.release();
    super.dispose();
  }

  // ── Data Loading ───────────────────────────────────────────
  Future<void> _loadCurrentUserLokasi() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final profile = await Supabase.instance.client
          .from('User')
          .select('id_lokasi, id_unit, id_subunit, id_area')
          .eq('id_user', user.id)
          .single();
      if (mounted) {
        setState(() {
          _currentUserLokasiId = profile['id_lokasi']?.toString();
          _currentUserUnitId = profile['id_unit']?.toString();
          _currentUserSubunitId = profile['id_subunit']?.toString();
          _currentUserAreaId = profile['id_area']?.toString();
          _isLoadingCurrentUser = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading current user lokasi: $e');
      if (mounted) setState(() => _isLoadingCurrentUser = false);
    }
  }

  void _populateData() {
    final r = widget.existingReport!;
    _titleCtrl.text = r['judul'] ?? '';
    _descCtrl.text = r['deskripsi'] ?? '';
    _deptCtrl.text = r['departemen_terdampak'] ?? '';
    _actionCtrl.text = r['tindakan_diambil'] ?? '';
    _selectedCause = r['penyebab'];
    _selectedSeverity = r['tingkat_keparahan'];
    _existingImageUrl = r['foto_bukti'];
    if (r['tanggal_kejadian'] != null) {
      _incidentDate = DateTime.tryParse(r['tanggal_kejadian']);
    }
    if (r['waktu_kejadian'] != null) {
      final parts = r['waktu_kejadian'].split(':');
      if (parts.length >= 2) {
        _incidentTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
    if (r['lokasi'] != null || r['id_lokasi'] != null) {
      _selectedLocation = {
        'id_lokasi': r['id_lokasi']?.toString(),
        'id_unit': r['id_unit']?.toString(),
        'id_subunit': r['id_subunit']?.toString(),
        'id_area': r['id_area']?.toString(),
        'nama': r['lokasi']?['nama_lokasi'] ?? '',
      };
    }
  }

  // ── Helpers ────────────────────────────────────────────────
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
      backgroundColor: CupertinoColors.destructiveRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _pickDate() async {
    final picked = await showAccidentDatePicker(
      context: context,
      lang: widget.lang,
      initialDate: _incidentDate,
    );
    if (picked != null) setState(() => _incidentDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showAccidentTimePicker(
      context: context,
      lang: widget.lang,
      initialTime: _incidentTime,
    );
    if (picked != null) setState(() => _incidentTime = picked);
  }

  Future<void> _pickCause() async {
    final result = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => AccidentPickCauseScreen(
        lang: widget.lang,
        selectedCause: _selectedCause,
      ),
    );
    if (result != null) setState(() => _selectedCause = result);
  }

  Future<void> _pickSeverity() async {
    final result = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => AccidentPickSeverityScreen(
        lang: widget.lang,
        selectedSeverity: _selectedSeverity,
      ),
    );
    if (result != null) setState(() => _selectedSeverity = result);
  }

  Future<void> _pickAffectedParty() async {
    final user = await showAccidentPickAffectedDialog(
      context,
      lang: widget.lang,
      currentUserId: Supabase.instance.client.auth.currentUser?.id,
      selectedUserId: _selectedVictim?['id_user']?.toString(),
      currentLokasiId: _currentUserLokasiId,
      currentUnitId: _currentUserUnitId,
      currentSubunitId: _currentUserSubunitId,
      currentAreaId: _currentUserAreaId,
    );
    if (user != null) {
      setState(() {
        _selectedVictim = user;
        _victimManualName = null;
        _selectedSupervisor = null;
      });
      await _autoLoadSupervisor(user);
    }
  }

  Future<void> _pickWitness() async {
    final user = await showAccidentPickWitnessDialog(
      context,
      lang: widget.lang,
      currentUserId: Supabase.instance.client.auth.currentUser?.id,
      selectedUserId: _selectedWitness?['id_user']?.toString(),
      currentLokasiId: _currentUserLokasiId,
      currentUnitId: _currentUserUnitId,
      currentSubunitId: _currentUserSubunitId,
      currentAreaId: _currentUserAreaId,
    );
    if (user != null) {
      setState(() {
        _selectedWitness = user;
        _witnessManualName = null;
      });
    }
  }

  Future<void> _autoLoadSupervisor(Map<String, dynamic> victim) async {
    try {
      final victimId = victim['id_user']?.toString();
      if (victimId == null) return;
      final victimData = await Supabase.instance.client
          .from('User')
          .select('id_supervisor, supervisor:id_supervisor(id_user, nama, gambar_user, jabatan!User_id_jabatan_fkey(nama_jabatan))')
          .eq('id_user', victimId)
          .single();
      if (mounted && victimData['supervisor'] != null) {
        setState(() {
          _selectedSupervisor = Map<String, dynamic>.from(victimData['supervisor'] as Map);
        });
      }
    } catch (e) {
      debugPrint('Error auto-load supervisor: $e');
    }
  }

  Future<void> _showLocationPicker() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => AccidentPickLocationScreen(lang: widget.lang),
    );
    if (result != null) {
      setState(() {
        _selectedLocation = result;
        if (result['nama_unit'] != null && result['nama_unit'].toString().isNotEmpty) {
          _deptCtrl.text = result['nama_unit'].toString();
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? result = await Navigator.push<XFile?>(
      context,
      MaterialPageRoute(builder: (_) => const AccidentCameraScreen()),
    );
    if (result != null && mounted) setState(() => _imageFile = result);
    AccidentCameraWarmupService.instance.warmUp();
  }

  // ── Submit ─────────────────────────────────────────────────
  Future<void> _submit() async {
    final List<MissingFieldItem> missing = [];

    if (!_isEdit) {
      final bool victimFilled = _selectedVictim != null ||
          (_victimManualName != null && _victimManualName!.trim().isNotEmpty);
      if (!victimFilled) {
        missing.add(MissingFieldItem(icon: Icons.person_outline, label: t['victim']!));
      }
      final bool witnessFilled = _selectedWitness != null ||
          (_witnessManualName != null && _witnessManualName!.trim().isNotEmpty);
      if (!witnessFilled) {
        missing.add(MissingFieldItem(icon: Icons.visibility_outlined, label: t['witness']!));
      }
    }
    if (_imageFile == null && _existingImageUrl == null) {
      missing.add(MissingFieldItem(icon: Icons.photo_camera_rounded, label: t['photo']!));
    }
    if (_titleCtrl.text.trim().isEmpty) {
      missing.add(MissingFieldItem(icon: Icons.edit_note_rounded, label: t['title_field']!));
    }
    if (_descCtrl.text.trim().isEmpty) {
      missing.add(MissingFieldItem(icon: Icons.description_outlined, label: t['desc']!));
    }
    if (_incidentDate == null) {
      missing.add(MissingFieldItem(icon: Icons.calendar_today_outlined, label: t['date']!));
    }
    if (_incidentTime == null) {
      missing.add(MissingFieldItem(icon: Icons.access_time_rounded, label: t['time']!));
    }
    if (_selectedLocation == null) {
      missing.add(MissingFieldItem(icon: Icons.location_on_outlined, label: t['location']!));
    }
    if (_selectedCause == null) {
      missing.add(MissingFieldItem(icon: Icons.warning_amber_rounded, label: t['cause']!));
    }
    if (_selectedSeverity == null) {
      missing.add(MissingFieldItem(icon: Icons.health_and_safety_outlined, label: t['severity']!));
    }
    if (_deptCtrl.text.trim().isEmpty) {
      missing.add(MissingFieldItem(icon: Icons.business_outlined, label: t['dept']!));
    }
    if (_actionCtrl.text.trim().isEmpty) {
      missing.add(MissingFieldItem(icon: Icons.medical_services_outlined, label: t['action']!));
    }

    if (missing.isNotEmpty) {
      RequiredFieldAlert.show(context, lang: widget.lang, missingFields: missing);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      String? imageUrl = _existingImageUrl;
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        final fileName = '${user.id}/accident_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('temuan_images').uploadBinary(
            fileName, bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'));
        imageUrl = supabase.storage.from('temuan_images').getPublicUrl(fileName);
      }

      final timeStr =
          '${_incidentTime!.hour.toString().padLeft(2, '0')}:${_incidentTime!.minute.toString().padLeft(2, '0')}:00';
      final data = {
        'judul': _titleCtrl.text.trim(),
        'deskripsi': _descCtrl.text.trim(),
        'foto_bukti': imageUrl,
        'tanggal_kejadian': DateFormat('yyyy-MM-dd').format(_incidentDate!),
        'waktu_kejadian': timeStr,
        'id_lokasi': _selectedLocation!['id_lokasi'],
        'id_unit': _selectedLocation!['id_unit'],
        'id_subunit': _selectedLocation!['id_subunit'],
        'id_area': _selectedLocation!['id_area'],
        'penyebab': _selectedCause,
        'tingkat_keparahan': _selectedSeverity,
        'departemen_terdampak': _deptCtrl.text.trim().isEmpty ? null : _deptCtrl.text.trim(),
        'tindakan_diambil': _actionCtrl.text.trim().isEmpty ? null : _actionCtrl.text.trim(),
      };

      if (_isEdit) {
        await supabase.from('accident_report')
            .update({...data, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id_laporan', widget.existingReport!['id_laporan']);
        if (mounted) {
          setState(() => _isSaving = false);
          await showResultPopup(
            context,
            icon: CupertinoIcons.checkmark_circle_fill,
            iconColor: const Color(0xFF16A34A),
            iconBgColor: const Color(0xFFF0FDF4),
            message: t['success_edit']!,
          );
          if (mounted) Navigator.pop(context, true);
        }
      } else {
        final String? victimId = _selectedVictim?['id_user'];
        final String? victimManual = _selectedVictim == null ? _victimManualName?.trim() : null;
        final String? witnessId = _selectedWitness?['id_user'];
        final String? witnessManual = _selectedWitness == null
            ? (_witnessManualName?.trim().isEmpty == true ? null : _witnessManualName?.trim())
            : null;
        await supabase.from('accident_report').insert({
          ...data,
          'id_pelapor': user.id,
          'id_pihak_terdampak': victimId,
          'nama_pihak_terdampak': victimManual,
          'id_supervisor': _selectedSupervisor?['id_user'],
          'id_saksi': witnessId,
          'nama_saksi': witnessManual,
        });
        if (mounted) {
          setState(() => _isSaving = false);
          await showResultPopup(
            context,
            icon: CupertinoIcons.checkmark_circle_fill,
            iconColor: const Color(0xFF16A34A),
            iconBgColor: const Color(0xFFF0FDF4),
            message: t['success']!,
          );
          if (mounted) Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint('Submit error: $e');
      if (mounted) {
        _showError('${t['fail']!}: $e');
        setState(() => _isSaving = false);
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2563EB)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_isEdit ? t['edit_title']! : t['create_title']!,
            style: GoogleFonts.inter(
                color: const Color(0xFF2563EB), fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: CupertinoColors.systemGrey5, height: 1),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isEdit) ...[
                  _buildSectionHeader(t['who_involved']!, t['who_sub']!, CupertinoIcons.person_2_fill),
                  const SizedBox(height: 14),
                  _buildUserPickerWithManual(
                    label: t['victim']!, selectedUser: _selectedVictim,
                    manualName: _victimManualName, placeholder: t['select_victim']!,
                    icon: Icons.person_outline,
                    onPickerTap: _pickAffectedParty,
                    onManualChanged: (val) => setState(() {
                      _victimManualName = val; _selectedVictim = null; _selectedSupervisor = null;
                    }),
                    onClear: () => setState(() {
                      _selectedVictim = null; _victimManualName = null; _selectedSupervisor = null;
                    }),
                  ),
                  const SizedBox(height: 10),
                  _buildSupervisorCard(),
                  const SizedBox(height: 10),
                  _buildUserPickerWithManual(
                    label: t['witness']!, selectedUser: _selectedWitness,
                    manualName: _witnessManualName, placeholder: t['select_witness']!,
                    icon: Icons.visibility_outlined,
                    onPickerTap: _pickWitness,
                    onManualChanged: (val) => setState(() { _witnessManualName = val; _selectedWitness = null; }),
                    onClear: () => setState(() { _selectedWitness = null; _witnessManualName = null; }),
                  ),
                  const SizedBox(height: 24),
                ],
                _buildSectionHeader(t['detail_title']!, t['detail_sub']!, CupertinoIcons.doc_text_fill),
                const SizedBox(height: 14),
                _buildSectionCard(children: [
                  _buildLabel(t['photo']!, icon: Icons.photo_camera_rounded),
                  _buildPhotoWidget(),
                ]),
                const SizedBox(height: 16),
                _buildSectionCard(children: [
                  _buildLabel(t['title_field']!, icon: Icons.edit_note_rounded),
                  _buildTextField(_titleCtrl, t['title_hint']!),
                  const SizedBox(height: 16),
                  _buildLabel(t['desc']!, icon: Icons.description_outlined),
                  _buildTextField(_descCtrl, t['desc_hint']!, maxLines: 4),
                ]),
                const SizedBox(height: 16),
                _buildSectionCard(children: [
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _buildLabel(t['date']!, icon: Icons.calendar_today_outlined),
                      _buildTapField(
                        text: _incidentDate != null ? DateFormat('dd/MM/yyyy').format(_incidentDate!) : t['pick_date']!,
                        hasValue: _incidentDate != null, onTap: _pickDate,
                      ),
                    ])),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _buildLabel(t['time']!, icon: Icons.access_time_rounded),
                      _buildTapField(
                        text: _incidentTime != null ? _incidentTime!.format(context) : t['pick_time']!,
                        hasValue: _incidentTime != null, onTap: _pickTime,
                      ),
                    ])),
                  ]),
                ]),
                const SizedBox(height: 16),
                _buildSectionCard(children: [
                  _buildLabel(t['location']!, icon: Icons.location_on_outlined),
                  _buildLocationTapField(),
                  const SizedBox(height: 16),
                  _buildLabel(t['cause']!, icon: Icons.warning_amber_rounded),
                  _buildCauseTapField(),
                  const SizedBox(height: 16),
                  _buildLabel(t['severity']!, icon: Icons.health_and_safety_outlined),
                  _buildSeverityTapField(),
                ]),
                const SizedBox(height: 16),
                _buildSectionCard(children: [
                  _buildLabel(t['dept']!, icon: Icons.business_outlined),
                  _buildTextField(_deptCtrl, t['dept_hint']!),
                  const SizedBox(height: 16),
                  _buildLabel(t['action']!, icon: Icons.medical_services_outlined),
                  _buildTextField(_actionCtrl, t['action_hint']!, maxLines: 3),
                ]),
              ],
            ),
          ),
          if (_isSaving) _buildLoadingOverlay(),
        ],
      ),
      bottomNavigationBar: _isSaving
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, _bottomSafeSpacing(context)),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: CupertinoColors.systemGrey5, width: 1)),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withValues(alpha:0.4), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(_isEdit ? t['update']! : t['submit']!,
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
    );
  }

  double _bottomSafeSpacing(BuildContext context) {
    final double navInset = MediaQuery.of(context).padding.bottom;
    return navInset > 0 ? navInset + 16 : 28;
  }

  // ── UI Helpers ─────────────────────────────────────────────
  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha:0.12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15, color: const Color(0xFF1E293B))),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
        ])),
      ]),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E7FF), width: 1),
        boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withValues(alpha:0.05), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildLabel(String label, {required IconData icon, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Row(children: [
        Icon(icon, size: 16, color: const Color(0xFF1D72F3)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF1D72F3))),
        if (required)
          const Text(' *', style: TextStyle(color: CupertinoColors.destructiveRed, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return TextFormField(
      controller: ctrl, maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 15),
        filled: true, fillColor: const Color(0xFFF8FAFF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E7FF), width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildTapField({required String text, required VoidCallback onTap, bool hasValue = false, Color? severityColor}) {
    final activeColor = severityColor ?? const Color(0xFF2563EB);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasValue ? activeColor : const Color(0xFFE0E7FF), width: hasValue ? 1.5 : 1),
        ),
        child: Row(children: [
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 15, color: hasValue ? Colors.black87 : const Color(0xFFCBD5E1), fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal))),
          Icon(CupertinoIcons.chevron_down, color: const Color(0xFF2563EB), size: 18),
        ]),
      ),
    );
  }

  Widget _buildCauseTapField() {
    final hasValue = _selectedCause != null;
    final Color activeColor =
        hasValue ? AccidentCauseData.colorOf(_selectedCause) : const Color(0xFF2563EB);
    final IconData activeIcon =
        hasValue ? AccidentCauseData.iconOf(_selectedCause) : Icons.warning_amber_rounded;
    final String label =
        hasValue ? AccidentCauseData.labelOf(_selectedCause, widget.lang) : t['pick_cause']!;

    return GestureDetector(
      onTap: _pickCause,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? activeColor : const Color(0xFFE0E7FF),
            width: hasValue ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          if (hasValue) ...[
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(activeIcon, color: activeColor, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: hasValue ? Colors.black87 : const Color(0xFFCBD5E1),
                fontWeight: hasValue ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
          const Icon(CupertinoIcons.chevron_down, color: Color(0xFF2563EB), size: 18),
        ]),
      ),
    );
  }

  Widget _buildSeverityTapField() {
    final hasValue = _selectedSeverity != null;
    final Color activeColor =
        hasValue ? AccidentSeverityData.colorOf(_selectedSeverity) : const Color(0xFF2563EB);
    final IconData activeIcon =
        hasValue ? AccidentSeverityData.iconOf(_selectedSeverity) : Icons.health_and_safety_outlined;
    final String label =
        hasValue ? AccidentSeverityData.labelOf(_selectedSeverity, widget.lang) : t['pick_severity']!;

    return GestureDetector(
      onTap: _pickSeverity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? activeColor : const Color(0xFFE0E7FF),
            width: hasValue ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          if (hasValue) ...[
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(activeIcon, color: activeColor, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: hasValue ? Colors.black87 : const Color(0xFFCBD5E1),
                fontWeight: hasValue ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
          const Icon(CupertinoIcons.chevron_down, color: Color(0xFF2563EB), size: 18),
        ]),
      ),
    );
  }

  static const List<IconData> _locLevelIcons = [
    Icons.location_city_rounded,
    Icons.business_rounded,
    Icons.layers_outlined,
    Icons.place_rounded,
  ];
  static const List<Color> _locLevelColors = [
    Color(0xFF10B981),
    Color(0xFF6366F1),
    Color(0xFFFBBF24),
    Color(0xFFF472B6),
  ];

  Widget _buildLocationTapField() {
    final hasValue = _selectedLocation != null;
    final int level = (_selectedLocation?['level'] is int) ? _selectedLocation!['level'] as int : 0;
    final String specific = _selectedLocation?['nama_spesifik']?.toString() ??
        _selectedLocation?['nama']?.toString() ?? '';
    final String fullPath = _selectedLocation?['nama']?.toString() ?? '';
    final Color activeColor = hasValue ? _locLevelColors[level] : const Color(0xFF2563EB);
    final IconData activeIcon = hasValue ? _locLevelIcons[level] : Icons.location_on_outlined;

    return GestureDetector(
      onTap: _showLocationPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasValue ? activeColor : const Color(0xFFE0E7FF), width: hasValue ? 1.5 : 1),
        ),
        child: hasValue
            ? Row(children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(color: activeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(activeIcon, color: activeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(specific,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
                      if (fullPath.isNotEmpty && fullPath != specific) ...[
                        const SizedBox(height: 2),
                        Text(fullPath,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF94A3B8))),
                      ],
                    ],
                  ),
                ),
                const Icon(CupertinoIcons.chevron_down, color: Color(0xFF2563EB), size: 18),
              ])
            : Row(children: [
                Expanded(child: Text(t['pick_location']!,
                    style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFFCBD5E1)))),
                const Icon(CupertinoIcons.chevron_down, color: Color(0xFF2563EB), size: 18),
              ]),
      ),
    );
  }

  Widget _buildSupervisorCard() {
    final hasValue = _selectedSupervisor != null;
    final String displayText = hasValue
        ? (_selectedSupervisor!['nama'] ?? '-')
        : (widget.lang == 'EN'
            ? 'Not yet available (select affected party first)'
            : widget.lang == 'ZH'
                ? '暂无数据（请先选择受影响方）'
                : 'Belum tersedia (pilih pihak terdampak terlebih dahulu)');

    return _buildSectionCard(children: [
      _buildLabel(t['supervisor']!, icon: Icons.supervisor_account_outlined, required: false),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? const Color(0xFF16A34A).withValues(alpha: 0.4) : const Color(0xFFE0E7FF),
            width: hasValue ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Expanded(
            child: Text(
              displayText,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: hasValue ? Colors.black87 : const Color(0xFFCBD5E1),
                fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          if (hasValue)
            const Icon(CupertinoIcons.checkmark_circle_fill, color: Color(0xFF16A34A), size: 18),
        ]),
      ),
    ]);
  }

  Widget _buildUserPickerWithManual({
    required String label, required Map<String, dynamic>? selectedUser,
    required String? manualName, required String placeholder, required IconData icon,
    required VoidCallback onPickerTap,
    required ValueChanged<String> onManualChanged, required VoidCallback onClear,
  }) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E7FF), width: 1),
        boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withValues(alpha:0.05), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildLabel(label, icon: icon),
        if (selectedUser != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2563EB), width: 1.5)),
            child: Row(children: [
              Expanded(child: Text(selectedUser['nama'] ?? '-', style: GoogleFonts.inter(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500))),
              GestureDetector(onTap: onClear, child: const Icon(CupertinoIcons.xmark_circle_fill, color: Color(0xFF94A3B8), size: 20)),
            ]),
          )
        else ...[
          TextFormField(
            initialValue: manualName, onChanged: onManualChanged,
            style: GoogleFonts.inter(fontSize: 15, color: Colors.black87),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 15),
              filled: true, fillColor: const Color(0xFFF8FAFF),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E7FF), width: 1)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onPickerTap,
            child: Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF), borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(CupertinoIcons.person_badge_plus, color: Color(0xFF2563EB), size: 16),
                const SizedBox(width: 8),
                Text(
                  widget.lang == 'EN' ? 'Or select from member list' : widget.lang == 'ZH' ? '或从成员列表选择' : 'Atau pilih dari daftar anggota',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB)),
                ),
              ]),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildPhotoWidget() {
    final hasPhoto = _imageFile != null || _existingImageUrl != null;
    if (!hasPhoto) {
      return GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 160, width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E7FF), width: 1.5),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.camera, color: Color(0xFF2563EB), size: 28),
            ),
            const SizedBox(height: 12),
            Text(t['add_photo']!, style: GoogleFonts.inter(color: const Color(0xFF2563EB), fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
        ),
      );
    }
    return Stack(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _imageFile != null
            ? (kIsWeb
                ? Image.network(_imageFile!.path, height: 200, width: double.infinity, fit: BoxFit.cover)
                : Image.file(File(_imageFile!.path), height: 200, width: double.infinity, fit: BoxFit.cover))
            : Image.network(_existingImageUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
      ),
      Positioned(
        right: 12, bottom: 12,
        child: GestureDetector(
          onTap: _pickImage,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha:0.6), borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const Icon(CupertinoIcons.camera_rotate, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text(widget.lang == 'EN' ? 'Retake' : 'Ganti',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha:0.45),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withValues(alpha:0.2), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.health_and_safety_outlined, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            const CupertinoActivityIndicator(radius: 12, color: Color(0xFF2563EB)),
            const SizedBox(height: 14),
            Text(t['saving']!, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
            const SizedBox(height: 6),
            Text(
              _isEdit
                  ? (widget.lang == 'EN' ? 'Updating your report...' : widget.lang == 'ZH' ? '正在更新报告...' : 'Memperbarui laporan Anda...')
                  : (widget.lang == 'EN' ? 'Uploading & saving report...' : widget.lang == 'ZH' ? '正在上传并保存...' : 'Mengunggah & menyimpan laporan...'),
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      ),
    );
  }
}