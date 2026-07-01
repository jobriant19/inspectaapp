import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'kts_section_location_picker.dart';

const List<String> kKtsBagianKasieList = [
  'Laser', 'Mesin', 'Spot', 'Las', 'Ftw', 'Cat',
  'Assy', 'Ekspedisi & Packing', 'Purchasing', 'Engineering', 'PPIC',
];

class _C {
  static const primary      = Color(0xFFF59E0B);
  static const primaryDark  = Color(0xFFD97706);
  static const primaryLight = Color(0xFFFEF3C7);
  static const textPrimary  = Color(0xFF78350F);
  static const textSec      = Color(0xFF92400E);
  static const divider      = Color(0xFFFDE68A);
  static const barColor     = Color(0xFFAB47BC);
}

class _KasieRow {
  final String kasieId;
  final String kasieNama;
  final String bagian;
  final Map<int, int> bulanan;
  final int total;

  const _KasieRow({
    required this.kasieId,
    required this.kasieNama,
    required this.bagian,
    required this.bulanan,
    required this.total,
  });
}

enum _RangeFilter { thisMonth, threeMonths, sixMonths }

extension _RF on _RangeFilter {
  String label(String lang) {
    switch (this) {
      case _RangeFilter.thisMonth:
        return lang == 'EN' ? 'This Month' : lang == 'ZH' ? '本月' : 'Bulan Ini';
      case _RangeFilter.threeMonths:
        return lang == 'EN' ? '3 Months' : lang == 'ZH' ? '3个月' : '3 Bulan';
      case _RangeFilter.sixMonths:
        return lang == 'EN' ? '6 Months' : lang == 'ZH' ? '6个月' : '6 Bulan';
    }
  }

  int get monthCount {
    switch (this) {
      case _RangeFilter.thisMonth:   return 1;
      case _RangeFilter.threeMonths: return 3;
      case _RangeFilter.sixMonths:   return 6;
    }
  }
}

class KtsKasieTab extends StatefulWidget {
  final String lang;
  const KtsKasieTab({super.key, required this.lang});

  @override
  State<KtsKasieTab> createState() => _KtsKasieTabState();
}

class _KtsKasieTabState extends State<KtsKasieTab> {
  final _db = Supabase.instance.client;

  String _t(String k) => _i18n[widget.lang]?[k] ?? _i18n['ID']![k] ?? k;

  static const _i18n = {
    'ID': {
      'laporan_kts' : 'Laporan KTS',
      'kasie'       : 'Kasie',
      'bagian'      : 'Bagian',
      'total'       : 'Total',
      'semua_bagian': 'Semua Bagian',
      'pilih_bagian': 'Pilih Bagian',
      'tidak_ada'   : 'Tidak ada data untuk periode ini',
      'grafik'      : 'Grafik',
      'terapkan'    : 'Terapkan',
      'nama'        : 'Nama',
      'bulan_ini'   : 'Bulan Ini',
    },
    'EN': {
      'laporan_kts' : 'KTS Report',
      'kasie'       : 'Kasie',
      'bagian'      : 'Section',
      'total'       : 'Total',
      'semua_bagian': 'All Sections',
      'pilih_bagian': 'Select Section',
      'tidak_ada'   : 'No data for this period',
      'grafik'      : 'Chart',
      'terapkan'    : 'Apply',
      'nama'        : 'Name',
      'bulan_ini'   : 'This Month',
    },
    'ZH': {
      'laporan_kts' : 'KTS报告',
      'kasie'       : '科长',
      'bagian'      : '部门',
      'total'       : '总计',
      'semua_bagian': '所有部门',
      'pilih_bagian': '选择部门',
      'tidak_ada'   : '此期间无数据',
      'grafik'      : '图表',
      'terapkan'    : '应用',
      'nama'        : '名称',
      'bulan_ini'   : '本月',
    },
  };

  // STATE
  _RangeFilter _range = _RangeFilter.threeMonths;
  String? _filterBagian;
  bool _chartExpanded = false;
  bool _loading = false;

  List<_KasieRow> _rows = [];
  List<String> _bulanLabels = [];
  Map<String, String> _sectionNameMap = {};

