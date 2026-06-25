import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class _AppColors {
  static const primary = Color(0xFF0EA5E9);
  static const primaryDark = Color(0xFF0369A1);
  static const primaryLight = Color(0xFFE0F2FE);
  static const textPrimary = Color(0xFF0C4A6E);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFFBDBDBD);
  static const divider = Color(0xFFE0F2FE);
}

// ─── Model Data ───────────────────────────────────────────────────────────────
class LocationData5R {
  final String name;
  final String pic;
  final String? value;

  const LocationData5R({
    required this.name,
    required this.pic,
    this.value,
  });
}

class AuditLocationData5R {
  final String id;
  final String name;
  final String pic;
  final double? auditScore;
  final String? auditDate;
  final String? auditPeriod;

  const AuditLocationData5R({
    required this.id,
    required this.name,
    required this.pic,
    this.auditScore,
    this.auditDate,
    this.auditPeriod,
  });
}

// ─── Main Widget ──────────────────────────────────────────────────────────────
class FiveRLocationTab extends StatelessWidget {
  final String lang;
  final String filterMode;
  final int selectedMonthIndex;
  final DateTime? selectedDate;
  final String selectedLocationLevel;
  final List<String> translatedMonths;
  final List<String> translatedLocationLevels;
  final String lastUpdatedText;
  final String Function(String) getTxt;
  final Future<List<LocationData5R>>? lokasiFuture;
  final Future<List<AuditLocationData5R>>? auditLokasiFuture;

  final Widget Function({
    required String label,
    required VoidCallback onTap,
    IconData icon,
    bool isActive,
  }) buildFilterBtn;

  final VoidCallback showMonthPicker;
  final VoidCallback showLevelPicker;
  final VoidCallback onRefresh;
  final void Function(AuditLocationData5R loc) onAuditLocationTap;

  const FiveRLocationTab({
    super.key,
    required this.lang,
    required this.filterMode,
    required this.selectedMonthIndex,
    required this.selectedDate,
    required this.selectedLocationLevel,
    required this.translatedMonths,
    required this.translatedLocationLevels,
    required this.lastUpdatedText,
    required this.getTxt,
    required this.lokasiFuture,
    required this.auditLokasiFuture,
    required this.buildFilterBtn,
    required this.showMonthPicker,
    required this.showLevelPicker,
    required this.onRefresh,
    required this.onAuditLocationTap,
  });

  bool get _use5RAudit => !(filterMode == 'daily' && selectedDate != null);

