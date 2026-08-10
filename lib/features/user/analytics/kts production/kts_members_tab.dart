import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/utils/jabatan_helper.dart';
import '../5r findings/picker/5r_members_location_picker.dart';

class KTSAppColors {
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

class KTSMemberData {
  final String name;
  final String? unitName;
  final int findings;
  final int completed;
  final bool isSelf;
  final String? avatarUrl;
  final Color? avatarColor;
  final int? idJabatan;
  final String? jabatanNama;
  final bool? isVerificator;

  const KTSMemberData({
    required this.name,
    this.unitName,
    required this.findings,
    required this.completed,
    this.isSelf = false,
    this.avatarUrl,
    this.avatarColor,
    this.idJabatan,
    this.jabatanNama,
    this.isVerificator,
  });
}

class KtsMembersTab extends StatefulWidget {
  final String lang;
  final String userId;

  const KtsMembersTab({
    super.key,
    required this.lang,
    required this.userId,
  });

  @override
  State<KtsMembersTab> createState() => _KtsMembersTabState();
}

class _KtsMembersTabState extends State<KtsMembersTab> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final Map<String, Map<String, String>> _texts = {
    'ID': {
      'anggota': 'Anggota', 'memuat_data': 'Memuat data...',
      'diperbarui_pada': 'Terakhir diperbarui pada',
      'semua_grup_anggota': 'Semua Grup', 'gagal_muat_anggota': 'Gagal memuat data Anggota',
      'tidak_ada_data_anggota': 'Tidak ada data anggota.',
      'nama': 'Nama', 'temuan': 'Temuan', 'selesai': 'Selesai',
      'target_bulanan': 'Target Bulanan', 'saya': 'Saya',
      'pilih_bulan': 'Pilih Bulan', 'pilih_grup': 'Pilih Grup',
      'cari': 'Cari...', 'terapkan': 'Terapkan',
      'semua_grup': 'Semua Penemu',
    },
    'EN': {
      'anggota': 'Members', 'memuat_data': 'Loading data...',
      'diperbarui_pada': 'Last updated at',
      'semua_grup_anggota': 'All Groups', 'gagal_muat_anggota': 'Failed to load Member data',
      'tidak_ada_data_anggota': 'No member data available.',
      'nama': 'Name', 'temuan': 'Findings', 'selesai': 'Completed',
      'target_bulanan': 'Monthly Target', 'saya': 'Me',
      'pilih_bulan': 'Select Month', 'pilih_grup': 'Select Group',
      'cari': 'Search...', 'terapkan': 'Apply',
      'semua_grup': 'All Finders',
    },
    'ZH': {
      'anggota': '成员', 'memuat_data': '加载数据...',
      'diperbarui_pada': '最后更新于',
      'semua_grup_anggota': '所有组', 'gagal_muat_anggota': '加载成员数据失败',
      'tidak_ada_data_anggota': '没有成员数据。',
      'nama': '名称', 'temuan': '发现', 'selesai': '已完成',
      'target_bulanan': '每月目标', 'saya': '我',
      'pilih_bulan': '选择月份', 'pilih_grup': '选择组',
      'cari': '搜索...', 'terapkan': '应用',
      'semua_grup': '所有发现者',
    },
  };

  String getTxt(String key) => _texts[widget.lang]?[key] ?? key;

  // STATE
  int _selectedMonthIndex = DateTime.now().month - 1;
  String _filterMode = 'monthly';
  DateTime? _selectedDate;
  String  _selectedMemberLocationLevel = 'Lokasi';
  String? _selectedMemberLocationId;
  String? _selectedMemberLocationName;
  DateTime? _lastUpdated;
  bool _isChartExpanded = false;

  Future<List<KTSMemberData>>? _anggotaFuture;
  int _targetAnggota = 2;

  late List<String> _translatedMonths;

  @override
  void initState() {
    super.initState();
    _initLocaleDependentLists();
    _fetchAllData();
    _fetchTarget();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initLocaleDependentLists();
  }

