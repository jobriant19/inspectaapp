import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KtsSectionPickResult {
  final bool isAllSections;
  final String? sectionName;
  final String? sectionId;

  const KtsSectionPickResult.all()
      : isAllSections = true,
        sectionName = null,
        sectionId = null;

  const KtsSectionPickResult.section(this.sectionName, {this.sectionId})
      : isAllSections = false;
}

Future<KtsSectionPickResult?> showKtsSectionLocationPicker(
  BuildContext context, {
  required String lang,
  Color accentColor = const Color(0xFF1D4ED8),
}) {
  return showDialog<KtsSectionPickResult>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: _KtsSectionLocationPickerSheet(lang: lang, accentColor: accentColor),
    ),
  );
}

// Level lokasi khas: warna & ikon konsisten dengan seluruh aplikasi
const List<String> _kLevelOrder = ['Lokasi', 'Unit', 'Subunit', 'Area'];
const List<Color> _kLevelColors = [
  Color(0xFF10B981), // Lokasi
  Color(0xFF6366F1), // Unit
  Color(0xFFFBBF24), // Subunit
  Color(0xFFF472B6), // Area
];
const List<IconData> _kLevelIcons = [
  Icons.location_city_rounded,
  Icons.business_rounded,
  Icons.layers_rounded,
  Icons.place_rounded,
];

class _KtsSectionLocationPickerSheet extends StatefulWidget {
  final String lang;
  final Color accentColor;
  const _KtsSectionLocationPickerSheet({required this.lang, required this.accentColor});

  @override
  State<_KtsSectionLocationPickerSheet> createState() =>
      _KtsSectionLocationPickerSheetState();
}

