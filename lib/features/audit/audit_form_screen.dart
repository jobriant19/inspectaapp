import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Screen that an auditor uses to answer questions and submit an audit.
class AuditFormScreen extends StatefulWidget {
  final String lang;
  final String levelType;
  final String idRef;
  final String locationName;
  final String? idSchedule; // optional – pass if opened from a schedule

  const AuditFormScreen({
    super.key,
    required this.lang,
    required this.levelType,
    required this.idRef,
    required this.locationName,
    this.idSchedule,
  });

  @override
  State<AuditFormScreen> createState() => _AuditFormScreenState();
}

class _AuditFormScreenState extends State<AuditFormScreen> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _questions = [];
  final Map<String, bool?> _answers = {}; // id_question → true/false/null
  final _noteCtrl = TextEditingController();
  bool _loading = true;
  bool _submitting = false;

  static const _primary = Color(0xFF6366F1);
  static const _green   = Color(0xFF10B981);
  static const _red     = Color(0xFFEF4444);
  static const _textMain = Color(0xFF1E3A8A);
  static const _textSub  = Color(0xFF64748B);
  static const _divider  = Color(0xFFE2E8F0);

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

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchQuestions() async {
    try {
      final rows = await _supabase
          .from('audit_question')
          .select()
          .eq('level_type', widget.levelType)
          .eq('id_ref', widget.idRef)
          .eq('is_active', true)
          .order('urutan');
      if (mounted) {
        setState(() {
          _questions = List<Map<String, dynamic>>.from(rows);
          for (final q in _questions) {
            _answers[q['id_question'].toString()] = null;
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _score {
    if (_questions.isEmpty) return 0;
    final answered = _answers.values.where((v) => v != null).length;
    if (answered == 0) return 0;
    final yes = _answers.values.where((v) => v == true).length;
    return (yes / _questions.length) * 100;
  }

  bool get _allAnswered =>
      _questions.isNotEmpty &&
      _questions.every(
          (q) => _answers[q['id_question'].toString()] != null);

  Future<void> _submit() async {
    if (!_allAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t(
            'Please answer all questions.',
            'Jawab semua pertanyaan terlebih dahulu.',
            '请回答所有问题。')),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }

    setState(() => _submitting = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final score  = double.parse(_score.toStringAsFixed(2));

      // 1. Insert audit_result
      final resultRow = await _supabase
          .from('audit_result')
          .insert({
            'id_schedule': widget.idSchedule,
            'id_auditor': userId,
            'level_type': widget.levelType,
            'id_ref': widget.idRef,
            'tanggal_audit': DateTime.now().toIso8601String().split('T').first,
            'nilai_audit': score,
            'catatan_audit': _noteCtrl.text.trim().isEmpty
                ? null
                : _noteCtrl.text.trim(),
          })
          .select('id_result')
          .single();

      final idResult = resultRow['id_result'].toString();

      // 2. Insert audit_answer for each question
      final answers = _answers.entries.map((e) => {
            'id_result': idResult,
            'id_question': e.key,
            'jawaban': e.value,
          }).toList();
      await _supabase.from('audit_answer').insert(answers);

      // 3. If opened from a schedule, mark it done
      if (widget.idSchedule != null) {
        await _supabase
            .from('audit_schedule')
            .update({'status': 'done'})
            .eq('id_schedule', widget.idSchedule!);
      }

      if (mounted) {
        _showResult(score);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  void _showResult(double score) {
    Color color;
    String label;
    if (score >= 80) { color = _green; label = _t('Good', 'Baik', '良好'); }
    else if (score >= 60) { color = const Color(0xFFF59E0B); label = _t('Fair', 'Cukup', '一般'); }
    else { color = _red; label = _t('Poor', 'Kurang', '较差'); }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${score.toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _t('Audit Completed!', 'Audit Selesai!', '审计完成！'),
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textMain),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.locationName} — $label',
              style: GoogleFonts.poppins(fontSize: 13, color: _textSub),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: Text(_t('Done', 'Selesai', '完成'),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final answered = _answers.values.where((v) => v != null).length;
    final total = _questions.length;
    final progress = total == 0 ? 0.0 : answered / total;

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
              _t('Audit Form', 'Formulir Audit', '审计表单'),
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _textMain),
            ),
            Text(widget.locationName,
                style:
                    GoogleFonts.poppins(fontSize: 11, color: _textSub)),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _primary))
          : Column(
              children: [
                // Progress header
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$answered / $total ${_t('answered', 'dijawab', '已回答')}',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _textSub),
                          ),
                          Text(
                            '${_score.toStringAsFixed(0)}%',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(_primary),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Questions list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: _questions.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      if (i == _questions.length) {
                        // Notes field
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            const SizedBox(height: 8),
                            Text(
                              _t('Notes (optional)', 'Catatan (opsional)', '备注（可选）'),
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _textMain),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _noteCtrl,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: _t(
                                    'Add notes…', 'Tambahkan catatan…', '添加备注…'),
                                hintStyle: GoogleFonts.poppins(
                                    fontSize: 13, color: Colors.grey),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: _divider)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: _divider)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: _primary, width: 1.5)),
                              ),
                            ),
                          ],
                        );
                      }

                      final q = _questions[i];
                      final id = q['id_question'].toString();
                      final answer = _answers[id];
                      return _QuestionCard(
                        index: i + 1,
                        question: q['pertanyaan'] as String,
                        answer: answer,
                        lang: widget.lang,
                        onChanged: (val) =>
                            setState(() => _answers[id] = val),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _allAnswered ? _primary : Colors.grey.shade300,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(
                    _t('Submit Audit', 'Kirim Audit', '提交审计'),
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Question card ────────────────────────────────────────────────────────────
class _QuestionCard extends StatelessWidget {
  final int index;
  final String question;
  final bool? answer;
  final String lang;
  final ValueChanged<bool> onChanged;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.answer,
    required this.lang,
    required this.onChanged,
  });

  String _t(String en, String id, String zh) {
    if (lang == 'EN') return en;
    if (lang == 'ZH') return zh;
    return id;
  }

  @override
  Widget build(BuildContext context) {
    const green  = Color(0xFF10B981);
    const red    = Color(0xFFEF4444);
    const pLt    = Color(0xFFEDE9FE);
    const textMain = Color(0xFF1E3A8A);

    final isYes = answer == true;
    final isNo  = answer == false;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: answer == null
              ? const Color(0xFFE2E8F0)
              : (isYes ? green : red).withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: pLt,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('$index',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF6366F1))),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(question,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textMain)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isYes
                          ? green.withOpacity(0.12)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isYes ? green : Colors.grey.shade300,
                        width: isYes ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isYes
                              ? Icons.check_circle_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 18,
                          color: isYes ? green : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _t('Yes', 'Ya', '是'),
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isYes ? green : Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isNo
                          ? red.withOpacity(0.10)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isNo ? red : Colors.grey.shade300,
                        width: isNo ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isNo
                              ? Icons.cancel_rounded
                              : Icons.cancel_outlined,
                          size: 18,
                          color: isNo ? red : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _t('No', 'Tidak', '否'),
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isNo ? red : Colors.grey),
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