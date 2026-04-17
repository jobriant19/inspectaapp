import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class AppColors {
  static const primaryColor   = Color(0xFF0EA5E9);
  static const primaryDark    = Color(0xFF0369A1);
  static const primaryLight   = Color(0xFFE0F2FE);
  static const surface        = Color(0xFFF0F9FF);
  static const textPrimary    = Color(0xFF0C4A6E);
  static const textSecondary  = Color(0xFF64748B);
  static const gold           = Color(0xFFF59E0B);
  static const silver         = Color(0xFF94A3B8);
  static const bronze         = Color(0xFFCD7F32);
  static const violet         = Color(0xFF8B5CF6);
  static const redTarget      = Color(0xFFEF4444);
  static const orangeTarget   = Color(0xFFF97316);
  static const green          = Color(0xFF16A34A);
  static const selfOrange     = Color(0xFFFFF7ED);
  static const selfBorder     = Color(0xFFFED7AA);
  static const border         = Color(0xFFBAE6FD);
}

class LeaderboardMember {
  final int rank;
  final String name;
  final String? avatarUrl;
  final int score;

  LeaderboardMember({
    required this.rank,
    required this.name,
    this.avatarUrl,
    required this.score,
  });

  String get altitudeLabel => '${score * 10} ft';
}

class DailyChartData {
  final int date;
  final int temuan;
  final int penyelesaian;

  DailyChartData({
    required this.date,
    required this.temuan,
    required this.penyelesaian,
  });
}

class ChartTarget {
  final int targetTemuan;
  final int targetPenyelesaian;

  const ChartTarget({
    required this.targetTemuan,
    required this.targetPenyelesaian,
  });
}

class LocationFilter {
  final int? idLokasi;
  final int? idUnit;
  final int? idSubunit;
  final int? idArea;
  final String displayName;

  const LocationFilter({
    this.idLokasi,
    this.idUnit,
    this.idSubunit,
    this.idArea,
    required this.displayName,
  });
}

const int kTargetTemuan = 3;
const int kTargetPenyelesaian = 4;

const Map<String, Map<String, String>> leaderboardTexts = {
  'ID': {
    'chart_title': 'Grafik Temuan & Penyelesaian',
    'chart_title_daily': 'Ringkasan Harian',
    'temuan': 'Temuan',
    'penyelesaian': 'Penyelesaian',
    'target': 'Target',
    'target_temuan': 'Target Temuan',
    'target_penyelesaian': 'Target Penyelesaian',
    'achievement_temuan': '✅ Target temuan tercapai!',
    'achievement_penyelesaian': '✅ Target penyelesaian tercapai!',
    'achievement_both': '🎉 Semua target tercapai bulan ini!',
    'no_chart_data': 'Tidak ada data grafik untuk bulan ini.',
    'no_daily_data': 'Tidak ada data untuk tanggal ini.',
    'season': 'Musim',
    'time_left': 'Sisa waktu',
    'days': 'hari',
    'per_day': '/hari',
    'history': 'Riwayat',
    'monthly': 'Bulanan',
    'daily': 'Harian',
    'name_col': 'Nama',
    'alt_col': 'Altitude',
    'score_col': 'Skor',
    'monthly_target': 'Target Bulanan',
    'no_rank_data': 'Belum ada data peringkat.',
    'appbar_title': 'Papan Peringkat Detail',
    'filter_location_title': 'Filter Lokasi',
    'reset': 'Reset',
    'apply_filter': 'Terapkan Filter',
    'all_locations': 'Semua Lokasi',
    'label_lokasi': 'Lokasi',
    'label_unit': 'Unit',
    'label_subunit': 'Subunit',
    'label_area': 'Area',
    'first_class': '✈ First Class',
    'business_class': '✈ Business Class',
    'premium_class': '✈ Premium Class',
    'total': 'Total',
    'items': 'item',
  },
  'EN': {
    'chart_title': 'Finding & Resolution Chart',
    'chart_title_daily': 'Daily Summary',
    'temuan': 'Findings',
    'penyelesaian': 'Resolutions',
    'target': 'Target',
    'target_temuan': 'Finding Target',
    'target_penyelesaian': 'Resolution Target',
    'achievement_temuan': '✅ Finding target achieved!',
    'achievement_penyelesaian': '✅ Resolution target achieved!',
    'achievement_both': '🎉 All targets achieved this month!',
    'no_chart_data': 'No chart data for this month.',
    'no_daily_data': 'No data for this date.',
    'season': 'Season',
    'time_left': 'Time left',
    'days': 'days',
    'per_day': '/day',
    'history': 'History',
    'monthly': 'Monthly',
    'daily': 'Daily',
    'name_col': 'Name',
    'alt_col': 'Altitude',
    'score_col': 'Score',
    'monthly_target': 'Monthly Target',
    'no_rank_data': 'No ranking data yet.',
    'appbar_title': 'Leaderboard Detail',
    'filter_location_title': 'Filter Location',
    'reset': 'Reset',
    'apply_filter': 'Apply Filter',
    'all_locations': 'All Locations',
    'label_lokasi': 'Location',
    'label_unit': 'Unit',
    'label_subunit': 'Subunit',
    'label_area': 'Area',
    'first_class': '✈ First Class',
    'business_class': '✈ Business Class',
    'premium_class': '✈ Premium Class',
    'total': 'Total',
    'items': 'items',
  },
  'ZH': {
    'chart_title': '发现与解决图表',
    'chart_title_daily': '每日摘要',
    'temuan': '发现',
    'penyelesaian': '解决',
    'target': '目标',
    'target_temuan': '发现目标',
    'target_penyelesaian': '解决目标',
    'achievement_temuan': '✅ 发现目标已达成！',
    'achievement_penyelesaian': '✅ 解决目标已达成！',
    'achievement_both': '🎉 本月所有目标均已达成！',
    'no_chart_data': '本月暂无图表数据。',
    'no_daily_data': '该日期暂无数据。',
    'season': '赛季',
    'time_left': '剩余时间',
    'days': '天',
    'per_day': '/天',
    'history': '历史',
    'monthly': '月度',
    'daily': '每日',
    'name_col': '姓名',
    'alt_col': '高度',
    'score_col': '分数',
    'monthly_target': '月度目标',
    'no_rank_data': '暂无排名数据。',
    'appbar_title': '排行榜详情',
    'filter_location_title': '筛选位置',
    'reset': '重置',
    'apply_filter': '应用筛选',
    'all_locations': '所有位置',
    'label_lokasi': '位置',
    'label_unit': '单位',
    'label_subunit': '子单位',
    'label_area': '区域',
    'first_class': '✈ 头等舱',
    'business_class': '✈ 商务舱',
    'premium_class': '✈ 优质舱',
    'total': '总计',
    'items': '项',
  },
};

