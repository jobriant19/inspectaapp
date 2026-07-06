import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';

String _elt(String lang, String id, String en, String zh) =>
    lang == 'ID' ? id : lang == 'ZH' ? zh : en;

enum _ExploreLocCategory { lokasi, unit, subunit, area }

class _ExploreLocItem {
  final String id;
  final String name;
  final String? image;
  final _ExploreLocCategory category;
  _ExploreLocItem({
    required this.id,
    required this.name,
    this.image,
    required this.category,
  });
}

class _ExploreCategoryMeta {
  final IconData icon;
  final Color color;
  final String label;
  final String allLabel;
  const _ExploreCategoryMeta({
    required this.icon,
    required this.color,
    required this.label,
    required this.allLabel,
  });
}

Map<_ExploreLocCategory, _ExploreCategoryMeta> _exploreCategoryMeta(String lang) {
  return {
    _ExploreLocCategory.lokasi: _ExploreCategoryMeta(
      icon: Icons.location_city_rounded,
      color: const Color(0xFF10B981),
      label: _elt(lang, 'Lokasi', 'Location', '位置'),
      allLabel: _elt(lang, 'Semua Lokasi', 'All Locations', '所有位置'),
    ),
    _ExploreLocCategory.unit: _ExploreCategoryMeta(
      icon: Icons.business_rounded,
      color: const Color(0xFF6366F1),
      label: _elt(lang, 'Unit', 'Unit', '单位'),
      allLabel: _elt(lang, 'Semua Unit', 'All Units', '所有单位'),
    ),
    _ExploreLocCategory.subunit: _ExploreCategoryMeta(
      icon: Icons.layers_rounded,
      color: const Color(0xFFFBBF24),
      label: _elt(lang, 'Subunit', 'Subunit', '子单位'),
      allLabel: _elt(lang, 'Semua Subunit', 'All Subunits', '所有子单位'),
    ),
    _ExploreLocCategory.area: _ExploreCategoryMeta(
      icon: Icons.place_rounded,
      color: const Color(0xFFF472B6),
      label: _elt(lang, 'Area', 'Area', '区域'),
      allLabel: _elt(lang, 'Semua Area', 'All Areas', '所有区域'),
    ),
  };
}

class ExploreLocationFilterScreen extends StatefulWidget {
  final String lang;
  const ExploreLocationFilterScreen({super.key, required this.lang});

  @override
  State<ExploreLocationFilterScreen> createState() => _ExploreLocationFilterScreenState();
}

