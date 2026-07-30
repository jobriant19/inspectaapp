import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_unit_indicator.dart';

class _C {
  static const primary   = Color(0xFF6366F1);
  static const primaryLt = Color(0xFFEEF2FF);
  static const red       = Color(0xFFEF4444);
  static const textMain  = Color(0xFF1E3A8A);
  static const textSub   = Color(0xFF64748B);
}

class AdminUnitLocationFilterDialog extends StatefulWidget {
  final String lang;
  final String? initialLokasiId;
  final String? initialUnitId;

  const AdminUnitLocationFilterDialog({
    super.key,
    required this.lang,
    this.initialLokasiId,
    this.initialUnitId,
  });

  @override
  State<AdminUnitLocationFilterDialog> createState() => _AdminUnitLocationFilterDialogState();
}

class _AdminUnitLocationFilterDialogState extends State<AdminUnitLocationFilterDialog> {
  static const _levels = ['Lokasi', 'Subunit', 'Area'];
  static const _levelColors = [
    Color(0xFF10B981),
    Color(0xFFFBBF24),
    Color(0xFFF472B6),
  ];
  static const int _perPage = 5;

  final TextEditingController _searchCtrl = TextEditingController();
  int _tabIndex = 0;
  int _currentPage = 1;
  bool _isLoading = true;

  List<Map<String, dynamic>> _lokasiData = [];
  List<Map<String, dynamic>> _subunitData = [];
  List<Map<String, dynamic>> _areaData = [];

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialUnitId != null ? 1 : 0;
    _searchCtrl.addListener(() => setState(() {}));
    _loadAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _t(String id, String en, String zh) =>
      widget.lang == 'EN' ? en : widget.lang == 'ZH' ? zh : id;

  String get _dialogTitle => _t('Filter Lokasi Spesifik', 'Specific Location Filter', '特定位置筛选');

  IconData _levelIcon(int i) {
    switch (i) {
      case 1:
        return Icons.layers_rounded;
      case 2:
        return Icons.place_rounded;
      default:
        return Icons.location_city_rounded;
    }
  }

