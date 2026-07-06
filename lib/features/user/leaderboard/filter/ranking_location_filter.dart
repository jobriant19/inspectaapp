import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../detail/leaderboard_detail_screen.dart';
import 'package:shimmer/shimmer.dart';

String _t(String lang, String id, String en, String zh) =>
    lang == 'ID' ? id : lang == 'ZH' ? zh : en;

enum _LocCategory { lokasi, unit, subunit, area }

class _LocItem {
  final String id;
  final String name;
  final String? image;
  final _LocCategory category;
  _LocItem({
    required this.id,
    required this.name,
    this.image,
    required this.category,
  });
}

class _CategoryMeta {
  final IconData icon;
  final Color color;
  final String label;
  final String allLabel;
  const _CategoryMeta({
    required this.icon,
    required this.color,
    required this.label,
    required this.allLabel,
  });
}

Map<_LocCategory, _CategoryMeta> _categoryMeta(String lang) {
  return {
    _LocCategory.lokasi: _CategoryMeta(
      icon: Icons.location_city_rounded,
      color: const Color(0xFF10B981),
      label: _t(lang, 'Lokasi', 'Location', '位置'),
      allLabel: _t(lang, 'Semua Lokasi', 'All Locations', '所有位置'),
    ),
    _LocCategory.unit: _CategoryMeta(
      icon: Icons.business_rounded,
      color: const Color(0xFF6366F1),
      label: _t(lang, 'Unit', 'Unit', '单位'),
      allLabel: _t(lang, 'Semua Unit', 'All Units', '所有单位'),
    ),
    _LocCategory.subunit: _CategoryMeta(
      icon: Icons.layers_rounded,
      color: const Color(0xFFFBBF24),
      label: _t(lang, 'Subunit', 'Subunit', '子单位'),
      allLabel: _t(lang, 'Semua Subunit', 'All Subunits', '所有子单位'),
    ),
    _LocCategory.area: _CategoryMeta(
      icon: Icons.place_rounded,
      color: const Color(0xFFF472B6),
      label: _t(lang, 'Area', 'Area', '区域'),
      allLabel: _t(lang, 'Semua Area', 'All Areas', '所有区域'),
    ),
  };
}

class RankingLocationFilter {
  RankingLocationFilter._();

  static Future<LocationFilter?> show({
    required BuildContext context,
    required String lang,
    required LocationFilter currentSelection,
  }) {
    return showModalBottomSheet<LocationFilter>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LocationFilterSheet(
        lang: lang,
        currentSelection: currentSelection,
      ),
    );
  }
}

class _LocationFilterSheet extends StatefulWidget {
  final String lang;
  final LocationFilter currentSelection;

  const _LocationFilterSheet({
    required this.lang,
    required this.currentSelection,
  });

  @override
  State<_LocationFilterSheet> createState() => _LocationFilterSheetState();
}

