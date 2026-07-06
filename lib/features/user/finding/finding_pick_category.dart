import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<Map<String, dynamic>?> showFindingPickCategoryDialog(
  BuildContext context, {
  required String lang,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => FindingPickCategoryDialog(lang: lang),
  );
}

class FindingPickCategoryDialog extends StatefulWidget {
  final String lang;
  const FindingPickCategoryDialog({super.key, required this.lang});

  static const Map<String, Color> _categoryColorMap = {
    'Ringkas': Color(0xFF1E3A8A),
    'Rapi': Color(0xFF0891B2),
    'Resik': Color(0xFF059669),
    'Rawat': Color(0xFFD97706),
    'Tindakan Tidak Aman': Color(0xFFDC2626),
    'Kondisi Tidak Aman': Color(0xFF7C3AED),
    'Lainnya': Color(0xFFDB2777),
  };

  static const Map<String, Color> _categoryLightColorMap = {
    'Ringkas': Color(0xFFEFF6FF),
    'Rapi': Color(0xFFECFEFF),
    'Resik': Color(0xFFECFDF5),
    'Rawat': Color(0xFFFFFBEB),
    'Tindakan Tidak Aman': Color(0xFFFEF2F2),
    'Kondisi Tidak Aman': Color(0xFFF5F3FF),
    'Lainnya': Color(0xFFFDF2F8),
  };

  static const Color _fallbackColor = Color(0xFF1D72F3);
  static const Color _fallbackLightColor = Color(0xFFEFF6FF);

  static Color getColorForCategory(String categoryName) =>
      _categoryColorMap[categoryName] ?? _fallbackColor;

  static Color getLightColorForCategory(String categoryName) =>
      _categoryLightColorMap[categoryName] ?? _fallbackLightColor;

