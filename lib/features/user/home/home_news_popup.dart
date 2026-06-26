import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/account/news_detail_screen.dart';

class HomeNewsPopup {
  // ── Key SharedPreferences ──
  static const _kSeenNewsKey = 'seen_news_ids';

  // ── Ambil set ID yang sudah dilihat ──
  static Future<Set<String>> _getSeenIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kSeenNewsKey) ?? [];
    return list.toSet();
  }

  // ── Tandai semua item sebagai sudah dilihat ──
  static Future<void> _markAsSeen(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = (prefs.getStringList(_kSeenNewsKey) ?? []).toSet();
    for (final item in items) {
      existing.add(item['id'].toString());
    }
    await prefs.setStringList(_kSeenNewsKey, existing.toList());
  }

  // ── Dipanggil dari admin setelah add/edit news ──
  // Hapus ID yang baru ditambah/diedit dari seen list
  // agar popup muncul kembali untuk user
  static Future<void> markNewsAsNew(dynamic newsId) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = (prefs.getStringList(_kSeenNewsKey) ?? []).toSet();
    existing.remove(newsId.toString());
    await prefs.setStringList(_kSeenNewsKey, existing.toList());
    debugPrint('🆕 News $newsId marked as new (removed from seen list)');
  }

  static Future<void> showIfNeeded(
    BuildContext context, {
    required String lang,
  }) async {
    try {
      final now = DateTime.now();

      final res = await Supabase.instance.client
          .from('latest_news')
          .select()
          .order('published_at', ascending: false)
          .limit(20);

      final List<Map<String, dynamic>> allItems =
          List<Map<String, dynamic>>.from(res);

      // ── Filter berdasarkan durasi tayang ──
      final List<Map<String, dynamic>> activeItems = allItems.where((item) {
        try {
          final rawDate = item['published_at'];
          DateTime publishedAt;
          if (rawDate is DateTime) {
            publishedAt = rawDate;
          } else {
            final dateStr = rawDate.toString().split('T').first;
            publishedAt = DateTime.parse(dateStr);
          }
          final durationDays =
              (item['display_duration_days'] as num?)?.toInt() ?? 7;
          final expiryDate = DateTime(
            publishedAt.year,
            publishedAt.month,
            publishedAt.day,
          ).add(Duration(days: durationDays));
          final today = DateTime(now.year, now.month, now.day);
          return today.isBefore(expiryDate);
        } catch (e) {
          debugPrint('HomeNewsPopup date parse error: $e');
          return false;
        }
      }).toList();

      if (activeItems.isEmpty) return;

      // ── Filter hanya yang belum dilihat ──
      final seenIds = await _getSeenIds();
      final List<Map<String, dynamic>> unseenItems = activeItems
          .where((item) => !seenIds.contains(item['id'].toString()))
          .toList();

      debugPrint(
        'HomeNewsPopup: total=${allItems.length}, active=${activeItems.length}, '
        'unseen=${unseenItems.length}',
      );

      // Jika semua sudah dilihat → tidak tampilkan popup
      if (unseenItems.isEmpty) return;
      if (!context.mounted) return;

      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'news_popup',
        barrierColor: Colors.black.withValues(alpha:0.55),
        transitionDuration: const Duration(milliseconds: 350),
        transitionBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.90, end: 1.0).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              ),
              child: child,
            ),
          );
        },
        pageBuilder: (ctx, _, __) => _HomeNewsPopupWidget(
          items: unseenItems,
          lang: lang,
          onDismiss: () async {
            // Tandai semua item yang ditampilkan sebagai sudah dilihat
            await _markAsSeen(unseenItems);
          },
        ),
      );
    } catch (e) {
      debugPrint('HomeNewsPopup error: $e');
    }
  }
}

class _HomeNewsPopupWidget extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String lang;
  final Future<void> Function() onDismiss;

  const _HomeNewsPopupWidget({
    required this.items,
    required this.lang,
    required this.onDismiss,
  });

  @override
  State<_HomeNewsPopupWidget> createState() => _HomeNewsPopupWidgetState();
}

class _HomeNewsPopupWidgetState extends State<_HomeNewsPopupWidget> {
  late PageController _pageController;
  int _currentPage = 0;

