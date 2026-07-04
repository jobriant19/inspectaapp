import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Map<String, Map<String, String>> _proModeTexts = {
  'EN': {
    'on_title': 'Professional Mode Active', 'off_title': 'Professional Mode Off',
    'on_sub': 'You can now access all locations without restrictions.',
    'off_sub': 'Back to regular mode.',
  },
  'ID': {
    'on_title': 'Mode Profesional Aktif', 'off_title': 'Mode Profesional Nonaktif',
    'on_sub': 'Anda sekarang dapat mengakses semua lokasi tanpa batasan.',
    'off_sub': 'Kembali ke mode reguler.',
  },
  'ZH': {
    'on_title': '专业模式已激活', 'off_title': '专业模式已停用',
    'on_sub': '您现在可以不受限制地访问所有地点。', 'off_sub': '返回常规模式。',
  },
};

const Map<String, Map<String, String>> _visitorTexts = {
  'EN': {
    'on_title': 'Visitor Mode Active', 'off_title': 'Visitor Mode Off',
    'on_sub': 'Your findings will be tagged as visitor reports.',
    'off_sub': 'Back to regular mode.',
  },
  'ID': {
    'on_title': 'Mode Pengunjung Aktif', 'off_title': 'Mode Pengunjung Nonaktif',
    'on_sub': 'Temuan Anda akan ditandai sebagai laporan pengunjung.',
    'off_sub': 'Kembali ke mode reguler.',
  },
  'ZH': {
    'on_title': '访客模式已激活', 'off_title': '访客模式已停用',
    'on_sub': '您的发现将被标记为访客报告。', 'off_sub': '返回常规模式。',
  },
};

void _showModeStatusDialog({
  required BuildContext context,
  required bool isActive,
  required Map<String, String> t,
  required Color primary,
  required String assetPath,
  required IconData fallbackIcon,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (ctx) {
      Future.delayed(const Duration(seconds: 3), () {
        if (ctx.mounted && Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
      });
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 36),
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.3),
                  blurRadius: 30, spreadRadius: 5, offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withValues(alpha: 0.1),
                    border: Border.all(color: primary.withValues(alpha: 0.3), width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      assetPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(fallbackIcon, color: primary, size: 42),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isActive ? t['on_title']! : t['off_title']!,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  isActive ? t['on_sub']! : t['off_sub']!,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.0, end: 0.0),
                    duration: const Duration(milliseconds: 3000),
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v, minHeight: 4,
                      backgroundColor: primary.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(primary.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void showVisitorStatusDialog(BuildContext context, bool isVisitor, String lang) {
  final t = _visitorTexts[lang] ?? _visitorTexts['ID']!;
  final Color primary = isVisitor ? const Color.fromARGB(255, 242, 181, 26) : Colors.grey.shade500;
  _showModeStatusDialog(
    context: context,
    isActive: isVisitor,
    t: t,
    primary: primary,
    assetPath: isVisitor ? 'assets/images/visitor_on.png' : 'assets/images/visitor_off.png',
    fallbackIcon: isVisitor ? Icons.visibility_rounded : Icons.visibility_off_rounded,
  );
}

void showProModeStatusDialog(BuildContext context, bool isProMode, String lang) {
  final t = _proModeTexts[lang] ?? _proModeTexts['ID']!;
  final Color primary = isProMode ? const Color(0xFF16A34A) : Colors.grey.shade500;
  _showModeStatusDialog(
    context: context,
    isActive: isProMode,
    t: t,
    primary: primary,
    assetPath: 'assets/images/modepro.png',
    fallbackIcon: isProMode ? Icons.workspace_premium_rounded : Icons.workspace_premium_outlined,
  );
}