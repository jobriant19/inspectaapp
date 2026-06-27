import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class _AppColors {
  static const primary      = Color(0xFF0EA5E9);
  static const primaryDark  = Color(0xFF0369A1);
  static const primaryLight = Color(0xFFE0F2FE);
  static const surface      = Color(0xFFF0F9FF);
  static const textPrimary  = Color(0xFF0C4A6E);
  static const textSecondary= Color(0xFF64748B);
  static const textMuted    = Color(0xFFBDBDBD);
  static const divider      = Color(0xFFE0F2FE);
}

class LocationData5R {
  final String  name;
  final String  pic;
  final String? value;
  const LocationData5R({required this.name, required this.pic, this.value});
}

class AuditLocationData5R {
  final String  id;
  final String  name;
  final String  pic;
  final double? auditScore;
  final String? auditDate;
  const AuditLocationData5R({
    required this.id,
    required this.name,
    required this.pic,
    this.auditScore,
    this.auditDate,
  });
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

class _ChartBarData {
  final int    date;
  final int    temuan;
  final double auditScore;
  _ChartBarData({required this.date, required this.temuan, this.auditScore = 0});
}

class Admin5RLocationTab extends StatefulWidget {
  final String lang;
  const Admin5RLocationTab({super.key, required this.lang});

  @override
  State<Admin5RLocationTab> createState() => Admin5RLocationTabState();
}

class Admin5RLocationTabState extends State<Admin5RLocationTab> {
  final _supabase = Supabase.instance.client;

  static const Map<String, Map<String, String>> _texts = {
    'ID': {
      'memuat_data':          'Memuat data...',
      'diperbarui_pada':      'Terakhir diperbarui pada',
      'tidak_ada_data_level': 'Tidak ada data untuk level',
      'rank':                 'Rank',
      'lokasi':               'Lokasi',
      'temuan':               'Temuan',
      'nilai':                'Nilai',
      'periode_audit':        'Periode audit: ',
      'target_bulanan':       'Target Bulanan',
      'pilih_bulan':          'Pilih Bulan',
      'pilih_level':          'Pilih Level',
      'terapkan':             'Terapkan',
      'level_lokasi':         'Lokasi',
      'level_unit':           'Unit',
      'level_subunit':        'Subunit',
      'level_area':           'Area',
      'belum_ada_audit':      'Belum ada riwayat audit.',
    },
    'EN': {
      'memuat_data':          'Loading data...',
      'diperbarui_pada':      'Last updated at',
      'tidak_ada_data_level': 'No data for level',
      'rank':                 'Rank',
      'lokasi':               'Location',
      'temuan':               'Findings',
      'nilai':                'Score',
      'periode_audit':        'Audit period: ',
      'target_bulanan':       'Monthly Target',
      'pilih_bulan':          'Select Month',
      'pilih_level':          'Select Level',
      'terapkan':             'Apply',
      'level_lokasi':         'Location',
      'level_unit':           'Unit',
      'level_subunit':        'Sub-unit',
      'level_area':           'Area',
      'belum_ada_audit':      'No audit history.',
    },
    'ZH': {
      'memuat_data':          '加载数据...',
      'diperbarui_pada':      '最后更新于',
      'tidak_ada_data_level': '没有级别的数据',
      'rank':                 '排名',
      'lokasi':               '位置',
      'temuan':               '发现',
      'nilai':                '评分',
      'periode_audit':        '审计期间: ',
      'target_bulanan':       '每月目标',
      'pilih_bulan':          '选择月份',
      'pilih_level':          '选择级别',
      'terapkan':             '应用',
      'level_lokasi':         '位置',
      'level_unit':           '单元',
      'level_subunit':        '子单元',
      'level_area':           '区域',
      'belum_ada_audit':      '还没有审计记录。',
    },
  };

  String _t(String key) => _texts[widget.lang]?[key] ?? key;

  // FILTER STATE
  int       _selectedMonthIndex = DateTime.now().month - 1;
  String    _filterMode         = 'monthly';
  DateTime? _selectedDate;
  DateTime? _lastUpdated;

  // SPESIFIC LOCATION LEVEL
  static const List<String> _levelsBackend = ['Lokasi', 'Unit', 'Subunit', 'Area'];
  String _selectedLevelBackend = 'Lokasi';

  // TARGET
  int _targetLokasi   = 5;
  int _targetUnit     = 5;
  int _targetSubunit  = 5;
  int _targetArea     = 5;

  // CHART
  bool                        _isChartExpanded = false;
  Future<List<_ChartBarData>>? _chartFuture;
  int                         _chartRefreshKey = 0;

  // DATA FUTURES
  Future<List<LocationData5R>>?      _lokasiFuture;
  Future<List<AuditLocationData5R>>? _auditFuture;

  // MONTH
  late List<String> _translatedMonths;

  @override
  void initState() {
    super.initState();
    _initMonths();
    _fetchTarget();
    _fetchAllData();
  }

