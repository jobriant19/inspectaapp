import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../user/analytics/5r findings/5r_location_tab.dart';

class _AppColors {
  static const primary = Color(0xFF0EA5E9);
  static const primaryLight = Color(0xFFE0F2FE);
  static const textSecondary = Color(0xFF64748B);
  static const divider = Color(0xFFE0F2FE);
}

class _ChartBarData {
  final int date;
  final int temuan;
  final int penyelesaian;
  _ChartBarData({required this.date, required this.temuan, required this.penyelesaian});
}

class Admin5RLocationTab extends StatefulWidget {
  final String lang;
  const Admin5RLocationTab({super.key, required this.lang});

  @override
  State<Admin5RLocationTab> createState() => _Admin5RLocationTabState();
}

class _Admin5RLocationTabState extends State<Admin5RLocationTab> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final Map<String, Map<String, String>> _texts = {
    'ID': {
      'rank': 'Rank', 'temuan': 'Temuan',
      'tidak_ada_data_level': 'Tidak ada data untuk level',
      'level_lokasi': 'Lokasi', 'level_unit': 'Unit',
      'level_subunit': 'Subunit', 'level_area': 'Area',
      'periode_audit': 'Periode audit: ',
      'memuat_data': 'Memuat data...',
      'diperbarui_pada': 'Terakhir diperbarui pada',
      'pilih_bulan': 'Pilih Bulan', 'pilih_lokasi': 'Pilih Lokasi',
      'cari': 'Cari...', 'terapkan': 'Terapkan',
      'semua_grup_anggota': 'Semua Grup',
    },
    'EN': {
      'rank': 'Rank', 'temuan': 'Findings',
      'tidak_ada_data_level': 'No data for level',
      'level_lokasi': 'Location', 'level_unit': 'Unit',
      'level_subunit': 'Sub-unit', 'level_area': 'Area',
      'periode_audit': 'Audit period: ',
      'memuat_data': 'Loading data...',
      'diperbarui_pada': 'Last updated at',
      'pilih_bulan': 'Select Month', 'pilih_lokasi': 'Select Location',
      'cari': 'Search...', 'terapkan': 'Apply',
      'semua_grup_anggota': 'All Groups',
    },
    'ZH': {
      'rank': '排名', 'temuan': '发现',
      'tidak_ada_data_level': '没有级别的数据',
      'level_lokasi': '位置', 'level_unit': '单元',
      'level_subunit': '子单元', 'level_area': '区域',
      'periode_audit': '审计期间: ',
      'memuat_data': '加载数据...',
      'diperbarui_pada': '最后更新于',
      'pilih_bulan': '选择月份', 'pilih_lokasi': '选择位置',
      'cari': '搜索...', 'terapkan': '应用',
      'semua_grup_anggota': '所有组',
    },
  };

  String getTxt(String key) => _texts[widget.lang]?[key] ?? key;

  // FILTER STATE
  int _selectedMonthIndex = DateTime.now().month - 1;
  String _filterMode = 'monthly';
  DateTime? _selectedDate;
  String _selectedLocationLevel = 'Lokasi';
  DateTime? _lastUpdated;
  int _chartRefreshKey = 0;

  // CHART STATE
  bool _isChartExpanded = false;
  Future<List<_ChartBarData>>? _chartFuture;
  int _chartTargetLokasi  = 5;
  int _chartTargetUnit    = 5;
  int _chartTargetSubunit = 5;
  int _chartTargetArea    = 5;

  // DATA STATE
  Future<List<LocationData5R>>? _lokasiFuture;
  Future<List<AuditLocationData5R>>? _auditLokasiFuture;

  // SPECIFIC LOCATION FILTER
  String? _selectedSpecificLocationId;
  String? _selectedSpecificLocationName;

  late List<String> _translatedMonths;
  late List<String> _translatedLocationLevels;

  @override
  void initState() {
    super.initState();
    _initLocaleDependentLists();
    _fetchAllData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initLocaleDependentLists();
  }

  void _initLocaleDependentLists() {
    final locale = widget.lang == 'ID' ? 'id_ID' : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');
    _translatedMonths = List.generate(12, (i) =>
        DateFormat.MMM(locale).format(DateTime(2000, i + 1)));

    final locationLevelsBackend = ['Lokasi', 'Unit', 'Subunit', 'Area'];
    _translatedLocationLevels = [
      getTxt('level_lokasi'), getTxt('level_unit'),
      getTxt('level_subunit'), getTxt('level_area'),
    ];
    final selectedLevelIndex = locationLevelsBackend.indexOf(_selectedLocationLevel);
    if (selectedLevelIndex != -1) _selectedLocationLevel = _translatedLocationLevels[selectedLevelIndex];
  }

  // ── TARGET FETCHING ─────────────────────────────────────────────────────
  Future<void> _fetchTarget() async {
    try {
      final month = _selectedMonthIndex + 1;
      final year = DateTime.now().year;

      if (_filterMode == 'daily' && _selectedDate != null) {
        await _fetchTargetForDate(_selectedDate!);
      } else {
        await _fetchTargetMonthly(month, year);
      }
    } catch (e) {
      debugPrint('Error fetching target: $e');
    }
  }

  Future<void> _fetchTargetMonthly(int month, int year) async {
    try {
      final referenceDate =
          DateTime(year, month, 1).toIso8601String().split('T').first;

      final rows = await _supabase
          .from('target_5r_findings')
          .select()
          .eq('type', 'monthly')
          .lte('effective_date', referenceDate)
          .order('effective_date', ascending: false)
          .limit(1);

      if (!mounted) return;
      final data = (rows as List).isNotEmpty ? rows.first : null;
      setState(() {
        if (data != null) {
          _chartTargetLokasi  = data['target_lokasi']  ?? 5;
          _chartTargetUnit    = data['target_unit']    ?? 5;
          _chartTargetSubunit = data['target_subunit'] ?? 5;
          _chartTargetArea    = data['target_area']    ?? 5;
        } else {
          _chartTargetLokasi = 0; _chartTargetUnit = 0;
          _chartTargetSubunit = 0; _chartTargetArea = 0;
        }
      });
    } catch (e) {
      debugPrint('Error fetching monthly target: $e');
    }
  }

  Future<void> _fetchTargetForDate(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T').first;
      final weekday = date.weekday;

      if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
        if (!mounted) return;
        _applyZeroTarget();
        return;
      }

      final offDayRows = await _supabase
          .from('target_5r_findings')
          .select()
          .eq('type', 'off_day')
          .eq('specific_date', dateStr)
          .eq('is_aktif', true)
          .limit(1);

      if ((offDayRows as List).isNotEmpty) {
        if (!mounted) return;
        _applyZeroTarget();
        return;
      }

      final dailyRows = await _supabase
          .from('target_5r_findings')
          .select()
          .eq('type', 'daily_specific')
          .eq('specific_date', dateStr)
          .eq('is_aktif', true)
          .order('updated_at', ascending: false)
          .limit(1);

      if ((dailyRows as List).isNotEmpty) {
        final daily = dailyRows.first;
        if (!mounted) return;
        setState(() {
          _chartTargetLokasi  = daily['target_lokasi']  ?? 5;
          _chartTargetUnit    = daily['target_unit']    ?? 5;
          _chartTargetSubunit = daily['target_subunit'] ?? 5;
          _chartTargetArea    = daily['target_area']    ?? 5;
        });
        return;
      }

      await _fetchTargetMonthly(date.month, date.year);
    } catch (e) {
      debugPrint('Error fetching daily target: $e');
    }
  }

  void _applyZeroTarget() {
    setState(() {
      _chartTargetLokasi = 0; _chartTargetUnit = 0;
      _chartTargetSubunit = 0; _chartTargetArea = 0;
    });
  }

  (int temuan, int selesai) get _locationTargets {
    final bool isHolidayOrWeekend = _filterMode == 'daily' &&
        _selectedDate != null &&
        _chartTargetLokasi == 0 && _chartTargetUnit == 0 &&
        _chartTargetSubunit == 0 && _chartTargetArea == 0;
    if (isHolidayOrWeekend) return (0, 0);

    final levelIdx = _translatedLocationLevels
        .indexOf(_selectedLocationLevel)
        .clamp(0, 3);
    final levelLower = ['Lokasi', 'Unit', 'Subunit', 'Area'][levelIdx];
    switch (levelLower) {
      case 'Unit':    return (_chartTargetUnit,    _chartTargetUnit);
      case 'Subunit': return (_chartTargetSubunit, _chartTargetSubunit);
      case 'Area':    return (_chartTargetArea,    _chartTargetArea);
      default:        return (_chartTargetLokasi,  _chartTargetLokasi);
    }
  }

  // ── MAIN DATA FETCH ─────────────────────────────────────────────────────
  void _fetchAllData({bool fromTabFilter = false}) {
    _fetchTarget();

    final levelBackendValue = ['Lokasi', 'Unit', 'Subunit', 'Area'][
        _translatedLocationLevels.indexOf(_selectedLocationLevel).clamp(0, 3)];

    setState(() {
      _lastUpdated = DateTime.now();
      final month = _selectedMonthIndex + 1;
      final year = DateTime.now().year;

      if (_filterMode == 'daily' && _selectedDate != null) {
        _lokasiFuture = _fetchLokasiDataDaily(_selectedDate!, levelBackendValue);
      } else {
        _lokasiFuture = _fetchLokasiData(month, year, levelBackendValue);
        _auditLokasiFuture = _fetchLokasiAuditData(month, year, levelBackendValue);
      }
      _chartFuture = _fetchChartData(month, year);
      _chartRefreshKey++;
    });
  }

  Future<List<LocationData5R>> _fetchLokasiData(int month, int year, String level) async {
    try {
      final levelLower = level.toLowerCase();
      final idMap = {
        'lokasi': 'id_lokasi', 'unit': 'id_unit',
        'subunit': 'id_subunit', 'area': 'id_area'
      };
      final nameMap = {
        'lokasi': 'nama_lokasi', 'unit': 'nama_unit',
        'subunit': 'nama_subunit', 'area': 'nama_area'
      };
      final idCol = idMap[levelLower] ?? 'id_lokasi';
      final nameCol = nameMap[levelLower] ?? 'nama_lokasi';

      var locQuery = _supabase.from(levelLower).select('$idCol, $nameCol');
      if (_selectedSpecificLocationId != null) {
        locQuery = locQuery.eq(idCol, _selectedSpecificLocationId!);
      }
      final List<dynamic> locations = await locQuery;

      final List<dynamic> temuanRes = await _supabase
          .from('temuan')
          .select(idCol)
          .neq('jenis_temuan', 'KTS Production')
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at', DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String())
          .not(idCol, 'is', null);

      final Map<String, int> countMap = {};
      for (final t in temuanRes) {
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

      return locations.map<LocationData5R>((loc) {
        final id = loc[idCol]?.toString() ?? '';
        return LocationData5R(
          name: loc[nameCol]?.toString() ?? '-',
          pic: picMap[id] ?? 'PIC belum diatur',
          value: (countMap[id] ?? 0).toString(),
        );
      }).toList()
        ..sort((a, b) => (int.tryParse(b.value ?? '0') ?? 0)
            .compareTo(int.tryParse(a.value ?? '0') ?? 0));
    } catch (e) {
      debugPrint('Error fetching Lokasi: $e');
      return [];
    }
  }

  Future<List<AuditLocationData5R>> _fetchLokasiAuditData(
      int month, int year, String level) async {
    try {
      final levelLower = level.toLowerCase();
      final idMap   = {'lokasi':'id_lokasi','unit':'id_unit','subunit':'id_subunit','area':'id_area'};
      final nameMap = {'lokasi':'nama_lokasi','unit':'nama_unit','subunit':'nama_subunit','area':'nama_area'};
      final idCol   = idMap[levelLower]   ?? 'id_lokasi';
      final nameCol = nameMap[levelLower] ?? 'nama_lokasi';

      var locQuery = _supabase.from(levelLower).select('$idCol, $nameCol, id_pic');
      if (_selectedSpecificLocationId != null) {
        locQuery = locQuery.eq(idCol, _selectedSpecificLocationId!);
      }
      final List<dynamic> locations = await locQuery;

      final startOfMonth = DateTime(year, month, 1).toIso8601String().split('T').first;
      final endOfMonth   = DateTime(year, month + 1, 0).toIso8601String().split('T').first;

      final List<dynamic> auditRows = await _supabase
          .from('audit_result')
          .select('id_ref, nilai_audit, tanggal_audit')
          .eq('level_type', levelLower)
          .gte('tanggal_audit', startOfMonth)
          .lte('tanggal_audit', endOfMonth)
          .order('tanggal_audit', ascending: false);

      final Map<String, Map<String, dynamic>> auditMap = {};
      for (final a in auditRows) {
        final ref = a['id_ref'].toString();
        if (!auditMap.containsKey(ref)) auditMap[ref] = a;
      }

      final picIds = locations
          .where((l) => l['id_pic'] != null)
          .map((l) => l['id_pic'].toString())
          .toSet()
          .toList();
      final Map<String, String> picMap = {};
      if (picIds.isNotEmpty) {
        final picRows = await _supabase
            .from('User')
            .select('id_user, nama')
            .inFilter('id_user', picIds);
        for (final p in picRows) {
          picMap[p['id_user'].toString()] = p['nama']?.toString() ?? '-';
        }
      }

      return locations.map<AuditLocationData5R>((loc) {
        final id    = loc[idCol]?.toString() ?? '';
        final audit = auditMap[id];
        return AuditLocationData5R(
          id: id,
          name: loc[nameCol]?.toString() ?? '-',
          pic: loc['id_pic'] != null
              ? (picMap[loc['id_pic'].toString()] ?? 'PIC belum diatur')
              : 'PIC belum diatur',
          auditScore: audit != null
              ? double.tryParse(audit['nilai_audit']?.toString() ?? '')
              : null,
          auditDate: audit?['tanggal_audit']?.toString(),
        );
      }).toList()
        ..sort((a, b) {
          if (a.auditScore == null && b.auditScore == null) return 0;
          if (a.auditScore == null) return 1;
          if (b.auditScore == null) return -1;
          return b.auditScore!.compareTo(a.auditScore!);
        });
    } catch (e) {
      debugPrint('Error fetching audit lokasi: $e');
      return [];
    }
  }

  Future<List<LocationData5R>> _fetchLokasiDataDaily(DateTime date, String level) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final levelLower = level.toLowerCase();
      final idMap = {
        'lokasi': 'id_lokasi', 'unit': 'id_unit',
        'subunit': 'id_subunit', 'area': 'id_area'
      };
      final nameMap = {
        'lokasi': 'nama_lokasi', 'unit': 'nama_unit',
        'subunit': 'nama_subunit', 'area': 'nama_area'
      };
      final idCol = idMap[levelLower] ?? 'id_lokasi';
      final nameCol = nameMap[levelLower] ?? 'nama_lokasi';

      var locQuery = _supabase.from(levelLower).select('$idCol, $nameCol');
      if (_selectedSpecificLocationId != null) {
        locQuery = locQuery.eq(idCol, _selectedSpecificLocationId!);
      }
      final List<dynamic> locations = await locQuery;

      final List<dynamic> temuanRes = await _supabase
          .from('temuan')
          .select(idCol)
          .neq('jenis_temuan', 'KTS Production')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .not(idCol, 'is', null);

      final Map<String, int> countMap = {};
      for (final t in temuanRes) {
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

      return locations.map<LocationData5R>((loc) {
        final id = loc[idCol]?.toString() ?? '';
        return LocationData5R(
          name: loc[nameCol]?.toString() ?? '-',
          pic: picMap[id] ?? 'PIC belum diatur',
          value: (countMap[id] ?? 0).toString(),
        );
      }).toList()
        ..sort((a, b) => (int.tryParse(b.value ?? '0') ?? 0)
            .compareTo(int.tryParse(a.value ?? '0') ?? 0));
    } catch (e) {
      debugPrint('Error fetching Lokasi daily: $e');
      return [];
    }
  }

  // ── CHART DATA (khusus tab Location) ────────────────────────────────────
  Future<List<_ChartBarData>> _fetchChartData(int month, int year) async {
    try {
      final daysInMonth = DateUtils.getDaysInMonth(year, month);
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

      bool isDaily = _filterMode == 'daily' && _selectedDate != null;
      DateTime startDt, endDt;
      if (isDaily) {
        startDt = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
        endDt   = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 23, 59, 59);
      } else {
        startDt = startOfMonth;
        endDt   = endOfMonth;
      }

      List<_ChartBarData> buildDailyFromTemuan(List<dynamic> res) {
        if (isDaily) {
          return [_ChartBarData(
            date          : _selectedDate!.day,
            temuan        : res.length,
            penyelesaian  : res.where((t) => t['id_penyelesaian'] != null).length,
          )];
        }
        final Map<int, int> temuanMap = {}, selesaiMap = {};
        for (final t in res) {
          final dt = DateTime.tryParse(t['created_at']?.toString() ?? '');
          if (dt == null) continue;
          temuanMap[dt.day] = (temuanMap[dt.day] ?? 0) + 1;
          if (t['id_penyelesaian'] != null) selesaiMap[dt.day] = (selesaiMap[dt.day] ?? 0) + 1;
        }
        return List.generate(daysInMonth, (i) => _ChartBarData(
            date: i + 1, temuan: temuanMap[i + 1] ?? 0, penyelesaian: selesaiMap[i + 1] ?? 0));
      }

      if (!isDaily) {
        final levelBackend = ['lokasi', 'unit', 'subunit', 'area'][
            _translatedLocationLevels.indexOf(_selectedLocationLevel).clamp(0, 3)];
        var auditQuery = _supabase
            .from('audit_result')
            .select('tanggal_audit, nilai_audit')
            .eq('level_type', levelBackend)
            .gte('tanggal_audit', startOfMonth.toIso8601String().split('T').first)
            .lte('tanggal_audit', endOfMonth.toIso8601String().split('T').first);
        if (_selectedSpecificLocationId != null) {
          auditQuery = auditQuery.eq('id_ref', _selectedSpecificLocationId!);
        }
        final List<dynamic> auditRes = await auditQuery;

        final Map<int, List<double>> dayScores = {};
        for (final a in auditRes) {
          final dt    = DateTime.tryParse(a['tanggal_audit']?.toString() ?? '');
          if (dt == null) continue;
          final score = double.tryParse(a['nilai_audit']?.toString() ?? '');
          if (score == null) continue;
          dayScores.putIfAbsent(dt.day, () => []).add(score);
        }
        return List.generate(daysInMonth, (i) {
          final day    = i + 1;
          final scores = dayScores[day] ?? [];
          final avg    = scores.isEmpty
              ? 0
              : (scores.reduce((a, b) => a + b) / scores.length).round();
          return _ChartBarData(date: day, temuan: avg, penyelesaian: 0);
        });
      }

      final levelBackend = ['lokasi', 'unit', 'subunit', 'area'][
          _translatedLocationLevels.indexOf(_selectedLocationLevel).clamp(0, 3)];
      final Map<String, String> idColMap = {
        'lokasi': 'id_lokasi', 'unit': 'id_unit',
        'subunit': 'id_subunit', 'area': 'id_area',
      };
      final idCol    = idColMap[levelBackend] ?? 'id_lokasi';
      var temuanLocQuery = _supabase
          .from('temuan')
          .select('created_at, id_penyelesaian, $idCol')
          .neq('jenis_temuan', 'KTS Production')
          .gte('created_at', startDt.toIso8601String())
          .lte('created_at', endDt.toIso8601String())
          .not(idCol, 'is', null);
      if (_selectedSpecificLocationId != null) {
        temuanLocQuery = temuanLocQuery.eq(idCol, _selectedSpecificLocationId!);
      }
      final List<dynamic> res = await temuanLocQuery;
      return buildDailyFromTemuan(res);
    } catch (e) {
      debugPrint('Error fetching chart data: $e');
      return [];
    }
  }

  String get _lastUpdatedText {
    if (_lastUpdated == null) return getTxt('memuat_data');
    final formattedDate = DateFormat('d MMM yyyy HH:mm',
        widget.lang == 'ID' ? 'id_ID' : 'en_US').format(_lastUpdated!);
    return '${getTxt('diperbarui_pada')} $formattedDate (GMT+7)';
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildCollapsibleChart(),
      Expanded(child: _buildLokasiTabContent()),
    ]);
  }

  Widget _buildLokasiTabContent() {
    return FiveRLocationTab(
      lang: widget.lang,
      filterMode: _filterMode,
      selectedMonthIndex: _selectedMonthIndex,
      selectedDate: _selectedDate,
      selectedLocationLevel: _selectedLocationLevel,
      selectedLocationName: _selectedSpecificLocationName,
      translatedMonths: _translatedMonths,
      translatedLocationLevels: _translatedLocationLevels,
      lastUpdatedText: _lastUpdatedText,
      getTxt: getTxt,
      lokasiFuture: _lokasiFuture,
      auditLokasiFuture: _auditLokasiFuture,
      buildFilterBtn: _buildFilterButton,
      showMonthPicker: () => _showMonthPicker(
        () => _fetchAllData(fromTabFilter: true),
      ),
      showLevelPicker: _showLevelPicker,
      onResetLevel: () {
        setState(() {
          _selectedLocationLevel = _translatedLocationLevels[0];
          _selectedSpecificLocationId = null;
          _selectedSpecificLocationName = null;
        });
        _fetchAllData(fromTabFilter: true);
      },
      onRefresh: () => _fetchAllData(fromTabFilter: true),
      onAuditLocationTap: (loc) => _showAuditLocationDetail(loc),
    );
  }

  void _showAuditLocationDetail(AuditLocationData5R loc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AuditLocationDetailSheet(
        lang: widget.lang,
        loc: loc,
        levelType: ['Lokasi', 'Unit', 'Subunit', 'Area'][
            _translatedLocationLevels
                .indexOf(_selectedLocationLevel)
                .clamp(0, 3)].toLowerCase(),
      ),
    );
  }

  // ── COLLAPSIBLE CHART ────────────────────────────────────────────────────
  Widget _buildCollapsibleChart() {
    const activeColor = Color(0xFF0EA5E9);
    const colorTemuan = activeColor;
    const colorPenyelesaian = Color(0xFF10B981);

    final locale = widget.lang == 'ID' ? 'id_ID' : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');
    final monthLabel = _filterMode == 'daily' && _selectedDate != null
        ? DateFormat('d MMM yyyy', locale).format(_selectedDate!)
        : DateFormat('MMMM yyyy', locale).format(DateTime(
            DateTime.now().year, _selectedMonthIndex + 1));

    return Column(children: [
      GestureDetector(
        onTap: () => setState(() => _isChartExpanded = !_isChartExpanded),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: activeColor.withValues(alpha:0.4), width: 1.2),
            boxShadow: [BoxShadow(color: activeColor.withValues(alpha:0.08), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            const Icon(Icons.bar_chart_rounded, size: 16, color: activeColor),
            const SizedBox(width: 8),
            Expanded(child: Text(
              widget.lang == 'ID' ? 'Grafik $monthLabel'
                  : widget.lang == 'ZH' ? '$monthLabel 图表'
                  : 'Chart $monthLabel',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: activeColor),
            )),
            AnimatedRotation(
              turns: _isChartExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              child: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: activeColor),
            ),
          ]),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: _isChartExpanded
            ? FutureBuilder<List<_ChartBarData>>(
                key: ValueKey('chart-$_chartRefreshKey-admin-5r-location'),
                future: _chartFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      height: 160,
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: CircularProgressIndicator(
                          color: _AppColors.primary, strokeWidth: 2)),
                    );
                  }

                  final (tTarget, pTarget) = _locationTargets;
                  final data = snapshot.data ?? [];

                  int maxVal = math.max(tTarget, pTarget);
                  for (final d in data) {
                    if (d.temuan > maxVal) maxVal = d.temuan;
                    if (d.penyelesaian > maxVal) maxVal = d.penyelesaian;
                  }
                  maxVal = ((math.max(maxVal, 5) / 5).ceil() * 5).clamp(5, 9999);

                  const double chartH    = 140.0;
                  const double barGroupW = 28.0;
                  const double barW      = 8.0;
                  const double leftW     = 36.0;

                  double valToY(int v) => chartH - (v / maxVal * chartH).clamp(0.0, chartH);

                  final yStep  = (maxVal / 4).ceil().clamp(1, 99999);
                  final yLabels = List.generate(5, (i) => i * yStep);

                  final bool isLocationAuditTab = !(_filterMode == 'daily' && _selectedDate != null);

                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.fromLTRB(0, 12, 8, 8),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _AppColors.primaryLight),
                      boxShadow: [BoxShadow(color: activeColor.withValues(alpha:0.06), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(
                        padding: EdgeInsets.only(left: leftW + 4, bottom: 8),
                        child: isLocationAuditTab
                            ? Wrap(spacing: 12, children: [
                                _chartLegendItem(colorTemuan,
                                  widget.lang == 'ID' ? 'Rata-rata Nilai Audit'
                                      : widget.lang == 'ZH' ? '平均审计分数'
                                      : 'Avg Audit Score'),
                              ])
                            : Wrap(spacing: 12, children: [
                                _chartLegendItem(colorTemuan,
                                  widget.lang == 'ID' ? 'Temuan' : 'Findings'),
                                _chartLegendItem(colorPenyelesaian,
                                  widget.lang == 'ID' ? 'Selesai' : 'Completed'),
                                if (tTarget > 0)
                                  _chartLegendDash(
                                    const Color(0xFFEF4444),
                                    widget.lang == 'ID' ? 'Target Lokasi' : widget.lang == 'ZH' ? '位置目标' : 'Location Target',
                                  ),
                                if (pTarget > 0)
                                  _chartLegendDash(
                                    const Color(0xFFF59E0B),
                                    widget.lang == 'ID' ? 'Target Selesai' : widget.lang == 'ZH' ? '完成目标' : 'Completion Target',
                                  ),
                              ]),
                      ),

                      SizedBox(
                        height: chartH + 28,
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          SizedBox(
                            width: leftW,
                            height: chartH,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: yLabels.map((v) {
                                final yPos = valToY(v);
                                if (yPos < 0 || yPos > chartH) return const SizedBox.shrink();
                                return Positioned(
                                  top: yPos - 7,
                                  right: 4,
                                  left: 0,
                                  child: Text(
                                    v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '$v',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: _AppColors.textSecondary,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          Expanded(child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: math.max(data.length * barGroupW + 8, 40),
                              child: Stack(children: [
                                ...yLabels.map((v) => Positioned(
                                  top: valToY(v), left: 0, right: 0,
                                  child: Container(height: 1, color: _AppColors.divider),
                                )),

                                if (tTarget > 0)
                                  Stack(children: [
                                    Positioned(
                                      top: valToY(tTarget), left: 0, right: 0,
                                      child: CustomPaint(
                                        painter: _DashedLinePainter(const Color(0xFFEF4444)),
                                        child: const SizedBox(height: 2))),
                                    Positioned(
                                      top: valToY(pTarget), left: 0, right: 0,
                                      child: CustomPaint(
                                        painter: _DashedLinePainter(const Color(0xFFF59E0B)),
                                        child: const SizedBox(height: 2))),
                                  ]),

                                ...data.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final d = entry.value;
                                  final x = i * barGroupW + 4.0;
                                  final tH = (d.temuan / maxVal * chartH).clamp(0.0, chartH);
                                  final pH = (d.penyelesaian / maxVal * chartH).clamp(0.0, chartH);

                                  final dateLabel = _filterMode == 'daily' && _selectedDate != null
                                      ? DateFormat('d/M', widget.lang == 'ID' ? 'id_ID' : 'en_US')
                                          .format(_selectedDate!)
                                      : DateFormat('d/M', widget.lang == 'ID' ? 'id_ID' : 'en_US')
                                          .format(DateTime(DateTime.now().year, _selectedMonthIndex + 1, d.date));

                                  return Positioned(
                                    left: x, top: 0,
                                    child: SizedBox(
                                      width: barGroupW, height: chartH + 28,
                                      child: Column(children: [
                                        SizedBox(height: chartH, child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(width: barW, height: tH,
                                              decoration: const BoxDecoration(
                                                color: colorTemuan,
                                                borderRadius: BorderRadius.vertical(top: Radius.circular(3)))),
                                            const SizedBox(width: 2),
                                            Container(width: barW, height: pH,
                                              decoration: const BoxDecoration(
                                                color: colorPenyelesaian,
                                                borderRadius: BorderRadius.vertical(top: Radius.circular(3)))),
                                          ],
                                        )),
                                        const SizedBox(height: 3),
                                        Text(dateLabel, style: const TextStyle(
                                            fontSize: 7.5, color: _AppColors.textSecondary,
                                            fontWeight: FontWeight.w500),
                                          textAlign: TextAlign.center),
                                      ]),
                                    ),
                                  );
                                }),
                              ]),
                            ),
                          )),
                        ]),
                      ),
                    ]),
                  );
                },
              )
            : const SizedBox.shrink(),
      ),
    ]);
  }

  Widget _chartLegendItem(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 10, color: _AppColors.textSecondary)),
  ]);

  Widget _chartLegendDash(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    SizedBox(width: 14, child: CustomPaint(
        painter: _DashedLinePainter(color), child: const SizedBox(height: 2))),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 10, color: _AppColors.textSecondary)),
  ]);

  // ── FILTER BUTTON ────────────────────────────────────────────────────────
  Widget _buildFilterButton({
    required String label,
    required VoidCallback onTap,
    IconData icon = Icons.keyboard_arrow_down_rounded,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? _AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _AppColors.primary : const Color(0xFF7DD3FC),
            width: 1.5,
          ),
          boxShadow: [BoxShadow(
              color: _AppColors.primary.withValues(alpha:0.10), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(child: Text(label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : _AppColors.primary),
            overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 4),
          Icon(icon, color: isActive ? Colors.white : _AppColors.primary, size: 18),
        ]),
      ),
    );
  }

  // ── MONTH / DAILY PICKER ─────────────────────────────────────────────────
  void _showMonthPicker(VoidCallback onChanged) async {
    String tempMode = _filterMode;
    int tempMonthIndex = _selectedMonthIndex;
    DateTime tempDate = _selectedDate ?? DateTime.now();
    DateTime tempDisplayMonth = DateTime(tempDate.year, tempDate.month, 1);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.65, maxWidth: 340),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _AppColors.primaryLight, width: 1.5)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                decoration: const BoxDecoration(
                  color: _AppColors.primaryLight,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                child: Row(children: [
                  const Icon(Icons.calendar_month_rounded, color: _AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(getTxt('pilih_bulan'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0C4A6E)))),
                  IconButton(icon: const Icon(Icons.close, size: 18, color: _AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Container(
                  decoration: BoxDecoration(color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _AppColors.primaryLight)),
                  padding: const EdgeInsets.all(4),
                  child: Row(children: ['monthly', 'daily'].map((mode) {
                    final isSel = tempMode == mode;
                    final label = mode == 'monthly'
                        ? (widget.lang == 'ID' ? 'Bulanan' : widget.lang == 'ZH' ? '按月' : 'Monthly')
                        : (widget.lang == 'ID' ? 'Harian' : widget.lang == 'ZH' ? '按日' : 'Daily');
                    return Expanded(child: GestureDetector(
                      onTap: () => setSt(() => tempMode = mode),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSel ? _AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(9)),
                        child: Center(child: Text(label, style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: isSel ? Colors.white : _AppColors.textSecondary))),
                      ),
                    ));
                  }).toList()),
                ),
              ),
              if (tempMode == 'monthly')
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.2),
                    itemCount: 12,
                    itemBuilder: (_, i) {
                      final isSel = i == tempMonthIndex;
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _filterMode = 'monthly';
                            _selectedMonthIndex = i;
                            _selectedDate = null;
                          });
                          _fetchTarget().then((_) => onChanged());
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: isSel ? _AppColors.primary : const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel ? _AppColors.primary : _AppColors.divider,
                              width: isSel ? 1.5 : 1),
                            boxShadow: isSel ? [BoxShadow(
                              color: _AppColors.primary.withValues(alpha:0.3),
                              blurRadius: 6, offset: const Offset(0, 2))] : []),
                          child: Center(child: Text(_translatedMonths[i], style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            color: isSel ? Colors.white : const Color(0xFF0C4A6E)))),
                        ),
                      );
                    },
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: _buildDailyCalendar(
                    tempDate,
                    tempDisplayMonth,
                    (picked) => setSt(() => tempDate = picked),
                    (newMonth) => setSt(() => tempDisplayMonth = newMonth),
                    onConfirm: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _filterMode = 'daily';
                        _selectedDate = tempDate;
                        _selectedMonthIndex = tempDate.month - 1;
                      });
                      onChanged();
                    },
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyCalendar(DateTime selectedDate, DateTime displayMonth,
      ValueChanged<DateTime> onDateChanged,
      ValueChanged<DateTime> onMonthChanged, {required VoidCallback onConfirm}) {
    final now = DateTime.now();
    final year = displayMonth.year;
    final month = displayMonth.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstWeekday = DateTime(year, month, 1).weekday % 7;
    final locale = widget.lang == 'ID' ? 'id_ID' : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');
    final monthLabel = DateFormat('MMMM yyyy', locale).format(DateTime(year, month));
    final dayLabels = widget.lang == 'ZH'
        ? ['日', '一', '二', '三', '四', '五', '六']
        : widget.lang == 'ID'
            ? ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
            : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final bool isCurrentMonth = year == now.year && month == now.month;

    return StatefulBuilder(
      builder: (_, setInner) => Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => onMonthChanged(DateTime(year, month - 1, 1)),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.chevron_left_rounded,
                    size: 18, color: _AppColors.primary),
              ),
            ),
            Text(monthLabel, style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0C4A6E))),
            GestureDetector(
              onTap: isCurrentMonth
                  ? null
                  : () => onMonthChanged(DateTime(year, month + 1, 1)),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isCurrentMonth
                      ? Colors.grey.shade100
                      : _AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.chevron_right_rounded,
                    size: 18,
                    color: isCurrentMonth
                        ? Colors.grey.shade400
                        : _AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(children: dayLabels.map((d) => Expanded(child: Center(
          child: Text(d, style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: _AppColors.textSecondary))))).toList()),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, crossAxisSpacing: 4, mainAxisSpacing: 4, childAspectRatio: 1),
          itemCount: firstWeekday + daysInMonth,
          itemBuilder: (_, i) {
            if (i < firstWeekday) return const SizedBox();
            final day = i - firstWeekday + 1;
            final date = DateTime(year, month, day);
            final isSelected = selectedDate.year == date.year &&
                selectedDate.month == date.month &&
                selectedDate.day == date.day;
            final isToday = now.year == date.year && now.month == date.month && now.day == date.day;
            final isFuture = date.isAfter(now);
            return GestureDetector(
              onTap: isFuture ? null : () => setInner(() => onDateChanged(date)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected ? _AppColors.primary
                      : isToday ? _AppColors.primaryLight : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday && !isSelected
                      ? Border.all(color: _AppColors.primary, width: 1.2) : null),
                child: Center(child: Text('$day', style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white
                      : isFuture ? const Color(0xFFBDBDBD) : const Color(0xFF0C4A6E)))),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: _AppColors.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10)),
            child: Text(getTxt('terapkan'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ),
      ]),
    );
  }

  // ── LEVEL PICKER ─────────────────────────────────────────────────────────
  void _showLevelPicker() async {
    String tempLevelLabel = _selectedLocationLevel;
    String? tempSelectedId = _selectedSpecificLocationId;
    final searchCtrl = TextEditingController();
    List<Map<String, dynamic>> items = [];
    bool loadingItems = true;
    bool levelDropdownOpen = false;

    final GlobalKey levelBtnKey = GlobalKey();
    final GlobalKey stackKey = GlobalKey();
    double dropdownTop = 102;
    double dropdownRight = 14;

    IconData levelIcon(String label) {
      final idx = _translatedLocationLevels.indexOf(label).clamp(0, 3);
      return [
        Icons.location_city_rounded,
        Icons.business_rounded,
        Icons.layers_rounded,
        Icons.place_rounded,
      ][idx];
    }

    Color levelColor(String label) {
      final idx = _translatedLocationLevels.indexOf(label).clamp(0, 3);
      return [
        const Color(0xFF10B981),
        const Color(0xFF6366F1),
        const Color(0xFFFBBF24),
        const Color(0xFFF472B6),
      ][idx];
    }

    Future<List<Map<String, dynamic>>> fetchItemsForLevel(String levelLabel) async {
      final levelBackend = ['Lokasi', 'Unit', 'Subunit', 'Area'][
          _translatedLocationLevels.indexOf(levelLabel).clamp(0, 3)];
      final levelLower = levelBackend.toLowerCase();
      final idMap = {'lokasi': 'id_lokasi', 'unit': 'id_unit', 'subunit': 'id_subunit', 'area': 'id_area'};
      final nameMap = {'lokasi': 'nama_lokasi', 'unit': 'nama_unit', 'subunit': 'nama_subunit', 'area': 'nama_area'};
      final idCol = idMap[levelLower] ?? 'id_lokasi';
      final nameCol = nameMap[levelLower] ?? 'nama_lokasi';
      try {
        final res = await _supabase.from(levelLower).select('$idCol, $nameCol').order(nameCol);
        return List<Map<String, dynamic>>.from(res)
            .map((e) => {'id': e[idCol]?.toString() ?? '', 'name': e[nameCol]?.toString() ?? '-'})
            .toList();
      } catch (e) {
        debugPrint('Error fetching level items: $e');
        return [];
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          if (loadingItems) {
            fetchItemsForLevel(tempLevelLabel).then((res) {
              items = res;
              loadingItems = false;
              setSt(() {});
            });
          }

          final query = searchCtrl.text.trim().toLowerCase();
          final filteredItems = query.isEmpty
              ? items
              : items.where((e) => (e['name'] as String).toLowerCase().contains(query)).toList();
          final currentLevelColor = levelColor(tempLevelLabel);

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 340,
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _AppColors.primaryLight, width: 1.5)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(key: stackKey, clipBehavior: Clip.none, children: [
                  Column(children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                      decoration: const BoxDecoration(
                        color: _AppColors.primaryLight,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                      child: Row(children: [
                        const Icon(Icons.tune_rounded, color: _AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(getTxt('pilih_lokasi'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0C4A6E)))),
                        IconButton(icon: const Icon(Icons.close, size: 18, color: _AppColors.textSecondary),
                          onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _AppColors.primary.withValues(alpha: 0.35), width: 1.3),
                              boxShadow: [BoxShadow(
                                  color: _AppColors.primary.withValues(alpha: 0.08),
                                  blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            child: TextField(
                              controller: searchCtrl,
                              onChanged: (_) => setSt(() {}),
                              style: const TextStyle(fontSize: 13, color: Color(0xFF0C4A6E), fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                hintText: getTxt('cari'),
                                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFFBDBDBD)),
                                prefixIcon: const Icon(Icons.search_rounded, color: _AppColors.primary, size: 19),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          key: levelBtnKey,
                          onTap: () {
                            final btnBox = levelBtnKey.currentContext!
                                .findRenderObject() as RenderBox;
                            final stackBox = stackKey.currentContext!
                                .findRenderObject() as RenderBox;
                            final btnPos = btnBox.localToGlobal(Offset.zero,
                                ancestor: stackBox);
                            setSt(() {
                              dropdownTop = btnPos.dy + btnBox.size.height + 6;
                              dropdownRight = stackBox.size.width -
                                  (btnPos.dx + btnBox.size.width);
                              levelDropdownOpen = !levelDropdownOpen;
                            });
                          },
                          child: Container(
                            width: 132,
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: currentLevelColor,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [BoxShadow(
                                  color: currentLevelColor.withValues(alpha: 0.30),
                                  blurRadius: 8, offset: const Offset(0, 3))],
                            ),
                            child: Row(children: [
                              Icon(levelIcon(tempLevelLabel), color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Expanded(child: Text(tempLevelLabel,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white))),
                              AnimatedRotation(
                                turns: levelDropdownOpen ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
                              ),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                    const Divider(height: 1, color: _AppColors.divider),
                    Expanded(
                      child: loadingItems
                          ? const Center(child: CircularProgressIndicator(color: _AppColors.primary, strokeWidth: 2))
                          : ListView(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    setState(() {
                                      _selectedLocationLevel = tempLevelLabel;
                                      _selectedSpecificLocationId = null;
                                      _selectedSpecificLocationName = null;
                                    });
                                    _fetchAllData(fromTabFilter: true);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: tempSelectedId == null
                                          ? currentLevelColor.withValues(alpha: 0.10)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: tempSelectedId == null ? currentLevelColor : _AppColors.divider,
                                        width: tempSelectedId == null ? 1.5 : 1),
                                    ),
                                    child: Row(children: [
                                      Icon(Icons.apps_rounded,
                                          size: 18,
                                          color: tempSelectedId == null ? currentLevelColor : _AppColors.textSecondary),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text('${getTxt('semua_grup_anggota')} ($tempLevelLabel)',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: tempSelectedId == null ? FontWeight.bold : FontWeight.w500,
                                              color: tempSelectedId == null ? currentLevelColor : const Color(0xFF0C4A6E)))),
                                      if (tempSelectedId == null)
                                        Icon(Icons.check_circle_rounded, color: currentLevelColor, size: 18),
                                    ]),
                                  ),
                                ),
                                if (filteredItems.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 24),
                                    child: Center(
                                      child: Text(getTxt('tidak_ada_data_level'),
                                          style: const TextStyle(fontSize: 12.5, color: _AppColors.textSecondary)),
                                    ),
                                  )
                                else
                                  ...filteredItems.map((item) {
                                    final isSel = item['id'] == tempSelectedId;
                                    return InkWell(
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        setState(() {
                                          _selectedLocationLevel = tempLevelLabel;
                                          _selectedSpecificLocationId = item['id'] as String;
                                          _selectedSpecificLocationName = item['name'] as String;
                                        });
                                        _fetchAllData(fromTabFilter: true);
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isSel ? currentLevelColor.withValues(alpha: 0.10) : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSel ? currentLevelColor : _AppColors.divider,
                                            width: isSel ? 1.5 : 1),
                                        ),
                                        child: Row(children: [
                                          Container(
                                            width: 34, height: 34,
                                            decoration: BoxDecoration(
                                              color: isSel ? currentLevelColor : const Color(0xFFF0F9FF),
                                              borderRadius: BorderRadius.circular(9),
                                            ),
                                            child: Icon(levelIcon(tempLevelLabel),
                                                size: 17, color: isSel ? Colors.white : currentLevelColor),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(item['name'] as String,
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                                        color: isSel ? currentLevelColor : const Color(0xFF0C4A6E)),
                                                    overflow: TextOverflow.ellipsis),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                  decoration: BoxDecoration(
                                                    color: currentLevelColor.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(color: currentLevelColor.withValues(alpha: 0.4)),
                                                  ),
                                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                                    Icon(levelIcon(tempLevelLabel), size: 9, color: currentLevelColor),
                                                    const SizedBox(width: 3),
                                                    Text(tempLevelLabel,
                                                        style: TextStyle(
                                                            fontSize: 9, fontWeight: FontWeight.w700, color: currentLevelColor)),
                                                  ]),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          if (isSel)
                                            Icon(Icons.check_circle_rounded, color: currentLevelColor, size: 18),
                                        ]),
                                      ),
                                    );
                                  }),
                              ],
                            ),
                    ),
                  ]),

                  if (levelDropdownOpen)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => setSt(() => levelDropdownOpen = false),
                        child: Container(color: Colors.transparent),
                      ),
                    ),

                  if (levelDropdownOpen)
                    Positioned(
                      top: dropdownTop,
                      right: dropdownRight,
                      width: 132,
                      child: Material(
                        elevation: 10,
                        borderRadius: BorderRadius.circular(12),
                        shadowColor: Colors.black.withValues(alpha: 0.25),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _AppColors.divider),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: _translatedLocationLevels.map((lvl) {
                              final isSel = lvl == tempLevelLabel;
                              final color = levelColor(lvl);
                              return InkWell(
                                onTap: () {
                                  tempLevelLabel = lvl;
                                  tempSelectedId = null;
                                  loadingItems = true;
                                  searchCtrl.clear();
                                  levelDropdownOpen = false;
                                  setSt(() {});
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: isSel ? color.withValues(alpha: 0.12) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(children: [
                                    Icon(levelIcon(lvl), size: 16, color: isSel ? color : _AppColors.textSecondary),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(lvl,
                                        style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                            color: isSel ? color : const Color(0xFF0C4A6E)))),
                                    if (isSel) Icon(Icons.check_rounded, size: 15, color: color),
                                  ]),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 5, 0), paint);
      x += 8;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}