  String _levelLabel(int i) {
    switch (i) {
      case 1:
        return _t('Subunit', 'Subunit', '子部门');
      case 2:
        return _t('Area', 'Area', '区域');
      default:
        return _t('Lokasi', 'Location', '位置');
    }
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final results = await Future.wait([
        supabase.from('lokasi').select('id_lokasi, nama_lokasi').order('nama_lokasi'),
        supabase
            .from('subunit')
            .select('id_subunit, nama_subunit, id_unit, unit(nama_unit)')
            .order('nama_subunit'),
        supabase
            .from('area')
            .select('id_area, nama_area, id_unit, unit(nama_unit)')
            .order('nama_area'),
      ]);
      if (mounted) {
        setState(() {
          _lokasiData = List<Map<String, dynamic>>.from(results[0] as List);
          _subunitData = List<Map<String, dynamic>>.from(results[1] as List);
          _areaData = List<Map<String, dynamic>>.from(results[2] as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading unit filter dialog: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _currentData {
    switch (_tabIndex) {
      case 1:
        return _subunitData;
      case 2:
        return _areaData;
      default:
        return _lokasiData;
    }
  }

  String _nameOf(Map<String, dynamic> item) {
    switch (_tabIndex) {
      case 1:
        return item['nama_subunit']?.toString() ?? '-';
      case 2:
        return item['nama_area']?.toString() ?? '-';
      default:
        return item['nama_lokasi']?.toString() ?? '-';
    }
  }

  String? _unitNameOf(Map<String, dynamic> item) {
    final u = item['unit'];
    if (u is Map) return u['nama_unit']?.toString();
    return null;
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _currentData;
    return _currentData.where((item) => _nameOf(item).toLowerCase().contains(q)).toList();
  }

  void _selectItem(Map<String, dynamic> item) {
    if (_tabIndex == 0) {
      Navigator.pop(context, {
        'type': 'lokasi',
        'id': item['id_lokasi']?.toString(),
        'name': item['nama_lokasi']?.toString(),
      });
    } else {
      Navigator.pop(context, {
        'type': 'unit',
        'id': item['id_unit']?.toString(),
        'name': _nameOf(item),
      });
    }
  }

  void _selectAll() {
    Navigator.pop(context, {'type': 'none'});
  }

  void _resetSearch() {
    _searchCtrl.clear();
    setState(() => _currentPage = 1);
  }

  Widget _buildAllCard() {
    final color = _levelColors[_tabIndex];
    final isSel = widget.initialLokasiId == null && widget.initialUnitId == null;
    return GestureDetector(
      onTap: _selectAll,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSel ? _C.primaryLt : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSel ? _C.primary : const Color(0xFFE2E8F0), width: isSel ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.apps_rounded, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _t('Semua (Tanpa Filter)', 'All (No Filter)', '全部'),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: _C.textMain),
              ),
            ),
            if (isSel)
              const Icon(Icons.check_circle_rounded, color: _C.primary, size: 20)
            else
              Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final color = _levelColors[_tabIndex];
    final name = _nameOf(item);
    final unitName = _tabIndex != 0 ? _unitNameOf(item) : null;
    final isSel = _tabIndex == 0
        ? (widget.initialLokasiId != null && item['id_lokasi']?.toString() == widget.initialLokasiId)
        : (widget.initialUnitId != null && item['id_unit']?.toString() == widget.initialUnitId);

    return GestureDetector(
      onTap: () => _selectItem(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSel ? _C.primaryLt : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSel ? _C.primary : const Color(0xFFE2E8F0), width: isSel ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
              child: Icon(_levelIcon(_tabIndex), size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: _C.textMain),
                  ),
                  if (_tabIndex != 0 && unitName != null && unitName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.business_rounded, size: 11, color: _C.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            unitName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(fontSize: 10.5, color: _C.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (isSel)
              const Icon(Icons.check_circle_rounded, color: _C.primary, size: 20)
            else
              Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isSearching = _searchCtrl.text.trim().isNotEmpty;
    final color = _levelColors[_tabIndex];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              height: 100,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: Icon(Icons.search_off_rounded, size: 40, color: color.withValues(alpha: 0.5)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _t('Tidak ada data', 'No data found', '未找到数据'),
              style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: _C.textMain),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? _t('Coba kata kunci lain.', 'Try a different keyword.', '请尝试其他关键词。')
                  : _t('Tidak ada item untuk level ini.', 'No items available for this level.', '此级别没有可用项目。'),
              style: GoogleFonts.poppins(fontSize: 11.5, color: _C.textSub, height: 1.4),
              textAlign: TextAlign.center,
            ),
            if (isSearching) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _resetSearch,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 14, color: color),
                      const SizedBox(width: 6),
                      Text(_t('Hapus pencarian', 'Clear search', '清除搜索'),
                          style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final filtered = _filtered;

    final totalPages = filtered.isEmpty ? 1 : (filtered.length / _perPage).ceil();
    final safePage = _currentPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * _perPage;
    final endIdx = (startIdx + _perPage) > filtered.length ? filtered.length : startIdx + _perPage;
    final pageItems = filtered.isEmpty ? <Map<String, dynamic>>[] : filtered.sublist(startIdx, endIdx);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 340,
        height: screenHeight * 0.78,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.primaryLt, width: 1.5),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _C.primaryLt, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.map_rounded, color: _C.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dialogTitle,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15, color: _C.primary),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: const Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
              child: Row(
                children: List.generate(_levels.length, (index) {
                  final isActive = _tabIndex == index;
                  final color = _levelColors[index];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _tabIndex = index;
                        _searchCtrl.clear();
                        _currentPage = 1;
                      }),
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
                            Icon(_levelIcon(index), size: 15, color: isActive ? Colors.white : color),
                            const SizedBox(height: 3),
                            Text(
                              _levelLabel(index),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.primary.withValues(alpha: 0.35), width: 1.3),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() => _currentPage = 1),
                  textAlignVertical: TextAlignVertical.center,
                  style: GoogleFonts.poppins(fontSize: 13, color: _C.textMain),
                  decoration: InputDecoration(
                    hintText: '${_t('Cari', 'Search', '搜索')} ${_levelLabel(_tabIndex)}...',
                    hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black38),
                    prefixIcon: const Icon(Icons.search_rounded, color: _C.primary, size: 18),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? GestureDetector(
                            onTap: _resetSearch,
                            child: Container(
                              margin: const EdgeInsets.all(10),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _C.red.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, size: 14, color: _C.red),
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Expanded(
              child: _isLoading
                  ? Shimmer.fromColors(
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
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                      children: [
                        _buildAllCard(),
                        if (filtered.isEmpty)
                          _buildEmptyState()
                        else
                          ...pageItems.map(_buildItemCard),
                      ],
                    ),
            ),
            if (!_isLoading && filtered.isNotEmpty && totalPages > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                child: AdminUnitPageIndicator(
                  currentPage: safePage,
                  totalPages: totalPages,
                  onPageChanged: (p) => setState(() => _currentPage = p),
                  color: _levelColors[_tabIndex],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AdminUnitSortDialog extends StatelessWidget {
  final Color primaryColor;
  final String currentSort;
  final String lang;
  final void Function(String sort) onSelect;

  const AdminUnitSortDialog({
    super.key,
    required this.primaryColor,
    required this.currentSort,
    required this.lang,
    required this.onSelect,
  });

  String _t(String en, String id, String zh) {
    if (lang == 'EN') return en;
    if (lang == 'ZH') return zh;
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      {'value': 'none', 'label': _t('Default (No Sort)', 'Default (Tanpa Urutan)', '默认（无排序）')},
      {'value': 'asc', 'label': _t('A to Z', 'A sampai Z', 'A到Z')},
      {'value': 'desc', 'label': _t('Z to A', 'Z sampai A', 'Z到A')},
    ];

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _C.primaryLt, borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.sort_by_alpha_rounded, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _t('Sort Order', 'Urutan Abjad', '排序方式'),
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: primaryColor),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              children: options.map((opt) {
                final isSelected = currentSort == opt['value'];
                return GestureDetector(
                  onTap: () => onSelect(opt['value']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor.withValues(alpha: 0.10) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? primaryColor : Colors.grey.shade200,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            opt['label']!,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? primaryColor : _C.textMain,
                            ),
                          ),
                        ),
                        if (isSelected) Icon(Icons.check_circle_rounded, color: primaryColor, size: 18),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}