import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';

String _selt(String lang, String id, String en, String zh) =>
    lang == 'ID' ? id : lang == 'ZH' ? zh : en;

enum _SectionCategory { lokasi, unit, subunit, area }

class _SectionItem {
  final String id;
  final String name;
  final _SectionCategory category;
  final String badgeLabel; // nama lokasi/unit/subunit/area spesifik tempat section berada
  _SectionItem({
    required this.id,
    required this.name,
    required this.category,
    required this.badgeLabel,
  });
}

class _SectionCategoryMeta {
  final IconData icon;
  final Color color;
  final String label;
  final String allLabel;
  const _SectionCategoryMeta({
    required this.icon,
    required this.color,
    required this.label,
    required this.allLabel,
  });
}

Map<_SectionCategory, _SectionCategoryMeta> _sectionCategoryMeta(String lang) {
  return {
    _SectionCategory.lokasi: _SectionCategoryMeta(
      icon: Icons.location_city_rounded,
      color: const Color(0xFF10B981),
      label: _selt(lang, 'Lokasi', 'Location', '位置'),
      allLabel: _selt(lang, 'Semua Section Lokasi', 'All Location Sections', '所有位置部门'),
    ),
    _SectionCategory.unit: _SectionCategoryMeta(
      icon: Icons.business_rounded,
      color: const Color(0xFF6366F1),
      label: _selt(lang, 'Unit', 'Unit', '单位'),
      allLabel: _selt(lang, 'Semua Section Unit', 'All Unit Sections', '所有单位部门'),
    ),
    _SectionCategory.subunit: _SectionCategoryMeta(
      icon: Icons.layers_rounded,
      color: const Color(0xFFFBBF24),
      label: _selt(lang, 'Subunit', 'Subunit', '子单位'),
      allLabel: _selt(lang, 'Semua Section Subunit', 'All Subunit Sections', '所有子单位部门'),
    ),
    _SectionCategory.area: _SectionCategoryMeta(
      icon: Icons.place_rounded,
      color: const Color(0xFFF472B6),
      label: _selt(lang, 'Area', 'Area', '区域'),
      allLabel: _selt(lang, 'Semua Section Area', 'All Area Sections', '所有区域部门'),
    ),
  };
}

/// Popup filter "Section Cause" khusus KTS Production.
/// Menampilkan daftar `section` yang dikelompokkan dalam 4 tab (Lokasi/Unit/Subunit/Area)
/// berdasarkan level lokasi paling spesifik dari section tsb, lengkap dengan pencarian.
class ExploreSectionFilterScreen extends StatefulWidget {
  final String lang;
  const ExploreSectionFilterScreen({super.key, required this.lang});

  @override
  State<ExploreSectionFilterScreen> createState() => _ExploreSectionFilterScreenState();
}

