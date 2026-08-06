import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'audit_evidence_camera_screen.dart';
import 'audit_popup_selfie.dart';

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

  List<Map<String, dynamic>> _temas = [];
  List<Map<String, dynamic>> _questions = [];
  final Map<String, bool?> _answers = {};
  final Map<String, XFile> _evidenceFiles = {};
  final Map<String, String> _evidenceUrls = {};
  final Map<String, TextEditingController> _noteCtrls = {};
  final _finalNoteCtrl = TextEditingController();

  bool _loading = true;
  bool _submitting = false;
  String? _selfieUrl;
  Timer? _scrollDebounceTimer;
  Timer? _scrollRetryTimer;
  int _scrollRequestGen = 0;
  static const int _maxScrollRetries = 6;

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

  IconData get _locationLevelIcon {
    switch (widget.levelType) {
      case 'area': return Icons.place_rounded;
      case 'subunit': return Icons.layers_rounded;
      case 'unit': return Icons.business_rounded;
      default: return Icons.location_city_rounded;
    }
  }

  Color get _locationLevelColor {
    switch (widget.levelType) {
      case 'area': return const Color(0xFFF472B6);
      case 'subunit': return const Color(0xFFFBBF24);
      case 'unit': return const Color(0xFF6366F1);
      default: return const Color(0xFF10B981);
    }
  }

  @override
  void initState() {
    super.initState();
    _selfieUrl = widget.selfieUrl;
    _fetchData();
  }

  @override
  void dispose() {
    _scrollDebounceTimer?.cancel();
    _scrollRetryTimer?.cancel();
    _scrollCtrl.dispose();
    _finalNoteCtrl.dispose();
    for (final c in _noteCtrls.values) { c.dispose(); }
    AuditEvidenceWarmupService.instance.release();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
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

      var qQuery = _supabase
          .from('audit_question')
          .select()
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

  bool _isVisible(List<Map<String, dynamic>> temaQuestions, int index) {
    if (index == 0) return true;
    final prevId = temaQuestions[index - 1]['id_question'].toString();
    return _isQuestionComplete(prevId);
  }

  bool _isQuestionComplete(String id) {
    final ans = _answers[id];
    if (ans == null) return false;
    if (ans == false) {
      return _evidenceFiles.containsKey(id) &&
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

  Color _scoreColor(double? s) {
    if (s == null) return const Color(0xFF64748B);
    if (s >= 80) return const Color(0xFF10B981);
    if (s >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  void _onAnswer(String id, bool value) {
    setState(() => _answers[id] = value);
    if (value == false) {
      AuditEvidenceWarmupService.instance.warmUp();
    }
    _requestAutoScroll(id, delayMs: 150);
  }

  void _requestAutoScroll(String id, {int delayMs = 150}) {
    _scrollDebounceTimer?.cancel();
    _scrollRetryTimer?.cancel();
    final gen = ++_scrollRequestGen;
    _scrollDebounceTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted || gen != _scrollRequestGen) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || gen != _scrollRequestGen) return;
        _scrollToNext(id, gen: gen);
      });
    });
  }

  List<String> _displayOrderedQuestionIds() {
    final List<String> ids = [];
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
    for (final tema in _temas) {
      final temaId = tema['id_tema'].toString();
      final temaQs = grouped[temaId];
      if (temaQs == null || temaQs.isEmpty) continue;
      ids.addAll(temaQs.map((q) => q['id_question'].toString()));
    }
    ids.addAll(noTema.map((q) => q['id_question'].toString()));
    return ids;
  }

  void _scrollToNext(String answeredId, {int attempt = 0, int gen = 0}) {
    if (!mounted || !_scrollCtrl.hasClients) return;
    if (gen != 0 && gen != _scrollRequestGen) return;

    final orderedIds = _displayOrderedQuestionIds();
    final idx = orderedIds.indexWhere((id) => id == answeredId);
    if (idx < 0) return;

    final currentScroll = _scrollCtrl.offset;
    final maxScroll = _scrollCtrl.position.maxScrollExtent;
    final viewport = _scrollCtrl.position.viewportDimension;

    if (!_isQuestionComplete(answeredId)) {
      final key = _questionKeys[answeredId];
      final ctx = key?.currentContext;
      final ro = ctx?.findRenderObject();
      if (ro is RenderBox && ro.attached) {
        try {
          final offset = ro.localToGlobal(
            Offset.zero,
            ancestor: _scrollCtrl.position.context.storageContext.findRenderObject(),
          );
          final cardBottom = currentScroll + offset.dy + ro.size.height;
          final rawTarget = cardBottom - viewport + 24;
          final targetScroll = rawTarget.clamp(currentScroll, maxScroll);
          if (targetScroll > currentScroll) {
            _scrollCtrl.animateTo(
              targetScroll,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            );
          }
        } catch (_) {}
      } else if (attempt < _maxScrollRetries) {
        _scheduleScrollRetry(answeredId, attempt, gen);
      }
      return;
    }

    bool foundRenderedTarget = false;
    for (int i = idx + 1; i < orderedIds.length; i++) {
      final nextId = orderedIds[i];
      final key = _questionKeys[nextId];
      final ctx = key?.currentContext;
      if (ctx == null) continue;

      final ro = ctx.findRenderObject();
      if (ro == null || !ro.attached) continue;

      final renderBox = ro as RenderBox?;
      if (renderBox == null) continue;

      foundRenderedTarget = true;

      try {
        final offset = renderBox.localToGlobal(
          Offset.zero,
          ancestor: _scrollCtrl.position.context.storageContext.findRenderObject(),
        );
        final rawTarget = currentScroll + offset.dy - 80;

        final targetScroll = rawTarget.clamp(currentScroll, maxScroll);

        if (targetScroll > currentScroll) {
          _scrollCtrl.animateTo(
            targetScroll,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      } catch (_) {
      }
      return;
    }

    if (!foundRenderedTarget && idx + 1 < _questions.length && attempt < _maxScrollRetries) {
      _scheduleScrollRetry(answeredId, attempt, gen);
      return;
    }

    final bottomTarget = _scrollCtrl.position.maxScrollExtent;
    if (bottomTarget > currentScroll) {
      _scrollCtrl.animateTo(
        bottomTarget,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  void _scheduleScrollRetry(String answeredId, int attempt, int gen) {
    _scrollRetryTimer?.cancel();
    final delay = Duration(milliseconds: 80 + (attempt * 60));
    _scrollRetryTimer = Timer(delay, () {
      if (!mounted || (gen != 0 && gen != _scrollRequestGen)) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || (gen != 0 && gen != _scrollRequestGen)) return;
        _scrollToNext(answeredId, attempt: attempt + 1, gen: gen);
      });
    });
  }

  Future<void> _captureEvidence(String id, String questionText) async {
    final file = await Navigator.push<XFile>(
      context,
      MaterialPageRoute(
        builder: (_) => AuditEvidenceCameraScreen(
          lang: widget.lang,
          questionText: questionText,
        ),
      ),
    );
    if (file != null && mounted) {
      setState(() {
        _evidenceFiles[id] = file;
        _evidenceUrls.remove(id);
      });
      _requestAutoScroll(id, delayMs: 150);
      AuditEvidenceWarmupService.instance.warmUp();
    }
  }

  void _showEvidencePreview(XFile file) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        final size = MediaQuery.of(dialogContext).size;
        final isLandscape = size.width > size.height;
        final maxW = isLandscape ? size.width * 0.75 : size.width * 0.92;
        final maxH = isLandscape ? size.height * 0.88 : size.height * 0.7;

        Widget img() => kIsWeb
            ? Image.network(
                file.path,
                fit: BoxFit.contain,
                width: double.infinity,
                errorBuilder: (_, __, ___) => SizedBox(
                  height: 200,
                  child: Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: Colors.grey.shade400, size: 40),
                  ),
                ),
              )
            : Image.file(
                File(file.path),
                fit: BoxFit.contain,
                width: double.infinity,
                errorBuilder: (_, __, ___) => SizedBox(
                  height: 200,
                  child: Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: Colors.grey.shade400, size: 40),
                  ),
                ),
              );

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    color: Colors.black,
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: img(),
                    ),
                  ),
                ),
                Positioned(
                  top: -14, right: -14,
                  child: GestureDetector(
                    onTap: () => Navigator.of(dialogContext).pop(),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close_rounded, size: 18, color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadPendingEvidence() async {
    for (final entry in _evidenceFiles.entries) {
      final qId = entry.key;
      if (_evidenceUrls.containsKey(qId)) continue;
      final file = entry.value;
      try {
        final bytes = await file.readAsBytes();
        final fileName =
            'evidence_${DateTime.now().millisecondsSinceEpoch}_$qId.jpg';
        final storagePath = 'audit_evidence/$fileName';
        await _supabase.storage.from('audit-evidence').uploadBinary(
              storagePath,
              bytes,
              fileOptions:
                  const FileOptions(contentType: 'image/jpeg', upsert: true),
            );
        _evidenceUrls[qId] =
            _supabase.storage.from('audit-evidence').getPublicUrl(storagePath);
      } catch (e) {
        debugPrint('Upload evidence error for $qId: $e');
      }
    }
  }

  Future<String?> _resolveSelfieUrlForSubmit() async {
    final current = _selfieUrl;
    if (current == null || current.trim().isEmpty) return null;
    if (current.startsWith('http://') || current.startsWith('https://')) {
      return current;
    }
    try {
      final file = XFile(current);
      final bytes = await file.readAsBytes();
      final userId = _supabase.auth.currentUser?.id ?? 'unknown';
      final ts = DateTime.now().millisecondsSinceEpoch;
      final path = 'selfies/${widget.levelType}/${widget.idRef}/$userId-$ts.jpg';
      await _supabase.storage.from('audit-selfie').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
          );
      final url = _supabase.storage.from('audit-selfie').getPublicUrl(path);
      if (mounted) setState(() => _selfieUrl = url);
      return url;
    } catch (e) {
      debugPrint('Error uploading selfie at submit: $e');
      return null;
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

      final resolvedSelfieUrl = await _resolveSelfieUrlForSubmit();

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
            'selfie_url': resolvedSelfieUrl,
            'is_finalized': false,
          })
          .select('id_result')
          .single();

      final idResult = resultRow['id_result'].toString();

      await _uploadPendingEvidence();

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

      if (widget.idSchedule != null) {
        await _supabase
            .from('audit_schedule')
            .update({'status': 'done'})
            .eq('id_schedule', widget.idSchedule!);
      }

      await _grantAuditSubmitPoin(userId: userId, score: score, idResult: idResult);

      await _notifyPic(idResult, score);

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
      final nameCol = 'nama_${widget.levelType}';
      final idCol = 'id_${widget.levelType}';
      final levelRow = await _supabase
          .from(widget.levelType)
          .select('id_pic, $nameCol')
          .eq(idCol, widget.idRef)
          .maybeSingle();

      final picId = levelRow?['id_pic']?.toString();
      if (picId == null) return;

      final picData = await _supabase
          .from('User')
          .select('fcm_token')
          .eq('id_user', picId)
          .maybeSingle();

      final fcmToken = picData?['fcm_token']?.toString();
      if (fcmToken == null || fcmToken.trim().isEmpty) return;

      final bool isPerfect = !_answers.values.any((ans) => ans == false);

      final String notifTitle;
      final String notifBody;

      if (isPerfect) {
        notifTitle = widget.lang == 'EN'
            ? '🏆 Perfect Audit Result!'
            : widget.lang == 'ZH'
                ? '🏆 完美审计结果！'
                : '🏆 Hasil Audit Sempurna!';
        notifBody = widget.lang == 'EN'
            ? '${widget.locationName} scored ${score.toStringAsFixed(0)}% — All items passed! Bonus points have been added.'
            : widget.lang == 'ZH'
                ? '${widget.locationName} 得分 ${score.toStringAsFixed(0)}% — 全部通过！已添加奖励积分。'
                : '${widget.locationName} meraih ${score.toStringAsFixed(0)}% — Semua item lulus! Poin bonus telah ditambahkan.';
      } else {
        notifTitle = widget.lang == 'EN'
            ? '📋 Audit Result — Action Required'
            : widget.lang == 'ZH'
                ? '📋 审计结果 — 需要改进'
                : '📋 Hasil Audit — Perlu Perbaikan';
        notifBody = widget.lang == 'EN'
            ? '${widget.locationName} scored ${score.toStringAsFixed(0)}%. Some items need corrective action. Please reply in the Audit tab.'
            : widget.lang == 'ZH'
                ? '${widget.locationName} 得分 ${score.toStringAsFixed(0)}%。部分项目需要整改，请在审计标签中回复。'
                : '${widget.locationName} meraih ${score.toStringAsFixed(0)}%. Ada item yang perlu diperbaiki. Silakan balas di tab Audit.';
      }

      await _supabase.functions.invoke(
        'send-fcm-v1',
        body: {
          'token': fcmToken.trim(),
          'title': notifTitle,
          'body': notifBody,
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'route': 'audit_notif',
            'id_result': idResult,
          },
        },
      );
    } catch (e) {
      debugPrint('_notifyPic error: $e');
    }
  }

  Future<void> _grantAuditSubmitPoin({
    required String userId,
    required double score,
    required String idResult,
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
        'id_result':      idResult,
      });
    } catch (e) {
      debugPrint('Error granting audit submit poin: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _grantBonusPoin({
    required String userId,
    required String idResult,
  }) async {
    final List<Map<String, dynamic>> granted = [];
    try {
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

      final Map<String, List<bool>> temaAnswers = {};
      for (final q in _questions) {
        final id  = q['id_question'].toString();
        final ans = _answers[id];
        if (ans == null) continue;
        final temaId = q['id_tema']?.toString() ?? 'no_tema';
        temaAnswers.putIfAbsent(temaId, () => []).add(ans);
      }

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

      bool allTema100 = temaAnswers.isNotEmpty;
      final List<Map<String, dynamic>> logEntries = [];

      for (final entry in temaAnswers.entries) {
        final temaId  = entry.key;
        final answers = entry.value;
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
            'id_result':      idResult,
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
          'id_result':      idResult,
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

    IconData tierIcon;
    if (score >= 80) {
      tierIcon = Icons.emoji_events_rounded;
    } else if (score >= 60) {
      tierIcon = Icons.thumb_up_rounded;
    } else {
      tierIcon = Icons.report_problem_rounded;
    }

    final hasNoAnswer = _answers.values.any((v) => v == false);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        Future.delayed(const Duration(seconds: 5), () {
          try {
            if (Navigator.of(dialogContext).canPop()) {
              Navigator.of(dialogContext).pop();
            }
          } catch (_) {
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 92, height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withValues(alpha: 0.16),
                              color.withValues(alpha: 0.06),
                            ],
                          ),
                          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            '${score.toStringAsFixed(0)}%',
                            style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: color),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -4, bottom: -4,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                          child: Icon(tierIcon, size: 15, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _t('Audit Completed!', 'Audit Selesai!', '审计完成！'),
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _textMain),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Icon(_locationLevelIcon, size: 13, color: _locationLevelColor),
                      Text(
                        widget.locationName,
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600, color: _locationLevelColor),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(label,
                            style: GoogleFonts.poppins(
                                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  Container(height: 1, color: _divider),
                  const SizedBox(height: 18),

                  if (hasNoAnswer)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _amber.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _amber.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(Icons.hourglass_top_rounded,
                                size: 15, color: Color(0xFFF59E0B)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _t('Points Pending', 'Poin Tertunda', '积分待定'),
                                  style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFB45309)),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _t(
                                    'Some findings are pending. Bonus points will be granted after PIC replies and you confirm all fixes.',
                                    'Masih ada temuan yang belum selesai. Poin bonus akan diberikan setelah PIC membalas dan Anda mengkonfirmasi semua perbaikan.',
                                    '存在待处理发现。PIC回复并您确认所有修复后将授予奖励积分。',
                                  ),
                                  style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF92400E),
                                      height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _green.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(Icons.celebration_rounded,
                                size: 15, color: Color(0xFF10B981)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _t('All Items Passed', 'Semua Item Lulus', '全部通过'),
                                  style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF047857)),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _t(
                                    'Great job! Bonus points have been granted to the PIC right away.',
                                    'Kerja bagus! Poin bonus langsung diberikan ke PIC.',
                                    '干得好！奖励积分已立即授予PIC。',
                                  ),
                                  style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF065F46),
                                      height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                          _t('Done', 'Selesai', '完成'),
                          style: GoogleFonts.poppins(
                              fontSize: 14.5, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
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
        centerTitle: true,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1D72F3), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [SizedBox(width: 48)],
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _t('Audit Form', 'Formulir Audit', '审计表单'),
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1D72F3)),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_locationLevelIcon, color: _locationLevelColor, size: 13),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    widget.locationName,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _locationLevelColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _loading
          ? _buildLoadingShimmer()
          : _questions.isEmpty
              ? Center(
                  child: Text(
                    _t('No active questions found.', 'Belum ada pertanyaan aktif.', '尚无活动问题。'),
                    style: GoogleFonts.poppins(fontSize: 13, color: _textSub),
                  ),
                )
              : Column(
                  children: [
                    // SELFIE EVIDENCE BANNER
                    if (_selfieUrl != null)
                      _SelfieEvidenceBanner(
                        selfieUrl: _selfieUrl!,
                        lang: widget.lang,
                        locationName: widget.locationName,
                        levelType: widget.levelType,
                        idRef: widget.idRef,
                        onRetake: (newUrl) => setState(() => _selfieUrl = newUrl),
                      ),

                    // PROGRESS BAR & SCORE
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
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black),
                              ),
                              Text(
                                '${_score.toStringAsFixed(0)}%',
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: _scoreColor(_score)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(_scoreColor(_score)),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // SCROLLABLE CONTENT
                    Expanded(
                      child: ListView(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        children: _buildContent(),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _loading || _questions.isEmpty
          ? null
          : Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ADDITIONAL NOTES
                  TextField(
                    controller: _finalNoteCtrl,
                    maxLines: 2,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: _t('Additional notes (optional)…', 'Catatan tambahan (opsional)…', '补充备注（可选）…'),
                      hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                      filled: true,
                      fillColor: _surface,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _divider)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _divider)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1D72F3), width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!_allAnswered)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _amber.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _amber.withValues(alpha: 0.35), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: _amber.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.info_outline_rounded, size: 14, color: _amber),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _t(
                                'Answer all questions to submit.',
                                'Jawab semua pertanyaan untuk mengirim.',
                                '回答所有问题后即可提交。',
                              ),
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFB45309)),
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

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: 4,
      itemBuilder: (_, __) => _buildShimmerQuestionCard(),
    );
  }

  Widget _buildShimmerQuestionCard() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8F1FE),
      highlightColor: const Color(0xFFF6FAFF),
      period: const Duration(milliseconds: 1200),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent() {
    final List<Widget> widgets = [];

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

    bool previousTemaDone = true;

    for (final tema in _temas) {
      final temaId = tema['id_tema'].toString();
      final temaQs = grouped[temaId];
      if (temaQs == null || temaQs.isEmpty) continue;

      if (!previousTemaDone) break;

      widgets.add(_buildTemaHeader(tema, temaQs));
      widgets.addAll(_buildTemaQuestions(temaQs));
      widgets.add(const SizedBox(height: 8));

      final temaAllDone = temaQs.every(
        (q) => _isQuestionComplete(q['id_question'].toString()),
      );
      previousTemaDone = temaAllDone;
    }

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
        color: isDone ? _green.withValues(alpha:0.08) : _primary.withValues(alpha:0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDone ? _green.withValues(alpha:0.3) : _primary.withValues(alpha:0.2)),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (isDone ? _green : _primary).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$answered/${qs.length}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDone ? _green : _primary,
              ),
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
        color: _textSub.withValues(alpha:0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _textSub.withValues(alpha:0.2)),
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
    final evidenceFile = _evidenceFiles[id];
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
                : (isYes ? _green : _red).withValues(alpha:0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QUESTION HEADER
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
                          : (isYes ? _green : _red).withValues(alpha:0.12),
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
                      style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF1D72F3)),
                    ),
                  ),
                ],
              ),
            ),

            // YES / NO BUTTONS
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
                          color: isYes ? _green.withValues(alpha:0.12) : Colors.white,
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
                          color: isNo ? _red.withValues(alpha:0.10) : Colors.white,
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

            // EVIDENCE SECTION IF NO
            if (isNo) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _red.withValues(alpha:0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _red.withValues(alpha:0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.camera_alt_rounded, size: 14, color: Color(0xFF1D72F3)),
                      const SizedBox(width: 5),
                      Text(
                        _t('Evidence Photo', 'Foto Bukti', '证据照片'),
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1D72F3)),
                      ),
                      const SizedBox(width: 3),
                      const Text(
                        '*',
                        style: TextStyle(color: _red, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    // UPLOAD PHOTO
                    if (evidenceFile == null)
                      GestureDetector(
                        onTap: () => _captureEvidence(id, _questionText(q)),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _red.withValues(alpha:0.35)),
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
                        GestureDetector(
                          onTap: () => _showEvidencePreview(evidenceFile),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: kIsWeb
                                ? Image.network(
                                    evidenceFile.path,
                                    width: double.infinity,
                                    height: 140,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 140,
                                      color: Colors.grey.shade100,
                                      child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                                    ),
                                  )
                                : Image.file(
                                    File(evidenceFile.path),
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
                        ),
                        Positioned(
                          left: 6, bottom: 6,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha:0.55),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 13),
                                  const SizedBox(width: 3),
                                  Text(
                                    _t('View', 'Lihat', '查看'),
                                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
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
                                color: Colors.black.withValues(alpha:0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.edit_note_rounded, size: 15, color: Color(0xFF1D72F3)),
                      const SizedBox(width: 5),
                      Text(_t('Auditor Notes', 'Catatan Auditor', '审核员备注'),
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1D72F3))),
                      const SizedBox(width: 3),
                      const Text(
                        '*',
                        style: TextStyle(color: _red, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ]),
                    const SizedBox(height: 5),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 3,
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
                      onChanged: (_) {
                        setState(() {});
                        _requestAutoScroll(id, delayMs: 450);
                      },
                      decoration: InputDecoration(
                        hintText: _t('Describe the issue found…', 'Jelaskan masalah yang ditemukan…', '描述发现的问题…'),
                        hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _divider)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _divider)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1D72F3), width: 1.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

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

