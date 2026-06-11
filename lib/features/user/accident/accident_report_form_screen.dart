import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shimmer/shimmer.dart';

import 'accident_result_popup.dart';

// ============================================================
// LAYAR FORM LAPORAN KECELAKAAN (CREATE & EDIT)
// ============================================================
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
      'select_supervisor': 'Pilih Supervisor',
      'supervisor_hint': 'Pilih pihak terdampak terlebih dahulu',
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
      'pick_cause': 'Pilih Penyebab',
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
      'select_supervisor': 'Select Supervisor',
      'supervisor_hint': 'Please select affected party first',
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
      'pick_cause': 'Select Cause',
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
      'supervisor': '主管',
      'select_supervisor': '选择主管',
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
      'pick_cause': '选择原因',
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

  static const List<Map<String, String>> _causesID = [
    {'key': 'Mesin', 'desc': 'Kecelakaan karena terjebak di alat'},
    {'key': 'Benda Berat', 'desc': 'Kecelakaan karena terbentur objek berat'},
    {'key': 'Kendaraan / Alat Angkut', 'desc': 'Kecelakaan karena alat transportasi'},
    {'key': 'Jatuh', 'desc': 'Kecelakaan karena jatuh dari ketinggian'},
    {'key': 'Listrik', 'desc': 'Kecelakaan karena kejutan listrik'},
    {'key': 'Panas / Api', 'desc': 'Kecelakaan karena objek panas'},
    {'key': 'Perkakas', 'desc': 'Kecelakaan karena peralatan kerja'},
    {'key': 'Benda Tajam', 'desc': 'Kecelakaan karena tergores benda tajam'},
    {'key': 'Bahan Kimia', 'desc': 'Kecelakaan karena bahan kimia berbahaya'},
    {'key': 'Lainnya', 'desc': 'Penyebab kecelakaan lainnya'},
  ];

  static const List<Map<String, dynamic>> _severities = [
    {'key': 'Ringan', 'desc': 'Cedera Tanpa Kehilangan Waktu Kerja', 'color': 0xFF16A34A},
    {'key': 'Menengah', 'desc': 'Cedera Kehilangan Waktu Kerja', 'color': 0xFFF97316},
    {'key': 'Berat', 'desc': 'Cedera Berat atau Fatality', 'color': 0xFFDC2626},
  ];

  // ── Lifecycle ──────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadCurrentUserLokasi();
    if (_isEdit) _populateData();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _deptCtrl.dispose();
    _actionCtrl.dispose();
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

  Color _severityColorFrom(String? key) {
    final s = _severities.firstWhere(
      (e) => e['key'] == key,
      orElse: () => {'color': 0xFF2563EB},
    );
    return Color(s['color'] as int);
  }

  // ── Pickers ────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _incidentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB), onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _incidentDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _incidentTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB), onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _incidentTime = picked);
  }

  void _showCausePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (_, ctrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey4,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(t['pick_cause']!,
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: const Color(0xFF2563EB))),
            ),
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _causesID.length,
                itemBuilder: (_, i) {
                  final c = _causesID[i];
                  final isSelected = _selectedCause == c['key'];
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCause = c['key']);
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE0E7FF),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['key']!,
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700, fontSize: 14,
                                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1E293B))),
                          const SizedBox(height: 3),
                          Text(c['desc']!,
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: const Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSeverityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(t['pick_severity']!,
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB))),
          ),
          ...(_severities.map((s) {
            final color = Color(s['color'] as int);
            return GestureDetector(
              onTap: () {
                setState(() => _selectedSeverity = s['key']);
                Navigator.pop(context);
              },
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['key'],
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700, fontSize: 14, color: color)),
                          Text(s['desc'],
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: const Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                    if (_selectedSeverity == s['key'])
                      Icon(CupertinoIcons.check_mark, color: color, size: 16),
                  ],
                ),
              ),
            );
          })).toList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _showUserPicker({
    required String role,
    required Function(Map<String, dynamic>) onSelected,
  }) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AccidentUserPickerSheet(
        lang: widget.lang,
        role: role,
        filterLokasiId: (role == 'victim' || role == 'witness') ? _currentUserLokasiId : null,
        filterUnitId: (role == 'victim' || role == 'witness') ? _currentUserUnitId : null,
        filterSubunitId: (role == 'victim' || role == 'witness') ? _currentUserSubunitId : null,
        filterAreaId: (role == 'victim' || role == 'witness') ? _currentUserAreaId : null,
        onSelected: (u) async {
          onSelected(u);
          if (role == 'victim') await _autoLoadSupervisor(u);
        },
      ),
    );
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
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccidentLocationPicker(lang: widget.lang),
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
    final picker = ImagePicker();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
            ),
            Text(
              widget.lang == 'EN' ? 'Add Evidence Photo' : widget.lang == 'ZH' ? '添加证据照片' : 'Tambah Foto Bukti',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 20),
            _buildImageSourceTile(
              icon: CupertinoIcons.camera_fill,
              color: const Color(0xFF2563EB),
              title: widget.lang == 'EN' ? 'Take Photo' : widget.lang == 'ZH' ? '拍照' : 'Ambil Foto',
              subtitle: widget.lang == 'EN' ? 'Open camera directly' : widget.lang == 'ZH' ? '直接打开相机' : 'Buka kamera langsung',
              bgColor: const Color(0xFFEFF6FF),
              borderColor: const Color(0xFFE0E7FF),
              onTap: () async {
                Navigator.pop(context);
                final img = await Navigator.push<XFile?>(
                  context,
                  MaterialPageRoute(builder: (_) => const AccidentCameraScreen()),
                );
                if (img != null && mounted) setState(() => _imageFile = img);
              },
            ),
            const SizedBox(height: 12),
            _buildImageSourceTile(
              icon: CupertinoIcons.photo_fill_on_rectangle_fill,
              color: const Color(0xFF1D4ED8),
              title: widget.lang == 'EN' ? 'Choose from Gallery' : widget.lang == 'ZH' ? '从相册选择' : 'Pilih dari Galeri',
              subtitle: widget.lang == 'EN' ? 'Select existing photo' : widget.lang == 'ZH' ? '选择现有照片' : 'Pilih foto yang sudah ada',
              bgColor: const Color(0xFFF8FAFF),
              borderColor: const Color(0xFFE0E7FF),
              onTap: () async {
                Navigator.pop(context);
                final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                if (img != null && mounted) setState(() => _imageFile = img);
              },
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
                child: Center(
                  child: Text(t['cancel']!,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF64748B))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF1E293B))),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
              ],
            ),
            const Spacer(),
            const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFF2563EB)),
          ],
        ),
      ),
    );
  }

  // ── Submit ─────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) { _showError(t['err_title']!); return; }
    final bool victimFilled = _selectedVictim != null ||
        (_victimManualName != null && _victimManualName!.trim().isNotEmpty);
    if (!victimFilled && !_isEdit) { _showError(t['err_victim']!); return; }
    if (_descCtrl.text.trim().isEmpty) { _showError(t['err_desc']!); return; }
    if (_incidentDate == null) { _showError(t['err_date']!); return; }
    if (_incidentTime == null) { _showError(t['err_time']!); return; }
    if (_selectedLocation == null) { _showError(t['err_location']!); return; }
    if (_selectedCause == null) { _showError(t['err_cause']!); return; }
    if (_selectedSeverity == null) { _showError(t['err_severity']!); return; }
    if (_imageFile == null && _existingImageUrl == null) { _showError(t['err_photo']!); return; }

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
                    icon: CupertinoIcons.person_fill, isRequired: true,
                    onPickerTap: () => _showUserPicker(
                      role: 'victim',
                      onSelected: (u) => setState(() {
                        _selectedVictim = u; _victimManualName = null; _selectedSupervisor = null;
                      }),
                    ),
                    onManualChanged: (val) => setState(() {
                      _victimManualName = val; _selectedVictim = null; _selectedSupervisor = null;
                    }),
                    onClear: () => setState(() {
                      _selectedVictim = null; _victimManualName = null; _selectedSupervisor = null;
                    }),
                  ),
                  const SizedBox(height: 10),
                  _buildUserPickerCard(
                    label: t['supervisor']!,
                    value: _selectedSupervisor?['nama'],
                    placeholder: (_selectedVictim == null && (_victimManualName == null || _victimManualName!.trim().isEmpty))
                        ? t['supervisor_hint']! : t['select_supervisor']!,
                    icon: CupertinoIcons.person_badge_plus,
                    isRequired: false,
                    isLocked: _selectedVictim == null && (_victimManualName == null || _victimManualName!.trim().isEmpty),
                    onTap: (_selectedVictim == null && (_victimManualName == null || _victimManualName!.trim().isEmpty))
                        ? null
                        : () => _showUserPicker(
                              role: 'supervisor',
                              onSelected: (u) => setState(() => _selectedSupervisor = u),
                            ),
                  ),
                  const SizedBox(height: 10),
                  _buildUserPickerWithManual(
                    label: t['witness']!, selectedUser: _selectedWitness,
                    manualName: _witnessManualName, placeholder: t['select_witness']!,
                    icon: CupertinoIcons.eye_fill, isRequired: false,
                    onPickerTap: () => _showUserPicker(
                      role: 'witness',
                      onSelected: (u) => setState(() { _selectedWitness = u; _witnessManualName = null; }),
                    ),
                    onManualChanged: (val) => setState(() { _witnessManualName = val; _selectedWitness = null; }),
                    onClear: () => setState(() { _selectedWitness = null; _witnessManualName = null; }),
                  ),
                  const SizedBox(height: 24),
                ],
                _buildSectionHeader(t['detail_title']!, t['detail_sub']!, CupertinoIcons.doc_text_fill),
                const SizedBox(height: 14),
                _buildSectionCard(children: [
                  _buildLabel(t['photo']!, isRequired: true),
                  _buildPhotoWidget(),
                ]),
                const SizedBox(height: 16),
                _buildSectionCard(children: [
                  _buildLabel(t['title_field']!, isRequired: true),
                  _buildTextField(_titleCtrl, t['title_hint']!, CupertinoIcons.text_cursor),
                  const SizedBox(height: 16),
                  _buildLabel(t['desc']!, isRequired: true),
                  _buildTextField(_descCtrl, t['desc_hint']!, CupertinoIcons.doc_text, maxLines: 4),
                ]),
                const SizedBox(height: 16),
                _buildSectionCard(children: [
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _buildLabel(t['date']!, isRequired: true),
                      _buildTapField(
                        icon: CupertinoIcons.calendar,
                        text: _incidentDate != null ? DateFormat('dd/MM/yyyy').format(_incidentDate!) : t['pick_date']!,
                        hasValue: _incidentDate != null, onTap: _pickDate,
                      ),
                    ])),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _buildLabel(t['time']!, isRequired: true),
                      _buildTapField(
                        icon: CupertinoIcons.clock_fill,
                        text: _incidentTime != null ? _incidentTime!.format(context) : t['pick_time']!,
                        hasValue: _incidentTime != null, onTap: _pickTime,
                      ),
                    ])),
                  ]),
                ]),
                const SizedBox(height: 16),
                _buildSectionCard(children: [
                  _buildLabel(t['location']!, isRequired: true),
                  _buildTapField(
                    icon: CupertinoIcons.location_fill,
                    text: _selectedLocation?['nama'] ?? t['pick_location']!,
                    hasValue: _selectedLocation != null, onTap: _showLocationPicker,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel(t['cause']!, isRequired: true),
                  _buildTapField(
                    icon: CupertinoIcons.exclamationmark_triangle_fill,
                    text: _selectedCause ?? t['pick_cause']!,
                    hasValue: _selectedCause != null, onTap: _showCausePicker,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel(t['severity']!, isRequired: true),
                  _buildTapField(
                    icon: Icons.health_and_safety_outlined,
                    text: _selectedSeverity ?? t['pick_severity']!,
                    hasValue: _selectedSeverity != null, onTap: _showSeverityPicker,
                    severityColor: _selectedSeverity != null ? _severityColorFrom(_selectedSeverity) : null,
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSectionCard(children: [
                  _buildLabel(t['dept']!, isRequired: false),
                  _buildTextField(_deptCtrl, t['dept_hint']!, CupertinoIcons.building_2_fill),
                  const SizedBox(height: 16),
                  _buildLabel(t['action']!, isRequired: false),
                  _buildTextField(_actionCtrl, t['action_hint']!, CupertinoIcons.bandage_fill, maxLines: 3),
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: CupertinoColors.systemGrey5, width: 1)),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
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
              color: const Color(0xFF2563EB).withOpacity(0.12),
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
        boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Row(children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF475569))),
        if (isRequired) const Text(' *', style: TextStyle(color: CupertinoColors.destructiveRed, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: ctrl, maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 15),
        prefixIcon: maxLines == 1 ? Icon(icon, color: const Color(0xFF2563EB), size: 20) : null,
        filled: true, fillColor: const Color(0xFFF8FAFF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E7FF), width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildTapField({required IconData icon, required String text, required VoidCallback onTap, bool hasValue = false, Color? severityColor}) {
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
          Icon(icon, color: hasValue ? activeColor : const Color(0xFFCBD5E1), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 15, color: hasValue ? Colors.black87 : const Color(0xFFCBD5E1), fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal))),
          Icon(CupertinoIcons.chevron_down, color: const Color(0xFF2563EB), size: 18),
        ]),
      ),
    );
  }

  Widget _buildUserPickerCard({
    required String label, required String? value, required String placeholder,
    required IconData icon, required bool isRequired, VoidCallback? onTap, bool isLocked = false,
  }) {
    return _buildSectionCard(children: [
      _buildLabel(label, isRequired: isRequired),
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: value != null ? const Color(0xFF2563EB) : const Color(0xFFE0E7FF), width: value != null ? 1.5 : 1),
          ),
          child: Row(children: [
            Icon(icon, color: isLocked ? const Color(0xFFCBD5E1) : value != null ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1), size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(value ?? placeholder,
                style: GoogleFonts.inter(fontSize: 15, color: value != null ? Colors.black87 : const Color(0xFFCBD5E1), fontWeight: value != null ? FontWeight.w500 : FontWeight.normal))),
            isLocked
                ? const Icon(CupertinoIcons.lock_fill, color: Color(0xFFCBD5E1), size: 18)
                : const Icon(CupertinoIcons.chevron_forward, color: Color(0xFF2563EB), size: 18),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildUserPickerWithManual({
    required String label, required Map<String, dynamic>? selectedUser,
    required String? manualName, required String placeholder, required IconData icon,
    required bool isRequired, required VoidCallback onPickerTap,
    required ValueChanged<String> onManualChanged, required VoidCallback onClear,
  }) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E7FF), width: 1),
        boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildLabel(label, isRequired: isRequired),
        if (selectedUser != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2563EB), width: 1.5)),
            child: Row(children: [
              Icon(icon, color: const Color(0xFF2563EB), size: 20),
              const SizedBox(width: 12),
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
              prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 20),
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
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
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
      color: Colors.black.withOpacity(0.45),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10))],
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

