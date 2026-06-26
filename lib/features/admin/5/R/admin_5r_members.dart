import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

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

class MemberData5R {
  final String  name;
  final String? unitName;
  final int     findings;
  final int     completed;
  final bool    isSelf;
  final String? avatarUrl;
  final Color?  avatarColor;

  const MemberData5R({
    required this.name,
    this.unitName,
    required this.findings,
    required this.completed,
    this.isSelf      = false,
    this.avatarUrl,
    this.avatarColor,
  });
}

class _ChartBarData {
  final int date;
  final int temuan;
  final int penyelesaian;
  _ChartBarData({required this.date, required this.temuan, required this.penyelesaian});
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

class _Avatar5R extends StatelessWidget {
  final String  name;
  final Color?  color;
  final double  size;
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
        color: bg..withValues(alpha:0.15),
        shape: BoxShape.circle,
        border: Border.all(color: bg..withValues(alpha:0.3), width: 1),
      ),
      child: Center(child: Text(initials,
          style: TextStyle(
              fontSize: size * 0.35,
              fontWeight: FontWeight.w700,
              color: bg))),
    );
  }
}

class Admin5RMembersTab extends StatefulWidget {
  final String lang;

  const Admin5RMembersTab({super.key, required this.lang});

  @override
  State<Admin5RMembersTab> createState() => Admin5RMembersTabState();
}

class Admin5RMembersTabState extends State<Admin5RMembersTab> {
  final _supabase = Supabase.instance.client;

  static const Map<String, Map<String, String>> _texts = {
    'ID': {
      'anggota': 'Anggota', 'memuat_data': 'Memuat data...',
      'diperbarui_pada': 'Terakhir diperbarui pada',
      'semua_grup_anggota': 'Semua Grup',
      'tidak_ada_data_anggota': 'Tidak ada data anggota.',
      'nama': 'Nama', 'temuan': 'Temuan', 'selesai': 'Selesai',
      'target_bulanan': 'Target Bulanan', 'saya': 'Saya',
      'pilih_bulan': 'Pilih Bulan', 'pilih_grup': 'Pilih Grup',
      'cari': 'Cari...', 'terapkan': 'Terapkan',
    },
    'EN': {
      'anggota': 'Members', 'memuat_data': 'Loading data...',
      'diperbarui_pada': 'Last updated at',
      'semua_grup_anggota': 'All Groups',
      'tidak_ada_data_anggota': 'No member data available.',
      'nama': 'Name', 'temuan': 'Findings', 'selesai': 'Completed',
      'target_bulanan': 'Monthly Target', 'saya': 'Me',
      'pilih_bulan': 'Select Month', 'pilih_grup': 'Select Group',
      'cari': 'Search...', 'terapkan': 'Apply',
    },
    'ZH': {
      'anggota': '成员', 'memuat_data': '加载数据...',
      'diperbarui_pada': '最后更新于',
      'semua_grup_anggota': '所有组',
      'tidak_ada_data_anggota': '没有成员数据。',
      'nama': '名称', 'temuan': '发现', 'selesai': '已完成',
      'target_bulanan': '每月目标', 'saya': '我',
      'pilih_bulan': '选择月份', 'pilih_grup': '选择组',
      'cari': '搜索...', 'terapkan': '应用',
    },
  };

  String _t(String key) => _texts[widget.lang]?[key] ?? key;

  // FILTER STATE
  int           _selectedMonthIndex = DateTime.now().month - 1;
  String        _filterMode         = 'monthly';
  DateTime?     _selectedDate;
  String?       _selectedUnitId;
  DateTime?     _lastUpdated;
  List<Map<String, dynamic>> _unitList = [];

  // TARGET
  int _targetAnggota        = 2;
  int _targetAnggotaSelesai = 2;

  // CHART STATE
  bool                        _isChartExpanded = false;
  Future<List<_ChartBarData>>? _chartFuture;
  int                         _chartRefreshKey = 0;

  // MEMBER FUTURE
  Future<List<MemberData5R>>? _membersFuture;

  // TRANSLATED MONTH
  late List<String> _translatedMonths;

  @override
  void initState() {
    super.initState();
    _initMonths();
    _fetchUnits().then((_) {
      _fetchTarget();
      _fetchAllData();
    });
  }

  void _initMonths() {
    final locale = widget.lang == 'ID' ? 'id_ID'
        : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    _translatedMonths = List.generate(
        12, (i) => DateFormat.MMM(locale).format(DateTime(2000, i + 1)));
  }

