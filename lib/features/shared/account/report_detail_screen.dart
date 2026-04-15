// report_detail_screen.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dotted_border/dotted_border.dart';

class ReportDetailScreen extends StatefulWidget {
  final String lang;
  final Map<String, dynamic>? report;

  const ReportDetailScreen({super.key, required this.lang, this.report});

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
  bool _isEditing = false; // Untuk beralih antara mode lihat dan edit
  bool get _isEditMode => widget.report != null;

  // State untuk gambar laporan
  File? _pickedImageFile;
  Uint8List? _pickedImageBytes;
  String? _existingImageUrl;

  // State untuk komentar
  List<Map<String, dynamic>> _comments = [];
  bool _commentsLoading = true;
  bool _isSendingComment = false;
  File? _commentImageFile;
  Uint8List? _commentImageBytes;

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
      'title': 'Title*',
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
      'title': 'Judul*',
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
      'title': '标题*',
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
    },
  };

  String getTxt(String key) => _txt[_currentLang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _currentLang = widget.lang;
    _isEditing = !_isEditMode;

    if (_isEditMode) {
      final report = widget.report!;
      _titleController.text = report['title'] ?? '';
      _descriptionController.text = report['description'] ?? '';
      _selectedPriority = report['priority'];
      
      _loadInitialImage();
      
      _fetchComments();
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

  // --- LOGIC UNTUK GAMBAR LAPORAN ---
  Future<void> _pickReportImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _pickedImageBytes = bytes);
      } else {
        setState(() => _pickedImageFile = File(pickedFile.path));
      }
    }
  }

  // --- LOGIC UNTUK GAMBAR KOMENTAR ---
  Future<void> _pickCommentImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _commentImageBytes = bytes);
      } else {
        setState(() => _commentImageFile = File(pickedFile.path));
      }
    }
  }

  void _clearCommentImage() {
    setState(() {
      _commentImageFile = null;
      _commentImageBytes = null;
    });
  }

  // --- LOGIC UNTUK DATABASE ---
  Future<void> _saveReport() async {
    if (!_formKey.currentState!.validate()) return;

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
        data['edited_at'] = DateTime.now().toIso8601String();
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

  Future<void> _deleteReport() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getTxt('delete')),
        content: Text(getTxt('delete_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(getTxt('no'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(getTxt('yes'), style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);
    try {
      final reportId = widget.report!['id'];
      // Cascade delete akan menghapus komentar terkait secara otomatis.
      await Supabase.instance.client.from('help_reports').delete().eq('id', reportId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(getTxt('report_deleted')), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _fetchComments() async {
    if (!mounted) return;
    setState(() => _commentsLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('report_comments')
          .select()
          .eq('report_id', widget.report!['id'])
          .order('created_at', ascending: true);

      final commentsWithUrls = <Map<String, dynamic>>[];
      for (var comment in response) {
        final newComment = Map<String, dynamic>.from(comment);
        final imageUrl = newComment['image_url'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            final path = imageUrl.split('/comment_images/').last;
            final signedUrl = await Supabase.instance.client.storage
                .from('comment_images')
                .createSignedUrl(path, 3600);
            newComment['signed_image_url'] = signedUrl;
          } catch (e) {
            newComment['signed_image_url'] = null;
          }
        }
        commentsWithUrls.add(newComment);
      }

      if (mounted) {
        setState(() {
          _comments = commentsWithUrls;
          _commentsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _commentsLoading = false);
        // Tampilkan error di snackbar agar lebih terlihat
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error fetching comments: $e"),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty && _commentImageFile == null && _commentImageBytes == null) return;

    setState(() => _isSendingComment = true);
    final userId = Supabase.instance.client.auth.currentUser!.id;
    String? imageUrl;

    try {
      if (_commentImageFile != null || _commentImageBytes != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}';
        final filePath = '$userId/$fileName';
        final fileOptions = FileOptions(contentType: 'image/jpeg');

        if (kIsWeb) {
        await Supabase.instance.client.storage
            .from('comment_images') // <--- HARUS 'comment_images'
            .uploadBinary(filePath, _commentImageBytes!, fileOptions: fileOptions);
      } else {
        await Supabase.instance.client.storage
            .from('comment_images') // <--- HARUS 'comment_images'
            .upload(filePath, _commentImageFile!, fileOptions: fileOptions);
      }
      imageUrl = Supabase.instance.client.storage
          .from('comment_images') // <--- HARUS 'comment_images'
          .getPublicUrl(filePath);
    
      }

      final data = {
        'report_id': widget.report!['id'],
        'user_id': userId,
        'comment_text': text.isNotEmpty ? text : null,
        'image_url': imageUrl,
      };

      await Supabase.instance.client.from('report_comments').insert(data);
      if (mounted) {
        _commentController.clear();
        _clearCommentImage();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(getTxt('comment_sent')), backgroundColor: Colors.green));
        _fetchComments(); // Refresh comment list
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending comment: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSendingComment = false);
    }
  }

  // --- WIDGET BUILDERS ---

  Widget _buildFormLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16),
      child: Text(label, style: const TextStyle(color: Color(0xFF475569), fontSize: 15, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Color(0xFF334155), fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    Widget imageContent;

    if (_pickedImageBytes != null) {
      imageContent = Image.memory(_pickedImageBytes!, fit: BoxFit.cover, width: double.infinity);
    } else if (_pickedImageFile != null) {
      imageContent = Image.file(_pickedImageFile!, fit: BoxFit.cover, width: double.infinity);
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      imageContent = Image.network(_existingImageUrl!, fit: BoxFit.cover, width: double.infinity,
        errorBuilder: (c, e, s) => _buildPlaceholder(getTxt('add_here')));
    } else {
      imageContent = _buildPlaceholder(getTxt('add_here'));
    }

    return DottedBorder(
      color: _isEditing ? const Color(0xFF1E3A8A) : Colors.grey.shade400,
      strokeWidth: 1.5,
      dashPattern: const [6, 4],
      borderType: BorderType.RRect,
      radius: const Radius.circular(12),
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(11), child: imageContent),
            if (_isEditing)
              GestureDetector(
                onTap: _pickReportImage,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(_existingImageUrl != null || _pickedImageFile != null || _pickedImageBytes != null ? 0.5 : 0),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: _existingImageUrl == null && _pickedImageFile == null && _pickedImageBytes == null
                    ? null
                    : _buildPlaceholder(getTxt('change_photo'), icon: Icons.edit_outlined),
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

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_commentImageBytes != null || _commentImageFile != null)
            _buildCommentImagePreview(),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.photo_camera_back_outlined, color: Colors.grey.shade600),
                onPressed: _pickCommentImage,
              ),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: getTxt('type_comment'),
                    border: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
              _isSendingComment
                ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : IconButton(
                    icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                    onPressed: _sendComment,
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentImagePreview() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 40),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _commentImageBytes != null
              ? Image.memory(_commentImageBytes!, height: 80, fit: BoxFit.cover)
              : Image.file(_commentImageFile!, height: 80, fit: BoxFit.cover),
          ),
          Positioned(
            top: -4, right: -4,
            child: GestureDetector(
              onTap: _clearCommentImage,
              child: Container(
                decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          )
        ],
      ),
    );
  }
  
  Widget _buildCommentsList() {
    if (_commentsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Text(getTxt('no_comments'), style: TextStyle(color: Colors.grey.shade600)),
        ),
      );
    }
    return ListView.builder(
      itemCount: _comments.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final comment = _comments[index];
        final signedImageUrl = comment['signed_image_url'] as String?;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(backgroundColor: Colors.grey.shade200, child: const Icon(Icons.person, color: Colors.grey)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "User ${comment['user_id'].toString().substring(0, 8)}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                    Text(
                      _formatDateTime(comment['created_at']),
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                    if (comment['comment_text'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(comment['comment_text']),
                      ),
                    if (signedImageUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(signedImageUrl, height: 120, fit: BoxFit.cover,
                            errorBuilder: (c, e, s) {
                              print("Error loading comment image: $e");
                              return Container(height: 120, color: Colors.grey.shade200, child: Center(child: Icon(Icons.broken_image)));
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: _isEditing ? Colors.white : Colors.grey.shade200,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5)),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _isEditMode ? (_isEditing ? getTxt('edit_report') : getTxt('report_detail')) : getTxt('new_report'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
        ),
        backgroundColor: Colors.transparent, elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
        centerTitle: true,
        actions: [
          if (_isEditMode && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: getTxt('edit_report'),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditMode && _isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: getTxt('delete'),
              onPressed: _isSaving ? null : _deleteReport,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: AbsorbPointer(
                  absorbing: !_isEditing,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormLabel(getTxt('photo_attachment')),
                      _buildImagePicker(),
                      
                      _buildFormLabel(getTxt('title')),
                      TextFormField(
                        controller: _titleController,
                        decoration: inputDecoration.copyWith(hintText: getTxt('title_hint')),
                        validator: (val) => val == null || val.isEmpty ? getTxt('title_empty_error') : null,
                      ),
                      
                      _buildFormLabel(getTxt('priority')),
                      DropdownButtonFormField<String>(
                        value: _selectedPriority,
                        onChanged: (val) => setState(() => _selectedPriority = val),
                        decoration: inputDecoration.copyWith(
                          fillColor: _isEditing ? Colors.white : Colors.grey.shade200,
                        ),
                        items: [
                          DropdownMenuItem(value: 'Fatal', child: Text(getTxt('fatal'))),
                          DropdownMenuItem(value: 'Normal', child: Text(getTxt('normal'))),
                        ],
                        validator: (val) => val == null ? getTxt('priority_empty_error') : null,
                      ),

                      _buildFormLabel(getTxt('problem_desc')),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: inputDecoration,
                        maxLines: 5,
                        minLines: 3,
                      ),

                      if (_isEditMode) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        _buildInfoRow(Icons.calendar_today_outlined, getTxt('created_at'), _formatDateTime(widget.report!['created_at'])),
                        if (widget.report!['edited_at'] != null)
                          _buildInfoRow(Icons.edit_calendar_outlined, getTxt('edited_at'), _formatDateTime(widget.report!['edited_at'])),
                        const Divider(),
                        _buildFormLabel(getTxt('comments')),
                        _buildCommentsList(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    disabledBackgroundColor: Colors.grey.shade400,
                  ),
                  onPressed: _isSaving ? null : _saveReport,
                  child: _isSaving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : Text(_isEditMode ? getTxt('update') : getTxt('submit'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            if (_isEditMode && !_isEditing)
              _buildCommentInput(),
          ],
        ),
      ),
    );
  }
}