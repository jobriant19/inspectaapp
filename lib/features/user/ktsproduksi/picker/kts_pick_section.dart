import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _kPrimaryLight = Color(0xFFEFF6FF);

const Color _kAccentGreen = Color(0xFF16A34A);
const Color _kAccentGreenLight = Color(0xFFF0FDF4);
const Color _kAccentGreenBorder = Color(0xFFBBF7D0);

const double _kSectionDialogWidth = 340;
const double _kSectionDialogHeightFactor = 0.72;

Future<Map<String, dynamic>?> showKtsPickSectionDialog(
  BuildContext context, {
  required String lang,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => _KtsPickSectionDialog(lang: lang),
  );
}

Map<String, dynamic> _sectionLocationBadgeInfo(Map<String, dynamic> s) {
  if (s['area'] != null && s['area']['nama_area'] != null) {
    return {
      'label': s['area']['nama_area'].toString(),
      'icon': Icons.place_rounded,
      'color': const Color(0xFFF472B6),
    };
  }
  if (s['subunit'] != null && s['subunit']['nama_subunit'] != null) {
    return {
      'label': s['subunit']['nama_subunit'].toString(),
      'icon': Icons.layers_rounded,
      'color': const Color(0xFFFBBF24),
    };
  }
  if (s['unit'] != null && s['unit']['nama_unit'] != null) {
    return {
      'label': s['unit']['nama_unit'].toString(),
      'icon': Icons.business_rounded,
      'color': const Color(0xFF6366F1),
    };
  }
  if (s['lokasi'] != null && s['lokasi']['nama_lokasi'] != null) {
    return {
      'label': s['lokasi']['nama_lokasi'].toString(),
      'icon': Icons.location_city_rounded,
      'color': const Color(0xFF10B981),
    };
  }
  return {
    'label': '-',
    'icon': Icons.location_off_rounded,
    'color': const Color(0xFF94A3B8),
  };
}

Widget _sectionLocationBadge(Map<String, dynamic> s) {
  final info = _sectionLocationBadgeInfo(s);
  final Color color = info['color'] as Color;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(info['icon'] as IconData, size: 11, color: color),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          info['label'] as String,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
        ),
      ),
    ]),
  );
}

Widget _sectionPickerShimmerList() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade200,
    highlightColor: Colors.grey.shade100,
    child: ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 60,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

class _KtsPickSectionDialog extends StatefulWidget {
  final String lang;
  const _KtsPickSectionDialog({required this.lang});

  @override
  State<_KtsPickSectionDialog> createState() => _KtsPickSectionDialogState();
}

class _KtsPickSectionDialogState extends State<_KtsPickSectionDialog> {
  String _locLevel = 'Lokasi';
  String? _locId;
  String? _locName;

  List<Map<String, dynamic>> _allSections = [];
  List<Map<String, dynamic>> _filteredSections = [];
  bool _isLoadingSections = false;

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    _loadSections();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _title(String lang) {
    switch (lang) {
      case 'EN':
        return 'Select Section';
      case 'ZH':
        return '选择部门';
      default:
        return 'Pilih Bagian';
    }
  }

  String _searchHint(String lang) {
    switch (lang) {
      case 'EN':
        return 'Search section...';
      case 'ZH':
        return '搜索部门...';
      default:
        return 'Cari bagian...';
    }
  }

  String _emptyText(String lang) {
    switch (lang) {
      case 'EN':
        return 'No sections found';
      case 'ZH':
        return '未找到部门';
      default:
        return 'Tidak ada bagian';
    }
  }

  String _countLabel(String lang) {
    final n = _filteredSections.length;
    switch (lang) {
      case 'EN':
        return '$n sections';
      case 'ZH':
        return '$n 个部门';
      default:
        return '$n bagian';
    }
  }

  String _nameOf(Map<String, dynamic> s) {
    if (widget.lang == 'EN') return s['nama_section_en']?.toString() ?? s['nama_section_id']?.toString() ?? '-';
    if (widget.lang == 'ZH') return s['nama_section_zh']?.toString() ?? s['nama_section_id']?.toString() ?? '-';
    return s['nama_section_id']?.toString() ?? '-';
  }

  static const Map<String, String> _locIdColumn = {
    'Lokasi': 'id_lokasi',
    'Unit': 'id_unit',
    'Subunit': 'id_subunit',
    'Area': 'id_area',
  };

