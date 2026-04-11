import 'package:flutter/material.dart';
import 'dart:math' as math;
import './riwayat_musim_screen.dart';

// ─── Warna & Tema (konsisten dengan analytics_screen.dart) ──────────────────
class _AppColors {
  static const primary = Color(0xFF0EA5E9);
  static const primaryDark = Color(0xFF0369A1);
  static const primaryLight = Color(0xFFE0F2FE);
  static const accent = Color(0xFF38BDF8);
  static const surface = Color(0xFFF0F9FF);
  static const cardBg = Colors.white;
  static const textPrimary = Color(0xFF0C4A6E);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFFBDBDBD);
  static const divider = Color(0xFFE0F2FE);
  static const selfHighlight = Color(0xFFFFF7ED);
  static const selfHighlightBorder = Color(0xFFFED7AA);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const gold = Color(0xFFFFD700);
  static const silver = Color(0xFFB0BEC5);
  static const bronze = Color(0xFFCD7F32);
}

// ─── Model Data ──────────────────────────────────────────────────────────────
class _RankMember {
  final int rank;
  final String name;
  final int score;
  final Color avatarColor;
  final bool isSelf;

  const _RankMember({
    required this.rank,
    required this.name,
    required this.score,
    required this.avatarColor,
    this.isSelf = false,
  });

  double get altitudeFraction {
    // Rank 1 = 1.0 (paling tinggi), makin besar rank makin rendah
    const maxScore = 970;
    return (score / maxScore).clamp(0.05, 1.0);
  }

  String get altitudeLabel {
    if (rank == 1) return '39,000 ft';
    if (rank == 2) return '35,000 ft';
    if (rank == 3) return '30,000 ft';
    if (rank <= 5) return '${25 - (rank - 4) * 3},000 ft';
    if (rank <= 8) return '${15 - (rank - 6) * 2},000 ft';
    return '${10 - (rank - 9)},000 ft';
  }

  bool get isTop3 => rank <= 3;

  Color get medalColor {
    if (rank == 1) return _AppColors.gold;
    if (rank == 2) return _AppColors.silver;
    if (rank == 3) return _AppColors.bronze;
    return _AppColors.primary;
  }
}

// ─── Dummy Data ───────────────────────────────────────────────────────────────
final _rankList = [
  _RankMember(rank: 1, name: 'Bintoro Setyo Hutomo', score: 970, avatarColor: Color(0xFF10B981)),
  _RankMember(rank: 2, name: 'Jakub Ari Darmawan', score: 693, avatarColor: Color(0xFF14B8A6)),
  _RankMember(rank: 3, name: 'Agung Setyo Harwijayanto', score: 402, avatarColor: Color(0xFF3B82F6)),
  _RankMember(rank: 4, name: 'Lusia Ika Hattary Kirana', score: 390, avatarColor: Color(0xFFEC4899)),
  _RankMember(rank: 5, name: 'Hadi Prabowo', score: 280, avatarColor: Color(0xFF6366F1)),
  _RankMember(rank: 6, name: 'Dewi Rahayu', score: 210, avatarColor: Color(0xFFF59E0B)),
  _RankMember(rank: 7, name: 'Rendi Kurniawan', score: 175, avatarColor: Color(0xFF8B5CF6)),
  _RankMember(rank: 8, name: 'Agung Setyo H.', score: 137, avatarColor: Color(0xFF64748B)),
  _RankMember(rank: 9, name: 'Yohanes Oscar Andrian', score: 95, avatarColor: Color(0xFFEF4444)),
  _RankMember(rank: 10, name: 'Maria Sari', score: 60, avatarColor: Color(0xFF0EA5E9)),
  _RankMember(rank: 11, name: 'Saya', score: 21, avatarColor: Color(0xFF0EA5E9), isSelf: true),
];

// ─── Main Screen ──────────────────────────────────────────────────────────────
class RankingScreen extends StatefulWidget {
  final String lang;
  const RankingScreen({super.key, required this.lang});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _cloudController;
  late Animation<double> _floatAnim;
  late Animation<double> _cloudAnim;

  String _selectedMonth = 'Apr';
  String _selectedGroup = 'Semua Grup';

  final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  final List<String> _groups = [
    'Semua Grup', 'Support', 'Engineering', 'Produksi'
  ];

