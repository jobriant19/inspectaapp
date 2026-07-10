import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/utils/jabatan_helper.dart'; // TODO: sesuaikan path jika berbeda

class _AppColors {
  static const primary = Color(0xFF0EA5E9);
  static const primaryLight = Color(0xFFE0F2FE);
  static const surface = Color(0xFFF0F9FF);
  static const textPrimary = Color(0xFF0C4A6E);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFFBDBDBD);
  static const divider = Color(0xFFE0F2FE);
}

class _ChartBarData {
  final int date;
  final int temuan;
  final int penyelesaian;
  _ChartBarData({required this.date, required this.temuan, required this.penyelesaian});
}

class _InspeksiData5R {
  final String name;
  final int findings;
  final String? avatarUrl;
  final int? idJabatan;
  final String? jabatanNama;
  final bool? isVerificator;
  final String? unitName;

  const _InspeksiData5R({
    required this.name,
    required this.findings,
    this.avatarUrl,
    this.idJabatan,
    this.jabatanNama,
    this.isVerificator,
    this.unitName,
  });
}

class Admin5RInspectionTab extends StatefulWidget {
  final String lang;
  const Admin5RInspectionTab({super.key, required this.lang});

  @override
  State<Admin5RInspectionTab> createState() => _Admin5RInspectionTabState();
}

class _Admin5RInspectionTabState extends State<Admin5RInspectionTab> {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const Map<String, Color> _roleColors = {
    'Eksekutif': Color(0xFFEF4444),
    'Executive': Color(0xFFEF4444),
    '行政': Color(0xFFEF4444),
    'Profesional': Color(0xFFF59E0B),
    'Professional': Color(0xFFF59E0B),
    '专业': Color(0xFFF59E0B),
    'Visitor': Color(0xFF3B82F6),
    '访客': Color(0xFF3B82F6),
  };

  final Map<String, Map<String, String>> _texts = {
    'ID': {
      'memuat_data': 'Memuat data...',
      'diperbarui_pada': 'Terakhir diperbarui pada',
      'nama': 'Nama', 'temuan': 'Temuan',
      'target_bulanan': 'Target Bulanan',
      'periode_audit': 'Periode audit: ',
      'eksekutif': 'Eksekutif', 'profesional': 'Profesional', 'visitor': 'Visitor',
      'pilih_bulan': 'Pilih Bulan', 'terapkan': 'Terapkan',
      'tidak_ada_temuan_role': 'Tidak ada temuan untuk role',
    },
    'EN': {
      'memuat_data': 'Loading data...',
      'diperbarui_pada': 'Last updated at',
      'nama': 'Name', 'temuan': 'Findings',
      'target_bulanan': 'Monthly Target',
      'periode_audit': 'Audit period: ',
      'eksekutif': 'Executive', 'profesional': 'Professional', 'visitor': 'Visitor',
      'pilih_bulan': 'Select Month', 'terapkan': 'Apply',
      'tidak_ada_temuan_role': 'No findings for role',
    },
    'ZH': {
      'memuat_data': '加载数据...',
      'diperbarui_pada': '最后更新于',
      'nama': '名称', 'temuan': '发现',
      'target_bulanan': '每月目标',
      'periode_audit': '审计期间: ',
      'eksekutif': '行政', 'profesional': '专业', 'visitor': '访客',
      'pilih_bulan': '选择月份', 'terapkan': '应用',
      'tidak_ada_temuan_role': '没有角色的发现',
    },
  };

  String getTxt(String key) => _texts[widget.lang]?[key] ?? key;

  // FILTER STATE
  int _selectedMonthIndex = DateTime.now().month - 1;
  String _filterMode = 'monthly';
  DateTime? _selectedDate;
  String _selectedInspectionRole = 'Eksekutif';
  DateTime? _lastUpdated;
  int _chartRefreshKey = 0;

  // CHART STATE
  bool _isChartExpanded = false;
  Future<List<_ChartBarData>>? _chartFuture;
  int _targetInspeksi = 2;
  int _chartTargetInspeksiSelesai = 2;

