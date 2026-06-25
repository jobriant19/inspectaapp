import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class _AppColors {
  static const primary = Color(0xFF0EA5E9);
  static const primaryLight = Color(0xFFE0F2FE);
  static const textPrimary = Color(0xFF0C4A6E);
  static const textSecondary = Color(0xFF64748B);
  static const divider = Color(0xFFE0F2FE);
}

class InspectionData5R {
  final String name;
  final int findings;
  final bool isSelf;

  const InspectionData5R({
    required this.name,
    required this.findings,
    this.isSelf = false,
  });
}

class FiveRInspectionTab extends StatefulWidget {
  final String lang;
  final String filterMode;
  final int selectedMonthIndex;
  final DateTime? selectedDate;
  final int targetInspeksi;
  final String lastUpdatedText;
  final String Function(String) getTxt;
  final List<String> translatedMonths;
  final List<String> translatedRoles;
  final String selectedInspectionRole;
  final Future<List<InspectionData5R>>? inspeksiFuture;
  final Widget Function({
    required String label,
    required VoidCallback onTap,
    IconData icon,
    bool isActive,
  }) buildFilterBtn;
  final void Function(VoidCallback) showMonthPicker;
  final void Function(String role) onRoleChanged;

  const FiveRInspectionTab({
    super.key,
    required this.lang,
    required this.filterMode,
    required this.selectedMonthIndex,
    required this.selectedDate,
    required this.targetInspeksi,
    required this.lastUpdatedText,
    required this.getTxt,
    required this.translatedMonths,
    required this.translatedRoles,
    required this.selectedInspectionRole,
    required this.inspeksiFuture,
    required this.buildFilterBtn,
    required this.showMonthPicker,
    required this.onRoleChanged,
  });

  @override
  State<FiveRInspectionTab> createState() => _FiveRInspectionTabState();
}

