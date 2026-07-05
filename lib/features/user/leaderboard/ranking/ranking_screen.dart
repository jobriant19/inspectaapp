import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../filter/ranking_location_filter.dart';
import 'ranking_podium_screen.dart';
import '../season_history_screen.dart';
import '../detail/leaderboard_detail_screen.dart' show LocationFilter;
import 'ranking_table_screen.dart';

class _AppColors {
  static const primary = Color(0xFF0EA5E9);
  static const primaryLight = Color(0xFFE0F2FE);
  static const surface = Color(0xFFF0F9FF);
  static const textPrimary = Color(0xFF0C4A6E);
  static const textSecondary = Color(0xFF64748B);
  static const gold = Color(0xFFFFD700);
  static const silver = Color(0xFFB0BEC5);
  static const bronze = Color(0xFFCD7F32);
}

class RankMember {
  final String id;
  final int rank;
  final String name;
  final int score;
  final int monthlyPoints;
  final String? avatarUrl;
  final Color avatarColor;
  final bool isSelf;
  final int? idJabatan;
  final String? jabatanNama;
  final bool? isVerificator;

  const RankMember({
    required this.id,
    required this.rank,
    required this.name,
    required this.score,
    required this.monthlyPoints,
    this.avatarUrl,
    required this.avatarColor,
    this.isSelf = false,
    this.idJabatan,
    this.jabatanNama,
    this.isVerificator,
  });

  bool get isTop3 => rank <= 3;

  Color get medalColor {
    if (rank == 1) return _AppColors.gold;
    if (rank == 2) return _AppColors.silver;
    if (rank == 3) return _AppColors.bronze;
    return _AppColors.primary;
  }
}

class RankingScreen extends StatefulWidget {
  final String lang;
  const RankingScreen({super.key, required this.lang});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Future<List<RankMember>>? _leaderboardFuture;
  DateTime? _lastUpdated;

  String _timeFilterMode = 'monthly'; 
  DateTime? _selectedDay;

  LocationFilter _selectedLocation = const LocationFilter(
    displayName: 'Semua Lokasi',
  );

  final Map<String, Map<String, String>> _texts = {
    'ID': {
      'loading': 'Memuat...',
      'saya': 'Saya',
      'last_updated_prefix': 'Terakhir diperbarui pada',
      'season': 'Musim',
      'history': 'Riwayat',
      'time_left_label': 'Sisa waktu:',
      'days_left_suffix': 'hari',
      'no_podium_data': 'Belum ada data peringkat\nuntuk bulan ini.',
      'error_prefix': 'Terjadi Kesalahan:',
      'no_rank_data': 'Belum ada peringkat bulan ini.',
      'rank_col': 'Rank',
      'name_col': 'Nama',
      'alt_col': 'Ketinggian',
      'score_col': 'Poin',
      'monthly_target': 'Target Bulanan',
      'filter_location': 'Filter Lokasi',
      'all_locations': 'Semua Lokasi',
      'label_lokasi': 'Lokasi',
      'label_unit': 'Unit',
      'label_subunit': 'Subunit',
      'label_area': 'Area',
      'reset': 'Reset',
      'apply_filter': 'Terapkan Filter',
      'filter_waktu': 'Filter Waktu',
      'bulanan': 'Bulanan',
      'harian': 'Harian',
      'pilih_hari': 'Pilih Hari',
      'terapkan': 'Terapkan',
    },
    'EN': {
      'loading': 'Loading...',
      'saya': 'Me',
      'last_updated_prefix': 'Last updated at',
      'season': 'Season',
      'history': 'History',
      'time_left_label': 'Time left:',
      'days_left_suffix': 'days',
      'no_podium_data': 'No ranking data available\nfor this month yet.',
      'error_prefix': 'An Error Occurred:',
      'no_rank_data': 'No rankings for this month yet.',
      'rank_col': 'Rank',
      'name_col': 'Name',
      'alt_col': 'Altitude',
      'score_col': 'Score',
      'monthly_target': 'Monthly Target',
      'filter_location': 'Filter Location',
      'all_locations': 'All Locations',
      'label_lokasi': 'Location',
      'label_unit': 'Unit',
      'label_subunit': 'Subunit',
      'label_area': 'Area',
      'reset': 'Reset',
      'apply_filter': 'Apply Filter',
      'filter_waktu': 'Time Filter',
      'bulanan': 'Monthly',
      'harian': 'Daily',
      'pilih_hari': 'Select Day',
      'terapkan': 'Apply',
    },
    'ZH': {
      'loading': '正在加载...',
      'saya': '我',
      'last_updated_prefix': '最后更新于',
      'season': '赛季',
      'history': '历史',
      'time_left_label': '剩余时间:',
      'days_left_suffix': '天',
      'no_podium_data': '本月暂无\n排名数据。',
      'error_prefix': '发生错误:',
      'no_rank_data': '本月暂无排名。',
      'rank_col': '排名',
      'name_col': '姓名',
      'alt_col': '高度',
      'score_col': '积分',
      'monthly_target': '月度目标',
      'filter_location': '筛选位置',
      'all_locations': '所有位置',
      'label_lokasi': '位置',
      'label_unit': '单位',
      'label_subunit': '子单位',
      'label_area': '区域',
      'reset': '重置',
      'apply_filter': '应用筛选',
      'filter_waktu': '时间筛选',
      'bulanan': '按月',
      'harian': '按日',
      'pilih_hari': '选择日期',
      'terapkan': '应用',
    },
  };

