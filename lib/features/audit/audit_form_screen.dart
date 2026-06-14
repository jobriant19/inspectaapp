import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'audit_evidence_camera_screen.dart';

/// Screen that an auditor uses to answer questions and submit an audit.
/// Flow: Yes -> auto next question. No -> wajib upload foto bukti + catatan
/// sebelum bisa lanjut ke pertanyaan berikutnya.
class AuditFormScreen extends StatefulWidget {
  final String lang;
  final String levelType;
  final String idRef;
  final String locationName;
  final String? idSchedule;
  final String? selfieUrl;

  const AuditFormScreen({
    super.key,
    required this.lang,
    required this.levelType,
    required this.idRef,
    required this.locationName,
    this.idSchedule,
    this.selfieUrl,
  });

  @override
  State<AuditFormScreen> createState() => _AuditFormScreenState();
}

class _AuditFormScreenState extends State<AuditFormScreen> {
  final _supabase = Supabase.instance.client;
  final _pageCtrl = PageController();

  List<Map<String, dynamic>> _questions = [];
  final Map<String, bool?> _answers = {};       // id_question → true/false/null
  final Map<String, String> _evidenceUrls = {}; // id_question → image url (untuk jawaban No)
  final Map<String, TextEditingController> _noteCtrls = {}; // id_question → catatan (untuk jawaban No)
  final _finalNoteCtrl = TextEditingController(); // catatan akhir/umum

  bool _loading = true;
  bool _submitting = false;
  int _currentPage = 0;

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
    _pageCtrl.dispose();
    _finalNoteCtrl.dispose();
    for (final c in _noteCtrls.values) {
      c.dispose();
    }
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
            final id = q['id_question'].toString();
            _answers[id] = null;
            _noteCtrls[id] = TextEditingController();
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _questionText(Map<String, dynamic> q) {
    if (widget.lang == 'EN') return q['pertanyaan_en']?.toString() ?? q['pertanyaan']?.toString() ?? '';
    if (widget.lang == 'ZH') return q['pertanyaan_zh']?.toString() ?? q['pertanyaan']?.toString() ?? '';
    return q['pertanyaan']?.toString() ?? '';
  }

  // ── Total halaman = jumlah pertanyaan + 1 (halaman ringkasan/catatan akhir) ──
  int get _totalPages => _questions.length + 1;

  // ── Skor akhir = rata-rata skor per tema, lalu rata-rata antar tema ──
  double get _score {
    if (_questions.isEmpty) return 0;
    final Map<String, List<bool>> groups = {};
    for (final q in _questions) {
      final id = q['id_question'].toString();
      final ans = _answers[id];
      if (ans == null) continue;
      final key = q['id_tema']?.toString() ?? 'no_tema';
      groups.putIfAbsent(key, () => []).add(ans);
    }
    if (groups.isEmpty) return 0;
    final groupScores = groups.values.map((list) {
      final yes = list.where((v) => v == true).length;
      return (yes / list.length) * 100.0;
    }).toList();
    return groupScores.reduce((a, b) => a + b) / groupScores.length;
  }

  int get _answeredCount => _answers.values.where((v) => v != null).length;

  // ── Apakah jawaban untuk pertanyaan ini sudah lengkap (termasuk bukti jika No) ──
  bool _isQuestionComplete(String id) {
    final ans = _answers[id];
    if (ans == null) return false;
    if (ans == false) {
      final hasImage = (_evidenceUrls[id] ?? '').isNotEmpty;
      final hasNote = (_noteCtrls[id]?.text.trim() ?? '').isNotEmpty;
      return hasImage && hasNote;
    }
    return true;
  }

  bool get _allAnswered =>
      _questions.isNotEmpty &&
      _questions.every((q) => _isQuestionComplete(q['id_question'].toString()));

  // ── Handler pilih Yes ──
  void _onYes(String id) {
    setState(() => _answers[id] = true);
    _goNextAuto();
  }

  // ── Handler pilih No ──
  void _onNo(String id) {
    setState(() => _answers[id] = false);
    // tidak auto-next, user harus isi bukti + catatan dulu
  }

