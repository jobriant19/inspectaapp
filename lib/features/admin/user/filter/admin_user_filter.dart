import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/jabatan_helper.dart';

class _AdminFilterColors {
  static const primary = Color(0xFF6366F1);
  static const primaryLight = Color(0xFFEEF2FF);
  static const textPrimary = Color(0xFF1E3A8A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFFBDBDBD);
  static const divider = Color(0xFFF1F5F9);
}

const double _kAdminFilterDialogWidth = 340;
const double _kAdminFilterDialogHeightFactor = 0.72;

const List<String> _adminFilterLevels = ['Lokasi', 'Unit', 'Subunit', 'Area'];

const List<Color> _adminFilterTabColors = [
  Color(0xFF10B981),
  Color(0xFF6366F1),
  Color(0xFFFBBF24),
  Color(0xFFF472B6), 
];

String _adminLevelLabel(String level, String lang) {
  switch (level) {
    case 'Unit':
      return lang == 'ZH' ? '部门' : 'Unit';
    case 'Subunit':
      return lang == 'ZH' ? '子部门' : 'Sub-Unit';
    case 'Area':
      return lang == 'ZH' ? '区域' : 'Area';
    default:
      return lang == 'EN' ? 'Location' : lang == 'ZH' ? '位置' : 'Lokasi';
  }
}

IconData _adminLevelIcon(String level) {
  switch (level) {
    case 'Unit':
      return Icons.business_rounded;
    case 'Subunit':
      return Icons.layers_rounded;
    case 'Area':
      return Icons.place_rounded;
    default:
      return Icons.location_city_rounded;
  }
}

const int kVerificatorFilterId = -1;

Color adminRoleColor(int? idJabatan) {
  if (idJabatan == kVerificatorFilterId) return const Color(0xFF10B981);
  if (idJabatan == 6) return const Color(0xFF059669);
  return JabatanHelper.getPrimaryColor(isVerificatorFlag: false, idJabatan: idJabatan);
}

IconData adminRoleIcon(int? idJabatan) {
  if (idJabatan == kVerificatorFilterId) return Icons.verified_user_outlined;
  if (idJabatan == 6) return Icons.admin_panel_settings_rounded;
  return JabatanHelper.getRoleIcon(isVerificatorFlag: false, idJabatan: idJabatan);
}

Widget buildAdminRoleBadge({
  required int? idJabatan,
  required String? jabatanNama,
  required bool? isVerificator,
  required String lang,
}) {
  final bool isVerif = isVerificator == true;
  final Color color = isVerif ? adminRoleColor(kVerificatorFilterId) : adminRoleColor(idJabatan);
  final IconData icon = isVerif ? adminRoleIcon(kVerificatorFilterId) : adminRoleIcon(idJabatan);
  final String label = isVerif
      ? (lang == 'EN' ? 'Verificator' : lang == 'ZH' ? '验证员' : 'Verifikator')
      : (jabatanNama ?? '-');
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ],
    ),
  );
}

Widget _buildAdminFilterShimmerList() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade200,
    highlightColor: Colors.grey.shade100,
    child: ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
  );
}

Widget _adminFilterDialogHeader({
  required BuildContext context,
  required IconData icon,
  required String title,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _AdminFilterColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _AdminFilterColors.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _AdminFilterColors.textPrimary,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
          ),
        ),
      ],
    ),
  );
}

Future<Map<String, String?>?> showAdminUserLocationFilterDialog(
  BuildContext context, {
  required String lang,
  String? initialLevel,
  String? initialId,
}) {
  return showDialog<Map<String, String?>>(
    context: context,
    builder: (ctx) => _AdminUserLocationFilterDialog(
      lang: lang,
      initialLevel: initialLevel ?? 'Lokasi',
      initialId: initialId,
    ),
  );
}

class _AdminUserLocationFilterDialog extends StatefulWidget {
  final String lang;
  final String initialLevel;
  final String? initialId;

