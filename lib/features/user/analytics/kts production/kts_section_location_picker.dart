import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Hasil yang dikembalikan oleh [showKtsSectionLocationPicker].
/// - [isAllSections] = true  -> user memilih "Semua Bagian" (filter di-reset).
/// - [sectionName]           -> nama bagian (nama_section_id) yang dipilih.
class KtsSectionPickResult {
  final bool isAllSections;
  final String? sectionName;

  const KtsSectionPickResult.all()
      : isAllSections = true,
        sectionName = null;

  const KtsSectionPickResult.section(this.sectionName) : isAllSections = false;
}

/// Menampilkan bottom sheet untuk memilih "bagian" (section) dengan filter
/// lokasi bertingkat (Lokasi -> Unit -> Sub-Unit -> Area), meniru picker
/// section yang dipakai di form penyelesaian KtsDetailScreen. Selalu
/// menyediakan opsi "Semua Bagian" di paling atas.
Future<KtsSectionPickResult?> showKtsSectionLocationPicker(
  BuildContext context, {
  required String lang,
}) {
  return showModalBottomSheet<KtsSectionPickResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _KtsSectionLocationPickerSheet(lang: lang),
  );
}

class _KtsSectionLocationPickerSheet extends StatefulWidget {
  final String lang;
  const _KtsSectionLocationPickerSheet({required this.lang});

  @override
  State<_KtsSectionLocationPickerSheet> createState() =>
      _KtsSectionLocationPickerSheetState();
}