  Future<void> _fetchUnits() async {
    try {
      final res = await _supabase.from('unit').select('id_unit, nama_unit');
      if (mounted) setState(() => _unitList = List<Map<String, dynamic>>.from(res));
    } catch (e) {
      debugPrint('Error fetching units: $e');
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
        _targetAnggota        = data?['target_anggota']         ?? 2;
        _targetAnggotaSelesai = data?['target_anggota_selesai'] ?? 2;
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
        if (mounted) setState(() { _targetAnggota = 0; _targetAnggotaSelesai = 0; });
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
        if (mounted) setState(() { _targetAnggota = 0; _targetAnggotaSelesai = 0; });
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
            _targetAnggota        = daily.first['target_anggota']         ?? 2;
            _targetAnggotaSelesai = daily.first['target_anggota_selesai'] ?? 2;
          });
          return;
        }
      }
      await _fetchTargetMonthly(date.month, date.year);
    } catch (e) {
      debugPrint('Error fetching daily target: $e');
    }
  }

  void _fetchAllData() {
    final month = _selectedMonthIndex + 1;
    final year  = DateTime.now().year;

    setState(() {
      _lastUpdated = DateTime.now();
      if (_filterMode == 'daily' && _selectedDate != null) {
        _membersFuture = _fetchMembersDaily(_selectedDate!);
        _chartFuture   = _fetchChartDataDaily(_selectedDate!);
      } else {
        _membersFuture = _fetchMembersMonthly(month, year);
        _chartFuture   = _fetchChartDataMonthly(month, year);
      }
      _chartRefreshKey++;
    });
  }

  Future<List<MemberData5R>> _fetchMembersMonthly(int month, int year) async {
    try {
      var q = _supabase.from('User')
          .select('id_user, nama, gambar_user, id_unit, unit!user_id_unit_fkey(nama_unit)');
      if (_selectedUnitId != null) q = q.eq('id_unit', _selectedUnitId!);
      final List<dynamic> users = await q;
      if (users.isEmpty) return [];

      final userIds = users.map((u) => u['id_user'].toString()).toList();
      final List<dynamic> temuanRes = await _supabase
          .from('temuan')
          .select('id_user, id_penyelesaian')
          .neq('jenis_temuan', 'KTS Production')
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at', DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String())
          .inFilter('id_user', userIds);

      return _buildMemberList(users, temuanRes);
    } catch (e) {
      debugPrint('Error fetching members monthly: $e');
      return [];
    }
  }

  Future<List<MemberData5R>> _fetchMembersDaily(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end   = DateTime(date.year, date.month, date.day, 23, 59, 59);

      var q = _supabase.from('User')
          .select('id_user, nama, gambar_user, id_unit, unit!user_id_unit_fkey(nama_unit)');
      if (_selectedUnitId != null) q = q.eq('id_unit', _selectedUnitId!);
      final List<dynamic> users = await q;
      if (users.isEmpty) return [];

      final userIds = users.map((u) => u['id_user'].toString()).toList();
      final List<dynamic> temuanRes = await _supabase
          .from('temuan')
          .select('id_user, id_penyelesaian')
          .neq('jenis_temuan', 'KTS Production')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .inFilter('id_user', userIds);

      return _buildMemberList(users, temuanRes);
    } catch (e) {
      debugPrint('Error fetching members daily: $e');
      return [];
    }
  }

  List<MemberData5R> _buildMemberList(
      List<dynamic> users, List<dynamic> temuanRes) {
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
      final s   = stats[uid] ?? {'temuan': 0, 'selesai': 0};
      return MemberData5R(
        name:       u['nama'] as String? ?? '-',
        unitName:   (u['unit'] as Map<String, dynamic>?)?['nama_unit'] as String?,
        findings:   s['temuan']!,
        completed:  s['selesai']!,
        isSelf:     uid == currentUserId,
        avatarUrl:  u['gambar_user'] as String?,
        avatarColor: const Color(0xFF0EA5E9),
      );
    }).toList()
      ..sort((a, b) {
        final c = b.findings.compareTo(a.findings);
        return c != 0 ? c : a.name.compareTo(b.name);
      });
  }

  Future<List<_ChartBarData>> _fetchChartDataMonthly(int month, int year) async {
    try {
      final daysInMonth = DateUtils.getDaysInMonth(year, month);
      var q = _supabase
          .from('temuan')
          .select('created_at, id_penyelesaian, id_user')
          .neq('jenis_temuan', 'KTS Production')
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at', DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String());

      if (_selectedUnitId != null) {
        final List<dynamic> usersInUnit = await _supabase
            .from('User').select('id_user').eq('id_unit', _selectedUnitId!);
        final ids = usersInUnit.map((u) => u['id_user'].toString()).toList();
        if (ids.isEmpty) {
          return List.generate(daysInMonth,
              (i) => _ChartBarData(date: i + 1, temuan: 0, penyelesaian: 0));
        }
        q = q.inFilter('id_user', ids);
      }

      final List<dynamic> res = await q;
      final Map<int, int> temuanMap = {}, selesaiMap = {};
      for (final t in res) {
        final dt = DateTime.tryParse(t['created_at']?.toString() ?? '');
        if (dt == null) continue;
        temuanMap[dt.day]  = (temuanMap[dt.day]  ?? 0) + 1;
        if (t['id_penyelesaian'] != null) {
          selesaiMap[dt.day] = (selesaiMap[dt.day] ?? 0) + 1;
        }
      }
      return List.generate(daysInMonth, (i) => _ChartBarData(
          date: i + 1,
          temuan: temuanMap[i + 1] ?? 0,
          penyelesaian: selesaiMap[i + 1] ?? 0));
    } catch (e) {
      debugPrint('Error fetching chart monthly: $e');
      return [];
    }
  }

  Future<List<_ChartBarData>> _fetchChartDataDaily(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end   = DateTime(date.year, date.month, date.day, 23, 59, 59);
      var q = _supabase
          .from('temuan')
          .select('created_at, id_penyelesaian, id_user')
          .neq('jenis_temuan', 'KTS Production')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());

      if (_selectedUnitId != null) {
        final List<dynamic> usersInUnit = await _supabase
            .from('User').select('id_user').eq('id_unit', _selectedUnitId!);
        final ids = usersInUnit.map((u) => u['id_user'].toString()).toList();
        if (ids.isEmpty) {
          return [_ChartBarData(date: date.day, temuan: 0, penyelesaian: 0)];
        }
        q = q.inFilter('id_user', ids);
      }

      final List<dynamic> res = await q;
      return [_ChartBarData(
        date:         date.day,
        temuan:       res.length,
        penyelesaian: res.where((t) => t['id_penyelesaian'] != null).length,
      )];
    } catch (e) {
      debugPrint('Error fetching chart daily: $e');
      return [];
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

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // FILTER ROW
      Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          _filterBtn(
            label: _periodLabel,
            isActive: true,
            onTap: _showMonthPicker,
          ),
          const SizedBox(width: 10),
          Expanded(child: _filterBtn(
            label: _selectedUnitId == null
                ? _t('semua_grup_anggota')
                : (_unitList.firstWhere(
                        (u) => u['id_unit'].toString() == _selectedUnitId,
                        orElse: () => {'nama_unit': _t('semua_grup_anggota')})
                    ['nama_unit'] as String),
            onTap: _showGroupPicker,
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

      // COLLAPSIBLE CHART
      _buildCollapsibleChart(),

      // TABLE HEADER
      _buildTableHeader(),

      // TARGET ROW
      _buildTargetRow(),

      // MEMBER LIST
      Expanded(child: _membersFuture == null
          ? _buildShimmer()
          : FutureBuilder<List<MemberData5R>>(
              future: _membersFuture,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return _buildShimmer();
                }
                if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
                  return Center(child: Text(_t('tidak_ada_data_anggota')));
                }
                final list = snap.data!;
                final self = list.firstWhere(
                  (m) => m.isSelf,
                  orElse: () => MemberData5R(
                    name:      _t('saya'),
                    findings:  0,
                    completed: 0,
                    isSelf:    true,
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

  Widget _buildCollapsibleChart() {
    const activeColor = _AppColors.primary;
    const colorTemuan      = activeColor;
    const colorPenyelesaian = Color(0xFF10B981);

    return Column(children: [
      GestureDetector(
        onTap: () => setState(() => _isChartExpanded = !_isChartExpanded),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 2, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: activeColor..withValues(alpha:0.4), width: 1.2),
            boxShadow: [BoxShadow(
                color: activeColor..withValues(alpha:0.08), blurRadius: 6,
                offset: const Offset(0, 2))],
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
                key: ValueKey('chart-members-$_chartRefreshKey'),
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
                          color: _AppColors.primary, strokeWidth: 2)),
                    );
                  }

                  final data = snapshot.data ?? [];
                  final tTarget = _targetAnggota;
                  final pTarget = _targetAnggotaSelesai;

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

                  double valToY(int v) =>
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
                          color: activeColor..withValues(alpha:0.06),
                          blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // LEGEND
                      Padding(
                        padding: EdgeInsets.only(left: leftW + 4, bottom: 8),
                        child: Wrap(spacing: 12, children: [
                          _legendItem(colorTemuan,
                              widget.lang == 'ID' ? 'Temuan' : 'Findings'),
                          _legendItem(colorPenyelesaian,
                              widget.lang == 'ID' ? 'Selesai' : 'Completed'),
                          if (tTarget > 0)
                            _legendDash(const Color(0xFFEF4444),
                                widget.lang == 'ID' ? 'Target Anggota'
                                    : widget.lang == 'ZH' ? '成员目标' : 'Member Target'),
                          if (pTarget > 0)
                            _legendDash(const Color(0xFFF59E0B),
                                widget.lang == 'ID' ? 'Target Anggota Selesai'
                                    : widget.lang == 'ZH' ? '成员完成目标' : 'Member Completion Target'),
                        ]),
                      ),

                      // CHART AREA
                      SizedBox(
                        height: chartH + 28,
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          // Y-AXIS LABELS
                          SizedBox(
                            width: leftW,
                            height: chartH,
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

                                // TARGET DASHED LINES
                                if (tTarget > 0)
                                  Positioned(top: valToY(tTarget), left: 0, right: 0,
                                    child: CustomPaint(
                                      painter: _DashedLinePainter(const Color(0xFFEF4444)),
                                      child: const SizedBox(height: 2))),
                                if (pTarget > 0)
                                  Positioned(top: valToY(pTarget), left: 0, right: 0,
                                    child: CustomPaint(
                                      painter: _DashedLinePainter(const Color(0xFFF59E0B)),
                                      child: const SizedBox(height: 2))),

                                // BARS
                                ...data.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final d = entry.value;
                                  final x   = i * barGroupW + 4.0;
                                  final tH  = (d.temuan / maxVal * chartH).clamp(0.0, chartH);
                                  final pH  = (d.penyelesaian / maxVal * chartH).clamp(0.0, chartH);
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
                                            Container(width: barW, height: tH,
                                              decoration: const BoxDecoration(
                                                color: colorTemuan,
                                                borderRadius: BorderRadius.vertical(
                                                    top: Radius.circular(3)))),
                                            const SizedBox(width: 2),
                                            Container(width: barW, height: pH,
                                              decoration: const BoxDecoration(
                                                color: colorPenyelesaian,
                                                borderRadius: BorderRadius.vertical(
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

  // TABLE HEADER
  Widget _buildTableHeader() {
    final cols = [_t('nama'), _t('temuan'), _t('selesai')];
    return Container(
      color: const Color(0xFFF8FAFF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: List.generate(cols.length, (i) {
        final isFirst = i == 0;
        return Expanded(
          flex: isFirst ? 3 : 1,
          child: Padding(
            padding: EdgeInsets.only(left: isFirst ? 44 : 0),
            child: Text(cols[i],
                textAlign: isFirst ? TextAlign.left : TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600,
                    color: _AppColors.textSecondary, letterSpacing: 0.2)),
          ),
        );
      })),
    );
  }

  // TARGET ROW
  Widget _buildTargetRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: _AppColors.primaryLight,
        border: Border(bottom: BorderSide(color: _AppColors.divider)),
      ),
      child: Row(children: [
        Expanded(flex: 3, child: Padding(
          padding: const EdgeInsets.only(left: 44),
          child: Text(_t('target_bulanan'),
              textAlign: TextAlign.left,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: _AppColors.primary)),
        )),
        Expanded(flex: 1, child: Text('$_targetAnggota',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: _AppColors.primary))),
        Expanded(flex: 1, child: Text('$_targetAnggotaSelesai',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: _AppColors.primary))),
      ]),
    );
  }

  // MEMBER ROW
  Widget _buildMemberRow(MemberData5R m) {
    final findingsColor = (_targetAnggota > 0 && m.findings >= _targetAnggota)
        ? const Color(0xFF16A34A) : _AppColors.textPrimary;
    final completedColor = (_targetAnggotaSelesai > 0 && m.completed >= _targetAnggotaSelesai)
        ? const Color(0xFF16A34A) : _AppColors.textPrimary;

    return Container(
      color: m.isSelf ? _AppColors.selfHighlight : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          _Avatar5R(name: m.name, avatarUrl: m.avatarUrl,
              color: m.avatarColor, size: 34),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                    color: _AppColors.textPrimary),
                overflow: TextOverflow.ellipsis),
            if (m.unitName != null && m.unitName!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(m.unitName!,
                  style: const TextStyle(fontSize: 11, color: _AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis),
            ],
          ])),
        ])),
        Expanded(flex: 1, child: Text('${m.findings}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600,
                color: findingsColor))),
        Expanded(flex: 1, child: Text('${m.completed}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600,
                color: completedColor))),
      ]),
    );
  }

  // SELF PINNED ROW
  Widget _buildSelfPinnedRow(MemberData5R self) {
    final findingsColor = (_targetAnggota > 0 && self.findings >= _targetAnggota)
        ? const Color(0xFF16A34A) : _AppColors.textSecondary;
    final completedColor = (_targetAnggotaSelesai > 0 && self.completed >= _targetAnggotaSelesai)
        ? const Color(0xFF16A34A) : _AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: _AppColors.selfHighlight,
        border: const Border(
            top: BorderSide(color: _AppColors.selfHighlightBorder, width: 1.5)),
        boxShadow: [BoxShadow(
            color: Colors.black..withValues(alpha:0.05),
            blurRadius: 6, offset: const Offset(0, -2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          _Avatar5R(name: self.name, avatarUrl: self.avatarUrl,
              color: self.avatarColor, size: 34),
          const SizedBox(width: 10),
          Expanded(child: Text(self.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: _AppColors.textPrimary),
              overflow: TextOverflow.ellipsis)),
        ])),
        Expanded(flex: 1, child: Text('${self.findings}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600,
                color: findingsColor))),
        Expanded(flex: 1, child: Text('${self.completed}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600,
                color: completedColor))),
      ]),
    );
  }

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
              _shimBox(height: 34, width: 34, isCircle: true),
              const SizedBox(width: 10),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                _shimBox(height: 14, width: 120),
                const SizedBox(height: 4),
                _shimBox(height: 12, width: 80),
              ])),
            ])),
            Expanded(flex: 1, child: Center(child: _shimBox(height: 14, width: 20))),
            Expanded(flex: 1, child: Center(child: _shimBox(height: 14, width: 20))),
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
              color: _AppColors.primary..withValues(alpha:0.10),
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
    String    tempMode  = _filterMode;
    DateTime  tempDate  = _selectedDate ?? DateTime.now();

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
              // HEADER
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                decoration: const BoxDecoration(
                  color: _AppColors.primaryLight,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                child: Row(children: [
                  const Icon(Icons.calendar_month_rounded, color: _AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_t('pilih_bulan'),
                      style: const TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 15, color: _AppColors.textPrimary))),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: _AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
                ]),
              ),
              // TOGGLE MODE
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: _AppColors.surface, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _AppColors.primaryLight)),
                  padding: const EdgeInsets.all(4),
                  child: Row(children: ['monthly', 'daily'].map((mode) {
                    final isSel = tempMode == mode;
                    final lbl = mode == 'monthly'
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
                        child: Center(child: Text(lbl, style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: isSel ? Colors.white : _AppColors.textSecondary))),
                      ),
                    ));
                  }).toList()),
                ),
              ),
              // CONTENT
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
                            _filterMode          = 'monthly';
                            _selectedMonthIndex  = i;
                            _selectedDate        = null;
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
                              color: _AppColors.primary..withValues(alpha:0.3),
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
          final isToday   = now.year == date.year && now.month == date.month && now.day == date.day;
          final isFuture  = date.isAfter(now);
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

  // GROUP PICKER
  void _showGroupPicker() async {
    final allItem = {'id_unit': null, 'nama_unit': _t('semua_grup_anggota')};
    final items   = [allItem, ..._unitList];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          final ctrl = TextEditingController();
          List<Map<String, dynamic>> filtered = List.from(items);

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6),
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
                    Expanded(child: Text(_t('pilih_grup'),
                        style: const TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 15, color: _AppColors.textPrimary))),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: _AppColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: StatefulBuilder(builder: (_, setInner) => TextField(
                    controller: ctrl,
                    onChanged: (q) {
                      setInner(() {
                        filtered = items.where((e) =>
                            (e['nama_unit'] as String).toLowerCase()
                                .contains(q.toLowerCase())).toList();
                      });
                      setSt(() {});
                    },
                    decoration: InputDecoration(
                      hintText: _t('cari'),
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
                  )),
                ),
                Flexible(child: StatefulBuilder(builder: (_, __) => ListView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final item     = filtered[i];
                    final lbl      = item['nama_unit'] as String;
                    final id       = item['id_unit']?.toString();
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
                            const Icon(Icons.check_circle_rounded,
                                color: _AppColors.primary, size: 18),
                        ]),
                      ),
                    );
                  },
                ))),
              ]),
            ),
          );
        },
      ),
    );
  }
}