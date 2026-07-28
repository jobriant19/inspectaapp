import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VerificationIntroThirdSlide extends StatelessWidget {
  final String lang;
  const VerificationIntroThirdSlide({super.key, required this.lang});

  static const Map<String, Map<String, String>> _txt = {
    'EN': {
      'title': 'How Voting Works',
      'subtitle': 'Voting outcome is determined by the majority',
      'majority': 'MAJORITY',
      'majority_desc':
          'The majority vote determines the final result (Valid/Invalid)',
      'majority_sub': 'Determines final outcome',
      'minority': 'MINORITY',
      'minority_desc': 'The minority vote receives a -5 point penalty',
      'minority_sub': 'Gets -5 point penalty',
    },
    'ID': {
      'title': 'Cara Voting',
      'subtitle': 'Hasil voting ditentukan oleh suara terbanyak',
      'majority': 'MAYORITAS',
      'majority_desc':
          'Suara mayoritas menentukan hasil akhir (Valid/Tidak Valid)',
      'majority_sub': 'Menentukan hasil akhir',
      'minority': 'MINORITAS',
      'minority_desc': 'Suara minoritas mendapat penalti -5 poin',
      'minority_sub': 'Mendapat penalti -5 poin',
    },
    'ZH': {
      'title': '投票方式',
      'subtitle': '投票结果由多数票决定',
      'majority': '多数',
      'majority_desc': '多数票决定最终结果（有效/无效）',
      'majority_sub': '决定最终结果',
      'minority': '少数',
      'minority_desc': '少数票将受到-5积分的惩罚',
      'minority_sub': '获得-5积分惩罚',
    },
  };

  String t(String key) => _txt[lang]?[key] ?? key;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          t('title'),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1D72F3),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),

        // SUBTITLE
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded,
                size: 15, color: Colors.grey.shade800),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                t('subtitle'),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // MAJORITY CARD
        _VotingGroupCard(
          label: t('majority'),
          desc: t('majority_desc'),
          subLabel: t('majority_sub'),
          color: const Color(0xFF059669),
          bgColor: const Color(0xFFECFDF5),
          borderColor: const Color(0xFF6EE7B7),
          icon: Icons.how_to_vote_rounded,
          filledCount: 4,
          totalCount: 6,
          isMajority: true,
        ),
        const SizedBox(height: 14),

        // VS DIVIDER
        Row(children: [
          Expanded(
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.grey.shade300],
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D72F3), Color(0xFF0891B2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1D72F3).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              'VS',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade300, Colors.transparent],
                ),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 14),

        // MINORITY CARD
        _VotingGroupCard(
          label: t('minority'),
          desc: t('minority_desc'),
          subLabel: t('minority_sub'),
          color: const Color(0xFFDC2626),
          bgColor: const Color(0xFFFFF1F2),
          borderColor: const Color(0xFFFCA5A5),
          icon: Icons.remove_circle_outline_rounded,
          filledCount: 2,
          totalCount: 6,
          isMajority: false,
        ),
      ],
    );
  }
}

class _VotingGroupCard extends StatelessWidget {
  final String label;
  final String desc;
  final String subLabel;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final IconData icon;
  final int filledCount;
  final int totalCount;
  final bool isMajority;

  const _VotingGroupCard({
    required this.label,
    required this.desc,
    required this.subLabel,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.icon,
    required this.filledCount,
    required this.totalCount,
    required this.isMajority,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // LABEL BADGE
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(children: [
                  Icon(icon, color: Colors.white, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ]),
              ),
              const Spacer(),
              // PERSENTASE
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  isMajority ? '≥ 50%' : '< 50%',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // VOTER ICONS BAR
          Row(
            children: List.generate(totalCount, (i) {
              final bool active = i < filledCount;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200 + (i * 50)),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? color.withValues(alpha: 0.15)
                        : Colors.grey.shade200,
                    border: Border.all(
                      color: active ? color : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 17,
                    color: active ? color : Colors.grey.shade400,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          // DESCRIPTION
          Text(
            desc,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.black87,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // SUB LABEL WITH ICON
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isMajority
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  subLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w700,
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