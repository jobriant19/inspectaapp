import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../home/popup/location_permission_popup.dart';
import '../accident_result_popup.dart';
import '../camera/accident_resolution_camera_screen.dart';
import '../picker/accident_pick_cause.dart';
import '../picker/accident_pick_severity.dart';
import 'accident_add_solution.dart';

class AccidentSolutionManagementScreen extends StatefulWidget {
  final String lang;
  const AccidentSolutionManagementScreen({super.key, required this.lang});

  @override
  State<AccidentSolutionManagementScreen> createState() =>
      _AccidentSolutionManagementScreenState();
}

class _AccidentSolutionManagementScreenState
    extends State<AccidentSolutionManagementScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('accident_report')
          .select('''
            id_laporan, judul, tingkat_keparahan, status, penyebab,
            tanggal_kejadian, foto_bukti, created_at,
            lokasi:id_lokasi(nama_lokasi)
          ''')
          .inFilter('status', ['Menunggu', 'Ditinjau', 'Selesai'])
          .order('created_at', ascending: false);

      final reportsList = List<Map<String, dynamic>>.from(data);

      final reportIds =
          reportsList.map((r) => r['id_laporan'] as String).toList();
      final Map<String, Map<String, dynamic>> resolutionMap = {};
      if (reportIds.isNotEmpty) {
        final resolutions = await supabase
            .from('resolution_accident')
            .select('''
              id_resolution, id_laporan, judul_resolusi, deskripsi_resolusi,
              tindakan_korektif, tindakan_preventif,
              tanggal_resolusi, created_at, foto_resolusi,
              hrd:resolution_accident_id_hrd_fkey(nama, gambar_user)
            ''')
            .inFilter('id_laporan', reportIds);
        for (final r in List<Map<String, dynamic>>.from(resolutions)) {
          resolutionMap[r['id_laporan'].toString()] = r;
        }
      }

      for (final r in reportsList) {
        r['_resolution'] = resolutionMap[r['id_laporan'].toString()];
      }

      if (mounted) {
        setState(() {
          _reports = reportsList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching HRD reports: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Color(0xFF16A34A)),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          widget.lang == 'EN'
              ? 'Solution Management'
              : widget.lang == 'ZH'
                  ? '解决方案管理'
                  : 'Manajemen Solusi',
          style: GoogleFonts.poppins(
              color: const Color(0xFF16A34A),
              fontWeight: FontWeight.w700,
              fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _fetchReports,
            icon: const Icon(CupertinoIcons.refresh,
                color: Color(0xFF16A34A)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              color: CupertinoColors.systemGrey5, height: 1),
        ),
      ),
      body: _isLoading
          ? _buildShimmer()
          : RefreshIndicator(
              onRefresh: _fetchReports,
              color: const Color(0xFF16A34A),
              child: _reports.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: _reports.length,
                      itemBuilder: (_, i) =>
                          _buildReportCard(_reports[i]),
                    ),
            ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Ditinjau':
        return const Color(0xFF2563EB);
      case 'Selesai':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFFDC2626);
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Ditinjau':
        return const Color(0xFFEFF6FF);
      case 'Selesai':
        return const Color(0xFFF0FDF4);
      default:
        return const Color(0xFFFEF2F2);
    }
  }

  IconData _statusIconFor(String status) {
    switch (status) {
      case 'Ditinjau':
        return Icons.visibility_rounded;
      case 'Selesai':
        return Icons.check_circle_rounded;
      default:
        return Icons.pending_actions_rounded;
    }
  }

  String _statusLabelFor(String status) {
    switch (status) {
      case 'Ditinjau':
        return widget.lang == 'EN'
            ? 'Under Review'
            : widget.lang == 'ZH'
                ? '审核中'
                : 'Ditinjau';
      case 'Selesai':
        return widget.lang == 'EN'
            ? 'Completed'
            : widget.lang == 'ZH'
                ? '已完成'
                : 'Selesai';
      default:
        return widget.lang == 'EN'
            ? 'Pending'
            : widget.lang == 'ZH'
                ? '等待中'
                : 'Menunggu';
    }
  }

  Widget _buildChip(IconData icon, String label, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> r) {
    final severityKey = r['tingkat_keparahan'] as String?;
    final severityLabel = AccidentSeverityData.labelOf(severityKey, widget.lang);
    final severityIcon = AccidentSeverityData.iconOf(severityKey);
    final sevColor = AccidentSeverityData.colorOf(severityKey);
    final status = r['status'] ?? '';
    final locName = r['lokasi']?['nama_lokasi'] ?? '-';
    final penyebabKey = r['penyebab'] as String?;
    final penyebabLabel = AccidentCauseData.labelOf(penyebabKey, widget.lang);
    final penyebabIcon = AccidentCauseData.iconOf(penyebabKey);
    final penyebabColor = AccidentCauseData.colorOf(penyebabKey);

    final statusColor = _statusColor(status);
    final statusBg = _statusBg(status);
    final statusIcon = _statusIconFor(status);
    final statusLabel = _statusLabelFor(status);

    return GestureDetector(
      onTap: () async {
        final existingSolution = r['_resolution'] as Map<String, dynamic>?;
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => existingSolution == null
                ? AccidentAddSolutionScreen(
                    reportId: r['id_laporan'] as String,
                    reportTitle: r['judul'] ?? '-',
                    lang: widget.lang,
                  )
                : HrdSolutionDetailScreen(
                    reportId: r['id_laporan'] as String,
                    reportTitle: r['judul'] ?? '-',
                    lang: widget.lang,
                    existingSolution: existingSolution,
                  ),
          ),
        );
        if (changed == true) _fetchReports();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: const Color(0xFF16A34A), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF16A34A).withValues(alpha:0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PHOTO
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: sevColor.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.black.withValues(alpha: 0.08), width: 1.2),
              ),
              child: r['foto_bukti'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12.5),
                      child: Image.network(r['foto_bukti'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                              Icons.warning_amber_rounded,
                              color: sevColor,
                              size: 32)))
                  : Icon(Icons.warning_amber_rounded,
                      color: sevColor, size: 32),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(r['judul'] ?? '-',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: const Color(0xFF1E293B)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(statusLabel,
                                style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_city_rounded,
                            size: 12, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(locName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF10B981))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildChip(
                        penyebabIcon,
                        penyebabLabel,
                        penyebabColor.withValues(alpha:0.1),
                        penyebabColor,
                      ),
                      const SizedBox(width: 6),
                      _buildChip(
                        severityIcon,
                        severityLabel,
                        sevColor.withValues(alpha:0.1),
                        sevColor,
                      ),
                      const Spacer(),
                      const Icon(CupertinoIcons.chevron_right,
                          size: 14,
                          color: Color(0xFF16A34A)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.checkmark_shield,
              size: 64, color: Color(0xFF16A34A)),
          const SizedBox(height: 16),
          Text(
            widget.lang == 'EN'
                ? 'No reports to resolve'
                : widget.lang == 'ZH'
                    ? '无需解决的报告'
                    : 'Belum ada laporan untuk diselesaikan',
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFDCFCE7),
      highlightColor: const Color(0xFFF0FDF4),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class HrdSolutionDetailScreen extends StatefulWidget {
  final String reportId;
  final String reportTitle;
  final String lang;
  final Map<String, dynamic> existingSolution;

  const HrdSolutionDetailScreen({
    super.key,
    required this.reportId,
    required this.reportTitle,
    required this.lang,
    required this.existingSolution,
  });

  @override
  State<HrdSolutionDetailScreen> createState() =>
      _HrdSolutionDetailScreenState();
}

class _HrdSolutionDetailScreenState
    extends State<HrdSolutionDetailScreen> {
  Map<String, dynamic>? _solution;
  // ignore: unused_field
  bool _isLoading = true;
  final bool _isSaving = false;

  final _judulCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _korektifCtrl = TextEditingController();
  final _preventifCtrl = TextEditingController();

  XFile? _imageFile;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    AccidentSolutionCameraWarmupService.instance.warmUp();
    _populateFromData(widget.existingSolution);
    _isLoading = false;
  }

  void _populateFromData(Map<String, dynamic>? data) {
    _solution = data;
    if (data != null) {
      _judulCtrl.text = data['judul_resolusi'] ?? '';
      _descCtrl.text = data['deskripsi_resolusi'] ?? '';
      _korektifCtrl.text = data['tindakan_korektif'] ?? '';
      _preventifCtrl.text = data['tindakan_preventif'] ?? '';
      _existingImageUrl = data['foto_resolusi'];
    }
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _descCtrl.dispose();
    _korektifCtrl.dispose();
    _preventifCtrl.dispose();
    AccidentSolutionCameraWarmupService.instance.release();
    super.dispose();
  }

  Future<bool> _checkAtmiOrBlock() async {
    final result = await LocationPermissionPopup.requestWithPopup(context, lang: widget.lang);
    if (result.isAtAtmi) return true;
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.location_off_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.lang == 'EN'
                  ? 'Solution can only be saved within PT ATMI Solo area.'
                  : widget.lang == 'ZH'
                      ? '解决方案只能在PT ATMI Solo区域内保存。'
                      : 'Solusi hanya dapat disimpan di area PT ATMI Solo.',
            ),
          ),
        ]),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
    return false;
  }

  Future<void> _pickImage() async {
    final XFile? result = await Navigator.push<XFile?>(
      context,
      MaterialPageRoute(builder: (_) => const AccidentSolutionCameraScreen()),
    );
    if (result != null && mounted) setState(() => _imageFile = result);
    AccidentSolutionCameraWarmupService.instance.warmUp();
  }

  Widget _buildPhotoWidget() {
    if (_isLoading) {
      return Shimmer.fromColors(
        baseColor: const Color(0xFFDCFCE7),
        highlightColor: const Color(0xFFF0FDF4),
        child: Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    final hasPhoto = _imageFile != null || _existingImageUrl != null;
    if (!hasPhoto) {
      return GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0FDF4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.camera,
                    color: Color(0xFF16A34A), size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                widget.lang == 'EN'
                    ? 'Add Solution Photo'
                    : widget.lang == 'ZH'
                        ? '添加解决方案照片'
                        : 'Tambah Foto Solusi',
                style: GoogleFonts.inter(
                    color: const Color(0xFF16A34A),
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
              Text(
                widget.lang == 'EN'
                    ? 'Tap to take or select a photo'
                    : widget.lang == 'ZH'
                        ? '点击拍照或选择照片'
                        : 'Ketuk untuk ambil atau pilih foto',
                style: GoogleFonts.inter(
                    fontSize: 11, color: const Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      );
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _imageFile != null
              ? (kIsWeb
                  ? Image.network(_imageFile!.path,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover)
                  : Image.file(File(_imageFile!.path),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover))
              : Image.network(_existingImageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover),
        ),
        Positioned(
          right: 10,
          bottom: 10,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha:0.6),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.camera_rotate,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    widget.lang == 'EN'
                        ? 'Retake'
                        : widget.lang == 'ZH'
                            ? '重拍'
                            : 'Ganti',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveSolution() async {
    if (_judulCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      await showResultPopup(
        context,
        icon: CupertinoIcons.exclamationmark_circle_fill,
        iconColor: const Color(0xFFEF4444),
        iconBgColor: const Color(0xFFFFF1F2),
        message: widget.lang == 'ZH'
            ? '标题和描述为必填项！'
            : widget.lang == 'EN'
                ? 'Title and description required!'
                : 'Judul dan deskripsi wajib diisi!',
        duration: const Duration(milliseconds: 500),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(radius: 18, color: Color(0xFF16A34A)),
              const SizedBox(height: 16),
              Text(
                widget.lang == 'ZH'
                    ? '正在保存...'
                    : widget.lang == 'EN'
                        ? 'Saving solution...'
                        : 'Menyimpan solusi...',
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B)),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      String? imageUrl = _existingImageUrl;
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        final fileName =
            '$userId/solution_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('temuan_images').uploadBinary(
            fileName, bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'));
        imageUrl =
            supabase.storage.from('temuan_images').getPublicUrl(fileName);
      }

      await supabase.from('resolution_accident').update({
        'judul_resolusi': _judulCtrl.text.trim(),
        'deskripsi_resolusi': _descCtrl.text.trim(),
        'tindakan_korektif': _korektifCtrl.text.trim().isEmpty
            ? null
            : _korektifCtrl.text.trim(),
        'tindakan_preventif': _preventifCtrl.text.trim().isEmpty
            ? null
            : _preventifCtrl.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
        'foto_resolusi': imageUrl,
      }).eq('id_resolution', _solution!['id_resolution']);

      if (mounted) {
        Navigator.of(context).pop();
        await showResultPopup(
          context,
          icon: CupertinoIcons.checkmark_circle_fill,
          iconColor: const Color(0xFF16A34A),
          iconBgColor: const Color(0xFFF0FDF4),
          message: widget.lang == 'ZH'
              ? '解决方案保存成功！'
              : widget.lang == 'EN'
                  ? 'Solution saved successfully!'
                  : 'Solusi berhasil disimpan!',
          duration: const Duration(milliseconds: 500),
        );
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('Save solution error: $e');
      if (mounted) {
        Navigator.of(context).pop();
        await showResultPopup(
          context,
          icon: CupertinoIcons.xmark_circle_fill,
          iconColor: const Color(0xFFEF4444),
          iconBgColor: const Color(0xFFFFF1F2),
          message: 'Error: $e',
          duration: const Duration(milliseconds: 500),
        );
      }
    }
  }

  double _bottomSafeSpacing(BuildContext context) {
    final double navInset = MediaQuery.of(context).padding.bottom;
    return navInset > 0 ? navInset + 16 : 28;
  }

  Widget _buildFormField({
    required TextEditingController ctrl,
    required IconData icon,
    required String label,
    required String hint,
    int maxLines = 1,
    Color borderColor = const Color(0xFF16A34A),
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: const Color(0xFF16A34A)),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF16A34A))),
            const Text(' *',
                style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
                color: const Color(0xFFCBD5E1), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF8FAFF),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: borderColor.withValues(alpha:0.3), width: 1)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Color(0xFF16A34A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.lang == 'EN'
              ? 'Edit Solution'
              : widget.lang == 'ZH'
                  ? '编辑解决方案'
                  : 'Edit Solusi',
          style: GoogleFonts.poppins(
              color: const Color(0xFF16A34A),
              fontWeight: FontWeight.w700,
              fontSize: 17),
        ),
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
                      // SOLUTION PHOTO
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFDCFCE7), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(CupertinoIcons.camera_fill,
                                    size: 15, color: Color(0xFF16A34A)),
                                const SizedBox(width: 6),
                                Text(
                                  widget.lang == 'EN'
                                      ? 'Solution Photo'
                                      : widget.lang == 'ZH'
                                          ? '解决方案照片'
                                          : 'Foto Solusi',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF16A34A)),
                                ),
                                const Text(' *',
                                    style: TextStyle(
                                        color: Color(0xFFEF4444),
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildPhotoWidget(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // TITLE FORM & DESCRIPTION
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFDCFCE7), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            _buildFormField(
                              ctrl: _judulCtrl,
                              icon: CupertinoIcons.pencil,
                              label: widget.lang == 'ID'
                                  ? 'Judul Solusi'
                                  : widget.lang == 'ZH'
                                      ? '解决方案标题'
                                      : 'Solution Title',
                              hint: widget.lang == 'ID'
                                  ? 'Contoh: Penanganan Insiden Terpeleset di Gudang'
                                  : widget.lang == 'ZH'
                                      ? '例如：仓库滑倒事故处理'
                                      : 'e.g. Warehouse Slip Incident Resolution',
                              borderColor: const Color(0xFF16A34A),
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              ctrl: _descCtrl,
                              icon: CupertinoIcons.doc_text_fill,
                              label: widget.lang == 'ID'
                                  ? 'Deskripsi Solusi'
                                  : widget.lang == 'ZH'
                                      ? '解决方案描述'
                                      : 'Solution Description',
                              hint: widget.lang == 'ID'
                                  ? 'Jelaskan proses penyelesaian secara lengkap dan rinci...'
                                  : widget.lang == 'ZH'
                                      ? '详细描述解决过程...'
                                      : 'Describe the resolution process in full detail...',
                              maxLines: 4,
                              borderColor: const Color(0xFF16A34A),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // CORRECTIVE ACTION
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFDCFCE7), width: 1.5),
                        ),
                        child: _buildFormField(
                          ctrl: _korektifCtrl,
                          icon: CupertinoIcons.wrench_fill,
                          label: widget.lang == 'ID'
                              ? 'Tindakan Korektif'
                              : widget.lang == 'ZH'
                                  ? '纠正措施'
                                  : 'Corrective Action',
                          hint: widget.lang == 'ID'
                              ? 'Contoh: Memperbaiki lantai licin dan memasang rambu peringatan'
                              : widget.lang == 'ZH'
                                  ? '例如：修复湿滑地面并安装警示标志'
                                  : 'e.g. Repaired the slippery floor and installed warning signs',
                          maxLines: 3,
                          borderColor: const Color(0xFF16A34A),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // PREVENTIF ACTION
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFDCFCE7), width: 1.5),
                        ),
                        child: _buildFormField(
                          ctrl: _preventifCtrl,
                          icon: CupertinoIcons.shield_fill,
                          label: widget.lang == 'ID'
                              ? 'Tindakan Preventif'
                              : widget.lang == 'ZH'
                                  ? '预防措施'
                                  : 'Preventive Action',
                          hint: widget.lang == 'ID'
                              ? 'Contoh: Melakukan inspeksi rutin area kerja setiap minggu'
                              : widget.lang == 'ZH'
                                  ? '例如：每周对工作区域进行例行检查'
                                  : 'e.g. Conduct routine weekly work area inspections',
                          maxLines: 3,
                          borderColor: const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isSaving)
                  Container(
                    color: Colors.black.withValues(alpha:0.3),
                    child: const Center(
                      child: CupertinoActivityIndicator(
                          radius: 14, color: Colors.white),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, _bottomSafeSpacing(context)),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
              top: BorderSide(color: CupertinoColors.systemGrey5, width: 1)),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF16A34A), Color(0xFF15803D)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A34A).withValues(alpha:0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isSaving
                ? null
                : () async {
                    if (!await _checkAtmiOrBlock()) return;
                    _saveSolution();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              widget.lang == 'ID'
                  ? 'Perbarui Solusi'
                  : widget.lang == 'ZH'
                      ? '更新解决方案'
                      : 'Update Solution',
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}