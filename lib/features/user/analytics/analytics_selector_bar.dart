import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AnalyticsSubTabController {
  void setActiveSubTab(int index);
}

class AnalyticsMainTypeMeta {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  final Color borderColor;
  const AnalyticsMainTypeMeta({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.borderColor,
  });
}

class AnalyticsSubTabMeta {
  final String label;
  final IconData icon;
  const AnalyticsSubTabMeta({required this.label, required this.icon});
}

class AnalyticsSelectorBar extends StatelessWidget {
  final String lang;
  final List<AnalyticsMainTypeMeta> mainTypes;
  final String selectedMainKey;
  final ValueChanged<String> onMainTypeChanged;

  final List<AnalyticsSubTabMeta> subTabs;
  final int selectedSubTabIndex;
  final ValueChanged<int> onSubTabChanged;

  final String defaultMainKey;
  final int defaultSubTabIndex;
  final VoidCallback onResetToDefault;

  const AnalyticsSelectorBar({
    super.key,
    required this.lang,
    required this.mainTypes,
    required this.selectedMainKey,
    required this.onMainTypeChanged,
    required this.subTabs,
    required this.selectedSubTabIndex,
    required this.onSubTabChanged,
    required this.defaultMainKey,
    required this.defaultSubTabIndex,
    required this.onResetToDefault,
  });

  AnalyticsMainTypeMeta get _selectedMeta => mainTypes.firstWhere(
        (m) => m.key == selectedMainKey,
        orElse: () => mainTypes.first,
      );

  bool get _isMainDefault => selectedMainKey == defaultMainKey;
  bool get _isSubDefault => selectedSubTabIndex == defaultSubTabIndex;

  @override
  Widget build(BuildContext context) {
    final meta = _selectedMeta;
    final hasSubTabs = subTabs.isNotEmpty;
    final subMeta = (hasSubTabs && selectedSubTabIndex < subTabs.length)
        ? subTabs[selectedSubTabIndex]
        : null;

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _SelectorButton(
              icon: meta.icon,
              label: meta.label,
              color: meta.color,
              borderColor: meta.borderColor,
              onTap: () => _openMainPicker(context, meta),
              showReset: !_isMainDefault,
              onReset: onResetToDefault,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _SelectorButton(
              icon: subMeta?.icon ?? meta.icon,
              label: subMeta?.label ?? meta.label,
              color: meta.color,
              borderColor: meta.borderColor,
              enabled: hasSubTabs,
              onTap: hasSubTabs ? () => _openSubTabPicker(context, meta) : null,
              showReset: hasSubTabs && _isMainDefault && !_isSubDefault,
              onReset: onResetToDefault,
            ),
          ),
        ],
      ),
    );
  }

  void _openMainPicker(BuildContext context, AnalyticsMainTypeMeta activeMeta) {
    _showAnalyticsPickerPopup<AnalyticsMainTypeMeta>(
      context: context,
      lang: lang,
      title: lang == 'EN' ? 'Select View' : lang == 'ZH' ? '选择视图' : 'Pilih Tampilan',
      headerIcon: Icons.tune_rounded,
      items: mainTypes,
      itemLabel: (m) => m.label,
      itemIcon: (m) => m.icon,
      itemColor: (m) => m.color,
      isSelected: (m) => m.key == selectedMainKey,
      onSelected: (m) => onMainTypeChanged(m.key),
      accentColor: activeMeta.color,
    );
  }

  void _openSubTabPicker(BuildContext context, AnalyticsMainTypeMeta activeMeta) {
    _showAnalyticsPickerPopup<AnalyticsSubTabMeta>(
      context: context,
      lang: lang,
      title: lang == 'EN' ? 'Select Tab' : lang == 'ZH' ? '选择标签' : 'Pilih Tab',
      headerIcon: Icons.view_list_rounded,
      items: subTabs,
      itemLabel: (s) => s.label,
      itemIcon: (s) => s.icon,
      itemColor: (_) => activeMeta.color,
      isSelected: (s) => subTabs.indexOf(s) == selectedSubTabIndex,
      onSelected: (s) => onSubTabChanged(subTabs.indexOf(s)),
      accentColor: activeMeta.color,
    );
  }
}

