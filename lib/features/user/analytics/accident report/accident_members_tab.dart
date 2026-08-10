import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/utils/jabatan_helper.dart';

class _C {
  static const primary             = Color(0xFF0EA5E9);
  static const textPrimary         = Color(0xFF0C4A6E);
  static const divider             = Color(0xFFE0F2FE);
  static const selfHighlight       = Color(0xFFFFF7ED);
  static const red                 = Color(0xFFEF4444);
  static const redLight            = Color(0xFFFEE2E2);
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

class AccidentMembersTab extends StatefulWidget {
  final String   lang;

  // FILTER STATE
  final String   filterMode;
  final int      selectedMonthIndex;
  final DateTime? selectedDate;
  final String    selectedLocationLevel;
  final String?   selectedLocationId;
  final String?   selectedLocationName;

  final Widget Function({
    required String     label,
    required VoidCallback onTap,
    IconData             icon,
    bool                 isActive,
  }) buildFilterBtn;

  final void Function(VoidCallback onChanged) showMonthPicker;
  final VoidCallback                          showLocationPicker;
  final VoidCallback                          onResetLocation;
  final String lastUpdatedText;

  const AccidentMembersTab({
    super.key,
    required this.lang,
    required this.filterMode,
    required this.selectedMonthIndex,
    this.selectedDate,
    required this.selectedLocationLevel,
    this.selectedLocationId,
    this.selectedLocationName,
    required this.buildFilterBtn,
    required this.showMonthPicker,
    required this.showLocationPicker,
    required this.onResetLocation,
    required this.lastUpdatedText,
  });

  @override
  State<AccidentMembersTab> createState() => AccidentMembersTabState();
}

class AccidentMembersTabState extends State<AccidentMembersTab> {
  final _supabase = Supabase.instance.client;

  Future<List<MemberData>>? membersFuture;

  static const Map<String, String> _locationIdColumnMap = {
    'Lokasi': 'id_lokasi',
    'Unit': 'id_unit',
    'Subunit': 'id_subunit',
    'Area': 'id_area',
  };