  const _AdminUserLocationFilterDialog({
    required this.lang,
    required this.initialLevel,
    this.initialId,
  });

  @override
  State<_AdminUserLocationFilterDialog> createState() =>
      _AdminUserLocationFilterDialogState();
}

class _AdminUserLocationFilterDialogState extends State<_AdminUserLocationFilterDialog> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchCtrl = TextEditingController();

  static const Map<String, String> _idColByLevel = {
    'lokasi': 'id_lokasi',
    'unit': 'id_unit',
    'subunit': 'id_subunit',
    'area': 'id_area',
  };
  static const Map<String, String> _nameColByLevel = {
    'lokasi': 'nama_lokasi',
    'unit': 'nama_unit',
    'subunit': 'nama_subunit',
    'area': 'nama_area',
  };

  String _level = 'Lokasi';
  String? _selectedId;
  final Map<String, List<Map<String, String>>> _dataByLevel = {
    'Lokasi': [],
    'Unit': [],
    'Subunit': [],
    'Area': [],
  };
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _level = widget.initialLevel;
    _selectedId = widget.initialId;
    _searchCtrl.addListener(() => setState(() {}));
    _fetchAllLevels();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.lang) {
      case 'EN':
        return 'Select Location';
      case 'ZH':
        return '选择位置';
      default:
        return 'Pilih Lokasi';
    }
  }

  String get _searchHint {
    final levelLabel = _adminLevelLabel(_level, widget.lang);
    switch (widget.lang) {
      case 'EN':
        return 'Search $levelLabel...';
      case 'ZH':
        return '搜索$levelLabel...';
      default:
        return 'Cari $levelLabel...';
    }
  }

  String get _allLabel {
    switch (widget.lang) {
      case 'EN':
        return 'All (${_adminLevelLabel(_level, widget.lang)})';
      case 'ZH':
        return '全部 (${_adminLevelLabel(_level, widget.lang)})';
      default:
        return 'Semua (${_adminLevelLabel(_level, widget.lang)})';
    }
  }

  String get _emptyLabel {
    switch (widget.lang) {
      case 'EN':
        return 'No data at this level';
      case 'ZH':
        return '该级别没有数据';
      default:
        return 'Tidak ada data pada level ini';
    }
  }

  Future<void> _fetchAllLevels() async {
    setState(() => _loading = true);
    try {
      for (final lvl in _adminFilterLevels) {
        final levelLower = lvl.toLowerCase();
        final idCol = _idColByLevel[levelLower] ?? 'id_lokasi';
        final nameCol = _nameColByLevel[levelLower] ?? 'nama_lokasi';
        final res = await _supabase.from(levelLower).select('$idCol, $nameCol').order(nameCol);
        _dataByLevel[lvl] = List<Map<String, dynamic>>.from(res)
            .map((e) => {'id': e[idCol]?.toString() ?? '', 'name': e[nameCol]?.toString() ?? '-'})
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetch location filter (Admin User): $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchCtrl.text.trim().toLowerCase();
    List<Map<String, String>> filtered;

    if (q.isEmpty) {
      filtered = _dataByLevel[_level] ?? [];
    } else {
      final currentMatches =
          (_dataByLevel[_level] ?? []).where((e) => e['name']!.toLowerCase().contains(q)).toList();
      if (currentMatches.isNotEmpty) {
        filtered = currentMatches;
      } else {
        String? matchLevel;
        List<Map<String, String>> matchResult = [];
        for (final lvl in _adminFilterLevels) {
          if (lvl == _level) continue;
          final matches = (_dataByLevel[lvl] ?? []).where((e) => e['name']!.toLowerCase().contains(q)).toList();
          if (matches.isNotEmpty) {
            matchLevel = lvl;
            matchResult = matches;
            break;
          }
        }
        filtered = matchResult;
        if (matchLevel != null) {
          final resolvedLevel = matchLevel;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _level != resolvedLevel) {
              setState(() {
                _level = resolvedLevel;
                _selectedId = null;
              });
            }
          });
        }
      }
    }

    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: _kAdminFilterDialogWidth,
        height: screenHeight * _kAdminFilterDialogHeightFactor,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _AdminFilterColors.primaryLight, width: 1.5),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _AdminFilterColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.map, color: _AdminFilterColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _AdminFilterColors.primary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          // TAB LEVEL
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              children: List.generate(_adminFilterLevels.length, (index) {
                final lvl = _adminFilterLevels[index];
                final isActive = lvl == _level;
                final color = _adminFilterTabColors[index];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _level = lvl;
                        _selectedId = null;
                        _searchCtrl.clear();
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive ? color : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isActive ? color : const Color(0xFFE2E8F0)),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.30),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_adminLevelIcon(lvl), size: 15, color: isActive ? Colors.white : color),
                          const SizedBox(height: 3),
                          Text(
                            _adminLevelLabel(lvl, widget.lang),
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isActive ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          // SEARCH
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _AdminFilterColors.primary.withValues(alpha: 0.35), width: 1.3),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                textAlignVertical: TextAlignVertical.center,
                style: GoogleFonts.poppins(fontSize: 13, color: _AdminFilterColors.textPrimary),
                decoration: InputDecoration(
                  hintText: _searchHint,
                  hintStyle: TextStyle(fontSize: 12.5, color: _AdminFilterColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: _AdminFilterColors.primary, size: 18),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: _AdminFilterColors.divider),
          Expanded(
            child: _loading
                ? _buildAdminFilterShimmerList()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                    children: [
                      _buildLocationAllCard(),
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(_emptyLabel,
                                style: const TextStyle(fontSize: 12.5, color: _AdminFilterColors.textSecondary)),
                          ),
                        )
                      else
                        ...filtered.map((item) => _buildLocationItemCard(item)),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }

  int get _levelColorIndex => _adminFilterLevels.indexOf(_level);

  Widget _buildLocationAllCard() {
    final isSel = _selectedId == null;
    final color = _adminFilterTabColors[_levelColorIndex];
    return GestureDetector(
      onTap: () => Navigator.pop(context, {'level': _level, 'id': null, 'name': null}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSel ? _AdminFilterColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSel ? _AdminFilterColors.primary : const Color(0xFFE2E8F0),
            width: isSel ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.apps_rounded, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _allLabel,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: _AdminFilterColors.textPrimary),
            ),
          ),
          if (isSel)
            const Icon(Icons.check_circle_rounded, color: _AdminFilterColors.primary, size: 20)
          else
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
        ]),
      ),
    );
  }

  Widget _buildLocationItemCard(Map<String, String> item) {
    final isSel = item['id'] == _selectedId;
    final color = _adminFilterTabColors[_levelColorIndex];
    final name = item['name'] ?? '-';
    final initials =
        name.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

    return GestureDetector(
      onTap: () => Navigator.pop(context, {'level': _level, 'id': item['id'], 'name': item['name']}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSel ? _AdminFilterColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSel ? _AdminFilterColors.primary : const Color(0xFFE2E8F0),
            width: isSel ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(initials, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: _AdminFilterColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_adminLevelIcon(_level), size: 10, color: color),
                    const SizedBox(width: 3),
                    Text(_adminLevelLabel(_level, widget.lang),
                        style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
                  ]),
                ),
              ],
            ),
          ),
          if (isSel)
            const Icon(Icons.check_circle_rounded, color: _AdminFilterColors.primary, size: 20)
          else
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
        ]),
      ),
    );
  }
}

