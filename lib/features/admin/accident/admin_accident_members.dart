import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class _C {
  static const primary             = Color(0xFF0EA5E9);
  static const primaryLight        = Color(0xFFE0F2FE);
  static const surface             = Color(0xFFF0F9FF);
  static const textPrimary         = Color(0xFF0C4A6E);
  static const textSecondary       = Color(0xFF64748B);
  static const textMuted           = Color(0xFFBDBDBD);
  static const divider             = Color(0xFFE0F2FE);
  static const selfHighlight       = Color(0xFFFFF7ED);
  static const selfHighlightBorder = Color(0xFFFED7AA);
  static const red                 = Color(0xFFEF4444);
  static const green               = Color(0xFF10B981);
}

class MemberDataAccident {
  final String  name;
  final String? unitName;
  final int     findings;
  final int     completed;
  final bool    isSelf;
  final String? avatarUrl;
  final Color?  avatarColor;

  const MemberDataAccident({
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
  final int selesai;
  _ChartBarData({required this.date, required this.temuan, this.selesai = 0});
}

class _Avatar extends StatelessWidget {
  final String  name;
  final Color?  color;
  final double  size;
  final String? avatarUrl;
  const _Avatar({required this.name, this.color, this.size = 36, this.avatarUrl});

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
    final bg = color ?? _C.red;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: bg.withValues(alpha:0.15), shape: BoxShape.circle,
        border: Border.all(color: bg.withValues(alpha:0.3), width: 1)),
      child: Center(child: Text(initials,
          style: TextStyle(fontSize: size * 0.35,
              fontWeight: FontWeight.w700, color: bg))),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final double primaryValue;
  final double secondaryValue;
  final Color  colorPrimary;
  final Color  colorSecondary;
  const _PieChartPainter({
    required this.primaryValue,
    required this.secondaryValue,
    required this.colorPrimary,
    required this.colorSecondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total       = primaryValue + secondaryValue;
    final center      = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.55;
    const gapAngle    = 0.04;

    if (total == 0) {
      canvas.drawCircle(center, (outerRadius + innerRadius) / 2,
        Paint()..color = const Color(0xFFE2E8F0)
              ..style = PaintingStyle.stroke
              ..strokeWidth = outerRadius - innerRadius);
      return;
    }

    final segments = [
      {'value': primaryValue,   'color': colorPrimary},
      {'value': secondaryValue, 'color': colorSecondary},
    ];
    double startAngle = -90 * (math.pi / 180);

    for (final seg in segments) {
      final value = seg['value'] as double;
      final color = seg['color'] as Color;
      if (value <= 0) continue;
      final sweepAngle = (value / total) * 2 * math.pi - gapAngle;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: outerRadius),
            startAngle, sweepAngle, false)
        ..close();
      canvas.drawPath(path,
        Paint()..color = color.withValues(alpha:0.2)
              ..style = PaintingStyle.fill
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: (outerRadius + innerRadius) / 2),
        startAngle, sweepAngle, false,
        Paint()..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = outerRadius - innerRadius
              ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class AdminAccidentMembersTab extends StatefulWidget {
  final String lang;
  const AdminAccidentMembersTab({super.key, required this.lang});

  @override
  State<AdminAccidentMembersTab> createState() => AdminAccidentMembersTabState();
}

class AdminAccidentMembersTabState extends State<AdminAccidentMembersTab> {
  final _supabase = Supabase.instance.client;

  String _t(String id, String en, String zh) {
    if (widget.lang == 'ID') return id;
    if (widget.lang == 'ZH') return zh;
    return en;
  }

  // FILTER STATE
  int       _selectedMonthIndex = DateTime.now().month - 1;
  String    _filterMode         = 'monthly';
  DateTime? _selectedDate;
  String?   _selectedUnitId;
  DateTime? _lastUpdated;
  List<Map<String, dynamic>> _unitList = [];

  // CHART STATE
  bool                        _isChartExpanded = false;
  Future<List<_ChartBarData>>? _chartFuture;
  int                         _chartRefreshKey = 0;

  Future<List<MemberDataAccident>>? _membersFuture;
  late List<String> _translatedMonths;

  @override
  void initState() {
    super.initState();
    _initMonths();
    _fetchUnits().then((_) => _fetchAllData());
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

  void _fetchAllData() {
    final month = _selectedMonthIndex + 1;
    final year  = DateTime.now().year;
    setState(() {
      _lastUpdated = DateTime.now();
      if (_filterMode == 'daily' && _selectedDate != null) {
        _membersFuture = _fetchMembersDaily(_selectedDate!);
        _chartFuture   = _fetchChartDaily(_selectedDate!);
      } else {
        _membersFuture = _fetchMembersMonthly(month, year);
        _chartFuture   = _fetchChartMonthly(month, year);
      }
      _chartRefreshKey++;
    });
  }

  Future<List<MemberDataAccident>> _fetchMembersMonthly(int month, int year) async {
    try {
      var q = _supabase
          .from('accident_report')
          .select('id_pelapor, status, id_unit')
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at', DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String());
      if (_selectedUnitId != null) q = q.eq('id_unit', _selectedUnitId!);
      final List<dynamic> res = await q;
      return _buildMemberList(res);
    } catch (e) {
      debugPrint('Error fetchMembersMonthly: $e');
      return [];
    }
  }

  Future<List<MemberDataAccident>> _fetchMembersDaily(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end   = DateTime(date.year, date.month, date.day, 23, 59, 59);
      var q = _supabase
          .from('accident_report')
          .select('id_pelapor, status, id_unit')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());
      if (_selectedUnitId != null) q = q.eq('id_unit', _selectedUnitId!);
      final List<dynamic> res = await q;
      return _buildMemberList(res);
    } catch (e) {
      debugPrint('Error fetchMembersDaily: $e');
      return [];
    }
  }

  Future<List<MemberDataAccident>> _buildMemberList(List<dynamic> reports) async {
    if (reports.isEmpty) return [];
    final Map<String, Map<String, dynamic>> grouped = {};
    for (final item in reports) {
      final uid = item['id_pelapor']?.toString() ?? '';
      if (uid.isEmpty) continue;
      grouped.putIfAbsent(uid, () => {'temuan': 0, 'selesai': 0});
      grouped[uid]!['temuan'] = (grouped[uid]!['temuan'] as int) + 1;
      if ((item['status'] ?? '') == 'Selesai') {
        grouped[uid]!['selesai'] = (grouped[uid]!['selesai'] as int) + 1;
      }
    }
    final userIds = grouped.keys.toList();
    if (userIds.isEmpty) return [];
    final List<dynamic> usersRes = await _supabase
        .from('User')
        .select('id_user, nama, gambar_user, id_unit, unit!user_id_unit_fkey(nama_unit)')
        .inFilter('id_user', userIds);
    final currentUserId = _supabase.auth.currentUser?.id;
    return usersRes.map((u) {
      final uid   = u['id_user']?.toString() ?? '';
      final stats = grouped[uid] ?? {'temuan': 0, 'selesai': 0};
      return MemberDataAccident(
        name:       u['nama'] as String? ?? '-',
        unitName:   (u['unit'] as Map<String, dynamic>?)?['nama_unit'] as String?,
        findings:   stats['temuan'] as int,
        completed:  stats['selesai'] as int,
        isSelf:     uid == currentUserId,
        avatarUrl:  u['gambar_user'] as String?,
        avatarColor: _C.red,
      );
    }).toList()
      ..sort((a, b) => b.findings.compareTo(a.findings));
  }

  Future<List<_ChartBarData>> _fetchChartMonthly(int month, int year) async {
    try {
      final daysInMonth = DateUtils.getDaysInMonth(year, month);
      var q = _supabase
          .from('accident_report')
          .select('created_at, status, id_unit')
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at', DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String());
      if (_selectedUnitId != null) q = q.eq('id_unit', _selectedUnitId!);
      final List<dynamic> res = await q;

      final Map<int, int> temuanMap = {};
      final Map<int, int> selesaiMap = {};
      for (final t in res) {
        final dt = DateTime.tryParse(t['created_at']?.toString() ?? '');
        if (dt == null) continue;
        temuanMap[dt.day]  = (temuanMap[dt.day]  ?? 0) + 1;
        if ((t['status'] ?? '') == 'Selesai') {
          selesaiMap[dt.day] = (selesaiMap[dt.day] ?? 0) + 1;
        }
      }
      return List.generate(daysInMonth, (i) => _ChartBarData(
          date:    i + 1,
          temuan:  temuanMap[i + 1]  ?? 0,
          selesai: selesaiMap[i + 1] ?? 0));
    } catch (e) {
      debugPrint('Error fetchChartMonthly: $e');
      return [];
    }
  }

  Future<List<_ChartBarData>> _fetchChartDaily(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end   = DateTime(date.year, date.month, date.day, 23, 59, 59);
      var q = _supabase
          .from('accident_report')
          .select('created_at, status, id_unit')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());
      if (_selectedUnitId != null) q = q.eq('id_unit', _selectedUnitId!);
      final List<dynamic> res = await q;
      final selesai = res.where((t) => (t['status'] ?? '') == 'Selesai').length;
      return [_ChartBarData(date: date.day, temuan: res.length, selesai: selesai)];
    } catch (e) {
      debugPrint('Error fetchChartDaily: $e');
      return [];
    }
  }

