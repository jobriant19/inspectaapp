import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../home/popup/location_permission_popup.dart';
import '../accident_result_popup.dart';
import '../camera/accident_resolution_camera_screen.dart';

class AccidentAddSolutionScreen extends StatefulWidget {
  final String reportId;
  final String reportTitle;
  final String lang;

  const AccidentAddSolutionScreen({
    super.key,
    required this.reportId,
    required this.reportTitle,
    required this.lang,
  });

  @override
  State<AccidentAddSolutionScreen> createState() =>
      _AccidentAddSolutionScreenState();
}

class _AccidentAddSolutionScreenState
    extends State<AccidentAddSolutionScreen> {
  final bool _isSaving = false;

  final _judulCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _korektifCtrl = TextEditingController();
  final _preventifCtrl = TextEditingController();

  XFile? _imageFile;

  @override
  void initState() {
    super.initState();
    AccidentSolutionCameraWarmupService.instance.warmUp();
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
    final result =
        await LocationPermissionPopup.requestWithPopup(context, lang: widget.lang);
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
    if (_imageFile == null) {
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
          child: kIsWeb
              ? Image.network(_imageFile!.path,
                  height: 180, width: double.infinity, fit: BoxFit.cover)
              : Image.file(File(_imageFile!.path),
                  height: 180, width: double.infinity, fit: BoxFit.cover),
        ),
        Positioned(
          right: 10,
          bottom: 10,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
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

      String? imageUrl;
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
        'tanggal_resolusi': DateTime.now().toIso8601String().substring(0, 10),
        'foto_resolusi': imageUrl,
      });
      await supabase
          .from('accident_report')
          .update({'status': 'Selesai'}).eq('id_laporan', widget.reportId);

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
                    color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF8FAFF),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: borderColor.withValues(alpha: 0.3), width: 1)),
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
              ? 'Add Solution'
              : widget.lang == 'ZH'
                  ? '添加解决方案'
                  : 'Tambah Solusi',
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
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
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CupertinoActivityIndicator(radius: 14, color: Colors.white),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, _bottomSafeSpacing(context)),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: CupertinoColors.systemGrey5, width: 1)),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF16A34A), Color(0xFF15803D)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A34A).withValues(alpha: 0.4),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              widget.lang == 'ID'
                  ? 'Simpan Solusi'
                  : widget.lang == 'ZH'
                      ? '保存解决方案'
                      : 'Save Solution',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}