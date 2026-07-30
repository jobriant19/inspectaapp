import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminCategorySortOptionDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String currentValue;
  final List<Map<String, String>> options;
  final ValueChanged<String> onSelect;

  const AdminCategorySortOptionDialog({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.currentValue,
    required this.options,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: Icon(Icons.close_rounded,
                        size: 16, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          // OPTION LIST
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              children: options.map((opt) {
                final isSelected = currentValue == opt['value'];
                return GestureDetector(
                  onTap: () => onSelect(opt['value']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? color.withValues(alpha: 0.08) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey.shade200,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            opt['label']!,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? color : const Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, color: color, size: 18),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminCategoryFilterBar extends StatelessWidget {
  final String lang;
  final Color color;
  final String sortPoin;
  final String sortOrder;
  final ValueChanged<String> onSortPoinChanged;
  final ValueChanged<String> onSortOrderChanged;

  const AdminCategoryFilterBar({
    super.key,
    required this.lang,
    required this.color,
    required this.sortPoin,
    required this.sortOrder,
    required this.onSortPoinChanged,
    required this.onSortOrderChanged,
  });

  void _showPoinSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AdminCategorySortOptionDialog(
        title: lang == 'EN'
            ? 'Sort by Points'
            : lang == 'ZH'
                ? '按积分排序'
                : 'Urut berdasarkan Poin',
        icon: Icons.star_rounded,
        color: color,
        currentValue: sortPoin,
        options: [
          {
            'value': 'none',
            'label': lang == 'EN' ? 'Default' : lang == 'ZH' ? '默认' : 'Default'
          },
          {
            'value': 'desc',
            'label': lang == 'EN'
                ? 'Highest Points First'
                : lang == 'ZH'
                    ? '积分从高到低'
                    : 'Poin Terbesar Dulu'
          },
          {
            'value': 'asc',
            'label': lang == 'EN'
                ? 'Lowest Points First'
                : lang == 'ZH'
                    ? '积分从低到高'
                    : 'Poin Terkecil Dulu'
          },
        ],
        onSelect: (v) {
          onSortPoinChanged(v);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AdminCategorySortOptionDialog(
        title: lang == 'EN'
            ? 'Sort Order'
            : lang == 'ZH'
                ? '排序方式'
                : 'Urutan Abjad',
        icon: Icons.sort_by_alpha_rounded,
        color: color,
        currentValue: sortOrder,
        options: [
          {
            'value': 'none',
            'label': lang == 'EN'
                ? 'Default (No Sort)'
                : lang == 'ZH'
                    ? '默认'
                    : 'Default (Tanpa Urutan)'
          },
          {'value': 'asc', 'label': 'A → Z (Ascending)'},
          {'value': 'desc', 'label': 'Z → A (Descending)'},
        ],
        onSelect: (v) {
          onSortOrderChanged(v);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    String? activeLabel,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? color : Colors.grey.shade200,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: isActive ? Colors.white : color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                isActive && activeLabel != null ? '$label $activeLabel' : label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 13, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }

  String get _pointsLabel =>
      lang == 'EN' ? 'Sort by Points' : lang == 'ZH' ? '按积分排序' : 'Urut Poin';
  String get _sortLabel =>
      lang == 'EN' ? 'Sort' : lang == 'ZH' ? '排序' : 'Urutan';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildFilterButton(
            context,
            label: _pointsLabel,
            icon: Icons.star_rounded,
            isActive: sortPoin != 'none',
            activeLabel:
                sortPoin == 'asc' ? '↑' : sortPoin == 'desc' ? '↓' : null,
            onTap: () => _showPoinSortDialog(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterButton(
            context,
            label: _sortLabel,
            icon: Icons.sort_by_alpha_rounded,
            isActive: sortOrder != 'none',
            activeLabel:
                sortOrder == 'asc' ? 'A→Z' : sortOrder == 'desc' ? 'Z→A' : null,
            onTap: () => _showSortDialog(context),
          ),
        ),
      ],
    );
  }
}

class AdminCategoryActiveChips extends StatelessWidget {
  final String sortPoin;
  final String sortOrder;
  final Color color;
  final ValueChanged<String> onSortPoinChanged;
  final ValueChanged<String> onSortOrderChanged;

  const AdminCategoryActiveChips({
    super.key,
    required this.sortPoin,
    required this.sortOrder,
    required this.color,
    required this.onSortPoinChanged,
    required this.onSortOrderChanged,
  });

  Widget _chip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 13, color: color),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (sortPoin != 'none') {
      chips.add(_chip(
        sortPoin == 'asc' ? '⭐ Poin ↑' : '⭐ Poin ↓',
        () => onSortPoinChanged('none'),
      ));
    }
    if (sortOrder != 'none') {
      chips.add(_chip(
        sortOrder == 'asc' ? '🔤 A→Z' : '🔤 Z→A',
        () => onSortOrderChanged('none'),
      ));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(spacing: 8, runSpacing: 4, children: chips),
    );
  }
}