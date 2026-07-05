import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'leaderboard_detail_screen.dart';

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

const Map<String, Map<String, String>> _riwayatTexts = {
  'ID': {
    'title': 'Riwayat Musim',
    'ongoing': 'Sedang Berlangsung',
    'ended': 'Berakhir',
    'participants': 'Peserta',
    'winners': 'Pemenang',
    'winners_temp': 'Pemenang Sementara',
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
    'winners_temp': 'Current Leader',
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
    'winners_temp': '暂时领先',
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

class RiwayatMusimScreen extends StatefulWidget {
  final String lang;
  const RiwayatMusimScreen({super.key, required this.lang});

  @override
  State<RiwayatMusimScreen> createState() => _RiwayatMusimScreenState();
}

class _RiwayatMusimScreenState extends State<RiwayatMusimScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final Future<List<SeasonHistory>> _historyFuture;

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
    _winnerCache[key] ??= () async {
      try {
        final startOfMonth = DateTime(year, month, 1).toIso8601String();
        final endOfMonth = DateTime(year, month + 1, 1).toIso8601String();

        final List<dynamic> logData = await _supabase
            .from('log_poin')
            .select('id_user, poin')
            .gte('created_at', startOfMonth)
            .lt('created_at', endOfMonth);
        
        final Map<String, int> monthlyMap = {};
        for (final log in logData) {
          final uid = log['id_user']?.toString() ?? '';
          if (uid.isEmpty) continue;
          final p = (log['poin'] as num?)?.toInt() ?? 0;
          monthlyMap[uid] = (monthlyMap[uid] ?? 0) + p;
        }

        if (monthlyMap.isEmpty) return <SeasonWinner>[];

        final List<dynamic> userData = await _supabase
            .from('User')
            .select('id_user, nama, gambar_user')
            .inFilter('id_user', monthlyMap.keys.toList())
            .or('is_visitor.is.null,is_visitor.eq.false');

        final List<Map<String, dynamic>> combined = [];
        for (final user in userData) {
          final uid = user['id_user']?.toString() ?? '';
          combined.add({
            'uid'        : uid,
            'nama'       : user['nama'] as String,
            'gambar_user': user['gambar_user'] as String?,
            'poin'       : monthlyMap[uid] ?? 0,
          });
        }
        combined.sort((a, b) =>
            (b['poin'] as int).compareTo(a['poin'] as int));

        return combined.take(3).toList().asMap().entries.map((e) {
          final item = e.value;
          return SeasonWinner(
            rank     : e.key + 1,
            name     : item['nama'] as String,
            avatarUrl: item['gambar_user'] as String?,
            score    : item['poin'] as int,
          );
        }).toList();
      } catch (e) {
        debugPrint('Error fetching winners from log_poin: $e');
        return <SeasonWinner>[];
      }
    }();
    return _winnerCache[key]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: _buildAppBar(),
      body: FutureBuilder<List<SeasonHistory>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildHistoryShimmer();
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(
              child: Text(_t('no_history'),
                  style: GoogleFonts.poppins(color: const Color(0xFF64748B))),
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
        icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1D72F3)),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        _t('title'),
        style: GoogleFonts.poppins(
          color: const Color(0xFF1D72F3),
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 1,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      iconTheme: const IconThemeData(color: Color(0xFF1D72F3)),
    );
  }

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
                  ? const Color(0xFF059669).withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isOngoing
                ? const Color(0xFF059669).withValues(alpha: 0.4)
                : const Color(0xFFE2E8F0),
            width: isOngoing ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            _buildCardHeader(item, isOngoing, isCurrentMonth),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: const Color(0xFFF1F5F9),
            ),
            _buildWinnersSection(item),
            _buildCardFooter(item, isOngoing),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(SeasonHistory item, bool isOngoing, bool isCurrentMonth) {
    const seasonGreen = Color(0xFF059669);
    const seasonGreenBg = Color(0xFFECFDF5);
    const seasonGreenBorder = Color(0xFFA7F3D0);
    const rangeBlue = Color(0xFF0EA5E9);
    const rangeBlueBg = Color(0xFFE0F2FE);
    const rangeBlueBorder = Color(0xFFBAE6FD);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: _buildSeasonLabelBadge(item, isCurrentMonth),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(item.status, isOngoing),
            ],
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: seasonGreenBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: seasonGreenBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month_rounded,
                          size: 18, color: seasonGreen),
                      const SizedBox(width: 8),
                      Text(
                        '${item.monthName(widget.lang)} ${item.year}',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: seasonGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: rangeBlueBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: rangeBlueBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_rounded, size: 15, color: rangeBlue),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            item.dateRange(widget.lang),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: rangeBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonLabelBadge(SeasonHistory item, bool isCurrentMonth) {
    if (isCurrentMonth) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF0EA5E9)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.30),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, size: 13, color: Colors.white),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                _t('current_season'),
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: Colors.white,
                ),
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
          const Icon(Icons.outlined_flag_rounded,
              size: 12, color: Color(0xFF64748B)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '${_t('season')} ${item.year}',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isOngoing) {
    if (isOngoing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF059669).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFF059669).withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF059669),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              _t('ongoing'),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF059669),
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
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnersSection(SeasonHistory item) {
    final isOngoing = item.status == 'ongoing';

    return FutureBuilder<List<SeasonWinner>>(
      future: _fetchWinners(item.year, item.month),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildWinnersShimmer();
        }

        final winners = snapshot.data ?? [];
        final champion = winners.isEmpty
            ? null
            : winners.firstWhere(
                (w) => w.rank == 1,
                orElse: () => winners.first,
              );

        final sectionLabel = isOngoing
            ? _t('winners_temp')
            : _t('winners');

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isOngoing
                        ? Icons.leaderboard_rounded
                        : Icons.emoji_events_rounded,
                    size: 15,
                    color: isOngoing
                        ? const Color(0xFF0EA5E9)
                        : const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    sectionLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isOngoing
                          ? const Color(0xFF0EA5E9)
                          : const Color(0xFF0C4A6E),
                    ),
                  ),
                  if (isOngoing) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF0EA5E9).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        widget.lang == 'ID'
                            ? 'Live'
                            : widget.lang == 'ZH'
                                ? '实时'
                                : 'Live',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0EA5E9),
                        ),
                      ),
                    ),
                  ],
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
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                )
              else
                _buildChampionRow(champion, isOngoing: isOngoing),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChampionRow(SeasonWinner winner, {bool isOngoing = false}) {
    final Color borderColor = isOngoing
        ? const Color(0xFF7DD3FC)
        : const Color(0xFFFFD700);
    final Color bgColor = isOngoing
        ? const Color(0xFFE0F2FE)
        : const Color(0xFFFFFDE7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Text(
            isOngoing ? '🏃' : '🥇',
            style: const TextStyle(fontSize: 26),
          ),
          const SizedBox(width: 12),
          // AVATAR
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isOngoing
                    ? const Color(0xFF0EA5E9)
                    : const Color(0xFFF59E0B),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isOngoing
                          ? const Color(0xFF0EA5E9)
                          : const Color(0xFFF59E0B))
                      .withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: isOngoing
                  ? const Color(0xFFBAE6FD)
                  : const Color(0xFFFFF9C4),
              backgroundImage:
                  (winner.avatarUrl != null && winner.avatarUrl!.isNotEmpty)
                      ? NetworkImage(winner.avatarUrl!)
                      : null,
              child:
                  (winner.avatarUrl == null || winner.avatarUrl!.isEmpty)
                      ? Text(
                          winner.name
                              .trim()
                              .split(' ')
                              .take(2)
                              .map((w) =>
                                  w.isNotEmpty ? w[0].toUpperCase() : '')
                              .join(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isOngoing
                                ? const Color(0xFF0369A1)
                                : const Color(0xFF7B5800),
                          ),
                        )
                      : null,
            ),
          ),
          const SizedBox(width: 12),
          // NAME & SCORE
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  winner.name,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isOngoing
                        ? const Color(0xFF0C4A6E)
                        : const Color(0xFF3B2800),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${winner.score} ${_t('pts')}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isOngoing
                        ? const Color(0xFF0369A1)
                        : const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),
          // BADGE #1
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isOngoing
                    ? [const Color(0xFF0C4A6E), const Color(0xFF0EA5E9)]
                    : [const Color(0xFFF59E0B), const Color(0xFFFFD54F)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '#1',
              style: GoogleFonts.poppins(
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

  Widget _buildCardFooter(SeasonHistory item, bool isOngoing) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        children: [
          // PARTICIPANT
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
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0369A1),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // VIEW DETAIL BUTTON
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
                  style: GoogleFonts.poppins(
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

  Widget _buildWinnersShimmer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[50]!,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Container(
                width: 52, height: 52,
                decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 120, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(height: 11, width: 80, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[50]!,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}