  void _initLocaleDependentLists() {
    final locale = widget.lang == 'ID' ? 'id_ID' : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');
    _translatedMonths = List.generate(
        12, (i) => DateFormat.MMM(locale).format(DateTime(2000, i + 1)));
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
        setState(() => _targetAnggota = data['target_anggota'] ?? 2);
      }
    } catch (e) {
      debugPrint('Error fetching target: $e');
    }
  }

  int get _selectedMonth => _selectedMonthIndex + 1;

  static const Map<String, String> _locationIdColumnMap = {
    'Lokasi': 'id_lokasi',
    'Unit': 'id_unit',
    'Subunit': 'id_subunit',
    'Area': 'id_area',
  };

  void _fetchAllData() {
    setState(() {
      _lastUpdated = DateTime.now();
      final month = _selectedMonth;
      final year = DateTime.now().year;
      if (_filterMode == 'daily' && _selectedDate != null) {
        _anggotaFuture = _fetchKtsAnggotaDataDaily(
            _selectedDate!, _selectedMemberLocationLevel, _selectedMemberLocationId);
      } else {
        _anggotaFuture = _fetchKtsAnggotaData(
            month, year, _selectedMemberLocationLevel, _selectedMemberLocationId);
      }
    });
  }

  Future<List<KTSMemberData>> _fetchKtsAnggotaData(
      int month, int year, String level, String? locationId) async {
    try {
      var userQuery = _supabase
          .from('User')
          .select(
              'id_user, nama, gambar_user, id_unit, id_jabatan, is_verificator, unit!user_id_unit_fkey(nama_unit), jabatan!User_id_jabatan_fkey(nama_jabatan)')
          .or('id_jabatan.is.null,id_jabatan.neq.6');
      if (locationId != null) {
        final idCol = _locationIdColumnMap[level] ?? 'id_lokasi';
        userQuery = userQuery.eq(idCol, locationId);
      }
      final List<dynamic> users = await userQuery;
      if (users.isEmpty) return [];

      final userIds = users.map((u) => u['id_user'].toString()).toList();

      final List<dynamic> temuanRes = await _supabase
          .from('temuan')
          .select('id_user, id_penyelesaian')
          .eq('jenis_temuan', 'KTS Production')
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at',
              DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String())
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

      return users.map((u) {
        final uid = u['id_user']?.toString() ?? '';
        final s = stats[uid] ?? {'temuan': 0, 'selesai': 0};
        return KTSMemberData(
          name: u['nama'] as String? ?? '-',
          unitName: (u['unit'] as Map<String, dynamic>?)?['nama_unit'] as String?,
          findings: s['temuan']!,
          completed: s['selesai']!,
          isSelf: uid == widget.userId,
          avatarUrl: u['gambar_user'] as String?,
          avatarColor: const Color(0xFFFBBF24),
          idJabatan: u['id_jabatan'] as int?,
          jabatanNama: (u['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'] as String?,
          isVerificator: u['is_verificator'] as bool?,
        );
      }).toList()
        ..sort((a, b) {
          final c = b.findings.compareTo(a.findings);
          return c != 0 ? c : a.name.compareTo(b.name);
        });
    } catch (e) {
      debugPrint('Error fetching KTS Anggota: $e');
      return [];
    }
  }

  Future<List<KTSMemberData>> _fetchKtsAnggotaDataDaily(
      DateTime date, String level, String? locationId) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

      var userQuery = _supabase
          .from('User')
          .select(
              'id_user, nama, gambar_user, id_unit, id_jabatan, is_verificator, unit!user_id_unit_fkey(nama_unit), jabatan!User_id_jabatan_fkey(nama_jabatan)')
          .or('id_jabatan.is.null,id_jabatan.neq.6');
      if (locationId != null) {
        final idCol = _locationIdColumnMap[level] ?? 'id_lokasi';
        userQuery = userQuery.eq(idCol, locationId);
      }
      final List<dynamic> users = await userQuery;
      if (users.isEmpty) return [];

      final userIds = users.map((u) => u['id_user'].toString()).toList();

      final List<dynamic> temuanRes = await _supabase
          .from('temuan')
          .select('id_user, id_penyelesaian')
          .eq('jenis_temuan', 'KTS Production')
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

      return users.map((u) {
        final uid = u['id_user']?.toString() ?? '';
        final s = stats[uid] ?? {'temuan': 0, 'selesai': 0};
        return KTSMemberData(
          name: u['nama'] as String? ?? '-',
          unitName: (u['unit'] as Map<String, dynamic>?)?['nama_unit'] as String?,
          findings: s['temuan']!,
          completed: s['selesai']!,
          isSelf: uid == widget.userId,
          avatarUrl: u['gambar_user'] as String?,
          avatarColor: const Color(0xFFFBBF24),
          idJabatan: u['id_jabatan'] as int?,
          jabatanNama: (u['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'] as String?,
          isVerificator: u['is_verificator'] as bool?,
        );
      }).toList()
        ..sort((a, b) {
          final c = b.findings.compareTo(a.findings);
          return c != 0 ? c : a.name.compareTo(b.name);
        });
    } catch (e) {
      debugPrint('Error fetching KTS Anggota daily: $e');
      return [];
    }
  }

  // FILTER PICKERS
  void _showMonthPicker() async {
    String tempMode = _filterMode;
    int tempMonthIndex = _selectedMonthIndex;
    DateTime tempDate = _selectedDate ?? DateTime.now();
    DateTime tempDisplayMonth = DateTime(tempDate.year, tempDate.month, 1);

    const accent = Color(0xFF1D72F3); // BIRU - FILTER WAKTU (samain dgn 5R)

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.68, maxWidth: 340),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.25), width: 1.5)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(getTxt('pilih_bulan'),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700, fontSize: 15, color: accent)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 18),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: const Color(0xFFF1F5F9)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Container(
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withValues(alpha: 0.2))),
                  padding: const EdgeInsets.all(4),
                  child: Row(children: ['monthly', 'daily'].map((mode) {
                    final isSel = tempMode == mode;
                    final label = mode == 'monthly'
                        ? (widget.lang == 'ID' ? 'Bulanan' : widget.lang == 'ZH' ? '按月' : 'Monthly')
                        : (widget.lang == 'ID' ? 'Harian' : widget.lang == 'ZH' ? '按日' : 'Daily');
                    final icon = mode == 'monthly'
                        ? Icons.calendar_view_month_rounded
                        : Icons.event_rounded;
                    return Expanded(child: GestureDetector(
                      onTap: () => setSt(() => tempMode = mode),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 38,
                        decoration: BoxDecoration(
                          color: isSel ? accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(9)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, size: 15,
                                color: isSel ? Colors.white : const Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(label, style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: isSel ? Colors.white : const Color(0xFF64748B))),
                          ],
                        ),
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
                          _fetchTarget().then((_) => _fetchAllData());
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: isSel ? accent : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel ? accent : const Color(0xFFDBEAFE),
                              width: isSel ? 1.5 : 1),
                            boxShadow: isSel ? [BoxShadow(
                              color: accent.withValues(alpha:0.3),
                              blurRadius: 6, offset: const Offset(0, 2))] : []),
                          child: Center(child: Text(_translatedMonths[i], style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
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
                    accent: accent,
                    onConfirm: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _filterMode = 'daily';
                        _selectedDate = tempDate;
                        _selectedMonthIndex = tempDate.month - 1;
                      });
                      _fetchAllData();
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
      ValueChanged<DateTime> onMonthChanged,
      {required Color accent, required VoidCallback onConfirm}) {
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
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.chevron_left_rounded, size: 18, color: accent),
              ),
            ),
            Text(monthLabel, style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0C4A6E))),
            GestureDetector(
              onTap: isCurrentMonth
                  ? null
                  : () => onMonthChanged(DateTime(year, month + 1, 1)),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isCurrentMonth
                      ? Colors.grey.shade100
                      : accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.chevron_right_rounded,
                    size: 18,
                    color: isCurrentMonth ? Colors.grey.shade400 : accent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(children: dayLabels.map((d) => Expanded(child: Center(
          child: Text(d, style: GoogleFonts.poppins(
              fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)))))).toList()),
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
                  color: isSelected ? accent
                      : isToday ? accent.withValues(alpha: 0.12) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday && !isSelected
                      ? Border.all(color: accent, width: 1.2) : null),
                child: Center(child: Text('$day', style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w600,
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
              backgroundColor: accent, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10)),
            child: Text(getTxt('terapkan'),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ),
      ]),
    );
  }

  void _showMemberLocationPicker() async {
    final result = await showMemberLocationFilterDialog(
      context,
      lang: widget.lang,
      initialLevel: _selectedMemberLocationLevel,
      initialId: _selectedMemberLocationId,
    );
    if (result == null || !mounted) return;
    setState(() {
      _selectedMemberLocationLevel = result['level'] ?? _selectedMemberLocationLevel;
      _selectedMemberLocationId    = result['id'];
      _selectedMemberLocationName  = result['name'];
    });
    _fetchAllData();
  }

  // UI HELPERS
  String get _lastUpdatedText {
    if (_lastUpdated == null) return getTxt('memuat_data');
    final formattedDate = DateFormat('d MMM yyyy HH:mm',
            widget.lang == 'ID' ? 'id_ID' : 'en_US')
        .format(_lastUpdated!);
    return '${getTxt('diperbarui_pada')} $formattedDate (GMT+7)';
  }

  Widget _buildShimmerBox(
      {double? width,
      required double height,
      bool isCircle = false,
      double borderRadius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(isCircle ? height / 2 : borderRadius),
      ),
    );
  }

  Widget _buildAnggotaShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: 10,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: KTSAppColors.divider, indent: 16),
        itemBuilder: (_, __) => Container(
          color: Colors.white,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(children: [
            Expanded(
                flex: 3,
                child: Row(children: [
                  _buildShimmerBox(height: 34, width: 34, isCircle: true),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        _buildShimmerBox(height: 14, width: 120),
                        const SizedBox(height: 4),
                        _buildShimmerBox(height: 12, width: 80),
                      ])),
                ])),
            Expanded(
                flex: 1,
                child: Center(
                    child: _buildShimmerBox(height: 14, width: 20))),
            Expanded(
                flex: 1,
                child: Center(
                    child: _buildShimmerBox(height: 14, width: 20))),
          ]),
        ),
      ),
    );
  }

  static const Color _timeAccent = Color(0xFF1D72F3); // BIRU - FILTER WAKTU

  Widget _buildMemberTimeFilterButton() {
    final isActive = _filterMode == 'daily';
    final modeLabel = _filterMode == 'daily'
        ? (widget.lang == 'ID' ? 'Harian' : widget.lang == 'ZH' ? '按日' : 'Daily')
        : (widget.lang == 'ID' ? 'Bulanan' : widget.lang == 'ZH' ? '按月' : 'Monthly');
    final valueLabel = _filterMode == 'daily' && _selectedDate != null
        ? DateFormat('d MMM yyyy',
                widget.lang == 'ID' ? 'id_ID' : widget.lang == 'EN' ? 'en_US' : 'zh_CN')
            .format(_selectedDate!)
        : _translatedMonths[_selectedMonthIndex];

    return GestureDetector(
      onTap: _showMonthPicker,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? _timeAccent : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _timeAccent : const Color(0xFF93C5FD),
            width: 1.5,
          ),
          boxShadow: [BoxShadow(
              color: _timeAccent.withValues(alpha: 0.10), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month_rounded, size: 15,
                    color: isActive ? Colors.white : _timeAccent),
                const SizedBox(width: 5),
                Flexible(
                  child: Text('$modeLabel · $valueLabel',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : _timeAccent)),
                ),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded,
              color: isActive ? Colors.white : _timeAccent, size: 18),
        ]),
      ),
    );
  }

  static const List<Color> _locationLevelColors = [
    Color(0xFF10B981), // Lokasi
    Color(0xFF6366F1), // Unit
    Color(0xFFFBBF24), // Subunit
    Color(0xFFF472B6), // Area
  ];
  static const List<IconData> _locationLevelIcons = [
    Icons.location_city_rounded,
    Icons.business_rounded,
    Icons.layers_rounded,
    Icons.place_rounded,
  ];
  static const List<String> _locationLevelOrder = ['Lokasi', 'Unit', 'Subunit', 'Area'];

  String get _allLocationLabel {
    switch (widget.lang) {
      case 'EN': return 'All Location';
      case 'ZH': return '所有位置';
      default: return 'Semua Lokasi';
    }
  }

  Widget _buildMemberLocationFilterButton() {
    final hasSelection = _selectedMemberLocationId != null;
    final levelIdx = _locationLevelOrder.indexOf(_selectedMemberLocationLevel).clamp(0, 3);
    final color = _locationLevelColors[levelIdx];
    final icon  = hasSelection ? _locationLevelIcons[levelIdx] : Icons.map;
    final label = hasSelection
        ? (_selectedMemberLocationName ?? _selectedMemberLocationLevel)
        : _allLocationLabel;

    return GestureDetector(
      onTap: _showMemberLocationPicker,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [BoxShadow(
              color: color.withValues(alpha: 0.10), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Expanded(
            child: Text(label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ),
          if (hasSelection)
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMemberLocationLevel = 'Lokasi';
                  _selectedMemberLocationId = null;
                  _selectedMemberLocationName = null;
                });
                _fetchAllData();
              },
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.45)),
                ),
                child: const Icon(Icons.close_rounded, size: 12, color: Color(0xFFEF4444)),
              ),
            )
          else
            Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 18),
        ]),
      ),
    );
  }

  Widget _buildTableHeader(List<String> cols, {required List<int> flex}) {
    return Container(
      color: const Color(0xFFF8FAFF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: List.generate(cols.length, (i) {
          return Expanded(
            flex: flex[i],
            child: Text(
              cols[i],
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: 0.2),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMemberRow(KTSMemberData m) {
    final target = _targetAnggota;
    final findingsColor = m.findings >= target
        ? const Color(0xFF16A34A)
        : KTSAppColors.textPrimary;
    final completedColor = m.completed >= target
        ? const Color(0xFF16A34A)
        : KTSAppColors.textPrimary;

    return Container(
      color: m.isSelf ? KTSAppColors.selfHighlight : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(children: [
        Expanded(
            flex: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _KTSAvatar(
                    name: m.name,
                    avatarUrl: m.avatarUrl,
                    color: m.avatarColor,
                    size: 36),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(m.name,
                          maxLines: 1,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: KTSAppColors.textPrimary),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildJabatanBadge(
                              idJabatan: m.idJabatan,
                              jabatanNama: m.jabatanNama,
                              isVerificator: m.isVerificator),
                          _buildUnitBadge(m.unitName),
                        ],
                      ),
                    ])),
              ],
            )),
        Expanded(
            flex: 1,
            child: Text('${m.findings}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: findingsColor))),
        Expanded(
            flex: 1,
            child: Text('${m.completed}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: completedColor))),
      ]),
    );
  }

  Widget _buildJabatanBadge({
    required int? idJabatan,
    required String? jabatanNama,
    required bool? isVerificator,
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

  Widget _buildUnitBadge(String? unitName) {
    if (unitName == null || unitName.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final color = _UnitBadgeHelper.getColor(unitName);
    final icon = _UnitBadgeHelper.getIcon(unitName);
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
        Text(unitName,
            style: TextStyle(
                fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  // PIE CHART
  Widget _buildChartToggleHeader() {
    const activeColor = KTSAppColors.primary;
    final locale = widget.lang == 'ID'
        ? 'id_ID'
        : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');
    final monthLabel = _filterMode == 'daily' && _selectedDate != null
        ? DateFormat('d MMM yyyy', locale).format(_selectedDate!)
        : DateFormat('MMMM yyyy', locale)
            .format(DateTime(DateTime.now().year, _selectedMonthIndex + 1));

    return GestureDetector(
      onTap: () => setState(() => _isChartExpanded = !_isChartExpanded),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: activeColor.withValues(alpha:0.4), width: 1.2),
          boxShadow: [
            BoxShadow(
                color: activeColor.withValues(alpha:0.08),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          const Icon(Icons.bar_chart_rounded,
              size: 16, color: activeColor),
          const SizedBox(width: 8),
          Expanded(
              child: Text(
            widget.lang == 'ID'
                ? 'Grafik $monthLabel'
                : widget.lang == 'ZH'
                    ? '$monthLabel 图表'
                    : 'Chart $monthLabel',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: activeColor),
          )),
          AnimatedRotation(
            turns: _isChartExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 250),
            child: const Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: activeColor),
          ),
        ]),
      ),
    );
  }

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
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return _buildChartShimmerSmall();
                    }
                    final data = snapshot.data ?? [];
                    final totalFindings =
                        data.fold<int>(0, (sum, m) => sum + m.findings);
                    final totalCompleted =
                        data.fold<int>(0, (sum, m) => sum + m.completed);
                    return _buildAnalyticsPieChart(
                      totalPrimary: totalFindings,
                      totalSecondary: totalCompleted,
                      colorPrimary: const Color(0xFFF59E0B),
                      colorSecondary: const Color(0xFF10B981),
                      labelPrimary: widget.lang == 'ID'
                          ? 'Temuan'
                          : widget.lang == 'ZH'
                              ? '发现'
                              : 'Findings',
                      labelSecondary: widget.lang == 'ID'
                          ? 'Selesai'
                          : widget.lang == 'ZH'
                              ? '已完成'
                              : 'Completed',
                      activeColor: const Color(0xFFF59E0B),
                    );
                  },
                )
              : const SizedBox.shrink(),
        ),
      ],
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
    final locale = widget.lang == 'ID'
        ? 'id_ID'
        : widget.lang == 'EN'
            ? 'en_US'
            : 'zh_CN';
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
        border: Border.all(color: activeColor.withValues(alpha:0.25)),
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha:0.07),
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
                Icon(Icons.pie_chart_rounded,
                    size: 14, color: activeColor),
                const SizedBox(width: 6),
                Text(
                  widget.lang == 'ID'
                      ? 'Ringkasan $monthLabel'
                      : widget.lang == 'ZH'
                          ? '$monthLabel 摘要'
                          : 'Summary $monthLabel',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: activeColor,
                  ),
                ),
              ]),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha:0.1),
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
                  Icon(Icons.pie_chart_outline,
                      size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 6),
                  Text(
                    widget.lang == 'ID'
                        ? 'Tidak ada data'
                        : widget.lang == 'ZH'
                            ? '暂无数据'
                            : 'No data',
                    style: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 12),
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
                    painter: KTSAnalyticsPieChartPainter(
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
                          Text('$total',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0C4A6E),
                              )),
                          Text(
                            widget.lang == 'ID'
                                ? 'Total'
                                : widget.lang == 'ZH'
                                    ? '总计'
                                    : 'Total',
                            style: const TextStyle(
                                fontSize: 9, color: Color(0xFF64748B)),
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
                      _buildPieInfoCard(
                        color: colorPrimary,
                        label: labelPrimary,
                        value: totalPrimary,
                        total: total,
                        icon: Icons.search_rounded,
                      ),
                      const SizedBox(height: 8),
                      _buildPieInfoCard(
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

  Widget _buildPieInfoCard({
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
        color: color.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color)),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? value / total : 0,
                    backgroundColor: color.withValues(alpha:0.15),
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
              Text('$value',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0C4A6E))),
              Text('$percent%',
                  style: TextStyle(
                      fontSize: 9,
                      color: color,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildPieChartWithToggle(),
      // FILTER ROW
      Container(
        color: Colors.transparent,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Expanded(child: _buildMemberTimeFilterButton()),
          const SizedBox(width: 10),
          Expanded(child: _buildMemberLocationFilterButton()),
        ]),
      ),
      // LAST UPDATED
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: KTSAppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.access_time_filled_rounded,
                  size: 13, color: KTSAppColors.primary),
              const SizedBox(width: 6),
              Text(_lastUpdatedText,
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: KTSAppColors.textPrimary)),
            ]),
          ),
        ),
      ),
      _buildTableHeader(
          [getTxt('nama'), getTxt('temuan'), getTxt('selesai')],
          flex: [3, 1, 1]),
      Expanded(child: Builder(builder: (context) {
        if (_anggotaFuture == null) return _buildAnggotaShimmer();
        return FutureBuilder<List<KTSMemberData>>(
          future: _anggotaFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildAnggotaShimmer();
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return Center(
                  child: Text(getTxt('tidak_ada_data_anggota')));
            }
            final memberList = snapshot.data!;
            return ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: memberList.length,
              separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  color: KTSAppColors.divider,
                  indent: 16),
              itemBuilder: (_, i) => _buildMemberRow(memberList[i]),
            );
          },
        );
      })),
    ]);
  }
}

