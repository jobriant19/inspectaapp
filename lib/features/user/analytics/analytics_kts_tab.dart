import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/services/gemini_recurring_service.dart';
import '../finding/finding_detail_screen.dart';
import '../home/kts_finding_card.dart';

// ─── Warna & Tema ──────────────────────────────────────────────────────────
class _KTSAppColors {
  static const primary = Color(0xFFF59E0B);
  static const primaryLight = Color(0xFFFEF3C7);
  static const surface = Color(0xFFFFFBEB);
  static const textPrimary = Color(0xFF78350F);
  static const textSecondary = Color(0xFF92400E);
  static const textMuted = Color(0xFFD97706);
  static const divider = Color(0xFFFDE68A);
  static const selfHighlight = Color(0xFFFFF7ED);
  static const selfHighlightBorder = Color(0xFFFED7AA);
}

// ─── Model Data ──────────────────────────────────────────────────────────────
class KTSMemberData {
  final String name;
  final String? unitName;
  final int findings;
  final int completed;
  final bool isSelf;
  final String? avatarUrl;
  final Color? avatarColor;

  const KTSMemberData({
    required this.name,
    this.unitName,
    required this.findings,
    required this.completed,
    this.isSelf = false,
    this.avatarUrl,
    this.avatarColor,
  });
}

class KTSRecurringTopic {
  final String topic;
  final String locationArea;
  final int total;
  final String? imageUrl;
  final List<Map<String, dynamic>> findings;

  const KTSRecurringTopic({
    required this.topic,
    required this.locationArea,
    required this.total,
    this.imageUrl,
    required this.findings,
  });
}

class _KTSChartBarData {
  final int date;
  final int temuan;
  final int penyelesaian;
  _KTSChartBarData({required this.date, required this.temuan, required this.penyelesaian});
}

// ─── Main Widget ──────────────────────────────────────────────────────────────
class KTSAnalyticsTab extends StatefulWidget {
  final String lang;
  final String userId;
  final VoidCallback? onTabChanged; // Tambahkan callback
  
  const KTSAnalyticsTab({
    super.key,
    required this.lang,
    required this.userId,
    this.onTabChanged,
  });

  @override
  State<KTSAnalyticsTab> createState() => _KTSAnalyticsTabState();
}

