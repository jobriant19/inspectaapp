import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'audit_theme_settings.dart';
import 'audit_type_settings.dart';

class AuditQuestionManagerScreen extends StatefulWidget {
  final String lang;

  const AuditQuestionManagerScreen({
    super.key,
    required this.lang,
  });

  @override
  State<AuditQuestionManagerScreen> createState() =>
      _AuditQuestionManagerScreenState();
}

class _C {
  static const primary   = Color(0xFF6366F1);
  static const primaryLt = Color(0xFFEDE9FE);
  static const red       = Color(0xFFEF4444);
  static const textMain  = Color(0xFF1E3A8A);
  static const textSub   = Color(0xFF64748B);
  static const divider   = Color(0xFFE2E8F0);
  static const surface   = Color(0xFFF8FAFC);
}

class _AuditQuestionManagerScreenState
    extends State<AuditQuestionManagerScreen>
    with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _jenisAuditList = [];
  bool _loadingJenis = true;
  TabController? _tabCtrl;

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  String _jenisLabel(Map<String, dynamic> j) {
    if (widget.lang == 'EN') return j['nama_en']?.toString() ?? '-';
    if (widget.lang == 'ZH') return j['nama_zh']?.toString() ?? '-';
    return j['nama_id']?.toString() ?? '-';
  }

  @override
  void initState() {
    super.initState();
    _fetchJenisAudit();
  }

  @override
  void dispose() {
    _tabCtrl?.dispose();
    super.dispose();
  }

  Future<void> _fetchJenisAudit() async {
    final oldCtrl = _tabCtrl;
    final previousId = (oldCtrl != null &&
            _jenisAuditList.isNotEmpty &&
            oldCtrl.index < _jenisAuditList.length)
        ? _jenisAuditList[oldCtrl.index]['id_jenis_audit']?.toString()
        : null;
    try {
      final rows = await _supabase.from('jenis_audit').select().order('urutan');
      final list = List<Map<String, dynamic>>.from(rows);
      if (!mounted) return;

      int newIndex = 0;
      if (previousId != null) {
        final idx = list.indexWhere(
            (j) => j['id_jenis_audit'].toString() == previousId);
        if (idx != -1) newIndex = idx;
      }

      final newCtrl = TabController(
        length: list.length,
        vsync: this,
        initialIndex: list.isEmpty ? 0 : newIndex.clamp(0, list.length - 1),
      );

      setState(() {
        _jenisAuditList = list;
        _tabCtrl = newCtrl;
        _loadingJenis = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        oldCtrl?.dispose();
      });
    } catch (e) {
      debugPrint('Error fetch jenis_audit: $e');
      if (mounted) setState(() => _loadingJenis = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _C.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('Audit Questions', 'Pertanyaan Audit', '审计问题'),
          style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _C.primary),
        ),
      ),
      body: Column(
        children: [
          // ── Pengaturan Jenis Audit button ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AuditTypeSettingsScreen(
                      lang: widget.lang,
                      initialList: _jenisAuditList,
                      onChanged: _fetchJenisAudit,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _C.primary,
                      _C.primary.withValues(alpha: 0.78)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: _C.primary.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.tune_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _t('Audit Type Settings',
                              'Pengaturan Jenis Audit', '审计类型设置'),
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        Text(
                          _t(
                            'Manage, add, edit or delete audit types',
                            'Kelola, tambah, edit atau hapus jenis audit',
                            '管理、添加、编辑或删除审计类型',
                          ),
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.82)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white, size: 13),
                ]),
              ),
            ),
          ),

          // ── TabBar jenis audit ──
          if (!_loadingJenis && _tabCtrl != null)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(3),
                child: TabBar(
                  controller: _tabCtrl,
                  indicator: BoxDecoration(
                    color: _C.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: _C.primary,
                  dividerColor: Colors.transparent,
                  overlayColor:
                      WidgetStateProperty.all(Colors.transparent),
                  isScrollable: _jenisAuditList.length > 4,
                  tabAlignment: _jenisAuditList.length > 4
                      ? TabAlignment.start
                      : TabAlignment.fill,
                  labelPadding: _jenisAuditList.length > 4
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(horizontal: 4),
                  tabs: _jenisAuditList.map((j) {
                    final label = _jenisLabel(j);
                    final words = label.trim().split(RegExp(r'\s+'));
                    final isOneWord = words.length == 1;
                    final displayText =
                        isOneWord ? label : words.join('\n');
                    final screenWidth =
                        MediaQuery.of(context).size.width;
                    final tabWidth = _jenisAuditList.length > 4
                        ? (screenWidth - 32 - 6) / 4
                        : null;
                    final content = FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        displayText,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    );
                    return Tab(
                      height: 48,
                      child: tabWidth != null
                          ? SizedBox(width: tabWidth, child: content)
                          : content,
                    );
                  }).toList(),
                ),
              ),
            )
          else if (_loadingJenis)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                  child: CircularProgressIndicator(
                      color: _C.primary, strokeWidth: 2)),
            ),

          // ── TabBarView ──
          if (!_loadingJenis && _tabCtrl != null)
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: _jenisAuditList
                    .map((j) => _QuestionTabView(
                          key: ValueKey(j['id_jenis_audit'].toString()),
                          lang: widget.lang,
                          idJenisAudit:
                              j['id_jenis_audit'].toString(),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab view per jenis audit — tanpa level_type & id_ref
// ─────────────────────────────────────────────────────────────────────────────
class _QuestionTabView extends StatefulWidget {
  final String lang;
  final String idJenisAudit;

  const _QuestionTabView({
    super.key,
    required this.lang,
    required this.idJenisAudit,
  });

  @override
  State<_QuestionTabView> createState() => _QuestionTabViewState();
}

class _QuestionTabViewState extends State<_QuestionTabView>
    with AutomaticKeepAliveClientMixin {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _temas     = [];
  List<Map<String, dynamic>> _questions = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  String _temaLabel(Map<String, dynamic> t) {
    if (widget.lang == 'EN') return t['nama_tema_en']?.toString() ?? '-';
    if (widget.lang == 'ZH') return t['nama_tema_zh']?.toString() ?? '-';
    return t['nama_tema_id']?.toString() ?? '-';
  }

  String _questionText(Map<String, dynamic> q) {
    if (widget.lang == 'EN') {
      return q['pertanyaan_en']?.toString() ??
          q['pertanyaan']?.toString() ?? '';
    }
    if (widget.lang == 'ZH') {
      return q['pertanyaan_zh']?.toString() ??
          q['pertanyaan']?.toString() ?? '';
    }
    return q['pertanyaan']?.toString() ?? '';
  }

  Future<String> _translateText(String text, String langPair) async {
    if (text.trim().isEmpty) return text;
    try {
      final normalized = langPair
          .replaceAll('|zh', '|zh-CN')
          .replaceAll('zh|', 'zh-CN|');
      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get'
        '?q=${Uri.encodeComponent(text)}&langpair=$normalized',
      );
      final res =
          await http.get(uri).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final t =
            data['responseData']?['translatedText']?.toString() ?? '';
        if (t.isEmpty ||
            t.toUpperCase().startsWith('MYMEMORY WARNING') ||
            t.toUpperCase().startsWith('PLEASE')) { return text; }
        return t;
      }
      return text;
    } catch (_) {
      return text;
    }
  }

  Future<Map<String, String>> _translateAll(String text) async {
    final results = await Future.wait([
      _translateText(text, 'id|en'),
      _translateText(text, 'id|zh'),
    ]);
    return {'id': text, 'en': results[0], 'zh': results[1]};
  }

  void _showSuccessPopup({
    required bool isSuccess,
    required String titleEn,
    required String titleId,
    required String titleZh,
    required String msgEn,
    required String msgId,
    required String msgZh,
  }) {
    if (!mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'success_q',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity:
            CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1.0).animate(
            CurvedAnimation(
                parent: anim, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) {
        final color = isSuccess
            ? const Color(0xFF16A34A)
            : const Color(0xFFDC2626);
        final bgLight = isSuccess
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFFEF2F2);
        final icon = isSuccess
            ? Icons.check_circle_rounded
            : Icons.error_rounded;
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 36),
              padding:
                  const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.22),
                    blurRadius: 32,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: bgLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: color.withValues(alpha: 0.25),
                          width: 2),
                    ),
                    child: Icon(icon, color: color, size: 38),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _t(titleEn, titleId, titleZh),
                    style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: color),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _t(msgEn, msgId, msgZh),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _t('Close', 'Tutup', '关闭'),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
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

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        // Fetch tema sesuai jenis audit
        _supabase
            .from('audit_tema')
            .select()
            .eq('id_jenis_audit', widget.idJenisAudit)
            .order('urutan'),
        // Fetch pertanyaan global — hanya filter id_jenis_audit,
        // TANPA level_type & id_ref
        _supabase
            .from('audit_question')
            .select()
            .eq('id_jenis_audit', widget.idJenisAudit)
            .order('urutan'),
      ]);
      if (mounted) {
        setState(() {
          _temas     = List<Map<String, dynamic>>.from(results[0] as List);
          _questions = List<Map<String, dynamic>>.from(results[1] as List);
          _loading   = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch tab data: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  // ADD / EDIT QUESTION
  Future<void> _showForm({
    Map<String, dynamic>? existing,
    String? defaultTemaId,
  }) async {
    final idCtrl = TextEditingController(
        text: existing?['pertanyaan'] as String? ?? '');
    final activeCtrl = ValueNotifier<bool>(
        existing == null
            ? true
            : (existing['is_active'] as bool? ?? true));
    final urutanCtrl = TextEditingController(
        text: existing == null
            ? '${_questions.length + 1}'
            : '${existing['urutan']}');
    String? selectedTemaId =
        existing?['id_tema']?.toString() ?? defaultTemaId;
    bool isTranslating = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.of(ctx).size.height * 0.88),
            padding:
                const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HANDLE BAR
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius:
                              BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // HEADER
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _C.primaryLt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                          Icons.help_outline_rounded,
                          color: _C.primary,
                          size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            existing == null
                                ? _t('Add Question',
                                    'Tambah Pertanyaan', '添加问题')
                                : _t('Edit Question',
                                    'Edit Pertanyaan', '编辑问题'),
                            style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _C.textMain),
                          ),
                          Text(
                            _t(
                              'Input in Indonesian, auto-translated to EN & ZH.',
                              'Isi dalam bahasa Indonesia, otomatis diterjemahkan ke EN & ZH.',
                              '用印尼语输入，自动翻译为 EN 和 ZH。',
                            ),
                            style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                color: _C.textSub),
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 18),

                  // DROPDOWN THEME
                  Text(_t('Theme', 'Tema', '主题'),
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _C.textSub)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12),
                        decoration: BoxDecoration(
                          color: _C.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _C.divider),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedTemaId,
                            isExpanded: true,
                            hint: Text(
                                _t('Select theme', 'Pilih tema',
                                    '选择主题'),
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.black38)),
                            items: _temas
                                .map((t) =>
                                    DropdownMenuItem<String>(
                                      value: t['id_tema']
                                          .toString(),
                                      child: Text(
                                          _temaLabel(t),
                                          style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color:
                                                  _C.textMain)),
                                    ))
                                .toList(),
                            onChanged: (v) => setSheet(
                                () => selectedTemaId = v),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AuditThemeSettingsScreen(
                              lang: widget.lang,
                              idJenisAudit:
                                  widget.idJenisAudit,
                              onChanged: _fetchAll,
                            ),
                          ),
                        );
                        setSheet(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _C.primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _C.primary
                                  .withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: _C.primary, size: 18),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // QUESTION
                  Text(
                    _t(
                        'Question (Indonesian)',
                        'Pertanyaan (Indonesia)',
                        '问题（印尼语）'),
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _C.textSub),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.divider),
                    ),
                    child: TextField(
                      controller: idCtrl,
                      maxLines: 3,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: _C.textMain),
                      decoration: InputDecoration(
                        hintText: _t(
                          'Enter question in Indonesian...',
                          'Masukkan pertanyaan dalam Bahasa Indonesia...',
                          '请用印尼语输入问题...',
                        ),
                        hintStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade400),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ORDER & ACTIVE
                  Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(_t('Order', 'Urutan', '顺序'),
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _C.textSub)),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: _C.surface,
                              borderRadius:
                                  BorderRadius.circular(12),
                              border:
                                  Border.all(color: _C.divider),
                            ),
                            child: TextField(
                              controller: urutanCtrl,
                              keyboardType:
                                  TextInputType.number,
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: _C.textMain),
                              decoration:
                                  const InputDecoration(
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(_t('Active', 'Aktif', '活跃'),
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _C.textSub)),
                        const SizedBox(height: 6),
                        ValueListenableBuilder<bool>(
                          valueListenable: activeCtrl,
                          builder: (_, v, __) => Switch(
                            value: v,
                            onChanged: (val) =>
                                activeCtrl.value = val,
                            activeColor: _C.primary,
                          ),
                        ),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 22),

                  // SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isTranslating
                          ? null
                          : () async {
                              final text =
                                  idCtrl.text.trim();
                              if (text.isEmpty ||
                                  selectedTemaId == null) {
                                return;
                              }
                              setSheet(() => isTranslating = true);
                              try {
                                final isDup = _questions.any((q) =>
                                    q['id_tema']?.toString() == selectedTemaId &&
                                    (q['pertanyaan']?.toString().trim().toLowerCase() ?? '') ==
                                        text.toLowerCase() &&
                                    (existing == null ||
                                        q['id_question'] != existing['id_question']));
                                if (isDup) {
                                  setSheet(() => isTranslating = false);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  _showSuccessPopup(
                                    isSuccess: false,
                                    titleEn: 'Duplicate Question',
                                    titleId: 'Pertanyaan Duplikat',
                                    titleZh: '问题重复',
                                    msgEn: 'This question already exists in this theme.',
                                    msgId: 'Pertanyaan ini sudah ada pada tema ini.',
                                    msgZh: '该主题中已存在此问题。',
                                  );
                                  return;
                                }
                                final t = await _translateAll(text);
                                final urutan = int.tryParse(
                                        urutanCtrl.text
                                            .trim()) ??
                                    _questions.length + 1;

                                // ── Payload tanpa level_type & id_ref ──
                                final payload = {
                                  'id_jenis_audit':
                                      widget.idJenisAudit,
                                  'id_tema': selectedTemaId,
                                  'pertanyaan':    t['id'],
                                  'pertanyaan_en': t['en'],
                                  'pertanyaan_zh': t['zh'],
                                  'urutan':    urutan,
                                  'is_active': activeCtrl.value,
                                };
                                final isAdd = existing == null;
                                if (isAdd) {
                                  await _supabase
                                      .from('audit_question')
                                      .insert(payload);
                                } else {
                                  await _supabase
                                      .from('audit_question')
                                      .update(payload)
                                      .eq('id_question',
                                          existing['id_question']);
                                }
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                _fetchAll();
                                _showSuccessPopup(
                                  isSuccess: true,
                                  titleEn: isAdd
                                      ? 'Question Added!'
                                      : 'Question Updated!',
                                  titleId: isAdd
                                      ? 'Pertanyaan Ditambahkan!'
                                      : 'Pertanyaan Diperbarui!',
                                  titleZh: isAdd
                                      ? '问题已添加！'
                                      : '问题已更新！',
                                  msgEn: isAdd
                                      ? 'New question has been saved successfully.'
                                      : 'Question has been updated successfully.',
                                  msgId: isAdd
                                      ? 'Pertanyaan baru berhasil disimpan.'
                                      : 'Pertanyaan berhasil diperbarui.',
                                  msgZh: isAdd
                                      ? '新问题已成功保存。'
                                      : '问题已成功更新。',
                                );
                              } catch (e) {
                                debugPrint(
                                    'Error save question: $e');
                                if (ctx.mounted) {
                                  setSheet(() =>
                                      isTranslating = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                      ),
                      child: isTranslating
                          ? Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _t(
                                      'Translating & Saving...',
                                      'Menerjemahkan & Menyimpan...',
                                      '翻译并保存中...'),
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.w600,
                                      color: Colors.white),
                                ),
                              ],
                            )
                          : Text(
                              _t('Save', 'Simpan', '保存'),
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
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

  Future<void> _delete(Map<String, dynamic> q) async {
    final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (_) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEB),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _C.red.withValues(alpha: 0.25), width: 2),
                    ),
                    child: const Icon(Icons.delete_forever_rounded,
                        color: _C.red, size: 34),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _t('Delete Question?', 'Hapus Pertanyaan?', '删除问题？'),
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _C.textMain),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _t(
                      'This action cannot be undone.',
                      'Tindakan ini tidak dapat dibatalkan.',
                      '此操作无法撤销。',
                    ),
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: _C.textSub, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.delete_forever_rounded,
                          color: Colors.white, size: 16),
                      label: Text(
                        _t('Delete', 'Hapus', '删除'),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.red,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _C.divider),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _t('Cancel', 'Batal', '取消'),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _C.textSub),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;

    if (confirmed) {
      await _supabase
          .from('audit_question')
          .delete()
          .eq('id_question', q['id_question']);
      _fetchAll();
      _showSuccessPopup(
        isSuccess: true,
        titleEn: 'Deleted!',
        titleId: 'Dihapus!',
        titleZh: '已删除！',
        msgEn: 'Question has been deleted successfully.',
        msgId: 'Pertanyaan berhasil dihapus.',
        msgZh: '问题已成功删除。',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade50,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          itemBuilder: (_, __) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 64,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    // GROUP QUESTIONS BY THEME
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    final List<Map<String, dynamic>> noTema = [];
    for (final q in _questions) {
      final temaId = q['id_tema']?.toString();
      if (temaId == null) {
        noTema.add(q);
      } else {
        grouped.putIfAbsent(temaId, () => []).add(q);
      }
    }

    return RefreshIndicator(
      onRefresh: _fetchAll,
      color: _C.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // THEME SETTINGS BUTTON
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AuditThemeSettingsScreen(
                    lang: widget.lang,
                    idJenisAudit: widget.idJenisAudit,
                    onChanged: _fetchAll,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _C.primaryLt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _C.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.tune_rounded,
                      color: _C.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                      _t('Theme Settings', 'Pengaturan Tema',
                          '主题设置'),
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _C.primary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          if (_temas.isEmpty && noTema.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: [
                  Icon(Icons.help_outline_rounded,
                      size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                      _t(
                          'No themes yet. Add a theme first.',
                          'Belum ada tema. Tambahkan tema terlebih dahulu.',
                          '暂无主题，请先添加主题。'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: _C.textSub)),
                ],
              ),
            ),

          // THEME SECTIONS
          ..._temas.map((tema) {
            final temaId = tema['id_tema'].toString();
            final qs = grouped[temaId] ?? [];
            return _buildTemaSection(
                _temaLabel(tema), temaId, qs);
          }),

          // NO THEME
          if (noTema.isNotEmpty)
            _buildTemaSection(
                _t('Other', 'Lainnya', '其他'), null, noTema),
        ],
      ),
    );
  }

  Widget _buildTemaSection(
      String title,
      String? temaId,
      List<Map<String, dynamic>> qs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _C.textMain)),
                ),
                GestureDetector(
                  onTap: () =>
                      _showForm(defaultTemaId: temaId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _C.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color:
                              _C.primary.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded,
                              size: 13, color: _C.primary),
                          const SizedBox(width: 3),
                          Text(
                              _t('Add', 'Tambah', '添加'),
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _C.primary)),
                        ]),
                  ),
                ),
              ],
            ),
          ),
          if (qs.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(
                  _t('No questions yet',
                      'Belum ada pertanyaan', '暂无问题'),
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey)),
            )
          else
            ...qs.map((q) {
              final isActive =
                  q['is_active'] as bool? ?? true;
              return Container(
                margin: const EdgeInsets.fromLTRB(
                    14, 0, 14, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isActive
                          ? _C.primaryLt
                          : Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isActive
                            ? _C.primary.withValues(alpha: 0.12)
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${q['urutan']}',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isActive
                                    ? _C.primary
                                    : Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(_questionText(q),
                              style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: isActive
                                      ? _C.textMain
                                      : Colors.grey)),
                          if (!isActive)
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 2),
                              child: Text(
                                  _t('Inactive', 'Nonaktif',
                                      '未激活'),
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey)),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 16, color: _C.primary),
                      onPressed: () =>
                          _showForm(existing: q),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 16, color: _C.red),
                      onPressed: () => _delete(q),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}