import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _kPrimary = Color(0xFF1D4ED8);
const Color _kPrimaryLight = Color(0xFFEFF6FF);
const Color _kBorder = Color(0xFFBFDBFE);

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
  List<Map<String, dynamic>> _lokasiList = [];
  List<Map<String, dynamic>> _unitList = [];
  List<Map<String, dynamic>> _subunitList = [];
  List<Map<String, dynamic>> _areaList = [];

  String? _selLokasiId;
  String? _selUnitId;
  String? _selSubunitId;
  String? _selAreaId;
  String? _selLokasiName;
  String? _selUnitName;
  String? _selSubunitName;
  String? _selAreaName;

  List<Map<String, dynamic>> _allSections = [];
  List<Map<String, dynamic>> _filteredSections = [];
  bool _isLoadingLocations = true;
  bool _isLoadingSections = false;

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    _loadLocations();
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

  Future<void> _loadLocations() async {
    try {
      final data = await Supabase.instance.client.from('lokasi').select('id_lokasi, nama_lokasi').order('nama_lokasi');
      if (mounted) setState(() { _lokasiList = List<Map<String, dynamic>>.from(data); _isLoadingLocations = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocations = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUnit(String lokasiId) async {
    final res = await Supabase.instance.client.from('unit').select('id_unit, nama_unit').eq('id_lokasi', lokasiId).order('nama_unit');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> _fetchSubunit(String unitId) async {
    final res = await Supabase.instance.client.from('subunit').select('id_subunit, nama_subunit').eq('id_unit', unitId).order('nama_subunit');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> _fetchArea(String subunitId) async {
    final res = await Supabase.instance.client.from('area').select('id_area, nama_area').eq('id_subunit', subunitId).order('nama_area');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> _loadSections({String? lokasiId, String? unitId, String? subunitId, String? areaId}) async {
    setState(() => _isLoadingSections = true);
    try {
      dynamic query = Supabase.instance.client
          .from('section')
          .select('*, lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area)');
      if (areaId != null) {
        query = query.eq('id_area', areaId);
      } else if (subunitId != null) {
        query = query.eq('id_subunit', subunitId);
      } else if (unitId != null) {
        query = query.eq('id_unit', unitId);
      } else if (lokasiId != null) {
        query = query.eq('id_lokasi', lokasiId);
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

  void _applyFilter() => _loadSections(lokasiId: _selLokasiId, unitId: _selUnitId, subunitId: _selSubunitId, areaId: _selAreaId);

  int get _activeFilterCount {
    int c = 0;
    if (_selLokasiId != null) c++;
    if (_selUnitId != null) c++;
    if (_selSubunitId != null) c++;
    if (_selAreaId != null) c++;
    return c;
  }

  String? get _activeFilterName => _selAreaName ?? _selSubunitName ?? _selUnitName ?? _selLokasiName;

  void _removeAllFilters() {
    setState(() {
      _selLokasiId = null; _selLokasiName = null;
      _selUnitId = null; _selUnitName = null;
      _selSubunitId = null; _selSubunitName = null;
      _selAreaId = null; _selAreaName = null;
      _unitList = []; _subunitList = []; _areaList = [];
    });
    _loadSections();
  }

  Future<void> _openFilterDialog() async {
    String? tLokasiId = _selLokasiId;
    String? tLokasiName = _selLokasiName;
    String? tUnitId = _selUnitId;
    String? tUnitName = _selUnitName;
    String? tSubunitId = _selSubunitId;
    String? tSubunitName = _selSubunitName;
    String? tAreaId = _selAreaId;
    String? tAreaName = _selAreaName;
    List<Map<String, dynamic>> tUnitList = List.from(_unitList);
    List<Map<String, dynamic>> tSubunitList = List.from(_subunitList);
    List<Map<String, dynamic>> tAreaList = List.from(_areaList);

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDlg) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
                  decoration: BoxDecoration(
                    color: _kPrimaryLight.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.slider_horizontal_3, color: _kPrimary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.lang == 'EN' ? 'Filter Location' : widget.lang == 'ZH' ? '筛选位置' : 'Filter Lokasi',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(dialogCtx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                          child: Icon(CupertinoIcons.xmark, size: 15, color: Colors.grey.shade500),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _isLoadingLocations
                            ? const Center(child: CupertinoActivityIndicator())
                            : _buildFilterChips(
                                label: widget.lang == 'EN' ? 'Location' : widget.lang == 'ZH' ? '位置' : 'Lokasi',
                                icon: CupertinoIcons.building_2_fill,
                                items: _lokasiList,
                                idKey: 'id_lokasi', nameKey: 'nama_lokasi',
                                selectedId: tLokasiId,
                                onSelect: (id) async {
                                  final selected = _lokasiList.firstWhere((e) => e['id_lokasi'].toString() == id);
                                  final units = await _fetchUnit(id);
                                  setDlg(() {
                                    tLokasiId = id;
                                    tLokasiName = selected['nama_lokasi']?.toString();
                                    tUnitId = null; tUnitName = null;
                                    tSubunitId = null; tSubunitName = null;
                                    tAreaId = null; tAreaName = null;
                                    tUnitList = units; tSubunitList = []; tAreaList = [];
                                  });
                                },
                              ),
                        if (tLokasiId != null && tUnitList.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildFilterChips(
                            label: 'Unit', icon: CupertinoIcons.squares_below_rectangle,
                            items: tUnitList, idKey: 'id_unit', nameKey: 'nama_unit',
                            selectedId: tUnitId,
                            onSelect: (id) async {
                              final selected = tUnitList.firstWhere((e) => e['id_unit'].toString() == id);
                              final subs = await _fetchSubunit(id);
                              setDlg(() {
                                tUnitId = id;
                                tUnitName = selected['nama_unit']?.toString();
                                tSubunitId = null; tSubunitName = null;
                                tAreaId = null; tAreaName = null;
                                tSubunitList = subs; tAreaList = [];
                              });
                            },
                          ),
                        ],
                        if (tUnitId != null && tSubunitList.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildFilterChips(
                            label: 'Sub-Unit', icon: CupertinoIcons.layers_alt_fill,
                            items: tSubunitList, idKey: 'id_subunit', nameKey: 'nama_subunit',
                            selectedId: tSubunitId,
                            onSelect: (id) async {
                              final selected = tSubunitList.firstWhere((e) => e['id_subunit'].toString() == id);
                              final areas = await _fetchArea(id);
                              setDlg(() {
                                tSubunitId = id;
                                tSubunitName = selected['nama_subunit']?.toString();
                                tAreaId = null; tAreaName = null;
                                tAreaList = areas;
                              });
                            },
                          ),
                        ],
                        if (tSubunitId != null && tAreaList.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildFilterChips(
                            label: 'Area', icon: CupertinoIcons.location_fill,
                            items: tAreaList, idKey: 'id_area', nameKey: 'nama_area',
                            selectedId: tAreaId,
                            onSelect: (id) {
                              final selected = tAreaList.firstWhere((e) => e['id_area'].toString() == id);
                              setDlg(() { tAreaId = id; tAreaName = selected['nama_area']?.toString(); });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, -2))]),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setDlg(() {
                              tLokasiId = null; tLokasiName = null;
                              tUnitId = null; tUnitName = null;
                              tSubunitId = null; tSubunitName = null;
                              tAreaId = null; tAreaName = null;
                              tUnitList = []; tSubunitList = []; tAreaList = [];
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _kBorder),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            widget.lang == 'EN' ? 'Reset' : widget.lang == 'ZH' ? '重置' : 'Reset',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selLokasiId = tLokasiId; _selLokasiName = tLokasiName;
                              _selUnitId = tUnitId; _selUnitName = tUnitName;
                              _selSubunitId = tSubunitId; _selSubunitName = tSubunitName;
                              _selAreaId = tAreaId; _selAreaName = tAreaName;
                              _unitList = tUnitList; _subunitList = tSubunitList; _areaList = tAreaList;
                            });
                            Navigator.pop(dialogCtx);
                            _applyFilter();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            widget.lang == 'EN' ? 'Apply' : widget.lang == 'ZH' ? '应用' : 'Terapkan',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips({
    required String label,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String nameKey,
    required String? selectedId,
    required Function(String id) onSelect,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 13, color: _kPrimary), const SizedBox(width: 6), Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)))]),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: items.map((item) {
            final id = item[idKey].toString();
            final name = item[nameKey] as String;
            final isSelected = selectedId == id;
            return GestureDetector(
              onTap: () => onSelect(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? _kPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? _kPrimary : _kBorder),
                  boxShadow: isSelected ? [BoxShadow(color: _kPrimary.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))] : null,
                ),
                child: Text(name, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFF1E293B))),
              ),
            );
          }).toList(),
        ),
      ],
    );
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
                child: const Icon(CupertinoIcons.square_grid_2x2_fill, color: _kPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _title(widget.lang),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16, color: _kPrimary),
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
                    border: Border.all(color: _kPrimary.withValues(alpha: 0.35), width: 1.3),
                    boxShadow: [BoxShadow(color: _kPrimary.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF0F172A), fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: _searchHint(widget.lang),
                      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFFBDBDBD)),
                      prefixIcon: const Icon(CupertinoIcons.search, color: _kPrimary, size: 19),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _openFilterDialog,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _activeFilterCount > 0 ? _kPrimary : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _activeFilterCount > 0 ? _kPrimary : _kPrimary.withValues(alpha: 0.35), width: 1.3),
                    boxShadow: [BoxShadow(color: _kPrimary.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Icon(CupertinoIcons.slider_horizontal_3, color: _activeFilterCount > 0 ? Colors.white : _kPrimary, size: 20),
                ),
              ),
            ]),
          ),

          // COUNT + ACTIVE LOCATION CHIP
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, bottom: 4),
            child: Row(children: [
              Text(_countLabel(widget.lang), style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              if (_activeFilterName != null) ...[
                const Spacer(),
                Flexible(
                  child: GestureDetector(
                    onTap: _removeAllFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Flexible(
                          child: Text(
                            _activeFilterName!,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(CupertinoIcons.xmark_circle_fill, size: 13, color: _kPrimary),
                      ]),
                    ),
                  ),
                ),
              ],
            ]),
          ),
          const Divider(height: 1, color: _kBorder),

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
                                border: Border.all(color: _kBorder),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(CupertinoIcons.square_grid_2x2_fill, color: _kPrimary, size: 18),
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