class _KtsSectionLocationPickerSheetState
    extends State<_KtsSectionLocationPickerSheet> {
  static const Color _kPrimary      = Color(0xFF1D4ED8);
  static const Color _kPrimaryLight = Color(0xFFEFF6FF);
  static const Color _kBorder       = Color(0xFFBFDBFE);

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

  // Selalu pakai nama Indonesia agar konsisten dengan data "bagian"
  // yang tersimpan di tabel penyelesaian / User.bagian_kasie.
  String _nameOf(Map<String, dynamic> s) => s['nama_section_id']?.toString() ?? '-';

  String _locationBadge(Map<String, dynamic> s) {
    final parts = <String>[];
    if (s['lokasi']?['nama_lokasi'] != null) parts.add(s['lokasi']['nama_lokasi']);
    if (s['unit']?['nama_unit'] != null) parts.add(s['unit']['nama_unit']);
    if (s['subunit']?['nama_subunit'] != null) parts.add(s['subunit']['nama_subunit']);
    if (s['area']?['nama_area'] != null) parts.add(s['area']['nama_area']);
    return parts.isEmpty ? '' : parts.join(' • ');
  }

  Future<void> _loadLocations() async {
    try {
      final data = await Supabase.instance.client
          .from('lokasi')
          .select('id_lokasi, nama_lokasi')
          .order('nama_lokasi');
      if (mounted) {
        setState(() {
          _lokasiList = List<Map<String, dynamic>>.from(data);
          _isLoadingLocations = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocations = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUnit(String lokasiId) async {
    final res = await Supabase.instance.client
        .from('unit')
        .select('id_unit, nama_unit')
        .eq('id_lokasi', lokasiId)
        .order('nama_unit');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> _fetchSubunit(String unitId) async {
    final res = await Supabase.instance.client
        .from('subunit')
        .select('id_subunit, nama_subunit')
        .eq('id_unit', unitId)
        .order('nama_subunit');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> _fetchArea(String subunitId) async {
    final res = await Supabase.instance.client
        .from('area')
        .select('id_area, nama_area')
        .eq('id_subunit', subunitId)
        .order('nama_area');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> _loadSections({
    String? lokasiId,
    String? unitId,
    String? subunitId,
    String? areaId,
  }) async {
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
      debugPrint('Error load section (picker): $e');
      if (mounted) setState(() => _isLoadingSections = false);
    }
  }

  List<Map<String, dynamic>> _applySearch(List<Map<String, dynamic>> src) {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return src;
    return src.where((s) => _nameOf(s).toLowerCase().contains(q)).toList();
  }

  void _onSearch() => setState(() => _filteredSections = _applySearch(_allSections));

  void _applyFilter() => _loadSections(
      lokasiId: _selLokasiId, unitId: _selUnitId, subunitId: _selSubunitId, areaId: _selAreaId);

  int get _activeFilterCount {
    int c = 0;
    if (_selLokasiId != null) c++;
    if (_selUnitId != null) c++;
    if (_selSubunitId != null) c++;
    if (_selAreaId != null) c++;
    return c;
  }

  Widget _activeFilterChip({required IconData icon, required String label, required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _kPrimaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _kPrimary),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(label,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _kPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(CupertinoIcons.xmark_circle_fill, size: 15, color: _kPrimary),
          ),
        ],
      ),
    );
  }

  void _removeLokasiFilter() {
    setState(() {
      _selLokasiId = null; _selLokasiName = null;
      _selUnitId = null; _selUnitName = null;
      _selSubunitId = null; _selSubunitName = null;
      _selAreaId = null; _selAreaName = null;
      _unitList = []; _subunitList = []; _areaList = [];
    });
    _loadSections();
  }

  void _removeUnitFilter() {
    setState(() {
      _selUnitId = null; _selUnitName = null;
      _selSubunitId = null; _selSubunitName = null;
      _selAreaId = null; _selAreaName = null;
      _subunitList = []; _areaList = [];
    });
    _applyFilter();
  }

  void _removeSubunitFilter() {
    setState(() {
      _selSubunitId = null; _selSubunitName = null;
      _selAreaId = null; _selAreaName = null;
      _areaList = [];
    });
    _applyFilter();
  }

  void _removeAreaFilter() {
    setState(() {
      _selAreaId = null; _selAreaName = null;
    });
    _applyFilter();
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
                              setDlg(() {
                                tAreaId = id;
                                tAreaName = selected['nama_area']?.toString();
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  decoration: BoxDecoration(
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, -2))],
                  ),
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
        Row(children: [
          Icon(icon, size: 13, color: _kPrimary),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        ]),
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
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.88,
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(10)), child: const Icon(CupertinoIcons.square_grid_2x2_fill, color: _kPrimary, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.lang == 'ZH' ? '选择部门' : widget.lang == 'EN' ? 'Select Section' : 'Pilih Bagian', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)))),
              IconButton(icon: const Icon(CupertinoIcons.xmark, color: Color(0xFF94A3B8), size: 20), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          Container(
            color: const Color(0xFFF8FAFF),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  GestureDetector(
                    onTap: _openFilterDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: _activeFilterCount > 0 ? _kPrimary : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _activeFilterCount > 0 ? _kPrimary : _kBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.slider_horizontal_3, size: 15, color: _activeFilterCount > 0 ? Colors.white : _kPrimary),
                          const SizedBox(width: 6),
                          Text(
                            widget.lang == 'EN' ? 'Filter Location' : widget.lang == 'ZH' ? '筛选位置' : 'Filter Lokasi',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _activeFilterCount > 0 ? Colors.white : _kPrimary),
                          ),
                          if (_activeFilterCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: Text('$_activeFilterCount', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: _kPrimary)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_activeFilterCount > 0)
                    GestureDetector(
                      onTap: _removeLokasiFilter,
                      child: Text(
                        widget.lang == 'EN' ? 'Reset all' : widget.lang == 'ZH' ? '全部重置' : 'Reset Semua',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8), decoration: TextDecoration.underline),
                      ),
                    ),
                ]),
                if (_activeFilterCount > 0) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      if (_selLokasiId != null)
                        _activeFilterChip(icon: CupertinoIcons.building_2_fill, label: _selLokasiName ?? '-', onRemove: _removeLokasiFilter),
                      if (_selUnitId != null)
                        _activeFilterChip(icon: CupertinoIcons.squares_below_rectangle, label: _selUnitName ?? '-', onRemove: _removeUnitFilter),
                      if (_selSubunitId != null)
                        _activeFilterChip(icon: CupertinoIcons.layers_alt_fill, label: _selSubunitName ?? '-', onRemove: _removeSubunitFilter),
                      if (_selAreaId != null)
                        _activeFilterChip(icon: CupertinoIcons.location_fill, label: _selAreaName ?? '-', onRemove: _removeAreaFilter),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: Color(0xFFE0E7FF), height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextFormField(
              controller: _searchCtrl,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: widget.lang == 'ZH' ? '搜索部门...' : widget.lang == 'EN' ? 'Search section...' : 'Cari bagian...',
                hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 14),
                prefixIcon: const Icon(CupertinoIcons.search, color: _kPrimary, size: 18),
                filled: true, fillColor: const Color(0xFFF8FAFF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorder, width: 1)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: Row(children: [
              const Icon(CupertinoIcons.square_grid_2x2, size: 13, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text('${_filteredSections.length} ${widget.lang == 'EN' ? 'sections' : widget.lang == 'ZH' ? '个部门' : 'bagian'}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
            ]),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 12),
          Expanded(
            child: _isLoadingSections
                ? const Center(child: CupertinoActivityIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    children: [
                      // OPSI "SEMUA BAGIAN" — SELALU TAMPIL DI PALING ATAS
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.pop(context, const KtsSectionPickResult.all()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: _kPrimaryLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _kPrimary.withValues(alpha: 0.35)),
                            ),
                            child: Row(children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(10)),
                                child: const Icon(CupertinoIcons.square_stack_3d_up_fill, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.lang == 'EN' ? 'All Sections' : widget.lang == 'ZH' ? '所有部门' : 'Semua Bagian',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: _kPrimary),
                                ),
                              ),
                              Icon(CupertinoIcons.chevron_right, size: 14, color: _kPrimary),
                            ]),
                          ),
                        ),
                      ),
                      if (_filteredSections.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: Column(children: [
                            const Icon(CupertinoIcons.square_grid_2x2, size: 48, color: Color(0xFFE2E8F0)),
                            const SizedBox(height: 12),
                            Text(widget.lang == 'EN' ? 'No sections found' : widget.lang == 'ZH' ? '未找到部门' : 'Tidak ada bagian', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14)),
                          ]),
                        )
                      else
                        ..._filteredSections.map((s) {
                          final name = _nameOf(s);
                          final badge = _locationBadge(s);
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => Navigator.pop(context, KtsSectionPickResult.section(name)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFF1F5F9)),
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
                                        Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1E293B))),
                                        if (badge.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(badge, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const Icon(CupertinoIcons.chevron_right, size: 14, color: Color(0xFFCBD5E1)),
                                ]),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}