  static const _updateColor = Color(0xFF1D72F3);
  static const _maintColor  = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _t(String id, String en, String zh) {
    if (widget.lang == 'ID') return id;
    if (widget.lang == 'ZH') return zh;
    return en;
  }

  String _title(Map<String, dynamic> item) {
    final k = 'title_${widget.lang.toLowerCase()}';
    return item[k] ?? item['title_en'] ?? '';
  }

  String _content(Map<String, dynamic> item) {
    final k = 'content_${widget.lang.toLowerCase()}';
    return item[k] ?? item['content_en'] ?? '';
  }

  Color _color(Map<String, dynamic> item) =>
      (item['type'] ?? '') == 'update' ? _updateColor : _maintColor;

  IconData _icon(Map<String, dynamic> item) =>
      (item['type'] ?? '') == 'update'
          ? Icons.update_rounded
          : Icons.build_rounded;

  String _typeLabel(Map<String, dynamic> item) {
    final isUpdate = (item['type'] ?? '') == 'update';
    return isUpdate
        ? _t('Pembaruan', 'Update', '更新')
        : _t('Pemberitahuan', 'Notice', '通知');
  }

  // ── Tutup + tandai sudah dilihat ──
  Future<void> _dismiss() async {
    await widget.onDismiss();
    if (mounted) Navigator.of(context).pop();
  }

  void _openDetail(Map<String, dynamic> item) async {
    await widget.onDismiss();
    if (!mounted) return;
    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewsDetailScreen(item: item, lang: widget.lang),
      ),
    );
  }

  double _calcContentHeight(BuildContext context) {
    final currentItem = widget.items[_currentPage];
    final hasImage = (currentItem['image_url'] ?? '').isNotEmpty;
    return hasImage ? 160 + 105.0 : 3 + 105.0;
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = widget.items[_currentPage];
    final double popupMaxH = MediaQuery.of(context).size.height * 0.62;

    // Intercept barrier tap → tandai sudah dilihat
    return WillPopScope(
      onWillPop: () async {
        await widget.onDismiss();
        return true;
      },
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            constraints: BoxConstraints(
              maxHeight: popupMaxH,
              maxWidth: 420,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _color(currentItem).withValues(alpha:0.20),
                  blurRadius: 36,
                  spreadRadius: 2,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(currentItem),
                SizedBox(
                  height: _calcContentHeight(context),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.items.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (_, index) =>
                        _buildPageContent(widget.items[index]),
                  ),
                ),
                _buildFooter(currentItem),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> item) {
    final Color primary = _color(item);
    final bool isUpdate = (item['type'] ?? '') == 'update';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: isUpdate
            ? const Color(0xFFEFF6FF)
            : const Color(0xFFFFFBEB),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          bottom: BorderSide(color: primary.withValues(alpha:0.1)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: primary.withValues(alpha:0.13),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(_icon(item), color: primary, size: 16),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _typeLabel(item).toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  _t('Info Terbaru', 'Latest News', '最新消息'),
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(Map<String, dynamic> item) {
    final String? imageUrl = item['image_url'];
    final Color primary = _color(item);

    return GestureDetector(
      onTap: () => _openDetail(item),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            Stack(
              children: [
                Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: primary.withValues(alpha:0.07),
                    child: Center(
                      child: Icon(_icon(item),
                          color: primary.withValues(alpha:0.25), size: 40),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha:0.48),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.open_in_new_rounded,
                            color: Colors.white, size: 10),
                        const SizedBox(width: 4),
                        Text(
                          _t('Selengkapnya', 'Read more', '阅读更多'),
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else
            Container(height: 3, color: primary),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _title(item),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E3A8A),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _content(item),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                if (imageUrl == null || imageUrl.isEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _t('Ketuk untuk baca selengkapnya',
                              'Tap to read more', '点击阅读更多'),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 9, color: primary),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(Map<String, dynamic> currentItem) {
    final Color currentColor = _color(currentItem);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.items.length > 1) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.items.length,
                (i) => GestureDetector(
                  onTap: () => _pageController.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _currentPage ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? _color(widget.items[i])
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _dismiss,
              style: ElevatedButton.styleFrom(
                backgroundColor: currentColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _t('Tutup', 'Close', '关闭'),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}