// ============================================================
// WIDGET PEMILIH USER
// ============================================================
class _AccidentUserPickerSheet extends StatefulWidget {
  final String lang;
  final String role;
  final Function(Map<String, dynamic>) onSelected;
  final String? filterLokasiId;
  final String? filterUnitId;
  final String? filterSubunitId;
  final String? filterAreaId;

  const _AccidentUserPickerSheet({
    required this.lang, required this.role, required this.onSelected,
    this.filterLokasiId, this.filterUnitId, this.filterSubunitId, this.filterAreaId,
  });

  @override
  State<_AccidentUserPickerSheet> createState() => _AccidentUserPickerSheetState();
}

class _AccidentUserPickerSheetState extends State<_AccidentUserPickerSheet> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() {
        _filtered = _users.where((u) => u['nama'].toString().toLowerCase().contains(q)).toList();
      });
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _fetchUsers() async {
    try {
      final hasFilter = widget.filterLokasiId != null || widget.filterUnitId != null ||
          widget.filterSubunitId != null || widget.filterAreaId != null;
      List<Map<String, dynamic>> result = [];
      const cols = 'id_user, nama, jabatan!User_id_jabatan_fkey(nama_jabatan), gambar_user, id_lokasi, id_unit, id_subunit, id_area';
      final q = Supabase.instance.client.from('User').select(cols);

      if (hasFilter) {
        if (widget.filterAreaId != null) {
          result = List<Map<String, dynamic>>.from(await q.eq('id_area', widget.filterAreaId!).order('nama'));
        }
        if (result.isEmpty && widget.filterSubunitId != null) {
          result = List<Map<String, dynamic>>.from(await q.eq('id_subunit', widget.filterSubunitId!).order('nama'));
        }
        if (result.isEmpty && widget.filterUnitId != null) {
          result = List<Map<String, dynamic>>.from(await q.eq('id_unit', widget.filterUnitId!).order('nama'));
        }
        if (result.isEmpty && widget.filterLokasiId != null) {
          result = List<Map<String, dynamic>>.from(await q.eq('id_lokasi', widget.filterLokasiId!).order('nama'));
        }
      } else {
        result = List<Map<String, dynamic>>.from(await q.order('nama'));
      }

      if (mounted) setState(() { _users = result; _filtered = result; _isLoading = false; });
    } catch (e) {
      debugPrint('Error fetching users: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _roleTitle {
    switch (widget.role) {
      case 'victim': return widget.lang == 'EN' ? 'Select Affected Party' : widget.lang == 'ZH' ? '选择受影响方' : 'Pilih Pihak Terdampak';
      case 'supervisor': return widget.lang == 'EN' ? 'Select Supervisor' : widget.lang == 'ZH' ? '选择主管' : 'Pilih Supervisor';
      case 'witness': return widget.lang == 'EN' ? 'Select Witness' : widget.lang == 'ZH' ? '选择目击者' : 'Pilih Saksi';
      default: return widget.lang == 'EN' ? 'Select User' : 'Pilih Pengguna';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 4,
            decoration: BoxDecoration(color: CupertinoColors.systemGrey4, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            Expanded(child: Text(_roleTitle, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)))),
            IconButton(icon: const Icon(CupertinoIcons.xmark, color: Color(0xFF94A3B8), size: 20), onPressed: () => Navigator.pop(context)),
          ]),
        ),
        if (widget.filterLokasiId != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFBFDBFE))),
              child: Row(children: [
                const Icon(CupertinoIcons.location_fill, size: 13, color: Color(0xFF2563EB)),
                const SizedBox(width: 6),
                Text(
                  widget.lang == 'EN' ? 'Showing users from your location' : 'Menampilkan pengguna di lokasi Anda',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF2563EB), fontWeight: FontWeight.w500),
                ),
              ]),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: TextFormField(
            controller: _searchCtrl,
            style: GoogleFonts.inter(fontSize: 15),
            decoration: InputDecoration(
              hintText: widget.lang == 'EN' ? 'Search...' : widget.lang == 'ZH' ? '搜索...' : 'Cari...',
              hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1)),
              prefixIcon: const Icon(CupertinoIcons.search, color: Color(0xFF2563EB), size: 20),
              filled: true, fillColor: const Color(0xFFF8FAFF),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFE0E7FF))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('${_filtered.length} ${widget.lang == 'EN' ? 'users found' : 'pengguna ditemukan'}',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator(radius: 14, color: Color(0xFF2563EB)))
              : _filtered.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(CupertinoIcons.person_crop_circle_badge_xmark, size: 48, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 12),
                      Text(widget.lang == 'EN' ? 'No users found' : 'Tidak ada pengguna',
                          style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14)),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final u = _filtered[i];
                        final name = u['nama'] ?? '';
                        final role = u['jabatan']?['nama_jabatan'] ?? '';
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () { widget.onSelected(u); Navigator.pop(context); },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF1F5F9))),
                              child: Row(children: [
                                CircleAvatar(
                                  radius: 20, backgroundColor: const Color(0xFFEFF6FF),
                                  backgroundImage: u['gambar_user'] != null ? NetworkImage(u['gambar_user']) : null,
                                  child: u['gambar_user'] == null
                                      ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                          style: GoogleFonts.inter(color: const Color(0xFF2563EB), fontWeight: FontWeight.bold))
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1E293B))),
                                  if (role.isNotEmpty) Text(role, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                                ])),
                                const Icon(CupertinoIcons.chevron_right, size: 14, color: Color(0xFFCBD5E1)),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}

