import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/services/gemini_recurring_service.dart';
import '../../../../core/utils/jabatan_helper.dart';

class _C {
  static const primary       = Color(0xFF0EA5E9);
  static const textPrimary   = Color(0xFF0C4A6E);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted     = Color(0xFFBDBDBD);
  static const divider       = Color(0xFFE0F2FE);
  static const red           = Color(0xFFEF4444);
  static const amber         = Color(0xFFF59E0B);
  static const green         = Color(0xFF10B981);
  static const surface       = Color(0xFFFEF2F2);
  static const primaryLight  = Color(0xFFFEE2E2);
}

class AccidentRecurringTab extends StatefulWidget {
  final String lang;
  final Widget Function({
    required String    label,
    required VoidCallback onTap,
    IconData           icon,
    bool               isActive,
  }) buildFilterBtn;

  const AccidentRecurringTab({
    super.key,
    required this.lang,
    required this.buildFilterBtn,
  });

  @override
  State<AccidentRecurringTab> createState() => AccidentRecurringTabState();
}

class AccidentRecurringTabState extends State<AccidentRecurringTab> {
  final _supabase = Supabase.instance.client;

  // FILTER STATE
  DateTime _recurringFrom   = DateTime(DateTime.now().year - 1, DateTime.now().month);
  DateTime _recurringTo     = DateTime.now();
  String?  _recurringUserId;
  String   _recurringUserName = '';

  Future<List<Map<String, dynamic>>>? _recurringFuture;

  String _t(String id, String en, String zh) {
    if (widget.lang == 'ID') return id;
    if (widget.lang == 'ZH') return zh;
    return en;
  }

  String _levelLabel(String backendLevel) {
    switch (backendLevel) {
      case 'Unit':
        return _t('Unit', 'Unit', '单元');
      case 'Subunit':
        return _t('Subunit', 'Sub-unit', '子单元');
      case 'Area':
        return _t('Area', 'Area', '区域');
      default:
        return _t('Lokasi', 'Location', '位置');
    }
  }

  @override
  void initState() {
    super.initState();
    _recurringFuture = _fetchRecurring();
  }

