import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/jabatan_helper.dart';
import 'user_profile_modal.dart';

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
  final String? idUser;
  final int rank;
  final String name;
  final String? avatarUrl;
  final int score;
  final int monthlyPoints; // poin dari log_poin bulan ini
  final int? idJabatan;
  final String? jabatanNama;
  final bool? isVerificator;

  LeaderboardMember({
    this.idUser,
    required this.rank,
    required this.name,
    this.avatarUrl,
    required this.score,
    this.monthlyPoints = 0,
    this.idJabatan,
    this.jabatanNama,
    this.isVerificator,
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
  final String? idLokasi;
  final String? idUnit;
  final String? idSubunit;
  final String? idArea;
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
    'current_season': 'Musim Aktif',
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
    'current_season': 'Active Season',
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
    'current_season': '当前赛季',
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
  String? _tempLokasiId;
  String? _tempUnitId;
  String? _tempSubunitId;
  String? _tempAreaId;
  List<Map<String, dynamic>> _tempUnitList = [];
  List<Map<String, dynamic>> _tempSubunitList = [];
  List<Map<String, dynamic>> _tempAreaList = [];

  FilterType _filterType = FilterType.monthly;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Jika bulan/tahun yang dipilih adalah bulan ini, default ke hari ini
    // Jika bukan, default ke tanggal 1 bulan tersebut
    if (now.year == widget.year && now.month == widget.month) {
      _selectedDate = DateTime(now.year, now.month, now.day);
    } else {
      _selectedDate = DateTime(widget.year, widget.month, 1);
    }
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

  Future<List<Map<String, dynamic>>> _fetchUnitByLokasi(String idLokasi) async {
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

  Future<List<Map<String, dynamic>>> _fetchSubunitByUnit(String idUnit) async {
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

  Future<List<Map<String, dynamic>>> _fetchAreaBySubunit(String idSubunit) async {
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

        // Fetch target
        _chartTargetFuture = _supabase.rpc('get_chart_target', params: {
          'selected_month': _selectedDate.month,
          'selected_year' : _selectedDate.year,
          'selected_unit_id': _selectedLocation.idUnit,
        }).then((response) {
          final List<dynamic> data = response;
          if (data.isEmpty) {
            return const ChartTarget(targetTemuan: 5, targetPenyelesaian: 4);
          }
          return ChartTarget(
            targetTemuan      : data[0]['target_temuan'] as int,
            targetPenyelesaian: data[0]['target_penyelesaian'] as int,
          );
        }).catchError((_) =>
            const ChartTarget(targetTemuan: 5, targetPenyelesaian: 4));

        // Fetch chart data
        _chartFuture = _supabase.rpc('get_daily_chart_data', params: {
          'selected_month'     : _selectedDate.month,
          'selected_year'      : _selectedDate.year,
          'selected_unit_id'   : _selectedLocation.idUnit,
          'selected_lokasi_id' : _selectedLocation.idLokasi,
          'selected_subunit_id': _selectedLocation.idSubunit,
          'selected_area_id'   : _selectedLocation.idArea,
        }).then((response) {
          final List<dynamic> data = response;
          return data.map((item) => DailyChartData(
            date        : item['tanggal'] as int,
            temuan      : item['temuan'] as int,
            penyelesaian: item['penyelesaian'] as int,
          )).toList();
        });

        // Fetch leaderboard MONTHLY dari log_poin
        _leaderboardFuture = _fetchMonthlyLeaderboardFromLogPoin();

      } else {
        // Mode harian
        _chartTargetFuture = null;
        _chartFuture = null;

        // Fetch pie chart harian
        _dailyPieFuture = _supabase.rpc('get_daily_chart_data', params: {
          'selected_month'     : _selectedDate.month,
          'selected_year'      : _selectedDate.year,
          'selected_unit_id'   : _selectedLocation.idUnit,
          'selected_lokasi_id' : _selectedLocation.idLokasi,
          'selected_subunit_id': _selectedLocation.idSubunit,
          'selected_area_id'   : _selectedLocation.idArea,
        }).then((response) {
          final List<dynamic> data = response;
          final selectedDay = _selectedDate.day;
          final found = data.firstWhere(
            (item) => (item['tanggal'] as int) == selectedDay,
            orElse: () => {'tanggal': selectedDay, 'temuan': 0, 'penyelesaian': 0},
          );
          return DailyChartData(
            date        : found['tanggal'] as int,
            temuan      : found['temuan'] as int,
            penyelesaian: found['penyelesaian'] as int,
          );
        });

        // Fetch leaderboard DAILY dari log_poin
        _leaderboardFuture = _fetchDailyLeaderboardFromLogPoin();
      }
    });
  }

  // ── Monthly leaderboard dari log_poin ──────────────────────────────────────
  Future<List<LeaderboardMember>> _fetchMonthlyLeaderboardFromLogPoin() async {
    try {
      final startOfMonth =
          DateTime(_selectedDate.year, _selectedDate.month, 1).toIso8601String();
      final endOfMonth =
          DateTime(_selectedDate.year, _selectedDate.month + 1, 1).toIso8601String();

      // 1. Ambil log_poin bulan ini
      final List<dynamic> logData = await _supabase
          .from('log_poin')
          .select('id_user, poin')
          .gte('created_at', startOfMonth)
          .lt('created_at', endOfMonth);

      // 2. Hitung total per user
      final Map<String, int> monthlyMap = {};
      for (final log in logData) {
        final uid = log['id_user']?.toString() ?? '';
        if (uid.isEmpty) continue;
        final p = (log['poin'] as num?)?.toInt() ?? 0;
        monthlyMap[uid] = (monthlyMap[uid] ?? 0) + p;
      }

      if (monthlyMap.isEmpty) return [];

      // 3. Ambil profil user dengan filter lokasi
      var userQuery = _supabase
          .from('User')
          .select(
            'id_user, nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)',
          )
          .inFilter('id_user', monthlyMap.keys.toList())
          .or('is_visitor.is.null,is_visitor.eq.false');

      if (_selectedLocation.idArea != null) {
        userQuery = userQuery.eq('id_area', _selectedLocation.idArea!);
      } else if (_selectedLocation.idSubunit != null) {
        userQuery = userQuery.eq('id_subunit', _selectedLocation.idSubunit!);
      } else if (_selectedLocation.idUnit != null) {
        userQuery = userQuery.eq('id_unit', _selectedLocation.idUnit!);
      } else if (_selectedLocation.idLokasi != null) {
        userQuery = userQuery.eq('id_lokasi', _selectedLocation.idLokasi!);
      }

      final List<dynamic> userData = await userQuery;

      // 4. Gabungkan & urutkan
      final List<Map<String, dynamic>> combined = [];
      for (final user in userData) {
        final uid = user['id_user']?.toString() ?? '';
        combined.add({
          'uid'            : uid,
          'nama'           : user['nama'] as String,
          'gambar_user'    : user['gambar_user'] as String?,
          'poin'           : monthlyMap[uid] ?? 0,
          'id_jabatan'     : user['id_jabatan'] as int?,
          'is_verificator' : user['is_verificator'] as bool?,
          'jabatan_nama'   : (user['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'] as String?,
        });
      }
      combined.sort((a, b) =>
          (b['poin'] as int).compareTo(a['poin'] as int));

      // 5. Map ke model
      return combined.asMap().entries.map((e) {
        final item = e.value;
        return LeaderboardMember(
          idUser       : item['uid'] as String,
          rank         : e.key + 1,
          name         : item['nama'] as String,
          avatarUrl    : item['gambar_user'] as String?,
          score        : item['poin'] as int,
          monthlyPoints: item['poin'] as int,
          idJabatan    : item['id_jabatan'] as int?,
          jabatanNama  : item['jabatan_nama'] as String?,
          isVerificator: item['is_verificator'] as bool?,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching monthly leaderboard from log_poin: $e');
      return [];
    }
  }

  // ── Daily leaderboard dari log_poin ────────────────────────────────────────
  Future<List<LeaderboardMember>> _fetchDailyLeaderboardFromLogPoin() async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final startOfDay = '${dateStr}T00:00:00.000Z';
      final endOfDay   = '${dateStr}T23:59:59.999Z';

      // 1. Ambil log_poin hari ini
      final List<dynamic> logData = await _supabase
          .from('log_poin')
          .select('id_user, poin')
          .gte('created_at', startOfDay)
          .lte('created_at', endOfDay);

      // 2. Hitung total per user
      final Map<String, int> dailyMap = {};
      for (final log in logData) {
        final uid = log['id_user']?.toString() ?? '';
        if (uid.isEmpty) continue;
        final p = (log['poin'] as num?)?.toInt() ?? 0;
        dailyMap[uid] = (dailyMap[uid] ?? 0) + p;
      }

      if (dailyMap.isEmpty) return [];

      // 3. Ambil profil user dengan filter lokasi
      var userQuery = _supabase
          .from('User')
          .select(
            'id_user, nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)',
          )
          .inFilter('id_user', dailyMap.keys.toList())
          .or('is_visitor.is.null,is_visitor.eq.false');

      if (_selectedLocation.idArea != null) {
        userQuery = userQuery.eq('id_area', _selectedLocation.idArea!);
      } else if (_selectedLocation.idSubunit != null) {
        userQuery = userQuery.eq('id_subunit', _selectedLocation.idSubunit!);
      } else if (_selectedLocation.idUnit != null) {
        userQuery = userQuery.eq('id_unit', _selectedLocation.idUnit!);
      } else if (_selectedLocation.idLokasi != null) {
        userQuery = userQuery.eq('id_lokasi', _selectedLocation.idLokasi!);
      }

      final List<dynamic> userData = await userQuery;

      // 4. Gabungkan & urutkan, hanya tampilkan yang > 0
      final List<Map<String, dynamic>> combined = [];
      for (final user in userData) {
        final uid = user['id_user']?.toString() ?? '';
        final dp = dailyMap[uid] ?? 0;
        if (dp > 0) {
          combined.add({
            'uid'            : uid,
            'nama'           : user['nama'] as String,
            'gambar_user'    : user['gambar_user'] as String?,
            'poin'           : dp,
            'id_jabatan'     : user['id_jabatan'] as int?,
            'is_verificator' : user['is_verificator'] as bool?,
            'jabatan_nama'   : (user['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'] as String?,
          });
        }
      }
      combined.sort((a, b) =>
          (b['poin'] as int).compareTo(a['poin'] as int));

      // 5. Map ke model
      return combined.asMap().entries.map((e) {
        final item = e.value;
        return LeaderboardMember(
          idUser       : item['uid'] as String,
          rank         : e.key + 1,
          name         : item['nama'] as String,
          avatarUrl    : item['gambar_user'] as String?,
          score        : item['poin'] as int,
          monthlyPoints: item['poin'] as int,
          idJabatan    : item['id_jabatan'] as int?,
          jabatanNama  : item['jabatan_nama'] as String?,
          isVerificator: item['is_verificator'] as bool?,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching daily leaderboard from log_poin: $e');
      return [];
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(widget.year, widget.month, 1),
      lastDate: DateTime(widget.year, widget.month + 1, 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0EA5E9),        // warna terpilih
              onPrimary: Colors.white,            // teks pada warna terpilih
              surface: Colors.white,              // background kalender
              onSurface: Color(0xFF0C4A6E),       // warna teks hari
              secondary: Color(0xFF38BDF8),
              onSecondary: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0EA5E9), // warna tombol Cancel/OK
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchData();
    }
  }

  // ── Bottom Sheet Filter Lokasi ────────────────────────────────────────────

  void _showLocationPicker() async {
    _tempLokasiId  = _selectedLocation.idLokasi;
    _tempUnitId    = _selectedLocation.idUnit;
    _tempSubunitId = _selectedLocation.idSubunit;
    _tempAreaId    = _selectedLocation.idArea;

    _tempUnitList    = [];
    _tempSubunitList = [];
    _tempAreaList    = [];

    if (_tempLokasiId != null) {
      _tempUnitList = await _fetchUnitByLokasi(_tempLokasiId!);
    }
    if (_tempUnitId != null && _tempUnitList.isNotEmpty) {
      _tempSubunitList = await _fetchSubunitByUnit(_tempUnitId!);
    }
    if (_tempSubunitId != null && _tempSubunitList.isNotEmpty) {
      _tempAreaList = await _fetchAreaBySubunit(_tempSubunitId!);
    }

    if (!mounted) return;
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
    required String? selectedId,
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String nameKey,
    required Function(String id, String name) onSelect,
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
            final id = item[idKey].toString();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1D72F3)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _getTxt('appbar_title'),
          style: GoogleFonts.poppins(
            color: const Color(0xFF1D72F3),
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        iconTheme: const IconThemeData(color: Color(0xFF1D72F3)),
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
    final endOfMonth = DateTime(
        widget.year, widget.month + 1, 1)
        .subtract(const Duration(seconds: 1));
    final diff = endOfMonth.difference(now);
    final daysLeft = diff.inDays;
    final hoursLeft = diff.inHours % 24;
    final isOngoing = !diff.isNegative;
    final isCurrentSeason = now.year == widget.year && now.month == widget.month;

    String timeLeftStr;
    if (diff.isNegative) {
      timeLeftStr = widget.lang == 'ID'
          ? 'Sudah berakhir'
          : widget.lang == 'ZH'
              ? '已结束'
              : 'Ended';
    } else if (daysLeft > 0) {
      timeLeftStr = widget.lang == 'ID'
          ? '$daysLeft hari $hoursLeft jam'
          : widget.lang == 'ZH'
              ? '$daysLeft 天 $hoursLeft 小时'
              : '$daysLeft days $hoursLeft hrs';
    } else {
      timeLeftStr = widget.lang == 'ID'
          ? '$hoursLeft jam'
          : widget.lang == 'ZH'
              ? '$hoursLeft 小时'
              : '$hoursLeft hrs';
    }

    final String statusLabel = isOngoing
        ? (widget.lang == 'ID'
            ? 'Sedang Berlangsung'
            : widget.lang == 'ZH'
                ? '进行中'
                : 'Ongoing')
        : (widget.lang == 'ID'
            ? 'Berakhir'
            : widget.lang == 'ZH'
                ? '已结束'
                : 'Ended');

    // Warna diambil konsisten dari season_history_screen.dart & ranking_screen.dart
    const seasonGreen = Color(0xFF059669);
    const seasonGreenBg = Color(0xFFECFDF5);
    const seasonGreenBorder = Color(0xFFA7F3D0);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: badge "Season" + status Ongoing/Ended — dual-style sama seperti season_history_screen.dart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: isCurrentSeason
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF0EA5E9)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withValues(alpha: 0.30),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded, size: 13, color: Colors.white),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                _getTxt('current_season'),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.outlined_flag_rounded,
                                size: 12, color: Color(0xFF64748B)),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                '${_getTxt('season')} ${widget.year}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              if (isOngoing)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF059669).withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF059669),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: chip periode — sama seperti _buildSeasonBanner() di ranking_screen.dart
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: seasonGreenBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: seasonGreenBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_month_rounded,
                    size: 16, color: seasonGreen),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.seasonTitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: seasonGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Row 3: chip sisa waktu — dilebarkan penuh & boleh 2 baris agar terlihat jelas, tidak terpotong
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_rounded,
                    size: 16, color: AppColors.primaryColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${_getTxt('time_left')} $timeLeftStr',
                    textAlign: TextAlign.center,
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
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
                  child: Builder(
                    builder: (context) {
                      final now = DateTime.now();
                      final ScrollController scrollCtrl = ScrollController();

                      // Hitung index bar hari ini
                      int todayIndex = -1;
                      if (now.year == _selectedDate.year && now.month == _selectedDate.month) {
                        todayIndex = data.indexWhere((d) => d.date == now.day);
                      }

                      // Scroll ke posisi hari ini di tengah setelah frame selesai render
                      if (todayIndex >= 0) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (scrollCtrl.hasClients) {
                            final chartAreaWidth = context.size?.width ?? 300;
                            final targetOffset = (todayIndex * barGroupWidth) - (chartAreaWidth / 2) + (barGroupWidth / 2);
                            scrollCtrl.jumpTo(targetOffset.clamp(0.0, scrollCtrl.position.maxScrollExtent));
                          }
                        });
                      }

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: scrollCtrl,
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
                      );
                    },
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
          // Header — samakan dengan ranking_table_screen.dart
          Container(
            color: const Color(0xFFF8FAFF),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Text(
                    widget.lang == 'ID' ? 'Rank' : widget.lang == 'ZH' ? '排名' : 'Rank',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                  ),
                ),
                Expanded(
                  child: Text(_getTxt('name_col'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    widget.lang == 'ID' ? 'Poin' : widget.lang == 'ZH' ? '积分' : 'Points',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          // Target row — samakan dengan ranking_table_screen.dart
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              border: Border(bottom: BorderSide(color: AppColors.primaryLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(_getTxt('monthly_target'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor))),
                const SizedBox(
                  width: 100,
                  child: Text('1000',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
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

  Widget _buildRankRow(LeaderboardMember item) {
    final isTop3 = item.rank <= 3;
    Color medalColor;
    Widget badge;

    if (item.rank == 1) {
      medalColor = AppColors.gold;
      badge = const Text('🥇', style: TextStyle(fontSize: 22));
    } else if (item.rank == 2) {
      medalColor = AppColors.silver;
      badge = const Text('🥈', style: TextStyle(fontSize: 22));
    } else if (item.rank == 3) {
      medalColor = AppColors.bronze;
      badge = const Text('🥉', style: TextStyle(fontSize: 22));
    } else {
      medalColor = AppColors.textSecondary;
      badge = Text('${item.rank}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13.5, fontWeight: FontWeight.w600,
          color: AppColors.textSecondary));
    }

    return InkWell(
      onTap: item.idUser == null ? null : () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (_, controller) => UserProfileModal(
              controller: controller,
              userId: item.idUser!,
              userName: item.name,
              userAvatarUrl: item.avatarUrl,
              userRank: item.rank,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isTop3 ? medalColor.withValues(alpha: 0.04) : Colors.white,
          border: Border(
            bottom: const BorderSide(color: AppColors.border, width: 1),
            left: isTop3
                ? BorderSide(color: medalColor, width: 3)
                : BorderSide.none,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            SizedBox(width: 48, child: Center(child: badge)),
            const SizedBox(width: 14),
            Expanded(
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isTop3
                          ? Border.all(color: medalColor.withValues(alpha: 0.6), width: 2)
                          : null,
                      boxShadow: isTop3
                          ? [BoxShadow(color: medalColor.withValues(alpha: 0.25), blurRadius: 6)]
                          : null,
                    ),
                    child: CircleAvatar(
                      radius: 17,
                      backgroundImage: (item.avatarUrl != null && item.avatarUrl!.isNotEmpty)
                          ? NetworkImage(item.avatarUrl!)
                          : null,
                      backgroundColor: AppColors.primaryLight,
                      child: (item.avatarUrl == null || item.avatarUrl!.isEmpty)
                          ? Text(
                              item.name.trim().split(' ').take(2)
                                  .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                                  .join(),
                              style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: AppColors.primaryColor))
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isTop3 ? FontWeight.w700 : FontWeight.w500,
                            color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        _buildJabatanBadge(
                          idJabatan: item.idJabatan,
                          jabatanNama: item.jabatanNama,
                          isVerificator: item.isVerificator,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 100,
              child: Text('${item.monthlyPoints}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800,
                  color: isTop3 ? medalColor : AppColors.primaryDark))),
          ],
        ),
      ),
    );
  }

  Widget _buildJabatanBadge({
    required int?    idJabatan,
    required String? jabatanNama,
    required bool?   isVerificator,
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
            style: TextStyle(
                fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
      ]),
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