// ============================================================
// PEMILIH LOKASI — FIXED VERSION
// ============================================================
class _AccidentLocationPicker extends StatefulWidget {
  final String lang;
  const _AccidentLocationPicker({required this.lang});

  @override
  State<_AccidentLocationPicker> createState() => _AccidentLocationPickerState();
}

class _AccidentLocationPickerState extends State<_AccidentLocationPicker> {
  int _level = 0;
  bool _isLoading = true;
  List<dynamic> _data = [];
  List<dynamic> _filtered = [];

  // History menyimpan item yang dipilih di setiap level
  // [{level, id, name, idKey}]
  final List<Map<String, dynamic>> _history = [];

  final _searchCtrl = TextEditingController();

  static const _tables = ['lokasi', 'unit', 'subunit', 'area'];
  static const _idCols = ['id_lokasi', 'id_unit', 'id_subunit', 'id_area'];
  static const _namCols = ['nama_lokasi', 'nama_unit', 'nama_subunit', 'nama_area'];
  static const _parentCols = ['', 'id_lokasi', 'id_unit', 'id_subunit']; // FK ke parent

  String get _nameCol => _namCols[_level];
  String get _idCol => _idCols[_level];

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase().trim();
    if (!mounted) return;
    setState(() {
      _filtered = q.isEmpty ? List.from(_data) : _data.where((item) => item[_nameCol].toString().toLowerCase().contains(q)).toList();
    });
  }

  // FIX: Terima parentId dan targetLevel sebagai parameter eksplisit
  // agar tidak bergantung pada state _level yang bisa berubah async
  Future<void> _fetch({String? parentId, int? targetLevel}) async {
    final level = targetLevel ?? _level;

    if (!mounted) return;
    setState(() { _isLoading = true; _data = []; _filtered = []; });

    // Bersihkan search tanpa memicu onSearch di tengah loading
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.clear();
    _searchCtrl.addListener(_onSearch);

    try {
      final supabase = Supabase.instance.client;
      final cols = '${_idCols[level]}, ${_namCols[level]}';
      List<dynamic> data = [];

      if (level == 0) {
        data = await supabase.from(_tables[level]).select(cols).order(_namCols[level]);
      } else {
        data = await supabase.from(_tables[level]).select(cols).eq(_parentCols[level], parentId!).order(_namCols[level]);
      }

      if (mounted) {
        setState(() { _data = data; _filtered = List.from(data); _isLoading = false; });
      }
    } catch (e) {
      debugPrint('Location fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // FIX: Simpan parentId di history agar _goBack bisa fetch dengan benar
  // Simpan id item yang DIPILIH (bukan yang akan jadi parent)
  void _goDeeper(Map<String, dynamic> item) {
    if (_level >= 3) return;

    // Capture semua nilai SEBELUM level berubah
    final currentLevel = _level;
    final itemId = item[_idCols[currentLevel]]?.toString();
    final itemName = item[_namCols[currentLevel]]?.toString() ?? '';

    // Simpan ke history: id item yang dipilih adalah parentId untuk level berikutnya
    _history.add({'level': currentLevel, 'id': itemId, 'name': itemName});

    final nextLevel = currentLevel + 1;
    setState(() => _level = nextLevel);

    // Fetch dengan parentId = id item yang baru dipilih, targetLevel eksplisit
    _fetch(parentId: itemId, targetLevel: nextLevel);
  }

  void _select(Map<String, dynamic> item) {
    final result = <String, dynamic>{};

    // Masukkan semua id dari history
    for (final h in _history) {
      result[_idCols[h['level'] as int]] = h['id'];
    }
    // Masukkan id item yang dipilih sekarang
    result[_idCol] = item[_idCol]?.toString();

    // Nama gabungan
    final parts = [..._history.map((h) => h['name'] as String), item[_nameCol].toString()];
    result['nama'] = parts.join(' / ');

    // Auto-fill nama_unit untuk departemen
    if (_history.length >= 2) {
      // level 1 ada di history index 1
      result['nama_unit'] = _history[1]['name'];
    } else if (_history.length == 1) {
      result['nama_unit'] = _history[0]['name'];
    } else if (_level == 1) {
      result['nama_unit'] = item[_nameCol].toString();
    }

    Navigator.pop(context, result);
  }

  void _goBack() {
    if (_history.isEmpty) { Navigator.pop(context); return; }

    _history.removeLast();
    final prevLevel = _level - 1;
    setState(() => _level = prevLevel);

    if (_history.isEmpty) {
      _fetch(targetLevel: 0);
    } else {
      // parentId untuk level ini = id item di history terakhir
      _fetch(parentId: _history.last['id']?.toString(), targetLevel: prevLevel);
    }
  }

  void _jumpToLevel(int targetLevel) {
    if (targetLevel == _level || targetLevel > _level) return;

    while (_history.length > targetLevel) { _history.removeLast(); }
    setState(() => _level = targetLevel);

    if (_history.isEmpty) {
      _fetch(targetLevel: 0);
    } else {
      _fetch(parentId: _history.last['id']?.toString(), targetLevel: targetLevel);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lvlLabels = {
      'EN': ['Location', 'Unit', 'Sub-Unit', 'Area'],
      'ID': ['Lokasi', 'Unit', 'Sub-Unit', 'Area'],
      'ZH': ['地点', '单位', '子单位', '区域'],
    };
    final labels = lvlLabels[widget.lang] ?? lvlLabels['ID']!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        // Drag handle
        Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 4,
            decoration: BoxDecoration(color: CupertinoColors.systemGrey4, borderRadius: BorderRadius.circular(2))),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(children: [
            IconButton(
              icon: Icon(_history.isEmpty ? CupertinoIcons.xmark : CupertinoIcons.back, color: const Color(0xFF2563EB), size: 20),
              onPressed: _goBack,
            ),
            Expanded(
              child: Text(
                _history.isEmpty ? labels[_level] : _history.last['name'].toString(),
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1E293B)),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20)),
              child: Text('${_filtered.length}', style: GoogleFonts.inter(color: const Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ]),
        ),

        // Breadcrumb tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(4, (i) {
              final isActive = i == _level;
              final isPast = i < _level;
              final isFuture = i > _level;
              return Row(children: [
                GestureDetector(
                  onTap: isFuture ? null : () => _jumpToLevel(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF2563EB) : isPast ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? const Color(0xFF2563EB) : isPast ? const Color(0xFFBFDBFE) : const Color(0xFFE0E7FF),
                        width: 1,
                      ),
                    ),
                    child: Text(labels[i],
                        style: GoogleFonts.inter(
                          color: isActive ? Colors.white : isPast ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                          fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        )),
                  ),
                ),
                if (i < 3)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(CupertinoIcons.chevron_right, size: 12, color: i < _level ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1)),
                  ),
              ]);
            }),
          ),
        ),
        const SizedBox(height: 8),

        // Search field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextFormField(
            controller: _searchCtrl,
            style: GoogleFonts.inter(fontSize: 15),
            decoration: InputDecoration(
              hintText: widget.lang == 'EN' ? 'Search...' : widget.lang == 'ZH' ? '搜索...' : 'Cari...',
              hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 13),
              prefixIcon: const Icon(CupertinoIcons.search, color: Color(0xFF2563EB), size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? GestureDetector(onTap: () { _searchCtrl.clear(); }, child: const Icon(CupertinoIcons.xmark_circle_fill, color: Color(0xFFCBD5E1), size: 18))
                  : null,
              filled: true, fillColor: const Color(0xFFF8FAFF),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFE0E7FF))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.lang == 'EN' ? '${_filtered.length} results' : widget.lang == 'ZH' ? '${_filtered.length} 个结果' : '${_filtered.length} hasil',
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
            ),
          ),
        ),
        const SizedBox(height: 4),

        // List
        Expanded(
          child: _isLoading
              ? Shimmer.fromColors(
                  baseColor: const Color(0xFFFFCDD2),
                  highlightColor: const Color(0xFFFFEBEE),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 6,
                    itemBuilder: (_, __) => Container(margin: const EdgeInsets.only(bottom: 10), height: 58,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
                  ),
                )
              : _filtered.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(CupertinoIcons.location_slash, size: 48, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 8),
                      Text(widget.lang == 'EN' ? 'No data found' : widget.lang == 'ZH' ? '未找到数据' : 'Data tidak ditemukan',
                          style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14)),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final item = _filtered[i];
                        final name = item[_nameCol]?.toString() ?? '-';
                        final isLastLevel = _level == 3;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white, borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE0E7FF)),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                          child: Material(
                            color: Colors.transparent, borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: isLastLevel ? () => _select(item) : () => _goDeeper(item),
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                                    child: Icon([
                                      CupertinoIcons.building_2_fill,
                                      CupertinoIcons.squares_below_rectangle,
                                      CupertinoIcons.layers_alt_fill,
                                      CupertinoIcons.location_fill,
                                    ][_level], color: const Color(0xFF2563EB), size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1E293B)))),
                                  // Tombol Pilih — select di level manapun
                                  GestureDetector(
                                    onTap: () => _select(item),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: const Color(0xFFBFDBFE)),
                                      ),
                                      child: Text(widget.lang == 'EN' ? 'Select' : widget.lang == 'ZH' ? '选择' : 'Pilih',
                                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB))),
                                    ),
                                  ),
                                  if (!isLastLevel) ...[
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => _goDeeper(item),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(color: const Color(0xFFF8FAFF), borderRadius: BorderRadius.circular(8)),
                                        child: const Icon(CupertinoIcons.chevron_right, color: Color(0xFF94A3B8), size: 16),
                                      ),
                                    ),
                                  ],
                                ]),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}

