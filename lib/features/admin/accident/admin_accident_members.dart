import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/utils/jabatan_helper.dart';

class _C {
  static const primary             = Color(0xFF0EA5E9);
  static const textPrimary         = Color(0xFF0C4A6E);
  static const textSecondary       = Color(0xFF64748B);
  static const textMuted           = Color(0xFFBDBDBD);
  static const divider             = Color(0xFFE0F2FE);
  static const selfHighlight       = Color(0xFFFFF7ED);
  static const selfHighlightBorder = Color(0xFFFED7AA);
  static const red                 = Color(0xFFEF4444);
  static const redLight            = Color(0xFFFEE2E2);
  static const redBorderLight      = Color(0xFFFCA5A5);
  static const green               = Color(0xFF10B981);
}

class MemberData {
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
  const MemberData({
    required this.name,
    this.unitName,
    required this.findings,
    required this.completed,
    this.isSelf    = false,
    this.avatarUrl,
    this.avatarColor,
    this.idJabatan,
    this.jabatanNama,
    this.isVerificator,
  });
}

class AdminAccidentMembersTab extends StatefulWidget {
  final String lang;
  const AdminAccidentMembersTab({super.key, required this.lang});

  @override
  State<AdminAccidentMembersTab> createState() => _AdminAccidentMembersTabState();
}

class _AdminAccidentMembersTabState extends State<AdminAccidentMembersTab> {
  final _supabase = Supabase.instance.client;

  // FILTER STATE
  int       _selectedMonthIndex = DateTime.now().month - 1;
  String    _filterMode         = 'monthly';
  DateTime? _selectedDate;
  String?   _selectedUnitId;
  DateTime? _lastUpdated;

  // CHART
  bool _isChartExpanded = false;

  // POPUP GUARD
  bool _isMonthPickerOpen = false;
  bool _isGroupPickerOpen = false;

  Future<List<MemberData>>? membersFuture;
  List<Map<String, dynamic>> _unitList = [];
  late List<String> _translatedMonths;

  @override
  void initState() {
    super.initState();
    _initLists();
    _fetchUnits().then((_) => fetchData());
  }