  void _initMonths() {
    final locale = widget.lang == 'ID' ? 'id_ID'
        : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    _translatedMonths = List.generate(
        12, (i) => DateFormat.MMM(locale).format(DateTime(2000, i + 1)));
  }

  List<String> get _translatedLevels => [
    _t('level_lokasi'), _t('level_unit'), _t('level_subunit'), _t('level_area'),
  ];

  String get _selectedLevelLabel {
    final idx = _levelsBackend.indexOf(_selectedLevelBackend).clamp(0, 3);
    return _translatedLevels[idx];
  }

  bool get _useAuditMode =>
      !(_filterMode == 'daily' && _selectedDate != null);

  int get _currentTarget {
    switch (_selectedLevelBackend) {
      case 'Unit':    return _targetUnit;
      case 'Subunit': return _targetSubunit;
      case 'Area':    return _targetArea;
      default:        return _targetLokasi;
    }
  }

  Future<void> _fetchTarget() async {
    try {
      if (_filterMode == 'daily' && _selectedDate != null) {
        await _fetchTargetForDate(_selectedDate!);
      } else {
        await _fetchTargetMonthly(_selectedMonthIndex + 1, DateTime.now().year);
      }
    } catch (e) {
      debugPrint('Error fetching target: $e');
    }
  }

