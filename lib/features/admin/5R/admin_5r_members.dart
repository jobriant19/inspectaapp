import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:shimmer/shimmer.dart';

// SESUAIKAN PATH INI dengan lokasi folder admin_5r_members.dart kamu
import '../../../core/utils/jabatan_helper.dart';

class _AppColors {
  static const primary             = Color(0xFF0EA5E9);
  static const primaryLight        = Color(0xFFE0F2FE);
  static const surface             = Color(0xFFF0F9FF);
  static const textPrimary         = Color(0xFF0C4A6E);
  static const textSecondary       = Color(0xFF64748B);
  static const textMuted           = Color(0xFFBDBDBD);
  static const divider             = Color(0xFFE0F2FE);
  static const selfHighlight       = Color(0xFFFFF7ED);
  static const selfHighlightBorder = Color(0xFFFED7AA);
}

class _ChartBarData {
  final int date;
  final int temuan;
  final int penyelesaian;
  _ChartBarData({required this.date, required this.temuan, required this.penyelesaian});
}

// ─── Model ───────────────────────────────────────────────────────────────────
class MemberData5R {
  final String  name;
  final String? unitName;
  final int     findings;
  final int     completed;
  final bool    isSelf;
  final String? avatarUrl;
  final Color?  avatarColor;
  final int?    idJabatan;
  final String? jabatanNama;
  final bool?   isVerificator;

  const MemberData5R({
    required this.name,
    this.unitName,
    required this.findings,
    required this.completed,
    this.isSelf      = false,
    this.avatarUrl,
    this.avatarColor,
    this.idJabatan,
    this.jabatanNama,
    this.isVerificator,
  });
}

class Admin5RMembersTab extends StatefulWidget {
  final String lang;

  const Admin5RMembersTab({
    super.key,
    required this.lang,
  });

  @override
  State<Admin5RMembersTab> createState() => _Admin5RMembersTabState();
}

class _Admin5RMembersTabState extends State<Admin5RMembersTab> {
  final _supabase = Supabase.instance.client;

  // TEKS MULTIBAHASA
  final Map<String, Map<String, String>> _texts = {
    'ID': {
      'memuat_data': 'Memuat data...',
      'diperbarui_pada': 'Terakhir diperbarui pada',
      'semua_grup': 'Semua Penemu',
      'semua_grup_anggota': 'Semua Grup',
      'tidak_ada_data_anggota': 'Tidak ada data anggota.',
      'nama': 'Nama', 'temuan': 'Temuan', 'selesai': 'Selesai',
      'target_bulanan': 'Target Bulanan', 'saya': 'Saya',
      'pilih_bulan': 'Pilih Bulan', 'pilih_grup': 'Pilih Grup',
      'cari': 'Cari...', 'terapkan': 'Terapkan',
    },
    'EN': {
      'memuat_data': 'Loading data...',
      'diperbarui_pada': 'Last updated at',
      'semua_grup': 'All Finders',
      'semua_grup_anggota': 'All Groups',
      'tidak_ada_data_anggota': 'No member data available.',
      'nama': 'Name', 'temuan': 'Findings', 'selesai': 'Completed',
      'target_bulanan': 'Monthly Target', 'saya': 'Me',
      'pilih_bulan': 'Select Month', 'pilih_grup': 'Select Group',
      'cari': 'Search...', 'terapkan': 'Apply',
    },
    'ZH': {
      'memuat_data': '加载数据...',
      'diperbarui_pada': '最后更新于',
      'semua_grup': '所有发现者',
      'semua_grup_anggota': '所有组',
      'tidak_ada_data_anggota': '没有成员数据。',
      'nama': '名称', 'temuan': '发现', 'selesai': '已完成',
      'target_bulanan': '每月目标', 'saya': '我',
      'pilih_bulan': '选择月份', 'pilih_grup': '选择组',
      'cari': '搜索...', 'terapkan': '应用',
    },
  };

  String getTxt(String key) => _texts[widget.lang]?[key] ?? key;

  // FILTER STATE
  int _selectedMonthIndex = DateTime.now().month - 1;
  String _filterMode = 'monthly';
  DateTime? _selectedDate;
  String? _selectedUnitId;
  DateTime? _lastUpdated;

