import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '5r_inspection_tab.dart';
import '5r_location_tab.dart';
import '5r_members_tab.dart';
import '5r_recurring_tab.dart';

class _AppColors {
  static const primary = Color(0xFF0EA5E9);
  static const primaryLight = Color(0xFFE0F2FE);
  static const surface = Color(0xFFF0F9FF);
  static const textPrimary = Color(0xFF0C4A6E);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFFBDBDBD);
  static const divider = Color(0xFFE0F2FE);
}

class _ChartBarData {
  final int date;
  final int temuan;
  final int penyelesaian;
  _ChartBarData({required this.date, required this.temuan, required this.penyelesaian});
}

class Analytics5RTab extends StatefulWidget {
  final String lang;
  const Analytics5RTab({super.key, required this.lang});

  @override
  State<Analytics5RTab> createState() => _Analytics5RTabState();
}

class _Analytics5RTabState extends State<Analytics5RTab>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient _supabase = Supabase.instance.client;

  final Map<String, Map<String, String>> _texts = {
    'ID': {
      'anggota': 'Anggota', 'inspeksi': 'Inspeksi', 'lokasi': 'Lokasi',
      'temuan_berulang': 'Temuan Berulang', 'memuat_data': 'Memuat data...',
      'diperbarui_pada': 'Terakhir diperbarui pada', 'semua_grup': 'Semua Penemu', 'semua_grup_anggota': 'Semua Grup',
      'gagal_muat_anggota': 'Gagal memuat data Anggota',
      'gagal_muat_inspeksi': 'Gagal memuat data Inspeksi',
      'gagal_muat_lokasi': 'Gagal memuat data Lokasi',
      'tidak_ada_data_anggota': 'Tidak ada data anggota.',
      'tidak_ada_temuan_role': 'Tidak ada temuan untuk role',
      'tidak_ada_data_level': 'Tidak ada data untuk level',
      'nama': 'Nama', 'temuan': 'Temuan', 'selesai': 'Selesai',
      'target_bulanan': 'Target Bulanan', 'saya': 'Saya', 'rank': 'Rank',
      'periode_audit': 'Periode audit: ', 'topik': 'Topik',
      'belum_memiliki_temuan': 'belum\nmemiliki temuan berulang',
      'eksekutif': 'Eksekutif', 'profesional': 'Profesional', 'visitor': 'Visitor',
      'level_lokasi': 'Lokasi', 'level_unit': 'Unit',
      'level_subunit': 'Subunit', 'level_area': 'Area',
      'pilih_bulan': 'Pilih Bulan', 'pilih_grup': 'Pilih Grup',
      'pilih_level': 'Pilih Level', 'pilih_lokasi': 'Pilih Lokasi',
      'pilih_periode': 'Pilih Periode', 'pilih_penemu': 'Pilih Penemu',
      'cari': 'Cari...', 'dari': 'Dari', 'sampai': 'Sampai',
      'terapkan': 'Terapkan', 'total': 'Total',
      'penemu': 'Penemu', 'periode': 'Periode',
      'daftar_temuan': 'Daftar Temuan', 'di_sekitar': 'Di sekitar',
    },
    'EN': {
      'anggota': 'Members', 'inspeksi': 'Inspection', 'lokasi': 'Location',
      'temuan_berulang': 'Recurring Findings', 'memuat_data': 'Loading data...',
      'diperbarui_pada': 'Last updated at', 'semua_grup': 'All Finders', 'semua_grup_anggota': 'All Groups',
      'gagal_muat_anggota': 'Failed to load Member data',
      'gagal_muat_inspeksi': 'Failed to load Inspection data',
      'gagal_muat_lokasi': 'Failed to load Location data',
      'tidak_ada_data_anggota': 'No member data available.',
      'tidak_ada_temuan_role': 'No findings for role',
      'tidak_ada_data_level': 'No data for level',
      'nama': 'Name', 'temuan': 'Findings', 'selesai': 'Completed',
      'target_bulanan': 'Monthly Target', 'saya': 'Me', 'rank': 'Rank',
      'periode_audit': 'Audit period: ', 'topik': 'Topic',
      'belum_memiliki_temuan': 'does not have\nrecurring findings yet',
      'eksekutif': 'Executive', 'profesional': 'Professional', 'visitor': 'Visitor',
      'level_lokasi': 'Location', 'level_unit': 'Unit',
      'level_subunit': 'Sub-unit', 'level_area': 'Area',
      'pilih_bulan': 'Select Month', 'pilih_grup': 'Select Group',
      'pilih_level': 'Select Level', 'pilih_lokasi': 'Select Location',
      'pilih_periode': 'Select Period', 'pilih_penemu': 'Select Finder',
      'cari': 'Search...', 'dari': 'From', 'sampai': 'To',
      'terapkan': 'Apply', 'total': 'Total',
      'penemu': 'Finder', 'periode': 'Period',
      'daftar_temuan': 'Finding List', 'di_sekitar': 'Around',
    },
    'ZH': {
      'anggota': '成员', 'inspeksi': '检查', 'lokasi': '位置',
      'temuan_berulang': '重复发现', 'memuat_data': '加载数据...',
      'diperbarui_pada': '最后更新于', 'semua_grup': '所有发现者', 'semua_grup_anggota': '所有组',
      'gagal_muat_anggota': '加载成员数据失败',
      'gagal_muat_inspeksi': '加载检查数据失败',
      'gagal_muat_lokasi': '加载位置数据失败',
      'tidak_ada_data_anggota': '没有成员数据。',
      'tidak_ada_temuan_role': '没有角色的发现',
      'tidak_ada_data_level': '没有级别的数据',
      'nama': '名称', 'temuan': '发现', 'selesai': '已完成',
      'target_bulanan': '每月目标', 'saya': '我', 'rank': '排名',
      'periode_audit': '审计期间: ', 'topik': '话题',
      'belum_memiliki_temuan': '还没有\n重复的发现',
      'eksekutif': '行政', 'profesional': '专业', 'visitor': '访客',
      'level_lokasi': '位置', 'level_unit': '单元',
      'level_subunit': '子单元', 'level_area': '区域',
      'pilih_bulan': '选择月份', 'pilih_grup': '选择组',
      'pilih_level': '选择级别', 'pilih_lokasi': '选择位置',
      'pilih_periode': '选择期间', 'pilih_penemu': '选择发现者',
      'cari': '搜索...', 'dari': '从', 'sampai': '到',
      'terapkan': '应用', 'total': '总计',
      'penemu': '发现者', 'periode': '期间',
      'daftar_temuan': '发现列表', 'di_sekitar': '周围',
    },
  };

  String getTxt(String key) => _texts[widget.lang]?[key] ?? key;

  // FILTER STATE
  int _selectedMonthIndex = DateTime.now().month - 1;
  String _filterMode = 'monthly';
  DateTime? _selectedDate;
  String? _selectedUnitId;
  String _selectedInspectionRole = 'Eksekutif';
  String _selectedLocationLevel = 'Lokasi';
  DateTime? _lastUpdated;
  int _chartRefreshKey = 0;

  // CHART COLAPSE STATE
  bool _isChartExpanded = false;
  int _currentTabCount = 4;
  bool _isChartLoadingForTab = false;

  // CHART DATA
  Future<List<_ChartBarData>>? _chartFuture;
  int _chartTargetTemuan       = 2;
  int _chartTargetPenyelesaian = 2;
  int _chartTargetLokasi       = 5;
  int _chartTargetUnit         = 5;
  int _chartTargetSubunit      = 5;
  int _chartTargetArea         = 5;
  int _chartTargetAnggotaSelesai  = 2;
  int _chartTargetInspeksiSelesai = 2;
  int _activeTabIndex = 0;

  // DATA STATE
  final _membersTabKey = GlobalKey<FiveRMembersTabState>();
  final _recurringTabKey = GlobalKey<FiveRRecurringTabState>();
  Future<List<InspectionData5R>>? _inspeksiFuture;
  Future<List<LocationData5R>>? _lokasiFuture;
  Future<List<AuditLocationData5R>>? _auditLokasiFuture;

  List<Map<String, dynamic>> _unitList = [];
  int _targetAnggota = 2;
  int _targetInspeksi = 2;

  late List<String> _translatedMonths;
  late List<String> _translatedRoles;
  late List<String> _translatedLocationLevels;

  @override
  void initState() {
    super.initState();
    _currentTabCount = 4;
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _initLocaleDependentLists();
    _fetchUnits().then((_) {
      _fetchAllData();
      setState(() => _isChartLoadingForTab = false);
    });
    _fetchTarget();
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

    final rolesBackend = ['Eksekutif', 'Profesional', 'Visitor'];
    _translatedRoles = [getTxt('eksekutif'), getTxt('profesional'), getTxt('visitor')];
    final selectedRoleIndex = rolesBackend.indexOf(_selectedInspectionRole);
    if (selectedRoleIndex != -1) _selectedInspectionRole = _translatedRoles[selectedRoleIndex];

    final locationLevelsBackend = ['Lokasi', 'Unit', 'Subunit', 'Area'];
    _translatedLocationLevels = [
      getTxt('level_lokasi'), getTxt('level_unit'),
      getTxt('level_subunit'), getTxt('level_area'),
    ];
    final selectedLevelIndex = locationLevelsBackend.indexOf(_selectedLocationLevel);
    if (selectedLevelIndex != -1) _selectedLocationLevel = _translatedLocationLevels[selectedLevelIndex];
  }

  Future<void> _fetchUnits() async {
    try {
      final response = await _supabase.from('unit').select('id_unit, nama_unit');
      if (mounted) setState(() => _unitList = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint('Error fetching units: $e');
    }
  }

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
      final rows = await _supabase
          .from('target_5r_findings')
          .select()
          .eq('type', 'monthly')
          .eq('bulan', month)
          .eq('tahun', year)
          .eq('is_aktif', true)
          .order('updated_at', ascending: false)
          .limit(1);

      if (!mounted) return;
      final data = (rows as List).isNotEmpty ? rows.first : null;
      setState(() {
        if (data != null) {
          _targetAnggota               = data['target_anggota']          ?? 2;
          _targetInspeksi              = data['target_inspeksi']         ?? 2;
          _chartTargetTemuan           = data['target_anggota']          ?? 2;
          _chartTargetPenyelesaian     = data['target_inspeksi']         ?? 2;
          _chartTargetAnggotaSelesai   = data['target_anggota_selesai']  ?? 2;
          _chartTargetInspeksiSelesai  = data['target_inspeksi_selesai'] ?? 2;
          _chartTargetLokasi           = data['target_lokasi']           ?? 5;
          _chartTargetUnit             = data['target_unit']             ?? 5;
          _chartTargetSubunit          = data['target_subunit']          ?? 5;
          _chartTargetArea             = data['target_area']             ?? 5;
        } else {
          _targetAnggota = 0; _targetInspeksi = 0;
          _chartTargetTemuan = 0; _chartTargetPenyelesaian = 0;
          _chartTargetAnggotaSelesai = 0; _chartTargetInspeksiSelesai = 0;
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
          _targetAnggota               = daily['target_anggota']          ?? 2;
          _targetInspeksi              = daily['target_inspeksi']         ?? 2;
          _chartTargetTemuan           = daily['target_anggota']          ?? 2;
          _chartTargetPenyelesaian     = daily['target_inspeksi']         ?? 2;
          _chartTargetAnggotaSelesai   = daily['target_anggota_selesai']  ?? 2;
          _chartTargetInspeksiSelesai  = daily['target_inspeksi_selesai'] ?? 2;
          _chartTargetLokasi           = daily['target_lokasi']           ?? 5;
          _chartTargetUnit             = daily['target_unit']             ?? 5;
          _chartTargetSubunit          = daily['target_subunit']          ?? 5;
          _chartTargetArea             = daily['target_area']             ?? 5;
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
      _targetAnggota = 0; _targetInspeksi = 0;
      _chartTargetTemuan = 0; _chartTargetPenyelesaian = 0;
      _chartTargetAnggotaSelesai = 0; _chartTargetInspeksiSelesai = 0;
      _chartTargetLokasi = 0; _chartTargetUnit = 0;
      _chartTargetSubunit = 0; _chartTargetArea = 0;
    });
  }

  int get _selectedMonth => _selectedMonthIndex + 1;

  void _rebuildTabControllerIfNeeded(int newCount) {
    if (_currentTabCount == newCount) {
      _activeTabIndex = _tabController.index;
      return;
    }
    _activeTabIndex = 0;
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _tabController = TabController(length: newCount, vsync: this);
    _currentTabCount = newCount;
    _tabController.addListener(_onTabChanged);
  }

  void _fetchAllData({bool fromTabFilter = false}) {
    if (!fromTabFilter) {
      _isChartLoadingForTab = false;
    }

    _fetchTarget();

    final roleBackendValue = ['Eksekutif', 'Profesional', 'Visitor'][
        _translatedRoles.indexOf(_selectedInspectionRole).clamp(0, 2)];
    final levelBackendValue = ['Lokasi', 'Unit', 'Subunit', 'Area'][
        _translatedLocationLevels.indexOf(_selectedLocationLevel).clamp(0, 3)];

    const int newTabCount = 4;

    if (!fromTabFilter && _currentTabCount != newTabCount) {
      _activeTabIndex = 0;
    }

    _rebuildTabControllerIfNeeded(newTabCount);

    setState(() {
      _lastUpdated = DateTime.now();
      final month = _selectedMonth;
      final year = DateTime.now().year;

      if (_filterMode == 'daily' && _selectedDate != null) {
        _inspeksiFuture = _fetchInspeksiDataDaily(_selectedDate!, roleBackendValue);
        _lokasiFuture = _fetchLokasiDataDaily(_selectedDate!, levelBackendValue);
      } else {
        _inspeksiFuture = _fetchInspeksiData(month, year, roleBackendValue);
        _lokasiFuture = _fetchLokasiData(month, year, levelBackendValue);
        _auditLokasiFuture = _fetchLokasiAuditData(month, year, levelBackendValue);
      }
      _chartFuture = _fetchChartData(month, year);
      _chartRefreshKey++;
    });

    _membersTabKey.currentState?.fetchData(
      filterMode:         _filterMode,
      selectedMonthIndex: _selectedMonthIndex,
      selectedDate:       _selectedDate,
      selectedUnitId:     _selectedUnitId,
    );
  }

  void _onTabChanged() {
    if (!mounted) return;
    if (_tabController.indexIsChanging) return;
    final newIdx = _tabController.index;
    if (_activeTabIndex == newIdx) return;

    final month = _selectedMonth;
    final year = DateTime.now().year;

    setState(() {
      _isChartLoadingForTab = true;
      _activeTabIndex = newIdx;
    });

    Future.wait([
      _fetchChartData(month, year),
    ]).then((results) {
      if (!mounted) return;
      setState(() {
        _chartFuture = Future.value(results[0]);
        _chartRefreshKey++;
        _isChartLoadingForTab = false;
        if (newIdx == 3) {
          _recurringTabKey.currentState?.refresh();
        }
      });
    });
  }

  (int temuan, int selesai) get _activeTabTargets {
    final bool isHolidayOrWeekend = _filterMode == 'daily' &&
        _selectedDate != null &&
        (_targetAnggota == 0 && _targetInspeksi == 0);

    switch (_activeTabIndex) {
      case 0:
        if (isHolidayOrWeekend) return (0, 0);
        return (_chartTargetTemuan, _chartTargetAnggotaSelesai);
      case 1:
        if (isHolidayOrWeekend) return (0, 0);
        return (_chartTargetPenyelesaian, _chartTargetInspeksiSelesai);
      case 2:
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
      default:
        return (0, 0);
    }
  }

  Future<List<InspectionData5R>> _fetchInspeksiData(int month, int year, String role) async {
    try {
      final roleCol = role == 'Eksekutif' ? 'is_eksekutif'
          : role == 'Profesional' ? 'is_pro'
          : 'is_visitor';

      final List<dynamic> temuanRes = await _supabase
          .from('temuan')
          .select('id_user, User_Creator:User!temuan_id_user_fkey(nama)')
          .neq('jenis_temuan', 'KTS Production')
          .eq(roleCol, true)
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at', DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String());

      final Map<String, Map<String, dynamic>> grouped = {};
      for (final item in temuanRes) {
        final user = item['User_Creator'] as Map<String, dynamic>?;
        if (user == null) continue;
        final userId = item['id_user']?.toString() ?? '';
        if (userId.isEmpty) continue;
        grouped.putIfAbsent(userId, () => {'nama': user['nama'] ?? '-', 'temuan': 0});
        grouped[userId]!['temuan'] = (grouped[userId]!['temuan'] as int) + 1;
      }

      return grouped.values
          .map((item) => InspectionData5R(
                name: item['nama'] as String,
                findings: item['temuan'] as int,
              ))
          .toList()
        ..sort((a, b) {
          final c = b.findings.compareTo(a.findings);
          return c != 0 ? c : a.name.compareTo(b.name);
        });
    } catch (e) {
      debugPrint('Error fetching Inspeksi: $e');
      return [];
    }
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

      final List<dynamic> locations = await _supabase
          .from(levelLower)
          .select('$idCol, $nameCol');

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

      final List<dynamic> locations = await _supabase.from(levelLower)
          .select('$idCol, $nameCol, id_pic');

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

  Future<List<InspectionData5R>> _fetchInspeksiDataDaily(DateTime date, String role) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final roleCol = role == 'Eksekutif' ? 'is_eksekutif'
          : role == 'Profesional' ? 'is_pro'
          : 'is_visitor';

      final List<dynamic> temuanRes = await _supabase
          .from('temuan')
          .select('id_user, User_Creator:User!temuan_id_user_fkey(nama)')
          .neq('jenis_temuan', 'KTS Production')
          .eq(roleCol, true)
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());

      final Map<String, Map<String, dynamic>> grouped = {};
      for (final item in temuanRes) {
        final user = item['User_Creator'] as Map<String, dynamic>?;
        if (user == null) continue;
        final userId = item['id_user']?.toString() ?? '';
        if (userId.isEmpty) continue;
        grouped.putIfAbsent(userId, () => {'nama': user['nama'] ?? '-', 'temuan': 0});
        grouped[userId]!['temuan'] = (grouped[userId]!['temuan'] as int) + 1;
      }

      return grouped.values
          .map((item) => InspectionData5R(
                name: item['nama'] as String,
                findings: item['temuan'] as int,
              ))
          .toList()
        ..sort((a, b) {
          final c = b.findings.compareTo(a.findings);
          return c != 0 ? c : a.name.compareTo(b.name);
        });
    } catch (e) {
      debugPrint('Error fetching Inspeksi daily: $e');
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

      final List<dynamic> locations = await _supabase
          .from(levelLower)
          .select('$idCol, $nameCol');

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

      if (_activeTabIndex == 3) return [];

      // TAB 0: MEMBERS
      if (_activeTabIndex == 0) {
        var query = _supabase
            .from('temuan')
            .select('created_at, id_penyelesaian, id_user')
            .neq('jenis_temuan', 'KTS Production')
            .gte('created_at', startDt.toIso8601String())
            .lte('created_at', endDt.toIso8601String());

        if (_selectedUnitId != null) {
          final List<dynamic> usersInUnit = await _supabase
              .from('User')
              .select('id_user')
              .eq('id_unit', _selectedUnitId!);
          final userIds = usersInUnit.map((u) => u['id_user'].toString()).toList();
          if (userIds.isEmpty) {
            return isDaily
                ? [_ChartBarData(date: _selectedDate!.day, temuan: 0, penyelesaian: 0)]
                : List.generate(daysInMonth, (i) => _ChartBarData(date: i + 1, temuan: 0, penyelesaian: 0));
          }
          query = query.inFilter('id_user', userIds);
        }

        final List<dynamic> res = await query;
        return buildDailyFromTemuan(res);
      }

      // TAB 1: INSPECTION
      if (_activeTabIndex == 1) {
        final roleBackend = ['Eksekutif', 'Profesional', 'Visitor'][
            _translatedRoles.indexOf(_selectedInspectionRole).clamp(0, 2)];

        var query = _supabase
            .from('temuan')
            .select('created_at, id_penyelesaian')
            .neq('jenis_temuan', 'KTS Production')
            .gte('created_at', startDt.toIso8601String())
            .lte('created_at', endDt.toIso8601String());

        if (roleBackend == 'Eksekutif') {
          query = query.eq('is_eksekutif', true);
        } else if (roleBackend == 'Profesional') {
          query = query.eq('is_pro', true);
        } else {
          query = query.eq('is_visitor', true);
        }

        final List<dynamic> res = await query;
        return buildDailyFromTemuan(res);
      }

      // TAB 2: LOCATION
      if (!isDaily) {
        final levelBackend = ['lokasi', 'unit', 'subunit', 'area'][
            _translatedLocationLevels.indexOf(_selectedLocationLevel).clamp(0, 3)];
        final List<dynamic> auditRes = await _supabase
            .from('audit_result')
            .select('tanggal_audit, nilai_audit')
            .eq('level_type', levelBackend)
            .gte('tanggal_audit', startOfMonth.toIso8601String().split('T').first)
            .lte('tanggal_audit', endOfMonth.toIso8601String().split('T').first);

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
      final List<dynamic> res = await _supabase
          .from('temuan')
          .select('created_at, id_penyelesaian, $idCol')
          .neq('jenis_temuan', 'KTS Production')
          .gte('created_at', startDt.toIso8601String())
          .lte('created_at', endDt.toIso8601String())
          .not(idCol, 'is', null);
      return buildDailyFromTemuan(res);
    } catch (e) {
      debugPrint('Error fetching chart data: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  String get _lastUpdatedText {
    if (_lastUpdated == null) return getTxt('memuat_data');
    final formattedDate = DateFormat('d MMM yyyy HH:mm',
        widget.lang == 'ID' ? 'id_ID' : 'en_US').format(_lastUpdated!);
    return '${getTxt('diperbarui_pada')} $formattedDate (GMT+7)';
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildTabBar(),
      _buildConditionalChart(),
      Expanded(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildAnggotaTab(),
            _buildInspeksiTab(),
            _buildLokasiTab(),
            _buildTemuanBerulangTab(),
          ],
        ),
      ),
    ]);
  }

  // TAB BAR
  Widget _buildTabBar() {
    final tabLabels = [getTxt('anggota'), getTxt('inspeksi'), getTxt('lokasi'), getTxt('temuan_berulang')];
    const activeColor = _AppColors.primary;

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(3),
        child: TabBar(
          controller: _tabController,
          isScrollable: tabLabels.length > 4,
          tabAlignment: tabLabels.length > 4 ? TabAlignment.center : TabAlignment.fill,
          indicator: BoxDecoration(
            color: activeColor,
            borderRadius: BorderRadius.circular(8),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: activeColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5),
          dividerColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: tabLabels.map((t) => Tab(child: Text(t))).toList(),
        ),
      ),
    );
  }

  // CONDITIONAL CHART
  Widget _buildConditionalChart() {
    if (_activeTabIndex == 3) return const SizedBox.shrink();
    if (_isChartLoadingForTab) return _buildChartShimmerSmall();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: KeyedSubtree(
        key: ValueKey('collapsible-5R-$_activeTabIndex'),
        child: _buildCollapsibleChart(),
      ),
    );
  }

  Widget _buildChartShimmerSmall() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        height: 158,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // COLLAPSIBLE BAR CHART
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
            border: Border.all(color: activeColor.withOpacity(0.4), width: 1.2),
            boxShadow: [BoxShadow(color: activeColor.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))],
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
                key: ValueKey('chart-$_chartRefreshKey-5R-$_activeTabIndex'),
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

                  final (tTarget, pTarget) = _activeTabTargets;
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

                  final bool isLocationAuditTab = _activeTabIndex == 2
                      && !(_filterMode == 'daily' && _selectedDate != null);

                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.fromLTRB(0, 12, 8, 8),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _AppColors.primaryLight),
                      boxShadow: [BoxShadow(color: activeColor.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // LEGEND
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
                                if (_activeTabIndex != 3 && tTarget > 0)
                                  _chartLegendDash(
                                    const Color(0xFFEF4444),
                                    _activeTabIndex == 0
                                        ? (widget.lang == 'ID' ? 'Target Anggota' : widget.lang == 'ZH' ? '成员目标' : 'Member Target')
                                        : _activeTabIndex == 1
                                            ? (widget.lang == 'ID' ? 'Target Inspeksi' : widget.lang == 'ZH' ? '检查目标' : 'Inspection Target')
                                            : (widget.lang == 'ID' ? 'Target Lokasi' : widget.lang == 'ZH' ? '位置目标' : 'Location Target'),
                                  ),
                                if (_activeTabIndex != 3 && pTarget > 0)
                                  _chartLegendDash(
                                    const Color(0xFFF59E0B),
                                    _activeTabIndex == 0
                                        ? (widget.lang == 'ID' ? 'Target Anggota Selesai' : widget.lang == 'ZH' ? '成员完成目标' : 'Member Completion Target')
                                        : _activeTabIndex == 1
                                            ? (widget.lang == 'ID' ? 'Target Inspeksi Selesai' : widget.lang == 'ZH' ? '检查完成目标' : 'Inspection Completion Target')
                                            : (widget.lang == 'ID' ? 'Target Selesai' : widget.lang == 'ZH' ? '完成目标' : 'Completion Target'),
                                  ),
                              ]),
                      ),

                      // CHART AREA
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

                          // PLOT AREA
                          Expanded(child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: math.max(data.length * barGroupW + 8, 40),
                              child: Stack(children: [
                                ...yLabels.map((v) => Positioned(
                                  top: valToY(v), left: 0, right: 0,
                                  child: Container(height: 1, color: _AppColors.divider),
                                )),

                                // TARGET LINE
                                if (_activeTabIndex != 3 && tTarget > 0)
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

                                // CHART BAR
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

  // MEMBERS TAB
  Widget _buildAnggotaTab() {
    return FiveRMembersTab(
      key:                  _membersTabKey,
      lang:                 widget.lang,
      filterMode:           _filterMode,
      selectedMonthIndex:   _selectedMonthIndex,
      selectedDate:         _selectedDate,
      selectedUnitId:       _selectedUnitId,
      unitList:             _unitList,
      targetAnggota:        _targetAnggota,
      targetAnggotaSelesai: _chartTargetAnggotaSelesai,
      lastUpdatedText:      _lastUpdatedText,
      getTxt:               getTxt,
      buildFilterBtn: ({
        required String    label,
        required VoidCallback onTap,
        IconData           icon     = Icons.keyboard_arrow_down_rounded,
        bool               isActive = false,
      }) =>
          _buildFilterButton(
              label: label, onTap: onTap, icon: icon, isActive: isActive),
      showMonthPicker: (_) => _showMonthPicker(
        () => _fetchAllData(fromTabFilter: true),
      ),
      showGroupPicker: _showGroupPicker,
    );
  }

  // INSPECTION TAB
  Widget _buildInspeksiTab() {
    return FiveRInspectionTab(
      lang: widget.lang,
      filterMode: _filterMode,
      selectedMonthIndex: _selectedMonthIndex,
      selectedDate: _selectedDate,
      targetInspeksi: _targetInspeksi,
      lastUpdatedText: _lastUpdatedText,
      getTxt: getTxt,
      translatedMonths: _translatedMonths,
      translatedRoles: _translatedRoles,
      selectedInspectionRole: _selectedInspectionRole,
      inspeksiFuture: _inspeksiFuture,
      buildFilterBtn: _buildFilterButton,
      showMonthPicker: (_) => _showMonthPicker(
        () => _fetchAllData(fromTabFilter: true),
      ),
      onRoleChanged: (role) {
        setState(() => _selectedInspectionRole = role);
        _fetchAllData(fromTabFilter: true);
      },
    );
  }

  // LOCATION TAB
  Widget _buildLokasiTab() {
    return FiveRLocationTab(
      lang: widget.lang,
      filterMode: _filterMode,
      selectedMonthIndex: _selectedMonthIndex,
      selectedDate: _selectedDate,
      selectedLocationLevel: _selectedLocationLevel,
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
      onRefresh: () => _fetchAllData(fromTabFilter: true),
      onAuditLocationTap: (loc) => _showAuditLocationDetail(loc),
    );
  }

  // RECURRING FINDINGS TAB
  Widget _buildTemuanBerulangTab() {
    return FiveRRecurringTab(
      key: _recurringTabKey,
      lang: widget.lang,
      getTxt: getTxt,
      buildFilterBtn: _buildFilterButton,
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

  // FILTER BUTTON
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
              color: _AppColors.primary.withOpacity(0.10), blurRadius: 6, offset: const Offset(0, 2))],
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

  void _showMonthPicker(VoidCallback onChanged) async {
    String tempMode = _filterMode;
    int tempMonthIndex = _selectedMonthIndex;
    DateTime tempDate = _selectedDate ?? DateTime.now();

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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _AppColors.textPrimary))),
                  IconButton(icon: const Icon(Icons.close, size: 18, color: _AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Container(
                  decoration: BoxDecoration(color: _AppColors.surface,
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
                            color: isSel ? _AppColors.primary : _AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel ? _AppColors.primary : _AppColors.divider,
                              width: isSel ? 1.5 : 1),
                            boxShadow: isSel ? [BoxShadow(
                              color: _AppColors.primary.withOpacity(0.3),
                              blurRadius: 6, offset: const Offset(0, 2))] : []),
                          child: Center(child: Text(_translatedMonths[i], style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            color: isSel ? Colors.white : _AppColors.textPrimary))),
                        ),
                      );
                    },
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: _buildDailyCalendar(tempDate,
                    (picked) => setSt(() => tempDate = picked),
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

  Widget _buildDailyCalendar(DateTime selectedDate, ValueChanged<DateTime> onDateChanged,
      {required VoidCallback onConfirm}) {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstWeekday = DateTime(year, month, 1).weekday % 7;
    final locale = widget.lang == 'ID' ? 'id_ID' : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');
    final monthLabel = DateFormat('MMMM yyyy', locale).format(DateTime(year, month));
    final dayLabels = widget.lang == 'ZH'
        ? ['日', '一', '二', '三', '四', '五', '六']
        : widget.lang == 'ID'
            ? ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
            : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return StatefulBuilder(
      builder: (_, setInner) => Column(children: [
        Text(monthLabel, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: _AppColors.textPrimary)),
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
                      : isFuture ? _AppColors.textMuted : _AppColors.textPrimary))),
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

  void _showGroupPicker() async {
    final allItem = {'id_unit': null, 'nama_unit': getTxt('semua_grup_anggota')};
    final items = [allItem, ..._unitList];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          final ctrl = TextEditingController();
          List<Map<String, dynamic>> filtered = List.from(items);

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
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
                    const Icon(Icons.group_rounded, color: _AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(getTxt('pilih_grup'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _AppColors.textPrimary))),
                    IconButton(icon: const Icon(Icons.close, size: 18, color: _AppColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: StatefulBuilder(
                    builder: (_, setInner) => TextField(
                      controller: ctrl,
                      onChanged: (q) {
                        setInner(() {
                          filtered = items.where((e) =>
                            (e['nama_unit'] as String).toLowerCase().contains(q.toLowerCase())).toList();
                        });
                        setSt(() {});
                      },
                      decoration: InputDecoration(
                        hintText: getTxt('cari'),
                        hintStyle: const TextStyle(fontSize: 13, color: _AppColors.textMuted),
                        prefixIcon: const Icon(Icons.search, color: _AppColors.primary, size: 18),
                        filled: true, fillColor: _AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: _AppColors.divider)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: _AppColors.divider)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: _AppColors.primary, width: 1.5)),
                      ),
                    ),
                  ),
                ),
                Flexible(child: StatefulBuilder(
                  builder: (_, __) => ListView.builder(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final item = filtered[i];
                      final lbl = item['nama_unit'] as String;
                      final id = item['id_unit']?.toString();
                      final isSelected = id == _selectedUnitId || (id == null && _selectedUnitId == null);
                      return InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() => _selectedUnitId = id);
                          _fetchAllData(fromTabFilter: true);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? _AppColors.primaryLight : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? _AppColors.primary : _AppColors.divider,
                              width: isSelected ? 1.5 : 1)),
                          child: Row(children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: isSelected ? _AppColors.primary : _AppColors.surface,
                                borderRadius: BorderRadius.circular(10)),
                              child: Center(child: Text(
                                lbl.isNotEmpty ? lbl[0].toUpperCase() : '?',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                                    color: isSelected ? Colors.white : _AppColors.primary))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(lbl, style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? _AppColors.primary : _AppColors.textPrimary))),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, color: _AppColors.primary, size: 18),
                          ]),
                        ),
                      );
                    },
                  ),
                )),
              ]),
            ),
          );
        },
      ),
    );
  }

  void _showLevelPicker() async {
    await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
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
                const Icon(Icons.tune_rounded, color: _AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(getTxt('pilih_level'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _AppColors.textPrimary))),
                IconButton(icon: const Icon(Icons.close, size: 18, color: _AppColors.textSecondary),
                  onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
              ]),
            ),
            Flexible(child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: _translatedLocationLevels.length,
              itemBuilder: (_, i) {
                final lbl = _translatedLocationLevels[i];
                final isSel = lbl == _selectedLocationLevel;
                return InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _selectedLocationLevel = lbl);
                    _fetchAllData(fromTabFilter: true);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? _AppColors.primaryLight : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSel ? _AppColors.primary : _AppColors.divider, width: 1)),
                    child: Row(children: [
                      Expanded(child: Text(lbl, style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        color: isSel ? _AppColors.primary : _AppColors.textPrimary))),
                      if (isSel) const Icon(Icons.check_circle_rounded, color: _AppColors.primary, size: 16),
                    ]),
                  ),
                );
              },
            )),
          ]),
        ),
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