  Future<void> _fetchTargetMonthly(int month, int year) async {
    try {
      final rows = await _supabase
          .from('target_5r_findings')
          .select()
          .eq('type', 'monthly')
          .eq('bulan', month)
          .eq('tahun', year)
          .eq('is_aktif', true)
          .order('updated_at', ascending: false)
          .limit(1);
      if (!mounted) return;
      final data = (rows as List).isNotEmpty ? rows.first : null;
      setState(() {
        _targetLokasi  = data?['target_lokasi']  ?? 5;
        _targetUnit    = data?['target_unit']    ?? 5;
        _targetSubunit = data?['target_subunit'] ?? 5;
        _targetArea    = data?['target_area']    ?? 5;
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
        if (mounted) {
          setState(() {
            _targetLokasi = 0; _targetUnit = 0;
            _targetSubunit = 0; _targetArea = 0;
          });
        }
        return;
      }
      final offDay = await _supabase
          .from('target_5r_findings')
          .select()
          .eq('type', 'off_day')
          .eq('specific_date', dateStr)
          .eq('is_aktif', true)
          .limit(1);
      if ((offDay as List).isNotEmpty) {
        if (mounted) {
          setState(() {
            _targetLokasi = 0; _targetUnit = 0;
            _targetSubunit = 0; _targetArea = 0;
          });
        }
        return;
      }
      final daily = await _supabase
          .from('target_5r_findings')
          .select()
          .eq('type', 'daily_specific')
          .eq('specific_date', dateStr)
          .eq('is_aktif', true)
          .order('updated_at', ascending: false)
          .limit(1);
      if ((daily as List).isNotEmpty) {
        if (mounted) {
          setState(() {
            _targetLokasi  = daily.first['target_lokasi']  ?? 5;
            _targetUnit    = daily.first['target_unit']    ?? 5;
            _targetSubunit = daily.first['target_subunit'] ?? 5;
            _targetArea    = daily.first['target_area']    ?? 5;
          });
        }
        return;
      }
      await _fetchTargetMonthly(date.month, date.year);
    } catch (e) {
      debugPrint('Error fetching daily target: $e');
    }
  }

  void _fetchAllData() {
    final month = _selectedMonthIndex + 1;
    final year  = DateTime.now().year;
    final level = _selectedLevelBackend;

    setState(() {
      _lastUpdated = DateTime.now();
      if (_filterMode == 'daily' && _selectedDate != null) {
        _lokasiFuture = _fetchLokasiDaily(_selectedDate!, level);
        _auditFuture  = null;
        _chartFuture  = _fetchChartDaily(_selectedDate!, level);
      } else {
        _lokasiFuture = null;
        _auditFuture  = _fetchAuditMonthly(month, year, level);
        _chartFuture  = _fetchChartAuditMonthly(month, year, level);
      }
      _chartRefreshKey++;
    });
  }

  Future<List<LocationData5R>> _fetchLokasiDaily(
      DateTime date, String level) async {
    try {
      final start      = DateTime(date.year, date.month, date.day);
      final end        = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final levelLower = level.toLowerCase();
      final idCol      = _idColFor(levelLower);
      final nameCol    = _nameColFor(levelLower);

      final List<dynamic> locations =
          await _supabase.from(levelLower).select('$idCol, $nameCol');

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

      return locations.map<LocationData5R>((loc) {
        final id = loc[idCol]?.toString() ?? '';
        return LocationData5R(
          name:  loc[nameCol]?.toString() ?? '-',
          pic:   picMap[id] ?? 'PIC belum diatur',
          value: (countMap[id] ?? 0).toString(),
        );
      }).toList()
        ..sort((a, b) => (int.tryParse(b.value ?? '0') ?? 0)
            .compareTo(int.tryParse(a.value ?? '0') ?? 0));
    } catch (e) {
      debugPrint('Error fetching lokasi daily: $e');
      return [];
    }
  }

  Future<List<AuditLocationData5R>> _fetchAuditMonthly(
      int month, int year, String level) async {
    try {
      final levelLower = level.toLowerCase();
      final idCol      = _idColFor(levelLower);
      final nameCol    = _nameColFor(levelLower);

      final List<dynamic> locations = await _supabase
          .from(levelLower)
          .select('$idCol, $nameCol, id_pic');

      final startOfMonth = DateTime(year, month, 1).toIso8601String().split('T').first;
      final endOfMonth   = DateTime(year, month + 1, 0).toIso8601String().split('T').first;

      final List<dynamic> auditRows = await _supabase
          .from('audit_result')
          .select('id_ref, nilai_audit, tanggal_audit')
          .eq('level_type', levelLower)
          .gte('tanggal_audit', startOfMonth)
          .lte('tanggal_audit', endOfMonth)
          .order('tanggal_audit', ascending: false);

      final Map<String, Map<String, dynamic>> auditMap = {};
      for (final a in auditRows) {
        final ref = a['id_ref'].toString();
        if (!auditMap.containsKey(ref)) auditMap[ref] = a;
      }

      final picIds = locations
          .where((l) => l['id_pic'] != null)
          .map((l) => l['id_pic'].toString())
          .toSet()
          .toList();
      final Map<String, String> picMap = {};
      if (picIds.isNotEmpty) {
        final picRows = await _supabase
            .from('User')
            .select('id_user, nama')
            .inFilter('id_user', picIds);
        for (final p in picRows) {
          picMap[p['id_user'].toString()] = p['nama']?.toString() ?? '-';
        }
      }

      return locations.map<AuditLocationData5R>((loc) {
        final id    = loc[idCol]?.toString() ?? '';
        final audit = auditMap[id];
        return AuditLocationData5R(
          id:         id,
          name:       loc[nameCol]?.toString() ?? '-',
          pic:        loc['id_pic'] != null
              ? (picMap[loc['id_pic'].toString()] ?? 'PIC belum diatur')
              : 'PIC belum diatur',
          auditScore: audit != null
              ? double.tryParse(audit['nilai_audit']?.toString() ?? '')
              : null,
          auditDate:  audit?['tanggal_audit']?.toString(),
        );
      }).toList()
        ..sort((a, b) {
          if (a.auditScore == null && b.auditScore == null) return 0;
          if (a.auditScore == null) return 1;
          if (b.auditScore == null) return -1;
          return b.auditScore!.compareTo(a.auditScore!);
        });
    } catch (e) {
      debugPrint('Error fetching audit monthly: $e');
      return [];
    }
  }

  Future<List<_ChartBarData>> _fetchChartAuditMonthly(
      int month, int year, String level) async {
    try {
      final daysInMonth  = DateUtils.getDaysInMonth(year, month);
      final levelLower   = level.toLowerCase();
      final startOfMonth = DateTime(year, month, 1).toIso8601String().split('T').first;
      final endOfMonth   = DateTime(year, month + 1, 0).toIso8601String().split('T').first;

      final List<dynamic> auditRes = await _supabase
          .from('audit_result')
          .select('tanggal_audit, nilai_audit')
          .eq('level_type', levelLower)
          .gte('tanggal_audit', startOfMonth)
          .lte('tanggal_audit', endOfMonth);

      final Map<int, List<double>> dayScores = {};
      for (final a in auditRes) {
        final dt    = DateTime.tryParse(a['tanggal_audit']?.toString() ?? '');
        final score = double.tryParse(a['nilai_audit']?.toString() ?? '');
        if (dt == null || score == null) continue;
        dayScores.putIfAbsent(dt.day, () => []).add(score);
      }
      return List.generate(daysInMonth, (i) {
        final day    = i + 1;
        final scores = dayScores[day] ?? [];
        final avg    = scores.isEmpty
            ? 0.0
            : scores.reduce((a, b) => a + b) / scores.length;
        return _ChartBarData(date: day, temuan: 0, auditScore: avg);
      });
    } catch (e) {
      debugPrint('Error fetching chart audit monthly: $e');
      return [];
    }
  }

  Future<List<_ChartBarData>> _fetchChartDaily(
      DateTime date, String level) async {
    try {
      final start      = DateTime(date.year, date.month, date.day);
      final end        = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final levelLower = level.toLowerCase();
      final idCol      = _idColFor(levelLower);

      final List<dynamic> res = await _supabase
          .from('temuan')
          .select('created_at, $idCol')
          .neq('jenis_temuan', 'KTS Production')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .not(idCol, 'is', null);

      return [_ChartBarData(date: date.day, temuan: res.length)];
    } catch (e) {
      debugPrint('Error fetching chart daily: $e');
      return [];
    }
  }

  String _idColFor(String level) {
    switch (level) {
      case 'unit':    return 'id_unit';
      case 'subunit': return 'id_subunit';
      case 'area':    return 'id_area';
      default:        return 'id_lokasi';
    }
  }

  String _nameColFor(String level) {
    switch (level) {
      case 'unit':    return 'nama_unit';
      case 'subunit': return 'nama_subunit';
      case 'area':    return 'nama_area';
      default:        return 'nama_lokasi';
    }
  }

  String get _lastUpdatedText {
    if (_lastUpdated == null) return _t('memuat_data');
    final fmt = DateFormat('d MMM yyyy HH:mm',
        widget.lang == 'ID' ? 'id_ID' : 'en_US').format(_lastUpdated!);
    return '${_t('diperbarui_pada')} $fmt (GMT+7)';
  }

  String get _periodLabel {
    final locale = widget.lang == 'ID' ? 'id_ID'
        : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    if (_filterMode == 'daily' && _selectedDate != null) {
      return DateFormat('d MMM yyyy', locale).format(_selectedDate!);
    }
    return DateFormat('MMMM yyyy', locale)
        .format(DateTime(DateTime.now().year, _selectedMonthIndex + 1));
  }

  Color _scoreColor(double? s) {
    if (s == null) return _AppColors.textMuted;
    if (s >= 80) return const Color(0xFF10B981);
    if (s >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // FILTER ROW
      Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          _filterBtn(label: _periodLabel, isActive: true, onTap: _showMonthPicker),
          const SizedBox(width: 10),
          Expanded(child: _filterBtn(
            label: _selectedLevelLabel,
            onTap: _showLevelPicker,
          )),
        ]),
      ),

