import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'leaderboard_detail_screen.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class SeasonHistory {
  final int year;
  final int month;
  final int participants;

  SeasonHistory({
    required this.year,
    required this.month,
    required this.participants,
  });

  String monthName(String lang) {
    final date = DateTime(year, month);
    final locale = lang == 'ID'
        ? 'id_ID'
        : lang == 'ZH'
            ? 'zh'
            : 'en_US';
    return DateFormat.MMMM(locale).format(date);
  }

  String dateRange(String lang) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final locale = lang == 'ID'
        ? 'id_ID'
        : lang == 'ZH'
            ? 'zh'
            : 'en_US';
    final formatter = DateFormat('dd MMM yyyy', locale);
    return '${formatter.format(firstDay)} - ${formatter.format(lastDay)}';
  }

  /// Status bulan: 'ongoing', 'ended'
  String get status {
    final now = DateTime.now();
    if (year == now.year && month == now.month) return 'ongoing';
    return 'ended';
  }
}

class SeasonWinner {
  final int rank;
  final String name;
  final String? avatarUrl;
  final int score;

  SeasonWinner({
    required this.rank,
    required this.name,
    this.avatarUrl,
    required this.score,
  });
}

// ── Translations ──────────────────────────────────────────────────────────────

const Map<String, Map<String, String>> _riwayatTexts = {
  'ID': {
    'title': 'Riwayat Musim',
    'ongoing': 'Sedang Berlangsung',
    'ended': 'Berakhir',
    'participants': 'Peserta',
    'winners': 'Pemenang',
    'no_winner': 'Belum ada data pemenang',
    'no_history': 'Tidak ada riwayat musim ditemukan.',
    'loading_error': 'Gagal memuat riwayat',
    'view_detail': 'Lihat Detail',
    'rank': 'Peringkat',
    'pts': 'poin',
    'season': 'Musim',
    'current_season': 'Musim Aktif',
  },
  'EN': {
    'title': 'Season History',
    'ongoing': 'Ongoing',
    'ended': 'Ended',
    'participants': 'Participants',
    'winners': 'Winners',
    'no_winner': 'No winner data yet',
    'no_history': 'No season history found.',
    'loading_error': 'Failed to load history',
    'view_detail': 'View Detail',
    'rank': 'Rank',
    'pts': 'pts',
    'season': 'Season',
    'current_season': 'Active Season',
  },
  'ZH': {
    'title': '赛季历史',
    'ongoing': '进行中',
    'ended': '已结束',
    'participants': '参与者',
    'winners': '获胜者',
    'no_winner': '暂无获胜者数据',
    'no_history': '未找到赛季历史。',
    'loading_error': '加载历史失败',
    'view_detail': '查看详情',
    'rank': '排名',
    'pts': '分',
    'season': '赛季',
    'current_season': '当前赛季',
  },
};

// ── Screen ────────────────────────────────────────────────────────────────────

class RiwayatMusimScreen extends StatefulWidget {
  final String lang;
  const RiwayatMusimScreen({super.key, required this.lang});

  @override
  State<RiwayatMusimScreen> createState() => _RiwayatMusimScreenState();
}