  @override
  void initState() {
    super.initState();
    _loadSectionNameMap().then((_) => _loadData());
  }

  // MONTH RANGE
  List<DateTime> _getMonths() {
    final now = DateTime.now();
    final count = _range.monthCount;
    return List.generate(count, (i) {
      final offset = count - 1 - i;
      return DateTime(now.year, now.month - offset, 1);
    });
  }

  Future<void> _loadSectionNameMap() async {
    try {
      final res = await _db
          .from('section')
          .select('nama_section_id, nama_section_en, nama_section_zh');
      final rows = List<Map<String, dynamic>>.from(res);
      final map = <String, String>{};
      for (final r in rows) {
        final idName = (r['nama_section_id'] as String?)?.trim();
        if (idName == null || idName.isEmpty) continue;
        map[idName.toLowerCase()] = idName;
        final enName = (r['nama_section_en'] as String?)?.trim();
        if (enName != null && enName.isNotEmpty) map[enName.toLowerCase()] = idName;
        final zhName = (r['nama_section_zh'] as String?)?.trim();
        if (zhName != null && zhName.isNotEmpty) map[zhName.toLowerCase()] = idName;
      }
      if (mounted) setState(() => _sectionNameMap = map);
    } catch (e) {
      debugPrint('loadSectionNameMap error: $e');
    }
  }

  String _resolveSectionName(String raw) {
    final key = raw.trim().toLowerCase();
    return _sectionNameMap[key] ?? raw.trim();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final months = _getMonths();
      final locale = widget.lang == 'ID' ? 'id_ID'
          : widget.lang == 'EN' ? 'en_US' : 'zh_CN';

      _bulanLabels = months.map((m) =>
          DateFormat('MMM yy', locale).format(m)).toList();

      final kasieRes = await _db
          .from('User')
          .select('id_user, nama, bagian_kasie')
          .eq('id_jabatan', 3);

      var kasieList = List<Map<String, dynamic>>.from(kasieRes);

      if (_filterBagian != null) {
        kasieList = kasieList.where((k) {
          final raw = (k['bagian_kasie'] as String?)?.trim() ?? '';
          return raw.isNotEmpty && _resolveSectionName(raw) == _filterBagian;
        }).toList();
      }

      if (kasieList.isEmpty) {
        setState(() { _rows = []; _loading = false; });
        return;
      }

      final start = months.first;
      final end = DateTime(months.last.year, months.last.month + 1, 0, 23, 59, 59);

      final penyelesaianRes = await _db
          .from('temuan')
          .select('''
            id_temuan,
            created_at,
            penyelesaian!temuan_id_penyelesaian_fkey(
              bagian
            )
          ''')
          .eq('jenis_temuan', 'KTS Production')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .not('id_penyelesaian', 'is', null);

      final penyelesaianList = List<Map<String, dynamic>>.from(penyelesaianRes);

      final Map<String, Set<int>> bagianMonthSet = {};
      for (final row in penyelesaianList) {
        final p = row['penyelesaian'] as Map<String, dynamic>?;
        if (p == null) continue;
        final rawBagian = (p['bagian'] as String?)?.trim() ?? '';
        if (rawBagian.isEmpty) continue;
        final bagian = _resolveSectionName(rawBagian);
        final createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '');
        if (createdAt == null) continue;

        for (int i = 0; i < months.length; i++) {
          final m = months[i];
          if (createdAt.year == m.year && createdAt.month == m.month) {
            bagianMonthSet.putIfAbsent(bagian, () => {}).add(i);
            break;
          }
        }
      }

