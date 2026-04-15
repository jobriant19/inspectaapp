import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'riwayat_musim_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'user_profile_modal.dart';

// Warna & Tema
class _AppColors {
  static const primary = Color(0xFF0EA5E9);
  static const primaryDark = Color(0xFF0369A1);
  static const primaryLight = Color(0xFFE0F2FE);
  static const surface = Color(0xFFF0F9FF);
  static const textPrimary = Color(0xFF0C4A6E);
  static const textSecondary = Color(0xFF64748B);
  static const selfHighlight = Color(0xFFFFF7ED);
  static const selfHighlightBorder = Color(0xFFFED7AA);
  static const divider = Color(0xFFE0F2FE);
  static const gold = Color(0xFFFFD700);
  static const silver = Color(0xFFB0BEC5);
  static const bronze = Color(0xFFCD7F32);
}

// Model Data
class _RankMember {
  final String id;
  final int rank;
  final String name;
  final int score;
  final String? avatarUrl;
  final Color avatarColor;
  final bool isSelf;

  const _RankMember({
    required this.id,
    required this.rank,
    required this.name,
    required this.score,
    this.avatarUrl,
    required this.avatarColor,
    this.isSelf = false,
  });

  String get altitudeLabel => '${score * 10} ft';
  bool get isTop3 => rank <= 3;

  Color get medalColor {
    if (rank == 1) return _AppColors.gold;
    if (rank == 2) return _AppColors.silver;
    if (rank == 3) return _AppColors.bronze;
    return _AppColors.primary;
  }
}

// Main Screen 
class RankingScreen extends StatefulWidget {
  final String lang;
  const RankingScreen({super.key, required this.lang});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Future<List<_RankMember>>? _leaderboardFuture;
  DateTime? _lastUpdated;
  _RankMember? _selfData;

  final Map<String, Map<String, String>> _texts = {
    'ID': {
      'loading': 'Memuat...',
      'last_updated_prefix': 'Terakhir diperbarui pada',
      'season': 'Musim',
      'history': 'Riwayat',
      'time_left_label': 'Sisa waktu:',
      'days_left_suffix': 'hari',
      'no_podium_data': 'Belum ada data peringkat\nuntuk bulan ini.',
      'error_prefix': 'Terjadi Kesalahan:',
      'no_rank_data': 'Belum ada peringkat bulan ini.',
      'rank_col': 'Rank',
      'name_col': 'Nama',
      'alt_col': 'Ketinggian',
      'score_col': 'Poin',
      'monthly_target': 'Target Bulanan',
      'badge_1': '✈  Kelas Utama',
      'badge_2': '✈  Kelas Bisnis',
      'badge_3': '✈  Kelas Premium',
    },
    'EN': {
      'loading': 'Loading...',
      'last_updated_prefix': 'Last updated at',
      'season': 'Season',
      'history': 'History',
      'time_left_label': 'Time left:',
      'days_left_suffix': 'days',
      'no_podium_data': 'No ranking data available\nfor this month yet.',
      'error_prefix': 'An Error Occurred:',
      'no_rank_data': 'No rankings for this month yet.',
      'rank_col': 'Rank',
      'name_col': 'Name',
      'alt_col': 'Altitude',
      'score_col': 'Score',
      'monthly_target': 'Monthly Target',
      'badge_1': '✈  First Class',
      'badge_2': '✈  Business Class',
      'badge_3': '✈  Premium Class',
    },
    'ZH': {
      'loading': '正在加载...',
      'last_updated_prefix': '最后更新于',
      'season': '赛季',
      'history': '历史',
      'time_left_label': '剩余时间:',
      'days_left_suffix': '天',
      'no_podium_data': '本月暂无\n排名数据。',
      'error_prefix': '发生错误:',
      'no_rank_data': '本月暂无排名。',
      'rank_col': '排名',
      'name_col': '姓名',
      'alt_col': '高度',
      'score_col': '积分',
      'monthly_target': '月度目标',
      'badge_1': '✈  头等舱',
      'badge_2': '✈  商务舱',
      'badge_3': '✈  高级舱',
    },
  };

