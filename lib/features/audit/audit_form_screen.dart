import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'audit_evidence_camera_screen.dart';

/// AuditFormScreen — pertanyaan dikelompokkan per tema sesuai jenis audit,
/// muncul satu per satu saat dijawab, scroll vertikal, submit fixed di bawah.
class AuditFormScreen extends StatefulWidget {
  final String lang;
  final String levelType;
  final String idRef;
  final String locationName;
  final String? idSchedule;
  final String? selfieUrl;
  final String? idJenisAudit;

  const AuditFormScreen({
    super.key,
    required this.lang,
    required this.levelType,
    required this.idRef,
    required this.locationName,
    this.idSchedule,
    this.selfieUrl,
    this.idJenisAudit,
  });

  @override
  State<AuditFormScreen> createState() => _AuditFormScreenState();
}

class _AuditFormScreenState extends State<AuditFormScreen> {
  final _supabase = Supabase.instance.client;
  final _scrollCtrl = ScrollController();

  // Data
  List<Map<String, dynamic>> _temas = [];
  List<Map<String, dynamic>> _questions = [];
  final Map<String, bool?> _answers = {};
  final Map<String, String> _evidenceUrls = {};
  final Map<String, TextEditingController> _noteCtrls = {};
  final _finalNoteCtrl = TextEditingController();

  bool _loading = true;
  bool _submitting = false;

  // Keys untuk scroll otomatis ke pertanyaan berikutnya
  final Map<String, GlobalKey> _questionKeys = {};

  static const _primary   = Color(0xFF6366F1);
  static const _green     = Color(0xFF10B981);
  static const _red       = Color(0xFFEF4444);
  static const _amber     = Color(0xFFF59E0B);
  static const _textMain  = Color(0xFF1E3A8A);
  static const _textSub   = Color(0xFF64748B);
  static const _divider   = Color(0xFFE2E8F0);
  static const _surface   = Color(0xFFF8FAFC);

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _finalNoteCtrl.dispose();
    for (final c in _noteCtrls.values) c.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch tema sesuai jenis audit
      final temaQuery = _supabase.from('audit_tema').select();
      if (widget.idJenisAudit != null) {
        final temaRows = await temaQuery
            .eq('id_jenis_audit', widget.idJenisAudit!)
            .order('urutan');
        _temas = List<Map<String, dynamic>>.from(temaRows);
      } else {
        final temaRows = await temaQuery.order('urutan');
        _temas = List<Map<String, dynamic>>.from(temaRows);
      }

      // Fetch pertanyaan sesuai jenis audit
      var qQuery = _supabase
          .from('audit_question')
          .select()
          .eq('level_type', widget.levelType)
          .eq('id_ref', widget.idRef)
          .eq('is_active', true);
      if (widget.idJenisAudit != null) {
        qQuery = qQuery.eq('id_jenis_audit', widget.idJenisAudit!);
      }
      final qRows = await qQuery.order('urutan');

      if (mounted) {
        setState(() {
          _questions = List<Map<String, dynamic>>.from(qRows);
          for (final q in _questions) {
            final id = q['id_question'].toString();
            _answers[id] = null;
            _noteCtrls[id] = TextEditingController();
            _questionKeys[id] = GlobalKey();
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

  String _temaLabel(Map<String, dynamic> t) {
    if (widget.lang == 'EN') return t['nama_tema_en']?.toString() ?? '-';
    if (widget.lang == 'ZH') return t['nama_tema_zh']?.toString() ?? '-';
    return t['nama_tema_id']?.toString() ?? '-';
  }

  // ── Pertanyaan yang sudah "visible" (pertanyaan pertama per tema selalu visible,
  //    pertanyaan berikutnya visible setelah pertanyaan sebelumnya dijawab) ──
  bool _isVisible(List<Map<String, dynamic>> temaQuestions, int index) {
    if (index == 0) return true;
    final prevId = temaQuestions[index - 1]['id_question'].toString();
    return _isQuestionComplete(prevId);
  }

  bool _isQuestionComplete(String id) {
    final ans = _answers[id];
    if (ans == null) return false;
    if (ans == false) {
      return (_evidenceUrls[id] ?? '').isNotEmpty &&
          (_noteCtrls[id]?.text.trim() ?? '').isNotEmpty;
    }
    return true;
  }

  bool get _allAnswered =>
      _questions.isNotEmpty &&
      _questions.every((q) => _isQuestionComplete(q['id_question'].toString()));

  int get _answeredCount => _questions.where((q) => _isQuestionComplete(q['id_question'].toString())).length;

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

  void _onAnswer(String id, bool value) {
    setState(() => _answers[id] = value);
    // Tunggu frame selesai render baru scroll, hindari konflik rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        _scrollToNext(id);
      });
    });
  }

