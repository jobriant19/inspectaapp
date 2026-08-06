import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../audit/form/audit_evidence_camera_screen.dart';
import '../../../user/home/alert/required_field_alert.dart';

class AuditNotifDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final String lang;

  const AuditNotifDetailScreen({
    super.key,
    required this.item,
    required this.lang,
  });

  @override
  State<AuditNotifDetailScreen> createState() =>
      _AuditNotifDetailScreenState();
}

class _AuditNotifDetailScreenState extends State<AuditNotifDetailScreen> {
  final _supabase = Supabase.instance.client;
  static const _blue = Color(0xFF1D72F3);
  static const _red = Color(0xFFEF4444);

  late Map<String, dynamic> _data;
  bool _loading = false;
  final Set<String> _collapsedSummaryTemas = {};

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.item);
  }

  String _t(String id, String en, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  String _formatDate(dynamic v) {
    if (v == null) return '-';
    final dt = v is DateTime ? v : DateTime.tryParse(v.toString());
    if (dt == null) return '-';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays < 1) return _t('Hari ini', 'Today', '今天');
    if (diff.inDays < 7) return '${diff.inDays} ${_t('hari lalu', 'days ago', '天前')}';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Color _scoreColor(double? s) {
    if (s == null) return const Color(0xFF64748B);
    if (s >= 80) return const Color(0xFF10B981);
    if (s >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Color _levelColor(String levelType) {
    switch (levelType) {
      case 'lokasi':
        return const Color(0xFF10B981);
      case 'unit':
        return const Color(0xFF6366F1);
      case 'subunit':
        return const Color(0xFFFBBF24);
      case 'area':
        return const Color(0xFFF472B6);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _levelIcon(String levelType) {
    switch (levelType) {
      case 'lokasi':
        return Icons.location_city_rounded;
      case 'unit':
        return Icons.business_rounded;
      case 'subunit':
        return Icons.layers_rounded;
      case 'area':
        return Icons.place_rounded;
      default:
        return Icons.location_off_rounded;
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
      decoration: BoxDecoration(shape: BoxShape.circle, color: _blue.withValues(alpha: 0.12)),
      child: Icon(Icons.person_rounded, size: size * 0.65, color: _blue),
    );
  }

  Future<void> _fetchDetailData() async {
    final idResult = _data['id_result']?.toString() ?? '';
    if (idResult.isEmpty) return;
    try {
      final resultRow = await _supabase
          .from('audit_result')
          .select(
            'id_result, level_type, id_ref, tanggal_audit, nilai_audit, '
            'nilai_final, is_finalized, catatan_audit, created_at, '
            'Auditor:User!fk_audit_result_auditor(nama, gambar_user)',
          )
          .eq('id_result', idResult)
          .maybeSingle();

      if (resultRow != null) {
        _data.addAll(Map<String, dynamic>.from(resultRow));
      }

      final userId = _supabase.auth.currentUser?.id ?? '';
      final logs = await _supabase
          .from('log_poin')
          .select('poin, deskripsi, tipe_aktivitas, created_at')
          .eq('id_user', userId)
          .eq('id_result', idResult)
          .order('created_at', ascending: true);
      _data['_poin_logs'] = List<Map<String, dynamic>>.from(logs as List);

      final answers = await _supabase
          .from('audit_answer')
          .select(
            'id_answer, jawaban, catatan, gambar_jawaban, '
            'Question:audit_question('
            'pertanyaan, pertanyaan_en, pertanyaan_zh, '
            'Tema:audit_tema(nama_tema_id, nama_tema_en, nama_tema_zh)'
            '), '
            'Replies:audit_answer_reply('
            'id_reply, id_pic, catatan_reply, gambar_reply, '
            'is_confirmed, confirmed_at, created_at, '
            'PIC:User!fk_reply_pic(nama, gambar_user)'
            ')',
          )
          .eq('id_result', idResult);
      _data['_answers'] = List<Map<String, dynamic>>.from(answers as List);
    } catch (e) {
      debugPrint('AuditNotifDetailScreen fetch error: $e');
    }
  }

  Future<void> _refreshDetail() async {
    setState(() => _loading = true);
    await _fetchDetailData();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _showConfirmSuccessPopup() async {
    if (!mounted) return;
    bool handled = false;
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'success',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.80, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) {
        void finish() {
          if (handled) return;
          handled = true;
          if (ctx.mounted && Navigator.of(ctx).canPop()) {
            Navigator.of(ctx).pop();
          }
        }

        Future.delayed(const Duration(milliseconds: 2000), finish);

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                    blurRadius: 40,
                    spreadRadius: 4,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.25), width: 2),
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF16A34A), size: 44),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _t('Berhasil!', 'Success!', '成功！'),
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _t(
                      'Balasan berhasil dikonfirmasi.',
                      'Reply confirmed successfully.',
                      '回复已成功确认。',
                    ),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 0.0),
                      duration: const Duration(milliseconds: 2000),
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 4,
                        backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: finish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'OK',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
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

  Future<void> _recalculateFinalScore(String idResult) async {
    try {
      final answers = await _supabase
          .from('audit_answer')
          .select('id_answer, jawaban, Replies:audit_answer_reply(is_confirmed)')
          .eq('id_result', idResult);

      final list = answers as List;
      final total = list.length;
      if (total == 0) return;

      final perQuestion = 100.0 / total;
      double score = 0;
      for (final a in list) {
        if (a['jawaban'] == true) {
          score += perQuestion;
        } else {
          final replies = (a['Replies'] as List?) ?? [];
          final confirmed = replies.any((r) => r['is_confirmed'] == true);
          if (confirmed) score += perQuestion / 2;
        }
      }

      await _supabase
          .from('audit_result')
          .update({'nilai_final': double.parse(score.toStringAsFixed(2))})
          .eq('id_result', idResult);
    } catch (e) {
      debugPrint('_recalculateFinalScore error: $e');
    }
  }

  void _openImageViewer(String? url) {
    if (url == null || url.isEmpty) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => _AuditImageViewer(imageUrl: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = double.tryParse(_data['nilai_audit']?.toString() ?? '');
    final scoreFinal = double.tryParse(_data['nilai_final']?.toString() ?? '');
    final isFinalized = _data['is_finalized'] == true;
    final displayScore = isFinalized ? scoreFinal : score;
    final scoreColor = isFinalized ? const Color(0xFFF59E0B) : _scoreColor(displayScore);
    final locationName = _data['_location_name']?.toString() ?? '-';
    final levelType = _data['level_type']?.toString() ?? '';
    final date = _formatDate(_data['tanggal_audit']);
    final answers = (_data['_answers'] as List<Map<String, dynamic>>?) ?? [];
    final role = _data['_role']?.toString() ?? 'auditor';
    final isPic = role == 'pic';
    final auditorData = _data['Auditor'] as Map<String, dynamic>?;
    final auditorName = auditorData?['nama']?.toString() ?? '';
    final auditorAvatar = auditorData?['gambar_user']?.toString();
    final idResult = _data['id_result']?.toString() ?? '';
    final userId = _supabase.auth.currentUser?.id ?? '';

    final noAnswers = answers.where((a) => a['jawaban'] == false).toList();
    final allNoConfirmed = noAnswers.isNotEmpty &&
        noAnswers.every((a) {
          final replies = (a['Replies'] as List?) ?? [];
          return replies.any((r) => r['is_confirmed'] == true);
        });
    final showScore = noAnswers.isEmpty || allNoConfirmed;

    final poinLogs = (_data['_poin_logs'] as List<Map<String, dynamic>>?) ?? [];
    int totalPoin = 0;
    for (final l in poinLogs) {
      totalPoin += ((l['poin'] as num?)?.toInt() ?? 0);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(
                        displayScore: displayScore,
                        scoreColor: scoreColor,
                        isFinalized: isFinalized,
                        allNoConfirmed: allNoConfirmed,
                        showScore: showScore,
                        locationName: locationName,
                        levelType: levelType,
                        date: date,
                        isPic: isPic,
                        auditorName: auditorName,
                        auditorAvatar: auditorAvatar,
                      ),
                      if (poinLogs.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _buildPoinLogCard(poinLogs, isPic, totalPoin),
                      ],
                      if (noAnswers.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Row(children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 16, color: Color(0xFFEF4444)),
                          const SizedBox(width: 6),
                          Text(
                            '${noAnswers.length} ${_t('pertanyaan perlu perbaikan', 'questions need fix', '个问题需要修复')}',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFEF4444)),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        ...noAnswers.map(
                            (ans) => _buildAnswerThread(ans, idResult, isPic, userId)),
                      ],
                      if (answers.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Row(children: [
                          Icon(Icons.list_alt_rounded, size: 16, color: _blue),
                          const SizedBox(width: 6),
                          Text(
                            _t('Ringkasan Jawaban', 'Answer Summary', '回答摘要'),
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w700, color: _blue),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        _buildAnswerSummary(answers),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_loading)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _blue),
                      ),
                      const SizedBox(width: 8),
                      Text(_t('Memperbarui…', 'Updating…', '更新中…'),
                          style: GoogleFonts.poppins(fontSize: 11, color: _blue)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: const Color(0xFFF8FAFC),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _blue),
        onPressed: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      title: Text(
        'Audit Notif Detail',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: _blue),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE2E8F0)),
      ),
    );
  }

  Widget _buildSummaryCard({
    required double? displayScore,
    required Color scoreColor,
    required bool isFinalized,
    required bool allNoConfirmed,
    required bool showScore,
    required String locationName,
    required String levelType,
    required String date,
    required bool isPic,
    required String auditorName,
    required String? auditorAvatar,
  }) {
    final locationColor = _levelColor(levelType);
    final locationIcon = _levelIcon(levelType);
    final roleColor = isPic ? const Color(0xFF10B981) : _blue;
    final roleIcon = isPic ? Icons.engineering_rounded : Icons.fact_check_rounded;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 88, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60, height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: showScore
                        ? scoreColor.withValues(alpha: 0.12)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: showScore
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayScore != null ? '${displayScore.toStringAsFixed(0)}%' : '-',
                              style: GoogleFonts.poppins(
                                  fontSize: 14, fontWeight: FontWeight.w800, color: scoreColor),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.pending_actions_rounded, size: 20, color: Color(0xFFF59E0B)),
                            Text(_t('Proses', 'WIP', '进行中'),
                                style: GoogleFonts.poppins(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFF59E0B))),
                          ],
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: locationColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: locationColor.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(locationIcon, size: 13, color: locationColor),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(locationName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12.5, fontWeight: FontWeight.w700, color: locationColor)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.schedule_rounded, size: 12, color: Colors.black),
                        const SizedBox(width: 4),
                        Text(date,
                            style: GoogleFonts.poppins(
                                fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.black)),
                      ]),
                      if (isPic && auditorName.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(children: [
                          Icon(Icons.badge_rounded, size: 12, color: _blue),
                          const SizedBox(width: 4),
                          Text('${_t('Auditor', 'Auditor', '审计员')} :',
                              style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: _blue)),
                          const SizedBox(width: 5),
                          _buildAuditorAvatar(auditorAvatar, size: 18),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(auditorName,
                                style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.black),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                      ],
                      if (!showScore) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 11, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 4),
                              Text(_t('Perlu Perbaikan', 'Needs Fix', '需要修复'),
                                  style: GoogleFonts.poppins(
                                      fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFFF59E0B))),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: roleColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(roleIcon, size: 12, color: roleColor),
                  const SizedBox(width: 4),
                  Text(isPic ? _t('PIC', 'PIC', 'PIC') : _t('Auditor', 'Auditor', '审计员'),
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: roleColor)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoinLogCard(List<Map<String, dynamic>> poinLogs, bool isPic, int totalPoin) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFF10B981).withValues(alpha: 0.10),
          _blue.withValues(alpha: 0.06),
        ]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFF10B981), size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isPic
                    ? _t('Bonus Poin PIC', 'PIC Bonus Points', 'PIC奖励积分')
                    : _t('Poin Diperoleh', 'Points Earned', '获得积分'),
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
              ),
            ),
            Text(totalPoin > 0 ? '+$totalPoin' : '$totalPoin',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: totalPoin >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
          ]),
          const SizedBox(height: 12),
          ...poinLogs.map((log) {
            final p = (log['poin'] as num?)?.toInt() ?? 0;
            final isPos = p >= 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPos
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(isPos ? '+$p' : '$p',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isPos ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(log['deskripsi']?.toString() ?? '',
                      style: GoogleFonts.poppins(
                          fontSize: 11.5, fontWeight: FontWeight.w500, color: const Color(0xFF334155))),
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }

  /// QUESTION + IMAGE + NOTES + REPLY THREAD
  Widget _buildAnswerThread(
      Map<String, dynamic> ans, String idResult, bool isPic, String userId) {
    final q = ans['Question'] as Map<String, dynamic>?;
    final replies = (ans['Replies'] as List?)
            ?.map((r) => Map<String, dynamic>.from(r as Map))
            .toList() ??
        [];
    final gambar = ans['gambar_jawaban']?.toString() ?? '';
    final catatan = ans['catatan']?.toString() ?? '';
    final idAnswer = ans['id_answer']?.toString() ?? '';

    final confirmedReplies = replies.where((r) => r['is_confirmed'] == true).toList();
    final isFullyConfirmed = confirmedReplies.isNotEmpty;

    String questionText;
    if (widget.lang == 'EN') {
      questionText = q?['pertanyaan_en']?.toString() ?? q?['pertanyaan']?.toString() ?? '-';
    } else if (widget.lang == 'ZH') {
      questionText = q?['pertanyaan_zh']?.toString() ?? q?['pertanyaan']?.toString() ?? '-';
    } else {
      questionText = q?['pertanyaan']?.toString() ?? '-';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isFullyConfirmed
            ? const Color(0xFFF59E0B).withValues(alpha: 0.05)
            : _red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFullyConfirmed
              ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
              : _red.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24, height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isFullyConfirmed
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : _red.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFullyConfirmed ? Icons.check_rounded : Icons.close_rounded,
                  size: 14,
                  color: isFullyConfirmed ? const Color(0xFF10B981) : _red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  questionText,
                  style: GoogleFonts.poppins(
                      fontSize: 13.5, fontWeight: FontWeight.w600, color: _blue),
                ),
              ),
            ],
          ),

          // EVIDENCE IMAGE 
          if (gambar.isNotEmpty) ...[
            const SizedBox(height: 10),
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
                        Positioned(
                          right: 8, bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          // NOTES
          if (catatan.isNotEmpty) ...[
            const SizedBox(height: 10),
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
          ],

          // FIX REPLIES
          if (replies.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(children: [
              Icon(Icons.forum_rounded, size: 14, color: _blue),
              const SizedBox(width: 5),
              Text(
                _t('Balasan Perbaikan', 'Fix Replies', '修复回复'),
                style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: _blue),
              ),
            ]),
            const SizedBox(height: 10),
            ...replies.map((reply) {
              final confirmed = reply['is_confirmed'] == true;
              final picData = reply['PIC'] as Map<String, dynamic>?;
              final picName = picData?['nama']?.toString() ?? '-';
              final picAvatar = picData?['gambar_user']?.toString();
              final replyGambar = reply['gambar_reply']?.toString() ?? '';
              final replyCatatan = reply['catatan_reply']?.toString() ?? '';
              final idReply = reply['id_reply']?.toString() ?? '';
              final replyOwnerId = reply['id_pic']?.toString();
              final isOwnReply = replyOwnerId != null && replyOwnerId == userId;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _blue.withValues(alpha: 0.3)),
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
                                  fontSize: 12, fontWeight: FontWeight.w600, color: _blue),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (confirmed) ...[
                            const SizedBox(width: 5),
                            const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF10B981)),
                            const SizedBox(width: 2),
                            Text(_t('Dikonfirmasi', 'Confirmed', '已确认'),
                                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF10B981))),
                          ],
                        ]),
                      ),
                      if (isPic && !confirmed && isOwnReply) ...[
                        GestureDetector(
                          onTap: () =>
                              _showEditReplySheet(idReply, idAnswer, idResult, userId, reply),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _blue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.edit_rounded, size: 14, color: _blue),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _deleteReply(idReply),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.delete_outline_rounded, size: 14, color: _red),
                          ),
                        ),
                      ],
                    ]),

                    if (replyGambar.isNotEmpty) ...[
                      const SizedBox(height: 10),
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
                                  Positioned(
                                    right: 6, bottom: 6,
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.55),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    if (replyCatatan.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(children: [
                        Icon(Icons.edit_note_rounded, size: 13, color: _blue),
                        const SizedBox(width: 5),
                        Text(
                          _t('Keterangan Tindakan Perbaikan', 'Corrective Action Description', '纠正措施说明'),
                          style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: _blue),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _blue.withValues(alpha: 0.15)),
                        ),
                        child: Text(replyCatatan,
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black)),
                      ),
                    ],

                    if (!isPic && !confirmed && !isOwnReply) ...[
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _confirmReply(idReply, idAnswer, idResult),
                            icon: const Icon(Icons.check_circle_rounded, size: 15),
                            label: Text(_t('Konfirmasi', 'Confirm', '确认'),
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showAuditorReplySheet(idReply, idAnswer, idResult, userId),
                            icon: const Icon(Icons.reply_rounded, size: 15),
                            label: Text(_t('Balas', 'Reply', '回复'),
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _blue,
                              side: const BorderSide(color: _blue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ],
                ),
              );
            }),
          ],

          if (isPic && !isFullyConfirmed) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showReplyBottomSheet(ans, idResult, true, userId),
                icon: const Icon(Icons.reply_rounded, size: 15),
                label: Text(
                  replies.isEmpty
                      ? _t('Balas Temuan', 'Reply Finding', '回复发现')
                      : _t('Tambah Balasan', 'Add Reply', '添加回复'),
                  style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _blue,
                  side: const BorderSide(color: _blue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],

          if (!isPic && replies.isEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.hourglass_top_rounded, size: 16, color: Color(0xFFF59E0B)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_t('Menunggu Balasan', 'Waiting for Reply', '等待回复'),
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFB45309))),
                      const SizedBox(height: 2),
                      Text(
                        _t(
                          'PIC belum mengirimkan bukti perbaikan untuk temuan ini.',
                          'PIC has not submitted fix evidence for this finding yet.',
                          'PIC尚未提交此发现的整改证据。',
                        ),
                        style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF92400E)),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswerSummary(List<Map<String, dynamic>> answers) {
    final Map<String, List<Map<String, dynamic>>> byTema = {};
    for (final ans in answers) {
      final q = ans['Question'] as Map<String, dynamic>?;
      final tema = q?['Tema'] as Map<String, dynamic>?;
      String temaKey;
      if (widget.lang == 'EN') {
        temaKey = tema?['nama_tema_en']?.toString() ?? _t('Lainnya', 'Other', '其他');
      } else if (widget.lang == 'ZH') {
        temaKey = tema?['nama_tema_zh']?.toString() ?? _t('Lainnya', 'Other', '其他');
      } else {
        temaKey = tema?['nama_tema_id']?.toString() ?? _t('Lainnya', 'Other', '其他');
      }
      byTema.putIfAbsent(temaKey, () => []).add(ans);
    }

    bool isAnswerConfirmed(Map<String, dynamic> ans) {
      final replies = (ans['Replies'] as List?) ?? [];
      return replies.any((r) => r['is_confirmed'] == true);
    }

    return Column(
      children: byTema.entries.map((entry) {
        final temaName = entry.key;
        final temaAnswers = entry.value;
        final yes = temaAnswers.where((a) => a['jawaban'] == true).length;
        final total = temaAnswers.length;
        final is100 = yes == total;
        final noAnswersInTema = temaAnswers.where((a) => a['jawaban'] == false).toList();
        final allNoConfirmedInTema =
            noAnswersInTema.isNotEmpty && noAnswersInTema.every(isAnswerConfirmed);
        final temaColor = is100
            ? const Color(0xFF10B981)
            : (allNoConfirmedInTema ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));
        final temaBgColor = is100
            ? const Color(0xFF10B981).withValues(alpha: 0.04)
            : (allNoConfirmedInTema
                ? const Color(0xFFFFF7ED)
                : const Color(0xFFEF4444).withValues(alpha: 0.05));
        final isCollapsed = _collapsedSummaryTemas.contains(temaName);

        return Container(
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: temaBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: temaColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isCollapsed) {
                      _collapsedSummaryTemas.remove(temaName);
                    } else {
                      _collapsedSummaryTemas.add(temaName);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(children: [
                    Icon(is100 ? Icons.check_circle_rounded : Icons.topic_outlined,
                        size: 14, color: temaColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(temaName,
                          style: GoogleFonts.poppins(
                              fontSize: 11.5, fontWeight: FontWeight.w700, color: temaColor)),
                    ),
                    const SizedBox(width: 8),
                    Text('$yes/$total',
                        style: GoogleFonts.poppins(
                            fontSize: 11.5, fontWeight: FontWeight.w700, color: temaColor)),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: isCollapsed ? 0 : 0.5,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: temaColor),
                    ),
                  ]),
                ),
              ),

              if (!isCollapsed) ...[
                Divider(height: 1, thickness: 1, color: temaColor.withValues(alpha: 0.15)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    children: temaAnswers.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final ans = entry.value;
                      final q = ans['Question'] as Map<String, dynamic>?;
                      final isYes = ans['jawaban'] == true;
                      final isConfirmedNo = !isYes && isAnswerConfirmed(ans);
                      String qText;
                      if (widget.lang == 'EN') {
                        qText = q?['pertanyaan_en']?.toString() ?? q?['pertanyaan']?.toString() ?? '-';
                      } else if (widget.lang == 'ZH') {
                        qText = q?['pertanyaan_zh']?.toString() ?? q?['pertanyaan']?.toString() ?? '-';
                      } else {
                        qText = q?['pertanyaan']?.toString() ?? '-';
                      }
                      return Padding(
                        padding: EdgeInsets.only(top: idx == 0 ? 0 : 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isYes || isConfirmedNo
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              size: 13,
                              color: isYes
                                  ? const Color(0xFF10B981)
                                  : (isConfirmedNo
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFFEF4444)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(qText,
                                  style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF1D72F3),
                                      height: 1.4)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  /// PIC REPLY POPUP
  Future<void> _showReplyBottomSheet(
      Map<String, dynamic> ans, String idResult, bool isPic, String userId) async {
    final noteCtrl = TextEditingController();
    XFile? photoFile;
    bool submitting = false;

    unawaited(AuditEvidenceWarmupService.instance.warmUp());

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _blue.withValues(alpha: 0.25), width: 1.5),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.reply_rounded, color: _blue, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _t('Balas Temuan', 'Reply Finding', '回复发现'),
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w700, color: _blue),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 18),

                    Row(children: [
                      Icon(Icons.camera_alt_rounded, size: 14, color: _blue),
                      const SizedBox(width: 5),
                      Text(_t('Foto Bukti Perbaikan', 'Fix Evidence Photo', '修复证据照片'),
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _blue)),
                      Text(' *', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFEF4444))),
                    ]),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final file = await Navigator.push<XFile>(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) => AuditEvidenceCameraScreen(lang: widget.lang, questionText: ''),
                          ),
                        );
                        if (file != null) {
                          setSt(() => photoFile = file);
                          unawaited(AuditEvidenceWarmupService.instance.warmUp());
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: photoFile == null ? 150 : 210,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _blue.withValues(alpha: 0.35)),
                        ),
                        child: photoFile == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_rounded, color: _blue, size: 26),
                                  const SizedBox(height: 6),
                                  Text(
                                    _t('Ambil / Upload Foto', 'Take / Upload Photo', '拍照/上传照片'),
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _blue),
                                  ),
                                ],
                              )
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: GestureDetector(
                                      onTap: () => _openLocalImageViewer(photoFile!),
                                      child: kIsWeb
                                          ? Image.network(photoFile!.path, fit: BoxFit.cover)
                                          : Image.file(File(photoFile!.path), fit: BoxFit.cover),
                                    ),
                                  ),
                                  Positioned(
                                    right: 8, bottom: 8,
                                    child: IgnorePointer(
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.55),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 6, right: 6,
                                    child: GestureDetector(
                                      onTap: () async {
                                        final file = await Navigator.push<XFile>(
                                          ctx,
                                          MaterialPageRoute(
                                            builder: (_) => AuditEvidenceCameraScreen(lang: widget.lang, questionText: ''),
                                          ),
                                        );
                                        if (file != null) {
                                          setSt(() => photoFile = file);
                                          unawaited(AuditEvidenceWarmupService.instance.warmUp());
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(children: [
                      Icon(Icons.edit_note_rounded, size: 14, color: _blue),
                      const SizedBox(width: 5),
                      Text(_t('Keterangan Tindakan Perbaikan', 'Corrective Action Description', '纠正措施说明'),
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _blue)),
                      Text(' *', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFEF4444))),
                    ]),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 3,
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
                      decoration: InputDecoration(
                        hintText: _t(
                          'Jelaskan tindakan perbaikan yang telah dilakukan…',
                          'Describe corrective action taken…',
                          '描述已采取的纠正措施…',
                        ),
                        hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: _blue.withValues(alpha: 0.25))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: _blue.withValues(alpha: 0.25))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: _blue, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitting
                            ? null
                            : () async {
                                final missing = <MissingFieldItem>[];
                                if (photoFile == null) {
                                  missing.add(MissingFieldItem(
                                    icon: Icons.camera_alt_rounded,
                                    label: _t('Foto Bukti Perbaikan', 'Fix Evidence Photo', '修复证据照片'),
                                  ));
                                }
                                if (noteCtrl.text.trim().isEmpty) {
                                  missing.add(MissingFieldItem(
                                    icon: Icons.edit_note_rounded,
                                    label: _t('Keterangan Tindakan Perbaikan',
                                        'Corrective Action Description', '纠正措施说明'),
                                  ));
                                }
                                if (missing.isNotEmpty) {
                                  await RequiredFieldAlert.show(context,
                                      lang: widget.lang, missingFields: missing);
                                  return;
                                }

                                setSt(() => submitting = true);
                                try {
                                  final bytes = await photoFile!.readAsBytes();
                                  final fileName =
                                      'reply_${DateTime.now().millisecondsSinceEpoch}_${ans['id_answer']}.jpg';
                                  final storagePath = 'audit_evidence/$fileName';
                                  await _supabase.storage.from('audit-evidence').uploadBinary(
                                        storagePath,
                                        bytes,
                                        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
                                      );
                                  final photoUrl =
                                      _supabase.storage.from('audit-evidence').getPublicUrl(storagePath);

                                  await _supabase.from('audit_answer_reply').insert({
                                    'id_answer': ans['id_answer'],
                                    'id_pic': userId,
                                    'catatan_reply': noteCtrl.text.trim(),
                                    'gambar_reply': photoUrl,
                                    'is_confirmed': false,
                                  });

                                  final picUserData = await _supabase
                                      .from('User')
                                      .select('nama')
                                      .eq('id_user', userId)
                                      .maybeSingle();
                                  final picName = picUserData?['nama']?.toString() ?? '-';
                                  await _notifyAuditor(idResult, picName);

                                  if (ctx.mounted) Navigator.pop(ctx);
                                  await _refreshDetail();
                                } catch (e) {
                                  setSt(() => submitting = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: submitting
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(_t('Kirim Balasan', 'Send Reply', '发送回复'),
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await AuditEvidenceWarmupService.instance.release();
  }

  void _openLocalImageViewer(XFile file) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => _AuditLocalImageViewer(file: file),
      ),
    );
  }

  Future<void> _showEditReplySheet(String idReply, String idAnswer, String idResult,
      String userId, Map<String, dynamic> existingReply) async {
    final noteCtrl =
        TextEditingController(text: existingReply['catatan_reply']?.toString() ?? '');
    String? existingPhotoUrl = existingReply['gambar_reply']?.toString();
    if (existingPhotoUrl != null && existingPhotoUrl.isEmpty) existingPhotoUrl = null;
    XFile? newPhotoFile;
    bool submitting = false;

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _blue.withValues(alpha: 0.25), width: 1.5),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.edit_rounded, color: _blue, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _t('Edit Balasan', 'Edit Reply', '编辑回复'),
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: _blue),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 18),

                    Row(children: [
                      Icon(Icons.camera_alt_rounded, size: 14, color: _blue),
                      const SizedBox(width: 5),
                      Text(_t('Foto Bukti Perbaikan', 'Fix Evidence Photo', '修复证据照片'),
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _blue)),
                      Text(' *', style: GoogleFonts.poppins(fontSize: 12, color: _red)),
                    ]),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final file = await Navigator.push<XFile>(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) => AuditEvidenceCameraScreen(lang: widget.lang, questionText: ''),
                          ),
                        );
                        if (file != null) setSt(() => newPhotoFile = file);
                      },
                      child: Container(
                        width: double.infinity,
                        height: (newPhotoFile == null && existingPhotoUrl == null) ? 150 : 210,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _blue.withValues(alpha: 0.35)),
                        ),
                        child: (newPhotoFile == null && existingPhotoUrl == null)
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_rounded, color: _blue, size: 26),
                                  const SizedBox(height: 6),
                                  Text(
                                    _t('Ambil / Upload Foto', 'Take / Upload Photo', '拍照/上传照片'),
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _blue),
                                  ),
                                ],
                              )
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: GestureDetector(
                                      onTap: () {
                                        if (newPhotoFile != null) {
                                          _openLocalImageViewer(newPhotoFile!);
                                        } else if (existingPhotoUrl != null) {
                                          _openImageViewer(existingPhotoUrl);
                                        }
                                      },
                                      child: newPhotoFile != null
                                          ? (kIsWeb
                                              ? Image.network(newPhotoFile!.path, fit: BoxFit.cover)
                                              : Image.file(File(newPhotoFile!.path), fit: BoxFit.cover))
                                          : Image.network(existingPhotoUrl!, fit: BoxFit.cover),
                                    ),
                                  ),
                                  Positioned(
                                    right: 8, bottom: 8,
                                    child: IgnorePointer(
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.55),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 6, right: 6,
                                    child: GestureDetector(
                                      onTap: () async {
                                        final file = await Navigator.push<XFile>(
                                          ctx,
                                          MaterialPageRoute(
                                            builder: (_) => AuditEvidenceCameraScreen(lang: widget.lang, questionText: ''),
                                          ),
                                        );
                                        if (file != null) setSt(() => newPhotoFile = file);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(children: [
                      Icon(Icons.edit_note_rounded, size: 14, color: _blue),
                      const SizedBox(width: 5),
                      Text(_t('Keterangan Tindakan Perbaikan', 'Corrective Action Description', '纠正措施说明'),
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _blue)),
                      Text(' *', style: GoogleFonts.poppins(fontSize: 12, color: _red)),
                    ]),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 3,
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
                      decoration: InputDecoration(
                        hintText: _t('Jelaskan tindakan perbaikan…', 'Describe corrective action…', '描述纠正措施…'),
                        hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: _blue.withValues(alpha: 0.25))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: _blue.withValues(alpha: 0.25))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: _blue, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitting
                            ? null
                            : () async {
                                final missing = <MissingFieldItem>[];
                                if (newPhotoFile == null && existingPhotoUrl == null) {
                                  missing.add(MissingFieldItem(
                                    icon: Icons.camera_alt_rounded,
                                    label: _t('Foto Bukti Perbaikan', 'Fix Evidence Photo', '修复证据照片'),
                                  ));
                                }
                                if (noteCtrl.text.trim().isEmpty) {
                                  missing.add(MissingFieldItem(
                                    icon: Icons.edit_note_rounded,
                                    label: _t('Keterangan Tindakan Perbaikan',
                                        'Corrective Action Description', '纠正措施说明'),
                                  ));
                                }
                                if (missing.isNotEmpty) {
                                  await RequiredFieldAlert.show(context,
                                      lang: widget.lang, missingFields: missing);
                                  return;
                                }

                                setSt(() => submitting = true);
                                try {
                                  String photoUrl = existingPhotoUrl ?? '';
                                  if (newPhotoFile != null) {
                                    final bytes = await newPhotoFile!.readAsBytes();
                                    final fileName =
                                        'reply_${DateTime.now().millisecondsSinceEpoch}_$idAnswer.jpg';
                                    final storagePath = 'audit_evidence/$fileName';
                                    await _supabase.storage.from('audit-evidence').uploadBinary(
                                          storagePath,
                                          bytes,
                                          fileOptions:
                                              const FileOptions(contentType: 'image/jpeg', upsert: true),
                                        );
                                    photoUrl =
                                        _supabase.storage.from('audit-evidence').getPublicUrl(storagePath);
                                  }

                                  await _supabase.from('audit_answer_reply').update({
                                    'catatan_reply': noteCtrl.text.trim(),
                                    'gambar_reply': photoUrl,
                                  }).eq('id_reply', idReply);

                                  if (ctx.mounted) Navigator.pop(ctx);
                                  await _refreshDetail();
                                } catch (e) {
                                  setSt(() => submitting = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: submitting
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(_t('Simpan Perubahan', 'Save Changes', '保存更改'),
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteReply(String idReply) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _t('Hapus Balasan', 'Delete Reply', '删除回复'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: const Color(0xFF1E3A8A)),
        ),
        content: Text(
          _t('Balasan ini akan dihapus. Lanjutkan?', 'This reply will be deleted. Continue?',
              '此回复将被删除。是否继续？'),
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t('Batal', 'Cancel', '取消'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(_t('Hapus', 'Delete', '删除'), style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await _supabase.from('audit_answer_reply').delete().eq('id_reply', idReply);
      await _refreshDetail();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ));
      }
    }
  }

  Future<void> _showAuditorReplySheet(
      String idReply, String idAnswer, String idResult, String userId) async {
    final noteCtrl = TextEditingController();
    XFile? photoFile;
    bool submitting = false;

    unawaited(AuditEvidenceWarmupService.instance.warmUp());

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _blue.withValues(alpha: 0.25), width: 1.5),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.reply_rounded, color: _blue, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _t('Balas Perbaikan', 'Reply to Fix', '回复修复'),
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w700, color: _blue),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                      _t(
                        'Jelaskan jika perbaikan belum sesuai — PIC akan menerima balasan ini dan bisa memperbaiki lagi.',
                        'Explain if the fix is not sufficient yet — PIC will receive this and can fix it again.',
                        '说明修复是否仍不充分——PIC将收到此回复并可以再次修复。',
                      ),
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 18),

                    Row(children: [
                      Icon(Icons.camera_alt_rounded, size: 14, color: _blue),
                      const SizedBox(width: 5),
                      Text(_t('Foto Bukti (opsional)', 'Evidence Photo (optional)', '证据照片（可选）'),
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _blue)),
                    ]),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final file = await Navigator.push<XFile>(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) => AuditEvidenceCameraScreen(lang: widget.lang, questionText: ''),
                          ),
                        );
                        if (file != null) {
                          setSt(() => photoFile = file);
                          unawaited(AuditEvidenceWarmupService.instance.warmUp());
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: photoFile == null ? 130 : 190,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _blue.withValues(alpha: 0.3)),
                        ),
                        child: photoFile == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_rounded, color: _blue, size: 24),
                                  const SizedBox(height: 6),
                                  Text(
                                    _t('Ambil / Upload Foto', 'Take / Upload Photo', '拍照/上传照片'),
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _blue),
                                  ),
                                ],
                              )
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: GestureDetector(
                                      onTap: () => _openLocalImageViewer(photoFile!),
                                      child: kIsWeb
                                          ? Image.network(photoFile!.path, fit: BoxFit.cover)
                                          : Image.file(File(photoFile!.path), fit: BoxFit.cover),
                                    ),
                                  ),
                                  Positioned(
                                    right: 8, bottom: 8,
                                    child: IgnorePointer(
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.55),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 6, right: 6,
                                    child: GestureDetector(
                                      onTap: () async {
                                        final file = await Navigator.push<XFile>(
                                          ctx,
                                          MaterialPageRoute(
                                            builder: (_) => AuditEvidenceCameraScreen(lang: widget.lang, questionText: ''),
                                          ),
                                        );
                                        if (file != null) {
                                          setSt(() => photoFile = file);
                                          unawaited(AuditEvidenceWarmupService.instance.warmUp());
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 6, left: 6,
                                    child: GestureDetector(
                                      onTap: () => setSt(() => photoFile = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(children: [
                      Icon(Icons.edit_note_rounded, size: 14, color: _blue),
                      const SizedBox(width: 5),
                      Text(_t('Catatan', 'Notes', '备注'),
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _blue)),
                      Text(' *', style: GoogleFonts.poppins(fontSize: 12, color: _red)),
                    ]),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 3,
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
                      decoration: InputDecoration(
                        hintText: _t(
                          'Jelaskan kekurangan perbaikan ini…',
                          'Describe what is still lacking…',
                          '说明此修复仍存在的问题…',
                        ),
                        hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: _blue.withValues(alpha: 0.25))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: _blue.withValues(alpha: 0.25))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: _blue, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: submitting
                            ? null
                            : () async {
                                if (noteCtrl.text.trim().isEmpty) {
                                  await RequiredFieldAlert.show(context,
                                      lang: widget.lang,
                                      missingFields: [
                                        MissingFieldItem(
                                          icon: Icons.edit_note_rounded,
                                          label: _t('Catatan', 'Notes', '备注'),
                                        ),
                                      ]);
                                  return;
                                }
                                setSt(() => submitting = true);
                                try {
                                  String? photoUrl;
                                  if (photoFile != null) {
                                    final bytes = await photoFile!.readAsBytes();
                                    final fileName =
                                        'auditor_reply_${DateTime.now().millisecondsSinceEpoch}_$idAnswer.jpg';
                                    final storagePath = 'audit_evidence/$fileName';
                                    await _supabase.storage.from('audit-evidence').uploadBinary(
                                          storagePath,
                                          bytes,
                                          fileOptions:
                                              const FileOptions(contentType: 'image/jpeg', upsert: true),
                                        );
                                    photoUrl =
                                        _supabase.storage.from('audit-evidence').getPublicUrl(storagePath);
                                  }

                                  await _supabase.from('audit_answer_reply').insert({
                                    'id_answer': idAnswer,
                                    'id_pic': userId,
                                    'catatan_reply': noteCtrl.text.trim(),
                                    'gambar_reply': photoUrl,
                                    'is_confirmed': false,
                                  });

                                  final auditorUserData = await _supabase
                                      .from('User')
                                      .select('nama')
                                      .eq('id_user', userId)
                                      .maybeSingle();
                                  final auditorName = auditorUserData?['nama']?.toString() ?? '-';
                                  await _notifyPicFromAuditor(
                                    idResult: idResult,
                                    auditorName: auditorName,
                                    isConfirm: false,
                                  );

                                  if (ctx.mounted) Navigator.pop(ctx);
                                  await _refreshDetail();
                                } catch (e) {
                                  setSt(() => submitting = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx)
                                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                                  }
                                }
                              },
                        icon: submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send_rounded, size: 16),
                        label: Text(
                          submitting ? '' : _t('Kirim Balasan', 'Send Reply', '发送回复'),
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await AuditEvidenceWarmupService.instance.release();
  }

  Future<void> _notifyAuditor(String idResult, String picName) async {
    try {
      final resultRow = await _supabase
          .from('audit_result')
          .select('id_auditor, level_type, id_ref')
          .eq('id_result', idResult)
          .maybeSingle();

      if (resultRow == null) return;

      final auditorId = resultRow['id_auditor']?.toString();
      if (auditorId == null) return;

      final auditorData =
          await _supabase.from('User').select('fcm_token').eq('id_user', auditorId).maybeSingle();

      final fcmToken = auditorData?['fcm_token']?.toString();
      if (fcmToken == null || fcmToken.trim().isEmpty) return;

      final levelType = resultRow['level_type']?.toString() ?? '';
      final idRef = resultRow['id_ref']?.toString() ?? '';
      String locationName = '-';
      if (levelType.isNotEmpty && idRef.isNotEmpty) {
        try {
          final nameCol = 'nama_$levelType';
          final idCol = 'id_$levelType';
          final locRow =
              await _supabase.from(levelType).select(nameCol).eq(idCol, idRef).maybeSingle();
          locationName = locRow?[nameCol]?.toString() ?? '-';
        } catch (_) {}
      }

      final notifTitle = _t('🔧 PIC Membalas Temuan', '🔧 PIC Replied to Finding', '🔧 PIC已回复发现');
      final notifBody = _t(
        '$picName telah mengirim bukti perbaikan untuk $locationName. Silakan tinjau dan konfirmasi.',
        '$picName has submitted corrective action evidence for $locationName. Please review and confirm.',
        '$picName 已提交 $locationName 的整改证据，请审阅并确认。',
      );

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
      debugPrint('_notifyAuditor error: $e');
    }
  }

  Future<void> _notifyPicFromAuditor({
    required String idResult,
    required String auditorName,
    required bool isConfirm,
  }) async {
    try {
      final resultRow = await _supabase
          .from('audit_result')
          .select('level_type, id_ref')
          .eq('id_result', idResult)
          .maybeSingle();

      if (resultRow == null) return;

      final levelType = resultRow['level_type']?.toString() ?? '';
      final idRef = resultRow['id_ref']?.toString() ?? '';
      if (levelType.isEmpty || idRef.isEmpty) return;

      final nameCol = 'nama_$levelType';
      final idCol = 'id_$levelType';

      final locRow =
          await _supabase.from(levelType).select('id_pic, $nameCol').eq(idCol, idRef).maybeSingle();

      final picId = locRow?['id_pic']?.toString();
      final locationName = locRow?[nameCol]?.toString() ?? '-';
      if (picId == null) return;

      final picData =
          await _supabase.from('User').select('fcm_token').eq('id_user', picId).maybeSingle();

      final fcmToken = picData?['fcm_token']?.toString();
      if (fcmToken == null || fcmToken.trim().isEmpty) return;

      final String notifTitle;
      final String notifBody;

      if (isConfirm) {
        notifTitle = _t('✅ Perbaikan Dikonfirmasi!', '✅ Fix Confirmed!', '✅ 整改已确认！');
        notifBody = _t(
          'Auditor $auditorName telah mengkonfirmasi perbaikan Anda untuk $locationName. Poin bonus telah ditambahkan!',
          'Auditor $auditorName has confirmed your fix for $locationName. Bonus points have been added!',
          '审计员 $auditorName 已确认您对 $locationName 的整改。已添加奖励积分！',
        );
      } else {
        notifTitle = _t('💬 Auditor Membalas Temuan', '💬 Auditor Replied to Finding', '💬 审计员已回复发现');
        notifBody = _t(
          'Auditor $auditorName memberikan catatan tambahan untuk $locationName. Silakan tinjau dan perbaiki kembali.',
          'Auditor $auditorName added notes for $locationName. Please review and fix again.',
          '审计员 $auditorName 对 $locationName 添加了备注，请审阅并再次整改。',
        );
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
      debugPrint('_notifyPicFromAuditor error: $e');
    }
  }

  Future<void> _confirmReply(String idReply, String idAnswer, String idResult) async {
    try {
      await _supabase.from('audit_answer_reply').update({
        'is_confirmed': true,
        'confirmed_at': DateTime.now().toIso8601String(),
      }).eq('id_reply', idReply);

      await _recalculateFinalScore(idResult);

      final resultRow = await _supabase
          .from('audit_result')
          .select('is_finalized, level_type, id_ref, id_auditor')
          .eq('id_result', idResult)
          .maybeSingle();

      if (resultRow == null || resultRow['is_finalized'] == true) {
        await _fetchDetailData();
        if (mounted) setState(() {});
        await _showConfirmSuccessPopup();
        return;
      }

      final allAnswers = await _supabase
          .from('audit_answer')
          .select(
            'id_answer, jawaban, '
            'Question:audit_question(id_tema, Tema:audit_tema(nama_tema_id, nama_tema_en, nama_tema_zh)), '
            'Replies:audit_answer_reply(is_confirmed)',
          )
          .eq('id_result', idResult);

      final answerList = allAnswers as List;
      final noAnswers = answerList.where((a) => a['jawaban'] == false).toList();

      final allNoConfirmed = noAnswers.isNotEmpty &&
          noAnswers.every((a) {
            final replies = (a['Replies'] as List?) ?? [];
            return replies.any((r) => r['is_confirmed'] == true);
          });

      if (!allNoConfirmed) {
        await _fetchDetailData();
        if (mounted) setState(() {});
        await _showConfirmSuccessPopup();
        return;
      }

      final levelType = resultRow['level_type'].toString();
      final idRef = resultRow['id_ref'].toString();
      final nameCol = 'nama_$levelType';
      final idCol = 'id_$levelType';

      final locRow =
          await _supabase.from(levelType).select('id_pic, $nameCol').eq(idCol, idRef).maybeSingle();

      final picId = locRow?['id_pic']?.toString();
      final lokasiName = locRow?[nameCol]?.toString() ?? '-';

      if (picId != null) {
        final Map<String, Map<String, String>> temaNamesMap = {};
        final Map<String, bool> temaAllYes = {};

        for (final a in answerList) {
          final q = a['Question'] as Map<String, dynamic>?;
          final tema = q?['Tema'] as Map<String, dynamic>?;
          final temaId = q?['id_tema']?.toString() ?? 'no_tema';
          final isYes = a['jawaban'] == true;

          temaNamesMap.putIfAbsent(temaId, () => {
                'id': tema?['nama_tema_id']?.toString() ?? _t('Lainnya', 'Other', '其他'),
                'en': tema?['nama_tema_en']?.toString() ?? _t('Lainnya', 'Other', '其他'),
                'zh': tema?['nama_tema_zh']?.toString() ?? _t('Lainnya', 'Other', '其他'),
              });

          temaAllYes[temaId] = (temaAllYes[temaId] ?? true) && isYes;
        }

        if (temaNamesMap.isNotEmpty) {
          final temaCfgRow = await _supabase
              .from('konfigurasi_poin')
              .select('poin, deskripsi_template')
              .eq('kode', 'AUDIT_BONUS_TEMA')
              .eq('is_aktif', true)
              .maybeSingle();

          if (temaCfgRow != null) {
            final fullPoin = temaCfgRow['poin'] as int;
            final halfPoin = (fullPoin / 2).round();
            final template = temaCfgRow['deskripsi_template'] as String;

            final logEntries = temaNamesMap.entries.map((entry) {
              final temaId = entry.key;
              final names = entry.value;
              final temaName = widget.lang == 'EN'
                  ? names['en']
                  : (widget.lang == 'ZH' ? names['zh'] : names['id']);
              final isTemaAllYes = temaAllYes[temaId] ?? false;
              final poin = isTemaAllYes ? fullPoin : halfPoin;
              final deskripsi = template
                  .replaceAll('{tema}', temaName ?? '-')
                  .replaceAll('{lokasi}', lokasiName);
              return {
                'id_user': picId,
                'poin': poin,
                'deskripsi': deskripsi,
                'tipe_aktivitas': 'audit_bonus_tema',
                'id_result': idResult,
              };
            }).toList();

            await _supabase.from('log_poin').insert(logEntries);
          }
        }
      }

      final auditorId = resultRow['id_auditor']?.toString() ?? '';
      if (auditorId.isNotEmpty) {
        final auditorUserData =
            await _supabase.from('User').select('nama').eq('id_user', auditorId).maybeSingle();
        final auditorName = auditorUserData?['nama']?.toString() ?? '-';
        await _notifyPicFromAuditor(
          idResult: idResult,
          auditorName: auditorName,
          isConfirm: true,
        );
      }

      await _supabase.from('audit_result').update({'is_finalized': true}).eq('id_result', idResult);

      await _fetchDetailData();
      if (mounted) setState(() {});
      await _showConfirmSuccessPopup();
    } catch (e) {
      debugPrint('_confirmReply error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ));
      }
    }
  }
}

class _AuditImageViewer extends StatelessWidget {
  final String imageUrl;
  const _AuditImageViewer({required this.imageUrl});

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
                    decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
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

class _AuditLocalImageViewer extends StatelessWidget {
  final XFile file;
  const _AuditLocalImageViewer({required this.file});

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
                child: kIsWeb
                    ? Image.network(file.path, fit: BoxFit.contain, width: double.infinity, height: double.infinity)
                    : Image.file(File(file.path), fit: BoxFit.contain, width: double.infinity, height: double.infinity),
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
                    decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
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