  Future<void> _loadSections({String? level, String? id}) async {
    setState(() => _isLoadingSections = true);
    try {
      dynamic query = Supabase.instance.client
          .from('section')
          .select('*, lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area)');
      if (level != null && id != null) {
        final idCol = _locIdColumn[level] ?? 'id_lokasi';
        query = query.eq(idCol, id);
      }

      final data = await query.order('urutan', ascending: true);
      final sections = List<Map<String, dynamic>>.from(data);
      if (mounted) {
        setState(() {
          _allSections = sections;
          _filteredSections = _applySearch(sections);
          _isLoadingSections = false;
        });
      }
    } catch (e) {
      debugPrint('Error load section: $e');
      if (mounted) setState(() => _isLoadingSections = false);
    }
  }

  List<Map<String, dynamic>> _applySearch(List<Map<String, dynamic>> src) {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return src;
    return src.where((s) => _nameOf(s).toLowerCase().contains(q)).toList();
  }

  void _onSearch() => setState(() => _filteredSections = _applySearch(_allSections));

  void _applyFilter() => _loadSections(level: _locId != null ? _locLevel : null, id: _locId);

  int get _activeFilterCount => _locId != null ? 1 : 0;

  String? get _activeFilterName => _locName;

  void _removeAllFilters() {
    setState(() {
      _locId = null;
      _locName = null;
    });
    _loadSections();
  }

  Future<void> _openLocationFilterDialog() async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => _KtsSectionLocationDialog(
        lang: widget.lang,
        initialLevel: _locLevel,
        initialId: _locId,
      ),
    );
    if (result != null) {
      setState(() {
        _locLevel = result['level'] ?? _locLevel;
        _locId = result['id'];
        _locName = result['name'];
      });
      _applyFilter();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: _kSectionDialogWidth,
        height: screenHeight * _kSectionDialogHeightFactor,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kPrimaryLight, width: 1.5),
        ),
        child: Column(children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(CupertinoIcons.square_grid_2x2_fill, color: _kAccentGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _title(widget.lang),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16, color: _kAccentGreen),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                  child: const Icon(CupertinoIcons.xmark, color: Color(0xFF64748B), size: 18),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFF1F5F9)),

          // SEARCH + FILTER
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kAccentGreen.withValues(alpha: 0.4), width: 1.3),
                    boxShadow: [BoxShadow(color: _kAccentGreen.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF0F172A), fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: _searchHint(widget.lang),
                      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFFBDBDBD)),
                      prefixIcon: const Icon(CupertinoIcons.search, color: _kAccentGreen, size: 19),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _openLocationFilterDialog,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _activeFilterCount > 0 ? _kAccentGreen : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _activeFilterCount > 0 ? _kAccentGreen : _kAccentGreen.withValues(alpha: 0.35), width: 1.3),
                    boxShadow: [BoxShadow(color: _kAccentGreen.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Icon(Icons.map, color: _activeFilterCount > 0 ? Colors.white : _kAccentGreen, size: 20),
                ),
              ),
            ]),
          ),

          // COUNT + ACTIVE LOCATION CHIP
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kAccentGreenLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kAccentGreenBorder),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(CupertinoIcons.square_grid_2x2_fill, size: 12, color: _kAccentGreen),
                    const SizedBox(width: 6),
                    Text(
                      _countLabel(widget.lang),
                      style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: _kAccentGreen),
                    ),
                  ]),
                ),
                if (_activeFilterName != null)
                  GestureDetector(
                    onTap: _removeAllFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _kAccentGreenLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kAccentGreenBorder),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(CupertinoIcons.location_solid, size: 12, color: _kAccentGreen),
                        const SizedBox(width: 6),
                        Text(
                          _activeFilterName!,
                          style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: _kAccentGreen),
                        ),
                        const SizedBox(width: 6),
                        const Icon(CupertinoIcons.xmark_circle_fill, size: 13, color: _kAccentGreen),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kAccentGreenBorder),

          // LIST
          Expanded(
            child: _isLoadingSections
                ? _sectionPickerShimmerList()
                : _filteredSections.isEmpty
                    ? Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(CupertinoIcons.square_grid_2x2, size: 44, color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 10),
                          Text(_emptyText(widget.lang), style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                        ]),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 6, bottom: 12),
                        itemCount: _filteredSections.length,
                        itemBuilder: (_, i) {
                          final s = _filteredSections[i];
                          final name = _nameOf(s);
                          return InkWell(
                            onTap: () => Navigator.pop(context, s),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _kAccentGreenBorder),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(CupertinoIcons.square_grid_2x2_fill, color: _kAccentGreen, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                                      const SizedBox(height: 4),
                                      _sectionLocationBadge(s),
                                    ],
                                  ),
                                ),
                                const Icon(CupertinoIcons.chevron_right, size: 14, color: Color(0xFFCBD5E1)),
                              ]),
                            ),
                          );
                        },
                      ),
          ),
        ]),
      ),
    );
  }
}

