import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class _C {
  static const textPrimary   = Color(0xFF0C4A6E);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted     = Color(0xFFBDBDBD);
  static const divider       = Color(0xFFE0F2FE);
  static const red           = Color(0xFFEF4444);
}

class LocationData {
  final String  name;
  final String  pic;
  final String? value;
  const LocationData({required this.name, required this.pic, this.value});
}

class AccidentLocationTab extends StatefulWidget {
  final String lang;

  // FILTER STATE
  final String    filterMode;
  final int       selectedMonthIndex;
  final DateTime? selectedDate;
  final String    selectedLocationLevel;
  final List<String> translatedLocationLevels;
  final List<String> levelBackends;

  final Widget Function({
    required String    label,
    required VoidCallback onTap,
    IconData           icon,
    bool               isActive,
  }) buildFilterBtn;

  final void Function(VoidCallback onChanged) showMonthPicker;
  final VoidCallback showLevelPicker;
  final String lastUpdatedText;

  const AccidentLocationTab({
    super.key,
    required this.lang,
    required this.filterMode,
    required this.selectedMonthIndex,
    this.selectedDate,
    required this.selectedLocationLevel,
    required this.translatedLocationLevels,
    required this.levelBackends,
    required this.buildFilterBtn,
    required this.showMonthPicker,
    required this.showLevelPicker,
    required this.lastUpdatedText,
  });

  @override
  State<AccidentLocationTab> createState() => AccidentLocationTabState();
}

class AccidentLocationTabState extends State<AccidentLocationTab> {
  final _supabase = Supabase.instance.client;

  Future<List<LocationData>>? locationFuture;
  
  void fetchData({
    String?   filterMode,
    int?      selectedMonthIndex,
    DateTime? selectedDate,
    String?   levelBackend,
  }) {
    final mode     = filterMode         ?? widget.filterMode;
    final monthIdx = selectedMonthIndex ?? widget.selectedMonthIndex;
    final date     = selectedDate       ?? widget.selectedDate;
    final backend  = levelBackend       ?? _levelBackend;

    final month = monthIdx + 1;
    final year  = DateTime.now().year;

    setState(() {
      if (mode == 'daily' && date != null) {
        locationFuture = _fetchLocationDaily(date, backend);
      } else {
        locationFuture = _fetchLocation(month, year, backend);
      }
    });
  }

  Future<List<LocationData>>? get currentFuture => locationFuture;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // LEVEL HELPERS
  String get _levelBackend {
    final idx = widget.translatedLocationLevels
        .indexOf(widget.selectedLocationLevel)
        .clamp(0, 3);
    return widget.levelBackends[idx];
  }

