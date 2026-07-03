import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class _C {
  static const textPrimary    = Color(0xFF0C4A6E);
  static const textSecondary  = Color(0xFF64748B);
  static const textMuted      = Color(0xFFBDBDBD);
  static const divider        = Color(0xFFE0F2FE);
  static const red            = Color(0xFFEF4444);
  static const redLight       = Color(0xFFFEE2E2);
  static const redBorderLight = Color(0xFFFCA5A5);
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

  // SPECIFIC LOCATION FILTER
  final String? selectedLocationId;
  final String? selectedLocationName;

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
    this.selectedLocationId,
    this.selectedLocationName,
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
    String?   specificLocationId,
  }) {
    final mode       = filterMode         ?? widget.filterMode;
    final monthIdx    = selectedMonthIndex ?? widget.selectedMonthIndex;
    final date        = selectedDate       ?? widget.selectedDate;
    final backend      = levelBackend       ?? _levelBackend;
    final specificId  = specificLocationId ?? widget.selectedLocationId;

    final month = monthIdx + 1;
    final year  = DateTime.now().year;

    setState(() {
      if (mode == 'daily' && date != null) {
        locationFuture = _fetchLocationDaily(date, backend, specificId);
      } else {
        locationFuture = _fetchLocation(month, year, backend, specificId);
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
  Future<List<LocationData>> _fetchLocation(
      int month, int year, String level, String? specificLocationId) async {
    try {
      final ll      = level.toLowerCase();
      final idCol   = _idColFor(ll);
      final nameCol = _nameColFor(ll);

      var locQuery = _supabase.from(ll).select('$idCol, $nameCol, id_pic');
      if (specificLocationId != null) {
        locQuery = locQuery.eq(idCol, specificLocationId);
      }
      final List<dynamic> locations = await locQuery;
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

      // Ambil id_pic dari tabel level (lokasi/unit/subunit/area), lalu join ke User
      final picIds = locations
          .map((loc) => loc['id_pic']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      final Map<String, String> picMap = {};
      if (picIds.isNotEmpty) {
        final List<dynamic> picRes = await _supabase
            .from('User')
            .select('id_user, nama')
            .inFilter('id_user', picIds);
        for (final p in picRes) {
          final userId = p['id_user']?.toString() ?? '';
          if (userId.isEmpty) continue;
          picMap[userId] = p['nama']?.toString() ?? 'PIC belum diatur';
        }
      }

      return locations.map<LocationData>((loc) {
        final id    = loc[idCol]?.toString() ?? '';
        final picId = loc['id_pic']?.toString();
        return LocationData(
          name:  loc[nameCol]?.toString() ?? '-',
          pic:   (picId != null && picMap.containsKey(picId))
              ? picMap[picId]!
              : 'PIC belum diatur',
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
  Future<List<LocationData>> _fetchLocationDaily(
      DateTime date, String level, String? specificLocationId) async {
    try {
      final start   = DateTime(date.year, date.month, date.day);
      final end     = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final ll      = level.toLowerCase();
      final idCol   = _idColFor(ll);
      final nameCol = _nameColFor(ll);

      var locQuery = _supabase.from(ll).select('$idCol, $nameCol, id_pic');
      if (specificLocationId != null) {
        locQuery = locQuery.eq(idCol, specificLocationId);
      }
      final locations  = await locQuery;
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

      // Ambil id_pic dari tabel level (lokasi/unit/subunit/area), lalu join ke User
      final picIds = (locations as List<dynamic>)
          .map((loc) => loc['id_pic']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      final Map<String, String> picMap = {};
      if (picIds.isNotEmpty) {
        final List<dynamic> picRes = await _supabase
            .from('User')
            .select('id_user, nama')
            .inFilter('id_user', picIds);
        for (final p in picRes) {
          final userId = p['id_user']?.toString() ?? '';
          if (userId.isEmpty) continue;
          picMap[userId] = p['nama']?.toString() ?? 'PIC belum diatur';
        }
      }

      return locations.map<LocationData>((loc) {
        final picId = loc['id_pic']?.toString();
        return LocationData(
          name:  loc[nameCol]?.toString() ?? '-',
          pic:   (picId != null && picMap.containsKey(picId))
              ? picMap[picId]!
              : 'PIC belum diatur',
          value: (countMap[loc[idCol]?.toString() ?? ''] ?? 0).toString(),
        );
      }).toList()
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
          Expanded(child: _buildLocationTimeFilterButton()),
          const SizedBox(width: 10),
          Expanded(child: _buildLocationLevelFilterButton()),
        ]),
      ),
      // LAST UPDATED
      _buildLastUpdatedWidget(),
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

  // TIME FILTER BUTTON
  Widget _buildLocationTimeFilterButton() {
    final isActive = widget.filterMode == 'daily';
    final modeLabel = widget.filterMode == 'daily'
        ? _t('Harian', 'Daily', '按日')
        : _t('Bulanan', 'Monthly', '按月');
    final valueLabel = widget.filterMode == 'daily' && widget.selectedDate != null
        ? DateFormat('d MMM yyyy',
                widget.lang == 'ID' ? 'id_ID'
                : widget.lang == 'EN' ? 'en_US' : 'zh_CN')
            .format(widget.selectedDate!)
        : _monthLabel;

    return GestureDetector(
      onTap: () => widget.showMonthPicker(fetchData),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? _C.red : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _C.red : _C.redBorderLight,
            width: 1.5,
          ),
          boxShadow: [BoxShadow(
              color: _C.red.withValues(alpha:0.10), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month_rounded, size: 15,
                    color: isActive ? Colors.white : _C.red),
                const SizedBox(width: 5),
                Flexible(
                  child: Text('$modeLabel · $valueLabel',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : _C.red)),
                ),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded,
              color: isActive ? Colors.white : _C.red, size: 18),
        ]),
      ),
    );
  }

  // LEVEL FILTER BUTTON
  Widget _buildLocationLevelFilterButton() {
    final hasSpecificLocation =
        widget.selectedLocationName != null && widget.selectedLocationName!.isNotEmpty;
    final isActive = hasSpecificLocation ||
        widget.selectedLocationLevel != widget.translatedLocationLevels[0];
    final label = hasSpecificLocation
        ? widget.selectedLocationName!
        : widget.selectedLocationLevel;

    return GestureDetector(
      onTap: widget.showLevelPicker,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? _C.red : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _C.red : _C.redBorderLight,
            width: 1.5,
          ),
          boxShadow: [BoxShadow(
              color: _C.red.withValues(alpha:0.10), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Expanded(
            child: Text(label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : _C.red)),
          ),
          Icon(Icons.keyboard_arrow_down_rounded,
              color: isActive ? Colors.white : _C.red, size: 18),
        ]),
      ),
    );
  }

  // LAST UPDATED
  Widget _buildLastUpdatedWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _C.redLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.access_time_filled_rounded,
                size: 13, color: _C.red),
            const SizedBox(width: 6),
            Text(widget.lastUpdatedText,
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _C.textPrimary)),
          ]),
        ),
      ),
    );
  }

  // PIC BADGE
  Widget _buildPicBadge(String picName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _C.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.red.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.assignment_ind_rounded, size: 10, color: _C.red),
        const SizedBox(width: 3),
        Flexible(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: 'PIC : ',
                  style: TextStyle(
                      fontSize: 9.5, fontWeight: FontWeight.w700, color: _C.red)),
              TextSpan(
                  text: picName,
                  style: TextStyle(
                      fontSize: 9.5, fontWeight: FontWeight.w700, color: _C.red)),
            ]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
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
              textAlign: TextAlign.center,
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
                color: _C.red.withValues(alpha:0.1),
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
            const SizedBox(height: 4),
            _buildPicBadge(loc.pic),
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