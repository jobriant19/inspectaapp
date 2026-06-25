import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class _AppColors {
  static const primary             = Color(0xFF0EA5E9);
  static const primaryLight        = Color(0xFFE0F2FE);
  static const textPrimary         = Color(0xFF0C4A6E);
  static const textSecondary       = Color(0xFF64748B);
  static const divider             = Color(0xFFE0F2FE);
  static const selfHighlight       = Color(0xFFFFF7ED);
  static const selfHighlightBorder = Color(0xFFFED7AA);
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

// ─── Widget utama ─────────────────────────────────────────────────────────────
class FiveRMembersTab extends StatefulWidget {
  final String lang;

  // Filter state dari parent
  final String    filterMode;
  final int       selectedMonthIndex;
  final DateTime? selectedDate;
  final String?   selectedUnitId;
  final List<Map<String, dynamic>> unitList;

  // Target dari parent
  final int targetAnggota;
  final int targetAnggotaSelesai;

  // Last-updated text
  final String lastUpdatedText;

  // Shared UI builders dari parent
  final Widget Function({
    required String    label,
    required VoidCallback onTap,
    IconData           icon,
    bool               isActive,
  }) buildFilterBtn;

  final void Function(VoidCallback onChanged) showMonthPicker;
  final VoidCallback showGroupPicker;

  // i18n helper dari parent
  final String Function(String key) getTxt;

  const FiveRMembersTab({
    super.key,
    required this.lang,
    required this.filterMode,
    required this.selectedMonthIndex,
    this.selectedDate,
    this.selectedUnitId,
    required this.unitList,
    required this.targetAnggota,
    required this.targetAnggotaSelesai,
    required this.lastUpdatedText,
    required this.buildFilterBtn,
    required this.showMonthPicker,
    required this.showGroupPicker,
    required this.getTxt,
  });

  @override
  State<FiveRMembersTab> createState() => FiveRMembersTabState();
}

class FiveRMembersTabState extends State<FiveRMembersTab> {
  final _supabase = Supabase.instance.client;

  Future<List<MemberData5R>>? membersFuture;

  // ─── Public: dipanggil parent saat filter berubah ─────────────────────────
  void fetchData({
    String?   filterMode,
    int?      selectedMonthIndex,
    DateTime? selectedDate,
    String?   selectedUnitId,
  }) {
    final mode     = filterMode         ?? widget.filterMode;
    final monthIdx = selectedMonthIndex ?? widget.selectedMonthIndex;
    final date     = selectedDate       ?? widget.selectedDate;
    final unitId   = selectedUnitId     ?? widget.selectedUnitId;

    final month = monthIdx + 1;
    final year  = DateTime.now().year;

    setState(() {
      if (mode == 'daily' && date != null) {
        membersFuture = _fetchAnggotaDataDaily(date, unitId);
      } else {
        membersFuture = _fetchAnggotaData(month, year, unitId);
      }
    });
  }

  // ─── Public: untuk chart di parent ────────────────────────────────────────
  Future<List<MemberData5R>>? get currentFuture => membersFuture;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // ─── Fetch (monthly) ──────────────────────────────────────────────────────
  Future<List<MemberData5R>> _fetchAnggotaData(
      int month, int year, String? unitId) async {
    try {
      var userQuery = _supabase
          .from('User')
          .select(
              'id_user, nama, gambar_user, id_unit, unit!user_id_unit_fkey(nama_unit)');
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
        final s   = stats[uid] ?? {'temuan': 0, 'selesai': 0};
        return MemberData5R(
          name:      u['nama'] as String? ?? '-',
          unitName:  (u['unit'] as Map<String, dynamic>?)?['nama_unit'] as String?,
          findings:  s['temuan']!,
          completed: s['selesai']!,
          isSelf:    uid == currentUserId,
          avatarUrl: u['gambar_user'] as String?,
          avatarColor: const Color(0xFF0EA5E9),
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

  // ─── Fetch (daily) ────────────────────────────────────────────────────────
  Future<List<MemberData5R>> _fetchAnggotaDataDaily(
      DateTime date, String? unitId) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end   = DateTime(date.year, date.month, date.day, 23, 59, 59);

      var userQuery = _supabase
          .from('User')
          .select(
              'id_user, nama, gambar_user, id_unit, unit!user_id_unit_fkey(nama_unit)');
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
      return users
          .map((u) {
            final uid = u['id_user']?.toString() ?? '';
            final s   = stats[uid] ?? {'temuan': 0, 'selesai': 0};
            return MemberData5R(
              name:      u['nama'] as String? ?? '-',
              unitName:  (u['unit'] as Map<String, dynamic>?)?['nama_unit']
                  as String?,
              findings:  s['temuan']!,
              completed: s['selesai']!,
              isSelf:    uid == currentUserId,
              avatarUrl: u['gambar_user'] as String?,
              avatarColor: const Color(0xFF0EA5E9),
            );
          })
          .toList()
          ..sort((a, b) {
            final c = b.findings.compareTo(a.findings);
            return c != 0 ? c : a.name.compareTo(b.name);
          });
    } catch (e) {
      debugPrint('Error fetching Anggota daily: $e');
      return [];
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Filter row
      Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          widget.buildFilterBtn(
            label: widget.filterMode == 'daily' && widget.selectedDate != null
                ? DateFormat('d MMM yyyy',
                        widget.lang == 'ID'
                            ? 'id_ID'
                            : widget.lang == 'EN' ? 'en_US' : 'zh_CN')
                    .format(widget.selectedDate!)
                : _monthLabel,
            isActive: true,
            onTap: () => widget.showMonthPicker(fetchData),
          ),
          const SizedBox(width: 10),
          Expanded(child: widget.buildFilterBtn(
            label: widget.selectedUnitId == null
                ? widget.getTxt('semua_grup_anggota')
                : (widget.unitList.firstWhere(
                        (u) =>
                            u['id_unit'].toString() == widget.selectedUnitId,
                        orElse: () => {
                              'nama_unit': widget.getTxt('semua_grup')
                            })['nama_unit']
                    as String),
            onTap: widget.showGroupPicker,
          )),
        ]),
      ),
      // Last updated
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(widget.lastUpdatedText,
              style: const TextStyle(
                  fontSize: 11,
                  color: _AppColors.textSecondary,
                  height: 1.4)),
        ),
      ),
      // Table header
      _buildTableHeader(),
      // Target row
      _buildTargetRow(),
      // List
      Expanded(child: membersFuture == null
          ? _buildShimmer()
          : FutureBuilder<List<MemberData5R>>(
              future: membersFuture,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return _buildShimmer();
                }
                if (snap.hasError ||
                    !snap.hasData ||
                    snap.data!.isEmpty) {
                  return Center(
                      child:
                          Text(widget.getTxt('tidak_ada_data_anggota')));
                }
                final list = snap.data!;
                final self = list.firstWhere(
                  (m) => m.isSelf,
                  orElse: () => MemberData5R(
                    name:      widget.getTxt('saya'),
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
                        height: 1,
                        color: _AppColors.divider,
                        indent: 16),
                    itemBuilder: (_, i) => _buildMemberRow(list[i]),
                  )),
                  _buildSelfPinnedRow(self),
                ]);
              },
            )),
    ]);
  }

  // ─── Table header ─────────────────────────────────────────────────────────
  Widget _buildTableHeader() {
    final cols = [
      widget.getTxt('nama'),
      widget.getTxt('temuan'),
      widget.getTxt('selesai'),
    ];
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
                textAlign:
                    isFirst ? TextAlign.left : TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _AppColors.textSecondary,
                    letterSpacing: 0.2)),
          ),
        );
      })),
    );
  }

  // ─── Target row ───────────────────────────────────────────────────────────
  Widget _buildTargetRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: _AppColors.primaryLight,
        border: Border(
            bottom: BorderSide(color: _AppColors.divider)),
      ),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(widget.getTxt('target_bulanan'),
                textAlign: TextAlign.left,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _AppColors.primary)),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text('${widget.targetAnggota}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _AppColors.primary)),
        ),
        Expanded(
          flex: 1,
          child: Text('${widget.targetAnggotaSelesai}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _AppColors.primary)),
        ),
      ]),
    );
  }

  // ─── Member row ───────────────────────────────────────────────────────────
  Widget _buildMemberRow(MemberData5R m) {
    final target = widget.targetAnggota;
    final findingsColor = (target > 0 && m.findings >= target)
        ? const Color(0xFF16A34A)
        : _AppColors.textPrimary;
    final completedTarget = widget.targetAnggotaSelesai;
    final completedColor =
        (completedTarget > 0 && m.completed >= completedTarget)
            ? const Color(0xFF16A34A)
            : _AppColors.textPrimary;

    return Container(
      color: m.isSelf ? _AppColors.selfHighlight : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          _Avatar5R(
              name: m.name, avatarUrl: m.avatarUrl,
              color: m.avatarColor, size: 34),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.name,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _AppColors.textPrimary),
                overflow: TextOverflow.ellipsis),
            if (m.unitName != null && m.unitName!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(m.unitName!,
                  style: const TextStyle(
                      fontSize: 11, color: _AppColors.textSecondary),
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
                  color: findingsColor)),
        ),
        Expanded(
          flex: 1,
          child: Text('${m.completed}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: completedColor)),
        ),
      ]),
    );
  }

  // ─── Self pinned row ──────────────────────────────────────────────────────
  Widget _buildSelfPinnedRow(MemberData5R self) {
    final target = widget.targetAnggota;
    final findingsColor = (target > 0 && self.findings >= target)
        ? const Color(0xFF16A34A)
        : _AppColors.textSecondary;
    final completedTarget = widget.targetAnggotaSelesai;
    final completedColor =
        (completedTarget > 0 && self.completed >= completedTarget)
            ? const Color(0xFF16A34A)
            : _AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: _AppColors.selfHighlight,
        border: const Border(
            top: BorderSide(
                color: _AppColors.selfHighlightBorder, width: 1.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, -2))
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          _Avatar5R(
              name: self.name,
              avatarUrl: self.avatarUrl,
              color: self.avatarColor,
              size: 34),
          const SizedBox(width: 10),
          Expanded(child: Text(self.name,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _AppColors.textPrimary),
              overflow: TextOverflow.ellipsis)),
        ])),
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

  // ─── Shimmer ──────────────────────────────────────────────────────────────
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
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
            Expanded(
                flex: 1,
                child:
                    Center(child: _shimmerBox(height: 14, width: 20))),
            Expanded(
                flex: 1,
                child:
                    Center(child: _shimmerBox(height: 14, width: 20))),
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
        borderRadius: BorderRadius.circular(
            isCircle ? height / 2 : borderRadius),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String get _monthLabel {
    final locale = widget.lang == 'ID'
        ? 'id_ID'
        : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    return DateFormat.MMM(locale)
        .format(DateTime(2000, widget.selectedMonthIndex + 1));
  }
}

// ─── Avatar helper ────────────────────────────────────────────────────────────
class _Avatar5R extends StatelessWidget {
  final String  name;
  final Color?  color;
  final double  size;
  final String? avatarUrl;

  const _Avatar5R(
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
    final bg = color ?? const Color(0xFF0EA5E9);
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
          color: bg.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: bg.withOpacity(0.3), width: 1)),
      child: Center(child: Text(initials,
          style: TextStyle(
              fontSize: size * 0.35,
              fontWeight: FontWeight.w700,
              color: bg))),
    );
  }
}