class _ExploreSectionFilterScreenState extends State<ExploreSectionFilterScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  List<_SectionItem> _lokasiItems = [];
  List<_SectionItem> _unitItems = [];
  List<_SectionItem> _subunitItems = [];
  List<_SectionItem> _areaItems = [];

  _SectionCategory _activeCategory = _SectionCategory.lokasi;
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

  String _nameOf(Map<String, dynamic> s) {
    if (widget.lang == 'EN') return (s['nama_section_en'] ?? s['nama_section_id'] ?? '-').toString();
    if (widget.lang == 'ZH') return (s['nama_section_zh'] ?? s['nama_section_id'] ?? '-').toString();
    return (s['nama_section_id'] ?? '-').toString();
  }

  Future<void> _fetchAll() async {
    try {
      final data = await _supabase
          .from('section')
          .select('''
            id_section, nama_section_id, nama_section_en, nama_section_zh,
            id_lokasi, id_unit, id_subunit, id_area,
            lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area)
          ''')
          .order('urutan', ascending: true);

      final List<_SectionItem> lokasiItems = [];
      final List<_SectionItem> unitItems = [];
      final List<_SectionItem> subunitItems = [];
      final List<_SectionItem> areaItems = [];

      for (final row in List<Map<String, dynamic>>.from(data)) {
        final name = _nameOf(row);
        final id = row['id_section'].toString();

        // Tentukan level paling spesifik (sama seperti logika badge lokasi di explore_screen.dart)
        if (row['area'] != null && row['area']['nama_area'] != null) {
          areaItems.add(_SectionItem(
            id: id, name: name, category: _SectionCategory.area,
            badgeLabel: row['area']['nama_area'].toString(),
          ));
        } else if (row['subunit'] != null && row['subunit']['nama_subunit'] != null) {
          subunitItems.add(_SectionItem(
            id: id, name: name, category: _SectionCategory.subunit,
            badgeLabel: row['subunit']['nama_subunit'].toString(),
          ));
        } else if (row['unit'] != null && row['unit']['nama_unit'] != null) {
          unitItems.add(_SectionItem(
            id: id, name: name, category: _SectionCategory.unit,
            badgeLabel: row['unit']['nama_unit'].toString(),
          ));
        } else if (row['lokasi'] != null && row['lokasi']['nama_lokasi'] != null) {
          lokasiItems.add(_SectionItem(
            id: id, name: name, category: _SectionCategory.lokasi,
            badgeLabel: row['lokasi']['nama_lokasi'].toString(),
          ));
        }
      }

      _lokasiItems = lokasiItems;
      _unitItems = unitItems;
      _subunitItems = subunitItems;
      _areaItems = areaItems;
    } catch (e) {
      debugPrint('Error fetching explore section filter data: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_SectionItem> _listFor(_SectionCategory cat) {
    switch (cat) {
      case _SectionCategory.lokasi:
        return _lokasiItems;
      case _SectionCategory.unit:
        return _unitItems;
      case _SectionCategory.subunit:
        return _subunitItems;
      case _SectionCategory.area:
        return _areaItems;
    }
  }

  List<_SectionItem> _filtered(List<_SectionItem> items) {
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
          for (final cat in _SectionCategory.values) {
            if (_filtered(_listFor(cat)).isNotEmpty) {
              _activeCategory = cat;
              break;
            }
          }
        }
      }
    });
  }

  int _levelFor(_SectionCategory cat) {
    switch (cat) {
      case _SectionCategory.lokasi:
        return 0;
      case _SectionCategory.unit:
        return 1;
      case _SectionCategory.subunit:
        return 2;
      case _SectionCategory.area:
        return 3;
    }
  }

  void _selectAll() {
    final level = _levelFor(_activeCategory);
    final metaMap = _sectionCategoryMeta(widget.lang);
    Navigator.pop(context, {
      'all': true,
      'level': level,
      'name': metaMap[_activeCategory]!.allLabel,
    });
  }

  void _selectItem(_SectionItem item) {
    Navigator.pop(context, {
      'id': item.id,
      'name': item.name,
      'level': _levelFor(item.category),
    });
  }

  @override
  Widget build(BuildContext context) {
    final metaMap = _sectionCategoryMeta(widget.lang);
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
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.square_foot_rounded, color: Color(0xFFD97706), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selt(widget.lang, 'Filter Section Penyebab', 'Filter Cause Section', '筛选原因部门'),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFB45309),
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

              // RESULT LIST
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
                                  _selt(widget.lang, 'Tidak ada section ditemukan', 'No sections found', '未找到部门'),
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
    final hint = _selt(widget.lang, 'Cari nama section...', 'Search section name...', '搜索部门名称...');
    final isFocused = _searchQuery.isNotEmpty;
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isFocused ? const Color(0xFFD97706) : const Color(0xFFFDE68A),
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 20, color: Color(0xFFD97706)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF78350F)),
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
                  color: const Color(0xFFD97706).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFD97706)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(Map<_SectionCategory, _SectionCategoryMeta> metaMap) {
    return Row(
      children: _SectionCategory.values.map((cat) {
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

  Widget _buildAllCard(_SectionCategoryMeta meta) {
    return _buildCardShell(
      color: meta.color,
      onTap: _selectAll,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: meta.color.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Icon(Icons.done_all_rounded, color: meta.color, size: 22),
      ),
      title: meta.allLabel,
      badgeIcon: meta.icon,
      badgeLabel: meta.label,
      badgeColor: meta.color,
    );
  }

  Widget _buildItemCard(_SectionItem item, _SectionCategoryMeta meta) {
    return _buildCardShell(
      color: meta.color,
      onTap: () => _selectItem(item),
      leading: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: meta.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
        child: Icon(Icons.square_foot_rounded, color: meta.color, size: 20),
      ),
      title: item.name,
      badgeIcon: meta.icon,
      badgeLabel: item.badgeLabel,
      badgeColor: meta.color,
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