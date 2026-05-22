import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

import 'news_detail_screen.dart';

class NewsScreen extends StatefulWidget {
  final String lang;
  final Map<String, Map<String, String>> translations;

  const NewsScreen({
    super.key,
    required this.lang,
    required this.translations,
  });

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late String _currentLang;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _updates = [];
  List<Map<String, dynamic>> _maintenance = [];

  // Warna tema per tipe
  static const _updatePrimary = Color(0xFF1D72F3);      // biru cerah
  static const _updateLight   = Color(0xFFEFF6FF);
  static const _maintPrimary  = Color(0xFFF59E0B);      // kuning cerah
  static const _maintLight    = Color(0xFFFFFBEB);

  String getTxt(String key) =>
      widget.translations[_currentLang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _currentLang = widget.lang;
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('latest_news')
          .select()
          .order('published_at', ascending: false);

      if (mounted) {
        final List<dynamic> allNewsData = response;
        setState(() {
          _updates = List<Map<String, dynamic>>.from(
              allNewsData.where((item) => item['type'] == 'update'));
          _maintenance = List<Map<String, dynamic>>.from(
              allNewsData.where((item) => item['type'] == 'maintenance'));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load news. Please try again later.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFEFF6FF),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Color(0xFF1D72F3)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            getTxt('news_title'),
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1D72F3),
                fontSize: 18),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.08),
          iconTheme: const IconThemeData(color: Color(0xFF1D72F3)),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Builder(
                builder: (context) {
                  final tabController = DefaultTabController.of(context);
                  return AnimatedBuilder(
                    animation: tabController,
                    builder: (context, _) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: TabBar(
                          isScrollable: false,
                          tabAlignment: TabAlignment.fill,
                          indicator: BoxDecoration(
                            color: tabController.index == 0
                                ? const Color(0xFF1D72F3)   // Biru untuk Update
                                : const Color(0xFFF59E0B),  // Kuning untuk Maintenance
                            borderRadius: BorderRadius.circular(8),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey.shade500,
                          labelStyle: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 13),
                          unselectedLabelStyle:
                              GoogleFonts.poppins(fontSize: 13),
                          dividerColor: Colors.transparent,
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.update_rounded,
                                    size: 15,
                                    color: tabController.index == 0
                                        ? Colors.white
                                        : const Color(0xFF1D72F3),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(getTxt('update_notes')),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.build_rounded,
                                    size: 15,
                                    color: tabController.index == 1
                                        ? Colors.white
                                        : const Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(getTxt('maintenance_notices')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
        body: _isLoading
            ? _buildSkeletonLoader()
            : _error != null
                ? Center(child: Text(_error!))
                : TabBarView(
                    children: [
                      _buildNewsList(_updates, 'update'),
                      _buildNewsList(_maintenance, 'maintenance'),
                    ],
                  ),
      ),
    );
  }

  Widget _buildNewsList(
      List<Map<String, dynamic>> newsItems, String type) {
    final Color bgColor =
        type == 'update' ? _updateLight : _maintLight;

    if (newsItems.isEmpty) {
      return Container(
        color: bgColor,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                type == 'update'
                    ? Icons.update_rounded
                    : Icons.build_rounded,
                size: 56,
                color: (type == 'update' ? _updatePrimary : _maintPrimary)
                    .withOpacity(0.25),
              ),
              const SizedBox(height: 12),
              Text(
                type == 'update'
                    ? 'No update notes available.'
                    : 'No maintenance notices.',
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: bgColor,
      child: RefreshIndicator(
        onRefresh: _fetchNews,
        color: type == 'update' ? _updatePrimary : _maintPrimary,
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: newsItems.length,
          itemBuilder: (context, index) {
            return _buildNewsItemCard(newsItems[index], type);
          },
        ),
      ),
    );
  }

  Widget _buildNewsItemCard(Map<String, dynamic> item, String type) {
    final bool isUpdate = type == 'update';
    final Color primary = isUpdate ? _updatePrimary : _maintPrimary;
    final Color badgeBg = isUpdate
        ? const Color(0xFFDBEAFE)
        : const Color(0xFFFEF3C7);

    final String title =
        item['title_${_currentLang.toLowerCase()}'] ?? item['title_en'] ?? '';
    final String content =
        item['content_${_currentLang.toLowerCase()}'] ??
            item['content_en'] ??
            '';
    final String? imageUrl = item['image_url'];
    final DateTime publishedDate =
        DateTime.parse(item['published_at']);

    String formattedDate;
    try {
      final locale = _currentLang == 'ID'
          ? 'id_ID'
          : (_currentLang == 'ZH' ? 'zh_CN' : 'en_US');
      formattedDate =
          DateFormat('d MMM yyyy', locale).format(publishedDate);
    } catch (_) {
      formattedDate = item['published_at'];
    }

    final String typeText = isUpdate
        ? (_currentLang == 'ID'
            ? 'Pembaruan'
            : (_currentLang == 'ZH' ? '更新' : 'Update'))
        : (_currentLang == 'ID'
            ? 'Pemberitahuan'
            : (_currentLang == 'ZH' ? '通知' : 'Notice'));

    // ── BUNGKUS DENGAN GestureDetector ──
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NewsDetailScreen(item: item, lang: _currentLang),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withOpacity(0.18), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: primary.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(19)),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 185,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 185,
                      color: Colors.grey.shade100,
                      child: Center(
                        child: CircularProgressIndicator(
                            color: primary, strokeWidth: 2),
                      ),
                    );
                  },
                ),
              ),
            if (imageUrl == null || imageUrl.isEmpty)
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(19)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isUpdate
                                  ? Icons.update_rounded
                                  : Icons.build_rounded,
                              size: 12,
                              color: primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              typeText,
                              style: GoogleFonts.poppins(
                                  color: primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.calendar_today_rounded,
                          size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: GoogleFonts.poppins(
                            color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Indikator "Ketuk untuk baca"
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _currentLang == 'ID'
                            ? 'Baca selengkapnya'
                            : _currentLang == 'ZH'
                                ? '阅读更多'
                                : 'Read more',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: primary,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 10, color: primary),
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

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 185,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
              ),
              const SizedBox(height: 12),
              Container(
                  height: 14, width: 160, color: Colors.white),
              const SizedBox(height: 10),
              Container(
                  height: 18,
                  width: double.infinity,
                  color: Colors.white),
              const SizedBox(height: 8),
              Container(
                  height: 14,
                  width: double.infinity,
                  color: Colors.white),
              const SizedBox(height: 5),
              Container(height: 14, width: 220, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}