      // LAST UPDATED
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(_lastUpdatedText,
              style: const TextStyle(
                  fontSize: 11, color: _AppColors.textSecondary, height: 1.4)),
        ),
      ),

      _buildCollapsibleChart(),

      _buildTableHeader(),

      Expanded(child: _useAuditMode ? _buildAuditList() : _buildDailyList()),
    ]);
  }

  Widget _buildCollapsibleChart() {
    const activeColor = _AppColors.primary;

    return Column(children: [
      GestureDetector(
        onTap: () => setState(() => _isChartExpanded = !_isChartExpanded),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 2, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: activeColor.withValues(alpha:0.4), width: 1.2),
            boxShadow: [BoxShadow(
                color: activeColor.withValues(alpha:0.08),
                blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            const Icon(Icons.bar_chart_rounded, size: 16, color: activeColor),
            const SizedBox(width: 8),
            Expanded(child: Text(
              widget.lang == 'ID' ? 'Grafik $_periodLabel'
                  : widget.lang == 'ZH' ? '$_periodLabel 图表'
                  : 'Chart $_periodLabel',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: activeColor),
            )),
            AnimatedRotation(
              turns: _isChartExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              child: const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 20, color: activeColor),
            ),
          ]),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: _isChartExpanded
            ? FutureBuilder<List<_ChartBarData>>(
                key: ValueKey('chart-location-$_chartRefreshKey'),
                future: _chartFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      height: 160,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: CircularProgressIndicator(
                          color: activeColor, strokeWidth: 2)),
                    );
                  }

                  final data   = snapshot.data ?? [];
                  final target = _currentTarget;

                  int maxVal = target;
                  if (_useAuditMode) {
                    maxVal = math.max(maxVal, 100);
                    for (final d in data) {
                      if (d.auditScore.round() > maxVal) maxVal = d.auditScore.round();
                    }
                  } else {
                    for (final d in data) {
                      if (d.temuan > maxVal) maxVal = d.temuan;
                    }
                  }
                  maxVal = ((math.max(maxVal, 5) / 5).ceil() * 5).clamp(5, 9999);

                  const double chartH    = 140.0;
                  const double barGroupW = 22.0;
                  const double barW      = 12.0;
                  const double leftW     = 36.0;

                  double valToY(num v) =>
                      chartH - (v / maxVal * chartH).clamp(0.0, chartH);

                  final yStep   = (maxVal / 4).ceil().clamp(1, 99999);
                  final yLabels = List.generate(5, (i) => i * yStep);

                  final locale = widget.lang == 'ID' ? 'id_ID'
                      : widget.lang == 'EN' ? 'en_US' : 'zh_CN';

                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.fromLTRB(0, 12, 8, 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _AppColors.primaryLight),
                      boxShadow: [BoxShadow(
                          color: activeColor.withValues(alpha:0.06),
                          blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // LEGEND
                      Padding(
                        padding: EdgeInsets.only(left: leftW + 4, bottom: 8),
                        child: Wrap(spacing: 12, children: [
                          _legendItem(activeColor,
                              _useAuditMode
                                  ? (widget.lang == 'ID' ? 'Rata-rata Nilai Audit'
                                      : widget.lang == 'ZH' ? '平均审计分数' : 'Avg Audit Score')
                                  : (widget.lang == 'ID' ? 'Temuan' : 'Findings')),
                          if (target > 0)
                            _legendDash(const Color(0xFFEF4444),
                                widget.lang == 'ID' ? 'Target Lokasi'
                                    : widget.lang == 'ZH' ? '位置目标' : 'Location Target'),
                        ]),
                      ),

                      // CHART AREA
                      SizedBox(
                        height: chartH + 28,
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          // Y-AXIS
                          SizedBox(
                            width: leftW, height: chartH,
                            child: Stack(clipBehavior: Clip.none, children: yLabels.map((v) {
                              final yPos = valToY(v);
                              if (yPos < 0 || yPos > chartH) return const SizedBox.shrink();
                              return Positioned(
                                top: yPos - 7, right: 4, left: 0,
                                child: Text(
                                  v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '$v',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 9, fontWeight: FontWeight.w600,
                                      color: _AppColors.textSecondary),
                                ),
                              );
                            }).toList()),
                          ),

                          // PLOT AREA
                          Expanded(child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: math.max(data.length * barGroupW + 8, 40),
                              child: Stack(children: [
                                // GRID LINES
                                ...yLabels.map((v) => Positioned(
                                  top: valToY(v), left: 0, right: 0,
                                  child: Container(height: 1, color: _AppColors.divider),
                                )),

                                // TARGET LINE DAILY ONLY
                                if (target > 0)
                                  Positioned(top: valToY(target), left: 0, right: 0,
                                    child: CustomPaint(
                                      painter: _DashedLinePainter(const Color(0xFFEF4444)),
                                      child: const SizedBox(height: 2))),

                                // BARS
                                ...data.asMap().entries.map((entry) {
                                  final i   = entry.key;
                                  final d   = entry.value;
                                  final x   = i * barGroupW + 4.0;
                                  final val = _useAuditMode ? d.auditScore : d.temuan.toDouble();
                                  final barH = (val / maxVal * chartH).clamp(0.0, chartH);
                                  final barColor = _useAuditMode
                                      ? _scoreColor(d.auditScore > 0 ? d.auditScore : null)
                                      : activeColor;
                                  final dateLabel = _filterMode == 'daily' && _selectedDate != null
                                      ? DateFormat('d/M', locale).format(_selectedDate!)
                                      : DateFormat('d/M', locale).format(DateTime(
                                          DateTime.now().year, _selectedMonthIndex + 1, d.date));

                                  return Positioned(
                                    left: x, top: 0,
                                    child: SizedBox(
                                      width: barGroupW, height: chartH + 28,
                                      child: Column(children: [
                                        SizedBox(height: chartH, child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(width: barW, height: barH,
                                              decoration: BoxDecoration(
                                                color: barColor,
                                                borderRadius: const BorderRadius.vertical(
                                                    top: Radius.circular(3)))),
                                          ],
                                        )),
                                        const SizedBox(height: 3),
                                        Text(dateLabel, style: const TextStyle(
                                            fontSize: 7.5,
                                            color: _AppColors.textSecondary,
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

  Widget _legendItem(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 10, color: _AppColors.textSecondary)),
  ]);

  Widget _legendDash(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    SizedBox(width: 14, child: CustomPaint(
        painter: _DashedLinePainter(color), child: const SizedBox(height: 2))),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 10, color: _AppColors.textSecondary)),
  ]);

  Widget _buildTableHeader() {
    final col3 = _useAuditMode ? _t('nilai') : _t('temuan');
    return Container(
      color: const Color(0xFFF8FAFF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        SizedBox(width: 40, child: Text(_t('rank'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                color: _AppColors.textSecondary, letterSpacing: 0.2))),
        Expanded(flex: 3, child: Text(_t('lokasi'),
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                color: _AppColors.textSecondary, letterSpacing: 0.2))),
        SizedBox(width: 70, child: Text(col3,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                color: _AppColors.textSecondary, letterSpacing: 0.2))),
      ]),
    );
  }

  Widget _buildAuditList() {
    if (_auditFuture == null) return _buildShimmer();
    return FutureBuilder<List<AuditLocationData5R>>(
      future: _auditFuture,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) return _buildShimmer();
        final data = snap.data ?? [];
        if (data.isEmpty) {
          return Center(child: Text(
              '${_t('tidak_ada_data_level')} "$_selectedLevelLabel".',
              style: const TextStyle(color: _AppColors.textSecondary)));
        }
        return RefreshIndicator(
          onRefresh: () async => _fetchAllData(),
          color: _AppColors.primary,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: data.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: _AppColors.divider, indent: 16),
            itemBuilder: (_, i) => _buildAuditRow(i + 1, data[i]),
          ),
        );
      },
    );
  }

  Widget _buildDailyList() {
    if (_lokasiFuture == null) return _buildShimmer();
    return FutureBuilder<List<LocationData5R>>(
      future: _lokasiFuture,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) return _buildShimmer();
        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return Center(child: Text(
              '${_t('tidak_ada_data_level')} "$_selectedLevelLabel".',
              style: const TextStyle(color: _AppColors.textSecondary)));
        }
        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: snap.data!.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: _AppColors.divider, indent: 16),
          itemBuilder: (_, i) => _buildLocationRow(i + 1, snap.data![i]),
        );
      },
    );
  }

  Widget _buildAuditRow(int rank, AuditLocationData5R loc) {
    final score      = loc.auditScore;
    final scoreColor = _scoreColor(score);

    return GestureDetector(
      onTap: () => _showAuditDetail(loc),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          SizedBox(width: 40, child: rank <= 3
              ? Text(['🥇', '🥈', '🥉'][rank - 1],
                  style: const TextStyle(fontSize: 20))
              : Text('$rank',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, color: _AppColors.textSecondary))),
          Expanded(flex: 3, child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.location_city_rounded,
                  color: scoreColor, size: 20)),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(loc.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: _AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis),
              Text(loc.pic,
                  style: const TextStyle(
                      fontSize: 11.5, color: _AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis),
              if (loc.auditDate != null) ...[
                const SizedBox(height: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: score != null ? score / 100 : 0,
                    backgroundColor: scoreColor.withValues(alpha:0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    minHeight: 4)),
              ],
            ])),
          ])),
          SizedBox(width: 70, child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(score != null ? '${score.toStringAsFixed(0)}%' : '-',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                      color: scoreColor)),
              if (loc.auditDate != null)
                Text(loc.auditDate!.substring(0, 10),
                    style: const TextStyle(
                        fontSize: 9, color: _AppColors.textSecondary)),
            ],
          )),
        ]),
      ),
    );
  }

  Widget _buildLocationRow(int rank, LocationData5R loc) {
    final count      = int.tryParse(loc.value ?? '0') ?? 0;
    final valueColor = count > 0 ? _AppColors.primaryDark : _AppColors.textMuted;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        SizedBox(width: 40, child: Text('$rank',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13,
                color: _AppColors.textSecondary, fontWeight: FontWeight.w500))),
        Expanded(flex: 3, child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: _AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.location_city_rounded,
                color: _AppColors.primary, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(loc.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: _AppColors.textPrimary),
                overflow: TextOverflow.ellipsis),
            Text(loc.pic,
                style: const TextStyle(
                    fontSize: 11.5, color: _AppColors.textSecondary),
                overflow: TextOverflow.ellipsis),
          ])),
        ])),
        SizedBox(width: 70, child: Text(loc.value ?? '0',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: valueColor))),
      ]),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: 8,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: _AppColors.divider, indent: 16),
        itemBuilder: (_, __) => Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            SizedBox(width: 40, child: Center(child: _shimBox(height: 14, width: 20))),
            Expanded(flex: 3, child: Row(children: [
              _shimBox(height: 38, width: 38, borderRadius: 10),
              const SizedBox(width: 10),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                _shimBox(height: 14, width: double.infinity),
                const SizedBox(height: 4),
                _shimBox(height: 12, width: 100),
              ])),
            ])),
            SizedBox(width: 70, child: Center(child: _shimBox(height: 14, width: 30))),
          ]),
        ),
      ),
    );
  }

  Widget _shimBox({double? width, required double height,
      bool isCircle = false, double borderRadius = 8}) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCircle ? height / 2 : borderRadius)),
    );
  }

  // FILTER BUTTON
  Widget _filterBtn({
    required String label,
    required VoidCallback onTap,
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
              color: _AppColors.primary.withValues(alpha:0.10),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(child: Text(label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : _AppColors.primary),
            overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded,
              color: isActive ? Colors.white : _AppColors.primary, size: 18),
        ]),
      ),
    );
  }

  // MONTH PICKER
  void _showMonthPicker() async {
    String   tempMode = _filterMode;
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
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _AppColors.primaryLight, width: 1.5)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                decoration: const BoxDecoration(
                  color: _AppColors.primaryLight,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                child: Row(children: [
                  const Icon(Icons.calendar_month_rounded,
                      color: _AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_t('pilih_bulan'),
                      style: const TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 15, color: _AppColors.textPrimary))),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18,
                        color: _AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: _AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _AppColors.primaryLight)),
                  padding: const EdgeInsets.all(4),
                  child: Row(children: ['monthly', 'daily'].map((mode) {
                    final isSel = tempMode == mode;
                    final lbl = mode == 'monthly'
                        ? (widget.lang == 'ID' ? 'Bulanan'
                            : widget.lang == 'ZH' ? '按月' : 'Monthly')
                        : (widget.lang == 'ID' ? 'Harian'
                            : widget.lang == 'ZH' ? '按日' : 'Daily');
                    return Expanded(child: GestureDetector(
                      onTap: () => setSt(() => tempMode = mode),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSel ? _AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(9)),
                        child: Center(child: Text(lbl, style: TextStyle(
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
                        crossAxisCount: 3, crossAxisSpacing: 10,
                        mainAxisSpacing: 10, childAspectRatio: 2.2),
                    itemCount: 12,
                    itemBuilder: (_, i) {
                      final isSel = i == _selectedMonthIndex;
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _filterMode         = 'monthly';
                            _selectedMonthIndex = i;
                            _selectedDate       = null;
                          });
                          _fetchTarget().then((_) => _fetchAllData());
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
                              color: _AppColors.primary.withValues(alpha:0.3),
                              blurRadius: 6, offset: const Offset(0, 2))] : []),
                          child: Center(child: Text(_translatedMonths[i],
                              style: TextStyle(
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
                  child: _buildDailyCalendar(tempDate,
                    (picked) => setSt(() => tempDate = picked),
                    onConfirm: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _filterMode         = 'daily';
                        _selectedDate       = tempDate;
                        _selectedMonthIndex = tempDate.month - 1;
                      });
                      _fetchTarget().then((_) => _fetchAllData());
                    },
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyCalendar(DateTime selectedDate,
      ValueChanged<DateTime> onDateChanged, {required VoidCallback onConfirm}) {
    final now          = DateTime.now();
    final year         = now.year;
    final month        = now.month;
    final daysInMonth  = DateUtils.getDaysInMonth(year, month);
    final firstWeekday = DateTime(year, month, 1).weekday % 7;
    final locale       = widget.lang == 'ID' ? 'id_ID'
        : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    final monthLabel   = DateFormat('MMMM yyyy', locale).format(DateTime(year, month));
    final dayLabels    = widget.lang == 'ZH'
        ? ['日', '一', '二', '三', '四', '五', '六']
        : widget.lang == 'ID'
            ? ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
            : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return StatefulBuilder(builder: (_, setInner) => Column(children: [
      Text(monthLabel, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: _AppColors.textPrimary)),
      const SizedBox(height: 10),
      Row(children: dayLabels.map((d) => Expanded(child: Center(
        child: Text(d, style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600,
            color: _AppColors.textSecondary))))).toList()),
      const SizedBox(height: 6),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, crossAxisSpacing: 4,
            mainAxisSpacing: 4, childAspectRatio: 1),
        itemCount: firstWeekday + daysInMonth,
        itemBuilder: (_, i) {
          if (i < firstWeekday) return const SizedBox();
          final day  = i - firstWeekday + 1;
          final date = DateTime(year, month, day);
          final isSelected = selectedDate.year == date.year &&
              selectedDate.month == date.month &&
              selectedDate.day == date.day;
          final isToday  = now.year == date.year && now.month == date.month && now.day == date.day;
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
          child: Text(_t('terapkan'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ),
    ]));
  }

  // LEVEL PICKER
  void _showLevelPicker() async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5),
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
                const Icon(Icons.tune_rounded, color: _AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(_t('pilih_level'),
                    style: const TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 15, color: _AppColors.textPrimary))),
                IconButton(
                  icon: const Icon(Icons.close, size: 18,
                      color: _AppColors.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                  padding: EdgeInsets.zero),
              ]),
            ),
            Flexible(child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: _levelsBackend.length,
              itemBuilder: (_, i) {
                final backend  = _levelsBackend[i];
                final label    = _translatedLevels[i];
                final isSel    = _selectedLevelBackend == backend;
                return InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _selectedLevelBackend = backend);
                    _fetchTarget().then((_) => _fetchAllData());
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? _AppColors.primaryLight : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSel ? _AppColors.primary : _AppColors.divider,
                        width: 1)),
                    child: Row(children: [
                      Expanded(child: Text(label, style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        color: isSel ? _AppColors.primary : _AppColors.textPrimary))),
                      if (isSel)
                        const Icon(Icons.check_circle_rounded,
                            color: _AppColors.primary, size: 16),
                    ]),
                  ),
                );
              },
            )),
          ]),
        ),
      ),
    );
  }

  // AUDIT DETAIL
  void _showAuditDetail(AuditLocationData5R loc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AuditDetailSheet(
        lang: widget.lang,
        loc: loc,
        levelType: _selectedLevelBackend.toLowerCase(),
        scoreColor: _scoreColor,
        belumAdaAudit: _t('belum_ada_audit'),
      ),
    );
  }
}