class _KTSAnalyticsTabState extends State<KTSAnalyticsTab>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient _supabase = Supabase.instance.client;

  final Map<String, Map<String, String>> _texts = {
    'ID': {
      'anggota': 'Anggota', 'temuan_berulang': 'Temuan Berulang',
      'memuat_data': 'Memuat data...', 'diperbarui_pada': 'Terakhir diperbarui pada',
      'semua_grup_anggota': 'Semua Grup', 'gagal_muat_anggota': 'Gagal memuat data Anggota',
      'tidak_ada_data_anggota': 'Tidak ada data anggota.',
      'tidak_ada_data_level': 'Tidak ada data untuk level',
      'nama': 'Nama', 'temuan': 'Temuan', 'selesai': 'Selesai',
      'target_bulanan': 'Target Bulanan', 'saya': 'Saya', 'rank': 'Rank',
      'topik': 'Topik', 'belum_memiliki_temuan': 'belum\nmemiliki temuan berulang',
      'pilih_bulan': 'Pilih Bulan', 'pilih_grup': 'Pilih Grup',
      'pilih_periode': 'Pilih Periode', 'pilih_penemu': 'Pilih Penemu',
      'cari': 'Cari...', 'dari': 'Dari', 'sampai': 'Sampai',
      'terapkan': 'Terapkan', 'total': 'Total',
      'penemu': 'Penemu', 'periode': 'Periode',
      'daftar_temuan': 'Daftar Temuan', 'di_sekitar': 'Di sekitar',
      'semua_grup': 'Semua Penemu', 'hari_terlewat': 'hari terlewat',
      'jam_terlewat': 'jam terlewat', 'menit_terlewat': 'menit terlewat',
      'deadline_hari_ini': 'Deadline hari ini', 'hari_tersisa': 'hari tersisa',
    },
    'EN': {
      'anggota': 'Members', 'temuan_berulang': 'Recurring Findings',
      'memuat_data': 'Loading data...', 'diperbarui_pada': 'Last updated at',
      'semua_grup_anggota': 'All Groups', 'gagal_muat_anggota': 'Failed to load Member data',
      'tidak_ada_data_anggota': 'No member data available.',
      'tidak_ada_data_level': 'No data for level',
      'nama': 'Name', 'temuan': 'Findings', 'selesai': 'Completed',
      'target_bulanan': 'Monthly Target', 'saya': 'Me', 'rank': 'Rank',
      'topik': 'Topic', 'belum_memiliki_temuan': 'does not have\nrecurring findings yet',
      'pilih_bulan': 'Select Month', 'pilih_grup': 'Select Group',
      'pilih_periode': 'Select Period', 'pilih_penemu': 'Select Finder',
      'cari': 'Search...', 'dari': 'From', 'sampai': 'To',
      'terapkan': 'Apply', 'total': 'Total',
      'penemu': 'Finder', 'periode': 'Period',
      'daftar_temuan': 'Finding List', 'di_sekitar': 'Around',
      'semua_grup': 'All Finders', 'hari_terlewat': 'days overdue',
      'jam_terlewat': 'hours overdue', 'menit_terlewat': 'minutes overdue',
      'deadline_hari_ini': 'Deadline today', 'hari_tersisa': 'days remaining',
    },
    'ZH': {
      'anggota': '成员', 'temuan_berulang': '重复发现',
      'memuat_data': '加载数据...', 'diperbarui_pada': '最后更新于',
      'semua_grup_anggota': '所有组', 'gagal_muat_anggota': '加载成员数据失败',
      'tidak_ada_data_anggota': '没有成员数据。',
      'tidak_ada_data_level': '没有级别的数据',
      'nama': '名称', 'temuan': '发现', 'selesai': '已完成',
      'target_bulanan': '每月目标', 'saya': '我', 'rank': '排名',
      'topik': '话题', 'belum_memiliki_temuan': '还没有\n重复的发现',
      'pilih_bulan': '选择月份', 'pilih_grup': '选择组',
      'pilih_periode': '选择期间', 'pilih_penemu': '选择发现者',
      'cari': '搜索...', 'dari': '从', 'sampai': '到',
      'terapkan': '应用', 'total': '总计',
      'penemu': '发现者', 'periode': '期间',
      'daftar_temuan': '发现列表', 'di_sekitar': '周围',
      'semua_grup': '所有发现者', 'hari_terlewat': '天逾期',
      'jam_terlewat': '小时逾期', 'menit_terlewat': '分钟逾期',
      'deadline_hari_ini': '今天截止', 'hari_tersisa': '天剩余',
    },
  };

  String getTxt(String key) => _texts[widget.lang]?[key] ?? key;

  // ─── State untuk Filter ──────────────────────────────────────────────────
  int _selectedMonthIndex = DateTime.now().month - 1;
  String _filterMode = 'monthly';
  DateTime? _selectedDate;
  String? _selectedUnitId;
  DateTime? _lastUpdated;
  int _chartRefreshKey = 0;
  bool _isChartExpanded = false;

  // Recurring findings filter
  DateTime _recurringFrom = DateTime(DateTime.now().year - 1, DateTime.now().month);
  DateTime _recurringTo = DateTime.now();
  String? _recurringUserId;
  String _recurringUserName = '';

  // ─── State untuk Data ────────────────────────────────────────────────────
  Future<List<KTSMemberData>>? _anggotaFuture;
  Future<List<KTSRecurringTopic>>? _recurringFuture;
  Future<List<_KTSChartBarData>>? _chartFuture;

  List<Map<String, dynamic>> _unitList = [];
  int _targetAnggota = 2;

  late List<String> _translatedMonths;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initLocaleDependentLists();
    _fetchUnits().then((_) {
      _fetchAllData();
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
          _targetAnggota = data['target_anggota'] ?? 2;
        });
      }
    } catch (e) {
      debugPrint('Error fetching target: $e');
    }
  }

  int get _selectedMonth => _selectedMonthIndex + 1;

  void _fetchAllData({bool fromTabFilter = false}) {
    setState(() {
      _lastUpdated = DateTime.now();
      final month = _selectedMonth;
      final year = DateTime.now().year;

      if (_filterMode == 'daily' && _selectedDate != null) {
        _anggotaFuture = _fetchKtsAnggotaDataDaily(_selectedDate!, _selectedUnitId);
      } else {
        _anggotaFuture = _fetchKtsAnggotaData(month, year, _selectedUnitId);
      }
      _chartFuture = _fetchChartData(month, year);
      _chartRefreshKey++;
      _recurringFuture = _fetchRecurringData();
    });
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

  Future<List<KTSMemberData>> _fetchKtsAnggotaData(int month, int year, String? unitId) async {
    try {
      var temuanQuery = _supabase
          .from('temuan')
          .select('id_user, id_penyelesaian, User_Creator:User!temuan_id_user_fkey(nama, gambar_user, id_unit, unit!user_id_unit_fkey(nama_unit))')
          .eq('jenis_temuan', 'KTS Production')
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at', DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String());

      final List<dynamic> temuanRes = await temuanQuery;

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

      final currentUserId = widget.userId;
      return grouped.entries.map((e) {
        final uid = e.key;
        final v = e.value;
        return KTSMemberData(
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

  Future<List<KTSMemberData>> _fetchKtsAnggotaDataDaily(DateTime date, String? unitId) async {
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

      final currentUserId = widget.userId;
      return grouped.entries.map((e) {
        final uid = e.key;
        final v = e.value;
        return KTSMemberData(
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

  Future<List<KTSRecurringTopic>> _fetchRecurringData() async {
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
          .eq('jenis_temuan', 'KTS Production')
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
        isKts: true,
        fromDate: _recurringFrom,
        toDate: _recurringTo,
        filterUserId: _recurringUserId,
      );

      return groups.map((g) => KTSRecurringTopic(
        topic: g.topic,
        locationArea: g.locationArea,
        total: g.total,
        imageUrl: g.imageUrl,
        findings: g.findings,
      )).toList();
    } catch (e) {
      debugPrint('Error fetching KTS Recurring: $e');
      return [];
    }
  }

  Future<List<_KTSChartBarData>> _fetchChartData(int month, int year) async {
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

      var query = _supabase
          .from('temuan')
          .select('created_at, id_penyelesaian, id_user')
          .eq('jenis_temuan', 'KTS Production')
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
            (i) => _KTSChartBarData(date: isDaily ? _selectedDate!.day : i + 1, temuan: 0, penyelesaian: 0));
        }
        query = query.inFilter('id_user', userIds);
      }

      final List<dynamic> res = await query;

      if (isDaily) {
        return [_KTSChartBarData(
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
      return List.generate(daysInMonth, (i) => _KTSChartBarData(
        date: i + 1, temuan: temuanMap[i + 1] ?? 0, penyelesaian: selesaiMap[i + 1] ?? 0));
    } catch (e) {
      debugPrint('Error fetching KTS chart data: $e');
      return [];
    }
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
        separatorBuilder: (_, __) => Divider(height: 1, color: _KTSAppColors.divider, indent: 16),
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

  // ─── Filter Popup Helpers ─────────────────────────────────────────────────

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
                border: Border.all(color: _KTSAppColors.primaryLight, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                    decoration: BoxDecoration(
                      color: _KTSAppColors.primaryLight,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(children: [
                      Icon(Icons.calendar_month_rounded, color: _KTSAppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          getTxt('pilih_bulan'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15, color: _KTSAppColors.textPrimary),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: _KTSAppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                      ),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _KTSAppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _KTSAppColors.primaryLight),
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
                                  color: isSelected ? _KTSAppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Center(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : _KTSAppColors.textSecondary,
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
                                color: isSelected ? _KTSAppColors.primary : _KTSAppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? _KTSAppColors.primary : _KTSAppColors.divider,
                                  width: isSelected ? 1.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(
                                        color: _KTSAppColors.primary.withOpacity(0.3),
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
                                    color: isSelected ? Colors.white : _KTSAppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else ...[
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

  Widget _buildDailyCalendar(
    DateTime selectedDate,
    ValueChanged<DateTime> onDateChanged, {
    required VoidCallback onConfirm,
  }) {
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
      builder: (_, setInner) => Column(
        children: [
          Text(
            monthLabel,
            style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: _KTSAppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            children: dayLabels.map((d) => Expanded(
              child: Center(
                child: Text(d,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _KTSAppColors.textSecondary)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 6),
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
                        ? _KTSAppColors.primary
                        : isToday
                            ? _KTSAppColors.primaryLight
                            : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isToday && !isSelected
                        ? Border.all(color: _KTSAppColors.primary, width: 1.2)
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
                                ? _KTSAppColors.textMuted
                                : _KTSAppColors.textPrimary,
                      ),
                    ),
                  ),
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
                backgroundColor: _KTSAppColors.primary,
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
                border: Border.all(color: _KTSAppColors.primaryLight, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                    decoration: BoxDecoration(
                      color: _KTSAppColors.primaryLight,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(children: [
                      Icon(Icons.group_rounded, color: _KTSAppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(getTxt('pilih_grup'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _KTSAppColors.textPrimary))),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: _KTSAppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                      ),
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
                              (e['nama_unit'] as String).toLowerCase().contains(q.toLowerCase())
                            ).toList();
                          });
                          setSt(() {});
                        },
                        decoration: InputDecoration(
                          hintText: getTxt('cari'),
                          hintStyle: const TextStyle(fontSize: 13, color: _KTSAppColors.textMuted),
                          prefixIcon: const Icon(Icons.search, color: _KTSAppColors.primary, size: 18),
                          filled: true, fillColor: _KTSAppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: _KTSAppColors.divider)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: _KTSAppColors.divider)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: _KTSAppColors.primary, width: 1.5)),
                        ),
                      ),
                    ),
                  ),
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
                              _fetchAllData();
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? _KTSAppColors.primaryLight : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? _KTSAppColors.primary : _KTSAppColors.divider,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: isSelected ? _KTSAppColors.primary : _KTSAppColors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(child: Text(
                                    lbl.isNotEmpty ? lbl[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 15,
                                      color: isSelected ? Colors.white : _KTSAppColors.primary,
                                    ),
                                  )),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(lbl, style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? _KTSAppColors.primary : _KTSAppColors.textPrimary,
                                ))),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded,
                                    color: _KTSAppColors.primary, size: 18),
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
            border: Border.all(color: _KTSAppColors.primaryLight, width: 1.5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.date_range_rounded, color: _KTSAppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(getTxt('pilih_periode'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _KTSAppColors.textPrimary))),
              IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
            ]),
            const SizedBox(height: 16),
            Text(getTxt('dari'), style: const TextStyle(fontSize: 12, color: _KTSAppColors.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _buildYearMonthPicker(tempFrom, locale, (d) => setSt(() => tempFrom = d)),
            const SizedBox(height: 14),
            Text(getTxt('sampai'), style: const TextStyle(fontSize: 12, color: _KTSAppColors.textSecondary, fontWeight: FontWeight.w600)),
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
                  backgroundColor: _KTSAppColors.primary,
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
      Expanded(
        flex: 3,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _KTSAppColors.surface, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _KTSAppColors.primaryLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: current.month - 1,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: _KTSAppColors.primary),
              style: const TextStyle(fontSize: 13, color: _KTSAppColors.textPrimary, fontWeight: FontWeight.w600),
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
            color: _KTSAppColors.surface, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _KTSAppColors.primaryLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: current.year,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: _KTSAppColors.primary),
              style: const TextStyle(fontSize: 13, color: _KTSAppColors.textPrimary, fontWeight: FontWeight.w600),
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
                  border: Border.all(color: _KTSAppColors.primaryLight, width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                      decoration: BoxDecoration(
                        color: _KTSAppColors.primaryLight,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.person_search_rounded, color: _KTSAppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(getTxt('pilih_penemu'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _KTSAppColors.textPrimary))),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: _KTSAppColors.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                          padding: EdgeInsets.zero,
                        ),
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
                                (e['nama'] as String).toLowerCase().contains(q.toLowerCase())
                              ).toList();
                            });
                            setSt(() {});
                          },
                          decoration: InputDecoration(
                            hintText: getTxt('cari'),
                            hintStyle: const TextStyle(fontSize: 13, color: _KTSAppColors.textMuted),
                            prefixIcon: const Icon(Icons.search, color: _KTSAppColors.primary, size: 18),
                            filled: true, fillColor: _KTSAppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: _KTSAppColors.divider)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: _KTSAppColors.divider)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: _KTSAppColors.primary, width: 1.5)),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 14, bottom: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('${filtered.length} ${widget.lang == 'ID' ? 'penemu' : widget.lang == 'ZH' ? '发现者' : 'finders'}',
                          style: const TextStyle(fontSize: 11, color: _KTSAppColors.textSecondary)),
                      ),
                    ),
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
                                  color: isSelected ? _KTSAppColors.primaryLight : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? _KTSAppColors.primary : _KTSAppColors.divider,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(children: [
                                  if (isAll)
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(
                                        color: isSelected ? _KTSAppColors.primary : _KTSAppColors.surface,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: _KTSAppColors.primaryLight)),
                                      child: Icon(Icons.group_rounded,
                                        color: isSelected ? Colors.white : _KTSAppColors.primary, size: 20),
                                    )
                                  else if (avatarUrl != null && avatarUrl.isNotEmpty)
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: NetworkImage(avatarUrl),
                                      onBackgroundImageError: (_, __) {},
                                      backgroundColor: _KTSAppColors.primaryLight,
                                    )
                                  else
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: isSelected ? _KTSAppColors.primary : _KTSAppColors.primaryLight,
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 15,
                                          color: isSelected ? Colors.white : _KTSAppColors.primary,
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
                                          color: isSelected ? _KTSAppColors.primary : _KTSAppColors.textPrimary,
                                        )),
                                      if (role != null && role.isNotEmpty)
                                        Text(role, style: const TextStyle(
                                          fontSize: 11, color: _KTSAppColors.textSecondary)),
                                    ],
                                  )),
                                  if (isSelected)
                                    const Icon(Icons.check_circle_rounded,
                                      color: _KTSAppColors.primary, size: 18),
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
          color: isActive ? _KTSAppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _KTSAppColors.primary : _KTSAppColors.primaryLight,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _KTSAppColors.primary.withOpacity(0.10),
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
                color: isActive ? Colors.white : _KTSAppColors.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Icon(icon, color: isActive ? Colors.white : _KTSAppColors.primary, size: 18),
        ]),
      ),
    );
  }

  // ─── 2 Tab untuk KTS: Members dan Recurring Findings ──────────────────────
  Widget _buildKTSTabBar() {
    final tabLabels = [getTxt('anggota'), getTxt('temuan_berulang')];
    final activeColor = _KTSAppColors.primary;

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
          isScrollable: false,
          tabAlignment: TabAlignment.fill,
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

  Widget _buildAnalyticsPieChart({
    required int totalPrimary,
    required int totalSecondary,
    required Color colorPrimary,
    required Color colorSecondary,
    required String labelPrimary,
    required String labelSecondary,
    required Color activeColor,
  }) {
    final total = totalPrimary + totalSecondary;
    const Color colorEmpty = Color(0xFFE2E8F0);

    final locale = widget.lang == 'ID' ? 'id_ID'
        : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    final monthLabel = _filterMode == 'daily' && _selectedDate != null
        ? DateFormat('d MMM yyyy', locale).format(_selectedDate!)
        : DateFormat('MMMM yyyy', locale)
            .format(DateTime(DateTime.now().year, _selectedMonthIndex + 1));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: activeColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: activeColor.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(Icons.pie_chart_rounded, size: 14, color: activeColor),
                const SizedBox(width: 6),
                Text(
                  widget.lang == 'ID' ? 'Ringkasan $monthLabel'
                      : widget.lang == 'ZH' ? '$monthLabel 摘要'
                      : 'Summary $monthLabel',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: activeColor,
                  ),
                ),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.lang == 'ID' ? 'Total' : widget.lang == 'ZH' ? '总计' : 'Total'}: $total',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: activeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (total == 0) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(children: [
                  Icon(Icons.pie_chart_outline, size: 40,
                      color: Colors.grey.shade300),
                  const SizedBox(height: 6),
                  Text(
                    widget.lang == 'ID' ? 'Tidak ada data'
                        : widget.lang == 'ZH' ? '暂无数据' : 'No data',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ]),
              ),
            ),
          ] else ...[
            Row(
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CustomPaint(
                    painter: _KTSAnalyticsPieChartPainter(
                      primaryValue: totalPrimary.toDouble(),
                      secondaryValue: totalSecondary.toDouble(),
                      colorPrimary: colorPrimary,
                      colorSecondary: colorSecondary,
                      colorEmpty: colorEmpty,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$total',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0C4A6E),
                            ),
                          ),
                          Text(
                            widget.lang == 'ID' ? 'Total'
                                : widget.lang == 'ZH' ? '总计' : 'Total',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPieInfoCardAnalytics(
                        color: colorPrimary,
                        label: labelPrimary,
                        value: totalPrimary,
                        total: total,
                        icon: Icons.search_rounded,
                      ),
                      const SizedBox(height: 8),
                      _buildPieInfoCardAnalytics(
                        color: colorSecondary,
                        label: labelSecondary,
                        value: totalSecondary,
                        total: total,
                        icon: Icons.check_circle_outline_rounded,
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
  }

  Widget _buildPieInfoCardAnalytics({
    required Color color,
    required String label,
    required int value,
    required int total,
    required IconData icon,
  }) {
    final percent =
        total > 0 ? (value / total * 100).toStringAsFixed(1) : '0.0';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? value / total : 0,
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0C4A6E),
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 9,
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

  Widget _buildLastUpdatedTextWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(_lastUpdatedText,
        style: const TextStyle(fontSize: 11, color: _KTSAppColors.textSecondary, height: 1.4)),
    );
  }

  // ─── Table Widgets ────────────────────────────────────────────────────────
  Widget _buildTableHeader(List<String> cols, {required List<int> flex}) {
    return Container(
      color: const Color(0xFFF8FAFF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
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
                  color: _KTSAppColors.textSecondary, letterSpacing: 0.2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMemberRow(KTSMemberData m) {
    final target = _targetAnggota;
    final findingsColor = m.findings >= target ? const Color(0xFF16A34A) : _KTSAppColors.textPrimary;
    final completedColor = m.completed >= target ? const Color(0xFF16A34A) : _KTSAppColors.textPrimary;

    return Container(
      color: m.isSelf ? _KTSAppColors.selfHighlight : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          _KTSAvatar(name: m.name, avatarUrl: m.avatarUrl, color: m.avatarColor, size: 34),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _KTSAppColors.textPrimary),
              overflow: TextOverflow.ellipsis),
            if (m.unitName != null && m.unitName!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(m.unitName!, style: const TextStyle(fontSize: 11, color: _KTSAppColors.textSecondary),
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

  Widget _buildSelfPinnedRow(KTSMemberData self) {
    final target = _targetAnggota;
    final findingsColor = self.findings >= target ? const Color(0xFF16A34A) : _KTSAppColors.textSecondary;
    final completedColor = self.completed >= target ? const Color(0xFF16A34A) : _KTSAppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: _KTSAppColors.selfHighlight,
        border: Border(top: BorderSide(color: _KTSAppColors.selfHighlightBorder, width: 1.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, -2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Row(children: [
            _KTSAvatar(name: self.name, avatarUrl: self.avatarUrl, color: self.avatarColor, size: 34),
            const SizedBox(width: 10),
            Expanded(child: Text(
              self.name,
              style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _KTSAppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            )),
          ]),
        ),
        Expanded(
          flex: 1,
          child: Text(
            '${self.findings}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5, fontWeight: FontWeight.w600, color: findingsColor),
          ),
        ),
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

  Widget _buildRecurringTopicCard(KTSRecurringTopic topic) {
    return GestureDetector(
      onTap: () => _showRecurringDetail(topic),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _KTSAppColors.primaryLight, width: 1.5),
          boxShadow: [BoxShadow(color: _KTSAppColors.primary.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            child: Container(
              width: 80, height: 80,
              color: _KTSAppColors.primaryLight,
              child: topic.imageUrl != null && topic.imageUrl!.isNotEmpty
                  ? Image.network(topic.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: _KTSAppColors.textMuted))
                  : const Icon(Icons.image_outlined, color: _KTSAppColors.textMuted, size: 32),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(topic.topic,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _KTSAppColors.textPrimary),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.tag_rounded, size: 13, color: const Color(0xFFD97706)),
                const SizedBox(width: 3),
                Expanded(child: Text(
                  '${widget.lang == 'ID' ? 'No. Order' : widget.lang == 'ZH' ? '订单号' : 'Order No.'}: ${topic.locationArea}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFD97706),
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                )),
              ]),
            ]),
          )),
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _KTSAppColors.primaryLight, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _KTSAppColors.primary.withOpacity(0.3)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(getTxt('total'), style: const TextStyle(fontSize: 9, color: _KTSAppColors.textSecondary)),
              Text('${topic.total}', style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900, color: _KTSAppColors.primary)),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showRecurringDetail(KTSRecurringTopic topic) {
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
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(topic.topic, style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: _KTSAppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.tag_rounded, size: 13, color: const Color(0xFFD97706)),
                    const SizedBox(width: 3),
                    Flexible(child: Text(
                      '${widget.lang == 'ID' ? 'No. Order' : widget.lang == 'ZH' ? '订单号' : 'Order No.'}: ${topic.locationArea}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFD97706),
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    )),
                  ]),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _KTSAppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                  child: Text('${getTxt('total')}: ${topic.total}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: _KTSAppColors.primary)),
                ),
              ]),
            ),
            const Divider(height: 1, color: _KTSAppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Align(alignment: Alignment.centerLeft,
                child: Text('${getTxt('daftar_temuan')} (${topic.total})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _KTSAppColors.textPrimary))),
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

  // ─── Method untuk build chart toggle header ──────────────────────────────
  Widget _buildChartToggleHeader() {
    final activeColor = _KTSAppColors.primary;
    final locale = widget.lang == 'ID' ? 'id_ID' : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');
    final monthLabel = _filterMode == 'daily' && _selectedDate != null
        ? DateFormat('d MMM yyyy', locale).format(_selectedDate!)
        : DateFormat('MMMM yyyy', locale).format(DateTime(
            DateTime.now().year, _selectedMonthIndex + 1));

    return GestureDetector(
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
    );
  }

  // ─── Pie Chart dengan toggle ──────────────────────────────────────────────
  Widget _buildPieChartWithToggle() {
    return Column(
      children: [
        _buildChartToggleHeader(),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isChartExpanded
              ? FutureBuilder<List<KTSMemberData>>(
                  future: _anggotaFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildChartShimmerSmall();
                    }
                    final data = snapshot.data ?? [];
                    final totalFindings = data.fold<int>(0, (sum, m) => sum + m.findings);
                    final totalCompleted = data.fold<int>(0, (sum, m) => sum + m.completed);
                    return _buildAnalyticsPieChart(
                      totalPrimary: totalFindings,
                      totalSecondary: totalCompleted,
                      colorPrimary: const Color(0xFFF59E0B),
                      colorSecondary: const Color(0xFF10B981),
                      labelPrimary: widget.lang == 'ID' ? 'Temuan'
                          : widget.lang == 'ZH' ? '发现' : 'Findings',
                      labelSecondary: widget.lang == 'ID' ? 'Selesai'
                          : widget.lang == 'ZH' ? '已完成' : 'Completed',
                      activeColor: const Color(0xFFF59E0B),
                    );
                  },
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ─── Chart Shimmer Small ──────────────────────────────────────────────────
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

  // ─── Anggota Tab ────────────────────────────────────────────────────────────
  Widget _buildAnggotaTab() {
    return Column(children: [
      _buildPieChartWithToggle(),
      // Filter row
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
            onTap: () => _showMonthPicker(() => _fetchAllData()),
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
      _buildTableHeader([getTxt('nama'), getTxt('temuan'), getTxt('selesai')], flex: [3, 1, 1]),
      // ─── HAPUS baris ini ──────────────────────────────────────────────────
      // _buildTargetRow([getTxt('target_bulanan'), '$_targetAnggota', '$_targetAnggota']),
      Expanded(child: Builder(builder: (context) {
        if (_anggotaFuture == null) return _buildAnggotaShimmer();
        return FutureBuilder<List<KTSMemberData>>(
          future: _anggotaFuture,
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
              orElse: () => KTSMemberData(name: getTxt('saya'), findings: 0, completed: 0, isSelf: true),
            );
            return Column(children: [
              Expanded(child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: memberList.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: _KTSAppColors.divider, indent: 16),
                itemBuilder: (_, i) => _buildMemberRow(memberList[i]),
              )),
              _buildSelfPinnedRow(self),
            ]);
          },
        );
      })),
    ]);
  }

  // ─── Recurring Tab - TANPA chart ──────────────────────────────────────────
  Widget _buildRecurringTab() {
    final locale = widget.lang == 'ID' ? 'id_ID' : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');
    final fromLabel = DateFormat('MMM yyyy', locale).format(_recurringFrom);
    final toLabel = DateFormat('MMM yyyy', locale).format(_recurringTo);
    final periodLabel = '$fromLabel - $toLabel';

    return Column(children: [
      // Filter row (tanpa chart)
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
            fontSize: 14, fontWeight: FontWeight.w700, color: _KTSAppColors.textPrimary))),
      ),
      const Divider(height: 1, color: _KTSAppColors.divider),
      Expanded(child: FutureBuilder<List<KTSRecurringTopic>>(
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
                  decoration: BoxDecoration(color: _KTSAppColors.primaryLight, shape: BoxShape.circle),
                  child: Icon(Icons.search_off_rounded, size: 36, color: _KTSAppColors.primary.withOpacity(0.5))),
                const SizedBox(height: 16),
                Text(
                  name.isEmpty ? getTxt('tidak_ada_data_anggota')
                      : '$name ${getTxt('belum_memiliki_temuan')}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: _KTSAppColors.textSecondary, height: 1.5)),
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

  // ─── build() method ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildKTSTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAnggotaTab(),
              _buildRecurringTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────
class _KTSAvatar extends StatelessWidget {
  final String name;
  final Color? color;
  final double size;
  final String? avatarUrl;

  const _KTSAvatar({required this.name, this.color, this.size = 36, this.avatarUrl});

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
    final bg = color ?? _KTSAppColors.primary;
    return Text(initials,
      style: TextStyle(fontSize: size * 0.35, fontWeight: FontWeight.w700, color: bg));
  }

  Widget _buildInitialsContainer() {
    final bg = color ?? _KTSAppColors.primary;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: bg.withOpacity(0.15), shape: BoxShape.circle,
        border: Border.all(color: bg.withOpacity(0.3), width: 1)),
      child: Center(child: _buildInitials()),
    );
  }
}

