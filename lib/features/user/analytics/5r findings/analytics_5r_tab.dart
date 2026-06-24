import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/services/gemini_recurring_service.dart';
import '../../finding/finding_detail_screen.dart';
import '../../home/kts_finding_card.dart';

// ─── Warna & Tema ──────────────────────────────────────────────────────────
class _AppColors {
  static const primary = Color(0xFF0EA5E9);
  static const primaryDark = Color(0xFF0369A1);
  static const primaryLight = Color(0xFFE0F2FE);
  static const surface = Color(0xFFF0F9FF);
  static const textPrimary = Color(0xFF0C4A6E);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFFBDBDBD);
  static const divider = Color(0xFFE0F2FE);
  static const selfHighlight = Color(0xFFFFF7ED);
  static const selfHighlightBorder = Color(0xFFFED7AA);
}

// ─── Model Data ──────────────────────────────────────────────────────────────
class MemberData5R {
  final String name;
  final String? unitName;
  final int findings;
  final int completed;
  final bool isSelf;
  final String? avatarUrl;
  final Color? avatarColor;

  const MemberData5R({
    required this.name,
    this.unitName,
    required this.findings,
    required this.completed,
    this.isSelf = false,
    this.avatarUrl,
    this.avatarColor,
  });
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

class LocationData5R {
  final String name;
  final String pic;
  final String? value;

  const LocationData5R({
    required this.name,
    required this.pic,
    this.value,
  });
}

class AuditLocationData5R {
  final String id;
  final String name;
  final String pic;
  final double? auditScore;
  final String? auditDate;
  final String? auditPeriod;

  const AuditLocationData5R({
    required this.id,
    required this.name,
    required this.pic,
    this.auditScore,
    this.auditDate,
    this.auditPeriod,
  });
}

class RecurringTopic5R {
  final String topic;
  final String locationArea;
  final int total;
  final String? imageUrl;
  final List<Map<String, dynamic>> findings;

  const RecurringTopic5R({
    required this.topic,
    required this.locationArea,
    required this.total,
    this.imageUrl,
    required this.findings,
  });
}

class _ChartBarData {
  final int date;
  final int temuan;
  final int penyelesaian;
  _ChartBarData({required this.date, required this.temuan, required this.penyelesaian});
}

// ─── Main Widget ──────────────────────────────────────────────────────────────
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

  // ─── State untuk Filter ──────────────────────────────────────────────────
  int _selectedMonthIndex = DateTime.now().month - 1;
  String _filterMode = 'monthly';
  DateTime? _selectedDate;
  String? _selectedUnitId;
  String _selectedInspectionRole = 'Eksekutif';
  String _selectedLocationLevel = 'Lokasi';
  DateTime? _lastUpdated;
  int _chartRefreshKey = 0;

  // Recurring findings filter
  DateTime _recurringFrom = DateTime(DateTime.now().year - 1, DateTime.now().month);
  DateTime _recurringTo = DateTime.now();
  String? _recurringUserId;
  String _recurringUserName = '';

  // ─── Chart collapse state ─────────────────────────────────────────────────
  bool _isChartExpanded = false;
  int _currentTabCount = 4;

  // ─── Shimmer state untuk chart per-tab ────────────────────────────────────
  bool _isChartLoadingForTab = false;

  // ─── Chart data ───────────────────────────────────────────────────────────
  Future<List<_ChartBarData>>? _chartFuture;
  int _chartTargetTemuan       = 2;
  int _chartTargetPenyelesaian = 2;
  int _chartTargetLokasi       = 5;
  int _chartTargetUnit         = 5;
  int _chartTargetSubunit      = 5;
  int _chartTargetArea         = 5;
  int _activeTabIndex = 0;

