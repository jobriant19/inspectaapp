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

  int _updatePage = 1;
  int _maintPage = 1;
  static const int _perPage = 10;

  static const _updatePrimary = Color(0xFF1D72F3);
  static const _maintPrimary  = Color(0xFFF59E0B);

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
          _updatePage = 1;
          _maintPage = 1;
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
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          toolbarHeight: kToolbarHeight,
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
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black.withValues(alpha:0.08),
          iconTheme: const IconThemeData(color: Color(0xFF1D72F3)),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(58),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Builder(
                builder: (context) {
                  final tabController = DefaultTabController.of(context);
                  return AnimatedBuilder(
                    animation: tabController,
                    builder: (context, _) {
                      return Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: TabBar(
                          isScrollable: false,
                          tabAlignment: TabAlignment.fill,
                          indicator: BoxDecoration(
                            color: tabController.index == 0
                                ? const Color(0xFF1D72F3) 
                                : const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: [
                              BoxShadow(
                                color: (tabController.index == 0
                                        ? const Color(0xFF1D72F3)
                                        : const Color(0xFFF59E0B))
                                    .withValues(alpha: 0.30),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey.shade500,
                          labelPadding: EdgeInsets.zero,
                          labelStyle: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700, fontSize: 12.5),
                          unselectedLabelStyle: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 12.5),
                          dividerColor: Colors.transparent,
                          tabs: [
                            Tab(
                              height: 38,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.update_rounded,
                                    size: 15,
                                    color: tabController.index == 0
                                        ? Colors.white
                                        : const Color(0xFF1D72F3),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _currentLang == 'ID' ? 'Pembaruan' : (_currentLang == 'ZH' ? '更新' : 'Update'),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Tab(
                              height: 38,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.build_rounded,
                                    size: 15,
                                    color: tabController.index == 1
                                        ? Colors.white
                                        : const Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _currentLang == 'ID' ? 'Pemeliharaan' : (_currentLang == 'ZH' ? '维护' : 'Maintenance'),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
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
                      _buildNewsList(
                        _updates,
                        'update',
                        _updatePage,
                        (p) => setState(() => _updatePage = p),
                      ),
                      _buildNewsList(
                        _maintenance,
                        'maintenance',
                        _maintPage,
                        (p) => setState(() => _maintPage = p),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildNewsList(
    List<Map<String, dynamic>> newsItems,
    String type,
    int currentPage,
    ValueChanged<int> onPageChanged,
  ) {
    const Color bgColor = Color(0xFFF8FAFC);
    final Color primary = type == 'update' ? _updatePrimary : _maintPrimary;

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
                color: primary.withValues(alpha:0.25),
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

    final totalPages = (newsItems.length / _perPage).ceil().clamp(1, 999999);
    final safePage = currentPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * _perPage;
    final endIdx = (startIdx + _perPage) > newsItems.length
        ? newsItems.length
        : startIdx + _perPage;
    final pageData = newsItems.sublist(startIdx, endIdx);

    return Container(
      color: bgColor,
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchNews,
              color: primary,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                itemCount: pageData.length,
                itemBuilder: (context, index) {
                  return _buildNewsItemCard(pageData[index], type);
                },
              ),
            ),
          ),
          if (totalPages > 1)
            _NewsPageIndicator(
              currentPage: safePage,
              totalPages: totalPages,
              color: primary,
              onPageChanged: onPageChanged,
            ),
        ],
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
      formattedDate = DateFormat('d MMM yyyy').format(publishedDate);
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

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NewsDetailScreen(item: item, lang: _currentLang),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withValues(alpha:0.16), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: primary.withValues(alpha:0.08),
                blurRadius: 16,
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
                  height: 170,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 170,
                    color: primary.withValues(alpha: 0.08),
                    child: Center(
                      child: Icon(
                        isUpdate ? Icons.update_rounded : Icons.build_rounded,
                        color: primary.withValues(alpha: 0.3),
                        size: 44,
                      ),
                    ),
                  ),
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 170,
                      color: Colors.grey.shade100,
                      child: Center(
                        child: CircularProgressIndicator(
                            color: primary, strokeWidth: 2),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
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
                            const SizedBox(width: 5),
                            Text(
                              typeText,
                              style: GoogleFonts.poppins(
                                  color: primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 11, color: Colors.grey.shade500),
                            const SizedBox(width: 5),
                            Text(
                              formattedDate,
                              style: GoogleFonts.poppins(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1D72F3)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.55),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: Colors.grey.shade100),
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
                            fontSize: 11.5,
                            color: primary,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 4),
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
                height: 170,
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

class _NewsPageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Color color;
  final ValueChanged<int> onPageChanged;

  const _NewsPageIndicator({
    required this.currentPage,
    required this.totalPages,
    required this.color,
    required this.onPageChanged,
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
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottomSpacing),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 12,
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
          color: isActive ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? null
              : Border.all(color: color.withValues(alpha: 0.25)),
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
              ? color.withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.08),
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