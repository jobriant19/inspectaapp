import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/translation_service.dart';
import '../../../user/home/alert/required_field_alert.dart';

class _C {
  static const primary = Color(0xFF1D72F3);
  static const primaryLt = Color(0xFFE3F2FD);
  static const red = Color(0xFFEF4444);
  static const textSub = Color(0xFF64748B);
  static const bg = Color(0xFFF8FAFC);
}

class AdminGuideSettingsScreen extends StatefulWidget {
  final String lang;
  const AdminGuideSettingsScreen({super.key, required this.lang});

  @override
  State<AdminGuideSettingsScreen> createState() => _AdminGuideSettingsScreenState();
}

class _AdminGuideSettingsScreenState extends State<AdminGuideSettingsScreen> {
  final _supabase = Supabase.instance.client;
  static const String _guideType = 'login';

  static const List<Map<String, String>> _tabLangs = [
    {'code': 'ID', 'label': 'Indonesia', 'flag': '🇮🇩'},
    {'code': 'EN', 'label': 'English', 'flag': '🇺🇸'},
    {'code': 'ZH', 'label': '中文', 'flag': '🇨🇳'},
  ];

  List<Map<String, dynamic>> _steps = [];
  bool _isLoading = true;
  String _activeTab = 'ID';
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  String _titleKey(String tab) => tab == 'EN' ? 'title_en' : (tab == 'ZH' ? 'title_zh' : 'title_id');

  @override
  void initState() {
    super.initState();
    _loadSilent();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSilent() async {
    try {
      final res = await _supabase
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
      debugPrint('Guide steps load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _steps;
    final key = _titleKey(_activeTab);
    return _steps.where((s) => (s[key] ?? '').toString().toLowerCase().contains(q)).toList();
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, item);
      for (int i = 0; i < _steps.length; i++) {
        _steps[i] = {..._steps[i], 'step_order': i + 1};
      }
    });

    try {
      await Future.wait(_steps.map((s) => _supabase
          .from('app_guides')
          .update({'step_order': s['step_order']})
          .eq('id', s['id'])));
      _loadSilent();
    } catch (e) {
      debugPrint('Reorder guide steps error: $e');
      _loadSilent();
    }
  }

  void _showStepDialog({Map<String, dynamic>? existing}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _GuideStepDialog(
        lang: widget.lang,
        guideType: _guideType,
        existing: existing,
        allSteps: _steps,
        nextStepOrder: _steps.length + 1,
        onSaved: _loadSilent,
      ),
    );
  }

  Future<void> _deleteStep(Map<String, dynamic> step) async {
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
                    _t('Delete Step?', 'Hapus Langkah?', '删除步骤？'),
                    style: GoogleFonts.poppins(
                        fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _t(
                      'This guide step will be permanently deleted.',
                      'Langkah panduan ini akan dihapus secara permanen.',
                      '此指南步骤将被永久删除。',
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
      await _supabase.from('app_guides').delete().eq('id', step['id']);
      _loadSilent();
    } catch (e) {
      debugPrint('Delete guide step error: $e');
    }
  }

  Widget _buildAddButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: GestureDetector(
        onTap: () => _showStepDialog(),
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
                    Text(_t('New Guide Step', 'Langkah Panduan Baru', '新指南步骤'),
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text(_t('Tap to add a new step', 'Ketuk untuk menambah langkah baru', '点击添加新步骤'),
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
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _search = v),
          textAlignVertical: TextAlignVertical.center,
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 14),
          decoration: InputDecoration(
            hintText: _t('Search step...', 'Cari langkah...', '搜索步骤...'),
            hintStyle: GoogleFonts.poppins(color: Colors.black38, fontWeight: FontWeight.w600, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 20),
            prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 0),
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
            suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 0),
            border: InputBorder.none,
            isCollapsed: true,
            isDense: true,
            contentPadding: EdgeInsets.zero,
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
              Icon(Icons.menu_book_rounded, size: 13, color: _C.primary),
              const SizedBox(width: 5),
              Text('$count ${_t('steps', 'langkah', '个步骤')}',
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
                isFiltering ? Icons.search_off_rounded : Icons.menu_book_rounded,
                size: 80,
                color: _C.primary.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltering
                  ? _t('No matching steps', 'Langkah Tidak Ditemukan', '未找到匹配步骤')
                  : _t('No steps yet', 'Belum Ada Langkah', '暂无步骤'),
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
                      'The login guide screen will show nothing until you add steps here.',
                      'Layar panduan login tidak akan menampilkan apa pun sampai Anda menambah langkah di sini.',
                      '在此添加步骤之前，登录指南页面将不会显示任何内容。'),
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

  Widget _buildStepCard(Map<String, dynamic> step, {required bool draggableIndex}) {
    final title = (step[_titleKey(_activeTab)] ?? '').toString();
    final imageUrl = step['image_url']?.toString();
    final order = step['step_order']?.toString() ?? '-';
    final index = _steps.indexWhere((s) => s['id'] == step['id']);

    return Container(
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
                      Text('${_t('Step', 'Langkah', '步骤')}: $order',
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
            onTap: () => _showStepDialog(existing: step),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 15),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _deleteStep(step),
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
        surfaceTintColor: Colors.white,
        foregroundColor: _C.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: _C.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('Login Guide Settings', 'Pengaturan Panduan Login', '登录指南设置'),
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
                  _t('Hold the drag icon to reorder steps', 'Tahan ikon drag untuk mengatur urutan langkah', '按住拖动图标以调整步骤顺序'),
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
                                child: _buildStepCard(filtered[i], draggableIndex: true),
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
                              itemBuilder: (_, i) => _buildStepCard(filtered[i], draggableIndex: false),
                            ),
                          )),
          ),
        ],
      ),
    );
  }
}