  // ─── State untuk Data ────────────────────────────────────────────────────
  Future<List<MemberData5R>>? _anggotaFuture;
  Future<List<InspectionData5R>>? _inspeksiFuture;
  Future<List<LocationData5R>>? _lokasiFuture;
  Future<List<AuditLocationData5R>>? _auditLokasiFuture;
  Future<List<RecurringTopic5R>>? _recurringFuture;

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
      final data = await _supabase
          .from('target_bulanan')
          .select()
          .eq('bulan', month)
          .eq('tahun', year)
          .maybeSingle();
      if (mounted && data != null) {
        setState(() {
          _targetAnggota  = data['target_anggota']  ?? 2;
          _targetInspeksi = data['target_inspeksi'] ?? 2;
          _chartTargetTemuan       = data['target_anggota']  ?? 2;
          _chartTargetPenyelesaian = data['target_inspeksi'] ?? 2;
          _chartTargetLokasi       = data['target_lokasi']   ?? 5;
          _chartTargetUnit         = data['target_unit']     ?? 5;
          _chartTargetSubunit      = data['target_subunit']  ?? 5;
          _chartTargetArea         = data['target_area']     ?? 5;
        });
      }
    } catch (e) {
      debugPrint('Error fetching target: $e');
    }
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
        _anggotaFuture = _fetchAnggotaDataDaily(_selectedDate!, _selectedUnitId);
        _inspeksiFuture = _fetchInspeksiDataDaily(_selectedDate!, roleBackendValue);
        _lokasiFuture = _fetchLokasiDataDaily(_selectedDate!, levelBackendValue);
      } else {
        _anggotaFuture = _fetchAnggotaData(month, year, _selectedUnitId);
        _inspeksiFuture = _fetchInspeksiData(month, year, roleBackendValue);
        _lokasiFuture = _fetchLokasiData(month, year, levelBackendValue);
        _auditLokasiFuture = _fetchLokasiAuditData(month, year, levelBackendValue);
      }
      _chartFuture = _fetchChartData(month, year);
      _chartRefreshKey++;
      _recurringFuture = _fetchRecurringData();
    });
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

        final bool isRecurringTab = newIdx == 3;
        if (isRecurringTab) {
          if (_recurringFuture == null) {
            _recurringFuture = _fetchRecurringData();
          }
        }
      });
    });
  }

  (int temuan, int selesai) get _activeTabTargets {
    switch (_activeTabIndex) {
      case 0:
        return (_chartTargetTemuan, _chartTargetTemuan);
      case 1:
        return (_chartTargetPenyelesaian, _chartTargetPenyelesaian);
      case 2:
        final levelLower = ['Lokasi', 'Unit', 'Subunit', 'Area']
            [_translatedLocationLevels.indexOf(_selectedLocationLevel).clamp(0, 3)];
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

  void _fetchRecurring() {
    setState(() {
      _recurringFuture = _fetchRecurringData();
      final month = _selectedMonth;
      final year = DateTime.now().year;
      _chartFuture = _fetchChartData(month, year);
      _chartRefreshKey++;
    });
  }

  // ─── Data Fetchers ────────────────────────────────────────────────────────

  Future<List<MemberData5R>> _fetchAnggotaData(int month, int year, String? unitId) async {
    try {
      var userQuery = _supabase
          .from('User')
          .select('id_user, nama, gambar_user, id_unit, unit!user_id_unit_fkey(nama_unit)');
      if (unitId != null) userQuery = userQuery.eq('id_unit', unitId);
      final List<dynamic> users = await userQuery;
      if (users.isEmpty) return [];

      final userIds = users.map((u) => u['id_user'].toString()).toList();

      final List<dynamic> temuanRes = await _supabase
          .from('temuan')
          .select('id_user, id_penyelesaian')
          .neq('jenis_temuan', 'KTS Production')
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at', DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String())
          .inFilter('id_user', userIds);

      final Map<String, Map<String, int>> stats = {};
      for (final t in temuanRes) {
        final uid = t['id_user']?.toString() ?? '';
        if (uid.isEmpty) continue;
        stats.putIfAbsent(uid, () => {'temuan': 0, 'selesai': 0});
        stats[uid]!['temuan'] = stats[uid]!['temuan']! + 1;
        if (t['id_penyelesaian'] != null) {
          stats[uid]!['selesai'] = stats[uid]!['selesai']! + 1;
        }
      }

      final currentUserId = _supabase.auth.currentUser?.id;
      final result = users.map((u) {
        final uid = u['id_user']?.toString() ?? '';
        final s = stats[uid] ?? {'temuan': 0, 'selesai': 0};
        return MemberData5R(
          name: u['nama'] as String? ?? '-',
          unitName: (u['unit'] as Map<String, dynamic>?)?['nama_unit'] as String?,
          findings: s['temuan']!,
          completed: s['selesai']!,
          isSelf: uid == currentUserId,
          avatarUrl: u['gambar_user'] as String?,
          avatarColor: const Color(0xFF0EA5E9),
        );
      }).toList()
        ..sort((a, b) {
          final c = b.findings.compareTo(a.findings);
          return c != 0 ? c : a.name.compareTo(b.name);
        });
      return result;
    } catch (e) {
      debugPrint('Error fetching Anggota: $e');
      return [];
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

  Future<List<MemberData5R>> _fetchAnggotaDataDaily(DateTime date, String? unitId) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

      var userQuery = _supabase
          .from('User')
          .select('id_user, nama, gambar_user, id_unit, unit!user_id_unit_fkey(nama_unit)');
      if (unitId != null) userQuery = userQuery.eq('id_unit', unitId);
      final List<dynamic> users = await userQuery;
      if (users.isEmpty) return [];

      final userIds = users.map((u) => u['id_user'].toString()).toList();

      final List<dynamic> temuanRes = await _supabase
          .from('temuan')
          .select('id_user, id_penyelesaian')
          .neq('jenis_temuan', 'KTS Production')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .inFilter('id_user', userIds);

      final Map<String, Map<String, int>> stats = {};
      for (final t in temuanRes) {
        final uid = t['id_user']?.toString() ?? '';
        if (uid.isEmpty) continue;
        stats.putIfAbsent(uid, () => {'temuan': 0, 'selesai': 0});
        stats[uid]!['temuan'] = stats[uid]!['temuan']! + 1;
        if (t['id_penyelesaian'] != null) {
          stats[uid]!['selesai'] = stats[uid]!['selesai']! + 1;
        }
      }

      final currentUserId = _supabase.auth.currentUser?.id;
      return users
          .where((u) => stats.containsKey(u['id_user']?.toString() ?? ''))
          .map((u) {
            final uid = u['id_user']?.toString() ?? '';
            final s = stats[uid]!;
            return MemberData5R(
              name: u['nama'] as String? ?? '-',
              unitName: (u['unit'] as Map<String, dynamic>?)?['nama_unit'] as String?,
              findings: s['temuan']!,
              completed: s['selesai']!,
              isSelf: uid == currentUserId,
              avatarUrl: u['gambar_user'] as String?,
              avatarColor: const Color(0xFF0EA5E9),
            );
          })
          .toList()
          ..sort((a, b) {
            final c = b.findings.compareTo(a.findings);
            return c != 0 ? c : a.name.compareTo(b.name);
          });
    } catch (e) {
      debugPrint('Error fetching Anggota daily: $e');
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

      DateTime startDt, endDt;
      bool isDaily = _filterMode == 'daily' && _selectedDate != null;
      if (isDaily) {
        startDt = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
        endDt = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 23, 59, 59);
      } else {
        startDt = startOfMonth;
        endDt = endOfMonth;
      }

      List<_ChartBarData> buildDailyFromTemuan(List<dynamic> res) {
        if (isDaily) {
          return [_ChartBarData(
            date: _selectedDate!.day,
            temuan: res.length,
            penyelesaian: res.where((t) => t['id_penyelesaian'] != null).length,
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

      // Tab 3 = Recurring — chart hidden
      if (_activeTabIndex == 3) return [];

      // Tab 0: Members
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
            return List.generate(isDaily ? 1 : daysInMonth,
                (i) => _ChartBarData(date: isDaily ? _selectedDate!.day : i + 1, temuan: 0, penyelesaian: 0));
          }
          query = query.inFilter('id_user', userIds);
        }

        final List<dynamic> res = await query;
        return buildDailyFromTemuan(res);
      }

      // Tab 1: Inspection
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

      // Tab 2: Location
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
          final dt = DateTime.tryParse(a['tanggal_audit']?.toString() ?? '');
          if (dt == null) continue;
          final score = double.tryParse(a['nilai_audit']?.toString() ?? '');
          if (score == null) continue;
          dayScores.putIfAbsent(dt.day, () => []).add(score);
        }
        return List.generate(daysInMonth, (i) {
          final day = i + 1;
          final scores = dayScores[day] ?? [];
          final avg = scores.isEmpty
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
      final idCol = idColMap[levelBackend] ?? 'id_lokasi';
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

  Future<List<RecurringTopic5R>> _fetchRecurringData() async {
    try {
      var query = _supabase
          .from('temuan')
          .select('''
            id_temuan, judul_temuan, gambar_temuan, created_at, status_temuan,
            poin_temuan, target_waktu_selesai, jenis_temuan,
            id_lokasi, id_unit, id_subunit, id_area, id_penanggung_jawab, id_user,
            lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area),
            kategoritemuan(nama_kategoritemuan),
            is_pro, is_visitor, is_eksekutif, no_order, jumlah_item,
            penyelesaian!temuan_id_penyelesaian_fkey(*, User_Solver:User!id_user(nama, gambar_user)),
            User_Creator:User!temuan_id_user_fkey(nama, gambar_user),
            User_PIC:User!temuan_id_penanggung_jawab_fkey(nama, gambar_user),
            subkategoritemuan:id_subkategoritemuan_uuid(id_subkategoritemuan, nama_subkategoritemuan)
          ''')
          .neq('jenis_temuan', 'KTS Production')
          .gte('created_at', _recurringFrom.toIso8601String())
          .lte('created_at', DateTime(
              _recurringTo.year, _recurringTo.month + 1, 0, 23, 59, 59)
              .toIso8601String());

      if (_recurringUserId != null) {
        query = query.eq('id_user', _recurringUserId!);
      }

      final List<dynamic> response =
          await query.order('created_at', ascending: false);
      final findings = List<Map<String, dynamic>>.from(response);
      if (findings.isEmpty) return [];

      final groups = await GeminiRecurringService.instance.analyzeFindings(
        findings,
        isKts: false,
        fromDate: _recurringFrom,
        toDate: _recurringTo,
        filterUserId: _recurringUserId,
      );

      return groups.map((g) => RecurringTopic5R(
        topic: g.topic,
        locationArea: g.locationArea,
        total: g.total,
        imageUrl: g.imageUrl,
        findings: g.findings,
      )).toList();
    } catch (e) {
      debugPrint('Error fetching Recurring: $e');
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

  // ─── BUILD ────────────────────────────────────────────────────────────────

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

  // ─── Tab Bar ──────────────────────────────────────────────────────────────
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

  // ─── Conditional Chart ────────────────────────────────────────────────────
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

  // ─── Collapsible Bar Chart ────────────────────────────────────────────────
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
                  final data = snapshot.data ?? [];
                  if (data.isEmpty || data.every((d) => d.temuan == 0 && d.penyelesaian == 0)) {
                    return Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _AppColors.primaryLight)),
                      child: Center(child: Text(
                        widget.lang == 'ID' ? 'Tidak ada data grafik'
                            : widget.lang == 'ZH' ? '暂无图表数据' : 'No chart data',
                        style: const TextStyle(color: _AppColors.textSecondary, fontSize: 13),
                      )),
                    );
                  }

                  final (tTarget, pTarget) = _activeTabTargets;
                  int maxVal = math.max(tTarget, pTarget).clamp(1, 99999);
                  for (final d in data) {
                    if (d.temuan > maxVal) maxVal = d.temuan;
                    if (d.penyelesaian > maxVal) maxVal = d.penyelesaian;
                  }
                  maxVal = ((maxVal / 5).ceil() * 5).clamp(1, 9999);

                  const double chartH = 140.0;
                  const double barGroupW = 28.0;
                  const double barW = 8.0;
                  const double leftW = 28.0;

                  double valToY(int v) => chartH - (v / maxVal * chartH).clamp(0.0, chartH);
                  final yStep = (maxVal / 4).ceil().clamp(1, 99999);
                  final yLabels = List.generate(5, (i) => i * yStep);

                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.fromLTRB(0, 12, 8, 8),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _AppColors.primaryLight),
                      boxShadow: [BoxShadow(color: activeColor.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 32, bottom: 8),
                        child: Builder(builder: (ctx) {
                          final bool isLocationAuditTab = _activeTabIndex == 2
                              && !(_filterMode == 'daily' && _selectedDate != null);

                          if (isLocationAuditTab) {
                            return Wrap(spacing: 12, children: [
                              _chartLegendItem(colorTemuan,
                                widget.lang == 'ID' ? 'Rata-rata Nilai Audit'
                                    : widget.lang == 'ZH' ? '平均审计分数'
                                    : 'Avg Audit Score'),
                            ]);
                          }

                          return Wrap(spacing: 12, children: [
                            _chartLegendItem(colorTemuan,
                              widget.lang == 'ID' ? 'Temuan' : 'Findings'),
                            _chartLegendItem(colorPenyelesaian,
                              widget.lang == 'ID' ? 'Selesai' : 'Completed'),
                            if (_activeTabIndex != 3) ...[
                              _chartLegendDash(const Color(0xFFEF4444),
                                _activeTabIndex == 0
                                    ? (widget.lang == 'ID' ? 'Target Anggota' : 'Member Target')
                                    : _activeTabIndex == 1
                                        ? (widget.lang == 'ID' ? 'Target Inspeksi' : 'Inspection Target')
                                        : (widget.lang == 'ID' ? 'Target Lokasi' : 'Location Target')),
                              _chartLegendDash(const Color(0xFFF59E0B),
                                widget.lang == 'ID' ? 'Target Selesai' : 'Completion Target'),
                            ],
                          ]);
                        }),
                      ),
                      SizedBox(
                        height: chartH + 28,
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          SizedBox(
                            width: leftW,
                            height: chartH,
                            child: Stack(children: yLabels.map((v) {
                              final yPos = valToY(v);
                              if (yPos < 0 || yPos > chartH) return const SizedBox.shrink();
                              return Positioned(
                                top: yPos - 7, right: 2,
                                child: Text(
                                  v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '$v',
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                                      color: _AppColors.textSecondary),
                                ),
                              );
                            }).toList()),
                          ),
                          Expanded(child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: data.length * barGroupW + 8,
                              child: Stack(children: [
                                ...yLabels.map((v) => Positioned(
                                  top: valToY(v), left: 0, right: 0,
                                  child: Container(height: 1, color: _AppColors.divider),
                                )),
                                Builder(builder: (context) {
                                  final (tTarget, pTarget) = _activeTabTargets;
                                  final showTarget = _activeTabIndex != 3 && tTarget > 0;
                                  if (!showTarget) return const SizedBox.shrink();
                                  return Stack(children: [
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
                                  ]);
                                }),
                                ...data.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final d = entry.value;
                                  final x = i * barGroupW + 4.0;
                                  final tH = (d.temuan / maxVal * chartH).clamp(0.0, chartH);
                                  final pH = (d.penyelesaian / maxVal * chartH).clamp(0.0, chartH);

                                  final dateLabel = DateFormat('d/M',
                                    widget.lang == 'ID' ? 'id_ID' : 'en_US',
                                  ).format(DateTime(DateTime.now().year, _selectedMonthIndex + 1, d.date));

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

  // ─── Anggota Tab ──────────────────────────────────────────────────────────
  Widget _buildAnggotaTab() {
    return Column(children: [
      Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          _buildFilterButton(
            label: _filterMode == 'daily' && _selectedDate != null
                ? DateFormat('d MMM yyyy',
                    widget.lang == 'ID' ? 'id_ID' : widget.lang == 'EN' ? 'en_US' : 'zh_CN')
                    .format(_selectedDate!)
                : _translatedMonths[_selectedMonthIndex],
            isActive: true,
            onTap: () => _showMonthPicker(() => _fetchAllData(fromTabFilter: true)),
          ),
          const SizedBox(width: 10),
          Expanded(child: _buildFilterButton(
            label: _selectedUnitId == null
                ? getTxt('semua_grup_anggota')
                : (_unitList.firstWhere(
                    (u) => u['id_unit'].toString() == _selectedUnitId,
                    orElse: () => {'nama_unit': getTxt('semua_grup')})['nama_unit'] as String),
            onTap: _showGroupPicker,
          )),
        ]),
      ),
      _buildLastUpdatedWidget(),
      Expanded(child: Builder(builder: (context) {
        final Future<List<MemberData5R>>? activeFuture = _anggotaFuture;
        if (activeFuture == null) return _buildAnggotaShimmer();
        return FutureBuilder<List<MemberData5R>>(
          future: activeFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildAnggotaShimmer();
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text(getTxt('tidak_ada_data_anggota')));
            }
            final memberList = snapshot.data!;
            final self = memberList.firstWhere(
              (m) => m.isSelf,
              orElse: () => MemberData5R(name: getTxt('saya'), findings: 0, completed: 0, isSelf: true),
            );
            return Column(children: [
              _buildTableHeader(
                [getTxt('nama'), getTxt('temuan'), getTxt('selesai')],
                flex: [3, 1, 1],
              ),
              _buildTargetRow([getTxt('target_bulanan'), '$_targetAnggota', '$_targetAnggota']),
              Expanded(child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: memberList.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: _AppColors.divider, indent: 16),
                itemBuilder: (_, i) => _buildMemberRow(memberList[i]),
              )),
              _buildSelfPinnedRow(self),
            ]);
          },
        );
      })),
    ]);
  }

  // ─── Inspeksi Tab ─────────────────────────────────────────────────────────
  Widget _buildInspeksiTab() {
    const Map<String, Color> roleColors = {
      'Eksekutif': Color(0xFFEF4444),
      'Executive': Color(0xFFEF4444),
      '行政': Color(0xFFEF4444),
      'Profesional': Color(0xFFF59E0B),
      'Professional': Color(0xFFF59E0B),
      '专业': Color(0xFFF59E0B),
      'Visitor': Color(0xFF3B82F6),
      '访客': Color(0xFF3B82F6),
    };

    return Column(children: [
      Container(
        color: Colors.transparent,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          _buildFilterButton(
            label: _filterMode == 'daily' && _selectedDate != null
                ? DateFormat('d MMM yyyy',
                    widget.lang == 'ID' ? 'id_ID' : widget.lang == 'EN' ? 'en_US' : 'zh_CN')
                    .format(_selectedDate!)
                : _translatedMonths[_selectedMonthIndex],
            isActive: true,
            onTap: () => _showMonthPicker(() => _fetchAllData(fromTabFilter: true)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: _translatedRoles.map((r) {
                final isSelected = _selectedInspectionRole == r;
                final activeColor = roleColors[r] ?? _AppColors.primary;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: r != _translatedRoles.last ? 6 : 0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedInspectionRole = r);
                        _fetchAllData(fromTabFilter: true);
                      },
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
                              ? [BoxShadow(
                                  color: activeColor.withOpacity(0.28),
                                  blurRadius: 8, offset: const Offset(0, 3))]
                              : [],
                        ),
                        child: Center(child: Text(r,
                          style: TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : _AppColors.textSecondary),
                          textAlign: TextAlign.center,
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ]),
      ),
      _buildLastUpdatedWidget(),
      _buildTableHeader([getTxt('nama'), getTxt('temuan')], flex: [3, 1]),
      _buildTargetRow([getTxt('target_bulanan'), '$_targetInspeksi']),
      Expanded(child: Builder(builder: (context) {
        if (_inspeksiFuture == null) return _buildInspeksiShimmer();
        return FutureBuilder<List<InspectionData5R>>(
          future: _inspeksiFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildInspeksiShimmer();
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('${getTxt('tidak_ada_temuan_role')} "$_selectedInspectionRole".'));
            }
            return ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: snapshot.data!.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: _AppColors.divider, indent: 16),
              itemBuilder: (_, i) => _buildInspectionRow(snapshot.data![i]),
            );
          },
        );
      })),
    ]);
  }

  // ─── Lokasi Tab ───────────────────────────────────────────────────────────
  Widget _buildLokasiTab() {
    final bool use5RAudit = !(_filterMode == 'daily' && _selectedDate != null);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          _buildFilterButton(
            label: _filterMode == 'daily' && _selectedDate != null
                ? DateFormat('d MMM yyyy',
                    widget.lang == 'ID' ? 'id_ID' : widget.lang == 'EN' ? 'en_US' : 'zh_CN')
                    .format(_selectedDate!)
                : _translatedMonths[_selectedMonthIndex],
            isActive: true,
            onTap: () => _showMonthPicker(() => _fetchAllData(fromTabFilter: true)),
          ),
          const SizedBox(width: 10),
          Expanded(child: _buildFilterButton(
            label: _selectedLocationLevel,
            onTap: _showLevelPicker,
          )),
        ]),
      ),
      if (!use5RAudit) _buildAuditPeriodBanner(),
      _buildLastUpdatedWidget(),
      use5RAudit
          ? _buildTableHeader(
              [getTxt('rank'), getTxt('lokasi'), _getRankAuditLabel()],
              flex: [1, 3, 1], isLocation: true)
          : _buildTableHeader(
              [getTxt('rank'), getTxt('lokasi'), getTxt('temuan')],
              flex: [1, 3, 1], isLocation: true),
      Expanded(child: Builder(builder: (context) {
        if (use5RAudit) {
          if (_auditLokasiFuture == null) return _buildLokasiShimmer();
          return FutureBuilder<List<AuditLocationData5R>>(
            future: _auditLokasiFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLokasiShimmer();
              }
              final data = snapshot.data ?? [];
              if (data.isEmpty) {
                return Center(child: Text(getTxt('tidak_ada_data_level'),
                    style: const TextStyle(color: _AppColors.textSecondary)));
              }
              return RefreshIndicator(
                onRefresh: () async => _fetchAllData(fromTabFilter: true),
                color: _AppColors.primary,
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: _AppColors.divider, indent: 16),
                  itemBuilder: (_, i) => _buildAuditLocationRow(i + 1, data[i]),
                ),
              );
            },
          );
        }

        if (_lokasiFuture == null) return _buildLokasiShimmer();
        return FutureBuilder<List<LocationData5R>>(
          future: _lokasiFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLokasiShimmer();
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text(
                  '${getTxt('tidak_ada_data_level')} "$_selectedLocationLevel".'));
            }
            return ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: snapshot.data!.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: _AppColors.divider, indent: 16),
              itemBuilder: (_, i) => _buildLocationRow(i + 1, snapshot.data![i]),
            );
          },
        );
      })),
    ]);
  }

  String _getRankAuditLabel() {
    if (widget.lang == 'EN') return 'Score';
    if (widget.lang == 'ZH') return '评分';
    return 'Nilai';
  }

  // ─── Temuan Berulang Tab ──────────────────────────────────────────────────
  Widget _buildTemuanBerulangTab() {
    final locale = widget.lang == 'ID' ? 'id_ID' : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');
    final fromLabel = DateFormat('MMM yyyy', locale).format(_recurringFrom);
    final toLabel = DateFormat('MMM yyyy', locale).format(_recurringTo);
    final periodLabel = '$fromLabel - $toLabel';

    return Column(children: [
      Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          Expanded(child: _buildFilterButton(
            label: periodLabel,
            onTap: _showPeriodPicker,
            icon: Icons.calendar_month_rounded,
          )),
          const SizedBox(width: 10),
          Expanded(child: _buildFilterButton(
            label: _recurringUserName.isEmpty ? getTxt('semua_grup') : _recurringUserName,
            onTap: _showUserPicker,
          )),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Align(alignment: Alignment.centerLeft,
          child: Text(getTxt('topik'), style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: _AppColors.textPrimary))),
      ),
      const Divider(height: 1, color: _AppColors.divider),
      Expanded(child: FutureBuilder<List<RecurringTopic5R>>(
        future: _recurringFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildRecurringShimmer();
          }
          final topics = snapshot.data ?? [];
          if (topics.isEmpty) {
            final name = _recurringUserName.isEmpty ? '' : _recurringUserName;
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 72, height: 72,
                  decoration: BoxDecoration(color: _AppColors.primaryLight, shape: BoxShape.circle),
                  child: Icon(Icons.search_off_rounded, size: 36, color: _AppColors.primary.withOpacity(0.5))),
                const SizedBox(height: 16),
                Text(
                  name.isEmpty ? getTxt('tidak_ada_data_anggota')
                      : '$name ${getTxt('belum_memiliki_temuan')}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: _AppColors.textSecondary, height: 1.5)),
              ],
            ));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: topics.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) => _buildRecurringTopicCard(topics[i]),
          );
        },
      )),
    ]);
  }

  Widget _buildRecurringTopicCard(RecurringTopic5R topic) {
    return GestureDetector(
      onTap: () => _showRecurringDetail(topic),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _AppColors.primaryLight, width: 1.5),
          boxShadow: [BoxShadow(color: _AppColors.primary.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            child: Container(
              width: 80, height: 80,
              color: _AppColors.primaryLight,
              child: topic.imageUrl != null && topic.imageUrl!.isNotEmpty
                  ? Image.network(topic.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: _AppColors.textMuted))
                  : const Icon(Icons.image_outlined, color: _AppColors.textMuted, size: 32),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Builder(builder: (context) {
              final isKts = topic.findings.isNotEmpty &&
                  (topic.findings.first['jenis_temuan'] ?? '') == 'KTS Production';
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(topic.topic,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _AppColors.textPrimary),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(
                    isKts ? Icons.tag_rounded : Icons.location_on_rounded,
                    size: 13,
                    color: isKts ? const Color(0xFFD97706) : _AppColors.primary,
                  ),
                  const SizedBox(width: 3),
                  Expanded(child: Text(
                    isKts
                        ? '${widget.lang == 'ID' ? 'No. Order' : widget.lang == 'ZH' ? '订单号' : 'Order No.'}: ${topic.locationArea}'
                        : topic.locationArea,
                    style: TextStyle(
                      fontSize: 12,
                      color: isKts ? const Color(0xFFD97706) : _AppColors.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              ]);
            }),
          )),
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _AppColors.primaryLight, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _AppColors.primary.withOpacity(0.3))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(getTxt('total'), style: const TextStyle(fontSize: 9, color: _AppColors.textSecondary)),
              Text('${topic.total}', style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w900, color: _AppColors.primary)),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showRecurringDetail(RecurringTopic5R topic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                Expanded(child: Builder(builder: (context) {
                  final isKts = topic.findings.isNotEmpty &&
                      (topic.findings.first['jenis_temuan'] ?? '') == 'KTS Production';
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(topic.topic, style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: _AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(
                        isKts ? Icons.tag_rounded : Icons.location_on_rounded,
                        size: 13,
                        color: isKts ? const Color(0xFFD97706) : _AppColors.primary),
                      const SizedBox(width: 3),
                      Flexible(child: Text(
                        isKts
                            ? '${widget.lang == 'ID' ? 'No. Order' : widget.lang == 'ZH' ? '订单号' : 'Order No.'}: ${topic.locationArea}'
                            : '${getTxt('di_sekitar')} ${topic.locationArea}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isKts ? const Color(0xFFD97706) : _AppColors.textSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                  ]);
                })),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: _AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                  child: Text('${getTxt('total')}: ${topic.total}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: _AppColors.primary))),
              ]),
            ),
            const Divider(height: 1, color: _AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Align(alignment: Alignment.centerLeft,
                child: Text('${getTxt('daftar_temuan')} (${topic.total})',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _AppColors.textPrimary))),
            ),
            Expanded(child: ListView.separated(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: topic.findings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _buildRecurringFindingCard(topic.findings[i]),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _buildRecurringFindingCard(Map<String, dynamic> data) {
    final isKts = (data['jenis_temuan'] ?? '') == 'KTS Production';

    if (isKts) {
      return KtsFindingCard(
        data: data,
        lang: widget.lang,
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => FindingDetailScreen(initialData: data, lang: widget.lang))),
      );
    }

    final imageUrl = (data['gambar_temuan'] ?? '').toString();
    final title = (data['judul_temuan'] ?? '-').toString();
    final status = (data['status_temuan'] ?? '').toString();
    final s = status.toLowerCase();
    final isFinished = ['selesai', 'done', 'completed', 'closed'].any((e) => s.contains(e));
    final isPro = data['is_pro'] == true;
    final isVisitor = data['is_visitor'] == true;
    final isEksekutif = data['is_eksekutif'] == true;
    final poin = int.tryParse((data['poin_temuan'] ?? 0).toString()) ?? 0;
    final isKtsCard = (data['jenis_temuan'] ?? '') == 'KTS Production';

    final tanggal = () {
      final v = data['created_at'];
      if (v == null) return '-';
      final dt = v is DateTime ? v : DateTime.tryParse(v.toString());
      if (dt == null) return '-';
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }();

    String location = '';
    if (data['area'] != null) location = data['area']['nama_area'] ?? '';
    else if (data['subunit'] != null) location = data['subunit']['nama_subunit'] ?? '';
    else if (data['unit'] != null) location = data['unit']['nama_unit'] ?? '';
    else if (data['lokasi'] != null) location = data['lokasi']['nama_lokasi'] ?? '';

    final statusColor = isFinished ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final statusBg = isFinished ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
    final statusIcon = isFinished ? Icons.check_circle_rounded : Icons.pending_actions_rounded;
    final statusText = isFinished
        ? (widget.lang == 'ID' ? 'Selesai' : widget.lang == 'ZH' ? '已完成' : 'Finished')
        : (widget.lang == 'ID' ? 'Belum Selesai' : widget.lang == 'ZH' ? '未完成' : 'Unfinished');

    List<Widget> badges = [];
    if (isPro) badges.add(_buildBadge('PROFESIONAL', const Color.fromARGB(255, 255, 244, 45), Colors.black));
    if (isVisitor) badges.add(_buildBadge('VISITOR', const Color(0xFF3B82F6), Colors.white));
    if (isEksekutif) badges.add(_buildBadge('EKSEKUTIF', const Color(0xFFEF4444), Colors.white));

    Color borderColor = isKtsCard ? const Color(0xFFFDE68A) : const Color(0xFF38BDF8);

    Widget? timeIndicator;
    if (isFinished) {
      final penyelesaianData = data['penyelesaian'] as Map<String, dynamic>?;
      String completionDateText = '-';
      if (penyelesaianData != null) {
        final v = penyelesaianData['tanggal_selesai'];
        if (v != null) {
          final dt = DateTime.tryParse(v.toString());
          if (dt != null) completionDateText = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
        }
      }
      timeIndicator = Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: statusBg,
          borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18))),
        child: Row(children: [
          Icon(Icons.event_available_rounded, size: 13, color: statusColor),
          const SizedBox(width: 5),
          Text(
            '${widget.lang == 'ID' ? 'Selesai pada' : widget.lang == 'ZH' ? '完成于' : 'Completed on'} $completionDateText',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
        ]),
      );
    } else {
      final deadline = DateTime.tryParse(data['target_waktu_selesai']?.toString() ?? '');
      if (deadline != null) {
        final now = DateTime.now();
        final difference = deadline.difference(now);
        Color timeColor;
        String timeText;
        IconData timeIcon;
        if (difference.isNegative) {
          timeColor = Colors.red.shade700;
          timeIcon = Icons.warning_amber_rounded;
          final abs = difference.abs();
          if (abs.inDays > 0) {
            timeText = widget.lang == 'ID'
                ? '${abs.inDays} hari terlewat'
                : widget.lang == 'ZH' ? '已超过 ${abs.inDays} 天' : '${abs.inDays} days overdue';
          } else if (abs.inHours > 0) {
            timeText = widget.lang == 'ID'
                ? '${abs.inHours} jam terlewat'
                : widget.lang == 'ZH' ? '已超过 ${abs.inHours} 小时' : '${abs.inHours} hours overdue';
          } else {
            timeText = widget.lang == 'ID'
                ? '${abs.inMinutes} menit terlewat'
                : widget.lang == 'ZH' ? '已超过 ${abs.inMinutes} 分钟' : '${abs.inMinutes} minutes overdue';
          }
        } else {
          final sisaHari = difference.inDays;
          if (sisaHari == 0) {
            timeColor = Colors.orange.shade800;
            timeIcon = Icons.today_rounded;
            timeText = widget.lang == 'ID'
                ? 'Deadline hari ini'
                : widget.lang == 'ZH' ? '今天截止' : 'Due today';
          } else {
            timeColor = Colors.green.shade800;
            timeIcon = Icons.timer_outlined;
            timeText = widget.lang == 'ID'
                ? '$sisaHari hari tersisa'
                : widget.lang == 'ZH' ? '还剩 $sisaHari 天' : '$sisaHari days remaining';
          }
        }
        timeIndicator = Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: timeColor.withOpacity(0.08),
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18))),
          child: Row(children: [
            Icon(timeIcon, size: 13, color: timeColor),
            const SizedBox(width: 5),
            Text(timeText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: timeColor)),
          ]),
        );
      }
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => FindingDetailScreen(initialData: data, lang: widget.lang))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [BoxShadow(
              color: borderColor.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 11, 11, 11),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.black.withOpacity(0.12), width: 1.5)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11.5),
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.grey))
                        : const Icon(Icons.image_outlined, color: Colors.grey, size: 26),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Text(title,
                    style: const TextStyle(fontSize: 14, height: 1.3, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    maxLines: 2, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF38BDF8), width: 1.1)),
                    child: const Text('5R', style: TextStyle(
                        color: Color(0xFF38BDF8), fontWeight: FontWeight.w900, fontSize: 9))),
                  if (poin > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFFF6B3D)]),
                        borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.local_fire_department_rounded, size: 10, color: Colors.white),
                        const SizedBox(width: 2),
                        Text('$poin', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
                      ]),
                    ),
                  ],
                ]),
                const SizedBox(height: 5),
                if (badges.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(bottom: 4),
                    child: Wrap(spacing: 4, runSpacing: 3, children: badges)),
                Row(children: [
                  const Icon(Icons.place_rounded, size: 12, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Expanded(child: Text(location,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.calendar_today_rounded, size: 11, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(tanggal, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(16)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(statusIcon, size: 11, color: statusColor),
                      const SizedBox(width: 3),
                      Text(statusText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                    ]),
                  ),
                ]),
              ])),
            ]),
          ),
          if (timeIndicator != null) timeIndicator,
        ]),
      ),
    );
  }

  Widget _buildBadge(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 8, fontWeight: FontWeight.w900)),
    );
  }

  // ─── Table Widgets ────────────────────────────────────────────────────────
  Widget _buildTableHeader(List<String> cols, {required List<int> flex, bool isLocation = false}) {
    return Container(
      color: const Color(0xFFF8FAFF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: isLocation
          ? Row(children: [
              SizedBox(width: 40, child: Text(cols[0], textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                      color: _AppColors.textSecondary, letterSpacing: 0.2))),
              Expanded(flex: 3, child: Text(cols[1], textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                      color: _AppColors.textSecondary, letterSpacing: 0.2))),
              SizedBox(width: 70, child: Text(cols[2], textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                      color: _AppColors.textSecondary, letterSpacing: 0.2))),
            ])
          : Row(
              children: List.generate(cols.length, (i) {
                final isFirst = i == 0;
                return Expanded(
                  flex: flex[i],
                  child: Padding(
                    padding: EdgeInsets.only(left: isFirst ? 44 : 0),
                    child: Text(cols[i],
                      textAlign: isFirst ? TextAlign.left : TextAlign.center,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                          color: _AppColors.textSecondary, letterSpacing: 0.2)),
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
            child: Text(vals[0], textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _AppColors.primary)),
          ),
        ),
        ...vals.sublist(1).map((v) => Expanded(
          flex: 1,
          child: Text(v, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _AppColors.primary)),
        )),
      ]),
    );
  }

  Widget _buildMemberRow(MemberData5R m) {
    final target = _targetAnggota;
    final findingsColor = m.findings >= target ? const Color(0xFF16A34A) : _AppColors.textPrimary;
    final completedColor = m.completed >= target ? const Color(0xFF16A34A) : _AppColors.textPrimary;

    return Container(
      color: m.isSelf ? _AppColors.selfHighlight : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          _Avatar5R(name: m.name, avatarUrl: m.avatarUrl, color: m.avatarColor, size: 34),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _AppColors.textPrimary),
                overflow: TextOverflow.ellipsis),
            if (m.unitName != null && m.unitName!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(m.unitName!, style: const TextStyle(fontSize: 11, color: _AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis),
            ],
          ])),
        ])),
        Expanded(flex: 1, child: Text('${m.findings}', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: findingsColor))),
        Expanded(flex: 1, child: Text('${m.completed}', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: completedColor))),
      ]),
    );
  }

  Widget _buildSelfPinnedRow(MemberData5R self) {
    final target = _targetAnggota;
    final findingsColor = self.findings >= target ? const Color(0xFF16A34A) : _AppColors.textSecondary;
    final completedColor = self.completed >= target ? const Color(0xFF16A34A) : _AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: _AppColors.selfHighlight,
        border: const Border(top: BorderSide(color: _AppColors.selfHighlightBorder, width: 1.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, -2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          _Avatar5R(name: self.name, avatarUrl: self.avatarUrl, color: self.avatarColor, size: 34),
          const SizedBox(width: 10),
          Expanded(child: Text(self.name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _AppColors.textPrimary),
            overflow: TextOverflow.ellipsis)),
        ])),
        Expanded(flex: 1, child: Text('${self.findings}', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: findingsColor))),
        Expanded(flex: 1, child: Text('${self.completed}', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: completedColor))),
      ]),
    );
  }

  Widget _buildInspectionRow(InspectionData5R item) {
    final target = _targetInspeksi;
    final findingsColor = item.findings >= target ? const Color(0xFF16A34A) : _AppColors.textPrimary;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          _Avatar5R(name: item.name, size: 34),
          const SizedBox(width: 10),
          Expanded(child: Text(item.name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _AppColors.textPrimary))),
        ])),
        Expanded(flex: 1, child: Text('${item.findings}', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: findingsColor))),
      ]),
    );
  }

  Widget _buildAuditPeriodBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.calendar_today_rounded, size: 15, color: _AppColors.primary),
        const SizedBox(width: 8),
        Text(getTxt('periode_audit'), style: const TextStyle(fontSize: 13, color: _AppColors.textSecondary)),
        const Text('13 Apr - 19 Apr 2026',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _AppColors.primaryDark)),
      ]),
    );
  }

  Widget _buildLocationRow(int rank, LocationData5R loc) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        SizedBox(width: 40, child: Text('$rank', textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: _AppColors.textSecondary, fontWeight: FontWeight.w500))),
        Expanded(flex: 3, child: Row(children: [
          Container(width: 38, height: 38,
            decoration: BoxDecoration(color: _AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.location_city_rounded, color: _AppColors.primary, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(loc.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _AppColors.textPrimary),
                overflow: TextOverflow.ellipsis),
            Text(loc.pic, style: const TextStyle(fontSize: 11.5, color: _AppColors.textSecondary),
                overflow: TextOverflow.ellipsis),
          ])),
        ])),
        SizedBox(width: 70, child: Text(loc.value ?? '0', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: (int.tryParse(loc.value ?? '0') ?? 0) > 0
                    ? _AppColors.primaryDark : _AppColors.textMuted))),
      ]),
    );
  }

  Widget _buildAuditLocationRow(int rank, AuditLocationData5R loc) {
    final score = loc.auditScore;
    Color scoreColor;
    if (score == null) {
      scoreColor = _AppColors.textMuted;
    } else if (score >= 80) {
      scoreColor = const Color(0xFF10B981);
    } else if (score >= 60) {
      scoreColor = const Color(0xFFF59E0B);
    } else {
      scoreColor = const Color(0xFFEF4444);
    }

    return GestureDetector(
      onTap: () => _showAuditLocationDetail(loc),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          SizedBox(
            width: 40,
            child: rank <= 3
                ? Text(['🥇','🥈','🥉'][rank - 1], style: const TextStyle(fontSize: 20))
                : Text('$rank', textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: _AppColors.textSecondary))),
          Expanded(flex: 3, child: Row(children: [
            Container(width: 38, height: 38,
              decoration: BoxDecoration(
                color: scoreColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.location_city_rounded, color: scoreColor, size: 20)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(loc.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis),
              Text(loc.pic, style: const TextStyle(fontSize: 11.5, color: _AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis),
              if (loc.auditDate != null) ...[
                const SizedBox(height: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: score != null ? score / 100 : 0,
                    backgroundColor: scoreColor.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    minHeight: 4)),
              ],
            ])),
          ])),
          SizedBox(width: 70, child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(score != null ? '${score.toStringAsFixed(0)}%' : '-',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: scoreColor)),
              if (loc.auditDate != null)
                Text(loc.auditDate!.substring(0, 10),
                    style: const TextStyle(fontSize: 9, color: _AppColors.textSecondary)),
            ],
          )),
        ]),
      ),
    );
  }

  void _showAuditLocationDetail(AuditLocationData5R loc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AuditLocationDetailSheet(
        lang: widget.lang,
        loc: loc,
        levelType: ['Lokasi','Unit','Subunit','Area'][
            _translatedLocationLevels.indexOf(_selectedLocationLevel).clamp(0,3)].toLowerCase(),
      ),
    );
  }

  // ─── Shimmer Helpers ──────────────────────────────────────────────────────
  Widget _buildShimmerBox({double? width, required double height, bool isCircle = false, double borderRadius = 8}) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCircle ? height / 2 : borderRadius),
      ),
    );
  }

  Widget _buildAnggotaShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!,
      child: ListView.separated(
        padding: EdgeInsets.zero, itemCount: 10,
        separatorBuilder: (_, __) => const Divider(height: 1, color: _AppColors.divider, indent: 16),
        itemBuilder: (_, __) => Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(children: [
            Expanded(flex: 3, child: Row(children: [
              _buildShimmerBox(height: 34, width: 34, isCircle: true),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildShimmerBox(height: 14, width: 120),
                const SizedBox(height: 4),
                _buildShimmerBox(height: 12, width: 80),
              ])),
            ])),
            Expanded(flex: 1, child: Center(child: _buildShimmerBox(height: 14, width: 20))),
            Expanded(flex: 1, child: Center(child: _buildShimmerBox(height: 14, width: 20))),
          ]),
        ),
      ),
    );
  }

  Widget _buildInspeksiShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!,
      child: ListView.separated(
        padding: EdgeInsets.zero, itemCount: 10,
        separatorBuilder: (_, __) => const Divider(height: 1, color: _AppColors.divider, indent: 16),
        itemBuilder: (_, __) => Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Expanded(flex: 3, child: Row(children: [
              _buildShimmerBox(height: 34, width: 34, isCircle: true),
              const SizedBox(width: 10),
              Expanded(child: _buildShimmerBox(height: 14)),
            ])),
            Expanded(flex: 1, child: Center(child: _buildShimmerBox(height: 14, width: 20))),
          ]),
        ),
      ),
    );
  }

  Widget _buildLokasiShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!,
      child: ListView.separated(
        padding: EdgeInsets.zero, itemCount: 8,
        separatorBuilder: (_, __) => const Divider(height: 1, color: _AppColors.divider, indent: 16),
        itemBuilder: (_, __) => Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            SizedBox(width: 40, child: Center(child: _buildShimmerBox(height: 14, width: 20))),
            Expanded(flex: 3, child: Row(children: [
              _buildShimmerBox(height: 38, width: 38, borderRadius: 10),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildShimmerBox(height: 14, width: double.infinity),
                const SizedBox(height: 4),
                _buildShimmerBox(height: 12, width: 100),
              ])),
            ])),
            SizedBox(width: 70, child: Center(child: _buildShimmerBox(height: 14, width: 20))),
          ]),
        ),
      ),
    );
  }

  Widget _buildRecurringShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (_, __) => Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(14))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildShimmerBox(height: 14, width: double.infinity),
                const SizedBox(height: 6),
                _buildShimmerBox(height: 12, width: 120),
              ],
            )),
            Container(
              margin: const EdgeInsets.only(right: 12),
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildLastUpdatedWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(_lastUpdatedText,
          style: const TextStyle(fontSize: 11, color: _AppColors.textSecondary, height: 1.4)),
    );
  }

  // ─── Filter Button ────────────────────────────────────────────────────────
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

  // ─── Filter Dialogs ───────────────────────────────────────────────────────

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

  void _showPeriodPicker() async {
    DateTime tempFrom = _recurringFrom;
    DateTime tempTo = _recurringTo;
    final locale = widget.lang == 'ID' ? 'id_ID' : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _AppColors.primaryLight, width: 1.5)),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.date_range_rounded, color: _AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(getTxt('pilih_periode'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _AppColors.textPrimary))),
              IconButton(icon: const Icon(Icons.close, size: 18),
                onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
            ]),
            const SizedBox(height: 16),
            Text(getTxt('dari'), style: const TextStyle(fontSize: 12, color: _AppColors.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _buildYearMonthPicker(tempFrom, locale, (d) => setSt(() => tempFrom = d)),
            const SizedBox(height: 14),
            Text(getTxt('sampai'), style: const TextStyle(fontSize: 12, color: _AppColors.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _buildYearMonthPicker(tempTo, locale, (d) => setSt(() => tempTo = d)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() { _recurringFrom = tempFrom; _recurringTo = tempTo; });
                  Navigator.pop(ctx);
                  _fetchRecurring();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _AppColors.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(getTxt('terapkan')),
              ),
            ),
          ]),
        ),
      )),
    );
  }

  Widget _buildYearMonthPicker(DateTime current, String locale, ValueChanged<DateTime> onChange) {
    final months = List.generate(12, (i) => DateFormat.MMM(locale).format(DateTime(2000, i + 1)));
    final years = List.generate(5, (i) => DateTime.now().year - 2 + i);
    return Row(children: [
      Expanded(
        flex: 3,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _AppColors.surface, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _AppColors.primaryLight)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: current.month - 1,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: _AppColors.primary),
              style: const TextStyle(fontSize: 13, color: _AppColors.textPrimary, fontWeight: FontWeight.w600),
              dropdownColor: Colors.white,
              items: List.generate(12, (i) => DropdownMenuItem(value: i, child: Text(months[i]))),
              onChanged: (v) { if (v != null) onChange(DateTime(current.year, v + 1)); },
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        flex: 2,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _AppColors.surface, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _AppColors.primaryLight)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: current.year,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: _AppColors.primary),
              style: const TextStyle(fontSize: 13, color: _AppColors.textPrimary, fontWeight: FontWeight.w600),
              dropdownColor: Colors.white,
              items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
              onChanged: (v) { if (v != null) onChange(DateTime(v, current.month)); },
            ),
          ),
        ),
      ),
    ]);
  }

  void _showUserPicker() async {
    try {
      final response = await _supabase
          .from('User')
          .select('id_user, nama, gambar_user, jabatan!User_id_jabatan_fkey(nama_jabatan)')
          .order('nama');
      final users = List<Map<String, dynamic>>.from(response);
      final allItem = {'id_user': null, 'nama': getTxt('pilih_penemu'), 'gambar_user': null, 'jabatan': null};
      final items = [allItem, ...users];
      if (!mounted) return;

      final ctrl = TextEditingController();
      List<Map<String, dynamic>> filtered = List.from(items);

      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSt) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
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
                    const Icon(Icons.person_search_rounded, color: _AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(getTxt('pilih_penemu'),
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
                            (e['nama'] as String).toLowerCase().contains(q.toLowerCase())).toList();
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
                Padding(
                  padding: const EdgeInsets.only(left: 14, bottom: 4),
                  child: Align(alignment: Alignment.centerLeft,
                    child: Text('${filtered.length} ${widget.lang == 'ID' ? 'penemu' : widget.lang == 'ZH' ? '发现者' : 'finders'}',
                      style: const TextStyle(fontSize: 11, color: _AppColors.textSecondary))),
                ),
                Flexible(child: StatefulBuilder(
                  builder: (_, __) => ListView.builder(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final item = filtered[i];
                      final name = item['nama'] as String;
                      final id = item['id_user']?.toString();
                      final avatarUrl = item['gambar_user'] as String?;
                      final role = (item['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'] as String?;
                      final isSelected = id == _recurringUserId || (id == null && _recurringUserId == null);
                      final isAll = id == null;

                      return InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _recurringUserId = id;
                            _recurringUserName = isAll
                                ? (widget.lang == 'ID' ? 'Semua Penemu' : widget.lang == 'ZH' ? '所有发现者' : 'All Finders')
                                : name;
                          });
                          _fetchRecurring();
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? _AppColors.primaryLight : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? _AppColors.primary : _AppColors.divider,
                              width: isSelected ? 1.5 : 1)),
                          child: Row(children: [
                            if (isAll)
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected ? _AppColors.primary : _AppColors.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _AppColors.primaryLight)),
                                child: Icon(Icons.group_rounded,
                                  color: isSelected ? Colors.white : _AppColors.primary, size: 20))
                            else if (avatarUrl != null && avatarUrl.isNotEmpty)
                              CircleAvatar(radius: 20, backgroundImage: NetworkImage(avatarUrl),
                                onBackgroundImageError: (_, __) {}, backgroundColor: _AppColors.primaryLight)
                            else
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: isSelected ? _AppColors.primary : _AppColors.primaryLight,
                                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                                      color: isSelected ? Colors.white : _AppColors.primary))),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(isAll
                                ? (widget.lang == 'ID' ? 'Semua Penemu' : widget.lang == 'ZH' ? '所有发现者' : 'All Finders')
                                : name,
                                style: TextStyle(fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? _AppColors.primary : _AppColors.textPrimary)),
                              if (role != null && role.isNotEmpty)
                                Text(role, style: const TextStyle(fontSize: 11, color: _AppColors.textSecondary)),
                            ])),
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
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error fetching users: $e');
    }
  }
}

