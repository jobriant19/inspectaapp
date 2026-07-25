import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'audit_question_form.dart';

class _C {
  static const primary   = Color(0xFF6366F1);
  static const primaryLt = Color(0xFFEDE9FE);
  static const red       = Color(0xFFEF4444);
  static const green     = Color(0xFF16A34A);
  static const textMain  = Color(0xFF1E3A8A);
  static const textSub   = Color(0xFF64748B);
  static const divider   = Color(0xFFE2E8F0);
  static const surface   = Color(0xFFF8FAFC);
}

class AuditQuestionDetailScreen extends StatefulWidget {
  final String lang;
  final Map<String, dynamic> question;
  final Map<String, dynamic>? tema;
  final String idJenisAudit;
  final List<Map<String, dynamic>> temas;
  final List<Map<String, dynamic>> questions;
  final VoidCallback onSaved;
  final VoidCallback onThemeChanged;
  final VoidCallback onDeleted;

  const AuditQuestionDetailScreen({
    super.key,
    required this.lang,
    required this.question,
    required this.tema,
    required this.idJenisAudit,
    required this.temas,
    required this.questions,
    required this.onSaved,
    required this.onThemeChanged,
    required this.onDeleted,
  });

  @override
  State<AuditQuestionDetailScreen> createState() =>
      _AuditQuestionDetailScreenState();
}

class _AuditQuestionDetailScreenState
    extends State<AuditQuestionDetailScreen> {
  final _supabase = Supabase.instance.client;
  late Map<String, dynamic> _question;

  @override
  void initState() {
    super.initState();
    _question = widget.question;
  }

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  String _temaLabel(Map<String, dynamic>? t) {
    if (t == null) return _t('Other', 'Lainnya', '其他');
    if (widget.lang == 'EN') return t['nama_tema_en']?.toString() ?? '-';
    if (widget.lang == 'ZH') return t['nama_tema_zh']?.toString() ?? '-';
    return t['nama_tema_id']?.toString() ?? '-';
  }

  Future<void> _delete() async {
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

    if (!confirmed) return;

    try {
      await _supabase
          .from('audit_question')
          .delete()
          .eq('id_question', _question['id_question']);

      widget.onDeleted();

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error delete question: $e');
    }
  }

  Future<void> _edit() async {
    await showAuditQuestionForm(
      context,
      lang: widget.lang,
      idJenisAudit: widget.idJenisAudit,
      temas: widget.temas,
      questions: widget.questions,
      existing: _question,
      onSaved: () {
        widget.onSaved();
      },
      onThemeChanged: widget.onThemeChanged,
    );

    if (!mounted) return;
    final updated = widget.questions.firstWhere(
      (q) => q['id_question'] == _question['id_question'],
      orElse: () => _question,
    );
    setState(() => _question = updated);
  }

  Widget _sectionLabel(IconData icon, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _C.primaryLt,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: _C.primary),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
              fontSize: 12.5, fontWeight: FontWeight.w700, color: _C.primary),
        ),
      ],
    );
  }

  Widget _valueCard(String value, {TextStyle? style}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.divider),
      ),
      child: Text(
        value,
        style: style ??
            GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: _C.textMain,
                height: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _question['is_active'] as bool? ?? true;
    final urutan = _question['urutan']?.toString() ?? '-';

    final qId = _question['pertanyaan']?.toString().trim();
    final qEn = _question['pertanyaan_en']?.toString().trim();
    final qZh = _question['pertanyaan_zh']?.toString().trim();

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
          _t('Question Detail', 'Detail Pertanyaan', '问题详情'),
          style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w700, color: _C.primary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // THEME
          _sectionLabel(Icons.topic_rounded, _t('Theme', 'Tema', '主题')),
          _valueCard(_temaLabel(widget.tema)),
          const SizedBox(height: 18),

          // ORDER
          _sectionLabel(Icons.sort_rounded, _t('Order', 'Urutan', '顺序')),
          _valueCard(urutan),
          const SizedBox(height: 18),

          // ACTIVE STATUS
          _sectionLabel(Icons.toggle_on_rounded,
              _t('Status', 'Status', '状态')),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isActive
                      ? _C.green.withValues(alpha: 0.35)
                      : _C.divider),
            ),
            child: Row(
              children: [
                Icon(
                  isActive
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 16,
                  color: isActive ? _C.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  isActive ? _t('Active', 'Aktif', '活跃') : _t(
                      'Inactive', 'Nonaktif', '未激活'),
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isActive ? _C.green : Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // QUESTION - INDONESIA
          _sectionLabel(Icons.edit_note_rounded,
              _t('Question (Indonesian)', 'Pertanyaan (Indonesia)', '问题（印尼语）')),
          _valueCard(
              (qId == null || qId.isEmpty) ? '-' : qId),
          const SizedBox(height: 18),

          // QUESTION - ENGLISH
          _sectionLabel(Icons.language_rounded,
              _t('Question (English)', 'Pertanyaan (Inggris)', '问题（英语）')),
          _valueCard(
              (qEn == null || qEn.isEmpty) ? '-' : qEn),
          const SizedBox(height: 18),

          // QUESTION - MANDARIN
          _sectionLabel(Icons.translate_rounded,
              _t('Question (Mandarin)', 'Pertanyaan (Mandarin)', '问题（中文）')),
          _valueCard(
              (qZh == null || qZh.isEmpty) ? '-' : qZh),
          const SizedBox(height: 28),

          // ACTION BUTTONS
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _edit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.edit_outlined,
                            color: Color(0xFF2563EB), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _t('Edit', 'Edit', '编辑'),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _delete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delete_outline_rounded,
                            color: Color(0xFFEF4444), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _t('Delete', 'Hapus', '删除'),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}