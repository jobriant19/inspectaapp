import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Map<String, Map<String, String>> _txt = {
  'EN': {
    's2_title': 'Verifier Roles',
    's2_exec': 'Executive',
    's2_exec_desc': 'Reviews general findings & completions',
    's2_hrd': 'HRD',
    's2_hrd_desc': 'Verifies accident reports only',
    's2_verif': 'Verificator',
    's2_verif_desc': 'General verifier with voting rights',
    's2_note': '3 Verificators are assigned per finding',
    's2_tap_hint': 'Tap a role to see how it works',
    // DETAIL — EXECUTIVE & VERIFICATOR
    'detail_finding_title': 'How Finding Verification Works',
    'detail_finding_body':
        'Executives and Verificators verify 5R and KTS Production findings by comparing the finding photo against the completion photo.',
    'detail_finding_step1_title': 'Compare the photos',
    'detail_finding_step1_desc':
        'Carefully examine the finding photo and the completion (solution) photo side by side, along with their notes.',
    'detail_finding_step2_title': 'Check category & location',
    'detail_finding_step2_desc':
        'Confirm the finding category (5R or KTS Production) and the location before deciding.',
    'detail_finding_step3_title': 'Read within the time limit',
    'detail_finding_step3_desc':
        'Every verification must be completed within 2 minutes after the reading countdown ends.',
    'detail_finding_step4_title': 'Swipe to decide',
    'detail_finding_step4_desc':
        'Swipe right for Valid, or swipe left for Invalid.',
    'detail_finding_step5_title': 'Earn or lose points',
    'detail_finding_step5_desc':
        'Vote with the majority to earn +10 points. Voting with the minority costs -5 points.',
    'detail_category_5r': '5R Finding',
    'detail_category_kts': 'KTS Production',
    // DETAIL — HRD
    'detail_accident_title': 'How Accident Verification Works',
    'detail_accident_body':
        'HRD reviews accident reports, including evidence photos, involved parties, and incident details, then decides whether the report is valid.',
    'detail_accident_step1_title': 'Review the evidence',
    'detail_accident_step1_desc':
        'Check the evidence photo, description, and action taken for the accident.',
    'detail_accident_step2_title': 'Check involved parties',
    'detail_accident_step2_desc':
        'Review the reporter, affected party, supervisor, and witness listed on the report.',
    'detail_accident_step3_title': 'Confirm incident details',
    'detail_accident_step3_desc':
        'Verify the location, date, time, cause, and affected department.',
    'detail_accident_step4_title': 'Swipe or edit',
    'detail_accident_step4_desc':
        'Swipe right to mark the report Valid. If it is not valid, edit the report data directly instead of swiping.',
    'detail_close': 'Close',
  },
  'ID': {
    's2_title': 'Peran Verifier',
    's2_exec': 'Eksekutif',
    's2_exec_desc': 'Meninjau temuan & penyelesaian umum',
    's2_hrd': 'HRD',
    's2_hrd_desc': 'Memverifikasi laporan kecelakaan saja',
    's2_verif': 'Verificator',
    's2_verif_desc': 'Verifier umum dengan hak voting',
    's2_note': '3 Verificator ditugaskan per temuan',
    's2_tap_hint': 'Ketuk salah satu peran untuk melihat cara kerjanya',
    'detail_finding_title': 'Cara Kerja Verifikasi Temuan',
    'detail_finding_body':
        'Eksekutif dan Verificator memverifikasi temuan 5R dan KTS Production dengan membandingkan foto temuan dengan foto penyelesaian.',
    'detail_finding_step1_title': 'Bandingkan foto',
    'detail_finding_step1_desc':
        'Periksa dengan teliti foto temuan dan foto penyelesaian (solusi) secara berdampingan, beserta catatannya.',
    'detail_finding_step2_title': 'Periksa kategori & lokasi',
    'detail_finding_step2_desc':
        'Pastikan kategori temuan (5R atau KTS Production) dan lokasinya sebelum memutuskan.',
    'detail_finding_step3_title': 'Baca dalam batas waktu',
    'detail_finding_step3_desc':
        'Setiap verifikasi harus diselesaikan dalam 2 menit setelah hitung mundur membaca berakhir.',
    'detail_finding_step4_title': 'Geser untuk memutuskan',
    'detail_finding_step4_desc':
        'Geser ke kanan untuk Valid, atau geser ke kiri untuk Tidak Valid.',
    'detail_finding_step5_title': 'Dapatkan atau kehilangan poin',
    'detail_finding_step5_desc':
        'Memilih sesuai mayoritas mendapat +10 poin. Memilih minoritas mendapat penalti -5 poin.',
    'detail_category_5r': 'Temuan 5R',
    'detail_category_kts': 'KTS Production',
    'detail_accident_title': 'Cara Kerja Verifikasi Kecelakaan',
    'detail_accident_body':
        'HRD meninjau laporan kecelakaan, termasuk foto bukti, pihak terlibat, dan detail kejadian, lalu memutuskan apakah laporan tersebut valid.',
    'detail_accident_step1_title': 'Tinjau bukti',
    'detail_accident_step1_desc':
        'Periksa foto bukti, deskripsi, dan tindakan yang diambil atas kecelakaan tersebut.',
    'detail_accident_step2_title': 'Periksa pihak terlibat',
    'detail_accident_step2_desc':
        'Tinjau pelapor, pihak terdampak, supervisor, dan saksi yang tercantum pada laporan.',
    'detail_accident_step3_title': 'Pastikan detail kejadian',
    'detail_accident_step3_desc':
        'Verifikasi lokasi, tanggal, waktu, penyebab, dan departemen terdampak.',
    'detail_accident_step4_title': 'Geser atau edit',
    'detail_accident_step4_desc':
        'Geser ke kanan untuk menandai laporan Valid. Jika tidak valid, edit langsung data laporannya alih-alih menggeser.',
    'detail_close': 'Tutup',
  },
  'ZH': {
    's2_title': '验证员角色',
    's2_exec': '高管',
    's2_exec_desc': '审查一般发现和完成情况',
    's2_hrd': 'HRD',
    's2_hrd_desc': '仅验证事故报告',
    's2_verif': '验证员',
    's2_verif_desc': '具有投票权的一般验证员',
    's2_note': '每个发现分配3名验证员',
    's2_tap_hint': '点击角色查看其工作方式',
    'detail_finding_title': '发现验证的工作方式',
    'detail_finding_body':
        '高管和验证员通过比对发现照片与完成照片来验证5R和KTS Production发现。',
    'detail_finding_step1_title': '比对照片',
    'detail_finding_step1_desc':
        '仔细并排检查发现照片和完成（解决方案）照片及其说明。',
    'detail_finding_step2_title': '检查类别与地点',
    'detail_finding_step2_desc':
        '在做决定前确认发现类别（5R或KTS Production）和地点。',
    'detail_finding_step3_title': '在时限内阅读',
    'detail_finding_step3_desc':
        '阅读倒计时结束后，每次验证必须在2分钟内完成。',
    'detail_finding_step4_title': '滑动以决定',
    'detail_finding_step4_desc': '向右滑动表示有效，向左滑动表示无效。',
    'detail_finding_step5_title': '获得或失去积分',
    'detail_finding_step5_desc':
        '投票与多数一致可获得+10积分。投票属于少数将被扣除-5积分。',
    'detail_category_5r': '5R',
    'detail_category_kts': 'KTS Production',
    'detail_accident_title': '事故验证的工作方式',
    'detail_accident_body':
        'HRD审查事故报告，包括证据照片、涉及人员和事故详情，然后决定报告是否有效。',
    'detail_accident_step1_title': '审查证据',
    'detail_accident_step1_desc': '检查事故的证据照片、描述和已采取的措施。',
    'detail_accident_step2_title': '检查涉及人员',
    'detail_accident_step2_desc':
        '审查报告中列出的报告人、受影响方、主管和目击者。',
    'detail_accident_step3_title': '确认事故详情',
    'detail_accident_step3_desc': '核实地点、日期、时间、原因和受影响部门。',
    'detail_accident_step4_title': '滑动或编辑',
    'detail_accident_step4_desc':
        '向右滑动将报告标记为有效。如果无效，请直接编辑报告数据，而不是滑动。',
    'detail_close': '关闭',
  },
};

