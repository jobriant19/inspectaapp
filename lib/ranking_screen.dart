import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import './riwayat_musim_screen.dart';

// ─── Warna & Tema ──────────────────────────────────────────────────────────
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

// ─── Model Data ──────────────────────────────────────────────────────────────
class _RankMember {
  final int rank;
  final String name;
  final int score;
  final String? avatarUrl;
  final Color avatarColor;
  final bool isSelf;

  const _RankMember({
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

// ─── Main Screen ──────────────────────────────────────────────────────────────
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
  final String _currentMonthString = DateFormat('MMM', 'id_ID').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    final now = DateTime.now();
    setState(() {
      _lastUpdated = now;
      // PERBAIKAN: Mengubah Future<List<dynamic>> menjadi Future<List<_RankMember>>
      _leaderboardFuture = _supabase
          .rpc('get_monthly_leaderboard', params: {
        'selected_month': now.month,
        'selected_year': now.year,
        'selected_unit_id': 0, // Ganti 0 dengan _selectedUnitId jika filter sudah ada
      }).then((response) {
        final List<dynamic> data = response;
        if (!mounted) return <_RankMember>[];

        List<_RankMember> members = data.map((item) {
          return _RankMember(
            rank: item['rank_num'] as int,
            name: item['nama'] as String,
            score: item['monthly_score'] as int,
            avatarUrl: item['gambar_user'] as String?,
            isSelf: item['is_self'] as bool,
            avatarColor: _AppColors.primary,
          );
        }).toList();

        // Menggunakan try-catch untuk firstWhere agar tidak error jika tidak ditemukan
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
        return <_RankMember>[]; // Kembalikan list kosong jika error
      });
    });
  }

  String get _lastUpdatedText {
    if (_lastUpdated == null) {
      return 'Memuat...';
    }
    final formattedDate = DateFormat('d MMM yyyy HH:mm', 'id_ID').format(_lastUpdated!);
    return 'Terakhir diperbarui pada $formattedDate (GMT+7)';
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
                  // PERBAIKAN: Hanya satu FutureBuilder
                  FutureBuilder<List<_RankMember>>(
                    future: _leaderboardFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: CircularProgressIndicator()),
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
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: Text('Belum ada peringkat bulan ini.')),
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
                  const SliverToBoxAdapter(child: SizedBox(height: 80)), // Ruang di bawah
                ],
              ),
            ),
          ),
          _buildSelfPinnedRow(),
        ],
      ),
    );
  }

  // ── Season Banner ──────────────────────────────────────────────────────────
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

  // ── Sky Section (Podium) ───────────────────────────────────────────────────
  Widget _buildSkySection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      height: 250, // Sedikit lebih tinggi untuk memberi ruang
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0369A1), Color(0xFF0EA5E9), Color(0xFF7DD3FC)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: _AppColors.primary.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FutureBuilder<List<_RankMember>>(
          future: _leaderboardFuture,
          builder: (context, snapshot) {
            // Bagian loading dan error handling tetap sama
            if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('Belum ada data peringkat\nuntuk bulan ini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70)),
              );
            }

            final members = snapshot.data!;
            _RankMember? top1, top2, top3;
            try { top1 = members.firstWhere((m) => m.rank == 1); } catch (e) { top1 = null; }
            try { top2 = members.firstWhere((m) => m.rank == 2); } catch (e) { top2 = null; }
            try { top3 = members.firstWhere((m) => m.rank == 3); } catch (e) { top3 = null; }

            return Stack(
              children: [
                // Latar belakang (jika ada, seperti awan/bintang, bisa ditaruh di sini)

                // Bagian Podium
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end, // Kunci untuk membuat efek podium
                    children: [
                      // Juara 2 (Kiri)
                      if (top2 != null)
                        _PodiumMember(member: top2, position: 2)
                      else
                        const SizedBox(width: 90), // Placeholder jika tidak ada
                      
                      // Juara 1 (Tengah)
                      if (top1 != null)
                        _PodiumMember(member: top1, position: 1)
                      else
                        const SizedBox(width: 90), // Placeholder jika tidak ada
                        
                      // Juara 3 (Kanan)
                      if (top3 != null)
                        _PodiumMember(member: top3, position: 3)
                      else
                        const SizedBox(width: 90), // Placeholder jika tidak ada
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Last Updated ───────────────────────────────────────────────────────────
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

  // ── Table Header ───────────────────────────────────────────────────────────
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

  // ── Target Row ─────────────────────────────────────────────────────────────
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

  // ── Rank Row ───────────────────────────────────────────────────────────────
  Widget _buildRankRow(_RankMember m) {
    final isTop3 = m.isTop3;
    return Container(
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
    );
  }

  String _badgeLabel(int rank) {
    if (rank == 1) return '✈  First Class';
    if (rank == 2) return '✈  Business Class';
    return '✈  Premium Class';
  }

  // ── Self Pinned Row ────────────────────────────────────────────────────────
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

// ─── WIDGET-WIDGET PEMBANTU ───────────────────────────────────────────────────

class _PodiumMember extends StatelessWidget {
  final _RankMember member;
  final int position; // 1=tengah, 2=kiri, 3=kanan

  const _PodiumMember({required this.member, required this.position});

  @override
  Widget build(BuildContext context) {
    final bool isFirst = position == 1;
    final double boxHeight = isFirst ? 130 : 100;
    final double avatarSize = isFirst ? 64 : 56;
    final Color podiumColor = isFirst ? _AppColors.gold : (position == 2 ? _AppColors.silver : _AppColors.bronze);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Nama dan Skor
        if(isFirst)
          Text('👑', style: TextStyle(fontSize: 24, shadows: [Shadow(color: podiumColor.withOpacity(0.5), blurRadius: 8)])),
        if(isFirst) const SizedBox(height: 4),
        _Avatar(
          name: member.name,
          avatarUrl: member.avatarUrl,
          size: avatarSize,
          showRing: true,
          ringColor: podiumColor,
        ),
        const SizedBox(height: 8),
        // Podium Box
        Container(
          height: boxHeight,
          width: 90,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: podiumColor.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${member.rank}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: podiumColor,
                  shadows: [Shadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)]
                ),
              ),
              const SizedBox(height: 6),
              Text(
                member.name.split(' ').first,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${member.score}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
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