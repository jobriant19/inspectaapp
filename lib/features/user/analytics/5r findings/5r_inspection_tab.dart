import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/utils/jabatan_helper.dart';

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
  final String? avatarUrl;
  final int? idJabatan;
  final String? jabatanNama;
  final bool? isVerificator;

  const InspectionData5R({
    required this.name,
    required this.findings,
    this.isSelf = false,
    this.avatarUrl,
    this.idJabatan,
    this.jabatanNama,
    this.isVerificator,
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
      // FILTER BAR
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
            icon: Icons.calendar_month_rounded,
            isActive: widget.filterMode == 'daily',
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
                                      color: activeColor.withValues(alpha:0.28),
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

      // LAST UPDATED
      _buildLastUpdatedWidget(),

      // TABLE HEADER
      _buildTableHeader(
        [widget.getTxt('nama'), widget.getTxt('temuan')],
        flex: [3, 1],
      ),

      // TARGET ROW
      _buildTargetRow(
          [widget.getTxt('target_bulanan'), '${widget.targetInspeksi}']),

      // LIST
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
              return _buildEmptyState();
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

  // EMPTY STATE PROFESSIONAL & VISITOR
  Widget _buildEmptyState() {
    final isProfessional = widget.selectedInspectionRole == widget.getTxt('profesional');
    final isVisitor = widget.selectedInspectionRole == widget.getTxt('visitor');

    if (!isProfessional && !isVisitor) {
      return Center(
        child: Text(
            '${widget.getTxt('tidak_ada_temuan_role')} "${widget.selectedInspectionRole}".'),
      );
    }

    final asset = isProfessional
        ? 'assets/images/modepro.png'
        : 'assets/images/visitor_off.png';

    final title = isProfessional
        ? (widget.lang == 'ID'
            ? 'Belum Ada Temuan Profesional'
            : widget.lang == 'ZH'
                ? '暂无专业模式发现'
                : 'No Professional Findings Yet')
        : (widget.lang == 'ID'
            ? 'Belum Ada Temuan Visitor'
            : widget.lang == 'ZH'
                ? '暂无访客发现'
                : 'No Visitor Findings Yet');

    final subtitle = isProfessional
        ? (widget.lang == 'ID'
            ? 'Belum ada temuan yang tercatat menggunakan Mode Profesional pada periode ini.'
            : widget.lang == 'ZH'
                ? '本期尚未有使用专业模式记录的发现。'
                : 'No findings have been recorded using Professional Mode for this period.')
        : (widget.lang == 'ID'
            ? 'Belum ada temuan yang tercatat oleh Visitor pada periode ini.'
            : widget.lang == 'ZH'
                ? '本期尚未有访客记录的发现。'
                : 'No findings have been recorded by Visitors for this period.');

    final Color accent = isProfessional
        ? const Color(0xFFF59E0B)
        : const Color(0xFF3B82F6);

    return Align(
      alignment: const Alignment(0, -0.35),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                accent.withOpacity(0.16),
                accent.withOpacity(0.02),
              ]),
              boxShadow: [
                BoxShadow(
                    color: accent.withOpacity(0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10)),
              ],
            ),
            child: Image.asset(
              asset,
              width: 130,
              height: 130,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                  Icons.image_not_supported_rounded,
                  size: 80,
                  color: accent.withOpacity(0.4)),
            ),
          ),
          const SizedBox(height: 20),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: accent,
                  letterSpacing: 0.1)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withOpacity(0.18)),
            ),
            child: Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5,
                    color: _AppColors.textPrimary,
                    height: 1.55,
                    fontWeight: FontWeight.w500)),
          ),
        ]),
      ),
    );
  }

  Widget _buildLastUpdatedWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _AppColors.primaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.access_time_filled_rounded,
                size: 13, color: _AppColors.primary),
            const SizedBox(width: 6),
            Text(widget.lastUpdatedText,
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _AppColors.textPrimary)),
          ]),
        ),
      ),
    );
  }

  Widget _buildTableHeader(List<String> cols, {required List<int> flex}) {
    return Container(
      color: const Color(0xFFF8FAFF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: List.generate(cols.length, (i) {
          return Expanded(
            flex: flex[i],
            child: Text(
              cols[i],
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _AppColors.textSecondary,
                  letterSpacing: 0.2),
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
          child: Text(
            vals[0],
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _AppColors.primary),
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
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
            flex: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Avatar5R(name: item.name, avatarUrl: item.avatarUrl, size: 36),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    _buildJabatanBadge(
                        idJabatan: item.idJabatan,
                        jabatanNama: item.jabatanNama,
                        isVerificator: item.isVerificator),
                  ],
                )),
              ],
            )),
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

  // ROLE BADGE
  Widget _buildJabatanBadge({
    required int?    idJabatan,
    required String? jabatanNama,
    required bool?   isVerificator,
  }) {
    final label = JabatanHelper.getDisplayRole(
      isVerificatorFlag: isVerificator,
      idJabatan: idJabatan,
      jabatanFromDb: jabatanNama,
      lang: widget.lang,
    );
    if (label.isEmpty) return const SizedBox.shrink();
    final color = JabatanHelper.getPrimaryColor(
        isVerificatorFlag: isVerificator, idJabatan: idJabatan);
    final icon = JabatanHelper.getRoleIcon(
        isVerificatorFlag: isVerificator, idJabatan: idJabatan);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha:0.4), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
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

// AVATAR 
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
        color: bg.withValues(alpha:0.15),
        shape: BoxShape.circle,
        border: Border.all(color: bg.withValues(alpha:0.3), width: 1),
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