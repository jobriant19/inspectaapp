import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

const Color _kDeadlineBrandColor = Color(0xFF1D72F3);

class FindingDeadlinePickerCard extends StatelessWidget {
  final String lang;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateSelected;

  const FindingDeadlinePickerCard({
    super.key,
    required this.lang,
    required this.selectedDate,
    required this.onDateSelected,
  });

  String _t(String id, String en, String zh) {
    if (lang == 'EN') return en;
    if (lang == 'ZH') return zh;
    return id;
  }

  Future<void> _openPicker(BuildContext context) async {
    final result = await showFindingDeadlinePicker(
      context: context,
      lang: lang,
      initialDate: selectedDate,
    );
    if (result != null) onDateSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasValue = selectedDate != null;
    return GestureDetector(
      onTap: () => _openPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue
                ? _kDeadlineBrandColor.withValues(alpha: 0.5)
                : Colors.grey.shade200,
            width: hasValue ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                color: hasValue ? _kDeadlineBrandColor : const Color(0xFF1E3A8A),
                size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasValue
                    ? DateFormat('EEE, d MMM yyyy').format(selectedDate!)
                    : _t('Pilih Tanggal', 'Select Date', '选择日期'),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: hasValue ? Colors.black87 : Colors.grey.shade500,
                  fontWeight: hasValue ? FontWeight.w800 : FontWeight.normal,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down,
                color: hasValue ? _kDeadlineBrandColor : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

Future<DateTime?> showFindingDeadlinePicker({
  required BuildContext context,
  required String lang,
  DateTime? initialDate,
}) {
  return showDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => _FindingDeadlineCalendarDialog(
      lang: lang,
      initialDate: initialDate,
    ),
  );
}

class _FindingDeadlineCalendarDialog extends StatefulWidget {
  final String lang;
  final DateTime? initialDate;

  const _FindingDeadlineCalendarDialog({
    required this.lang,
    required this.initialDate,
  });

  @override
  State<_FindingDeadlineCalendarDialog> createState() =>
      _FindingDeadlineCalendarDialogState();
}

class _FindingDeadlineCalendarDialogState
    extends State<_FindingDeadlineCalendarDialog> {
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
    _selected = widget.initialDate ?? DateTime.now();
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
    final minSelectable = DateTime(today.year, today.month, today.day);
    final maxSelectable = today.add(const Duration(days: 365));

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
              color: _kDeadlineBrandColor.withValues(alpha: 0.25),
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
                    color: _kDeadlineBrandColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.event_available_rounded,
                      color: _kDeadlineBrandColor, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  _t('PILIH TANGGAL', 'SELECT DATE', '选择日期'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kDeadlineBrandColor,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
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
                          color: _kDeadlineBrandColor),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _changeMonth(1),
                      child: const Icon(Icons.chevron_right_rounded,
                          color: _kDeadlineBrandColor),
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
                          ? _kDeadlineBrandColor
                          : (isToday
                              ? _kDeadlineBrandColor.withValues(alpha: 0.1)
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
                                : (isToday ? _kDeadlineBrandColor : const Color(0xFF334155)),
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
                    backgroundColor: _kDeadlineBrandColor,
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