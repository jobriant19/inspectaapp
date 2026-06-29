import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../audit/audit_evidence_camera_screen.dart';

class AuditNotifTab extends StatefulWidget {
  final String lang;
  final String Function(String) t;

  const AuditNotifTab({super.key, required this.lang, required this.t});

  @override
  State<AuditNotifTab> createState() => _AuditNotifTabState();
}

class _AuditNotifTabState extends State<AuditNotifTab>
    with AutomaticKeepAliveClientMixin {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  DateTime _filterFrom = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _filterTo = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);

  static const _blue = Color(0xFF1D4ED8);
  static const _blueLt = Color(0xFFEFF6FF);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _t(String id, String en, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  Future<void> _fetch() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    setState(() => _isLoading = true);
    try {
      // AUDITOR FETCH
      final auditorRows = await _supabase
          .from('audit_result')
          .select(
            'id_result, level_type, id_ref, tanggal_audit, nilai_audit, '
            'nilai_final, is_finalized, catatan_audit, created_at',
          )
          .eq('id_auditor', userId)
          .gte('created_at', _filterFrom.toIso8601String())
          .lte('created_at', _filterTo.toIso8601String())
          .order('created_at', ascending: false)
          .limit(100);

      final List<Map<String, dynamic>> items = [];
      for (final row in auditorRows as List) {
        final r = Map<String, dynamic>.from(row as Map);
        r['_role'] = 'auditor';
        items.add(r);
      }

      // PIC LOCATION FETCH
      final picLevels = await Future.wait([
        _supabase.from('lokasi').select('id_lokasi').eq('id_pic', userId),
        _supabase.from('unit').select('id_unit').eq('id_pic', userId),
        _supabase.from('subunit').select('id_subunit').eq('id_pic', userId),
        _supabase.from('area').select('id_area').eq('id_pic', userId),
      ]);

      final List<Map<String, String>> picRefs = [];
      for (final r in picLevels[0] as List) { picRefs.add({'level': 'lokasi', 'id': r['id_lokasi'].toString()}); }
      for (final r in picLevels[1] as List) { picRefs.add({'level': 'unit', 'id': r['id_unit'].toString()}); }
      for (final r in picLevels[2] as List) { picRefs.add({'level': 'subunit', 'id': r['id_subunit'].toString()}); }
      for (final r in picLevels[3] as List) { picRefs.add({'level': 'area', 'id': r['id_area'].toString()}); }

      for (final ref in picRefs) {
        final picRows = await _supabase
            .from('audit_result')
            .select(
              'id_result, level_type, id_ref, tanggal_audit, nilai_audit, '
              'nilai_final, is_finalized, catatan_audit, created_at, '
              'Auditor:User!fk_audit_result_auditor(nama)',
            )
            .eq('level_type', ref['level']!)
            .eq('id_ref', ref['id']!)
            .gte('created_at', _filterFrom.toIso8601String())
            .lte('created_at', _filterTo.toIso8601String())
            .order('created_at', ascending: false)
            .limit(30);

        for (final row in picRows as List) {
          final r = Map<String, dynamic>.from(row as Map);
          r['_role'] = 'pic';
          r['_level'] = ref['level'];
          final alreadyExists = items.any((i) => i['id_result'] == r['id_result']);
          if (!alreadyExists) items.add(r);
        }
      }

      // SORT BY created_at 
      items.sort((a, b) {
        final at = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(2000);
        final bt = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(2000);
        return bt.compareTo(at);
      });

      for (final item in items) {
        final levelType = item['level_type']?.toString() ?? item['_level']?.toString() ?? '';
        final idRef = item['id_ref']?.toString() ?? '';
        final idResult = item['id_result']?.toString() ?? '';

        // LOCATION NAME
        if (levelType.isNotEmpty && idRef.isNotEmpty) {
          try {
            final nameCol = 'nama_$levelType';
            final idCol = 'id_$levelType';
            final nameRow = await _supabase
                .from(levelType)
                .select(nameCol)
                .eq(idCol, idRef)
                .maybeSingle();
            item['_location_name'] = nameRow?[nameCol]?.toString() ?? '-';
          } catch (_) {
            item['_location_name'] = '-';
          }
        } else {
          item['_location_name'] = '-';
        }

        try {
          final logs = await _supabase
              .from('log_poin')
              .select('poin, deskripsi, tipe_aktivitas, created_at')
              .eq('id_user', userId)
              .eq('id_result', idResult)
              .order('created_at', ascending: true);
          item['_poin_logs'] = List<Map<String, dynamic>>.from(logs as List);
        } catch (_) {
          item['_poin_logs'] = <Map<String, dynamic>>[];
        }

        // ANSWER, THEME, REPLIES FOR AUDITOR & PIC DETAILS
        try {
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
          item['_answers'] = List<Map<String, dynamic>>.from(answers as List);
        } catch (_) {
          item['_answers'] = <Map<String, dynamic>>[];
        }
      }

      if (mounted) {
        setState(() {
          _allItems = items;
          _isLoading = false;
        });
        _applyFilter(_searchQuery);
      }
    } catch (e) {
      debugPrint('AuditNotifTab fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter(String query) {
    setState(() {
      _searchQuery = query;
      final q = query.toLowerCase().trim();
      if (q.isEmpty) {
        _filtered = List.from(_allItems);
      } else {
        _filtered = _allItems.where((item) {
          final loc = (item['_location_name'] ?? '').toString().toLowerCase();
          final level = (item['level_type'] ?? '').toString().toLowerCase();
          final score = (item['nilai_audit'] ?? '').toString();
          return loc.contains(q) || level.contains(q) || score.contains(q);
        }).toList();
      }
    });
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

  String _monthLabel(DateTime dt) {
    final months = {
      'EN': ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'],
      'ID': ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'],
      'ZH': ['1月','2月','3月','4月','5月','6月','7月','8月','9月','10月','11月','12月'],
    };
    final m = months[widget.lang] ?? months['ID']!;
    return '${m[dt.month - 1]} ${dt.year}';
  }

  Color _scoreColor(double? s) {
    if (s == null) return const Color(0xFF64748B);
    if (s >= 80) return const Color(0xFF10B981);
    if (s >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Future<void> _showPeriodPicker() async {
    DateTime tempFrom = _filterFrom;
    DateTime tempTo = DateTime(_filterTo.year, _filterTo.month, _filterTo.day);
    final now = DateTime.now();
    final years = List.generate(3, (i) => now.year - 1 + i);
    final monthNames = {
      'EN': ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'],
      'ID': ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'],
      'ZH': ['1月','2月','3月','4月','5月','6月','7月','8月','9月','10月','11月','12月'],
    }[widget.lang] ?? ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'];

    Widget buildPicker(DateTime current, ValueChanged<DateTime> onChange, StateSetter setSt) {
      return Row(children: [
        Expanded(
          flex: 3,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _blueLt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _blue.withValues(alpha:0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: current.month - 1,
                icon: Icon(Icons.keyboard_arrow_down, size: 18, color: _blue),
                style: TextStyle(fontSize: 13, color: _blue, fontWeight: FontWeight.w600),
                dropdownColor: Colors.white,
                items: List.generate(12, (i) => DropdownMenuItem(value: i, child: Text(monthNames[i]))),
                onChanged: (v) {
                  if (v != null) setSt(() => onChange(DateTime(current.year, v + 1)));
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _blueLt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _blue.withValues(alpha:0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: current.year,
                icon: Icon(Icons.keyboard_arrow_down, size: 18, color: _blue),
                style: TextStyle(fontSize: 13, color: _blue, fontWeight: FontWeight.w600),
                dropdownColor: Colors.white,
                items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                onChanged: (v) {
                  if (v != null) setSt(() => onChange(DateTime(v, current.month)));
                },
              ),
            ),
          ),
        ),
      ]);
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _blue.withValues(alpha:0.2), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.date_range_rounded, color: _blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _t('Pilih Periode', 'Select Period', '选择期间'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _blue),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
                ]),
                const SizedBox(height: 16),
                Text(_t('Dari', 'From', '从'), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                buildPicker(tempFrom, (d) => tempFrom = d, setSt),
                const SizedBox(height: 14),
                Text(_t('Sampai', 'To', '到'), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                buildPicker(tempTo, (d) => tempTo = d, setSt),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _filterFrom = DateTime(tempFrom.year, tempFrom.month, 1);
                        _filterTo = DateTime(tempTo.year, tempTo.month + 1, 0, 23, 59, 59);
                      });
                      Navigator.pop(ctx);
                      _fetch();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_t('Terapkan', 'Apply', '应用')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final periodLabel = '${_monthLabel(_filterFrom)} – ${_monthLabel(DateTime(_filterTo.year, _filterTo.month))}';

    return Column(
      children: [
        // FILTER BAR
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(children: [
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _blue.withValues(alpha:0.25)),
                ),
                child: Row(children: [
                  Icon(Icons.search, color: _blue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _applyFilter,
                      style: GoogleFonts.poppins(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: _t('Cari lokasi audit…', 'Search audit location…', '搜索审计位置…'),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () { _searchCtrl.clear(); _applyFilter(''); },
                      child: const Icon(Icons.close, size: 16, color: Colors.grey),
                    ),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showPeriodPicker,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(periodLabel,
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                ]),
              ),
            ),
          ]),
        ),

        // CONTENT
        Expanded(
          child: _isLoading
              ? Shimmer.fromColors(
                  baseColor: Colors.grey.shade200,
                  highlightColor: Colors.grey.shade100,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 4,
                    itemBuilder: (_, __) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      height: 110,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                )
              : _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _blue.withValues(alpha:0.08),
                            ),
                            child: Icon(Icons.fact_check_outlined, size: 36, color: _blue.withValues(alpha:0.4)),
                          ),
                          const SizedBox(height: 16),
                          Text(widget.t('empty_audit'),
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E3A8A))),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(widget.t('empty_audit_sub'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      color: _blue,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _buildCard(_filtered[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  // AUDIT NOTIF CARD
  Widget _buildCard(Map<String, dynamic> item) {
    final score = double.tryParse(item['nilai_audit']?.toString() ?? '');
    final scoreFinal = double.tryParse(item['nilai_final']?.toString() ?? '');
    final isFinalized = item['is_finalized'] == true;
    final displayScore = isFinalized ? scoreFinal : score;
    final scoreColor = _scoreColor(displayScore);
    final locationName = item['_location_name']?.toString() ?? '-';
    final levelType = item['level_type']?.toString() ?? '';
    final date = _formatDate(item['tanggal_audit']);
    final answers = (item['_answers'] as List<Map<String, dynamic>>?) ?? [];
    final role = item['_role']?.toString() ?? 'auditor';
    final isPic = role == 'pic';
    final auditorData = item['Auditor'] as Map<String, dynamic>?;
    final auditorName = auditorData?['nama']?.toString() ?? '';
    final idResult = item['id_result']?.toString() ?? '';
    final userId = _supabase.auth.currentUser?.id ?? '';

    final noAnswers = answers.where((a) => a['jawaban'] == false).toList();
    final allNoConfirmed = noAnswers.isNotEmpty &&
        noAnswers.every((a) {
          final replies = (a['Replies'] as List?) ?? [];
          return replies.any((r) => r['is_confirmed'] == true);
        });

    final effectiveScore =
        (noAnswers.isNotEmpty && allNoConfirmed) ? 100.0 : displayScore;
    final effectiveScoreColor =
        _scoreColor(noAnswers.isNotEmpty && allNoConfirmed ? 100.0 : displayScore);
    final showScore = noAnswers.isEmpty || allNoConfirmed;

    final poinLogs = (item['_poin_logs'] as List<Map<String, dynamic>>?) ?? [];
    final showPoinLogs = true;

    int totalPoin = 0;
    if (showPoinLogs) {
      for (final l in poinLogs) {
        totalPoin += ((l['poin'] as num?)?.toInt() ?? 0);
      }
    }

    final expanded = ValueNotifier<bool>(false);

    return ValueListenableBuilder<bool>(
      valueListenable: expanded,
      builder: (_, isExpanded, __) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: showScore
                ? scoreColor.withValues(alpha:0.25)
                : const Color(0xFFF59E0B).withValues(alpha:0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha:0.04),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            // HEADER
            GestureDetector(
              onTap: () => expanded.value = !isExpanded,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      color: showScore
                          ? effectiveScoreColor.withValues(alpha:0.12)
                          : const Color(0xFFF59E0B).withValues(alpha:0.1),
                      shape: BoxShape.circle,
                    ),
                    child: showScore
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  effectiveScore != null
                                      ? '${effectiveScore.toStringAsFixed(0)}%'
                                      : '-',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: effectiveScoreColor),
                                ),
                                if (isFinalized || allNoConfirmed)
                                  Text(_t('Final', 'Final', '最终'),
                                      style: GoogleFonts.poppins(
                                          fontSize: 8,
                                          color: effectiveScoreColor)),
                              ],
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.pending_actions_rounded,
                                    size: 20, color: Color(0xFFF59E0B)),
                                Text(
                                  _t('Proses', 'WIP', '进行中'),
                                  style: GoogleFonts.poppins(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFF59E0B)),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPic
                                  ? const Color(0xFF10B981).withValues(alpha:0.12)
                                  : _blue.withValues(alpha:0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isPic ? _t('PIC', 'PIC', 'PIC') : _t('Auditor', 'Auditor', '审计员'),
                              style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: isPic ? const Color(0xFF10B981) : _blue),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _blue.withValues(alpha:0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(levelType.toUpperCase(),
                                style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: _blue)),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(locationName,
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E3A8A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                        const SizedBox(height: 3),
                        Row(children: [
                          Text(date,
                              style: GoogleFonts.poppins(
                                  fontSize: 10, color: Colors.grey.shade400)),
                          if (isPic && auditorName.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '· ${_t('oleh', 'by', '由')} $auditorName',
                                style: GoogleFonts.poppins(
                                    fontSize: 10, color: Colors.grey.shade500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          // Badge poin hanya jika showPoinLogs dan ada poin
                          if (totalPoin != 0 && showPoinLogs) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: totalPoin > 0
                                    ? const Color(0xFF10B981).withValues(alpha:0.12)
                                    : const Color(0xFFEF4444).withValues(alpha:0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                totalPoin > 0 ? '+$totalPoin poin' : '$totalPoin poin',
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: totalPoin > 0
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444)),
                              ),
                            ),
                          ],
                          if (!showScore) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha:0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFFF59E0B).withValues(alpha:0.4)),
                              ),
                              child: Text(
                                _t('Perlu Perbaikan', 'Needs Fix', '需要修复'),
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFF59E0B)),
                              ),
                            ),
                          ],
                        ]),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _blue,
                    size: 22,
                  ),
                ]),
              ),
            ),

            // EXPAND DETAIL
            if (isExpanded) ...[
              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // POINT LOG
              if (poinLogs.isNotEmpty && showPoinLogs)
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      const Color(0xFF10B981).withValues(alpha:0.08),
                      _blue.withValues(alpha:0.05),
                    ]),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha:0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.emoji_events_rounded,
                            color: Color(0xFF10B981), size: 15),
                        const SizedBox(width: 6),
                        Text(
                          isPic
                              ? _t('Bonus Poin PIC', 'PIC Bonus Points', 'PIC奖励积分')
                              : _t('Poin Diperoleh', 'Points Earned', '获得积分'),
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF10B981)),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      ...poinLogs.map((log) {
                        final p = (log['poin'] as num?)?.toInt() ?? 0;
                        final isPos = p >= 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isPos
                                    ? const Color(0xFF10B981).withValues(alpha:0.12)
                                    : const Color(0xFFEF4444).withValues(alpha:0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(isPos ? '+$p' : '$p',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: isPos
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444))),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(log['deskripsi']?.toString() ?? '',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: const Color(0xFF1E3A8A)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ]),
                        );
                      }),
                    ],
                  ),
                ),

              // ANSWER IS NO + THREAD REPLY
              if (noAnswers.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 14, color: Color(0xFFEF4444)),
                    const SizedBox(width: 6),
                    Text(
                      '${noAnswers.length} ${_t('pertanyaan perlu perbaikan', 'questions need fix', '个问题需要修复')}',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFEF4444)),
                    ),
                  ]),
                ),
                ...noAnswers.map((ans) =>
                    _buildAnswerThreadFull(ans, idResult, isPic, userId)),
              ],

              // ALL SUMMARY ANSWER
              if (answers.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: Row(children: [
                    Icon(Icons.list_alt_rounded, size: 14, color: _blue),
                    const SizedBox(width: 6),
                    Text(
                      _t('Ringkasan Jawaban', 'Answer Summary', '回答摘要'),
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _blue),
                    ),
                  ]),
                ),
                _buildAnswerSummary(answers),
              ],

              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerThreadFull(
      Map<String, dynamic> ans,
      String idResult,
      bool isPic,
      String userId) {
    final q = ans['Question'] as Map<String, dynamic>?;
    final replies = (ans['Replies'] as List?)
            ?.map((r) => Map<String, dynamic>.from(r as Map))
            .toList() ??
        [];
    final gambar = ans['gambar_jawaban']?.toString() ?? '';
    final catatan = ans['catatan']?.toString() ?? '';
    final idAnswer = ans['id_answer']?.toString() ?? '';

    // IS PIC REPLY CONRIRMED BY AUDITOR ?
    final confirmedReplies = replies.where((r) => r['is_confirmed'] == true).toList();
    final isFullyConfirmed = confirmedReplies.isNotEmpty;

    String questionText;
    if (widget.lang == 'EN') {
      questionText = q?['pertanyaan_en']?.toString() ??
          q?['pertanyaan']?.toString() ?? '-';
    } else if (widget.lang == 'ZH') {
      questionText = q?['pertanyaan_zh']?.toString() ??
          q?['pertanyaan']?.toString() ?? '-';
    } else {
      questionText = q?['pertanyaan']?.toString() ?? '-';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFullyConfirmed
            ? const Color(0xFF10B981).withValues(alpha:0.05)
            : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFullyConfirmed
              ? const Color(0xFF10B981).withValues(alpha:0.3)
              : const Color(0xFFEF4444).withValues(alpha:0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // QUESTION
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: isFullyConfirmed
                      ? const Color(0xFF10B981).withValues(alpha:0.1)
                      : const Color(0xFFEF4444).withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFullyConfirmed ? Icons.check_rounded : Icons.close_rounded,
                  size: 12,
                  color: isFullyConfirmed
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(questionText,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E3A8A))),
              ),
            ],
          ),

          // AUDITOR EVIDENCE IMAGE
          if (gambar.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(gambar,
                  height: 120, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          ],
          if (catatan.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _t('Catatan', 'Notes', '备注'),
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha:0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(catatan,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: const Color(0xFF64748B))),
            ),
          ],

          // REPLIES LIST
          if (replies.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 8),
            ...replies.map((reply) {
              final confirmed = reply['is_confirmed'] == true;
              final picData = reply['PIC'] as Map<String, dynamic>?;
              final picName = picData?['nama']?.toString() ?? '-';
              final replyGambar = reply['gambar_reply']?.toString() ?? '';
              final replyCatatan = reply['catatan_reply']?.toString() ?? '';
              final idReply = reply['id_reply']?.toString() ?? '';
              final replyOwnerId = reply['id_pic']?.toString();
              final isOwnReply = replyOwnerId != null && replyOwnerId == userId;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: confirmed
                      ? const Color(0xFF10B981).withValues(alpha:0.07)
                      : const Color(0xFF6366F1).withValues(alpha:0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: confirmed
                        ? const Color(0xFF10B981).withValues(alpha:0.3)
                        : const Color(0xFF6366F1).withValues(alpha:0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(
                        confirmed ? Icons.verified_rounded : Icons.reply_rounded,
                        size: 13,
                        color: confirmed
                            ? const Color(0xFF10B981)
                            : const Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          confirmed
                              ? '$picName ✓ ${_t('Dikonfirmasi', 'Confirmed', '已确认')}'
                              : picName,
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: confirmed
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF6366F1)),
                        ),
                      ),
                      if (isPic && !confirmed && isOwnReply) ...[
                        GestureDetector(
                          onTap: () => _showEditReplySheet(
                              idReply, idAnswer, idResult, userId, reply),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: _blue.withValues(alpha:0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.edit_rounded,
                                size: 13, color: _blue),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _deleteReply(idReply),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha:0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                size: 13, color: Color(0xFFEF4444)),
                          ),
                        ),
                      ],
                    ]),

                    if (replyCatatan.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(replyCatatan,
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF1E3A8A))),
                    ],
                    if (replyGambar.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(replyGambar,
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink()),
                      ),
                    ],

                    if (!isPic && !confirmed && !isOwnReply) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _confirmReply(idReply, idAnswer, idResult),
                            icon: const Icon(Icons.check_circle_rounded, size: 14),
                            label: Text(
                              _t('Konfirmasi', 'Confirm', '确认'),
                              style: GoogleFonts.poppins(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showAuditorReplySheet(
                                idReply, idAnswer, idResult, userId),
                            icon: const Icon(Icons.reply_rounded, size: 14),
                            label: Text(
                              _t('Balas', 'Reply', '回复'),
                              style: GoogleFonts.poppins(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _blue,
                              side: BorderSide(color: _blue),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
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

          // REPLY BUTTON ONLY FOR PIC NOT YET CONFIRMED
          if (isPic && !isFullyConfirmed) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _showReplyBottomSheet(ans, idResult, true, userId),
                icon: const Icon(Icons.reply_rounded, size: 14),
                label: Text(
                  replies.isEmpty
                      ? _t('Balas Temuan', 'Reply Finding', '回复发现')
                      : _t('Tambah Balasan', 'Add Reply', '添加回复'),
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  side: const BorderSide(color: Color(0xFF6366F1)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],

          // AUDIT INFO WAITING FOR PIC REPLY
          if (!isPic && replies.isEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha:0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha:0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.hourglass_top_rounded,
                    size: 13, color: Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _t(
                      'Menunggu balasan PIC…',
                      'Waiting for PIC reply…',
                      '等待PIC回复…',
                    ),
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: const Color(0xFFF59E0B)),
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  /// PIC REPLY BOTTOM SHEET IMAGE + NOTES REQUIRED
  Future<void> _showReplyBottomSheet(
      Map<String, dynamic> ans,
      String idResult,
      bool isPic,
      String userId) async {
    final noteCtrl = TextEditingController();
    String? photoUrl;
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
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
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.reply_rounded,
                        color: Color(0xFF6366F1), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t('Balas Temuan', 'Reply Finding', '回复发现'),
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E3A8A)),
                        ),
                        Text(
                          _t(
                            'Sertakan bukti foto dan penjelasan tindakan perbaikan.',
                            'Include photo evidence and corrective action description.',
                            '请附上照片证据和纠正措施说明。',
                          ),
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E3A8A)),
                    children: const [
                      TextSpan(text: 'Foto Bukti Perbaikan'),
                      TextSpan(
                          text: ' *',
                          style: TextStyle(color: Color(0xFFEF4444))),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final url = await Navigator.push<String>(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => AuditEvidenceCameraScreen(
                          lang: widget.lang,
                          questionText: '',
                        ),
                      ),
                    );
                    if (url != null) setSt(() => photoUrl = url);
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: photoUrl == null
                            ? const Color(0xFFEF4444).withValues(alpha:0.4)
                            : const Color(0xFF6366F1).withValues(alpha:0.5),
                      ),
                    ),
                    child: photoUrl == null
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Column(children: [
                              const Icon(Icons.add_a_photo_rounded,
                                  color: Color(0xFF6366F1), size: 22),
                              const SizedBox(height: 4),
                              Text(
                                _t('Ambil / Upload Foto *',
                                    'Take / Upload Photo *', '拍照/上传照片 *'),
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6366F1)),
                              ),
                              Text(
                                _t('Wajib diisi', 'Required', '必填'),
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: const Color(0xFFEF4444)),
                              ),
                            ]),
                          )
                        : Stack(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(photoUrl!,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 6, right: 6,
                              child: GestureDetector(
                                onTap: () => setSt(() => photoUrl = null),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha:0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ]),
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E3A8A)),
                    children: const [
                      TextSpan(text: 'Keterangan Tindakan Perbaikan'),
                      TextSpan(
                          text: ' *',
                          style: TextStyle(color: Color(0xFFEF4444))),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: _t(
                      'Jelaskan tindakan perbaikan yang telah dilakukan…',
                      'Describe corrective action taken…',
                      '描述已采取的纠正措施…',
                    ),
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF6366F1), width: 1.5)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            if (photoUrl == null) {
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                content: Text(_t(
                                    'Upload foto bukti perbaikan terlebih dahulu.',
                                    'Please upload fix evidence photo.',
                                    '请先上传修复证据照片。')),
                                backgroundColor: const Color(0xFFEF4444),
                              ));
                              return;
                            }
                            if (noteCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                content: Text(_t(
                                    'Keterangan tindakan perbaikan wajib diisi.',
                                    'Corrective action description is required.',
                                    '请填写纠正措施说明。')),
                                backgroundColor: const Color(0xFFEF4444),
                              ));
                              return;
                            }
                            setSt(() => submitting = true);
                            try {
                              await _supabase.from('audit_answer_reply').insert({
                                'id_answer': ans['id_answer'],
                                'id_pic': userId,
                                'catatan_reply': noteCtrl.text.trim(),
                                'gambar_reply': photoUrl,
                                'is_confirmed': false,
                              });

                              // AUDITOR NOTIF IF PIC DONE REPLY
                              final picUserData = await _supabase
                                  .from('User')
                                  .select('nama')
                                  .eq('id_user', userId)
                                  .maybeSingle();
                              final picName =
                                  picUserData?['nama']?.toString() ?? '-';
                              await _notifyAuditor(idResult, picName);

                              if (ctx.mounted) Navigator.pop(ctx);
                              _fetch();
                            } catch (e) {
                              setSt(() => submitting = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Error: $e')));
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: submitting
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            _t('Kirim Balasan', 'Send Reply', '发送回复'),
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
  }

  /// REPLY EDIT FOR PIC NOT YET CONFIRMED 
  Future<void> _showEditReplySheet(
      String idReply,
      String idAnswer,
      String idResult,
      String userId,
      Map<String, dynamic> existingReply) async {
    final noteCtrl = TextEditingController(
        text: existingReply['catatan_reply']?.toString() ?? '');
    String? photoUrl = existingReply['gambar_reply']?.toString();
    if (photoUrl != null && photoUrl.isEmpty) photoUrl = null;
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
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
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _blue.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.edit_rounded, color: _blue, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _t('Edit Balasan', 'Edit Reply', '编辑回复'),
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E3A8A)),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E3A8A)),
                    children: const [
                      TextSpan(text: 'Foto Bukti Perbaikan'),
                      TextSpan(
                          text: ' *',
                          style: TextStyle(color: Color(0xFFEF4444))),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final url = await Navigator.push<String>(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => AuditEvidenceCameraScreen(
                          lang: widget.lang,
                          questionText: '',
                        ),
                      ),
                    );
                    if (url != null) setSt(() => photoUrl = url);
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: photoUrl == null
                            ? const Color(0xFFEF4444).withValues(alpha:0.4)
                            : const Color(0xFF6366F1).withValues(alpha:0.5),
                      ),
                    ),
                    child: photoUrl == null
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Column(children: [
                              const Icon(Icons.add_a_photo_rounded,
                                  color: Color(0xFF6366F1), size: 22),
                              const SizedBox(height: 4),
                              Text(
                                _t('Ambil / Upload Foto *',
                                    'Take / Upload Photo *', '拍照/上传照片 *'),
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6366F1)),
                              ),
                            ]),
                          )
                        : Stack(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(photoUrl!,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 6, right: 6,
                              child: GestureDetector(
                                onTap: () => setSt(() => photoUrl = null),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha:0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ]),
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E3A8A)),
                    children: const [
                      TextSpan(text: 'Keterangan Tindakan Perbaikan'),
                      TextSpan(
                          text: ' *',
                          style: TextStyle(color: Color(0xFFEF4444))),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: _t(
                      'Jelaskan tindakan perbaikan…',
                      'Describe corrective action…',
                      '描述纠正措施…',
                    ),
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF6366F1), width: 1.5)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            if (photoUrl == null) {
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                content: Text(_t(
                                    'Upload foto bukti perbaikan terlebih dahulu.',
                                    'Please upload fix evidence photo.',
                                    '请先上传修复证据照片。')),
                                backgroundColor: const Color(0xFFEF4444),
                              ));
                              return;
                            }
                            if (noteCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                content: Text(_t(
                                    'Keterangan tindakan perbaikan wajib diisi.',
                                    'Corrective action description is required.',
                                    '请填写纠正措施说明。')),
                                backgroundColor: const Color(0xFFEF4444),
                              ));
                              return;
                            }
                            setSt(() => submitting = true);
                            try {
                              await _supabase
                                  .from('audit_answer_reply')
                                  .update({
                                'catatan_reply': noteCtrl.text.trim(),
                                'gambar_reply': photoUrl,
                              }).eq('id_reply', idReply);
                              if (ctx.mounted) Navigator.pop(ctx);
                              _fetch();
                            } catch (e) {
                              setSt(() => submitting = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Error: $e')));
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: submitting
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            _t('Simpan Perubahan', 'Save Changes', '保存更改'),
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
  }

  /// DELETE REPLY FOR PIC NOT YET CONFIRMED
  Future<void> _deleteReply(String idReply) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _t('Hapus Balasan', 'Delete Reply', '删除回复'),
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E3A8A)),
        ),
        content: Text(
          _t('Balasan ini akan dihapus. Lanjutkan?',
              'This reply will be deleted. Continue?', '此回复将被删除。是否继续？'),
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t('Batal', 'Cancel', '取消'),
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(_t('Hapus', 'Delete', '删除'),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await _supabase
          .from('audit_answer_reply')
          .delete()
          .eq('id_reply', idReply);
      _fetch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ));
      }
    }
  }

  /// AUDITOR REPLY BOTTOM SHEET FOR PIC REPLY NOT YET CONFIRMED
  Future<void> _showAuditorReplySheet(
      String idReply,
      String idAnswer,
      String idResult,
      String userId) async {
    final noteCtrl = TextEditingController();
    String? photoUrl;
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
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
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _blue.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.reply_rounded, color: _blue, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t('Balas Perbaikan', 'Reply to Fix', '回复修复'),
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E3A8A)),
                        ),
                        Text(
                          _t(
                            'Jelaskan jika perbaikan belum sesuai — PIC akan menerima balasan ini dan bisa memperbaiki lagi.',
                            'Explain if the fix is not sufficient yet — PIC will receive this and can fix it again.',
                            '说明修复是否仍不充分——PIC将收到此回复并可以再次修复。',
                          ),
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final url = await Navigator.push<String>(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => AuditEvidenceCameraScreen(
                          lang: widget.lang,
                          questionText: '',
                        ),
                      ),
                    );
                    if (url != null) setSt(() => photoUrl = url);
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _blue.withValues(alpha:0.3)),
                    ),
                    child: photoUrl == null
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Column(children: [
                              Icon(Icons.add_a_photo_rounded, color: _blue, size: 22),
                              const SizedBox(height: 4),
                              Text(
                                _t('Upload Foto (opsional)',
                                    'Upload Photo (optional)', '上传照片（可选）'),
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _blue),
                              ),
                            ]),
                          )
                        : Stack(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(photoUrl!,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 6, right: 6,
                              child: GestureDetector(
                                onTap: () => setSt(() => photoUrl = null),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha:0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ]),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: _t(
                      'Jelaskan kekurangan perbaikan ini (wajib)…',
                      'Describe what is still lacking (required)…',
                      '说明此修复仍存在的问题（必填）…',
                    ),
                    hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _blue, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: submitting
                        ? null
                        : () async {
                            if (noteCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                content: Text(_t(
                                    'Catatan wajib diisi.',
                                    'Note is required.',
                                    '备注为必填项。')),
                                backgroundColor: const Color(0xFFEF4444),
                              ));
                              return;
                            }
                            setSt(() => submitting = true);
                            try {
                              await _supabase.from('audit_answer_reply').insert({
                                'id_answer': idAnswer,
                                'id_pic': userId,
                                'catatan_reply': noteCtrl.text.trim(),
                                'gambar_reply': photoUrl,
                                'is_confirmed': false,
                              });

                              // ── Notif ke PIC: Auditor membalas (bukan confirm) ──
                              final auditorUserData = await _supabase
                                  .from('User')
                                  .select('nama')
                                  .eq('id_user', userId)
                                  .maybeSingle();
                              final auditorName =
                                  auditorUserData?['nama']?.toString() ?? '-';
                              await _notifyPicFromAuditor(
                                idResult: idResult,
                                auditorName: auditorName,
                                isConfirm: false,
                              );

                              if (ctx.mounted) Navigator.pop(ctx);
                              _fetch();
                            } catch (e) {
                              setSt(() => submitting = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Error: $e')));
                              }
                            }
                          },
                    icon: submitting
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, size: 16),
                    label: Text(
                      submitting ? '' : _t('Kirim Balasan', 'Send Reply', '发送回复'),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// SEND PUSH NOTIF TO AUDITOR WHEN PIC REPLY
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

      final auditorData = await _supabase
          .from('User')
          .select('fcm_token')
          .eq('id_user', auditorId)
          .maybeSingle();

      final fcmToken = auditorData?['fcm_token']?.toString();
      if (fcmToken == null || fcmToken.trim().isEmpty) return;

      // GET LOCATION NAME
      final levelType = resultRow['level_type']?.toString() ?? '';
      final idRef = resultRow['id_ref']?.toString() ?? '';
      String locationName = '-';
      if (levelType.isNotEmpty && idRef.isNotEmpty) {
        try {
          final nameCol = 'nama_$levelType';
          final idCol = 'id_$levelType';
          final locRow = await _supabase
              .from(levelType)
              .select(nameCol)
              .eq(idCol, idRef)
              .maybeSingle();
          locationName = locRow?[nameCol]?.toString() ?? '-';
        } catch (_) {}
      }

      final notifTitle = _t(
        '🔧 PIC Membalas Temuan',
        '🔧 PIC Replied to Finding',
        '🔧 PIC已回复发现',
      );
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

  /// SEND PUSH NOTIF TO PIC WHEN AUDITOR HAS BEEN CONFIRM OR REPLY 
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

      final locRow = await _supabase
          .from(levelType)
          .select('id_pic, $nameCol')
          .eq(idCol, idRef)
          .maybeSingle();

      final picId = locRow?['id_pic']?.toString();
      final locationName = locRow?[nameCol]?.toString() ?? '-';
      if (picId == null) return;

      final picData = await _supabase
          .from('User')
          .select('fcm_token')
          .eq('id_user', picId)
          .maybeSingle();

      final fcmToken = picData?['fcm_token']?.toString();
      if (fcmToken == null || fcmToken.trim().isEmpty) return;

      final String notifTitle;
      final String notifBody;

      if (isConfirm) {
        notifTitle = _t(
          '✅ Perbaikan Dikonfirmasi!',
          '✅ Fix Confirmed!',
          '✅ 整改已确认！',
        );
        notifBody = _t(
          'Auditor $auditorName telah mengkonfirmasi perbaikan Anda untuk $locationName. Poin bonus telah ditambahkan!',
          'Auditor $auditorName has confirmed your fix for $locationName. Bonus points have been added!',
          '审计员 $auditorName 已确认您对 $locationName 的整改。已添加奖励积分！',
        );
      } else {
        notifTitle = _t(
          '💬 Auditor Membalas Temuan',
          '💬 Auditor Replied to Finding',
          '💬 审计员已回复发现',
        );
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

  Future<void> _confirmReply(
      String idReply, String idAnswer, String idResult) async {
    try {
      // UPDATE REPLY → is_confirmed: true
      await _supabase
          .from('audit_answer_reply')
          .update({
            'is_confirmed': true,
            'confirmed_at': DateTime.now().toIso8601String(),
          })
          .eq('id_reply', idReply);

      // CHECK RESULT FINALIZED
      final resultRow = await _supabase
          .from('audit_result')
          .select('is_finalized, level_type, id_ref, id_auditor')
          .eq('id_result', idResult)
          .maybeSingle();

      if (resultRow == null || resultRow['is_finalized'] == true) {
        _fetch();
        return;
      }

      // GET ALL ANSWER NO & CHECK ARE ALL CONFIRMED
      final allAnswers = await _supabase
          .from('audit_answer')
          .select('id_answer, jawaban, Replies:audit_answer_reply(is_confirmed)')
          .eq('id_result', idResult);

      final noAnswers = (allAnswers as List)
          .where((a) => a['jawaban'] == false)
          .toList();

      final allNoConfirmed = noAnswers.isNotEmpty &&
          noAnswers.every((a) {
            final replies = (a['Replies'] as List?) ?? [];
            return replies.any((r) => r['is_confirmed'] == true);
          });

      if (!allNoConfirmed) {
        _fetch();
        return;
      }

      // ALL NO ANSWER CONFIRMED → SEND AUDIT_BONUS_PIC TO PIC
      final levelType = resultRow['level_type'].toString();
      final idRef = resultRow['id_ref'].toString();
      final nameCol = 'nama_$levelType';
      final idCol = 'id_$levelType';

      final locRow = await _supabase
          .from(levelType)
          .select('id_pic, $nameCol')
          .eq(idCol, idRef)
          .maybeSingle();

      final picId = locRow?['id_pic']?.toString();
      final lokasiName = locRow?[nameCol]?.toString() ?? '-';

      if (picId != null) {
        final cfgRow = await _supabase
            .from('konfigurasi_poin')
            .select('poin, deskripsi_template')
            .eq('kode', 'AUDIT_BONUS_PIC')
            .eq('is_aktif', true)
            .maybeSingle();

        if (cfgRow != null) {
          final deskripsi = (cfgRow['deskripsi_template'] as String)
              .replaceAll('{lokasi}', lokasiName);

          await _supabase.from('log_poin').insert({
            'id_user': picId,
            'poin': cfgRow['poin'] as int,
            'deskripsi': deskripsi,
            'tipe_aktivitas': 'audit_bonus_pic',
            'id_result': idResult,
          });
        }
      }

      // NOTIF TO PIC FOR SUCCESS CONFIRM + ACCEPT BONUS
      final auditorId = resultRow['id_auditor']?.toString() ?? '';
      if (auditorId.isNotEmpty) {
        final auditorUserData = await _supabase
            .from('User')
            .select('nama')
            .eq('id_user', auditorId)
            .maybeSingle();
        final auditorName = auditorUserData?['nama']?.toString() ?? '-';
        await _notifyPicFromAuditor(
          idResult: idResult,
          auditorName: auditorName,
          isConfirm: true,
        );
      }

      await _supabase
          .from('audit_result')
          .update({'is_finalized': true})
          .eq('id_result', idResult);

      _fetch();
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

  /// ALL ANSWER SUMMARY 
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

    return Column(
      children: byTema.entries.map((entry) {
        final temaName = entry.key;
        final temaAnswers = entry.value;
        final yes = temaAnswers.where((a) => a['jawaban'] == true).length;
        final total = temaAnswers.length;
        final is100 = yes == total;
        Color temaColor = is100 ? const Color(0xFF10B981) : const Color(0xFFEF4444);

        return Container(
          margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
          decoration: BoxDecoration(
            color: is100
                ? const Color(0xFF10B981).withValues(alpha:0.04)
                : const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: temaColor.withValues(alpha:0.2)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(children: [
                  Icon(
                      is100 ? Icons.check_circle_rounded : Icons.topic_outlined,
                      size: 13, color: temaColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(temaName,
                        style: GoogleFonts.poppins(
                            fontSize: 11, fontWeight: FontWeight.w700, color: temaColor)),
                  ),
                  Text('$yes/$total',
                      style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w700, color: temaColor)),
                ]),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}