  // DATA STATE
  Future<List<_InspeksiData5R>>? _inspeksiFuture;

  late List<String> _translatedMonths;
  late List<String> _translatedRoles;

  @override
  void initState() {
    super.initState();
    _initLocaleDependentLists();
    _fetchData();
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
  }

  int get _selectedMonth => _selectedMonthIndex + 1;

  // ==================== FETCH: TARGET ====================
  Future<void> _fetchTarget() async {
    try {
      final month = _selectedMonth;
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
      final referenceDate = DateTime(year, month, 1).toIso8601String().split('T').first;
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
          _targetInspeksi = data['target_inspeksi'] ?? 2;
          _chartTargetInspeksiSelesai = data['target_inspeksi_selesai'] ?? 2;
        } else {
          _targetInspeksi = 0;
          _chartTargetInspeksiSelesai = 0;
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
          _targetInspeksi = daily['target_inspeksi'] ?? 2;
          _chartTargetInspeksiSelesai = daily['target_inspeksi_selesai'] ?? 2;
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
      _targetInspeksi = 0;
      _chartTargetInspeksiSelesai = 0;
    });
  }

  (int temuan, int selesai) get _chartTargets {
    final bool isHolidayOrWeekend = _filterMode == 'daily' &&
        _selectedDate != null &&
        _targetInspeksi == 0 &&
        _chartTargetInspeksiSelesai == 0;
    if (isHolidayOrWeekend) return (0, 0);
    return (_targetInspeksi, _chartTargetInspeksiSelesai);
  }

  // ==================== FETCH: MAIN DATA ====================
  void _fetchData() {
    _fetchTarget();

    final roleBackendValue = ['Eksekutif', 'Profesional', 'Visitor'][
        _translatedRoles.indexOf(_selectedInspectionRole).clamp(0, 2)];

    setState(() {
      _lastUpdated = DateTime.now();
      final month = _selectedMonth;
      final year = DateTime.now().year;

      if (_filterMode == 'daily' && _selectedDate != null) {
        _inspeksiFuture = _fetchInspeksiDataDaily(_selectedDate!, roleBackendValue);
      } else {
        _inspeksiFuture = _fetchInspeksiData(month, year, roleBackendValue);
      }
      _chartFuture = _fetchChartData(month, year);
      _chartRefreshKey++;
    });
  }

  Future<List<_InspeksiData5R>> _fetchInspeksiData(int month, int year, String role) async {
    try {
      final roleCol = role == 'Eksekutif' ? 'is_eksekutif'
          : role == 'Profesional' ? 'is_pro'
          : 'is_visitor';

      final List<dynamic> temuanRes = await _supabase
          .from('temuan')
          .select('id_user, User_Creator:User!temuan_id_user_fkey(nama, gambar_user, id_jabatan, is_verificator, unit!user_id_unit_fkey(nama_unit), jabatan!User_id_jabatan_fkey(nama_jabatan))')
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
        grouped.putIfAbsent(userId, () => {
          'nama': user['nama'] ?? '-',
          'temuan': 0,
          'gambar_user': user['gambar_user'],
          'id_jabatan': user['id_jabatan'],
          'is_verificator': user['is_verificator'],
          'jabatan_nama': (user['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'],
          'unit_nama': (user['unit'] as Map<String, dynamic>?)?['nama_unit'],
        });
        grouped[userId]!['temuan'] = (grouped[userId]!['temuan'] as int) + 1;
      }

      if (role == 'Eksekutif') {
        final List<dynamic> eksekutifUsers = await _supabase
            .from('User')
            .select('id_user, nama, gambar_user, id_jabatan, is_verificator, unit!user_id_unit_fkey(nama_unit), jabatan!User_id_jabatan_fkey(nama_jabatan)')
            .eq('id_jabatan', 1);
        for (final u in eksekutifUsers) {
          final uid = u['id_user']?.toString() ?? '';
          if (uid.isEmpty) continue;
          grouped.putIfAbsent(uid, () => {
            'nama': u['nama'] ?? '-',
            'temuan': 0,
            'gambar_user': u['gambar_user'],
            'id_jabatan': u['id_jabatan'],
            'is_verificator': u['is_verificator'],
            'jabatan_nama': (u['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'],
            'unit_nama': (u['unit'] as Map<String, dynamic>?)?['nama_unit'],
          });
        }
      }

      return grouped.values
          .map((item) => _InspeksiData5R(
                name: item['nama'] as String,
                findings: item['temuan'] as int,
                avatarUrl: item['gambar_user'] as String?,
                idJabatan: item['id_jabatan'] as int?,
                jabatanNama: item['jabatan_nama'] as String?,
                isVerificator: item['is_verificator'] as bool?,
                unitName: item['unit_nama'] as String?,
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

  Future<List<_InspeksiData5R>> _fetchInspeksiDataDaily(DateTime date, String role) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final roleCol = role == 'Eksekutif' ? 'is_eksekutif'
          : role == 'Profesional' ? 'is_pro'
          : 'is_visitor';

      final List<dynamic> temuanRes = await _supabase
          .from('temuan')
          .select('id_user, User_Creator:User!temuan_id_user_fkey(nama, gambar_user, id_jabatan, is_verificator, unit!user_id_unit_fkey(nama_unit), jabatan!User_id_jabatan_fkey(nama_jabatan))')
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
        grouped.putIfAbsent(userId, () => {
          'nama': user['nama'] ?? '-',
          'temuan': 0,
          'gambar_user': user['gambar_user'],
          'id_jabatan': user['id_jabatan'],
          'is_verificator': user['is_verificator'],
          'jabatan_nama': (user['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'],
          'unit_nama': (user['unit'] as Map<String, dynamic>?)?['nama_unit'],
        });
        grouped[userId]!['temuan'] = (grouped[userId]!['temuan'] as int) + 1;
      }

      if (role == 'Eksekutif') {
        final List<dynamic> eksekutifUsers = await _supabase
            .from('User')
            .select('id_user, nama, gambar_user, id_jabatan, is_verificator, unit!user_id_unit_fkey(nama_unit), jabatan!User_id_jabatan_fkey(nama_jabatan)')
            .eq('id_jabatan', 1);
        for (final u in eksekutifUsers) {
          final uid = u['id_user']?.toString() ?? '';
          if (uid.isEmpty) continue;
          grouped.putIfAbsent(uid, () => {
            'nama': u['nama'] ?? '-',
            'temuan': 0,
            'gambar_user': u['gambar_user'],
            'id_jabatan': u['id_jabatan'],
            'is_verificator': u['is_verificator'],
            'jabatan_nama': (u['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'],
            'unit_nama': (u['unit'] as Map<String, dynamic>?)?['nama_unit'],
          });
        }
      }

      return grouped.values
          .map((item) => _InspeksiData5R(
                name: item['nama'] as String,
                findings: item['temuan'] as int,
                avatarUrl: item['gambar_user'] as String?,
                idJabatan: item['id_jabatan'] as int?,
                jabatanNama: item['jabatan_nama'] as String?,
                isVerificator: item['is_verificator'] as bool?,
                unitName: item['unit_nama'] as String?,
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

  // ==================== FETCH: CHART ====================
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
    } catch (e) {
      debugPrint('Error fetching chart data: $e');
      return [];
    }
  }

  String get _lastUpdatedText {
    if (_lastUpdated == null) return getTxt('memuat_data');
    final formattedDate = DateFormat('d MMM yyyy HH:mm',
        widget.lang == 'ID' ? 'id_ID' : 'en_US').format(_lastUpdated!);
    return '${getTxt('diperbarui_pada')} $formattedDate (GMT+7)';
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildCollapsibleChart(),
      Expanded(child: _buildInspeksiBody()),
    ]);
  }

  // COLLAPSIBLE BAR CHART
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
                key: ValueKey('chart-$_chartRefreshKey-inspection'),
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

                  final (tTarget, pTarget) = _chartTargets;
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
                              widget.lang == 'ID' ? 'Target Inspeksi'
                                  : widget.lang == 'ZH' ? '检查目标'
                                  : 'Inspection Target',
                            ),
                          if (pTarget > 0)
                            _chartLegendDash(
                              const Color(0xFFF59E0B),
                              widget.lang == 'ID' ? 'Target Inspeksi Selesai'
                                  : widget.lang == 'ZH' ? '检查完成目标'
                                  : 'Inspection Completion Target',
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

  // ==================== INSPEKSI BODY (filter bar + list) ====================
  Widget _buildInspeksiBody() {
    return Column(children: [
      // FILTER BAR
      Container(
        color: Colors.transparent,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          _buildFilterButton(
            label: _filterMode == 'daily' && _selectedDate != null
                ? DateFormat(
                    'd MMM yyyy',
                    widget.lang == 'ID'
                        ? 'id_ID'
                        : widget.lang == 'EN'
                            ? 'en_US'
                            : 'zh_CN',
                  ).format(_selectedDate!)
                : _translatedMonths[_selectedMonthIndex],
            icon: Icons.calendar_month_rounded,
            isActive: _filterMode == 'daily' ||
                _selectedMonthIndex != DateTime.now().month - 1,
            onTap: _showMonthPicker,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: _translatedRoles.map((r) {
                final isSelected = _selectedInspectionRole == r;
                final activeColor = _roleColors[r] ?? _AppColors.primary;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: r != _translatedRoles.last ? 6 : 0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedInspectionRole = r);
                        _fetchData();
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
                              ? [
                                  BoxShadow(
                                      color: activeColor.withValues(alpha: 0.28),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3))
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            r,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : _AppColors.textSecondary,
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

      // LAST UPDATED
      _buildLastUpdatedWidget(),

      // TABLE HEADER
      _buildTableHeader([getTxt('nama'), getTxt('temuan')], flex: [3, 1]),

      // TARGET ROW
      _buildTargetRow([getTxt('target_bulanan'), '$_targetInspeksi']),

      // LIST
      Expanded(child: Builder(builder: (context) {
        if (_inspeksiFuture == null) return _buildInspeksiShimmer();
        return FutureBuilder<List<_InspeksiData5R>>(
          future: _inspeksiFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildInspeksiShimmer();
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: snapshot.data!.length,
              separatorBuilder: (_, __) => const Divider(
                  height: 1, color: _AppColors.divider, indent: 16),
              itemBuilder: (_, i) => _buildInspectionRow(snapshot.data![i]),
            );
          },
        );
      })),
    ]);
  }

  // EMPTY STATE PROFESIONAL & VISITOR
  Widget _buildEmptyState() {
    final isProfessional = _selectedInspectionRole == getTxt('profesional');
    final isVisitor = _selectedInspectionRole == getTxt('visitor');

    if (!isProfessional && !isVisitor) {
      return Center(
        child: Text('${getTxt('tidak_ada_temuan_role')} "$_selectedInspectionRole".'),
      );
    }

    final asset = isProfessional
        ? 'assets/images/modepro.png'
        : 'assets/images/visitor_off.png';

    final title = isProfessional
        ? (widget.lang == 'ID'
            ? 'Belum Ada Temuan Profesional'
            : widget.lang == 'ZH'
                ? '暂无专业模式发现'
                : 'No Professional Findings Yet')
        : (widget.lang == 'ID'
            ? 'Belum Ada Temuan Visitor'
            : widget.lang == 'ZH'
                ? '暂无访客发现'
                : 'No Visitor Findings Yet');

    final subtitle = isProfessional
        ? (widget.lang == 'ID'
            ? 'Belum ada temuan yang tercatat menggunakan Mode Profesional pada periode ini.'
            : widget.lang == 'ZH'
                ? '本期尚未有使用专业模式记录的发现。'
                : 'No findings have been recorded using Professional Mode for this period.')
        : (widget.lang == 'ID'
            ? 'Belum ada temuan yang tercatat oleh Visitor pada periode ini.'
            : widget.lang == 'ZH'
                ? '本期尚未有访客记录的发现。'
                : 'No findings have been recorded by Visitors for this period.');

    final Color accent = isProfessional
        ? const Color(0xFFF59E0B)
        : const Color(0xFF3B82F6);

    return Align(
      alignment: const Alignment(0, -0.35),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                accent.withOpacity(0.16),
                accent.withOpacity(0.02),
              ]),
              boxShadow: [
                BoxShadow(
                    color: accent.withOpacity(0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10)),
              ],
            ),
            child: Image.asset(
              asset,
              width: 130,
              height: 130,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                  Icons.image_not_supported_rounded,
                  size: 80,
                  color: accent.withOpacity(0.4)),
            ),
          ),
          const SizedBox(height: 20),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: accent,
                  letterSpacing: 0.1)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withOpacity(0.18)),
            ),
            child: Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5,
                    color: _AppColors.textPrimary,
                    height: 1.55,
                    fontWeight: FontWeight.w500)),
          ),
        ]),
      ),
    );
  }

  Widget _buildLastUpdatedWidget() {
    return Padding(
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
                  color: _AppColors.textSecondary,
                  letterSpacing: 0.2),
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
          child: Text(
            vals[0],
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _AppColors.primary),
          ),
        ),
        ...vals.sublist(1).map((v) => Expanded(
              flex: 1,
              child: Text(
                v,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _AppColors.primary),
              ),
            )),
      ]),
    );
  }

  Widget _buildInspectionRow(_InspeksiData5R item) {
    final target = _targetInspeksi;
    final findingsColor = (target > 0 && item.findings >= target)
        ? const Color(0xFF16A34A)
        : _AppColors.textPrimary;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
            flex: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Avatar5RAdmin(name: item.name, avatarUrl: item.avatarUrl, size: 36),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildJabatanBadge(
                            idJabatan: item.idJabatan,
                            jabatanNama: item.jabatanNama,
                            isVerificator: item.isVerificator),
                        _buildUnitBadge(item.unitName),
                      ],
                    ),
                  ],
                )),
              ],
            )),
        Expanded(
            flex: 1,
            child: Text(
              '${item.findings}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: findingsColor),
            )),
      ]),
    );
  }

  // ROLE BADGE
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

  Widget _buildInspeksiShimmer() {
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Expanded(
                flex: 3,
                child: Row(children: [
                  _buildShimmerBox(height: 34, width: 34, isCircle: true),
                  const SizedBox(width: 10),
                  Expanded(child: _buildShimmerBox(height: 14)),
                ])),
            Expanded(
                flex: 1,
                child: Center(
                    child: _buildShimmerBox(height: 14, width: 20))),
          ]),
        ),
      ),
    );
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

  // FILTER BUTTON
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
              color: _AppColors.primary.withValues(alpha: 0.10), blurRadius: 6, offset: const Offset(0, 2))],
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

  // ==================== MONTH / DAILY PICKER ====================
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
                          _fetchTarget().then((_) => _fetchData());
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
                      _fetchData();
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
                child: const Icon(Icons.chevron_left_rounded,
                    size: 18, color: _AppColors.primary),
              ),
            ),
            Text(monthLabel, style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: _AppColors.textPrimary)),
            GestureDetector(
              onTap: isCurrentMonth
                  ? null
                  : () => onMonthChanged(DateTime(year, month + 1, 1)),
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

// AVATAR
class _Avatar5RAdmin extends StatelessWidget {
  final String name;
  final Color? color;
  final double size;
  final String? avatarUrl;

  const _Avatar5RAdmin(
      // ignore: unused_element_parameter
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
    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    final bg = color ?? _AppColors.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: bg.withValues(alpha: 0.3), width: 1),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
              fontSize: size * 0.35,
              fontWeight: FontWeight.w700,
              color: bg),
        ),
      ),
    );
  }
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