  Future<List<Map<String, dynamic>>> _fetchRecurring() async {
    try {
      var q = _supabase.from('accident_report').select('''
        id_laporan, judul, deskripsi, foto_bukti, created_at, status,
        tanggal_kejadian, tingkat_keparahan, penyebab, tindakan_diambil,
        id_lokasi, id_unit, id_subunit, id_area, id_pelapor,
        lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area),
        User_Pelapor:User!accident_report_id_pelapor_fkey(nama, gambar_user)
      ''')
          .gte('created_at', _recurringFrom.toIso8601String())
          .lte('created_at', DateTime(
              _recurringTo.year, _recurringTo.month + 1, 0, 23, 59, 59)
              .toIso8601String());
      if (_recurringUserId != null) q = q.eq('id_pelapor', _recurringUserId!);
      final List<dynamic> res = await q.order('created_at', ascending: false);
      final reports = List<Map<String, dynamic>>.from(res);
      if (reports.isEmpty) return [];

      final groups = await GeminiRecurringService.instance.analyzeAccidents(
        reports,
        fromDate:     _recurringFrom,
        toDate:       _recurringTo,
        filterUserId: _recurringUserId,
      );
      return groups.map((g) => {
        'topic':           g.topic,
        'locationArea':    g.locationArea,
        'total':           g.total,
        'imageUrl':        g.imageUrl,
        'reports':         g.reports,
        'severityPattern': g.severityPattern,
        'similarityScore': g.similarityScore,
        'aiReason':        g.reason,
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    final locale    = widget.lang == 'ID' ? 'id_ID'
        : widget.lang == 'ZH' ? 'zh_CN' : 'en_US';
    final fromLabel = DateFormat('MMM yyyy', locale).format(_recurringFrom);
    final toLabel   = DateFormat('MMM yyyy', locale).format(_recurringTo);

    return Column(children: [
      // FILTER ROW (TETAP - style putih/merah sudah benar dari parent)
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          Expanded(child: widget.buildFilterBtn(
            label: '$fromLabel - $toLabel',
            icon: Icons.calendar_month_rounded,
            onTap: _showPeriodPicker,
          )),
          const SizedBox(width: 10),
          Expanded(child: widget.buildFilterBtn(
            label: _recurringUserName.isEmpty
                ? _t('Semua Penemu', 'All Finders', '所有发现者')
                : _recurringUserName,
            onTap: _showUserPicker,
          )),
        ]),
      ),
      // SECTION LABEL (gaya sama seperti 5R)
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.primaryLight),
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                  color: _C.red, shape: BoxShape.circle),
              child: const Icon(Icons.autorenew_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('Kecelakaan Berulang', 'Recurring Accidents', '重复事故'),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _C.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _t(
                      'Laporan kecelakaan dengan pola atau lokasi serupa dikelompokkan otomatis',
                      'Accident reports with similar patterns or locations are grouped automatically',
                      '相似模式或位置的事故报告会自动分组',
                    ),
                    style: const TextStyle(
                        fontSize: 11,
                        color: _C.textSecondary,
                        height: 1.3),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
      // LIST
      Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _recurringFuture,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _buildShimmer();
          }
          final groups = snap.data ?? [];
          if (groups.isEmpty) return _buildEmptyState();
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _AccidentRecurringCard(
              group:  groups[i],
              lang:   widget.lang,
              onTap:  () => _showRecurringDetail(context, groups[i]),
            ),
          );
        },
      )),
    ]);
  }

  // ─── EMPTY STATE (ilustrasi + teks sesuai bahasa) ─────────────────────────
  Widget _buildEmptyState() {
    final name = _recurringUserName.isEmpty ? '' : _recurringUserName;
    final message = name.isEmpty
        ? _t('Belum ada laporan kecelakaan yang berulang.',
            'No recurring accident reports yet.', '暂无重复的事故报告。')
        : '$name ${_t('belum memiliki laporan kecelakaan berulang', 'does not have recurring accident reports yet', '还没有重复的事故报告')}';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              width: 170,
              height: 170,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                    color: _C.surface, shape: BoxShape.circle),
                child: Icon(Icons.warning_amber_rounded,
                    size: 44, color: _C.red.withValues(alpha: 0.5)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: _C.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => Container(
          height: 90,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  // RECURRING DETAIL BOTTOM SHEET
  void _showRecurringDetail(BuildContext context, Map<String, dynamic> group) {
    final topic      = group['topic'] as String;
    final reports    = group['reports'] as List<Map<String, dynamic>>;
    final locale     = widget.lang == 'ID' ? 'id_ID'
        : widget.lang == 'ZH' ? 'zh_CN' : 'en_US';
    final listLabel  = _t('Daftar Laporan', 'Report List', '报告列表');
    final totalLabel = _t('Total', 'Total', '总计');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                Expanded(child: Text(topic,
                    style: const TextStyle(fontSize: 16,
                        fontWeight: FontWeight.bold, color: _C.textPrimary))),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('$totalLabel: ${reports.length}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: _C.red)),
                ),
              ]),
            ),
            const Divider(height: 1, color: _C.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('$listLabel (${reports.length})',
                    style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w700, color: _C.textPrimary)),
              ),
            ),
            Expanded(child: ListView.separated(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: reports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _AccidentReportCard(
                  data: reports[i], lang: widget.lang, locale: locale),
            )),
          ]),
        ),
      ),
    );
  }

  // PERIOD PICKER (TIDAK BERUBAH)
  void _showPeriodPicker() async {
    DateTime tempFrom = _recurringFrom;
    DateTime tempTo   = _recurringTo;
    final locale = widget.lang == 'ID' ? 'id_ID'
        : widget.lang == 'EN' ? 'en_US' : 'zh_CN';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFFE0F2FE), width: 1.5)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.date_range_rounded,
                      color: _C.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    _t('Pilih Periode', 'Select Period', '选择期间'),
                    style: const TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 15, color: _C.textPrimary))),
                  IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero),
                ]),
                const SizedBox(height: 16),
                Text(_t('Dari', 'From', '从'),
                    style: const TextStyle(fontSize: 12,
                        color: _C.textSecondary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                _buildYearMonthPicker(
                    tempFrom, locale, (d) => setSt(() => tempFrom = d)),
                const SizedBox(height: 14),
                Text(_t('Sampai', 'To', '到'),
                    style: const TextStyle(fontSize: 12,
                        color: _C.textSecondary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                _buildYearMonthPicker(
                    tempTo, locale, (d) => setSt(() => tempTo = d)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _recurringFrom   = tempFrom;
                        _recurringTo     = tempTo;
                        _recurringFuture = _fetchRecurring();
                      });
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                    child: Text(_t('Terapkan', 'Apply', '应用')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYearMonthPicker(
      DateTime current, String locale, ValueChanged<DateTime> onChange) {
    final months = List.generate(
        12, (i) => DateFormat.MMM(locale).format(DateTime(2000, i + 1)));
    final years = List.generate(5, (i) => DateTime.now().year - 2 + i);

    Widget dropdown<T>({
      required T value,
      required List<T> items,
      required String Function(T) label,
      required ValueChanged<T?> onChanged,
    }) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0F2FE)),
        ),
        child: DropdownButtonHideUnderline(child: DropdownButton<T>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 18, color: _C.primary),
          style: const TextStyle(fontSize: 13,
              color: _C.textPrimary, fontWeight: FontWeight.w600),
          dropdownColor: Colors.white,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(label(e))))
              .toList(),
          onChanged: onChanged,
        )),
      );
    }

    return Row(children: [
      Expanded(flex: 3, child: dropdown<int>(
        value: current.month - 1,
        items: List.generate(12, (i) => i),
        label: (i) => months[i],
        onChanged: (v) {
          if (v != null) onChange(DateTime(current.year, v + 1));
        },
      )),
      const SizedBox(width: 8),
      Expanded(flex: 2, child: dropdown<int>(
        value: current.year,
        items: years,
        label: (y) => '$y',
        onChanged: (v) {
          if (v != null) onChange(DateTime(v, current.month));
        },
      )),
    ]);
  }

  // ─── Badge jabatan (sama seperti 5R/KTS) ──────────────────────────────────
  Widget _buildJabatanBadge({
    required int? idJabatan,
    required String? jabatanNama,
    required bool? isVerificator,
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  // ─── Popup pemilih lokasi (Lokasi/Unit/Subunit/Area) untuk filter finder ──
  Future<Map<String, String?>?> _pickLocationFilter(
      BuildContext parentContext, String initialLevel, String? initialId) async {
    String tempLevel = initialLevel;
    String? tempId = initialId;
    List<Map<String, String>> locItems = [];
    bool loading = true;
    bool initialized = false;
    final searchCtrl = TextEditingController();

    Future<void> fetchItems(void Function(void Function()) setSt) async {
      loading = true;
      setSt(() {});
      final levelLower = tempLevel.toLowerCase();
      final idMap = {'lokasi': 'id_lokasi', 'unit': 'id_unit', 'subunit': 'id_subunit', 'area': 'id_area'};
      final nameMap = {'lokasi': 'nama_lokasi', 'unit': 'nama_unit', 'subunit': 'nama_subunit', 'area': 'nama_area'};
      final idCol = idMap[levelLower] ?? 'id_lokasi';
      final nameCol = nameMap[levelLower] ?? 'nama_lokasi';
      try {
        final res = await _supabase.from(levelLower).select('$idCol, $nameCol').order(nameCol);
        locItems = List<Map<String, dynamic>>.from(res)
            .map((e) => {'id': e[idCol]?.toString() ?? '', 'name': e[nameCol]?.toString() ?? '-'})
            .toList();
      } catch (e) {
        locItems = [];
      }
      loading = false;
      setSt(() {});
    }

    IconData levelIcon(String label) {
      switch (label) {
        case 'Unit': return Icons.business_rounded;
        case 'Subunit': return Icons.layers_rounded;
        case 'Area': return Icons.place_rounded;
        default: return Icons.location_city_rounded;
      }
    }

    return showDialog<Map<String, String?>>(
      context: parentContext,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          if (!initialized) {
            initialized = true;
            fetchItems(setSt);
          }
          final q = searchCtrl.text.trim().toLowerCase();
          final filteredLoc = q.isEmpty
              ? locItems
              : locItems.where((e) => e['name']!.toLowerCase().contains(q)).toList();

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 320,
              height: MediaQuery.of(parentContext).size.height * 0.7,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.divider, width: 1.5),
              ),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.tune_rounded, color: _C.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_t('Pilih Lokasi', 'Select Location', '选择位置'),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15, color: _C.textPrimary))),
                    IconButton(
                        icon: const Icon(Icons.close, size: 18, color: _C.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.divider),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(children: ['Lokasi', 'Unit', 'Subunit', 'Area'].map((lvl) {
                      final isSel = lvl == tempLevel;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            tempLevel = lvl;
                            tempId = null;
                            searchCtrl.clear();
                            fetchItems(setSt);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 34,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: isSel ? _C.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Center(
                                child: Text(_levelLabel(lvl),
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: isSel ? Colors.white : _C.textSecondary))),
                          ),
                        ),
                      );
                    }).toList()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _C.primary.withValues(alpha: 0.35), width: 1.3),
                    ),
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: (_) => setSt(() {}),
                      style: const TextStyle(fontSize: 13, color: _C.textPrimary),
                      decoration: InputDecoration(
                        hintText: _t('Cari...', 'Search...', '搜索...'),
                        hintStyle: const TextStyle(fontSize: 12.5, color: _C.textMuted),
                        prefixIcon: const Icon(Icons.search_rounded, color: _C.primary, size: 18),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: _C.divider),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator(color: _C.primary, strokeWidth: 2))
                      : ListView(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          children: [
                            InkWell(
                              onTap: () => Navigator.pop(ctx, {'level': tempLevel, 'id': null, 'name': null}),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: tempId == null ? _C.primary.withValues(alpha: 0.10) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: tempId == null ? _C.primary : _C.divider,
                                      width: tempId == null ? 1.5 : 1),
                                ),
                                child: Row(children: [
                                  Icon(Icons.apps_rounded,
                                      size: 18, color: tempId == null ? _C.primary : _C.textSecondary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: Text('${_t('Semua', 'All', '全部')} (${_levelLabel(tempLevel)})',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: tempId == null ? FontWeight.bold : FontWeight.w500,
                                              color: tempId == null ? _C.primary : _C.textPrimary))),
                                  if (tempId == null)
                                    const Icon(Icons.check_circle_rounded, color: _C.primary, size: 18),
                                ]),
                              ),
                            ),
                            if (filteredLoc.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                    child: Text(_t('Tidak ada data untuk level ini.',
                                        'No data for this level.', '此级别没有数据。'),
                                        style: const TextStyle(fontSize: 12.5, color: _C.textSecondary))),
                              )
                            else
                              ...filteredLoc.map((item) {
                                final isSel = item['id'] == tempId;
                                return InkWell(
                                  onTap: () =>
                                      Navigator.pop(ctx, {'level': tempLevel, 'id': item['id'], 'name': item['name']}),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSel ? _C.primary.withValues(alpha: 0.10) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: isSel ? _C.primary : _C.divider,
                                          width: isSel ? 1.5 : 1),
                                    ),
                                    child: Row(children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isSel ? _C.primary : const Color(0xFFF0F9FF),
                                          borderRadius: BorderRadius.circular(9),
                                        ),
                                        child: Icon(levelIcon(tempLevel),
                                            size: 16, color: isSel ? Colors.white : _C.primary),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Text(item['name']!,
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                                  color: isSel ? _C.primary : _C.textPrimary),
                                              overflow: TextOverflow.ellipsis)),
                                      if (isSel)
                                        const Icon(Icons.check_circle_rounded, color: _C.primary, size: 18),
                                    ]),
                                  ),
                                );
                              }),
                          ],
                        ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ─── Popup Select Finder (dengan filter lokasi + badge jabatan) ───────────
  void _showUserPicker() async {
    String currentLocLevel = 'Lokasi';
    String? currentLocId;
    String? currentLocName;
    List<Map<String, dynamic>> items = [];
    List<Map<String, dynamic>> filtered = [];
    bool loadingUsers = true;
    bool initialized = false;
    final ctrl = TextEditingController();

    Future<void> loadUsers(void Function(void Function()) setSt) async {
      loadingUsers = true;
      setSt(() {});
      try {
        var userQuery = _supabase.from('User').select(
            'id_user, nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)');
        if (currentLocId != null) {
          const idMap = {'Lokasi': 'id_lokasi', 'Unit': 'id_unit', 'Subunit': 'id_subunit', 'Area': 'id_area'};
          final idCol = idMap[currentLocLevel] ?? 'id_lokasi';
          userQuery = userQuery.eq(idCol, currentLocId!);
        }
        final res = await userQuery.order('nama');
        final users = List<Map<String, dynamic>>.from(res);
        final allItem = {
          'id_user': null, 'nama': _t('Semua Penemu', 'All Finders', '所有发现者'),
          'gambar_user': null, 'jabatan': null,
          'id_jabatan': null, 'is_verificator': null,
        };
        items = [allItem, ...users];
      } catch (e) {
        debugPrint('Error fetching users: $e');
        items = [];
      }
      final q = ctrl.text.trim().toLowerCase();
      filtered = q.isEmpty
          ? List.from(items)
          : items.where((e) => (e['nama'] as String).toLowerCase().contains(q)).toList();
      loadingUsers = false;
      setSt(() {});
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          if (!initialized) {
            initialized = true;
            loadUsers(setSt);
          }
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 340,
              height: MediaQuery.of(context).size.height * 0.72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.divider, width: 1.5),
              ),
              child: Column(children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.person_search_rounded, color: _C.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_t('Pilih Penemu', 'Select Finder', '选择发现者'),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15, color: _C.textPrimary))),
                    IconButton(
                        icon: const Icon(Icons.close, size: 18, color: _C.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero),
                  ]),
                ),
                // SEARCH + FILTER LOKASI (BERSEBELAHAN)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                  child: Row(children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _C.primary.withValues(alpha: 0.35), width: 1.3),
                          boxShadow: [
                            BoxShadow(
                                color: _C.primary.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: TextField(
                          controller: ctrl,
                          onChanged: (q) {
                            filtered = q.trim().isEmpty
                                ? List.from(items)
                                : items
                                    .where((e) => (e['nama'] as String).toLowerCase().contains(q.toLowerCase()))
                                    .toList();
                            setSt(() {});
                          },
                          style: const TextStyle(
                              fontSize: 13, color: _C.textPrimary, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: _t('Cari...', 'Search...', '搜索...'),
                            hintStyle: const TextStyle(fontSize: 12.5, color: _C.textMuted),
                            prefixIcon: const Icon(Icons.search_rounded, color: _C.primary, size: 19),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final result = await _pickLocationFilter(ctx, currentLocLevel, currentLocId);
                        if (result != null) {
                          currentLocLevel = result['level'] ?? currentLocLevel;
                          currentLocId = result['id'];
                          currentLocName = result['name'];
                          await loadUsers(setSt);
                        }
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: currentLocId != null ? _C.primary : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: currentLocId != null
                                  ? _C.primary
                                  : _C.primary.withValues(alpha: 0.35),
                              width: 1.3),
                          boxShadow: [
                            BoxShadow(
                                color: _C.primary.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Icon(Icons.place_rounded,
                            color: currentLocId != null ? Colors.white : _C.primary, size: 20),
                      ),
                    ),
                  ]),
                ),
                // INFO FILTER LOKASI AKTIF + COUNT
                Padding(
                  padding: const EdgeInsets.only(left: 14, right: 14, bottom: 4),
                  child: Row(children: [
                    Text('${filtered.length} ${widget.lang == 'ID' ? 'penemu' : widget.lang == 'ZH' ? '发现者' : 'finders'}',
                        style: const TextStyle(fontSize: 11, color: _C.textSecondary)),
                    if (currentLocName != null) ...[
                      const Spacer(),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(currentLocName!,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _C.primary),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  ]),
                ),
                const Divider(height: 1, color: _C.divider),
                // LIST
                Expanded(
                  child: loadingUsers
                      ? const Center(child: CircularProgressIndicator(color: _C.primary, strokeWidth: 2))
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 6, bottom: 12),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final item = filtered[i];
                            final name = item['nama'] as String;
                            final id = item['id_user']?.toString();
                            final avatarUrl = item['gambar_user'] as String?;
                            final idJabatan = item['id_jabatan'] as int?;
                            final isVerificator = item['is_verificator'] as bool?;
                            final jabatanNama =
                                (item['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'] as String?;
                            final isSelected =
                                id == _recurringUserId || (id == null && _recurringUserId == null);
                            final isAll = id == null;

                            return InkWell(
                              onTap: () {
                                Navigator.pop(ctx);
                                setState(() {
                                  _recurringUserId = id;
                                  _recurringUserName =
                                      isAll ? _t('Semua Penemu', 'All Finders', '所有发现者') : name;
                                  _recurringFuture = _fetchRecurring();
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFE0F2FE) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: isSelected ? _C.primary : _C.divider,
                                      width: isSelected ? 1.5 : 1),
                                ),
                                child: Row(children: [
                                  if (isAll)
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isSelected ? _C.primary : const Color(0xFFF0F9FF),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: _C.divider),
                                      ),
                                      child: Icon(Icons.group_rounded,
                                          color: isSelected ? Colors.white : _C.primary, size: 20),
                                    )
                                  else if (avatarUrl != null && avatarUrl.isNotEmpty)
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: NetworkImage(avatarUrl),
                                      onBackgroundImageError: (_, __) {},
                                      backgroundColor: const Color(0xFFE0F2FE),
                                    )
                                  else
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: isSelected ? _C.primary : const Color(0xFFE0F2FE),
                                      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: isSelected ? Colors.white : _C.primary)),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(isAll ? _t('Semua Penemu', 'All Finders', '所有发现者') : name,
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                color: isSelected ? _C.primary : _C.textPrimary)),
                                        if (!isAll) ...[
                                          const SizedBox(height: 4),
                                          _buildJabatanBadge(
                                              idJabatan: idJabatan,
                                              jabatanNama: jabatanNama,
                                              isVerificator: isVerificator),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle_rounded, color: _C.primary, size: 18),
                                ]),
                              ),
                            );
                          },
                        ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ─── CARD TOPIK (gaya sama seperti 5R: strip keseringan + total besar) ──────
