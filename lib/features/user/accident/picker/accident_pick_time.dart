import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _kAccidentTimeBrandColor = Color(0xFF2563EB);

Future<TimeOfDay?> showAccidentTimePicker({
  required BuildContext context,
  required String lang,
  TimeOfDay? initialTime,
}) {
  return showTimePicker(
    context: context,
    initialTime: initialTime ?? TimeOfDay.now(),
    helpText: _timeHelpText(lang),
    cancelText: _timeCancelText(lang),
    confirmText: 'OK',
    builder: (ctx, child) {
      return Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kAccidentTimeBrandColor,
            onPrimary: Colors.white,
            onSurface: Color(0xFF0F172A),
          ),
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(ctx).textTheme),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            helpTextStyle: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kAccidentTimeBrandColor,
              letterSpacing: 0.4,
            ),
            hourMinuteTextStyle: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.w700),
            hourMinuteShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            hourMinuteColor: WidgetStateColor.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? _kAccidentTimeBrandColor.withValues(alpha: 0.12)
                    : const Color(0xFFF8FAFF)),
            hourMinuteTextColor: WidgetStateColor.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? _kAccidentTimeBrandColor
                    : const Color(0xFF0F172A)),
            dayPeriodShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            dayPeriodBorderSide: const BorderSide(color: Color(0xFFE0E7FF)),
            dayPeriodColor: WidgetStateColor.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? _kAccidentTimeBrandColor
                    : const Color(0xFFF1F5F9)),
            dayPeriodTextColor: WidgetStateColor.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? Colors.white
                    : const Color(0xFF64748B)),
            dialBackgroundColor: const Color(0xFFF8FAFF),
            dialHandColor: _kAccidentTimeBrandColor,
            dialTextColor: WidgetStateColor.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? Colors.white
                    : const Color(0xFF334155)),
            entryModeIconColor: _kAccidentTimeBrandColor,
            confirmButtonStyle: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: _kAccidentTimeBrandColor,
              textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            cancelButtonStyle: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade500,
              textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        child: child!,
      );
    },
  );
}

String _timeHelpText(String lang) {
  if (lang == 'EN') return 'SELECT INCIDENT TIME';
  if (lang == 'ZH') return '选择事故时间';
  return 'PILIH WAKTU KEJADIAN';
}

String _timeCancelText(String lang) {
  if (lang == 'EN') return 'Cancel';
  if (lang == 'ZH') return '取消';
  return 'Batal';
}