class _AuditDetailSheet extends StatefulWidget {
  final String lang;
  final AuditLocationData5R loc;
  final String levelType;
  final Color Function(double?) scoreColor;
  final String belumAdaAudit;

  const _AuditDetailSheet({
    required this.lang,
    required this.loc,
    required this.levelType,
    required this.scoreColor,
    required this.belumAdaAudit,
  });

  @override
  State<_AuditDetailSheet> createState() => _AuditDetailSheetState();
}

class _AuditDetailSheetState extends State<_AuditDetailSheet> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final rows = await _supabase
          .from('audit_result')
          .select('id_result, nilai_audit, tanggal_audit, catatan_audit, id_auditor')
          .eq('level_type', widget.levelType)
          .eq('id_ref', widget.loc.id)
          .order('tanggal_audit', ascending: false)
          .limit(15);

      final auditorIds = List<Map<String, dynamic>>.from(rows)
          .where((r) => r['id_auditor'] != null)
          .map((r) => r['id_auditor'].toString())
          .toSet()
          .toList();
      final Map<String, String> auditorMap = {};
      if (auditorIds.isNotEmpty) {
        final aRows = await _supabase
            .from('User')
            .select('id_user, nama')
            .inFilter('id_user', auditorIds);
        for (final a in List<Map<String, dynamic>>.from(aRows)) {
          auditorMap[a['id_user'].toString()] = a['nama']?.toString() ?? '-';
        }
      }

      final allIds = List<Map<String, dynamic>>.from(rows)
          .map((r) => r['id_result'].toString())
          .toList();
      final Map<String, List<Map<String, dynamic>>> answersMap = {};
      if (allIds.isNotEmpty) {
        final allAnswers = await _supabase
            .from('audit_answer')
            .select('id_result, jawaban, id_question')
            .inFilter('id_result', allIds)
            .order('created_at');

        final questionIds = List<Map<String, dynamic>>.from(allAnswers)
            .map((a) => a['id_question'].toString())
            .toSet()
            .toList();
        final Map<String, String> questionMap = {};
        if (questionIds.isNotEmpty) {
          final qRows = await _supabase
              .from('audit_question')
              .select('id_question, pertanyaan')
              .inFilter('id_question', questionIds);
          for (final q in List<Map<String, dynamic>>.from(qRows)) {
            questionMap[q['id_question'].toString()] =
                q['pertanyaan']?.toString() ?? '-';
          }
        }
        for (final a in List<Map<String, dynamic>>.from(allAnswers)) {
          final resultId = a['id_result'].toString();
          answersMap.putIfAbsent(resultId, () => []);
          answersMap[resultId]!.add({
            'jawaban': a['jawaban'],
            'audit_question': {
              'pertanyaan': questionMap[a['id_question']?.toString() ?? ''] ?? '-',
            },
          });
        }
      }

      final result = <Map<String, dynamic>>[];
      for (final row in List<Map<String, dynamic>>.from(rows)) {
        final resultId = row['id_result'].toString();
        result.add({
          ...row,
          'auditorName': auditorMap[row['id_auditor']?.toString() ?? ''] ?? '-',
          'answers':     answersMap[resultId] ?? [],
        });
      }
      if (mounted) setState(() { _history = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Row(children: [
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.loc.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A8A))),
                Text(widget.loc.pic,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ])),
              if (widget.loc.auditScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: widget.scoreColor(widget.loc.auditScore).withValues(alpha:0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('${widget.loc.auditScore!.toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                          color: widget.scoreColor(widget.loc.auditScore))),
                ),
            ]),
          ),
          const Divider(height: 1),
          Expanded(child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)))
              : _history.isEmpty
                  ? Center(child: Text(widget.belumAdaAudit,
                        style: const TextStyle(color: Color(0xFF64748B))))
                  : ListView.separated(
                      controller: ctrl,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final h        = _history[i];
                        final score    = double.tryParse(h['nilai_audit']?.toString() ?? '');
                        final auditor  = h['auditorName'] as String? ?? '-';
                        final date     = h['tanggal_audit']?.toString() ?? '';
                        final catatan  = h['catatan_audit'] as String?;
                        final answers  = h['answers'] as List<Map<String, dynamic>>? ?? [];
                        final color    = widget.scoreColor(score);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: color.withValues(alpha:0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: color.withValues(alpha:0.3))),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Row(children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                    color: color.withValues(alpha:0.12),
                                    shape: BoxShape.circle),
                                child: Center(child: Text(
                                    score != null
                                        ? '${score.toStringAsFixed(0)}%' : '-',
                                    style: TextStyle(fontSize: 11,
                                        fontWeight: FontWeight.w800, color: color)))),
                              const SizedBox(width: 10),
                              Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(auditor,
                                    style: const TextStyle(fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E3A8A))),
                                Text(date,
                                    style: const TextStyle(fontSize: 11,
                                        color: Color(0xFF64748B))),
                                if (catatan != null && catatan.isNotEmpty)
                                  Text(catatan,
                                      style: const TextStyle(fontSize: 11,
                                          color: Color(0xFF64748B)),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                              ])),
                            ]),
                            if (answers.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 6),
                              ...answers.map((a) {
                                final jawaban   = a['jawaban'] as bool? ?? false;
                                final pertanyaan =
                                    (a['audit_question'] as Map<String, dynamic>?)?
                                        ['pertanyaan'] ?? '-';
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(children: [
                                    Icon(
                                      jawaban
                                          ? Icons.check_circle_rounded
                                          : Icons.cancel_rounded,
                                      size: 14,
                                      color: jawaban
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444)),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(pertanyaan,
                                        style: const TextStyle(
                                            fontSize: 11.5, color: Color(0xFF334155)))),
                                  ]),
                                );
                              }),
                            ],
                          ]),
                        );
                      },
                    )),
        ]),
      ),
    );
  }
}