  // MONTHLY FETCH
  Future<List<LocationData>> _fetchLocation(int month, int year, String level) async {
    try {
      final ll      = level.toLowerCase();
      final idCol   = _idColFor(ll);
      final nameCol = _nameColFor(ll);

      final List<dynamic> locations =
          await _supabase.from(ll).select('$idCol, $nameCol');
      final List<dynamic> reportRes = await _supabase
          .from('accident_report')
          .select(idCol)
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at',
              DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String())
          .not(idCol, 'is', null);

      final Map<String, int> countMap = {};
      for (final t in reportRes) {
        final id = t[idCol]?.toString() ?? '';
        if (id.isEmpty) continue;
        countMap[id] = (countMap[id] ?? 0) + 1;
      }

      final List<dynamic> picRes = await _supabase
          .from('User')
          .select('$idCol, nama')
          .not(idCol, 'is', null);
      final Map<String, String> picMap = {};
      for (final p in picRes) {
        final locId = p[idCol]?.toString() ?? '';
        if (locId.isEmpty || picMap.containsKey(locId)) continue;
        picMap[locId] = p['nama']?.toString() ?? 'PIC belum diatur';
      }

      return locations.map<LocationData>((loc) {
        final id = loc[idCol]?.toString() ?? '';
        return LocationData(
          name:  loc[nameCol]?.toString() ?? '-',
          pic:   picMap[id] ?? 'PIC belum diatur',
          value: (countMap[id] ?? 0).toString(),
        );
      }).toList()
        ..sort((a, b) => (int.tryParse(b.value ?? '0') ?? 0)
            .compareTo(int.tryParse(a.value ?? '0') ?? 0));
    } catch (e) {
      return [];
    }
  }

  // DAILY FETCH
  Future<List<LocationData>> _fetchLocationDaily(DateTime date, String level) async {
    try {
      final start   = DateTime(date.year, date.month, date.day);
      final end     = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final ll      = level.toLowerCase();
      final idCol   = _idColFor(ll);
      final nameCol = _nameColFor(ll);

      final locations  = await _supabase.from(ll).select('$idCol, $nameCol');
      final reportList = await _supabase
          .from('accident_report')
          .select(idCol)
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());

      final Map<String, int> countMap = {};
      for (final t in reportList) {
        final id = t[idCol]?.toString() ?? '';
        if (id.isEmpty) continue;
        countMap[id] = (countMap[id] ?? 0) + 1;
      }

      return (locations as List<dynamic>).map((loc) => LocationData(
        name:  loc[nameCol]?.toString() ?? '-',
        pic:   '-',
        value: (countMap[loc[idCol]?.toString() ?? ''] ?? 0).toString(),
      )).toList()
        ..sort((a, b) => (int.tryParse(b.value ?? '0') ?? 0)
            .compareTo(int.tryParse(a.value ?? '0') ?? 0));
    } catch (e) {
      return [];
    }
  }

  // COLUMN HELPER
  String _idColFor(String ll) =>
      {'lokasi': 'id_lokasi', 'unit': 'id_unit',
       'subunit': 'id_subunit', 'area': 'id_area'}[ll] ?? 'id_lokasi';

  String _nameColFor(String ll) =>
      {'lokasi': 'nama_lokasi', 'unit': 'nama_unit',
       'subunit': 'nama_subunit', 'area': 'nama_area'}[ll] ?? 'nama_lokasi';

  String _t(String id, String en, String zh) {
    if (widget.lang == 'ID') return id;
    if (widget.lang == 'ZH') return zh;
    return en;
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // FILTER ROW
      Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          widget.buildFilterBtn(
            label: widget.filterMode == 'daily' && widget.selectedDate != null
                ? DateFormat('d MMM yyyy',
                        widget.lang == 'ID' ? 'id_ID'
                        : widget.lang == 'EN' ? 'en_US' : 'zh_CN')
                    .format(widget.selectedDate!)
                : _monthLabel,
            isActive: true,
            onTap: () => widget.showMonthPicker(fetchData),
          ),
          const SizedBox(width: 10),
          Expanded(child: widget.buildFilterBtn(
            label: widget.selectedLocationLevel,
            onTap: widget.showLevelPicker,
          )),
        ]),
      ),
      // LAST UPDATED
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(widget.lastUpdatedText,
              style: const TextStyle(
                  fontSize: 11, color: _C.textSecondary, height: 1.4)),
        ),
      ),
      _buildTableHeader(),
      // LIST
      Expanded(child: locationFuture == null
          ? _buildShimmer()
          : FutureBuilder<List<LocationData>>(
              future: locationFuture,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return _buildShimmer();
                }
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return Center(child: Text(
                    _t('Tidak ada data lokasi.',
                       'No location data.', '没有位置数据。'),
                    style: const TextStyle(color: _C.textSecondary)));
                }
                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: _C.divider, indent: 16),
                  itemBuilder: (_, i) => _buildLocationRow(i + 1, list[i]),
                );
              },
            )),
    ]);
  }

  // TABLE HEADER
  Widget _buildTableHeader() {
    return Container(
      color: const Color(0xFFF8FAFF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        SizedBox(
          width: 40,
          child: Text(_t('Rank', 'Rank', '排名'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                  color: _C.textSecondary, letterSpacing: 0.2)),
        ),
        Expanded(
          flex: 3,
          child: Text(_t('Lokasi', 'Location', '位置'),
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                  color: _C.textSecondary, letterSpacing: 0.2)),
        ),
        SizedBox(
          width: 70,
          child: Text(_t('Laporan', 'Reports', '报告'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                  color: _C.textSecondary, letterSpacing: 0.2)),
        ),
      ]),
    );
  }

  // LOCATION ROW
  Widget _buildLocationRow(int rank, LocationData loc) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        SizedBox(
          width: 40,
          child: Text('$rank',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13,
                  color: _C.textSecondary, fontWeight: FontWeight.w500)),
        ),
        Expanded(flex: 3, child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: _C.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.location_city_rounded,
                color: _C.red, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(loc.name,
                style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w600, color: _C.textPrimary),
                overflow: TextOverflow.ellipsis),
            Text(loc.pic,
                style: const TextStyle(
                    fontSize: 11.5, color: _C.textSecondary),
                overflow: TextOverflow.ellipsis),
          ])),
        ])),
        SizedBox(
          width: 70,
          child: Text(loc.value ?? '0',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: (int.tryParse(loc.value ?? '0') ?? 0) > 0
                      ? _C.red : _C.textMuted)),
        ),
      ]),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!,
      child: ListView.separated(
        padding: EdgeInsets.zero, itemCount: 8,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: _C.divider, indent: 16),
        itemBuilder: (_, __) => Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            SizedBox(
                width: 40,
                child: Center(child: _shimmerBox(height: 14, width: 20))),
            Expanded(flex: 3, child: Row(children: [
              _shimmerBox(height: 38, width: 38, borderRadius: 10),
              const SizedBox(width: 10),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                _shimmerBox(height: 14, width: double.infinity),
                const SizedBox(height: 4),
                _shimmerBox(height: 12, width: 100),
              ])),
            ])),
            SizedBox(
                width: 70,
                child: Center(child: _shimmerBox(height: 14, width: 20))),
          ]),
        ),
      ),
    );
  }

  Widget _shimmerBox({double? width, required double height,
      bool isCircle = false, double borderRadius = 8}) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(isCircle ? height / 2 : borderRadius),
      ),
    );
  }

  // HELPERS
  String get _monthLabel {
    final locale = widget.lang == 'ID' ? 'id_ID'
        : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    return DateFormat.MMM(locale)
        .format(DateTime(2000, widget.selectedMonthIndex + 1));
  }
}