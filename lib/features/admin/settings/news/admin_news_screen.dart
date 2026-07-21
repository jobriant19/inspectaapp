import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/fcm_v1_service.dart';
import '../../../user/account/news/news_detail_screen.dart';
import 'admin_add_news.dart';

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
  static const _addColor = Color(0xFF1D72F3);

  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;
  String _filterType = 'all';
  String _searchQuery = '';
  int _currentPage = 1;
  static const int _perPage = 10;

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
        builder: (_) => AdminAddNewsScreen(
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
    if (mounted) _showLoadingDialog();

    String? finalImageUrl = existingImageUrl;

    if (imageBytes != null && imageBytes.isNotEmpty) {
      final uploaded = await _uploadImageBytes(imageBytes, imageExt ?? 'jpg');
      if (uploaded != null) {
        finalImageUrl = uploaded;
      } else {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
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
      dynamic savedId;

      if (existing == null) {
        final insertResult = await Supabase.instance.client
            .from('latest_news')
            .insert(payload)
            .select();
        debugPrint('INSERT result: $insertResult');
        savedId = (insertResult as List?)?.isNotEmpty == true
            ? insertResult.first['id']
            : null;
      } else {
        savedId = existing['id'];
        debugPrint('UPDATE id=$savedId payload=$payload');
        final updateResult = await Supabase.instance.client
            .from('latest_news')
            .update(payload)
            .eq('id', savedId)
            .select();
        debugPrint('UPDATE result: $updateResult');
      }

      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (existing == null) {
        _sendNewsNotification(
          type: type,
          titleId: titleId,
          titleEn: titleEn,
          titleZh: titleZh,
        );
      }

      if (savedId != null) await _clearSeenNewsCache(newsId: savedId);

      _load();

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

  Future<void> _clearSeenNewsCache({required dynamic newsId}) async {
    try {
      await Supabase.instance.client
          .from('news_seen')
          .delete()
          .eq('id_news', newsId);
      debugPrint('🗑️ news_seen cleared for news id=$newsId');
    } catch (e) {
      debugPrint('Error clearing news_seen: $e');
    }
  }

  Future<void> _sendNewsNotification({
    required String type,
    required String titleId,
    required String titleEn,
    required String titleZh,
  }) async {
    try {
      final List<dynamic> users = await Supabase.instance.client
          .from('User')
          .select('id_user, fcm_token');

      if (users.isEmpty) {
        debugPrint('⚠️ No users found');
        return;
      }

      final tokens = users
          .where((u) {
            final t = u['fcm_token'];
            return t != null && t.toString().trim().isNotEmpty;
          })
          .map((u) => u['fcm_token'].toString().trim())
          .toSet()
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
        foregroundColor: _addColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
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
              color: _addColor),
        ),
      ),
      body: Column(
        children: [
          // ADD NEWS
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
                    colors: [_addColor, _addColor.withValues(alpha:0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: _addColor.withValues(alpha:0.35),
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
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha:0.95)),
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
          // SEARCH BAR
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
                onChanged: (v) => setState(() {
                  _searchQuery = v;
                  _currentPage = 1;
                }),
                textAlignVertical: TextAlignVertical.center,
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
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          // FILTER
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
                        widget.lang == 'ZH' ? '维护' : 'Maintenance',
                        const Color(0xFFF59E0B),
                        Icons.build_rounded)),
              ],
            ),
          ),
          // COUNT
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _addColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _addColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.article_rounded, size: 14, color: _addColor),
                    const SizedBox(width: 6),
                    Text(
                      '${_filteredWithSearch.length} ${widget.lang == 'EN' ? 'articles' : widget.lang == 'ZH' ? '篇文章' : 'berita'}',
                      style: GoogleFonts.poppins(
                        color: _addColor,
                        fontSize: 12,
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
                final filtered = _filteredWithSearch;
                final totalPages = filtered.isEmpty
                    ? 1
                    : (filtered.length / _perPage).ceil();
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
                          : filtered.isEmpty
                              ? _buildEmptyNewsState()
                              : RefreshIndicator(
                                  onRefresh: _load,
                                  color: _primary,
                                  child: ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 4, 16, 16),
                                    itemCount: pageData.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (_, i) =>
                                        _buildNewsCard(pageData[i]),
                                  ),
                                ),
                    ),
                    if (!_isLoading && totalPages > 1)
                      _AdminNewsPageIndicator(
                        currentPage: safePage,
                        totalPages: totalPages,
                        onPageChanged: (p) =>
                            setState(() => _currentPage = p),
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

  Widget _buildEmptyNewsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              height: 140,
              errorBuilder: (_, __, ___) => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _addColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.campaign_outlined,
                    size: 56, color: _addColor.withValues(alpha: 0.5)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.lang == 'EN'
                  ? 'No News Yet'
                  : widget.lang == 'ZH'
                      ? '暂无新闻'
                      : 'Belum Ada Berita',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _addColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              widget.lang == 'EN'
                  ? 'Tap "Add New Article" above to publish your first news.'
                  : widget.lang == 'ZH'
                      ? '点击上方"添加新文章"发布您的第一条新闻。'
                      : 'Ketuk "Tambah Berita Baru" di atas untuk membuat berita pertama Anda.',
              style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black45),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterPill(
      String type, String label, Color color, IconData icon) {
    final isActive = _filterType == type;
    return GestureDetector(
      onTap: () => setState(() {
        _filterType = type;
        _currentPage = 1;
      }),
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                      color: isActive ? Colors.white : color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCardDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final dateStr = raw.split('T').first;
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy').format(date);
    } catch (_) {
      return raw;
    }
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

    final dateLabel = _formatCardDate(item['published_at']?.toString());
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
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha:0.06),
                blurRadius: 14,
                offset: const Offset(0, 4)),
          ],
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // THUMBNAIL
              SizedBox(
                width: 96,
                height: 96,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: (imageUrl != null && imageUrl.isNotEmpty)
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: 96,
                          height: 96,
                          errorBuilder: (_, __, ___) =>
                              _newsImgPlaceholder(color, icon),
                        )
                      : _newsImgPlaceholder(color, icon),
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // TITLE
                    Text(
                      item[titleKey] ?? '-',
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1D72F3),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // TYPE TAG
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha:0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 11, color: color),
                          const SizedBox(width: 4),
                          Text(
                            isUpdate ? 'Update' : 'Maintenance',
                            style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: color),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // DATE
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 5),
                          Text(dateLabel,
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // EDIT & DELETE
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _iconBtn(Icons.edit_outlined,
                      const Color(0xFF2563EB),
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
      ),
    );
  }

  Widget _newsImgPlaceholder(Color color, IconData icon) => Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Icon(icon, color: color, size: 30)),
      );

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
                  // TITLE
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // MESSAGE
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
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (ctx.mounted && Navigator.of(ctx).canPop()) {
            Navigator.of(ctx).pop();
          }
          _load();
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
                  // SAVED
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
                  // MESSAGE
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
                  // OK BUTTON
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

class _AdminNewsPageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const _AdminNewsPageIndicator({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  static const Color _mainColor = Color(0xFF1D72F3);
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
          border: Border.all(color: _mainColor.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: _mainColor.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildArrowButton(
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
                    Expanded(child: _buildPageNumberButton(p)),
                    if (p != pageNumbers.last) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            _buildArrowButton(
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

  Widget _buildPageNumberButton(int page) {
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
          color: isActive ? _mainColor : _mainColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? null
              : Border.all(color: _mainColor.withValues(alpha: 0.25)),
        ),
        child: Text(
          '$page',
          style: GoogleFonts.poppins(
            color: isActive ? Colors.white : _mainColor,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: enabled
              ? _mainColor.withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 15,
          color: enabled ? _mainColor : Colors.grey.shade400,
        ),
      ),
    );
  }
}