  void fetchData({
    String?   filterMode,
    int?      selectedMonthIndex,
    DateTime? selectedDate,
    String?   selectedLocationLevel,
    String?   selectedLocationId,
  }) {
    final mode     = filterMode            ?? widget.filterMode;
    final monthIdx = selectedMonthIndex    ?? widget.selectedMonthIndex;
    final date     = selectedDate          ?? widget.selectedDate;
    final level    = selectedLocationLevel ?? widget.selectedLocationLevel;
    final locId    = selectedLocationId    ?? widget.selectedLocationId;

    final month = monthIdx + 1;
    final year  = DateTime.now().year;

    setState(() {
      if (mode == 'daily' && date != null) {
        membersFuture = _fetchMembersDaily(date, level, locId);
      } else {
        membersFuture = _fetchMembers(month, year, level, locId);
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
  Future<List<MemberData>> _fetchMembers(int month, int year, String level, String? locationId) async {
    try {
      var q = _supabase
          .from('accident_report')
          .select('id_pelapor, status, id_lokasi, id_unit, id_subunit, id_area') // sesuaikan kolom bila beda
          .gte('created_at', DateTime(year, month, 1).toIso8601String())
          .lte('created_at',
              DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String());
      if (locationId != null) {
        final idCol = _locationIdColumnMap[level] ?? 'id_lokasi';
        q = q.eq(idCol, locationId);
      }
      final List<dynamic> res = await q;
      return _groupMembersFromReports(res);
    } catch (e) {
      return [];
    }
  }

  Future<List<MemberData>> _fetchMembersDaily(DateTime date, String level, String? locationId) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end   = DateTime(date.year, date.month, date.day, 23, 59, 59);
      var q = _supabase
          .from('accident_report')
          .select('id_pelapor, status, id_lokasi, id_unit, id_subunit, id_area') // sesuaikan kolom bila beda
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());
      if (locationId != null) {
        final idCol = _locationIdColumnMap[level] ?? 'id_lokasi';
        q = q.eq(idCol, locationId);
      }
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

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // FILTER ROW
      Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Expanded(child: _buildMemberTimeFilterButton()),
          const SizedBox(width: 10),
          Expanded(child: _buildMemberLocationFilterButton()),
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
              Text(widget.lastUpdatedText,
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
                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: _C.divider, indent: 16),
                  itemBuilder: (_, i) => _buildMemberRow(list[i]),
                );
              },
            )),
    ]);
  }

  // EMPTY STATE
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
                _C.red.withValues(alpha:0.16),
                _C.red.withValues(alpha:0.02),
              ]),
              boxShadow: [
                BoxShadow(
                    color: _C.red.withValues(alpha:0.18),
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
                  color: _C.red.withValues(alpha:0.4)),
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
              color: _C.red.withValues(alpha:0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.red.withValues(alpha:0.18)),
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
      child: Row(children: List.generate(cols.length, (i) {
        return Expanded(
          flex: i == 0 ? 3 : 1,
          child: Text(cols[i],
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600,
                  color: Colors.black, letterSpacing: 0.2)),
        );
      })),
    );
  }

  // MEMBER ROW
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

  static const Color _timeAccent = Color(0xFF1D72F3); // BIRU - FILTER WAKTU (samain dgn 5R)

  Widget _buildMemberTimeFilterButton() {
    final isActive = widget.filterMode == 'daily';
    final modeLabel = widget.filterMode == 'daily'
        ? _t('Harian', 'Daily', '按日')
        : _t('Bulanan', 'Monthly', '按月');
    final valueLabel = widget.filterMode == 'daily' && widget.selectedDate != null
        ? DateFormat('d MMM yyyy',
                widget.lang == 'ID' ? 'id_ID'
                : widget.lang == 'EN' ? 'en_US' : 'zh_CN')
            .format(widget.selectedDate!)
        : _monthLabel;

    return GestureDetector(
      onTap: () => widget.showMonthPicker(fetchData),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? _timeAccent : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _timeAccent : const Color(0xFF93C5FD),
            width: 1.5,
          ),
          boxShadow: [BoxShadow(
              color: _timeAccent.withValues(alpha:0.10), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month_rounded, size: 15,
                    color: isActive ? Colors.white : _timeAccent),
                const SizedBox(width: 5),
                Flexible(
                  child: Text('$modeLabel · $valueLabel',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : _timeAccent)),
                ),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded,
              color: isActive ? Colors.white : _timeAccent, size: 18),
        ]),
      ),
    );
  }

  static const List<Color> _locationLevelColors = [
    Color(0xFF10B981), // Lokasi
    Color(0xFF6366F1), // Unit
    Color(0xFFFBBF24), // Subunit
    Color(0xFFF472B6), // Area
  ];
  static const List<IconData> _locationLevelIcons = [
    Icons.location_city_rounded,
    Icons.business_rounded,
    Icons.layers_rounded,
    Icons.place_rounded,
  ];
  static const List<String> _locationLevelOrder = ['Lokasi', 'Unit', 'Subunit', 'Area'];

  String get _allLocationLabel => _t('Semua Lokasi', 'All Location', '所有位置');

  Widget _buildMemberLocationFilterButton() {
    final hasSelection = widget.selectedLocationId != null;
    final levelIdx = _locationLevelOrder.indexOf(widget.selectedLocationLevel).clamp(0, 3);
    final color = _locationLevelColors[levelIdx];
    final icon  = hasSelection ? _locationLevelIcons[levelIdx] : Icons.map;
    final label = hasSelection
        ? (widget.selectedLocationName ?? widget.selectedLocationLevel)
        : _allLocationLabel;

    return GestureDetector(
      onTap: widget.showLocationPicker,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [BoxShadow(
              color: color.withValues(alpha:0.10), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Expanded(
            child: Text(label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ),
          if (hasSelection)
            GestureDetector(
              onTap: widget.onResetLocation,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.45)),
                ),
                child: const Icon(Icons.close_rounded, size: 12, color: Color(0xFFEF4444)),
              ),
            )
          else
            Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 18),
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
        color: color.withValues(alpha:0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha:0.4), width: 1),
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
        color: bg.withValues(alpha:0.15), shape: BoxShape.circle,
        border: Border.all(color: bg.withValues(alpha:0.3), width: 1)),
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