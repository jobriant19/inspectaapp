import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dotted_border/dotted_border.dart';

import '../../home/alert/required_field_alert.dart';
import 'camera/help_center_camera.dart';

class ReportDetailScreen extends StatefulWidget {
  final String lang;
  final Map<String, dynamic>? report;
  final bool startInEditing;

  const ReportDetailScreen({
    super.key,
    required this.lang,
    this.report,
    this.startInEditing = false,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late String _currentLang;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _commentController = TextEditingController();
  String? _selectedPriority;
  bool _isSaving = false;
  bool _isEditing = false;
  bool get _isEditMode => widget.report != null;

  // State untuk gambar laporan
  File? _pickedImageFile;
  Uint8List? _pickedImageBytes;
  String? _existingImageUrl;

  final Map<String, Map<String, String>> _txt = {
    'EN': {
      'new_report': 'Report Issue',
      'edit_report': 'Edit Report',
      'report_detail': 'Report Detail',
      'photo_attachment': 'Photo Attachment',
      'change_photo': 'Change Photo',
      'add_here': 'Add here',
      'priority': 'Priority',
      'select_priority': 'Select priority',
      'problem_desc': 'Problem Description',
      'title': 'Title',
      'title_hint': 'e.g., The app is slow',
      'fatal': 'Fatal',
      'normal': 'Normal',
      'submit': 'Submit',
      'update': 'Update',
      'delete': 'Delete Report',
      'delete_confirm': 'Are you sure you want to delete this report?',
      'yes': 'Yes, Delete',
      'no': 'Cancel',
      'title_empty_error': 'Title cannot be empty',
      'priority_empty_error': 'Priority must be selected',
      'desc_empty_error': 'Description cannot be empty',
      'report_saved': 'Report saved successfully!',
      'report_deleted': 'Report deleted successfully!',
      'created_at': 'Reported on',
      'edited_at': 'Last updated on',
      'comments': 'Comments',
      'no_comments': 'No comments yet. Be the first to comment!',
      'type_comment': 'Type a comment...',
      'comment_sent': 'Comment sent!',
      'status': 'Status',
      'sent': 'Sent',
      'viewed': 'Viewed',
      'completed': 'Completed',
      'photo_empty_error': 'Photo attachment is required',
    },
    'ID': {
      'new_report': 'Lapor Kendala',
      'edit_report': 'Ubah Laporan',
      'report_detail': 'Detail Laporan',
      'photo_attachment': 'Lampiran Foto',
      'change_photo': 'Ganti Foto',
      'add_here': 'Tambahkan disini',
      'priority': 'Prioritas',
      'select_priority': 'Pilih prioritas',
      'problem_desc': 'Deskripsi Masalah',
      'title': 'Judul',
      'title_hint': 'cth., Aplikasi terasa lambat',
      'fatal': 'Fatal',
      'normal': 'Normal',
      'submit': 'Kirim',
      'update': 'Perbarui',
      'delete': 'Hapus Laporan',
      'delete_confirm': 'Apakah Anda yakin ingin menghapus laporan ini?',
      'yes': 'Ya, Hapus',
      'no': 'Batal',
      'title_empty_error': 'Judul tidak boleh kosong',
      'priority_empty_error': 'Prioritas harus dipilih',
      'desc_empty_error': 'Deskripsi tidak boleh kosong',
      'report_saved': 'Laporan berhasil disimpan!',
      'report_deleted': 'Laporan berhasil dihapus!',
      'created_at': 'Dilaporkan pada',
      'edited_at': 'Terakhir diperbarui',
      'comments': 'Komentar',
      'no_comments': 'Belum ada komentar. Jadilah yang pertama berkomentar!',
      'type_comment': 'Ketik komentar...',
      'comment_sent': 'Komentar terkirim!',
      'status': 'Status',
      'sent': 'Dikirim',
      'viewed': 'Dilihat',
      'completed': 'Selesai',
      'photo_empty_error': 'Lampiran foto wajib diisi',
    },
    'ZH': {
      'new_report': '报告问题',
      'edit_report': '编辑报告',
      'report_detail': '报告详情',
      'photo_attachment': '照片附件',
      'change_photo': '更换照片',
      'add_here': '在此添加',
      'priority': '优先',
      'select_priority': '选择优先级',
      'problem_desc': '问题描述',
      'title': '标题',
      'title_hint': '例如, 应用很慢',
      'fatal': '致命',
      'normal': '普通',
      'submit': '提交',
      'update': '更新',
      'delete': '删除报告',
      'delete_confirm': '您确定要删除此报告吗？',
      'yes': '是, 删除',
      'no': '取消',
      'title_empty_error': '标题不能为空',
      'priority_empty_error': '必须选择优先级',
      'desc_empty_error': '描述不能为空',
      'report_saved': '报告已成功保存！',
      'report_deleted': '报告已成功删除！',
      'created_at': '报告于',
      'edited_at': '最后更新于',
      'comments': '评论',
      'no_comments': '暂无评论。快来抢沙发吧！',
      'type_comment': '输入评论...',
      'comment_sent': '评论已发送！',
      'status': '状态',
      'sent': '已发送',
      'viewed': '已查看',
      'completed': '已完成',
      'photo_empty_error': '必须上传照片',
    },
  };

  String getTxt(String key) => _txt[_currentLang]?[key] ?? key;

  Color _priorityColor(String p) =>
      p.toLowerCase() == 'fatal' ? const Color(0xFFEF4444) : const Color(0xFF0EA5E9);

  IconData _priorityIcon(String p) =>
      p.toLowerCase() == 'fatal' ? Icons.warning_amber_rounded : Icons.info_outline_rounded;

  Color _statusColor(String s) {
    switch (s) {
      case 'Dikirim': return const Color(0xFF0EA5E9);
      case 'Dilihat': return const Color(0xFFF59E0B);
      case 'Selesai': return const Color(0xFF10B981);
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'Dikirim': return Icons.send_rounded;
      case 'Dilihat': return Icons.visibility_rounded;
      case 'Selesai': return Icons.check_circle_rounded;
      default: return Icons.circle_outlined;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'Dikirim': return getTxt('sent');
      case 'Dilihat': return getTxt('viewed');
      case 'Selesai': return getTxt('completed');
      default: return s;
    }
  }

  Widget _tagIcon(IconData icon, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(text, style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
      ],
    ),
  );

  @override
  void initState() {
    super.initState();
    _currentLang = widget.lang;
    _isEditing = !_isEditMode || widget.startInEditing;
    HelpCenterCameraWarmupService.instance.warmUp();

    if (_isEditMode) {
      final report = widget.report!;
      _titleController.text = report['title'] ?? '';
      _descriptionController.text = report['description'] ?? '';
      _selectedPriority = report['priority'];
      
      _loadInitialImage();
    }
  }

  Future<void> _loadInitialImage() async {
    final imageUrl = widget.report?['image_url'] as String?;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final path = imageUrl.split('/report_images/').last;
        final signedUrl = await Supabase.instance.client.storage
            .from('report_images')
            .createSignedUrl(path, 3600);
        if (mounted) {
          setState(() {
            _existingImageUrl = signedUrl;
          });
        }
      } catch (e) {
        print("Error creating signed URL in Detail Screen: $e");
      }
    }
  }

  @override
  void dispose() {
    HelpCenterCameraWarmupService.instance.release();
    _titleController.dispose();
    _descriptionController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null) return '-';
    try {
      // 1. Parse string tanggal sebagai UTC
      final dateTimeUtc = DateTime.parse(dateString);
      // 2. Konversi ke zona waktu lokal perangkat
      final dateTimeLocal = dateTimeUtc.toLocal();
      // 3. Format waktu lokal tersebut
      return DateFormat('d MMMM yyyy, HH:mm', _currentLang).format(dateTimeLocal);
    } catch (e) {
      // Jika ada error parsing, kembalikan string aslinya
      return dateString;
    }
  }

  // --- LOGIC UNTUK GAMBAR LAPORAN: langsung ke kamera ---
  Future<void> _openCamera() async {
    final XFile? picked = await Navigator.push<XFile?>(
      context,
      MaterialPageRoute(
        builder: (_) => HelpCenterCameraScreen(lang: _currentLang),
      ),
    );
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImageBytes = bytes;
        _pickedImageFile = null;
      });
    } else {
      setState(() {
        _pickedImageFile = File(picked.path);
        _pickedImageBytes = null;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      HelpCenterCameraWarmupService.instance.warmUp();
    });
  }

  void _openFullImageViewer() {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.95),
        pageBuilder: (_, __, ___) => _ReportImageViewer(
          imageBytes: _pickedImageBytes,
          imageFile: _pickedImageFile,
          imageUrl: (_pickedImageBytes == null && _pickedImageFile == null) ? _existingImageUrl : null,
        ),
      ),
    );
  }

  // --- LOGIC UNTUK DATABASE ---
  Future<void> _saveReport() async {
    final missing = <MissingFieldItem>[];
    final hasPhoto = _pickedImageFile != null ||
        _pickedImageBytes != null ||
        (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);
    if (!hasPhoto) {
      missing.add(MissingFieldItem(icon: Icons.camera_alt_rounded, label: getTxt('photo_empty_error')));
    }
    if (_titleController.text.trim().isEmpty) {
      missing.add(MissingFieldItem(icon: Icons.title_rounded, label: getTxt('title_empty_error')));
    }
    if (_selectedPriority == null) {
      missing.add(MissingFieldItem(icon: Icons.flag_rounded, label: getTxt('priority_empty_error')));
    }
    if (_descriptionController.text.trim().isEmpty) {
      missing.add(MissingFieldItem(icon: Icons.description_rounded, label: getTxt('desc_empty_error')));
    }
    if (missing.isNotEmpty) {
      RequiredFieldAlert.show(context, lang: _currentLang, missingFields: missing);
      return;
    }

    setState(() => _isSaving = true);
    final userId = Supabase.instance.client.auth.currentUser!.id;
    String? imageUrl = _existingImageUrl;

    try {
      if (_pickedImageFile != null || _pickedImageBytes != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}';
        final filePath = '$userId/$fileName'; 
        final fileOptions = FileOptions(contentType: 'image/jpeg');

        if (kIsWeb) {
          await Supabase.instance.client.storage.from('report_images').uploadBinary(filePath, _pickedImageBytes!, fileOptions: fileOptions);
        } else {
          await Supabase.instance.client.storage.from('report_images').upload(filePath, _pickedImageFile!, fileOptions: fileOptions);
        }
        imageUrl = Supabase.instance.client.storage.from('report_images').getPublicUrl(filePath);
      }

      final data = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'priority': _selectedPriority,
        'image_url': imageUrl,
      };

      if (_isEditMode) {
        data['edited_at'] = DateTime.now().toUtc().toIso8601String();
        await Supabase.instance.client.from('help_reports').update(data).eq('id', widget.report!['id']);
      } else {
        data['user_id'] = userId;
        data['status'] = 'Dikirim';
        await Supabase.instance.client.from('help_reports').insert(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(getTxt('report_saved')), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildFormLabel(String label, IconData icon, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF1D72F3)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: const Color(0xFF1D72F3),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          if (required) ...[
            const SizedBox(width: 3),
            Text('*', style: GoogleFonts.poppins(color: const Color(0xFFEF4444), fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: const Color(0xFF1D72F3).withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: const Color(0xFF1D72F3), size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityField() {
    final hasValue = _selectedPriority != null;
    final label = hasValue
        ? (_selectedPriority!.toLowerCase() == 'fatal' ? getTxt('fatal') : getTxt('normal'))
        : getTxt('select_priority');
    final color = hasValue ? _priorityColor(_selectedPriority!) : Colors.grey.shade400;
    final icon = hasValue ? _priorityIcon(_selectedPriority!) : Icons.flag_outlined;

    return GestureDetector(
      onTap: _isEditing ? _showPriorityPicker : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _isEditing ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasValue ? color.withOpacity(0.4) : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  color: hasValue ? Colors.black87 : Colors.black38,
                ),
              ),
            ),
            if (_isEditing) Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showPriorityPicker() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1D72F3).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.flag_rounded, color: Color(0xFF1D72F3), size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                getTxt('select_priority'),
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
              ),
              const SizedBox(height: 18),
              _priorityOption('Fatal', getTxt('fatal'), Icons.warning_amber_rounded, const Color(0xFFEF4444)),
              const SizedBox(height: 10),
              _priorityOption('Normal', getTxt('normal'), Icons.info_outline_rounded, const Color(0xFF0EA5E9)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(getTxt('no'), style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priorityOption(String value, String label, IconData icon, Color color) {
    final isSelected = _selectedPriority == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPriority = value);
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
            ),
            if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    Widget imageContent;

    if (_pickedImageBytes != null) {
      imageContent = Image.memory(_pickedImageBytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    } else if (_pickedImageFile != null) {
      imageContent = Image.file(_pickedImageFile!, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      imageContent = Image.network(
        _existingImageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (c, e, s) => _buildPlaceholder(getTxt('add_here')),
      );
    } else {
      imageContent = _buildPlaceholder(getTxt('add_here'));
    }

    final bool hasImage = _pickedImageBytes != null ||
        _pickedImageFile != null ||
        (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);

    if (!hasImage) {
      return DottedBorder(
        color: _isEditing ? const Color(0xFF1D72F3) : Colors.grey.shade400,
        strokeWidth: 1.5,
        dashPattern: const [6, 4],
        borderType: BorderType.RRect,
        radius: const Radius.circular(16),
        child: GestureDetector(
          onTap: _isEditing ? _openCamera : null,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: imageContent,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1D72F3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: _openFullImageViewer,
              child: imageContent,
            ),
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
                      Colors.black.withOpacity(0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            if (_isEditing)
              Positioned(
                bottom: 10,
                right: 10,
                child: GestureDetector(
                  onTap: _openCamera,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15),
                        const SizedBox(width: 6),
                        Text(
                          getTxt('change_photo'),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12.5,
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

  Widget _buildPlaceholder(String text, {IconData icon = Icons.add_photo_alternate_outlined}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF1E3A8A), size: 30),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00C9E4), width: 2)),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1D72F3)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditMode
              ? (_isEditing ? getTxt('edit_report') : getTxt('report_detail'))
              : getTxt('new_report'),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D72F3),
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
        actions: [
          if (_isEditMode && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF1D72F3)),
              tooltip: getTxt('edit_report'),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AbsorbPointer(
                      absorbing: !_isEditing,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormLabel(getTxt('photo_attachment'), Icons.camera_alt_rounded, required: true),
                          _buildImagePicker(),
                          _buildFormLabel(getTxt('title'), Icons.title_rounded, required: true),
                          TextFormField(
                            controller: _titleController,
                            style: GoogleFonts.poppins(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                            decoration: inputDecoration.copyWith(hintText: getTxt('title_hint')),
                          ),
                          _buildFormLabel(getTxt('priority'), Icons.flag_rounded, required: true),
                          _buildPriorityField(),
                          _buildFormLabel(getTxt('problem_desc'), Icons.description_rounded, required: true),
                          TextFormField(
                            controller: _descriptionController,
                            style: GoogleFonts.poppins(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                            decoration: inputDecoration,
                            maxLines: 5,
                            minLines: 3,
                          ),
                        ],
                      ),
                    ),
                    if (_isEditMode) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black.withOpacity(0.06)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF1D72F3)),
                              const SizedBox(width: 6),
                              Text(getTxt('status'), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1D72F3))),
                              const Spacer(),
                              _tagIcon(
                                _statusIcon(widget.report!['status'] ?? 'Dikirim'),
                                _statusLabel(widget.report!['status'] ?? 'Dikirim'),
                                _statusColor(widget.report!['status'] ?? 'Dikirim'),
                              ),
                            ]),
                            const SizedBox(height: 14),
                            Container(height: 1, color: Colors.grey.shade100),
                            const SizedBox(height: 10),
                            _buildInfoRow(
                                Icons.calendar_today_outlined,
                                getTxt('created_at'),
                                _formatDateTime(widget.report!['created_at'])),
                            if (widget.report!['edited_at'] != null)
                              _buildInfoRow(
                                  Icons.edit_calendar_outlined,
                                  getTxt('edited_at'),
                                  _formatDateTime(widget.report!['edited_at'])),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D72F3),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor:
                        const Color(0xFF1D72F3).withOpacity(0.4),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  onPressed: _isSaving ? null : _saveReport,
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3))
                      : Text(
                          _isEditMode
                              ? getTxt('update')
                              : getTxt('submit'),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReportImageViewer extends StatelessWidget {
  final Uint8List? imageBytes;
  final File? imageFile;
  final String? imageUrl;

  const _ReportImageViewer({this.imageBytes, this.imageFile, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (imageBytes != null) {
      content = Image.memory(imageBytes!, fit: BoxFit.contain);
    } else if (imageFile != null) {
      content = Image.file(imageFile!, fit: BoxFit.contain);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      content = Image.network(
        imageUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.white54, size: 60),
      );
    } else {
      content = const Icon(Icons.image_not_supported, color: Colors.white54, size: 60);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black.withOpacity(0.001)),
            ),
          ),
          Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: content,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}