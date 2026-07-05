import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../filter/ranking_location_filter.dart';
import 'leaderboard_podium_screen.dart';
import 'leaderboard_table_screen.dart';

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
    'no_rank_data': 'Belum Ada Data Peringkat',
    'no_rank_data_sub': 'Data akan muncul di sini setelah ada aktivitas poin pada periode ini.',
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
    'no_rank_data': 'No Ranking Data Yet',
    'no_rank_data_sub': 'Data will appear here once points activity is recorded for this period.',
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
    'no_rank_data': '暂无排名数据',
    'no_rank_data_sub': '本期一旦有积分活动记录，数据将显示在此处。',
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

  LocationFilter _selectedLocation = const LocationFilter(displayName: 'Semua Lokasi');

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
    _fetchData();
  }


  String _getTxt(String key) =>
      leaderboardTexts[widget.lang]?[key] ??
      leaderboardTexts['ID']![key] ??
      key;

  void _fetchData() {
    setState(() {
      if (_filterType == FilterType.monthly) {
        _leaderboardFuture = _fetchMonthlyLeaderboardFromLogPoin();
      } else {
        _leaderboardFuture = _fetchDailyLeaderboardFromLogPoin();
      }
    });
  }

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

  // ── Filter Lokasi ─────────────────────────────────────────────────────────

  void _showLocationPicker() async {
    final result = await RankingLocationFilter.show(
      context: context,
      lang: widget.lang,
      currentSelection: _selectedLocation,
    );
    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
      _fetchData();
    }
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
          LeaderboardPodiumScreen(
            leaderboardFuture: _leaderboardFuture,
            lang: widget.lang,
            isDaily: _filterType == FilterType.daily,
          ),
          LeaderboardTableScreen(
            leaderboardFuture: _leaderboardFuture,
            lang: widget.lang,
            isDaily: _filterType == FilterType.daily,
          ),
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
            flex: 1,
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
              flex: 1,
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
          ],
        ],
      ),
    );
  }
}