class _KtsSectionLocationPickerSheetState
    extends State<_KtsSectionLocationPickerSheet> {
  Color get _kPrimary      => widget.accentColor;
  Color get _kPrimaryLight => widget.accentColor.withValues(alpha: 0.08);
  Color get _kBorder       => widget.accentColor.withValues(alpha: 0.35);

  // FILTER LOKASI: SATU LEVEL SPESIFIK (bukan cascading lagi)
  String _filterLocLevel = 'Lokasi';
  String? _filterLocId;
  String? _filterLocName;

  List<Map<String, dynamic>> _allSections = [];
  List<Map<String, dynamic>> _filteredSections = [];
  bool _isLoadingSections = true;

  int _currentPage = 1;
  static const int _perPage = 5;

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

  String _t(String id, String en, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  String _idNameOf(Map<String, dynamic> s) => s['nama_section_id']?.toString() ?? '-';

  String _displayNameOf(Map<String, dynamic> s) {
    if (widget.lang == 'EN') {
      final en = (s['nama_section_en'] as String?)?.trim();
      if (en != null && en.isNotEmpty) return en;
    } else if (widget.lang == 'ZH') {
      final zh = (s['nama_section_zh'] as String?)?.trim();
      if (zh != null && zh.isNotEmpty) return zh;
    }
    return _idNameOf(s);
  }

  // LOKASI PALING SPESIFIK SAJA: Area > Subunit > Unit > Lokasi
  Map<String, dynamic>? _mostSpecificLocation(Map<String, dynamic> s) {
    if (s['area']?['nama_area'] != null) {
      return {'level': 'Area', 'label': s['area']['nama_area'].toString()};
    }
    if (s['subunit']?['nama_subunit'] != null) {
      return {'level': 'Subunit', 'label': s['subunit']['nama_subunit'].toString()};
    }
    if (s['unit']?['nama_unit'] != null) {
      return {'level': 'Unit', 'label': s['unit']['nama_unit'].toString()};
    }
    if (s['lokasi']?['nama_lokasi'] != null) {
      return {'level': 'Lokasi', 'label': s['lokasi']['nama_lokasi'].toString()};
    }
    return null;
  }

  Future<void> _loadSections({String? levelBackend, String? locId}) async {
    setState(() => _isLoadingSections = true);
    try {
      dynamic query = Supabase.instance.client
          .from('section')
          .select('*, lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area)');

      if (locId != null && levelBackend != null) {
        const idColMap = {
          'Lokasi': 'id_lokasi', 'Unit': 'id_unit',
          'Subunit': 'id_subunit', 'Area': 'id_area',
        };
        final idCol = idColMap[levelBackend] ?? 'id_lokasi';
        query = query.eq(idCol, locId);
      }

      final data = await query.order('urutan', ascending: true);
      final sections = List<Map<String, dynamic>>.from(data);
      if (mounted) {
        setState(() {
          _allSections = sections;
          _filteredSections = _applySearch(sections);
          _isLoadingSections = false;
          _currentPage = 1;
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
    return src.where((s) => _displayNameOf(s).toLowerCase().contains(q)).toList();
  }

  void _onSearch() => setState(() {
        _filteredSections = _applySearch(_allSections);
        _currentPage = 1;
      });

  void _applyFilter() => _loadSections(
      levelBackend: _filterLocId != null ? _filterLocLevel : null,
      locId: _filterLocId);

  void _clearLocationFilter() {
    setState(() {
      _filterLocId = null;
      _filterLocName = null;
    });
    _applyFilter();
  }

  // ─── FILTER LOCATION BUTTON (trigger) ─────────────────────────────────────
  Widget _buildLocationFilterButton() {
    final hasSelection = _filterLocId != null;
    final levelIdx = _kLevelOrder.indexOf(_filterLocLevel).clamp(0, 3);
    final color = hasSelection ? _kLevelColors[levelIdx] : _kPrimary;
    final icon = hasSelection ? _kLevelIcons[levelIdx] : Icons.tune_rounded;
    final label = hasSelection
        ? (_filterLocName ?? _filterLocLevel)
        : _t('Filter Lokasi', 'Filter Location', '筛选位置');

    return GestureDetector(
      onTap: _showLocationFilterPicker,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.10), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
          ),
          const SizedBox(width: 4),
          if (hasSelection)
            GestureDetector(
              onTap: _clearLocationFilter,
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

  // ─── POPUP FILTER LOCATION (sama persis gaya select specific location) ────
  Future<void> _showLocationFilterPicker() async {
    String tempLevel = _filterLocId != null ? _filterLocLevel : 'Lokasi';
    String? tempId = _filterLocId;
    List<Map<String, String>> items = [];
    bool loading = true;
    bool initialized = false;
    int subPage = 1;
    const int subPerPage = 5;
    final searchCtrl = TextEditingController();

    Future<void> fetchItems(void Function(void Function()) setSt) async {
      loading = true;
      setSt(() {});
      final levelLower = tempLevel.toLowerCase();
      const idMap = {'lokasi': 'id_lokasi', 'unit': 'id_unit', 'subunit': 'id_subunit', 'area': 'id_area'};
      const nameMap = {'lokasi': 'nama_lokasi', 'unit': 'nama_unit', 'subunit': 'nama_subunit', 'area': 'nama_area'};
      final idCol = idMap[levelLower] ?? 'id_lokasi';
      final nameCol = nameMap[levelLower] ?? 'nama_lokasi';
      try {
        final res = await Supabase.instance.client.from(levelLower).select('$idCol, $nameCol').order(nameCol);
        items = List<Map<String, dynamic>>.from(res)
            .map((e) => {'id': e[idCol]?.toString() ?? '', 'name': e[nameCol]?.toString() ?? '-'})
            .toList();
      } catch (e) {
        items = [];
      }
      loading = false;
      subPage = 1;
      setSt(() {});
    }

    IconData levelIcon(String label) => _kLevelIcons[_kLevelOrder.indexOf(label).clamp(0, 3)];
    Color levelColor(String label) => _kLevelColors[_kLevelOrder.indexOf(label).clamp(0, 3)];
    String levelLabelText(String lvl) {
      switch (lvl) {
        case 'Unit':    return _t('Unit', 'Unit', '单元');
        case 'Subunit': return _t('Subunit', 'Sub-unit', '子单元');
        case 'Area':    return _t('Area', 'Area', '区域');
        default:        return _t('Lokasi', 'Location', '位置');
      }
    }

    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          if (!initialized) { initialized = true; fetchItems(setSt); }
          final q = searchCtrl.text.trim().toLowerCase();
          final filtered = q.isEmpty ? items : items.where((e) => e['name']!.toLowerCase().contains(q)).toList();
          final currentColor = levelColor(tempLevel);

          final totalPages = filtered.isEmpty ? 1 : (filtered.length / subPerPage).ceil();
          final safePage = subPage.clamp(1, totalPages);
          final start = (safePage - 1) * subPerPage;
          final end = (start + subPerPage) > filtered.length ? filtered.length : start + subPerPage;
          final pageItems = filtered.isEmpty ? <Map<String, String>>[] : filtered.sublist(start, end);

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 340,
              height: MediaQuery.of(context).size.height * 0.78,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kPrimary.withValues(alpha: 0.25), width: 1.5),
              ),
              child: Column(children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.tune_rounded, color: _kPrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_t('Filter Lokasi', 'Filter Location', '筛选位置'),
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15, color: _kPrimary)),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 18),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 10),
                Container(height: 1, color: const Color(0xFFF1F5F9)),
                // LEVEL TABS
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: Row(children: _kLevelOrder.map((lvl) {
                    final isSel = lvl == tempLevel;
                    final color = levelColor(lvl);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () { tempLevel = lvl; tempId = null; searchCtrl.clear(); fetchItems(setSt); },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: isSel ? color : Colors.white,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: isSel ? color : const Color(0xFFE2E8F0)),
                          ),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(levelIcon(lvl), size: 14, color: isSel ? Colors.white : color),
                            const SizedBox(height: 2),
                            Text(levelLabelText(lvl),
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: isSel ? Colors.white : const Color(0xFF475569))),
                          ]),
                        ),
                      ),
                    );
                  }).toList()),
                ),
                // SEARCH
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: currentColor.withValues(alpha: 0.35), width: 1.3)),
                    child: TextField(
                      controller: searchCtrl,
                      textAlignVertical: TextAlignVertical.center,
                      onChanged: (_) => setSt(() { subPage = 1; }),
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: _t('Cari...', 'Search...', '搜索...'),
                        hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFFBDBDBD), fontWeight: FontWeight.w600),
                        prefixIcon: Icon(Icons.search_rounded, color: currentColor, size: 18),
                        suffixIcon: searchCtrl.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () => setSt(() { searchCtrl.clear(); subPage = 1; }),
                                child: Container(
                                  margin: const EdgeInsets.all(9),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), shape: BoxShape.circle),
                                  child: const Icon(Icons.close_rounded, size: 13, color: Color(0xFFEF4444)),
                                ),
                              )
                            : null,
                        border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                Container(height: 1, color: const Color(0xFFE0F2FE)),
                // LIST
                Expanded(
                  child: loading
                      ? Shimmer.fromColors(
                          baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            itemCount: 6,
                            itemBuilder: (_, __) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
                              child: Row(children: [
                                Container(width: 44, height: 44, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white)),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Container(height: 14, width: 150, color: Colors.white),
                                  const SizedBox(height: 6),
                                  Container(height: 10, width: 90, color: Colors.white),
                                ])),
                              ]),
                            ),
                          ),
                        )
                      : Column(children: [
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              children: [
                                InkWell(
                                  onTap: () => Navigator.pop(ctx, {'level': tempLevel, 'id': null, 'name': null}),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: tempId == null ? currentColor.withValues(alpha: 0.10) : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: tempId == null ? currentColor : const Color(0xFFE0F2FE), width: tempId == null ? 1.5 : 1),
                                    ),
                                    child: Row(children: [
                                      Container(
                                        width: 44, height: 44, alignment: Alignment.center,
                                        decoration: BoxDecoration(color: currentColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                                        child: Icon(Icons.map_rounded, size: 20, color: currentColor),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text('${_t('Semua', 'All', '全部')} (${levelLabelText(tempLevel)})',
                                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: tempId == null ? FontWeight.w700 : FontWeight.w600, color: tempId == null ? currentColor : const Color(0xFF1E293B))),
                                      ),
                                      if (tempId == null) Icon(Icons.check_circle_rounded, color: currentColor, size: 18),
                                    ]),
                                  ),
                                ),
                                if (filtered.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                                      Image.asset('assets/images/team_illustration.png', height: 100, fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => Container(width: 76, height: 76, decoration: BoxDecoration(color: currentColor.withValues(alpha: 0.08), shape: BoxShape.circle), child: Icon(Icons.search_off_rounded, size: 32, color: currentColor.withValues(alpha: 0.4)))),
                                      const SizedBox(height: 10),
                                      Text(_t('Tidak ada data untuk level ini.', 'No data for this level.', '此级别没有数据。'), style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: currentColor), textAlign: TextAlign.center),
                                      if (searchCtrl.text.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        GestureDetector(
                                          onTap: () => setSt(() { searchCtrl.clear(); subPage = 1; }),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                            decoration: BoxDecoration(color: currentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30), border: Border.all(color: currentColor.withValues(alpha: 0.35))),
                                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                                              Icon(Icons.refresh_rounded, size: 14, color: currentColor),
                                              const SizedBox(width: 6),
                                              Text(_t('Hapus pencarian', 'Clear search', '清除搜索'), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: currentColor)),
                                            ]),
                                          ),
                                        ),
                                      ],
                                    ]),
                                  )
                                else
                                  ...pageItems.map((item) {
                                    final isSel = item['id'] == tempId;
                                    return InkWell(
                                      onTap: () => Navigator.pop(ctx, {'level': tempLevel, 'id': item['id'], 'name': item['name']}),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isSel ? currentColor.withValues(alpha: 0.10) : Colors.white,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: isSel ? currentColor : const Color(0xFFE0F2FE), width: isSel ? 1.5 : 1),
                                        ),
                                        child: Row(children: [
                                          Container(
                                            width: 44, height: 44, alignment: Alignment.center,
                                            decoration: BoxDecoration(color: currentColor.withValues(alpha: isSel ? 0.20 : 0.14), borderRadius: BorderRadius.circular(12)),
                                            child: Icon(levelIcon(tempLevel), size: 20, color: currentColor),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(item['name']!,
                                                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: isSel ? currentColor : const Color(0xFF1E293B)),
                                                overflow: TextOverflow.ellipsis),
                                          ),
                                          if (isSel) Icon(Icons.check_circle_rounded, color: currentColor, size: 18),
                                        ]),
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                          if (totalPages > 1 && filtered.isNotEmpty)
                            _SectionPagePickerIndicator(currentPage: safePage, totalPages: totalPages, color: currentColor, onPageChanged: (p) => setSt(() => subPage = p)),
                        ]),
                ),
              ]),
            ),
          );
        },
      ),
    );

    if (result != null) {
      setState(() {
        if (result['id'] == null) {
          _filterLocId = null;
          _filterLocName = null;
          _filterLocLevel = result['level'] ?? 'Lokasi';
        } else {
          _filterLocLevel = result['level'] ?? 'Lokasi';
          _filterLocId = result['id'];
          _filterLocName = result['name'];
        }
      });
      _applyFilter();
    }
  }

  // ─── LABEL JUMLAH SECTION (dibuat lebih menarik) ───────────────────────────
  Widget _buildCountLabel() {
    final count = _filteredSections.length;
    final text = widget.lang == 'EN'
        ? '$count ${count == 1 ? 'section' : 'sections'}'
        : widget.lang == 'ZH'
            ? '$count 个部门'
            : '$count bagian';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.grid_view_rounded, size: 12, color: _kPrimary),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: _kPrimary)),
      ]),
    );
  }

  // ─── EMPTY STATE (dipakai untuk list section utama) ────────────────────────
  Widget _buildEmptyState() {
    final hasQuery = _searchCtrl.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Image.asset(
          'assets/images/team_illustration.png',
          height: 130, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            width: 90, height: 90,
            decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: Icon(Icons.search_off_rounded, size: 40, color: _kPrimary.withValues(alpha: 0.4)),
          ),
        ),
        const SizedBox(height: 14),
        Text(_t('Tidak ada bagian', 'No sections found', '未找到部门'),
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
            textAlign: TextAlign.center),
        if (hasQuery) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _searchCtrl.clear(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _kPrimary.withValues(alpha: 0.35)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.refresh_rounded, size: 14, color: _kPrimary),
                const SizedBox(width: 6),
                Text(_t('Hapus pencarian', 'Clear search', '清除搜索'),
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary)),
              ]),
            ),
          ),
        ],
      ]),
    );
  }

  // ─── CARD SECTION ──────────────────────────────────────────────────────────
  Widget _buildSectionCard(Map<String, dynamic> s) {
    final displayName = _displayNameOf(s);
    final idName = _idNameOf(s);
    final sectionId = s['id_section']?.toString();
    final loc = _mostSpecificLocation(s);
    final levelIdx = loc != null ? _kLevelOrder.indexOf(loc['level'] as String).clamp(0, 3) : -1;
    final locColor = levelIdx >= 0 ? _kLevelColors[levelIdx] : const Color(0xFF94A3B8);
    final locIcon = levelIdx >= 0 ? _kLevelIcons[levelIdx] : Icons.location_off_rounded;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pop(context, KtsSectionPickResult.section(idName, sectionId: sectionId)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.grid_view_rounded, color: _kPrimary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1E293B)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (loc != null) ...[
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: locColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: locColor.withValues(alpha: 0.4)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(locIcon, size: 10, color: locColor),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(loc['label'] as String,
                              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: locColor),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, size: 14, color: Color(0xFFCBD5E1)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width > 480 ? 480.0 : size.width - 40;
    final dialogHeight = (size.height * 0.78).clamp(420.0, 640.0);

    final totalPages = _filteredSections.isEmpty ? 1 : (_filteredSections.length / _perPage).ceil();
    final safePage = _currentPage.clamp(1, totalPages);
    final start = (safePage - 1) * _perPage;
    final end = (start + _perPage) > _filteredSections.length ? _filteredSections.length : start + _perPage;
    final pageItems = _filteredSections.isEmpty ? <Map<String, dynamic>>[] : _filteredSections.sublist(start, end);

    return Container(
      width: dialogWidth,
      height: dialogHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 28, offset: const Offset(0, 10)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(10)),
                child: Icon(CupertinoIcons.square_grid_2x2_fill, color: _kPrimary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(_t('Pilih Bagian', 'Select Section', '选择部门'),
                    style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 18),
                ),
              ),
            ]),
          ),
          // FILTER LOCATION BUTTON
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Align(alignment: Alignment.centerLeft, child: _buildLocationFilterButton()),
          ),
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder, width: 1.2),
              ),
              child: TextField(
                controller: _searchCtrl,
                textAlignVertical: TextAlignVertical.center,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: _t('Cari bagian...', 'Search section...', '搜索部门...'),
                  hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFBDBDBD), fontWeight: FontWeight.w600),
                  prefixIcon: Icon(CupertinoIcons.search, color: _kPrimary, size: 18),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _searchCtrl.clear(),
                          child: Container(
                            margin: const EdgeInsets.all(10),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFEF4444)),
                          ),
                        )
                      : null,
                  border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          // COUNT LABEL
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: Align(alignment: Alignment.centerLeft, child: _buildCountLabel()),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 14),
          // LIST + PAGINATION
          Expanded(
            child: _isLoadingSections
                ? const Center(child: CupertinoActivityIndicator())
                : Column(children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                        children: [
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
                                    child: Text(_t('Semua Bagian', 'All Sections', '所有部门'),
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: _kPrimary)),
                                  ),
                                  Icon(CupertinoIcons.chevron_right, size: 14, color: _kPrimary),
                                ]),
                              ),
                            ),
                          ),
                          if (_filteredSections.isEmpty)
                            _buildEmptyState()
                          else
                            ...pageItems.map(_buildSectionCard),
                        ],
                      ),
                    ),
                    if (totalPages > 1 && _filteredSections.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: _SectionPagePickerIndicator(
                          currentPage: safePage,
                          totalPages: totalPages,
                          color: _kPrimary,
                          onPageChanged: (p) => setState(() => _currentPage = p),
                        ),
                      ),
                  ]),
          ),
        ],
      ),
    );
  }
}