  String getTxt(String key) => _texts[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _selectedLocation = LocationFilter(displayName: getTxt('all_locations'));
    _fetchData();
  }

  void _fetchData() {
    final now = DateTime.now();
    setState(() {
      _lastUpdated = now;
      _leaderboardFuture = _fetchLeaderboardFromLogPoin(now);
    });
  }

  Future<List<RankMember>> _fetchLeaderboardFromLogPoin(DateTime now) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;

      String startStr;
      String endStr;

      if (_timeFilterMode == 'daily' && _selectedDay != null) {
        final d = _selectedDay!;
        startStr = DateTime(d.year, d.month, d.day).toIso8601String();
        endStr = DateTime(d.year, d.month, d.day, 23, 59, 59).toIso8601String();
      } else {
        startStr = DateTime(now.year, now.month, 1).toIso8601String();
        endStr = DateTime(now.year, now.month + 1, 1).toIso8601String();
      }

      // Ambil semua log_poin sesuai rentang waktu
      final List<dynamic> logData = await _supabase
          .from('log_poin')
          .select('id_user, poin, created_at')
          .gte('created_at', startStr)
          .lte('created_at', endStr);

      // Hitung total poin per user
      final Map<String, int> monthlyMap = {};
      for (final log in logData) {
        final uid = log['id_user']?.toString() ?? '';
        if (uid.isEmpty) continue;
        final p = (log['poin'] as num?)?.toInt() ?? 0;
        monthlyMap[uid] = (monthlyMap[uid] ?? 0) + p;
      }

      if (monthlyMap.isEmpty) return [];

      // Ambil data profil user
      final List<String> userIds = monthlyMap.keys.toList();
      var userQuery = _supabase
          .from('User')
          .select(
            'id_user, nama, gambar_user, id_lokasi, id_unit, id_subunit, id_area, is_visitor, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)',
          )
          .inFilter('id_user', userIds)
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