Future<Map<String, dynamic>?> showAdminUserRoleFilterDialog(
  BuildContext context, {
  required String lang,
  required List<Map<String, dynamic>> jabatanList,
  int? selectedJabatanId,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => _AdminUserRoleFilterDialog(
      lang: lang,
      jabatanList: jabatanList,
      selectedJabatanId: selectedJabatanId,
    ),
  );
}

class _AdminUserRoleFilterDialog extends StatefulWidget {
  final String lang;
  final List<Map<String, dynamic>> jabatanList;
  final int? selectedJabatanId;

  const _AdminUserRoleFilterDialog({
    required this.lang,
    required this.jabatanList,
    this.selectedJabatanId,
  });

  @override
  State<_AdminUserRoleFilterDialog> createState() => _AdminUserRoleFilterDialogState();
}

class _AdminUserRoleFilterDialogState extends State<_AdminUserRoleFilterDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _sorted = [];
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _sorted = List<Map<String, dynamic>>.from(widget.jabatanList)
      ..sort((a, b) => (a['id_jabatan'] as int).compareTo(b['id_jabatan'] as int));
    _filtered = List<Map<String, dynamic>>.from(_sorted);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.lang) {
      case 'EN':
        return 'Select Role';
      case 'ZH':
        return '选择角色';
      default:
        return 'Pilih Role';
    }
  }

  String get _searchHint {
    switch (widget.lang) {
      case 'EN':
        return 'Search role...';
      case 'ZH':
        return '搜索角色...';
      default:
        return 'Cari role...';
    }
  }

  String get _allLabel {
    switch (widget.lang) {
      case 'EN':
        return 'All Roles';
      case 'ZH':
        return '所有角色';
      default:
        return 'Semua Role';
    }
  }

  String get _emptyText {
    switch (widget.lang) {
      case 'EN':
        return 'No roles found';
      case 'ZH':
        return '未找到角色';
      default:
        return 'Role tidak ditemukan';
    }
  }

  String get _emptySubtitle {
    switch (widget.lang) {
      case 'EN':
        return 'Try a different keyword.';
      case 'ZH':
        return '请尝试其他关键词。';
      default:
        return 'Coba kata kunci lain.';
    }
  }

  String get _clearSearchLabel {
    switch (widget.lang) {
      case 'EN':
        return 'Clear search';
      case 'ZH':
        return '清除搜索';
      default:
        return 'Hapus pencarian';
    }
  }

  String get _verificatorLabel {
    switch (widget.lang) {
      case 'EN':
        return 'Verificator';
      case 'ZH':
        return '验证员';
      default:
        return 'Verifikator';
    }
  }

  bool get _verificatorMatchesSearch {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return _verificatorLabel.toLowerCase().contains(q);
  }

  void _applySearch(String q) {
    final query = q.trim().toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? List<Map<String, dynamic>>.from(_sorted)
          : _sorted
              .where((e) =>
                  (e['nama_jabatan'] ?? '').toString().toLowerCase().contains(query))
              .toList();
    });
  }

  void _resetSearch() {
    _searchCtrl.clear();
    _applySearch('');
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        width: _kAdminFilterDialogWidth,
        height: screenHeight * _kAdminFilterDialogHeightFactor,
        color: Colors.white,
        child: Column(children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _AdminFilterColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.badge_rounded,
                    color: _AdminFilterColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _AdminFilterColors.primary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Color(0xFF64748B), size: 18),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          // SEARCH
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _AdminFilterColors.primary.withValues(alpha: 0.35),
                    width: 1.3),
                boxShadow: [
                  BoxShadow(
                    color: _AdminFilterColors.primary.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _applySearch,
                textAlignVertical: TextAlignVertical.center,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: _AdminFilterColors.textPrimary,
                    fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: _searchHint,
                  hintStyle:
                      TextStyle(fontSize: 12.5, color: _AdminFilterColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: _AdminFilterColors.primary, size: 19),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? GestureDetector(
                          onTap: _resetSearch,
                          child: Container(
                            margin: const EdgeInsets.all(10),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 14, color: Colors.red),
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: _AdminFilterColors.divider),
          // LIST
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              children: [
                _buildRoleCard(
                  context: context,
                  icon: Icons.apps_rounded,
                  color: _AdminFilterColors.primary,
                  label: _allLabel,
                  isSelected: widget.selectedJabatanId == null,
                  onTap: () => Navigator.pop(context, {'id': null, 'name': null}),
                ),
                if (_filtered.isEmpty && !_verificatorMatchesSearch)
                  _buildEmptyState()
                else ...[
                  ..._filtered.map((jab) {
                    final id = jab['id_jabatan'] as int;
                    final nama = jab['nama_jabatan']?.toString() ?? '';
                    return _buildRoleCard(
                      context: context,
                      icon: adminRoleIcon(id),
                      color: adminRoleColor(id),
                      label: nama,
                      isSelected: widget.selectedJabatanId == id,
                      onTap: () => Navigator.pop(context, {'id': id, 'name': nama}),
                    );
                  }),
                  if (_verificatorMatchesSearch)
                    _buildRoleCard(
                      context: context,
                      icon: adminRoleIcon(kVerificatorFilterId),
                      color: adminRoleColor(kVerificatorFilterId),
                      label: _verificatorLabel,
                      isSelected: widget.selectedJabatanId == kVerificatorFilterId,
                      onTap: () => Navigator.pop(
                          context, {'id': kVerificatorFilterId, 'name': _verificatorLabel}),
                    ),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/team_illustration.png',
            height: 100,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _AdminFilterColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.badge_rounded,
                  size: 28, color: _AdminFilterColors.primary.withValues(alpha: 0.4)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _emptyText,
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w700, color: _AdminFilterColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _emptySubtitle,
            style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _AdminFilterColors.textSecondary,
                height: 1.5),
            textAlign: TextAlign.center,
          ),
          if (_searchCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _resetSearch,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: _AdminFilterColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _AdminFilterColors.primary.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 14, color: _AdminFilterColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      _clearSearchLabel,
                      style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w700, color: _AdminFilterColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : _AdminFilterColors.textPrimary,
              ),
            ),
          ),
          if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 18),
        ]),
      ),
    );
  }
}