  void _scrollToNext(String answeredId) {
    if (!mounted || !_scrollCtrl.hasClients) return;

    final idx = _questions.indexWhere(
      (q) => q['id_question'].toString() == answeredId,
    );
    if (idx < 0) return;

    final currentScroll = _scrollCtrl.offset;
    final maxScroll = _scrollCtrl.position.maxScrollExtent;

    // Cari pertanyaan atau tema header berikutnya yang sudah ter-render
    for (int i = idx + 1; i < _questions.length; i++) {
      final nextId = _questions[i]['id_question'].toString();
      final key = _questionKeys[nextId];
      final ctx = key?.currentContext;
      if (ctx == null) continue;

      final ro = ctx.findRenderObject();
      if (ro == null || !ro.attached) continue;

      final renderBox = ro as RenderBox?;
      if (renderBox == null) continue;

      try {
        final offset = renderBox.localToGlobal(
          Offset.zero,
          ancestor: _scrollCtrl.position.context.storageContext.findRenderObject(),
        );
        final rawTarget = currentScroll + offset.dy - 80; // 80px padding atas

        // ── PERUBAHAN: jangan pernah scroll mundur ke atas, hanya boleh maju ke bawah ──
        final targetScroll = rawTarget.clamp(currentScroll, maxScroll);

        if (targetScroll > currentScroll) {
          _scrollCtrl.animateTo(
            targetScroll,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
        // Jika targetScroll <= currentScroll, pertanyaan berikutnya sudah terlihat,
        // tidak perlu scroll sama sekali (dan tidak boleh scroll mundur ke atas).
      } catch (_) {
        // ── PERUBAHAN: tidak lagi fallback ke ensureVisible karena berisiko
        // scroll ke atas — lebih aman tidak auto-scroll untuk kasus ini.
      }
      return;
    }

    // Semua sudah dijawab → scroll ke bawah untuk tombol Submit
    final bottomTarget = _scrollCtrl.position.maxScrollExtent;
    if (bottomTarget > currentScroll) {
      _scrollCtrl.animateTo(
        bottomTarget,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

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
        content: Text(_t('Please complete all questions.',
            'Lengkapi semua pertanyaan.', '请完成所有问题。')),
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
      final score = double.parse(_score.toStringAsFixed(2));

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
            'is_finalized': false,
          })
          .select('id_result')
          .single();

      final idResult = resultRow['id_result'].toString();

      // 2. Insert semua jawaban
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

      // 3. Update status schedule
      if (widget.idSchedule != null) {
        await _supabase
            .from('audit_schedule')
            .update({'status': 'done'})
            .eq('id_schedule', widget.idSchedule!);
      }

      // 4. Beri poin AUDIT_SUBMIT ke auditor
      await _grantAuditSubmitPoin(userId: userId, score: score);

      // 5. Kirim notif ke PIC lokasi yang diaudit
      await _notifyPic(idResult, score);

      // 6. Beri bonus poin (ke PIC) jika ada tema/keseluruhan yang 100%
      await _grantBonusPoin(userId: userId, idResult: idResult);

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

  Future<void> _notifyPic(String idResult, double score) async {
    try {
      // Ambil id_pic dari level yang diaudit
      final nameCol = 'nama_${widget.levelType}';
      final idCol = 'id_${widget.levelType}';
      final levelRow = await _supabase
          .from(widget.levelType)
          .select('id_pic, $nameCol')
          .eq(idCol, widget.idRef)
          .maybeSingle();

      final picId = levelRow?['id_pic']?.toString();
      if (picId == null) return;

      // Ambil FCM token PIC
      final picData = await _supabase
          .from('User')
          .select('fcm_token, nama')
          .eq('id_user', picId)
          .maybeSingle();

      final fcmToken = picData?['fcm_token']?.toString();
      if (fcmToken == null || fcmToken.trim().isEmpty) return;

      final notifTitle = _t(
        'Hasil Audit Masuk',
        'Audit Result Received',
        '收到审计结果',
      );
      final notifBody =
          '${widget.locationName} — ${score.toStringAsFixed(0)}%';

      await _supabase.functions.invoke(
        'send-fcm-v1',
        body: {
          'token': fcmToken.trim(),
          'title': notifTitle,
          'body': notifBody,
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'route': 'audit_notif',
          },
        },
      );
    } catch (e) {
      debugPrint('_notifyPic error: $e');
    }
  }

  /// Beri poin dasar AUDIT_SUBMIT ke auditor yang mengisi audit.
  Future<void> _grantAuditSubmitPoin({
    required String userId,
    required double score,
  }) async {
    try {
      final cfgRow = await _supabase
          .from('konfigurasi_poin')
          .select('poin, deskripsi_template')
          .eq('kode', 'AUDIT_SUBMIT')
          .eq('is_aktif', true)
          .maybeSingle();

      if (cfgRow == null) return;

      final deskripsi = (cfgRow['deskripsi_template'] as String)
          .replaceAll('{lokasi}', widget.locationName)
          .replaceAll('{nilai}', score.toStringAsFixed(0));

      await _supabase.from('log_poin').insert({
        'id_user':        userId,
        'poin':           cfgRow['poin'] as int,
        'deskripsi':      deskripsi,
        'tipe_aktivitas': 'audit_submit',
      });
    } catch (e) {
      debugPrint('Error granting audit submit poin: $e');
    }
  }

  /// Beri bonus poin per tema (100%) dan full (semua 100%) ke PIC lokasi yang diaudit.
  /// HANYA diberikan jika SELURUH jawaban di result ini adalah Yes (tidak ada satupun No).
  Future<List<Map<String, dynamic>>> _grantBonusPoin({
    required String userId,
    required String idResult,
  }) async {
    final List<Map<String, dynamic>> granted = [];
    try {
      // ── Guard: jika ada satu saja jawaban No → skip semua bonus tema & full ──
      final hasAnyNo = _answers.values.any((ans) => ans == false);
      if (hasAnyNo) return granted;

      final cfgRows = await _supabase
          .from('konfigurasi_poin')
          .select('kode, poin, deskripsi_template')
          .inFilter('kode', ['AUDIT_BONUS_TEMA', 'AUDIT_BONUS_FULL'])
          .eq('is_aktif', true);

      final Map<String, Map<String, dynamic>> cfg = {};
      for (final row in cfgRows as List) {
        cfg[row['kode'].toString()] = row as Map<String, dynamic>;
      }
      if (cfg.isEmpty) return granted;

      // ── Ambil id_pic dari lokasi yang diaudit ──
      final levelType = widget.levelType;
      final idRef     = widget.idRef;
      final nameCol   = 'nama_$levelType';
      final idCol     = 'id_$levelType';

      final levelRow = await _supabase
          .from(levelType)
          .select('id_pic, $nameCol')
          .eq(idCol, idRef)
          .maybeSingle();

      final picId = levelRow?['id_pic']?.toString();
      if (picId == null) return granted;

      // ── Hitung skor per tema (di sini pasti semua Yes karena guard di atas) ──
      final Map<String, List<bool>> temaAnswers = {};
      for (final q in _questions) {
        final id  = q['id_question'].toString();
        final ans = _answers[id];
        if (ans == null) continue;
        final temaId = q['id_tema']?.toString() ?? 'no_tema';
        temaAnswers.putIfAbsent(temaId, () => []).add(ans);
      }

      // Map temaId → nama tema
      final Map<String, String> temaNames = {};
      for (final t in _temas) {
        final id = t['id_tema'].toString();
        String name;
        if (widget.lang == 'EN') {
          name = t['nama_tema_en']?.toString() ?? '-';
        } else if (widget.lang == 'ZH') {
          name = t['nama_tema_zh']?.toString() ?? '-';
        } else {
          name = t['nama_tema_id']?.toString() ?? '-';
        }
        temaNames[id] = name;
      }

      // Karena sudah dipastikan tidak ada No, semua tema pasti 100%
      bool allTema100 = temaAnswers.isNotEmpty;
      final List<Map<String, dynamic>> logEntries = [];

      for (final entry in temaAnswers.entries) {
        final temaId  = entry.key;
        final answers = entry.value;
        // Double-check: semua harus Yes
        final allYes  = answers.every((a) => a == true);
        if (!allYes) {
          allTema100 = false;
          continue;
        }

        final temaCfg = cfg['AUDIT_BONUS_TEMA'];
        if (temaCfg != null) {
          final temaLabel = temaNames[temaId] ?? temaId;
          final deskripsi = (temaCfg['deskripsi_template'] as String)
              .replaceAll('{tema}', temaLabel)
              .replaceAll('{lokasi}', widget.locationName);

          logEntries.add({
            'id_user':        picId,
            'poin':           temaCfg['poin'] as int,
            'deskripsi':      deskripsi,
            'tipe_aktivitas': 'audit_bonus_tema',
          });
          granted.add({'poin': temaCfg['poin'] as int, 'deskripsi': deskripsi});
        }
      }

      if (allTema100 && cfg.containsKey('AUDIT_BONUS_FULL')) {
        final fullCfg   = cfg['AUDIT_BONUS_FULL']!;
        final deskripsi = (fullCfg['deskripsi_template'] as String)
            .replaceAll('{lokasi}', widget.locationName)
            .replaceAll('{tema}', '');

        logEntries.add({
          'id_user':        picId,
          'poin':           fullCfg['poin'] as int,
          'deskripsi':      deskripsi,
          'tipe_aktivitas': 'audit_bonus_full',
        });
        granted.add({'poin': fullCfg['poin'] as int, 'deskripsi': deskripsi});
      }

      if (logEntries.isNotEmpty) {
        await _supabase.from('log_poin').insert(logEntries);
      }
    } catch (e) {
      debugPrint('Error granting bonus poin: $e');
    }
    return granted;
  }

  void _showResult(double score) {
    Color color;
    String label;
    if (score >= 80) {
      color = _green;
      label = _t('Good', 'Baik', '良好');
    } else if (score >= 60) {
      color = _amber;
      label = _t('Fair', 'Cukup', '一般');
    } else {
      color = _red;
      label = _t('Poor', 'Kurang', '较差');
    }

    // Apakah ada jawaban No (belum 100%)
    final hasNoAnswer = _answers.values.any((v) => v == false);

    showDialog(
      context: context,
      // ── PERUBAHAN: popup bisa ditutup dengan klik di luar area ──
      barrierDismissible: true,
      builder: (dialogContext) {
        // ── PERUBAHAN: auto-tutup popup 5 detik setelah muncul ──
        Future.delayed(const Duration(seconds: 5), () {
          try {
            if (Navigator.of(dialogContext).canPop()) {
              Navigator.of(dialogContext).pop();
            }
          } catch (_) {
            // Popup sudah ditutup lebih dulu (klik luar / tombol) — aman diabaikan
          }
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12), shape: BoxShape.circle),
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
                  // ── PERUBAHAN: urutan parameter (en, id, zh) diperbaiki ──
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

                // ── Info jika ada jawaban No: poin menunggu perbaikan ──
                if (hasNoAnswer) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      // ── PERUBAHAN: background dibuat putih saja ──
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 15, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            // ── PERUBAHAN: urutan parameter (en, id, zh) diperbaiki ──
                            _t(
                              'Some findings are pending. Overall points will be '
                              'shown after PIC replies and you confirm all fixes.',
                              'Masih ada temuan yang belum selesai. '
                              'Poin keseluruhan akan ditampilkan setelah PIC membalas '
                              'dan Anda mengkonfirmasi semua perbaikan.',
                              '存在待处理发现。PIC回复并您确认所有修复后将显示总积分。',
                            ),
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: _amber),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // ── PERUBAHAN: cukup tutup dialog di sini,
                      // navigasi balik ditangani setelah dialog selesai (lihat .then di bawah) ──
                      Navigator.pop(dialogContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(
                        // ── PERUBAHAN: urutan parameter (en, id, zh) diperbaiki ──
                        _t('Done', 'Selesai', '完成'),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // ── PERUBAHAN: baru kembali ke screen sebelumnya SETELAH popup tertutup,
      // konsisten untuk semua cara menutup (tombol / klik luar / auto 5 detik) ──
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _questions.length;
    final progress = total == 0 ? 0.0 : _answeredCount / total;

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textMain, size: 20),
          onPressed: () => Navigator.pop(context),
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
                    // ── Selfie banner ──
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
                                '$_answeredCount / $total ${_t('answered', 'dijawab', '已回答')}',
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

                    // ── Scrollable content ──
                    Expanded(
                      child: ListView(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        children: _buildContent(),
                      ),
                    ),
                  ],
                ),
      // ── Submit button fixed di bawah ──
      bottomNavigationBar: _loading || _questions.isEmpty
          ? null
          : Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Catatan akhir
                  TextField(
                    controller: _finalNoteCtrl,
                    maxLines: 2,
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: _t('Additional notes (optional)…', 'Catatan tambahan (opsional)…', '补充备注（可选）…'),
                      hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                      filled: true,
                      fillColor: _surface,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _divider)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _divider)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!_allAnswered)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 14, color: _amber),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _t(
                                'Answer all questions to submit.',
                                'Jawab semua pertanyaan untuk mengirim.',
                                '回答所有问题后即可提交。',
                              ),
                              style: GoogleFonts.poppins(fontSize: 11, color: _amber),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_allAnswered && !_submitting) ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _allAnswered ? _primary : Colors.grey.shade300,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              _t('Submit Audit', 'Kirim Audit', '提交审计'),
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildContent() {
    final List<Widget> widgets = [];

    // Group pertanyaan per tema
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

    // Render per tema sesuai urutan _temas
    // ── PERUBAHAN: hanya tampilkan tema berikutnya jika tema sebelumnya sudah semua terjawab ──
    bool previousTemaDone = true; // tema pertama selalu boleh tampil

    for (final tema in _temas) {
      final temaId = tema['id_tema'].toString();
      final temaQs = grouped[temaId];
      if (temaQs == null || temaQs.isEmpty) continue;

      // Hanya tampilkan tema ini jika tema sebelumnya sudah selesai semua
      if (!previousTemaDone) break;

      widgets.add(_buildTemaHeader(tema, temaQs));
      widgets.addAll(_buildTemaQuestions(temaQs));
      widgets.add(const SizedBox(height: 8));

      // Cek apakah tema ini sudah selesai semua untuk menentukan boleh tampilkan tema berikutnya
      final temaAllDone = temaQs.every(
        (q) => _isQuestionComplete(q['id_question'].toString()),
      );
      previousTemaDone = temaAllDone;
    }

    // Pertanyaan tanpa tema — tampil hanya jika semua tema sebelumnya selesai
    if (previousTemaDone && noTema.isNotEmpty) {
      widgets.add(_buildNoTemaHeader());
      widgets.addAll(_buildTemaQuestions(noTema));
    }

    return widgets;
  }

  Widget _buildTemaHeader(Map<String, dynamic> tema, List<Map<String, dynamic>> qs) {
    final answered = qs.where((q) => _isQuestionComplete(q['id_question'].toString())).length;
    final isDone = answered == qs.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 10, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDone ? _green.withOpacity(0.08) : _primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDone ? _green.withOpacity(0.3) : _primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.topic_outlined,
            color: isDone ? _green : _primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _temaLabel(tema),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDone ? _green : _primary,
              ),
            ),
          ),
          Text(
            '$answered/${qs.length}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDone ? _green : _textSub,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoTemaHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _textSub.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _textSub.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.list_alt_rounded, color: _textSub, size: 18),
          const SizedBox(width: 8),
          Text(
            _t('Other', 'Lainnya', '其他'),
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _textSub),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTemaQuestions(List<Map<String, dynamic>> qs) {
    final List<Widget> result = [];
    for (int i = 0; i < qs.length; i++) {
      // ── PERUBAHAN: dalam satu tema, pertanyaan muncul satu per satu ──
      // Pertanyaan ke-i visible jika pertanyaan ke-(i-1) sudah complete
      final visible = _isVisible(qs, i);
      if (!visible) break;
      result.add(_buildQuestionCard(qs[i], i + 1));
      result.add(const SizedBox(height: 10));
    }
    return result;
  }

  Widget _buildQuestionCard(Map<String, dynamic> q, int displayIndex) {
    final id = q['id_question'].toString();
    final answer = _answers[id];
    final isYes = answer == true;
    final isNo = answer == false;
    final evidenceUrl = _evidenceUrls[id];
    final noteCtrl = _noteCtrls[id]!;

    return KeyedSubtree(
      key: _questionKeys[id],
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: answer == null
                ? _divider
                : (isYes ? _green : _red).withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header pertanyaan ──
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: answer == null
                          ? const Color(0xFFEDE9FE)
                          : (isYes ? _green : _red).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: answer == null
                          ? Text('$displayIndex',
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800, color: _primary))
                          : Icon(
                              isYes ? Icons.check_rounded : Icons.close_rounded,
                              size: 16,
                              color: isYes ? _green : _red,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _questionText(q),
                      style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600, color: _textMain),
                    ),
                  ),
                ],
              ),
            ),

            // ── Tombol Yes / No ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onAnswer(id, true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: isYes ? _green.withOpacity(0.12) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isYes ? _green : Colors.grey.shade300,
                              width: isYes ? 1.5 : 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isYes ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                              size: 18, color: isYes ? _green : Colors.grey,
                            ),
                            const SizedBox(width: 5),
                            Text(_t('Yes', 'Ya', '是'),
                                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700,
                                    color: isYes ? _green : Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onAnswer(id, false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: isNo ? _red.withOpacity(0.10) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isNo ? _red : Colors.grey.shade300,
                              width: isNo ? 1.5 : 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isNo ? Icons.cancel_rounded : Icons.cancel_outlined,
                              size: 18, color: isNo ? _red : Colors.grey,
                            ),
                            const SizedBox(width: 5),
                            Text(_t('No', 'Tidak', '否'),
                                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700,
                                    color: isNo ? _red : Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Evidence section jika No ──
            if (isNo) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _red.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _red.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.error_outline_rounded, size: 14, color: _red),
                      const SizedBox(width: 5),
                      Text(
                        _t('Evidence Required', 'Bukti Wajib Dilampirkan', '需要提供证据'),
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _red),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    // Upload foto
                    if (evidenceUrl == null)
                      GestureDetector(
                        onTap: () => _captureEvidence(id, _questionText(q)),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _red.withOpacity(0.35)),
                          ),
                          child: Column(children: [
                            const Icon(Icons.add_a_photo_rounded, color: _red, size: 24),
                            const SizedBox(height: 5),
                            Text(
                              _t('Take / Upload Photo', 'Ambil / Unggah Foto', '拍照/上传照片'),
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _red),
                            ),
                          ]),
                        ),
                      )
                    else
                      Stack(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            evidenceUrl,
                            width: double.infinity,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 140,
                              color: Colors.grey.shade100,
                              child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6, right: 6,
                          child: GestureDetector(
                            onTap: () => _captureEvidence(id, _questionText(q)),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ]),
                    const SizedBox(height: 10),
                    Text(_t('Notes', 'Catatan', '备注'),
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _textSub)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 3,
                      style: GoogleFonts.poppins(fontSize: 13),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: _t('Describe the issue found…', 'Jelaskan masalah yang ditemukan…', '描述发现的问题…'),
                        hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _divider)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _divider)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primary, width: 1.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Hint jika Yes ──
            if (isYes)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded, size: 14, color: _green),
                  const SizedBox(width: 5),
                  Text(
                    _t('Answered ✓', 'Terjawab ✓', '已回答 ✓'),
                    style: GoogleFonts.poppins(fontSize: 11, color: _green),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

/// Banner selfie — tidak berubah dari versi lama
class _SelfieEvidenceBanner extends StatelessWidget {
  final String selfieUrl;
  final String lang;

  const _SelfieEvidenceBanner({required this.selfieUrl, required this.lang});

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
              width: 52, height: 52, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 52, height: 52,
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
                Row(children: [
                  const Icon(Icons.verified_rounded, color: teal, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    _t('Audit Location Proof', 'Bukti Lokasi Audit', '审计位置证明'),
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: teal),
                  ),
                ]),
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