class _FiveRInspectionTabState extends State<FiveRInspectionTab> {
  static const Map<String, Color> _roleColors = {
    'Eksekutif': Color(0xFFEF4444),
    'Executive': Color(0xFFEF4444),
    '行政': Color(0xFFEF4444),
    'Profesional': Color(0xFFF59E0B),
    'Professional': Color(0xFFF59E0B),
    '专业': Color(0xFFF59E0B),
    'Visitor': Color(0xFF3B82F6),
    '访客': Color(0xFF3B82F6),
  };

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Filter bar ──────────────────────────────────────────────────────
      Container(
        color: Colors.transparent,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          widget.buildFilterBtn(
            label: widget.filterMode == 'daily' && widget.selectedDate != null
                ? DateFormat(
                    'd MMM yyyy',
                    widget.lang == 'ID'
                        ? 'id_ID'
                        : widget.lang == 'EN'
                            ? 'en_US'
                            : 'zh_CN',
                  ).format(widget.selectedDate!)
                : widget.translatedMonths[widget.selectedMonthIndex],
            isActive: true,
            onTap: () => widget.showMonthPicker(() {}),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: widget.translatedRoles.map((r) {
                final isSelected = widget.selectedInspectionRole == r;
                final activeColor = _roleColors[r] ?? _AppColors.primary;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: r != widget.translatedRoles.last ? 6 : 0),
                    child: GestureDetector(
                      onTap: () => widget.onRoleChanged(r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 38,
                        decoration: BoxDecoration(
                          color: isSelected ? activeColor : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? activeColor : _AppColors.divider,
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                      color: activeColor.withOpacity(0.28),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3))
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            r,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : _AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ]),
      ),

      // ── Last updated ────────────────────────────────────────────────────
      _buildLastUpdatedWidget(),

      // ── Table header ────────────────────────────────────────────────────
      _buildTableHeader(
        [widget.getTxt('nama'), widget.getTxt('temuan')],
        flex: [3, 1],
      ),

      // ── Target row ──────────────────────────────────────────────────────
      _buildTargetRow(
          [widget.getTxt('target_bulanan'), '${widget.targetInspeksi}']),

      // ── List ────────────────────────────────────────────────────────────
      Expanded(child: Builder(builder: (context) {
        if (widget.inspeksiFuture == null) return _buildInspeksiShimmer();
        return FutureBuilder<List<InspectionData5R>>(
          future: widget.inspeksiFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildInspeksiShimmer();
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                    '${widget.getTxt('tidak_ada_temuan_role')} "${widget.selectedInspectionRole}".'),
              );
            }
            return ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: snapshot.data!.length,
              separatorBuilder: (_, __) => const Divider(
                  height: 1, color: _AppColors.divider, indent: 16),
              itemBuilder: (_, i) =>
                  _buildInspectionRow(snapshot.data![i]),
            );
          },
        );
      })),
    ]);
  }

  // ── Widgets pembantu ────────────────────────────────────────────────────────

  Widget _buildLastUpdatedWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        widget.lastUpdatedText,
        style: const TextStyle(
            fontSize: 11, color: _AppColors.textSecondary, height: 1.4),
      ),
    );
  }

  Widget _buildTableHeader(List<String> cols, {required List<int> flex}) {
    return Container(
      color: const Color(0xFFF8FAFF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: List.generate(cols.length, (i) {
          final isFirst = i == 0;
          return Expanded(
            flex: flex[i],
            child: Padding(
              padding: EdgeInsets.only(left: isFirst ? 44 : 0),
              child: Text(
                cols[i],
                textAlign: isFirst ? TextAlign.left : TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _AppColors.textSecondary,
                    letterSpacing: 0.2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTargetRow(List<String> vals) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: _AppColors.primaryLight,
        border: Border(bottom: BorderSide(color: _AppColors.divider)),
      ),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(
              vals[0],
              textAlign: TextAlign.left,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _AppColors.primary),
            ),
          ),
        ),
        ...vals.sublist(1).map((v) => Expanded(
              flex: 1,
              child: Text(
                v,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _AppColors.primary),
              ),
            )),
      ]),
    );
  }

  Widget _buildInspectionRow(InspectionData5R item) {
    final target = widget.targetInspeksi;
    final findingsColor = (target > 0 && item.findings >= target)
        ? const Color(0xFF16A34A)
        : _AppColors.textPrimary;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Expanded(
            flex: 3,
            child: Row(children: [
              _Avatar5R(name: item.name, size: 34),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(item.name,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _AppColors.textPrimary))),
            ])),
        Expanded(
            flex: 1,
            child: Text(
              '${item.findings}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: findingsColor),
            )),
      ]),
    );
  }

  Widget _buildInspeksiShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: 10,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: _AppColors.divider, indent: 16),
        itemBuilder: (_, __) => Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Expanded(
                flex: 3,
                child: Row(children: [
                  _buildShimmerBox(height: 34, width: 34, isCircle: true),
                  const SizedBox(width: 10),
                  Expanded(child: _buildShimmerBox(height: 14)),
                ])),
            Expanded(
                flex: 1,
                child: Center(
                    child: _buildShimmerBox(height: 14, width: 20))),
          ]),
        ),
      ),
    );
  }

  Widget _buildShimmerBox(
      {double? width,
      required double height,
      bool isCircle = false,
      double borderRadius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(isCircle ? height / 2 : borderRadius),
      ),
    );
  }
}

// ── Avatar helper (lokal, tidak perlu export) ─────────────────────────────────
class _Avatar5R extends StatelessWidget {
  final String name;
  final Color? color;
  final double size;
  final String? avatarUrl;

  const _Avatar5R(
      // ignore: unused_element_parameter
      {required this.name, this.color, this.size = 36, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(avatarUrl!),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }
    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    final bg = color ?? _AppColors.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: bg.withOpacity(0.3), width: 1),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
              fontSize: size * 0.35,
              fontWeight: FontWeight.w700,
              color: bg),
        ),
      ),
    );
  }
}