import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class _C {
  static const primary             = Color(0xFF0EA5E9);
  static const textPrimary         = Color(0xFF0C4A6E);
  static const textSecondary       = Color(0xFF64748B);
  static const divider             = Color(0xFFE0F2FE);
  static const selfHighlight       = Color(0xFFFFF7ED);
  static const selfHighlightBorder = Color(0xFFFED7AA);
  static const red                 = Color(0xFFEF4444);
}

class MemberData {
  final String  name;
  final String? unitName;
  final int     findings;
  final int     completed;
  final bool    isSelf;
  final String? avatarUrl;
  final Color?  avatarColor;
  const MemberData({
    required this.name,
    this.unitName,
    required this.findings,
    required this.completed,
    this.isSelf    = false,
    this.avatarUrl,
    this.avatarColor,
  });
}

class AccidentMembersTab extends StatefulWidget {
  final String   lang;

  // FILTER STATE
  final String   filterMode;
  final int      selectedMonthIndex;
  final DateTime? selectedDate;
  final String?  selectedUnitId;
  final List<Map<String, dynamic>> unitList;

  final Widget Function({
    required String     label,
    required VoidCallback onTap,
    IconData             icon,
    bool                 isActive,
  }) buildFilterBtn;

  final void Function(VoidCallback onChanged) showMonthPicker;
  final VoidCallback                          showGroupPicker;
  final String lastUpdatedText;

  const AccidentMembersTab({
    super.key,
    required this.lang,
    required this.filterMode,
    required this.selectedMonthIndex,
    this.selectedDate,
    this.selectedUnitId,
    required this.unitList,
    required this.buildFilterBtn,
    required this.showMonthPicker,
    required this.showGroupPicker,
    required this.lastUpdatedText,
  });

  @override
  State<AccidentMembersTab> createState() => AccidentMembersTabState();
}

class AccidentMembersTabState extends State<AccidentMembersTab> {
  final _supabase = Supabase.instance.client;

  Future<List<MemberData>>? membersFuture;

  void fetchData({
    String?   filterMode,
    int?      selectedMonthIndex,
    DateTime? selectedDate,
    String?   selectedUnitId,
  }) {
    final mode     = filterMode        ?? widget.filterMode;
    final monthIdx = selectedMonthIndex ?? widget.selectedMonthIndex;
    final date     = selectedDate       ?? widget.selectedDate;
    final unitId   = selectedUnitId     ?? widget.selectedUnitId;

    final month = monthIdx + 1;
    final year  = DateTime.now().year;

    setState(() {
      if (mode == 'daily' && date != null) {
        membersFuture = _fetchMembersDaily(date, unitId);
      } else {
        membersFuture = _fetchMembers(month, year, unitId);
      }
    });
  }

  // PIE CHART PUBLIC
  Future<List<MemberData>>? get currentFuture => membersFuture;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

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
        .select('id_user, nama, gambar_user, id_unit, unit!user_id_unit_fkey(nama_unit)')
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
      );
    }).toList()
      ..sort((a, b) => b.findings.compareTo(a.findings));
  }

  String _t(String id, String en, String zh) {
    if (widget.lang == 'ID') return id;
    if (widget.lang == 'ZH') return zh;
    return en;
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // FILTER ROW
      Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          widget.buildFilterBtn(
            label: widget.filterMode == 'daily' && widget.selectedDate != null
                ? DateFormat('d MMM yyyy',
                    widget.lang == 'ID' ? 'id_ID'
                    : widget.lang == 'EN' ? 'en_US' : 'zh_CN')
                    .format(widget.selectedDate!)
                : _monthLabel,
            isActive: true,
            onTap: () => widget.showMonthPicker(fetchData),
          ),
          const SizedBox(width: 10),
          Expanded(child: widget.buildFilterBtn(
            label: widget.selectedUnitId == null
                ? _t('Semua Grup', 'All Groups', '所有组')
                : (widget.unitList.firstWhere(
                    (u) => u['id_unit'].toString() == widget.selectedUnitId,
                    orElse: () => {
                      'nama_unit': _t('Semua Grup', 'All Groups', '所有组')
                    })['nama_unit'] as String),
            onTap: widget.showGroupPicker,
          )),
        ]),
      ),
      // LAST UPDATED
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(widget.lastUpdatedText,
              style: const TextStyle(
                  fontSize: 11, color: _C.textSecondary, height: 1.4)),
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
                  return Center(child: Text(
                    _t('Tidak ada data anggota.',
                       'No member data.', '没有成员数据。'),
                    style: const TextStyle(color: _C.textSecondary)));
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

  // TABLE HEADER
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

  // MEMBER ROW
  Widget _buildMemberRow(MemberData m) {
    return Container(
      color: m.isSelf ? _C.selfHighlight : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          _Avatar(name: m.name, avatarUrl: m.avatarUrl,
              color: m.avatarColor, size: 34),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
            style: const TextStyle(fontSize: 13.5,
                fontWeight: FontWeight.w600, color: _C.textPrimary))),
        Expanded(flex: 1, child: Text('${m.completed}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5,
                fontWeight: FontWeight.w600, color: _C.textPrimary))),
      ]),
    );
  }

  // SELF PINNED ROW
  Widget _buildSelfPinnedRow(MemberData self) {
    return Container(
      decoration: BoxDecoration(
        color: _C.selfHighlight,
        border: const Border(
            top: BorderSide(color: _C.selfHighlightBorder, width: 1.5)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            style: const TextStyle(fontSize: 13.5,
                fontWeight: FontWeight.w600, color: _C.textSecondary))),
        Expanded(flex: 1, child: Text('${self.completed}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5,
                fontWeight: FontWeight.w600, color: _C.textSecondary))),
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

  // HELPERS
  String get _monthLabel {
    final locale = widget.lang == 'ID' ? 'id_ID'
        : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    return DateFormat.MMM(locale)
        .format(DateTime(2000, widget.selectedMonthIndex + 1));
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
        color: bg.withOpacity(0.15), shape: BoxShape.circle,
        border: Border.all(color: bg.withOpacity(0.3), width: 1)),
      child: Center(child: Text(initials,
          style: TextStyle(fontSize: size * 0.35,
              fontWeight: FontWeight.w700, color: bg))),
    );
  }
}