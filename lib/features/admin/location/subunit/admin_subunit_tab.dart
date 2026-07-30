import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../user/finding/finding_pick_pic.dart';
import 'admin_add_subunit.dart';
import 'admin_edit_subunit.dart';
import 'admin_subunit_detail.dart';
import 'admin_subunit_filter.dart';
import 'admin_subunit_indicator.dart';
import 'camera/admin_subunit_camera.dart';

class AdminSubunitTab extends StatefulWidget {
  final String lang;
  const AdminSubunitTab({super.key, required this.lang});

  @override
  State<AdminSubunitTab> createState() => _AdminSubunitTabState();
}

class _AdminSubunitTabState extends State<AdminSubunitTab>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _data = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _search = '';
  int _currentPage = 1;
  static const int _perPage = 10;

  final TextEditingController _searchCtrl = TextEditingController();

  String? _filterField;
  String? _filterValue;
  String? _filterLabel;
  Color? _filterActiveColor;
  String _sortOrder = 'none';

  static const _primary = Color(0xFFFBBF24);
  static const _lokasiColor = Color(0xFF10B981);
  static const _unitColor = Color(0xFF6366F1);
  static const _areaColor = Color(0xFFF472B6);

  @override
  void initState() {
    super.initState();
    _load();
    AdminSubunitCameraWarmupService.instance.warmUp();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    AdminSubunitCameraWarmupService.instance.release();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('subunit')
          .select(
              'id_subunit, nama_subunit, deskripsi_subunit, deskripsi_subunit_en, deskripsi_subunit_zh, is_star, gambar_subunit, qrcode, id_unit, id_lokasi, id_pic, unit(nama_unit), User!fk_subunit_pic(nama, gambar_user, id_jabatan, is_verificator, jabatan(nama_jabatan))')
          .order('nama_subunit');
      if (mounted) {
        setState(() {
          _data = List<Map<String, dynamic>>.from(res);
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final q = _search.toLowerCase();
    List<Map<String, dynamic>> result = List.from(_data);

    if (q.isNotEmpty) {
      result = result.where((d) => (d['nama_subunit'] ?? '').toLowerCase().contains(q)).toList();
    }
    if (_filterField != null && _filterValue != null) {
      result = result.where((d) => d[_filterField]?.toString() == _filterValue).toList();
    }
    if (_sortOrder == 'asc') {
      result.sort((a, b) => (a['nama_subunit'] ?? '').compareTo(b['nama_subunit'] ?? ''));
    } else if (_sortOrder == 'desc') {
      result.sort((a, b) => (b['nama_subunit'] ?? '').compareTo(a['nama_subunit'] ?? ''));
    }
    _filtered = result;
    _currentPage = 1;
  }

  bool get _isFiltering => _search.isNotEmpty || _filterField != null || _sortOrder != 'none';

  void _clearSearchAndFilter() {
    _searchCtrl.clear();
    setState(() {
      _search = '';
      _filterField = null;
      _filterValue = null;
      _filterLabel = null;
      _filterActiveColor = null;
      _sortOrder = 'none';
      _applyFilter();
    });
  }

  Widget _buildPicSubtitle(Map<String, dynamic> item) {
    final picData = item['User'] as Map<String, dynamic>?;
    final picName = picData?['nama'] as String?;
    final picImage = picData?['gambar_user'] as String?;
    final idJabatan = picData?['id_jabatan'] as int?;
    final isVerificator = picData?['is_verificator'] as bool?;
    final jabatanRaw = picData?['jabatan'];
    final jabatanNama = jabatanRaw is Map ? jabatanRaw['nama_jabatan']?.toString() : null;

    if (picName == null || picName.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_rounded, size: 11, color: Color(0xFFF59E0B)),
            const SizedBox(width: 4),
            Text(
              widget.lang == 'EN' ? 'No PIC' : widget.lang == 'ZH' ? '无负责人' : 'Belum ada PIC',
              style: GoogleFonts.poppins(
                color: const Color(0xFFB45309),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: _primary.withValues(alpha: 0.18),
          backgroundImage: (picImage != null && picImage.isNotEmpty) ? NetworkImage(picImage) : null,
          child: (picImage == null || picImage.isEmpty)
              ? const Icon(Icons.person_rounded, size: 14, color: Color(0xFFB45309))
              : null,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                picName,
                style: GoogleFonts.poppins(color: Colors.black87, fontSize: 9.5, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Transform.scale(
                scale: 0.72,
                alignment: Alignment.centerLeft,
                child: buildJabatanBadge(
                  idJabatan: idJabatan,
                  jabatanNama: jabatanNama,
                  isVerificator: isVerificator,
                  lang: widget.lang,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminAddSubunitDialog(
        lang: widget.lang,
        subunits: _data,
        onSaved: _load,
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminEditSubunitDialog(
        lang: widget.lang,
        existing: item,
        subunits: _data,
        onSaved: _load,
      ),
    );
  }

  Future<void> _delete(String id, String name) async {
    final ok = await _showSubunitConfirm(context, name, widget.lang);
    if (!ok) return;
    await Supabase.instance.client.from('subunit').delete().eq('id_subunit', id);
    _load();
  }

  Widget _buildFilterRow() {
    final bool isFilterActive = _filterField != null;
    final IconData activeIcon = _filterField == 'id_lokasi'
        ? Icons.location_city_rounded
        : _filterField == 'id_unit'
            ? Icons.business_rounded
            : Icons.place_rounded;
    return Row(
      children: [
        Expanded(
          child: _SubunitFilterButton(
            label: widget.lang == 'EN'
                ? 'Specific Location'
                : widget.lang == 'ZH'
                    ? '特定位置'
                    : 'Lokasi Spesifik',
            icon: !isFilterActive ? Icons.map_rounded : activeIcon,
            isActive: isFilterActive,
            activeLabel: _filterLabel,
            primaryColor: _primary,
            activeColor: _filterActiveColor ?? _unitColor,
            onTap: () => _showUnitFilterDialog(),
            onClear: () => setState(() {
              _filterField = null;
              _filterValue = null;
              _filterLabel = null;
              _filterActiveColor = null;
              _applyFilter();
            }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SubunitFilterButton(
            label: widget.lang == 'EN' ? 'Sort' : widget.lang == 'ZH' ? '排序' : 'Urutan',
            icon: Icons.sort_by_alpha_rounded,
            isActive: _sortOrder != 'none',
            activeLabel: _sortOrder == 'asc' ? 'A→Z' : _sortOrder == 'desc' ? 'Z→A' : null,
            primaryColor: _primary,
            onTap: () => _showSortDialog(),
          ),
        ),
      ],
    );
  }

  void _showUnitFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AdminSubunitLocationFilterDialog(
        lang: widget.lang,
        initialField: _filterField,
        initialValue: _filterValue,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      final type = result['type'];
      if (type == 'lokasi') {
        _filterField = 'id_lokasi';
        _filterValue = result['id'] as String?;
        _filterLabel = result['name'] as String?;
        _filterActiveColor = _lokasiColor;
      } else if (type == 'unit') {
        _filterField = 'id_unit';
        _filterValue = result['id'] as String?;
        _filterLabel = result['name'] as String?;
        _filterActiveColor = _unitColor;
      } else if (type == 'area') {
        _filterField = 'id_subunit';
        _filterValue = result['id'] as String?;
        _filterLabel = result['name'] as String?;
        _filterActiveColor = _areaColor;
      } else {
        _filterField = null;
        _filterValue = null;
        _filterLabel = null;
        _filterActiveColor = null;
      }
      _applyFilter();
    });
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AdminSubunitSortDialog(
        primaryColor: _primary,
        currentSort: _sortOrder,
        lang: widget.lang,
        onSelect: (sort) {
          setState(() {
            _sortOrder = sort;
            _applyFilter();
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final totalPages =
        _filtered.isEmpty ? 1 : (_filtered.length / _perPage).ceil();
    final safePage = _currentPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * _perPage;
    final endIdx =
        (startIdx + _perPage) > _filtered.length ? _filtered.length : startIdx + _perPage;
    final pageData = _filtered.isEmpty ? <Map<String, dynamic>>[] : _filtered.sublist(startIdx, endIdx);

    return _buildSubunitTabContent(
      isLoading: _isLoading,
      search: _search,
      searchController: _searchCtrl,
      isFiltering: _isFiltering,
      onClearAll: _clearSearchAndFilter,
      onSearch: (v) => setState(() {
        _search = v;
        _applyFilter();
      }),
      addTitle: widget.lang == 'EN'
          ? 'Add New Subunit'
          : widget.lang == 'ZH'
              ? '添加新子单位'
              : 'Tambah Subunit Baru',
      addSubtitle: widget.lang == 'EN'
          ? 'Tap to add a new subunit'
          : widget.lang == 'ZH'
              ? '点击以添加新子单位'
              : 'Ketuk untuk menambah subunit baru',
      data: pageData,
      totalCount: _filtered.length,
      currentPage: safePage,
      totalPages: totalPages,
      onPageChanged: (p) => setState(() => _currentPage = p),
      lang: widget.lang,
      primaryColor: _primary,
      nameFn: (item) => item['nama_subunit'] ?? '',
      subtitleWidgetBuilder: (item) => _buildPicSubtitle(item),
      imageUrlFn: (item) => item['gambar_subunit'] as String?,
      icon: Icons.layers_rounded,
      onAdd: () => _showAddDialog(),
      onEdit: (item) => _showEditDialog(item),
      onDelete: (item) => _delete(item['id_subunit'], item['nama_subunit'] ?? ''),
      onRefresh: _load,
      filterWidget: _buildFilterRow(),
      onTapDetail: (item) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminSubunitDetailScreen(
            item: item,
            lang: widget.lang,
            primaryColor: _primary,
            unitColor: _unitColor,
            icon: Icons.layers_rounded,
            nameFn: (item) => item['nama_subunit'] ?? '',
            onEdit: (item) => _showEditDialog(item),
            onDelete: (item) => _delete(item['id_subunit'], item['nama_subunit'] ?? ''),
          ),
        ),
      ),
    );
  }
}

Widget _buildSubunitTabContent({
  required bool isLoading,
  required String search,
  required TextEditingController searchController,
  required bool isFiltering,
  required VoidCallback onClearAll,
  required ValueChanged<String> onSearch,
  required List<Map<String, dynamic>> data,
  required String lang,
  required Color primaryColor,
  required String Function(Map<String, dynamic>) nameFn,
  Widget Function(Map<String, dynamic>)? subtitleWidgetBuilder,
  String? Function(Map<String, dynamic>)? imageUrlFn,
  int? totalCount,
  int currentPage = 1,
  int totalPages = 1,
  ValueChanged<int>? onPageChanged,
  required IconData icon,
  required VoidCallback onAdd,
  required void Function(Map<String, dynamic>) onEdit,
  required void Function(Map<String, dynamic>) onDelete,
  required Future<void> Function() onRefresh,
  void Function(Map<String, dynamic>)? onTapDetail,
  Widget? filterWidget,
  Widget? activeChipsWidget,
  required String addTitle,
  required String addSubtitle,
}) {
  const bg = Color(0xFFF8FAFC);
  const card = Color(0xFFFFFFFF);
  final bool hasPageIndicator = totalPages > 1 && onPageChanged != null;
  final double listBottomPad = hasPageIndicator ? 84.0 : 20.0;

  return Scaffold(
    backgroundColor: bg,
    body: Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withValues(alpha:0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha:0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          addTitle,
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                        Text(
                          addSubtitle,
                          style: GoogleFonts.poppins(
                              fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withValues(alpha:0.08)),
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearch,
              textAlignVertical: TextAlignVertical.center,
              style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 14),
              decoration: InputDecoration(
                hintText: lang == 'EN' ? 'Search Subunit...' : lang == 'ZH' ? '搜索子单位...' : 'Cari Subunit...',
                hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 20),
                suffixIcon: search.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          searchController.clear();
                          onSearch('');
                        },
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
        if (filterWidget != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: filterWidget,
          ),
        ],
        const SizedBox(height: 8),
        if (activeChipsWidget != null) activeChipsWidget,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.list_alt_rounded, size: 13, color: Color(0xFFB45309)),
                  const SizedBox(width: 5),
                  Text(
                    '${totalCount ?? data.length} ${lang == 'EN' ? 'items' : lang == 'ZH' ? '条数据' : 'data'}',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFB45309),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: isLoading
              ? Shimmer.fromColors(
                  baseColor: Colors.grey.shade200,
                  highlightColor: Colors.grey.shade50,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, listBottomPad),
                    itemCount: 6,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, __) => Container(
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                )
              : data.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/team_illustration.png',
                              height: 140,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.layers_rounded,
                                size: 80,
                                color: primaryColor.withValues(alpha: 0.45),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isFiltering
                                  ? (lang == 'EN'
                                      ? 'No matching subunits'
                                      : lang == 'ZH'
                                          ? '未找到匹配子单位'
                                          : 'Subunit Tidak Ditemukan')
                                  : (lang == 'EN'
                                      ? 'No subunit data found'
                                      : lang == 'ZH'
                                          ? '未找到子单位数据'
                                          : 'Data subunit tidak ditemukan'),
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB45309),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isFiltering
                                  ? (lang == 'EN'
                                      ? 'Try adjusting your search keyword or filter to find what you\'re looking for.'
                                      : lang == 'ZH'
                                          ? '尝试调整搜索关键词或筛选条件以查找您需要的内容。'
                                          : 'Coba ubah kata kunci pencarian atau filter untuk menemukan yang Anda cari.')
                                  : (lang == 'EN'
                                      ? 'Subunits will show up here as soon as they\'re added.'
                                      : lang == 'ZH'
                                          ? '添加子单位后将显示在此处。'
                                          : 'Subunit akan muncul di sini setelah ditambahkan.'),
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (isFiltering) ...[
                              const SizedBox(height: 18),
                              GestureDetector(
                                onTap: onClearAll,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.refresh_rounded, size: 15, color: primaryColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        lang == 'EN'
                                            ? 'Clear search & filter'
                                            : lang == 'ZH'
                                                ? '清除搜索与筛选'
                                                : 'Hapus pencarian & filter',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: onRefresh,
                      color: primaryColor,
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, listBottomPad),
                        itemCount: data.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final item = data[i];
                          return GestureDetector(
                            onTap: onTapDetail != null ? () => onTapDetail(item) : null,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: card,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.black.withValues(alpha:0.06)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha:0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 84,
                                    height: 84,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: (imageUrlFn != null &&
                                            (imageUrlFn(item) ?? '').isNotEmpty)
                                        ? Image.network(
                                            imageUrlFn(item)!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Icon(icon, color: const Color(0xFFB45309), size: 38),
                                          )
                                        : Icon(icon, color: const Color(0xFFB45309), size: 38),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nameFn(item),
                                          style: GoogleFonts.poppins(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (subtitleWidgetBuilder != null) ...[
                                          const SizedBox(height: 6),
                                          subtitleWidgetBuilder(item),
                                        ],
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => onEdit(item),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB).withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.edit_outlined,
                                          color: Color(0xFF2563EB), size: 20),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => onDelete(item),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.delete_outline_rounded,
                                          color: Color(0xFFEF4444), size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
        if (!isLoading && totalPages > 1 && onPageChanged != null)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: AdminSubunitPageIndicator(
                currentPage: currentPage,
                totalPages: totalPages,
                onPageChanged: onPageChanged,
                color: primaryColor,
                horizontalMargin: 16,
              ),
            ),
          ),
      ],
    ),
  );
}

Future<bool> _showSubunitConfirm(BuildContext context, String name, String lang) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (_) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEBEB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: Color(0xFFEF4444),
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  lang == 'EN' ? 'Delete?' : lang == 'ZH' ? '删除？' : 'Hapus?',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${lang == 'EN' ? 'Are you sure to delete' : lang == 'ZH' ? '确定要删除' : 'Yakin menghapus'} "$name"?',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.delete_forever_rounded,
                        color: Colors.white, size: 18),
                    label: Text(
                      lang == 'EN' ? 'Delete' : lang == 'ZH' ? '删除' : 'Hapus',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      lang == 'EN' ? 'Cancel' : lang == 'ZH' ? '取消' : 'Batal',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ) ??
      false;
}

class _SubunitFilterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final String? activeLabel;
  final Color primaryColor;
  final Color? activeColor;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _SubunitFilterButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.primaryColor,
    required this.onTap,
    this.activeLabel,
    this.activeColor,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isActive ? (activeColor ?? primaryColor) : const Color(0xFFB45309);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? color.withValues(alpha: 0.45) : Colors.grey.shade200,
            width: isActive ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: isActive ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            isActive
                ? Expanded(
                    child: Text(
                      activeLabel ?? label,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : Flexible(
                    child: Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
            if (isActive && onClear != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.45)),
                  ),
                  child: const Icon(Icons.close_rounded, size: 11, color: Color(0xFFEF4444)),
                ),
              ),
            ] else if (isActive) ...[
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: color),
            ],
          ],
        ),
      ),
    );
  }
}