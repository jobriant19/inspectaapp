import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/translation_service.dart';
import '../../../user/home/alert/required_field_alert.dart';

class _C {
  static const primary = Color(0xFF8B5CF6);
  static const primaryLt = Color(0xFFEDE9FE);
  static const red = Color(0xFFEF4444);
  static const textSub = Color(0xFF64748B);
  static const bg = Color(0xFFF8FAFC);
}

class AdminOnboardingSettingsScreen extends StatefulWidget {
  final String lang;
  final List<Map<String, dynamic>>? initialData;

  const AdminOnboardingSettingsScreen({
    super.key,
    required this.lang,
    this.initialData,
  });

  @override
  State<AdminOnboardingSettingsScreen> createState() =>
      _AdminOnboardingSettingsScreenState();
}

class _AdminOnboardingSettingsScreenState
    extends State<AdminOnboardingSettingsScreen> {
  final _supabase = Supabase.instance.client;

  static const List<Map<String, String>> _tabLangs = [
    {'code': 'ID', 'label': 'Indonesia', 'flag': '🇮🇩'},
    {'code': 'EN', 'label': 'English', 'flag': '🇺🇸'},
    {'code': 'ZH', 'label': '中文', 'flag': '🇨🇳'},
  ];

  List<Map<String, dynamic>> _slides = [];
  bool _isLoading = true;
  String _activeTab = 'ID';
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  String _titleKey(String tab) =>
      tab == 'EN' ? 'title_en' : (tab == 'ZH' ? 'title_zh' : 'title_id');

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _slides = _sorted(widget.initialData!);
      _isLoading = false;
    }
    _loadSilent();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _sorted(List<Map<String, dynamic>> raw) {
    final list = List<Map<String, dynamic>>.from(raw);
    list.sort((a, b) =>
        ((a['sort_order'] as int?) ?? 0).compareTo((b['sort_order'] as int?) ?? 0));
    return list;
  }

  Future<void> _loadSilent() async {
    try {
      final res = await _supabase
          .from('onboarding_slides')
          .select()
          .order('sort_order', ascending: true)
          .order('id', ascending: true);
      if (mounted) {
        setState(() {
          _slides = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Onboarding slides load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _slides;
    final key = _titleKey(_activeTab);
    return _slides.where((s) => (s[key] ?? '').toString().toLowerCase().contains(q)).toList();
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _slides.removeAt(oldIndex);
      _slides.insert(newIndex, item);
      for (int i = 0; i < _slides.length; i++) {
        _slides[i] = {..._slides[i], 'sort_order': i + 1};
      }
    });

    try {
      await Future.wait(_slides.map((s) => _supabase
          .from('onboarding_slides')
          .update({'sort_order': s['sort_order']})
          .eq('id', s['id'])));
      _loadSilent();
    } catch (e) {
      debugPrint('Reorder onboarding slides error: $e');
      _loadSilent();
    }
  }

  void _showSlideDialog({Map<String, dynamic>? existing}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _OnboardingSlideDialog(
        lang: widget.lang,
        existing: existing,
        allSlides: _slides,
        nextSortOrder: _slides.length + 1,
        onSaved: _loadSilent,
      ),
    );
  }

  void _openDetail(Map<String, dynamic> slide) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _OnboardingSlideDetailScreen(lang: widget.lang, slide: slide),
      ),
    );
  }

  Future<void> _deleteSlide(Map<String, dynamic> slide) async {
    final ok = await showDialog<bool>(
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
                    width: 72,
                    height: 72,
                    decoration:
                        const BoxDecoration(color: Color(0xFFFFEBEB), shape: BoxShape.circle),
                    child: const Icon(Icons.delete_forever_rounded,
                        color: Color(0xFFEF4444), size: 34),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _t('Delete Slide?', 'Hapus Slide?', '删除幻灯片？'),
                    style: GoogleFonts.poppins(
                        fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _t(
                      'This onboarding slide will be permanently deleted.',
                      'Slide onboarding ini akan dihapus secara permanen.',
                      '此引导页幻灯片将被永久删除。',
                    ),
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: const Color(0xFF64748B), height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_t('Delete', 'Hapus', '删除'),
                          style:
                              GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_t('Cancel', 'Batal', '取消'),
                          style: GoogleFonts.poppins(
                              color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
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
      await _supabase.from('onboarding_slides').delete().eq('id', slide['id']);
      _loadSilent();
    } catch (e) {
      debugPrint('Delete onboarding slide error: $e');
    }
  }

  Widget _buildAddButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: GestureDetector(
        onTap: () => _showSlideDialog(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_C.primary, _C.primary.withValues(alpha: 0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: _C.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_t('New Onboarding Slide', 'Slide Onboarding Baru', '新引导页幻灯片'),
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text(_t('Tap to add a new slide', 'Ketuk untuk menambah slide baru', '点击添加新幻灯片'),
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabChip(Map<String, String> info) {
    final isActive = info['code'] == _activeTab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = info['code']!),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? _C.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isActive ? _C.primary : Colors.grey.shade300, width: isActive ? 1.5 : 1),
            boxShadow: isActive
                ? [
                    BoxShadow(color: _C.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(info['flag']!, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(info['label']!,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _search = v),
          textAlignVertical: TextAlignVertical.center,
          style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 14),
          decoration: InputDecoration(
            hintText: _t('Search slide...', 'Cari slide...', '搜索幻灯片...'),
            hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 20),
            suffixIcon: _search.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _search = '');
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _C.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.slideshow_rounded, size: 13, color: _C.primary),
              const SizedBox(width: 5),
              Text('$count ${_t('slides', 'slide', '张幻灯片')}',
                  style: GoogleFonts.poppins(color: _C.primary, fontSize: 11, fontWeight: FontWeight.w700)),
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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
          height: 84,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
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
              height: 140,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                isFiltering ? Icons.search_off_rounded : Icons.slideshow_rounded,
                size: 80,
                color: _C.primary.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltering
                  ? _t('No matching slides', 'Slide Tidak Ditemukan', '未找到匹配幻灯片')
                  : _t('No slides yet', 'Belum Ada Slide', '暂无幻灯片'),
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: _C.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isFiltering
                  ? _t(
                      'Try adjusting your search keyword to find what you\'re looking for.',
                      'Coba ubah kata kunci pencarian untuk menemukan yang Anda cari.',
                      '尝试调整搜索关键词以查找您需要的内容。')
                  : _t(
                      'The app will show its default onboarding until you add slides here.',
                      'Aplikasi akan menampilkan onboarding bawaan sampai Anda menambah slide di sini.',
                      '在此添加幻灯片之前，应用将显示默认引导页。'),
              style: GoogleFonts.poppins(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black45, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (isFiltering) ...[
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _search = '');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: _C.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _C.primary.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 15, color: _C.primary),
                      const SizedBox(width: 6),
                      Text(_t('Clear search', 'Hapus pencarian', '清除搜索'),
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w700, color: _C.primary)),
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

  Widget _thumb(String? imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: (imageUrl != null && imageUrl.isNotEmpty)
          ? Image.network(imageUrl, width: 84, height: 84, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  width: 84, height: 84, color: _C.primaryLt,
                  child: const Icon(Icons.image_not_supported_rounded, color: _C.primary)))
          : Container(width: 84, height: 84, color: _C.primaryLt,
              child: const Icon(Icons.image_rounded, color: _C.primary)),
    );
  }

  Widget _buildSlideCard(Map<String, dynamic> slide, {required bool draggableIndex}) {
    final title = (slide[_titleKey(_activeTab)] ?? '').toString();
    final imageUrl = slide['image_url']?.toString();
    final order = slide['sort_order']?.toString() ?? '-';
    final index = _slides.indexWhere((s) => s['id'] == slide['id']);

    return GestureDetector(
      onTap: () => _openDetail(slide),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.primary.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            _thumb(imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title.isEmpty ? '-' : title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          color: const Color(0xFF1D72F3), fontWeight: FontWeight.w700, fontSize: 13.5)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: _C.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.reorder_rounded, size: 12, color: _C.primary),
                        const SizedBox(width: 4),
                        Text('${_t('Order', 'Urutan', '顺序')}: $order',
                            style: GoogleFonts.poppins(
                                fontSize: 10.5, fontWeight: FontWeight.w700, color: _C.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _showSlideDialog(existing: slide),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 15),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _deleteSlide(slide),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 15),
              ),
            ),
            if (draggableIndex && index != -1) ...[
              const SizedBox(width: 6),
              ReorderableDragStartListener(
                index: index,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.drag_indicator_rounded, color: Colors.black45, size: 17),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final bool isReorderable = _search.isEmpty;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _C.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: _C.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('Onboarding Slides', 'Slide Onboarding', '引导页幻灯片'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: _C.primary),
        ),
      ),
      body: Column(
        children: [
          _buildAddButton(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(children: _tabLangs.map(_buildTabChip).toList()),
          ),
          _buildSearchField(),
          const SizedBox(height: 10),
          _buildCountBadge(filtered.length),
          const SizedBox(height: 4),
          if (isReorderable && filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _t('Hold the drag icon to reorder slides', 'Tahan ikon drag untuk mengatur urutan slide', '按住拖动图标以调整幻灯片顺序'),
                  style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: _C.textSub),
                ),
              ),
            ),
          const SizedBox(height: 6),
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : filtered.isEmpty
                    ? _buildEmptyState()
                    : (isReorderable
                        ? RefreshIndicator(
                            onRefresh: _loadSilent,
                            color: _C.primary,
                            child: ReorderableListView.builder(
                              buildDefaultDragHandles: false,
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              itemCount: filtered.length,
                              onReorder: _onReorder,
                              itemBuilder: (_, i) => Padding(
                                key: ValueKey(filtered[i]['id']),
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildSlideCard(filtered[i], draggableIndex: true),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadSilent,
                            color: _C.primary,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) => _buildSlideCard(filtered[i], draggableIndex: false),
                            ),
                          )),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlideDetailScreen extends StatefulWidget {
  final String lang;
  final Map<String, dynamic> slide;

  const _OnboardingSlideDetailScreen({required this.lang, required this.slide});

  @override
  State<_OnboardingSlideDetailScreen> createState() => _OnboardingSlideDetailScreenState();
}

