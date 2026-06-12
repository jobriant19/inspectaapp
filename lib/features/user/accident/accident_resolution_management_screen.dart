import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../core/services/location_service.dart';
import 'accident_report_form_screen.dart';
import 'accident_result_popup.dart';

// ============================================================
// LAYAR MANAJEMEN RESOLUSI — KHUSUS HRD (id_jabatan = 5)
// ============================================================
class AccidentResolutionManagementScreen extends StatefulWidget {
  final String lang;
  const AccidentResolutionManagementScreen({super.key, required this.lang});

  @override
  State<AccidentResolutionManagementScreen> createState() =>
      _AccidentResolutionManagementScreenState();
}

class _AccidentResolutionManagementScreenState
    extends State<AccidentResolutionManagementScreen> {
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
      // Ambil semua laporan yang statusnya Ditinjau atau sudah selesai
      // agar HRD bisa mengelola resolusi
      final data = await Supabase.instance.client
          .from('accident_report')
          .select('''
            id_laporan, judul, tingkat_keparahan, status, penyebab,
            tanggal_kejadian, foto_bukti, created_at,
            lokasi:id_lokasi(nama_lokasi)
          ''')
          .inFilter('status', ['Menunggu', 'Ditinjau', 'Selesai'])
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _reports = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching HRD reports: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _severityColor(String sev) {
    switch (sev) {
      case 'Berat':
        return const Color(0xFFDC2626);
      case 'Menengah':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFF16A34A);
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
          style: GoogleFonts.inter(
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
    final severity = r['tingkat_keparahan'] ?? '';
    final sevColor = _severityColor(severity);
    final status = r['status'] ?? '';
    final locName = r['lokasi']?['nama_lokasi'] ?? '-';
    final penyebab = r['penyebab'] ?? '-';

    final Color statusColor = status == 'Selesai'
        ? const Color(0xFF16A34A)
        : const Color(0xFFF97316);
    final Color statusBg = status == 'Selesai'
        ? const Color(0xFFF0FDF4)
        : const Color(0xFFFFF7ED);

    return GestureDetector(
      onTap: () async {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => HrdResolutionDetailScreen(
              reportId: r['id_laporan'] as String,
              reportTitle: r['judul'] ?? '-',
              lang: widget.lang,
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
              color: const Color(0xFFDCFCE7), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF16A34A).withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Foto
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: sevColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: r['foto_bukti'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(r['foto_bukti'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                              Icons.warning_amber_rounded,
                              color: sevColor,
                              size: 28)))
                  : Icon(Icons.warning_amber_rounded,
                      color: sevColor, size: 28),
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
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(status,
                            style: GoogleFonts.inter(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(locName,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildChip(
                        Icons.medical_services_outlined,
                        penyebab,
                        const Color(0xFFF5F3FF),
                        const Color(0xFF7C3AED),
                      ),
                      const SizedBox(width: 6),
                      _buildChip(
                        Icons.warning_amber_rounded,
                        severity,
                        sevColor.withOpacity(0.1),
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

// ============================================================
// LAYAR DETAIL RESOLUSI UNTUK HRD — CRUD RESOLUSI
// ============================================================
class HrdResolutionDetailScreen extends StatefulWidget {
  final String reportId;
  final String reportTitle;
  final String lang;

  const HrdResolutionDetailScreen({
    super.key,
    required this.reportId,
    required this.reportTitle,
    required this.lang,
  });

  @override
  State<HrdResolutionDetailScreen> createState() =>
      _HrdResolutionDetailScreenState();
}

class _HrdResolutionDetailScreenState
    extends State<HrdResolutionDetailScreen> {
  Map<String, dynamic>? _resolution;
  bool _isLoading = true;
  bool _isSaving = false;

  final _judulCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _korektifCtrl = TextEditingController();
  final _preventifCtrl = TextEditingController();

  // ── Foto resolusi ──
  XFile? _imageFile;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _loadResolution();
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _descCtrl.dispose();
    _korektifCtrl.dispose();
    _preventifCtrl.dispose();
    super.dispose();
  }

  Future<bool> _checkAtmiOrBlock() async {
    final result = await LocationService.instance.checkUserAtAtmi(
      forceRefresh: true,
    );
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
                  ? 'Resolution can only be saved within PT ATMI Solo area.'
                  : widget.lang == 'ZH'
                      ? '解决方案只能在PT ATMI Solo区域内保存。'
                      : 'Penyelesaian hanya dapat disimpan di area PT ATMI Solo.',
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

  Future<void> _loadResolution() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('resolution_accident')
          .select('''
            id_resolution, judul_resolusi, deskripsi_resolusi,
            tindakan_korektif, tindakan_preventif,
            tanggal_resolusi, created_at, foto_resolusi,
            hrd:resolution_accident_id_hrd_fkey(nama, gambar_user)
          ''')
          .eq('id_laporan', widget.reportId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _resolution = data;
          _isLoading = false;
          if (data != null) {
            _judulCtrl.text = data['judul_resolusi'] ?? '';
            _descCtrl.text = data['deskripsi_resolusi'] ?? '';
            _korektifCtrl.text = data['tindakan_korektif'] ?? '';
            _preventifCtrl.text = data['tindakan_preventif'] ?? '';
            _existingImageUrl = data['foto_resolusi'];
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading resolution: $e');
      if (mounted) setState(() => _isLoading = false);
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              widget.lang == 'EN'
                  ? 'Add Resolution Photo'
                  : widget.lang == 'ZH'
                      ? '添加解决方案照片'
                      : 'Tambah Foto Penyelesaian',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 20),
            // Kamera
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                final img = await Navigator.push<XFile?>(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AccidentCameraScreen()),
                );
                if (img != null && mounted) setState(() => _imageFile = img);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFDCFCE7), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(CupertinoIcons.camera_fill,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.lang == 'EN'
                              ? 'Take Photo'
                              : widget.lang == 'ZH'
                                  ? '拍照'
                                  : 'Ambil Foto',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: const Color(0xFF1E293B)),
                        ),
                        Text(
                          widget.lang == 'EN'
                              ? 'Open camera directly'
                              : widget.lang == 'ZH'
                                  ? '直接打开相机'
                                  : 'Buka kamera langsung',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(CupertinoIcons.chevron_right,
                        size: 16, color: Color(0xFF16A34A)),
                  ],
                ),
              ),
            ),
            // Galeri
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                final img = await picker.pickImage(
                    source: ImageSource.gallery, imageQuality: 80);
                if (img != null && mounted) setState(() => _imageFile = img);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFDCFCE7), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15803D),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                          CupertinoIcons.photo_fill_on_rectangle_fill,
                          color: Colors.white,
                          size: 22),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.lang == 'EN'
                              ? 'Choose from Gallery'
                              : widget.lang == 'ZH'
                                  ? '从相册选择'
                                  : 'Pilih dari Galeri',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: const Color(0xFF1E293B)),
                        ),
                        Text(
                          widget.lang == 'EN'
                              ? 'Select existing photo'
                              : widget.lang == 'ZH'
                                  ? '选择现有照片'
                                  : 'Pilih foto yang sudah ada',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(CupertinoIcons.chevron_right,
                        size: 16, color: Color(0xFF16A34A)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Batal
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    widget.lang == 'EN'
                        ? 'Cancel'
                        : widget.lang == 'ZH'
                            ? '取消'
                            : 'Batal',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: const Color(0xFF64748B)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoWidget() {
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
                    ? 'Add Resolution Photo'
                    : widget.lang == 'ZH'
                        ? '添加解决方案照片'
                        : 'Tambah Foto Penyelesaian',
                style: GoogleFonts.inter(
                    color: const Color(0xFF16A34A),
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
              Text(
                widget.lang == 'EN'
                    ? 'Optional'
                    : widget.lang == 'ZH'
                        ? '可选'
                        : 'Opsional',
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
                  color: Colors.black.withOpacity(0.6),
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

  Future<void> _saveResolution() async {
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

    // Tampilkan loading popup
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
            '$userId/resolution_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('temuan_images').uploadBinary(
            fileName, bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'));
        imageUrl =
            supabase.storage.from('temuan_images').getPublicUrl(fileName);
      }

      if (_resolution == null) {
        await supabase.from('resolution_accident').insert({
          'id_laporan': widget.reportId,
          'id_hrd': userId,
          'judul_resolusi': _judulCtrl.text.trim(),
          'deskripsi_resolusi': _descCtrl.text.trim(),
          'tindakan_korektif': _korektifCtrl.text.trim().isEmpty
              ? null
              : _korektifCtrl.text.trim(),
          'tindakan_preventif': _preventifCtrl.text.trim().isEmpty
              ? null
              : _preventifCtrl.text.trim(),
          'tanggal_resolusi':
              DateTime.now().toIso8601String().substring(0, 10),
          'foto_resolusi': imageUrl,
        });
        await supabase
            .from('accident_report')
            .update({'status': 'Selesai'}).eq('id_laporan', widget.reportId);
      } else {
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
        }).eq('id_resolution', _resolution!['id_resolution']);
      }

      if (mounted) {
        // Tutup loading popup
        Navigator.of(context).pop();
        // Tampilkan success popup lalu kembali
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
        Navigator.of(context).pop(); // tutup loading
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

  Widget _buildFormField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    int maxLines = 1,
    Color borderColor = const Color(0xFF16A34A),
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569))),
            if (isRequired)
              const Text(' *',
                  style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
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
                    color: borderColor.withOpacity(0.3), width: 1)),
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
    final bool isEdit = _resolution != null;

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
              ? (isEdit ? 'Edit Solution' : 'Add Solution')
              : widget.lang == 'ZH'
                  ? (isEdit ? '编辑解决方案' : '添加解决方案')
                  : (isEdit ? 'Edit Solusi' : 'Tambah Solusi'),
          style: GoogleFonts.inter(
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
      body: _isLoading
          ? const Center(
              child: CupertinoActivityIndicator(
                  radius: 14, color: Color(0xFF16A34A)))
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info laporan
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.assignment_outlined,
                                color: Color(0xFF2563EB), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(widget.reportTitle,
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E293B))),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Foto Resolusi ──
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
                                Text(
                                  widget.lang == 'EN'
                                      ? 'Solution Photo'
                                      : widget.lang == 'ZH'
                                          ? '解决方案照片'
                                          : 'Foto Solusi',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF475569)),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.lang == 'EN'
                                        ? 'Optional'
                                        : widget.lang == 'ZH'
                                            ? '可选'
                                            : 'Opsional',
                                    style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: const Color(0xFF16A34A),
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildPhotoWidget(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Form judul & deskripsi
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
                              label: widget.lang == 'ID'
                                  ? 'Judul Solusi'
                                  : widget.lang == 'ZH'
                                      ? '解决方案标题'
                                      : 'Solution Title',
                              hint: widget.lang == 'ID'
                                  ? 'Contoh: Penanganan Insiden Gudang'
                                  : widget.lang == 'ZH'
                                      ? '例如：仓库事故处理'
                                      : 'e.g. Warehouse Incident Handling',
                              borderColor: const Color(0xFF16A34A),
                              isRequired: true,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              ctrl: _descCtrl,
                              label: widget.lang == 'ID'
                                  ? 'Deskripsi Solusi'
                                  : widget.lang == 'ZH'
                                      ? '解决方案描述'
                                      : 'Solution Description',
                              hint: widget.lang == 'ID'
                                  ? 'Jelaskan penyelesaian secara rinci...'
                                  : widget.lang == 'ZH'
                                      ? '详细说明解决方案...'
                                      : 'Explain in detail...',
                              maxLines: 4,
                              borderColor: const Color(0xFF16A34A),
                              isRequired: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tindakan Korektif
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFFFF7ED), width: 1.5),
                        ),
                        child: _buildFormField(
                          ctrl: _korektifCtrl,
                          label: widget.lang == 'ID'
                              ? 'Tindakan Korektif'
                              : widget.lang == 'ZH'
                                  ? '纠正措施'
                                  : 'Corrective Action',
                          hint: widget.lang == 'ID'
                              ? 'Tindakan untuk mengatasi masalah...'
                              : widget.lang == 'ZH'
                                  ? '解决问题的措施...'
                                  : 'Actions to address the issue...',
                          maxLines: 3,
                          borderColor: const Color(0xFFF97316),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tindakan Preventif
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
                          label: widget.lang == 'ID'
                              ? 'Tindakan Preventif'
                              : widget.lang == 'ZH'
                                  ? '预防措施'
                                  : 'Preventive Action',
                          hint: widget.lang == 'ID'
                              ? 'Tindakan untuk mencegah terulang...'
                              : widget.lang == 'ZH'
                                  ? '防止再次发生的措施...'
                                  : 'Actions to prevent recurrence...',
                          maxLines: 3,
                          borderColor: const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isSaving)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CupertinoActivityIndicator(
                          radius: 14, color: Colors.white),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
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
                color: const Color(0xFF16A34A).withOpacity(0.4),
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
                    _saveResolution();
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
              isEdit
                  ? (widget.lang == 'ID'
                      ? 'Perbarui Solusi'
                      : widget.lang == 'ZH'
                          ? '更新解决方案'
                          : 'Update Solution')
                  : (widget.lang == 'ID'
                      ? 'Simpan Solusi'
                      : widget.lang == 'ZH'
                          ? '保存解决方案'
                          : 'Save Solution'),
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}