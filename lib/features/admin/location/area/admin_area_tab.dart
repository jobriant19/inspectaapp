import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../user/finding/finding_pick_pic.dart';
import 'admin_add_area.dart';
import 'admin_area_detail.dart';
import 'admin_area_indicator.dart';
import 'admin_edit_area.dart';
import 'camera/admin_area_camera.dart';
class AdminAreaTab extends StatefulWidget {
  final String lang;
  const AdminAreaTab({super.key, required this.lang});

  @override
  State<AdminAreaTab> createState() => _AdminAreaTabState();
}

class _AdminAreaTabState extends State<AdminAreaTab>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _data = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _search = '';
  int _currentPage = 1;
  static const int _perPage = 10;

  String? _filterField;
  String? _filterValue;
  String? _filterLabel;
  Color? _filterActiveColor;
  String _sortOrder = 'none';

  static const _primary = Color(0xFFF472B6);
  static const _lokasiColor = Color(0xFF10B981);
  static const _unitColor = Color(0xFF6366F1);
  static const _subunitColor = Color(0xFFFBBF24);

  @override
  void initState() {
    super.initState();
    _load();
    AdminAreaCameraWarmupService.instance.warmUp();
  }

  @override
  void dispose() {
    AdminAreaCameraWarmupService.instance.release();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('area')
          .select(
              'id_area, nama_area, deskripsi_area, deskripsi_area_en, deskripsi_area_zh, is_star, gambar_area, qrcode, id_subunit, id_unit, id_lokasi, id_pic, subunit(nama_subunit), unit(nama_unit), lokasi(nama_lokasi), User!fk_area_pic(nama, gambar_user, id_jabatan, is_verificator, jabatan(nama_jabatan))')
          .order('nama_area');
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
      result = result.where((d) => (d['nama_area'] ?? '').toLowerCase().contains(q)).toList();
    }
    if (_filterField != null && _filterValue != null) {
      result = result.where((d) => d[_filterField]?.toString() == _filterValue).toList();
    }
    if (_sortOrder == 'asc') {
      result.sort((a, b) => (a['nama_area'] ?? '').compareTo(b['nama_area'] ?? ''));
    } else if (_sortOrder == 'desc') {
      result.sort((a, b) => (b['nama_area'] ?? '').compareTo(a['nama_area'] ?? ''));
    }
    _filtered = result;
    _currentPage = 1;
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
              ? const Icon(Icons.person_rounded, size: 14, color: Color(0xFFBE185D))
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
      barrierDismissible: true,
      builder: (ctx) => AdminAddAreaDialog(
        lang: widget.lang,
        areas: _data,
        onSaved: _load,
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AdminEditAreaDialog(
        lang: widget.lang,
        existing: item,
        areas: _data,
        onSaved: _load,
      ),
    );
  }

  Future<void> _delete(String id, String name) async {
    final ok = await _showAreaConfirm(context, name, widget.lang);
    if (!ok) return;
    await Supabase.instance.client.from('area').delete().eq('id_area', id);
    _load();
  }

  Widget _buildFilterRow() {
    final bool isFilterActive = _filterField != null;
    final IconData activeIcon = _filterField == 'id_lokasi'
        ? Icons.location_city_rounded
        : _filterField == 'id_unit'
            ? Icons.business_rounded
            : Icons.layers_rounded;
    return Row(
      children: [
        Expanded(
          child: _AreaFilterButton(
            label: widget.lang == 'EN'
                ? 'Specific Location'
                : widget.lang == 'ZH'
                    ? '特定位置'
                    : 'Lokasi Spesifik',
            icon: !isFilterActive ? Icons.map_rounded : activeIcon,
            isActive: isFilterActive,
            activeLabel: _filterLabel,
            primaryColor: _primary,
            activeColor: _filterActiveColor ?? _subunitColor,
            onTap: () => _showLocationFilterDialog(),
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
          child: _AreaFilterButton(
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

  void _showLocationFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _AreaLocationFilterDialog(
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
      } else if (type == 'subunit') {
        _filterField = 'id_subunit';
        _filterValue = result['id'] as String?;
        _filterLabel = result['name'] as String?;
        _filterActiveColor = _subunitColor;
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
      builder: (ctx) => _buildSortDialog(
        ctx: ctx,
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

    return _buildAreaTabContent(
      isLoading: _isLoading,
      search: _search,
      onSearch: (v) => setState(() {
        _search = v;
        _applyFilter();
      }),
      addTitle: widget.lang == 'EN'
          ? 'Add New Area'
          : widget.lang == 'ZH'
              ? '添加新区域'
              : 'Tambah Area Baru',
      addSubtitle: widget.lang == 'EN'
          ? 'Tap to add a new area'
          : widget.lang == 'ZH'
              ? '点击以添加新区域'
              : 'Ketuk untuk menambah area baru',
      data: pageData,
      totalCount: _filtered.length,
      currentPage: safePage,
      totalPages: totalPages,
      onPageChanged: (p) => setState(() => _currentPage = p),
      lang: widget.lang,
      primaryColor: _primary,
      nameFn: (item) => item['nama_area'] ?? '',
      subtitleWidgetBuilder: (item) => _buildPicSubtitle(item),
      imageUrlFn: (item) => item['gambar_area'] as String?,
      icon: Icons.place_rounded,
      onAdd: () => _showAddDialog(),
      onEdit: (item) => _showEditDialog(item),
      onDelete: (item) => _delete(item['id_area'], item['nama_area'] ?? ''),
      onRefresh: _load,
      filterWidget: _buildFilterRow(),
      onTapDetail: (item) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminAreaDetailScreen(
            item: item,
            lang: widget.lang,
            primaryColor: _primary,
            unitColor: _unitColor,
            subunitColor: _subunitColor,
            icon: Icons.place_rounded,
            nameFn: (item) => item['nama_area'] ?? '',
            onEdit: (item) => _showEditDialog(item),
            onDelete: (item) => _delete(item['id_area'], item['nama_area'] ?? ''),
          ),
        ),
      ),
    );
  }
}

Widget _buildAreaTabContent({
  required bool isLoading,
  required String search,
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
              onChanged: onSearch,
              textAlignVertical: TextAlignVertical.center,
              style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 14),
              decoration: InputDecoration(
                hintText: lang == 'EN' ? 'Search...' : lang == 'ZH' ? '搜索...' : 'Cari...',
                hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 20),
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
                  const Icon(Icons.list_alt_rounded, size: 13, color: Color(0xFFBE185D)),
                  const SizedBox(width: 5),
                  Text(
                    '${totalCount ?? data.length} ${lang == 'EN' ? 'items' : lang == 'ZH' ? '条数据' : 'data'}',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFBE185D),
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/team_illustration.png',
                              height: 140,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.place_rounded,
                                size: 80,
                                color: primaryColor.withValues(alpha: 0.45),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              lang == 'EN'
                                  ? 'No area data found'
                                  : lang == 'ZH'
                                      ? '未找到区域数据'
                                      : 'Data area tidak ditemukan',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFBE185D),
                              ),
                              textAlign: TextAlign.center,
                            ),
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
                                                Icon(icon, color: const Color(0xFFBE185D), size: 38),
                                          )
                                        : Icon(icon, color: const Color(0xFFBE185D), size: 38),
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
              child: AdminAreaPageIndicator(
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

Future<bool> _showAreaConfirm(BuildContext context, String name, String lang) async {
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

class _AreaFilterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final String? activeLabel;
  final Color primaryColor;
  final Color? activeColor;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _AreaFilterButton({
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
    final Color color = isActive ? (activeColor ?? primaryColor) : const Color(0xFFBE185D);

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

class _AreaLocationFilterDialog extends StatefulWidget {
  final String lang;
  final String? initialField;
  final String? initialValue;

  const _AreaLocationFilterDialog({
    required this.lang,
    this.initialField,
    this.initialValue,
  });

  @override
  State<_AreaLocationFilterDialog> createState() => _AreaLocationFilterDialogState();
}

class _AreaLocationFilterDialogState extends State<_AreaLocationFilterDialog> {
  static const _purple = Color(0xFF6366F1);
  static const _purpleLight = Color(0xFFEEF2FF);

  static const _levels = ['Lokasi', 'Unit', 'Sub-Unit'];
  static const _levelColors = [Color(0xFF10B981), _purple, Color(0xFFFBBF24)];
  static const _levelIcons = [
    Icons.location_city_rounded,
    Icons.business_rounded,
    Icons.layers_rounded,
  ];

  final TextEditingController _searchCtrl = TextEditingController();
  int _tabIndex = 0;
  bool _isLoading = true;

  List<Map<String, dynamic>> _lokasiData = [];
  List<Map<String, dynamic>> _unitData = [];
  List<Map<String, dynamic>> _subunitData = [];

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialField == 'id_unit'
        ? 1
        : widget.initialField == 'id_subunit'
            ? 2
            : 0;
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

  String _levelLabel(int i) {
    switch (i) {
      case 1:
        return 'Unit';
      case 2:
        return 'Sub-Unit';
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
        supabase.from('unit').select('id_unit, nama_unit').order('nama_unit'),
        supabase.from('subunit').select('id_subunit, nama_subunit').order('nama_subunit'),
      ]);
      if (mounted) {
        setState(() {
          _lokasiData = List<Map<String, dynamic>>.from(results[0] as List);
          _unitData = List<Map<String, dynamic>>.from(results[1] as List);
          _subunitData = List<Map<String, dynamic>>.from(results[2] as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading area filter dialog: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _currentData {
    switch (_tabIndex) {
      case 1:
        return _unitData;
      case 2:
        return _subunitData;
      default:
        return _lokasiData;
    }
  }

  String _nameOf(Map<String, dynamic> item) {
    switch (_tabIndex) {
      case 1:
        return item['nama_unit']?.toString() ?? '-';
      case 2:
        return item['nama_subunit']?.toString() ?? '-';
      default:
        return item['nama_lokasi']?.toString() ?? '-';
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _currentData;
    return _currentData.where((item) => _nameOf(item).toLowerCase().contains(q)).toList();
  }

  void _selectItem(Map<String, dynamic> item) {
    final types = ['lokasi', 'unit', 'subunit'];
    final idKeys = ['id_lokasi', 'id_unit', 'id_subunit'];
    Navigator.pop(context, {
      'type': types[_tabIndex],
      'id': item[idKeys[_tabIndex]]?.toString(),
      'name': _nameOf(item),
    });
  }

  void _selectAll() {
    Navigator.pop(context, {'type': 'none'});
  }

  Widget _buildAllCard() {
    final color = _levelColors[_tabIndex];
    final isSel = widget.initialField == null;
    return GestureDetector(
      onTap: _selectAll,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSel ? _purpleLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSel ? _purple : const Color(0xFFE2E8F0), width: isSel ? 1.5 : 1),
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
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF1E3A8A)),
              ),
            ),
            if (isSel)
              const Icon(Icons.check_circle_rounded, color: _purple, size: 20)
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

    return GestureDetector(
      onTap: () => _selectItem(item),
      child: Container(
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
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
              child: Icon(_levelIcons[_tabIndex], size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF1E3A8A)),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              height: 100,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.place_rounded,
                size: 56,
                color: Color(0xFFFBCFE8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _t('Tidak ada data', 'No data found', '未找到数据'),
              style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: _purple),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final filtered = _filtered;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 340,
        height: screenHeight * 0.72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _purpleLight, width: 1.5),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _purpleLight, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.map_rounded, color: _purple, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _t('Filter Area', 'Filter Area', '筛选区域'),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16, color: _purple),
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
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                children: List.generate(_levels.length, (index) {
                  final isActive = _tabIndex == index;
                  final color = _levelColors[index];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _tabIndex = index;
                        _searchCtrl.clear();
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
                            Icon(_levelIcons[index], size: 15, color: isActive ? Colors.white : color),
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
                  border: Border.all(color: _purple.withValues(alpha: 0.35), width: 1.3),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  textAlignVertical: TextAlignVertical.center,
                  style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1E3A8A)),
                  decoration: InputDecoration(
                    hintText: '${_t('Cari', 'Search', '搜索')} ${_levelLabel(_tabIndex)}...',
                    hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black38),
                    prefixIcon: const Icon(Icons.search_rounded, color: _purple, size: 18),
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
                          ...filtered.map(_buildItemCard),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildSortDialog({
  required BuildContext ctx,
  required Color primaryColor,
  required String currentSort,
  required String lang,
  required void Function(String sort) onSelect,
}) {
  final options = [
    {'value': 'none', 'label': lang == 'EN' ? 'Default (No Sort)' : lang == 'ZH' ? '默认' : 'Default (Tanpa Urutan)'},
    {'value': 'asc', 'label': lang == 'EN' ? 'A → Z (Ascending)' : 'A → Z (Ascending)'},
    {'value': 'desc', 'label': lang == 'EN' ? 'Z → A (Descending)' : 'Z → A (Descending)'},
  ];

  return Dialog(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha:0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            children: [
              const Icon(Icons.sort_by_alpha_rounded, color: Color(0xFFBE185D), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lang == 'EN' ? 'Sort Order' : lang == 'ZH' ? '排序方式' : 'Urutan Abjad',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E3A8A)),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration:
                      BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                  child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
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
                    color: isSelected ? primaryColor.withValues(alpha:0.10) : Colors.white,
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
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? const Color(0xFFBE185D) : const Color(0xFF1E3A8A),
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: Color(0xFFBE185D), size: 18),
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