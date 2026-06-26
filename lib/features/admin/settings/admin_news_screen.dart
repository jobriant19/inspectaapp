import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/fcm_v1_service.dart';
import '../../shared/account/news_detail_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminNewsScreen extends StatefulWidget {
  final String lang;
  final List<Map<String, dynamic>>? initialData; 
  const AdminNewsScreen({super.key, required this.lang, this.initialData});

  @override
  State<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends State<AdminNewsScreen> {
  static const _bg = Color(0xFFF8FAFC);
  static const _primary = Color(0xFFF59E0B);

  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;
  String _filterType = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _data = widget.initialData!;
      _isLoading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('latest_news')
          .select()
          .order('published_at', ascending: false);
      if (mounted) {
        setState(() {
          _data = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filterType == 'all') return _data;
    return _data
        .where((d) => (d['type'] ?? '').toLowerCase() == _filterType)
        .toList();
  }

  List<Map<String, dynamic>> get _filteredWithSearch {
    final base = _filtered;
    if (_searchQuery.trim().isEmpty) return base;
    final q = _searchQuery.toLowerCase();
    return base.where((d) {
      final titleId = (d['title_id'] ?? '').toString().toLowerCase();
      final titleEn = (d['title_en'] ?? '').toString().toLowerCase();
      final titleZh = (d['title_zh'] ?? '').toString().toLowerCase();
      final contentId = (d['content_id'] ?? '').toString().toLowerCase();
      return titleId.contains(q) ||
          titleEn.contains(q) ||
          titleZh.contains(q) ||
          contentId.contains(q);
    }).toList();
  }

  Future<String?> _uploadImageBytes(Uint8List bytes, String ext) async {
    try {
      final fileName = 'news_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await Supabase.instance.client.storage
          .from('news-images')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
              upsert: true,
            ),
          );
      final url = Supabase.instance.client.storage
          .from('news-images')
          .getPublicUrl(fileName);
      return url;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  void _showFormDialog({Map<String, dynamic>? item}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _NewsFormPage(
          lang: widget.lang,
          item: item,
          onSave: ({
            required Map<String, dynamic>? existing,
            required String type,
            required DateTime publishedAt,
            required String titleId,
            required String titleEn,
            required String titleZh,
            required String contentId,
            required String contentEn,
            required String contentZh,
            Uint8List? imageBytes,
            String? imageExt,
            String? existingImageUrl,
            required int displayDurationDays,
          }) async {
            await _saveNews(
              existing: existing,
              type: type,
              publishedAt: publishedAt,
              titleId: titleId,
              titleEn: titleEn,
              titleZh: titleZh,
              contentId: contentId,
              contentEn: contentEn,
              contentZh: contentZh,
              imageBytes: imageBytes,
              imageExt: imageExt,
              existingImageUrl: existingImageUrl,
              displayDurationDays: displayDurationDays,
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveNews({
    required Map<String, dynamic>? existing,
    required String type,
    required DateTime publishedAt,
    required String titleId,
    required String titleEn,
    required String titleZh,
    required String contentId,
    required String contentEn,
    required String contentZh,
    Uint8List? imageBytes,
    String? imageExt,
    String? existingImageUrl,
    required int displayDurationDays,
  }) async {
    // Tampilkan loading dialog di tengah layar
    if (mounted) _showLoadingDialog();

    String? finalImageUrl = existingImageUrl;

    if (imageBytes != null && imageBytes.isNotEmpty) {
      final uploaded = await _uploadImageBytes(imageBytes, imageExt ?? 'jpg');
      if (uploaded != null) {
        finalImageUrl = uploaded;
      } else {
        if (mounted) Navigator.of(context, rootNavigator: true).pop(); // tutup loading
        if (mounted) {
          _showResultDialog(
            isSuccess: false,
            message: widget.lang == 'EN'
                ? 'Image upload failed.\nPlease check your storage bucket settings.'
                : 'Upload gambar gagal.\nPeriksa pengaturan bucket storage Anda.',
          );
          return;
        }
      }
    }

    final payload = <String, dynamic>{
      'type': type,
      'published_at':
          '${publishedAt.year}-${publishedAt.month.toString().padLeft(2, '0')}-${publishedAt.day.toString().padLeft(2, '0')}',
      'title_id': titleId,
      'title_en': titleEn,
      'title_zh': titleZh,
      'content_id': contentId,
      'content_en': contentEn,
      'content_zh': contentZh,
      'display_duration_days': displayDurationDays,
      'image_url': finalImageUrl,
    };

    try {
      if (existing == null) {
        final insertResult = await Supabase.instance.client
            .from('latest_news')
            .insert(payload)
            .select();
        debugPrint('INSERT result: $insertResult');
      } else {
        final recordId = existing['id'];
        debugPrint('UPDATE id=$recordId payload=$payload');
        final updateResult = await Supabase.instance.client
            .from('latest_news')
            .update(payload)
            .eq('id', recordId)
            .select();
        debugPrint('UPDATE result: $updateResult');
      }

      // Tutup loading dialog
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      // Kirim push notif hanya saat INSERT
      if (existing == null) {
        _sendNewsNotification(
          type: type,
          titleId: titleId,
          titleEn: titleEn,
          titleZh: titleZh,
        );
      }

      await _clearSeenNewsCache();

      // Reload list
      _load();

      // Tampilkan success dialog
      if (mounted) {
        _showSaveSuccessDialog(
          message: existing == null
              ? (widget.lang == 'EN'
                  ? 'News has been saved successfully.'
                  : widget.lang == 'ZH'
                      ? '新闻已成功保存。'
                      : 'Berita berhasil disimpan.')
              : (widget.lang == 'EN'
                  ? 'News has been updated successfully.'
                  : widget.lang == 'ZH'
                      ? '新闻已成功更新。'
                      : 'Berita berhasil diperbarui.'),
        );
      }
    } catch (e) {
      // Tutup loading dialog
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      debugPrint('SAVE ERROR: $e');
      if (mounted) {
        _showResultDialog(
          isSuccess: false,
          message: widget.lang == 'EN'
              ? 'Failed to save news.\n${e.toString()}'
              : widget.lang == 'ZH'
                  ? '保存新闻失败。\n${e.toString()}'
                  : 'Gagal menyimpan berita.\n${e.toString()}',
        );
      }
    }
  }

  // ── Hapus cache seen news agar popup muncul kembali setelah add/edit ──
  Future<void> _clearSeenNewsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('seen_news_ids');
      debugPrint('🗑️ Seen news cache cleared — popup will show again');
    } catch (e) {
      debugPrint('Error clearing seen news cache: $e');
    }
  }

  Future<void> _sendNewsNotification({
    required String type,
    required String titleId,
    required String titleEn,
    required String titleZh,
  }) async {
    try {
      // Ambil SEMUA user — tanpa filter tambahan agar tidak ada yang terlewat
      final List<dynamic> users = await Supabase.instance.client
          .from('User')
          .select('id_user, fcm_token');

      if (users.isEmpty) {
        debugPrint('⚠️ No users found');
        return;
      }

      // Filter manual di Dart: hanya yang punya fcm_token tidak null dan tidak kosong
      final tokens = users
          .where((u) {
            final t = u['fcm_token'];
            return t != null && t.toString().trim().isNotEmpty;
          })
          .map((u) => u['fcm_token'].toString().trim())
          .toSet() // deduplicate
          .toList();

      debugPrint('📱 Users total: ${users.length}, with FCM token: ${tokens.length}');

      if (tokens.isEmpty) {
        debugPrint('⚠️ No users with FCM token');
        return;
      }

      final isUpdate = type == 'update';
      final emoji = isUpdate ? '🔔' : '🔧';
      final notifTitle = '$emoji ${isUpdate ? 'Update' : 'Maintenance'}';

      await FcmV1Service.instance.sendToMultipleTokens(
        fcmTokens: tokens,
        title: notifTitle,
        body: titleId,
        route: 'news',
        extraData: {
          'type': type,
          'title_id': titleId,
          'title_en': titleEn,
          'title_zh': titleZh,
        },
      );
    } catch (e) {
      debugPrint('❌ Error in _sendNewsNotification: $e');
    }
  }

  Future<void> _deleteNews(int id) async {
    final ok = await showDialog<bool>(
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
                        color: Color(0xFFFFEBEB), shape: BoxShape.circle),
                    child: const Icon(Icons.delete_forever_rounded,
                        color: Color(0xFFEF4444), size: 38),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.lang == 'EN'
                        ? 'Delete News?'
                        : widget.lang == 'ZH'
                            ? '删除新闻？'
                            : 'Hapus Berita?',
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.lang == 'EN'
                        ? 'This action cannot be undone.'
                        : widget.lang == 'ZH'
                            ? '此操作无法撤销。'
                            : 'Tindakan ini tidak dapat dibatalkan.',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        height: 1.5),
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
                        widget.lang == 'EN'
                            ? 'Delete'
                            : widget.lang == 'ZH'
                                ? '删除'
                                : 'Hapus',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
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
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        widget.lang == 'EN'
                            ? 'Cancel'
                            : widget.lang == 'ZH'
                                ? '取消'
                                : 'Batal',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
    if (!ok) return;
    try {
      await Supabase.instance.client
          .from('latest_news')
          .delete()
          .eq('id', id);
      _showSnack(widget.lang == 'EN' ? 'Deleted.' : 'Dihapus.');
      _load();
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFF59E0B),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.lang == 'EN' ? 'Latest News' : 'Kabar Terbaru',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: const Color(0xFFF59E0B)),
        ),
      ),
      body: Column(
        children: [
          // ── Banner Add ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: GestureDetector(
              onTap: () => _showFormDialog(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primary, _primary.withValues(alpha:0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: _primary.withValues(alpha:0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:0.25),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.lang == 'EN'
                                ? 'Add New Article'
                                : widget.lang == 'ZH'
                                    ? '添加新文章'
                                    : 'Tambah Berita Baru',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                          Text(
                            widget.lang == 'EN'
                                ? 'Tap to add a new article'
                                : widget.lang == 'ZH'
                                    ? '点击以添加新文章'
                                    : 'Ketuk untuk menambah berita baru',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha:0.85)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          ),
          // ── Search ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha:0.08)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.poppins(
                    color: const Color(0xFF1E3A8A), fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.lang == 'EN'
                      ? 'Search news...'
                      : widget.lang == 'ZH'
                          ? '搜索新闻...'
                          : 'Cari berita...',
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
          // ── Filter ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                Expanded(
                    child: _filterPill(
                        'all',
                        widget.lang == 'EN'
                            ? 'All'
                            : widget.lang == 'ZH'
                                ? '全部'
                                : 'Semua',
                        Colors.black54,
                        Icons.list_rounded)),
                const SizedBox(width: 8),
                Expanded(
                    child: _filterPill('update', 'Update',
                        const Color(0xFF6366F1), Icons.update_rounded)),
                const SizedBox(width: 8),
                Expanded(
                    child: _filterPill(
                        'maintenance',
                        widget.lang == 'EN' ? 'Maint.' : 'Maint.',
                        const Color(0xFFF59E0B),
                        Icons.build_rounded)),
              ],
            ),
          ),
          // ── Count ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filteredWithSearch.length} ${widget.lang == 'EN' ? 'articles' : widget.lang == 'ZH' ? '篇文章' : 'berita'}',
                style: GoogleFonts.poppins(
                    color: Colors.black38, fontSize: 12),
              ),
            ),
          ),
          // ── List ──
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : _filteredWithSearch.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.campaign_outlined,
                                size: 56, color: Colors.black12),
                            const SizedBox(height: 12),
                            Text(
                              widget.lang == 'EN'
                                  ? 'No news yet'
                                  : widget.lang == 'ZH'
                                      ? '暂无新闻'
                                      : 'Belum ada berita',
                              style: GoogleFonts.poppins(
                                  color: Colors.black38),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: _primary,
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 4, 16, 32),
                          itemCount: _filteredWithSearch.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) =>
                              _buildNewsCard(_filteredWithSearch[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterPill(
      String type, String label, Color color, IconData icon) {
    final isActive = _filterType == type;
    return GestureDetector(
      onTap: () => setState(() => _filterType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isActive ? color : color.withValues(alpha:0.35),
              width: 1.5),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: color.withValues(alpha:0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isActive ? Colors.white : color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                    color: isActive ? Colors.white : color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> item) {
    final type = (item['type'] ?? '').toString().toLowerCase();
    final isUpdate = type == 'update';
    final color = isUpdate
        ? const Color(0xFF6366F1)
        : const Color(0xFFF59E0B);
    final icon =
        isUpdate ? Icons.update_rounded : Icons.build_rounded;

    final String titleKey = widget.lang == 'ZH'
        ? 'title_zh'
        : widget.lang == 'EN'
            ? 'title_en'
            : 'title_id';
    final String contentKey = widget.lang == 'ZH'
        ? 'content_zh'
        : widget.lang == 'EN'
            ? 'content_en'
            : 'content_id';

    final date = item['published_at']?.toString() ?? '';
    final String? imageUrl = item['image_url'];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NewsDetailScreen(item: item, lang: widget.lang),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha:0.06)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha:0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail gambar (jika ada) ──
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 130,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha:0.10),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item[titleKey] ?? '-',
                          style: GoogleFonts.poppins(
                              color: const Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: color.withValues(alpha:0.10),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                isUpdate ? 'Update' : 'Maintenance',
                                style: GoogleFonts.poppins(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.calendar_today_rounded,
                                size: 11, color: Colors.black38),
                            const SizedBox(width: 3),
                            Text(date,
                                style: GoogleFonts.poppins(
                                    color: Colors.black38, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _iconBtn(Icons.edit_outlined,
                          const Color(0xFF6366F1),
                          () => _showFormDialog(item: item)),
                      const SizedBox(height: 6),
                      _iconBtn(Icons.delete_outline_rounded,
                          const Color(0xFFEF4444),
                          () => _deleteNews(item['id'])),
                    ],
                  ),
                ],
              ),
            ),
            if ((item[contentKey] ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: Colors.grey.shade100, height: 1),
                    const SizedBox(height: 8),
                    Text(
                      item[contentKey] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          color: Colors.black45, fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
            color: color.withValues(alpha:0.10),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 15),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
          height: 100,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // POP UP LOADING — muncul saat proses simpan ke database
  // ─────────────────────────────────────────────
  void _showLoadingDialog() {
    if (!mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'loading',
      barrierColor: Colors.black.withValues(alpha:0.45),
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 60),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withValues(alpha:0.18),
                    blurRadius: 32,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: Color(0xFFF59E0B),
                      strokeWidth: 4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.lang == 'EN'
                        ? 'Saving...'
                        : widget.lang == 'ZH'
                            ? '保存中...'
                            : 'Menyimpan...',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E3A8A),
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

  // ─────────────────────────────────────────────
  // POP UP NOTIFIKASI TENGAH LAYAR (berhasil/gagal)
  // ─────────────────────────────────────────────
  void _showResultDialog({required bool isSuccess, required String message}) {
    if (!mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'result',
      barrierColor: Colors.black.withValues(alpha:0.45),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.80, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) {
        // Auto close setelah 2.5 detik
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (ctx.mounted && Navigator.of(ctx).canPop()) {
            Navigator.of(ctx).pop();
          }
        });

        final Color primary =
            isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
        final Color bgLight =
            isSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
        final IconData icon =
            isSuccess ? Icons.check_circle_rounded : Icons.error_rounded;
        final String title = isSuccess
            ? (widget.lang == 'EN'
                ? 'Success!'
                : widget.lang == 'ZH'
                    ? '成功！'
                    : 'Berhasil!')
            : (widget.lang == 'EN'
                ? 'Failed!'
                : widget.lang == 'ZH'
                    ? '失败！'
                    : 'Gagal!');

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha:0.25),
                    blurRadius: 40,
                    spreadRadius: 4,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Ikon lingkaran ──
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: bgLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: primary.withValues(alpha:0.25), width: 2),
                    ),
                    child: Icon(icon, color: primary, size: 44),
                  ),
                  const SizedBox(height: 18),
                  // ── Judul ──
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ── Pesan ──
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ── Progress bar auto-close ──
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 0.0),
                      duration: const Duration(milliseconds: 2500),
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 4,
                        backgroundColor: primary.withValues(alpha:0.1),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(primary.withValues(alpha:0.6)),
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

  // ─────────────────────────────────────────────
  // POP UP SUKSES SIMPAN — style seperti konfirmasi hapus
  // Auto close 2.5 detik lalu kembali ke list
  // ─────────────────────────────────────────────
  void _showSaveSuccessDialog({required String message}) {
    if (!mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'save_success',
      barrierColor: Colors.black.withValues(alpha:0.45),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.80, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) {
        // Auto close + reload list setelah 2.5 detik
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (ctx.mounted && Navigator.of(ctx).canPop()) {
            Navigator.of(ctx).pop();
          }
          _load(); // refresh list berita
        });

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha:0.25),
                    blurRadius: 40,
                    spreadRadius: 4,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Ikon lingkaran hijau ──
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF16A34A).withValues(alpha:0.25),
                          width: 2),
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF16A34A), size: 44),
                  ),
                  const SizedBox(height: 18),
                  // ── Judul ──
                  Text(
                    widget.lang == 'EN'
                        ? 'Saved!'
                        : widget.lang == 'ZH'
                            ? '已保存！'
                            : 'Tersimpan!',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ── Pesan ──
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ── Progress bar auto-close ──
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 0.0),
                      duration: const Duration(milliseconds: 2500),
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 4,
                        backgroundColor:
                            const Color(0xFF16A34A).withValues(alpha:0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF16A34A)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ── Tombol OK manual ──
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        _load();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        widget.lang == 'EN'
                            ? 'OK'
                            : widget.lang == 'ZH'
                                ? '确定'
                                : 'OK',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.white),
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

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor:
          isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }
}