  // ── Pindah otomatis ke halaman berikutnya (delay singkat agar UI terlihat) ──
  void _goNextAuto() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      if (_currentPage < _totalPages - 1) {
        _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    });
  }

  void _goNext() {
    if (_currentPage < _totalPages - 1) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _goPrev() {
    if (_currentPage > 0) {
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  // ── Buka kamera bukti foto untuk jawaban "No" ──
  Future<void> _captureEvidence(String id, String questionText) async {
    final url = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => AuditEvidenceCameraScreen(
          lang: widget.lang,
          questionText: questionText,
        ),
      ),
    );
    if (url != null && mounted) {
      setState(() => _evidenceUrls[id] = url);
    }
  }

  Future<void> _submit() async {
    if (!_allAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t(
            'Please complete all questions (including evidence for "No" answers).',
            'Lengkapi semua pertanyaan (termasuk bukti untuk jawaban "Tidak").',
            '请完成所有问题（包括"否"答案的证据）。')),
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
            'catatan_audit': _finalNoteCtrl.text.trim().isEmpty
                ? null
                : _finalNoteCtrl.text.trim(),
            'selfie_url': widget.selfieUrl,
          })
          .select('id_result')
          .single();

      final idResult = resultRow['id_result'].toString();

      // 2. Insert audit_answer untuk setiap pertanyaan (termasuk bukti foto + catatan jika ada)
      final answers = _answers.entries.map((e) {
        final id = e.key;
        return {
          'id_result': idResult,
          'id_question': id,
          'jawaban': e.value,
          'catatan': _noteCtrls[id]?.text.trim().isEmpty == true
              ? null
              : _noteCtrls[id]?.text.trim(),
          'gambar_jawaban': _evidenceUrls[id],
        };
      }).toList();
      await _supabase.from('audit_answer').insert(answers);

      // 3. Jika dibuka dari schedule, tandai selesai
      if (widget.idSchedule != null) {
        await _supabase
            .from('audit_schedule')
            .update({'status': 'done'})
            .eq('id_schedule', widget.idSchedule!);
      }

      if (mounted) _showResult(score);
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
    final total = _questions.length;
    final progress = total == 0 ? 0.0 : _answeredCount / total;
    final isSummaryPage = _currentPage == total; // halaman terakhir

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textMain, size: 20),
          onPressed: () {
            if (_currentPage > 0) {
              _goPrev();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('Audit Form', 'Formulir Audit', '审计表单'),
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: _textMain),
            ),
            Text(widget.locationName,
                style: GoogleFonts.poppins(fontSize: 11, color: _textSub)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _questions.isEmpty
              ? Center(
                  child: Text(
                    _t('No active questions found.', 'Belum ada pertanyaan aktif.', '尚无活动问题。'),
                    style: GoogleFonts.poppins(fontSize: 13, color: _textSub),
                  ),
                )
              : Column(
                  children: [
                    // ── Banner bukti selfie (hanya tampil jika selfieUrl ada) ──
                    if (widget.selfieUrl != null)
                      _SelfieEvidenceBanner(selfieUrl: widget.selfieUrl!, lang: widget.lang),

                    // ── Progress header ──
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isSummaryPage
                                    ? _t('Summary', 'Ringkasan', '总结')
                                    : '${_currentPage + 1} / $total',
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _textSub),
                              ),
                              Text(
                                '${_score.toStringAsFixed(0)}%',
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: _primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(_primary),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // ── PageView pertanyaan (tidak bisa swipe manual) ──
                    Expanded(
                      child: PageView.builder(
                        controller: _pageCtrl,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _totalPages,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemBuilder: (_, i) {
                          if (i == _questions.length) return _buildSummaryPage();
                          return _buildQuestionPage(i);
                        },
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _loading || _questions.isEmpty
          ? null
          : Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              child: _buildBottomBar(),
            ),
    );
  }

  Widget _buildBottomBar() {
    final isSummaryPage = _currentPage == _questions.length;

    if (isSummaryPage) {
      // ── Halaman ringkasan: tombol Submit ──
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _allAnswered ? _primary : Colors.grey.shade300,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(_t('Submit Audit', 'Kirim Audit', '提交审计'),
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      );
    }

    final q = _questions[_currentPage];
    final id = q['id_question'].toString();
    final ans = _answers[id];

    // ── Pertanyaan dengan jawaban "Yes": tidak perlu tombol (auto-next) ──
    if (ans == true) return const SizedBox.shrink();

    // ── Pertanyaan dengan jawaban "No": tombol Next, aktif jika bukti+catatan lengkap ──
    if (ans == false) {
      final complete = _isQuestionComplete(id);
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: complete ? _goNext : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: complete ? _primary : Colors.grey.shade300,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          child: Text(
            _currentPage == _questions.length - 1
                ? _t('Continue to Summary', 'Lanjut ke Ringkasan', '继续到总结')
                : _t('Next Question', 'Pertanyaan Selanjutnya', '下一个问题'),
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    // ── Belum dijawab: tidak ada tombol ──
    return const SizedBox.shrink();
  }

  // ── Halaman pertanyaan tunggal ──
  Widget _buildQuestionPage(int index) {
    final q = _questions[index];
    final id = q['id_question'].toString();
    final answer = _answers[id];
    final isYes = answer == true;
    final isNo = answer == false;
    final evidenceUrl = _evidenceUrls[id];
    final noteCtrl = _noteCtrls[id]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Kartu pertanyaan ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: answer == null
                    ? const Color(0xFFE2E8F0)
                    : (isYes ? _green : _red).withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
                  child: Center(
                    child: Text('${index + 1}',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800, color: _primary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_questionText(q),
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _textMain)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Tombol Yes / No ──
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _onYes(id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isYes ? _green.withOpacity(0.12) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isYes ? _green : Colors.grey.shade300, width: isYes ? 1.5 : 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isYes ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                            size: 20, color: isYes ? _green : Colors.grey),
                        const SizedBox(width: 6),
                        Text(_t('Yes', 'Ya', '是'),
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: isYes ? _green : Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _onNo(id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isNo ? _red.withOpacity(0.10) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isNo ? _red : Colors.grey.shade300, width: isNo ? 1.5 : 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isNo ? Icons.cancel_rounded : Icons.cancel_outlined, size: 20, color: isNo ? _red : Colors.grey),
                        const SizedBox(width: 6),
                        Text(_t('No', 'Tidak', '否'),
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: isNo ? _red : Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Section bukti foto + catatan, hanya jika jawaban "No" ──
          if (isNo) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _red.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _red.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 16, color: _red),
                      const SizedBox(width: 6),
                      Text(
                        _t('Evidence Required', 'Bukti Wajib Dilampirkan', '需要提供证据'),
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Upload / preview foto ──
                  if (evidenceUrl == null)
                    GestureDetector(
                      onTap: () => _captureEvidence(id, _questionText(q)),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _red.withOpacity(0.35), style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.add_a_photo_rounded, color: _red, size: 28),
                            const SizedBox(height: 6),
                            Text(
                              _t('Take / Upload Photo', 'Ambil / Unggah Foto', '拍照/上传照片'),
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _red),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            evidenceUrl,
                            width: double.infinity,
                            height: 160,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 160,
                              color: Colors.grey.shade100,
                              child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8, right: 8,
                          child: GestureDetector(
                            onTap: () => _captureEvidence(id, _questionText(q)),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                              child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),

                  // ── Catatan wajib ──
                  Text(_t('Notes', 'Catatan', '备注'),
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _textSub)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 3,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: _t('Describe the issue found…', 'Jelaskan masalah yang ditemukan…', '描述发现的问题…'),
                      hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _divider)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _divider)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primary, width: 1.5)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Hint jika jawaban Yes (auto-lanjut) ──
          if (isYes) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                _t('Moving to next question…', 'Lanjut ke pertanyaan berikutnya…', '正在前往下一个问题…'),
                style: GoogleFonts.poppins(fontSize: 12, color: _textSub),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Halaman ringkasan (catatan akhir + rekap jawaban) ──
  Widget _buildSummaryPage() {
    final yesCount = _answers.values.where((v) => v == true).length;
    final noCount = _answers.values.where((v) => v == false).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('Audit Summary', 'Ringkasan Audit', '审计总结'),
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _textMain),
          ),
          const SizedBox(height: 12),

          // ── Recap chips ──
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _green.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text('$yesCount', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: _green)),
                      Text(_t('Yes', 'Ya', '是'), style: GoogleFonts.poppins(fontSize: 11, color: _green)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _red.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text('$noCount', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: _red)),
                      Text(_t('No', 'Tidak', '否'), style: GoogleFonts.poppins(fontSize: 11, color: _red)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text('${_score.toStringAsFixed(0)}%', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: _primary)),
                      Text(_t('Score', 'Skor', '分数'), style: GoogleFonts.poppins(fontSize: 11, color: _primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Catatan akhir (opsional) ──
          Text(_t('Additional Notes (optional)', 'Catatan Tambahan (opsional)', '补充备注（可选）'),
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _textMain)),
          const SizedBox(height: 8),
          TextField(
            controller: _finalNoteCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: _t('Add overall notes…', 'Tambahkan catatan umum…', '添加总体备注…'),
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _divider)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _divider)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 1.5)),
            ),
          ),

          // ── Peringatan jika belum lengkap ──
          if (!_allAnswered) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _t('Some questions are not fully answered yet.',
                          'Beberapa pertanyaan belum lengkap dijawab.',
                          '部分问题尚未完整回答。'),
                      style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Banner bukti selfie audit — tampil di bawah AppBar, di atas progress header.
class _SelfieEvidenceBanner extends StatelessWidget {
  final String selfieUrl;
  final String lang;

  const _SelfieEvidenceBanner({
    required this.selfieUrl,
    required this.lang,
  });

  String _t(String en, String id, String zh) {
    if (lang == 'EN') return en;
    if (lang == 'ZH') return zh;
    return id;
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF14B8A6);
    const tealBg = Color(0xFFE6FAF8);

    return Container(
      width: double.infinity,
      color: tealBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              selfieUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: teal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.broken_image_outlined, color: teal, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: teal, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      _t('Audit Location Proof', 'Bukti Lokasi Audit', '审计位置证明'),
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: teal),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _t(
                    'Selfie captured before the audit started.',
                    'Selfie diambil sebelum audit dimulai.',
                    '审计开始前已拍摄自拍。',
                  ),
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF0F766E)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}