class _KtsSectionLocationDialog extends StatefulWidget {
  final String lang;
  final String initialLevel;
  final String? initialId;

  const _KtsSectionLocationDialog({
    required this.lang,
    required this.initialLevel,
    this.initialId,
  });

  @override
  State<_KtsSectionLocationDialog> createState() => _KtsSectionLocationDialogState();
}

class _KtsSectionLocationDialogState extends State<_KtsSectionLocationDialog> {
  static const Color _kPrimary       = Color(0xFF1D4ED8);
  static const Color _kPrimaryLight  = Color(0xFFEFF6FF);
  static const Color _kTextSecondary = Color(0xFF64748B);
  static const Color _kTextMuted     = Color(0xFFBDBDBD);

  static const double _kDialogWidth = 340;
  static const double _kDialogHeightFactor = 0.72;

  static const List<String> _kLevels = ['Lokasi', 'Unit', 'Subunit', 'Area'];
  static const List<Color> _kLevelColors = [
    Color(0xFF10B981),
    Color(0xFF6366F1),
    Color(0xFFFBBF24),
    Color(0xFFF472B6),
  ];

  static const Map<String, String> _idColByLevel = {
    'lokasi': 'id_lokasi', 'unit': 'id_unit', 'subunit': 'id_subunit', 'area': 'id_area',
  };
  static const Map<String, String> _nameColByLevel = {
    'lokasi': 'nama_lokasi', 'unit': 'nama_unit', 'subunit': 'nama_subunit', 'area': 'nama_area',
  };

  final _supabase = Supabase.instance.client;
  final TextEditingController _searchCtrl = TextEditingController();