class _OnboardingSlideDetailScreenState extends State<_OnboardingSlideDetailScreen> {
  static const List<Map<String, String>> _tabLangs = [
    {'code': 'ID', 'label': 'Indonesia', 'flag': '🇮🇩'},
    {'code': 'EN', 'label': 'English', 'flag': '🇺🇸'},
    {'code': 'ZH', 'label': '中文', 'flag': '🇨🇳'},
  ];

  late String _activeTab;

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  String _titleKey(String tab) =>
      tab == 'EN' ? 'title_en' : (tab == 'ZH' ? 'title_zh' : 'title_id');
  String _descKey(String tab) => tab == 'EN'
      ? 'description_en'
      : (tab == 'ZH' ? 'description_zh' : 'description_id');

  @override
  void initState() {
    super.initState();
    _activeTab = widget.lang;
  }

  void _openFullscreenImage(String url) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => _OnboardingFullscreenImageViewer(imageUrl: url),
      ),
    );
  }

  Widget _detailLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 13, color: _C.primary),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.poppins(
                color: _C.primary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      ],
    );
  }

  Widget _buildTabChip(Map<String, String> info) {
    final isActive = info['code'] == _activeTab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = info['code']!),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? _C.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isActive ? _C.primary : Colors.grey.shade300, width: isActive ? 1.5 : 1),
            boxShadow: isActive
                ? [
                    BoxShadow(color: _C.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(info['flag']!, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(info['label']!,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.slide['image_url']?.toString();
    final title = (widget.slide[_titleKey(_activeTab)] ?? '').toString();
    final desc = (widget.slide[_descKey(_activeTab)] ?? '').toString();
    final order = widget.slide['sort_order']?.toString() ?? '-';

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _C.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: _C.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('Slide Detail', 'Detail Slide', '幻灯片详情'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: _C.primary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: (imageUrl != null && imageUrl.isNotEmpty) ? () => _openFullscreenImage(imageUrl) : null,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _C.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _C.primary.withValues(alpha: 0.2)),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: (imageUrl != null && imageUrl.isNotEmpty)
                            ? Image.network(imageUrl, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported_rounded,
                                    size: 48, color: _C.primary.withValues(alpha: 0.4)))
                            : Icon(Icons.image_rounded, size: 48, color: _C.primary.withValues(alpha: 0.4)),
                      ),
                      if (imageUrl != null && imageUrl.isNotEmpty)
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: _tabLangs.map(_buildTabChip).toList()),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _C.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.reorder_rounded, size: 14, color: _C.primary),
                  const SizedBox(width: 6),
                  Text('${_t('Order', 'Urutan', '顺序')}: $order',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _C.primary)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _detailLabel(Icons.short_text_rounded, _t('Title', 'Judul', '标题')),
            const SizedBox(height: 6),
            Text(
              title.isEmpty ? '-' : title,
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1D72F3)),
            ),
            const SizedBox(height: 18),
            _detailLabel(Icons.notes_rounded, _t('Description', 'Deskripsi', '描述')),
            const SizedBox(height: 6),
            Text(
              desc.isEmpty ? '-' : desc,
              style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.black, height: 1.6, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _OnboardingFullscreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final Uint8List? previewBytes;

  const _OnboardingFullscreenImageViewer({required this.imageUrl, this.previewBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black.withValues(alpha: 0.95)),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: Center(
                  child: previewBytes != null
                      ? Image.memory(previewBytes!, fit: BoxFit.contain)
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_rounded,
                            color: Colors.white54,
                            size: 64,
                          ),
                        ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _C.red.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.2),
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlideDialog extends StatefulWidget {
  final String lang;
  final Map<String, dynamic>? existing;
  final List<Map<String, dynamic>> allSlides;
  final int nextSortOrder;
  final VoidCallback onSaved;

  const _OnboardingSlideDialog({
    required this.lang,
    required this.existing,
    required this.allSlides,
    required this.nextSortOrder,
    required this.onSaved,
  });

  @override
  State<_OnboardingSlideDialog> createState() => _OnboardingSlideDialogState();
}

class _OnboardingSlideDialogState extends State<_OnboardingSlideDialog> {
  final _supabase = Supabase.instance.client;

  String? _imageUrl;
  Uint8List? _previewBytes;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  TextEditingController? _orderCtrl;

  bool get isEdit => widget.existing != null;

  String _titleKey(String tab) =>
      tab == 'EN' ? 'title_en' : (tab == 'ZH' ? 'title_zh' : 'title_id');
  String _descKey(String tab) => tab == 'EN'
      ? 'description_en'
      : (tab == 'ZH' ? 'description_zh' : 'description_id');

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _imageUrl = e?['image_url'] as String?;
    _titleCtrl = TextEditingController(text: isEdit ? (e![_titleKey(widget.lang)] ?? '').toString() : '');
    _descCtrl = TextEditingController(text: isEdit ? (e![_descKey(widget.lang)] ?? '').toString() : '');
    if (isEdit) {
      final currentOrder = (e!['sort_order'] as int?) ?? 1;
      _orderCtrl = TextEditingController(text: currentOrder.toString());
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _orderCtrl?.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _previewBytes = bytes;
        _isUploadingImage = true;
      });

      final ext = picked.name.split('.').last.toLowerCase();
      final safeExt = ext.isEmpty ? 'jpg' : ext;
      final fileName = 'onboarding-${DateTime.now().millisecondsSinceEpoch}.$safeExt';
      final filePath = 'onboarding/$fileName';
      final String contentType = safeExt == 'png'
          ? 'image/png'
          : safeExt == 'gif'
              ? 'image/gif'
              : safeExt == 'webp'
                  ? 'image/webp'
                  : 'image/jpeg';

      await _supabase.storage.from('onboarding-images').uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );
      final newUrl = _supabase.storage.from('onboarding-images').getPublicUrl(filePath);
      if (mounted) {
        setState(() {
          _imageUrl = newUrl;
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      debugPrint('Error uploading onboarding image: $e');
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _openFullscreenPreview() {
    final url = _imageUrl;
    if (_previewBytes == null && (url == null || url.isEmpty)) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => _OnboardingFullscreenImageViewer(
          imageUrl: url ?? '',
          previewBytes: _previewBytes,
        ),
      ),
    );
  }

  Widget _fieldLabel(IconData icon, String label, {bool required = true}) {
    return Row(
      children: [
        Icon(icon, size: 13, color: _C.primary),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.poppins(
                color: _C.primary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        if (required) ...[
          const SizedBox(width: 3),
          Text('*',
              style: GoogleFonts.poppins(color: _C.red, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ],
    );
  }

  Widget _buildImagePicker() {
    final hasPreview = _previewBytes != null || (_imageUrl != null && _imageUrl!.isNotEmpty);
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _C.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.primary.withValues(alpha: 0.3), width: 1.3),
        ),
        child: hasPreview
            ? Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTap: _openFullscreenPreview,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.7),
                      child: _previewBytes != null
                          ? Image.memory(_previewBytes!, fit: BoxFit.cover)
                          : Image.network(_imageUrl!, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: _C.primary, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.photo_library_rounded, size: 14, color: _C.primary),
                      ),
                    ),
                  ),
                ],
              )
            : GestureDetector(
                onTap: _pickImage,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: _C.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
                        child: const Icon(Icons.add_photo_alternate_rounded, color: _C.primary, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(_t('Tap to select from gallery', 'Tap untuk pilih dari galeri', '点击从相册选择'),
                          style: GoogleFonts.poppins(color: _C.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl,
      {int maxLines = 1, String? hint, TextInputType? keyboardType, bool isTitleField = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(
          color: isTitleField ? const Color(0xFF1D72F3) : Colors.black,
          fontWeight: isTitleField ? FontWeight.w700 : FontWeight.w600,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.black26, fontSize: 12),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    final missing = <MissingFieldItem>[];
    if (_imageUrl == null || _imageUrl!.isEmpty) {
      missing.add(MissingFieldItem(icon: Icons.image_rounded, label: _t('Slide Image', 'Gambar Slide', '幻灯片图片')));
    }
    if (title.isEmpty) {
      missing.add(MissingFieldItem(icon: Icons.short_text_rounded, label: _t('Title', 'Judul', '标题')));
    }
    if (desc.isEmpty) {
      missing.add(MissingFieldItem(icon: Icons.notes_rounded, label: _t('Description', 'Deskripsi', '描述')));
    }
    if (missing.isNotEmpty) {
      RequiredFieldAlert.show(context, lang: widget.lang, missingFields: missing);
      return;
    }

    setState(() => _isSaving = true);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _OnboardingTranslatingDialog(color: _C.primary, lang: widget.lang),
      );
    }

    Map<String, String> titleAll = {'id': title, 'en': title, 'zh': title};
    Map<String, String> descAll = {'id': desc, 'en': desc, 'zh': desc};
    try {
      final results = await Future.wait<Map<String, String>>([
        TranslationHelper.instance.translateDescriptionAllLangs(title, widget.lang),
        TranslationHelper.instance.translateDescriptionAllLangs(desc, widget.lang),
      ]);
      titleAll = results[0];
      descAll = results[1];
    } catch (e) {
      debugPrint('Onboarding slide translate error: $e');
    }

    final data = <String, dynamic>{
      'image_url': _imageUrl,
      'title_id': titleAll['id'],
      'title_en': titleAll['en'],
      'title_zh': titleAll['zh'],
      'description_id': descAll['id'],
      'description_en': descAll['en'],
      'description_zh': descAll['zh'],
    };

    if (!isEdit) {
      data['sort_order'] = widget.nextSortOrder;
    }

    try {
      if (isEdit) {
        final existingId = widget.existing!['id'];
        final currentOrder = (widget.existing!['sort_order'] as int?) ?? 1;
        final total = widget.allSlides.length;
        final parsed = int.tryParse(_orderCtrl?.text.trim() ?? '');
        if (parsed != null) {
          final desiredOrder = parsed.clamp(1, total == 0 ? 1 : total);
          if (desiredOrder != currentOrder) {
            final occupantIndex = widget.allSlides.indexWhere(
                (s) => s['id'] != existingId && (s['sort_order'] as int?) == desiredOrder);
            if (occupantIndex != -1) {
              await _supabase
                  .from('onboarding_slides')
                  .update({'sort_order': currentOrder})
                  .eq('id', widget.allSlides[occupantIndex]['id']);
            }
            data['sort_order'] = desiredOrder;
          }
        }
        await _supabase.from('onboarding_slides').update(data).eq('id', existingId);
      } else {
        await _supabase.from('onboarding_slides').insert(data);
      }

      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      debugPrint('Save onboarding slide error: $e');
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Icon(Icons.slideshow_rounded, size: 18, color: _C.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEdit ? _t('Edit Slide', 'Ubah Slide', '编辑幻灯片') : _t('Add New Slide', 'Tambah Slide Baru', '添加新幻灯片'),
                      style: GoogleFonts.poppins(color: _C.primary, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: _C.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.close, size: 18, color: _C.red),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel(Icons.image_rounded, _t('Slide Image', 'Gambar Slide', '幻灯片图片')),
                    const SizedBox(height: 8),
                    _buildImagePicker(),
                    const SizedBox(height: 18),
                    _fieldLabel(Icons.short_text_rounded, _t('Title', 'Judul', '标题')),
                    const SizedBox(height: 6),
                    _buildTextField(_titleCtrl,
                        isTitleField: true,
                        hint: _t('e.g. Welcome to Inspecta', 'cth. Selamat Datang di Inspecta', '例如：欢迎来到 Inspecta')),
                    const SizedBox(height: 16),
                    _fieldLabel(Icons.notes_rounded, _t('Description', 'Deskripsi', '描述')),
                    const SizedBox(height: 6),
                    _buildTextField(_descCtrl,
                        maxLines: 4, hint: _t('Slide description...', 'Deskripsi slide...', '幻灯片描述...')),
                    const SizedBox(height: 6),
                    Text(
                      _t(
                        'Will be auto-translated to the other 2 languages.',
                        'Akan diterjemahkan otomatis ke 2 bahasa lainnya.',
                        '将自动翻译为其他两种语言。',
                      ),
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _C.textSub),
                    ),
                    if (isEdit) ...[
                      const SizedBox(height: 16),
                      _fieldLabel(Icons.reorder_rounded, _t('Slide Order', 'Urutan Slide', '幻灯片顺序'), required: false),
                      const SizedBox(height: 6),
                      _buildTextField(_orderCtrl!,
                          keyboardType: TextInputType.number,
                          hint: _t('e.g. 2', 'cth. 2', '例如：2')),
                      const SizedBox(height: 6),
                      Text(
                        _t(
                          'If this position is already used by another slide, they will swap.',
                          'Jika posisi ini sudah digunakan slide lain, urutannya akan bertukar.',
                          '如果此位置已被其他幻灯片占用，顺序将互换。',
                        ),
                        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _C.textSub),
                      ),
                    ],
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, -2))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_t('Cancel', 'Batal', '取消'),
                          style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: (_isSaving || _isUploadingImage) ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.primary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                ),
                                const SizedBox(width: 8),
                                Text(_t('Saving...', 'Menyimpan...', '保存中...'),
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                              ],
                            )
                          : Text(_t('Save', 'Simpan', '保存'),
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingTranslatingDialog extends StatefulWidget {
  final Color color;
  final String lang;
  const _OnboardingTranslatingDialog({required this.color, required this.lang});

  @override
  State<_OnboardingTranslatingDialog> createState() => _OnboardingTranslatingDialogState();
}

class _OnboardingTranslatingDialogState extends State<_OnboardingTranslatingDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.lang) {
      case 'EN':
        return 'Translating...';
      case 'ZH':
        return '翻译中...';
      default:
        return 'Menerjemahkan...';
    }
  }

  String get _subtitle {
    switch (widget.lang) {
      case 'EN':
        return 'Converting to Indonesian, English & Mandarin';
      case 'ZH':
        return '正在转换为印尼语、英语和中文';
      default:
        return 'Mengubah ke Bahasa Indonesia, Inggris & Mandarin';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = 0.90 + (_controller.value * 0.12);
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [widget.color, widget.color.withValues(alpha: 0.6)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: const Icon(Icons.translate_rounded, color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(height: 22),
            Text(_title,
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(_subtitle,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B), height: 1.4),
                textAlign: TextAlign.center),
            const SizedBox(height: 22),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: 150,
                height: 6,
                child: LinearProgressIndicator(
                  backgroundColor: widget.color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}