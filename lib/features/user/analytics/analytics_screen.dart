import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../finding/finding_detail_screen.dart';
import '../home/kts_finding_card.dart';

// ─── Warna & Tema ──────────────────────────────────────────────────────────
class _AppColors {
  static const primary = Color(0xFF0EA5E9);
  static const primaryDark = Color(0xFF0369A1);
  static const primaryLight = Color(0xFFE0F2FE);
  static const accent = Color(0xFF38BDF8);
  static const surface = Color(0xFFF0F9FF);
  static const cardBg = Colors.white;
  static const textPrimary = Color(0xFF0C4A6E);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFFBDBDBD);
  static const divider = Color(0xFFE0F2FE);
  static const selfHighlight = Color(0xFFFFF7ED);
  static const selfHighlightBorder = Color(0xFFFED7AA);
  static const chipSelected = Color(0xFF0369A1);
  static const chipUnselected = Colors.white;
  static const targetBlue = Color(0xFF0EA5E9);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
}

// ─── Model Data ──────────────────────────────────────────────────────────────
class MemberData {
  final String name;
  final String? unitName;
  final int findings;
  final int completed;
  final bool isSelf;
  final String? avatarUrl;
  final Color? avatarColor;

  const MemberData({
    required this.name,
    this.unitName,
    required this.findings,
    required this.completed,
    this.isSelf = false,
    this.avatarUrl,
    this.avatarColor,
  });
}

class InspectionData {
  final String name;
  final int findings;
  final bool isSelf;

  const InspectionData({
    required this.name,
    required this.findings,
    this.isSelf = false,
  });
}

class LocationData {
  final String name;
  final String pic;
  final String? value;

  const LocationData({
    required this.name,
    required this.pic,
    this.value,
  });
}

class RecurringTopic {
  final String topic;
  final String locationArea;
  final int total;
  final String? imageUrl;
  final List<Map<String, dynamic>> findings;