Future<String?> showAdminUserSortFilterDialog(
  BuildContext context, {
  required String lang,
  required String currentSort,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _AdminUserSortFilterDialog(lang: lang, currentSort: currentSort),
  );
}

class _AdminUserSortFilterDialog extends StatelessWidget {
  final String lang;
  final String currentSort;

  const _AdminUserSortFilterDialog({required this.lang, required this.currentSort});

  String get _title {
    switch (lang) {
      case 'EN':
        return 'Sort Order';
      case 'ZH':
        return '排序方式';
      default:
        return 'Urutan Abjad';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: _AdminFilterColors.primaryLight,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: _adminFilterDialogHeader(
              context: context,
              icon: Icons.sort_by_alpha_rounded,
              title: _title,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            child: Column(
              children: [
                _buildOption(
                  context: context,
                  label: lang == 'EN' ? 'All (No Sort)' : 'Semua (Tanpa Urutan)',
                  isSelected: currentSort == 'none',
                  onTap: () => Navigator.pop(context, 'none'),
                ),
                _buildOption(
                  context: context,
                  label: 'A → Z (Ascending)',
                  isSelected: currentSort == 'asc',
                  onTap: () => Navigator.pop(context, 'asc'),
                ),
                _buildOption(
                  context: context,
                  label: 'Z → A (Descending)',
                  isSelected: currentSort == 'desc',
                  onTap: () => Navigator.pop(context, 'desc'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _AdminFilterColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _AdminFilterColors.primary : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? _AdminFilterColors.primary : _AdminFilterColors.textPrimary,
              ),
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle_rounded, color: _AdminFilterColors.primary, size: 18),
        ]),
      ),
    );
  }
}