  String get _lastUpdatedText {
    if (_lastUpdated == null) return _t('Memuat data...', 'Loading data...', '加载数据...');
    final fmt = DateFormat('d MMM yyyy HH:mm',
        widget.lang == 'ID' ? 'id_ID' : 'en_US').format(_lastUpdated!);
    return '${_t('Terakhir diperbarui pada', 'Last updated at', '最后更新于')} $fmt (GMT+7)';
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
          _filterBtn(label: _periodLabel, isActive: true, onTap: _showMonthPicker),
          const SizedBox(width: 10),
          Expanded(child: _filterBtn(
            label: _selectedUnitId == null
                ? _t('Semua Grup', 'All Groups', '所有组')
                : (_unitList.firstWhere(
                        (u) => u['id_unit'].toString() == _selectedUnitId,
                        orElse: () => {
                              'nama_unit': _t('Semua Grup', 'All Groups', '所有组')
                            })['nama_unit']
                    as String),
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
                  fontSize: 11, color: _C.textSecondary, height: 1.4)),
        ),
      ),

      _buildCollapsibleChart(),

      _buildTableHeader(),

      Expanded(child: _membersFuture == null
          ? _buildShimmer()
          : FutureBuilder<List<MemberDataAccident>>(
              future: _membersFuture,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return _buildShimmer();
                }
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return Center(child: Text(
                      _t('Tidak ada data anggota.', 'No member data.', '没有成员数据。'),
                      style: const TextStyle(color: _C.textSecondary)));
                }
                final self = list.firstWhere(
                  (m) => m.isSelf,
                  orElse: () => MemberDataAccident(
                    name:      _t('Saya', 'Me', '我'),
                    findings:  0,
                    completed: 0,
                    isSelf:    true,
                  ),
                );
                return Column(children: [
                  Expanded(child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: _C.divider, indent: 16),
                    itemBuilder: (_, i) => _buildMemberRow(list[i]),
                  )),
                  _buildSelfPinnedRow(self),
                ]);
              },
            )),
    ]);
  }

  Widget _buildCollapsibleChart() {
    return Column(children: [
      GestureDetector(
        onTap: () => setState(() => _isChartExpanded = !_isChartExpanded),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 2, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.red.withValues(alpha:0.4), width: 1.2),
            boxShadow: [BoxShadow(
                color: _C.red.withValues(alpha:0.08),
                blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            const Icon(Icons.bar_chart_rounded, size: 16, color: _C.red),
            const SizedBox(width: 8),
            Expanded(child: Text(
              _t('Grafik $_periodLabel', 'Chart $_periodLabel', '$_periodLabel 图表'),
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: _C.red),
            )),
            AnimatedRotation(
              turns: _isChartExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              child: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: _C.red),
            ),
          ]),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: _isChartExpanded
            ? FutureBuilder<List<_ChartBarData>>(
                key: ValueKey('chart-accident-members-$_chartRefreshKey'),
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
                          color: _C.red, strokeWidth: 2)),
                    );
                  }

                  final data     = snapshot.data ?? [];
                  final totalRep  = data.fold<int>(0, (s, d) => s + d.temuan);
                  final totalDone = data.fold<int>(0, (s, d) => s + d.selesai);

                  return Column(children: [
                    _buildPieChart(totalRep, totalDone),
                  ]);
                },
              )
            : const SizedBox.shrink(),
      ),
    ]);
  }

  Widget _buildPieChart(int totalRep, int totalDone) {
    final total = totalRep + totalDone;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.red.withValues(alpha:0.25)),
        boxShadow: [BoxShadow(
            color: _C.red.withValues(alpha:0.07),
            blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const Icon(Icons.pie_chart_rounded, size: 14, color: _C.red),
            const SizedBox(width: 6),
            Text(
              _t('Ringkasan $_periodLabel', 'Summary $_periodLabel', '$_periodLabel 摘要'),
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: _C.red)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _C.red.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(20)),
            child: Text(
              '${_t('Total', 'Total', '总计')}: $total',
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: _C.red)),
          ),
        ]),
        const SizedBox(height: 12),
        if (total == 0)
          Center(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(children: [
              Icon(Icons.pie_chart_outline, size: 40, color: Colors.grey.shade300),
              const SizedBox(height: 6),
              Text(_t('Tidak ada data', 'No data', '暂无数据'),
                  style: const TextStyle(color: _C.textSecondary, fontSize: 12)),
            ]),
          ))
        else
          Row(children: [
            SizedBox(
              width: 130, height: 130,
              child: CustomPaint(
                painter: _PieChartPainter(
                  primaryValue:   totalRep.toDouble(),
                  secondaryValue: totalDone.toDouble(),
                  colorPrimary:   _C.red,
                  colorSecondary: _C.green,
                ),
                child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$total', style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: _C.textPrimary)),
                  Text(_t('Total', 'Total', '总计'),
                      style: const TextStyle(fontSize: 9, color: _C.textSecondary)),
                ])),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(children: [
              _buildPieCard(_C.red,   _t('Laporan', 'Reports', '报告'),
                  totalRep,  total, Icons.warning_amber_rounded),
              const SizedBox(height: 8),
              _buildPieCard(_C.green, _t('Selesai', 'Completed', '已完成'),
                  totalDone, total, Icons.check_circle_outline_rounded),
            ])),
          ]),
      ]),
    );
  }

  Widget _buildPieCard(Color color, String label, int value, int total, IconData icon) {
    final pct = total > 0 ? (value / total * 100).toStringAsFixed(1) : '0.0';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha:0.3))),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
              color: color.withValues(alpha:0.15), shape: BoxShape.circle),
          child: Icon(icon, size: 12, color: color)),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? value / total : 0,
              backgroundColor: color.withValues(alpha:0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 3)),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$value', style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800, color: _C.textPrimary)),
          Text('$pct%', style: TextStyle(
              fontSize: 9, color: color, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  Widget _buildTableHeader() {
    final cols = [
      _t('Nama', 'Name', '名称'),
      _t('Laporan', 'Reports', '报告'),
      _t('Selesai', 'Completed', '已完成'),
    ];
    return Container(
      color: const Color(0xFFF8FAFF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: List.generate(cols.length, (i) => Expanded(
        flex: i == 0 ? 3 : 1,
        child: Padding(
          padding: EdgeInsets.only(left: i == 0 ? 44 : 0),
          child: Text(cols[i],
              textAlign: i == 0 ? TextAlign.left : TextAlign.center,
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600,
                  color: _C.textSecondary, letterSpacing: 0.2)),
        ),
      ))),
    );
  }

  Widget _buildMemberRow(MemberDataAccident m) {
    return Container(
      color: m.isSelf ? _C.selfHighlight : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          _Avatar(name: m.name, avatarUrl: m.avatarUrl,
              color: m.avatarColor, size: 34),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                    color: _C.textPrimary),
                overflow: TextOverflow.ellipsis),
            if (m.unitName != null && m.unitName!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(m.unitName!,
                  style: const TextStyle(fontSize: 11, color: _C.textSecondary),
                  overflow: TextOverflow.ellipsis),
            ],
          ])),
        ])),
        Expanded(flex: 1, child: Text('${m.findings}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600,
                color: _C.textPrimary))),
        Expanded(flex: 1, child: Text('${m.completed}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600,
                color: _C.textPrimary))),
      ]),
    );
  }

  Widget _buildSelfPinnedRow(MemberDataAccident self) {
    return Container(
      decoration: BoxDecoration(
        color: _C.selfHighlight,
        border: const Border(
            top: BorderSide(color: _C.selfHighlightBorder, width: 1.5)),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 6, offset: const Offset(0, -2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          _Avatar(name: self.name, avatarUrl: self.avatarUrl,
              color: self.avatarColor, size: 34),
          const SizedBox(width: 10),
          Expanded(child: Text(self.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: _C.textPrimary),
              overflow: TextOverflow.ellipsis)),
        ])),
        Expanded(flex: 1, child: Text('${self.findings}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600,
                color: _C.textSecondary))),
        Expanded(flex: 1, child: Text('${self.completed}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600,
                color: _C.textSecondary))),
      ]),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!,
      child: ListView.separated(
        padding: EdgeInsets.zero, itemCount: 10,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: _C.divider, indent: 16),
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
          color: isActive ? _C.red : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _C.red : const Color(0xFFFCA5A5),
            width: 1.5),
          boxShadow: [BoxShadow(
              color: _C.red.withValues(alpha:0.10),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(child: Text(label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : _C.red),
            overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded,
              color: isActive ? Colors.white : _C.red, size: 18),
        ]),
      ),
    );
  }

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
              border: Border.all(color: _C.primaryLight, width: 1.5)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                decoration: const BoxDecoration(
                  color: _C.primaryLight,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                child: Row(children: [
                  const Icon(Icons.calendar_month_rounded, color: _C.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    _t('Pilih Bulan', 'Select Month', '选择月份'),
                    style: const TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 15, color: _C.textPrimary))),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: _C.textSecondary),
                    onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: _C.surface, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.primaryLight)),
                  padding: const EdgeInsets.all(4),
                  child: Row(children: ['monthly', 'daily'].map((mode) {
                    final isSel = tempMode == mode;
                    final lbl   = mode == 'monthly'
                        ? _t('Bulanan', 'Monthly', '按月')
                        : _t('Harian', 'Daily', '按日');
                    return Expanded(child: GestureDetector(
                      onTap: () => setSt(() => tempMode = mode),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSel ? _C.red : Colors.transparent,
                          borderRadius: BorderRadius.circular(9)),
                        child: Center(child: Text(lbl, style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: isSel ? Colors.white : _C.textSecondary))),
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
                          _fetchAllData();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: isSel ? _C.red : _C.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel ? _C.red : _C.divider,
                              width: isSel ? 1.5 : 1),
                            boxShadow: isSel ? [BoxShadow(
                              color: _C.red.withValues(alpha:0.3),
                              blurRadius: 6, offset: const Offset(0, 2))] : []),
                          child: Center(child: Text(_translatedMonths[i],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? Colors.white : _C.textPrimary))),
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
          fontSize: 13, fontWeight: FontWeight.w700, color: _C.textPrimary)),
      const SizedBox(height: 10),
      Row(children: dayLabels.map((d) => Expanded(child: Center(
        child: Text(d, style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600,
            color: _C.textSecondary))))).toList()),
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
          final isToday  = now.day == day && now.month == month;
          final isFuture = date.isAfter(now);
          return GestureDetector(
            onTap: isFuture ? null : () => setInner(() => onDateChanged(date)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isSelected ? _C.red
                    : isToday ? _C.primaryLight : Colors.transparent,
                shape: BoxShape.circle,
                border: isToday && !isSelected
                    ? Border.all(color: _C.red, width: 1.2) : null),
              child: Center(child: Text('$day', style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white
                    : isFuture ? _C.textMuted : _C.textPrimary))),
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
            backgroundColor: _C.red, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 10)),
          child: Text(_t('Terapkan', 'Apply', '应用'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ),
    ]));
  }

  void _showGroupPicker() async {
    final allItem = {'id_unit': null, 'nama_unit': _t('Semua Grup', 'All Groups', '所有组')};
    final items   = [allItem, ..._unitList];
    final ctrl    = TextEditingController();
    List<Map<String, dynamic>> filtered = List.from(items);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.primaryLight, width: 1.5)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                decoration: const BoxDecoration(
                  color: _C.primaryLight,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                child: Row(children: [
                  const Icon(Icons.group_rounded, color: _C.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_t('Pilih Grup', 'Select Group', '选择组'),
                      style: const TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 15, color: _C.textPrimary))),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: _C.textSecondary),
                    onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: TextField(
                  controller: ctrl,
                  onChanged: (q) => setSt(() {
                    filtered = items.where((e) =>
                        (e['nama_unit'] as String).toLowerCase()
                            .contains(q.toLowerCase())).toList();
                  }),
                  decoration: InputDecoration(
                    hintText: _t('Cari...', 'Search...', '搜索...'),
                    hintStyle: const TextStyle(fontSize: 13, color: _C.textMuted),
                    prefixIcon: const Icon(Icons.search, color: _C.primary, size: 18),
                    filled: true, fillColor: _C.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: _C.divider)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: _C.divider)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: _C.primary, width: 1.5)),
                  ),
                ),
              ),
              Flexible(child: ListView.builder(
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
                        color: isSelected ? _C.primaryLight : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _C.primary : _C.divider,
                          width: isSelected ? 1.5 : 1)),
                      child: Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: isSelected ? _C.primary : _C.surface,
                            borderRadius: BorderRadius.circular(10)),
                          child: Center(child: Text(
                            lbl.isNotEmpty ? lbl[0].toUpperCase() : '?',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                                color: isSelected ? Colors.white : _C.primary))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(lbl, style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? _C.primary : _C.textPrimary))),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: _C.primary, size: 18),
                      ]),
                    ),
                  );
                },
              )),
            ]),
          ),
        ),
      ),
    );
  }
}