// ============================================================
// TYPEDEF CALLBACK SAVE
// ============================================================
typedef _SaveNewsCallback = Future<void> Function({
  required Map<String, dynamic>? existing,
  required String type,
  required DateTime publishedAt,
  required String titleId,
  required String titleEn,
  required String titleZh,
  required String contentId,
  required String contentEn,
  required String contentZh,
  Uint8List? imageBytes,
  String? imageExt,
  String? existingImageUrl,
  required int displayDurationDays,
});

// ============================================================
// FULL SCREEN FORM PAGE
// ============================================================
class _NewsFormPage extends StatefulWidget {
  final String lang;
  final Map<String, dynamic>? item;
  final _SaveNewsCallback onSave;

  const _NewsFormPage({
    required this.lang,
    required this.item,
    required this.onSave,
  });

  @override
  State<_NewsFormPage> createState() => _NewsFormPageState();
}

class _NewsFormPageState extends State<_NewsFormPage> {
  static const _primary = Color(0xFFF59E0B);

  bool get _isEdit => widget.item != null;

  final _titleCtrl   = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '7');

  String _selectedType = 'update';
  DateTime _selectedDate = DateTime.now();

  Uint8List? _pickedImageBytes;
  String? _pickedImageExt;
  String? _existingImageUrl;

  bool _isTranslating = false;
  bool _isSaving = false;

  // Hasil translate
  String? _titleId, _titleEn, _titleZh;
  String? _contentId, _contentEn, _contentZh;

  @override
  void initState() {
    super.initState();
    final d = widget.item;
    if (d != null) {
      _selectedType = (d['type'] ?? 'update').toString().toLowerCase();
      _selectedDate = d['published_at'] != null
          ? DateTime.tryParse(d['published_at'].toString()) ?? DateTime.now()
          : DateTime.now();
      _durationCtrl.text = (d['display_duration_days'] ?? 7).toString();
      _existingImageUrl = d['image_url'];

      // Isi field dengan konten bahasa Inggris sebagai default edit
      _titleCtrl.text   = d['title_en'] ?? d['title_id'] ?? '';
      _contentCtrl.text = d['content_en'] ?? d['content_id'] ?? '';

      // Simpan terjemahan yang sudah ada
      _titleId   = d['title_id'];
      _titleEn   = d['title_en'];
      _titleZh   = d['title_zh'];
      _contentId = d['content_id'];
      _contentEn = d['content_en'];
      _contentZh = d['content_zh'];
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  // ── Auto-translate via MyMemory API (free, no key, no limit) ──
  Future<String> _translateText(String text, String langPair) async {
    if (text.trim().isEmpty) return text;
    try {
      // MyMemory: gunakan zh-CN untuk Mandarin
      final normalizedPair = langPair
          .replaceAll('|zh', '|zh-CN')
          .replaceAll('zh|', 'zh-CN|');
      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get'
        '?q=${Uri.encodeComponent(text)}&langpair=$normalizedPair',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final translated =
            data['responseData']?['translatedText']?.toString() ?? '';
        if (translated.isEmpty ||
            translated.toUpperCase().startsWith('MYMEMORY WARNING') ||
            translated.toUpperCase().startsWith('PLEASE')) {
          return text; // fallback ke original
        }
        return translated;
      }
      return text;
    } catch (_) {
      return text;
    }
  }

  // Deteksi bahasa: ZH jika ada karakter CJK,
  // ID jika ada kata-kata Indonesia umum (minimal 1 kata),
  // EN sebagai default
  String _detectLang(String text) {
    if (text.trim().isEmpty) return 'id'; // default ID karena app berbahasa Indonesia

    // Cek karakter CJK → Mandarin
    if (RegExp(r'[\u4e00-\u9fff\u3400-\u4dbf]').hasMatch(text)) return 'zh';

    // Cek karakter non-Latin lain (Arab, Cyrillic, dll) → fallback EN
    if (RegExp(r'[^\x00-\x7F]').hasMatch(text) &&
        !RegExp(r'[\u4e00-\u9fff]').hasMatch(text)) { return 'en';}

    final lower = text.toLowerCase().trim();
    final words = lower.split(RegExp(r'[\s\.,!?;:()\-]+'))
        .where((w) => w.isNotEmpty)
        .toList();

    // Kata-kata khas Inggris yang TIDAK ada dalam bahasa Indonesia
    final enStrongWords = {
      'the', 'this', 'that', 'these', 'those', 'is', 'are', 'was', 'were',
      'have', 'has', 'had', 'will', 'would', 'could', 'should', 'may', 'might',
      'shall', 'must', 'do', 'does', 'did', 'been', 'being', 'be',
      'we', 'our', 'your', 'their', 'his', 'her', 'its', 'my',
      'please', 'thank', 'thanks', 'hello', 'hi', 'dear',
      'new', 'update', 'version', 'release', 'feature', 'fix', 'bug',
      'maintenance', 'scheduled', 'upgrade', 'improvement', 'enhancement',
      'system', 'server', 'service', 'access', 'user', 'password',
      'available', 'currently', 'support', 'contact', 'information',
      'notice', 'important', 'urgent', 'downtime', 'outage',
      'completed', 'resolved', 'ongoing', 'planned',
    };

    // Kata-kata khas Indonesia (termasuk kata pendek dan umum)
    final idStrongWords = {
      // Kata pendek umum
      'judul', 'isi', 'dan', 'yang', 'di', 'ke', 'dari', 'untuk', 'dengan',
      'pada', 'adalah', 'ini', 'itu', 'tidak', 'ada', 'juga', 'sudah',
      'akan', 'bisa', 'karena', 'saat', 'kami', 'anda', 'telah',
      'dapat', 'atau', 'kita', 'mereka', 'saya', 'dia', 'nya',
      // Kata berita/teknologi Indonesia
      'berita', 'kabar', 'terbaru', 'pembaruan', 'pemeliharaan', 'perbaikan',
      'fitur', 'versi', 'rilis', 'aplikasi', 'sistem', 'layanan', 'server',
      'pengguna', 'sandi', 'akses', 'tersedia', 'sedang', 'selesai',
      'dijadwalkan', 'gangguan', 'pemberitahuan', 'penting', 'mendesak',
      'konten', 'tampilan', 'halaman', 'data', 'jaringan', 'koneksi',
      // Kata umum lainnya
      'namun', 'tetapi', 'bahwa', 'jika', 'maka', 'agar', 'supaya',
      'oleh', 'kepada', 'tentang', 'antara', 'setiap', 'semua', 'beberapa',
      'tersebut', 'sehingga', 'selain', 'seluruh', 'dalam', 'lain',
      'apabila', 'setelah', 'sebelum', 'ketika', 'lebih', 'sangat',
      'harus', 'belum', 'baru', 'lagi', 'masih', 'pula',
      // Awalan/akhiran khas Indonesia yang berdiri sendiri sebagai kata
      'menggunakan', 'melakukan', 'memberikan', 'meningkatkan', 'menambahkan',
      'menghapus', 'mengubah', 'memperbarui', 'memperbaiki', 'menyelesaikan',
      'dilakukan', 'diberikan', 'ditambahkan', 'diperbarui', 'diperbaiki',
      'penggunaan', 'pelayanan', 'penyimpanan', 'pengiriman',
    };

    int enScore = 0;
    int idScore = 0;

    for (final word in words) {
      if (enStrongWords.contains(word)) enScore += 2;
      if (idStrongWords.contains(word)) idScore += 2;
    }

    // Cek awalan khas Indonesia (me-, ber-, pe-, ke-, ter-, se-)
    for (final word in words) {
      if (word.length > 4) {
        if (word.startsWith('me') || word.startsWith('ber') ||
            word.startsWith('pe') || word.startsWith('ke') ||
            word.startsWith('ter') || word.startsWith('se') ||
            word.startsWith('di') || word.endsWith('kan') ||
            word.endsWith('nya') || word.endsWith('lah') ||
            word.endsWith('pun') || word.endsWith('an')) {
          idScore += 1;
        }
      }
    }

    debugPrint('🔍 Lang detect: enScore=$enScore idScore=$idScore words=$words');

    if (idScore > enScore) return 'id';
    if (enScore > idScore) return 'en';

    // Jika skor sama (teks ambigu/pendek/random) → default ID
    // karena admin menggunakan bahasa Indonesia
    return 'id';
  }

  Future<bool> _autoTranslate() async {
    final title   = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    if (title.isEmpty) return false;

    try {
      final sourceLang = _detectLang(title.isNotEmpty ? title : content);
      debugPrint('🌐 Detected lang: $sourceLang for title: "$title"');

      // Tentukan pasangan translate berdasarkan bahasa sumber
      // Index: [0]=ID, [1]=EN, [2]=ZH
      String pairToId, pairToEn, pairToZh;
      switch (sourceLang) {
        case 'id':
          pairToId = '';       // sudah ID — tidak perlu translate
          pairToEn = 'id|en';
          pairToZh = 'id|zh';
          break;
        case 'zh':
          pairToId = 'zh|id';
          pairToEn = 'zh|en';
          pairToZh = '';       // sudah ZH — tidak perlu translate
          break;
        default: // 'en'
          pairToId = 'en|id';
          pairToEn = '';       // sudah EN — tidak perlu translate
          pairToZh = 'en|zh';
      }

      // ── Translate TITLE ke 3 bahasa secara paralel ──
      final titleResults = await Future.wait([
        pairToId.isEmpty
            ? Future.value(title)          // [0] ID
            : _translateText(title, pairToId),
        pairToEn.isEmpty
            ? Future.value(title)          // [1] EN
            : _translateText(title, pairToEn),
        pairToZh.isEmpty
            ? Future.value(title)          // [2] ZH
            : _translateText(title, pairToZh),
      ]);

      // ── Translate CONTENT ke 3 bahasa secara paralel ──
      final contentResults = await Future.wait([
        content.isEmpty
            ? Future.value('')
            : pairToId.isEmpty
                ? Future.value(content)    // [0] content ID
                : _translateText(content, pairToId),
        content.isEmpty
            ? Future.value('')
            : pairToEn.isEmpty
                ? Future.value(content)    // [1] content EN
                : _translateText(content, pairToEn),
        content.isEmpty
            ? Future.value('')
            : pairToZh.isEmpty
                ? Future.value(content)    // [2] content ZH
                : _translateText(content, pairToZh),
      ]);

      if (!mounted) return false;

      // Pastikan hasil tidak kosong — fallback ke teks asal jika gagal
      final String finalTitleId = titleResults[0].isNotEmpty
          ? titleResults[0] : title;
      final String finalTitleEn = titleResults[1].isNotEmpty
          ? titleResults[1] : title;
      final String finalTitleZh = titleResults[2].isNotEmpty
          ? titleResults[2] : title;
      final String finalContentId = contentResults[0];
      final String finalContentEn = contentResults[1];
      final String finalContentZh = contentResults[2];

      debugPrint(
        '✅ Translate done:\n'
        '  title  → ID="$finalTitleId" | EN="$finalTitleEn" | ZH="$finalTitleZh"\n'
        '  content→ ID="$finalContentId" | EN="$finalContentEn" | ZH="$finalContentZh"',
      );

      setState(() {
        _titleId   = finalTitleId;
        _titleEn   = finalTitleEn;
        _titleZh   = finalTitleZh;
        _contentId = finalContentId;
        _contentEn = finalContentEn;
        _contentZh = finalContentZh;
        _isTranslating = false;
      });

      return true;
    } catch (e) {
      debugPrint('❌ Translate error: $e');
      if (mounted) setState(() => _isTranslating = false);
      return false;
    }
  }

  // ── Submit ──────────────────────────────────────────────
  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();

    if (title.isEmpty) {
      _showSnack(
        widget.lang == 'EN' ? 'Title is required.'
            : widget.lang == 'ZH' ? '标题为必填项。'
            : 'Judul wajib diisi.',
        isError: true,
      );
      return;
    }

    // Step 1: Tampil translating state di tombol
    if (mounted) setState(() { _isSaving = true; _isTranslating = true; });

    final translateOk = await _autoTranslate();

    if (!mounted) return;

    if (!translateOk || _titleId == null) {
      setState(() { _isSaving = false; _isTranslating = false; });
      _showSnack(
        widget.lang == 'EN'
            ? 'Translation failed. Please check your connection.'
            : widget.lang == 'ZH'
                ? '翻译失败，请检查网络。'
                : 'Terjemahan gagal. Periksa koneksi Anda.',
        isError: true,
      );
      return;
    }

    // Step 2: Translate selesai → reset state tombol
    if (mounted) setState(() { _isSaving = false; _isTranslating = false; });

    // Step 3: Pop form DULU → kembali ke AdminNewsScreen
    // Parent yang akan handle loading dialog + success dialog
    if (mounted) Navigator.of(context).pop();

    // Step 4: Panggil onSave di parent (sudah di AdminNewsScreen)
    await widget.onSave(
      existing: widget.item,
      type: _selectedType,
      publishedAt: _selectedDate,
      titleId:   _titleId!,
      titleEn:   _titleEn!,
      titleZh:   _titleZh!,
      contentId: _contentId ?? '',
      contentEn: _contentEn ?? '',
      contentZh: _contentZh ?? '',
      imageBytes: _pickedImageBytes,
      imageExt:   _pickedImageExt,
      existingImageUrl: _existingImageUrl,
      displayDurationDays: int.tryParse(_durationCtrl.text) ?? 7,
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Widget _dlgLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      label,
      style: GoogleFonts.poppins(
        color: Colors.black54,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    ),
  );

  Widget _typeChip(String type, ValueChanged<String> onTap) {
    final isActive = type == _selectedType;
    final color = type == 'update'
        ? const Color(0xFF6366F1)
        : const Color(0xFFF59E0B);
    final icon  = type == 'update'
        ? Icons.update_rounded
        : Icons.build_rounded;
    final label = type == 'update' ? 'Update' : 'Maintenance';

    return GestureDetector(
      onTap: () => onTap(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha:0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: isActive ? 0 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: isActive ? Colors.white : color),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.poppins(
                  color: isActive ? Colors.white : color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return SizedBox(
      height: 130,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              color: Colors.grey.shade400, size: 38),
          const SizedBox(height: 8),
          Text(
            widget.lang == 'EN'
                ? 'Tap to choose image from gallery'
                : widget.lang == 'ZH'
                    ? '点击从相册选择图片'
                    : 'Ketuk untuk pilih gambar dari galeri',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha:0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.campaign_outlined, color: _primary, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            _isEdit
                ? (widget.lang == 'EN' ? 'Edit News' : widget.lang == 'ZH' ? '编辑新闻' : 'Edit Berita')
                : (widget.lang == 'EN' ? 'Add News' : widget.lang == 'ZH' ? '添加新闻' : 'Tambah Berita'),
            style: GoogleFonts.poppins(
                color: const Color(0xFF1E3A8A),
                fontWeight: FontWeight.w700,
                fontSize: 16),
          ),
        ]),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Tipe ──
                _dlgLabel(widget.lang == 'EN' ? 'Type' : widget.lang == 'ZH' ? '类型' : 'Tipe'),
                Row(children: [
                  _typeChip('update', (v) => setState(() => _selectedType = v)),
                  const SizedBox(width: 10),
                  _typeChip('maintenance', (v) => setState(() => _selectedType = v)),
                ]),
                const SizedBox(height: 20),

                // ── Tanggal publish ──
                _dlgLabel(widget.lang == 'EN'
                    ? 'Published Date'
                    : widget.lang == 'ZH'
                        ? '发布日期'
                        : 'Tanggal Tayang'),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      builder: (c, child) => Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(primary: _primary),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: Colors.black38, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: GoogleFonts.poppins(
                            color: const Color(0xFF1E3A8A), fontSize: 14),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Durasi popup ──
                _dlgLabel(widget.lang == 'EN'
                    ? 'Popup Display Duration (days)'
                    : widget.lang == 'ZH'
                        ? '弹窗显示天数'
                        : 'Durasi Tampil Popup (hari)'),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () {
                        final c = int.tryParse(_durationCtrl.text) ?? 7;
                        if (c > 1) setState(() => _durationCtrl.text = (c - 1).toString());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Icon(Icons.remove_rounded,
                            color: _primary, size: 20),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _durationCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            color: const Color(0xFF1E3A8A),
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        final c = int.tryParse(_durationCtrl.text) ?? 7;
                        setState(() => _durationCtrl.text = (c + 1).toString());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Icon(Icons.add_rounded,
                            color: _primary, size: 20),
                      ),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5, left: 2),
                  child: Text(
                    widget.lang == 'EN'
                        ? 'News will appear in popup for this many days after published date'
                        : widget.lang == 'ZH'
                            ? '新闻将在发布日期后的这些天内显示在弹窗中'
                            : 'Berita akan muncul di popup selama ini sejak tanggal tayang',
                    style: GoogleFonts.poppins(
                        color: Colors.grey.shade500, fontSize: 10.5),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Gambar ──
                _dlgLabel('Image (${widget.lang == 'EN' ? 'optional' : widget.lang == 'ZH' ? '可选' : 'opsional'})'),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                      maxWidth: 1200,
                    );
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      final ext = picked.name.split('.').last.toLowerCase();
                      setState(() {
                        _pickedImageBytes = bytes;
                        _pickedImageExt   = ext == 'png' ? 'png' : 'jpg';
                        _existingImageUrl = null;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 130),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _pickedImageBytes != null ||
                                _existingImageUrl != null
                            ? _primary.withValues(alpha:0.5)
                            : Colors.grey.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: _pickedImageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Stack(children: [
                              Image.memory(_pickedImageBytes!,
                                  width: double.infinity,
                                  height: 160,
                                  fit: BoxFit.cover),
                              Positioned(
                                bottom: 8, right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha:0.55),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.edit_rounded,
                                          color: Colors.white, size: 13),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.lang == 'EN' ? 'Change' : 'Ganti',
                                        style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8, right: 8,
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _pickedImageBytes = null;
                                    _pickedImageExt   = null;
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                        color: Colors.red.shade400,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ]),
                          )
                        : _existingImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Stack(children: [
                                  Image.network(_existingImageUrl!,
                                      width: double.infinity,
                                      height: 160,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _imagePlaceholder()),
                                  Positioned(
                                    bottom: 8, right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha:0.55),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.edit_rounded,
                                              color: Colors.white, size: 13),
                                          const SizedBox(width: 4),
                                          Text(
                                            widget.lang == 'EN'
                                                ? 'Change'
                                                : 'Ganti',
                                            style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8, right: 8,
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _existingImageUrl = null;
                                        _pickedImageBytes = null;
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                            color: Colors.red.shade400,
                                            shape: BoxShape.circle),
                                        child: const Icon(Icons.close,
                                            color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ),
                                ]),
                              )
                            : _imagePlaceholder(),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Title ──
                _dlgLabel(widget.lang == 'EN'
                    ? 'Title'
                    : widget.lang == 'ZH'
                        ? '标题'
                        : 'Judul'),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _titleCtrl,
                    maxLines: 1,
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF1E3A8A), fontSize: 14),
                    decoration: InputDecoration(
                      hintText: widget.lang == 'EN'
                          ? 'Enter news title...'
                          : widget.lang == 'ZH'
                              ? '输入新闻标题...'
                              : 'Masukkan judul berita...',
                      hintStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade400, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Content ──
                _dlgLabel(widget.lang == 'EN'
                    ? 'Content'
                    : widget.lang == 'ZH'
                        ? '内容'
                        : 'Konten'),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _contentCtrl,
                    maxLines: 6,
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF1E3A8A), fontSize: 14),
                    decoration: InputDecoration(
                      hintText: widget.lang == 'EN'
                          ? 'Enter news content...'
                          : widget.lang == 'ZH'
                              ? '输入新闻内容...'
                              : 'Masukkan konten berita...',
                      hintStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade400, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── Tombol Simpan (sticky di bawah) ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                    top: BorderSide(color: Colors.grey.shade100)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isSaving || _isTranslating) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: (_isSaving || _isTranslating)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _isTranslating
                                ? (widget.lang == 'EN'
                                    ? 'Translating...'
                                    : widget.lang == 'ZH'
                                        ? '翻译中...'
                                        : 'Menerjemahkan...')
                                : (widget.lang == 'EN'
                                    ? 'Saving...'
                                    : widget.lang == 'ZH'
                                        ? '保存中...'
                                        : 'Menyimpan...'),
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                          ),
                        ],
                      )
                      : Text(
                        _isEdit
                            ? (widget.lang == 'EN'
                                ? 'Update News'
                                : widget.lang == 'ZH'
                                    ? '更新新闻'
                                    : 'Perbarui Berita')
                            : (widget.lang == 'EN'
                                ? 'Save News'
                                : widget.lang == 'ZH'
                                    ? '保存新闻'
                                    : 'Simpan Berita'),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700, fontSize: 15),
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