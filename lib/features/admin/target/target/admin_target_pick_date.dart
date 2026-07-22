import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

const Color _kTargetDateBrandColor = Color(0xFF1D72F3);

Future<DateTime?> showAdminTargetDatePicker({
  required BuildContext context,
  required String lang,
  DateTime? initialDate,
}) {
  return showDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => _AdminTargetDateCalendarDialog(
      lang: lang,
      initialDate: initialDate,
    ),
  );
}

class _AdminTargetDateCalendarDialog extends StatefulWidget {
  final String lang;
  final DateTime? initialDate;

  const _AdminTargetDateCalendarDialog({
    required this.lang,
    required this.initialDate,
  });

  @override
  State<_AdminTargetDateCalendarDialog> createState() =>
      _AdminTargetDateCalendarDialogState();
}

class _AdminTargetDateCalendarDialogState
    extends State<_AdminTargetDateCalendarDialog> {
  late DateTime _visibleMonth;
  late DateTime _selected;

  static const List<String> _monthLabelsId = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  String _t(String id, String en, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  @override
  void initState() {
    super.initState();
    final init = widget.initialDate ?? DateTime.now();
    _selected = init;
    _visibleMonth = DateTime(_selected.year, _selected.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  List<String> get _weekdayLabels {
    if (widget.lang == 'EN') return const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    if (widget.lang == 'ZH') return const ['日', '一', '二', '三', '四', '五', '六'];
    return const ['M', 'S', 'S', 'R', 'K', 'J', 'S'];
  }

  String _monthTitle(DateTime d) {
    if (widget.lang == 'EN') return DateFormat('MMMM yyyy').format(d);
    if (widget.lang == 'ZH') return '${d.year}年 ${d.month}月';
    return '${_monthLabelsId[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final minSelectable = DateTime(2020, 1, 1);
    final maxSelectable = DateTime(2030, 12, 31);

    final firstDayOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingEmptyDays = firstDayOfMonth.weekday % 7;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _kTargetDateBrandColor.withValues(alpha: 0.25),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kTargetDateBrandColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.event_available_rounded,
                      color: _kTargetDateBrandColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _t('PILIH TANGGAL TARGET', 'SELECT TARGET DATE', '选择目标日期'),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kTargetDateBrandColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              DateFormat('EEE, d MMM yyyy').format(_selected),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _monthTitle(_visibleMonth),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _changeMonth(-1),
                      child: const Icon(Icons.chevron_left_rounded,
                          color: _kTargetDateBrandColor),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _changeMonth(1),
                      child: const Icon(Icons.chevron_right_rounded,
                          color: _kTargetDateBrandColor),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: _weekdayLabels
                  .map((w) => Expanded(
                        child: Center(
                          child: Text(
                            w,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 4),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: daysInMonth + leadingEmptyDays,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                if (index < leadingEmptyDays) return const SizedBox.shrink();
                final day = index - leadingEmptyDays + 1;
                final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
                final isSelected = date.year == _selected.year &&
                    date.month == _selected.month &&
                    date.day == _selected.day;
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final isDisabled =
                    date.isBefore(minSelectable) || date.isAfter(maxSelectable);

                return GestureDetector(
                  onTap: isDisabled ? null : () => setState(() => _selected = date),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _kTargetDateBrandColor
                          : (isToday
                              ? _kTargetDateBrandColor.withValues(alpha: 0.1)
                              : Colors.transparent),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$day',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isDisabled
                            ? Colors.grey.shade300
                            : isSelected
                                ? Colors.white
                                : (isToday ? _kTargetDateBrandColor : const Color(0xFF334155)),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    _t('Batal', 'Cancel', '取消'),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kTargetDateBrandColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('OK', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}