  void _initLists() {
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
      debugPrint('fetchUnits: $e');
    }
  }

  // FETCH DATA (mengganti future sesuai filter aktif)
  void fetchData() {
    final month = _selectedMonthIndex + 1;
    final year  = DateTime.now().year;

    setState(() {
      _lastUpdated = DateTime.now();
      if (_filterMode == 'daily' && _selectedDate != null) {
        membersFuture = _fetchMembersDaily(_selectedDate!, _selectedUnitId);
      } else {
        membersFuture = _fetchMembers(month, year, _selectedUnitId);
      }
    });
  }

  // PIE CHART PUBLIC
  Future<List<MemberData>>? get currentFuture => membersFuture;

  // MONTHLY FETCH
  Future<List<MemberData>> _fetchMembers(int month, int year, String? unitId) async {
    try {
      var q = _supabase
          .from('accident_report')
          .select('id_pelapor, status, id_unit')
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at',
              DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String());
      if (unitId != null) q = q.eq('id_unit', unitId);
      final List<dynamic> res = await q;
      return _groupMembersFromReports(res);
    } catch (e) {
      return [];
    }
  }

  // DAILY FETCH
  Future<List<MemberData>> _fetchMembersDaily(DateTime date, String? unitId) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end   = DateTime(date.year, date.month, date.day, 23, 59, 59);
      var q = _supabase
          .from('accident_report')
          .select('id_pelapor, status')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());
      if (unitId != null) q = q.eq('id_unit', unitId);
      final List<dynamic> res = await q;
      return _groupMembersFromReports(res);
    } catch (e) {
      return [];
    }
  }

  Future<List<MemberData>> _groupMembersFromReports(List<dynamic> reports) async {
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
    final List<dynamic> usersRes = await _supabase
        .from('User')
        .select(
            'id_user, nama, gambar_user, id_unit, id_jabatan, is_verificator, unit!user_id_unit_fkey(nama_unit), jabatan!User_id_jabatan_fkey(nama_jabatan)')
        .inFilter('id_user', userIds);
    final currentUserId = _supabase.auth.currentUser?.id;
    return usersRes.map((u) {
      final uid   = u['id_user']?.toString() ?? '';
      final stats = grouped[uid] ?? {'temuan': 0, 'selesai': 0};
      return MemberData(
        name:      u['nama'] as String? ?? '-',
        unitName:  (u['unit'] as Map<String, dynamic>?)?['nama_unit'] as String?,
        findings:  stats['temuan'] as int,
        completed: stats['selesai'] as int,
        isSelf:    uid == currentUserId,
        avatarUrl: u['gambar_user'] as String?,
        avatarColor: _C.red,
        idJabatan: u['id_jabatan'] as int?,
        jabatanNama: (u['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'] as String?,
        isVerificator: u['is_verificator'] as bool?,
      );
    }).toList()
      ..sort((a, b) => b.findings.compareTo(a.findings));
  }

  String _t(String id, String en, String zh) {
    if (widget.lang == 'ID') return id;
    if (widget.lang == 'ZH') return zh;
    return en;
  }

  String get _lastUpdatedText {
    if (_lastUpdated == null) return _t('Memuat data...', 'Loading data...', '加载数据...');
    final fmt = DateFormat('d MMM yyyy HH:mm',
        widget.lang == 'ID' ? 'id_ID' : 'en_US').format(_lastUpdated!);
    return '${_t('Terakhir diperbarui pada', 'Last updated at', '最后更新于')} $fmt (GMT+7)';
  }

  String get _activeDateLabel {
    final locale = widget.lang == 'ID' ? 'id_ID'
        : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    if (_filterMode == 'daily' && _selectedDate != null) {
      return DateFormat('d MMM yyyy', locale).format(_selectedDate!);
    }
    return DateFormat('MMMM yyyy', locale)
        .format(DateTime(DateTime.now().year, _selectedMonthIndex + 1));
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // CHART TOGGLE + PIE CHART (posisi paling atas, sesuai accident_members_tab.dart)
      _buildConditionalChart(),
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
              color: _C.redLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.access_time_filled_rounded,
                  size: 13, color: _C.red),
              const SizedBox(width: 6),
              Text(_lastUpdatedText,
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _C.textPrimary)),
            ]),
          ),
        ),
      ),
      _buildTableHeader(),
      // LIST
      Expanded(child: membersFuture == null
          ? _buildShimmer()
          : FutureBuilder<List<MemberData>>(
              future: membersFuture,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return _buildShimmer();
                }
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return _buildEmptyState();
                }
                final self = list.firstWhere(
                  (m) => m.isSelf,
                  orElse: () => MemberData(
                    name: _t('Saya', 'Me', '我'),
                    findings: 0, completed: 0, isSelf: true),
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

  // ===================== CHART SECTION =====================

  Widget _buildConditionalChart() {
    return Column(children: [
      GestureDetector(
        onTap: () => setState(() => _isChartExpanded = !_isChartExpanded),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.red.withValues(alpha: 0.4), width: 1.2),
            boxShadow: [BoxShadow(color: _C.red.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            Icon(Icons.bar_chart_rounded, size: 16, color: _C.red),
            const SizedBox(width: 8),
            Expanded(child: Text(
              _t('Grafik $_activeDateLabel', 'Chart $_activeDateLabel', '$_activeDateLabel 图表'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _C.red),
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
        child: _isChartExpanded ? _buildMembersPieChart() : const SizedBox.shrink(),
      ),
    ]);
  }

  Widget _buildMembersPieChart() {
    if (membersFuture == null) return _buildChartShimmer();
    return FutureBuilder<List<MemberData>>(
      future: membersFuture,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildChartShimmer();
        }
        final data      = snap.data ?? [];
        final totalRep  = data.fold<int>(0, (s, m) => s + m.findings);
        final totalDone = data.fold<int>(0, (s, m) => s + m.completed);
        return _buildPieChart(
          totalPrimary:   totalRep,
          totalSecondary: totalDone,
          colorPrimary:   _C.red,
          colorSecondary: _C.green,
          labelPrimary:   _t('Laporan', 'Reports', '报告'),
          labelSecondary: _t('Selesai', 'Completed', '已完成'),
          iconPrimary:    Icons.warning_amber_rounded,
          iconSecondary:  Icons.check_circle_outline_rounded,
        );
      },
    );
  }

  Widget _buildChartShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        height: 158,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPieChart({
    required int    totalPrimary,
    required int    totalSecondary,
    required Color  colorPrimary,
    required Color  colorSecondary,
    required String labelPrimary,
    required String labelSecondary,
    required IconData iconPrimary,
    required IconData iconSecondary,
  }) {
    final total = totalPrimary + totalSecondary;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.red.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: _C.red.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const Icon(Icons.pie_chart_rounded, size: 14, color: _C.red),
            const SizedBox(width: 6),
            Text(
              _t('Ringkasan $_activeDateLabel', 'Summary $_activeDateLabel', '$_activeDateLabel 摘要'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _C.red),
            ),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _C.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_t('Total', 'Total', '总计')}: $total',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _C.red),
            ),
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
                  primaryValue:   totalPrimary.toDouble(),
                  secondaryValue: totalSecondary.toDouble(),
                  colorPrimary:   colorPrimary,
                  colorSecondary: colorSecondary,
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
              _buildPieCard(colorPrimary,   labelPrimary,   totalPrimary,   total, iconPrimary),
              const SizedBox(height: 8),
              _buildPieCard(colorSecondary, labelSecondary, totalSecondary, total, iconSecondary),
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? value / total : 0,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 3,
            ),
          ),
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

  // ===================== EMPTY STATE =====================

  Widget _buildEmptyState() {
    final title = _t(
      'Belum Ada Laporan Kecelakaan',
      'No Accident Reports Yet',
      '暂无事故报告',
    );

    final subtitle = _t(
      'Belum ada laporan kecelakaan maupun data terkait yang tercatat pada periode ini.',
      'No accident reports or related data have been recorded for this period.',
      '本期尚未记录事故报告或相关数据。',
    );

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
                _C.red.withValues(alpha: 0.16),
                _C.red.withValues(alpha: 0.02),
              ]),
              boxShadow: [
                BoxShadow(
                    color: _C.red.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10)),
              ],
            ),
            child: Image.asset(
              'assets/images/safety.png',
              width: 130,
              height: 130,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                  Icons.image_not_supported_rounded,
                  size: 80,
                  color: _C.red.withValues(alpha: 0.4)),
            ),
          ),
          const SizedBox(height: 20),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _C.red,
                  letterSpacing: 0.1)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _C.red.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.red.withValues(alpha: 0.18)),
            ),
            child: Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5,
                    color: _C.textPrimary,
                    height: 1.55,
                    fontWeight: FontWeight.w500)),
          ),
        ]),
      ),
    );
  }

  // ===================== TABLE =====================

  Widget _buildTableHeader() {
    final cols = [
      _t('Nama', 'Name', '名称'),
      _t('Laporan', 'Reports', '报告'),
      _t('Selesai', 'Completed', '已完成'),
    ];
    return Container(
      color: const Color(0xFFF8FAFF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: List.generate(cols.length, (i) {
        return Expanded(
          flex: i == 0 ? 3 : 1,
          child: Text(cols[i],
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600,
                  color: _C.textSecondary, letterSpacing: 0.2)),
        );
      })),
    );
  }

  Widget _buildMemberRow(MemberData m) {
    return Container(
      color: m.isSelf ? _C.selfHighlight : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(flex: 3, child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Avatar(name: m.name, avatarUrl: m.avatarUrl,
                color: m.avatarColor, size: 36),
            const SizedBox(width: 10),
            Expanded(child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name,
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: _C.textPrimary),
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
        Expanded(flex: 1, child: Text('${m.findings}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5,
                fontWeight: FontWeight.w600, color: _C.textPrimary))),
        Expanded(flex: 1, child: Text('${m.completed}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5,
                fontWeight: FontWeight.w600, color: _C.textPrimary))),
      ]),
    );
  }

  Widget _buildSelfPinnedRow(MemberData self) {
    return Container(
      decoration: BoxDecoration(
        color: _C.selfHighlight,
        border: const Border(
            top: BorderSide(color: _C.selfHighlightBorder, width: 1.5)),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6, offset: const Offset(0, -2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(flex: 3, child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Avatar(name: self.name, avatarUrl: self.avatarUrl,
                color: self.avatarColor, size: 36),
            const SizedBox(width: 10),
            Expanded(child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(self.name,
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: _C.textPrimary),
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
        Expanded(flex: 1, child: Text('${self.findings}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5,
                fontWeight: FontWeight.w600, color: _C.textSecondary))),
        Expanded(flex: 1, child: Text('${self.completed}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5,
                fontWeight: FontWeight.w600, color: _C.textSecondary))),
      ]),
    );
  }

  // ===================== FILTER BUTTONS =====================

  Widget _buildMemberTimeFilterButton() {
    final isActive = _filterMode == 'daily';
    final modeLabel = _filterMode == 'daily'
        ? _t('Harian', 'Daily', '按日')
        : _t('Bulanan', 'Monthly', '按月');
    final valueLabel = _filterMode == 'daily' && _selectedDate != null
        ? DateFormat('d MMM yyyy',
                widget.lang == 'ID' ? 'id_ID'
                : widget.lang == 'EN' ? 'en_US' : 'zh_CN')
            .format(_selectedDate!)
        : _monthLabel;

    return GestureDetector(
      onTap: _showMonthPicker,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? _C.red : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _C.red : _C.redBorderLight,
            width: 1.5,
          ),
          boxShadow: [BoxShadow(
              color: _C.red.withValues(alpha: 0.10), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month_rounded, size: 15,
                    color: isActive ? Colors.white : _C.red),
                const SizedBox(width: 5),
                Flexible(
                  child: Text('$modeLabel · $valueLabel',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : _C.red)),
                ),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded,
              color: isActive ? Colors.white : _C.red, size: 18),
        ]),
      ),
    );
  }

  Widget _buildMemberGroupFilterButton() {
    final isActive = _selectedUnitId != null;
    final label = _selectedUnitId == null
        ? _t('Semua Grup', 'All Groups', '所有组')
        : (_unitList.firstWhere(
                (u) => u['id_unit'].toString() == _selectedUnitId,
                orElse: () => {'nama_unit': _t('Semua Grup', 'All Groups', '所有组')})['nama_unit']
            as String);

    return GestureDetector(
      onTap: _showGroupPicker,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? _C.red : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _C.red : _C.redBorderLight,
            width: 1.5,
          ),
          boxShadow: [BoxShadow(
              color: _C.red.withValues(alpha: 0.10), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Expanded(
            child: Text(label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : _C.red)),
          ),
          Icon(Icons.keyboard_arrow_down_rounded,
              color: isActive ? Colors.white : _C.red, size: 18),
        ]),
      ),
    );
  }

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
              _shimmerBox(height: 34, width: 34, isCircle: true),
              const SizedBox(width: 10),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                _shimmerBox(height: 14, width: 120),
                const SizedBox(height: 4),
                _shimmerBox(height: 12, width: 80),
              ])),
            ])),
            Expanded(flex: 1,
                child: Center(child: _shimmerBox(height: 14, width: 20))),
            Expanded(flex: 1,
                child: Center(child: _shimmerBox(height: 14, width: 20))),
          ]),
        ),
      ),
    );
  }

  Widget _shimmerBox({double? width, required double height,
      bool isCircle = false, double borderRadius = 8}) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(isCircle ? height / 2 : borderRadius),
      ),
    );
  }

  String get _monthLabel {
    final locale = widget.lang == 'ID' ? 'id_ID'
        : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    return DateFormat.MMM(locale)
        .format(DateTime(2000, _selectedMonthIndex + 1));
  }

  // ===================== MONTH / DAILY PICKER =====================

  void _showMonthPicker() async {
    if (_isMonthPickerOpen) return;
    _isMonthPickerOpen = true;

    String tempMode = _filterMode;
    int tempMonthIdx = _selectedMonthIndex;
    DateTime tempDate = _selectedDate ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.65, maxWidth: 340),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0F2FE), width: 1.5)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2FE),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              child: Row(children: [
                const Icon(Icons.calendar_month_rounded, color: _C.red, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  _t('Pilih Bulan', 'Select Month', '选择月份'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _C.textPrimary))),
                IconButton(icon: const Icon(Icons.close, size: 18, color: _C.textSecondary),
                    onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0F2FE))),
                padding: const EdgeInsets.all(4),
                child: Row(children: ['monthly', 'daily'].map((mode) {
                  final isSel = tempMode == mode;
                  final label = mode == 'monthly'
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
                      child: Center(child: Text(label, style: TextStyle(
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
                    final isSel = i == tempMonthIdx;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _filterMode = 'monthly';
                          _selectedMonthIndex = i;
                          _selectedDate = null;
                        });
                        fetchData();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: isSel ? _C.red : const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isSel ? _C.red : const Color(0xFFE0F2FE),
                              width: isSel ? 1.5 : 1)),
                        child: Center(child: Text(_translatedMonths[i], style: TextStyle(
                            fontSize: 13, fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
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
                  (d) => setSt(() => tempDate = d),
                  onConfirm: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _filterMode = 'daily';
                      _selectedDate = tempDate;
                      _selectedMonthIndex = tempDate.month - 1;
                    });
                    fetchData();
                  },
                ),
              ),
          ]),
        ),
      )),
    );
    _isMonthPickerOpen = false;
  }

  Widget _buildDailyCalendar(DateTime selectedDate, ValueChanged<DateTime> onChange,
      {required VoidCallback onConfirm}) {
    final now = DateTime.now();
    final locale = widget.lang == 'ID' ? 'id_ID' : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    final dayLabels = widget.lang == 'ZH'
        ? ['日', '一', '二', '三', '四', '五', '六']
        : widget.lang == 'ID'
            ? ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
            : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    DateTime displayedMonth = DateTime(selectedDate.year, selectedDate.month);

    return StatefulBuilder(builder: (_, setIn) {
      final year  = displayedMonth.year;
      final month = displayedMonth.month;
      final daysInMonth    = DateUtils.getDaysInMonth(year, month);
      final firstWeekday   = DateTime(year, month, 1).weekday % 7;
      final monthLabel     = DateFormat('MMMM yyyy', locale).format(DateTime(year, month));
      final isCurrentMonth = year == now.year && month == now.month;

      return Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
            onPressed: () => setIn(() => displayedMonth = DateTime(year, month - 1)),
            icon: const Icon(Icons.chevron_left_rounded, color: _C.red, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
          Text(monthLabel, style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: _C.textPrimary)),
          IconButton(
            onPressed: isCurrentMonth
                ? null
                : () => setIn(() => displayedMonth = DateTime(year, month + 1)),
            icon: Icon(Icons.chevron_right_rounded,
                color: isCurrentMonth ? _C.textMuted : _C.red, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: dayLabels.map((d) => Expanded(child: Center(
            child: Text(d, style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: _C.textSecondary))))).toList()),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, crossAxisSpacing: 4, mainAxisSpacing: 4, childAspectRatio: 1),
          itemCount: firstWeekday + daysInMonth,
          itemBuilder: (_, i) {
            if (i < firstWeekday) return const SizedBox();
            final day  = i - firstWeekday + 1;
            final date = DateTime(year, month, day);
            final isSel   = selectedDate.year == year &&
                selectedDate.month == month && selectedDate.day == day;
            final isToday = now.year == year && now.month == month && now.day == day;
            final isFut   = date.isAfter(now);
            return GestureDetector(
              onTap: isFut ? null : () => setIn(() => onChange(date)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSel ? _C.red : isToday ? const Color(0xFFE0F2FE) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday && !isSel ? Border.all(color: _C.red, width: 1.2) : null),
                child: Center(child: Text('$day', style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSel || isToday ? FontWeight.bold : FontWeight.normal,
                    color: isSel ? Colors.white : isFut ? _C.textMuted : _C.textPrimary))),
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
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(_t('Terapkan', 'Apply', '应用'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ),
      ]);
    });
  }

  // ===================== GROUP PICKER =====================

  void _showGroupPicker() async {
    if (_isGroupPickerOpen) return;
    _isGroupPickerOpen = true;

    final allItem = {'id_unit': null, 'nama_unit': _t('Semua Grup', 'All Groups', '所有组')};
    final items   = [allItem, ..._unitList];
    final ctrl    = TextEditingController();
    List<Map<String, dynamic>> filtered = List.from(items);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0F2FE), width: 1.5)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2FE),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              child: Row(children: [
                const Icon(Icons.group_rounded, color: _C.red, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(_t('Pilih Grup', 'Select Group', '选择组'),
                    style: const TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 15, color: _C.textPrimary))),
                IconButton(icon: const Icon(Icons.close, size: 18, color: _C.textSecondary),
                    onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: TextField(
                controller: ctrl,
                onChanged: (q) => setSt(() {
                  filtered = items.where((e) =>
                      (e['nama_unit'] as String).toLowerCase().contains(q.toLowerCase())).toList();
                }),
                decoration: InputDecoration(
                  hintText: _t('Cari...', 'Search...', '搜索...'),
                  hintStyle: const TextStyle(fontSize: 13, color: _C.textMuted),
                  prefixIcon: const Icon(Icons.search, color: _C.red, size: 18),
                  filled: true, fillColor: const Color(0xFFF0F9FF),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Color(0xFFE0F2FE))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Color(0xFFE0F2FE))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: _C.red, width: 1.5)),
                ),
              ),
            ),
            Flexible(child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final item  = filtered[i];
                final lbl   = item['nama_unit'] as String;
                final id    = item['id_unit']?.toString();
                final isSel = id == _selectedUnitId || (id == null && _selectedUnitId == null);
                return InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _selectedUnitId = id);
                    fetchData();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFFE0F2FE) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isSel ? _C.red : const Color(0xFFE0F2FE),
                          width: isSel ? 1.5 : 1)),
                    child: Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: isSel ? _C.red : const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(10)),
                        child: Center(child: Text(
                          lbl.isNotEmpty ? lbl[0].toUpperCase() : '?',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                              color: isSel ? Colors.white : _C.red))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(lbl, style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          color: isSel ? _C.red : _C.textPrimary))),
                      if (isSel) const Icon(Icons.check_circle_rounded, color: _C.red, size: 18),
                    ]),
                  ),
                );
              },
            )),
          ]),
        ),
      )),
    );
    _isGroupPickerOpen = false;
  }
}

// AVATAR HELPER
class _Avatar extends StatelessWidget {
  final String  name;
  final Color?  color;
  final double  size;
  final String? avatarUrl;
  const _Avatar(
      {required this.name, this.color, this.size = 36, this.avatarUrl});

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
    final bg = color ?? _C.primary;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.15), shape: BoxShape.circle,
        border: Border.all(color: bg.withValues(alpha: 0.3), width: 1)),
      child: Center(child: Text(initials,
          style: TextStyle(fontSize: size * 0.35,
              fontWeight: FontWeight.w700, color: bg))),
    );
  }
}

// UNIT BADGE HELPER
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

// PIE CHART PAINTER
class _PieChartPainter extends CustomPainter {
  final double primaryValue;
  final double secondaryValue;
  final Color  colorPrimary;
  final Color  colorSecondary;
  const _PieChartPainter({
    required this.primaryValue, required this.secondaryValue,
    required this.colorPrimary, required this.colorSecondary,
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
        ..arcTo(Rect.fromCircle(center: center, radius: outerRadius), startAngle, sweepAngle, false)
        ..close();
      canvas.drawPath(path,
        Paint()..color = color.withValues(alpha: 0.2)
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