enum FilterType { monthly, daily }

class LeaderboardDetailScreen extends StatefulWidget {
  final String seasonTitle;
  final int year;
  final int month;
  final String lang;

  const LeaderboardDetailScreen({
    super.key,
    required this.seasonTitle,
    required this.year,
    required this.month,
    required this.lang,
  });

  @override
  State<LeaderboardDetailScreen> createState() => _LeaderboardDetailScreenState();
}

class _LeaderboardDetailScreenState extends State<LeaderboardDetailScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Future<List<LeaderboardMember>>? _leaderboardFuture;
  Future<List<DailyChartData>>? _chartFuture;
  Future<ChartTarget>? _chartTargetFuture;
  Future<DailyChartData>? _dailyPieFuture;

  // State untuk filter lokasi hierarkis
  LocationFilter _selectedLocation = const LocationFilter(displayName: 'Semua Lokasi');

  // Data lokasi
  List<Map<String, dynamic>> _lokasiList = [];

  // State sementara dalam bottom sheet
  int? _tempLokasiId;
  int? _tempUnitId;
  int? _tempSubunitId;
  int? _tempAreaId;
  List<Map<String, dynamic>> _tempUnitList = [];
  List<Map<String, dynamic>> _tempSubunitList = [];
  List<Map<String, dynamic>> _tempAreaList = [];

  FilterType _filterType = FilterType.monthly;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(widget.year, widget.month, 1);
    _selectedLocation = LocationFilter(
      displayName: leaderboardTexts[widget.lang]?['all_locations'] ??
          leaderboardTexts['ID']!['all_locations']!,
    );
    _fetchLokasi().then((_) => _fetchData());
  }


  String _getTxt(String key) =>
      leaderboardTexts[widget.lang]?[key] ??
      leaderboardTexts['ID']![key] ??
      key;

  // ── Fetch Lokasi Hierarkis ────────────────────────────────────────────────

  Future<void> _fetchLokasi() async {
    try {
      final response = await _supabase
          .from('lokasi')
          .select('id_lokasi, nama_lokasi')
          .order('nama_lokasi');
      if (mounted) {
        setState(() {
          _lokasiList = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Error fetching lokasi: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUnitByLokasi(int idLokasi) async {
    try {
      final response = await _supabase
          .from('unit')
          .select('id_unit, nama_unit')
          .eq('id_lokasi', idLokasi)
          .order('nama_unit');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching unit: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSubunitByUnit(int idUnit) async {
    try {
      final response = await _supabase
          .from('subunit')
          .select('id_subunit, nama_subunit')
          .eq('id_unit', idUnit)
          .order('nama_subunit');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching subunit: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAreaBySubunit(int idSubunit) async {
    try {
      final response = await _supabase
          .from('area')
          .select('id_area, nama_area')
          .eq('id_subunit', idSubunit)
          .order('nama_area');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching area: $e');
      return [];
    }
  }

  // ── Fetch Data ────────────────────────────────────────────────────────────

  void _fetchData() {
    setState(() {
      if (_filterType == FilterType.monthly) {
        _dailyPieFuture = null;

        // Fetch target dari database
        _chartTargetFuture = _supabase.rpc('get_chart_target', params: {
          'selected_month': _selectedDate.month,
          'selected_year': _selectedDate.year,
          'selected_unit_id': _selectedLocation.idUnit ?? 0,
        }).then((response) {
          final List<dynamic> data = response;
          if (data.isEmpty) {
            return const ChartTarget(targetTemuan: 5, targetPenyelesaian: 4);
          }
          return ChartTarget(
            targetTemuan: data[0]['target_temuan'] as int,
            targetPenyelesaian: data[0]['target_penyelesaian'] as int,
          );
        }).catchError((_) {
          return const ChartTarget(targetTemuan: 5, targetPenyelesaian: 4);
        });

        _leaderboardFuture = _supabase.rpc('get_monthly_leaderboard', params: {
          'selected_month': _selectedDate.month,
          'selected_year': _selectedDate.year,
          'selected_unit_id': _selectedLocation.idUnit ?? 0,
        }).then((response) {
          final List<dynamic> data = response;
          return data.map((item) => LeaderboardMember(
            rank: item['rank_num'] as int,
            name: item['nama'] as String,
            avatarUrl: item['gambar_user'] as String?,
            score: item['monthly_score'] as int,
          )).toList();
        });

        _chartFuture = _supabase.rpc('get_daily_chart_data', params: {
          'selected_month': _selectedDate.month,
          'selected_year': _selectedDate.year,
          'selected_unit_id': _selectedLocation.idUnit ?? 0,
          'selected_lokasi_id': _selectedLocation.idLokasi ?? 0,
          'selected_subunit_id': _selectedLocation.idSubunit ?? 0,
          'selected_area_id': _selectedLocation.idArea ?? 0,
        }).then((response) {
          final List<dynamic> data = response;
          return data.map((item) => DailyChartData(
            date: item['tanggal'] as int,
            temuan: item['temuan'] as int,
            penyelesaian: item['penyelesaian'] as int,
          )).toList();
        });

      } else {
        // Mode harian - fetch data untuk pie chart
        _chartTargetFuture = null;
        _chartFuture = null;

        // Fetch data pie chart harian
        _dailyPieFuture = _supabase.rpc('get_daily_chart_data', params: {
          'selected_month': _selectedDate.month,
          'selected_year': _selectedDate.year,
          'selected_unit_id': _selectedLocation.idUnit ?? 0,
          'selected_lokasi_id': _selectedLocation.idLokasi ?? 0,
          'selected_subunit_id': _selectedLocation.idSubunit ?? 0,
          'selected_area_id': _selectedLocation.idArea ?? 0,
        }).then((response) {
          final List<dynamic> data = response;
          // Cari data untuk tanggal yang dipilih
          final selectedDay = _selectedDate.day;
          final found = data.firstWhere(
            (item) => (item['tanggal'] as int) == selectedDay,
            orElse: () => {'tanggal': selectedDay, 'temuan': 0, 'penyelesaian': 0},
          );
          return DailyChartData(
            date: found['tanggal'] as int,
            temuan: found['temuan'] as int,
            penyelesaian: found['penyelesaian'] as int,
          );
        });

        _leaderboardFuture = _supabase.rpc('get_daily_leaderboard', params: {
          'selected_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
          'selected_unit_id': _selectedLocation.idUnit ?? 0,
        }).then((response) {
          final List<dynamic> data = response;
          return data.map((item) => LeaderboardMember(
            rank: item['rank_num'] as int,
            name: item['nama'] as String,
            avatarUrl: item['gambar_user'] as String?,
            score: item['daily_score'] as int,
          )).toList();
        });
      }
    });
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _fetchData();
      });
    }
  }

  // ── Bottom Sheet Filter Lokasi ────────────────────────────────────────────

  void _showLocationPicker() {
    _tempLokasiId = _selectedLocation.idLokasi;
    _tempUnitId = _selectedLocation.idUnit;
    _tempSubunitId = _selectedLocation.idSubunit;
    _tempAreaId = _selectedLocation.idArea;
    _tempUnitList = [];
    _tempSubunitList = [];
    _tempAreaList = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildLocationBottomSheet(ctx),
    );
  }

  Widget _buildLocationBottomSheet(BuildContext ctx) {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppColors.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getTxt('filter_location_title'), // <-- terjemahan
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setSheetState(() {
                          _tempLokasiId = null;
                          _tempUnitId = null;
                          _tempSubunitId = null;
                          _tempAreaId = null;
                          _tempUnitList = [];
                          _tempSubunitList = [];
                          _tempAreaList = [];
                        });
                      },
                      child: Text(
                        _getTxt('reset'), // <-- terjemahan
                        style: const TextStyle(color: AppColors.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Level 1: Lokasi
                      _buildFilterSection(
                        label: _getTxt('label_lokasi'), // <-- terjemahan
                        icon: Icons.business_rounded,
                        selectedId: _tempLokasiId,
                        items: _lokasiList,
                        idKey: 'id_lokasi',
                        nameKey: 'nama_lokasi',
                        onSelect: (id, name) async {
                          final units = await _fetchUnitByLokasi(id);
                          setSheetState(() {
                            _tempLokasiId = id;
                            _tempUnitId = null;
                            _tempSubunitId = null;
                            _tempAreaId = null;
                            _tempUnitList = units;
                            _tempSubunitList = [];
                            _tempAreaList = [];
                          });
                        },
                      ),
                      // Level 2: Unit
                      if (_tempLokasiId != null && _tempUnitList.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildFilterSection(
                          label: _getTxt('label_unit'), // <-- terjemahan
                          icon: Icons.account_tree_rounded,
                          selectedId: _tempUnitId,
                          items: _tempUnitList,
                          idKey: 'id_unit',
                          nameKey: 'nama_unit',
                          onSelect: (id, name) async {
                            final subunits = await _fetchSubunitByUnit(id);
                            setSheetState(() {
                              _tempUnitId = id;
                              _tempSubunitId = null;
                              _tempAreaId = null;
                              _tempSubunitList = subunits;
                              _tempAreaList = [];
                            });
                          },
                        ),
                      ],
                      // Level 3: Subunit
                      if (_tempUnitId != null && _tempSubunitList.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildFilterSection(
                          label: _getTxt('label_subunit'), // <-- terjemahan
                          icon: Icons.folder_open_rounded,
                          selectedId: _tempSubunitId,
                          items: _tempSubunitList,
                          idKey: 'id_subunit',
                          nameKey: 'nama_subunit',
                          onSelect: (id, name) async {
                            final areas = await _fetchAreaBySubunit(id);
                            setSheetState(() {
                              _tempSubunitId = id;
                              _tempAreaId = null;
                              _tempAreaList = areas;
                            });
                          },
                        ),
                      ],
                      // Level 4: Area
                      if (_tempSubunitId != null && _tempAreaList.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildFilterSection(
                          label: _getTxt('label_area'), // <-- terjemahan
                          icon: Icons.map_rounded,
                          selectedId: _tempAreaId,
                          items: _tempAreaList,
                          idKey: 'id_area',
                          nameKey: 'nama_area',
                          onSelect: (id, name) {
                            setSheetState(() {
                              _tempAreaId = id;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Tombol Terapkan
              Padding(
                padding: EdgeInsets.fromLTRB(
                    16, 8, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      String displayName = _getTxt('all_locations'); // <-- terjemahan
                      if (_tempAreaId != null && _tempAreaList.isNotEmpty) {
                        displayName = _tempAreaList.firstWhere(
                          (e) => e['id_area'] == _tempAreaId,
                          orElse: () => {'nama_area': _getTxt('label_area')},
                        )['nama_area'];
                      } else if (_tempSubunitId != null &&
                          _tempSubunitList.isNotEmpty) {
                        displayName = _tempSubunitList.firstWhere(
                          (e) => e['id_subunit'] == _tempSubunitId,
                          orElse: () =>
                              {'nama_subunit': _getTxt('label_subunit')},
                        )['nama_subunit'];
                      } else if (_tempUnitId != null &&
                          _tempUnitList.isNotEmpty) {
                        displayName = _tempUnitList.firstWhere(
                          (e) => e['id_unit'] == _tempUnitId,
                          orElse: () => {'nama_unit': _getTxt('label_unit')},
                        )['nama_unit'];
                      } else if (_tempLokasiId != null &&
                          _lokasiList.isNotEmpty) {
                        displayName = _lokasiList.firstWhere(
                          (e) => e['id_lokasi'] == _tempLokasiId,
                          orElse: () =>
                              {'nama_lokasi': _getTxt('label_lokasi')},
                        )['nama_lokasi'];
                      }

                      setState(() {
                        _selectedLocation = LocationFilter(
                          idLokasi: _tempLokasiId,
                          idUnit: _tempUnitId,
                          idSubunit: _tempSubunitId,
                          idArea: _tempAreaId,
                          displayName: displayName,
                        );
                        _fetchData();
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _getTxt('apply_filter'), // <-- terjemahan
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterSection({
    required String label,
    required IconData icon,
    required int? selectedId,
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String nameKey,
    required Function(int id, String name) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primaryColor),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final id = item[idKey] as int;
            final name = item[nameKey] as String;
            final isSelected = selectedId == id;
            return GestureDetector(
              onTap: () => onSelect(id, name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryColor
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _getTxt('appbar_title'),
          style: const TextStyle(
              color: Color(0xFF0C4A6E), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF0C4A6E)),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildHeader(),
          _buildFilterTypeSelector(),
          _buildFilters(),
          _buildBarChart(),
          _buildLeaderboardTable(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysLeft = endOfMonth.difference(now).inDays;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C4A6E), Color(0xFF0EA5E9)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_getTxt('season'),
                  style: const TextStyle(fontSize: 11, color: Colors.white70)),
              const SizedBox(height: 3),
              Text(widget.seasonTitle,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_getTxt('time_left'),
                  style:
                      const TextStyle(fontSize: 11, color: Colors.white70)),
              Text('$daysLeft ${_getTxt('days')}',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFCD34D))),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.history_rounded, size: 13),
                label: Text(_getTxt('history')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  textStyle: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTypeSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        children: [
          _tabButton(FilterType.monthly, Icons.calendar_month_rounded,
              _getTxt('monthly')),
          const SizedBox(width: 8),
          _tabButton(FilterType.daily, Icons.calendar_today_rounded,
              _getTxt('daily')),
        ],
      ),
    );
  }

  Widget _tabButton(FilterType type, IconData icon, String label) {
    final isActive = _filterType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filterType = type;
            _fetchData();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  isActive ? AppColors.primaryColor : AppColors.border,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: AppColors.primaryColor.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color: isActive ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? Colors.white
                          : AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Row(
        children: [
          Expanded(
            flex: _filterType == FilterType.daily ? 2 : 1,
            child: GestureDetector(
              onTap: _showLocationPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedLocation.idLokasi != null
                        ? AppColors.primaryColor
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 15, color: AppColors.primaryColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _selectedLocation.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedLocation.idLokasi != null
                              ? AppColors.primaryColor
                              : AppColors.textPrimary,
                          fontWeight: _selectedLocation.idLokasi != null
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
          if (_filterType == FilterType.daily) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 14, color: AppColors.primaryColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          DateFormat('d MMM yyyy', 'id_ID')
                              .format(_selectedDate),
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Bar Chart ─────────────────────────────────────────────────────────────

  Widget _buildBarChart() {
    // Mode harian → tampilkan pie chart
    if (_filterType == FilterType.daily) {
      return _buildDailyPieChart();
    }

    // Mode bulanan → tampilkan bar chart (sama seperti sebelumnya)
    return FutureBuilder<ChartTarget>(
      future: _chartTargetFuture,
      builder: (context, targetSnapshot) {
        final target = targetSnapshot.data ??
            const ChartTarget(targetTemuan: 5, targetPenyelesaian: 4);

        return FutureBuilder<List<DailyChartData>>(
          future: _chartFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                targetSnapshot.connectionState == ConnectionState.waiting) {
              return _buildChartShimmer();
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                  child: Text(_getTxt('no_chart_data'),
                      style: const TextStyle(color: Color(0xFF64748B))),
                ),
              );
            }
            final chartData = snapshot.data!;
            return Column(
              children: [
                _buildAchievementBanner(chartData, target),
                _buildChartBody(chartData, target),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDailyPieChart() {
    return FutureBuilder<DailyChartData>(
      future: _dailyPieFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildChartShimmer();
        }

        final data = snapshot.data;
        final totalTemuan = data?.temuan ?? 0;
        final totalPenyelesaian = data?.penyelesaian ?? 0;
        final total = totalTemuan + totalPenyelesaian;

        // Format tanggal header
        final dateLabel = DateFormat(
          'd MMM yyyy',
          widget.lang == 'ID'
              ? 'id_ID'
              : widget.lang == 'ZH'
                  ? 'zh'
                  : 'en_US',
        ).format(_selectedDate);

        const Color colorTemuan = Color(0xFF0EA5E9);
        const Color colorPenyelesaian = Color(0xFF10B981);
        const Color colorEmpty = Color(0xFFE2E8F0);

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header judul + tanggal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getTxt('chart_title_daily'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0C4A6E),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      dateLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0369A1),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tidak ada data
              if (total == 0) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Icon(Icons.pie_chart_outline,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text(
                          _getTxt('no_daily_data'),
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Layout: Pie di kiri, Keterangan di kanan
                Row(
                  children: [
                    // Pie chart custom
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CustomPaint(
                        painter: _PieChartPainter(
                          temuanValue: totalTemuan.toDouble(),
                          penyelesaianValue: totalPenyelesaian.toDouble(),
                          colorTemuan: colorTemuan,
                          colorPenyelesaian: colorPenyelesaian,
                          colorEmpty: colorEmpty,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$total',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0C4A6E),
                                ),
                              ),
                              Text(
                                _getTxt('total'),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Keterangan detail
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Temuan
                          _buildPieInfoCard(
                            color: colorTemuan,
                            label: _getTxt('temuan'),
                            value: totalTemuan,
                            total: total,
                            icon: Icons.search_rounded,
                          ),
                          const SizedBox(height: 12),
                          // Card Penyelesaian
                          _buildPieInfoCard(
                            color: colorPenyelesaian,
                            label: _getTxt('penyelesaian'),
                            value: totalPenyelesaian,
                            total: total,
                            icon: Icons.check_circle_outline_rounded,
                          ),
                          const SizedBox(height: 12),
                          // Total row
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _getTxt('total'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                Text(
                                  '$total ${_getTxt('items')}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0C4A6E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

Widget _buildPieInfoCard({
  required Color color,
  required String label,
  required int value,
  required int total,
  required IconData icon,
}) {
  final percent = total > 0 ? (value / total * 100).toStringAsFixed(1) : '0.0';
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              // Progress bar mini
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? value / total : 0,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0C4A6E),
              ),
            ),
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildAchievementBanner(List<DailyChartData> data, ChartTarget target) {
    final totalTemuan = data.fold<int>(0, (sum, d) => sum + d.temuan);
    final totalPenyelesaian = data.fold<int>(0, (sum, d) => sum + d.penyelesaian);
    final daysInMonth =
        DateUtils.getDaysInMonth(_selectedDate.year, _selectedDate.month);
    final temuanTarget = target.targetTemuan * daysInMonth;
    final penyelesaianTarget = target.targetPenyelesaian * daysInMonth;

    final temuanClear = totalTemuan >= temuanTarget;
    final penyelesaianClear = totalPenyelesaian >= penyelesaianTarget;

    if (!temuanClear && !penyelesaianClear) return const SizedBox.shrink();

    String message;
    Color bgColor;
    if (temuanClear && penyelesaianClear) {
      message = _getTxt('achievement_both');
      bgColor = const Color(0xFF16A34A);
    } else if (temuanClear) {
      message = _getTxt('achievement_temuan');
      bgColor = const Color(0xFF0EA5E9);
    } else {
      message = _getTxt('achievement_penyelesaian');
      bgColor = const Color(0xFF8B5CF6);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: bgColor.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Text(message,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
          textAlign: TextAlign.center),
    );
  }

  Widget _buildChartBody(List<DailyChartData> data, ChartTarget target) {
    // Konstanta dimensi
    const double chartHeight = 180.0;
    const double barGroupWidth = 30.0;
    const double barWidth = 9.0;
    const double labelHeight = 32.0; // Lebih tinggi untuk 2 baris label
    const double leftAxisWidth = 36.0;

    // Warna yang lebih kontras dan berbeda jelas
    const Color colorTemuan = Color(0xFF0EA5E9);        // Biru muda
    const Color colorPenyelesaian = Color(0xFF10B981);  // Hijau emerald
    const Color colorTargetTemuan = Color(0xFFEF4444);  // Merah terang
    const Color colorTargetPenyelesaian = Color(0xFFF59E0B); // Kuning amber

    // Hitung maxVal berdasarkan target dari database
    int maxVal = target.targetTemuan > target.targetPenyelesaian
        ? target.targetTemuan
        : target.targetPenyelesaian;
    for (final d in data) {
      if (d.temuan > maxVal) maxVal = d.temuan;
      if (d.penyelesaian > maxVal) maxVal = d.penyelesaian;
    }
    maxVal = ((maxVal / 5).ceil() * 5).clamp(5, 9999);

    double valToY(int val) =>
        chartHeight - (val / maxVal * chartHeight).clamp(0, chartHeight);

    final yLabels = List.generate(6, (i) => (maxVal / 5 * i).round());

    // Format label bulan
    final monthStr = _selectedDate.month.toString();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(0, 12, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 6),
            child: Text(_getTxt('chart_title'),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0C4A6E))),
          ),
          // Info target dari database
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8),
            child: Row(
              children: [
                _buildTargetChip(
                  color: colorTargetTemuan,
                  label:
                      '${_getTxt('target')} ${_getTxt('temuan')}: ${target.targetTemuan}${_getTxt('per_day')}',
                ),
                const SizedBox(width: 8),
                _buildTargetChip(
                  color: colorTargetPenyelesaian,
                  label:
                      '${_getTxt('target')} ${_getTxt('penyelesaian')}: ${target.targetPenyelesaian}${_getTxt('per_day')}',
                ),
              ],
            ),
          ),
          // Legend
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 10),
            child: Wrap(spacing: 12, runSpacing: 4, children: [
              _legendItem(colorTemuan, _getTxt('temuan')),
              _legendItem(colorPenyelesaian, _getTxt('penyelesaian')),
              _legendDash(colorTargetTemuan,
                  '${_getTxt('target')} ${_getTxt('temuan')}'),
              _legendDash(colorTargetPenyelesaian,
                  '${_getTxt('target')} ${_getTxt('penyelesaian')}'),
            ]),
          ),
          // Area Chart
          SizedBox(
            height: chartHeight + labelHeight + 8,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sumbu Y
                SizedBox(
                  width: leftAxisWidth,
                  height: chartHeight,
                  child: Stack(
                    children: yLabels.map((v) {
                      final top = valToY(v);
                      return Positioned(
                        top: top - 8,
                        right: 4,
                        child: Text('$v',
                            style: const TextStyle(
                                fontSize: 9, color: Color(0xFF94A3B8))),
                      );
                    }).toList(),
                  ),
                ),
                // Area bars + sumbu X
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: data.length * barGroupWidth + 8,
                      child: Stack(
                        children: [
                          // Grid lines horizontal
                          ...yLabels.map((v) {
                            final top = valToY(v);
                            return Positioned(
                              top: top,
                              left: 0,
                              right: 0,
                              child: Container(
                                  height: 1,
                                  color: const Color(0xFFE2E8F0)),
                            );
                          }),
                          // Garis target temuan (MERAH)
                          Positioned(
                            top: valToY(target.targetTemuan),
                            left: 0,
                            right: 0,
                            child: CustomPaint(
                              painter: _DashedLinePainter(colorTargetTemuan),
                              child: const SizedBox(height: 2),
                            ),
                          ),
                          // Garis target penyelesaian (KUNING AMBER)
                          Positioned(
                            top: valToY(target.targetPenyelesaian),
                            left: 0,
                            right: 0,
                            child: CustomPaint(
                              painter:
                                  _DashedLinePainter(colorTargetPenyelesaian),
                              child: const SizedBox(height: 2),
                            ),
                          ),
                          // Bars per tanggal
                          ...data.asMap().entries.map((entry) {
                            final i = entry.key;
                            final d = entry.value;
                            final x = i * barGroupWidth + 4;
                            final temuanH =
                                (d.temuan / maxVal * chartHeight)
                                    .clamp(0.0, chartHeight);
                            final penyelesaianH =
                                (d.penyelesaian / maxVal * chartHeight)
                                    .clamp(0.0, chartHeight);

                            return Positioned(
                              left: x,
                              top: 0,
                              child: SizedBox(
                                width: barGroupWidth,
                                height: chartHeight + labelHeight + 8,
                                child: Column(
                                  children: [
                                    // Bars
                                    SizedBox(
                                      height: chartHeight,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // Bar Temuan (Biru)
                                          Container(
                                            width: barWidth,
                                            height: temuanH,
                                            decoration: BoxDecoration(
                                              color: colorTemuan,
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                      top: Radius.circular(3)),
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          // Bar Penyelesaian (Hijau)
                                          Container(
                                            width: barWidth,
                                            height: penyelesaianH,
                                            decoration: BoxDecoration(
                                              color: colorPenyelesaian,
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                      top: Radius.circular(3)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Label tanggal/bulan (format: "1 Apr")
                                    SizedBox(
                                      height: labelHeight,
                                      width: barGroupWidth,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            // Format: "1 Apr" sesuai bulan yang dipilih
                                            DateFormat(
                                              'd MMM',
                                              widget.lang == 'ID'
                                                  ? 'id_ID'
                                                  : widget.lang == 'ZH'
                                                      ? 'zh'
                                                      : 'en_US',
                                            ).format(
                                              DateTime(
                                                _selectedDate.year,
                                                _selectedDate.month,
                                                d.date,
                                              ),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 7.5,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF334155),
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.visible,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10.5, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _legendDash(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          child: CustomPaint(
              painter: _DashedLinePainter(color),
              child: const SizedBox(height: 2)),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10.5, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildTargetChip({required Color color, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 9.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _buildChartShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        height: 240,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Leaderboard Table ─────────────────────────────────────────────────────

  Widget _buildLeaderboardTable() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                _th('Rank', 44),
                Expanded(
                    child: Text(_getTxt('name_col'),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary))),
                _th(_getTxt('alt_col'), 72, center: true),
                _th(_getTxt('score_col'), 48, center: true),
              ],
            ),
          ),
          // Target row
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 44),
                Expanded(
                    child: Text(_getTxt('monthly_target'),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor))),
                SizedBox(
                    width: 72,
                    child: const Text('—',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor))),
                SizedBox(
                    width: 48,
                    child: const Text('1000',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryColor))),
              ],
            ),
          ),
          // Data rows
          FutureBuilder<List<LeaderboardMember>>(
            future: _leaderboardFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                    children: List.generate(
                        6, (_) => const _TableRowShimmer()));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                      child: Text(_getTxt('no_rank_data'),
                          style: const TextStyle(
                              color: AppColors.textSecondary))),
                );
              }
              final data = snapshot.data!;
              return Column(
                  children:
                      data.map((item) => _buildRankRow(item)).toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _th(String text, double width, {bool center = false}) {
    return SizedBox(
      width: width,
      child: Text(text,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary)),
    );
  }

  Widget _buildRankRow(LeaderboardMember item) {
    Color? leftBorder;
    Color bgColor = Colors.white;
    Color scoreColor = AppColors.primaryDark;
    Widget badge;
    String? subLabel;

    if (item.rank == 1) {
      leftBorder = AppColors.gold;
      bgColor = const Color(0xFFFFFBEB);
      scoreColor = AppColors.gold;
      badge = const Text('🥇', style: TextStyle(fontSize: 20));
      subLabel = _getTxt('first_class'); // <-- terjemahan
    } else if (item.rank == 2) {
      leftBorder = AppColors.silver;
      bgColor = const Color(0xFFF8FAFC);
      scoreColor = AppColors.silver;
      badge = const Text('🥈', style: TextStyle(fontSize: 20));
      subLabel = _getTxt('business_class'); // <-- terjemahan
    } else if (item.rank == 3) {
      leftBorder = AppColors.bronze;
      bgColor = const Color(0xFFFDF6EE);
      scoreColor = AppColors.bronze;
      badge = const Text('🥉', style: TextStyle(fontSize: 20));
      subLabel = _getTxt('premium_class'); // <-- terjemahan
    } else {
      badge = SizedBox(
        width: 28,
        child: Text('${item.rank}',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
          left: leftBorder != null
              ? BorderSide(color: leftBorder, width: 3)
              : BorderSide.none,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 44, child: Center(child: badge)),
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundImage: (item.avatarUrl != null &&
                          item.avatarUrl!.isNotEmpty)
                      ? NetworkImage(item.avatarUrl!)
                      : null,
                  backgroundColor: AppColors.primaryLight,
                  child: (item.avatarUrl == null || item.avatarUrl!.isEmpty)
                      ? Text(
                          item.name
                              .trim()
                              .split(' ')
                              .take(2)
                              .map((w) =>
                                  w.isNotEmpty ? w[0].toUpperCase() : '')
                              .join(),
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryColor))
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: item.rank <= 3
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis),
                      if (subLabel != null)
                        Text(subLabel,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: scoreColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
              width: 72,
              child: Text(item.altitudeLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: item.rank <= 3
                          ? scoreColor
                          : AppColors.textSecondary))),
          SizedBox(
              width: 48,
              child: Text('${item.score}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: scoreColor))),
        ],
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _TableRowShimmer extends StatelessWidget {
  const _TableRowShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Color(0xFFBAE6FD), width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle)),
            const SizedBox(width: 20),
            Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(
                child: Container(height: 12, color: Colors.white)),
            const SizedBox(width: 16),
            Container(width: 50, height: 12, color: Colors.white),
            const SizedBox(width: 16),
            Container(width: 30, height: 14, color: Colors.white),
          ],
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

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PieChartPainter extends CustomPainter {
  final double temuanValue;
  final double penyelesaianValue;
  final Color colorTemuan;
  final Color colorPenyelesaian;
  final Color colorEmpty;

  _PieChartPainter({
    required this.temuanValue,
    required this.penyelesaianValue,
    required this.colorTemuan,
    required this.colorPenyelesaian,
    required this.colorEmpty,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = temuanValue + penyelesaianValue;
    final center = Offset(size.width / 2, size.height / 2);
    // Radius luar dan dalam (donut)
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.55;

    final rect = Rect.fromCircle(center: center, radius: outerRadius);

    if (total == 0) {
      // Tampilkan lingkaran kosong
      final paint = Paint()
        ..color = colorEmpty
        ..style = PaintingStyle.stroke
        ..strokeWidth = outerRadius - innerRadius;
      canvas.drawCircle(center, (outerRadius + innerRadius) / 2, paint);
      return;
    }

    // Sudut awal: -90 derajat (atas)
    double startAngle = -90 * (3.14159265 / 180);
    const double gapAngle = 0.04; // gap antar segmen (radian)

    final segments = [
      {'value': temuanValue, 'color': colorTemuan},
      {'value': penyelesaianValue, 'color': colorPenyelesaian},
    ];

    for (final seg in segments) {
      final value = seg['value'] as double;
      final color = seg['color'] as Color;
      if (value <= 0) continue;

      final sweepAngle = (value / total) * 2 * 3.14159265 - gapAngle;

      // Shadow untuk efek depth
      final shadowPaint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(rect, startAngle, sweepAngle, false)
        ..close();
      canvas.drawPath(path, shadowPaint);

      // Segmen utama (donut)
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = outerRadius - innerRadius
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(
            center: center, radius: (outerRadius + innerRadius) / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}