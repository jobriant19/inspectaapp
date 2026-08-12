import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/utils/konfigurasi_poin_helper.dart';
import '../../../core/widgets/activity_log_detail_popup.dart';
import '../../admin/target/target/admin_target_pick_date.dart';

class ActivityLogTab extends StatefulWidget {
  final String lang;
  final List<Map<String, dynamic>>? initialLogs;
  final String Function(String) t;

  const ActivityLogTab({
    super.key,
    required this.lang,
    required this.t,
    this.initialLogs,
  });

  @override
  State<ActivityLogTab> createState() => _ActivityLogTabState();
}

class _ActivityLogTabState extends State<ActivityLogTab>
    with AutomaticKeepAliveClientMixin {
  String _searchQuery = '';
  DateTime _filterFrom =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _filterTo = DateTime(
      DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _allLogs = [];
  List<Map<String, dynamic>> _filteredLogs = [];
  int _totalPoin = 0;
  bool _isLoading = false;
  Map<String, Map<String, dynamic>> _konfigMap = {};

  int _currentPage = 1;
  static const int _perPage = 7;

  static const Color _accent = Color(0xFF0EA5E9);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.initialLogs != null) {
      _allLogs = widget.initialLogs!;
      _computeTotal(_allLogs);
      _filteredLogs = List.from(_allLogs);
    } else {
      _fetchLogs();
    }
    _loadKonfigMap();
  }

  Future<void> _loadKonfigMap() async {
    final map = await KonfigurasiPoinHelper.getMap();
    if (mounted) setState(() => _konfigMap = map);
  }

  void _computeTotal(List<Map<String, dynamic>> logs) {
    int total = 0;
    for (final l in logs) {
      total += ((l['poin'] as num?)?.toInt() ?? 0);
    }
    _totalPoin = total;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    setState(() => _isLoading = true);
    try {
      final List<dynamic> logs = await Supabase.instance.client
          .from('log_poin')
          .select('poin, deskripsi, deskripsi_en, deskripsi_zh, tipe_aktivitas, created_at')
          .eq('id_user', userId)
          .gte('created_at', _filterFrom.toIso8601String())
          .lte('created_at', _filterTo.toIso8601String())
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(logs);
      if (mounted) {
        setState(() {
          _allLogs = list;
          _computeTotal(list);
          _isLoading = false;
        });
        _applySearch(_searchQuery);
      }
    } catch (e) {
      debugPrint('Error fetching activity logs: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applySearch(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
      if (query.trim().isEmpty) {
        _filteredLogs = List.from(_allLogs);
      } else {
        final q = query.toLowerCase();
        _filteredLogs = _allLogs.where((l) {
          final desc = (l['deskripsi'] ?? '').toString().toLowerCase();
          final tipe = (l['tipe_aktivitas'] ?? '').toString().toLowerCase();
          return desc.contains(q) || tipe.contains(q);
        }).toList();
      }
    });
  }

  void _resetSearch() {
    _searchCtrl.clear();
    _applySearch('');
  }

  Color _getTipeColor(String tipe, bool isPositive) {
    switch (tipe) {
      case 'login_pertama':
        return const Color(0xFFEC4899);
      case 'login_harian':
        return const Color(0xFF3B82F6);
      case 'login_pertama_hari_ini':
        return const Color(0xFFF59E0B);
      case 'penalti':
        return const Color(0xFFEF4444);
      default:
        return isPositive
            ? const Color(0xFF16A34A)
            : const Color(0xFFDC2626);
    }
  }

  IconData _getTipeIcon(String tipe, bool isPositive) {
    switch (tipe) {
      case 'login_pertama':
        return Icons.celebration_rounded;
      case 'login_harian':
        return Icons.today_rounded;
      case 'login_pertama_hari_ini':
        return Icons.emoji_events_rounded;
      case 'penalti':
        return Icons.warning_amber_rounded;
      default:
        return isPositive
            ? Icons.star_rounded
            : Icons.remove_circle_outline_rounded;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    DateTime? dt =
        value is DateTime ? value : DateTime.tryParse(value.toString());
    if (dt == null) return '-';
    dt = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) {
      return widget.lang == 'ZH'
          ? '刚刚'
          : widget.lang == 'EN'
              ? 'Just now'
              : 'Baru saja';
    }
    if (diff.inHours < 1) {
      return widget.lang == 'ZH'
          ? '${diff.inMinutes}分钟前'
          : widget.lang == 'EN'
              ? '${diff.inMinutes} min ago'
              : '${diff.inMinutes} menit lalu';
    }
    if (diff.inDays < 1) {
      return widget.lang == 'ZH'
          ? '${diff.inHours}小时前'
          : widget.lang == 'EN'
              ? '${diff.inHours} hr ago'
              : '${diff.inHours} jam lalu';
    }
    if (diff.inDays < 7) {
      return widget.lang == 'ZH'
          ? '${diff.inDays}天前'
          : widget.lang == 'EN'
              ? '${diff.inDays} days ago'
              : '${diff.inDays} hari lalu';
    }
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  int _recencyLevel(dynamic value) {
    if (value == null) return 3;
    DateTime? dt = value is DateTime ? value : DateTime.tryParse(value.toString());
    if (dt == null) return 3;
    dt = dt.toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inHours < 1) return 0;
    if (diff.inDays < 1) return 1;
    if (diff.inDays < 7) return 2;
    return 3;
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
            Icon(labelIcon, size: 13, color: _accent),
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
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accent.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_rounded, size: 17, color: _accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      DateFormat('EEE, d MMM yyyy').format(value),
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0C4A6E)),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_right_rounded, size: 18, color: _accent),
                ],
              ),
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
              border: Border.all(color: _accent.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.date_range_rounded, color: _accent, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.lang == 'EN'
                          ? 'Select Period'
                          : widget.lang == 'ZH'
                              ? '选择期间'
                              : 'Pilih Periode',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0C4A6E)),
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

                dateField(
                  label: widget.lang == 'EN'
                      ? 'From'
                      : widget.lang == 'ZH'
                          ? '从'
                          : 'Dari',
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

                dateField(
                  label: widget.lang == 'EN'
                      ? 'To'
                      : widget.lang == 'ZH'
                          ? '到'
                          : 'Sampai',
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
                        _filterFrom = DateTime(tempFrom.year, tempFrom.month, tempFrom.day);
                        _filterTo = DateTime(tempTo.year, tempTo.month, tempTo.day, 23, 59, 59);
                        _currentPage = 1;
                      });
                      Navigator.pop(ctx);
                      _fetchLogs();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      widget.lang == 'EN'
                          ? 'Apply'
                          : widget.lang == 'ZH'
                              ? '应用'
                              : 'Terapkan',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
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

  Color _getFireColor(int points) {
    if (points >= 1000) return const Color(0xFFEF4444);
    if (points >= 500) return const Color(0xFFF97316);
    if (points >= 100) return const Color(0xFF22C55E);
    if (points > 0) return const Color(0xFF3B82F6);
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final fireColor = _getFireColor(_totalPoin);
    final periodLabel =
        '${DateFormat('d MMM').format(_filterFrom)} – ${DateFormat('d MMM yyyy').format(_filterTo)}';
    final totalPages =
        _filteredLogs.isEmpty ? 1 : (_filteredLogs.length / _perPage).ceil();
    final safePage = _currentPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * _perPage;
    final endIdx = (startIdx + _perPage) > _filteredLogs.length
        ? _filteredLogs.length
        : startIdx + _perPage;
    final pagedLogs = _filteredLogs.isEmpty
        ? <Map<String, dynamic>>[]
        : _filteredLogs.sublist(startIdx, endIdx);

    final bool isSearchEmptyResult =
        _searchQuery.trim().isNotEmpty && _filteredLogs.isEmpty;

    return Column(children: [
      Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF0EA5E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Row(children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.22),
              border: Border.all(color: fireColor.withValues(alpha: 0.7), width: 2),
            ),
            child: Icon(Icons.local_fire_department_rounded, color: fireColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lang == 'EN'
                      ? 'TOTAL POINTS'
                      : widget.lang == 'ZH'
                          ? '总积分'
                          : 'TOTAL POIN',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8),
                ),
                const SizedBox(height: 3),
                Text(
                  _isLoading ? '...' : '$_totalPoin',
                  style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0),
                ),
                Text(
                  widget.lang == 'EN'
                      ? 'points earned'
                      : widget.lang == 'ZH'
                          ? '积分'
                          : 'poin terkumpul',
                  style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: Colors.white.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 46,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.white.withValues(alpha: 0.22),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_rounded, color: Colors.white.withValues(alpha: 0.9), size: 18),
              const SizedBox(height: 4),
              Text(
                _isLoading ? '...' : '${_filteredLogs.length}',
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              Text(
                'log',
                style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.65)),
              ),
            ],
          ),
        ]),
      ),

      // FILTER BAR
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(children: [
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Row(children: [
                const Icon(Icons.search, color: Color(0xFF0EA5E9), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _applySearch,
                    style: GoogleFonts.poppins(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: widget.lang == 'EN'
                          ? 'Search activity...'
                          : widget.lang == 'ZH'
                              ? '搜索活动...'
                              : 'Cari aktivitas...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintStyle: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: _resetSearch,
                    child: Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 14, color: Color(0xFFDC2626)),
                    ),
                  ),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showPeriodPicker,
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      periodLabel,
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ]),
            ),
          ),
        ]),
      ),

      // ACTIVITY LOG LIST
      Expanded(
        child: _isLoading
            ? Shimmer.fromColors(
                baseColor: Colors.grey.shade200,
                highlightColor: Colors.grey.shade100,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 5,
                  itemBuilder: (_, __) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 70,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              )
            : _filteredLogs.isEmpty
                ? (isSearchEmptyResult
                    ? _buildSearchEmptyState()
                    : _buildEmptyState())
                : Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          itemCount: pagedLogs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) =>
                              _buildActivityLogCard(pagedLogs[index]),
                        ),
                      ),
                      if (totalPages > 1)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            16, 4, 16, MediaQuery.of(context).viewPadding.bottom + 12,
                          ),
                          child: _ActivityPageIndicator(
                            currentPage: safePage,
                            totalPages: totalPages,
                            onPageChanged: (p) => setState(() => _currentPage = p),
                            color: _accent,
                          ),
                        )
                      else
                        const SizedBox(height: 12),
                    ],
                  ),
      ),
    ]);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00C9E4).withValues(alpha: 0.08),
            ),
            child: Icon(Icons.history_rounded,
                size: 36, color: const Color(0xFF00C9E4).withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 12),
          Text(
            widget.t('empty_activity'),
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E3A8A)),
          ),
        ],
      ),
    );
  }

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
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.search_off_rounded,
                    size: 46, color: _accent.withValues(alpha: 0.4)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.lang == 'EN'
                  ? 'No matching activity'
                  : widget.lang == 'ZH'
                      ? '未找到匹配的活动'
                      : 'Aktivitas Tidak Ditemukan',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _accent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.lang == 'EN'
                  ? "Try adjusting your search keyword to find what you're looking for."
                  : widget.lang == 'ZH'
                      ? '尝试调整搜索关键词以查找您需要的内容。'
                      : 'Coba ubah kata kunci pencarian untuk menemukan yang Anda cari.',
              style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _resetSearch,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _accent.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 15, color: _accent),
                    const SizedBox(width: 6),
                    Text(
                      widget.lang == 'EN'
                          ? 'Clear search'
                          : widget.lang == 'ZH'
                              ? '清除搜索'
                              : 'Hapus pencarian',
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w700, color: _accent),
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

  Widget _buildActivityLogCard(Map<String, dynamic> log) {
    final int poin = (log['poin'] as num).toInt();
    final bool isPositive = poin >= 0;
    final String tipe = (log['tipe_aktivitas'] ?? '').toString();
    final String deskripsiTampil =
        KonfigurasiPoinHelper.resolveDeskripsi(log: log, lang: widget.lang);
    final String namaTampil = KonfigurasiPoinHelper.resolveNama(
      map: _konfigMap,
      tipeAktivitas: tipe,
      lang: widget.lang,
      fallbackDeskripsi: deskripsiTampil,
      log: log,
    );
    final String tanggal = _formatDate(log['created_at']);
    final Color color = _getTipeColor(tipe, isPositive);
    final Color pointColor = isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final IconData icon = _getTipeIcon(tipe, isPositive);

    final int recency = _recencyLevel(log['created_at']);
    late final Color timeColor;
    late final IconData timeIcon;
    switch (recency) {
      case 0:
        timeColor = const Color(0xFF0EA5E9);
        timeIcon = Icons.bolt_rounded;
        break;
      case 1:
        timeColor = const Color(0xFF0D9488);
        timeIcon = Icons.access_time_filled_rounded;
        break;
      case 2:
        timeColor = const Color(0xFF64748B);
        timeIcon = Icons.schedule_rounded;
        break;
      default:
        timeColor = const Color(0xFF475569);
        timeIcon = Icons.event_rounded;
    }

    return GestureDetector(
      onTap: () => ActivityLogDetailPopup.show(
        context: context,
        lang: widget.lang,
        nama: namaTampil,
        deskripsi: KonfigurasiPoinHelper.resolvePopupDeskripsi(
          map: _konfigMap,
          tipeAktivitas: tipe,
          lang: widget.lang,
          log: log,
        ),
        poin: poin,
        tipeAktivitas: tipe,
        createdAt: log['created_at'],
        iconColor: color,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.1)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaTampil,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                      height: 1.4),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: timeColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: timeColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(timeIcon, size: 11, color: timeColor),
                      const SizedBox(width: 4),
                      Text(
                        tanggal,
                        style: GoogleFonts.poppins(
                            fontSize: 10.5, fontWeight: FontWeight.w700, color: timeColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: pointColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(
              isPositive ? '+$poin' : '$poin',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: pointColor),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ActivityPageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final Color color;

  const _ActivityPageIndicator({
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