  const RecurringTopic({
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

// ─── Main Screen ──────────────────────────────────────────────────────────────
class AnalyticsScreen extends StatefulWidget {
  final String lang;
  const AnalyticsScreen({super.key, required this.lang});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
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
  int _recurringChartRefreshKey = 0;

  // Recurring findings filter
  DateTime _recurringFrom = DateTime(DateTime.now().year - 1, DateTime.now().month);
  DateTime _recurringTo = DateTime.now();
  String? _recurringUserId;
  String _recurringUserName = '';

  // ─── Finding Type Selector ────────────────────────────────────────────────
  String _selectedFindingType = '5R'; // '5R', 'KTS', 'Accident'

  // ─── Chart collapse state ─────────────────────────────────────────────────
  bool _isChartExpanded = false;
  int _currentTabCount = 4;
  bool _fetchTriggeredByTabFilter = false;

  // ─── Accident Report data ─────────────────────────────────────────────────
  Future<List<MemberData>>? _accidentAnggotaFuture;
  Future<List<LocationData>>? _accidentLokasiFuture;
  Future<List<Map<String, dynamic>>>? _accidentRecurringFuture;

  // ─── KTS data ─────────────────────────────────────────────────────────────
  Future<List<MemberData>>? _ktsAnggotaFuture;
  Future<List<InspectionData>>? _ktsInspeksiFuture;
  Future<List<LocationData>>? _ktsLokasiFuture;

  // ─── Chart data ───────────────────────────────────────────────────────────
  Future<List<_ChartBarData>>? _chartFuture;
  int _chartTargetTemuan       = 2;  // Anggota / Members
  int _chartTargetPenyelesaian = 2;  // Inspeksi
  int _chartTargetLokasi       = 5;  // Lokasi (default)
  int _chartTargetUnit         = 5;
  int _chartTargetSubunit      = 5;
  int _chartTargetArea         = 5;
  int _activeTabIndex = 0;

  // ─── Recurring Chart data ─────────────────────────────────────────────────
  Future<List<_ChartBarData>>? _recurringChartFuture;

  // ─── State untuk Data ────────────────────────────────────────────────────
  Future<List<MemberData>>? _anggotaFuture;
  Future<List<InspectionData>>? _inspeksiFuture;
  Future<List<LocationData>>? _lokasiFuture;
  Future<List<RecurringTopic>>? _recurringFuture;

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
    _fetchUnits().then((_) => _fetchAllData());
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
          // target chart per-tab
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

  /// Dipanggil dari setState-safe context (bukan dari dalam build).
  /// Rebuild TabController hanya jika jumlah tab berubah.
  void _rebuildTabControllerIfNeeded(int newCount) {
    if (_currentTabCount == newCount) {
      // Jumlah tab sama, sinkronkan _activeTabIndex saja
      _activeTabIndex = _tabController.index;
      return;
    }
    // Jumlah tab berubah — dispose lama, buat baru
    _activeTabIndex = 0;
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose(); // dispose langsung, bukan di postFrameCallback
    _tabController = TabController(length: newCount, vsync: this);
    _currentTabCount = newCount;
    _tabController.addListener(_onTabChanged);
  }

  void _fetchAllData({bool fromTabFilter = false}) {
    final roleBackendValue = ['Eksekutif', 'Profesional', 'Visitor'][
        _translatedRoles.indexOf(_selectedInspectionRole).clamp(0, 2)];
    final levelBackendValue = ['Lokasi', 'Unit', 'Subunit', 'Area'][
        _translatedLocationLevels.indexOf(_selectedLocationLevel).clamp(0, 3)];

    final int newTabCount = _selectedFindingType == 'KTS Production' ? 2
      : _selectedFindingType == 'Accident' ? 3
      : 4;

    // Reset activeTabIndex ke 0 saat finding type berubah (bukan dari tab filter)
    if (!fromTabFilter && _currentTabCount != newTabCount) {
      _activeTabIndex = 0;
    }

    // PENTING: rebuild controller SEBELUM setState agar TabBar/TabBarView
    // langsung mendapat controller dengan length yang benar
    _rebuildTabControllerIfNeeded(newTabCount);

    setState(() {
      _lastUpdated = DateTime.now();
      final month = _selectedMonth;
      final year = DateTime.now().year;

      if (_selectedFindingType == '5R') {
        if (_filterMode == 'daily' && _selectedDate != null) {
          _anggotaFuture = _fetchAnggotaDataDaily(_selectedDate!, _selectedUnitId);
          _inspeksiFuture = _fetchInspeksiDataDaily(_selectedDate!, roleBackendValue);
          _lokasiFuture = _fetchLokasiDataDaily(_selectedDate!, levelBackendValue);
        } else {
          _anggotaFuture = _fetchAnggotaData(month, year, _selectedUnitId);
          _inspeksiFuture = _fetchInspeksiData(month, year, roleBackendValue);
          _lokasiFuture = _fetchLokasiData(month, year, levelBackendValue);
        }
        _chartFuture = _fetchChartData(month, year, '5R');
        _chartRefreshKey++;
        _recurringFuture = _fetchRecurringData(ktsOnly: false);
        _recurringChartFuture = _fetchRecurringChartData();
        _recurringChartRefreshKey++;

      } else if (_selectedFindingType == 'KTS Production') {
        if (_filterMode == 'daily' && _selectedDate != null) {
          _ktsAnggotaFuture = _fetchKtsAnggotaDataDaily(_selectedDate!, _selectedUnitId);
        } else {
          _ktsAnggotaFuture = _fetchKtsAnggotaData(month, year, _selectedUnitId);
        }
        _chartFuture = _fetchChartData(month, year, 'KTS Production');
        _chartRefreshKey++;
        _recurringFuture = _fetchRecurringData(ktsOnly: true);
        _recurringChartFuture = _fetchKtsRecurringChartData();
        _recurringChartRefreshKey++;

      } else {
        // Accident
        if (_filterMode == 'daily' && _selectedDate != null) {
          _accidentAnggotaFuture = _fetchAccidentAnggotaDataDaily(_selectedDate!, _selectedUnitId);
          _accidentLokasiFuture = _fetchAccidentLokasiDataDaily(_selectedDate!, levelBackendValue);
        } else {
          _accidentAnggotaFuture = _fetchAccidentAnggotaData(month, year, _selectedUnitId);
          _accidentLokasiFuture = _fetchAccidentLokasiData(month, year, levelBackendValue);
        }
        _accidentRecurringFuture = _fetchAccidentRecurringData();
        _chartFuture = _fetchChartData(month, year, 'Accident');
        _chartRefreshKey++;
        _recurringChartFuture = _fetchAccidentRecurringChartData();
        _recurringChartRefreshKey++;
      }
    });
  }

  void _onTabChanged() {
    if (!mounted) return;
    // Hanya proses saat animasi benar-benar selesai
    if (_tabController.indexIsChanging) return;
    final newIdx = _tabController.index;
    if (_activeTabIndex == newIdx) return;

    final month = _selectedMonth;
    final year = DateTime.now().year;
    setState(() {
      _activeTabIndex = newIdx;
      _chartFuture = _fetchChartData(month, year, _selectedFindingType);
      _chartRefreshKey++;

      final bool isRecurringTab =
          (_selectedFindingType == '5R' && newIdx == 3) ||
          (_selectedFindingType == 'KTS Production' && newIdx == 1) ||
          (_selectedFindingType == 'Accident' && newIdx == 2);
      if (isRecurringTab) {
        if (_selectedFindingType == 'KTS Production') {
          _recurringChartFuture = _fetchKtsRecurringChartData();
        } else if (_selectedFindingType == 'Accident') {
          _recurringChartFuture = _fetchAccidentRecurringChartData();
        } else {
          _recurringChartFuture = _fetchRecurringChartData();
        }
        _recurringChartRefreshKey++;
      }
    });
  }
  
  Future<void> _fetchChartTarget(int month, int year) async {
    try {
      final data = await _supabase
          .from('target_bulanan')
          .select()
          .eq('bulan', month)
          .eq('tahun', year)
          .maybeSingle();
      if (mounted && data != null) {
        setState(() {
          _chartTargetTemuan       = data['target_anggota']  ?? 2;
          _chartTargetPenyelesaian = data['target_inspeksi'] ?? 2;
          _chartTargetLokasi       = data['target_lokasi']   ?? 5;
          _chartTargetUnit         = data['target_unit']     ?? 5;
          _chartTargetSubunit      = data['target_subunit']  ?? 5;
          _chartTargetArea         = data['target_area']     ?? 5;
        });
      }
    } catch (e) {
      debugPrint('Error fetching chart target: $e');
    }
  }

  /// Kembalikan pasangan [targetTemuan, targetPenyelesaian] sesuai tab aktif (5R only).
  /// Tab 0=Anggota, 1=Inspeksi, 2=Lokasi, 3=RecurringFindings
  (int temuan, int selesai) get _activeTabTargets {
    if (_selectedFindingType != '5R') {
      return (_chartTargetTemuan, _chartTargetPenyelesaian);
    }
    switch (_activeTabIndex) {
      case 0: // Anggota
        return (_chartTargetTemuan, _chartTargetTemuan);
      case 1: // Inspeksi
        return (_chartTargetPenyelesaian, _chartTargetPenyelesaian);
      case 2: // Lokasi
        final levelLower = ['Lokasi', 'Unit', 'Subunit', 'Area']
            [_translatedLocationLevels.indexOf(_selectedLocationLevel).clamp(0, 3)];
        switch (levelLower) {
          case 'Unit':    return (_chartTargetUnit,    _chartTargetUnit);
          case 'Subunit': return (_chartTargetSubunit, _chartTargetSubunit);
          case 'Area':    return (_chartTargetArea,    _chartTargetArea);
          default:        return (_chartTargetLokasi,  _chartTargetLokasi);
        }
      default: // Tab 3 = Recurring → tidak ada target
        return (0, 0);
    }
  }

  /// Refresh chart sesuai konteks saat ini (bulan, unit, tipe)
  void _refreshChart() {
    final month = _selectedMonth;
    final year = DateTime.now().year;
    setState(() {
      _chartFuture = _fetchChartData(month, year, _selectedFindingType);
      _chartRefreshKey++; // wajib agar FutureBuilder rebuild dengan key baru
    });
  }

  void _fetchRecurring() {
    final month = _selectedMonth;
    final year = DateTime.now().year;
    setState(() {
      if (_selectedFindingType == 'Accident') {
        _accidentRecurringFuture = _fetchAccidentRecurringData();
        _recurringChartFuture = _fetchAccidentRecurringChartData();
      } else if (_selectedFindingType == 'KTS Production') {
        _recurringFuture = _fetchRecurringData(ktsOnly: true);
        _recurringChartFuture = _fetchKtsRecurringChartData();
      } else {
        _recurringFuture = _fetchRecurringData(ktsOnly: false);
        _recurringChartFuture = _fetchRecurringChartData();
      }
      _chartFuture = _fetchChartData(month, year, _selectedFindingType);
      _chartRefreshKey++;
      _recurringChartRefreshKey++;
    });
  }

  Future<List<MemberData>> _fetchAnggotaData(int month, int year, String? unitId) async {
    try {
      // Step 1: Ambil user yang memenuhi filter unit
      var userQuery = _supabase
          .from('User')
          .select('id_user, nama, gambar_user, id_unit, unit!user_id_unit_fkey(nama_unit)');
      if (unitId != null) userQuery = userQuery.eq('id_unit', unitId);
      final List<dynamic> users = await userQuery;
      if (users.isEmpty) return [];

      final userIds = users.map((u) => u['id_user'].toString()).toList();

      // Step 2: Ambil temuan 5R bulan ini untuk user tersebut
      final List<dynamic> temuanRes = await _supabase
          .from('temuan')
          .select('id_user, id_penyelesaian')
          .neq('jenis_temuan', 'KTS Production')
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at', DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String())
          .inFilter('id_user', userIds);

      // Step 3: Hitung temuan dan selesai per user
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
        return MemberData(
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

  Future<List<InspectionData>> _fetchInspeksiData(int month, int year, String role) async {
    try {
      // Filter kolom role sesuai backend value
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
          .map((item) => InspectionData(
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

  Future<List<LocationData>> _fetchLokasiData(int month, int year, String level) async {
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

      // Step 1: Ambil semua lokasi/unit/subunit/area
      final List<dynamic> locations = await _supabase
          .from(levelLower)
          .select('$idCol, $nameCol');

      // Step 2: Ambil temuan 5R bulan ini
      final List<dynamic> temuanRes = await _supabase
          .from('temuan')
          .select(idCol)
          .neq('jenis_temuan', 'KTS Production')
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at', DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String())
          .not(idCol, 'is', null);

      // Step 3: Hitung per lokasi
      final Map<String, int> countMap = {};
      for (final t in temuanRes) {
        final id = t[idCol]?.toString() ?? '';
        if (id.isEmpty) continue;
        countMap[id] = (countMap[id] ?? 0) + 1;
      }

      // Step 4: Ambil PIC per lokasi (1 user per lokasi/unit/subunit/area)
      final picColMap = {
        'lokasi': 'id_lokasi', 'unit': 'id_unit',
        'subunit': 'id_subunit', 'area': 'id_area'
      };
      final picFilterCol = picColMap[levelLower] ?? 'id_lokasi';
      final List<dynamic> picRes = await _supabase
          .from('User')
          .select('$picFilterCol, nama')
          .not(picFilterCol, 'is', null);

      // Ambil PIC pertama per lokasi
      final Map<String, String> picMap = {};
      for (final p in picRes) {
        final locId = p[picFilterCol]?.toString() ?? '';
        if (locId.isEmpty || picMap.containsKey(locId)) continue;
        picMap[locId] = p['nama']?.toString() ?? 'PIC belum diatur';
      }

      return locations.map<LocationData>((loc) {
        final id = loc[idCol]?.toString() ?? '';
        return LocationData(
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

  Future<List<MemberData>> _fetchAnggotaDataDaily(DateTime date, String? unitId) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // Step 1: Ambil user filter unit
      var userQuery = _supabase
          .from('User')
          .select('id_user, nama, gambar_user, id_unit, unit!user_id_unit_fkey(nama_unit)');
      if (unitId != null) userQuery = userQuery.eq('id_unit', unitId);
      final List<dynamic> users = await userQuery;
      if (users.isEmpty) return [];

      final userIds = users.map((u) => u['id_user'].toString()).toList();

      // Step 2: Ambil temuan hari ini
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

      // Hanya tampilkan yang ada temuan hari ini (seperti get_anggota_stats_daily)
      final currentUserId = _supabase.auth.currentUser?.id;
      return users
          .where((u) => stats.containsKey(u['id_user']?.toString() ?? ''))
          .map((u) {
            final uid = u['id_user']?.toString() ?? '';
            final s = stats[uid]!;
            return MemberData(
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

  Future<List<InspectionData>> _fetchInspeksiDataDaily(DateTime date, String role) async {
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
          .map((item) => InspectionData(
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

  Future<List<LocationData>> _fetchLokasiDataDaily(DateTime date, String level) async {
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

      return locations.map<LocationData>((loc) {
        final id = loc[idCol]?.toString() ?? '';
        return LocationData(
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

  // ── Chart Data ──────────────────────────────────────────────────────────────
  Future<List<_ChartBarData>> _fetchChartData(int month, int year, String type) async {
    try {
      final daysInMonth = DateUtils.getDaysInMonth(year, month);
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

      // Tentukan range waktu
      DateTime startDt, endDt;
      bool isDaily = _filterMode == 'daily' && _selectedDate != null;
      if (isDaily) {
        startDt = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
        endDt = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 23, 59, 59);
      } else {
        startDt = startOfMonth;
        endDt = endOfMonth;
      }

      if (type == 'Accident') {
        if (_activeTabIndex == 2) {
          // Recurring Accident tab: group by bulan sesuai filter recurring
          final fromStr = _recurringFrom.toIso8601String();
          final toStr = DateTime(_recurringTo.year, _recurringTo.month + 1, 0, 23, 59, 59).toIso8601String();
          var query = _supabase
              .from('accident_report')
              .select('created_at, status')
              .gte('created_at', fromStr)
              .lte('created_at', toStr);
          if (_recurringUserId != null) query = query.eq('id_pelapor', _recurringUserId!);

          final List<dynamic> res = await query;
          final Map<String, int> laporanMap = {}, selesaiMap = {};
          for (final t in res) {
            final dt = DateTime.tryParse(t['created_at']?.toString() ?? '');
            if (dt == null) continue;
            final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
            laporanMap[key] = (laporanMap[key] ?? 0) + 1;
            if (t['status'] == 'Selesai') selesaiMap[key] = (selesaiMap[key] ?? 0) + 1;
          }
          final result = <_ChartBarData>[];
          DateTime cur = DateTime(_recurringFrom.year, _recurringFrom.month);
          final endMonth = DateTime(_recurringTo.year, _recurringTo.month);
          int idx = 1;
          while (!cur.isAfter(endMonth)) {
            final key = '${cur.year}-${cur.month.toString().padLeft(2, '0')}';
            result.add(_ChartBarData(date: idx++, temuan: laporanMap[key] ?? 0, penyelesaian: selesaiMap[key] ?? 0));
            cur = DateTime(cur.year, cur.month + 1);
          }
          return result;

        } else if (_activeTabIndex == 1) {
          // Location tab Accident: filter by level column
          final levelBackend = ['lokasi', 'unit', 'subunit', 'area'][
              _translatedLocationLevels.indexOf(_selectedLocationLevel).clamp(0, 3)];
          final idColMap = {'lokasi': 'id_lokasi', 'unit': 'id_unit', 'subunit': 'id_subunit', 'area': 'id_area'};
          final idCol = idColMap[levelBackend] ?? 'id_lokasi';

          var query = _supabase
              .from('accident_report')
              .select('created_at, status, $idCol')
              .gte('created_at', startDt.toIso8601String())
              .lte('created_at', endDt.toIso8601String())
              .not(idCol, 'is', null);
          if (_selectedUnitId != null) query = query.eq('id_unit', _selectedUnitId!);

          final List<dynamic> res = await query;
          if (isDaily) {
            return [_ChartBarData(
              date: _selectedDate!.day,
              temuan: res.length,
              penyelesaian: res.where((t) => t['status'] == 'Selesai').length,
            )];
          }
          final Map<int, int> laporanMap = {}, selesaiMap = {};
          for (final t in res) {
            final dt = DateTime.tryParse(t['created_at']?.toString() ?? '');
            if (dt == null) continue;
            laporanMap[dt.day] = (laporanMap[dt.day] ?? 0) + 1;
            if (t['status'] == 'Selesai') selesaiMap[dt.day] = (selesaiMap[dt.day] ?? 0) + 1;
          }
          return List.generate(daysInMonth, (i) => _ChartBarData(
            date: i + 1, temuan: laporanMap[i + 1] ?? 0, penyelesaian: selesaiMap[i + 1] ?? 0));

        } else {
          // Tab 0 = Members Accident: filter by unit via id_pelapor
          var query = _supabase
              .from('accident_report')
              .select('created_at, status, id_pelapor')
              .gte('created_at', startDt.toIso8601String())
              .lte('created_at', endDt.toIso8601String());

          if (_selectedUnitId != null) {
            final usersInUnit = await _supabase
                .from('User')
                .select('id_user')
                .eq('id_unit', _selectedUnitId!);
            final userIds = (usersInUnit as List).map((u) => u['id_user'].toString()).toList();
            if (userIds.isEmpty) {
              return List.generate(isDaily ? 1 : daysInMonth, (i) => _ChartBarData(
                date: isDaily ? _selectedDate!.day : i + 1, temuan: 0, penyelesaian: 0));
            }
            query = query.inFilter('id_pelapor', userIds);
          }

          final List<dynamic> res = await query;
          if (isDaily) {
            return [_ChartBarData(
              date: _selectedDate!.day,
              temuan: res.length,
              penyelesaian: res.where((t) => t['status'] == 'Selesai').length,
            )];
          }
          final Map<int, int> laporanMap = {}, selesaiMap = {};
          for (final t in res) {
            final dt = DateTime.tryParse(t['created_at']?.toString() ?? '');
            if (dt == null) continue;
            laporanMap[dt.day] = (laporanMap[dt.day] ?? 0) + 1;
            if (t['status'] == 'Selesai') selesaiMap[dt.day] = (selesaiMap[dt.day] ?? 0) + 1;
          }
          return List.generate(daysInMonth, (i) => _ChartBarData(
            date: i + 1, temuan: laporanMap[i + 1] ?? 0, penyelesaian: selesaiMap[i + 1] ?? 0));
        }
      } else if (type == 'KTS Production') {
        // Tab 0 = Members, Tab 1 = Recurring Findings
        if (_activeTabIndex == 1) {
          // Recurring tab KTS: group by bulan sesuai filter recurring
          final fromStr = _recurringFrom.toIso8601String();
          final toStr = DateTime(_recurringTo.year, _recurringTo.month + 1, 0, 23, 59, 59).toIso8601String();
          var query = _supabase
              .from('temuan')
              .select('created_at, id_penyelesaian')
              .eq('jenis_temuan', 'KTS Production')
              .gte('created_at', fromStr)
              .lte('created_at', toStr);
          if (_recurringUserId != null) query = query.eq('id_user', _recurringUserId!);

          final List<dynamic> res = await query;
          final Map<String, int> temuanMap = {}, selesaiMap = {};
          for (final t in res) {
            final dt = DateTime.tryParse(t['created_at']?.toString() ?? '');
            if (dt == null) continue;
            final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
            temuanMap[key] = (temuanMap[key] ?? 0) + 1;
            if (t['id_penyelesaian'] != null) selesaiMap[key] = (selesaiMap[key] ?? 0) + 1;
          }
          final result = <_ChartBarData>[];
          DateTime cur = DateTime(_recurringFrom.year, _recurringFrom.month);
          final endMonth = DateTime(_recurringTo.year, _recurringTo.month);
          int idx = 1;
          while (!cur.isAfter(endMonth)) {
            final key = '${cur.year}-${cur.month.toString().padLeft(2, '0')}';
            result.add(_ChartBarData(date: idx++, temuan: temuanMap[key] ?? 0, penyelesaian: selesaiMap[key] ?? 0));
            cur = DateTime(cur.year, cur.month + 1);
          }
          return result;

        } else {
          // Tab 0 = Members: filter by unit (sama logika dengan 5R Members)
          var query = _supabase
              .from('temuan')
              .select('created_at, id_penyelesaian, id_user')
              .eq('jenis_temuan', 'KTS Production')
              .gte('created_at', startDt.toIso8601String())
              .lte('created_at', endDt.toIso8601String());

          if (_selectedUnitId != null) {
            final usersInUnit = await _supabase
                .from('User')
                .select('id_user')
                .eq('id_unit', _selectedUnitId!);
            final userIds = (usersInUnit as List).map((u) => u['id_user'].toString()).toList();
            if (userIds.isEmpty) {
              return List.generate(isDaily ? 1 : daysInMonth, (i) => _ChartBarData(
                date: isDaily ? _selectedDate!.day : i + 1, temuan: 0, penyelesaian: 0));
            }
            query = query.inFilter('id_user', userIds);
          }

          final List<dynamic> res = await query;
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

      } else {
        // 5R — chart sesuai tab aktif
        if (_activeTabIndex == 0) {
          // ── Members: filter by unit (sama persis dengan get_anggota_stats logic)
          var query = _supabase
              .from('temuan')
              .select('created_at, id_penyelesaian, id_user, id_unit')
              .neq('jenis_temuan', 'KTS Production')
              .gte('created_at', startDt.toIso8601String())
              .lte('created_at', endDt.toIso8601String());

          // Filter unit: ambil id_user yang unit-nya sesuai, lalu filter temuan
          if (_selectedUnitId != null) {
            // Ambil dulu user yang ada di unit ini
            final usersInUnit = await _supabase
                .from('User')
                .select('id_user')
                .eq('id_unit', _selectedUnitId!);
            final userIds = (usersInUnit as List).map((u) => u['id_user'].toString()).toList();
            if (userIds.isEmpty) {
              return List.generate(isDaily ? 1 : daysInMonth, (i) => _ChartBarData(
                date: isDaily ? _selectedDate!.day : i + 1, temuan: 0, penyelesaian: 0));
            }
            query = query.inFilter('id_user', userIds);
          }

          final List<dynamic> res = await query;
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

        } else if (_activeTabIndex == 1) {
          // ── Inspection: filter by role (sama persis dengan get_inspeksi_stats logic)
          final roleBackend = ['Eksekutif', 'Profesional', 'Visitor'][
              _translatedRoles.indexOf(_selectedInspectionRole).clamp(0, 2)];

          var query = _supabase
              .from('temuan')
              .select('created_at, id_penyelesaian')
              .neq('jenis_temuan', 'KTS Production')
              .gte('created_at', startDt.toIso8601String())
              .lte('created_at', endDt.toIso8601String());

          // Filter role sesuai is_eksekutif / is_pro / is_visitor
          if (roleBackend == 'Eksekutif') {
            query = query.eq('is_eksekutif', true);
          } else if (roleBackend == 'Profesional') {
            query = query.eq('is_pro', true);
          } else {
            query = query.eq('is_visitor', true);
          }

          final List<dynamic> res = await query;
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

        } else if (_activeTabIndex == 2) {
          // ── Location: filter by level column (sama persis dengan get_lokasi_stats logic)
          final levelBackend = ['lokasi', 'unit', 'subunit', 'area'][
              _translatedLocationLevels.indexOf(_selectedLocationLevel).clamp(0, 3)];

          // Kolom id yang dipakai di tabel temuan sesuai level
          final Map<String, String> idColMap = {
            'lokasi': 'id_lokasi',
            'unit': 'id_unit',
            'subunit': 'id_subunit',
            'area': 'id_area',
          };
          final idCol = idColMap[levelBackend] ?? 'id_lokasi';

          var query = _supabase
              .from('temuan')
              .select('created_at, id_penyelesaian, $idCol')
              .neq('jenis_temuan', 'KTS Production')
              .gte('created_at', startDt.toIso8601String())
              .lte('created_at', endDt.toIso8601String())
              .not(idCol, 'is', null); // hanya yang punya lokasi

          final List<dynamic> res = await query;
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

        } else {
          // ── Recurring tab (tab index 3): gunakan filter periode recurring
          final fromStr = _recurringFrom.toIso8601String();
          final toStr = DateTime(_recurringTo.year, _recurringTo.month + 1, 0, 23, 59, 59).toIso8601String();
          var query = _supabase
              .from('temuan')
              .select('created_at, id_penyelesaian')
              .neq('jenis_temuan', 'KTS Production')
              .gte('created_at', fromStr)
              .lte('created_at', toStr);
          if (_recurringUserId != null) query = query.eq('id_user', _recurringUserId!);

          final List<dynamic> res = await query;
          // Chart recurring: group by bulan
          final Map<String, int> temuanMap = {}, selesaiMap = {};
          for (final t in res) {
            final dt = DateTime.tryParse(t['created_at']?.toString() ?? '');
            if (dt == null) continue;
            final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
            temuanMap[key] = (temuanMap[key] ?? 0) + 1;
            if (t['id_penyelesaian'] != null) selesaiMap[key] = (selesaiMap[key] ?? 0) + 1;
          }
          // Bangun data per bulan sesuai range recurring
          final result = <_ChartBarData>[];
          DateTime cur = DateTime(_recurringFrom.year, _recurringFrom.month);
          final endMonth = DateTime(_recurringTo.year, _recurringTo.month);
          int idx = 1;
          while (!cur.isAfter(endMonth)) {
            final key = '${cur.year}-${cur.month.toString().padLeft(2, '0')}';
            result.add(_ChartBarData(
              date: idx++,
              temuan: temuanMap[key] ?? 0,
              penyelesaian: selesaiMap[key] ?? 0,
            ));
            cur = DateTime(cur.year, cur.month + 1);
          }
          return result;
        }
      }
    } catch (e) {
      debugPrint('Error fetching chart data: $e');
      return [];
    }
  }

  Future<List<_ChartBarData>> _fetchRecurringChartData() async {
    try {
      final fromStr = _recurringFrom.toIso8601String();
      final toStr = DateTime(_recurringTo.year, _recurringTo.month + 1, 0, 23, 59, 59).toIso8601String();
      
      if (_selectedFindingType == 'Accident') {
        var query = _supabase
            .from('accident_report')
            .select('created_at, status')
            .gte('created_at', fromStr)
            .lte('created_at', toStr);
        if (_recurringUserId != null) query = query.eq('id_pelapor', _recurringUserId!);
        final List<dynamic> res = await query;
        
        // Group by month
        final Map<String, int> laporanMap = {};
        final Map<String, int> selesaiMap = {};
        for (final t in res) {
          final dt = DateTime.tryParse(t['created_at']?.toString() ?? '');
          if (dt == null) continue;
          final key = '${dt.year}-${dt.month.toString().padLeft(2,'0')}';
          laporanMap[key] = (laporanMap[key] ?? 0) + 1;
          if (t['status'] == 'Selesai') selesaiMap[key] = (selesaiMap[key] ?? 0) + 1;
        }
        
        return _buildMonthlyChartData(laporanMap, selesaiMap);
        
      } else {
        // 5R atau KTS
        var query = _supabase
            .from('temuan')
            .select('created_at, id_penyelesaian, jenis_temuan')
            .gte('created_at', fromStr)
            .lte('created_at', toStr);
        if (_selectedFindingType == 'KTS Production') {
          query = query.eq('jenis_temuan', 'KTS Production');
        } else {
          query = query.neq('jenis_temuan', 'KTS Production');
        }
        if (_recurringUserId != null) query = query.eq('id_user', _recurringUserId!);
        final List<dynamic> res = await query;
        
        final Map<String, int> temuanMap = {};
        final Map<String, int> selesaiMap = {};
        for (final t in res) {
          final dt = DateTime.tryParse(t['created_at']?.toString() ?? '');
          if (dt == null) continue;
          final key = '${dt.year}-${dt.month.toString().padLeft(2,'0')}';
          temuanMap[key] = (temuanMap[key] ?? 0) + 1;
          if (t['id_penyelesaian'] != null) selesaiMap[key] = (selesaiMap[key] ?? 0) + 1;
        }
        
        return _buildMonthlyChartData(temuanMap, selesaiMap);
      }
    } catch (e) {
      debugPrint('Error fetching recurring chart: $e');
      return [];
    }
  }

  /// Chart recurring khusus KTS — digroup per topic (judul_temuan) sesuai yang tampil di tabel
  Future<List<_ChartBarData>> _fetchKtsRecurringChartData() async {
    try {
      final fromStr = _recurringFrom.toIso8601String();
      final toStr = DateTime(_recurringTo.year, _recurringTo.month + 1, 0, 23, 59, 59).toIso8601String();

      var query = _supabase
          .from('temuan')
          .select('created_at, id_penyelesaian')
          .eq('jenis_temuan', 'KTS Production')
          .gte('created_at', fromStr)
          .lte('created_at', toStr);
      if (_recurringUserId != null) query = query.eq('id_user', _recurringUserId!);

      final List<dynamic> res = await query;

      final Map<String, int> temuanMap = {};
      final Map<String, int> selesaiMap = {};
      for (final t in res) {
        final dt = DateTime.tryParse(t['created_at']?.toString() ?? '');
        if (dt == null) continue;
        final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        temuanMap[key] = (temuanMap[key] ?? 0) + 1;
        if (t['id_penyelesaian'] != null) selesaiMap[key] = (selesaiMap[key] ?? 0) + 1;
      }

      return _buildMonthlyChartData(temuanMap, selesaiMap);
    } catch (e) {
      debugPrint('Error fetching KTS recurring chart: $e');
      return [];
    }
  }

  /// Chart recurring khusus Accident — digroup per bulan dari accident_report
  Future<List<_ChartBarData>> _fetchAccidentRecurringChartData() async {
    try {
      final fromStr = _recurringFrom.toIso8601String();
      final toStr = DateTime(_recurringTo.year, _recurringTo.month + 1, 0, 23, 59, 59).toIso8601String();

      var query = _supabase
          .from('accident_report')
          .select('created_at, status')
          .gte('created_at', fromStr)
          .lte('created_at', toStr);
      if (_recurringUserId != null) query = query.eq('id_pelapor', _recurringUserId!);

      final List<dynamic> res = await query;

      final Map<String, int> laporanMap = {};
      final Map<String, int> selesaiMap = {};
      for (final t in res) {
        final dt = DateTime.tryParse(t['created_at']?.toString() ?? '');
        if (dt == null) continue;
        final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        laporanMap[key] = (laporanMap[key] ?? 0) + 1;
        if (t['status'] == 'Selesai') selesaiMap[key] = (selesaiMap[key] ?? 0) + 1;
      }

      return _buildMonthlyChartData(laporanMap, selesaiMap);
    } catch (e) {
      debugPrint('Error fetching Accident recurring chart: $e');
      return [];
    }
  }

  List<_ChartBarData> _buildMonthlyChartData(
      Map<String, int> primaryMap, Map<String, int> secondaryMap) {
    final result = <_ChartBarData>[];
    DateTime current = DateTime(_recurringFrom.year, _recurringFrom.month);
    final end = DateTime(_recurringTo.year, _recurringTo.month);
    int idx = 1;
    while (!current.isAfter(end)) {
      final key = '${current.year}-${current.month.toString().padLeft(2,'0')}';
      result.add(_ChartBarData(
        date: idx++,
        temuan: primaryMap[key] ?? 0,
        penyelesaian: secondaryMap[key] ?? 0,
      ));
      current = DateTime(current.year, current.month + 1);
    }
    return result;
  }

  // ── KTS Fetch Methods ────────────────────────────────────────────────────────
  Future<List<MemberData>> _fetchKtsAnggotaData(int month, int year, String? unitId) async {
    try {
      // Langsung query dari tabel temuan jenis_temuan = KTS Production
      var temuanQuery = _supabase
          .from('temuan')
          .select('id_user, id_penyelesaian, User_Creator:User!temuan_id_user_fkey(nama, gambar_user, id_unit, unit!user_id_unit_fkey(nama_unit))')
          .eq('jenis_temuan', 'KTS Production')
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at', DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String());

      final List<dynamic> temuanRes = await temuanQuery;

      if (temuanRes.isEmpty) return [];

      // Grouping per user
      final Map<String, Map<String, dynamic>> grouped = {};
      for (final t in temuanRes) {
        final user = t['User_Creator'] as Map<String, dynamic>?;
        if (user == null) continue;
        final uid = t['id_user']?.toString() ?? '';
        if (uid.isEmpty) continue;

        // Filter unit jika ada
        if (unitId != null) {
          final userUnitId = user['id_unit']?.toString();
          if (userUnitId != unitId) continue;
        }

        grouped.putIfAbsent(uid, () => {
          'nama': user['nama'] ?? '-',
          'gambar_user': user['gambar_user'],
          'unitName': (user['unit'] as Map<String, dynamic>?)?['nama_unit'],
          'temuan': 0,
          'selesai': 0,
        });
        grouped[uid]!['temuan'] = (grouped[uid]!['temuan'] as int) + 1;
        if (t['id_penyelesaian'] != null) {
          grouped[uid]!['selesai'] = (grouped[uid]!['selesai'] as int) + 1;
        }
      }

      final currentUserId = _supabase.auth.currentUser?.id;
      return grouped.entries.map((e) {
        final uid = e.key;
        final v = e.value;
        return MemberData(
          name: v['nama'] as String? ?? '-',
          unitName: v['unitName'] as String?,
          findings: v['temuan'] as int,
          completed: v['selesai'] as int,
          isSelf: uid == currentUserId,
          avatarUrl: v['gambar_user'] as String?,
          avatarColor: const Color(0xFFFBBF24),
        );
      }).toList()
        ..sort((a, b) => b.findings.compareTo(a.findings));
    } catch (e) {
      debugPrint('Error fetching KTS Anggota: $e');
      return [];
    }
  }

  Future<List<InspectionData>> _fetchKtsInspeksiData(int month, int year, String role) async {
    try {
      final List<dynamic> response = await _supabase
          .from('temuan')
          .select('id_user, User_Creator:User!temuan_id_user_fkey(nama)')
          .eq('jenis_temuan', 'KTS Production')
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at', DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String());
      final Map<String, Map<String, dynamic>> grouped = {};
      for (final item in response) {
        final user = item['User_Creator'] as Map<String, dynamic>?;
        if (user == null) continue;
        final userId = item['id_user']?.toString() ?? '';
        grouped.putIfAbsent(userId, () => {'nama': user['nama'] ?? '', 'temuan': 0});
        grouped[userId]!['temuan'] = (grouped[userId]!['temuan'] as int) + 1;
      }
      return grouped.values.map((item) => InspectionData(
        name: item['nama'] as String, findings: item['temuan'] as int,
      )).toList()..sort((a, b) => b.findings.compareTo(a.findings));
    } catch (e) { return []; }
  }

  Future<List<LocationData>> _fetchKtsLokasiData(int month, int year, String level) async {
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
          .eq('jenis_temuan', 'KTS Production')
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

      return locations.map<LocationData>((loc) {
        final id = loc[idCol]?.toString() ?? '';
        return LocationData(
          name: loc[nameCol]?.toString() ?? '-',
          pic: picMap[id] ?? 'PIC belum diatur',
          value: (countMap[id] ?? 0).toString(),
        );
      }).toList()
        ..sort((a, b) => (int.tryParse(b.value ?? '0') ?? 0)
            .compareTo(int.tryParse(a.value ?? '0') ?? 0));
    } catch (e) {
      debugPrint('Error fetching KTS Lokasi: $e');
      return [];
    }
  }

  Future<List<MemberData>> _fetchKtsAnggotaDataDaily(DateTime date, String? unitId) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final List<dynamic> temuanRes = await _supabase
          .from('temuan')
          .select('id_user, id_penyelesaian, User_Creator:User!temuan_id_user_fkey(nama, gambar_user, id_unit, unit!user_id_unit_fkey(nama_unit))')
          .eq('jenis_temuan', 'KTS Production')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());

      if (temuanRes.isEmpty) return [];

      final Map<String, Map<String, dynamic>> grouped = {};
      for (final t in temuanRes) {
        final user = t['User_Creator'] as Map<String, dynamic>?;
        if (user == null) continue;
        final uid = t['id_user']?.toString() ?? '';
        if (uid.isEmpty) continue;

        if (unitId != null) {
          final userUnitId = user['id_unit']?.toString();
          if (userUnitId != unitId) continue;
        }

        grouped.putIfAbsent(uid, () => {
          'nama': user['nama'] ?? '-',
          'gambar_user': user['gambar_user'],
          'unitName': (user['unit'] as Map<String, dynamic>?)?['nama_unit'],
          'temuan': 0,
          'selesai': 0,
        });
        grouped[uid]!['temuan'] = (grouped[uid]!['temuan'] as int) + 1;
        if (t['id_penyelesaian'] != null) {
          grouped[uid]!['selesai'] = (grouped[uid]!['selesai'] as int) + 1;
        }
      }

      final currentUserId = _supabase.auth.currentUser?.id;
      return grouped.entries.map((e) {
        final uid = e.key;
        final v = e.value;
        return MemberData(
          name: v['nama'] as String? ?? '-',
          unitName: v['unitName'] as String?,
          findings: v['temuan'] as int,
          completed: v['selesai'] as int,
          isSelf: uid == currentUserId,
          avatarUrl: v['gambar_user'] as String?,
          avatarColor: const Color(0xFFFBBF24),
        );
      }).toList()
        ..sort((a, b) => b.findings.compareTo(a.findings));
    } catch (e) {
      debugPrint('Error fetching KTS Anggota daily: $e');
      return [];
    }
  }

  Future<List<InspectionData>> _fetchKtsInspeksiDataDaily(DateTime date, String role) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final List<dynamic> response = await _supabase.from('temuan')
          .select('id_user, User_Creator:User!temuan_id_user_fkey(nama)')
          .eq('jenis_temuan', 'KTS Production')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());
      final Map<String, Map<String, dynamic>> grouped = {};
      for (final item in response) {
        final user = item['User_Creator'] as Map<String, dynamic>?;
        if (user == null) continue;
        final userId = item['id_user']?.toString() ?? '';
        grouped.putIfAbsent(userId, () => {'nama': user['nama'] ?? '', 'temuan': 0});
        grouped[userId]!['temuan'] = (grouped[userId]!['temuan'] as int) + 1;
      }
      return grouped.values.map((item) => InspectionData(
        name: item['nama'] as String, findings: item['temuan'] as int,
      )).toList()..sort((a, b) => b.findings.compareTo(a.findings));
    } catch (e) { return []; }
  }

  Future<List<LocationData>> _fetchKtsLokasiDataDaily(DateTime date, String level) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final levelLower = level.toLowerCase();
      final idMap = {'lokasi': 'id_lokasi', 'unit': 'id_unit', 'subunit': 'id_subunit', 'area': 'id_area'};
      final nameMap = {'lokasi': 'nama_lokasi', 'unit': 'nama_unit', 'subunit': 'nama_subunit', 'area': 'nama_area'};
      final idCol = idMap[levelLower] ?? 'id_lokasi';
      final nameCol = nameMap[levelLower] ?? 'nama_lokasi';
      final locations = await _supabase.from(levelLower).select('$idCol, $nameCol');
      final temuanList = await _supabase.from('temuan').select(idCol)
          .eq('jenis_temuan', 'KTS Production')
          .gte('created_at', start.toIso8601String()).lte('created_at', end.toIso8601String());
      final Map<String, int> countMap = {};
      for (final t in temuanList) {
        final id = t[idCol]?.toString() ?? '';
        if (id.isEmpty) continue;
        countMap[id] = (countMap[id] ?? 0) + 1;
      }
      return (locations as List<dynamic>).map((loc) => LocationData(
        name: loc[nameCol]?.toString() ?? '-', pic: '-',
        value: (countMap[loc[idCol]?.toString() ?? ''] ?? 0).toString(),
      )).toList()..sort((a, b) => (int.tryParse(b.value ?? '0') ?? 0).compareTo(int.tryParse(a.value ?? '0') ?? 0));
    } catch (e) { return []; }
  }

  // ── Accident Report Fetch Methods ────────────────────────────────────────────
  Future<List<MemberData>> _fetchAccidentAnggotaData(int month, int year, String? unitId) async {
    try {
      var query = _supabase
          .from('accident_report')
          .select('id_pelapor, status, id_unit')
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at', DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String());
      if (unitId != null) query = query.eq('id_unit', unitId);
      final List<dynamic> response = await query;

      if (response.isEmpty) return [];

      final Map<String, Map<String, dynamic>> grouped = {};
      for (final item in response) {
        final userId = item['id_pelapor']?.toString() ?? '';
        if (userId.isEmpty) continue;
        grouped.putIfAbsent(userId, () => {'temuan': 0, 'selesai': 0});
        grouped[userId]!['temuan'] = (grouped[userId]!['temuan'] as int) + 1;
        if ((item['status'] ?? '') == 'Selesai') {
          grouped[userId]!['selesai'] = (grouped[userId]!['selesai'] as int) + 1;
        }
      }

      final userIds = grouped.keys.toList();
      final List<dynamic> usersRes = await _supabase
          .from('User')
          .select('id_user, nama, gambar_user, id_unit, unit!user_id_unit_fkey(nama_unit)')
          .inFilter('id_user', userIds);

      final currentUserId = _supabase.auth.currentUser?.id;
      return usersRes.map((u) {
        final uid = u['id_user']?.toString() ?? '';
        final stats = grouped[uid] ?? {'temuan': 0, 'selesai': 0};
        return MemberData(
          name: u['nama'] as String? ?? '-',
          unitName: (u['unit'] as Map<String, dynamic>?)?['nama_unit'] as String?,
          findings: stats['temuan'] as int,
          completed: stats['selesai'] as int,
          isSelf: uid == currentUserId,
          avatarUrl: u['gambar_user'] as String?,
          avatarColor: const Color(0xFFEF4444),
        );
      }).toList()..sort((a, b) => b.findings.compareTo(a.findings));
    } catch (e) { return []; }
  }

  Future<List<LocationData>> _fetchAccidentLokasiData(int month, int year, String level) async {
    try {
      final levelLower = level.toLowerCase();
      final idMap = {'lokasi': 'id_lokasi', 'unit': 'id_unit', 'subunit': 'id_subunit', 'area': 'id_area'};
      final nameMap = {'lokasi': 'nama_lokasi', 'unit': 'nama_unit', 'subunit': 'nama_subunit', 'area': 'nama_area'};
      final idCol = idMap[levelLower] ?? 'id_lokasi';
      final nameCol = nameMap[levelLower] ?? 'nama_lokasi';

      // Step 1: Ambil semua lokasi/unit/subunit/area
      final List<dynamic> locations = await _supabase
          .from(levelLower)
          .select('$idCol, $nameCol');

      // Step 2: Hitung accident_report per lokasi bulan ini
      final List<dynamic> reportRes = await _supabase
          .from('accident_report')
          .select(idCol)
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at', DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String())
          .not(idCol, 'is', null);

      final Map<String, int> countMap = {};
      for (final t in reportRes) {
        final id = t[idCol]?.toString() ?? '';
        if (id.isEmpty) continue;
        countMap[id] = (countMap[id] ?? 0) + 1;
      }

      // Step 3: Ambil PIC per lokasi dari tabel User
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
          name: loc[nameCol]?.toString() ?? '-',
          pic: picMap[id] ?? 'PIC belum diatur',
          value: (countMap[id] ?? 0).toString(),
        );
      }).toList()
        ..sort((a, b) => (int.tryParse(b.value ?? '0') ?? 0)
            .compareTo(int.tryParse(a.value ?? '0') ?? 0));
    } catch (e) {
      debugPrint('Error fetching Accident Lokasi: $e');
      return [];
    }
  }

  Future<List<MemberData>> _fetchAccidentAnggotaDataDaily(DateTime date, String? unitId) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
      var query = _supabase
          .from('accident_report')
          .select('id_pelapor, status')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());
      if (unitId != null) query = query.eq('id_unit', unitId);
      final List<dynamic> response = await query;

      if (response.isEmpty) return [];

      final Map<String, Map<String, dynamic>> grouped = {};
      for (final item in response) {
        final userId = item['id_pelapor']?.toString() ?? '';
        if (userId.isEmpty) continue;
        grouped.putIfAbsent(userId, () => {'temuan': 0, 'selesai': 0});
        grouped[userId]!['temuan'] = (grouped[userId]!['temuan'] as int) + 1;
        if ((item['status'] ?? '') == 'Selesai') {
          grouped[userId]!['selesai'] = (grouped[userId]!['selesai'] as int) + 1;
        }
      }

      final userIds = grouped.keys.toList();
      final List<dynamic> usersRes = await _supabase
          .from('User')
          .select('id_user, nama, gambar_user, id_unit, unit!user_id_unit_fkey(nama_unit)')
          .inFilter('id_user', userIds);

      final currentUserId = _supabase.auth.currentUser?.id;
      return usersRes.map((u) {
        final uid = u['id_user']?.toString() ?? '';
        final stats = grouped[uid] ?? {'temuan': 0, 'selesai': 0};
        return MemberData(
          name: u['nama'] as String? ?? '-',
          unitName: (u['unit'] as Map<String, dynamic>?)?['nama_unit'] as String?,
          findings: stats['temuan'] as int,
          completed: stats['selesai'] as int,
          isSelf: uid == currentUserId,
          avatarUrl: u['gambar_user'] as String?,
          avatarColor: const Color(0xFFEF4444),
        );
      }).toList()..sort((a, b) => b.findings.compareTo(a.findings));
    } catch (e) { return []; }
  }

  Future<List<LocationData>> _fetchAccidentLokasiDataDaily(DateTime date, String level) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final levelLower = level.toLowerCase();
      final idMap = {'lokasi': 'id_lokasi', 'unit': 'id_unit', 'subunit': 'id_subunit', 'area': 'id_area'};
      final nameMap = {'lokasi': 'nama_lokasi', 'unit': 'nama_unit', 'subunit': 'nama_subunit', 'area': 'nama_area'};
      final idCol = idMap[levelLower] ?? 'id_lokasi';
      final nameCol = nameMap[levelLower] ?? 'nama_lokasi';
      final locations = await _supabase.from(levelLower).select('$idCol, $nameCol');
      final reportList = await _supabase.from('accident_report').select(idCol)
          .gte('created_at', start.toIso8601String()).lte('created_at', end.toIso8601String());
      final Map<String, int> countMap = {};
      for (final t in reportList) {
        final id = t[idCol]?.toString() ?? '';
        if (id.isEmpty) continue;
        countMap[id] = (countMap[id] ?? 0) + 1;
      }
      return (locations as List<dynamic>).map((loc) => LocationData(
        name: loc[nameCol]?.toString() ?? '-', pic: '-',
        value: (countMap[loc[idCol]?.toString() ?? ''] ?? 0).toString(),
      )).toList()..sort((a, b) => (int.tryParse(b.value ?? '0') ?? 0).compareTo(int.tryParse(a.value ?? '0') ?? 0));
    } catch (e) { return []; }
  }

  /// Fetch accident reports yang berulang (grouped by judul/penyebab yang mirip)
  Future<List<Map<String, dynamic>>> _fetchAccidentRecurringData() async {
    try {
      final locale = widget.lang == 'ID' ? 'id_ID' : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');
      
      // 1. Buat base query TANPA .order() terlebih dahulu
      var query = _supabase
          .from('accident_report')
          .select('''
            id_laporan, judul, deskripsi, foto_bukti, created_at, status,
            tanggal_kejadian, tingkat_keparahan, penyebab, tindakan_diambil,
            id_lokasi, id_unit, id_subunit, id_area,
            lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area),
            User_Pelapor:User!accident_report_id_pelapor_fkey(nama, gambar_user)
          ''')
          .gte('created_at', _recurringFrom.toIso8601String())
          .lte('created_at', DateTime(
              _recurringTo.year, _recurringTo.month + 1, 0, 23, 59, 59).toIso8601String());

      // 2. Tambahkan filter kondisional (.eq) di sini
      if (_recurringUserId != null) {
        query = query.eq('id_pelapor', _recurringUserId!);
      }

      // 3. Tambahkan .order() di tahap paling akhir saat akan mengeksekusi query (await)
      final List<dynamic> response = await query.order('created_at', ascending: false);
      
      final reports = List<Map<String, dynamic>>.from(response);

      if (reports.isEmpty) return [];

      // Grouping sederhana berdasarkan tingkat_keparahan + kesamaan penyebab
      final Map<String, List<Map<String, dynamic>>> groups = {};
      for (final r in reports) {
        final key = (r['tingkat_keparahan'] ?? '').toString().toLowerCase();
        groups.putIfAbsent(key, () => []).add(r);
      }

      // Hanya kembalikan grup dengan ≥ 2 laporan
      final result = <Map<String, dynamic>>[];
      groups.forEach((key, items) {
        if (items.length < 2) return;
        final first = items.first;
        String location = '';
        if (first['area'] != null) location = first['area']['nama_area'] ?? '';
        else if (first['subunit'] != null) location = first['subunit']['nama_subunit'] ?? '';
        else if (first['unit'] != null) location = first['unit']['nama_unit'] ?? '';
        else if (first['lokasi'] != null) location = first['lokasi']['nama_lokasi'] ?? '';

        result.add({
          'topic': first['tingkat_keparahan'] ?? '-',
          'locationArea': location,
          'total': items.length,
          'imageUrl': first['foto_bukti'],
          'reports': items,
        });
      });

      result.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
      return result;
    } catch (e) {
      debugPrint('Error fetching accident recurring: $e');
      return [];
    }
}

  Future<List<RecurringTopic>> _fetchRecurringData({bool ktsOnly = false}) async {
    try {
      var query = _supabase
          .from('temuan')
          .select('''
            id_temuan, judul_temuan, gambar_temuan, created_at, status_temuan,
            poin_temuan, target_waktu_selesai, jenis_temuan,
            id_lokasi, id_unit, id_subunit, id_area, id_penanggung_jawab,
            lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area),
            kategoritemuan(nama_kategoritemuan),
            is_pro, is_visitor, is_eksekutif, no_order, jumlah_item,
            penyelesaian!temuan_id_penyelesaian_fkey(*, User_Solver:User!id_user(nama, gambar_user)),
            User_Creator:User!temuan_id_user_fkey(nama, gambar_user),
            User_PIC:User!temuan_id_penanggung_jawab_fkey(nama, gambar_user),
            subkategoritemuan:id_subkategoritemuan_uuid(id_subkategoritemuan, nama_subkategoritemuan)
          ''')
          .gte('created_at', _recurringFrom.toIso8601String())
          .lte('created_at', DateTime(
              _recurringTo.year, _recurringTo.month + 1, 0, 23, 59, 59)
              .toIso8601String());

      // Filter berdasarkan jenis_temuan
      if (ktsOnly) {
        query = query.eq('jenis_temuan', 'KTS Production');
      } else {
        query = query.neq('jenis_temuan', 'KTS Production');
      }

      if (_recurringUserId != null) {
        query = query.eq('id_user', _recurringUserId!);
      }

      final List<dynamic> response =
          await query.order('created_at', ascending: false);
      final findings = List<Map<String, dynamic>>.from(response);

      if (findings.isEmpty) return [];

      final groups = _groupFindingsSemantic(findings);
      groups.sort((a, b) => b.total.compareTo(a.total));
      return groups;
    } catch (e) {
      debugPrint('Error fetching Recurring: $e');
      return [];
    }
  }

  /// Normalisasi teks: lowercase, hapus tanda baca, stemming sederhana
  String _normalizeText(String text) {
    // Lowercase
    String result = text.toLowerCase().trim();

    // Hapus tanda baca dan karakter spesial
    result = result.replaceAll(RegExp(r'[^\w\s]'), ' ');

    // Normalisasi spasi
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Stopwords Indonesia + Inggris yang umum
    const stopwords = {
      'yang', 'di', 'ke', 'dari', 'dan', 'atau', 'tidak', 'ada', 'pada',
      'dengan', 'untuk', 'ini', 'itu', 'adalah', 'sudah', 'belum', 'akan',
      'bisa', 'dapat', 'perlu', 'harus', 'karena', 'saat', 'masih', 'nya',
      'an', 'ter', 'me', 'ber', 'pe', 'se', 'the', 'a', 'is', 'in',
      'on', 'at', 'to', 'of', 'and', 'or', 'not', 'no', 'was', 'are',
      'be', 'has', 'had', 'have', 'do', 'does', 'did', 'but', 'by', 'as',
      'telah', 'sedang', 'juga', 'lebih', 'lagi', 'saja', 'pun',
      'agar', 'atas', 'bawah', 'dalam', 'luar', 'kiri', 'kanan', 'dekat',
      'jauh', 'besar', 'kecil', 'panjang', 'pendek', 'tinggi', 'rendah',
    };

    final words = result.split(' ')
        .where((w) => w.length > 1 && !stopwords.contains(w))
        .toList();

    // Stemming sederhana: potong akhiran umum Indonesia
    final stemmed = words.map((w) {
      if (w.endsWith('kan') && w.length > 5) return w.substring(0, w.length - 3);
      if (w.endsWith('an') && w.length > 4) return w.substring(0, w.length - 2);
      if (w.endsWith('i') && w.length > 3) return w.substring(0, w.length - 1);
      if (w.endsWith('nya') && w.length > 4) return w.substring(0, w.length - 3);
      if (w.endsWith('ing') && w.length > 4) return w.substring(0, w.length - 3);
      if (w.endsWith('ed') && w.length > 3) return w.substring(0, w.length - 2);
      return w;
    }).toList();

    return stemmed.join(' ');
  }

  /// Hitung TF-IDF vector untuk setiap dokumen
  List<Map<String, double>> _computeTfIdf(List<String> docs) {
    // Tokenize semua dokumen
    final tokenized = docs.map((d) => d.split(' ').where((w) => w.isNotEmpty).toList()).toList();

    // Hitung DF (document frequency) per term
    final df = <String, int>{};
    for (final tokens in tokenized) {
      final unique = tokens.toSet();
      for (final t in unique) {
        df[t] = (df[t] ?? 0) + 1;
      }
    }

    final n = docs.length;
    final vectors = <Map<String, double>>[];

    for (final tokens in tokenized) {
      if (tokens.isEmpty) {
        vectors.add({});
        continue;
      }

      // TF: frekuensi term dalam dokumen ini
      final tf = <String, int>{};
      for (final t in tokens) {
        tf[t] = (tf[t] ?? 0) + 1;
      }

      // TF-IDF
      final vec = <String, double>{};
      for (final entry in tf.entries) {
        final termTf = entry.value / tokens.length;
        final idfLog = (n > 1 && (df[entry.key] ?? 0) < n)
            ? (1 + (n.toDouble() / df[entry.key]!.toDouble()))
            : 1.0;
        vec[entry.key] = termTf * idfLog;
      }
      vectors.add(vec);
    }

    return vectors;
  }

  /// Versi yang lebih sederhana dan reliable
  double _similarity(Map<String, double> a, Map<String, double> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    double dot = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (final k in a.keys) {
      dot += a[k]! * (b[k] ?? 0.0);
      normA += a[k]! * a[k]!;
    }
    for (final v in b.values) {
      normB += v * v;
    }
    if (normA <= 0 || normB <= 0) return 0.0;
    return dot / (math.sqrt(normA) * math.sqrt(normB));
  }

  /// Main semantic grouping — TF-IDF + Cosine Similarity + konteks
  List<RecurringTopic> _groupFindingsSemantic(List<Map<String, dynamic>> findings) {
    const double threshold = 0.30;
    final limit = math.min(findings.length, 500);

    // Pre-compute normalized tokens per finding
    final tokensList = List<Set<String>>.generate(limit, (i) {
      final f = findings[i];
      final judul = _normalizeText(f['judul_temuan']?.toString() ?? '');
      final kat = _normalizeText(
          (f['kategoritemuan'] as Map<String, dynamic>?)?['nama_kategoritemuan']?.toString() ?? '');
      final subkat = _normalizeText(
          (f['subkategoritemuan'] as Map<String, dynamic>?)?['nama_subkategoritemuan']?.toString() ?? '');
      final deskripsi = _normalizeText(f['deskripsi_temuan']?.toString() ?? '');
      // Judul paling penting — duplikasi untuk bobot
      final allTokens = [
        ...judul.split(' '), ...judul.split(' '), ...judul.split(' '),
        ...kat.split(' '), ...kat.split(' '),
        ...subkat.split(' '),
        ...deskripsi.split(' '),
      ].where((w) => w.length > 1).toSet();
      return allTokens;
    });

    // Jaccard similarity — jauh lebih cepat dari TF-IDF
    double jaccard(Set<String> a, Set<String> b) {
      if (a.isEmpty || b.isEmpty) return 0.0;
      final intersection = a.intersection(b).length;
      final union = a.union(b).length;
      return union == 0 ? 0.0 : intersection / union;
    }

    // Union-Find
    final parent = List<int>.generate(limit, (i) => i);
    int find(int x) {
      while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }
      return x;
    }
    void union(int x, int y) {
      final px = find(x), py = find(y);
      if (px != py) parent[px] = py;
    }

    for (int i = 0; i < limit; i++) {
      for (int j = i + 1; j < limit; j++) {
        // Jangan campur 5R dan KTS
        final jenisI = (findings[i]['jenis_temuan'] ?? '').toString();
        final jenisJ = (findings[j]['jenis_temuan'] ?? '').toString();
        if (jenisI != jenisJ) continue;

        // Fast pre-check: jika kategori berbeda, skip
        final katI = (findings[i]['kategoritemuan'] as Map<String, dynamic>?)?['nama_kategoritemuan']?.toString() ?? '';
        final katJ = (findings[j]['kategoritemuan'] as Map<String, dynamic>?)?['nama_kategoritemuan']?.toString() ?? '';
        if (katI.isNotEmpty && katJ.isNotEmpty && katI != katJ) continue;

        if (jaccard(tokensList[i], tokensList[j]) >= threshold) {
          union(i, j);
        }
      }
    }

    // Kumpulkan grup
    final groupMap = <int, List<int>>{};
    for (int i = 0; i < limit; i++) {
      groupMap.putIfAbsent(find(i), () => []).add(i);
    }

    final result = <RecurringTopic>[];
    groupMap.forEach((root, indices) {
      if (indices.length < 2) return;

      final groupFindings = indices.map((i) => findings[i]).toList();
      final first = groupFindings.first;
      final isKts = (first['jenis_temuan'] ?? '') == 'KTS Production';

      // Label paling representatif
      final titles = groupFindings
          .map((f) => f['judul_temuan']?.toString() ?? '')
          .where((t) => t.isNotEmpty)
          .toList()
        ..sort((a, b) => a.length.compareTo(b.length));
      final label = titles.firstWhere((t) => t.length >= 5,
          orElse: () => titles.isNotEmpty ? titles.first : '-');

      String location = '';
      if (!isKts) {
        if (first['area'] != null) location = first['area']['nama_area'] ?? '';
        else if (first['subunit'] != null) location = first['subunit']['nama_subunit'] ?? '';
        else if (first['unit'] != null) location = first['unit']['nama_unit'] ?? '';
        else if (first['lokasi'] != null) location = first['lokasi']['nama_lokasi'] ?? '';
      } else {
        location = (first['no_order'] ?? '').toString();
        if (location.isEmpty) location = '-';
      }

      result.add(RecurringTopic(
        topic: label,
        locationArea: location,
        total: groupFindings.length,
        imageUrl: first['gambar_temuan'] as String?,
        findings: groupFindings,
      ));
    });

    result.sort((a, b) => b.total.compareTo(a.total));
    return result;
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
                borderRadius: BorderRadius.horizontal(left: Radius.circular(14)),
              ),
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
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ]),
        ),
      ),
    );
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
        separatorBuilder: (_, __) => Divider(height: 1, color: _AppColors.divider, indent: 16),
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
        separatorBuilder: (_, __) => Divider(height: 1, color: _AppColors.divider, indent: 16),
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
        separatorBuilder: (_, __) => Divider(height: 1, color: _AppColors.divider, indent: 16),
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
            SizedBox(width: 50, child: Center(child: _buildShimmerBox(height: 14, width: 20))),
          ]),
        ),
      ),
    );
  }

  // ─── Filter Popup Helpers ─────────────────────────────────────────────────

  /// Generic popup with search + list
  Future<T?> _showSearchPopup<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required String Function(T) labelOf,
    required T? selected,
  }) {
    final ctrl = TextEditingController();
    List<T> filtered = List.from(items);
    return showDialog<T>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _AppColors.primaryLight, width: 1.5),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
                decoration: BoxDecoration(
                  color: _AppColors.primaryLight,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(children: [
                  Icon(Icons.tune_rounded, color: _AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(title, style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15, color: _AppColors.textPrimary))),
                  IconButton(icon: const Icon(Icons.close, size: 18, color: _AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
                ]),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: TextField(
                  controller: ctrl,
                  onChanged: (q) {
                    setSt(() {
                      filtered = items.where((e) =>
                          labelOf(e).toLowerCase().contains(q.toLowerCase())).toList();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: getTxt('cari'),
                    hintStyle: const TextStyle(fontSize: 13, color: _AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search, color: _AppColors.primary, size: 18),
                    filled: true, fillColor: _AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: _AppColors.primaryLight)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: _AppColors.primaryLight)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: _AppColors.primary, width: 1.5)),
                  ),
                ),
              ),
              // List
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    final lbl = labelOf(item);
                    final isSel = item == selected || lbl == (selected != null ? labelOf(selected!) : null);
                    return InkWell(
                      onTap: () => Navigator.pop(ctx, item),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSel ? _AppColors.primaryLight : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSel ? _AppColors.primary : _AppColors.divider, width: 1),
                        ),
                        child: Row(children: [
                          Expanded(child: Text(lbl, style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel ? _AppColors.primary : _AppColors.textPrimary,
                          ))),
                          if (isSel) const Icon(Icons.check_circle_rounded, color: _AppColors.primary, size: 16),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // Month picker popup
  void _showMonthPicker(VoidCallback onChanged) async {
    String tempMode = _filterMode;
    int tempMonthIndex = _selectedMonthIndex;
    DateTime tempDate = _selectedDate ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.65,
                maxWidth: 340,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _AppColors.primaryLight, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                    decoration: BoxDecoration(
                      color: _AppColors.primaryLight,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_month_rounded, color: _AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          getTxt('pilih_bulan'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15, color: _AppColors.textPrimary),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: _AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                      ),
                    ]),
                  ),

                  // ── Toggle Daily / Monthly ───────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _AppColors.primaryLight),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: ['monthly', 'daily'].map((mode) {
                          final isSelected = tempMode == mode;
                          final label = mode == 'monthly'
                              ? (widget.lang == 'ID' ? 'Bulanan' : widget.lang == 'ZH' ? '按月' : 'Monthly')
                              : (widget.lang == 'ID' ? 'Harian' : widget.lang == 'ZH' ? '按日' : 'Daily');
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setSt(() => tempMode = mode),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSelected ? _AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Center(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : _AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // ── Konten: Monthly Grid / Daily Picker ──────────────
                  if (tempMode == 'monthly') ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 2.2,
                        ),
                        itemCount: 12,
                        itemBuilder: (_, i) {
                          final isSelected = i == tempMonthIndex;
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
                                color: isSelected ? _AppColors.primary : _AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? _AppColors.primary : _AppColors.divider,
                                  width: isSelected ? 1.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(
                                        color: _AppColors.primary.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      )]
                                    : [],
                              ),
                              child: Center(
                                child: Text(
                                  _translatedMonths[i],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? Colors.white : _AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    // ── Daily: Kalender Tanggal di Bulan Ini ────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: _buildDailyCalendar(
                        tempDate,
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
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Kalender tanggal — hanya bulan & tahun saat ini
  Widget _buildDailyCalendar(
    DateTime selectedDate,
    ValueChanged<DateTime> onDateChanged, {
    required VoidCallback onConfirm,
  }) {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstWeekday = DateTime(year, month, 1).weekday % 7; // 0=Sun
    final locale = widget.lang == 'ID' ? 'id_ID' : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');
    final monthLabel = DateFormat('MMMM yyyy', locale).format(DateTime(year, month));
    final dayLabels = widget.lang == 'ZH'
        ? ['日', '一', '二', '三', '四', '五', '六']
        : widget.lang == 'ID'
            ? ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
            : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return StatefulBuilder(
      builder: (_, setInner) => Column(
        children: [
          // Bulan label
          Text(
            monthLabel,
            style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: _AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          // Header hari
          Row(
            children: dayLabels.map((d) => Expanded(
              child: Center(
                child: Text(d,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _AppColors.textSecondary)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 6),
          // Grid tanggal
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: firstWeekday + daysInMonth,
            itemBuilder: (_, i) {
              if (i < firstWeekday) return const SizedBox();
              final day = i - firstWeekday + 1;
              final date = DateTime(year, month, day);
              final isSelected = selectedDate.year == date.year &&
                  selectedDate.month == date.month &&
                  selectedDate.day == date.day;
              final isToday = now.year == date.year &&
                  now.month == date.month &&
                  now.day == date.day;
              final isFuture = date.isAfter(now);
              return GestureDetector(
                onTap: isFuture ? null : () => setInner(() => onDateChanged(date)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _AppColors.primary
                        : isToday
                            ? _AppColors.primaryLight
                            : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isToday && !isSelected
                        ? Border.all(color: _AppColors.primary, width: 1.2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : isFuture
                                ? _AppColors.textMuted
                                : _AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Tombol konfirmasi
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: _AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(
                getTxt('terapkan'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Group picker popup
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _AppColors.primaryLight, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                    decoration: BoxDecoration(
                      color: _AppColors.primaryLight,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.group_rounded, color: _AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(getTxt('pilih_grup'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _AppColors.textPrimary))),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: _AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                      ),
                    ]),
                  ),
                  // Search
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    child: StatefulBuilder(
                      builder: (_, setInner) => TextField(
                        controller: ctrl,
                        onChanged: (q) {
                          setInner(() {
                            filtered = items.where((e) =>
                              (e['nama_unit'] as String).toLowerCase().contains(q.toLowerCase())
                            ).toList();
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
                  // List
                  Flexible(
                    child: StatefulBuilder(
                      builder: (_, __) => ListView.builder(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final item = filtered[i];
                          final lbl = item['nama_unit'] as String;
                          final id = item['id_unit']?.toString();
                          final isSelected = id == _selectedUnitId ||
                            (id == null && _selectedUnitId == null);
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
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: isSelected ? _AppColors.primary : _AppColors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(child: Text(
                                    lbl.isNotEmpty ? lbl[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 15,
                                      color: isSelected ? Colors.white : _AppColors.primary,
                                    ),
                                  )),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(lbl, style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? _AppColors.primary : _AppColors.textPrimary,
                                ))),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded,
                                    color: _AppColors.primary, size: 18),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Inspection role picker popup
  void _showRolePicker() async {
    final result = await _showSearchPopup<String>(
      context: context,
      title: getTxt('eksekutif') + ' / ' + getTxt('profesional') + ' / ' + getTxt('visitor'),
      items: _translatedRoles,
      labelOf: (e) => e,
      selected: _selectedInspectionRole,
    );
    if (result != null && mounted) {
      setState(() => _selectedInspectionRole = result);
      _fetchAllData();
    }
  }

  Widget _buildConditionalChart() {
    // Recurring Findings tab juga pakai collapsible chart (tanpa target line)
    final activeColor = _selectedFindingType == 'KTS Production'
        ? const Color(0xFFF59E0B)
        : _selectedFindingType == 'Accident'
            ? const Color(0xFFEF4444)
            : _AppColors.primary;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: KeyedSubtree(
        key: ValueKey('collapsible-$_selectedFindingType-$_activeTabIndex'),
        child: _buildCollapsibleChart(),
      ),
    );
  }

  // Location level picker popup
  void _showLevelPicker() async {
    final result = await _showSearchPopup<String>(
      context: context,
      title: getTxt('pilih_level'),
      items: _translatedLocationLevels,
      labelOf: (e) => e,
      selected: _selectedLocationLevel,
    );
    if (result != null && mounted) {
      setState(() => _selectedLocationLevel = result);
      _fetchAllData(fromTabFilter: true);
    }
  }

  // Location picker (using FullLocationPickerBottomSheet style but as popup)
  void _showLocationPickerForFilter() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AnalyticsLocationPickerSheet(lang: widget.lang),
    );
    if (result != null && mounted) {
      // apply location filter
      setState(() {
        _selectedLocationLevel = _translatedLocationLevels[result['level'] as int];
      });
      _fetchAllData();
    }
  }

  // Recurring period picker
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
            border: Border.all(color: _AppColors.primaryLight, width: 1.5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.date_range_rounded, color: _AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(getTxt('pilih_periode'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _AppColors.textPrimary))),
              IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
            ]),
            const SizedBox(height: 16),
            // From
            Text(getTxt('dari'), style: const TextStyle(fontSize: 12, color: _AppColors.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _buildYearMonthPicker(tempFrom, locale, (d) => setSt(() => tempFrom = d)),
            const SizedBox(height: 14),
            // To
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
                  backgroundColor: _AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
      // Month
      Expanded(
        flex: 3,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _AppColors.surface, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _AppColors.primaryLight),
          ),
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
      // Year
      Expanded(
        flex: 2,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _AppColors.surface, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _AppColors.primaryLight),
          ),
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

  // Recurring user picker
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

      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSt) {
            final ctrl = TextEditingController();
            List<Map<String, dynamic>> filtered = List.from(items);

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _AppColors.primaryLight, width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                      decoration: BoxDecoration(
                        color: _AppColors.primaryLight,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.person_search_rounded, color: _AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(getTxt('pilih_penemu'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _AppColors.textPrimary))),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: _AppColors.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                          padding: EdgeInsets.zero,
                        ),
                      ]),
                    ),
                    // Search
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                      child: StatefulBuilder(
                        builder: (_, setInner) => TextField(
                          controller: ctrl,
                          onChanged: (q) {
                            setInner(() {
                              filtered = items.where((e) =>
                                (e['nama'] as String).toLowerCase().contains(q.toLowerCase())
                              ).toList();
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
                    // Count label
                    Padding(
                      padding: const EdgeInsets.only(left: 14, bottom: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('${filtered.length} ${widget.lang == 'ID' ? 'penemu' : widget.lang == 'ZH' ? '发现者' : 'finders'}',
                          style: const TextStyle(fontSize: 11, color: _AppColors.textSecondary)),
                      ),
                    ),
                    // List
                    Flexible(
                      child: StatefulBuilder(
                        builder: (_, __) => ListView.builder(
                          padding: const EdgeInsets.only(bottom: 12),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final item = filtered[i];
                            final name = item['nama'] as String;
                            final id = item['id_user']?.toString();
                            final avatarUrl = item['gambar_user'] as String?;
                            final role = (item['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'] as String?;
                            final isSelected = id == _recurringUserId ||
                              (id == null && _recurringUserId == null);
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
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(children: [
                                  // Avatar
                                  if (isAll)
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(
                                        color: isSelected ? _AppColors.primary : _AppColors.surface,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: _AppColors.primaryLight)),
                                      child: Icon(Icons.group_rounded,
                                        color: isSelected ? Colors.white : _AppColors.primary, size: 20),
                                    )
                                  else if (avatarUrl != null && avatarUrl.isNotEmpty)
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: NetworkImage(avatarUrl),
                                      onBackgroundImageError: (_, __) {},
                                      backgroundColor: _AppColors.primaryLight,
                                    )
                                  else
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: isSelected ? _AppColors.primary : _AppColors.primaryLight,
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 15,
                                          color: isSelected ? Colors.white : _AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(isAll
                                          ? (widget.lang == 'ID' ? 'Semua Penemu' : widget.lang == 'ZH' ? '所有发现者' : 'All Finders')
                                          : name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? _AppColors.primary : _AppColors.textPrimary,
                                        )),
                                      if (role != null && role.isNotEmpty)
                                        Text(role, style: const TextStyle(
                                          fontSize: 11, color: _AppColors.textSecondary)),
                                    ],
                                  )),
                                  if (isSelected)
                                    const Icon(Icons.check_circle_rounded,
                                      color: _AppColors.primary, size: 18),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } catch (e) {
      debugPrint('Error fetching users: $e');
    }
  }

  // ─── Filter Button Widget ─────────────────────────────────────────────────
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
          boxShadow: [
            BoxShadow(
              color: _AppColors.primary.withOpacity(0.10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : _AppColors.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Icon(icon, color: isActive ? Colors.white : _AppColors.primary, size: 18),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        _buildFindingTypeSelector(),
        _buildTabBar(),
        _buildConditionalChart(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _selectedFindingType == 'KTS Production'
                ? [
                    _buildAnggotaTab(),
                    _buildTemuanBerulangTab(filterKts: true),
                  ]
                : _selectedFindingType == 'Accident'
                    ? [
                        _buildAnggotaTab(),
                        _buildLokasiTab(),
                        _buildAccidentRecurringTab(),
                      ]
                    : [
                        _buildAnggotaTab(),
                        _buildInspeksiTab(),
                        _buildLokasiTab(),
                        _buildTemuanBerulangTab(filterKts: false),
                      ],
          ),
        ),
      ]),
    );
  }

  // ── Tab Bar ────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    final bool isKts = _selectedFindingType == 'KTS Production';
    final bool isAccident = _selectedFindingType == 'Accident';

    final List<String> tabLabels;
    if (isKts) {
      tabLabels = [getTxt('anggota'), getTxt('temuan_berulang')];
    } else if (isAccident) {
      final recurringLabel = widget.lang == 'ID' ? 'Kecelakaan Berulang'
          : widget.lang == 'ZH' ? '重复事故' : 'Recurring Accident';
      tabLabels = [getTxt('anggota'), getTxt('lokasi'), recurringLabel];
    } else {
      tabLabels = [getTxt('anggota'), getTxt('inspeksi'), getTxt('lokasi'), getTxt('temuan_berulang')];
    }

    final activeColor = _selectedFindingType == 'KTS Production'
        ? const Color(0xFFF59E0B)
        : _selectedFindingType == 'Accident'
            ? const Color(0xFFEF4444)
            : _AppColors.primary;

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
          // Untuk 3 tab pakai fill agar proporsional
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

  Widget _buildLastUpdatedTextWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(_lastUpdatedText,
        style: const TextStyle(fontSize: 11, color: _AppColors.textSecondary, height: 1.4)),
    );
  }

  // ── Finding Type Selector ──────────────────────────────────────────────────
  Widget _buildFindingTypeSelector() {
    const types = [
      {'key': '5R', 'label': '5R Finding', 'icon': Icons.search_rounded},
      {'key': 'KTS Production', 'label': 'KTS Production', 'icon': Icons.precision_manufacturing_rounded},
      {'key': 'Accident', 'label': 'Accident Report', 'icon': Icons.warning_amber_rounded},
    ];
    const activeColors = {
      '5R': Color(0xFF0EA5E9),
      'KTS Production': Color(0xFFF59E0B),
      'Accident': Color(0xFFEF4444),
    };
    const borderColors = {
      '5R': Color(0xFF7DD3FC),
      'KTS Production': Color(0xFFFCD34D),
      'Accident': Color(0xFFFCA5A5),
    };

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: types.map((t) {
          final key = t['key'] as String;
          final isSelected = _selectedFindingType == key;
          final activeColor = activeColors[key]!;
          final borderColor = isSelected ? activeColor : borderColors[key]!;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: key != 'Accident' ? 6 : 0),
              child: GestureDetector(
                onTap: () {
                  if (_selectedFindingType != key) {
                    setState(() {
                      _selectedFindingType = key;
                      _isChartExpanded = false;
                      _recurringFuture = null;
                      _accidentRecurringFuture = null;
                    });
                    _fetchAllData();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected ? activeColor : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor, width: 1.5),
                    boxShadow: isSelected ? [BoxShadow(
                      color: activeColor.withOpacity(0.28), blurRadius: 8, offset: const Offset(0, 3),
                    )] : [],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t['icon'] as IconData, size: 12,
                            color: isSelected ? Colors.white : activeColor),
                        const SizedBox(width: 4),
                        Flexible(child: Text(
                          t['label'] as String,
                          style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : activeColor,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Collapsible Bar Chart ──────────────────────────────────────────────────
  Widget _buildCollapsibleChart() {
    final activeColor = _selectedFindingType == '5R'
        ? const Color(0xFF0EA5E9)
        : _selectedFindingType == 'KTS Production'
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    final colorTemuan = activeColor;
    const colorPenyelesaian = Color(0xFF10B981);

    final locale = widget.lang == 'ID' ? 'id_ID' : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');
    final monthLabel = _filterMode == 'daily' && _selectedDate != null
        ? DateFormat('d MMM yyyy', locale).format(_selectedDate!)
        : DateFormat('MMMM yyyy', locale).format(DateTime(
            DateTime.now().year, _selectedMonthIndex + 1));

    return Column(children: [
      // Toggle button
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
            Icon(Icons.bar_chart_rounded, size: 16, color: activeColor),
            const SizedBox(width: 8),
            Expanded(child: Text(
              widget.lang == 'ID' ? 'Grafik $monthLabel'
                  : widget.lang == 'ZH' ? '$monthLabel 图表'
                  : 'Chart $monthLabel',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: activeColor),
            )),
            AnimatedRotation(
              turns: _isChartExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              child: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: activeColor),
            ),
          ]),
        ),
      ),
      // Animated chart body
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: _isChartExpanded
            ? FutureBuilder<List<_ChartBarData>>(
                key: ValueKey('chart-$_chartRefreshKey-$_selectedFindingType-$_activeTabIndex'),
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

                  // Hitung max
                  final (tTarget, pTarget) = _activeTabTargets;
                  int maxVal = (_selectedFindingType == '5R' && _activeTabIndex != 3)
                      ? math.max(tTarget, pTarget).clamp(1, 99999)
                      : 1;
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
                  final yLabels = List.generate(4, (i) => (maxVal / 3 * i).round());

                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.fromLTRB(0, 12, 8, 8),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _AppColors.primaryLight),
                      boxShadow: [BoxShadow(color: activeColor.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Legend
                      Padding(
                        padding: const EdgeInsets.only(left: 32, bottom: 8),
                        child: Builder(builder: (ctx) {
                          final bool isRecurringTab =
                              (_selectedFindingType == '5R'       && _activeTabIndex == 3) ||
                              (_selectedFindingType == 'KTS Production'      && _activeTabIndex == 1) ||
                              (_selectedFindingType == 'Accident' && _activeTabIndex == 2);
                          return Wrap(spacing: 12, children: [
                            _chartLegendItem(colorTemuan,
                              _selectedFindingType == 'Accident'
                                  ? (widget.lang == 'ID' ? 'Laporan' : 'Reports')
                                  : (widget.lang == 'ID' ? 'Temuan' : 'Findings')),
                            _chartLegendItem(colorPenyelesaian,
                              widget.lang == 'ID' ? 'Selesai' : 'Completed'),
                            if (_selectedFindingType == '5R' && !isRecurringTab) ...[
                              _chartLegendDash(const Color(0xFFEF4444),
                                _activeTabIndex == 0
                                    ? (widget.lang == 'ID' ? 'Target Anggota'  : 'Member Target')
                                    : _activeTabIndex == 1
                                        ? (widget.lang == 'ID' ? 'Target Inspeksi' : 'Inspection Target')
                                        : (widget.lang == 'ID' ? 'Target Lokasi'   : 'Location Target')),
                              _chartLegendDash(const Color(0xFFF59E0B),
                                widget.lang == 'ID' ? 'Target Selesai' : 'Completion Target'),
                            ],
                          ]);
                        }),
                      ),
                      // Chart area
                      SizedBox(
                        height: chartH + 28,
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          // Y axis
                          SizedBox(
                            width: leftW,
                            height: chartH,
                            child: Stack(children: yLabels.map((v) {
                              return Positioned(
                                top: valToY(v) - 7,
                                right: 3,
                                child: Text('$v', style: const TextStyle(
                                  fontSize: 8, color: _AppColors.textMuted)),
                              );
                            }).toList()),
                          ),
                          // Bars
                          Expanded(child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: data.length * barGroupW + 8,
                              child: Stack(children: [
                                // Grid lines
                                ...yLabels.map((v) => Positioned(
                                  top: valToY(v), left: 0, right: 0,
                                  child: Container(height: 1, color: _AppColors.divider),
                                )),
                                // Target lines (5R only)
                                Builder(builder: (context) {
                                  final (tTarget, pTarget) = _activeTabTargets;
                                  // Tampilkan target hanya jika bukan Recurring tab DAN bukan KTS/Accident
                                  final bool isRecurringTab =
                                      (_selectedFindingType == '5R'       && _activeTabIndex == 3) ||
                                      (_selectedFindingType == 'KTS Production'      && _activeTabIndex == 1) ||
                                      (_selectedFindingType == 'Accident' && _activeTabIndex == 2);
                                  final showTarget = _selectedFindingType == '5R'
                                      && !isRecurringTab
                                      && tTarget > 0;
                                  if (!showTarget) return const SizedBox.shrink();
                                  return Stack(children: [
                                    Positioned(
                                      top: valToY(tTarget), left: 0, right: 0,
                                      child: CustomPaint(
                                        painter: _DashedLinePainterSimple(const Color(0xFFEF4444)),
                                        child: const SizedBox(height: 2))),
                                    Positioned(
                                      top: valToY(pTarget), left: 0, right: 0,
                                      child: CustomPaint(
                                        painter: _DashedLinePainterSimple(const Color(0xFFF59E0B)),
                                        child: const SizedBox(height: 2))),
                                  ]);
                                }),
                                // Bar items
                                ...data.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final d = entry.value;
                                  final x = i * barGroupW + 4.0;
                                  final tH = (d.temuan / maxVal * chartH).clamp(0.0, chartH);
                                  final pH = (d.penyelesaian / maxVal * chartH).clamp(0.0, chartH);
                                  // Recurring tab (5R tab 3): label = nama bulan, bukan tanggal
                                  final bool isRecurringTabActive =
                                      (_selectedFindingType == '5R' && _activeTabIndex == 3) ||
                                      (_selectedFindingType == 'KTS Production' && _activeTabIndex == 1) ||
                                      (_selectedFindingType == 'Accident' && _activeTabIndex == 2);

                                  String dateLabel;
                                  if (isRecurringTabActive) {
                                    // Hitung bulan dari index recurring range
                                    final locale = widget.lang == 'ID' ? 'id_ID' : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');
                                    final targetMonth = DateTime(
                                      _recurringFrom.year,
                                      _recurringFrom.month + (d.date - 1),
                                    );
                                    dateLabel = DateFormat('MMM yy', locale).format(targetMonth);
                                  } else {
                                    dateLabel = DateFormat('d/M',
                                      widget.lang == 'ID' ? 'id_ID' : 'en_US',
                                    ).format(DateTime(DateTime.now().year, _selectedMonthIndex + 1, d.date));
                                  }
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
                                              decoration: BoxDecoration(
                                                color: colorTemuan,
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)))),
                                            const SizedBox(width: 2),
                                            Container(width: barW, height: pH,
                                              decoration: BoxDecoration(
                                                color: colorPenyelesaian,
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)))),
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
      painter: _DashedLinePainterSimple(color), child: const SizedBox(height: 2))),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 10, color: _AppColors.textSecondary)),
  ]);

  Widget _buildRecurringChart(Color activeColor) {
    final locale = widget.lang == 'ID' ? 'id_ID' : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');
    
    List<String> monthLabels = [];
    DateTime current = DateTime(_recurringFrom.year, _recurringFrom.month);
    final end = DateTime(_recurringTo.year, _recurringTo.month);
    while (!current.isAfter(end)) {
      monthLabels.add(DateFormat('MMM yy', locale).format(current));
      current = DateTime(current.year, current.month + 1);
    }

    return FutureBuilder<List<_ChartBarData>>(
      key: ValueKey(_recurringChartRefreshKey),
      future: _recurringChartFuture, 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            height: 100,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: activeColor.withOpacity(0.2))),
            child: Center(child: CircularProgressIndicator(color: activeColor, strokeWidth: 2)),
          );
        }
        final data = snapshot.data ?? [];
        if (data.isEmpty || data.every((d) => d.temuan == 0 && d.penyelesaian == 0)) {
          return const SizedBox.shrink();
        }

        int maxVal = 1;
        for (final d in data) {
          if (d.temuan > maxVal) maxVal = d.temuan;
          if (d.penyelesaian > maxVal) maxVal = d.penyelesaian;
        }
        maxVal = ((maxVal / 5).ceil() * 5).clamp(1, 9999);

        const double chartH = 100.0;
        const double barGroupW = 36.0;
        const double barW = 10.0;
        const double leftW = 28.0;
        const colorPenyelesaian = Color(0xFF10B981);

        double valToY(int v) => chartH - (v / maxVal * chartH).clamp(0.0, chartH);
        final yLabels = List.generate(3, (i) => (maxVal / 2 * i).round());

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          padding: const EdgeInsets.fromLTRB(0, 10, 8, 6),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: activeColor.withOpacity(0.25)),
            boxShadow: [BoxShadow(color: activeColor.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(left: 32, bottom: 6),
              child: Wrap(spacing: 10, children: [
                _chartLegendItem(activeColor,
                  _selectedFindingType == 'Accident'
                      ? (widget.lang == 'ID' ? 'Laporan' : 'Reports')
                      : (widget.lang == 'ID' ? 'Temuan' : 'Findings')),
                _chartLegendItem(colorPenyelesaian,
                  widget.lang == 'ID' ? 'Selesai' : 'Completed'),
              ]),
            ),
            SizedBox(
              height: chartH + 22,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: leftW, height: chartH,
                  child: Stack(children: yLabels.map((v) => Positioned(
                    top: valToY(v) - 6, right: 3,
                    child: Text('$v', style: const TextStyle(fontSize: 7.5, color: _AppColors.textMuted)),
                  )).toList()),
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
                      ...data.asMap().entries.map((entry) {
                        final i = entry.key;
                        final d = entry.value;
                        final x = i * barGroupW + 4.0;
                        final tH = (d.temuan / maxVal * chartH).clamp(0.0, chartH);
                        final pH = (d.penyelesaian / maxVal * chartH).clamp(0.0, chartH);
                        final label = i < monthLabels.length ? monthLabels[i] : '';
                        return Positioned(
                          left: x, top: 0,
                          child: SizedBox(
                            width: barGroupW, height: chartH + 22,
                            child: Column(children: [
                              SizedBox(height: chartH, child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(width: barW, height: tH,
                                    decoration: BoxDecoration(color: activeColor,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)))),
                                  const SizedBox(width: 2),
                                  Container(width: barW, height: pH,
                                    decoration: BoxDecoration(color: colorPenyelesaian,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)))),
                                ],
                              )),
                              const SizedBox(height: 2),
                              Text(label, style: const TextStyle(
                                fontSize: 6.5, color: _AppColors.textSecondary,
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
    );
  }

  // ── Anggota Tab ────────────────────────────────────────────────────────────
  Widget _buildAnggotaTab() {
    return Column(children: [
      // Filter row — proportional width
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
      _buildLastUpdatedTextWidget(),
      Expanded(child: Builder(builder: (context) {
        Future<List<MemberData>>? activeFuture;
        if (_selectedFindingType == '5R') {
          activeFuture = _anggotaFuture;
        } else if (_selectedFindingType == 'KTS Production') {
          activeFuture = _ktsAnggotaFuture;
        } else {
          activeFuture = _accidentAnggotaFuture;
        }
        if (activeFuture == null) return _buildAnggotaShimmer();
        return FutureBuilder<List<MemberData>>(
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
              orElse: () => MemberData(name: getTxt('saya'), findings: 0, completed: 0, isSelf: true),
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
                separatorBuilder: (_, __) => Divider(height: 1, color: _AppColors.divider, indent: 16),
                itemBuilder: (_, i) => _buildMemberRow(memberList[i]),
              )),
              _buildSelfPinnedRow(self),
            ]);
          },
        );
      })),
    ]);
  }

  // ── Inspeksi Tab ───────────────────────────────────────────────────────────
  Widget _buildInspeksiTab() {
    if (_selectedFindingType == 'Accident') {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 40, color: _AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            widget.lang == 'ID' ? 'Tidak tersedia untuk Accident Report'
                : 'Not available for Accident Report',
            style: const TextStyle(color: _AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ));
    }
    // Mapping warna per role (konsisten dengan explore_screen filter)
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
                    padding: EdgeInsets.only(
                      right: r != _translatedRoles.last ? 6 : 0,
                    ),
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
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            r,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : _AppColors.textSecondary,
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
      _buildLastUpdatedTextWidget(),
      _buildTableHeader([getTxt('nama'), getTxt('temuan')], flex: [3, 1]),
      _buildTargetRow([getTxt('target_bulanan'), '$_targetInspeksi']),
      Expanded(child: Builder(builder: (context) {
        final Future<List<InspectionData>>? activeFuture = _selectedFindingType == '5R'
            ? _inspeksiFuture
            : _selectedFindingType == 'KTS Production'
                ? _ktsInspeksiFuture
                : Future.value([]);
        if (activeFuture == null) return _buildInspeksiShimmer();
        return FutureBuilder<List<InspectionData>>(
          future: activeFuture,
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
            separatorBuilder: (_, __) => Divider(height: 1, color: _AppColors.divider, indent: 16),
            itemBuilder: (_, i) => _buildInspectionRow(snapshot.data![i]),
          );
        },
      );
      })),
    ]);
  }

  // ── Lokasi Tab ─────────────────────────────────────────────────────────────
  Widget _buildLokasiTab() {
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
      _buildAuditPeriodBanner(),
      _buildLastUpdatedTextWidget(),
      _buildTableHeader([getTxt('rank'), getTxt('lokasi'), getTxt('temuan')], flex: [1, 3, 1], isLocation: true),
      Expanded(child: Builder(builder: (context) {
        final Future<List<LocationData>>? activeFuture = _selectedFindingType == '5R'
            ? _lokasiFuture
            : _selectedFindingType == 'KTS Production'
                ? _ktsLokasiFuture
                : _accidentLokasiFuture;
        if (activeFuture == null) return _buildLokasiShimmer();
        return FutureBuilder<List<LocationData>>(
          future: activeFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLokasiShimmer();
            }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('${getTxt('tidak_ada_data_level')} "$_selectedLocationLevel".'));
          }
          final locationList = snapshot.data!;
          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: locationList.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: _AppColors.divider, indent: 16),
            itemBuilder: (_, i) => _buildLocationRow(i + 1, locationList[i]),
          );
        },
      );
      })),
    ]);
  }

  // ── Temuan Berulang Tab ────────────────────────────────────────────────────
  Widget _buildTemuanBerulangTab({bool filterKts = false}) {
    final locale = widget.lang == 'ID' ? 'id_ID' : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');
    final fromLabel = DateFormat('MMM yyyy', locale).format(_recurringFrom);
    final toLabel = DateFormat('MMM yyyy', locale).format(_recurringTo);
    final periodLabel = '$fromLabel - $toLabel';

    final activeColor = _selectedFindingType == 'KTS Production'
        ? const Color(0xFFF59E0B)
        : _AppColors.primary;

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
      Expanded(child: FutureBuilder<List<RecurringTopic>>(
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

  Widget _buildAccidentRecurringTab() {
    final locale = widget.lang == 'ID' ? 'id_ID' : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');
    final fromLabel = DateFormat('MMM yyyy', locale).format(_recurringFrom);
    final toLabel = DateFormat('MMM yyyy', locale).format(_recurringTo);
    final periodLabel = '$fromLabel - $toLabel';

    final tabTitle = widget.lang == 'ID' ? 'Laporan Kecelakaan Berulang'
        : widget.lang == 'ZH' ? '重复事故报告' : 'Recurring Accident Reports';
    final emptyText = widget.lang == 'ID' ? 'Tidak ada laporan kecelakaan berulang.'
        : widget.lang == 'ZH' ? '没有重复的事故报告。' : 'No recurring accident reports.';

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
          child: Text(tabTitle, style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: _AppColors.textPrimary))),
      ),
      const Divider(height: 1, color: _AppColors.divider),
      Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _accidentRecurringFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildRecurringShimmer();
          }
          final groups = snapshot.data ?? [];
          if (groups.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2), shape: BoxShape.circle),
                  child: Icon(Icons.warning_amber_rounded, size: 36,
                    color: const Color(0xFFEF4444).withOpacity(0.5))),
                const SizedBox(height: 16),
                Text(emptyText, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: _AppColors.textSecondary, height: 1.5)),
              ],
            ));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _buildAccidentRecurringCard(groups[i]),
          );
        },
      )),
    ]);
  }

  Widget _buildAccidentRecurringCard(Map<String, dynamic> group) {
    final topic = group['topic'] as String;
    final locationArea = group['locationArea'] as String;
    final total = group['total'] as int;
    final imageUrl = group['imageUrl'] as String?;
    final reports = group['reports'] as List<Map<String, dynamic>>;

    // Warna berdasarkan tingkat keparahan
    Color severityColor;
    IconData severityIcon;
    final topicLower = topic.toLowerCase();
    if (topicLower.contains('berat') || topicLower.contains('heavy') || topicLower.contains('重')) {
      severityColor = const Color(0xFFEF4444);
      severityIcon = Icons.dangerous_rounded;
    } else if (topicLower.contains('menengah') || topicLower.contains('medium') || topicLower.contains('中')) {
      severityColor = const Color(0xFFF59E0B);
      severityIcon = Icons.warning_amber_rounded;
    } else {
      severityColor = const Color(0xFF10B981);
      severityIcon = Icons.info_outline_rounded;
    }

    final severityLabel = widget.lang == 'ID' ? 'Tingkat: $topic'
        : widget.lang == 'ZH' ? '级别: $topic' : 'Severity: $topic';

    return GestureDetector(
      onTap: () => _showAccidentRecurringDetail(topic, reports),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: severityColor.withOpacity(0.3), width: 1.5),
          boxShadow: [BoxShadow(color: severityColor.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            child: Container(
              width: 80, height: 80,
              color: severityColor.withOpacity(0.1),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(severityIcon, color: severityColor, size: 32))
                  : Icon(severityIcon, color: severityColor, size: 32),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(severityLabel,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: severityColor),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.location_on_rounded, size: 13, color: _AppColors.textSecondary),
                const SizedBox(width: 3),
                Expanded(child: Text(locationArea.isEmpty ? '-' : locationArea,
                  style: const TextStyle(fontSize: 12, color: _AppColors.textSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ]),
          )),
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: severityColor.withOpacity(0.3)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(getTxt('total'), style: TextStyle(fontSize: 9, color: severityColor.withOpacity(0.7))),
              Text('$total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: severityColor)),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showAccidentRecurringDetail(String topic, List<Map<String, dynamic>> reports) {
    final locale = widget.lang == 'ID' ? 'id_ID' : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');
    final titleLabel = widget.lang == 'ID' ? 'Daftar Laporan' : widget.lang == 'ZH' ? '报告列表' : 'Report List';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                Expanded(child: Text(topic,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _AppColors.textPrimary))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                  child: Text('${getTxt('total')}: ${reports.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444)))),
              ]),
            ),
            const Divider(height: 1, color: _AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Align(alignment: Alignment.centerLeft,
                child: Text('$titleLabel (${reports.length})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _AppColors.textPrimary))),
            ),
            Expanded(child: ListView.separated(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: reports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _buildAccidentReportCard(reports[i], locale),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _buildAccidentReportCard(Map<String, dynamic> data, String locale) {
    final judul = (data['judul'] ?? '-').toString();
    final status = (data['status'] ?? '').toString();
    final tingkat = (data['tingkat_keparahan'] ?? '').toString();
    final penyebab = (data['penyebab'] ?? '-').toString();
    final fotoUrl = (data['foto_bukti'] ?? '').toString();
    final isSelesai = status == 'Selesai';

    final tanggal = () {
      final v = data['created_at'];
      if (v == null) return '-';
      final dt = v is DateTime ? v : DateTime.tryParse(v.toString());
      if (dt == null) return '-';
      return DateFormat('dd/MM/yyyy', locale).format(dt);
    }();

    String location = '';
    if (data['area'] != null) location = data['area']['nama_area'] ?? '';
    else if (data['subunit'] != null) location = data['subunit']['nama_subunit'] ?? '';
    else if (data['unit'] != null) location = data['unit']['nama_unit'] ?? '';
    else if (data['lokasi'] != null) location = data['lokasi']['nama_lokasi'] ?? '';

    final statusColor = isSelesai ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final statusBg = isSelesai ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
    final statusText = isSelesai
        ? (widget.lang == 'ID' ? 'Selesai' : widget.lang == 'ZH' ? '已完成' : 'Resolved')
        : (widget.lang == 'ID' ? status : status);

    Color severityColor;
    final tLower = tingkat.toLowerCase();
    if (tLower.contains('berat') || tLower.contains('heavy')) {
      severityColor = const Color(0xFFEF4444);
    } else if (tLower.contains('menengah') || tLower.contains('medium')) {
      severityColor = const Color(0xFFF59E0B);
    } else {
      severityColor = const Color(0xFF10B981);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: severityColor.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: severityColor.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Foto
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: severityColor.withOpacity(0.3), width: 1.5)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.5),
                child: fotoUrl.isNotEmpty
                    ? Image.network(fotoUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported, color: Colors.grey))
                    : Container(color: const Color(0xFFF8FAFC),
                        child: const Icon(Icons.warning_amber_rounded, color: Colors.grey, size: 28)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(judul,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _AppColors.textPrimary),
                  maxLines: 2, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: severityColor, width: 1)),
                  child: Text(tingkat, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: severityColor))),
              ]),
              const SizedBox(height: 4),
              if (location.isNotEmpty)
                Row(children: [
                  const Icon(Icons.place_rounded, size: 11, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 3),
                  Expanded(child: Text(location,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.calendar_today_rounded, size: 10, color: Color(0xFF94A3B8)),
                const SizedBox(width: 3),
                Text(tanggal, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                  child: Text(statusText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor))),
              ]),
            ])),
          ]),
        ),
        // Penyebab row
        if (penyebab.isNotEmpty && penyebab != '-')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14))),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, size: 12, color: severityColor),
              const SizedBox(width: 5),
              Expanded(child: Text(penyebab,
                style: TextStyle(fontSize: 11, color: severityColor.withOpacity(0.9), fontWeight: FontWeight.w500),
                maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]),
          ),
      ]),
    );
  }

  Widget _buildRecurringTopicCard(RecurringTopic topic) {
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
          // Image
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
              // Cek apakah topic ini KTS dari findings pertama
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
                      color: isKts ? const Color(0xFFD97706) : _AppColors.textSecondary,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  )),
                ]),
              ]);
            }),
          )),
          // Total badge
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _AppColors.primaryLight, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _AppColors.primary.withOpacity(0.3)),
            ),
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

  void _showRecurringDetail(RecurringTopic topic) {
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
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
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
                        color: isKts ? const Color(0xFFD97706) : _AppColors.primary,
                      ),
                      const SizedBox(width: 3),
                      Flexible(child: Text(
                        isKts
                            ? '${widget.lang == 'ID' ? 'No. Order' : widget.lang == 'ZH' ? '订单号' : 'Order No.'}: ${topic.locationArea}'
                            : '${getTxt('di_sekitar')} ${topic.locationArea}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isKts ? const Color(0xFFD97706) : _AppColors.textSecondary,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      )),
                    ]),
                  ]);
                })),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                  child: Text('${getTxt('total')}: ${topic.total}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: _AppColors.primary)),
                ),
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
              itemBuilder: (_, i) {
                final data = topic.findings[i];
                return _buildRecurringFindingCard(data);
              },
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
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FindingDetailScreen(
              initialData: data,
              lang: widget.lang,
            ),
          ),
        ),
      );
    }

    // Card 5R biasa — kode lama tetap di bawah ini (tidak diubah)
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

    List<String> inspTypes = [];
    if (isPro) inspTypes.add('pro');
    if (isVisitor) inspTypes.add('visitor');
    if (isEksekutif) inspTypes.add('eksekutif');

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
            bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)),
        ),
        child: Row(children: [
          Icon(Icons.event_available_rounded, size: 13, color: statusColor),
          const SizedBox(width: 5),
          Text(
            '${widget.lang == 'ID' ? 'Selesai pada' : widget.lang == 'ZH' ? '完成于' : 'Completed on'} $completionDateText',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
          ),
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
          if (abs.inDays > 0) timeText = '${abs.inDays} ${getTxt('hari_terlewat')}';
          else if (abs.inHours > 0) timeText = '${abs.inHours} ${getTxt('jam_terlewat')}';
          else timeText = '${abs.inMinutes} ${getTxt('menit_terlewat')}';
        } else {
          final sisaHari = difference.inDays;
          if (sisaHari == 0) {
            timeColor = Colors.orange.shade800;
            timeIcon = Icons.today_rounded;
            timeText = getTxt('deadline_hari_ini');
          } else {
            timeColor = Colors.green.shade800;
            timeIcon = Icons.timer_outlined;
            timeText = '$sisaHari ${getTxt('hari_tersisa')}';
          }
        }
        timeIndicator = Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: timeColor.withOpacity(0.08),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)),
          ),
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
                      color: Color(0xFF38BDF8), fontWeight: FontWeight.w900, fontSize: 9)),
                  ),
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
              SizedBox(
                width: 40,
                child: Text(cols[0],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600,
                    color: _AppColors.textSecondary, letterSpacing: 0.2)),
              ),
              Expanded(
                flex: 3,
                child: Text(cols[1],
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600,
                    color: _AppColors.textSecondary, letterSpacing: 0.2)),
              ),
              SizedBox(
                width: 70,
                child: Text(cols[2],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600,
                    color: _AppColors.textSecondary, letterSpacing: 0.2)),
              ),
            ])
          : Row(
              children: List.generate(cols.length, (i) {
                final isFirst = i == 0;
                return Expanded(
                  flex: flex[i],
                  child: Padding(
                    padding: EdgeInsets.only(left: isFirst ? 44 : 0),
                    child: Text(
                      cols[i],
                      textAlign: isFirst ? TextAlign.left : TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600,
                        color: _AppColors.textSecondary, letterSpacing: 0.2),
                    ),
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
            padding: const EdgeInsets.only(left: 44), // sejajar dengan nama (avatar 34 + gap 10)
            child: Text(
              vals[0],
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: _AppColors.primary),
            ),
          ),
        ),
        ...vals.sublist(1).map((v) => Expanded(
          flex: 1,
          child: Text(v,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: _AppColors.primary)),
        )),
      ]),
    );
  }

  Widget _buildMemberRow(MemberData m) {
    final target = _targetAnggota;
    final findingsColor = m.findings >= target ? const Color(0xFF16A34A) : _AppColors.textPrimary;
    final completedColor = m.completed >= target ? const Color(0xFF16A34A) : _AppColors.textPrimary;

    return Container(
      color: m.isSelf ? _AppColors.selfHighlight : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          _Avatar(name: m.name, avatarUrl: m.avatarUrl, color: m.avatarColor, size: 34),
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

  Widget _buildSelfPinnedRow(MemberData self) {
  final target = _targetAnggota;
  final findingsColor = self.findings >= target ? const Color(0xFF16A34A) : _AppColors.textSecondary;
  final completedColor = self.completed >= target ? const Color(0xFF16A34A) : _AppColors.textSecondary;

  return Container(
    decoration: BoxDecoration(
      color: _AppColors.selfHighlight,
      border: Border(top: BorderSide(color: _AppColors.selfHighlightBorder, width: 1.5)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, -2))],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      // Kolom Name — flex 3, SAMA persis dengan _buildMemberRow
      Expanded(
        flex: 3,
        child: Row(children: [
          _Avatar(name: self.name, avatarUrl: self.avatarUrl, color: self.avatarColor, size: 34),
          const SizedBox(width: 10),
          Expanded(child: Text(
            self.name,
            style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: _AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          )),
        ]),
      ),
      // Kolom Findings — flex 1, SAMA dengan header & member row
      Expanded(
        flex: 1,
        child: Text(
          '${self.findings}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5, fontWeight: FontWeight.w600, color: findingsColor),
        ),
      ),
      // Kolom Completed — flex 1, SAMA dengan header & member row
      Expanded(
        flex: 1,
        child: Text(
          '${self.completed}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5, fontWeight: FontWeight.w600, color: completedColor),
        ),
      ),
    ]),
  );
}

  Widget _buildInspectionRow(InspectionData item) {
    final target = _targetInspeksi;
    final findingsColor = item.findings >= target
        ? const Color(0xFF16A34A)
        : _AppColors.textPrimary;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        // Kolom Name — flex 3, struktur SAMA dengan header
        Expanded(
          flex: 3,
          child: Row(children: [
            _Avatar(name: item.name, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _AppColors.textPrimary,
                ),
              ),
            ),
          ]),
        ),
        // Kolom Findings — flex 1, center, SAMA dengan header
        Expanded(
          flex: 1,
          child: Text(
            '${item.findings}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: findingsColor,
            ),
          ),
        ),
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
        Icon(Icons.calendar_today_rounded, size: 15, color: _AppColors.primary),
        const SizedBox(width: 8),
        Text(getTxt('periode_audit'), style: TextStyle(fontSize: 13, color: _AppColors.textSecondary)),
        const Text('13 Apr - 19 Apr 2026',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _AppColors.primaryDark)),
      ]),
    );
  }

  Widget _buildLocationRow(int rank, LocationData loc) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        SizedBox(
          width: 40,
          child: Text('$rank',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: _AppColors.textSecondary, fontWeight: FontWeight.w500))),
        Expanded(
          flex: 3,
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: _AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.location_city_rounded, color: _AppColors.primary, size: 20)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(loc.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _AppColors.textPrimary),
                overflow: TextOverflow.ellipsis),
              Text(loc.pic,
                style: const TextStyle(fontSize: 11.5, color: _AppColors.textSecondary),
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
                  ? _AppColors.primaryDark
                  : _AppColors.textMuted))),
      ]),
    );
  }
}