class _RiwayatMusimScreenState extends State<RiwayatMusimScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final Future<List<SeasonHistory>> _historyFuture;

  // Cache pemenang per bulan-tahun agar tidak fetch ulang
  final Map<String, Future<List<SeasonWinner>>> _winnerCache = {};

  String _t(String key) =>
      _riwayatTexts[widget.lang]?[key] ??
      _riwayatTexts['ID']![key] ??
      key;

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchHistory();
  }

  Future<List<SeasonHistory>> _fetchHistory() async {
    try {
      final response = await _supabase.rpc('get_season_history');
      final List<dynamic> data = response;
      return data
          .map((item) => SeasonHistory(
                year: item['season_year'] as int,
                month: item['season_month'] as int,
                participants: (item['participant_count'] as int?) ?? 0,
              ))
          .toList();
    } catch (e) {
      debugPrint('Error fetching season history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${_t('loading_error')}: $e'),
              backgroundColor: Colors.red),
        );
      }
      return [];
    }
  }

  Future<List<SeasonWinner>> _fetchWinners(int year, int month) {
    final key = '$year-$month';
    _winnerCache[key] ??= _supabase.rpc('get_monthly_leaderboard', params: {
      'selected_month'     : month,
      'selected_year'      : year,
      'selected_unit_id'   : 0,
      'selected_lokasi_id' : 0,
      'selected_subunit_id': 0,
      'selected_area_id'   : 0,
    }).then((response) {
      final List<dynamic> data = response;
      return data
          .take(3)
          .map((item) => SeasonWinner(
                rank     : item['rank_num'] as int,
                name     : item['nama'] as String,
                avatarUrl: item['gambar_user'] as String?,
                score    : item['poin'] as int,  // ← DIPERBAIKI
              ))
          .toList();
    }).catchError((_) => <SeasonWinner>[]);
    return _winnerCache[key]!;
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: _buildAppBar(),
      body: FutureBuilder<List<SeasonHistory>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(
              child: Text(_t('no_history'),
                  style: const TextStyle(color: Color(0xFF64748B))),
            );
          }

          final historyList = snapshot.data!;
          return ListView.builder(
            itemCount: historyList.length,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemBuilder: (context, index) {
              final item = historyList[index];
              return _buildSeasonCard(item);
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        _t('title'),
        style: const TextStyle(
            color: Color(0xFF0C4A6E), fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      iconTheme: const IconThemeData(color: Color(0xFF0C4A6E)),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE0F2FE)),
      ),
    );
  }

  // ── Season Card ─────────────────────────────────────────────────────────────

  Widget _buildSeasonCard(SeasonHistory item) {
    final isOngoing = item.status == 'ongoing';
    final now = DateTime.now();
    final isCurrentMonth = item.year == now.year && item.month == now.month;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LeaderboardDetailScreen(
            seasonTitle: '${item.monthName(widget.lang)} ${item.year}',
            year: item.year,
            month: item.month,
            lang: widget.lang,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isOngoing
                  ? const Color(0xFF0EA5E9).withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isOngoing
                ? const Color(0xFF0EA5E9).withValues(alpha: 0.4)
                : const Color(0xFFE2E8F0),
            width: isOngoing ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            // ── Header Card ──
            _buildCardHeader(item, isOngoing, isCurrentMonth),
            // ── Divider ──
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: const Color(0xFFF1F5F9),
            ),
            // ── Winners Section ──
            _buildWinnersSection(item),
            // ── Footer ──
            _buildCardFooter(item, isOngoing),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(SeasonHistory item, bool isOngoing, bool isCurrentMonth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isOngoing
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0C4A6E), Color(0xFF0EA5E9)],
              )
            : null,
        color: isOngoing ? null : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info musim
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label musim kecil
                Text(
                  isCurrentMonth
                      ? _t('current_season')
                      : '${_t('season')} ${item.year}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isOngoing
                        ? Colors.white.withValues(alpha: 0.8)
                        : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                // Nama bulan + tahun
                Text(
                  '${item.monthName(widget.lang)} ${item.year}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isOngoing ? Colors.white : const Color(0xFF0C4A6E),
                  ),
                ),
                const SizedBox(height: 4),
                // Rentang tanggal
                Text(
                  item.dateRange(widget.lang),
                  style: TextStyle(
                    fontSize: 12,
                    color: isOngoing
                        ? Colors.white.withValues(alpha: 0.75)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Badge status
          _buildStatusBadge(item.status, isOngoing),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isOngoing) {
    if (isOngoing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dot animasi (simulasi dengan Container)
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF4ADE80),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              _t('ongoing'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF94A3B8),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _t('ended'),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ── Winners Section ─────────────────────────────────────────────────────────

  Widget _buildWinnersSection(SeasonHistory item) {
    return FutureBuilder<List<SeasonWinner>>(
      future: _fetchWinners(item.year, item.month),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildWinnersShimmer();
        }

        final winners = snapshot.data ?? [];
        // Ambil hanya juara 1
        final champion = winners.isEmpty
            ? null
            : winners.firstWhere(
                (w) => w.rank == 1,
                orElse: () => winners.first,
              );

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label section
              Row(
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      size: 15, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 6),
                  Text(
                    _t('winners'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0C4A6E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (champion == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 6),
                      Text(
                        _t('no_winner'),
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                )
              else
                _buildChampionRow(champion),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChampionRow(SeasonWinner winner) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF7DD3FC)),
      ),
      child: Row(
        children: [
          // Medali
          const Text('🥇', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF0EA5E9),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFBAE6FD),
              backgroundImage: (winner.avatarUrl != null &&
                      winner.avatarUrl!.isNotEmpty)
                  ? NetworkImage(winner.avatarUrl!)
                  : null,
              child: (winner.avatarUrl == null || winner.avatarUrl!.isEmpty)
                  ? Text(
                      winner.name
                          .trim()
                          .split(' ')
                          .take(2)
                          .map((w) =>
                              w.isNotEmpty ? w[0].toUpperCase() : '')
                          .join(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0369A1),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // Nama & skor
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  winner.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0C4A6E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${winner.score} ${_t('pts')}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0369A1),
                  ),
                ),
              ],
            ),
          ),
          // Badge #1
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0C4A6E), Color(0xFF0EA5E9)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '#1',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Card Footer ─────────────────────────────────────────────────────────────

  Widget _buildCardFooter(SeasonHistory item, bool isOngoing) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        children: [
          // Peserta
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                const Icon(Icons.groups_rounded,
                    size: 14, color: Color(0xFF0369A1)),
                const SizedBox(width: 5),
                Text(
                  '${item.participants} ${_t('participants')}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0369A1),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Tombol detail
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: isOngoing
                  ? const LinearGradient(
                      colors: [Color(0xFF0C4A6E), Color(0xFF0EA5E9)])
                  : null,
              color: isOngoing ? null : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _t('view_detail'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isOngoing
                        ? Colors.white
                        : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: isOngoing ? Colors.white : const Color(0xFF475569),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shimmer & Helpers ────────────────────────────────────────────────────────

  Widget _buildWinnersShimmer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}