String _t(String lang, String key) => _txt[lang]?[key] ?? key;

enum _RoleKind { executive, hrd, verificator }

class VerifierRolesSlide extends StatefulWidget {
  final String lang;
  const VerifierRolesSlide({super.key, required this.lang});

  @override
  State<VerifierRolesSlide> createState() => _VerifierRolesSlideState();
}

class _VerifierRolesSlideState extends State<VerifierRolesSlide> {
  _RoleKind? _expandedRole;

  void _toggleRole(_RoleKind kind) {
    setState(() {
      _expandedRole = _expandedRole == kind ? null : kind;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return Column(
      children: [
        // TITLE & SUBTITLE 
        Text(
          _t(lang, 's2_title'),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1D72F3),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_rounded, size: 13, color: Colors.grey.shade400),
            const SizedBox(width: 5),
            Text(
              _t(lang, 's2_tap_hint'),
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // AREA SCROLL
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              children: [
                _RoleCard(
                  icon: Icons.workspace_premium_rounded,
                  color: const Color(0xFFEF4444),
                  role: _t(lang, 's2_exec'),
                  desc: _t(lang, 's2_exec_desc'),
                  lang: lang,
                  kind: _RoleKind.executive,
                  isExpanded: _expandedRole == _RoleKind.executive,
                  onTap: () => _toggleRole(_RoleKind.executive),
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  icon: Icons.health_and_safety_rounded,
                  color: const Color(0xFFEC4899),
                  role: _t(lang, 's2_hrd'),
                  desc: _t(lang, 's2_hrd_desc'),
                  lang: lang,
                  kind: _RoleKind.hrd,
                  isExpanded: _expandedRole == _RoleKind.hrd,
                  onTap: () => _toggleRole(_RoleKind.hrd),
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  icon: Icons.fact_check_rounded,
                  color: const Color(0xFF4ADE80),
                  role: _t(lang, 's2_verif'),
                  desc: _t(lang, 's2_verif_desc'),
                  lang: lang,
                  kind: _RoleKind.verificator,
                  isExpanded: _expandedRole == _RoleKind.verificator,
                  onTap: () => _toggleRole(_RoleKind.verificator),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // VERIFICATOR NOTE
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1D72F3).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF1D72F3).withValues(alpha: 0.3),
            ),
          ),
          child: Row(children: [
            const Icon(Icons.group_rounded, color: Color(0xFF1D72F3), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _t(lang, 's2_note'),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF1D72F3),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String role;
  final String desc;
  final String lang;
  final _RoleKind kind;
  final bool isExpanded;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.color,
    required this.role,
    required this.desc,
    required this.lang,
    required this.kind,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            InkWell(
              splashColor: color.withValues(alpha: 0.08),
              highlightColor: color.withValues(alpha: 0.05),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1D72F3),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            desc,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedRotation(
                        turns: isExpanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Icon(Icons.chevron_right_rounded, size: 18, color: color),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? _RoleDetailContent(lang: lang, kind: kind, color: color)
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleDetailContent extends StatelessWidget {
  final String lang;
  final _RoleKind kind;
  final Color color;
  const _RoleDetailContent({
    required this.lang,
    required this.kind,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAccident = kind == _RoleKind.hrd;

    final String detailBody = isAccident
        ? _t(lang, 'detail_accident_body')
        : _t(lang, 'detail_finding_body');

    final List<_DetailStep> steps = isAccident
        ? [
            _DetailStep(Icons.photo_camera_back_rounded,
                _t(lang, 'detail_accident_step1_title'),
                _t(lang, 'detail_accident_step1_desc')),
            _DetailStep(Icons.people_alt_rounded,
                _t(lang, 'detail_accident_step2_title'),
                _t(lang, 'detail_accident_step2_desc')),
            _DetailStep(Icons.event_note_rounded,
                _t(lang, 'detail_accident_step3_title'),
                _t(lang, 'detail_accident_step3_desc')),
            _DetailStep(Icons.rule_rounded,
                _t(lang, 'detail_accident_step4_title'),
                _t(lang, 'detail_accident_step4_desc')),
          ]
        : [
            _DetailStep(Icons.compare_rounded,
                _t(lang, 'detail_finding_step1_title'),
                _t(lang, 'detail_finding_step1_desc')),
            _DetailStep(Icons.category_rounded,
                _t(lang, 'detail_finding_step2_title'),
                _t(lang, 'detail_finding_step2_desc')),
            _DetailStep(Icons.timer_rounded,
                _t(lang, 'detail_finding_step3_title'),
                _t(lang, 'detail_finding_step3_desc')),
            _DetailStep(Icons.swipe_rounded,
                _t(lang, 'detail_finding_step4_title'),
                _t(lang, 'detail_finding_step4_desc')),
            _DetailStep(Icons.emoji_events_rounded,
                _t(lang, 'detail_finding_step5_title'),
                _t(lang, 'detail_finding_step5_desc')),
          ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: color.withValues(alpha: 0.15), height: 24),
          Text(
            detailBody,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.black,
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (!isAccident) ...[
            Row(children: [
              _CategoryChip(
                label: _t(lang, 'detail_category_5r'),
                color: const Color(0xFF2F80ED),
              ),
              const SizedBox(width: 8),
              _CategoryChip(
                label: _t(lang, 'detail_category_kts'),
                color: const Color(0xFFFFC107),
              ),
            ]),
            const SizedBox(height: 16),
          ],
          ...List.generate(steps.length, (i) {
            final step = steps[i];
            final bool isLast = i == steps.length - 1;
            return _StepTile(step: step, color: color, isLast: isLast);
          }),
        ],
      ),
    );
  }
}

class _DetailStep {
  final IconData icon;
  final String title;
  final String desc;
  const _DetailStep(this.icon, this.title, this.desc);
}

class _StepTile extends StatelessWidget {
  final _DetailStep step;
  final Color color;
  final bool isLast;
  const _StepTile({
    required this.step,
    required this.color,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Icon(step.icon, size: 16, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: color.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D72F3),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    step.desc,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color color;
  const _CategoryChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}