import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/services/gemini_recurring_service.dart';

class _C {
  static const primary       = Color(0xFF0EA5E9);
  static const textPrimary   = Color(0xFF0C4A6E);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted     = Color(0xFFBDBDBD);
  static const divider       = Color(0xFFE0F2FE);
  static const red           = Color(0xFFEF4444);
  static const amber         = Color(0xFFF59E0B);
  static const green         = Color(0xFF10B981);
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
      // FILTER ROW
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
      // TITLE
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _t('Laporan Kecelakaan Berulang',
               'Recurring Accident Reports', '重复事故报告'),
            style: const TextStyle(fontSize: 14,
                fontWeight: FontWeight.w700, color: _C.textPrimary),
          ),
        ),
      ),
      const Divider(height: 1, color: _C.divider),
      // LIST
      Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _recurringFuture,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _buildShimmer();
          }
          final groups = snap.data ?? [];
          if (groups.isEmpty) return _buildEmpty();
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

  Widget _buildEmpty() {
    return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 72, height: 72,
        decoration: const BoxDecoration(
            color: Color(0xFFFEF2F2), shape: BoxShape.circle),
        child: Icon(Icons.warning_amber_rounded,
            size: 36, color: _C.red.withOpacity(0.5)),
      ),
      const SizedBox(height: 16),
      Text(
        _t('Tidak ada laporan kecelakaan berulang.',
           'No recurring accident reports.', '没有重复的事故报告。'),
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontSize: 14, color: _C.textSecondary, height: 1.5),
      ),
    ]));
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => Container(
          height: 80,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14)),
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

  // PERIOD PICKER
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

  // USER PICKER
  void _showUserPicker() async {
    try {
      final res = await _supabase
          .from('User')
          .select(
              'id_user, nama, gambar_user, jabatan!User_id_jabatan_fkey(nama_jabatan)')
          .order('nama');
      final users   = List<Map<String, dynamic>>.from(res);
      final allItem = {
        'id_user': null,
        'nama': _t('Semua Penemu', 'All Finders', '所有发现者'),
        'gambar_user': null,
        'jabatan': null,
      };
      final items = [allItem, ...users];
      if (!mounted) return;

      final ctrl = TextEditingController();
      List<Map<String, dynamic>> filtered = List.from(items);

      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSt) => Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.of(context).size.height * 0.7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFFE0F2FE), width: 1.5)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20))),
                  child: Row(children: [
                    const Icon(Icons.person_search_rounded,
                        color: _C.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      _t('Pilih Penemu', 'Select Finder', '选择发现者'),
                      style: const TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 15, color: _C.textPrimary))),
                    IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: _C.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero),
                  ]),
                ),
                // SEARCH
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: TextField(
                    controller: ctrl,
                    onChanged: (q) => setSt(() {
                      filtered = items
                          .where((e) => (e['nama'] as String)
                              .toLowerCase()
                              .contains(q.toLowerCase()))
                          .toList();
                    }),
                    decoration: InputDecoration(
                      hintText: _t('Cari...', 'Search...', '搜索...'),
                      hintStyle: const TextStyle(
                          fontSize: 13, color: _C.textMuted),
                      prefixIcon: const Icon(Icons.search,
                          color: _C.primary, size: 18),
                      filled: true,
                      fillColor: const Color(0xFFF0F9FF),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                              color: Color(0xFFE0F2FE))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                              color: Color(0xFFE0F2FE))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                              color: _C.primary, width: 1.5)),
                    ),
                  ),
                ),
                // LIST
                Flexible(child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final item      = filtered[i];
                    final name      = item['nama'] as String;
                    final id        = item['id_user']?.toString();
                    final avatarUrl = item['gambar_user'] as String?;
                    final role      = (item['jabatan']
                            as Map<String, dynamic>?)?['nama_jabatan']
                        as String?;
                    final isSel = id == _recurringUserId ||
                        (id == null && _recurringUserId == null);
                    final isAll = id == null;

                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _recurringUserId = id;
                          _recurringUserName = isAll
                              ? _t('Semua Penemu', 'All Finders',
                                  '所有发现者')
                              : name;
                          _recurringFuture = _fetchRecurring();
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSel
                              ? const Color(0xFFE0F2FE)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isSel
                                  ? _C.primary
                                  : const Color(0xFFE0F2FE),
                              width: isSel ? 1.5 : 1)),
                        child: Row(children: [
                          if (isAll)
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: isSel
                                    ? _C.primary
                                    : const Color(0xFFF0F9FF),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFFE0F2FE))),
                              child: Icon(Icons.group_rounded,
                                  color: isSel
                                      ? Colors.white
                                      : _C.primary,
                                  size: 20))
                          else if (avatarUrl != null &&
                              avatarUrl.isNotEmpty)
                            CircleAvatar(
                                radius: 20,
                                backgroundImage:
                                    NetworkImage(avatarUrl),
                                backgroundColor:
                                    const Color(0xFFE0F2FE))
                          else
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: isSel
                                  ? _C.primary
                                  : const Color(0xFFE0F2FE),
                              child: Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isSel
                                        ? Colors.white
                                        : _C.primary),
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                            Text(
                              isAll
                                  ? _t('Semua Penemu',
                                      'All Finders', '所有发现者')
                                  : name,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSel
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSel
                                      ? _C.primary
                                      : _C.textPrimary),
                            ),
                            if (role != null && role.isNotEmpty)
                              Text(role,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: _C.textSecondary)),
                          ])),
                          if (isSel)
                            const Icon(Icons.check_circle_rounded,
                                color: _C.primary, size: 18),
                        ]),
                      ),
                    );
                  },
                )),
              ]),
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('showUserPicker: $e');
    }
  }
}

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
    final imageUrl     = group['imageUrl'] as String?;
    final severity     = group['severityPattern'] as String? ?? topic;

    Color color; IconData icon;
    final s = severity.toLowerCase();
    if (s.contains('berat') || s.contains('heavy') || s.contains('重')) {
      color = _C.red;   icon = Icons.dangerous_rounded;
    } else if (s.contains('menengah') || s.contains('medium') ||
        s.contains('中')) {
      color = _C.amber; icon = Icons.warning_amber_rounded;
    } else {
      color = _C.green; icon = Icons.info_outline_rounded;
    }

    final totalLabel = lang == 'ID' ? 'Total'
        : lang == 'ZH' ? '总计' : 'Total';
    final sevLabel   = lang == 'ID' ? 'Pola: $severity'
        : lang == 'ZH' ? '模式: $severity' : 'Pattern: $severity';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(14)),
            child: Container(
              width: 80, height: 80,
              color: color.withOpacity(0.1),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(icon, color: color, size: 32))
                  : Icon(icon, color: color, size: 32),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(topic,
                  style: TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w700, color: color),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.repeat_rounded,
                    size: 12, color: color.withOpacity(0.7)),
                const SizedBox(width: 3),
                Expanded(child: Text(sevLabel,
                    style: TextStyle(
                        fontSize: 11, color: color.withOpacity(0.8)),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              if (locationArea.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.location_on_rounded,
                      size: 12, color: _C.textSecondary),
                  const SizedBox(width: 3),
                  Expanded(child: Text(locationArea,
                      style: const TextStyle(
                          fontSize: 11, color: _C.textSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              ],
            ]),
          )),
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.3))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(totalLabel,
                  style: TextStyle(
                      fontSize: 9, color: color.withOpacity(0.7))),
              Text('$total',
                  style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w900, color: color)),
            ]),
          ),
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
        border: Border.all(color: sevColor.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(
            color: sevColor.withOpacity(0.1),
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
                    color: sevColor.withOpacity(0.3), width: 1.5)),
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
                      color: sevColor.withOpacity(0.1),
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
              color: sevColor.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14))),
            child: Row(children: [
              Icon(Icons.info_outline_rounded,
                  size: 12, color: sevColor),
              const SizedBox(width: 5),
              Expanded(child: Text(penyebab,
                  style: TextStyle(fontSize: 11,
                      color: sevColor.withOpacity(0.9),
                      fontWeight: FontWeight.w500),
                  maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]),
          ),
      ]),
    );
  }
}