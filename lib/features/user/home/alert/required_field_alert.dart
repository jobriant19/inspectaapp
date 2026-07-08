import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class MissingFieldItem {
  final IconData icon;
  final String label;
  const MissingFieldItem({required this.icon, required this.label});
}

class RequiredFieldAlert {
  RequiredFieldAlert._();

  static const Color _kRed = Color(0xFFDC2626);
  static const Color _kRedLight = Color(0xFFFEF2F2);
  static const Color _kRedBorder = Color(0xFFFCA5A5);

  static Future<void> show(
    BuildContext context, {
    required String lang,
    required List<MissingFieldItem> missingFields,
  }) {
    if (missingFields.isEmpty) return Future.value();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => _RequiredFieldAlertDialog(
        lang: lang,
        missingFields: missingFields,
      ),
    );
  }
}

class _RequiredFieldAlertDialog extends StatelessWidget {
  final String lang;
  final List<MissingFieldItem> missingFields;

  const _RequiredFieldAlertDialog({
    required this.lang,
    required this.missingFields,
  });

  Map<String, String> get _t {
    switch (lang) {
      case 'EN':
        return {
          'title': 'Required Fields Missing',
          'subtitle': 'Please complete the following field(s) before saving:',
          'button': 'Understood',
        };
      case 'ZH':
        return {
          'title': '必填项未完成',
          'subtitle': '请先完善以下项目再保存：',
          'button': '明白',
        };
      default:
        return {
          'title': 'Data Wajib Belum Lengkap',
          'subtitle': 'Mohon lengkapi bagian berikut sebelum menyimpan:',
          'button': 'Mengerti',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: RequiredFieldAlert._kRed.withValues(alpha: 0.25),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: RequiredFieldAlert._kRedLight,
                      border: Border.all(
                        color: RequiredFieldAlert._kRedBorder,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.exclamationmark_triangle_fill,
                      color: RequiredFieldAlert._kRed,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t['title']!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: RequiredFieldAlert._kRed,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t['subtitle']!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: RequiredFieldAlert._kRedLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: RequiredFieldAlert._kRedBorder.withValues(alpha: 0.5),
                ),
              ),
              constraints: const BoxConstraints(maxHeight: 260),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: missingFields
                      .map((field) => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    field.icon,
                                    size: 16,
                                    color: RequiredFieldAlert._kRed,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    field.label,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF7F1D1D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RequiredFieldAlert._kRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    t['button']!,
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
}