class _SelectorButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;
  final bool enabled;
  final bool showReset;
  final VoidCallback onReset;
  const _SelectorButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.borderColor,
    required this.onTap,
    this.enabled = true,
    required this.showReset,
    required this.onReset,
  });

  bool get _showArrow => enabled && !showReset;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: enabled ? color : borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.10), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: 4,
                right: (showReset || _showArrow) ? 24 : 4,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(icon, size: 16, color: enabled ? color : color.withValues(alpha: 0.45)),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: enabled ? color : color.withValues(alpha: 0.45),
                        height: 1.0,
                      ),
                      maxLines: 1,
                      softWrap: false,
                      textHeightBehavior: const TextHeightBehavior(
                        applyHeightToFirstAscent: false,
                        applyHeightToLastDescent: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // TOMBOL RESET (X)
            if (showReset)
              Positioned(
                right: 0,
                child: GestureDetector(
                  onTap: onReset,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 13, color: Color(0xFFEF4444)),
                  ),
                ),
              ),
            if (_showArrow)
              Positioned(
                right: 0,
                child: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: color),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showAnalyticsPickerPopup<T>({
  required BuildContext context,
  required String lang,
  required String title,
  required IconData headerIcon,
  required List<T> items,
  required String Function(T) itemLabel,
  required IconData Function(T) itemIcon,
  required Color Function(T) itemColor,
  required bool Function(T) isSelected,
  required ValueChanged<T> onSelected,
  required Color accentColor,
}) async {
  final searchCtrl = TextEditingController();
  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) {
        final query = searchCtrl.text.trim().toLowerCase();
        final filtered = query.isEmpty
            ? items
            : items.where((i) => itemLabel(i).toLowerCase().contains(query)).toList();

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.72,
              maxWidth: 360,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentColor.withValues(alpha: 0.25), width: 1.5),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(headerIcon, color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: accentColor,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 18),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: const Color(0xFFF1F5F9)),
              // SEARCH + RESET SEARCH
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: TextField(
                  controller: searchCtrl,
                  onChanged: (_) => setSt(() {}),
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: lang == 'EN' ? 'Search...' : lang == 'ZH' ? '搜索...' : 'Cari...',
                    hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFFBDBDBD), fontWeight: FontWeight.w500),
                    prefixIcon: Icon(Icons.search_rounded, color: accentColor, size: 19),
                    suffixIcon: searchCtrl.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              searchCtrl.clear();
                              setSt(() {});
                            },
                            child: Container(
                              margin: const EdgeInsets.all(10),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFEF4444)),
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFF),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: accentColor.withValues(alpha: 0.2))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: accentColor.withValues(alpha: 0.2))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: accentColor, width: 1.5)),
                  ),
                ),
              ),
              // LIST / EMPTY STATE
              Flexible(
                child: filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 24),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Image.asset(
                            'assets/images/team_illustration.png',
                            height: 120,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.search_off_rounded,
                                  size: 40, color: accentColor.withValues(alpha: 0.4)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            lang == 'EN' ? 'Not found' : lang == 'ZH' ? '未找到' : 'Tidak ditemukan',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: accentColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lang == 'EN'
                                ? 'Try a different keyword'
                                : lang == 'ZH'
                                    ? '请尝试其他关键词'
                                    : 'Coba kata kunci lain',
                            style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () {
                              searchCtrl.clear();
                              setSt(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: accentColor.withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh_rounded, size: 15, color: accentColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    lang == 'EN'
                                        ? 'Clear search'
                                        : lang == 'ZH'
                                            ? '清除搜索'
                                            : 'Hapus pencarian',
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: accentColor),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ]),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final item = filtered[i];
                          final sel = isSelected(item);
                          final color = itemColor(item);
                          return InkWell(
                            onTap: () {
                              Navigator.pop(ctx);
                              onSelected(item);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: sel ? color.withValues(alpha: 0.10) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: sel ? color : const Color(0xFFE2E8F0), width: sel ? 1.5 : 1),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: sel ? color : color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Icon(itemIcon(item), size: 17, color: sel ? Colors.white : color),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    itemLabel(item),
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: sel ? color : Colors.black),
                                  ),
                                ),
                                if (sel) Icon(Icons.check_circle_rounded, color: color, size: 18),
                              ]),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
            ]),
          ),
        );
      },
    ),
  );
}