      final rows = kasieList.map((k) {
        final kasieId   = k['id_user']?.toString() ?? '';
        final kasieNama = k['nama']?.toString() ?? '-';
        final rawBagianKasie = (k['bagian_kasie'] as String?)?.trim() ?? '';
        final bagian = rawBagianKasie.isEmpty ? '' : _resolveSectionName(rawBagianKasie);

        final monthSet = bagianMonthSet[bagian] ?? {};
        final bulanan = <int, int>{};
        for (int i = 0; i < months.length; i++) {
          bulanan[i] = monthSet.contains(i) ? 1 : 0;
        }
        final total = monthSet.length;

        return _KasieRow(
          kasieId: kasieId,
          kasieNama: kasieNama,
          bagian: bagian,
          bulanan: bulanan,
          total: total,
        );
      }).toList()
        ..sort((a, b) => b.total.compareTo(a.total));

      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      debugPrint('KtsKasieTab loadData error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  // FILTER PICKERS
  void _showRangePicker() async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.primaryLight, width: 1.5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
              decoration: const BoxDecoration(
                color: _C.primaryLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(children: [
                const Icon(Icons.date_range_rounded, color: _C.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  widget.lang == 'EN' ? 'Select Period'
                      : widget.lang == 'ZH' ? '选择期间' : 'Pilih Periode',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _C.textPrimary),
                )),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: _C.textSec),
                  onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero,
                ),
              ]),
            ),
            const SizedBox(height: 8),
            ..._RangeFilter.values.map((r) {
              final sel = _range == r;
              return GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _range = r);
                  _loadData();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: sel ? _C.primaryLight : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel ? _C.primary : const Color(0xFFE2E8F0),
                      width: sel ? 1.8 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Expanded(child: Text(r.label(widget.lang),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: sel ? _C.primaryDark : const Color(0xFF1E293B),
                      ),
                    )),
                    if (sel) const Icon(Icons.check_circle_rounded, color: _C.primary, size: 20),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }

  void _showBagianPicker() async {
    final result = await showKtsSectionLocationPicker(context, lang: widget.lang);
    if (result == null) return;
    setState(() => _filterBagian = result.isAllSections ? null : result.sectionName);
    _loadData();
  }

  // FILTER BAR
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(children: [
        // RANGE MONTH BUTTON
        _filterBtn(
          label: _range.label(widget.lang),
          color: _C.primary,
          active: true,
          icon: Icons.date_range_rounded,
          onTap: _showRangePicker,
        ),
        const SizedBox(width: 8),
        // SECTION BUTTON
        Expanded(child: _filterBtn(
          label: _filterBagian ?? _t('semua_bagian'),
          color: _C.primary,
          active: _filterBagian != null,
          icon: Icons.grid_view_rounded,
          onTap: _showBagianPicker,
        )),
      ]),
    );
  }

  Widget _filterBtn({
    required String label,
    required VoidCallback onTap,
    required Color color,
    bool active = false,
    IconData icon = Icons.keyboard_arrow_down_rounded,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? color : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? color : _C.primaryLight, width: 1.5),
          boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: active ? Colors.white : color),
          const SizedBox(width: 6),
          Flexible(child: Text(label,
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: active ? Colors.white : color,
            ),
            overflow: TextOverflow.ellipsis,
          )),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded,
              size: 16, color: active ? Colors.white : color),
        ]),
      ),
    );
  }

  // CHART TOGGLE HEADER
  Widget _buildChartToggle() {
    final locale = widget.lang == 'ID' ? 'id_ID'
        : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    final months = _getMonths();
    String rangeLabel;
    if (months.length == 1) {
      rangeLabel = DateFormat('MMMM yyyy', locale).format(months.first);
    } else {
      rangeLabel = '${DateFormat('MMM', locale).format(months.first)} – '
          '${DateFormat('MMM yyyy', locale).format(months.last)}';
    }

    return GestureDetector(
      onTap: () => setState(() => _chartExpanded = !_chartExpanded),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _C.primary.withOpacity(0.45), width: 1.2),
          boxShadow: [BoxShadow(
              color: _C.primary.withOpacity(0.07), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          const Icon(Icons.bar_chart_rounded, size: 16, color: _C.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(
            '${_t('grafik')} ${_t('laporan_kts')} – $rangeLabel',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _C.primaryDark),
          )),
          AnimatedRotation(
            turns: _chartExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 250),
            child: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: _C.primary),
          ),
        ]),
      ),
    );
  }

  // HORIZONTAL BAR CHART
  Widget _buildChart() {
    if (_loading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[50]!,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          height: 200,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    final nonZero = _rows.where((r) => r.total > 0).toList();
    final zero    = _rows.where((r) => r.total == 0).toList();
    final sorted  = [...nonZero, ...zero];

    if (sorted.isEmpty) return _emptyBox();

    final xMax   = _range.monthCount;
    final xTicks = List.generate(xMax + 1, (i) => i);

    const double labelW  = 72.0;
    const double barH    = 22.0;
    const double rowVPad = 4.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.primaryLight, width: 1.2),
        boxShadow: [BoxShadow(
            color: _C.primary.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: LayoutBuilder(builder: (ctx, constraints) {
        final barAreaW = constraints.maxWidth - labelW - 8;

        final List<double> tickX = xTicks
            .map((v) => xMax > 0 ? (v / xMax) * barAreaW : 0.0)
            .toList();

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // X LABEL LINE
          Row(children: [
            SizedBox(width: labelW + 8),
            SizedBox(
              width: barAreaW,
              height: 16,
              child: Stack(
                clipBehavior: Clip.none,
                children: List.generate(xTicks.length, (i) {
                  double left = tickX[i];
                  if (i == xTicks.length - 1) left -= 8;
                  return Positioned(
                    left: left,
                    top: 0,
                    child: Text(
                      '${xTicks[i]}',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: i == 0 ? TextAlign.left
                          : i == xTicks.length - 1 ? TextAlign.right
                          : TextAlign.center,
                    ),
                  );
                }),
              ),
            ),
          ]),

          // TOP LINE
          Row(children: [
            SizedBox(width: labelW + 8),
            Container(width: barAreaW, height: 1, color: const Color(0xFFE2E8F0)),
          ]),
          const SizedBox(height: 4),

          // BAR ROWS
          ...sorted.map((row) {
            final frac     = xMax > 0 ? row.total / xMax : 0.0;
            final barWidth = (barAreaW * frac).clamp(0.0, barAreaW);
            final isZero   = row.total == 0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: rowVPad),
              child: SizedBox(
                height: barH,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // LEFT LABEL KASIE NAME
                    SizedBox(
                      width: labelW,
                      child: Text(
                        row.kasieNama,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isZero
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF334155),
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // BAR AREA
                    Expanded(child: CustomPaint(
                      painter: _KasieBarPainter(
                        tickX: tickX,
                        barWidth: barWidth,
                        barH: barH,
                        barVPad: rowVPad * 0.5,
                        isZero: isZero,
                      ),
                      child: const SizedBox.expand(),
                    )),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 4),
          // BOTTOM LINE
          Row(children: [
            SizedBox(width: labelW + 8),
            Container(width: barAreaW, height: 1, color: const Color(0xFFE2E8F0)),
          ]),
        ]);
      }),
    );
  }

  // TABLE
  Widget _buildTable() {
    if (_loading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[50]!,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          height: 200,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    if (_rows.isEmpty) return _emptyBox();

    final locale = widget.lang == 'ID' ? 'id_ID'
        : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    final months = _getMonths();
    final bulanLabels3 = months
        .map((m) => DateFormat('MMM', locale).format(m))
        .toList();

    final List<int> colTotals = List.generate(
        _bulanLabels.length,
        (i) => _rows.fold(0, (s, r) => s + (r.bulanan[i] ?? 0)));
    final int grandTotal = _rows.fold(0, (s, r) => s + r.total);

    const int flexSection = 3;
    const int flexKasie   = 4;
    const int flexMonth   = 2;
    const int flexTotal   = 2;

    Widget headerCell(String text, {int flex = 2, TextAlign align = TextAlign.left, Color? color}) =>
      Expanded(
        flex: flex,
        child: Text(text,
          textAlign: align,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color ?? _C.textSec,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );

    Widget buildHeaderRow() => Container(
      decoration: const BoxDecoration(
        color: _C.primaryLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        headerCell(_t('bagian'), flex: flexSection),
        headerCell(_t('kasie'), flex: flexKasie),
        ...bulanLabels3.map((lbl) =>
          headerCell(lbl, flex: flexMonth, align: TextAlign.center)),
        headerCell(_t('total'),
          flex: flexTotal,
          align: TextAlign.center,
          color: _C.primaryDark),
      ]),
    );

    Widget buildDataRow(int idx, _KasieRow row) => Container(
      decoration: BoxDecoration(
        border: idx > 0
            ? const Border(top: BorderSide(color: _C.divider))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        // SECTION
        Expanded(
          flex: flexSection,
          child: Text(
            row.bagian.isEmpty ? '-' : row.bagian,
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: row.total > 0 ? _C.textPrimary : const Color(0xFFCBD5E1),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // KASIE NAME
        Expanded(
          flex: flexKasie,
          child: Text(
            row.kasieNama,
            style: TextStyle(
              fontSize: 11,
              color: row.total > 0 ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // VALUE PER MONTH
        ...List.generate(_bulanLabels.length, (mi) {
          final val = row.bulanan[mi] ?? 0;
          return Expanded(
            flex: flexMonth,
            child: Center(child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: val > 0
                    ? _C.barColor.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(child: Text(
                '$val',
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: val > 0 ? _C.barColor : const Color(0xFFCBD5E1),
                ),
              )),
            )),
          );
        }),
        // TOTAL
        Expanded(
          flex: flexTotal,
          child: Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: row.total > 0 ? _C.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${row.total}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w900,
                color: row.total > 0 ? Colors.white : const Color(0xFFCBD5E1),
              ),
            ),
          )),
        ),
      ]),
    );

    Widget buildFooterRow() => Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFF7ED),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(top: BorderSide(color: _C.divider, width: 1.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        // LABEL "TOTAL" SPAN SECTION + KASIE
        Expanded(
          flex: flexSection + flexKasie,
          child: Text(
            widget.lang == 'EN' ? 'Total' : widget.lang == 'ZH' ? '合计' : 'Total',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w900, color: _C.textPrimary),
          ),
        ),
        // TOTAL PER MONTH
        ...List.generate(_bulanLabels.length, (mi) => Expanded(
          flex: flexMonth,
          child: Center(child: Text(
            '${colTotals[mi]}',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w900, color: _C.primaryDark),
          )),
        )),
        // GRAND TOTAL
        Expanded(
          flex: flexTotal,
          child: Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: _C.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$grandTotal',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          )),
        ),
      ]),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.primaryLight, width: 1.5),
        boxShadow: [BoxShadow(
            color: _C.primary.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        buildHeaderRow(),
        ..._rows.asMap().entries.map((e) => buildDataRow(e.key, e.value)),
        buildFooterRow(),
      ]),
    );
  }

  Widget _emptyBox() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.primaryLight, width: 1.5),
      ),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.bar_chart_outlined, size: 40, color: _C.primaryLight),
        const SizedBox(height: 8),
        Text(_t('tidak_ada'),
          style: const TextStyle(color: _C.textSec, fontSize: 13)),
      ])),
    );
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildFilterBar(),
      _buildChartToggle(),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: _C.primary,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _chartExpanded ? _buildChart() : const SizedBox.shrink(),
              ),
              // SECTION TITLE
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _C.barColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_outline_rounded,
                        size: 14, color: _C.barColor),
                  ),
                  const SizedBox(width: 8),
                  Text(_t('laporan_kts') + ' ' + _t('kasie'),
                    style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800, color: _C.barColor)),
                ]),
              ),
              _buildTable(),
            ],
          ),
        ),
      ),
    ]);
  }
}

// CUSTOM PAINTER FOR HORIZONTAL BAR
class _KasieBarPainter extends CustomPainter {
  final List<double> tickX;
  final double barWidth;
  final double barH;
  final double barVPad;
  final bool isZero;

  const _KasieBarPainter({
    required this.tickX,
    required this.barWidth,
    required this.barH,
    required this.barVPad,
    required this.isZero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    for (int i = 1; i < tickX.length; i++) {
      canvas.drawLine(
        Offset(tickX[i], 0),
        Offset(tickX[i], size.height),
        gridPaint,
      );
    }

    if (!isZero && barWidth > 0) {
      final barPaint = Paint()..color = const Color(0xFFAB47BC);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, barVPad, barWidth, size.height - barVPad * 2),
          const Radius.circular(4),
        ),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_KasieBarPainter old) =>
      old.barWidth != barWidth || old.isZero != isZero;
}