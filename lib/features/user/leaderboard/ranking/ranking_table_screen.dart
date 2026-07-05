import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/utils/jabatan_helper.dart';
import '../user_profile_modal.dart';
import 'ranking_screen.dart' show RankMember;

class _TableColors {
  static const primary = Color(0xFF0EA5E9);
  static const primaryDark = Color(0xFF0369A1);
  static const primaryLight = Color(0xFFE0F2FE);
  static const textPrimary = Color(0xFF0C4A6E);
  static const textSecondary = Color(0xFF64748B);
  static const selfHighlight = Color(0xFFFFF7ED);
  static const divider = Color(0xFFE0F2FE);
}

class RankingTableScreen {
  RankingTableScreen._();
  static const double _nameContentLeftGap = 14;
  static const double _tableHeaderStickyHeight = 84.0;
  static const double _bottomNavBarHeight = 65.0;

  static List<Widget> buildSlivers({
    required BuildContext context,
    required Future<List<RankMember>>? leaderboardFuture,
    required String lang,
    required String Function(String key) getTxt,
  }) {
    final double systemBottomInset = MediaQuery.of(context).viewPadding.bottom;
    final double safeBottom = systemBottomInset > 0 ? systemBottomInset : 8;
    final double bottomClearance = _bottomNavBarHeight + safeBottom;

    return [
      SliverPersistentHeader(
        pinned: true,
        delegate: _TableHeaderDelegate(
          height: _tableHeaderStickyHeight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTableHeader(lang),
              _buildTargetRow(lang),
            ],
          ),
        ),
      ),
      FutureBuilder<List<RankMember>>(
        future: leaderboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
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
                child: Center(
                  child: Text('Terjadi Kesalahan: ${snapshot.error}'),
                ),
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
              (ctx, i) => _buildRankRow(
                context: context,
                m: rankList[i],
                lang: lang,
                getTxt: getTxt,
              ),
              childCount: rankList.length,
            ),
          );
        },
      ),
      SliverToBoxAdapter(
        child: Container(
          color: Colors.white,
          height: bottomClearance,
        ),
      ),
    ];
  }

  static Widget _buildTableHeader(String lang) {
    final String rankCol =
        lang == 'ID' ? 'Rank' : lang == 'ZH' ? '排名' : 'Rank';
    final String nameCol =
        lang == 'ID' ? 'Nama' : lang == 'ZH' ? '姓名' : 'Name';
    final String scoreCol = lang == 'ID'
        ? 'Poin Bulan Ini'
        : lang == 'ZH'
        ? '本月积分'
        : 'Monthly Points';

    return Container(
      color: const Color(0xFFF8FAFF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              rankCol,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _TableColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              nameCol,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _TableColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              scoreCol,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _TableColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildTargetRow(String lang) {
    final String targetText = lang == 'ID'
        ? 'Target Bulanan'
        : lang == 'ZH'
        ? '月度目标'
        : 'Monthly Target';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: const BoxDecoration(
        color: _TableColors.primaryLight,
        border: Border(bottom: BorderSide(color: _TableColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              targetText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _TableColors.primary,
              ),
            ),
          ),
          const SizedBox(
            width: 100,
            child: Text(
              '1000',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _TableColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildRankRow({
    required BuildContext context,
    required RankMember m,
    required String lang,
    required String Function(String key) getTxt,
  }) {
    final isTop3 = m.isTop3;
    return InkWell(
      onTap: () => _showUserProfileModal(context, m),
      child: Container(
        decoration: BoxDecoration(
          color: m.isSelf
              ? _TableColors.selfHighlight
              : isTop3
              ? m.medalColor.withValues(alpha: 0.04)
              : Colors.white,
          border: Border(
            bottom: BorderSide(color: _TableColors.divider, width: 1),
            left: isTop3
                ? BorderSide(color: m.medalColor, width: 3)
                : BorderSide.none,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Center(child: _RankBadge(member: m)),
            ),
            const SizedBox(width: _nameContentLeftGap),
            Expanded(
              child: Row(
                children: [
                  _Avatar(
                    name: m.name,
                    avatarUrl: m.avatarUrl,
                    color: m.avatarColor,
                    size: 34,
                    showRing: isTop3,
                    ringColor: m.medalColor,
                  ),
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
                            color: _TableColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        _buildJabatanBadge(
                          idJabatan: m.idJabatan,
                          jabatanNama: m.jabatanNama,
                          isVerificator: m.isVerificator,
                          lang: lang,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(
                '${m.monthlyPoints}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isTop3 ? m.medalColor : _TableColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildJabatanBadge({
    required int?    idJabatan,
    required String? jabatanNama,
    required bool?   isVerificator,
    required String  lang,
  }) {
    final label = JabatanHelper.getDisplayRole(
      isVerificatorFlag: isVerificator,
      idJabatan: idJabatan,
      jabatanFromDb: jabatanNama,
      lang: lang,
    );
    if (label.isEmpty) return const SizedBox.shrink();
    final color = JabatanHelper.getPrimaryColor(
        isVerificatorFlag: isVerificator, idJabatan: idJabatan);
    final icon = JabatanHelper.getRoleIcon(
        isVerificatorFlag: isVerificator, idJabatan: idJabatan);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  static void _showUserProfileModal(BuildContext context, RankMember member) {
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
              userId: member.id,
              userName: member.name,
              userAvatarUrl: member.avatarUrl,
              userRank: member.rank,
            );
          },
        );
      },
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
          border: Border(
            bottom: BorderSide(color: _TableColors.divider, width: 1),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 48, child: SizedBox.shrink()),
            const SizedBox(width: RankingTableScreen._nameContentLeftGap),
            Container(
              height: 34,
              width: 34,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
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
  final RankMember member;
  const _RankBadge({required this.member});

  @override
  Widget build(BuildContext context) {
    if (member.rank == 1) {
      return const Text('🥇', style: TextStyle(fontSize: 24));
    }
    if (member.rank == 2) {
      return const Text('🥈', style: TextStyle(fontSize: 24));
    }
    if (member.rank == 3) {
      return const Text('🥉', style: TextStyle(fontSize: 24));
    }
    return Text(
      '${member.rank}',
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: _TableColors.textSecondary,
      ),
    );
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
    final bg = color ?? _TableColors.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showRing
            ? Border.all(color: (ringColor ?? bg).withValues(alpha: 0.6), width: 2)
            : null,
        boxShadow: showRing
            ? [
                BoxShadow(
                  color: (ringColor ?? bg).withValues(alpha: 0.25),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
      child: CircleAvatar(
        radius: size / 2,
        backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
            ? NetworkImage(avatarUrl!)
            : null,
        backgroundColor: bg.withValues(alpha: 0.15),
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
                  color: bg,
                ),
              )
            : null,
      ),
    );
  }
}

class _TableHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _TableHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _TableHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}