import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';

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

  static const _lokasiColor = Color(0xFF10B981);
  static const _unitColor = Color(0xFF6366F1);
  static const _subunitColor = Color(0xFFFBBF24);
  static const _areaColor = Color(0xFFF472B6);

  final Set<String> _collapsedTemas = {};

  Color get _levelColor {
    switch (widget.levelType) {
      case 'lokasi': return _lokasiColor;
      case 'unit': return _unitColor;
      case 'subunit': return _subunitColor;
      case 'area': return _areaColor;
      default: return _primary;
    }
  }

  IconData get _levelIcon {
    switch (widget.levelType) {
      case 'lokasi': return Icons.location_city_rounded;
      case 'unit': return Icons.business_rounded;
      case 'subunit': return Icons.layers_rounded;
      case 'area': return Icons.place_rounded;
      default: return Icons.location_on_rounded;
    }
  }

  Widget _buildAuditorAvatar(String? url, {double size = 20}) {
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          url,
          width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultAuditorAvatar(size),
        ),
      );
    }
    return _defaultAuditorAvatar(size);
  }

  Widget _defaultAuditorAvatar(double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: _accentBlue.withValues(alpha: 0.12)),
      child: Icon(Icons.person_rounded, size: size * 0.65, color: _accentBlue),
    );
  }

  static const _accentBlue = Color(0xFF1D72F3);

  static const List<String> _bulanID = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];
  static const List<String> _bulanEN = ['January','February','March','April','May','June','July','August','September','October','November','December'];
  static const List<String> _bulanZH = ['1月','2月','3月','4月','5月','6月','7月','8月','9月','10月','11月','12月'];

  String _formatTanggalAudit(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    if (widget.lang == 'EN') return '${dt.day} ${_bulanEN[dt.month - 1]} ${dt.year}';
    if (widget.lang == 'ZH') return '${dt.year}年${_bulanZH[dt.month - 1]}${dt.day}日';
    return '${dt.day} ${_bulanID[dt.month - 1]} ${dt.year}';
  }

  void _openImageViewer(String url) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => _AuditFullImageViewer(imageUrl: url),
      ),
    );
  }

  Widget _zoomBadge({double size = 22, double iconSize = 13}) {
    return Positioned(
      right: 8,
      bottom: 8,
      child: IgnorePointer(
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.fullscreen_rounded, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }

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
      final resultRow = await _supabase
          .from('audit_result')
          .select(
            'id_result, level_type, id_ref, tanggal_audit, nilai_audit, '
            'nilai_final, is_finalized, catatan_audit, selfie_url, created_at, '
            'Auditor:User!fk_audit_result_auditor(nama, gambar_user)',
          )
          .eq('id_result', widget.idResult)
          .single();

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
            .inFilter('tipe_aktivitas', ['audit_submit'])
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
            .inFilter('tipe_aktivitas', ['audit_bonus_tema', 'audit_bonus_full'])
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
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: _levelColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('Detail Hasil Audit', 'Audit Result Detail', '审计结果详情'),
          style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w700, color: _levelColor),
        ),
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
    final scoreColor = isFinalized ? const Color(0xFFF59E0B) : _scoreColor(displayScore);
    final needsFix = score != null && !isFinalized && score < 100;
    final auditorData = _result!['Auditor'] as Map<String, dynamic>?;
    final auditorName = auditorData?['nama']?.toString() ?? '-';
    final auditorAvatar = auditorData?['gambar_user']?.toString();
    final tanggal = _result!['tanggal_audit']?.toString() ?? '-';
    final catatan = _result!['catatan_audit']?.toString() ?? '';
    final selfieUrl = _result!['selfie_url']?.toString() ?? '';
    final grouped = _groupByTema();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // HEADER CARD
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scoreColor.withValues(alpha:0.35), width: 1.5),
          ),
          child: Column(
            children: [
              Row(children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                      color: needsFix
                          ? _amber.withValues(alpha:0.10)
                          : scoreColor.withValues(alpha:0.15),
                      shape: BoxShape.circle),
                  child: Center(
                    child: needsFix
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.build_rounded, size: 18, color: _amber),
                              const SizedBox(height: 2),
                              Text(_t('Perlu\nPerbaikan', 'Need\nFix', '需要\n修复'),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                      fontSize: 7.5, fontWeight: FontWeight.w700, color: _amber)),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                displayScore != null
                                    ? '${displayScore.toStringAsFixed(0)}%'
                                    : '-',
                                style: GoogleFonts.poppins(
                                    fontSize: 18, fontWeight: FontWeight.w900, color: scoreColor),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(_levelIcon, size: 15, color: _levelColor),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            widget.locationName,
                            style: GoogleFonts.poppins(
                                fontSize: 15, fontWeight: FontWeight.w700, color: _levelColor),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.badge_rounded, size: 12, color: _accentBlue),
                        const SizedBox(width: 4),
                        Text('${_t('Auditor', 'Auditor', '审计员')} :',
                            style: GoogleFonts.poppins(
                                fontSize: 11, fontWeight: FontWeight.w700, color: _accentBlue)),
                        const SizedBox(width: 6),
                        _buildAuditorAvatar(auditorAvatar, size: 20),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            auditorName,
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 5),
                      Row(children: [
                        Icon(Icons.event_rounded, size: 12, color: _textSub),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            tanggal.isNotEmpty && tanggal != '-'
                                ? _formatTanggalAudit(tanggal)
                                : '-',
                            style: GoogleFonts.poppins(
                                fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ]),

              // SELFIE
              if (selfieUrl.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(children: [
                  const Icon(Icons.camera_alt_rounded, size: 13, color: _accentBlue),
                  const SizedBox(width: 5),
                  Text(_t('Bukti Selfie Audit', 'Audit Selfie Proof', '审计自拍证明'),
                      style: GoogleFonts.poppins(
                          fontSize: 11.5, fontWeight: FontWeight.w700, color: _accentBlue)),
                ]),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _openImageViewer(selfieUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.network(selfieUrl,
                            width: double.infinity, height: 220, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                        _zoomBadge(size: 26, iconSize: 15),
                      ],
                    ),
                  ),
                ),
              ],

              // NOTES
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

        if (_poinLogs.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _green.withValues(alpha:0.08),
                _primary.withValues(alpha:0.05),
              ]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _green.withValues(alpha:0.3)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha:0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: roleColor.withValues(alpha:0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              forRole == 'auditor' ? Icons.badge_rounded : Icons.verified_user_rounded,
                              size: 11, color: roleColor,
                            ),
                            const SizedBox(width: 4),
                            Text(roleLabel,
                                style: GoogleFonts.poppins(
                                    fontSize: 9.5, fontWeight: FontWeight.w700, color: roleColor)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isPos
                              ? _green.withValues(alpha:0.12)
                              : _red.withValues(alpha:0.12),
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
                                    fontSize: 11.5, fontWeight: FontWeight.w700, color: _textMain)),
                            const SizedBox(height: 2),
                            Text(log['deskripsi']?.toString() ?? '',
                                style: GoogleFonts.poppins(
                                    fontSize: 11, fontWeight: FontWeight.w600, color: _textSub, height: 1.35),
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

        Row(children: [
          const Icon(Icons.list_alt_rounded, size: 16, color: _accentBlue),
          const SizedBox(width: 6),
          Text(
            _t('Ringkasan Jawaban', 'Answer Summary', '回答摘要'),
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w700, color: _accentBlue),
          ),
        ]),
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
          final noAnswersInTema = answers.where((a) => a['jawaban'] == false).toList();
          final allNoConfirmedInTema = noAnswersInTema.isNotEmpty &&
              noAnswersInTema.every((a) {
                final replies = (a['Replies'] as List?) ?? [];
                return replies.any((r) => r['is_confirmed'] == true);
              });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (context) {
                  final temaColor = is100
                      ? _green
                      : (allNoConfirmedInTema ? const Color(0xFFF59E0B) : _red);
                  final temaBgColor = is100
                      ? _green.withValues(alpha: 0.06)
                      : (allNoConfirmedInTema
                          ? const Color(0xFFFFF7ED)
                          : _red.withValues(alpha: 0.05));
                  final isCollapsed = _collapsedTemas.contains(temaId);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isCollapsed) {
                          _collapsedTemas.remove(temaId);
                        } else {
                          _collapsedTemas.add(temaId);
                        }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: temaBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: temaColor.withValues(alpha:0.25)),
                      ),
                      child: Row(children: [
                        Icon(
                          is100 ? Icons.check_circle_rounded : Icons.topic_outlined,
                          size: 16,
                          color: temaColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(temaName,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, fontWeight: FontWeight.w700, color: temaColor)),
                        ),
                        Text('$yes/${answers.length}',
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w700, color: temaColor)),
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          turns: isCollapsed ? 0 : 0.5,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: temaColor),
                        ),
                      ]),
                    ),
                  );
                },
              ),

              if (!_collapsedTemas.contains(temaId))
              ...answers.asMap().entries.map((e) {
                final ans = e.value;
                final q = ans['Question'] as Map<String, dynamic>?;
                final isYes = ans['jawaban'] == true;
                final catatan = ans['catatan']?.toString() ?? '';
                final gambar = ans['gambar_jawaban']?.toString() ?? '';
                final replies = (ans['Replies'] as List?)
                    ?.map((r) => Map<String, dynamic>.from(r as Map))
                    .toList() ?? [];
                final isConfirmedNo = !isYes && replies.any((r) => r['is_confirmed'] == true);
                final isGoodState = isYes || isConfirmedNo;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isYes
                        ? Colors.white
                        : (isConfirmedNo
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.05)
                            : _red.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isYes
                          ? _green.withValues(alpha:0.35)
                          : (isConfirmedNo
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                              : _red.withValues(alpha:0.35)),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha:0.03),
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
                                color: isGoodState
                                    ? _green.withValues(alpha:0.12)
                                    : _red.withValues(alpha:0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isGoodState ? Icons.check_rounded : Icons.close_rounded,
                                size: 14,
                                color: isGoodState ? _green : _red,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _questionText(q),
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _accentBlue,
                                    height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (!isYes)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (gambar.isNotEmpty) ...[
                                AspectRatio(
                                  aspectRatio: 16 / 10,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.black.withValues(alpha: 0.12), width: 1.5),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14.5),
                                      child: GestureDetector(
                                        onTap: () => _openImageViewer(gambar),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.network(gambar,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const Center(
                                                    child: Icon(Icons.image_not_supported_rounded,
                                                        color: Colors.grey, size: 40))),
                                            _zoomBadge(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (catatan.isNotEmpty) ...[
                                Row(children: [
                                  const Icon(Icons.sticky_note_2_outlined, size: 14, color: _red),
                                  const SizedBox(width: 5),
                                  Text(
                                    _t('Catatan Auditor', 'Auditor Notes', '审计员备注'),
                                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: _red),
                                  ),
                                ]),
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _red.withValues(alpha: 0.15)),
                                  ),
                                  child: Text(catatan,
                                      style: GoogleFonts.poppins(
                                          fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black)),
                                ),
                                const SizedBox(height: 12),
                              ],

                              // FIX REPLIES
                              if (replies.isNotEmpty) ...[
                                Row(children: [
                                  Icon(Icons.forum_rounded, size: 14, color: _accentBlue),
                                  const SizedBox(width: 5),
                                  Text(
                                    _t('Balasan Perbaikan', 'Fix Replies', '修复回复'),
                                    style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: _accentBlue),
                                  ),
                                ]),
                                const SizedBox(height: 10),
                                ...replies.map((reply) {
                                  final picData = reply['PIC'] as Map<String, dynamic>?;
                                  final picName = picData?['nama']?.toString() ?? '-';
                                  final picAvatar = picData?['gambar_user']?.toString();
                                  final confirmed = reply['is_confirmed'] == true;
                                  final replyGambar = reply['gambar_reply']?.toString() ?? '';
                                  final replyCatatan = reply['catatan_reply']?.toString() ?? '';
                                  final konfCatatan = reply['catatan_konfirmasi']?.toString() ?? '';
                                  final konfGambar = reply['gambar_konfirmasi']?.toString() ?? '';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _accentBlue.withValues(alpha: 0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          _buildAuditorAvatar(picAvatar, size: 22),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Row(children: [
                                              Flexible(
                                                child: Text(
                                                  picName,
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 12, fontWeight: FontWeight.w600, color: _accentBlue),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (confirmed) ...[
                                                const SizedBox(width: 6),
                                                const Icon(Icons.check_circle_rounded, size: 13, color: _green),
                                                const SizedBox(width: 3),
                                                Text(_t('Dikonfirmasi', 'Confirmed', '已确认'),
                                                    style: GoogleFonts.poppins(
                                                        fontSize: 10, fontWeight: FontWeight.w600, color: _green)),
                                              ],
                                            ]),
                                          ),
                                        ]),
                                        if (replyGambar.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          AspectRatio(
                                            aspectRatio: 16 / 10,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(9),
                                                child: GestureDetector(
                                                  onTap: () => _openImageViewer(replyGambar),
                                                  child: Stack(
                                                    fit: StackFit.expand,
                                                    children: [
                                                      Image.network(replyGambar,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (_, __, ___) => const Center(
                                                              child: Icon(Icons.image_not_supported_rounded,
                                                                  color: Colors.grey, size: 28))),
                                                      _zoomBadge(size: 20, iconSize: 12),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (replyCatatan.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Row(children: [
                                            Icon(Icons.edit_note_rounded, size: 13, color: _accentBlue),
                                            const SizedBox(width: 5),
                                            Text(
                                              _t('Keterangan Tindakan Perbaikan', 'Corrective Action Description', '纠正措施说明'),
                                              style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: _accentBlue),
                                            ),
                                          ]),
                                          const SizedBox(height: 6),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: _accentBlue.withValues(alpha: 0.15)),
                                            ),
                                            child: Text(replyCatatan,
                                                style: GoogleFonts.poppins(
                                                    fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black)),
                                          ),
                                        ],
                                        if (confirmed && konfCatatan.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _t('Catatan Konfirmasi', 'Confirmation Note', '确认备注'),
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFFF59E0B)),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(konfCatatan,
                                                    style: GoogleFonts.poppins(fontSize: 11, color: _textMain)),
                                                if (konfGambar.isNotEmpty) ...[
                                                  const SizedBox(height: 8),
                                                  AspectRatio(
                                                    aspectRatio: 16 / 10,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(7),
                                                        child: GestureDetector(
                                                          onTap: () => _openImageViewer(konfGambar),
                                                          child: Stack(
                                                            fit: StackFit.expand,
                                                            children: [
                                                              Image.network(konfGambar, fit: BoxFit.cover),
                                                              _zoomBadge(size: 18, iconSize: 11),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
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
                            ],
                          ),
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

class _AuditFullImageViewer extends StatelessWidget {
  final String imageUrl;
  const _AuditFullImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_not_supported, color: Colors.white54, size: 60),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}