      // Gabungkan & hitung rank
      final List<Map<String, dynamic>> combined = [];
      for (final user in userData) {
        final uid = user['id_user']?.toString() ?? '';
        final mp = monthlyMap[uid] ?? 0;
        combined.add({
          'id_user': uid,
          'nama': user['nama'] as String,
          'gambar_user': user['gambar_user'] as String?,
          'monthlyPoints': mp,
          'id_jabatan': user['id_jabatan'] as int?,
          'is_verificator': user['is_verificator'] as bool?,
          'jabatan_nama': (user['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'] as String?,
        });
      }

      combined.sort(
        (a, b) =>
            (b['monthlyPoints'] as int).compareTo(a['monthlyPoints'] as int),
      );

      final List<RankMember> members = [];
      for (int i = 0; i < combined.length; i++) {
        final item = combined[i];
        final uid = item['id_user'] as String;
        members.add(
          RankMember(
            id: uid,
            rank: i + 1,
            name: item['nama'] as String,
            score: item['monthlyPoints'] as int,
            monthlyPoints: item['monthlyPoints'] as int,
            avatarUrl: item['gambar_user'] as String?,
            isSelf: uid == currentUserId,
            avatarColor: _AppColors.primary,
            idJabatan: item['id_jabatan'] as int?,
            jabatanNama: item['jabatan_nama'] as String?,
            isVerificator: item['is_verificator'] as bool?,
          ),
        );
      }

      return members;
    } catch (e) {
      debugPrint('Error fetching leaderboard from log_poin: $e');
      return [];
    }
  }

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

  void _showTimeFilterPicker() async {
    String tempMode = _timeFilterMode;
    DateTime tempDay = _selectedDay ?? DateTime.now();
    DateTime tempDisplayMonth = DateTime(tempDay.year, tempDay.month, 1);
    final now = DateTime.now();

    final locale = widget.lang == 'ID' ? 'id_ID'
        : widget.lang == 'ZH' ? 'zh_CN' : 'en_US';

    final dayLabels = widget.lang == 'ZH'
        ? ['日','一','二','三','四','五','六']
        : widget.lang == 'ID'
            ? ['Min','Sen','Sel','Rab','Kam','Jum','Sab']
            : ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          final daysInMonth = DateUtils.getDaysInMonth(
              tempDisplayMonth.year, tempDisplayMonth.month);
          final firstWeekday =
              DateTime(tempDisplayMonth.year, tempDisplayMonth.month, 1)
                      .weekday %
                  7;
          final monthLabel =
              DateFormat('MMMM yyyy', locale).format(tempDisplayMonth);
          final bool isCurrentMonth = tempDisplayMonth.year == now.year &&
              tempDisplayMonth.month == now.month;

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
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                  decoration: const BoxDecoration(
                    color: _AppColors.primaryLight,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_month_rounded, color: _AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(getTxt('filter_waktu'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _AppColors.textPrimary))),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: _AppColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                    ),
                  ]),
                ),
                // MONTHLY / DAILY TOGGLE
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
                        final label = mode == 'monthly' ? getTxt('bulanan') : getTxt('harian');
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
                              child: Center(child: Text(label,
                                style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : _AppColors.textSecondary,
                                ))),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // CONTENT
                if (tempMode == 'monthly')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _AppColors.primaryLight),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_rounded, color: _AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('MMMM yyyy', locale).format(now),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _AppColors.textPrimary),
                        ),
                      ]),
                    ),
                  )
                else
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Column(children: [
                        // MONTH HEADER NAVIGATION
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => setSt(() => tempDisplayMonth = DateTime(
                                  tempDisplayMonth.year, tempDisplayMonth.month - 1, 1)),
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
                            Text(monthLabel,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _AppColors.textPrimary)),
                            GestureDetector(
                              onTap: isCurrentMonth
                                  ? null
                                  : () => setSt(() => tempDisplayMonth = DateTime(
                                      tempDisplayMonth.year, tempDisplayMonth.month + 1, 1)),
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
                        const SizedBox(height: 8),
                        // DAILY HEADER
                        Row(children: dayLabels.map((d) => Expanded(
                          child: Center(child: Text(d,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _AppColors.textSecondary))),
                        )).toList()),
                        const SizedBox(height: 6),
                        // DATE GRID
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7, crossAxisSpacing: 4, mainAxisSpacing: 4, childAspectRatio: 1,
                          ),
                          itemCount: firstWeekday + daysInMonth,
                          itemBuilder: (_, i) {
                            if (i < firstWeekday) return const SizedBox();
                            final day = i - firstWeekday + 1;
                            final date = DateTime(
                                tempDisplayMonth.year, tempDisplayMonth.month, day);
                            final isSelected = tempDay.year == date.year &&
                                tempDay.month == date.month && tempDay.day == date.day;
                            final isToday = now.year == date.year &&
                                now.month == date.month && now.day == date.day;
                            final isFuture = date.isAfter(now);
                            return GestureDetector(
                              onTap: isFuture ? null : () => setSt(() => tempDay = date),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                decoration: BoxDecoration(
                                  color: isSelected ? _AppColors.primary
                                      : isToday ? _AppColors.primaryLight : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: isToday && !isSelected
                                      ? Border.all(color: _AppColors.primary, width: 1.2) : null,
                                ),
                                child: Center(child: Text('$day',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.white
                                        : isFuture ? _AppColors.textSecondary : _AppColors.textPrimary,
                                  ))),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        // APPLY BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              setState(() {
                                _timeFilterMode = tempMode;
                                _selectedDay = tempMode == 'daily' ? tempDay : null;
                              });
                              _fetchData();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: Text(getTxt('terapkan'),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ),
                      ]),
                    ),
                  ),
                // APPLY BUTTON FOR MONTHLY
                if (tempMode == 'monthly')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _timeFilterMode = 'monthly';
                            _selectedDay = null;
                          });
                          _fetchData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(getTxt('terapkan'),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ),
                  ),
              ]),
            ),
          );
        },
      ),
    );
  }

  String get _lastUpdatedText {
    if (_lastUpdated == null) return getTxt('loading');
    final formattedDate = DateFormat(
      'd MMM yyyy HH:mm',
      'id_ID',
    ).format(_lastUpdated!);
    return '${getTxt('last_updated_prefix')} $formattedDate (GMT+7)';
  }

  static const double _stickyHeaderHeight = 160.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async => _fetchData(),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: RankingPodiumScreen(
                leaderboardFuture: _leaderboardFuture,
                lang: widget.lang,
                isDaily: _timeFilterMode == 'daily' && _selectedDay != null,
                selectedDay: _selectedDay,
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                height: _stickyHeaderHeight,
                child: Container(
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLastUpdated(),
                      _buildSeasonBanner(),
                      _buildFilterButtonsRow(),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            ),
            ...RankingTableScreen.buildSlivers(
              context: context,
              leaderboardFuture: _leaderboardFuture,
              lang: widget.lang,
              getTxt: getTxt,
              isDaily: _timeFilterMode == 'daily' && _selectedDay != null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationFilterButton() {
    final isFiltered = _selectedLocation.idLokasi != null;
    return GestureDetector(
      onTap: _showLocationPicker,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isFiltered ? _AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFiltered ? _AppColors.primary : const Color(0xFFBAE6FD),
            width: isFiltered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_rounded,
              size: 14,
              color: isFiltered ? _AppColors.primary : _AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                _selectedLocation.displayName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isFiltered ? FontWeight.w700 : FontWeight.w600,
                  color:
                      isFiltered ? _AppColors.primary : _AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isFiltered) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedLocation = LocationFilter(
                      displayName: getTxt('all_locations'),
                    );
                  });
                  _fetchData();
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: _AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 11,
                    color: _AppColors.primary,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 3),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: isFiltered ? _AppColors.primary : _AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilterButton() {
    final locale = widget.lang == 'ID' ? 'id_ID'
        : widget.lang == 'ZH' ? 'zh_CN' : 'en_US';
    final isDaily = _timeFilterMode == 'daily' && _selectedDay != null;

    final String label = isDaily
        ? DateFormat('d MMM yyyy', locale).format(_selectedDay!)
        : DateFormat('MMM yyyy', locale).format(DateTime.now());

    return GestureDetector(
      onTap: _showTimeFilterPicker,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isDaily ? _AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDaily ? _AppColors.primary : const Color(0xFFBAE6FD),
            width: isDaily ? 1.5 : 1,
          ),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.access_time_rounded, size: 14,
            color: isDaily ? _AppColors.primary : _AppColors.textSecondary),
          const SizedBox(width: 5),
          Flexible(child: Text(label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isDaily ? FontWeight.w700 : FontWeight.w600,
              color: isDaily ? _AppColors.primary : _AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis)),
          if (isDaily) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                setState(() { _timeFilterMode = 'monthly'; _selectedDay = null; });
                _fetchData();
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: _AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 11, color: _AppColors.primary),
              ),
            ),
          ],
          const SizedBox(width: 3),
          Icon(Icons.keyboard_arrow_down_rounded, size: 14,
            color: isDaily ? _AppColors.primary : _AppColors.textSecondary),
        ]),
      ),
    );
  }

  Widget _buildFilterButtonsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Expanded(child: _buildTimeFilterButton()),
          const SizedBox(width: 8),
          Expanded(child: _buildLocationFilterButton()),
          const SizedBox(width: 8),
          Expanded(child: _buildSeasonHistoryFilterButton()),
        ],
      ),
    );
  }

  // SEASON HISTORY BUTTON
  Widget _buildSeasonHistoryFilterButton() {
    final String label = widget.lang == 'ID'
        ? 'Riwayat'
        : widget.lang == 'ZH'
        ? '历史'
        : 'History';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RiwayatMusimScreen(lang: widget.lang),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBAE6FD), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_rounded,
                size: 14, color: _AppColors.textSecondary),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SEASON BANNER
  Widget _buildSeasonBanner() {
    final String timeLeftLabel = widget.lang == 'ID'
        ? 'Sisa waktu:'
        : widget.lang == 'ZH'
        ? '剩余时间:'
        : 'Time left:';

    final now = DateTime.now();
    final endOfMonth = DateTime(
      now.year,
      now.month + 1,
      1,
    ).subtract(const Duration(seconds: 1));
    final diff = endOfMonth.difference(now);
    final daysLeft = diff.inDays;
    final hoursLeft = diff.inHours % 24;

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

    final locale = widget.lang == 'ID'
        ? 'id_ID'
        : widget.lang == 'ZH'
        ? 'zh_CN'
        : 'en_US';
    final isDaily = _timeFilterMode == 'daily' && _selectedDay != null;
    final displayDate = isDaily ? _selectedDay! : DateTime.now();
    final fmt = isDaily
        ? DateFormat('d MMMM yyyy', locale).format(displayDate)
        : DateFormat('MMMM yyyy', locale).format(displayDate);

    const seasonGreen = Color(0xFF059669);
    const seasonGreenBg = Color(0xFFECFDF5);
    const seasonGreenBorder = Color(0xFFA7F3D0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ACTIVE PERIOD
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      fmt,
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
          ),
          const SizedBox(width: 10),
          // TIME LEFT
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_rounded,
                      size: 16, color: _AppColors.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '$timeLeftLabel $timeLeftStr',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdated() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _AppColors.primaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.access_time_filled_rounded,
                size: 13,
                color: _AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                _lastUpdatedText,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}