import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/utils/jabatan_helper.dart';

class _AppColors {
  static const primary             = Color(0xFF0EA5E9);
  static const primaryLight        = Color(0xFFE0F2FE);
  static const textPrimary         = Color(0xFF0C4A6E);
  static const divider             = Color(0xFFE0F2FE);
  static const selfHighlight       = Color(0xFFFFF7ED);
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

class FiveRMembersTab extends StatefulWidget {
  final String lang;

  // FILTER STATE
  final String    filterMode;
  final int       selectedMonthIndex;
  final DateTime? selectedDate;

  // FILTER LOKASI (Lokasi/Unit/Subunit/Area)
  final String    selectedLocationLevel;
  final String?   selectedLocationId;
  final String?   selectedLocationName;

  // TARGET
  final int targetAnggota;
  final int targetAnggotaSelesai;

  // LAST UPDATED
  final String lastUpdatedText;

  // SHARED UI BUILDER
  final Widget Function({
    required String    label,
    required VoidCallback onTap,
    IconData           icon,
    bool               isActive,
  }) buildFilterBtn;

  final void Function(VoidCallback onChanged) showMonthPicker;
  final VoidCallback showLocationPicker;
  final VoidCallback onResetLocation;

  final String Function(String key) getTxt;

  const FiveRMembersTab({
    super.key,
    required this.lang,
    required this.filterMode,
    required this.selectedMonthIndex,
    this.selectedDate,
    required this.selectedLocationLevel,
    this.selectedLocationId,
    this.selectedLocationName,
    required this.targetAnggota,
    required this.targetAnggotaSelesai,
    required this.lastUpdatedText,
    required this.buildFilterBtn,
    required this.showMonthPicker,
    required this.showLocationPicker,
    required this.onResetLocation,
    required this.getTxt,
  });

  @override
  State<FiveRMembersTab> createState() => FiveRMembersTabState();
}

class FiveRMembersTabState extends State<FiveRMembersTab> {
  final _supabase = Supabase.instance.client;

  Future<List<MemberData5R>>? membersFuture;

  void fetchData({
    String?   filterMode,
    int?      selectedMonthIndex,
    DateTime? selectedDate,
    String?   selectedLocationLevel,
    String?   selectedLocationId,
  }) {
    final mode       = filterMode           ?? widget.filterMode;
    final monthIdx    = selectedMonthIndex   ?? widget.selectedMonthIndex;
    final date        = selectedDate         ?? widget.selectedDate;
    final level       = selectedLocationLevel ?? widget.selectedLocationLevel;
    final locationId  = selectedLocationId   ?? widget.selectedLocationId;

    final month = monthIdx + 1;
    final year  = DateTime.now().year;

    setState(() {
      if (mode == 'daily' && date != null) {
        membersFuture = _fetchAnggotaDataDaily(date, level, locationId);
      } else {
        membersFuture = _fetchAnggotaData(month, year, level, locationId);
      }
    });
  }

  Future<List<MemberData5R>>? get currentFuture => membersFuture;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  static const Map<String, String> _locationIdColumnMap = {
    'Lokasi': 'id_lokasi',
    'Unit': 'id_unit',
    'Subunit': 'id_subunit',
    'Area': 'id_area',
  };

