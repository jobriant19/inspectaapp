import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuditQuestionManagerScreen extends StatefulWidget {
  final String lang;
  final String levelType;   // 'lokasi' | 'unit' | 'subunit' | 'area'
  final String idRef;
  final String locationName;

  const AuditQuestionManagerScreen({
    super.key,
    required this.lang,
    required this.levelType,
    required this.idRef,
    required this.locationName,
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
    extends State<AuditQuestionManagerScreen> with SingleTickerProviderStateMixin {
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
    try {
      final rows = await _supabase.from('jenis_audit').select().order('urutan');
      final list = List<Map<String, dynamic>>.from(rows);
      if (mounted) {
        setState(() {
          _jenisAuditList = list;
          _tabCtrl = TabController(length: list.length, vsync: this);
          _loadingJenis = false;
        });
      }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _C.textMain, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('Audit Questions', 'Pertanyaan Audit', '审计问题'),
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _C.textMain),
            ),
            Text(
              widget.locationName,
              style: GoogleFonts.poppins(fontSize: 11, color: _C.textSub),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        bottom: _loadingJenis || _tabCtrl == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(46),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                      labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 11),
                      unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11),
                      dividerColor: Colors.transparent,
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: _jenisAuditList
                          .map((j) => Tab(child: Text(_jenisLabel(j))))
                          .toList(),
                    ),
                  ),
                ),
              ),
      ),
      body: _loadingJenis || _tabCtrl == null
          ? const Center(child: CircularProgressIndicator(color: _C.primary))
          : TabBarView(
              controller: _tabCtrl,
              children: _jenisAuditList.map((j) => _QuestionTabView(
                    lang: widget.lang,
                    levelType: widget.levelType,
                    idRef: widget.idRef,
                    idJenisAudit: j['id_jenis_audit'].toString(),
                  )).toList(),
            ),
    );
  }
}

// ============================================================
// TAB VIEW per Jenis Audit
// ============================================================
class _QuestionTabView extends StatefulWidget {
  final String lang;
  final String levelType;
  final String idRef;
  final String idJenisAudit;

  const _QuestionTabView({
    required this.lang,
    required this.levelType,
    required this.idRef,
    required this.idJenisAudit,
  });

  @override
  State<_QuestionTabView> createState() => _QuestionTabViewState();
}