// AVATAR WIDGET
class _KTSAvatar extends StatelessWidget {
  final String name;
  final Color? color;
  final double size;
  final String? avatarUrl;

  const _KTSAvatar(
      {required this.name, this.color, this.size = 36, this.avatarUrl});

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
    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    final bg = color ?? KTSAppColors.primary;
    return Text(initials,
        style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
            color: bg));
  }

  Widget _buildInitialsContainer() {
    final bg = color ?? KTSAppColors.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: bg.withValues(alpha:0.15),
          shape: BoxShape.circle,
          border: Border.all(color: bg.withValues(alpha:0.3), width: 1)),
      child: Center(child: _buildInitials()),
    );
  }
}

// PIE CHART PAINTER
class KTSAnalyticsPieChartPainter extends CustomPainter {
  final double primaryValue;
  final double secondaryValue;
  final Color colorPrimary;
  final Color colorSecondary;
  final Color colorEmpty;

  KTSAnalyticsPieChartPainter({
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
      canvas.drawCircle(
          center, (outerRadius + innerRadius) / 2, paint);
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

      final sweepAngle =
          (value / total) * 2 * 3.14159265 - gapAngle;

      final shadowPaint = Paint()
        ..color = color.withValues(alpha:0.2)
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

class _UnitBadgeHelper {
  static const List<Color> _palette = [
    Color(0xFF0D9488), // teal
    Color(0xFF6366F1), // indigo
    Color(0xFF8B5CF6), // purple
    Color(0xFFEC4899), // pink
    Color(0xFF06B6D4), // cyan
    Color(0xFFF97316), // orange
    Color(0xFF84CC16), // lime
    Color(0xFFEF4444), // red
  ];

  static Color getColor(String unitName) {
    final name = unitName.toLowerCase();
    if (name.contains('finance')) return const Color(0xFF0D9488);
    if (name.contains('fabrication')) return const Color(0xFF6366F1);
    if (name.contains('machine') || name.contains('mdc')) {
      return const Color(0xFF8B5CF6);
    }
    if (name.contains('marketing')) return const Color(0xFFEC4899);
    if (name.contains('support')) return const Color(0xFF06B6D4);
    // Fallback: konsisten per nama unit lain via hash
    final idx = unitName.hashCode.abs() % _palette.length;
    return _palette[idx];
  }

  static IconData getIcon(String unitName) {
    final name = unitName.toLowerCase();
    if (name.contains('finance')) return Icons.account_balance_wallet_rounded;
    if (name.contains('fabrication')) return Icons.precision_manufacturing_rounded;
    if (name.contains('machine') || name.contains('mdc')) {
      return Icons.engineering_rounded;
    }
    if (name.contains('marketing')) return Icons.campaign_rounded;
    if (name.contains('support')) return Icons.support_agent_rounded;
    return Icons.apartment_rounded;
  }
}