  // Lokalisasi
  String get _titleText =>
      widget.lang == 'ID' ? 'Papan Peringkat' :
      widget.lang == 'ZH' ? '排行榜' : 'Leaderboard';
  String get _historyButtonText =>
      widget.lang == 'ID' ? 'Riwayat' :
      widget.lang == 'ZH' ? '历史' : 'History';
  String get _timeLeftLabel =>
      widget.lang == 'ID' ? 'Sisa waktu:' :
      widget.lang == 'ZH' ? '剩余时间:' : 'Time left:';
  String get _rankCol =>
      widget.lang == 'ID' ? 'Rank' :
      widget.lang == 'ZH' ? '排名' : 'Rank';
  String get _nameCol =>
      widget.lang == 'ID' ? 'Nama' :
      widget.lang == 'ZH' ? '姓名' : 'Name';
  String get _scoreCol =>
      widget.lang == 'ID' ? 'Poin' :
      widget.lang == 'ZH' ? '积分' : 'Score';
  String get _altCol =>
      widget.lang == 'ID' ? 'Ketinggian' :
      widget.lang == 'ZH' ? '高度' : 'Altitude';
  String get _seasonText =>
      widget.lang == 'ID' ? 'Musim' :
      widget.lang == 'ZH' ? '赛季' : 'Season';
  String get _timeLeftText =>
      widget.lang == 'ID' ? 'Sisa 51 hari' :
      widget.lang == 'ZH' ? '剩余51天' : '51 days left';
  String get _targetText =>
      widget.lang == 'ID' ? 'Target Bulanan' :
      widget.lang == 'ZH' ? '月度目标' : 'Monthly Target';
  String get _lastUpdatedText =>
      widget.lang == 'ID'
          ? 'Terakhir diperbarui pada 10 Apr 2026 pukul 00.00 (GMT+7)'
          : widget.lang == 'ZH'
          ? '最后更新于 2026年4月10日 00:00 (GMT+7)'
          : 'Last updated Apr 10, 2026 at 00:00 (GMT+7)';

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _floatAnim = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _cloudAnim = Tween<double>(begin: 0, end: 1).animate(_cloudController);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _cloudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.surface,
      body: Column(
        children: [
          // _buildFilterBar() DIHAPUS DARI SINI
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // URUTAN DIUBAH: Sky Section sekarang di atas
                SliverToBoxAdapter(child: _buildSkySection()),
                SliverToBoxAdapter(child: _buildLastUpdated()),
                // URUTAN DIUBAH: Season Banner sekarang di bawah last updated
                SliverToBoxAdapter(child: _buildSeasonBanner()),
                SliverToBoxAdapter(child: _buildTableHeader()),
                SliverToBoxAdapter(child: _buildTargetRow()),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildRankRow(_rankList[i]),
                    childCount: _rankList.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
          _buildSelfPinnedRow(),
        ],
      ),
    );
  }

  // ── Filter Bar ─────────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _StyledDropdown(
            value: _selectedMonth,
            items: _months,
            onChanged: (v) => setState(() => _selectedMonth = v!),
            width: 100,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StyledDropdown(
              value: _selectedGroup,
              items: _groups,
              onChanged: (v) => setState(() => _selectedGroup = v!),
            ),
          ),
        ],
      ),
    );
  }

  // ── Season Banner ──────────────────────────────────────────────────────────
  Widget _buildSeasonBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bagian Kiri: Season, Riwayat, Bulan
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _seasonText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tombol Riwayat
                  OutlinedButton.icon(
                    onPressed: () {
                      // Navigasi ke halaman Riwayat
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RiwayatMusimScreen(lang: widget.lang),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history_rounded, size: 16),
                    label: Text(_historyButtonText),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _AppColors.textPrimary, 
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Apr 2026',
                style: TextStyle(
                  color: _AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          // Bagian Kanan: Sisa Waktu
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _timeLeftLabel,
                style: const TextStyle(
                  color: _AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                // Teks disesuaikan dengan gambar
                widget.lang == 'ZH' ? '剩余51天 7小时' : 'Sisa 51 hari 7 jam',
                style: const TextStyle(
                  color: _AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Sky Section ────────────────────────────────────────────────────────────
  Widget _buildSkySection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      height: 220,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0369A1),
            Color(0xFF0EA5E9),
            Color(0xFF7DD3FC),
            Color(0xFFE0F2FE),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _AppColors.primary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Bintang / titik kecil di langit
            ..._buildStarDots(),
            // Awan animasi
            AnimatedBuilder(
              animation: _cloudAnim,
              builder: (_, __) => Stack(
                children: [
                  _cloudWidget(
                    left: -120 + (_cloudAnim.value * 600),
                    top: 18,
                    width: 100,
                    opacity: 0.18,
                  ),
                  _cloudWidget(
                    left: 80 + (_cloudAnim.value * 400),
                    top: 50,
                    width: 70,
                    opacity: 0.12,
                  ),
                  _cloudWidget(
                    left: -60 + (_cloudAnim.value * 500),
                    top: 80,
                    width: 90,
                    opacity: 0.10,
                  ),
                ],
              ),
            ),
            // Garis altitude horizontal
            ..._buildAltitudeLines(),
            // Pesawat untuk TOP 3 (animasi float)
            AnimatedBuilder(
              animation: _floatAnim,
              builder: (_, __) => Stack(
                children: _rankList
                    .where((m) => m.isTop3)
                    .map((m) => _buildPlaneMarker(m))
                    .toList(),
              ),
            ),
            // Pesawat untuk rank 4-11 (tanpa float)
            Stack(
              children: _rankList
                  .where((m) => !m.isTop3)
                  .map((m) => _buildPlaneMarkerSimple(m))
                  .toList(),
            ),
            // Label judul
            Positioned(
              bottom: 10,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '✈  Sky Altitude Competition',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bintang kecil di langit
  List<Widget> _buildStarDots() {
    final rng = math.Random(7);
    return List.generate(18, (i) {
      return Positioned(
        top: rng.nextDouble() * 100,
        left: rng.nextDouble() * 400,
        child: Container(
          width: rng.nextDouble() * 2.5 + 0.5,
          height: rng.nextDouble() * 2.5 + 0.5,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(rng.nextDouble() * 0.6 + 0.2),
            shape: BoxShape.circle,
          ),
        ),
      );
    });
  }

  // Garis altitude tipis
  List<Widget> _buildAltitudeLines() {
    return List.generate(4, (i) {
      final topPos = 30.0 + (i * 42.0);
      return Positioned(
        top: topPos,
        left: 0,
        right: 0,
        child: Row(
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 0.5,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _cloudWidget({
    required double left,
    required double top,
    required double width,
    required double opacity,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: width,
        height: width * 0.38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(opacity),
          borderRadius: BorderRadius.circular(50),
        ),
      ),
    );
  }

  // Posisi horizontal berdasarkan rank
  double _planeLeft(int rank, double maxWidth) {
    // Distribusi horizontal merata
    final slots = _rankList.length + 1;
    return (rank / slots) * maxWidth - 24;
  }

  // Posisi vertikal berdasarkan altitude (score)
  double _planeTop(_RankMember m) {
    // altitude tinggi → posisi atas (top kecil)
    // altitude rendah → posisi bawah (top besar)
    const minTop = 10.0;
    const maxTop = 160.0;
    final frac = m.altitudeFraction; // 1.0 = paling tinggi
    return minTop + (1.0 - frac) * (maxTop - minTop);
  }

  Widget _buildPlaneMarker(_RankMember m) {
    final screenW = (MediaQuery.of(context).size.width) - 32;
    final left = _planeLeft(m.rank, screenW);
    final top = _planeTop(m);

    return Positioned(
      left: left,
      top: top + _floatAnim.value,
      child: _PlaneMarker(
        member: m,
        isTop3: true,
        isFirst: m.rank == 1,
      ),
    );
  }

  Widget _buildPlaneMarkerSimple(_RankMember m) {
    final screenW = (MediaQuery.of(context).size.width) - 32;
    final left = _planeLeft(m.rank, screenW);
    final top = _planeTop(m);

    return Positioned(
      left: left,
      top: top,
      child: _PlaneMarker(
        member: m,
        isTop3: false,
        isFirst: false,
      ),
    );
  }

  // ── Last Updated ───────────────────────────────────────────────────────────
  Widget _buildLastUpdated() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Text(
        _lastUpdatedText,
        style: const TextStyle(
          fontSize: 11,
          color: _AppColors.textSecondary,
          height: 1.4,
        ),
      ),
    );
  }

  // ── Table Header ───────────────────────────────────────────────────────────
  Widget _buildTableHeader() {
    return Container(
      color: const Color(0xFFF8FAFF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              _rankCol,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _nameCol,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              _altCol,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              _scoreCol,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Target Row ─────────────────────────────────────────────────────────────
  Widget _buildTargetRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: _AppColors.primaryLight,
        border: Border(
          bottom: BorderSide(color: _AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 48),
          Expanded(
            child: Text(
              _targetText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _AppColors.primary,
              ),
            ),
          ),
          const SizedBox(
            width: 80,
            child: Text(
              '-',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _AppColors.primary,
              ),
            ),
          ),
          const SizedBox(
            width: 56,
            child: Text(
              '1000',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _AppColors.primary,
              ),
            ),
          ),
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
          // Rank badge
          SizedBox(
            width: 48,
            child: Center(child: _RankBadge(member: m)),
          ),
          // Avatar + Nama
          Expanded(
            child: Row(
              children: [
                _Avatar(
                  name: m.name,
                  color: m.avatarColor,
                  size: 34,
                  showRing: isTop3,
                  ringColor: m.medalColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isTop3
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isTop3)
                        Text(
                          _badgeLabel(m.rank),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: m.medalColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Altitude
          SizedBox(
            width: 80,
            child: Text(
              m.altitudeLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: isTop3 ? m.medalColor : _AppColors.textSecondary,
              ),
            ),
          ),
          // Score
          SizedBox(
            width: 56,
            child: Text(
              '${m.score}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isTop3 ? m.medalColor : _AppColors.primaryDark,
              ),
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
    final self = _rankList.firstWhere((m) => m.isSelf);
    return Container(
      decoration: BoxDecoration(
        color: _AppColors.selfHighlight,
        border: Border(
          top: BorderSide(
            color: _AppColors.selfHighlightBorder,
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Center(child: _RankBadge(member: self)),
          ),
          _Avatar(name: self.name, color: self.avatarColor, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              self.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              self.altitudeLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                color: _AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              '${self.score}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Plane Marker Widget ──────────────────────────────────────────────────────
class _PlaneMarker extends StatelessWidget {
  final _RankMember member;
  final bool isTop3;
  final bool isFirst;

  const _PlaneMarker({
    required this.member,
    required this.isTop3,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    final color = member.medalColor;
    final avatarSize = isFirst ? 30.0 : isTop3 ? 26.0 : 22.0;
    final planeSize = isFirst ? 20.0 : isTop3 ? 17.0 : 14.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pesawat
        Stack(
          alignment: Alignment.center,
          children: [
            if (isTop3)
              Container(
                width: planeSize + 10,
                height: planeSize + 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.18),
                ),
              ),
            Icon(
              Icons.airplanemode_active_rounded,
              color: isTop3 ? color : Colors.white.withOpacity(0.7),
              size: planeSize,
              shadows: isTop3
                  ? [Shadow(color: color.withOpacity(0.6), blurRadius: 8)]
                  : [],
            ),
          ],
        ),
        const SizedBox(height: 2),
        // Avatar lingkaran dengan inisial
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: member.avatarColor.withOpacity(0.2),
            border: Border.all(
              color: isTop3 ? color : Colors.white.withOpacity(0.5),
              width: isTop3 ? 2 : 1,
            ),
            boxShadow: isTop3
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              member.name.trim().split(' ').first[0].toUpperCase(),
              style: TextStyle(
                fontSize: avatarSize * 0.38,
                fontWeight: FontWeight.bold,
                color: isTop3 ? color : Colors.white,
              ),
            ),
          ),
        ),
        // Rank label
        if (isTop3)
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Text(
              '#${member.rank}',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Rank Badge Widget ────────────────────────────────────────────────────────
class _RankBadge extends StatelessWidget {
  final _RankMember member;
  const _RankBadge({required this.member});

  @override
  Widget build(BuildContext context) {
    if (member.rank == 1) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFFFFEC80), _AppColors.gold],
          ),
          boxShadow: [
            BoxShadow(
              color: _AppColors.gold.withOpacity(0.4),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Center(
          child: Text('🥇', style: TextStyle(fontSize: 16)),
        ),
      );
    }
    if (member.rank == 2) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _AppColors.silver.withOpacity(0.2),
          border: Border.all(color: _AppColors.silver, width: 1.5),
        ),
        child: const Center(
          child: Text('🥈', style: TextStyle(fontSize: 15)),
        ),
      );
    }
    if (member.rank == 3) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _AppColors.bronze.withOpacity(0.15),
          border: Border.all(color: _AppColors.bronze, width: 1.5),
        ),
        child: const Center(
          child: Text('🥉', style: TextStyle(fontSize: 15)),
        ),
      );
    }
    return Text(
      '${member.rank}',
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: _AppColors.textSecondary,
      ),
    );
  }
}

// ─── Avatar Widget ────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String name;
  final Color? color;
  final double size;
  final bool showRing;
  final Color? ringColor;

  const _Avatar({
    required this.name,
    this.color,
    this.size = 36,
    this.showRing = false,
    this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    final bg = color ?? _AppColors.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: showRing
              ? (ringColor ?? bg).withOpacity(0.6)
              : bg.withOpacity(0.3),
          width: showRing ? 2 : 1,
        ),
        boxShadow: showRing
            ? [
                BoxShadow(
                  color: (ringColor ?? bg).withOpacity(0.25),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
            color: bg,
          ),
        ),
      ),
    );
  }
}

// ─── Styled Dropdown (sama persis dengan analytics_screen.dart) ───────────────
class _StyledDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool isDark;
  final double? width;

  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.isDark = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    const bg = Colors.white;
    final textColor = isDark ? _AppColors.primary : _AppColors.textPrimary;
    final iconColor = isDark ? _AppColors.primary : _AppColors.textSecondary;
    final borderColor = isDark ? _AppColors.primary : _AppColors.divider;

    Widget dropdown = Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
          width: isDark ? 1.5 : 1.0,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: iconColor,
            size: 20,
          ),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: const TextStyle(
                      color: _AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );

    if (width != null) return SizedBox(width: width, child: dropdown);
    return dropdown;
  }
}