class _QuestionTabViewState extends State<_QuestionTabView>
    with AutomaticKeepAliveClientMixin {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _temas = [];
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
    if (widget.lang == 'EN') return q['pertanyaan_en']?.toString() ?? q['pertanyaan']?.toString() ?? '';
    if (widget.lang == 'ZH') return q['pertanyaan_zh']?.toString() ?? q['pertanyaan']?.toString() ?? '';
    return q['pertanyaan']?.toString() ?? '';
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
            .eq('level_type', widget.levelType)
            .eq('id_ref', widget.idRef)
            .eq('id_jenis_audit', widget.idJenisAudit)
            .order('urutan'),
      ]);
      if (mounted) {
        setState(() {
          _temas = List<Map<String, dynamic>>.from(results[0] as List);
          _questions = List<Map<String, dynamic>>.from(results[1] as List);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch tab data: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Tambah Tema Baru ──────────────────────────────────────
  Future<void> _showAddTemaDialog() async {
    final idCtrl = TextEditingController();
    final enCtrl = TextEditingController();
    final zhCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(_t('Add Theme', 'Tambah Tema', '添加主题'),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _langField(idCtrl, _t('Theme name (Indonesian)', 'Nama Tema (Indonesia)', '主题名称（印尼语）')),
            const SizedBox(height: 10),
            _langField(enCtrl, _t('Theme name (English)', 'Nama Tema (English)', '主题名称（英语）')),
            const SizedBox(height: 10),
            _langField(zhCtrl, _t('Theme name (Chinese)', 'Nama Tema (Mandarin)', '主题名称（中文）')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_t('Cancel', 'Batal', '取消'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (idCtrl.text.trim().isEmpty) return;
              await _supabase.from('audit_tema').insert({
                'id_jenis_audit': widget.idJenisAudit,
                'nama_tema_id': idCtrl.text.trim(),
                'nama_tema_en': enCtrl.text.trim().isEmpty ? idCtrl.text.trim() : enCtrl.text.trim(),
                'nama_tema_zh': zhCtrl.text.trim().isEmpty ? idCtrl.text.trim() : zhCtrl.text.trim(),
                'urutan': _temas.length + 1,
              });
              if (ctx.mounted) Navigator.pop(ctx);
              _fetchAll();
            },
            child: Text(_t('Save', 'Simpan', '保存'),
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _langField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 12),
        filled: true,
        fillColor: _C.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _C.divider)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  // ── Tambah / Edit Pertanyaan ────────────────────────────────
  Future<void> _showForm({Map<String, dynamic>? existing, String? defaultTemaId}) async {
    final idCtrl = TextEditingController(text: existing?['pertanyaan'] as String? ?? '');
    final enCtrl = TextEditingController(text: existing?['pertanyaan_en'] as String? ?? '');
    final zhCtrl = TextEditingController(text: existing?['pertanyaan_zh'] as String? ?? '');
    final activeCtrl = ValueNotifier<bool>(
        existing == null ? true : (existing['is_active'] as bool? ?? true));
    final urutanCtrl = TextEditingController(
        text: existing == null ? '${_questions.length + 1}' : '${existing['urutan']}');
    String? selectedTemaId = existing?['id_tema']?.toString() ?? defaultTemaId;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.9),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    existing == null
                        ? _t('Add Question', 'Tambah Pertanyaan', '添加问题')
                        : _t('Edit Question', 'Edit Pertanyaan', '编辑问题'),
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _C.textMain),
                  ),
                  const SizedBox(height: 14),

                  // ── Tema dropdown ──
                  Text(_t('Theme', 'Tema', '主题'),
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _C.textSub)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: _C.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _C.divider),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedTemaId,
                              isExpanded: true,
                              hint: Text(_t('Select theme', 'Pilih tema', '选择主题'),
                                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.black38)),
                              items: _temas.map((t) => DropdownMenuItem<String>(
                                    value: t['id_tema'].toString(),
                                    child: Text(_temaLabel(t),
                                        style: GoogleFonts.poppins(fontSize: 13, color: _C.textMain)),
                                  )).toList(),
                              onChanged: (v) => setSheet(() => selectedTemaId = v),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          await _showAddTemaDialog();
                          setSheet(() {}); // refresh dropdown list after add
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _C.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _C.primary.withOpacity(0.4)),
                          ),
                          child: const Icon(Icons.add_rounded, color: _C.primary, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Pertanyaan 3 bahasa ──
                  _qField(idCtrl, _t('Question (Indonesian)', 'Pertanyaan (Indonesia)', '问题（印尼语）')),
                  const SizedBox(height: 10),
                  _qField(enCtrl, _t('Question (English)', 'Pertanyaan (English)', '问题（英语）')),
                  const SizedBox(height: 10),
                  _qField(zhCtrl, _t('Question (Chinese)', 'Pertanyaan (Mandarin)', '问题（中文）')),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_t('Order', 'Urutan', '顺序'),
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _C.textSub)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: urutanCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: _C.surface,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: _C.divider)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_t('Active', 'Aktif', '活跃'),
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _C.textSub)),
                          const SizedBox(height: 6),
                          ValueListenableBuilder<bool>(
                            valueListenable: activeCtrl,
                            builder: (_, v, __) => Switch(
                              value: v,
                              onChanged: (val) => activeCtrl.value = val,
                              activeColor: _C.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final text = idCtrl.text.trim();
                        if (text.isEmpty || selectedTemaId == null) return;
                        final urutan = int.tryParse(urutanCtrl.text.trim()) ?? _questions.length + 1;
                        final payload = {
                          'level_type': widget.levelType,
                          'id_ref': widget.idRef,
                          'id_jenis_audit': widget.idJenisAudit,
                          'id_tema': selectedTemaId,
                          'pertanyaan': text,
                          'pertanyaan_en': enCtrl.text.trim().isEmpty ? null : enCtrl.text.trim(),
                          'pertanyaan_zh': zhCtrl.text.trim().isEmpty ? null : zhCtrl.text.trim(),
                          'urutan': urutan,
                          'is_active': activeCtrl.value,
                        };
                        if (existing == null) {
                          await _supabase.from('audit_question').insert(payload);
                        } else {
                          await _supabase
                              .from('audit_question')
                              .update(payload)
                              .eq('id_question', existing['id_question']);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        _fetchAll();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(_t('Save', 'Simpan', '保存'),
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
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

  Widget _qField(TextEditingController ctrl, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _C.textSub)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: label,
            hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            filled: true,
            fillColor: _C.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _C.divider)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Future<void> _delete(Map<String, dynamic> q) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_t('Delete Question', 'Hapus Pertanyaan', '删除问题'),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(_t('This cannot be undone.', 'Ini tidak dapat dibatalkan.', '此操作无法撤销。'),
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text(_t('Cancel', 'Batal', '取消'), style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: _C.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text(_t('Delete', 'Hapus', '删除'), style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirmed == true) {
      await _supabase.from('audit_question').delete().eq('id_question', q['id_question']);
      _fetchAll();
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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    // group questions by tema
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
          // ── Add theme button ──
          GestureDetector(
            onTap: _showAddTemaDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _C.primaryLt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline_rounded, color: _C.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(_t('Add Theme', 'Tambah Tema', '添加主题'),
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _C.primary)),
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
                  Icon(Icons.help_outline_rounded, size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(_t('No themes yet. Add a theme first.',
                      'Belum ada tema. Tambahkan tema terlebih dahulu.', '暂无主题，请先添加主题。'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 13, color: _C.textSub)),
                ],
              ),
            ),

          // ── Tema sections ──
          ..._temas.map((tema) {
            final temaId = tema['id_tema'].toString();
            final qs = grouped[temaId] ?? [];
            return _buildTemaSection(_temaLabel(tema), temaId, qs);
          }),

          // ── No theme group ──
          if (noTema.isNotEmpty)
            _buildTemaSection(_t('Other', 'Lainnya', '其他'), null, noTema),
        ],
      ),
    );
  }

  Widget _buildTemaSection(String title, String? temaId, List<Map<String, dynamic>> qs) {
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
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _C.textMain)),
                ),
                GestureDetector(
                  onTap: () => _showForm(defaultTemaId: temaId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _C.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _C.primary.withOpacity(0.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.add_rounded, size: 13, color: _C.primary),
                      const SizedBox(width: 3),
                      Text(_t('Add', 'Tambah', '添加'),
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: _C.primary)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          if (qs.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(_t('No questions yet', 'Belum ada pertanyaan', '暂无问题'),
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            )
          else
            ...qs.map((q) {
              final isActive = q['is_active'] as bool? ?? true;
              return Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isActive ? _C.primaryLt : Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: isActive ? _C.primary.withOpacity(0.12) : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${q['urutan']}',
                            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800,
                                color: isActive ? _C.primary : Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_questionText(q),
                              style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w500,
                                  color: isActive ? _C.textMain : Colors.grey)),
                          if (!isActive)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(_t('Inactive', 'Nonaktif', '未激活'),
                                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 16, color: _C.primary),
                      onPressed: () => _showForm(existing: q),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 16, color: _C.red),
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