  static IconData getIconForCategory(String categoryName) {
    switch (categoryName) {
      case 'Ringkas':
        return Icons.delete_sweep_outlined;
      case 'Rapi':
        return Icons.fact_check_outlined;
      case 'Resik':
        return Icons.cleaning_services_outlined;
      case 'Rawat':
        return Icons.construction_outlined;
      case 'Tindakan Tidak Aman':
        return Icons.warning_amber_rounded;
      case 'Kondisi Tidak Aman':
        return Icons.dangerous_outlined;
      case 'Lainnya':
        return Icons.more_horiz_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  State<FindingPickCategoryDialog> createState() =>
      _FindingPickCategoryDialogState();
}

class _FindingPickCategoryDialogState
    extends State<FindingPickCategoryDialog> {
  List<Map<String, dynamic>> _allCategories = [];
  List<Map<String, dynamic>> _filteredCategories = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await Supabase.instance.client
          .from('kategoritemuan')
          .select('*, subkategoritemuan(*)')
          .eq('jenis_kategori', '5R');
      final data = List<Map<String, dynamic>>.from(response);
      if (mounted) {
        setState(() {
          _allCategories = data;
          _filteredCategories = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCategories = _allCategories.where((category) {
        final categoryName =
            category['nama_kategoritemuan'].toString().toLowerCase();
        final subcategories =
            List<Map<String, dynamic>>.from(category['subkategoritemuan']);
        return categoryName.contains(query) ||
            subcategories.any((sub) => sub['nama_subkategoritemuan']
                .toString()
                .toLowerCase()
                .contains(query));
      }).toList();
    });
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 60,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
              const Divider(height: 1),
              ...List.generate(
                  2,
                  (_) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 12),
                            Container(
                                height: 12, width: 160, color: Colors.white),
                          ],
                        ),
                      )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      backgroundColor: Colors.transparent,
      child: Container(
        width: size.width > 480 ? 440 : size.width * 0.92,
        height: size.height * 0.8,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.category_outlined,
                        color: Color(0xFF1E3A8A), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.lang == 'ID'
                              ? 'Pilih Kategori'
                              : widget.lang == 'ZH'
                                  ? '选择类别'
                                  : 'Select Category',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E3A8A),
                          ),
                        ),
                        Text(
                          widget.lang == 'ID'
                              ? 'Pilih kategori & subkategori temuan'
                              : widget.lang == 'ZH'
                                  ? '选择发现类别和子类别'
                                  : 'Choose finding category & subcategory',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            // SEARCH BAR
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.lang == 'ID'
                      ? 'Cari kategori atau subkategori...'
                      : widget.lang == 'ZH'
                          ? '搜索类别或子类别...'
                          : 'Search category or subcategory...',
                  hintStyle: GoogleFonts.poppins(
                      color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF1E3A8A)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                        color: Color(0xFF00C9E4), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 0, horizontal: 20),
                ),
              ),
            ),

            // COUNT INDICATOR
            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_filteredCategories.length} ${widget.lang == 'ID' ? 'kategori ditemukan' : widget.lang == 'ZH' ? '找到的类别' : 'categories found'}',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                ),
              ),

            // LIST
            Expanded(
              child: _isLoading
                  ? _buildShimmerLoading()
                  : _filteredCategories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off,
                                  size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 8),
                              Text(
                                widget.lang == 'ID'
                                    ? 'Kategori tidak ditemukan'
                                    : widget.lang == 'ZH'
                                        ? '未找到类别'
                                        : 'Category not found',
                                style: GoogleFonts.poppins(
                                    color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: _filteredCategories.length,
                          itemBuilder: (context, index) {
                            final category = _filteredCategories[index];
                            final String kategoriNama =
                                category['nama_kategoritemuan'];
                            final subcategories =
                                List<Map<String, dynamic>>.from(
                                    category['subkategoritemuan']);
                            final mainColor =
                                FindingPickCategoryDialog.getColorForCategory(
                                    kategoriNama);
                            final lightColor = FindingPickCategoryDialog
                                .getLightColorForCategory(kategoriNama);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: mainColor.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                                border: Border.all(
                                  color: mainColor.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // CATEGORY HEADER
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: lightColor,
                                      borderRadius:
                                          const BorderRadius.vertical(
                                              top: Radius.circular(16)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: mainColor.withValues(
                                                alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            FindingPickCategoryDialog
                                                .getIconForCategory(
                                                    kategoriNama),
                                            color: mainColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            kategoriNama,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: mainColor,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: mainColor.withValues(
                                                alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '${subcategories.length}',
                                            style: GoogleFonts.poppins(
                                              color: mainColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // SUBCATEGORIES
                                  ...subcategories.asMap().entries.map((entry) {
                                    final i = entry.key;
                                    final sub = entry.value;
                                    final isLast =
                                        i == subcategories.length - 1;

                                    return InkWell(
                                      onTap: () {
                                        Navigator.pop(context, {
                                          'id_kategoritemuan_uuid':
                                              category['id_kategoritemuan'],
                                          'id_subkategoritemuan_uuid':
                                              sub['id_subkategoritemuan'],
                                          'poin':
                                              sub['poin_subkategoritemuan'],
                                          'kategori_nama': kategoriNama,
                                          'subkategori_nama':
                                              sub['nama_subkategoritemuan'],
                                        });
                                      },
                                      borderRadius: isLast
                                          ? const BorderRadius.vertical(
                                              bottom: Radius.circular(16))
                                          : BorderRadius.zero,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          border: !isLast
                                              ? Border(
                                                  bottom: BorderSide(
                                                      color: Colors
                                                          .grey.shade100,
                                                      width: 1))
                                              : null,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: mainColor.withValues(
                                                    alpha: 0.5),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                sub['nama_subkategoritemuan'],
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            if (sub['poin_subkategoritemuan'] !=
                                                null)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20),
                                                  border: Border.all(
                                                      color: Colors.amber
                                                          .withValues(
                                                              alpha: 0.3)),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                        Icons
                                                            .local_fire_department_rounded,
                                                        size: 10,
                                                        color: Colors.amber),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      '${sub['poin_subkategoritemuan']}',
                                                      style: GoogleFonts
                                                          .poppins(
                                                        fontSize: 11,
                                                        color: Colors.amber,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            const SizedBox(width: 8),
                                            Icon(Icons.arrow_forward_ios,
                                                size: 12,
                                                color: Colors.grey.shade400),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}