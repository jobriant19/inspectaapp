import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../user/finding/finding_pick_pic.dart';
import '../../user/home/alert/required_field_alert.dart';

class AdminHelpReportsScreen extends StatefulWidget {
  final String lang;
  const AdminHelpReportsScreen({super.key, required this.lang});

  @override
  State<AdminHelpReportsScreen> createState() => _AdminHelpReportsScreenState();
}

class _AdminHelpReportsScreenState extends State<AdminHelpReportsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String _filterStatus = 'Semua';
  String _searchQuery = '';
  int _currentPage = 1;
  static const int _perPage = 8;

  List<Map<String, dynamic>> get _searchFiltered {
    final all = _t('all');
    List<Map<String, dynamic>> base = _items;

    // FILTER STATUS
    if (_filterStatus != all) {
      const statusMap = {
        'Dikirim': 'Dikirim', 'Sent': 'Dikirim', '已发送': 'Dikirim',
        'Dilihat': 'Dilihat', 'Viewed': 'Dilihat', '已查看': 'Dilihat',
        'Selesai': 'Selesai', 'Completed': 'Selesai', '已完成': 'Selesai',
      };
      final dbStatus = statusMap[_filterStatus] ?? _filterStatus;
      base = base.where((i) => i['status'] == dbStatus).toList();
    }

    // FILTER SEARCH
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      base = base.where((i) {
        final title =
            (i['title'] as String? ?? '').toLowerCase();
        final userName =
            (i['_userName'] as String? ?? '').toLowerCase();
        return title.contains(q) || userName.contains(q);
      }).toList();
    }

    return base;
  }

  // ignore: unused_field
  Uint8List? _replyImageBytes;
  // ignore: unused_field
  String? _replyImageExt;

  String _t(String key) {
    const txt = {
      'ID': {
        'title': 'Laporan Bantuan',
        'all': 'Semua',
        'sent': 'Dikirim',
        'viewed': 'Dilihat',
        'completed': 'Selesai',
        'priority': 'Prioritas',
        'status': 'Status',
        'empty': 'Tidak ada laporan.',
        'fatal': 'Fatal',
        'normal': 'Normal',
        'change_status': 'Ubah Status',
        'cancel': 'Batal',
        'delete_confirm': 'Hapus laporan ini?',
        'delete_desc': 'Tindakan ini tidak dapat dibatalkan.',
        'delete': 'Hapus',
        'success_status': 'Status berhasil diperbarui.',
        'success_delete': 'Laporan berhasil dihapus.',
        'success_reply': 'Balasan berhasil dikirim.',
        'error': 'Terjadi kesalahan.',
        'reporter': 'Pelapor',
        'date': 'Tanggal',
        'description': 'Deskripsi',
        'no_desc': 'Tidak ada deskripsi.',
        'view_detail': 'Detail Laporan',
        'close': 'Tutup',
        'admin_reply': 'Balasan Admin',
        'reply_hint': 'Tulis balasan untuk user...',
        'send_reply': 'Kirim Balasan',
        'reply_label': 'Dibalas',
        'no_reply': 'Belum ada balasan.',
        'replied_at': 'Dibalas pada',
        'reply_image': 'Gambar Balasan',
        'pick_image': 'Pilih Gambar',
        'search_hint': 'Cari laporan atau pelapor...',
        'report_count': 'laporan',
        'empty_all_title': 'Belum Ada Laporan',
        'empty_all_desc': 'Belum ada laporan bantuan yang masuk.',
        'empty_sent_title': 'Tidak Ada Laporan Terkirim',
        'empty_sent_desc': 'Belum ada laporan dengan status dikirim.',
        'empty_viewed_title': 'Tidak Ada Laporan Dilihat',
        'empty_viewed_desc': 'Belum ada laporan yang sedang ditinjau.',
        'empty_completed_title': 'Belum Ada Laporan Selesai',
        'empty_completed_desc': 'Laporan yang sudah selesai akan muncul di sini.',
        'empty_search_title': 'Laporan Tidak Ditemukan',
        'empty_search_desc': 'Coba kata kunci pencarian lain.',
        'close_image': 'Tutup',
        'delete_name_confirm': 'Yakin ingin menghapus laporan',
        'edit_reply': 'Edit Balasan',
        'delete_reply': 'Hapus Balasan',
        'delete_reply_confirm': 'Hapus balasan ini?',
        'delete_reply_desc': 'User tidak akan lagi melihat balasan ini.',
        'success_delete_reply': 'Balasan berhasil dihapus.',
        'reply_required': 'Balasan wajib diisi',
      },
      'EN': {
        'title': 'Help Reports',
        'all': 'All',
        'sent': 'Sent',
        'viewed': 'Viewed',
        'completed': 'Completed',
        'priority': 'Priority',
        'status': 'Status',
        'empty': 'No reports found.',
        'fatal': 'Fatal',
        'normal': 'Normal',
        'change_status': 'Change Status',
        'cancel': 'Cancel',
        'delete_confirm': 'Delete this report?',
        'delete_desc': 'This action cannot be undone.',
        'delete': 'Delete',
        'success_status': 'Status updated successfully.',
        'success_delete': 'Report deleted successfully.',
        'success_reply': 'Reply sent successfully.',
        'error': 'An error occurred.',
        'reporter': 'Reporter',
        'date': 'Date',
        'description': 'Description',
        'no_desc': 'No description.',
        'view_detail': 'Report Detail',
        'close': 'Close',
        'admin_reply': 'Admin Reply',
        'reply_hint': 'Write a reply for the user...',
        'send_reply': 'Send Reply',
        'reply_label': 'Replied',
        'no_reply': 'No reply yet.',
        'replied_at': 'Replied at',
        'reply_image': 'Reply Image',
        'pick_image': 'Pick Image',
        'search_hint': 'Search reports or reporter...',
        'report_count': 'reports',
        'empty_all_title': 'No Reports Yet',
        'empty_all_desc': 'No help reports have come in yet.',
        'empty_sent_title': 'No Sent Reports',
        'empty_sent_desc': 'There are no reports with sent status.',
        'empty_viewed_title': 'No Viewed Reports',
        'empty_viewed_desc': 'No reports are currently being reviewed.',
        'empty_completed_title': 'No Completed Reports',
        'empty_completed_desc': 'Completed reports will appear here.',
        'empty_search_title': 'No Reports Found',
        'empty_search_desc': 'Try a different search keyword.',
        'close_image': 'Close',
        'delete_name_confirm': 'Are you sure you want to delete report',
        'edit_reply': 'Edit Reply',
        'delete_reply': 'Delete Reply',
        'delete_reply_confirm': 'Delete this reply?',
        'delete_reply_desc': 'The user will no longer see this reply.',
        'success_delete_reply': 'Reply deleted successfully.',
        'reply_required': 'Reply is required',
      },
      'ZH': {
        'title': '帮助报告',
        'all': '全部',
        'sent': '已发送',
        'viewed': '已查看',
        'completed': '已完成',
        'priority': '优先级',
        'status': '状态',
        'empty': '没有报告。',
        'fatal': '致命',
        'normal': '普通',
        'change_status': '更改状态',
        'cancel': '取消',
        'delete_confirm': '删除此报告？',
        'delete_desc': '此操作无法撤销。',
        'delete': '删除',
        'success_status': '状态更新成功。',
        'success_delete': '报告删除成功。',
        'success_reply': '回复发送成功。',
        'error': '发生错误。',
        'reporter': '报告人',
        'date': '日期',
        'description': '描述',
        'no_desc': '无描述。',
        'view_detail': '报告详情',
        'close': '关闭',
        'admin_reply': '管理员回复',
        'reply_hint': '为用户写回复...',
        'send_reply': '发送回复',
        'reply_label': '已回复',
        'no_reply': '暂无回复。',
        'replied_at': '回复于',
        'reply_image': '回复图片',
        'pick_image': '选择图片',
        'search_hint': '搜索报告或报告人...',
        'report_count': '条报告',
        'empty_all_title': '暂无报告',
        'empty_all_desc': '还没有收到帮助报告。',
        'empty_sent_title': '没有已发送的报告',
        'empty_sent_desc': '没有状态为已发送的报告。',
        'empty_viewed_title': '没有已查看的报告',
        'empty_viewed_desc': '目前没有正在审核的报告。',
        'empty_completed_title': '没有已完成的报告',
        'empty_completed_desc': '已完成的报告将显示在这里。',
        'empty_search_title': '未找到报告',
        'empty_search_desc': '请尝试其他关键词。',
        'close_image': '关闭',
        'delete_name_confirm': '确定要删除报告',
        'edit_reply': '编辑回复',
        'delete_reply': '删除回复',
        'delete_reply_confirm': '删除此回复？',
        'delete_reply_desc': '用户将不再看到此回复。',
        'success_delete_reply': '回复删除成功。',
        'reply_required': '回复为必填项',
      },
    };
    return txt[widget.lang]?[key] ?? txt['ID']![key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _filterStatus = _t('all');
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final List<dynamic> reportsRaw = await Supabase.instance.client
          .from('help_reports')
          .select('*')
          .order('created_at', ascending: false)
          .limit(1000);

      debugPrint('DEBUG help_reports count: ${reportsRaw.length}');

      if (reportsRaw.isEmpty) {
        if (mounted) setState(() { _items = []; _isLoading = false; });
        return;
      }

      final userIds = reportsRaw
          .map((r) => r['user_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      Map<String, Map<String, dynamic>> userMap = {};
      if (userIds.isNotEmpty) {
        final List<dynamic> usersRaw = await Supabase.instance.client
            .from('User')
            .select('id_user, nama, gambar_user, id_jabatan, is_verificator, jabatan(nama_jabatan)')
            .inFilter('id_user', userIds);
        for (final u in usersRaw) {
          userMap[u['id_user'].toString()] = Map<String, dynamic>.from(u);
        }
      }

      final List<Map<String, dynamic>> processed = [];
      for (final item in reportsRaw) {
        final newItem = Map<String, dynamic>.from(item);

        final uid = newItem['user_id']?.toString() ?? '';
        newItem['_userName']   = userMap[uid]?['nama'] as String? ?? '-';
        newItem['_userAvatar'] = userMap[uid]?['gambar_user'] as String?;
        newItem['_userIdJabatan'] = userMap[uid]?['id_jabatan'] as int?;
        newItem['_userIsVerificator'] = userMap[uid]?['is_verificator'] as bool?;
        newItem['_userJabatanNama'] =
            (userMap[uid]?['jabatan'] as Map?)?['nama_jabatan'] as String?;

        final imageUrl = newItem['image_url'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            final path = imageUrl.split('/report_images/').last;
            final signedUrl = await Supabase.instance.client.storage
                .from('report_images')
                .createSignedUrl(path, 3600);
            newItem['signed_image_url'] = signedUrl;
          } catch (_) {
            newItem['signed_image_url'] = null;
          }
        }

        final replyImageUrl = newItem['admin_reply_image'] as String?;
        if (replyImageUrl != null && replyImageUrl.isNotEmpty) {
          try {
            final path = replyImageUrl.split('/report_images/').last;
            final signedReplyUrl = await Supabase.instance.client.storage
                .from('report_images')
                .createSignedUrl(path, 3600);
            newItem['signed_admin_reply_image'] = signedReplyUrl;
          } catch (_) {
            newItem['signed_admin_reply_image'] = null;
          }
        }
        processed.add(newItem);
      }

      if (mounted) {
        setState(() {
          _items = processed;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching help reports: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack(_t('error'), isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: isError ? Colors.red : const Color(0xFF0EA5E9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('help_reports')
          .update({'status': newStatus}).eq('id', id);
      if (mounted) {
        setState(() {
          final idx = _items.indexWhere((e) => e['id'] == id);
          if (idx != -1) _items[idx]['status'] = newStatus;
        });
      }
    } catch (e) {
      _showSnack(_t('error'), isError: true);
    }
  }

  Future<Map<String, dynamic>?> _sendReply(String id, String replyText, {Uint8List? imageBytes, String? imageExt}) async {
    try {
      String? replyImageUrl;

      // UPLOAD IMAGE
      if (imageBytes != null && imageExt != null) {
        final fileName = 'reply_${id}_${DateTime.now().millisecondsSinceEpoch}.$imageExt';
        final filePath = 'reply_images/$fileName';
        final contentType = imageExt == 'png' ? 'image/png' : 'image/jpeg';

        await Supabase.instance.client.storage
            .from('report_images')
            .uploadBinary(
              filePath,
              imageBytes,
              fileOptions: FileOptions(contentType: contentType, upsert: true),
            );

        replyImageUrl = Supabase.instance.client.storage
            .from('report_images')
            .getPublicUrl(filePath);
      }
      
      final updated = await Supabase.instance.client.from('help_reports').update({
        'admin_reply': replyText,
        'replied_at': DateTime.now().toUtc().toIso8601String(),
        'status': 'Selesai',
        if (replyImageUrl != null) 'admin_reply_image': replyImageUrl,
      }).eq('id', id).select().single();

      final newItem = Map<String, dynamic>.from(updated);

      final riu = newItem['admin_reply_image'] as String?;
      if (riu != null && riu.isNotEmpty) {
        try {
          final path = riu.split('/report_images/').last;
          final signed = await Supabase.instance.client.storage
              .from('report_images')
              .createSignedUrl(path, 3600);
          newItem['signed_admin_reply_image'] = signed;
        } catch (_) {
          newItem['signed_admin_reply_image'] = null;
        }
      } else {
        newItem['signed_admin_reply_image'] = null;
      }

      if (mounted) {
        setState(() {
          final idx = _items.indexWhere((e) => e['id'] == id);
          if (idx != -1) {
            _items[idx] = {..._items[idx], ...newItem};
          }
        });
      }
      return newItem;
    } catch (e) {
      debugPrint('Error send reply: $e');
      _showSnack(_t('error'), isError: true);
      return null;
    }
  }

  Future<Map<String, dynamic>?> _deleteReply(String id) async {
    try {
      final updated = await Supabase.instance.client.from('help_reports').update({
        'admin_reply': null,
        'replied_at': null,
        'admin_reply_image': null,
        'status': 'Dilihat',
      }).eq('id', id).select().single();

      final newItem = Map<String, dynamic>.from(updated);
      newItem['signed_admin_reply_image'] = null;

      if (mounted) {
        setState(() {
          final idx = _items.indexWhere((e) => e['id'] == id);
          if (idx != -1) {
            _items[idx] = {..._items[idx], ...newItem};
          }
        });
      }
      return newItem;
    } catch (e) {
      _showSnack(_t('error'), isError: true);
      return null;
    }
  }

  Future<void> _deleteItem(String id, String title) async {
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
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEBEB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: Color(0xFFEF4444),
                  size: 38,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _t('delete_confirm'),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${_t('delete_name_confirm')} "$title"?',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.delete_forever_rounded,
                      color: Colors.white, size: 18),
                  label: Text(
                    _t('delete'),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
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
                  child: Text(
                    _t('cancel'),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) {
      try {
        await Supabase.instance.client.from('help_reports').delete().eq('id', id);
        _showSnack(_t('success_delete'));
        _fetchData();
      } catch (e) {
        _showSnack(_t('error'), isError: true);
      }
    }
  }

  void _showDetail(Map<String, dynamic> item) {
    if (item['status'] == 'Dikirim') {
      item['status'] = 'Dilihat';
      _updateStatus(item['id'] as String, 'Dilihat');
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _HelpReportDetailScreen(
          item: item,
          lang: widget.lang,
          t: _t,
          localStatus: _localStatus,
          localPriority: _localPriority,
          statusColor: _statusColor,
          priorityColor: _priorityColor,
          priorityIcon: _priorityIcon,
          statusIcon: _statusIcon,
          onSendReply: _sendReply,
          onDeleteReply: _deleteReply,
        ),
      ),
    );
  }

  String _localStatus(String s) {
    switch (s) {
      case 'Dikirim': return _t('sent');
      case 'Dilihat': return _t('viewed');
      case 'Selesai': return _t('completed');
      default: return s;
    }
  }

  String _localPriority(String p) {
    switch (p.toLowerCase()) {
      case 'fatal': return _t('fatal');
      case 'normal': return _t('normal');
      default: return p;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Dikirim': return const Color(0xFF0EA5E9);
      case 'Dilihat': return const Color(0xFFF59E0B);
      case 'Selesai': return const Color(0xFF10B981);
      default: return Colors.grey;
    }
  }

  Color _priorityColor(String p) => p.toLowerCase() == 'fatal' ? const Color(0xFFEF4444) : const Color(0xFF0EA5E9);

  IconData _priorityIcon(String p) =>
      p.toLowerCase() == 'fatal'
          ? Icons.warning_amber_rounded
          : Icons.info_outline_rounded;

  IconData _statusIcon(String s) {
    switch (s) {
      case 'Dikirim':
        return Icons.send_rounded;
      case 'Dilihat':
        return Icons.visibility_rounded;
      case 'Selesai':
        return Icons.check_circle_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0EA5E9);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('title'),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: primaryColor,
            fontSize: 16,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 255, 255, 255), Color.fromARGB(255, 255, 255, 255)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1, color: Colors.white.withValues(alpha:0.15)),
        ),
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.black.withValues(alpha:0.08)),
              ),
              child: TextField(
                onChanged: (v) => setState(() {
                  _searchQuery = v;
                  _currentPage = 1;
                }),
                textAlignVertical: TextAlignVertical.center,
                style: GoogleFonts.poppins(
                    color: const Color(0xFF1E3A8A), fontSize: 14),
                decoration: InputDecoration(
                  hintText: _t('search_hint'),
                  hintStyle: GoogleFonts.poppins(
                      color: Colors.black38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search,
                      color: Colors.black38, size: 20),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          // FILTER TABS
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                _t('all'),
                _t('sent'),
                _t('viewed'),
                _t('completed'),
              ].map((tab) {
                final isActive = _filterStatus == tab;
                Color tabColor;
                IconData tabIcon;
                if (tab == _t('sent')) {
                  tabColor = primaryColor;
                  tabIcon = Icons.send_rounded;
                } else if (tab == _t('viewed')) {
                  tabColor = const Color(0xFFF59E0B);
                  tabIcon = Icons.visibility_rounded;
                } else if (tab == _t('completed')) {
                  tabColor = const Color(0xFF10B981);
                  tabIcon = Icons.check_circle_rounded;
                } else {
                  tabColor = const Color(0xFF6366F1);
                  tabIcon = Icons.list_alt_rounded;
                }

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _filterStatus = tab;
                      _currentPage = 1;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin:
                          EdgeInsets.only(right: tab != _t('completed') ? 6 : 0),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? tabColor
                            : tabColor.withValues(alpha:0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive
                              ? tabColor
                              : tabColor.withValues(alpha:0.25),
                          width: 1.5,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: tabColor.withValues(alpha:0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tabIcon,
                            size: 14,
                            color: isActive
                                ? Colors.white
                                : tabColor,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tab,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? Colors.white
                                  : tabColor,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // COUNT INFO
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha:0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryColor.withValues(alpha:0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fact_check_rounded, size: 13, color: primaryColor),
                    const SizedBox(width: 5),
                    Text(
                      '${_searchFiltered.length} ${_t('report_count')}',
                      style: GoogleFonts.poppins(
                        color: primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // LIST
          Expanded(
            child: Builder(
              builder: (context) {
                final filtered = _searchFiltered;
                final totalPages =
                    filtered.isEmpty ? 1 : (filtered.length / _perPage).ceil();
                final safePage = _currentPage.clamp(1, totalPages);
                final startIdx = (safePage - 1) * _perPage;
                final endIdx = (startIdx + _perPage) > filtered.length
                    ? filtered.length
                    : startIdx + _perPage;
                final pageData = filtered.isEmpty
                    ? <Map<String, dynamic>>[]
                    : filtered.sublist(startIdx, endIdx);

                return Column(
                  children: [
                    Expanded(
                      child: _isLoading
                          ? _buildShimmer()
                          : RefreshIndicator(
                              onRefresh: _fetchData,
                              color: primaryColor,
                              child: filtered.isEmpty
                                  ? _buildEmpty()
                                  : ListView.separated(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 4, 16, 16),
                                      itemCount: pageData.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 10),
                                      itemBuilder: (_, i) =>
                                          _buildCard(pageData[i]),
                                    ),
                            ),
                    ),
                    if (!_isLoading && totalPages > 1)
                      _HelpReportsPageIndicator(
                        currentPage: safePage,
                        totalPages: totalPages,
                        onPageChanged: (p) => setState(() => _currentPage = p),
                        color: primaryColor,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    const primaryColor = Color(0xFF1D72F3);
    final signedUrl  = item['signed_image_url'] as String?;
    final priority   = item['priority'] as String? ?? 'Normal';
    final status     = item['status'] as String? ?? 'Dikirim';
    final createdAt  = item['created_at'] as String?;
    String dateStr   = '';
    if (createdAt != null) {
      try { dateStr = DateFormat('d MMM yyyy').format(DateTime.parse(createdAt).toLocal()); } catch (_) {}
    }

    return GestureDetector(
      onTap: () => _showDetail(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.06), blurRadius: 14, offset: const Offset(0, 4))],
          border: Border(left: BorderSide(color: _statusColor(status), width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE / PLACEHOLDER
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: (signedUrl != null && signedUrl.isNotEmpty)
                    ? Image.network(
                        signedUrl,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imgPlaceholder(),
                      )
                    : _imgPlaceholder(),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TITLE
                    Text(
                      item['title'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // PRIORITY & STATUS
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _tagIcon(_priorityIcon(priority), _localPriority(priority), _priorityColor(priority)),
                        _tagIcon(_statusIcon(status), _localStatus(status), _statusColor(status)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // DATE
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 5),
                          Text(
                            dateStr,
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // DELETE BUTTON
              GestureDetector(
                onTap: () => _deleteItem(item['id'] as String, item['title'] ?? ''),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha:0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tagIcon(IconData icon, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha:0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: color)),
      ],
    ),
  );

  Widget _imgPlaceholder() => Container(
    width: 88, height: 88,
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(Icons.flag_outlined, color: Colors.grey.shade400, size: 32),
  );

  Widget _buildEmpty() {
    final isSearching = _searchQuery.isNotEmpty;
    String titleKey;
    String descKey;
    IconData icon;
    Color color;

    if (isSearching) {
      titleKey = 'empty_search_title';
      descKey = 'empty_search_desc';
      icon = Icons.search_off_rounded;
      color = const Color(0xFF64748B);
    } else if (_filterStatus == _t('sent')) {
      titleKey = 'empty_sent_title';
      descKey = 'empty_sent_desc';
      icon = Icons.send_rounded;
      color = const Color(0xFF0EA5E9);
    } else if (_filterStatus == _t('viewed')) {
      titleKey = 'empty_viewed_title';
      descKey = 'empty_viewed_desc';
      icon = Icons.visibility_rounded;
      color = const Color(0xFFF59E0B);
    } else if (_filterStatus == _t('completed')) {
      titleKey = 'empty_completed_title';
      descKey = 'empty_completed_desc';
      icon = Icons.check_circle_rounded;
      color = const Color(0xFF10B981);
    } else {
      titleKey = 'empty_all_title';
      descKey = 'empty_all_desc';
      icon = Icons.inbox_outlined;
      color = const Color(0xFF6366F1);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              height: 140,
              errorBuilder: (_, __, ___) => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.withValues(alpha:0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 56, color: color.withValues(alpha:0.5)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _t(titleKey),
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w700, color: color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _t(descKey),
              style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black45),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() => ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: 5,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, __) => Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  );
}

class _HelpReportDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final String lang;
  final String Function(String) t;
  final String Function(String) localStatus;
  final String Function(String) localPriority;
  final Color Function(String) statusColor;
  final Color Function(String) priorityColor;
  final IconData Function(String) priorityIcon;
  final IconData Function(String) statusIcon;
  final Future<Map<String, dynamic>?> Function(String id, String replyText, {Uint8List? imageBytes, String? imageExt}) onSendReply;
  final Future<Map<String, dynamic>?> Function(String id) onDeleteReply;

  const _HelpReportDetailScreen({
    required this.item,
    required this.lang,
    required this.t,
    required this.localStatus,
    required this.localPriority,
    required this.statusColor,
    required this.priorityColor,
    required this.priorityIcon,
    required this.statusIcon,
    required this.onSendReply,
    required this.onDeleteReply,
  });

  @override
  State<_HelpReportDetailScreen> createState() => _HelpReportDetailScreenState();
}

class _HelpReportDetailScreenState extends State<_HelpReportDetailScreen> {
  static const primaryColor = Color(0xFF1D72F3);

  late Map<String, dynamic> _item;
  late TextEditingController _replyCtrl;

  bool get _hasReply => (_item['admin_reply'] as String?)?.isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _replyCtrl = TextEditingController(text: _item['admin_reply'] as String? ?? '');
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  String _t(String key) => widget.t(key);

  void _openImageViewer(String url) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha:0.95),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => _FullImageViewer(imageUrl: url, closeLabel: _t('close_image')),
      ),
    );
  }

  Future<void> _handleSendReply(String replyText, Uint8List? imgBytes, String? imgExt) async {
    final result = await widget.onSendReply(_item['id'] as String, replyText, imageBytes: imgBytes, imageExt: imgExt);
    if (!mounted || result == null) return;
    setState(() {
      _item = {..._item, ...result};
    });
    _showSuccessPopup(_t('success_reply'));
  }

  Future<void> _handleDeleteReply() async {
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
              Text(_t('delete_reply_confirm'),
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(_t('delete_reply_desc'),
                  style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B), height: 1.5),
                  textAlign: TextAlign.center),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 18),
                  label: Text(_t('delete'), style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
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
                  child: Text(_t('cancel'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF64748B))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) return;
    final result = await widget.onDeleteReply(_item['id'] as String);
    if (!mounted || result == null) return;
    setState(() {
      _item = {..._item, ...result};
      _replyCtrl.clear();
    });
    _showSuccessPopup(_t('success_delete_reply'));
  }

  void _showSuccessPopup(String message) {
    if (!mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'success',
      barrierColor: Colors.black.withValues(alpha:0.45),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) {
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (ctx.mounted && Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
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
                boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha:0.25), blurRadius: 30, spreadRadius: 3, offset: const Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha:0.25), width: 2),
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 38),
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
                        duration: const Duration(milliseconds: 1800),
                        builder: (_, v, __) => LinearProgressIndicator(
                          value: v,
                          backgroundColor: const Color(0xFF10B981).withValues(alpha:0.12),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
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

  void _showReplyDialog({required bool isEdit}) {
    final replyCtrl = TextEditingController(text: isEdit ? (_item['admin_reply'] as String? ?? '') : '');
    Uint8List? dialogImageBytes;
    String? dialogImageExt;
    final existingImage = _item['signed_admin_reply_image'] as String?;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: primaryColor.withValues(alpha:0.12), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.reply_rounded, color: primaryColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEdit ? _t('edit_reply') : _t('send_reply'),
                          style: GoogleFonts.poppins(color: primaryColor, fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                          child: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                        ),
                      ),
                    ],
                  ),
                ),
                // BODY
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.image_rounded, size: 14, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(_t('reply_image'), style: GoogleFonts.poppins(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                        ]),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () async {
                            final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 800);
                            if (picked != null) {
                              final bytes = await picked.readAsBytes();
                              final ext = picked.name.split('.').last.toLowerCase();
                              setDlg(() {
                                dialogImageBytes = bytes;
                                dialogImageExt = ext.isEmpty ? 'jpg' : ext;
                              });
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: 140,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha:0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: primaryColor.withValues(alpha:0.3), width: 1.3),
                            ),
                            child: dialogImageBytes != null
                                ? Image.memory(dialogImageBytes!, fit: BoxFit.cover)
                                : (existingImage != null && existingImage.isNotEmpty)
                                    ? Image.network(existingImage, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported))
                                    : Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(color: primaryColor.withValues(alpha:0.12), shape: BoxShape.circle),
                                              child: const Icon(Icons.add_photo_alternate_rounded, color: primaryColor, size: 24),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(_t('pick_image'), style: GoogleFonts.poppins(color: primaryColor, fontSize: 13, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(children: [
                          const Icon(Icons.reply_rounded, size: 14, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(_t('admin_reply'), style: GoogleFonts.poppins(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                          const SizedBox(width: 3),
                          Text('*', style: GoogleFonts.poppins(color: const Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: TextField(
                            controller: replyCtrl,
                            maxLines: 4,
                            style: GoogleFonts.poppins(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: _t('reply_hint'),
                              hintStyle: GoogleFonts.poppins(color: Colors.black26, fontSize: 13),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                // FOOTER
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 6, offset: const Offset(0, -2))],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            foregroundColor: Colors.grey.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(_t('cancel'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            final text = replyCtrl.text.trim();
                            if (text.isEmpty) {
                              RequiredFieldAlert.show(
                                context,
                                lang: widget.lang,
                                missingFields: [MissingFieldItem(icon: Icons.reply_rounded, label: _t('reply_required'))],
                              );
                              return;
                            }
                            Navigator.pop(ctx);
                            _handleSendReply(text, dialogImageBytes, dialogImageExt);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            shadowColor: primaryColor.withValues(alpha:0.3),
                          ),
                          child: Text(
                            isEdit ? _t('edit_reply') : _t('send_reply'),
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard({required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.black.withValues(alpha:0.06)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 12, offset: const Offset(0, 4))],
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
          decoration: BoxDecoration(color: color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 12),
        SizedBox(width: 80, child: Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600))),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final signedUrl  = item['signed_image_url'] as String?;
    final userName   = item['_userName'] as String? ?? '-';
    final userAvatar = item['_userAvatar'] as String?;
    final userIdJabatan = item['_userIdJabatan'] as int?;
    final userIsVerificator = item['_userIsVerificator'] as bool?;
    final userJabatanNama = item['_userJabatanNama'] as String?;
    final status     = item['status'] as String? ?? 'Dikirim';
    final createdAt  = item['created_at'] as String?;
    final repliedAt  = item['replied_at'] as String?;
    final existReply = item['admin_reply'] as String? ?? '';
    final existReplyImage = item['signed_admin_reply_image'] as String?;

    String dateStr = '-', repliedStr = '-';
    if (createdAt != null) {
      try { dateStr = DateFormat('d MMM yyyy, HH:mm').format(DateTime.parse(createdAt).toLocal()); } catch (_) {}
    }
    if (repliedAt != null) {
      try { repliedStr = DateFormat('d MMM yyyy, HH:mm').format(DateTime.parse(repliedAt).toLocal()); } catch (_) {}
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_t('view_detail'), style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: primaryColor, fontSize: 16)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: Colors.black.withValues(alpha:0.06))),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (signedUrl != null && signedUrl.isNotEmpty)
            GestureDetector(
              onTap: () => _openImageViewer(signedUrl),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(signedUrl, height: 200, width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(height: 200, color: Colors.grey.shade100, child: const Icon(Icons.image_not_supported, size: 48, color: Colors.black26))),
                  ),
                  Positioned(
                    right: 10, bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha:0.55), shape: BoxShape.circle),
                      child: const Icon(Icons.zoom_out_map_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          Text(item['title'] ?? '', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: primaryColor)),
          const SizedBox(height: 16),

          // REPORTER INFO CARD
          _infoCard(children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: primaryColor.withValues(alpha:0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.info_outline_rounded, size: 15, color: primaryColor),
              ),
              const SizedBox(width: 8),
              Text(_t('reporter'), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: primaryColor)),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: primaryColor.withValues(alpha:0.1),
                backgroundImage: (userAvatar != null && userAvatar.isNotEmpty) ? NetworkImage(userAvatar) : null,
                child: (userAvatar == null || userAvatar.isEmpty) ? const Icon(Icons.person_rounded, color: primaryColor, size: 22) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(userName, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
                  if (userJabatanNama != null && userJabatanNama.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    buildJabatanBadge(idJabatan: userIdJabatan, jabatanNama: userJabatanNama, isVerificator: userIsVerificator, lang: widget.lang),
                  ],
                ]),
              ),
            ]),
          ]),
          const SizedBox(height: 14),

          // DATE, PRIORITY, STATUS, REPLIED CARD
          _infoCard(children: [
            _detailRow(Icons.calendar_today_rounded, _t('date'), dateStr, primaryColor),
            _detailRow(widget.priorityIcon(item['priority'] ?? ''), _t('priority'), widget.localPriority(item['priority'] ?? ''), widget.priorityColor(item['priority'] ?? '')),
            _detailRow(widget.statusIcon(status), _t('status'), widget.localStatus(status), widget.statusColor(status), isLast: existReply.isEmpty),
            if (existReply.isNotEmpty)
              _detailRow(Icons.mark_email_read_rounded, _t('replied_at'), repliedStr, const Color(0xFF10B981), isLast: true),
          ]),
          const SizedBox(height: 14),

          // DESCRIPTION
          _infoCard(children: [
            Row(children: [
              const Icon(Icons.description_rounded, size: 15, color: primaryColor),
              const SizedBox(width: 8),
              Text(_t('description'), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: primaryColor)),
            ]),
            const SizedBox(height: 10),
            Text(
              (item['description'] as String?)?.isNotEmpty == true ? item['description'] : _t('no_desc'),
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.5),
            ),
          ]),

          const SizedBox(height: 20),
          Container(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 20),

          // ADMIN REPLY
          Row(children: [
            const Icon(Icons.reply_rounded, size: 16, color: primaryColor),
            const SizedBox(width: 6),
            Text(_t('admin_reply'), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: primaryColor)),
            const SizedBox(width: 3),
            Text('*', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFEF4444))),
          ]),
          const SizedBox(height: 10),

          if (_hasReply) ...[
            // REPLY VIEW MODE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha:0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha:0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (existReplyImage != null && existReplyImage.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () => _openImageViewer(existReplyImage),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          existReplyImage,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 160,
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    existReply,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showReplyDialog(isEdit: true),
                  icon: const Icon(Icons.edit_rounded, size: 15, color: primaryColor),
                  label: Text(_t('edit_reply'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12.5, color: primaryColor)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handleDeleteReply,
                  icon: const Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFEF4444)),
                  label: Text(_t('delete_reply'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12.5, color: const Color(0xFFEF4444))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]),
          ] else ...[
            // UNREPLY 
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showReplyDialog(isEdit: false),
                icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                label: Text(_t('send_reply'), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _FullImageViewer extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;
  final String closeLabel;

  // ignore: unused_element_parameter
  const _FullImageViewer({this.imageUrl, this.imageBytes, required this.closeLabel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4,
              child: Center(
                child: imageBytes != null
                    ? Image.memory(imageBytes!, fit: BoxFit.contain, width: double.infinity, height: double.infinity)
                    : Image.network(
                        imageUrl!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.white54, size: 60),
                      ),
              ),
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                    ),
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

class _HelpReportsPageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final Color color;

  const _HelpReportsPageIndicator({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.color,
  });

  static const int _maxVisibleButtons = 5;

  List<int> _visiblePageNumbers() {
    if (totalPages <= _maxVisibleButtons) {
      return List.generate(totalPages, (i) => i + 1);
    }
    int start = currentPage - 2;
    int end = currentPage + 2;
    if (start < 1) {
      start = 1;
      end = _maxVisibleButtons;
    } else if (end > totalPages) {
      end = totalPages;
      start = totalPages - (_maxVisibleButtons - 1);
    }
    return List.generate(end - start + 1, (i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    final bool canPrev = currentPage > 1;
    final bool canNext = currentPage < totalPages;
    final pageNumbers = _visiblePageNumbers();

    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double bottomSpacing = bottomInset > 0 ? bottomInset + 10 : 16;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(15, 8, 15, bottomSpacing),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _arrowButton(
              icon: Icons.arrow_back_ios_new_rounded,
              enabled: canPrev,
              onTap: () {
                if (!canPrev) return;
                onPageChanged(currentPage - 1);
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  for (final p in pageNumbers) ...[
                    Expanded(child: _pageButton(p)),
                    if (p != pageNumbers.last) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            _arrowButton(
              icon: Icons.arrow_forward_ios_rounded,
              enabled: canNext,
              onTap: () {
                if (!canNext) return;
                onPageChanged(currentPage + 1);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageButton(int page) {
    final bool isActive = page == currentPage;
    return GestureDetector(
      onTap: () {
        if (page == currentPage) return;
        onPageChanged(page);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: isActive ? null : Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(
          '$page',
          style: GoogleFonts.poppins(
            color: isActive ? Colors.white : color,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _arrowButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 15,
          color: enabled ? color : Colors.grey.shade400,
        ),
      ),
    );
  }
}