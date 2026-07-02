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

enum _RangeFilter { thisMonth, threeMonths, sixMonths, oneYear, custom }

extension _RF on _RangeFilter {
  String label(String lang) {
    switch (this) {
      case _RangeFilter.thisMonth:
        return lang == 'EN' ? 'This Month' : lang == 'ZH' ? '本月' : 'Bulan Ini';
      case _RangeFilter.threeMonths:
        return lang == 'EN' ? '3 Months' : lang == 'ZH' ? '3个月' : '3 Bulan';
      case _RangeFilter.sixMonths:
        return lang == 'EN' ? '6 Months' : lang == 'ZH' ? '6个月' : '6 Bulan';
      case _RangeFilter.oneYear:
        return lang == 'EN' ? '1 Year' : lang == 'ZH' ? '1年' : '1 Tahun';
      case _RangeFilter.custom:
        return lang == 'EN' ? 'Custom' : lang == 'ZH' ? '自定义' : 'Kustom';
    }
  }

  int get monthCount {
    switch (this) {
      case _RangeFilter.thisMonth:   return 1;
      case _RangeFilter.threeMonths: return 3;
      case _RangeFilter.sixMonths:   return 6;
      case _RangeFilter.oneYear:     return 12;
      case _RangeFilter.custom:      return 12; 
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
  DateTime? _customStart;
  DateTime? _customEnd;

  List<_KasieRow> _rows = [];
  List<String> _bulanLabels = [];
  Map<String, String> _sectionNameMap = {};
  Map<String, String> _sectionDisplayMap = {};

  @override
  void initState() {
    super.initState();
    _loadSectionNameMap().then((_) => _loadData());
  }

  // MONTH RANGE
  List<DateTime> _getMonths() {
    if (_range == _RangeFilter.custom && _customStart != null && _customEnd != null) {
      final List<DateTime> months = [];
      DateTime cursor = DateTime(_customStart!.year, _customStart!.month, 1);
      final last = DateTime(_customEnd!.year, _customEnd!.month, 1);
      while (!cursor.isAfter(last) && months.length < 12) {
        months.add(cursor);
        cursor = DateTime(cursor.year, cursor.month + 1, 1);
      }
      return months;
    }
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
      final displayMap = <String, String>{};
      for (final r in rows) {
        final idName = (r['nama_section_id'] as String?)?.trim();
        if (idName == null || idName.isEmpty) continue;
        map[idName.toLowerCase()] = idName;
        final enName = (r['nama_section_en'] as String?)?.trim();
        if (enName != null && enName.isNotEmpty) map[enName.toLowerCase()] = idName;
        final zhName = (r['nama_section_zh'] as String?)?.trim();
        if (zhName != null && zhName.isNotEmpty) map[zhName.toLowerCase()] = idName;

        String display = idName;
        if (widget.lang == 'EN') {
          if (enName != null && enName.isNotEmpty) display = enName;
        } else if (widget.lang == 'ZH') {
          if (zhName != null && zhName.isNotEmpty) display = zhName;
        }
        displayMap[idName.toLowerCase()] = display;
      }
      if (mounted) setState(() { _sectionNameMap = map; _sectionDisplayMap = displayMap; });
    } catch (e) {
      debugPrint('loadSectionNameMap error: $e');
    }
  }

  String _resolveSectionName(String raw) {
    final key = raw.trim().toLowerCase();
    return _sectionNameMap[key] ?? raw.trim();
  }

  String _displaySectionName(String raw) {
    if (raw.isEmpty) return raw;
    return _sectionDisplayMap[raw.trim().toLowerCase()] ?? raw;
  }

  String _normKey(String raw) => raw.trim().toLowerCase();

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final months = _getMonths();
      final locale = widget.lang == 'ID' ? 'id_ID'
          : widget.lang == 'EN' ? 'en_US' : 'zh_CN';

      _bulanLabels = months.map((m) => DateFormat('MMM yy', locale).format(m)).toList();

      final kasieRes = await _db
          .from('User')
          .select('''
            id_user, nama, bagian_kasie, id_section,
            section:id_section(nama_section_id, nama_section_en, nama_section_zh)
          ''')
          .eq('id_jabatan', 3);

      var kasieList = List<Map<String, dynamic>>.from(kasieRes);
      String kasieMatchKey(Map<String, dynamic> k) {
        final id = k['id_section']?.toString();
        if (id != null && id.isNotEmpty) return 'id:$id';
        final raw = (k['bagian_kasie'] as String?)?.trim() ?? '';
        if (raw.isEmpty) return '';
        return 'name:${_normKey(_resolveSectionName(raw))}';
      }

      String kasieBagianLabel(Map<String, dynamic> k) {
        final sectionJoin = k['section'] as Map<String, dynamic>?;
        final joinedName = (sectionJoin?['nama_section_id'] as String?)?.trim();
        if (joinedName != null && joinedName.isNotEmpty) return joinedName;
        final raw = (k['bagian_kasie'] as String?)?.trim() ?? '';
        return raw.isEmpty ? '' : _resolveSectionName(raw);
      }

      if (_filterBagian != null) {
        kasieList = kasieList.where((k) {
          final label = kasieBagianLabel(k);
          return label.isNotEmpty && _normKey(label) == _normKey(_filterBagian!);
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
              bagian,
              id_section
            )
          ''')
          .eq('jenis_temuan', 'KTS Production')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .not('id_penyelesaian', 'is', null);

      final penyelesaianList = List<Map<String, dynamic>>.from(penyelesaianRes);
      final Map<String, Map<int, int>> bagianMonthCounts = {};
      for (final row in penyelesaianList) {
        final p = row['penyelesaian'] as Map<String, dynamic>?;
        if (p == null) continue;

        final idSection = p['id_section']?.toString();
        String key;
        if (idSection != null && idSection.isNotEmpty) {
          key = 'id:$idSection';
        } else {
          final rawBagian = (p['bagian'] as String?)?.trim() ?? '';
          if (rawBagian.isEmpty) continue;
          key = 'name:${_normKey(_resolveSectionName(rawBagian))}';
        }

        final createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '');
        if (createdAt == null) continue;

        for (int i = 0; i < months.length; i++) {
          final m = months[i];
          if (createdAt.year == m.year && createdAt.month == m.month) {
            final monthMap = bagianMonthCounts.putIfAbsent(key, () => {});
            monthMap[i] = (monthMap[i] ?? 0) + 1;
            break;
          }
        }
      }

      final rows = kasieList.map((k) {
        final kasieId   = k['id_user']?.toString() ?? '';
        final kasieNama = k['nama']?.toString() ?? '-';
        final bagian = kasieBagianLabel(k);
        final key = kasieMatchKey(k);

        final monthCounts = key.isEmpty ? <int, int>{} : (bagianMonthCounts[key] ?? {});
        final bulanan = <int, int>{};
        int total = 0;
        for (int i = 0; i < months.length; i++) {
          final v = monthCounts[i] ?? 0;
          bulanan[i] = v;
          total += v;
        }

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
            ..._RangeFilter.values.where((r) => r != _RangeFilter.custom).map((r) {
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
            GestureDetector(
              onTap: () { Navigator.pop(ctx); _showCustomRangePicker(); },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: _range == _RangeFilter.custom ? _C.primaryLight : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _range == _RangeFilter.custom ? _C.primary : const Color(0xFFE2E8F0),
                    width: _range == _RangeFilter.custom ? 1.8 : 1,
                  ),
                ),
                child: Row(children: [
                  const Icon(Icons.edit_calendar_rounded, size: 16, color: _C.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    _range == _RangeFilter.custom && _customStart != null && _customEnd != null
                        ? '${DateFormat('MMM yyyy').format(_customStart!)} – ${DateFormat('MMM yyyy').format(_customEnd!)}'
                        : (widget.lang == 'EN' ? 'Custom (Start – End)' : widget.lang == 'ZH' ? '自定义（开始-结束）' : 'Kustom (Mulai – Selesai)'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _range == _RangeFilter.custom ? _C.primaryDark : const Color(0xFF1E293B),
                    ),
                  )),
                  if (_range == _RangeFilter.custom) const Icon(Icons.check_circle_rounded, color: _C.primary, size: 20),
                ]),
              ),
            ),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }

  void _showCustomRangePicker() async {
    final now = DateTime.now();
    DateTime tempStart = _customStart ?? DateTime(now.year, now.month, 1);
    DateTime tempEnd   = _customEnd   ?? DateTime(now.year, now.month, 1);

    await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) {
      Widget monthYearPicker(String title, DateTime value, ValueChanged<DateTime> onChanged) {
        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.divider)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _C.textSec)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: DropdownButton<int>(
                isExpanded: true, value: value.month, underline: const SizedBox.shrink(),
                items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m,
                  child: Text(DateFormat('MMMM').format(DateTime(2024, m, 1)), style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (m) { if (m != null) onChanged(DateTime(value.year, m, 1)); },
              )),
              const SizedBox(width: 8),
              Expanded(child: DropdownButton<int>(
                isExpanded: true, value: value.year, underline: const SizedBox.shrink(),
                items: List.generate(6, (i) => now.year - 4 + i).map((y) => DropdownMenuItem(value: y,
                  child: Text('$y', style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (y) { if (y != null) onChanged(DateTime(y, value.month, 1)); },
              )),
            ]),
          ]),
        );
      }

      final monthsDiff = (tempEnd.year - tempStart.year) * 12 + (tempEnd.month - tempStart.month);
      final isValid = monthsDiff >= 0 && monthsDiff < 12;

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
              decoration: const BoxDecoration(color: _C.primaryLight, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              child: Row(children: [
                const Icon(Icons.edit_calendar_rounded, color: _C.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.lang == 'EN' ? 'Custom Period' : widget.lang == 'ZH' ? '自定义期间' : 'Periode Kustom',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _C.textPrimary))),
                IconButton(icon: const Icon(Icons.close, size: 18, color: _C.textSec), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
              ]),
            ),
            const SizedBox(height: 8),
            monthYearPicker(widget.lang == 'EN' ? 'Start' : widget.lang == 'ZH' ? '开始' : 'Mulai', tempStart, (d) => setLocal(() => tempStart = d)),
            monthYearPicker(widget.lang == 'EN' ? 'End' : widget.lang == 'ZH' ? '结束' : 'Selesai', tempEnd, (d) => setLocal(() => tempEnd = d)),
            if (!isValid)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.lang == 'EN' ? 'Range must be between 0–12 months' : widget.lang == 'ZH' ? '范围必须在0-12个月之间' : 'Rentang maksimal 12 bulan',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
              ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: isValid ? () {
                  Navigator.pop(ctx);
                  setState(() { _range = _RangeFilter.custom; _customStart = tempStart; _customEnd = tempEnd; });
                  _loadData();
                } : null,
                style: ElevatedButton.styleFrom(backgroundColor: _C.primary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(widget.lang == 'EN' ? 'Apply' : widget.lang == 'ZH' ? '应用' : 'Terapkan'),
              )),
            ),
          ]),
        ),
      );
    }));
  }

  void _showBagianPicker() async {
    final result = await showKtsSectionLocationPicker(context, lang: widget.lang, accentColor: _C.primary);
    if (result == null) return;
    setState(() => _filterBagian = result.isAllSections ? null : result.sectionName);
    _loadData();
  }

  // FILTER BAR
  Widget _buildFilterBar() {
    String rangeLabel = _range.label(widget.lang);
    if (_range == _RangeFilter.custom && _customStart != null && _customEnd != null) {
      rangeLabel = '${DateFormat('MMM yy').format(_customStart!)}–${DateFormat('MMM yy').format(_customEnd!)}';
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(children: [
        // RANGE MONTH BUTTON
        Expanded(child: _filterBtn(
          label: rangeLabel,
          color: _C.primary,
          active: true,
          icon: Icons.date_range_rounded,
          onTap: _showRangePicker,
        )),
        const SizedBox(width: 8),
        // SECTION BUTTON
        Expanded(child: _filterBtn(
          label: _filterBagian != null ? _displaySectionName(_filterBagian!) : _t('semua_bagian'),
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
          boxShadow: [BoxShadow(color: color.withValues(alpha:0.12), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Icon(icon, size: 14, color: active ? Colors.white : color),
          const SizedBox(width: 6),
          Expanded(child: Text(label,
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
          border: Border.all(color: _C.primary.withValues(alpha:0.45), width: 1.2),
          boxShadow: [BoxShadow(
              color: _C.primary.withValues(alpha:0.07), blurRadius: 6, offset: const Offset(0, 2))],
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
    final int xMax = _getMonths().length;
    final int tickStep = xMax <= 6 ? 1 : (xMax / 6).ceil();
    final List<int> xTicks = [];
    for (int v = 0; v <= xMax; v += tickStep) {
      xTicks.add(v);
    }
    if (xTicks.last != xMax) xTicks.add(xMax);

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
            color: _C.primary.withValues(alpha:0.07), blurRadius: 10, offset: const Offset(0, 3))],
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
    final months = _getMonths();
    if (months.length > 6) {
      return _buildWideTable(months);
    }

    final locale = widget.lang == 'ID' ? 'id_ID'
        : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
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
            row.bagian.isEmpty ? '-' : _displaySectionName(row.bagian),
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
                    ? _C.barColor.withValues(alpha:0.15)
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
            color: _C.primary.withValues(alpha:0.06), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        buildHeaderRow(),
        ..._rows.asMap().entries.map((e) => buildDataRow(e.key, e.value)),
        buildFooterRow(),
      ]),
    );
  }

  Widget _buildWideTable(List<DateTime> months) {
    final locale = widget.lang == 'ID' ? 'id_ID'
        : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    final bulanLabels3 = months.map((m) => DateFormat('MMM', locale).format(m)).toList();
    final int grandTotal = _rows.fold(0, (s, r) => s + r.total);

    const double leftW  = 150.0;
    const double monthW = 46.0;
    const double totalW = 56.0;
    const double rowH   = 40.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.primaryLight, width: 1.5),
        boxShadow: [BoxShadow(color: _C.primary.withValues(alpha:0.06), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // KOLOM KIRI TETAP (Bagian + Kasie)
          SizedBox(width: leftW, child: Column(children: [
            Container(
              height: rowH, color: _C.primaryLight,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(children: [
                Expanded(flex: 5, child: Align(alignment: Alignment.centerLeft,
                  child: Text(_t('bagian'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _C.textSec)))),
                Expanded(flex: 6, child: Align(alignment: Alignment.centerLeft,
                  child: Text(_t('kasie'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _C.textSec)))),
              ]),
            ),
            ..._rows.asMap().entries.map((e) {
              final idx = e.key; final row = e.value;
              return Container(
                height: rowH,
                decoration: BoxDecoration(border: idx > 0 ? const Border(top: BorderSide(color: _C.divider)) : null),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(children: [
                  Expanded(flex: 5, child: Text(
                    row.bagian.isEmpty ? '-' : _displaySectionName(row.bagian),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: row.total > 0 ? _C.textPrimary : const Color(0xFFCBD5E1)),
                    overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 6, child: Text(
                    row.kasieNama,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: row.total > 0 ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    overflow: TextOverflow.ellipsis)),
                ]),
              );
            }),
            Container(
              height: rowH,
              decoration: const BoxDecoration(color: Color(0xFFFFF7ED), border: Border(top: BorderSide(color: _C.divider, width: 1.5))),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(alignment: Alignment.centerLeft, child: Text(
                widget.lang == 'EN' ? 'Total' : widget.lang == 'ZH' ? '合计' : 'Total',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _C.textPrimary))),
            ),
          ])),
          Container(width: 1, color: _C.divider),
          // KOLOM KANAN SCROLLABLE (Bulan + Total)
          Expanded(child: LayoutBuilder(builder: (_, rightConstraints) {
            final availW = rightConstraints.maxWidth;
            final neededW = monthW * months.length + totalW;
            final effMonthW = neededW < availW && months.isNotEmpty
                ? (availW - totalW) / months.length
                : monthW;
            final totalContentW = neededW < availW ? availW : neededW;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: neededW < availW ? const NeverScrollableScrollPhysics() : const ClampingScrollPhysics(),
              child: SizedBox(width: totalContentW, child: Column(children: [
                Container(
                  height: rowH, color: _C.primaryLight,
                  child: Row(children: [
                    ...bulanLabels3.map((lbl) => SizedBox(width: effMonthW, child: Center(
                      child: Text(lbl, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _C.textSec))))),
                    SizedBox(width: totalW, child: Center(
                      child: Text(_t('total'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _C.primaryDark)))),
                  ]),
                ),
                ..._rows.asMap().entries.map((e) {
                  final idx = e.key; final row = e.value;
                  return Container(
                    height: rowH,
                    decoration: BoxDecoration(border: idx > 0 ? const Border(top: BorderSide(color: _C.divider)) : null),
                    child: Row(children: [
                      ...List.generate(months.length, (mi) {
                        final val = row.bulanan[mi] ?? 0;
                        return SizedBox(width: effMonthW, child: Center(child: Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            color: val > 0 ? _C.barColor.withValues(alpha:0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(child: Text('$val',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: val > 0 ? _C.barColor : const Color(0xFFCBD5E1)))),
                        )));
                      }),
                      SizedBox(width: totalW, child: Center(child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(color: row.total > 0 ? _C.primary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                        child: Text('${row.total}', textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: row.total > 0 ? Colors.white : const Color(0xFFCBD5E1)))))),
                    ]),
                  );
                }),
                Container(
                  height: rowH,
                  decoration: const BoxDecoration(color: Color(0xFFFFF7ED), border: Border(top: BorderSide(color: _C.divider, width: 1.5))),
                  child: Row(children: [
                    ...List.generate(months.length, (mi) {
                      final colTotal = _rows.fold(0, (s, r) => s + (r.bulanan[mi] ?? 0));
                      return SizedBox(width: effMonthW, child: Center(child: Text('$colTotal',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _C.primaryDark))));
                    }),
                    SizedBox(width: totalW, child: Center(child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(color: _C.primary, borderRadius: BorderRadius.circular(8)),
                      child: Text('$grandTotal', textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white))))),
                  ]),
                ),
              ])),
            );
          })),
        ]),
      ),
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
                      color: _C.barColor.withValues(alpha:0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_outline_rounded,
                        size: 14, color: _C.barColor),
                  ),
                  const SizedBox(width: 8),
                  Text('${_t('laporan_kts')} ${_t('kasie')}',
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