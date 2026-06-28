import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

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
  String? _selectedUnitId;
  DateTime? _lastUpdated;
  bool _isChartExpanded = false;

  Future<List<KTSMemberData>>? _anggotaFuture;
  List<Map<String, dynamic>> _unitList = [];
  int _targetAnggota = 2;

  late List<String> _translatedMonths;

  @override
  void initState() {
    super.initState();
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
    _translatedMonths = List.generate(
        12, (i) => DateFormat.MMM(locale).format(DateTime(2000, i + 1)));
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
        setState(() => _targetAnggota = data['target_anggota'] ?? 2);
      }
    } catch (e) {
      debugPrint('Error fetching target: $e');
    }
  }

  int get _selectedMonth => _selectedMonthIndex + 1;

  void _fetchAllData() {
    setState(() {
      _lastUpdated = DateTime.now();
      final month = _selectedMonth;
      final year = DateTime.now().year;
      if (_filterMode == 'daily' && _selectedDate != null) {
        _anggotaFuture = _fetchKtsAnggotaDataDaily(_selectedDate!, _selectedUnitId);
      } else {
        _anggotaFuture = _fetchKtsAnggotaData(month, year, _selectedUnitId);
      }
    });
  }

  Future<List<KTSMemberData>> _fetchKtsAnggotaData(
      int month, int year, String? unitId) async {
    try {
      final List<dynamic> temuanRes = await _supabase
          .from('temuan')
          .select(
              'id_user, id_penyelesaian, User_Creator:User!temuan_id_user_fkey(nama, gambar_user, id_unit, unit!user_id_unit_fkey(nama_unit))')
          .eq('jenis_temuan', 'KTS Production')
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at',
              DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String());

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

      return grouped.entries.map((e) {
        final uid = e.key;
        final v = e.value;
        return KTSMemberData(
          name: v['nama'] as String? ?? '-',
          unitName: v['unitName'] as String?,
          findings: v['temuan'] as int,
          completed: v['selesai'] as int,
          isSelf: uid == widget.userId,
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

  Future<List<KTSMemberData>> _fetchKtsAnggotaDataDaily(
      DateTime date, String? unitId) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final List<dynamic> temuanRes = await _supabase
          .from('temuan')
          .select(
              'id_user, id_penyelesaian, User_Creator:User!temuan_id_user_fkey(nama, gambar_user, id_unit, unit!user_id_unit_fkey(nama_unit))')
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

      return grouped.entries.map((e) {
        final uid = e.key;
        final v = e.value;
        return KTSMemberData(
          name: v['nama'] as String? ?? '-',
          unitName: v['unitName'] as String?,
          findings: v['temuan'] as int,
          completed: v['selesai'] as int,
          isSelf: uid == widget.userId,
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

  // FILTER PICKERS
  void _showMonthPicker() async {
    String tempMode = _filterMode;
    DateTime tempDate = _selectedDate ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.65,
                maxWidth: 340),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: KTSAppColors.primaryLight, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                  decoration: const BoxDecoration(
                    color: KTSAppColors.primaryLight,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_month_rounded,
                        color: KTSAppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(getTxt('pilih_bulan'),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: KTSAppColors.textPrimary))),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 18, color: KTSAppColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                    ),
                  ]),
                ),
                // TOGGLE MODE
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: KTSAppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: KTSAppColors.primaryLight),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: ['monthly', 'daily'].map((mode) {
                        final isSelected = tempMode == mode;
                        final label = mode == 'monthly'
                            ? (widget.lang == 'ID'
                                ? 'Bulanan'
                                : widget.lang == 'ZH' ? '按月' : 'Monthly')
                            : (widget.lang == 'ID'
                                ? 'Harian'
                                : widget.lang == 'ZH' ? '按日' : 'Daily');
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setSt(() => tempMode = mode),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? KTSAppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Center(
                                child: Text(label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? Colors.white
                                          : KTSAppColors.textSecondary,
                                    )),
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
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: 12,
                      itemBuilder: (_, i) {
                        final isSelected = i == _selectedMonthIndex;
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
                              color: isSelected
                                  ? KTSAppColors.primary
                                  : KTSAppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? KTSAppColors.primary
                                    : KTSAppColors.divider,
                                width: isSelected ? 1.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: KTSAppColors.primary
                                            .withValues(alpha:0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                _translatedMonths[i],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : KTSAppColors.textPrimary,
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
                        _fetchAllData();
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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
    final locale = widget.lang == 'ID'
        ? 'id_ID'
        : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');
    final monthLabel =
        DateFormat('MMMM yyyy', locale).format(DateTime(year, month));
    final dayLabels = widget.lang == 'ZH'
        ? ['日', '一', '二', '三', '四', '五', '六']
        : widget.lang == 'ID'
            ? ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
            : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return StatefulBuilder(
      builder: (_, setInner) => Column(
        children: [
          Text(monthLabel,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: KTSAppColors.textPrimary)),
          const SizedBox(height: 10),
          Row(
            children: dayLabels
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: KTSAppColors.textSecondary)),
                      ),
                    ))
                .toList(),
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
                onTap: isFuture
                    ? null
                    : () => setInner(() => onDateChanged(date)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? KTSAppColors.primary
                        : isToday
                            ? KTSAppColors.primaryLight
                            : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isToday && !isSelected
                        ? Border.all(
                            color: KTSAppColors.primary, width: 1.2)
                        : null,
                  ),
                  child: Center(
                    child: Text('$day',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : isFuture
                                  ? KTSAppColors.textMuted
                                  : KTSAppColors.textPrimary,
                        )),
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
                backgroundColor: KTSAppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(getTxt('terapkan'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  void _showGroupPicker() async {
    final allItem = {
      'id_unit': null,
      'nama_unit': getTxt('semua_grup_anggota')
    };
    final items = [allItem, ..._unitList];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          final ctrl = TextEditingController();
          List<Map<String, dynamic>> filtered = List.from(items);

          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: KTSAppColors.primaryLight, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                    decoration: const BoxDecoration(
                      color: KTSAppColors.primaryLight,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.group_rounded,
                          color: KTSAppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(getTxt('pilih_grup'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: KTSAppColors.textPrimary))),
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: KTSAppColors.textSecondary),
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
                            filtered = items
                                .where((e) => (e['nama_unit'] as String)
                                    .toLowerCase()
                                    .contains(q.toLowerCase()))
                                .toList();
                          });
                          setSt(() {});
                        },
                        decoration: InputDecoration(
                          hintText: getTxt('cari'),
                          hintStyle: const TextStyle(
                              fontSize: 13, color: KTSAppColors.textMuted),
                          prefixIcon: const Icon(Icons.search,
                              color: KTSAppColors.primary, size: 18),
                          filled: true,
                          fillColor: KTSAppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                  color: KTSAppColors.divider)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                  color: KTSAppColors.divider)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                  color: KTSAppColors.primary, width: 1.5)),
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
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? KTSAppColors.primaryLight
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? KTSAppColors.primary
                                      : KTSAppColors.divider,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? KTSAppColors.primary
                                        : KTSAppColors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                      child: Text(
                                    lbl.isNotEmpty
                                        ? lbl[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isSelected
                                          ? Colors.white
                                          : KTSAppColors.primary,
                                    ),
                                  )),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Text(lbl,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? KTSAppColors.primary
                                              : KTSAppColors.textPrimary,
                                        ))),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded,
                                      color: KTSAppColors.primary, size: 18),
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
          color: isActive ? KTSAppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isActive ? KTSAppColors.primary : KTSAppColors.primaryLight,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: KTSAppColors.primary.withValues(alpha:0.10),
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
                color: isActive ? Colors.white : KTSAppColors.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Icon(icon,
              color: isActive ? Colors.white : KTSAppColors.primary,
              size: 18),
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
          final isFirst = i == 0;
          return Expanded(
            flex: flex[i],
            child: Padding(
              padding: EdgeInsets.only(left: isFirst ? 44 : 0),
              child: Text(
                cols[i],
                textAlign: isFirst ? TextAlign.left : TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: KTSAppColors.textSecondary,
                    letterSpacing: 0.2),
              ),
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
            child: Row(children: [
              _KTSAvatar(
                  name: m.name,
                  avatarUrl: m.avatarUrl,
                  color: m.avatarColor,
                  size: 34),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(m.name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: KTSAppColors.textPrimary),
                        overflow: TextOverflow.ellipsis),
                    if (m.unitName != null && m.unitName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(m.unitName!,
                          style: const TextStyle(
                              fontSize: 11,
                              color: KTSAppColors.textSecondary),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ])),
            ])),
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

  Widget _buildSelfPinnedRow(KTSMemberData self) {
    final target = _targetAnggota;
    final findingsColor = self.findings >= target
        ? const Color(0xFF16A34A)
        : KTSAppColors.textSecondary;
    final completedColor = self.completed >= target
        ? const Color(0xFF16A34A)
        : KTSAppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: KTSAppColors.selfHighlight,
        border: const Border(
            top: BorderSide(
                color: KTSAppColors.selfHighlightBorder, width: 1.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 6,
              offset: const Offset(0, -2))
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Row(children: [
            _KTSAvatar(
                name: self.name,
                avatarUrl: self.avatarUrl,
                color: self.avatarColor,
                size: 34),
            const SizedBox(width: 10),
            Expanded(
                child: Text(self.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: KTSAppColors.textPrimary),
                    overflow: TextOverflow.ellipsis)),
          ]),
        ),
        Expanded(
          flex: 1,
          child: Text('${self.findings}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: findingsColor)),
        ),
        Expanded(
          flex: 1,
          child: Text('${self.completed}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: completedColor)),
        ),
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
          _buildFilterButton(
            label: _filterMode == 'daily' && _selectedDate != null
                ? DateFormat(
                        'd MMM yyyy',
                        widget.lang == 'ID'
                            ? 'id_ID'
                            : widget.lang == 'EN'
                                ? 'en_US'
                                : 'zh_CN')
                    .format(_selectedDate!)
                : _translatedMonths[_selectedMonthIndex],
            isActive: true,
            onTap: _showMonthPicker,
          ),
          const SizedBox(width: 10),
          Expanded(
              child: _buildFilterButton(
            label: _selectedUnitId == null
                ? getTxt('semua_grup_anggota')
                : (_unitList.firstWhere(
                        (u) =>
                            u['id_unit'].toString() == _selectedUnitId,
                        orElse: () =>
                            {'nama_unit': getTxt('semua_grup')})['nama_unit']
                    as String),
            onTap: _showGroupPicker,
          )),
        ]),
      ),
      // LAST UPDATED
      Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Text(_lastUpdatedText,
            style: const TextStyle(
                fontSize: 11,
                color: KTSAppColors.textSecondary,
                height: 1.4)),
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
            final self = memberList.firstWhere(
              (m) => m.isSelf,
              orElse: () => KTSMemberData(
                  name: getTxt('saya'),
                  findings: 0,
                  completed: 0,
                  isSelf: true),
            );
            return Column(children: [
              Expanded(
                  child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: memberList.length,
                separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: KTSAppColors.divider,
                    indent: 16),
                itemBuilder: (_, i) =>
                    _buildMemberRow(memberList[i]),
              )),
              _buildSelfPinnedRow(self),
            ]);
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