  String _level = 'Lokasi';
  String? _selectedId;
  final Map<String, List<Map<String, String>>> _dataByLevel = {
    'Lokasi': [], 'Unit': [], 'Subunit': [], 'Area': [],
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
      case 'EN': return 'Select Specific Location';
      case 'ZH': return '选择具体位置';
      default: return 'Pilih Lokasi Spesifik';
    }
  }

  String get _searchHint {
    switch (widget.lang) {
      case 'EN': return 'Search...';
      case 'ZH': return '搜索...';
      default: return 'Cari...';
    }
  }

  String _levelLabel(String level) {
    switch (level) {
      case 'Unit': return widget.lang == 'ZH' ? '部门' : 'Unit';
      case 'Subunit': return widget.lang == 'ZH' ? '子部门' : 'Sub-Unit';
      case 'Area': return widget.lang == 'ZH' ? '区域' : 'Area';
      default: return widget.lang == 'EN' ? 'Location' : widget.lang == 'ZH' ? '位置' : 'Lokasi';
    }
  }

  IconData _levelIcon(String level) {
    switch (level) {
      case 'Unit': return Icons.business_rounded;
      case 'Subunit': return Icons.layers_rounded;
      case 'Area': return Icons.place_rounded;
      default: return Icons.location_city_rounded;
    }
  }

  String get _allLabel {
    switch (widget.lang) {
      case 'EN': return 'All (${_levelLabel(_level)})';
      case 'ZH': return '全部 (${_levelLabel(_level)})';
      default: return 'Semua (${_levelLabel(_level)})';
    }
  }

  String get _emptyLabel {
    switch (widget.lang) {
      case 'EN': return 'No data at this level';
      case 'ZH': return '该级别没有数据';
      default: return 'Tidak ada data pada level ini';
    }
  }

  Future<void> _fetchAllLevels() async {
    setState(() => _loading = true);
    try {
      for (final lvl in _kLevels) {
        final levelLower = lvl.toLowerCase();
        final idCol = _idColByLevel[levelLower] ?? 'id_lokasi';
        final nameCol = _nameColByLevel[levelLower] ?? 'nama_lokasi';
        final res = await _supabase.from(levelLower).select('$idCol, $nameCol').order(nameCol);
        _dataByLevel[lvl] = List<Map<String, dynamic>>.from(res)
            .map((e) => {'id': e[idCol]?.toString() ?? '', 'name': e[nameCol]?.toString() ?? '-'})
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetch location filter (KTS Section): $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 64,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  int get _levelColorIndex => _kLevels.indexOf(_level);

  @override
  Widget build(BuildContext context) {
    final q = _searchCtrl.text.trim().toLowerCase();
    List<Map<String, String>> filtered;

    if (q.isEmpty) {
      filtered = _dataByLevel[_level] ?? [];
    } else {
      final currentMatches = (_dataByLevel[_level] ?? []).where((e) => e['name']!.toLowerCase().contains(q)).toList();
      if (currentMatches.isNotEmpty) {
        filtered = currentMatches;
      } else {
        String? matchLevel;
        List<Map<String, String>> matchResult = [];
        for (final lvl in _kLevels) {
          if (lvl == _level) continue;
          final matches = (_dataByLevel[lvl] ?? []).where((e) => e['name']!.toLowerCase().contains(q)).toList();
          if (matches.isNotEmpty) { matchLevel = lvl; matchResult = matches; break; }
        }
        filtered = matchResult;
        if (matchLevel != null) {
          final resolvedLevel = matchLevel;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _level != resolvedLevel) {
              setState(() { _level = resolvedLevel; _selectedId = null; });
            }
          });
        }
      }
    }

    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: _kDialogWidth,
        height: screenHeight * _kDialogHeightFactor,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kPrimaryLight, width: 1.5),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.map, color: _kPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(_title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: _kPrimary)),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              children: List.generate(_kLevels.length, (index) {
                final lvl = _kLevels[index];
                final isActive = lvl == _level;
                final color = _kLevelColors[index];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() { _level = lvl; _selectedId = null; _searchCtrl.clear(); }),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive ? color : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isActive ? color : const Color(0xFFE2E8F0)),
                        boxShadow: isActive
                            ? [BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 8, offset: const Offset(0, 3))]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_levelIcon(lvl), size: 15, color: isActive ? Colors.white : color),
                          const SizedBox(height: 3),
                          Text(
                            _levelLabel(lvl),
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kPrimary.withValues(alpha: 0.35), width: 1.3),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: _searchHint,
                  hintStyle: TextStyle(fontSize: 12.5, color: _kTextMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: _kAccentGreen, size: 18),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          Container(height: 1, color: const Color(0xFFEFF6FF)),
          Expanded(
            child: _loading
                ? _buildShimmerList()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                    children: [
                      _buildAllCard(),
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(_emptyLabel, style: const TextStyle(fontSize: 12.5, color: _kTextSecondary)),
                          ),
                        )
                      else
                        ...filtered.map((item) => _buildItemCard(item)),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _buildAllCard() {
    final isSel = _selectedId == null;
    final color = _kLevelColors[_levelColorIndex];
    return GestureDetector(
      onTap: () => Navigator.pop(context, {'level': _level, 'id': null, 'name': null}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFE0F2FE) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSel ? _kPrimary : const Color(0xFFE2E8F0), width: isSel ? 1.5 : 1),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.apps_rounded, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_allLabel, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0F172A))),
          ),
          if (isSel)
            const Icon(Icons.check_circle_rounded, color: _kPrimary, size: 20)
          else
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
        ]),
      ),
    );
  }

  Widget _buildItemCard(Map<String, String> item) {
    final isSel = item['id'] == _selectedId;
    final color = _kLevelColors[_levelColorIndex];
    final name = item['name'] ?? '-';
    final initials = name.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

    return GestureDetector(
      onTap: () => Navigator.pop(context, {'level': _level, 'id': item['id'], 'name': item['name']}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFE0F2FE) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSel ? _kPrimary : const Color(0xFFE2E8F0), width: isSel ? 1.5 : 1),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
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
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0F172A)),
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
                    Icon(_levelIcon(_level), size: 10, color: color),
                    const SizedBox(width: 3),
                    Text(_levelLabel(_level), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
                  ]),
                ),
              ],
            ),
          ),
          if (isSel)
            const Icon(Icons.check_circle_rounded, color: _kPrimary, size: 20)
          else
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
        ]),
      ),
    );
  }
}