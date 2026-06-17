import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';

/// Full-screen detail hasil audit — tema, pertanyaan, jawaban, skor, bonus poin.
class AuditResultDetailScreen extends StatefulWidget {
  final String lang;
  final String idResult;
  final String locationName;
  final String levelType;

  const AuditResultDetailScreen({
    super.key,
    required this.lang,
    required this.idResult,
    required this.locationName,
    required this.levelType,
  });

  @override
  State<AuditResultDetailScreen> createState() =>
      _AuditResultDetailScreenState();
}

class _AuditResultDetailScreenState extends State<AuditResultDetailScreen> {
  final _supabase = Supabase.instance.client;

  Map<String, dynamic>? _result;
  List<Map<String, dynamic>> _answers = [];
  List<Map<String, dynamic>> _poinLogs = [];
  bool _loading = true;

  static const _primary = Color(0xFF8B5CF6);
  static const _green = Color(0xFF10B981);
  static const _red = Color(0xFFEF4444);
  static const _amber = Color(0xFFF59E0B);
  static const _textMain = Color(0xFF1E3A8A);
  static const _textSub = Color(0xFF64748B);

  String _t(String id, String en, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      // Fetch result + auditor
      final resultRow = await _supabase
          .from('audit_result')
          .select(
            'id_result, level_type, id_ref, tanggal_audit, nilai_audit, '
            'nilai_final, is_finalized, catatan_audit, selfie_url, created_at, '
            'Auditor:User!fk_audit_result_auditor(nama, gambar_user)',
          )
          .eq('id_result', widget.idResult)
          .single();

      // Fetch semua jawaban + tema + reply
      final answerRows = await _supabase
          .from('audit_answer')
          .select(
            'id_answer, jawaban, catatan, gambar_jawaban, created_at, '
            'Question:audit_question('
            '  pertanyaan, pertanyaan_en, pertanyaan_zh, urutan, '
            '  Tema:audit_tema(id_tema, nama_tema_id, nama_tema_en, nama_tema_zh, urutan)'
            '), '
            'Replies:audit_answer_reply('
            '  id_reply, catatan_reply, gambar_reply, is_confirmed, created_at, '
            '  confirmed_at, catatan_konfirmasi, gambar_konfirmasi, '
            '  PIC:User!fk_reply_pic(id_user, nama, gambar_user)'
            ')',
          )
          .eq('id_result', widget.idResult)
          .order('created_at');

      // Fetch poin log terkait result ini (auditor & PIC)
      final auditorId =
          (resultRow['Auditor'] as Map?)?['id_user']?.toString() ?? '';
      final picRow = await _supabase
          .from(widget.levelType)
          .select('id_pic')
          .eq('id_${widget.levelType}', resultRow['id_ref'].toString())
          .maybeSingle();
      final picId = picRow?['id_pic']?.toString() ?? '';

      List<Map<String, dynamic>> logs = [];
      // Auditor logs
      if (auditorId.isNotEmpty) {
        final al = await _supabase
            .from('log_poin')
            .select('id_user, poin, deskripsi, tipe_aktivitas, created_at')
            .eq('id_user', auditorId)
            .inFilter('tipe_aktivitas', ['audit_submit', 'audit_bonus_tema', 'audit_bonus_full'])
            .gte('created_at', resultRow['created_at'].toString())
            .order('created_at')
            .limit(10);
        for (final l in al as List) {
          final m = Map<String, dynamic>.from(l as Map);
          m['_for'] = 'auditor';
          logs.add(m);
        }
      }
      // PIC logs
      if (picId.isNotEmpty) {
        final pl = await _supabase
            .from('log_poin')
            .select('id_user, poin, deskripsi, tipe_aktivitas, created_at')
            .eq('id_user', picId)
            .inFilter('tipe_aktivitas', [
              'audit_bonus_tema', 'audit_bonus_full', 'audit_bonus_pic'
            ])
            .gte('created_at', resultRow['created_at'].toString())
            .order('created_at')
            .limit(10);
        for (final l in pl as List) {
          final m = Map<String, dynamic>.from(l as Map);
          m['_for'] = 'pic';
          logs.add(m);
        }
      }

      if (mounted) {
        setState(() {
          _result = Map<String, dynamic>.from(resultRow as Map);
          _answers = List<Map<String, dynamic>>.from(answerRows as List);
          _poinLogs = logs;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('AuditResultDetail fetch error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _scoreColor(double? s) {
    if (s == null) return _textSub;
    if (s >= 80) return _green;
    if (s >= 60) return _amber;
    return _red;
  }

  String _questionText(Map<String, dynamic>? q) {
    if (q == null) return '-';
    if (widget.lang == 'EN') return q['pertanyaan_en']?.toString() ?? q['pertanyaan']?.toString() ?? '-';
    if (widget.lang == 'ZH') return q['pertanyaan_zh']?.toString() ?? q['pertanyaan']?.toString() ?? '-';
    return q['pertanyaan']?.toString() ?? '-';
  }

  String _temaLabel(Map<String, dynamic>? t) {
    if (t == null) return _t('Lainnya', 'Other', '其他');
    if (widget.lang == 'EN') return t['nama_tema_en']?.toString() ?? '-';
    if (widget.lang == 'ZH') return t['nama_tema_zh']?.toString() ?? '-';
    return t['nama_tema_id']?.toString() ?? '-';
  }

  /// Kelompokkan jawaban per tema, urutkan sesuai urutan tema
  Map<String, List<Map<String, dynamic>>> _groupByTema() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    final Map<String, int> temaOrder = {};

    for (final ans in _answers) {
      final q = ans['Question'] as Map<String, dynamic>?;
      final tema = q?['Tema'] as Map<String, dynamic>?;
      final temaKey = tema?['id_tema']?.toString() ?? '__no_tema__';
      temaOrder[temaKey] = (tema?['urutan'] as int?) ?? 9999;
      grouped.putIfAbsent(temaKey, () => []).add(ans);
    }

    // Sort per tema urutan
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => (temaOrder[a] ?? 9999).compareTo(temaOrder[b] ?? 9999));

    return {for (final k in sortedKeys) k: grouped[k]!};
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
              color: _primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('Detail Audit', 'Audit Detail', '审计详情'),
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _textMain),
            ),
            Text(widget.locationName,
                style: GoogleFonts.poppins(fontSize: 11, color: _textSub)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _primary),
            onPressed: _fetch,
          ),
        ],
      ),
      body: _loading
          ? _buildShimmer()
          : _result == null
              ? Center(
                  child: Text(_t('Data tidak ditemukan', 'Data not found', '数据未找到'),
                      style: GoogleFonts.poppins(color: _textSub)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final score =
        double.tryParse(_result!['nilai_audit']?.toString() ?? '');
    final scoreFinal =
        double.tryParse(_result!['nilai_final']?.toString() ?? '');
    final isFinalized = _result!['is_finalized'] == true;
    final displayScore = isFinalized ? scoreFinal : score;
    final scoreColor = _scoreColor(displayScore);
    final auditorData = _result!['Auditor'] as Map<String, dynamic>?;
    final auditorName = auditorData?['nama']?.toString() ?? '-';
    final auditorAvatar = auditorData?['gambar_user']?.toString();
    final tanggal = _result!['tanggal_audit']?.toString() ?? '-';
    final catatan = _result!['catatan_audit']?.toString() ?? '';
    final selfieUrl = _result!['selfie_url']?.toString() ?? '';
    final grouped = _groupByTema();

    // Skor per tema
    final Map<String, double> temaScores = {};
    for (final entry in grouped.entries) {
      final answers = entry.value;
      final yes = answers.where((a) => a['jawaban'] == true).length;
      temaScores[entry.key] = answers.isEmpty ? 0 : (yes / answers.length) * 100;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // ── Header card ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scoreColor.withOpacity(0.12), scoreColor.withOpacity(0.04)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scoreColor.withOpacity(0.35), width: 1.5),
          ),
          child: Column(
            children: [
              Row(children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                      color: scoreColor.withOpacity(0.15), shape: BoxShape.circle),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayScore != null
                              ? '${displayScore.toStringAsFixed(0)}%'
                              : '-',
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.w900, color: scoreColor),
                        ),
                        if (isFinalized)
                          Text(_t('Final', 'Final', '最终'),
                              style: GoogleFonts.poppins(fontSize: 9, color: scoreColor)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.locationName,
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w700, color: _textMain),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(children: [
                        if (auditorAvatar != null && auditorAvatar.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(auditorAvatar,
                                width: 20, height: 20, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                          ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            auditorName,
                            style: GoogleFonts.poppins(fontSize: 12, color: _textSub),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 2),
                      Text(tanggal,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey.shade400)),
                    ],
                  ),
                ),
              ]),

              // Selfie
              if (selfieUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(selfieUrl,
                      width: double.infinity, height: 120, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                ),
              ],

              // Catatan
              if (catatan.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(catatan,
                      style: GoogleFonts.poppins(fontSize: 12, color: _textSub)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Skor per tema ──
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.bar_chart_rounded, size: 16, color: _primary),
                const SizedBox(width: 6),
                Text(_t('Skor per Tema', 'Score per Theme', '各主题分数'),
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w700, color: _textMain)),
              ]),
              const SizedBox(height: 12),
              ...grouped.entries.map((entry) {
                final temaId = entry.key;
                final answers = entry.value;
                final tema = (answers.first['Question'] as Map?)?['Tema'] as Map<String, dynamic>?;
                final temaName = temaId == '__no_tema__'
                    ? _t('Lainnya', 'Other', '其他')
                    : _temaLabel(tema);
                final temaScore = temaScores[temaId] ?? 0;
                final temaColor = _scoreColor(temaScore);
                final yes = answers.where((a) => a['jawaban'] == true).length;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(temaName,
                              style: GoogleFonts.poppins(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: _textMain)),
                        ),
                        Text('$yes/${answers.length}  ${temaScore.toStringAsFixed(0)}%',
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w700, color: temaColor)),
                      ]),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: temaScore / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(temaColor),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Bonus poin ──
        if (_poinLogs.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _green.withOpacity(0.08),
                _primary.withOpacity(0.05),
              ]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _green.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.emoji_events_rounded, color: _green, size: 16),
                  const SizedBox(width: 6),
                  Text(_t('Distribusi Poin', 'Points Distribution', '积分分配'),
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w700, color: _green)),
                ]),
                const SizedBox(height: 10),
                ...(_poinLogs.map((log) {
                  final p = (log['poin'] as num?)?.toInt() ?? 0;
                  final isPos = p >= 0;
                  final forRole = log['_for']?.toString() ?? '';
                  final tipe = log['tipe_aktivitas']?.toString() ?? '';
                  Color roleColor = forRole == 'auditor' ? _primary : _green;

                  String roleLabel;
                  if (forRole == 'auditor') {
                    roleLabel = _t('Auditor', 'Auditor', '审计员');
                  } else {
                    roleLabel = 'PIC';
                  }

                  String tipeLabel;
                  switch (tipe) {
                    case 'audit_submit':
                      tipeLabel = _t('Submit Audit', 'Submit Audit', '提交审计');
                      break;
                    case 'audit_bonus_tema':
                      tipeLabel = _t('Bonus Tema', 'Theme Bonus', '主题奖励');
                      break;
                    case 'audit_bonus_full':
                      tipeLabel = _t('Bonus Sempurna', 'Perfect Bonus', '完美奖励');
                      break;
                    case 'audit_bonus_pic':
                      tipeLabel = _t('Bonus PIC', 'PIC Bonus', 'PIC奖励');
                      break;
                    default:
                      tipeLabel = tipe;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(roleLabel,
                            style: GoogleFonts.poppins(
                                fontSize: 9, fontWeight: FontWeight.w700, color: roleColor)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isPos
                              ? _green.withOpacity(0.12)
                              : _red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(isPos ? '+$p' : '$p',
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w800,
                                color: isPos ? _green : _red)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tipeLabel,
                                style: GoogleFonts.poppins(
                                    fontSize: 10, fontWeight: FontWeight.w600, color: _textSub)),
                            Text(log['deskripsi']?.toString() ?? '',
                                style: GoogleFonts.poppins(fontSize: 10, color: _textSub),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ]),
                  );
                })),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Jawaban per tema ──
        Text(
          _t('Detail Jawaban', 'Answer Details', '回答详情'),
          style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w700, color: _textMain),
        ),
        const SizedBox(height: 10),

        ...grouped.entries.map((entry) {
          final temaId = entry.key;
          final answers = entry.value;
          final tema = (answers.first['Question'] as Map?)?['Tema'] as Map<String, dynamic>?;
          final temaName = temaId == '__no_tema__'
              ? _t('Lainnya', 'Other', '其他')
              : _temaLabel(tema);
          final yes = answers.where((a) => a['jawaban'] == true).length;
          final is100 = yes == answers.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tema header
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: is100
                      ? _green.withOpacity(0.08)
                      : _primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: is100
                        ? _green.withOpacity(0.3)
                        : _primary.withOpacity(0.2),
                  ),
                ),
                child: Row(children: [
                  Icon(
                    is100 ? Icons.check_circle_rounded : Icons.topic_outlined,
                    size: 16,
                    color: is100 ? _green : _primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(temaName,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: is100 ? _green : _primary)),
                  ),
                  Text('$yes/${answers.length}',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: is100 ? _green : _textSub)),
                ]),
              ),

              // Pertanyaan
              ...answers.asMap().entries.map((e) {
                final idx = e.key;
                final ans = e.value;
                final q = ans['Question'] as Map<String, dynamic>?;
                final isYes = ans['jawaban'] == true;
                final catatan = ans['catatan']?.toString() ?? '';
                final gambar = ans['gambar_jawaban']?.toString() ?? '';
                final replies = (ans['Replies'] as List?)
                    ?.map((r) => Map<String, dynamic>.from(r as Map))
                    .toList() ?? [];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isYes
                          ? _green.withOpacity(0.35)
                          : _red.withOpacity(0.35),
                      width: 1.2,
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
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24, height: 24,
                              decoration: BoxDecoration(
                                color: isYes
                                    ? _green.withOpacity(0.12)
                                    : _red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isYes ? Icons.check_rounded : Icons.close_rounded,
                                size: 14,
                                color: isYes ? _green : _red,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _questionText(q),
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _textMain),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Evidence jika No
                      if (!isYes) ...[
                        if (gambar.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(gambar,
                                  width: double.infinity,
                                  height: 160,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink()),
                            ),
                          ),
                        if (catatan.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _red.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _red.withOpacity(0.2)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.notes_rounded, size: 13, color: _red),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(catatan,
                                        style: GoogleFonts.poppins(
                                            fontSize: 11.5, color: _textSub)),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Replies thread
                        if (replies.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  const Icon(Icons.forum_rounded, size: 12, color: _primary),
                                  const SizedBox(width: 5),
                                  Text(
                                    _t('Tindak Lanjut', 'Follow-up', '跟进记录'),
                                    style: GoogleFonts.poppins(
                                        fontSize: 11, fontWeight: FontWeight.w600, color: _primary),
                                  ),
                                ]),
                                const SizedBox(height: 6),
                                ...replies.map((reply) {
                                  final picData = reply['PIC'] as Map<String, dynamic>?;
                                  final picName = picData?['nama']?.toString() ?? '-';
                                  final confirmed = reply['is_confirmed'] == true;
                                  final replyGambar = reply['gambar_reply']?.toString() ?? '';
                                  final replyCatatan = reply['catatan_reply']?.toString() ?? '';
                                  final konfCatatan = reply['catatan_konfirmasi']?.toString() ?? '';
                                  final konfGambar = reply['gambar_konfirmasi']?.toString() ?? '';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: confirmed
                                          ? _green.withOpacity(0.07)
                                          : const Color(0xFF6366F1).withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: confirmed
                                            ? _green.withOpacity(0.3)
                                            : const Color(0xFF6366F1).withOpacity(0.2),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Icon(
                                            confirmed ? Icons.verified_rounded : Icons.reply_rounded,
                                            size: 12,
                                            color: confirmed ? _green : const Color(0xFF6366F1),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(picName,
                                              style: GoogleFonts.poppins(
                                                  fontSize: 11, fontWeight: FontWeight.w600,
                                                  color: confirmed ? _green : const Color(0xFF6366F1))),
                                          if (confirmed) ...[
                                            const SizedBox(width: 4),
                                            Text('✓ ${_t('Dikonfirmasi', 'Confirmed', '已确认')}',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 10, color: _green)),
                                          ],
                                        ]),
                                        if (replyCatatan.isNotEmpty) ...[
                                          const SizedBox(height: 5),
                                          Text(replyCatatan,
                                              style: GoogleFonts.poppins(
                                                  fontSize: 11, color: _textMain)),
                                        ],
                                        if (replyGambar.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(replyGambar,
                                                height: 100, width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                                          ),
                                        ],
                                        // Konfirmasi detail
                                        if (confirmed && konfCatatan.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: _green.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _t('Catatan Konfirmasi', 'Confirmation Note', '确认备注'),
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 10, fontWeight: FontWeight.w600, color: _green),
                                                ),
                                                Text(konfCatatan,
                                                    style: GoogleFonts.poppins(fontSize: 11, color: _textMain)),
                                                if (konfGambar.isNotEmpty) ...[
                                                  const SizedBox(height: 5),
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: Image.network(konfGambar,
                                                        height: 80, width: double.infinity,
                                                        fit: BoxFit.cover),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ],

                      if (isYes)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                          child: Row(children: [
                            const Icon(Icons.check_circle_rounded, size: 13, color: _green),
                            const SizedBox(width: 5),
                            Text(_t('Terjawab ✓', 'Answered ✓', '已回答 ✓'),
                                style: GoogleFonts.poppins(fontSize: 10, color: _green)),
                          ]),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildShimmer() => Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (_, __) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 100,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
}