  Future<List<MemberData5R>> _fetchAnggotaData(
      int month, int year, String level, String? locationId) async {
    try {
      var userQuery = _supabase
          .from('User')
          .select(
              'id_user, nama, gambar_user, id_unit, id_jabatan, is_verificator, unit!user_id_unit_fkey(nama_unit), jabatan!User_id_jabatan_fkey(nama_jabatan)')
          .or('id_jabatan.is.null,id_jabatan.neq.6');
      if (locationId != null) {
        final idCol = _locationIdColumnMap[level] ?? 'id_lokasi';
        userQuery = userQuery.eq(idCol, locationId);
      }
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
      DateTime date, String level, String? locationId) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end   = DateTime(date.year, date.month, date.day, 23, 59, 59);

      var userQuery = _supabase
          .from('User')
          .select(
              'id_user, nama, gambar_user, id_unit, id_jabatan, is_verificator, unit!user_id_unit_fkey(nama_unit), jabatan!User_id_jabatan_fkey(nama_jabatan)')
          .or('id_jabatan.is.null,id_jabatan.neq.6');
      if (locationId != null) {
        final idCol = _locationIdColumnMap[level] ?? 'id_lokasi';
        userQuery = userQuery.eq(idCol, locationId);
      }
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
              idJabatan: u['id_jabatan'] as int?,
              jabatanNama: (u['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'] as String?,
              isVerificator: u['is_verificator'] as bool?,
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
              color: _AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.access_time_filled_rounded,
                  size: 13, color: _AppColors.primary),
              const SizedBox(width: 6),
              Text(widget.lastUpdatedText,
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
                if (snap.hasError ||
                    !snap.hasData ||
                    snap.data!.isEmpty) {
                  return Center(
                      child:
                          Text(widget.getTxt('tidak_ada_data_anggota')));
                }
                final list = snap.data!;
                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: _AppColors.divider,
                      indent: 16),
                  itemBuilder: (_, i) => _buildMemberRow(list[i]),
                );
              },
            )),
    ]);
  }

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
        return Expanded(
          flex: i == 0 ? 3 : 1,
          child: Text(cols[i],
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
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
        border: Border(
            bottom: BorderSide(color: _AppColors.divider)),
      ),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Text(widget.getTxt('target_bulanan'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _AppColors.primary)),
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
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(flex: 3, child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Avatar5R(
                name: m.name, avatarUrl: m.avatarUrl,
                color: m.avatarColor, size: 36),
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

  String get _monthLabel {
    final locale = widget.lang == 'ID'
        ? 'id_ID'
        : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    return DateFormat.MMM(locale)
        .format(DateTime(2000, widget.selectedMonthIndex + 1));
  }

  static const Color _timeAccent = Color(0xFF1D72F3);  // BIRU - FILTER WAKTU

  static const List<Color> _locationLevelColors = [
    Color(0xFF10B981), // Lokasi
    Color(0xFF6366F1), // Unit
    Color(0xFFFBBF24), // Subunit
    Color(0xFFF472B6), // Area
  ];
  static const List<IconData> _locationLevelIcons = [
    Icons.location_city_rounded, // Lokasi
    Icons.business_rounded,      // Unit
    Icons.layers_rounded,        // Subunit
    Icons.place_rounded,         // Area
  ];
  static const List<String> _locationLevelOrder = ['Lokasi', 'Unit', 'Subunit', 'Area'];

  Widget _buildMemberTimeFilterButton() {
    final isActive = widget.filterMode == 'daily';
    final modeLabel = widget.filterMode == 'daily'
        ? (widget.lang == 'ID' ? 'Harian' : widget.lang == 'ZH' ? '按日' : 'Daily')
        : (widget.lang == 'ID' ? 'Bulanan' : widget.lang == 'ZH' ? '按月' : 'Monthly');
    final valueLabel = widget.filterMode == 'daily' && widget.selectedDate != null
        ? DateFormat('d MMM yyyy',
                widget.lang == 'ID' ? 'id_ID' : widget.lang == 'EN' ? 'en_US' : 'zh_CN')
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

  String get _allLocationLabel {
    switch (widget.lang) {
      case 'EN':
        return 'All Location';
      case 'ZH':
        return '所有位置';
      default:
        return 'Semua Lokasi';
    }
  }

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
}

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
          color: bg.withValues(alpha:0.15),
          shape: BoxShape.circle,
          border: Border.all(color: bg.withValues(alpha:0.3), width: 1)),
      child: Center(child: Text(initials,
          style: TextStyle(
              fontSize: size * 0.35,
              fontWeight: FontWeight.w700,
              color: bg))),
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
    // Fallback: konsisten per nama unit lain via hash
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