// ─── Analytics Location Picker Sheet ─────────────────────────────────────────
class _AnalyticsLocationPickerSheet extends StatefulWidget {
  final String lang;
  const _AnalyticsLocationPickerSheet({required this.lang});

  @override
  State<_AnalyticsLocationPickerSheet> createState() => _AnalyticsLocationPickerSheetState();
}

class _AnalyticsLocationPickerSheetState extends State<_AnalyticsLocationPickerSheet> {
  int _level = 0;
  bool _isLoading = true;
  List<dynamic> _data = [];
  List<dynamic> _filtered = [];
  final List<Map<String, dynamic>> _history = [];
  final _searchCtrl = TextEditingController();

  static const _idCols = ['id_lokasi', 'id_unit', 'id_subunit', 'id_area'];
  static const _namCols = ['nama_lokasi', 'nama_unit', 'nama_subunit', 'nama_area'];
  static const _tables = ['lokasi', 'unit', 'subunit', 'area'];
  static const _parentCols = ['', 'id_lokasi', 'id_unit', 'id_subunit'];

  String get _idCol => _idCols[_level];
  String get _nameCol => _namCols[_level];

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty ? List.from(_data)
          : _data.where((item) => item[_nameCol].toString().toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _fetch({dynamic parentId}) async {
    setState(() => _isLoading = true);
    _searchCtrl.clear();
    try {
      final supabase = Supabase.instance.client;
      final table = _tables[_level];
      var q = supabase.from(table).select('${_idCols[_level]}, ${_namCols[_level]}');
      if (_level > 0 && parentId != null) {
        q = q.eq(_parentCols[_level], parentId);
      }
      final data = await q.order(_namCols[_level]);
      if (mounted) {
        setState(() { _data = data; _filtered = List.from(data); _isLoading = false; });
      }
    } catch (e) {
      debugPrint('Location fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goDeeper(Map<String, dynamic> item) {
    if (_level >= 3) return;
    _history.add({'level': _level, 'id': item[_idCol], 'name': item[_nameCol]});
    setState(() => _level++);
    _fetch(parentId: item[_idCols[_level - 1]]);
  }

  void _select(Map<String, dynamic> item) {
    final parts = [..._history.map((h) => h['name'].toString()), item[_nameCol].toString()];
    Navigator.pop(context, {
      'id': item[_idCol],
      'name': parts.join(' / '),
      'level': _level,
    });
  }

  void _goBack() {
    if (_history.isEmpty) { Navigator.pop(context); return; }
    _history.removeLast();
    setState(() => _level--);
    _fetch(parentId: _history.isEmpty ? null : _history.last['id']);
  }

  @override
  Widget build(BuildContext context) {
    final lvlLabels = {'EN': ['Location', 'Unit', 'Sub-Unit', 'Area'],
      'ID': ['Lokasi', 'Unit', 'Sub-Unit', 'Area'], 'ZH': ['地点', '单位', '子单位', '区域']};
    final labels = lvlLabels[widget.lang] ?? lvlLabels['ID']!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        Container(
          margin: const EdgeInsets.only(top: 10), width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(children: [
            IconButton(
              icon: Icon(_history.isEmpty ? Icons.close : Icons.arrow_back_ios_new_rounded,
                  color: _AppColors.primary, size: 20),
              onPressed: _goBack),
            Expanded(child: Text(
              _history.isEmpty ? labels[_level] : _history.last['name'].toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _AppColors.textPrimary),
              textAlign: TextAlign.center)),
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
              child: Text('${_filtered.length}',
                style: const TextStyle(color: _AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13))),
          ]),
        ),
        // Breadcrumb
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: List.generate(4, (i) {
            final isActive = i == _level;
            final isPast = i < _level;
            return Row(children: [
              GestureDetector(
                onTap: isPast ? () {
                  final steps = _level - i;
                  for (int s = 0; s < steps; s++) { if (_history.isNotEmpty) _history.removeLast(); }
                  setState(() => _level = i);
                  _fetch(parentId: _history.isEmpty ? null : _history.last['id']);
                } : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? _AppColors.primary : isPast ? _AppColors.primaryLight : const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(20)),
                  child: Text(labels[i], style: TextStyle(
                    color: isActive ? Colors.white : isPast ? _AppColors.primary : Colors.grey.shade300,
                    fontSize: 11, fontWeight: isActive ? FontWeight.bold : FontWeight.normal))),
              ),
              if (i < 3) Icon(Icons.chevron_right, size: 12,
                  color: i < _level ? _AppColors.primary : Colors.grey.shade300),
            ]);
          })),
        ),
        const SizedBox(height: 8),
        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: _AppColors.surface, borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _AppColors.primaryLight)),
            child: Row(children: [
              const Icon(Icons.search_rounded, color: _AppColors.primary),
              const SizedBox(width: 10),
              Expanded(child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.lang == 'EN' ? 'Search...' : widget.lang == 'ZH' ? '搜索...' : 'Cari...',
                  border: InputBorder.none, isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14)),
              )),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _AppColors.primary))
            : _filtered.isEmpty
                ? const Center(child: Text('No data', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final item = _filtered[i];
                      final name = item[_nameCol]?.toString() ?? '-';
                      final isLastLevel = _level == 3;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _AppColors.primaryLight),
                          boxShadow: [BoxShadow(color: _AppColors.primary.withOpacity(0.06),
                              blurRadius: 6, offset: const Offset(0, 2))]),
                        child: InkWell(
                          onTap: isLastLevel ? () => _select(item) : () => _goDeeper(item),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                                child: Icon([Icons.location_city, Icons.workspaces, Icons.layers, Icons.place][_level],
                                  color: _AppColors.primary, size: 18)),
                              const SizedBox(width: 12),
                              Expanded(child: Text(name,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _AppColors.textPrimary))),
                              GestureDetector(
                                onTap: () => _select(item),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _AppColors.primaryLight, borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _AppColors.primary)),
                                  child: Text(widget.lang == 'EN' ? 'Select' : widget.lang == 'ZH' ? '选择' : 'Pilih',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _AppColors.primary))),
                              ),
                              if (!isLastLevel) ...[
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _goDeeper(item),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(color: _AppColors.surface, borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.chevron_right, color: Colors.grey, size: 18))),
                              ],
                            ]),
                          ),
                        ),
                      );
                    })),
      ]),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String name;
  final Color? color;
  final double size;
  final String? avatarUrl;

  const _Avatar({required this.name, this.color, this.size = 36, this.avatarUrl});

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
    return _buildInitialsContainer();
  }

  Widget _buildInitials() {
    final initials = name.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    final bg = color ?? _AppColors.primary;
    return Text(initials,
      style: TextStyle(fontSize: size * 0.35, fontWeight: FontWeight.w700, color: bg));
  }

  Widget _buildInitialsContainer() {
    final bg = color ?? _AppColors.primary;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: bg.withOpacity(0.15), shape: BoxShape.circle,
        border: Border.all(color: bg.withOpacity(0.3), width: 1)),
      child: Center(child: _buildInitials()),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _AppColors.primary : _AppColors.divider, width: 1.5),
          boxShadow: selected ? [BoxShadow(color: _AppColors.primary.withOpacity(0.3),
              blurRadius: 6, offset: const Offset(0, 2))] : null,
        ),
        child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _AppColors.textSecondary)),
      ),
    );
  }
}

class _DashedLinePainterSimple extends CustomPainter {
  final Color color;
  _DashedLinePainterSimple(this.color);

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