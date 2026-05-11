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

class _AuditQuestionManagerScreenState
    extends State<AuditQuestionManagerScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _questions = [];
  bool _loading = true;

  static const _primary = Color(0xFF6366F1);
  static const _primaryLt = Color(0xFFEDE9FE);
  static const _red = Color(0xFFEF4444);
  static const _textMain = Color(0xFF1E3A8A);
  static const _textSub = Color(0xFF64748B);
  static const _divider = Color(0xFFE2E8F0);

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    setState(() => _loading = true);
    try {
      final rows = await _supabase
          .from('audit_question')
          .select()
          .eq('level_type', widget.levelType)
          .eq('id_ref', widget.idRef)
          .order('urutan');
      if (mounted) {
        setState(() {
          _questions = List<Map<String, dynamic>>.from(rows);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showForm({Map<String, dynamic>? existing}) async {
    final ctrl = TextEditingController(
        text: existing?['pertanyaan'] as String? ?? '');
    final activeCtrl = ValueNotifier<bool>(
        existing == null ? true : (existing['is_active'] as bool? ?? true));
    final urutanCtrl = TextEditingController(
        text: existing == null
            ? '${(_questions.length + 1)}'
            : '${existing['urutan']}');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          // ✅ FIX: tambahkan maxHeight agar tidak overflow
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          // ✅ FIX: bungkus dengan SingleChildScrollView
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  existing == null
                      ? _t('Add Question', 'Tambah Pertanyaan', '添加问题')
                      : _t('Edit Question', 'Edit Pertanyaan', '编辑问题'),
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _textMain),
                ),
                const SizedBox(height: 14),
                Text(_t('Question', 'Pertanyaan', '问题'),
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _textSub)),
                const SizedBox(height: 6),
                TextField(
                  controller: ctrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: _t(
                        'Enter question text…',
                        'Masukkan teks pertanyaan…',
                        '输入问题内容…'),
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _divider)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _divider)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: _primary, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_t('Order', 'Urutan', '顺序'),
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _textSub)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: urutanCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _divider)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _divider)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _primary, width: 1.5)),
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
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _textSub)),
                        const SizedBox(height: 6),
                        ValueListenableBuilder<bool>(
                          valueListenable: activeCtrl,
                          builder: (_, v, __) => Switch(
                            value: v,
                            onChanged: (val) => activeCtrl.value = val,
                            activeColor: _primary,
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
                      final text = ctrl.text.trim();
                      if (text.isEmpty) return;
                      final urutan =
                          int.tryParse(urutanCtrl.text.trim()) ??
                              _questions.length + 1;
                      final payload = {
                        'level_type': widget.levelType,
                        'id_ref': widget.idRef,
                        'pertanyaan': text,
                        'urutan': urutan,
                        'is_active': activeCtrl.value,
                      };
                      if (existing == null) {
                        await _supabase
                            .from('audit_question')
                            .insert(payload);
                      } else {
                        await _supabase
                            .from('audit_question')
                            .update(payload)
                            .eq('id_question', existing['id_question']);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      _fetchQuestions();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(_t('Save', 'Simpan', '保存'),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    ctrl.dispose();
    activeCtrl.dispose();
    urutanCtrl.dispose();
  }

  Future<void> _delete(Map<String, dynamic> q) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_t('Delete Question', 'Hapus Pertanyaan', '删除问题'),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
            _t('This cannot be undone.', 'Ini tidak dapat dibatalkan.', '此操作无法撤销。'),
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(_t('Cancel', 'Batal', '取消'),
                  style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: Text(_t('Delete', 'Hapus', '删除'),
                  style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirmed == true) {
      await _supabase
          .from('audit_question')
          .delete()
          .eq('id_question', q['id_question']);
      _fetchQuestions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _textMain, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('Audit Questions', 'Pertanyaan Audit', '审计问题'),
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textMain),
            ),
            Text(
              widget.locationName,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: _textSub),
            ),
          ],
        ),
        actions: const [],
      ),
      body: Column(
        children: [
          // ── Tombol Add Question di atas ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: GestureDetector(
              onTap: () => _showForm(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primary, Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _t('Add Question', 'Tambah Pertanyaan', '添加问题'),
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          Text(
                            _t('Add new audit question', 'Tambahkan pertanyaan baru', '添加新问题'),
                            style: GoogleFonts.poppins(fontSize: 10, color: Colors.white.withOpacity(0.85)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // ── Daftar Pertanyaan ──
          Expanded(
            child: _loading
                ? Shimmer.fromColors(
                    baseColor: Colors.grey.shade200,
                    highlightColor: Colors.grey.shade50,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 6,
                      itemBuilder: (_, __) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
                : _questions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.help_outline_rounded, size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              _t('No questions yet.\nTap + Add to begin.',
                                  'Belum ada pertanyaan.\nKetuk tombol di atas untuk mulai.',
                                  '暂无问题，点击上方按钮开始。'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(fontSize: 13, color: _textSub),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: _questions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final q = _questions[i];
                          final isActive = q['is_active'] as bool? ?? true;
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: isActive ? _primaryLt : Colors.grey.shade200,
                                  width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    color: isActive ? _primary.withOpacity(0.12) : Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text('${q['urutan']}',
                                        style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: isActive ? _primary : Colors.grey)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(q['pertanyaan'] as String? ?? '',
                                          style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: isActive ? _textMain : Colors.grey)),
                                      if (!isActive)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(_t('Inactive', 'Nonaktif', '未激活'),
                                              style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                                        ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18, color: _primary),
                                      onPressed: () => _showForm(existing: q),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: _red),
                                      onPressed: () => _delete(q),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}