class _SelfieEvidenceBanner extends StatelessWidget {
  final String selfieUrl;
  final String lang;
  final String locationName;
  final String levelType;
  final String idRef;
  final ValueChanged<String> onRetake;

  const _SelfieEvidenceBanner({
    required this.selfieUrl,
    required this.lang,
    required this.locationName,
    required this.levelType,
    required this.idRef,
    required this.onRetake,
  });

  String _t(String en, String id, String zh) {
    if (lang == 'EN') return en;
    if (lang == 'ZH') return zh;
    return id;
  }

  bool get _isLocalSelfiePath =>
      !selfieUrl.startsWith('http://') && !selfieUrl.startsWith('https://');

  Widget _buildSelfieThumbnail(Color teal) {
    final fallback = Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        color: teal.withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.broken_image_outlined, color: teal, size: 24),
    );
    if (!kIsWeb && _isLocalSelfiePath) {
      return Image.file(
        File(selfieUrl),
        width: 52, height: 52, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    return Image.network(
      selfieUrl,
      width: 52, height: 52, fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF14B8A6);
    const tealBg = Color(0xFFE6FAF8);
    return GestureDetector(
      onTap: () => showAuditSelfiePopup(
        context,
        selfieUrl: selfieUrl,
        lang: lang,
        locationName: locationName,
        levelType: levelType,
        idRef: idRef,
        onRetake: onRetake,
      ),
      child: Container(
        width: double.infinity,
        color: tealBg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildSelfieThumbnail(teal),
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
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF0F766E)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: teal, size: 20),
          ],
        ),
      ),
    );
  }
}