  String getTxt(String key) => _texts[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    final now = DateTime.now();
    setState(() {
      _lastUpdated = now;
      _leaderboardFuture = _supabase
          .rpc('get_monthly_leaderboard', params: {
        'selected_month': now.month,
        'selected_year': now.year,
        'selected_unit_id': 0,
      }).then((response) {
        final List<dynamic> data = response;
        if (!mounted) return <_RankMember>[];

        List<_RankMember> members = data.map((item) {
          return _RankMember(
            id: item['id_user'] as String,
            rank: item['rank_num'] as int,
            name: item['nama'] as String,
            score: item['monthly_score'] as int,
            avatarUrl: item['gambar_user'] as String?,
            isSelf: item['is_self'] as bool,
            avatarColor: _AppColors.primary,
          );
        }).toList();

        try {
          _selfData = members.firstWhere((m) => m.isSelf);
        } catch (e) {
          _selfData = null;
        }

        return members;
      }).catchError((error) {
        debugPrint('Error fetching leaderboard: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Gagal memuat papan peringkat: $error'),
                backgroundColor: Colors.red),
          );
        }
        return <_RankMember>[];
      });
    });
  }

  String get _lastUpdatedText {
    if (_lastUpdated == null) {
      return getTxt('loading');
    }
    final formattedDate = DateFormat('d MMM yyyy HH:mm', 'id_ID').format(_lastUpdated!);
    return '${getTxt('last_updated_prefix')} $formattedDate (GMT+7)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.surface,
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _fetchData();
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(child: _buildSkySection()),
                  SliverToBoxAdapter(child: _buildLastUpdated()),
                  SliverToBoxAdapter(child: _buildSeasonBanner()),
                  SliverToBoxAdapter(child: _buildTableHeader()),
                  SliverToBoxAdapter(child: _buildTargetRow()),
                  FutureBuilder<List<_RankMember>>(
                    future: _leaderboardFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => const _RankRowShimmerPlaceholder(),
                            childCount: 8,
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                         return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Center(child: Text('Terjadi Kesalahan: ${snapshot.error}')),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Center(child: Text(getTxt('no_rank_data'))),
                          ),
                        );
                      }

                      final rankList = snapshot.data!;
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _buildRankRow(rankList[i]),
                          childCount: rankList.length,
                        ),
                      );
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
          ),
          _buildSelfPinnedRow(),
        ],
      ),
    );
  }

  // Season Banner
  Widget _buildSeasonBanner() {
    final String seasonText =
        widget.lang == 'ID' ? 'Musim' : widget.lang == 'ZH' ? '赛季' : 'Season';
    final String historyButtonText =
        widget.lang == 'ID' ? 'Riwayat' : widget.lang == 'ZH' ? '历史' : 'History';
    final String timeLeftLabel =
        widget.lang == 'ID' ? 'Sisa waktu:' : widget.lang == 'ZH' ? '剩余时间:' : 'Time left:';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(seasonText,
                      style: const TextStyle(
                          fontSize: 14,
                          color: _AppColors.textSecondary,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  RiwayatMusimScreen(lang: widget.lang)));
                    },
                    icon: const Icon(Icons.history_rounded, size: 16),
                    label: Text(historyButtonText),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _AppColors.textPrimary,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now()),
                style: const TextStyle(
                    color: _AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(timeLeftLabel,
                  style:
                      const TextStyle(color: _AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 2),
              Builder(
                builder: (context) {
                  final now = DateTime.now();
                  final endOfMonth = DateTime(now.year, now.month + 1, 0);
                  final daysLeft = endOfMonth.difference(now).inDays;
                  return Text(
                    'Sisa $daysLeft hari',
                    style: const TextStyle(
                        color: _AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Sky Section (Podium)
  Widget _buildSkySection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1E90FF),
                      Color(0xFF41B8F5),
                      Color(0xFF7DD3FC),
                      Color(0xFFBAE6FD),
                    ],
                    stops: [0.0, 0.35, 0.65, 1.0],
                  ),
                ),
              ),
            ),

            // LAYER 2: Matahari / cahaya 
            Positioned(
              top: -30,
              right: 30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.35),
                      Colors.white.withOpacity(0.12),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // LAYER 3: Awan besar kiri bawah
            Positioned(
              left: -20,
              bottom: 40,
              child: _buildFantasyCloud(160, 0.92),
            ),

            // LAYER 4: Awan besar kanan bawah
            Positioned(
              right: -30,
              bottom: 30,
              child: _buildFantasyCloud(140, 0.85),
            ),

            // LAYER 5: Awan kecil kiri atas 
            Positioned(
              left: 10,
              top: 30,
              child: _buildFantasyCloud(80, 0.65),
            ),

            // LAYER 6: Awan kecil kanan atas
            Positioned(
              right: 20,
              top: 15,
              child: _buildFantasyCloud(65, 0.55),
            ),

            // LAYER 7: Awan tipis tengah
            Positioned(
              left: 80,
              top: 55,
              child: _buildFantasyCloud(90, 0.45),
            ),

            // LAYER 8: Pesawat mini dekoratif kanan
            Positioned(
              right: 28,
              top: 52,
              child: Transform.rotate(
                angle: -0.15,
                child: const Text('✈', style: TextStyle(fontSize: 16, color: Colors.white70)),
              ),
            ),

            // LAYER 9: Pesawat mini dekoratif kiri
            Positioned(
              left: 48,
              top: 90,
              child: Transform.rotate(
                angle: 0.1,
                child: const Text('✈', style: TextStyle(fontSize: 11, color: Colors.white54)),
              ),
            ),

            // LAYER 10: Garis runway / landasan bawah
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.5),
                      Colors.white.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // LAYER 11: Konten Podium
            FutureBuilder<List<_RankMember>>(
              future: _leaderboardFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData &&
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const _PodiumShimmerPlaceholder();
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      getTxt('no_podium_data'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, height: 1.5),
                    ),
                  );
                }

                final members = snapshot.data!;
                _RankMember? top1, top2, top3;
                try { top1 = members.firstWhere((m) => m.rank == 1); } catch (_) {}
                try { top2 = members.firstWhere((m) => m.rank == 2); } catch (_) {}
                try { top3 = members.firstWhere((m) => m.rank == 3); } catch (_) {}

                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (top2 != null)
                          _PodiumMember(member: top2, position: 2)
                        else
                          const SizedBox(width: 95),
                        if (top1 != null)
                          _PodiumMember(member: top1, position: 1)
                        else
                          const SizedBox(width: 105),
                        if (top3 != null)
                          _PodiumMember(member: top3, position: 3)
                        else
                          const SizedBox(width: 95),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Awan bergaya anime/fantasy
  Widget _buildFantasyCloud(double width, double opacity) {
    final h = width * 0.5;
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: width,
        height: h + 10,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                width: width,
                height: h * 0.55,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            Positioned(
              left: width * 0.05,
              bottom: h * 0.35,
              child: Container(
                width: width * 0.38,
                height: width * 0.38,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: width * 0.28,
              bottom: h * 0.42,
              child: Container(
                width: width * 0.44,
                height: width * 0.44,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: width * 0.05,
              bottom: h * 0.3,
              child: Container(
                width: width * 0.32,
                height: width * 0.32,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Last Updated
  Widget _buildLastUpdated() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Text(
        _lastUpdatedText,
        style: const TextStyle(
            fontSize: 11, color: _AppColors.textSecondary, height: 1.4),
      ),
    );
  }

  // Table Header
  Widget _buildTableHeader() {
    final String rankCol =
        widget.lang == 'ID' ? 'Rank' : widget.lang == 'ZH' ? '排名' : 'Rank';
    final String nameCol =
        widget.lang == 'ID' ? 'Nama' : widget.lang == 'ZH' ? '姓名' : 'Name';
    final String altCol =
        widget.lang == 'ID' ? 'Ketinggian' : widget.lang == 'ZH' ? '高度' : 'Altitude';
    final String scoreCol =
        widget.lang == 'ID' ? 'Poin' : widget.lang == 'ZH' ? '积分' : 'Score';

    return Container(
      color: const Color(0xFFF8FAFF),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
              width: 48,
              child: Text(rankCol,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _AppColors.textSecondary))),
          Expanded(
              child: Text(nameCol,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _AppColors.textSecondary))),
          SizedBox(
              width: 80,
              child: Text(altCol,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _AppColors.textSecondary))),
          SizedBox(
              width: 56,
              child: Text(scoreCol,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _AppColors.textSecondary))),
        ],
      ),
    );
  }

  // Target Row
  Widget _buildTargetRow() {
    final String targetText = widget.lang == 'ID'
        ? 'Target Bulanan'
        : widget.lang == 'ZH'
            ? '月度目标'
            : 'Monthly Target';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
          color: _AppColors.primaryLight,
          border: Border(bottom: BorderSide(color: _AppColors.divider))),
      child: Row(
        children: [
          const SizedBox(width: 48),
          Expanded(
              child: Text(targetText,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _AppColors.primary))),
          const SizedBox(
              width: 80,
              child: Text('-',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _AppColors.primary))),
          const SizedBox(
              width: 56,
              child: Text('1000',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _AppColors.primary))),
        ],
      ),
    );
  }

  void _showUserProfileModal(_RankMember member) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) {
          return UserProfileModal(
            controller: controller,
            userId: member.id, // <-- GANTI MENJADI INI
            userName: member.name,
            userAvatarUrl: member.avatarUrl,
            userRank: member.rank,
          );
        },
      );
    },
  );
}

  // Rank Row
  Widget _buildRankRow(_RankMember m) {
    final isTop3 = m.isTop3;
    return InkWell(
      onTap: () {
        _showUserProfileModal(m);
        // Hapus komentar di atas setelah Anda menambahkan id_user ke _RankMember
        // Untuk sementara, kita bisa mock panggilannya untuk menghindari error
        print("Tapped on ${m.name}");
      },
      child: Container(
        decoration: BoxDecoration(
          color: m.isSelf
              ? _AppColors.selfHighlight
              : isTop3
                  ? m.medalColor.withOpacity(0.04)
                  : Colors.white,
          border: Border(
            bottom: BorderSide(color: _AppColors.divider, width: 1),
            left: isTop3
                ? BorderSide(color: m.medalColor, width: 3)
                : BorderSide.none,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            SizedBox(width: 48, child: Center(child: _RankBadge(member: m))),
            Expanded(
              child: Row(
                children: [
                  _Avatar(
                      name: m.name,
                      avatarUrl: m.avatarUrl,
                      color: m.avatarColor,
                      size: 34,
                      showRing: isTop3,
                      ringColor: m.medalColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          m.name,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isTop3 ? FontWeight.w700 : FontWeight.w500,
                              color: _AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isTop3)
                          Text(_badgeLabel(m.rank),
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: m.medalColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                m.altitudeLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isTop3 ? m.medalColor : _AppColors.textSecondary),
              ),
            ),
            SizedBox(
              width: 56,
              child: Text(
                '${m.score}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isTop3 ? m.medalColor : _AppColors.primaryDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _badgeLabel(int rank) {
    if (rank == 1) return '✈  First Class';
    if (rank == 2) return '✈  Business Class';
    return '✈  Premium Class';
  }

  // Self Pinned Row
  Widget _buildSelfPinnedRow() {
    if (_selfData == null) {
      return const SizedBox.shrink();
    }
    final self = _selfData!;
    return Container(
      decoration: BoxDecoration(
        color: _AppColors.selfHighlight,
        border: Border(
            top: BorderSide(
                color: _AppColors.selfHighlightBorder, width: 1.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, -2))
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 48, child: Center(child: _RankBadge(member: self))),
          _Avatar(
              name: self.name,
              avatarUrl: self.avatarUrl,
              color: self.avatarColor,
              size: 34),
          const SizedBox(width: 10),
          Expanded(
              child: Text(self.name,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis)),
          SizedBox(
              width: 80,
              child: Text(self.altitudeLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11.5, color: _AppColors.textSecondary))),
          SizedBox(
              width: 56,
              child: Text('${self.score}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _AppColors.primaryDark))),
        ],
      ),
    );
  }
}

class _PodiumMember extends StatelessWidget {
  final _RankMember member;
  final int position;

  const _PodiumMember({required this.member, required this.position});

  // Tinggi platform podium: #1 paling menjulang
  double get _platformHeight => position == 1 ? 115.0 : position == 2 ? 82.0 : 66.0;
  double get _avatarSize      => position == 1 ? 66.0  : position == 2 ? 54.0  : 50.0;
  double get _columnWidth     => position == 1 ? 108.0 : 92.0;

  // Warna platform: kristal/kaca berwarna medali
  Color get _platformColor => member.medalColor;

  @override
  Widget build(BuildContext context) {
    final bool isFirst = position == 1;

    return SizedBox(
      width: _columnWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // ── Mahkota animasi juara 1 ──────────────────────────
          if (isFirst) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.6),
                  width: 1,
                ),
              ),
              child: const Text(
                '👑  #1',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFFD700),
                  shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],

          // ── Lingkaran Avatar + Glow ──────────────────────────
          Stack(
            alignment: Alignment.center,
            children: [
              // Lingkaran glow luar
              Container(
                width: _avatarSize + 14,
                height: _avatarSize + 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _platformColor.withOpacity(isFirst ? 0.25 : 0.18),
                ),
              ),
              // Ring border medali
              Container(
                width: _avatarSize + 5,
                height: _avatarSize + 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _platformColor,
                    width: isFirst ? 2.5 : 2.0,
                  ),
                ),
              ),
              // Avatar
              _Avatar(
                name: member.name,
                avatarUrl: member.avatarUrl,
                color: member.avatarColor,
                size: _avatarSize,
              ),
            ],
          ),

          const SizedBox(height: 5),

          // Nama
          Text(
            member.name.split(' ').first,
            style: TextStyle(
              color: Colors.white,
              fontSize: isFirst ? 13.5 : 12.0,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              shadows: const [
                Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 1)),
              ],
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            maxLines: 1,
          ),

          const SizedBox(height: 5),

          // Platform Podium bergaya kristal
          Container(
            height: _platformHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _platformColor.withOpacity(0.70),
                  _platformColor.withOpacity(0.45),
                  _platformColor.withOpacity(0.25),
                ],
              ),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.7), width: 1.5),
                left: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
                right: BorderSide(color: _platformColor.withOpacity(0.5), width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: _platformColor.withOpacity(0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 6,
                  top: 8,
                  bottom: 8,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${member.rank}',
                        style: TextStyle(
                          fontSize: isFirst ? 36 : 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.45),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '${member.score} Pts',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isFirst ? 12.5 : 11.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumShimmerPlaceholder extends StatelessWidget {
  const _PodiumShimmerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _AppColors.primaryDark.withOpacity(0.5),
      highlightColor: _AppColors.primary.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildShimmerBlock(height: 100, avatarSize: 58), // Peringkat 2
            _buildShimmerBlock(height: 130, avatarSize: 68), // Peringkat 1
            _buildShimmerBlock(height: 100, avatarSize: 58), // Peringkat 3
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBlock({required double height, required double avatarSize}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: avatarSize,
          width: avatarSize,
          decoration:
              const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
        const SizedBox(height: 10),
        Container(
          height: height,
          width: 95,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
        ),
      ],
    );
  }
}

