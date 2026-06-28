import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class _C {
  static const primary             = Color(0xFFF59E0B);
  static const primaryLight        = Color(0xFFFEF3C7);
  static const surface             = Color(0xFFFFFBEB);
  static const textPrimary         = Color(0xFF78350F);
  static const textSecondary       = Color(0xFF92400E);
  static const textMuted           = Color(0xFFD97706);
  static const divider             = Color(0xFFFDE68A);
  static const selfHighlight       = Color(0xFFFFF7ED);
  static const selfHighlightBorder = Color(0xFFFED7AA);
  static const green               = Color(0xFF10B981);
}

class AdminKtsMemberData {
  final String  name;
  final String? unitName;
  final int     findings;
  final int     completed;
  final bool    isSelf;
  final String? avatarUrl;
  final Color?  avatarColor;

  const AdminKtsMemberData({
    required this.name,
    this.unitName,
    required this.findings,
    required this.completed,
    this.isSelf      = false,
    this.avatarUrl,
    this.avatarColor,
  });
}

class AdminKtsMembersTab extends StatefulWidget {
  final String lang;

  const AdminKtsMembersTab({
    super.key,
    required this.lang,
  });

  @override
  State<AdminKtsMembersTab> createState() => AdminKtsMembersTabState();
}

class AdminKtsMembersTabState extends State<AdminKtsMembersTab> {
  final _supabase = Supabase.instance.client;

  // FILTER STATE
  int       _selectedMonthIndex = DateTime.now().month - 1;
  String    _filterMode         = 'monthly';
  DateTime? _selectedDate;
  String?   _selectedUnitId;
  DateTime? _lastUpdated;
  List<Map<String, dynamic>> _unitList = [];

  // CHART STATE
  bool _isChartExpanded = false;

  // DATA
  Future<List<AdminKtsMemberData>>? _membersFuture;
  int _targetAnggota = 2;
  late List<String> _translatedMonths;

  String get _locale => widget.lang == 'ID'
      ? 'id_ID'
      : widget.lang == 'EN'
          ? 'en_US'
          : 'zh_CN';

  String _t(String id, String en, String zh) {
    if (widget.lang == 'ID') return id;
    if (widget.lang == 'ZH') return zh;
    return en;
  }

  String get _periodLabel {
    if (_filterMode == 'daily' && _selectedDate != null) {
      return DateFormat('d MMM yyyy', _locale).format(_selectedDate!);
    }
    return DateFormat('MMMM yyyy', _locale)
        .format(DateTime(DateTime.now().year, _selectedMonthIndex + 1));
  }

  String get _lastUpdatedText {
    if (_lastUpdated == null) {
      return _t('Memuat data...', 'Loading data...', '加载数据...');
    }
    final fmt = DateFormat('d MMM yyyy HH:mm',
            widget.lang == 'ID' ? 'id_ID' : 'en_US')
        .format(_lastUpdated!);
    return '${_t('Terakhir diperbarui pada', 'Last updated at', '最后更新于')} $fmt (GMT+7)';
  }

  @override
  void initState() {
    super.initState();
    _initMonths();
    _fetchUnits().then((_) => _fetchAllData());
    _fetchTarget();
  }

  void _initMonths() {
    _translatedMonths = List.generate(
        12, (i) => DateFormat.MMM(_locale).format(DateTime(2000, i + 1)));
  }

  Future<void> _fetchUnits() async {
    try {
      final res =
          await _supabase.from('unit').select('id_unit, nama_unit');
      if (mounted) {
        setState(() =>
            _unitList = List<Map<String, dynamic>>.from(res));
      }
    } catch (e) {
      debugPrint('fetchUnits: $e');
    }
  }

  Future<void> _fetchTarget() async {
    try {
      final month = _selectedMonthIndex + 1;
      final year  = DateTime.now().year;
      final data  = await _supabase
          .from('target_bulanan')
          .select()
          .eq('bulan', month)
          .eq('tahun', year)
          .maybeSingle();
      if (mounted && data != null) {
        setState(
            () => _targetAnggota = data['target_anggota'] ?? 2);
      }
    } catch (e) {
      debugPrint('fetchTarget: $e');
    }
  }

