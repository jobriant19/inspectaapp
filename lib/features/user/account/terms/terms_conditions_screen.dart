import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TermsConditionsScreen extends StatelessWidget {
  final String lang;
  const TermsConditionsScreen({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    return LegalDocScreen(
      lang: lang,
      docType: 'terms_conditions',
      primaryColor: const Color(0xFF1D72F3),
      headerIcon: Icons.gavel_rounded,
      titleId: 'Syarat & Ketentuan',
      titleEn: 'Terms & Conditions',
      titleZh: '条款和条件',
    );
  }
}

class LegalDocScreen extends StatefulWidget {
  final String lang;
  final String docType;
  final Color primaryColor;
  final IconData headerIcon;
  final String titleId;
  final String titleEn;
  final String titleZh;

  const LegalDocScreen({
    super.key,
    required this.lang,
    required this.docType,
    required this.primaryColor,
    required this.headerIcon,
    required this.titleId,
    required this.titleEn,
    required this.titleZh,
  });

  @override
  State<LegalDocScreen> createState() => _LegalDocScreenState();
}

class _LegalDocScreenState extends State<LegalDocScreen> {
  static const _bg = Color(0xFFEFF6FF);
  static const int _perPage = 5;

  static const List<Map<String, String>> _langs = [
    {'code': 'ID', 'label': 'Bahasa Indonesia', 'flag': '🇮🇩'},
    {'code': 'EN', 'label': 'English', 'flag': '🇺🇸'},
    {'code': 'ZH', 'label': '中文', 'flag': '🇨🇳'},
  ];

  late String _displayLang;
  List<Map<String, dynamic>> _sections = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _displayLang = widget.lang;
    _fetchSections();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _t3(String en, String id, String zh) {
    if (_displayLang == 'EN') return en;
    if (_displayLang == 'ZH') return zh;
    return id;
  }

  String get _pageTitle {
    if (_displayLang == 'EN') return widget.titleEn;
    if (_displayLang == 'ZH') return widget.titleZh;
    return widget.titleId;
  }

  String _flagFor(String code) => _langs.firstWhere((l) => l['code'] == code)['flag']!;

  String _titleKey(String lang) =>
      lang == 'EN' ? 'title_en' : (lang == 'ZH' ? 'title_zh' : 'title');
  String _contentKey(String lang) =>
      lang == 'EN' ? 'content_en' : (lang == 'ZH' ? 'content_zh' : 'content');

  Future<void> _fetchSections({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('legal_documents')
          .select()
          .eq('doc_type', widget.docType)
          .order('created_at');
      if (mounted) {
        setState(() {
          _sections = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('${widget.docType} fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _sections;
    final key = _titleKey(_displayLang);
    return _sections.where((s) => (s[key] ?? '').toString().toLowerCase().contains(q)).toList();
  }

  Widget _buildLangSwitcher() {
    return GestureDetector(
      onTap: _showLanguagePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: widget.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: widget.primaryColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_flagFor(_displayLang), style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(_displayLang,
                style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w700, color: widget.primaryColor)),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: widget.primaryColor),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                  color: widget.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 2,
                  offset: const Offset(0, 12)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _t3('Select Language', 'Pilih Bahasa', '选择语言'),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700, fontSize: 17, color: widget.primaryColor),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: widget.primaryColor.withValues(alpha: 0.08), shape: BoxShape.circle),
                        child: Icon(Icons.close_rounded, size: 18, color: widget.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  children: _langs.map((l) {
                    final isSelected = _displayLang == l['code'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _displayLang = l['code']!;
                          _currentPage = 1;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? widget.primaryColor.withValues(alpha: 0.08)
                              : const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? widget.primaryColor : const Color(0xFFE0E7FF),
                            width: isSelected ? 1.6 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE0E7FF)),
                              ),
                              child: Text(l['flag']!, style: const TextStyle(fontSize: 22)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                l['label']!,
                                style: GoogleFonts.poppins(
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  fontSize: 15,
                                  color: isSelected ? widget.primaryColor : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, color: widget.primaryColor, size: 20),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.primaryColor.withValues(alpha: 0.20)),
          boxShadow: [
            BoxShadow(
                color: widget.primaryColor.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() {
            _search = v;
            _currentPage = 1;
          }),
          textAlignVertical: TextAlignVertical.center,
          style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: _t3('Search...', 'Cari...', '搜索...'),
            hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
            prefixIcon: Icon(Icons.search, color: widget.primaryColor.withValues(alpha: 0.7), size: 20),
            suffixIcon: _search.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() {
                        _search = '';
                        _currentPage = 1;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFEF4444)),
                    ),
                  )
                : null,
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildCountBadge(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: widget.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.primaryColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.list_alt_rounded, size: 13, color: widget.primaryColor),
              const SizedBox(width: 5),
              Text('$count ${_t3('results', 'hasil', '结果')}',
                  style: GoogleFonts.poppins(
                      color: widget.primaryColor, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, __) => Container(
          height: 130,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isFiltering = _search.isNotEmpty;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                isFiltering ? Icons.search_off_rounded : widget.headerIcon,
                size: 80,
                color: widget.primaryColor.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltering
                  ? _t3('No matching sections', 'Bagian Tidak Ditemukan', '未找到匹配部分')
                  : _t3('No content yet', 'Belum Ada Konten', '暂无内容'),
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: widget.primaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isFiltering
                  ? _t3(
                      'Try adjusting your search keyword to find what you\'re looking for.',
                      'Coba ubah kata kunci pencarian untuk menemukan yang Anda cari.',
                      '尝试调整搜索关键词以查找您需要的内容。')
                  : _t3(
                      'Content will show up here as soon as it\'s published.',
                      'Konten akan muncul di sini setelah dipublikasikan.',
                      '内容发布后将显示在此处。'),
              style: GoogleFonts.poppins(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black45, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (isFiltering) ...[
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() {
                    _search = '';
                    _currentPage = 1;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: widget.primaryColor.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 15, color: widget.primaryColor),
                      const SizedBox(width: 6),
                      Text(_t3('Clear search', 'Hapus pencarian', '清除搜索'),
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w700, color: widget.primaryColor)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> section, int number) {
    final title = (section[_titleKey(_displayLang)] ?? '').toString();
    final content = (section[_contentKey(_displayLang)] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.primaryColor.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
              color: widget.primaryColor.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.primaryColor, widget.primaryColor.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text('$number',
                      style:
                          GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    title.isEmpty ? '-' : title,
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF1D72F3), fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content.isEmpty ? '-' : content,
            style: GoogleFonts.poppins(
                color: Colors.black, fontWeight: FontWeight.w600, fontSize: 13.5, height: 1.7),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final totalPages = filtered.isEmpty ? 1 : (filtered.length / _perPage).ceil();
    if (_currentPage > totalPages) _currentPage = totalPages;
    if (_currentPage < 1) _currentPage = 1;
    final start = (_currentPage - 1) * _perPage;
    final end = (start + _perPage).clamp(0, filtered.length);
    final pageItems = filtered.isEmpty ? <Map<String, dynamic>>[] : filtered.sublist(start, end);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: widget.primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_pageTitle,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: widget.primaryColor, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        iconTheme: IconThemeData(color: widget.primaryColor),
        centerTitle: true,
        surfaceTintColor: Colors.white,
        actions: [
          _buildLangSwitcher(),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(),
          _buildCountBadge(filtered.length),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : pageItems.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => _fetchSections(showLoading: false),
                        color: widget.primaryColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                          itemCount: pageItems.length,
                          itemBuilder: (_, i) => _buildCard(pageItems[i], start + i + 1),
                        ),
                      ),
          ),
          if (!_isLoading && totalPages > 1)
            _TermsPageIndicator(
              currentPage: _currentPage,
              totalPages: totalPages,
              color: widget.primaryColor,
              onPageChanged: (p) => setState(() => _currentPage = p),
            ),
        ],
      ),
    );
  }
}

class _TermsPageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Color color;
  final ValueChanged<int> onPageChanged;

  const _TermsPageIndicator({
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
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomSpacing),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            _arrowButton(
              icon: Icons.arrow_back_ios_new_rounded,
              enabled: canPrev,
              onTap: () {
                if (canPrev) onPageChanged(currentPage - 1);
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
                if (canNext) onPageChanged(currentPage + 1);
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
        if (page != currentPage) onPageChanged(page);
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
        child: Text('$page',
            style: GoogleFonts.poppins(
                color: isActive ? Colors.white : color, fontWeight: FontWeight.w800, fontSize: 13)),
      ),
    );
  }

  Widget _arrowButton({required IconData icon, required bool enabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: enabled ? color : Colors.grey.shade400),
      ),
    );
  }
}