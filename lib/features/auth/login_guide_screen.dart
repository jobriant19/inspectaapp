import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../admin/location/subunit/admin_subunit_indicator.dart';

class LoginGuideScreen extends StatefulWidget {
  final String lang;
  const LoginGuideScreen({super.key, required this.lang});

  @override
  State<LoginGuideScreen> createState() => _LoginGuideScreenState();
}

class _LoginGuideScreenState extends State<LoginGuideScreen> {
  static const Color _primary = Color(0xFF1D72F3);
  static const Color _bg = Color(0xFFF8FAFC);
  static const String _guideType = 'login';
  static const int _perPage = 7;

  List<Map<String, dynamic>> _steps = [];
  bool _isLoading = true;
  int _currentPage = 1;

  static const Map<String, Map<String, String>> _translations = {
    'EN': {
      'title': 'Login Guide',
      'subtitle': 'Follow these steps to sign in to Inspecta',
      'empty_title': 'No guide available yet',
      'empty_desc': 'The admin has not added a login guide yet.',
    },
    'ID': {
      'title': 'Panduan Login',
      'subtitle': 'Ikuti langkah-langkah berikut untuk masuk ke Inspecta',
      'empty_title': 'Panduan belum tersedia',
      'empty_desc': 'Admin belum menambahkan panduan login.',
    },
    'ZH': {
      'title': '登录指南',
      'subtitle': '请按照以下步骤登录 Inspecta',
      'empty_title': '暂无指南',
      'empty_desc': '管理员尚未添加登录指南。',
    },
  };

  String _t(String key) =>
      _translations[widget.lang]?[key] ?? _translations['EN']![key]!;

  String _titleKey() =>
      widget.lang == 'EN' ? 'title_en' : (widget.lang == 'ZH' ? 'title_zh' : 'title_id');
  String _descKey() => widget.lang == 'EN'
      ? 'description_en'
      : (widget.lang == 'ZH' ? 'description_zh' : 'description_id');

  @override
  void initState() {
    super.initState();
    _loadSteps();
  }

  Future<void> _loadSteps() async {
    try {
      final res = await Supabase.instance.client
          .from('app_guides')
          .select()
          .eq('guide_type', _guideType)
          .order('step_order', ascending: true)
          .order('id', ascending: true);
      if (mounted) {
        setState(() {
          _steps = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load login guide error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, __) => Container(
          height: 110,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, size: 72, color: _primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              _t('empty_title'),
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: _primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _t('empty_desc'),
              style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black45, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(Map<String, dynamic> step, int overallIndex) {
    final title = (step[_titleKey()] ?? '').toString();
    final desc = (step[_descKey()] ?? '').toString();
    final imageUrl = step['image_url']?.toString();

    return GestureDetector(
      onTap: () => _showDetailDialog(step, overallIndex),
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GAMBAR DI SISI KIRI
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 96, height: 96,
                          color: _primary.withValues(alpha: 0.08),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 96, height: 96,
                          color: _primary.withValues(alpha: 0.08),
                          child: Icon(Icons.image_not_supported_rounded, color: _primary.withValues(alpha: 0.4)),
                        ),
                      )
                    : Container(
                        width: 96, height: 96,
                        color: _primary.withValues(alpha: 0.08),
                        child: Icon(Icons.image_rounded, color: _primary.withValues(alpha: 0.4)),
                      ),
              ),
              Positioned(
                top: -8,
                left: -8,
                child: Container(
                  width: 26, height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    '${overallIndex + 1}',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // TITLE + DESCRIPTION DI SISI KANAN
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? '-' : title,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: _primary),
                ),
                const SizedBox(height: 6),
                Text(
                  desc.isEmpty ? '-' : desc,
                  style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  String _t3(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  void _showDetailDialog(Map<String, dynamic> step, int overallIndex) {
    final title = (step[_titleKey()] ?? '').toString();
    final desc = (step[_descKey()] ?? '').toString();
    final imageUrl = step['image_url']?.toString();

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _primary.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 2,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER: TOMBOL CLOSE X MERAH DI DALAM POPUP, POJOK KANAN ATAS
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 12, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_t3('Step', 'Langkah', '步骤')} ${overallIndex + 1}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: _primary,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFDC2626)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // GAMBAR PERSEGI DENGAN JARAK DI DALAM POPUP
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: (imageUrl != null && imageUrl.isNotEmpty)
                              ? () => _showFullScreenGuideImage(imageUrl)
                              : null,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: (imageUrl != null && imageUrl.isNotEmpty)
                                  ? CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color: _primary.withValues(alpha: 0.08),
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        color: _primary.withValues(alpha: 0.08),
                                        child: Icon(Icons.image_not_supported_rounded,
                                            size: 48, color: _primary.withValues(alpha: 0.4)),
                                      ),
                                    )
                                  : Container(
                                      color: _primary.withValues(alpha: 0.08),
                                      child: Icon(Icons.image_rounded,
                                          size: 48, color: _primary.withValues(alpha: 0.4)),
                                    ),
                            ),
                          ),
                        ),
                        // ICON FULLSCREEN (indikasi bisa diklik full screen)
                        if (imageUrl != null && imageUrl.isNotEmpty)
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.fullscreen_rounded, size: 18, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // TITLE + DESCRIPTION
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.isEmpty ? '-' : title,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          desc.isEmpty ? '-' : desc,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            height: 1.6,
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

  void _showFullScreenGuideImage(String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _GuideImageFullScreenViewer(imageUrl: imageUrl),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = _steps.isEmpty ? 1 : (_steps.length / _perPage).ceil();
    final safePage = _currentPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * _perPage;
    final endIdx = (startIdx + _perPage) > _steps.length ? _steps.length : startIdx + _perPage;
    final pageSteps = _steps.isEmpty ? <Map<String, dynamic>>[] : _steps.sublist(startIdx, endIdx);
    final bool hasPageIndicator = totalPages > 1;
    final double listBottomPad = hasPageIndicator ? 84.0 : 24.0;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: _primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('title'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: _primary),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : _steps.isEmpty
                    ? _buildEmptyState()
                    : ListView(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, listBottomPad),
                        children: [
                          Text(
                            _t('subtitle'),
                            style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black54, height: 1.5),
                          ),
                          const SizedBox(height: 16),
                          ...List.generate(pageSteps.length, (i) {
                            final overallIndex = startIdx + i;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildStepCard(pageSteps[i], overallIndex),
                            );
                          }),
                        ],
                      ),
          ),
          if (!_isLoading && hasPageIndicator)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: AdminSubunitPageIndicator(
                  currentPage: safePage,
                  totalPages: totalPages,
                  onPageChanged: (p) => setState(() => _currentPage = p),
                  color: _primary,
                  horizontalMargin: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GuideImageFullScreenViewer extends StatelessWidget {
  final String imageUrl;

  const _GuideImageFullScreenViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 5.0,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const CircularProgressIndicator(color: Colors.white70),
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}