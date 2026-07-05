import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/utils/jabatan_helper.dart';
import '../user_profile_modal.dart';
import 'leaderboard_detail_screen.dart' show LeaderboardMember, AppColors, leaderboardTexts;

class LeaderboardTableScreen extends StatelessWidget {
  final Future<List<LeaderboardMember>>? leaderboardFuture;
  final String lang;
  final bool isDaily;

  const LeaderboardTableScreen({
    super.key,
    required this.leaderboardFuture,
    required this.lang,
    this.isDaily = false,
  });

  String _getTxt(String key) =>
      leaderboardTexts[lang]?[key] ??
      leaderboardTexts['ID']![key] ??
      key;

  String get _noRankDataSub {
    if (isDaily) {
      switch (lang) {
        case 'EN':
          return 'Data will appear here once points activity is recorded for this day.';
        case 'ZH':
          return '当天一旦有积分活动记录，数据将显示在此处。';
        default:
          return 'Data akan muncul di sini setelah ada aktivitas poin pada tanggal ini.';
      }
    }
    switch (lang) {
      case 'EN':
        return 'Data will appear here once points activity is recorded this month.';
      case 'ZH':
        return '本月一旦有积分活动记录，数据将显示在此处。';
      default:
        return 'Data akan muncul di sini setelah ada aktivitas poin bulan ini.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          // Header — dibuat lebih tegas & jelas agar mudah dibaca
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFEFF8FF),
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Text(
                    lang == 'ID' ? 'Rank' : lang == 'ZH' ? '排名' : 'Rank',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: AppColors.textPrimary),
                  ),
                ),
                Expanded(
                  child: Text(_getTxt('name_col'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: AppColors.textPrimary)),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    lang == 'ID' ? 'Poin' : lang == 'ZH' ? '积分' : 'Points',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          // Target row — samakan dengan ranking_table_screen.dart
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              border: Border(bottom: BorderSide(color: AppColors.primaryLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(_getTxt('monthly_target'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor))),
                const SizedBox(
                  width: 100,
                  child: Text('1000',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor))),
              ],
            ),
          ),
          // Data rows
          FutureBuilder<List<LeaderboardMember>>(
            future: leaderboardFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                    children: List.generate(
                        6, (_) => const _TableRowShimmer()));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/team_illustration.png',
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getTxt('no_rank_data'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _noRankDataSub,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final data = snapshot.data!;
              return Column(
                  children:
                      data.map((item) => _buildRankRow(context, item)).toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRankRow(BuildContext context, LeaderboardMember item) {
    final isTop3 = item.rank <= 3;
    Color medalColor;
    Widget badge;

    if (item.rank == 1) {
      medalColor = AppColors.gold;
      badge = const Text('🥇', style: TextStyle(fontSize: 22));
    } else if (item.rank == 2) {
      medalColor = AppColors.silver;
      badge = const Text('🥈', style: TextStyle(fontSize: 22));
    } else if (item.rank == 3) {
      medalColor = AppColors.bronze;
      badge = const Text('🥉', style: TextStyle(fontSize: 22));
    } else {
      medalColor = AppColors.textSecondary;
      badge = Text('${item.rank}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13.5, fontWeight: FontWeight.w600,
          color: AppColors.textSecondary));
    }

    return InkWell(
      onTap: item.idUser == null ? null : () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (_, controller) => UserProfileModal(
              controller: controller,
              userId: item.idUser!,
              userName: item.name,
              userAvatarUrl: item.avatarUrl,
              userRank: item.rank,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isTop3 ? medalColor.withValues(alpha: 0.04) : Colors.white,
          border: Border(
            bottom: const BorderSide(color: AppColors.border, width: 1),
            left: isTop3
                ? BorderSide(color: medalColor, width: 3)
                : BorderSide.none,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            SizedBox(width: 48, child: Center(child: badge)),
            const SizedBox(width: 14),
            Expanded(
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isTop3
                          ? Border.all(color: medalColor.withValues(alpha: 0.6), width: 2)
                          : null,
                      boxShadow: isTop3
                          ? [BoxShadow(color: medalColor.withValues(alpha: 0.25), blurRadius: 6)]
                          : null,
                    ),
                    child: CircleAvatar(
                      radius: 17,
                      backgroundImage: (item.avatarUrl != null && item.avatarUrl!.isNotEmpty)
                          ? NetworkImage(item.avatarUrl!)
                          : null,
                      backgroundColor: AppColors.primaryLight,
                      child: (item.avatarUrl == null || item.avatarUrl!.isEmpty)
                          ? Text(
                              item.name.trim().split(' ').take(2)
                                  .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                                  .join(),
                              style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: AppColors.primaryColor))
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.name,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: isTop3 ? FontWeight.w800 : FontWeight.w600,
                            color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        _buildJabatanBadge(
                          idJabatan: item.idJabatan,
                          jabatanNama: item.jabatanNama,
                          isVerificator: item.isVerificator,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 100,
              child: Text('${item.monthlyPoints}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w900,
                  color: isTop3 ? medalColor : AppColors.primaryDark))),
          ],
        ),
      ),
    );
  }

  Widget _buildJabatanBadge({
    required int?    idJabatan,
    required String? jabatanNama,
    required bool?   isVerificator,
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
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _TableRowShimmer extends StatelessWidget {
  const _TableRowShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Color(0xFFBAE6FD), width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle)),
            const SizedBox(width: 20),
            Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(
                child: Container(height: 12, color: Colors.white)),
            const SizedBox(width: 16),
            Container(width: 50, height: 12, color: Colors.white),
            const SizedBox(width: 16),
            Container(width: 30, height: 14, color: Colors.white),
          ],
        ),
      ),
    );
  }
}