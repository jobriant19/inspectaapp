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
  String? _selectedPriority;
  bool _isSaving = false;
  bool _isEditing = false;
  bool get _isEditMode => widget.report != null;

  // State untuk gambar laporan
  File? _pickedImageFile;
  Uint8List? _pickedImageBytes;
  String? _existingImageUrl;

  // State untuk gambar balasan admin (signed URL)
  String? _signedReplyImageUrl;

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
      'status': 'Status',
      'sent': 'Sent',
      'viewed': 'Viewed',
      'completed': 'Completed',
      'photo_empty_error': 'Photo attachment is required',
      'admin_reply': 'Admin Reply',
      'replied_at': 'Replied at',
      'edit': 'Edit',
      'delete_btn': 'Delete',
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
      'status': 'Status',
      'sent': 'Dikirim',
      'viewed': 'Dilihat',
      'completed': 'Selesai',
      'photo_empty_error': 'Lampiran foto wajib diisi',
      'admin_reply': 'Balasan Admin',
      'replied_at': 'Dibalas pada',
      'edit': 'Edit',
      'delete_btn': 'Hapus',
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
      'status': '状态',
      'sent': '已发送',
      'viewed': '已查看',
      'completed': '已完成',
      'photo_empty_error': '必须上传照片',
      'admin_reply': '管理员回复',
      'replied_at': '回复于',
      'edit': '编辑',
      'delete_btn': '删除',
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
      _loadReplyImage();
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
        debugPrint("Error creating signed URL in Detail Screen: $e");
      }
    }
  }

  Future<void> _loadReplyImage() async {
    final url = widget.report?['admin_reply_image'] as String?;
    if (url != null && url.isNotEmpty) {
      try {
        final path = url.split('/report_images/').last;
        final signed = await Supabase.instance.client.storage
            .from('report_images')
            .createSignedUrl(path, 3600);
        if (mounted) setState(() => _signedReplyImageUrl = signed);
      } catch (e) {
        debugPrint('Error signing reply image: $e');
      }
    }
  }

  @override
  void dispose() {
    HelpCenterCameraWarmupService.instance.release();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null) return '-';
    try {
      final dateTimeUtc = DateTime.parse(dateString);
      final dateTimeLocal = dateTimeUtc.toLocal();
      return DateFormat('d MMMM yyyy, HH:mm', _currentLang).format(dateTimeLocal);
    } catch (e) {
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

  void _openReplyImageViewer(String url) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.95),
        pageBuilder: (_, __, ___) => _ReportImageViewer(imageUrl: url),
      ),
    );
  }

  // --- POPUP HASIL AKSI (pengganti snackbar) ---
  void _showResultPopup(String message, {bool isError = false, VoidCallback? onDismissed}) {
    if (!mounted) return;
    final color = isError ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final bgLight = isError ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);
    final icon = isError ? Icons.error_rounded : Icons.check_circle_rounded;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'result',
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) {
        Future.delayed(const Duration(milliseconds: 1600), () {
          if (ctx.mounted && Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
          onDismissed?.call();
        });
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 50),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 30, spreadRadius: 3, offset: const Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      color: bgLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withOpacity(0.25), width: 2),
                    ),
                    child: Icon(icon, color: color, size: 38),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 130,
                      height: 5,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1.0, end: 0.0),
                        duration: const Duration(milliseconds: 1600),
                        builder: (_, v, __) => LinearProgressIndicator(
                          value: v,
                          backgroundColor: color.withOpacity(0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
        setState(() => _isSaving = false);
        _showResultPopup(getTxt('report_saved'), onDismissed: () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showResultPopup('Error: $e', isError: true);
      }
    }
  }

  Future<void> _deleteReport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(color: Color(0xFFFFEBEB), shape: BoxShape.circle),
                child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 38),
              ),
              const SizedBox(height: 20),
              Text(getTxt('delete'), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(getTxt('delete_confirm'), style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B), height: 1.5), textAlign: TextAlign.center),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 18),
                  label: Text(getTxt('yes'), style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(getTxt('no'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF64748B))),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client.from('help_reports').delete().eq('id', widget.report!['id']);
      if (mounted) {
        setState(() => _isSaving = false);
        _showResultPopup(getTxt('report_deleted'), onDismissed: () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showResultPopup('Error: $e', isError: true);
      }
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

  Widget _infoCard({required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.black.withOpacity(0.06)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _detailRow(IconData icon, String label, String value, Color color, {bool isLast = false}) => Padding(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 12),
        SizedBox(width: 90, child: Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600))),
      ],
    ),
  );

  Widget _buildPriorityField() {
    final hasValue = _selectedPriority != null;
    final label = hasValue
        ? (_selectedPriority!.toLowerCase() == 'fatal' ? getTxt('fatal') : getTxt('normal'))
        : getTxt('select_priority');
    final color = hasValue ? _priorityColor(_selectedPriority!) : Colors.grey.shade400;
    final icon = hasValue ? _priorityIcon(_selectedPriority!) : Icons.flag_outlined;

    return GestureDetector(
      onTap: _showPriorityPicker,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
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
            Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400),
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
        color: const Color(0xFF1D72F3),
        strokeWidth: 1.5,
        dashPattern: const [6, 4],
        borderType: BorderType.RRect,
        radius: const Radius.circular(16),
        child: GestureDetector(
          onTap: _openCamera,
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
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.55), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 10, right: 10,
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
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
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

  // ─────────────────────────────────────────────
  // VIEW DETAIL (mode lihat, bergaya seperti admin)
  // ─────────────────────────────────────────────
  Widget _buildViewDetail() {
    final report = widget.report!;
    final status = report['status'] as String? ?? 'Dikirim';
    final createdAt = report['created_at'] as String?;
    final editedAt = report['edited_at'] as String?;
    final repliedAt = report['replied_at'] as String?;
    final adminReply = report['admin_reply'] as String?;
    final canEditDelete = status == 'Dikirim';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
          GestureDetector(
            onTap: _openFullImageViewer,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    _existingImageUrl!,
                    height: 200, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200, color: Colors.grey.shade100,
                      child: const Icon(Icons.image_not_supported, size: 48, color: Colors.black26),
                    ),
                  ),
                ),
                Positioned(
                  right: 10, bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), shape: BoxShape.circle),
                    child: const Icon(Icons.zoom_out_map_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 18),
        Text(report['title'] ?? '', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1D72F3))),
        const SizedBox(height: 16),

        _infoCard(children: [
          _detailRow(Icons.calendar_today_rounded, getTxt('created_at'), _formatDateTime(createdAt), const Color(0xFF1D72F3),
              isLast: editedAt == null && repliedAt == null),
          if (editedAt != null)
            _detailRow(Icons.edit_calendar_outlined, getTxt('edited_at'), _formatDateTime(editedAt), const Color(0xFF6366F1),
                isLast: repliedAt == null),
          _detailRow(_priorityIcon(report['priority'] ?? ''), getTxt('priority'),
              (report['priority'] as String? ?? '').toLowerCase() == 'fatal' ? getTxt('fatal') : getTxt('normal'),
              _priorityColor(report['priority'] ?? '')),
          _detailRow(_statusIcon(status), getTxt('status'), _statusLabel(status), _statusColor(status),
              isLast: repliedAt == null),
          if (repliedAt != null)
            _detailRow(Icons.mark_email_read_rounded, getTxt('replied_at'), _formatDateTime(repliedAt), const Color(0xFF10B981), isLast: true),
        ]),
        const SizedBox(height: 14),

        _infoCard(children: [
          Row(children: [
            const Icon(Icons.description_rounded, size: 15, color: Color(0xFF1D72F3)),
            const SizedBox(width: 8),
            Text(getTxt('problem_desc'), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1D72F3))),
          ]),
          const SizedBox(height: 10),
          Text(
            (report['description'] as String?)?.isNotEmpty == true ? report['description'] : '-',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.5),
          ),
        ]),

        if (adminReply != null && adminReply.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 20),
          Row(children: [
            const Icon(Icons.reply_rounded, size: 16, color: Color(0xFF1D72F3)),
            const SizedBox(width: 6),
            Text(getTxt('admin_reply'), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1D72F3))),
          ]),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_signedReplyImageUrl != null && _signedReplyImageUrl!.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () => _openReplyImageViewer(_signedReplyImageUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        _signedReplyImageUrl!,
                        height: 160, width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 160, color: Colors.grey.shade100,
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  adminReply,
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black, height: 1.6),
                ),
              ],
            ),
          ),
        ],

        if (canEditDelete) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isEditing = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 16),
                        const SizedBox(width: 6),
                        Text(getTxt('edit'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF2563EB))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _isSaving ? null : _deleteReport,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16),
                        const SizedBox(width: 6),
                        Text(getTxt('delete_btn'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFFEF4444))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // EDIT / TAMBAH FORM
  // ─────────────────────────────────────────────
  Widget _buildEditForm(InputDecoration inputDecoration) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D72F3),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: const Color(0xFF1D72F3).withOpacity(0.4),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            onPressed: _isSaving ? null : _saveReport,
            child: _isSaving
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : Text(
                    _isEditMode ? getTxt('update') : getTxt('submit'),
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00C9E4), width: 2)),
    );

    final bool showView = _isEditMode && !_isEditing;

    return Scaffold(
      backgroundColor: showView ? const Color(0xFFF8FAFC) : const Color(0xFFF5F7FA),
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
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1D72F3), fontSize: 18),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: showView
          ? _buildViewDetail()
          : Form(key: _formKey, child: _buildEditForm(inputDecoration)),
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