class _KTSAnalyticsPieChartPainter extends CustomPainter {
  final double primaryValue;
  final double secondaryValue;
  final Color colorPrimary;
  final Color colorSecondary;
  final Color colorEmpty;

  _KTSAnalyticsPieChartPainter({
    required this.primaryValue,
    required this.secondaryValue,
    required this.colorPrimary,
    required this.colorSecondary,
    required this.colorEmpty,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = primaryValue + secondaryValue;
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.55;
    final rect = Rect.fromCircle(center: center, radius: outerRadius);

    if (total == 0) {
      final paint = Paint()
        ..color = colorEmpty
        ..style = PaintingStyle.stroke
        ..strokeWidth = outerRadius - innerRadius;
      canvas.drawCircle(center, (outerRadius + innerRadius) / 2, paint);
      return;
    }

    double startAngle = -90 * (3.14159265 / 180);
    const double gapAngle = 0.04;

    final segments = [
      {'value': primaryValue, 'color': colorPrimary},
      {'value': secondaryValue, 'color': colorSecondary},
    ];

    for (final seg in segments) {
      final value = seg['value'] as double;
      final color = seg['color'] as Color;
      if (value <= 0) continue;

      final sweepAngle = (value / total) * 2 * 3.14159265 - gapAngle;

      final shadowPaint = Paint()
        ..color = color.withOpacity(0.2)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(rect, startAngle, sweepAngle, false)
        ..close();
      canvas.drawPath(path, shadowPaint);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = outerRadius - innerRadius
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: (outerRadius + innerRadius) / 2),
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