class _ExploreLocationFilterScreenState extends State<ExploreLocationFilterScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  List<_ExploreLocItem> _lokasiItems = [];
  List<_ExploreLocItem> _unitItems = [];
  List<_ExploreLocItem> _subunitItems = [];
  List<_ExploreLocItem> _areaItems = [];

  _ExploreLocCategory _activeCategory = _ExploreLocCategory.lokasi;
  String _searchQuery = '';

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
          .map((e) => _ExploreLocItem(
                id: e['id_lokasi'] as String,
                name: e['nama_lokasi'] as String,
                image: e['gambar_lokasi'] as String?,
                category: _ExploreLocCategory.lokasi,
              ))
          .toList();
      _unitItems = (results[1] as List)
          .map((e) => _ExploreLocItem(
                id: e['id_unit'] as String,
                name: e['nama_unit'] as String,
                image: e['gambar_unit'] as String?,
                category: _ExploreLocCategory.unit,
              ))
          .toList();
      _subunitItems = (results[2] as List)
          .map((e) => _ExploreLocItem(
                id: e['id_subunit'] as String,
                name: e['nama_subunit'] as String,
                image: e['gambar_subunit'] as String?,
                category: _ExploreLocCategory.subunit,
              ))
          .toList();
      _areaItems = (results[3] as List)
          .map((e) => _ExploreLocItem(
                id: e['id_area'] as String,
                name: e['nama_area'] as String,
                image: e['gambar_area'] as String?,
                category: _ExploreLocCategory.area,
              ))
          .toList();
    } catch (e) {
      debugPrint('Error fetching explore location filter data: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_ExploreLocItem> _listFor(_ExploreLocCategory cat) {
    switch (cat) {
      case _ExploreLocCategory.lokasi:
        return _lokasiItems;
      case _ExploreLocCategory.unit:
        return _unitItems;
      case _ExploreLocCategory.subunit:
        return _subunitItems;
      case _ExploreLocCategory.area:
        return _areaItems;
    }
  }

  List<_ExploreLocItem> _filtered(List<_ExploreLocItem> items) {
    if (_searchQuery.trim().isEmpty) return items;
    final q = _searchQuery.trim().toLowerCase();
    return items.where((it) => it.name.toLowerCase().contains(q)).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      if (value.trim().isNotEmpty) {
        final currentHasMatch = _filtered(_listFor(_activeCategory)).isNotEmpty;
        if (!currentHasMatch) {
          for (final cat in _ExploreLocCategory.values) {
            if (_filtered(_listFor(cat)).isNotEmpty) {
              _activeCategory = cat;
              break;
            }
          }
        }
      }
    });
  }

  int _levelFor(_ExploreLocCategory cat) {
    switch (cat) {
      case _ExploreLocCategory.lokasi:
        return 0;
      case _ExploreLocCategory.unit:
        return 1;
      case _ExploreLocCategory.subunit:
        return 2;
      case _ExploreLocCategory.area:
        return 3;
    }
  }

  void _selectAll() {
    final level = _levelFor(_activeCategory);
    final metaMap = _exploreCategoryMeta(widget.lang);
    final label = metaMap[_activeCategory]!.allLabel;
    Navigator.pop(context, {
      'all': true,
      'level': level,
      'name': label,
    });
  }

  void _selectItem(_ExploreLocItem item) {
    Navigator.pop(context, {
      'id': item.id,
      'name': item.name,
      'level': _levelFor(item.category),
    });
  }

  @override
  Widget build(BuildContext context) {
    final metaMap = _exploreCategoryMeta(widget.lang);
    final currentMeta = metaMap[_activeCategory]!;
    final list = _filtered(_listFor(_activeCategory));
    final showAllCard = _searchQuery.trim().isEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 480,
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.map_rounded, color: Color(0xFF0284C7), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _elt(widget.lang, 'Filter Lokasi', 'Filter Location', '筛选位置'),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1D72F3),
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
                        child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: const Color(0xFFF1F5F9)),

              // SEARCH + TABS
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Column(
                  children: [
                    _buildSearchField(),
                    const SizedBox(height: 10),
                    _buildCategoryTabs(metaMap),
                  ],
                ),
              ),

              // CARD RESULT LIST
              Expanded(
                child: _loading
                    ? _buildShimmerList()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        children: [
                          if (showAllCard) _buildAllCard(currentMeta),
                          if (list.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text(
                                  _elt(widget.lang, 'Tidak ada hasil ditemukan', 'No results found', '未找到结果'),
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                ),
                              ),
                            )
                          else
                            ...list.map((item) => _buildItemCard(item, currentMeta)),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final hint = _elt(
      widget.lang,
      'Cari lokasi, unit, subunit, area...',
      'Search location, unit, subunit, area...',
      '搜索位置、单位、子单位、区域...',
    );
    final isFocused = _searchQuery.isNotEmpty;
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isFocused ? const Color(0xFF0284C7) : const Color(0xFFBAE6FD),
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0284C7)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0C4A6E)),
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
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
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF0284C7)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(Map<_ExploreLocCategory, _ExploreCategoryMeta> metaMap) {
    return Row(
      children: _ExploreLocCategory.values.map((cat) {
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
                border: Border.all(color: isActive ? meta.color : const Color(0xFFE2E8F0)),
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
                  Icon(meta.icon, size: 15, color: isActive ? Colors.white : meta.color),
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

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
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
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
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

  Widget _buildAllCard(_ExploreCategoryMeta meta) {
    return _buildCardShell(
      color: meta.color,
      onTap: _selectAll,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: meta.color.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Icon(Icons.public_rounded, color: meta.color, size: 22),
      ),
      title: meta.allLabel,
      badgeIcon: meta.icon,
      badgeLabel: meta.label,
      badgeColor: meta.color,
    );
  }

  Widget _buildItemCard(_ExploreLocItem item, _ExploreCategoryMeta meta) {
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
      color: meta.color,
      onTap: () => _selectItem(item),
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
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
      child: Text(initials, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
    );
  }

  Widget _buildCardShell({
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
          ],
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
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, size: 10, color: badgeColor),
                        const SizedBox(width: 3),
                        Text(
                          badgeLabel,
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: badgeColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}