  String get _rankAuditLabel {
    if (lang == 'EN') return 'Score';
    if (lang == 'ZH') return '评分';
    return 'Nilai';
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Filter bar ────────────────────────────────────────────────────────
      Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          buildFilterBtn(
            label: filterMode == 'daily' && selectedDate != null
                ? DateFormat('d MMM yyyy',
                    lang == 'ID' ? 'id_ID' : lang == 'EN' ? 'en_US' : 'zh_CN')
                    .format(selectedDate!)
                : translatedMonths[selectedMonthIndex],
            isActive: true,
            onTap: showMonthPicker,
          ),
          const SizedBox(width: 10),
          Expanded(child: buildFilterBtn(
            label: selectedLocationLevel,
            onTap: showLevelPicker,
          )),
        ]),
      ),

      // ── Audit period banner (daily mode only) ─────────────────────────────
      if (!_use5RAudit) _buildAuditPeriodBanner(),

      // ── Last updated ──────────────────────────────────────────────────────
      _buildLastUpdatedWidget(),

      // ── Table header ──────────────────────────────────────────────────────
      _use5RAudit
          ? _buildTableHeader([getTxt('rank'), getTxt('lokasi'), _rankAuditLabel])
          : _buildTableHeader([getTxt('rank'), getTxt('lokasi'), getTxt('temuan')]),

      // ── List ──────────────────────────────────────────────────────────────
      Expanded(child: Builder(builder: (context) {
        if (_use5RAudit) {
          if (auditLokasiFuture == null) return _buildLokasiShimmer();
          return FutureBuilder<List<AuditLocationData5R>>(
            future: auditLokasiFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLokasiShimmer();
              }
              final data = snapshot.data ?? [];
              if (data.isEmpty) {
                return Center(
                  child: Text(getTxt('tidak_ada_data_level'),
                      style: const TextStyle(color: _AppColors.textSecondary)));
              }
              return RefreshIndicator(
                onRefresh: () async => onRefresh(),
                color: _AppColors.primary,
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: data.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: _AppColors.divider, indent: 16),
                  itemBuilder: (_, i) =>
                      _buildAuditLocationRow(i + 1, data[i]),
                ),
              );
            },
          );
        }

        if (lokasiFuture == null) return _buildLokasiShimmer();
        return FutureBuilder<List<LocationData5R>>(
          future: lokasiFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLokasiShimmer();
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                    '${getTxt('tidak_ada_data_level')} "$selectedLocationLevel".'));
            }
            return ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: snapshot.data!.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: _AppColors.divider, indent: 16),
              itemBuilder: (_, i) =>
                  _buildLocationRow(i + 1, snapshot.data![i]),
            );
          },
        );
      })),
    ]);
  }

  // ── Widget helpers ──────────────────────────────────────────────────────────

  Widget _buildLastUpdatedWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(lastUpdatedText,
          style: const TextStyle(
              fontSize: 11, color: _AppColors.textSecondary, height: 1.4)),
    );
  }

  Widget _buildAuditPeriodBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.calendar_today_rounded, size: 15, color: _AppColors.primary),
        const SizedBox(width: 8),
        Text(getTxt('periode_audit'),
            style: const TextStyle(fontSize: 13, color: _AppColors.textSecondary)),
        const Text('13 Apr - 19 Apr 2026',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _AppColors.primaryDark)),
      ]),
    );
  }

  Widget _buildTableHeader(List<String> cols) {
    return Container(
      color: const Color(0xFFF8FAFF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        SizedBox(
            width: 40,
            child: Text(cols[0],
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _AppColors.textSecondary,
                    letterSpacing: 0.2))),
        Expanded(
            flex: 3,
            child: Text(cols[1],
                textAlign: TextAlign.left,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _AppColors.textSecondary,
                    letterSpacing: 0.2))),
        SizedBox(
            width: 70,
            child: Text(cols[2],
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _AppColors.textSecondary,
                    letterSpacing: 0.2))),
      ]),
    );
  }

  Widget _buildLocationRow(int rank, LocationData5R loc) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        SizedBox(
            width: 40,
            child: Text('$rank',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13,
                    color: _AppColors.textSecondary,
                    fontWeight: FontWeight.w500))),
        Expanded(
            flex: 3,
            child: Row(children: [
              Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: _AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.location_city_rounded,
                      color: _AppColors.primary, size: 20)),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(loc.name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis),
                    Text(loc.pic,
                        style: const TextStyle(
                            fontSize: 11.5, color: _AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis),
                  ])),
            ])),
        SizedBox(
            width: 70,
            child: Text(loc.value ?? '0',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: (int.tryParse(loc.value ?? '0') ?? 0) > 0
                        ? _AppColors.primaryDark
                        : _AppColors.textMuted))),
      ]),
    );
  }

  Widget _buildAuditLocationRow(int rank, AuditLocationData5R loc) {
    final score = loc.auditScore;
    Color scoreColor;
    if (score == null) {
      scoreColor = _AppColors.textMuted;
    } else if (score >= 80) {
      scoreColor = const Color(0xFF10B981);
    } else if (score >= 60) {
      scoreColor = const Color(0xFFF59E0B);
    } else {
      scoreColor = const Color(0xFFEF4444);
    }

    return GestureDetector(
      onTap: () => onAuditLocationTap(loc),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          SizedBox(
              width: 40,
              child: rank <= 3
                  ? Text(['🥇', '🥈', '🥉'][rank - 1],
                      style: const TextStyle(fontSize: 20))
                  : Text('$rank',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13, color: _AppColors.textSecondary))),
          Expanded(
              flex: 3,
              child: Row(children: [
                Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.location_city_rounded,
                        color: scoreColor, size: 20)),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(loc.name,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis),
                      Text(loc.pic,
                          style: const TextStyle(
                              fontSize: 11.5, color: _AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis),
                      if (loc.auditDate != null) ...[
                        const SizedBox(height: 2),
                        ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                                value: score != null ? score / 100 : 0,
                                backgroundColor: scoreColor.withOpacity(0.15),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(scoreColor),
                                minHeight: 4)),
                      ],
                    ])),
              ])),
          SizedBox(
              width: 70,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                      score != null ? '${score.toStringAsFixed(0)}%' : '-',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: scoreColor)),
                  if (loc.auditDate != null)
                    Text(loc.auditDate!.substring(0, 10),
                        style: const TextStyle(
                            fontSize: 9, color: _AppColors.textSecondary)),
                ],
              )),
        ]),
      ),
    );
  }

  Widget _buildLokasiShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: 8,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: _AppColors.divider, indent: 16),
        itemBuilder: (_, __) => Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            SizedBox(
                width: 40,
                child: Center(child: _shimmerBox(height: 14, width: 20))),
            Expanded(
                flex: 3,
                child: Row(children: [
                  _shimmerBox(height: 38, width: 38, borderRadius: 10),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        _shimmerBox(height: 14, width: double.infinity),
                        const SizedBox(height: 4),
                        _shimmerBox(height: 12, width: 100),
                      ])),
                ])),
            SizedBox(
                width: 70,
                child: Center(child: _shimmerBox(height: 14, width: 20))),
          ]),
        ),
      ),
    );
  }

  Widget _shimmerBox(
      {double? width,
      required double height,
      bool isCircle = false,
      double borderRadius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(isCircle ? height / 2 : borderRadius),
      ),
    );
  }
}

