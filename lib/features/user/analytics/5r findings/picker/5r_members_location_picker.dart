import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const List<String> _memberLocLevels = ['Lokasi', 'Unit', 'Subunit', 'Area'];

const Color _memberLocHeaderColor = Color(0xFF1D72F3); // BIRU - HEADER "SELECT SPECIFIC LOCATION"

const List<Color> _memberLocTabColors = [
  Color(0xFF10B981), // Lokasi
  Color(0xFF6366F1), // Unit
  Color(0xFFFBBF24), // Subunit
  Color(0xFFF472B6), // Area
];

IconData _memberLocLevelIcon(String level) {
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

String _memberLocLevelLabel(String level, String lang) {
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

IconData _memberLocParentIcon(String level) {
  switch (level) {
    case 'Unit':
      return Icons.location_city_rounded; // parent = Lokasi
    case 'Subunit':
      return Icons.business_rounded;      // parent = Unit
    case 'Area':
      return Icons.layers_rounded;        // parent = Subunit
    default:
      return Icons.location_city_rounded;
  }
}

const double _kMemberLocDialogWidth = 340;
const double _kMemberLocDialogHeightFactor = 0.78;
const int _kMemberLocPerPage = 7;

Future<Map<String, String?>?> showMemberLocationFilterDialog(
  BuildContext context, {
  required String lang,
  required String initialLevel,
  String? initialId,
}) {
  return showDialog<Map<String, String?>>(
    context: context,
    builder: (ctx) => _MemberLocationFilterDialog(
      lang: lang,
      initialLevel: initialLevel,
      initialId: initialId,
    ),
  );
}

class _MemberLocationFilterDialog extends StatefulWidget {
  final String lang;
  final String initialLevel;
  final String? initialId;

  const _MemberLocationFilterDialog({
    required this.lang,
    required this.initialLevel,
    this.initialId,
  });

  @override
  State<_MemberLocationFilterDialog> createState() => _MemberLocationFilterDialogState();
}

class _MemberLocationFilterDialogState extends State<_MemberLocationFilterDialog> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchCtrl = TextEditingController();

  String _level = 'Lokasi';
  String? _selectedId;
  final Map<String, List<Map<String, String>>> _dataByLevel = {
    'Lokasi': [],
    'Unit': [],
    'Subunit': [],
    'Area': [],
  };
  bool _loading = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _level = widget.initialLevel;
    _selectedId = widget.initialId;
    _searchCtrl.addListener(() => setState(() { _currentPage = 1; }));
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
        return 'Select Specific Location';
      case 'ZH':
        return '选择特定位置';
      default:
        return 'Pilih Lokasi Spesifik';
    }
  }

  String get _searchHint {
    switch (widget.lang) {
      case 'EN':
        return 'Search...';
      case 'ZH':
        return '搜索...';
      default:
        return 'Cari...';
    }
  }

  String get _allLabel {
    switch (widget.lang) {
      case 'EN':
        return 'All (${_memberLocLevelLabel(_level, widget.lang)})';
      case 'ZH':
        return '全部 (${_memberLocLevelLabel(_level, widget.lang)})';
      default:
        return 'Semua (${_memberLocLevelLabel(_level, widget.lang)})';
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
      final lokasiRes = await _supabase.from('lokasi').select('id_lokasi, nama_lokasi').order('nama_lokasi');
      _dataByLevel['Lokasi'] = List<Map<String, dynamic>>.from(lokasiRes)
          .map((e) => {
                'id': e['id_lokasi']?.toString() ?? '',
                'name': e['nama_lokasi']?.toString() ?? '-',
                'parent': '',
              })
          .toList();

      final unitRes = await _supabase
          .from('unit')
          .select('id_unit, nama_unit, lokasi(nama_lokasi)')
          .order('nama_unit');
      _dataByLevel['Unit'] = List<Map<String, dynamic>>.from(unitRes)
          .map((e) => {
                'id': e['id_unit']?.toString() ?? '',
                'name': e['nama_unit']?.toString() ?? '-',
                'parent': (e['lokasi'] as Map<String, dynamic>?)?['nama_lokasi']?.toString() ?? '',
              })
          .toList();

      final subunitRes = await _supabase
          .from('subunit')
          .select('id_subunit, nama_subunit, unit(nama_unit)')
          .order('nama_subunit');
      _dataByLevel['Subunit'] = List<Map<String, dynamic>>.from(subunitRes)
          .map((e) => {
                'id': e['id_subunit']?.toString() ?? '',
                'name': e['nama_subunit']?.toString() ?? '-',
                'parent': (e['unit'] as Map<String, dynamic>?)?['nama_unit']?.toString() ?? '',
              })
          .toList();

      final areaRes = await _supabase
          .from('area')
          .select('id_area, nama_area, subunit(nama_subunit)')
          .order('nama_area');
      _dataByLevel['Area'] = List<Map<String, dynamic>>.from(areaRes)
          .map((e) => {
                'id': e['id_area']?.toString() ?? '',
                'name': e['nama_area']?.toString() ?? '-',
                'parent': (e['subunit'] as Map<String, dynamic>?)?['nama_subunit']?.toString() ?? '',
              })
          .toList();
    } catch (e) {
      debugPrint('Error fetch member location filter: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  int get _levelColorIndex => _memberLocLevels.indexOf(_level);

  @override
  Widget build(BuildContext context) {
    final q = _searchCtrl.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? (_dataByLevel[_level] ?? [])
        : (_dataByLevel[_level] ?? []).where((e) => e['name']!.toLowerCase().contains(q)).toList();

    final totalPages = filtered.isEmpty ? 1 : (filtered.length / _kMemberLocPerPage).ceil();
    final safePage = _currentPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * _kMemberLocPerPage;
    final endIdx = (startIdx + _kMemberLocPerPage) > filtered.length ? filtered.length : startIdx + _kMemberLocPerPage;
    final pageItems = filtered.isEmpty ? <Map<String, String>>[] : filtered.sublist(startIdx, endIdx);

    final screenHeight = MediaQuery.of(context).size.height;
    final color = _memberLocTabColors[_levelColorIndex];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: _kMemberLocDialogWidth,
        height: screenHeight * _kMemberLocDialogHeightFactor,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _memberLocHeaderColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune_rounded, color: _memberLocHeaderColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(_title,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15, color: _memberLocHeaderColor)),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 18),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              children: List.generate(_memberLocLevels.length, (index) {
                final lvl = _memberLocLevels[index];
                final isActive = lvl == _level;
                final lvlColor = _memberLocTabColors[index];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _level = lvl;
                      _selectedId = null;
                      _searchCtrl.clear();
                      _currentPage = 1;
                    }),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive ? lvlColor : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isActive ? lvlColor : const Color(0xFFE2E8F0)),
                        boxShadow: isActive
                            ? [BoxShadow(color: lvlColor.withValues(alpha: 0.30), blurRadius: 8, offset: const Offset(0, 3))]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_memberLocLevelIcon(lvl), size: 15, color: isActive ? Colors.white : lvlColor),
                          const SizedBox(height: 3),
                          Text(_memberLocLevelLabel(lvl, widget.lang),
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: isActive ? Colors.white : const Color(0xFF475569))),
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
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.35), width: 1.3),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: _searchHint,
                  hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFFBDBDBD)),
                  prefixIcon: Icon(Icons.search_rounded, color: color, size: 18),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _searchCtrl.clear(),
                          child: Container(
                            margin: const EdgeInsets.all(10),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFEF4444)),
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
          const Divider(height: 1, color: Color(0xFFE0F2FE)),
          Expanded(
            child: _loading
                ? _buildMemberLocShimmer()
                : Column(children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                        children: [
                          _buildAllCard(color),
                          if (filtered.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                Image.asset(
                                  'assets/images/team_illustration.png',
                                  height: 110,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 84, height: 84,
                                    decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.08), shape: BoxShape.circle),
                                    child: Icon(Icons.search_off_rounded, size: 36, color: color.withValues(alpha: 0.4)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(_emptyLabel,
                                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: color),
                                    textAlign: TextAlign.center),
                                if (q.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: () => _searchCtrl.clear(),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(color: color.withValues(alpha: 0.35)),
                                      ),
                                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                                        Icon(Icons.refresh_rounded, size: 14, color: color),
                                        const SizedBox(width: 6),
                                        Text(
                                          widget.lang == 'EN' ? 'Clear search' : widget.lang == 'ZH' ? '清除搜索' : 'Hapus pencarian',
                                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: color),
                                        ),
                                      ]),
                                    ),
                                  ),
                                ],
                              ]),
                            )
                          else
                            ...pageItems.map((item) => _buildItemCard(item, color)),
                        ],
                      ),
                    ),
                    if (totalPages > 1)
                      _MemberLocPageIndicator(
                        currentPage: safePage,
                        totalPages: totalPages,
                        color: color,
                        onPageChanged: (p) => setState(() => _currentPage = p),
                      ),
                  ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildAllCard(Color color) {
    final isSel = _selectedId == null;
    return GestureDetector(
      onTap: () => Navigator.pop(context, {'level': _level, 'id': null, 'name': null}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFE0F2FE) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSel ? color : const Color(0xFFE2E8F0), width: isSel ? 1.5 : 1),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.map_rounded, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_allLabel,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0F172A))),
          ),
          if (isSel)
            Icon(Icons.check_circle_rounded, color: color, size: 20)
          else
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
        ]),
      ),
    );
  }

  Color _parentColorFor(String level) {
    switch (level) {
      case 'Unit':
        return _memberLocTabColors[0]; // warna khas Lokasi
      case 'Subunit':
        return _memberLocTabColors[1]; // warna khas Unit
      case 'Area':
        return _memberLocTabColors[2]; // warna khas Subunit
      default:
        return _memberLocTabColors[0];
    }
  }

  Widget _buildItemCard(Map<String, String> item, Color color) {
    final isSel = item['id'] == _selectedId;
    final name = item['name'] ?? '-';
    final parent = item['parent'] ?? '';
    final parentColor = _parentColorFor(_level);

    return GestureDetector(
      onTap: () => Navigator.pop(context, {'level': _level, 'id': item['id'], 'name': item['name']}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFE0F2FE) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSel ? color : const Color(0xFFE2E8F0), width: isSel ? 1.5 : 1),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(_memberLocLevelIcon(_level), size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0F172A))),
                const SizedBox(height: 4),
                if (_level == 'Lokasi')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_memberLocLevelIcon(_level), size: 10, color: color),
                      const SizedBox(width: 3),
                      Text(_memberLocLevelLabel(_level, widget.lang),
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
                    ]),
                  )
                else if (parent.isNotEmpty)
                  Row(children: [
                    Icon(_memberLocParentIcon(_level), size: 11, color: parentColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(parent,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10.5, color: parentColor, fontWeight: FontWeight.w600)),
                    ),
                  ]),
              ],
            ),
          ),
          if (isSel)
            Icon(Icons.check_circle_rounded, color: color, size: 20)
          else
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
        ]),
      ),
    );
  }

  Widget _buildMemberLocShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        itemCount: 7,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 64,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// ─── Page indicator, gaya sama seperti AdminUnitPageIndicator ────────────────
class _MemberLocPageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Color color;
  final ValueChanged<int> onPageChanged;

  const _MemberLocPageIndicator({
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
    if (start < 1) {
      start = 1;
      end = _maxVisibleButtons;
    } else if (end > totalPages) {
      end = totalPages;
      start = totalPages - (_maxVisibleButtons - 1);
    }
    return List.generate(end - start + 1, (i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    final bool canPrev = currentPage > 1;
    final bool canNext = currentPage < totalPages;
    final pageNumbers = _visiblePageNumbers();

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
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
                        style: GoogleFonts.poppins(
                            color: p == currentPage ? Colors.white : color,
                            fontWeight: FontWeight.w800,
                            fontSize: 13)),
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