class _LocationFilterSheetState extends State<_LocationFilterSheet> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  List<_LocItem> _lokasiItems = [];
  List<_LocItem> _unitItems = [];
  List<_LocItem> _subunitItems = [];
  List<_LocItem> _areaItems = [];

  _LocCategory _activeCategory = _LocCategory.lokasi;
  String _searchQuery = '';
  _LocItem? _selectedItem;

  bool get _isFilterActive => _selectedItem != null;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    try {
      final results = await Future.wait([
        _supabase
            .from('lokasi')
            .select('id_lokasi, nama_lokasi, gambar_lokasi')
            .order('nama_lokasi'),
        _supabase
            .from('unit')
            .select('id_unit, nama_unit, gambar_unit')
            .order('nama_unit'),
        _supabase
            .from('subunit')
            .select('id_subunit, nama_subunit, gambar_subunit')
            .order('nama_subunit'),
        _supabase
            .from('area')
            .select('id_area, nama_area, gambar_area')
            .order('nama_area'),
      ]);

      _lokasiItems = (results[0] as List)
          .map((e) => _LocItem(
                id: e['id_lokasi'] as String,
                name: e['nama_lokasi'] as String,
                image: e['gambar_lokasi'] as String?,
                category: _LocCategory.lokasi,
              ))
          .toList();
      _unitItems = (results[1] as List)
          .map((e) => _LocItem(
                id: e['id_unit'] as String,
                name: e['nama_unit'] as String,
                image: e['gambar_unit'] as String?,
                category: _LocCategory.unit,
              ))
          .toList();
      _subunitItems = (results[2] as List)
          .map((e) => _LocItem(
                id: e['id_subunit'] as String,
                name: e['nama_subunit'] as String,
                image: e['gambar_subunit'] as String?,
                category: _LocCategory.subunit,
              ))
          .toList();
      _areaItems = (results[3] as List)
          .map((e) => _LocItem(
                id: e['id_area'] as String,
                name: e['nama_area'] as String,
                image: e['gambar_area'] as String?,
                category: _LocCategory.area,
              ))
          .toList();

      // Pre-select sesuai filter yang sedang aktif
      final cur = widget.currentSelection;
      if (cur.idArea != null) {
        _activeCategory = _LocCategory.area;
        _selectedItem = _findById(_areaItems, cur.idArea);
      } else if (cur.idSubunit != null) {
        _activeCategory = _LocCategory.subunit;
        _selectedItem = _findById(_subunitItems, cur.idSubunit);
      } else if (cur.idUnit != null) {
        _activeCategory = _LocCategory.unit;
        _selectedItem = _findById(_unitItems, cur.idUnit);
      } else if (cur.idLokasi != null) {
        _activeCategory = _LocCategory.lokasi;
        _selectedItem = _findById(_lokasiItems, cur.idLokasi);
      }
    } catch (e) {
      debugPrint('Error fetching location filter data: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  _LocItem? _findById(List<_LocItem> list, String? id) {
    if (id == null) return null;
    for (final item in list) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<_LocItem> _listFor(_LocCategory cat) {
    switch (cat) {
      case _LocCategory.lokasi:
        return _lokasiItems;
      case _LocCategory.unit:
        return _unitItems;
      case _LocCategory.subunit:
        return _subunitItems;
      case _LocCategory.area:
        return _areaItems;
    }
  }

  List<_LocItem> _filtered(List<_LocItem> items) {
    if (_searchQuery.trim().isEmpty) return items;
    final q = _searchQuery.trim().toLowerCase();
    return items.where((it) => it.name.toLowerCase().contains(q)).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      if (value.trim().isNotEmpty) {
        final currentHasMatch =
            _filtered(_listFor(_activeCategory)).isNotEmpty;
        if (!currentHasMatch) {
          for (final cat in _LocCategory.values) {
            if (_filtered(_listFor(cat)).isNotEmpty) {
              _activeCategory = cat;
              break;
            }
          }
        }
      }
    });
  }

  LocationFilter _buildResult() {
    if (_selectedItem == null) {
      return LocationFilter(
        displayName: _t(widget.lang, 'Semua Lokasi', 'All Locations', '所有位置'),
      );
    }
    final item = _selectedItem!;
    switch (item.category) {
      case _LocCategory.lokasi:
        return LocationFilter(idLokasi: item.id, displayName: item.name);
      case _LocCategory.unit:
        return LocationFilter(idUnit: item.id, displayName: item.name);
      case _LocCategory.subunit:
        return LocationFilter(idSubunit: item.id, displayName: item.name);
      case _LocCategory.area:
        return LocationFilter(idArea: item.id, displayName: item.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final metaMap = _categoryMeta(widget.lang);
    final currentMeta = metaMap[_activeCategory]!;
    final list = _filtered(_listFor(_activeCategory));
    final showAllCard = _searchQuery.trim().isEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.pop(context), // Klik di luar popup = sama seperti klik X
      child: Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: GestureDetector(
        onTap: () {}, // Serap tap di dalam konten agar popup tidak ikut tertutup
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 16, 12),
                child: Row(
                  children: [
                    const Icon(Icons.map_rounded,
                        color: Color(0xFF1D72F3), size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _t(widget.lang, 'Filter Lokasi', 'Filter Location', '筛选位置'),
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1D72F3),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D72F3).withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF1D72F3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          const Divider(height: 1),
          // Search + Tabs (FIXED, tidak ikut scroll)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              children: [
                _buildSearchField(),
                const SizedBox(height: 10),
                _buildCategoryTabs(metaMap),
              ],
            ),
          ),
          // List hasil (HANYA bagian ini yang scroll)
          Expanded(
            child: _loading
                ? _buildShimmerList()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    children: [
                      if (showAllCard) _buildAllCard(currentMeta),
                      if (list.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              _t(widget.lang, 'Tidak ada hasil ditemukan',
                                  'No results found', '未找到结果'),
                              style: const TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 13),
                            ),
                          ),
                        )
                      else
                        ...list.map((item) => _buildItemCard(item, currentMeta)),
                    ],
                  ),
          ),
          // Tombol Reset & Terapkan (FIXED)
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
            child: Row(
              children: [
                if (_isFilterActive) ...[
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedItem = null;
                          _searchCtrl.clear();
                          _searchQuery = '';
                          _activeCategory = _LocCategory.lokasi;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                        ),
                        child: Center(
                          child: Text(
                            _t(widget.lang, 'Reset', 'Reset', '重置'),
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: _isFilterActive ? 2 : 1,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, _buildResult()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _t(widget.lang, 'Terapkan Filter', 'Apply Filter', '应用筛选'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
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
      ),
    );
  }

  Widget _buildSearchField() {
    final hint = _t(
      widget.lang,
      'Cari lokasi, unit, subunit, area...',
      'Search location, unit, subunit, area...',
      '搜索位置、单位、子单位、区域...',
    );
    final bool isFocused = _searchQuery.isNotEmpty;
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused
              ? const Color(0xFF0EA5E9)
              : const Color(0xFF0EA5E9).withValues(alpha: 0.35),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 21, color: Color(0xFF0EA5E9)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                isDense: true,
                hintStyle:
                    const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              ),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0C4A6E),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                _onSearchChanged('');
              },
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    size: 14, color: Color(0xFF0EA5E9)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 140, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(height: 16, width: 70, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(Map<_LocCategory, _CategoryMeta> metaMap) {
    return Row(
      children: _LocCategory.values.map((cat) {
        final meta = metaMap[cat]!;
        final isActive = _activeCategory == cat;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _activeCategory = cat),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? meta.color : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isActive ? meta.color : const Color(0xFFE2E8F0)),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: meta.color.withValues(alpha: 0.30),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(meta.icon,
                      size: 15, color: isActive ? Colors.white : meta.color),
                  const SizedBox(height: 3),
                  Text(
                    meta.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
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
      }).toList(),
    );
  }

  Widget _buildAllCard(_CategoryMeta meta) {
    final isSelected = _selectedItem == null;
    return _buildCardShell(
      isSelected: isSelected,
      color: meta.color,
      onTap: () => setState(() => _selectedItem = null),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: meta.color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.public_rounded, color: meta.color, size: 22),
      ),
      title: meta.allLabel,
      badgeIcon: meta.icon,
      badgeLabel: meta.label,
      badgeColor: meta.color,
    );
  }

  Widget _buildItemCard(_LocItem item, _CategoryMeta meta) {
    final isSelected = _selectedItem != null &&
        _selectedItem!.id == item.id &&
        _selectedItem!.category == item.category;

    Widget leading;
    if (item.image != null && item.image!.isNotEmpty) {
      leading = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          item.image!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackAvatar(item.name, meta.color),
        ),
      );
    } else {
      leading = _fallbackAvatar(item.name, meta.color);
    }

    return _buildCardShell(
      isSelected: isSelected,
      color: meta.color,
      onTap: () => setState(() => _selectedItem = item),
      leading: leading,
      title: item.name,
      badgeIcon: meta.icon,
      badgeLabel: meta.label,
      badgeColor: meta.color,
    );
  }

  Widget _fallbackAvatar(String name, Color color) {
    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        initials,
        style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  Widget _buildCardShell({
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
    required Widget leading,
    required String title,
    required IconData badgeIcon,
    required String badgeLabel,
    required Color badgeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.6 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: const Color(0xFF0C4A6E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: badgeColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, size: 10, color: badgeColor),
                        const SizedBox(width: 3),
                        Text(
                          badgeLabel,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}