// ─── Audit Location Detail Sheet ──────────────────────────────────────────────
class AuditLocationDetailSheet extends StatefulWidget {
  final String lang;
  final AuditLocationData5R loc;
  final String levelType;

  const AuditLocationDetailSheet({
    super.key,
    required this.lang,
    required this.loc,
    required this.levelType,
  });

  @override
  State<AuditLocationDetailSheet> createState() =>
      _AuditLocationDetailSheetState();
}

class _AuditLocationDetailSheetState extends State<AuditLocationDetailSheet> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final rows = await _supabase
          .from('audit_result')
          .select('id_result, nilai_audit, tanggal_audit, catatan_audit, id_auditor')
          .eq('level_type', widget.levelType)
          .eq('id_ref', widget.loc.id)
          .order('tanggal_audit', ascending: false)
          .limit(15);

      final auditorIds = List<Map<String, dynamic>>.from(rows)
          .where((r) => r['id_auditor'] != null)
          .map((r) => r['id_auditor'].toString())
          .toSet()
          .toList();
      final Map<String, String> auditorMap = {};
      if (auditorIds.isNotEmpty) {
        final auditorRows = await _supabase
            .from('User')
            .select('id_user, nama')
            .inFilter('id_user', auditorIds);
        for (final a in List<Map<String, dynamic>>.from(auditorRows)) {
          auditorMap[a['id_user'].toString()] = a['nama']?.toString() ?? '-';
        }
      }

      final allIds = List<Map<String, dynamic>>.from(rows)
          .map((r) => r['id_result'].toString())
          .toList();

      final Map<String, List<Map<String, dynamic>>> answersMap = {};
      if (allIds.isNotEmpty) {
        final allAnswers = await _supabase
            .from('audit_answer')
            .select('id_result, jawaban, id_question')
            .inFilter('id_result', allIds)
            .order('created_at');

        final questionIds = List<Map<String, dynamic>>.from(allAnswers)
            .map((a) => a['id_question'].toString())
            .toSet()
            .toList();
        final Map<String, String> questionMap = {};
        if (questionIds.isNotEmpty) {
          final qRows = await _supabase
              .from('audit_question')
              .select('id_question, pertanyaan')
              .inFilter('id_question', questionIds);
          for (final q in List<Map<String, dynamic>>.from(qRows)) {
            questionMap[q['id_question'].toString()] =
                q['pertanyaan']?.toString() ?? '-';
          }
        }
        for (final a in List<Map<String, dynamic>>.from(allAnswers)) {
          final resultId = a['id_result'].toString();
          answersMap.putIfAbsent(resultId, () => []);
          answersMap[resultId]!.add({
            'jawaban': a['jawaban'],
            'audit_question': {
              'pertanyaan':
                  questionMap[a['id_question']?.toString() ?? ''] ?? '-'
            },
          });
        }
      }

      final result = <Map<String, dynamic>>[];
      for (final row in List<Map<String, dynamic>>.from(rows)) {
        final resultId = row['id_result'].toString();
        result.add({
          ...row,
          'auditorName':
              auditorMap[row['id_auditor']?.toString() ?? ''] ?? '-',
          'answers': answersMap[resultId] ?? [],
        });
      }
      if (mounted) setState(() { _history = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _scoreColor(double? s) {
    if (s == null) return const Color(0xFF94A3B8);
    if (s >= 80) return const Color(0xFF10B981);
    if (s >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                Text(widget.loc.name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A8A))),
                Text(widget.loc.pic,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
              ])),
              if (widget.loc.auditScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: _scoreColor(widget.loc.auditScore)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(
                      '${widget.loc.auditScore!.toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _scoreColor(widget.loc.auditScore))),
                ),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF0EA5E9)))
                  : _history.isEmpty
                      ? Center(
                          child: Text(
                              widget.lang == 'EN'
                                  ? 'No audit history.'
                                  : 'Belum ada riwayat audit.',
                              style: const TextStyle(
                                  color: Color(0xFF64748B))))
                      : ListView.separated(
                          controller: ctrl,
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _history.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final h = _history[i];
                            final score = double.tryParse(
                                h['nilai_audit']?.toString() ?? '');
                            final auditor =
                                h['auditorName'] as String? ?? '-';
                            final date =
                                h['tanggal_audit']?.toString() ?? '';
                            final catatan =
                                h['catatan_audit'] as String?;
                            final answers =
                                h['answers'] as List<Map<String, dynamic>>? ??
                                    [];
                            final color = _scoreColor(score);

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                  color: color.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: color.withOpacity(0.3))),
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                              color:
                                                  color.withOpacity(0.12),
                                              shape: BoxShape.circle),
                                          child: Center(
                                              child: Text(
                                                  score != null
                                                      ? '${score.toStringAsFixed(0)}%'
                                                      : '-',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: color)))),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(auditor,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: Color(
                                                        0xFF1E3A8A))),
                                            Text(date,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        Color(0xFF64748B))),
                                            if (catatan != null &&
                                                catatan.isNotEmpty)
                                              Text(catatan,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Color(
                                                          0xFF64748B)),
                                                  maxLines: 2,
                                                  overflow: TextOverflow
                                                      .ellipsis),
                                          ])),
                                    ]),
                                    if (answers.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      const Divider(height: 1),
                                      const SizedBox(height: 6),
                                      ...answers.map((a) {
                                        final jawaban =
                                            a['jawaban'] as bool? ?? false;
                                        final pertanyaan = (a['audit_question']
                                                    as Map<String,
                                                        dynamic>?)?[
                                                'pertanyaan'] ??
                                            '-';
                                        return Padding(
                                          padding: const EdgeInsets
                                              .symmetric(vertical: 3),
                                          child: Row(children: [
                                            Icon(
                                                jawaban
                                                    ? Icons
                                                        .check_circle_rounded
                                                    : Icons.cancel_rounded,
                                                size: 14,
                                                color: jawaban
                                                    ? const Color(
                                                        0xFF10B981)
                                                    : const Color(
                                                        0xFFEF4444)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                                child: Text(pertanyaan,
                                                    style: const TextStyle(
                                                        fontSize: 11.5,
                                                        color: Color(
                                                            0xFF334155)))),
                                          ]),
                                        );
                                      }),
                                    ],
                                  ]),
                            );
                          },
                        )),
        ]),
      ),
    );
  }
}