class _RankRowShimmerPlaceholder extends StatelessWidget {
  const _RankRowShimmerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _AppColors.divider, width: 1)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 48, child: SizedBox.shrink()),
            Container(
              height: 34,
              width: 34,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 120, color: Colors.white),
                  const SizedBox(height: 5),
                  Container(height: 10, width: 80, color: Colors.white),
                ],
              ),
            ),
            Container(height: 14, width: 60, color: Colors.white),
            const SizedBox(width: 20),
            Container(height: 16, width: 36, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final _RankMember member;
  const _RankBadge({required this.member});

  @override
  Widget build(BuildContext context) {
    if (member.rank == 1) return const Text('🥇', style: TextStyle(fontSize: 24));
    if (member.rank == 2) return const Text('🥈', style: TextStyle(fontSize: 24));
    if (member.rank == 3) return const Text('🥉', style: TextStyle(fontSize: 24));
    return Text('${member.rank}',
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: _AppColors.textSecondary));
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final Color? color;
  final double size;
  final bool showRing;
  final Color? ringColor;

  const _Avatar({
    required this.name,
    this.avatarUrl,
    this.color,
    this.size = 36,
    this.showRing = false,
    this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? _AppColors.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showRing
            ? Border.all(color: (ringColor ?? bg).withOpacity(0.6), width: 2)
            : null,
        boxShadow: showRing
            ? [BoxShadow(color: (ringColor ?? bg).withOpacity(0.25), blurRadius: 6)]
            : null,
      ),
      child: CircleAvatar(
        radius: size / 2,
        backgroundImage:
            (avatarUrl != null && avatarUrl!.isNotEmpty) ? NetworkImage(avatarUrl!) : null,
        backgroundColor: bg.withOpacity(0.15),
        onBackgroundImageError: avatarUrl != null ? (_, __) {} : null,
        child: (avatarUrl == null || avatarUrl!.isEmpty)
            ? Text(
                name
                    .trim()
                    .split(' ')
                    .take(2)
                    .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                    .join(),
                style: TextStyle(
                    fontSize: size * 0.35,
                    fontWeight: FontWeight.w700,
                    color: bg),
              )
            : null,
      ),
    );
  }
}