  // TARGET
  int _targetAnggota = 2;
  int _targetAnggotaSelesai = 2;

  // UNIT LIST (untuk filter grup)
  List<Map<String, dynamic>> _unitList = [];

  late List<String> _translatedMonths;

  Future<List<MemberData5R>>? membersFuture;

  // CHART STATE
  bool _isChartExpanded = false;
  Future<List<_ChartBarData>>? _chartFuture;
  int _chartRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _initLocaleDependentLists();
    _fetchUnits().then((_) {
      _fetchMembers();
      _fetchChart();
    });
    _fetchTarget();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initLocaleDependentLists();
  }

  void _initLocaleDependentLists() {
    final locale = widget.lang == 'ID'
        ? 'id_ID'
        : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');
    _translatedMonths = List.generate(
        12, (i) => DateFormat.MMM(locale).format(DateTime(2000, i + 1)));
  }

  // ─── FETCH UNIT LIST ─────────────────────────────────────────────────────
  Future<void> _fetchUnits() async {
    try {
      final response =
          await _supabase.from('unit').select('id_unit, nama_unit');
      if (mounted) {
        setState(() => _unitList = List<Map<String, dynamic>>.from(response));
      }
    } catch (e) {
      debugPrint('Error fetching units: $e');
    }
  }

  // ─── FETCH TARGET ────────────────────────────────────────────────────────
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
      final referenceDate =
          DateTime(year, month, 1).toIso8601String().split('T').first;

      final rows = await _supabase
          .from('target_5r_findings')
          .select()
          .eq('type', 'monthly')
          .lte('effective_date', referenceDate)
          .order('effective_date', ascending: false)
          .limit(1);

      if (!mounted) return;
      final data = (rows as List).isNotEmpty ? rows.first : null;
      setState(() {
        if (data != null) {
          _targetAnggota = data['target_anggota'] ?? 2;
          _targetAnggotaSelesai = data['target_anggota_selesai'] ?? 2;
        } else {
          _targetAnggota = 0;
          _targetAnggotaSelesai = 0;
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
          _targetAnggota = daily['target_anggota'] ?? 2;
          _targetAnggotaSelesai = daily['target_anggota_selesai'] ?? 2;
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
      _targetAnggota = 0;
      _targetAnggotaSelesai = 0;
    });
  }

  // ─── FETCH MEMBERS ───────────────────────────────────────────────────────
  void _fetchMembers() {
    final month = _selectedMonthIndex + 1;
    final year = DateTime.now().year;

    setState(() {
      _lastUpdated = DateTime.now();
      if (_filterMode == 'daily' && _selectedDate != null) {
        membersFuture = _fetchAnggotaDataDaily(_selectedDate!, _selectedUnitId);
      } else {
        membersFuture = _fetchAnggotaData(month, year, _selectedUnitId);
      }
    });
  }

  void _onFilterChanged() {
    _fetchTarget();
    _fetchMembers();
    _fetchChart();
  }

  Future<List<MemberData5R>> _fetchAnggotaData(
      int month, int year, String? unitId) async {
    try {
      var userQuery = _supabase
          .from('User')
          .select(
              'id_user, nama, gambar_user, id_unit, id_jabatan, is_verificator, unit!user_id_unit_fkey(nama_unit), jabatan!User_id_jabatan_fkey(nama_jabatan)')
          .or('id_jabatan.is.null,id_jabatan.neq.6');
      if (unitId != null) userQuery = userQuery.eq('id_unit', unitId);
      final List<dynamic> users = await userQuery;
      if (users.isEmpty) return [];

      final userIds = users.map((u) => u['id_user'].toString()).toList();

      final List<dynamic> temuanRes = await _supabase
          .from('temuan')
          .select('id_user, id_penyelesaian')
          .neq('jenis_temuan', 'KTS Production')
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

      final currentUserId = _supabase.auth.currentUser?.id;
      return users.map((u) {
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
      debugPrint('Error fetching Anggota: $e');
      return [];
    }
  }

  Future<List<MemberData5R>> _fetchAnggotaDataDaily(
      DateTime date, String? unitId) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

      var userQuery = _supabase
          .from('User')
          .select(
              'id_user, nama, gambar_user, id_unit, id_jabatan, is_verificator, unit!user_id_unit_fkey(nama_unit), jabatan!User_id_jabatan_fkey(nama_jabatan)')
          .or('id_jabatan.is.null,id_jabatan.neq.6');
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
      return users.map((u) {
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
      debugPrint('Error fetching Anggota daily: $e');
      return [];
    }
  }

  // ─── CHART FETCH ─────────────────────────────────────────────────────────
  void _fetchChart() {
    final month = _selectedMonthIndex + 1;
    final year = DateTime.now().year;
    setState(() {
      _chartFuture = _fetchChartData(month, year);
      _chartRefreshKey++;
    });
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
    } catch (e) {
      debugPrint('Error fetching chart data: $e');
      return [];
    }
  }

  String get _lastUpdatedText {
    if (_lastUpdated == null) return getTxt('memuat_data');
    final formattedDate = DateFormat('d MMM yyyy HH:mm',
            widget.lang == 'ID' ? 'id_ID' : 'en_US')
        .format(_lastUpdated!);
    return '${getTxt('diperbarui_pada')} $formattedDate (GMT+7)';
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // COLLAPSIBLE CHART
      _buildCollapsibleChart(),
      // FILTER ROW
      Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Expanded(child: _buildMemberTimeFilterButton()),
          const SizedBox(width: 10),
          Expanded(child: _buildMemberGroupFilterButton()),
        ]),
      ),
      // LAST UPDATED
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.access_time_filled_rounded,
                  size: 13, color: _AppColors.primary),
              const SizedBox(width: 6),
              Text(_lastUpdatedText,
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _AppColors.textPrimary)),
            ]),
          ),
        ),
      ),
      // TABLE HEADER
      _buildTableHeader(),
      // TARGET ROW
      _buildTargetRow(),
      // LIST
      Expanded(child: membersFuture == null
          ? _buildShimmer()
          : FutureBuilder<List<MemberData5R>>(
              future: membersFuture,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return _buildShimmer();
                }
                if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
                  return Center(child: Text(getTxt('tidak_ada_data_anggota')));
                }
                final list = snap.data!;
                final self = list.firstWhere(
                  (m) => m.isSelf,
                  orElse: () => MemberData5R(
                    name: getTxt('saya'),
                    findings: 0,
                    completed: 0,
                    isSelf: true,
                  ),
                );
                return Column(children: [
                  Expanded(child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, color: _AppColors.divider, indent: 16),
                    itemBuilder: (_, i) => _buildMemberRow(list[i]),
                  )),
                  _buildSelfPinnedRow(self),
                ]);
              },
            )),
    ]);
  }

  Widget _buildTableHeader() {
    final cols = [getTxt('nama'), getTxt('temuan'), getTxt('selesai')];
    return Container(
      color: const Color(0xFFF8FAFF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: List.generate(cols.length, (i) {
        return Expanded(
          flex: i == 0 ? 3 : 1,
          child: Text(cols[i],
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _AppColors.textSecondary,
                  letterSpacing: 0.2)),
        );
      })),
    );
  }

  Widget _buildTargetRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: _AppColors.primaryLight,
        border: Border(bottom: BorderSide(color: _AppColors.divider)),
      ),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Text(getTxt('target_bulanan'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _AppColors.primary)),
        ),
        Expanded(
          flex: 1,
          child: Text('$_targetAnggota',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _AppColors.primary)),
        ),
        Expanded(
          flex: 1,
          child: Text('$_targetAnggotaSelesai',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _AppColors.primary)),
        ),
      ]),
    );
  }

  Widget _buildMemberRow(MemberData5R m) {
    final target = _targetAnggota;
    final findingsColor = (target > 0 && m.findings >= target)
        ? const Color(0xFF16A34A)
        : _AppColors.textPrimary;
    final completedTarget = _targetAnggotaSelesai;
    final completedColor = (completedTarget > 0 && m.completed >= completedTarget)
        ? const Color(0xFF16A34A)
        : _AppColors.textPrimary;

    return Container(
      color: m.isSelf ? _AppColors.selfHighlight : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(flex: 3, child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Avatar5R(name: m.name, avatarUrl: m.avatarUrl, color: m.avatarColor, size: 36),
            const SizedBox(width: 10),
            Expanded(child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name,
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _AppColors.textPrimary),
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
              ],
            )),
          ],
        )),
        Expanded(
          flex: 1,
          child: Text('${m.findings}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: findingsColor)),
        ),
        Expanded(
          flex: 1,
          child: Text('${m.completed}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: completedColor)),
        ),
      ]),
    );
  }

  Widget _buildSelfPinnedRow(MemberData5R self) {
    final target = _targetAnggota;
    final findingsColor = (target > 0 && self.findings >= target)
        ? const Color(0xFF16A34A)
        : _AppColors.textSecondary;
    final completedTarget = _targetAnggotaSelesai;
    final completedColor = (completedTarget > 0 && self.completed >= completedTarget)
        ? const Color(0xFF16A34A)
        : _AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: _AppColors.selfHighlight,
        border: const Border(
            top: BorderSide(color: _AppColors.selfHighlightBorder, width: 1.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, -2))
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(flex: 3, child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Avatar5R(name: self.name, avatarUrl: self.avatarUrl, color: self.avatarColor, size: 36),
            const SizedBox(width: 10),
            Expanded(child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(self.name,
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildJabatanBadge(
                        idJabatan: self.idJabatan,
                        jabatanNama: self.jabatanNama,
                        isVerificator: self.isVerificator),
                    _buildUnitBadge(self.unitName),
                  ],
                ),
              ],
            )),
          ],
        )),
        Expanded(
          flex: 1,
          child: Text('${self.findings}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: findingsColor)),
        ),
        Expanded(
          flex: 1,
          child: Text('${self.completed}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: completedColor)),
        ),
      ]),
    );
  }

  // ─── COLLAPSIBLE BAR CHART (sama persis seperti tab Members di analytics_5r_tab.dart) ───
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
            border: Border.all(color: activeColor.withValues(alpha: 0.4), width: 1.2),
            boxShadow: [BoxShadow(color: activeColor.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))],
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
                key: ValueKey('chart-$_chartRefreshKey-members'),
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

                  final tTarget = _targetAnggota;
                  final pTarget = _targetAnggotaSelesai;
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

                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.fromLTRB(0, 12, 8, 8),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _AppColors.primaryLight),
                      boxShadow: [BoxShadow(color: activeColor.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // LEGEND
                      Padding(
                        padding: EdgeInsets.only(left: leftW + 4, bottom: 8),
                        child: Wrap(spacing: 12, children: [
                          _chartLegendItem(colorTemuan,
                            widget.lang == 'ID' ? 'Temuan' : 'Findings'),
                          _chartLegendItem(colorPenyelesaian,
                            widget.lang == 'ID' ? 'Selesai' : 'Completed'),
                          if (tTarget > 0)
                            _chartLegendDash(
                              const Color(0xFFEF4444),
                              widget.lang == 'ID' ? 'Target Anggota' : widget.lang == 'ZH' ? '成员目标' : 'Member Target',
                            ),
                          if (pTarget > 0)
                            _chartLegendDash(
                              const Color(0xFFF59E0B),
                              widget.lang == 'ID' ? 'Target Anggota Selesai' : widget.lang == 'ZH' ? '成员完成目标' : 'Member Completion Target',
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
                                if (tTarget > 0)
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

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: 10,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: _AppColors.divider, indent: 16),
        itemBuilder: (_, __) => Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(children: [
            Expanded(flex: 3, child: Row(children: [
              _shimmerBox(height: 34, width: 34, isCircle: true),
              const SizedBox(width: 10),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _shimmerBox(height: 14, width: 120),
                const SizedBox(height: 4),
                _shimmerBox(height: 12, width: 80),
              ])),
            ])),
            Expanded(flex: 1, child: Center(child: _shimmerBox(height: 14, width: 20))),
            Expanded(flex: 1, child: Center(child: _shimmerBox(height: 14, width: 20))),
          ]),
        ),
      ),
    );
  }

  Widget _shimmerBox({
    double? width,
    required double height,
    bool isCircle = false,
    double borderRadius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCircle ? height / 2 : borderRadius),
      ),
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
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
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
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  String get _monthLabel {
    final locale = widget.lang == 'ID' ? 'id_ID' : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    return DateFormat.MMM(locale).format(DateTime(2000, _selectedMonthIndex + 1));
  }

  Widget _buildMemberTimeFilterButton() {
    final isActive = _filterMode == 'daily';
    final modeLabel = _filterMode == 'daily'
        ? (widget.lang == 'ID' ? 'Harian' : widget.lang == 'ZH' ? '按日' : 'Daily')
        : (widget.lang == 'ID' ? 'Bulanan' : widget.lang == 'ZH' ? '按月' : 'Monthly');
    final valueLabel = _filterMode == 'daily' && _selectedDate != null
        ? DateFormat('d MMM yyyy',
                widget.lang == 'ID' ? 'id_ID' : widget.lang == 'EN' ? 'en_US' : 'zh_CN')
            .format(_selectedDate!)
        : _monthLabel;

    return GestureDetector(
      onTap: _showMonthPicker,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? _AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _AppColors.primary : const Color(0xFF7DD3FC),
            width: 1.5,
          ),
          boxShadow: [BoxShadow(
              color: _AppColors.primary.withValues(alpha: 0.10), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month_rounded, size: 15,
                    color: isActive ? Colors.white : _AppColors.primary),
                const SizedBox(width: 5),
                Flexible(
                  child: Text('$modeLabel · $valueLabel',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : _AppColors.primary)),
                ),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded,
              color: isActive ? Colors.white : _AppColors.primary, size: 18),
        ]),
      ),
    );
  }

  Widget _buildMemberGroupFilterButton() {
    final isActive = _selectedUnitId != null;
    final label = _selectedUnitId == null
        ? getTxt('semua_grup_anggota')
        : (_unitList.firstWhere(
                (u) => u['id_unit'].toString() == _selectedUnitId,
                orElse: () => {'nama_unit': getTxt('semua_grup')})['nama_unit']
            as String);

    return GestureDetector(
      onTap: _showGroupPicker,
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
              color: _AppColors.primary.withValues(alpha: 0.10), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Expanded(
            child: Text(label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : _AppColors.primary)),
          ),
          Icon(Icons.keyboard_arrow_down_rounded,
              color: isActive ? Colors.white : _AppColors.primary, size: 18),
        ]),
      ),
    );
  }

  // ─── DIALOG: MONTH / DAILY PICKER ───────────────────────────────────────
  void _showMonthPicker() async {
    String tempMode = _filterMode;
    int tempMonthIndex = _selectedMonthIndex;
    DateTime tempDate = _selectedDate ?? DateTime.now();
    DateTime tempDisplayMonth = DateTime(tempDate.year, tempDate.month, 1);

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
                          _onFilterChanged();
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
                              color: _AppColors.primary.withValues(alpha: 0.3),
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
                  child: _buildDailyCalendar(
                    tempDate,
                    tempDisplayMonth,
                    (picked) => setSt(() => tempDate = picked),
                    (newMonth) => setSt(() => tempDisplayMonth = newMonth),
                    onConfirm: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _filterMode = 'daily';
                        _selectedDate = tempDate;
                        _selectedMonthIndex = tempDate.month - 1;
                      });
                      _onFilterChanged();
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
      ValueChanged<DateTime> onMonthChanged, {required VoidCallback onConfirm}) {
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
                  color: _AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.chevron_left_rounded, size: 18, color: _AppColors.primary),
              ),
            ),
            Text(monthLabel, style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: _AppColors.textPrimary)),
            GestureDetector(
              onTap: isCurrentMonth ? null : () => onMonthChanged(DateTime(year, month + 1, 1)),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isCurrentMonth ? Colors.grey.shade100 : _AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.chevron_right_rounded,
                    size: 18,
                    color: isCurrentMonth ? Colors.grey.shade400 : _AppColors.primary),
              ),
            ),
          ],
        ),
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

  // ─── DIALOG: GROUP PICKER ────────────────────────────────────────────────
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
                          _onFilterChanged();
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
}

// ─── Avatar ──────────────────────────────────────────────────────────────────
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
      );
    }
    final initials = name.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    final bg = color ?? const Color(0xFF0EA5E9);
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: bg.withValues(alpha: 0.3), width: 1)),
      child: Center(child: Text(initials,
          style: TextStyle(fontSize: size * 0.35, fontWeight: FontWeight.w700, color: bg))),
    );
  }
}

// ─── Unit Badge Helper ────────────────────────────────────────────────────────
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