class _GuideStepDialog extends StatefulWidget {
  final String lang;
  final String guideType;
  final Map<String, dynamic>? existing;
  final List<Map<String, dynamic>> allSteps;
  final int nextStepOrder;
  final VoidCallback onSaved;

  const _GuideStepDialog({
    required this.lang,
    required this.guideType,
    required this.existing,
    required this.allSteps,
    required this.nextStepOrder,
    required this.onSaved,
  });

  @override
  State<_GuideStepDialog> createState() => _GuideStepDialogState();
}

class _GuideStepDialogState extends State<_GuideStepDialog> {
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
      final currentOrder = (e!['step_order'] as int?) ?? 1;
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
      final fileName = 'guide-${DateTime.now().millisecondsSinceEpoch}.$safeExt';
      final filePath = 'login-guide/$fileName';
      final String contentType = safeExt == 'png'
          ? 'image/png'
          : safeExt == 'gif'
              ? 'image/gif'
              : safeExt == 'webp'
                  ? 'image/webp'
                  : 'image/jpeg';

      await _supabase.storage.from('guide-images').uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );
      final newUrl = _supabase.storage.from('guide-images').getPublicUrl(filePath);
      if (mounted) {
        setState(() {
          _imageUrl = newUrl;
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      debugPrint('Error uploading guide image: $e');
      if (mounted) setState(() => _isUploadingImage = false);
    }
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.7),
                    child: _previewBytes != null
                        ? Image.memory(_previewBytes!, fit: BoxFit.cover)
                        : Image.network(_imageUrl!, fit: BoxFit.cover),
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
      missing.add(MissingFieldItem(icon: Icons.image_rounded, label: _t('Step Image', 'Gambar Langkah', '步骤图片')));
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
        builder: (_) => _GuideTranslatingDialog(color: _C.primary, lang: widget.lang),
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
      debugPrint('Guide step translate error: $e');
    }

    final data = <String, dynamic>{
      'guide_type': widget.guideType,
      'image_url': _imageUrl,
      'title_id': titleAll['id'],
      'title_en': titleAll['en'],
      'title_zh': titleAll['zh'],
      'description_id': descAll['id'],
      'description_en': descAll['en'],
      'description_zh': descAll['zh'],
    };

    if (!isEdit) {
      data['step_order'] = widget.nextStepOrder;
    }

    try {
      if (isEdit) {
        final existingId = widget.existing!['id'];
        final currentOrder = (widget.existing!['step_order'] as int?) ?? 1;
        final total = widget.allSteps.length;
        final parsed = int.tryParse(_orderCtrl?.text.trim() ?? '');
        if (parsed != null) {
          final desiredOrder = parsed.clamp(1, total == 0 ? 1 : total);
          if (desiredOrder != currentOrder) {
            final occupantIndex = widget.allSteps.indexWhere(
                (s) => s['id'] != existingId && (s['step_order'] as int?) == desiredOrder);
            if (occupantIndex != -1) {
              await _supabase
                  .from('app_guides')
                  .update({'step_order': currentOrder})
                  .eq('id', widget.allSteps[occupantIndex]['id']);
            }
            data['step_order'] = desiredOrder;
          }
        }
        await _supabase.from('app_guides').update(data).eq('id', existingId);
      } else {
        await _supabase.from('app_guides').insert(data);
      }

      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      debugPrint('Save guide step error: $e');
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
                  Icon(Icons.menu_book_rounded, size: 18, color: _C.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEdit ? _t('Edit Step', 'Ubah Langkah', '编辑步骤') : _t('Add New Step', 'Tambah Langkah Baru', '添加新步骤'),
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
                    _fieldLabel(Icons.image_rounded, _t('Step Image', 'Gambar Langkah', '步骤图片')),
                    const SizedBox(height: 8),
                    _buildImagePicker(),
                    const SizedBox(height: 18),
                    _fieldLabel(Icons.short_text_rounded, _t('Title', 'Judul', '标题')),
                    const SizedBox(height: 6),
                    _buildTextField(_titleCtrl,
                        isTitleField: true,
                        hint: _t('e.g. Enter Email Address', 'cth. Isi Alamat Email', '例如：输入电子邮件地址')),
                    const SizedBox(height: 16),
                    _fieldLabel(Icons.notes_rounded, _t('Description', 'Deskripsi', '描述')),
                    const SizedBox(height: 6),
                    _buildTextField(_descCtrl,
                        maxLines: 4, hint: _t('Step description...', 'Deskripsi langkah...', '步骤描述...')),
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
                      _fieldLabel(Icons.reorder_rounded, _t('Step Order', 'Urutan Langkah', '步骤顺序'), required: false),
                      const SizedBox(height: 6),
                      _buildTextField(_orderCtrl!,
                          keyboardType: TextInputType.number,
                          hint: _t('e.g. 2', 'cth. 2', '例如：2')),
                      const SizedBox(height: 6),
                      Text(
                        _t(
                          'If this position is already used by another step, they will swap.',
                          'Jika posisi ini sudah digunakan langkah lain, urutannya akan bertukar.',
                          '如果此位置已被其他步骤占用，顺序将互换。',
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

class _GuideTranslatingDialog extends StatefulWidget {
  final Color color;
  final String lang;
  const _GuideTranslatingDialog({required this.color, required this.lang});

  @override
  State<_GuideTranslatingDialog> createState() => _GuideTranslatingDialogState();
}

class _GuideTranslatingDialogState extends State<_GuideTranslatingDialog>
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