// ============================================================
// KAMERA KHUSUS ACCIDENT REPORT
// ============================================================
class AccidentCameraScreen extends StatefulWidget {
  const AccidentCameraScreen({super.key});

  @override
  State<AccidentCameraScreen> createState() => _AccidentCameraScreenState();
}

class _AccidentCameraScreenState extends State<AccidentCameraScreen> with WidgetsBindingObserver {
  CameraController? _ctrl;
  List<CameraDescription>? _cameras;
  int _camIndex = 0;
  bool _ready = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _ctrl?.dispose(); super.dispose(); }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_ctrl == null || !_ctrl!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) { _ctrl!.dispose(); }
    else if (state == AppLifecycleState.resumed) { _init(); }
  }

  Future<void> _init() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) await _setCamera(_camIndex);
  }

  Future<void> _setCamera(int i) async {
    await _ctrl?.dispose();
    _ctrl = CameraController(_cameras![i], ResolutionPreset.high, enableAudio: false);
    try {
      await _ctrl!.initialize();
      if (mounted) setState(() => _ready = true);
    } on CameraException catch (e) { debugPrint('Camera error: ${e.code}'); }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _ctrl == null) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CupertinoActivityIndicator(color: Colors.white, radius: 16)));
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Center(child: CameraPreview(_ctrl!)),
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.black.withOpacity(0.4),
              child: Row(children: [
                IconButton(icon: const Icon(CupertinoIcons.back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                Expanded(child: Center(child: Text('FOTO BUKTI', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)))),
                const SizedBox(width: 48),
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: 40, left: 0, right: 0,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            GestureDetector(
              onTap: () async {
                final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                if (img != null && mounted) Navigator.pop(context, img);
              },
              child: Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(CupertinoIcons.photo, color: Colors.white)),
            ),
            GestureDetector(
              onTap: () async {
                if (_ctrl == null || _ctrl!.value.isTakingPicture) return;
                try {
                  final pic = await _ctrl!.takePicture();
                  if (mounted) Navigator.pop(context, pic);
                } on CameraException catch (e) { debugPrint('Snap error: ${e.code}'); }
              },
              child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                child: Padding(padding: const EdgeInsets.all(4), child: Container(decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
              ),
            ),
            GestureDetector(
              onTap: () {
                if (_cameras == null || _cameras!.length < 2) return;
                setState(() { _ready = false; _camIndex = (_camIndex + 1) % _cameras!.length; });
                _setCamera(_camIndex);
              },
              child: Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(CupertinoIcons.switch_camera, color: Colors.white)),
            ),
          ]),
        ),
      ]),
    );
  }
}