  void _fetchAllData() {
    final month = _selectedMonthIndex + 1;
    final year  = DateTime.now().year;
    setState(() {
      _lastUpdated = DateTime.now();
      if (_filterMode == 'daily' && _selectedDate != null) {
        _membersFuture =
            _fetchMembersDaily(_selectedDate!, _selectedUnitId);
      } else {
        _membersFuture =
            _fetchMembersMonthly(month, year, _selectedUnitId);
      }
    });
  }

  Future<List<AdminKtsMemberData>> _fetchMembersMonthly(
      int month, int year, String? unitId) async {
    try {
      final res = await _supabase
          .from('temuan')
          .select(
              'id_user, id_penyelesaian, '
              'User_Creator:User!temuan_id_user_fkey('
              'nama, gambar_user, id_unit, '
              'unit!user_id_unit_fkey(nama_unit))')
          .eq('jenis_temuan', 'KTS Production')
          .gte('created_at',
              DateTime(year, month, 1).toIso8601String())
          .lte('created_at',
              DateTime(year, month + 1, 0, 23, 59, 59)
                  .toIso8601String());

      return _buildMemberList(res as List<dynamic>, unitId);
    } catch (e) {
      debugPrint('fetchMembersMonthly: $e');
      return [];
    }
  }

  Future<List<AdminKtsMemberData>> _fetchMembersDaily(
      DateTime date, String? unitId) async {
    try {
      final start =
          DateTime(date.year, date.month, date.day);
      final end =
          DateTime(date.year, date.month, date.day, 23, 59, 59);
      final res = await _supabase
          .from('temuan')
          .select(
              'id_user, id_penyelesaian, '
              'User_Creator:User!temuan_id_user_fkey('
              'nama, gambar_user, id_unit, '
              'unit!user_id_unit_fkey(nama_unit))')
          .eq('jenis_temuan', 'KTS Production')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());

      return _buildMemberList(res as List<dynamic>, unitId);
    } catch (e) {
      debugPrint('fetchMembersDaily: $e');
      return [];
    }
  }

  List<AdminKtsMemberData> _buildMemberList(
      List<dynamic> raw, String? unitId) {
    if (raw.isEmpty) return [];
    final Map<String, Map<String, dynamic>> grouped = {};
    for (final t in raw) {
      final user =
          t['User_Creator'] as Map<String, dynamic>?;
      if (user == null) continue;
      final uid = t['id_user']?.toString() ?? '';
      if (uid.isEmpty) continue;
      if (unitId != null) {
        if (user['id_unit']?.toString() != unitId) continue;
      }
      grouped.putIfAbsent(uid, () => {
        'nama':       user['nama'] ?? '-',
        'gambar':     user['gambar_user'],
        'unitName':   (user['unit']
                as Map<String, dynamic>?)?['nama_unit'],
        'temuan':  0,
        'selesai': 0,
      });
      grouped[uid]!['temuan'] =
          (grouped[uid]!['temuan'] as int) + 1;
      if (t['id_penyelesaian'] != null) {
        grouped[uid]!['selesai'] =
            (grouped[uid]!['selesai'] as int) + 1;
      }
    }

    final currentUserId = _supabase.auth.currentUser?.id;
    return grouped.entries.map((e) {
      final v = e.value;
      return AdminKtsMemberData(
        name:        v['nama'] as String? ?? '-',
        unitName:    v['unitName'] as String?,
        findings:    v['temuan'] as int,
        completed:   v['selesai'] as int,
        isSelf:      e.key == currentUserId,
        avatarUrl:   v['gambar'] as String?,
        avatarColor: _C.primary,
      );
    }).toList()
      ..sort((a, b) => b.findings.compareTo(a.findings));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // CHART TOGGLE
      _buildChartToggle(),
      // ANIMATED PIE CHART
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: _isChartExpanded
            ? _buildPieChartSection()
            : const SizedBox.shrink(),
      ),

      // FILTER ROW
      Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 10),
        child: Row(children: [
          _buildFilterBtn(
            label: _filterMode == 'daily' && _selectedDate != null
                ? DateFormat('d MMM yyyy', _locale)
                    .format(_selectedDate!)
                : _translatedMonths[_selectedMonthIndex],
            isActive: true,
            onTap:    _showMonthPicker,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildFilterBtn(
              label: _selectedUnitId == null
                  ? _t('Semua Grup', 'All Groups', '所有组')
                  : (_unitList.firstWhere(
                          (u) =>
                              u['id_unit'].toString() ==
                              _selectedUnitId,
                          orElse: () => {
                                'nama_unit': _t(
                                    'Semua Grup',
                                    'All Groups',
                                    '所有组')
                              })['nama_unit']
                      as String),
              onTap: _showGroupPicker,
            ),
          ),
        ]),
      ),

      // LAST UPDATED
      Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _lastUpdatedText,
            style: GoogleFonts.poppins(
                fontSize: 11,
                color: _C.textSecondary,
                height: 1.4),
          ),
        ),
      ),

      // TABLE HEADER
      _buildTableHeader(),

      // LIST
      Expanded(child: _buildList()),
    ]);
  }

  Widget _buildChartToggle() {
    return GestureDetector(
      onTap: () =>
          setState(() => _isChartExpanded = !_isChartExpanded),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: _C.primary.withValues(alpha: 0.4),
              width: 1.2),
          boxShadow: [
            BoxShadow(
              color: _C.primary.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          const Icon(Icons.bar_chart_rounded,
              size: 16, color: _C.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _t(
                'Grafik $_periodLabel',
                'Chart $_periodLabel',
                '$_periodLabel 图表',
              ),
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _C.primary),
            ),
          ),
          AnimatedRotation(
            turns: _isChartExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 250),
            child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: _C.primary),
          ),
        ]),
      ),
    );
  }

  Widget _buildPieChartSection() {
    if (_membersFuture == null) return _buildChartShimmer();
    return FutureBuilder<List<AdminKtsMemberData>>(
      future: _membersFuture,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildChartShimmer();
        }
        final data         = snap.data ?? [];
        final totalFindings  =
            data.fold<int>(0, (s, m) => s + m.findings);
        final totalCompleted =
            data.fold<int>(0, (s, m) => s + m.completed);
        return _buildPieChart(totalFindings, totalCompleted);
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildPieChart(int totalFindings, int totalCompleted) {
    final total = totalFindings + totalCompleted;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: _C.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        // HEADER
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          Row(children: [
            const Icon(Icons.pie_chart_rounded,
                size: 14, color: _C.primary),
            const SizedBox(width: 6),
            Text(
              _t(
                'Ringkasan $_periodLabel',
                'Summary $_periodLabel',
                '$_periodLabel 摘要',
              ),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _C.primary,
              ),
            ),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _C.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_t('Total', 'Total', '总计')}: $total',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _C.primary,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),

        if (total == 0)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(children: [
                Icon(Icons.pie_chart_outline,
                    size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 6),
                Text(
                  _t('Tidak ada data', 'No data', '暂无数据'),
                  style: GoogleFonts.poppins(
                      color: _C.textSecondary, fontSize: 12),
                ),
              ]),
            ),
          )
        else
          Row(children: [
            SizedBox(
              width: 130,
              height: 130,
              child: CustomPaint(
                painter: _AdminKtsPieChartPainter(
                  primaryValue:   totalFindings.toDouble(),
                  secondaryValue: totalCompleted.toDouble(),
                  colorPrimary:   _C.primary,
                  colorSecondary: _C.green,
                ),
                child: Center(
                  child: Column(
                      mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      '$total',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _C.textPrimary,
                      ),
                    ),
                    Text(
                      _t('Total', 'Total', '总计'),
                      style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: _C.textSecondary),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(children: [
                _buildPieCard(
                  _C.primary,
                  _t('Temuan', 'Findings', '发现'),
                  totalFindings,
                  total,
                  Icons.search_rounded,
                ),
                const SizedBox(height: 8),
                _buildPieCard(
                  _C.green,
                  _t('Selesai', 'Completed', '已完成'),
                  totalCompleted,
                  total,
                  Icons.check_circle_outline_rounded,
                ),
              ]),
            ),
          ]),
      ]),
    );
  }

  Widget _buildPieCard(
      Color color, String label, int value, int total, IconData icon) {
    final pct =
        total > 0 ? (value / total * 100).toStringAsFixed(1) : '0.0';
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
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
                style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color)),
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
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            '$value',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _C.textPrimary,
            ),
          ),
          Text(
            '$pct%',
            style: GoogleFonts.poppins(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.w600),
          ),
        ]),
      ]),
    );
  }

  Widget _buildTableHeader() {
    final cols = [
      _t('Nama', 'Name', '名称'),
      _t('Temuan', 'Findings', '发现'),
      _t('Selesai', 'Completed', '已完成'),
    ];
    return Container(
      color: const Color(0xFFF8FAFF),
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10),
      child: Row(
        children: List.generate(cols.length, (i) {
          final isFirst = i == 0;
          return Expanded(
            flex: isFirst ? 3 : 1,
            child: Padding(
              padding: EdgeInsets.only(left: isFirst ? 44 : 0),
              child: Text(
                cols[i],
                textAlign:
                    isFirst ? TextAlign.left : TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _C.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildList() {
    if (_membersFuture == null) return _buildShimmer();
    return FutureBuilder<List<AdminKtsMemberData>>(
      future: _membersFuture,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildShimmer();
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return Center(
            child: Text(
              _t('Tidak ada data anggota.',
                 'No member data.', '没有成员数据。'),
              style: GoogleFonts.poppins(
                  color: _C.textSecondary),
            ),
          );
        }
        final self = list.firstWhere(
          (m) => m.isSelf,
          orElse: () => AdminKtsMemberData(
            name:      _t('Saya', 'Me', '我'),
            findings:  0,
            completed: 0,
            isSelf:    true,
          ),
        );
        return Column(children: [
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(
                  height: 1, color: _C.divider, indent: 16),
              itemBuilder: (_, i) => _buildMemberRow(list[i]),
            ),
          ),
          _buildSelfPinnedRow(self),
        ]);
      },
    );
  }

  Widget _buildMemberRow(AdminKtsMemberData m) {
    final findingsColor = m.findings >= _targetAnggota
        ? const Color(0xFF16A34A)
        : _C.textPrimary;
    final completedColor = m.completed >= _targetAnggota
        ? const Color(0xFF16A34A)
        : _C.textPrimary;

    return Container(
      color: m.isSelf ? _C.selfHighlight : Colors.white,
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 11),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Row(children: [
            _AdminKtsAvatar(
              name:      m.name,
              avatarUrl: m.avatarUrl,
              color:     m.avatarColor,
              size:      34,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                  m.name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _C.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (m.unitName != null &&
                    m.unitName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    m.unitName!,
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: _C.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ]),
            ),
          ]),
        ),
        Expanded(
          flex: 1,
          child: Text(
            '${m.findings}',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: findingsColor,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            '${m.completed}',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: completedColor,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildSelfPinnedRow(AdminKtsMemberData self) {
    final findingsColor = self.findings >= _targetAnggota
        ? const Color(0xFF16A34A)
        : _C.textSecondary;
    final completedColor = self.completed >= _targetAnggota
        ? const Color(0xFF16A34A)
        : _C.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: _C.selfHighlight,
        border: const Border(
          top: BorderSide(
              color: _C.selfHighlightBorder, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Row(children: [
            _AdminKtsAvatar(
              name:      self.name,
              avatarUrl: self.avatarUrl,
              color:     self.avatarColor,
              size:      34,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                self.name,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _C.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ),
        Expanded(
          flex: 1,
          child: Text(
            '${self.findings}',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: findingsColor,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            '${self.completed}',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: completedColor,
            ),
          ),
        ),
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
        separatorBuilder: (_, __) => const Divider(
            height: 1, color: _C.divider, indent: 16),
        itemBuilder: (_, __) => Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 11),
          child: Row(children: [
            Expanded(
              flex: 3,
              child: Row(children: [
                _shimBox(height: 34, width: 34, isCircle: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                    _shimBox(height: 14, width: 120),
                    const SizedBox(height: 4),
                    _shimBox(height: 12, width: 80),
                  ]),
                ),
              ]),
            ),
            Expanded(
                flex: 1,
                child: Center(
                    child: _shimBox(height: 14, width: 20))),
            Expanded(
                flex: 1,
                child: Center(
                    child: _shimBox(height: 14, width: 20))),
          ]),
        ),
      ),
    );
  }

  Widget _shimBox(
      {double? width,
      required double height,
      bool isCircle = false,
      double borderRadius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
            isCircle ? height / 2 : borderRadius),
      ),
    );
  }

  Widget _buildFilterBtn({
    required String label,
    required VoidCallback onTap,
    IconData icon    = Icons.keyboard_arrow_down_rounded,
    bool     isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? _C.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _C.primary : _C.primaryLight,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _C.primary.withValues(alpha: 0.10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : _C.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Icon(icon,
              color: isActive ? Colors.white : _C.primary,
              size: 18),
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.of(context).size.height * 0.65,
                maxWidth: 340),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _C.primaryLight, width: 1.5),
            ),
            child:
                Column(mainAxisSize: MainAxisSize.min, children: [
              // HEADER
              Container(
                padding:
                    const EdgeInsets.fromLTRB(16, 14, 8, 12),
                decoration: const BoxDecoration(
                  color: _C.primaryLight,
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20)),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_month_rounded,
                      color: _C.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _t('Pilih Bulan', 'Select Month',
                          '选择月份'),
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _C.textPrimary),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: _C.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                  ),
                ]),
              ),
              // TOGGLE MODE
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: _C.primaryLight),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children:
                        ['monthly', 'daily'].map((mode) {
                      final isSel = tempMode == mode;
                      final lbl = mode == 'monthly'
                          ? _t('Bulanan', 'Monthly', '按月')
                          : _t('Harian', 'Daily', '按日');
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setSt(() => tempMode = mode),
                          child: AnimatedContainer(
                            duration: const Duration(
                                milliseconds: 200),
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSel
                                  ? _C.primary
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(9),
                            ),
                            child: Center(
                              child: Text(
                                lbl,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSel
                                      ? Colors.white
                                      : _C.textSecondary,
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
              // CONTENT
              if (tempMode == 'monthly')
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      16, 8, 16, 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.2,
                    ),
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
                          _fetchTarget()
                              .then((_) => _fetchAllData());
                        },
                        child: AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: isSel
                                ? _C.primary
                                : _C.surface,
                            borderRadius:
                                BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel
                                  ? _C.primary
                                  : _C.divider,
                              width: isSel ? 1.5 : 1,
                            ),
                            boxShadow: isSel
                                ? [
                                    BoxShadow(
                                      color: _C.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              _translatedMonths[i],
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSel
                                    ? Colors.white
                                    : _C.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      16, 8, 16, 16),
                  child: _buildDailyCalendar(
                    tempDate,
                    (d) => setSt(() => tempDate = d),
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

  Widget _buildDailyCalendar(
    DateTime selectedDate,
    ValueChanged<DateTime> onChange, {
    required VoidCallback onConfirm,
  }) {
    final now          = DateTime.now();
    final year         = now.year;
    final month        = now.month;
    final daysInMonth  = DateUtils.getDaysInMonth(year, month);
    final firstWeekday = DateTime(year, month, 1).weekday % 7;
    final monthLabel   = DateFormat('MMMM yyyy', _locale)
        .format(DateTime(year, month));
    final dayLabels = widget.lang == 'ZH'
        ? ['日', '一', '二', '三', '四', '五', '六']
        : widget.lang == 'ID'
            ? ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
            : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return StatefulBuilder(
      builder: (_, setIn) => Column(children: [
        Text(
          monthLabel,
          style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary),
        ),
        const SizedBox(height: 10),
        Row(
          children: dayLabels
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _C.textSecondary)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: firstWeekday + daysInMonth,
          itemBuilder: (_, i) {
            if (i < firstWeekday) return const SizedBox();
            final day   = i - firstWeekday + 1;
            final date  = DateTime(year, month, day);
            final isSel = selectedDate.year == date.year &&
                selectedDate.month == date.month &&
                selectedDate.day == date.day;
            final isToday = now.day == day &&
                now.month == month &&
                now.year == year;
            final isFut = date.isAfter(now);
            return GestureDetector(
              onTap:
                  isFut ? null : () => setIn(() => onChange(date)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSel
                      ? _C.primary
                      : isToday
                          ? _C.primaryLight
                          : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday && !isSel
                      ? Border.all(
                          color: _C.primary, width: 1.2)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: isSel || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSel
                          ? Colors.white
                          : isFut
                              ? _C.textMuted
                              : _C.textPrimary,
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
              backgroundColor: _C.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(
              _t('Terapkan', 'Apply', '应用'),
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ),
      ]),
    );
  }

  void _showGroupPicker() async {
    final allItem = {
      'id_unit':   null,
      'nama_unit': _t('Semua Grup', 'All Groups', '所有组'),
    };
    final items  = [allItem, ..._unitList];
    final ctrl   = TextEditingController();
    List<Map<String, dynamic>> filtered = List.from(items);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.of(context).size.height * 0.6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _C.primaryLight, width: 1.5),
            ),
            child:
                Column(mainAxisSize: MainAxisSize.min, children: [
              // HEADER
              Container(
                padding:
                    const EdgeInsets.fromLTRB(16, 14, 8, 12),
                decoration: const BoxDecoration(
                  color: _C.primaryLight,
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20)),
                ),
                child: Row(children: [
                  const Icon(Icons.group_rounded,
                      color: _C.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _t('Pilih Grup', 'Select Group',
                          '选择组'),
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _C.textPrimary),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: _C.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                  ),
                ]),
              ),
              // SEARCH
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: TextField(
                  controller: ctrl,
                  onChanged: (q) => setSt(() {
                    filtered = items
                        .where((e) =>
                            (e['nama_unit'] as String)
                                .toLowerCase()
                                .contains(q.toLowerCase()))
                        .toList();
                  }),
                  decoration: InputDecoration(
                    hintText:
                        _t('Cari...', 'Search...', '搜索...'),
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 13, color: _C.textMuted),
                    prefixIcon: const Icon(Icons.search,
                        color: _C.primary, size: 18),
                    filled: true,
                    fillColor: _C.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide:
                            const BorderSide(color: _C.divider)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide:
                            const BorderSide(color: _C.divider)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(
                            color: _C.primary, width: 1.5)),
                  ),
                ),
              ),
              // LIST
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    final lbl  = item['nama_unit'] as String;
                    final id   = item['id_unit']?.toString();
                    final isSel = id == _selectedUnitId ||
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
                          color: isSel
                              ? _C.primaryLight
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel
                                ? _C.primary
                                : _C.divider,
                            width: isSel ? 1.5 : 1,
                          ),
                        ),
                        child: Row(children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSel
                                  ? _C.primary
                                  : _C.surface,
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                lbl.isNotEmpty
                                    ? lbl[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isSel
                                      ? Colors.white
                                      : _C.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              lbl,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSel
                                    ? _C.primary
                                    : _C.textPrimary,
                              ),
                            ),
                          ),
                          if (isSel)
                            const Icon(
                                Icons.check_circle_rounded,
                                color: _C.primary,
                                size: 18),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _AdminKtsAvatar extends StatelessWidget {
  final String  name;
  final Color?  color;
  final double  size;
  final String? avatarUrl;

  const _AdminKtsAvatar({
    required this.name,
    this.color,
    this.size = 36,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(avatarUrl!),
        onBackgroundImageError: (_, __) {},
      );
    }
    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    final bg = color ?? _C.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border:
            Border.all(color: bg.withValues(alpha: 0.3), width: 1),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
            color: bg,
          ),
        ),
      ),
    );
  }
}

class _AdminKtsPieChartPainter extends CustomPainter {
  final double primaryValue;
  final double secondaryValue;
  final Color  colorPrimary;
  final Color  colorSecondary;

  const _AdminKtsPieChartPainter({
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
      canvas.drawCircle(
        center,
        (outerRadius + innerRadius) / 2,
        Paint()
          ..color = const Color(0xFFE2E8F0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = outerRadius - innerRadius,
      );
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
      final sweepAngle =
          (value / total) * 2 * math.pi - gapAngle;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
            Rect.fromCircle(center: center, radius: outerRadius),
            startAngle,
            sweepAngle,
            false)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill
          ..maskFilter =
              const MaskFilter.blur(BlurStyle.normal, 4),
      );

      canvas.drawArc(
        Rect.fromCircle(
            center: center,
            radius: (outerRadius + innerRadius) / 2),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = color
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