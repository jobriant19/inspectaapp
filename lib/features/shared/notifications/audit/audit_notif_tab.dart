import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../admin/target/target/admin_target_pick_date.dart';
import 'audit_notif_detail.dart';

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
  DateTime _filterTo = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  // NEW: state pagination — 7 card per halaman
  int _currentPage = 1;
  static const int _perPage = 7;

  static const _blue = Color(0xFF1D4ED8);
  // NEW: warna khusus tombol pilih periode & popup kalender
  static const _periodBlue = Color(0xFF1D72F3);

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

  bool _periodeOverlapsFilter(Map<String, dynamic> row) {
    final schedule = row['Schedule'] as Map<String, dynamic>?;
    if (schedule == null) return false;
    final mulai = DateTime.tryParse(schedule['periode_mulai']?.toString() ?? '');
    final selesai = DateTime.tryParse(schedule['periode_selesai']?.toString() ?? '');
    if (mulai == null || selesai == null) return false;
    final filterFrom = DateTime(_filterFrom.year, _filterFrom.month, _filterFrom.day);
    final filterTo = DateTime(_filterTo.year, _filterTo.month, _filterTo.day, 23, 59, 59);
    return !selesai.isBefore(filterFrom) && !mulai.isAfter(filterTo);
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
            'nilai_final, is_finalized, catatan_audit, created_at, '
            'Schedule:audit_schedule!fk_audit_result_schedule(periode_mulai, periode_selesai)',
          )
          .eq('id_auditor', userId)
          .order('created_at', ascending: false)
          .limit(100);

      final List<Map<String, dynamic>> items = [];
      for (final row in auditorRows as List) {
        final r = Map<String, dynamic>.from(row as Map);
        r['_role'] = 'auditor';
        if (_periodeOverlapsFilter(r)) items.add(r);
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
              'Auditor:User!fk_audit_result_auditor(nama), '
              'Schedule:audit_schedule!fk_audit_result_schedule(periode_mulai, periode_selesai)',
            )
            .eq('level_type', ref['level']!)
            .eq('id_ref', ref['id']!)
            .order('created_at', ascending: false)
            .limit(30);

        for (final row in picRows as List) {
          final r = Map<String, dynamic>.from(row as Map);
          r['_role'] = 'pic';
          r['_level'] = ref['level'];
          if (!_periodeOverlapsFilter(r)) continue;
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
      _currentPage = 1; // NEW: reset ke halaman 1 setiap kali search berubah
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

  // NEW: reset pencarian saja (dipakai tombol reset di search bar & empty state)
  void _resetSearch() {
    _searchCtrl.clear();
    _applyFilter('');
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

  String _fmtFilterDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  Color _scoreColor(double? s) {
    if (s == null) return const Color(0xFF64748B);
    if (s >= 80) return const Color(0xFF10B981);
    if (s >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Future<void> _showPeriodPicker() async {
    DateTime tempFrom = _filterFrom;
    DateTime tempTo = _filterTo;

    Widget dateField({
      required String label,
      required IconData labelIcon,
      required DateTime value,
      required VoidCallback onTap,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(labelIcon, size: 13, color: _periodBlue),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ]),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 48,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _periodBlue.withValues(alpha:0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _periodBlue.withValues(alpha:0.35)),
              ),
              child: Row(children: [
                Icon(Icons.event_rounded, size: 17, color: _periodBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DateFormat('EEE, d MMM yyyy').format(value),
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0C3A8C)),
                  ),
                ),
                Icon(Icons.keyboard_arrow_right_rounded, size: 18, color: _periodBlue),
              ]),
            ),
          ),
        ],
      );
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
              border: Border.all(color: _periodBlue.withValues(alpha:0.2), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: _periodBlue.withValues(alpha:0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.date_range_rounded, color: _periodBlue, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _t('Pilih Periode', 'Select Period', '选择期间'),
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0C3A8C)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                    ),
                  ),
                ]),
                const SizedBox(height: 18),

                // Kolom "Dari" — klik untuk buka kalender penuh
                dateField(
                  label: _t('Dari', 'From', '从'),
                  labelIcon: Icons.play_circle_outline_rounded,
                  value: tempFrom,
                  onTap: () async {
                    final picked = await showAdminTargetDatePicker(
                      context: ctx,
                      lang: widget.lang,
                      initialDate: tempFrom,
                    );
                    if (picked != null) {
                      setSt(() {
                        tempFrom = picked;
                        if (tempTo.isBefore(tempFrom)) tempTo = tempFrom;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Kolom "Sampai" — klik untuk buka kalender penuh
                dateField(
                  label: _t('Sampai', 'To', '到'),
                  labelIcon: Icons.flag_circle_rounded,
                  value: tempTo,
                  onTap: () async {
                    final picked = await showAdminTargetDatePicker(
                      context: ctx,
                      lang: widget.lang,
                      initialDate: tempTo,
                    );
                    if (picked != null) {
                      setSt(() {
                        tempTo = picked;
                        if (tempFrom.isAfter(tempTo)) tempFrom = tempTo;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _filterFrom = tempFrom;
                        _filterTo = tempTo;
                      });
                      Navigator.pop(ctx);
                      _fetch();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _periodBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(_t('Terapkan', 'Apply', '应用'),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
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
    final periodLabel = '${_fmtFilterDate(_filterFrom)} – ${_fmtFilterDate(_filterTo)}';

    // NEW: hitung pagination — 7 card per halaman
    final totalPages = _filtered.isEmpty ? 1 : (_filtered.length / _perPage).ceil();
    final safePage = _currentPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * _perPage;
    final endIdx = (startIdx + _perPage) > _filtered.length ? _filtered.length : startIdx + _perPage;
    final pagedItems = _filtered.isEmpty ? <Map<String, dynamic>>[] : _filtered.sublist(startIdx, endIdx);

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
                      onTap: _resetSearch,
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
                  color: _periodBlue,
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
                  ? (_searchQuery.trim().isNotEmpty
                      ? _buildSearchEmptyState()
                      : _buildEmptyState())
                  : Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _fetch,
                            color: _blue,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              itemCount: pagedItems.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) => _buildCard(pagedItems[i]),
                            ),
                          ),
                        ),
                        // NEW: bottom page indicator — 7 card per halaman
                        if (totalPages > 1)
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              16, 4, 16, MediaQuery.of(context).viewPadding.bottom + 12,
                            ),
                            child: _AuditPageIndicator(
                              currentPage: safePage,
                              totalPages: totalPages,
                              onPageChanged: (p) => setState(() => _currentPage = p),
                              color: _blue,
                            ),
                          )
                        else
                          const SizedBox(height: 12),
                      ],
                    ),
        ),
      ],
    );
  }

  // NEW: empty state umum — tidak ada data audit sama sekali di periode ini
  Widget _buildEmptyState() {
    return Center(
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
    );
  }

  // NEW: empty state khusus saat pencarian tidak menemukan hasil
  Widget _buildSearchEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              height: 140,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha:0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.search_off_rounded, size: 46, color: _blue.withValues(alpha:0.4)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _t('Audit Tidak Ditemukan', 'No matching audit', '未找到匹配的审计'),
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: _blue),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _t(
                'Coba ubah kata kunci pencarian untuk menemukan yang Anda cari.',
                "Try adjusting your search keyword to find what you're looking for.",
                '尝试调整搜索关键词以查找您需要的内容。',
              ),
              style: GoogleFonts.poppins(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.grey.shade500, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _resetSearch,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _blue.withValues(alpha:0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 15, color: _blue),
                    const SizedBox(width: 6),
                    Text(
                      _t('Hapus pencarian', 'Clear search', '清除搜索'),
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _blue),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // AUDIT NOTIF CARD
  Widget _buildCard(Map<String, dynamic> item) {
    final score = double.tryParse(item['nilai_audit']?.toString() ?? '');
    final scoreFinal = double.tryParse(item['nilai_final']?.toString() ?? '');
    final isFinalized = item['is_finalized'] == true;
    final displayScore = isFinalized ? scoreFinal : score;
    final locationName = item['_location_name']?.toString() ?? '-';
    final levelType = item['level_type']?.toString() ?? '';
    final date = _formatDate(item['tanggal_audit']);
    final answers = (item['_answers'] as List<Map<String, dynamic>>?) ?? [];
    final role = item['_role']?.toString() ?? 'auditor';
    final isPic = role == 'pic';
    final auditorData = item['Auditor'] as Map<String, dynamic>?;
    final auditorName = auditorData?['nama']?.toString() ?? '';

    final noAnswers = answers.where((a) => a['jawaban'] == false).toList();
    final allNoConfirmed = noAnswers.isNotEmpty &&
        noAnswers.every((a) {
          final replies = (a['Replies'] as List?) ?? [];
          return replies.any((r) => r['is_confirmed'] == true);
        });

    final effectiveScore = displayScore;
    final effectiveScoreColor = _scoreColor(displayScore);
    final showScore = noAnswers.isEmpty || allNoConfirmed;

    final poinLogs = (item['_poin_logs'] as List<Map<String, dynamic>>?) ?? [];
    int totalPoin = 0;
    for (final l in poinLogs) {
      totalPoin += ((l['poin'] as num?)?.toInt() ?? 0);
    }

    final locationColor = _levelColor(levelType);
    final locationIcon = _levelIcon(levelType);
    final roleColor = isPic ? const Color(0xFF10B981) : _blue;
    final roleIcon = isPic ? Icons.engineering_rounded : Icons.fact_check_rounded;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: showScore
              ? effectiveScoreColor.withValues(alpha: 0.25)
              : const Color(0xFFF59E0B).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AuditNotifDetailScreen(
                item: item,
                lang: widget.lang,
              ),
            ),
          );
          _fetch();
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 92, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54, height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: showScore
                          ? effectiveScoreColor.withValues(alpha: 0.12)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: showScore
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
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
                                        fontSize: 8, color: effectiveScoreColor)),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // NEW: LOKASI SEBAGAI LABEL — icon + warna sesuai level
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
                                child: Text(
                                  locationName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: locationColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // NEW: TANGGAL LEBIH MENARIK
                        Row(children: [
                          Icon(Icons.schedule_rounded, size: 12, color: Colors.black),
                          const SizedBox(width: 4),
                          Text(date,
                              style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black)),
                          if (isPic && auditorName.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '· ${_t('oleh', 'by', '由')} $auditorName',
                                style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ]),
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
                                const Icon(Icons.warning_amber_rounded,
                                    size: 11, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 4),
                                Text(
                                  _t('Perlu Perbaikan', 'Needs Fix', '需要修复'),
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFF59E0B)),
                                ),
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
            // NEW: LABEL AUDITOR/PIC — pojok kanan atas, poin di bawahnya
            Positioned(
              top: 14,
              right: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
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
                        Text(
                          isPic ? _t('PIC', 'PIC', 'PIC') : _t('Auditor', 'Auditor', '审计员'),
                          style: GoogleFonts.poppins(
                              fontSize: 10, fontWeight: FontWeight.w700, color: roleColor),
                        ),
                      ],
                    ),
                  ),
                  if (totalPoin != 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: totalPoin > 0
                              ? const [Color(0xFF0D9488), Color(0xFF2DD4BF)]
                              : const [Color(0xFFDC2626), Color(0xFFF87171)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: (totalPoin > 0
                                      ? const Color(0xFF0D9488)
                                      : const Color(0xFFDC2626))
                                  .withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department_rounded,
                              size: 13, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('$totalPoin',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11.5)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // NEW: PANAH — pojok kanan bawah saja
            Positioned(
              bottom: 10,
              right: 10,
              child: Icon(Icons.chevron_right_rounded, color: _blue, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  // NEW: helper warna & icon per level lokasi (konsisten dengan add_finding_flow_screen.dart)
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
}

// ══════════════════════════════════════════════════════════════
// NEW: indikator halaman bawah — 7 card per halaman
// ══════════════════════════════════════════════════════════════
class _AuditPageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final Color color;

  const _AuditPageIndicator({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.color,
  });

  static const int _maxVisibleButtons = 5;

  List<int> _visiblePageNumbers() {
    if (totalPages <= _maxVisibleButtons) {
      return List.generate(totalPages, (i) => i + 1);
    }
    int start = currentPage - 2;
    int end = currentPage + 2;
    if (start < 1) {
      start = 1;
      end = _maxVisibleButtons;
    } else if (end > totalPages) {
      end = totalPages;
      start = totalPages - (_maxVisibleButtons - 1);
    }
    return List.generate(end - start + 1, (i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    final bool canPrev = currentPage > 1;
    final bool canNext = currentPage < totalPages;
    final pageNumbers = _visiblePageNumbers();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.14), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          _arrowButton(
            icon: Icons.arrow_back_ios_new_rounded,
            enabled: canPrev,
            onTap: () {
              if (!canPrev) return;
              onPageChanged(currentPage - 1);
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                for (final p in pageNumbers) ...[
                  Expanded(child: _pageButton(p)),
                  if (p != pageNumbers.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          _arrowButton(
            icon: Icons.arrow_forward_ios_rounded,
            enabled: canNext,
            onTap: () {
              if (!canNext) return;
              onPageChanged(currentPage + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _pageButton(int page) {
    final bool isActive = page == currentPage;
    return GestureDetector(
      onTap: () {
        if (page == currentPage) return;
        onPageChanged(page);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: isActive ? null : Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          '$page',
          style: GoogleFonts.poppins(
              color: isActive ? Colors.white : color, fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ),
    );
  }

  Widget _arrowButton({required IconData icon, required bool enabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.16) : Colors.grey.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: enabled ? color : Colors.grey.shade400),
      ),
    );
  }
}