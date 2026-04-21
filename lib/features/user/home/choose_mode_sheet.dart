import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// WIDGET: TOMBOL "CHOOSE MODE" DI HOME CONTENT
// Panggil ini di tempat tombol Pro Mode sebelumnya berada
// ============================================================
class ChooseModeButton extends StatelessWidget {
  final bool isProMode;
  final bool isVisitorMode;
  final String lang;
  final VoidCallback onTap;

  const ChooseModeButton({
    super.key,
    required this.isProMode,
    required this.isVisitorMode,
    required this.lang,
    required this.onTap,
  });

  static const Map<String, String> _label = {
    'EN': 'Choose Mode',
    'ID': 'Pilih Mode',
    'ZH': '选择模式',
  };

  static const Map<String, String> _proLabel = {
    'EN': 'Pro',
    'ID': 'Pro',
    'ZH': '专业',
  };

  static const Map<String, String> _visitorLabel = {
    'EN': 'Visitor',
    'ID': 'Pengunjung',
    'ZH': '访客',
  };

  @override
  Widget build(BuildContext context) {
    final bool anyActive = isProMode || isVisitorMode;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: anyActive
              ? const LinearGradient(
                  colors: [Color(0xFF00C9E4), Color(0xFF0891B2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: anyActive ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: anyActive
                ? Colors.transparent
                : const Color(0xFF00C9E4).withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00C9E4)
                  .withOpacity(anyActive ? 0.3 : 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 18,
              color: anyActive ? Colors.white : const Color(0xFF00C9E4),
            ),
            const SizedBox(width: 6),
            Text(
              _label[lang] ?? 'Choose Mode',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: anyActive ? Colors.white : const Color(0xFF1E3A8A),
              ),
            ),
            if (anyActive) ...[
              const SizedBox(width: 8),
              _buildActiveBadge(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBadge() {
    final List<Widget> badges = [];
    if (isProMode) {
      badges.add(_MiniModeBadge(
        label: _proLabel[lang] ?? 'Pro',
        color: const Color(0xFF4ADE80),
      ));
    }
    if (isVisitorMode) {
      if (badges.isNotEmpty) badges.add(const SizedBox(width: 4));
      badges.add(_MiniModeBadge(
        label: _visitorLabel[lang] ?? 'Visitor',
        color: const Color(0xFFFBBF24),
      ));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: badges);
  }
}

class _MiniModeBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniModeBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.6), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ============================================================
// MODAL SHEET: CHOOSE MODE (Pro + Visitor)
// Panggil dengan: showChooseModeSheet(context, ...)
// ============================================================
Future<void> showChooseModeSheet({
  required BuildContext context,
  required bool isProMode,
  required bool isVisitorMode,
  required String lang,
  required ValueChanged<bool> onProModeChanged,
  required ValueChanged<bool> onVisitorModeChanged,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ChooseModeSheet(
      isProMode: isProMode,
      isVisitorMode: isVisitorMode,
      lang: lang,
      onProModeChanged: onProModeChanged,
      onVisitorModeChanged: onVisitorModeChanged,
    ),
  );
}

class _ChooseModeSheet extends StatefulWidget {
  final bool isProMode;
  final bool isVisitorMode;
  final String lang;
  final ValueChanged<bool> onProModeChanged;
  final ValueChanged<bool> onVisitorModeChanged;

  const _ChooseModeSheet({
    required this.isProMode,
    required this.isVisitorMode,
    required this.lang,
    required this.onProModeChanged,
    required this.onVisitorModeChanged,
  });

  @override
  State<_ChooseModeSheet> createState() => _ChooseModeSheetState();
}

class _ChooseModeSheetState extends State<_ChooseModeSheet>
    with SingleTickerProviderStateMixin {
  late bool _isProMode;
  late bool _isVisitorMode;
  late AnimationController _ctrl;
  late Animation<double> _slideAnim;

  static const Map<String, Map<String, String>> _txt = {
    'EN': {
      'title': 'Choose Mode',
      'subtitle': 'Customize your experience',
      'pro_title': 'Professional Mode',
      'pro_desc': 'Access all locations across the company without restrictions.',
      'visitor_title': 'Visitor Mode',
      'visitor_desc': 'Your findings will be tagged as visitor reports.',
      'pro_on': 'Pro Mode Activated',
      'pro_off': 'Pro Mode Deactivated',
      'visitor_on': 'Visitor Mode Activated',
      'visitor_off': 'Visitor Mode Deactivated',
      'active': 'Active',
      'inactive': 'Inactive',
      'done': 'Done',
    },
    'ID': {
      'title': 'Pilih Mode',
      'subtitle': 'Sesuaikan pengalaman Anda',
      'pro_title': 'Mode Profesional',
      'pro_desc': 'Akses semua lokasi di seluruh perusahaan tanpa batasan.',
      'visitor_title': 'Mode Pengunjung',
      'visitor_desc': 'Temuan Anda akan ditandai sebagai laporan pengunjung.',
      'pro_on': 'Mode Pro Diaktifkan',
      'pro_off': 'Mode Pro Dinonaktifkan',
      'visitor_on': 'Mode Pengunjung Diaktifkan',
      'visitor_off': 'Mode Pengunjung Dinonaktifkan',
      'active': 'Aktif',
      'inactive': 'Nonaktif',
      'done': 'Selesai',
    },
    'ZH': {
      'title': '选择模式',
      'subtitle': '自定义您的体验',
      'pro_title': '专业模式',
      'pro_desc': '不受限制地访问公司所有地点。',
      'visitor_title': '访客模式',
      'visitor_desc': '您的发现将被标记为访客报告。',
      'pro_on': '专业模式已激活',
      'pro_off': '专业模式已停用',
      'visitor_on': '访客模式已激活',
      'visitor_off': '访客模式已停用',
      'active': '激活',
      'inactive': '未激活',
      'done': '完成',
    },
  };

  String t(String key) => _txt[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _isProMode = widget.isProMode;
    _isVisitorMode = widget.isVisitorMode;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnim,
      builder: (_, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(_slideAnim),
        child: child,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C9E4), Color(0xFF0891B2)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tune_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('title'),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                      Text(
                        t('subtitle'),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Pro Mode Card
            _ModeCard(
              icon: Icons.workspace_premium_rounded,
              iconGradient: const LinearGradient(
                colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
              ),
              glowColor: const Color(0xFF4ADE80),
              title: t('pro_title'),
              description: t('pro_desc'),
              isActive: _isProMode,
              activeLabel: t('active'),
              inactiveLabel: t('inactive'),
              lang: widget.lang,
              onChanged: (val) {
                setState(() => _isProMode = val);
                widget.onProModeChanged(val);
                _showModeSnack(
                  context,
                  val ? t('pro_on') : t('pro_off'),
                  val ? const Color(0xFF16A34A) : Colors.grey.shade600,
                  val
                      ? Icons.workspace_premium_rounded
                      : Icons.workspace_premium_outlined,
                );
              },
            ),

            const SizedBox(height: 14),

            // Visitor Mode Card
            _ModeCard(
              icon: Icons.visibility_rounded,
              iconGradient: const LinearGradient(
                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
              ),
              glowColor: const Color(0xFFFBBF24),
              title: t('visitor_title'),
              description: t('visitor_desc'),
              isActive: _isVisitorMode,
              activeLabel: t('active'),
              inactiveLabel: t('inactive'),
              lang: widget.lang,
              onChanged: (val) {
                setState(() => _isVisitorMode = val);
                widget.onVisitorModeChanged(val);
                _showModeSnack(
                  context,
                  val ? t('visitor_on') : t('visitor_off'),
                  val ? const Color(0xFFF59E0B) : Colors.grey.shade600,
                  val ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                );
              },
            ),

            const SizedBox(height: 24),

            // Done Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C9E4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    t('done'),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModeSnack(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            message,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ── Sub-widget: Kartu mode tunggal ──
class _ModeCard extends StatelessWidget {
  final IconData icon;
  final LinearGradient iconGradient;
  final Color glowColor;
  final String title;
  final String description;
  final bool isActive;
  final String activeLabel;
  final String inactiveLabel;
  final String lang;
  final ValueChanged<bool> onChanged;

  const _ModeCard({
    required this.icon,
    required this.iconGradient,
    required this.glowColor,
    required this.title,
    required this.description,
    required this.isActive,
    required this.activeLabel,
    required this.inactiveLabel,
    required this.lang,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? glowColor.withOpacity(0.06) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? glowColor.withOpacity(0.4) : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: glowColor.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: isActive ? iconGradient : null,
              color: isActive ? null : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: glowColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey.shade400,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? const Color(0xFF1E3A8A)
                          : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive
                          ? glowColor.withOpacity(0.2)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isActive ? activeLabel : inactiveLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isActive ? glowColor : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Toggle Switch
          GestureDetector(
            onTap: () => onChanged(!isActive),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 50,
              height: 28,
              decoration: BoxDecoration(
                gradient: isActive ? iconGradient : null,
                color: isActive ? null : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: glowColor.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    left: isActive ? 24 : 2,
                    top: 2,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          )
                        ],
                      ),
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