// ─── PAGINATION INDICATOR (dipakai list section utama & popup filter lokasi) ─
class _SectionPagePickerIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Color color;
  final ValueChanged<int> onPageChanged;

  const _SectionPagePickerIndicator({
    required this.currentPage,
    required this.totalPages,
    required this.color,
    required this.onPageChanged,
  });

  static const int _maxVisibleButtons = 5;

  List<int> _visiblePageNumbers() {
    if (totalPages <= _maxVisibleButtons) {
      return List.generate(totalPages, (i) => i + 1);
    }
    int start = currentPage - 2;
    int end = currentPage + 2;
    if (start < 1) { start = 1; end = _maxVisibleButtons; }
    else if (end > totalPages) { end = totalPages; start = totalPages - (_maxVisibleButtons - 1); }
    return List.generate(end - start + 1, (i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    final bool canPrev = currentPage > 1;
    final bool canNext = currentPage < totalPages;
    final pageNumbers = _visiblePageNumbers();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        GestureDetector(
          onTap: canPrev ? () => onPageChanged(currentPage - 1) : null,
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: canPrev ? color.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: canPrev ? color : Colors.grey.shade400),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(children: [
            for (final p in pageNumbers) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => p == currentPage ? null : onPageChanged(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p == currentPage ? color : color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: p == currentPage ? null : Border.all(color: color.withValues(alpha: 0.25)),
                    ),
                    child: Text('$p',
                        style: GoogleFonts.poppins(color: p == currentPage ? Colors.white : color, fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              ),
              if (p != pageNumbers.last) const SizedBox(width: 8),
            ],
          ]),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: canNext ? () => onPageChanged(currentPage + 1) : null,
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: canNext ? color.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_forward_ios_rounded, size: 15, color: canNext ? color : Colors.grey.shade400),
          ),
        ),
      ]),
    );
  }
}