class _AccidentRecurringCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final String               lang;
  final VoidCallback         onTap;
  const _AccidentRecurringCard(
      {required this.group, required this.lang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final topic        = group['topic'] as String? ?? '-';
    final locationArea = group['locationArea'] as String? ?? '';
    final total        = group['total'] as int? ?? 0;
    final imageUrl      = group['imageUrl'] as String?;
    final severity      = group['severityPattern'] as String? ?? topic;

    Color severityColor; IconData severityIcon;
    final s = severity.toLowerCase();
    if (s.contains('berat') || s.contains('heavy') || s.contains('重')) {
      severityColor = _C.red;   severityIcon = Icons.dangerous_rounded;
    } else if (s.contains('menengah') || s.contains('medium') || s.contains('中')) {
      severityColor = _C.amber; severityIcon = Icons.warning_amber_rounded;
    } else {
      severityColor = _C.green; severityIcon = Icons.info_outline_rounded;
    }

    final occurrenceLabel = lang == 'ID'
        ? '$total kejadian'
        : lang == 'ZH'
            ? '$total 次'
            : '$total occurrences';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: severityColor.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: severityColor.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // STRIP POLA KEPARAHAN
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.10),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14.5)),
            ),
            child: Row(children: [
              Icon(severityIcon, size: 13, color: severityColor),
              const SizedBox(width: 4),
              Text(severity,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: severityColor)),
              const Spacer(),
              Text(occurrenceLabel,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: severityColor)),
            ]),
          ),
          // KONTEN
          Row(children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(15)),
              child: Container(
                width: 78,
                height: 78,
                color: severityColor.withValues(alpha: 0.10),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(severityIcon, color: severityColor, size: 30))
                    : Icon(severityIcon, color: severityColor, size: 30),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(topic,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700, color: _C.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    if (locationArea.isNotEmpty)
                      Row(children: [
                        const Icon(Icons.location_on_rounded, size: 13, color: _C.textSecondary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(locationArea,
                              style: const TextStyle(fontSize: 12, color: _C.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('$total',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: severityColor)),
                Icon(Icons.chevron_right_rounded, color: _C.textMuted, size: 18),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _AccidentReportCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String               lang;
  final String               locale;
  const _AccidentReportCard(
      {required this.data, required this.lang, required this.locale});

  @override
  Widget build(BuildContext context) {
    final judul     = (data['judul']             ?? '-').toString();
    final status    = (data['status']            ?? '').toString();
    final tingkat   = (data['tingkat_keparahan'] ?? '').toString();
    final penyebab  = (data['penyebab']          ?? '').toString();
    final fotoUrl   = (data['foto_bukti']        ?? '').toString();
    final isSelesai = status == 'Selesai';

    final tanggal = () {
      final v = data['created_at'];
      if (v == null) return '-';
      final dt = v is DateTime ? v : DateTime.tryParse(v.toString());
      return dt != null
          ? DateFormat('dd/MM/yyyy', locale).format(dt) : '-';
    }();

    String location = '';
    if      (data['area']    != null)
      location = (data['area']    as Map)['nama_area']    ?? '';
    else if (data['subunit'] != null)
      location = (data['subunit'] as Map)['nama_subunit'] ?? '';
    else if (data['unit']    != null)
      location = (data['unit']    as Map)['nama_unit']    ?? '';
    else if (data['lokasi']  != null)
      location = (data['lokasi']  as Map)['nama_lokasi']  ?? '';

    final statusColor = isSelesai
        ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final statusBg    = isSelesai
        ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
    final statusText  = isSelesai
        ? (lang == 'ID' ? 'Selesai'
            : lang == 'ZH' ? '已完成' : 'Resolved')
        : status;

    Color sevColor;
    final tl = tingkat.toLowerCase();
    if      (tl.contains('berat')    || tl.contains('heavy'))
      sevColor = _C.red;
    else if (tl.contains('menengah') || tl.contains('medium'))
      sevColor = _C.amber;
    else
      sevColor = _C.green;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sevColor.withValues(alpha:0.3), width: 1.5),
        boxShadow: [BoxShadow(
            color: sevColor.withValues(alpha:0.1),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: sevColor.withValues(alpha:0.3), width: 1.5)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.5),
                child: fotoUrl.isNotEmpty
                    ? Image.network(fotoUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey))
                    : Container(
                        color: const Color(0xFFF8FAFC),
                        child: const Icon(Icons.warning_amber_rounded,
                            color: Colors.grey, size: 28)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Expanded(child: Text(judul,
                    style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _C.textPrimary),
                    maxLines: 2, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 6),
                if (tingkat.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: sevColor.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: sevColor, width: 1)),
                    child: Text(tingkat,
                        style: TextStyle(fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: sevColor)),
                  ),
              ]),
              const SizedBox(height: 4),
              if (location.isNotEmpty)
                Row(children: [
                  const Icon(Icons.place_rounded,
                      size: 11, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 3),
                  Expanded(child: Text(location,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF475569)),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 10, color: Color(0xFF94A3B8)),
                const SizedBox(width: 3),
                Text(tanggal,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF64748B))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(statusText,
                      style: TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor)),
                ),
              ]),
            ])),
          ]),
        ),
        if (penyebab.isNotEmpty && penyebab != '-')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: sevColor.withValues(alpha:0.06),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14))),
            child: Row(children: [
              Icon(Icons.info_outline_rounded,
                  size: 12, color: sevColor),
              const SizedBox(width: 5),
              Expanded(child: Text(penyebab,
                  style: TextStyle(fontSize: 11,
                      color: sevColor.withValues(alpha:0.9),
                      fontWeight: FontWeight.w500),
                  maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]),
          ),
      ]),
    );
  }
}