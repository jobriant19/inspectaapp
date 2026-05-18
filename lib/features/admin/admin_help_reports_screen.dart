import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

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

  List<Map<String, dynamic>> get _searchFiltered {
    final all = _t('all');
    List<Map<String, dynamic>> base = _items;

    // Filter status
    if (_filterStatus != all) {
      const statusMap = {
        'Dikirim': 'Dikirim', 'Sent': 'Dikirim', '已发送': 'Dikirim',
        'Dilihat': 'Dilihat', 'Viewed': 'Dilihat', '已查看': 'Dilihat',
        'Selesai': 'Selesai', 'Completed': 'Selesai', '已完成': 'Selesai',
      };
      final dbStatus = statusMap[_filterStatus] ?? _filterStatus;
      base = base.where((i) => i['status'] == dbStatus).toList();
    }

    // Filter search
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

  Uint8List? _replyImageBytes;
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

  // ── FIX PGRST200: fetch terpisah lalu merge manual ──
  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // Step 1: Ambil semua help_reports — tambahkan .limit(1000) agar tidak terpotong
      final List<dynamic> reportsRaw = await Supabase.instance.client
          .from('help_reports')
          .select('*')
          .order('created_at', ascending: false)
          .limit(1000);

      debugPrint('DEBUG help_reports count: ${reportsRaw.length}'); // ← cek di console

      if (reportsRaw.isEmpty) {
        if (mounted) setState(() { _items = []; _isLoading = false; });
        return;
      }

      // Step 2: Kumpulkan user_id unik
      final userIds = reportsRaw
          .map((r) => r['user_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      // Step 3: Fetch data dari tabel "User" secara terpisah
      Map<String, Map<String, dynamic>> userMap = {};
      if (userIds.isNotEmpty) {
        final List<dynamic> usersRaw = await Supabase.instance.client
            .from('User')
            .select('id_user, nama, gambar_user')
            .inFilter('id_user', userIds);
        for (final u in usersRaw) {
          userMap[u['id_user'].toString()] = Map<String, dynamic>.from(u);
        }
      }

      // Step 4: Merge data + generate signed URLs gambar
      final List<Map<String, dynamic>> processed = [];
      for (final item in reportsRaw) {
        final newItem = Map<String, dynamic>.from(item);

        final uid = newItem['user_id']?.toString() ?? '';
        newItem['_userName']   = userMap[uid]?['nama'] as String? ?? '-';
        newItem['_userAvatar'] = userMap[uid]?['gambar_user'] as String?;

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
        processed.add(newItem);
      }

      if (mounted) {
        setState(() {
          _items = processed;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching help reports: $e'); // ← lihat error detail di console
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

  List<Map<String, dynamic>> get _filtered {
    final all = _t('all');
    if (_filterStatus == all) return _items;
    const statusMap = {
      'Dikirim': 'Dikirim', 'Sent': 'Dikirim', '已发送': 'Dikirim',
      'Dilihat': 'Dilihat', 'Viewed': 'Dilihat', '已查看': 'Dilihat',
      'Selesai': 'Selesai', 'Completed': 'Selesai', '已完成': 'Selesai',
    };
    final dbStatus = statusMap[_filterStatus] ?? _filterStatus;
    return _items.where((i) => i['status'] == dbStatus).toList();
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('help_reports')
          .update({'status': newStatus}).eq('id', id);
      // Update lokal langsung tanpa refetch penuh
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

  // ── Kirim balasan admin → update kolom admin_reply + replied_at + status Selesai ──
  Future<void> _sendReply(String id, String replyText, {Uint8List? imageBytes, String? imageExt}) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      String? replyImageUrl;

      // Upload gambar balasan jika ada
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

      await Supabase.instance.client.from('help_reports').update({
        'admin_reply': replyText,
        'replied_at': now,
        'status': 'Selesai',
        if (replyImageUrl != null) 'admin_reply_image': replyImageUrl,
      }).eq('id', id);

      _showSnack(_t('success_reply'));

      if (mounted) {
        setState(() {
          final idx = _items.indexWhere((e) => e['id'] == id);
          if (idx != -1) {
            _items[idx]['admin_reply'] = replyText;
            _items[idx]['replied_at'] = now;
            _items[idx]['status'] = 'Selesai';
            if (replyImageUrl != null) {
              _items[idx]['admin_reply_image'] = replyImageUrl;
            }
          }
          // Reset state gambar reply
          _replyImageBytes = null;
          _replyImageExt = null;
        });
      }
    } catch (e) {
      debugPrint('Error send reply: $e');
      _showSnack(_t('error'), isError: true);
    }
  }

  Future<void> _deleteItem(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28)),
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
                _t('delete_desc'),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: Color(0xFFE2E8F0), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
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
    final signedUrl  = item['signed_image_url'] as String?;
    final userName   = item['_userName'] as String? ?? '-';
    final createdAt  = item['created_at'] as String?;
    final repliedAt  = item['replied_at'] as String?;
    final existReply = item['admin_reply'] as String? ?? '';
    final existReplyImage = item['admin_reply_image'] as String?;
    final replyCtrl  = TextEditingController(text: existReply);

    // State lokal untuk gambar reply di dalam bottom sheet
    Uint8List? localImageBytes;
    String? localImageExt;

    String dateStr = '-', repliedStr = '-';
    if (createdAt != null) {
      try { dateStr = DateFormat('d MMM yyyy, HH:mm').format(DateTime.parse(createdAt).toLocal()); } catch (_) {}
    }
    if (repliedAt != null) {
      try { repliedStr = DateFormat('d MMM yyyy, HH:mm').format(DateTime.parse(repliedAt).toLocal()); } catch (_) {}
    }

    // Auto set Dilihat jika masih Dikirim
    if (item['status'] == 'Dikirim') {
      item['status'] = 'Dilihat';
      _updateStatus(item['id'] as String, 'Dilihat');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (ctx2, ctrl) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx2).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_t('view_detail'), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A8A))),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx2),
                          child: Text(_t('close'), style: const TextStyle(color: Color(0xFF0EA5E9))),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      controller: ctrl,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Gambar laporan
                        if (signedUrl != null && signedUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(signedUrl, height: 180, width: double.infinity, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 60)),
                          ),
                        const SizedBox(height: 16),
                        Text(item['title'] ?? '', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A8A))),
                        const SizedBox(height: 12),
                        _detailRow(_t('reporter'), userName),
                        _detailRow(_t('date'), dateStr),
                        _detailRow(_t('priority'), _localPriority(item['priority'] ?? '')),
                        _detailRow(_t('status'), _localStatus(item['status'] ?? '')),
                        if (existReply.isNotEmpty) _detailRow(_t('replied_at'), repliedStr),
                        const SizedBox(height: 12),
                        Text(_t('description'), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(
                          (item['description'] as String?)?.isNotEmpty == true ? item['description'] : _t('no_desc'),
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                        ),
                        const SizedBox(height: 20),
                        Container(height: 1, color: Colors.grey.shade100),
                        const SizedBox(height: 20),
                        // Ubah Status
                        Text(_t('change_status'), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black54)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: ['Dikirim', 'Dilihat', 'Selesai'].map((s) {
                            final isSelected = item['status'] == s;
                            final color = _statusColor(s);
                            return GestureDetector(
                              onTap: () { Navigator.pop(ctx2); _updateStatus(item['id'] as String, s); },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? color : color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: color),
                                ),
                                child: Text(_localStatus(s), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : color)),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        Container(height: 1, color: Colors.grey.shade100),
                        const SizedBox(height: 20),
                        // ── Balasan Admin ──
                        Row(
                          children: [
                            const Icon(Icons.reply_rounded, size: 16, color: Color(0xFF0EA5E9)),
                            const SizedBox(width: 6),
                            Text(_t('admin_reply'), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A8A))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: replyCtrl,
                          maxLines: 4,
                          style: GoogleFonts.poppins(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: _t('reply_hint'),
                            hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.black38),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0EA5E9))),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // ── Pilih Gambar Reply ──
                        GestureDetector(
                          onTap: () async {
                            final picked = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 70,
                              maxWidth: 800,
                            );
                            if (picked != null) {
                              final bytes = await picked.readAsBytes();
                              final ext = picked.name.split('.').last.toLowerCase();
                              setSheet(() {
                                localImageBytes = bytes;
                                localImageExt = ext.isEmpty ? 'jpg' : ext;
                              });
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0EA5E9).withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.3), style: BorderStyle.solid),
                            ),
                            child: localImageBytes != null
                                ? Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(localImageBytes!, height: 120, width: double.infinity, fit: BoxFit.cover),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(_t('pick_image'), style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF0EA5E9))),
                                    ],
                                  )
                                : existReplyImage != null && existReplyImage.isNotEmpty
                                    ? Column(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(existReplyImage, height: 120, width: double.infinity, fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported)),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(_t('pick_image'), style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF0EA5E9))),
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.image_outlined, size: 18, color: Color(0xFF0EA5E9)),
                                          const SizedBox(width: 8),
                                          Text(_t('reply_image'), style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF0EA5E9))),
                                        ],
                                      ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Tombol Kirim Balasan ──
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final reply = replyCtrl.text.trim();
                              if (reply.isEmpty) return;
                              Navigator.pop(ctx2);
                              await _sendReply(
                                item['id'] as String,
                                reply,
                                imageBytes: localImageBytes,
                                imageExt: localImageExt,
                              );
                            },
                            icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                            label: Text(_t('send_reply'), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0EA5E9),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 90, child: Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600))),
        const Text(': ', style: TextStyle(color: Colors.black45)),
        Expanded(child: Text(value, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF1E3A8A), fontWeight: FontWeight.w600))),
      ],
    ),
  );

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

  Color _priorityColor(String p) =>
      p.toLowerCase() == 'fatal' ? const Color(0xFFEF4444) : const Color(0xFF0EA5E9);

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
              height: 1, color: Colors.white.withOpacity(0.15)),
        ),
      ),
      body: Column(
        children: [
          // ── Search Bar ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.black.withOpacity(0.08)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.poppins(
                    color: const Color(0xFF1E3A8A), fontSize: 14),
                decoration: InputDecoration(
                  hintText: _t('search_hint'),
                  hintStyle: GoogleFonts.poppins(
                      color: Colors.black38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search,
                      color: Colors.black38, size: 20),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          // ── Filter Tabs ──
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
                    onTap: () =>
                        setState(() => _filterStatus = tab),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin:
                          EdgeInsets.only(right: tab != _t('completed') ? 6 : 0),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? tabColor
                            : tabColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive
                              ? tabColor
                              : tabColor.withOpacity(0.25),
                          width: 1.5,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: tabColor.withOpacity(0.25),
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
          // ── Count info ──
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_searchFiltered.length} ${_t('report_count')}',
                style: GoogleFonts.poppins(
                    color: Colors.black38, fontSize: 12),
              ),
            ),
          ),
          // ── List ──
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : RefreshIndicator(
                    onRefresh: _fetchData,
                    color: primaryColor,
                    child: _searchFiltered.isEmpty
                        ? _buildEmpty()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                                16, 4, 16, 32),
                            itemCount: _searchFiltered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) =>
                                _buildCard(_searchFiltered[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final signedUrl = item['signed_image_url'] as String?;
    final priority  = item['priority'] as String? ?? 'Normal';
    final status    = item['status'] as String? ?? 'Dikirim';
    final userName  = item['_userName'] as String? ?? '-';
    final hasReply  = (item['admin_reply'] as String?)?.isNotEmpty == true;
    final createdAt = item['created_at'] as String?;
    String dateStr  = '';
    if (createdAt != null) {
      try { dateStr = DateFormat('d MMM yyyy').format(DateTime.parse(createdAt).toLocal()); } catch (_) {}
    }

    return GestureDetector(
      onTap: () => _showDetail(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
          border: Border(left: BorderSide(color: _statusColor(status), width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Gambar / Placeholder ──
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: (signedUrl != null && signedUrl.isNotEmpty)
                    ? Image.network(signedUrl, width: 72, height: 72, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imgPlaceholder())
                    : _imgPlaceholder(),
              ),
              const SizedBox(width: 14),

              // ── Konten Tengah ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul
                    Text(
                      item['title'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E3A8A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    // Nama user
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 13, color: Colors.black45),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            userName,
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Tags baris pertama: Priority + Status
                    Row(
                      children: [
                        _tag(_localPriority(priority), _priorityColor(priority)),
                        const SizedBox(width: 6),
                        _tag(_localStatus(status), _statusColor(status)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Tags baris kedua: Replied + Tanggal
                    Row(
                      children: [
                        if (hasReply) ...[
                          _tag('✓ ${_t('reply_label')}', const Color(0xFF10B981)),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            dateStr,
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.black38),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // ── Tombol Hapus ──
              GestureDetector(
                onTap: () => _deleteItem(item['id'] as String),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_rounded, size: 20, color: Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
    width: 72, height: 72,
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(Icons.flag_outlined, color: Colors.grey.shade400, size: 32),
  );

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: color),
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0EA5E9).withOpacity(0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.inbox_outlined,
              size: 56,
              color: const Color(0xFF0EA5E9).withOpacity(0.4)),
        ),
        const SizedBox(height: 12),
        Text(
          _t('empty'),
          style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black38,
              fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );

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