// ─── Audit Location Detail Sheet ──────────────────────────────────────────────
class _AuditLocationDetailSheet extends StatefulWidget {
  final String lang;
  final AuditLocationData5R loc;
  final String levelType;
  const _AuditLocationDetailSheet({required this.lang, required this.loc, required this.levelType});

  @override
  State<_AuditLocationDetailSheet> createState() => _AuditLocationDetailSheetState();
}

class _AuditLocationDetailSheetState extends State<_AuditLocationDetailSheet> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final rows = await _supabase
          .from('audit_result')
          .select('id_result, nilai_audit, tanggal_audit, catatan_audit, id_auditor')
          .eq('level_type', widget.levelType)
          .eq('id_ref', widget.loc.id)
          .order('tanggal_audit', ascending: false)
          .limit(15);

      final auditorIds = List<Map<String, dynamic>>.from(rows)
          .where((r) => r['id_auditor'] != null)
          .map((r) => r['id_auditor'].toString())
          .toSet()
          .toList();
      final Map<String, String> auditorMap = {};
      if (auditorIds.isNotEmpty) {
        final auditorRows = await _supabase
            .from('User')
            .select('id_user, nama')
            .inFilter('id_user', auditorIds);
        for (final a in List<Map<String, dynamic>>.from(auditorRows)) {
          auditorMap[a['id_user'].toString()] = a['nama']?.toString() ?? '-';
        }
      }

      final result = <Map<String, dynamic>>[];
      final allIds = List<Map<String, dynamic>>.from(rows).map((r) => r['id_result'].toString()).toList();

      Map<String, List<Map<String, dynamic>>> answersMap = {};
      if (allIds.isNotEmpty) {
        final allAnswers = await _supabase
            .from('audit_answer')
            .select('id_result, jawaban, id_question')
            .inFilter('id_result', allIds)
            .order('created_at');

        final questionIds = List<Map<String, dynamic>>.from(allAnswers)
            .map((a) => a['id_question'].toString())
            .toSet()
            .toList();
        final Map<String, String> questionMap = {};
        if (questionIds.isNotEmpty) {
          final qRows = await _supabase
              .from('audit_question')
              .select('id_question, pertanyaan')
              .inFilter('id_question', questionIds);
          for (final q in List<Map<String, dynamic>>.from(qRows)) {
            questionMap[q['id_question'].toString()] = q['pertanyaan']?.toString() ?? '-';
          }
        }

        for (final a in List<Map<String, dynamic>>.from(allAnswers)) {
          final resultId = a['id_result'].toString();
          answersMap.putIfAbsent(resultId, () => []);
          answersMap[resultId]!.add({
            'jawaban': a['jawaban'],
            'audit_question': {'pertanyaan': questionMap[a['id_question']?.toString() ?? ''] ?? '-'},
          });
        }
      }

      for (final row in List<Map<String, dynamic>>.from(rows)) {
        final resultId = row['id_result'].toString();
        result.add({
          ...row,
          'auditorName': auditorMap[row['id_auditor']?.toString() ?? ''] ?? '-',
          'answers': answersMap[resultId] ?? [],
        });
      }
      if (mounted) setState(() { _history = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _scoreColor(double? s) {
    if (s == null) return const Color(0xFF94A3B8);
    if (s >= 80) return const Color(0xFF10B981);
    if (s >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.loc.name, style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A))),
                Text(widget.loc.pic, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ])),
              if (widget.loc.auditScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _scoreColor(widget.loc.auditScore).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                  child: Text('${widget.loc.auditScore!.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                        color: _scoreColor(widget.loc.auditScore))),
                ),
            ]),
          ),
          const Divider(height: 1),
          Expanded(child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)))
              : _history.isEmpty
                  ? Center(child: Text(
                      widget.lang == 'EN' ? 'No audit history.' : 'Belum ada riwayat audit.',
                      style: const TextStyle(color: Color(0xFF64748B))))
                  : ListView.separated(
                      controller: ctrl,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final h = _history[i];
                        final score = double.tryParse(h['nilai_audit']?.toString() ?? '');
                        final auditor = h['auditorName'] as String? ?? '-';
                        final date = h['tanggal_audit']?.toString() ?? '';
                        final catatan = h['catatan_audit'] as String?;
                        final answers = h['answers'] as List<Map<String, dynamic>>? ?? [];
                        final color = _scoreColor(score);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withOpacity(0.3))),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Container(width: 44, height: 44,
                                decoration: BoxDecoration(
                                    color: color.withOpacity(0.12), shape: BoxShape.circle),
                                child: Center(child: Text(
                                    score != null ? '${score.toStringAsFixed(0)}%' : '-',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)))),
                              const SizedBox(width: 10),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(auditor, style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A))),
                                Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                if (catatan != null && catatan.isNotEmpty)
                                  Text(catatan, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      maxLines: 2, overflow: TextOverflow.ellipsis),
                              ])),
                            ]),
                            if (answers.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 6),
                              ...answers.map((a) {
                                final jawaban = a['jawaban'] as bool? ?? false;
                                final pertanyaan = (a['audit_question'] as Map<String, dynamic>?)?['pertanyaan'] ?? '-';
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(children: [
                                    Icon(
                                      jawaban ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                      size: 14,
                                      color: jawaban ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(pertanyaan,
                                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155)))),
                                  ]),
                                );
                              }),
                            ],
                          ]),
                        );
                      },
                    )),
        ]),
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────
class _Avatar5R extends StatelessWidget {
  final String name;
  final Color? color;
  final double size;
  final String? avatarUrl;

  const _Avatar5R({required this.name, this.color, this.size = 36, this.avatarUrl});

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
    final initials = name.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    final bg = color ?? _AppColors.primary;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: bg.withOpacity(0.15), shape: BoxShape.circle,
        border: Border.all(color: bg.withOpacity(0.3), width: 1)),
      child: Center(child: Text(initials,
        style: TextStyle(fontSize: size * 0.35, fontWeight: FontWeight.w700, color: bg))),
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