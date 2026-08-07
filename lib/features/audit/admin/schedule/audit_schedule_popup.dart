import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> showAuditSchedulePopup(
  BuildContext context, {
  required bool isSuccess,
  required String lang,
}) {
  final String message;
  if (lang == 'EN') {
    message = isSuccess ? 'Audit schedule saved!' : 'Failed to save schedule.';
  } else if (lang == 'ZH') {
    message = isSuccess ? '审计计划已保存！' : '保存计划失败。';
  } else {
    message = isSuccess
        ? 'Jadwal audit berhasil disimpan!'
        : 'Gagal menyimpan jadwal.';
  }

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (Navigator.of(dialogContext).canPop()) {
          Navigator.of(dialogContext).pop();
        }
      });
      return Dialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSuccess
                      ? const Color(0xFF10B981).withOpacity(0.12)
                      : const Color(0xFFEF4444).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess
                      ? Icons.check_circle_rounded
                      : Icons.error_rounded,
                  color: isSuccess
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  size: 42,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}