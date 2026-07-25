import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../audit_bottom_indicator.dart';
import 'audit_question_detail.dart';
import 'audit_question_form.dart';
import '../theme/audit_theme_settings.dart';
import '../type/audit_type_settings.dart';

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
          // AUDIT TYPE SETTINGS
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
                    child: const Icon(Icons.fact_check_outlined,
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
                              fontWeight: FontWeight.w600,
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

          // AUDIT TYPE TABBAR
          if (_loadingJenis)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade200,
                highlightColor: Colors.grey.shade50,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            )
          else if (_tabCtrl != null)
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
            ),

          // TAB BAR
          if (_loadingJenis)
            Expanded(
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade200,
                highlightColor: Colors.grey.shade50,
                child: _buildTabContentShimmer(),
              ),
            )
          else if (_tabCtrl != null)
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

  Widget _buildTabContentShimmer() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // THEME SETTINGS BUTTON placeholder
        Container(
          height: 40,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        // SECTION CARD placeholder
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 14,
                width: 130,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              ...List.generate(
                3,
                (i) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

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

  int _temaPage = 1;
  final Map<String, int> _questionPage = {};
  static const int _temasPerPage = 4;
  static const int _questionsPerPage = 5;

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
        _supabase
            .from('audit_tema')
            .select()
            .eq('id_jenis_audit', widget.idJenisAudit)
            .order('urutan'),
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // THEME SETTINGS BUTTON placeholder
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            // SECTION CARD placeholder
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 130,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  ...List.generate(
                    3,
                    (i) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

    final List<String> sectionKeys = [
      for (final tema in _temas) tema['id_tema'].toString(),
      if (noTema.isNotEmpty) '__notema__',
    ];

    final int totalTemaPages = sectionKeys.isEmpty
        ? 1
        : (sectionKeys.length / _temasPerPage).ceil();
    if (_temaPage > totalTemaPages) _temaPage = totalTemaPages;
    if (_temaPage < 1) _temaPage = 1;

    final int temaStart = (_temaPage - 1) * _temasPerPage;
    final int temaEnd =
        (temaStart + _temasPerPage).clamp(0, sectionKeys.length);
    final List<String> visibleKeys =
        sectionKeys.isEmpty ? [] : sectionKeys.sublist(temaStart, temaEnd);

    final List<Widget> sectionWidgets = [];
    for (final key in visibleKeys) {
      if (key == '__notema__') {
        sectionWidgets.add(
          _buildTemaSection(_t('Other', 'Lainnya', '其他'), null, noTema),
        );
      } else {
        final tema = _temas.firstWhere((t) => t['id_tema'].toString() == key);
        final qs = List<Map<String, dynamic>>.from(grouped[key] ?? []);
        qs.sort((a, b) => ((a['urutan'] as num?) ?? 0)
            .compareTo((b['urutan'] as num?) ?? 0));
        sectionWidgets.add(_buildTemaSection(_temaLabel(tema), key, qs));
      }
    }

    return Column(
      children: [
        // THEME SETTINGS BUTTON
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: GestureDetector(
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
                color: const Color(0xFF1D72F3).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF1D72F3).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.topic_rounded,
                      color: Color(0xFF1D72F3), size: 16),
                  const SizedBox(width: 6),
                  Text(
                      _t('Theme Settings', 'Pengaturan Tema',
                          '主题设置'),
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1D72F3))),
                ],
              ),
            ),
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchAll,
            color: _C.primary,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
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
                ...sectionWidgets,
              ],
            ),
          ),
        ),

        // BOTTOM INDICATOR
        if (sectionKeys.length > _temasPerPage)
          AuditBottomIndicator(
            currentPage: _temaPage,
            totalPages: totalTemaPages,
            onPageChanged: (p) => setState(() => _temaPage = p),
          ),
      ],
    );
  }

  Widget _buildTemaSection(
    String title,
    String? temaId,
    List<Map<String, dynamic>> qs) {

    final String pageKey = temaId ?? '__notema__';
    final int totalQPages =
        qs.isEmpty ? 1 : (qs.length / _questionsPerPage).ceil();
    int qPage = _questionPage[pageKey] ?? 1;
    if (qPage > totalQPages) qPage = totalQPages;
    if (qPage < 1) qPage = 1;
    _questionPage[pageKey] = qPage;

    final int qStart = (qPage - 1) * _questionsPerPage;
    final int qEnd = (qStart + _questionsPerPage).clamp(0, qs.length);
    final List<Map<String, dynamic>> pagedQs =
        qs.isEmpty ? [] : qs.sublist(qStart, qEnd);

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
                          color: const Color(0xFF1D72F3))),
                ),
                GestureDetector(
                  onTap: () => showAuditQuestionForm(
                    context,
                    lang: widget.lang,
                    idJenisAudit: widget.idJenisAudit,
                    temas: _temas,
                    questions: _questions,
                    defaultTemaId: temaId,
                    onSaved: _fetchAll,
                    onThemeChanged: _fetchAll,
                  ),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _C.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: _C.primary.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded,
                              size: 13, color: _C.primary),
                          const SizedBox(width: 3),
                          Text(_t('Add', 'Tambah', '添加'),
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
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(
                  _t('No questions yet', 'Belum ada pertanyaan', '暂无问题'),
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            )
          else
            ...pagedQs.asMap().entries.map((entry) {
              final q = entry.value;
              final isActive = q['is_active'] as bool? ?? true;
              return GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AuditQuestionDetailScreen(
                        lang: widget.lang,
                        question: q,
                        tema: temaId == null
                            ? null
                            : _temas.firstWhere(
                                (t) => t['id_tema'].toString() == temaId,
                                orElse: () => <String, dynamic>{},
                              ),
                        idJenisAudit: widget.idJenisAudit,
                        temas: _temas,
                        questions: _questions,
                        onSaved: _fetchAll,
                        onThemeChanged: _fetchAll,
                        onDeleted: _fetchAll,
                      ),
                    ),
                  );
                },
                child: Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isActive ? _C.primaryLt : Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                color: isActive ? _C.primary : Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_questionText(q),
                              textAlign: TextAlign.left,
                              style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black)),
                          if (!isActive)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                  _t('Inactive', 'Nonaktif', '未激活'),
                                  style: GoogleFonts.poppins(
                                      fontSize: 10, color: Colors.grey)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => showAuditQuestionForm(
                        context,
                        lang: widget.lang,
                        idJenisAudit: widget.idJenisAudit,
                        temas: _temas,
                        questions: _questions,
                        existing: q,
                        onSaved: _fetchAll,
                        onThemeChanged: _fetchAll,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_outlined,
                            size: 15, color: Color(0xFF2563EB)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _delete(q),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: _C.red.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_outline,
                            size: 15, color: _C.red),
                      ),
                    ),
                  ],
                ),
                ),
              );
            }),

          if (qs.length > _questionsPerPage)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: AuditBottomIndicator(
                currentPage: qPage,
                totalPages: totalQPages,
                onPageChanged: (p) =>
                    setState(() => _questionPage[pageKey] = p),
                pinnedAtBottom: false,
              ),
            ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}