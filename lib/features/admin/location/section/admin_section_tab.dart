import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/code/qr_generator_screen.dart';
import '../../../user/finding/finding_pick_pic.dart';
import 'admin_add_section.dart';
import 'admin_edit_section.dart';
import 'camera/admin_section_camera.dart';

class _C {
  static const primary   = Color(0xFF1D72F3);
  static const primaryLt = Color(0xFFDCEAFE);
  static const red       = Color(0xFFEF4444);
  static const textMain  = Color(0xFF1D72F3);
  static const textSub   = Color(0xFF64748B);
  static const divider   = Color(0xFFE2E8F0);
  static const surface   = Color(0xFFF8FAFC);
}

class AdminSectionTab extends StatefulWidget {
  final String lang;
  const AdminSectionTab({super.key, required this.lang});

  @override
  State<AdminSectionTab> createState() => _AdminSectionTabState();
}

class _AdminSectionTabState extends State<AdminSectionTab> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _lokasiList = [];
  List<Map<String, dynamic>> _unitList = [];
  List<Map<String, dynamic>> _subunitList = [];
  List<Map<String, dynamic>> _areaList = [];
  bool _loading = true;
  String _search = '';
  int _currentPage = 1;
  static const int _perPage = 10;

  String? _filterField;
  String? _filterValue;
  String? _filterLabel;
  Color? _filterActiveColor;
  String _sortOrder = 'none';

  static const _lokasiColor = Color(0xFF10B981);
  static const _unitColor = Color(0xFF6366F1);
  static const _subunitColor = Color(0xFFFBBF24);
  static const _areaColor = Color(0xFFF472B6);

  // Urutan (en, id, zh) -- konvensi bahasa di file ini.
  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  String _nameOf(Map<String, dynamic> s) {
    if (widget.lang == 'EN') {
      return s['nama_section_en']?.toString() ?? s['nama_section_id']?.toString() ?? '-';
    }
    if (widget.lang == 'ZH') {
      return s['nama_section_zh']?.toString() ?? s['nama_section_id']?.toString() ?? '-';
    }
    return s['nama_section_id']?.toString() ?? '-';
  }


  @override
  void initState() {
    super.initState();
    _fetchAll();
    AdminSectionCameraWarmupService.instance.warmUp();
  }

  @override
  void dispose() {
    AdminSectionCameraWarmupService.instance.release();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _supabase
            .from('section')
            .select(
                '*, lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area), User!fk_section_pic(nama, gambar_user, id_jabatan, is_verificator, jabatan(nama_jabatan))')
            .order('urutan', ascending: true),
        _supabase.from('lokasi').select('id_lokasi, nama_lokasi').order('nama_lokasi'),
        _supabase.from('unit').select('id_unit, nama_unit, id_lokasi').order('nama_unit'),
        _supabase.from('subunit').select('id_subunit, nama_subunit, id_unit').order('nama_subunit'),
        _supabase.from('area').select('id_area, nama_area, id_subunit').order('nama_area'),
      ]);
      if (mounted) {
        setState(() {
          _sections = List<Map<String, dynamic>>.from(results[0] as List);
          _lokasiList = List<Map<String, dynamic>>.from(results[1] as List);
          _unitList = List<Map<String, dynamic>>.from(results[2] as List);
          _subunitList = List<Map<String, dynamic>>.from(results[3] as List);
          _areaList = List<Map<String, dynamic>>.from(results[4] as List);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch section: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    List<Map<String, dynamic>> result = List.from(_sections);

    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      result = result.where((s) => _nameOf(s).toLowerCase().contains(q)).toList();
    }

    if (_filterField != null && _filterValue != null) {
      result = result.where((s) => s[_filterField]?.toString() == _filterValue).toList();
    }

    if (_sortOrder == 'asc') {
      result.sort((a, b) => _nameOf(a).compareTo(_nameOf(b)));
    } else if (_sortOrder == 'desc') {
      result.sort((a, b) => _nameOf(b).compareTo(_nameOf(a)));
    }

    return result;
  }

  void _showSuccessPopup({
    required bool isSuccess,
    required String titleEn,
    required String titleId,
    required String titleZh,
    required String msgEn,
    required String msgId,
    required String msgZh,
  }) {
    if (!mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'success_section',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1.0)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) {
        final color = isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
        final bgLight = isSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
        final icon = isSuccess ? Icons.check_circle_rounded : Icons.error_rounded;
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 36),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.22),
                    blurRadius: 32,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: bgLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.25), width: 2),
                    ),
                    child: Icon(icon, color: color, size: 38),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _t(titleEn, titleId, titleZh),
                    style: GoogleFonts.poppins(
                        fontSize: 17, fontWeight: FontWeight.w800, color: color),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _t(msgEn, msgId, msgZh),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey.shade600, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _t('Close', 'Tutup', '关闭'),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterRow() {
    final bool isFilterActive = _filterField != null;
    final IconData activeIcon = _filterField == 'id_lokasi'
        ? Icons.location_city_rounded
        : _filterField == 'id_unit'
            ? Icons.business_rounded
            : _filterField == 'id_subunit'
                ? Icons.layers_rounded
                : Icons.place_rounded;
    return Row(
      children: [
        Expanded(
          child: _SectionFilterButton(
            label: _t('Specific Location', 'Lokasi Spesifik', '特定位置'),
            icon: !isFilterActive ? Icons.map_rounded : activeIcon,
            isActive: isFilterActive,
            activeLabel: _filterLabel,
            primaryColor: _C.primary,
            activeColor: _filterActiveColor ?? _lokasiColor,
            onTap: _showLocationFilterDialog,
            onClear: () => setState(() {
              _filterField = null;
              _filterValue = null;
              _filterLabel = null;
              _filterActiveColor = null;
              _currentPage = 1;
            }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SectionFilterButton(
            label: _t('Sort', 'Urutan', '排序'),
            icon: Icons.sort_by_alpha_rounded,
            isActive: _sortOrder != 'none',
            activeLabel: _sortOrder == 'asc' ? 'A→Z' : _sortOrder == 'desc' ? 'Z→A' : null,
            primaryColor: _C.primary,
            onTap: _showSortDialog,
          ),
        ),
      ],
    );
  }

  void _showLocationFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _SectionLocationFilterDialog(
        lang: widget.lang,
        lokasiList: _lokasiList,
        unitList: _unitList,
        subunitList: _subunitList,
        areaList: _areaList,
        initialField: _filterField,
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
      } else if (type == 'area') {
        _filterField = 'id_area';
        _filterValue = result['id'] as String?;
        _filterLabel = result['name'] as String?;
        _filterActiveColor = _areaColor;
      } else {
        _filterField = null;
        _filterValue = null;
        _filterLabel = null;
        _filterActiveColor = null;
      }
      _currentPage = 1;
    });
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _SectionSortDialog(
        primaryColor: _C.primary,
        currentSort: _sortOrder,
        lang: widget.lang,
        onSelect: (sort) {
          setState(() {
            _sortOrder = sort;
            _currentPage = 1;
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  // ADD FORM — didelegasikan ke AdminAddSectionDialog
  Future<void> _showAddDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AdminAddSectionDialog(
        lang: widget.lang,
        sections: _sections,
        lokasiList: _lokasiList,
        unitList: _unitList,
        subunitList: _subunitList,
        areaList: _areaList,
        onSaved: _fetchAll,
        showResultPopup: _showSuccessPopup,
      ),
    );
  }

  // EDIT FORM — didelegasikan ke AdminEditSectionDialog
  Future<void> _showEditDialog(Map<String, dynamic> existing) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AdminEditSectionDialog(
        lang: widget.lang,
        existing: existing,
        sections: _sections,
        lokasiList: _lokasiList,
        unitList: _unitList,
        subunitList: _subunitList,
        areaList: _areaList,
        onSaved: _fetchAll,
        showResultPopup: _showSuccessPopup,
      ),
    );
  }

  // DELETE CONFIRM
  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (_) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEB),
                      shape: BoxShape.circle,
                      border: Border.all(color: _C.red.withValues(alpha: 0.25), width: 2),
                    ),
                    child: const Icon(Icons.delete_forever_rounded, color: _C.red, size: 34),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _t('Delete Section?', 'Hapus Section?', '删除部门？'),
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _t(
                      'Users linked to this section will keep their data, but the section link will be removed.',
                      'User yang terhubung ke section ini datanya tetap ada, namun tautan section akan dihapus.',
                      '与此部门关联的用户数据将保留，但部门关联将被移除。',
                    ),
                    style: GoogleFonts.poppins(fontSize: 12, color: _C.textSub, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 16),
                      label: Text(
                        _t('Delete', 'Hapus', '删除'),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.red,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _C.divider),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _t('Cancel', 'Batal', '取消'),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 13, color: _C.textSub),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;

    if (!ok) return;
    try {
      await _supabase.from('section').delete().eq('id_section', item['id_section']);
      await _fetchAll();
      _showSuccessPopup(
        isSuccess: true,
        titleEn: 'Deleted!',
        titleId: 'Dihapus!',
        titleZh: '已删除！',
        msgEn: 'Section has been deleted.',
        msgId: 'Section berhasil dihapus.',
        msgZh: '部门已成功删除。',
      );
    } catch (e) {
      debugPrint('Delete section error: $e');
    }
  }

  // Label lokasi di card hanya menampilkan level PALING SPESIFIK yang
  // tersedia, urutan prioritas: Area > Sub-Unit > Unit > Lokasi -- masing
  // masing dengan ikon dan warna khas levelnya sendiri.
  Map<String, dynamic>? _specificLocationInfo(Map<String, dynamic> item) {
    if (item['area']?['nama_area'] != null) {
      return {
        'label': item['area']['nama_area'],
        'icon': Icons.place_rounded,
        'color': const Color(0xFFF472B6),
      };
    }
    if (item['subunit']?['nama_subunit'] != null) {
      return {
        'label': item['subunit']['nama_subunit'],
        'icon': Icons.layers_rounded,
        'color': const Color(0xFFFBBF24),
      };
    }
    if (item['unit']?['nama_unit'] != null) {
      return {
        'label': item['unit']['nama_unit'],
        'icon': Icons.business_rounded,
        'color': const Color(0xFF6366F1),
      };
    }
    if (item['lokasi']?['nama_lokasi'] != null) {
      return {
        'label': item['lokasi']['nama_lokasi'],
        'icon': Icons.location_city_rounded,
        'color': const Color(0xFF10B981),
      };
    }
    return null;
  }

  Widget _buildLocationChip(Map<String, dynamic> item) {
    final info = _specificLocationInfo(item);
    if (info == null) {
      return Text(
        _t('No location mapped', 'Tidak ada lokasi', '未设置位置'),
        style: GoogleFonts.poppins(fontSize: 10, color: _C.textSub),
      );
    }
    final color = info['color'] as Color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info['icon'] as IconData, size: 11, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              info['label'] as String,
              style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allData = _filtered;
    final totalPages = allData.isEmpty ? 1 : (allData.length / _perPage).ceil();
    final safePage = _currentPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * _perPage;
    final endIdx = (startIdx + _perPage) > allData.length ? allData.length : startIdx + _perPage;
    final data = allData.isEmpty ? <Map<String, dynamic>>[] : allData.sublist(startIdx, endIdx);

    return Scaffold(
      backgroundColor: _C.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _C.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('Section Settings', 'Pengaturan Section', '部门设置'),
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: _C.primary),
        ),
      ),
      body: Column(
        children: [
          // ADD BUTTON
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: GestureDetector(
              onTap: () => _showAddDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_C.primary, _C.primary.withValues(alpha: 0.78)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                        color: _C.primary.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _t('Add Section', 'Tambah Section', '添加部门'),
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        Text(
                          _t('Tap to add a new section', 'Ketuk untuk menambah section baru', '点击以添加新部门'),
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: Colors.white.withValues(alpha: 0.82), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 13),
                ]),
              ),
            ),
          ),

          // SEARCH
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.divider),
              ),
              child: TextField(
                onChanged: (v) => setState(() {
                  _search = v;
                  _currentPage = 1;
                }),
                textAlignVertical: TextAlignVertical.center,
                style: GoogleFonts.poppins(fontSize: 13, color: _C.textMain),
                decoration: InputDecoration(
                  hintText: _t('Search section...', 'Cari section...', '搜索部门...'),
                  hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.black38),
                  prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 18),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildFilterRow(),
          ),

          // COUNT
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _C.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _C.primary.withValues(alpha: 0.30)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.dashboard_customize_rounded, size: 13, color: _C.primary),
                    const SizedBox(width: 5),
                    Text(
                      '${allData.length} ${_t('sections', 'section', '个部门')}',
                      style: GoogleFonts.poppins(
                          color: _C.primary, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // LIST
          Expanded(
            child: _loading
                ? Shimmer.fromColors(
                    baseColor: Colors.grey.shade200,
                    highlightColor: Colors.grey.shade50,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      itemCount: 6,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, __) => Container(
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  )
                : data.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.dashboard_customize_outlined, size: 52, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            Text(_t('No sections yet.', 'Belum ada section.', '暂无部门。'),
                                style: GoogleFonts.poppins(fontSize: 13, color: _C.textSub)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchAll,
                        color: _C.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                          itemCount: data.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final item = data[i];
                            final imgUrl = item['gambar_section'] as String?;
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _SectionDetailScreen(
                                    item: item,
                                    lang: widget.lang,
                                    onEdit: (it) => _showEditDialog(it),
                                    onDelete: (it) => _confirmDelete(it),
                                  ),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: _C.divider),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: Row(children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                        color: _C.primaryLt, borderRadius: BorderRadius.circular(12)),
                                    child: (imgUrl != null && imgUrl.isNotEmpty)
                                        ? Image.network(
                                            imgUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Center(
                                              child: Text(
                                                '${item['urutan'] ?? i + 1}',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 15, fontWeight: FontWeight.w800, color: _C.primary),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              '${item['urutan'] ?? i + 1}',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 15, fontWeight: FontWeight.w800, color: _C.primary),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _nameOf(item),
                                          style: GoogleFonts.poppins(
                                              fontSize: 13, fontWeight: FontWeight.w700, color: _C.textMain),
                                        ),
                                        const SizedBox(height: 4),
                                        _buildLocationChip(item),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showEditDialog(item),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                          color: _C.primary.withValues(alpha: 0.09),
                                          borderRadius: BorderRadius.circular(9)),
                                      child: const Icon(Icons.edit_outlined, color: _C.primary, size: 15),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => _confirmDelete(item),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                          color: _C.red.withValues(alpha: 0.09),
                                          borderRadius: BorderRadius.circular(9)),
                                      child: const Icon(Icons.delete_outline_rounded, color: _C.red, size: 15),
                                    ),
                                  ),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
          ),
          if (!_loading && totalPages > 1)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: _SectionPageIndicator(
                currentPage: safePage,
                totalPages: totalPages,
                onPageChanged: (p) => setState(() => _currentPage = p),
                color: _C.primary,
              ),
            ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------
// Layar Detail Section: semua kolom tabel + generate/regenerate QR Code
// --------------------------------------------------------------------
class _SectionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final String lang;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;

  const _SectionDetailScreen({
    required this.item,
    required this.lang,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_SectionDetailScreen> createState() => _SectionDetailScreenState();
}

class _SectionDetailScreenState extends State<_SectionDetailScreen> {
  late Map<String, dynamic> _item;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  String get _name {
    if (widget.lang == 'EN') {
      return _item['nama_section_en']?.toString() ?? _item['nama_section_id']?.toString() ?? '-';
    }
    if (widget.lang == 'ZH') {
      return _item['nama_section_zh']?.toString() ?? _item['nama_section_id']?.toString() ?? '-';
    }
    return _item['nama_section_id']?.toString() ?? '-';
  }

  String get _desc {
    if (widget.lang == 'EN') {
      return (_item['deskripsi_section_en'] ?? _item['deskripsi_section'] ?? '').toString();
    }
    if (widget.lang == 'ZH') {
      return (_item['deskripsi_section_zh'] ?? _item['deskripsi_section'] ?? '').toString();
    }
    return (_item['deskripsi_section'] ?? '').toString();
  }

  Future<void> _openQrGenerator() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRGeneratorScreen(
          lang: widget.lang,
          levelName: 'section',
          levelId: _item['id_section'].toString(),
          itemName: _name,
        ),
      ),
    );
    if (result == true) {
      setState(() => _isRefreshing = true);
      try {
        final refreshed = await Supabase.instance.client
            .from('section')
            .select(
                '*, lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area), User!fk_section_pic(nama, gambar_user, id_jabatan, is_verificator, jabatan(nama_jabatan))')
            .eq('id_section', _item['id_section'].toString())
            .maybeSingle();
        if (refreshed != null && mounted) {
          setState(() => _item = {..._item, ...refreshed});
        }
      } catch (e) {
        debugPrint('Refresh QR section error: $e');
      } finally {
        if (mounted) setState(() => _isRefreshing = false);
      }
    }
  }

  void _openFullImage(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _C.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.poppins(color: _C.primary, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _mappingBadge({required IconData icon, required Color color, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.poppins(color: color, fontSize: 11, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gambarUrl = _item['gambar_section'] as String?;
    final isStar = (_item['is_star'] ?? 0) as int;
    final qrcode = _item['qrcode'] as String?;
    final lokasiName = _item['lokasi']?['nama_lokasi'] as String?;
    final unitName = _item['unit']?['nama_unit'] as String?;
    final subunitName = _item['subunit']?['nama_subunit'] as String?;
    final areaName = _item['area']?['nama_area'] as String?;
    final picData = _item['User'] as Map<String, dynamic>?;
    final picName = picData?['nama'] as String?;
    final picImage = picData?['gambar_user'] as String?;
    final picJabatan = picData?['jabatan']?['nama_jabatan'] as String?;
    final picIdJabatan = picData?['id_jabatan'] as int?;
    final picIsVerificator = picData?['is_verificator'] as bool?;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _C.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('Section Detail', 'Detail Section', '部门详情'),
          style: GoogleFonts.poppins(color: _C.primary, fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: (gambarUrl != null && gambarUrl.isNotEmpty)
                      ? () => _openFullImage(gambarUrl)
                      : null,
                  child: Container(
                    width: 96,
                    height: 96,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: _C.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                      border: (gambarUrl != null && gambarUrl.isNotEmpty)
                          ? Border.all(color: _C.primary.withValues(alpha: 0.25), width: 1.5)
                          : null,
                    ),
                    child: (gambarUrl != null && gambarUrl.isNotEmpty)
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                gambarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.dashboard_customize_rounded, color: _C.primary, size: 30),
                              ),
                              Positioned(
                                right: 6,
                                bottom: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.zoom_in_rounded, size: 13, color: _C.primary),
                                ),
                              ),
                            ],
                          )
                        : const Icon(Icons.dashboard_customize_rounded, color: _C.primary, size: 30),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name,
                        style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                      if (lokasiName != null || unitName != null || subunitName != null || areaName != null) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (lokasiName != null && lokasiName.isNotEmpty)
                              _mappingBadge(icon: Icons.location_city_rounded, color: const Color(0xFF10B981), label: lokasiName),
                            if (unitName != null && unitName.isNotEmpty)
                              _mappingBadge(icon: Icons.business_rounded, color: const Color(0xFF6366F1), label: unitName),
                            if (subunitName != null && subunitName.isNotEmpty)
                              _mappingBadge(icon: Icons.layers_rounded, color: const Color(0xFFFBBF24), label: subunitName),
                            if (areaName != null && areaName.isNotEmpty)
                              _mappingBadge(icon: Icons.place_rounded, color: const Color(0xFFF472B6), label: areaName),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isStar > 0 ? const Color(0xFFFEF3C7) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isStar > 0 ? const Color(0xFFFBBF24) : Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isStar > 0 ? Icons.star_rounded : Icons.star_border_rounded,
                                size: 12, color: isStar > 0 ? const Color(0xFFFBBF24) : Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              isStar > 0 ? _t('Starred', 'Bintang', '已加星标') : _t('No Star', 'Tanpa Bintang', '无星标'),
                              style: GoogleFonts.poppins(
                                  fontSize: 10, fontWeight: FontWeight.w600, color: isStar > 0 ? const Color(0xFFF59E0B) : Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.grey.shade100, thickness: 1.5),
            const SizedBox(height: 16),

            _sectionLabel(Icons.notes_rounded, _t('Description', 'Deskripsi', '描述')),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _C.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.primary.withValues(alpha: 0.20)),
              ),
              child: Text(
                _desc.isEmpty ? '-' : _desc,
                style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),

            _sectionLabel(Icons.badge_rounded, 'PIC'),
            const SizedBox(height: 10),
            if (picName != null && picName.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _C.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.primary.withValues(alpha: 0.20)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: _C.primary.withValues(alpha: 0.18),
                      backgroundImage: (picImage != null && picImage.isNotEmpty) ? NetworkImage(picImage) : null,
                      child: (picImage == null || picImage.isEmpty)
                          ? const Icon(Icons.person_rounded, color: _C.primary, size: 22)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(picName, style: GoogleFonts.poppins(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 5),
                          buildJabatanBadge(
                            idJabatan: picIdJabatan,
                            jabatanNama: picJabatan,
                            isVerificator: picIsVerificator,
                            lang: widget.lang,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFFBBF24).withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.person_off_rounded, size: 16, color: Color(0xFFF59E0B)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _t('No PIC assigned yet', 'Belum ada PIC yang ditugaskan', '尚未分配负责人'),
                        style: GoogleFonts.poppins(color: const Color(0xFFB45309), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            _sectionLabel(Icons.qr_code_2_rounded, 'QR Code'),
            const SizedBox(height: 10),
            if (_isRefreshing)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (qrcode != null && qrcode.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _C.primary.withValues(alpha: 0.25)),
                  boxShadow: [BoxShadow(color: _C.primary.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    QrImageView(data: qrcode, version: QrVersions.auto, size: 220),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _openQrGenerator,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(_t('Regenerate QR', 'Buat Ulang QR', '重新生成二维码'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _C.primary,
                        side: const BorderSide(color: _C.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      _t('QR Code has not been generated yet.', 'Kode QR belum dibuat.', '二维码尚未生成。'),
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.black45, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _openQrGenerator,
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: Text(_t('Generate QR Code', 'Buat Kode QR', '生成二维码'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        shadowColor: _C.primary.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onEdit(_item);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 16),
                          const SizedBox(width: 6),
                          Text(_t('Edit', 'Edit', '编辑'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF2563EB))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onDelete(_item);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16),
                          const SizedBox(width: 6),
                          Text(_t('Delete', 'Hapus', '删除'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFFEF4444))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionPageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final Color color;

  const _SectionPageIndicator({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.color,
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _arrowButton(
            icon: Icons.arrow_back_ios_new_rounded,
            enabled: canPrev,
            onTap: () {
              if (!canPrev) return;
              onPageChanged(currentPage - 1);
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                for (final p in pageNumbers) ...[
                  Expanded(child: _pageButton(p)),
                  if (p != pageNumbers.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          _arrowButton(
            icon: Icons.arrow_forward_ios_rounded,
            enabled: canNext,
            onTap: () {
              if (!canNext) return;
              onPageChanged(currentPage + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _pageButton(int page) {
    final bool isActive = page == currentPage;
    return GestureDetector(
      onTap: () {
        if (page == currentPage) return;
        onPageChanged(page);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: isActive ? null : Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          '$page',
          style: GoogleFonts.poppins(
            color: isActive ? Colors.white : color,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _arrowButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.16) : Colors.grey.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 15,
          color: enabled ? color : Colors.grey.shade400,
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------
// Filter Button & Location Filter Dialog untuk Section Settings
// --------------------------------------------------------------------
class _SectionFilterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final String? activeLabel;
  final Color primaryColor;
  final Color? activeColor;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _SectionFilterButton({
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
    final Color color = isActive ? (activeColor ?? primaryColor) : primaryColor;

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
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : Flexible(
                    child: Text(
                      label,
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: color),
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
                    color: _C.red.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: _C.red.withValues(alpha: 0.45)),
                  ),
                  child: Icon(Icons.close_rounded, size: 11, color: _C.red),
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

class _SectionLocationFilterDialog extends StatefulWidget {
  final String lang;
  final List<Map<String, dynamic>> lokasiList;
  final List<Map<String, dynamic>> unitList;
  final List<Map<String, dynamic>> subunitList;
  final List<Map<String, dynamic>> areaList;
  final String? initialField;

  const _SectionLocationFilterDialog({
    required this.lang,
    required this.lokasiList,
    required this.unitList,
    required this.subunitList,
    required this.areaList,
    required this.initialField,
  });

  @override
  State<_SectionLocationFilterDialog> createState() => _SectionLocationFilterDialogState();
}

class _SectionLocationFilterDialogState extends State<_SectionLocationFilterDialog> {
  static const _levels = ['Lokasi', 'Unit', 'Sub-Unit', 'Area'];
  static const _levelColors = [
    Color(0xFF10B981),
    Color(0xFF6366F1),
    Color(0xFFFBBF24),
    Color(0xFFF472B6),
  ];
  static const _levelIcons = [
    Icons.location_city_rounded,
    Icons.business_rounded,
    Icons.layers_rounded,
    Icons.place_rounded,
  ];

  final TextEditingController _searchCtrl = TextEditingController();
  int _tabIndex = 0;

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialField == 'id_unit'
        ? 1
        : widget.initialField == 'id_subunit'
            ? 2
            : widget.initialField == 'id_area'
                ? 3
                : 0;
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _levelLabel(int i) {
    switch (i) {
      case 1:
        return 'Unit';
      case 2:
        return 'Sub-Unit';
      case 3:
        return _t('Area', 'Area', '区域');
      default:
        return _t('Location', 'Lokasi', '位置');
    }
  }

  List<Map<String, dynamic>> get _currentData {
    switch (_tabIndex) {
      case 1:
        return widget.unitList;
      case 2:
        return widget.subunitList;
      case 3:
        return widget.areaList;
      default:
        return widget.lokasiList;
    }
  }

  String _idKey(int i) {
    switch (i) {
      case 1:
        return 'id_unit';
      case 2:
        return 'id_subunit';
      case 3:
        return 'id_area';
      default:
        return 'id_lokasi';
    }
  }

  String _nameKey(int i) {
    switch (i) {
      case 1:
        return 'nama_unit';
      case 2:
        return 'nama_subunit';
      case 3:
        return 'nama_area';
      default:
        return 'nama_lokasi';
    }
  }

  String _typeKey(int i) {
    switch (i) {
      case 1:
        return 'unit';
      case 2:
        return 'subunit';
      case 3:
        return 'area';
      default:
        return 'lokasi';
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    final nameKey = _nameKey(_tabIndex);
    if (q.isEmpty) return _currentData;
    return _currentData
        .where((item) => (item[nameKey]?.toString() ?? '').toLowerCase().contains(q))
        .toList();
  }

  void _selectItem(Map<String, dynamic> item) {
    Navigator.pop(context, {
      'type': _typeKey(_tabIndex),
      'id': item[_idKey(_tabIndex)]?.toString(),
      'name': item[_nameKey(_tabIndex)]?.toString(),
    });
  }

  void _selectAll() => Navigator.pop(context, {'type': 'none'});

  Widget _buildAllCard() {
    final color = _levelColors[_tabIndex];
    final isSel = widget.initialField == null;
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
                _t('All (No Filter)', 'Semua (Tanpa Filter)', '全部'),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: _C.textMain),
              ),
            ),
            if (isSel)
              Icon(Icons.check_circle_rounded, color: _C.primary, size: 20)
            else
              Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final color = _levelColors[_tabIndex];
    final name = item[_nameKey(_tabIndex)]?.toString() ?? '-';
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
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13, color: _C.textMain),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
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
                      _t('Filter Section', 'Filter Section', '筛选部门'),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16, color: _C.primary),
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
                      }),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
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
                                fontSize: 10,
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
                  textAlignVertical: TextAlignVertical.center,
                  style: GoogleFonts.poppins(fontSize: 13, color: _C.textMain),
                  decoration: InputDecoration(
                    hintText: '${_t('Search', 'Cari', '搜索')} ${_levelLabel(_tabIndex)}...',
                    hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black38),
                    prefixIcon: const Icon(Icons.search_rounded, color: _C.primary, size: 18),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                children: [
                  _buildAllCard(),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(_t('No data found', 'Tidak ada data', '未找到数据'),
                            style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: _C.textSub)),
                      ),
                    )
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

class _SectionSortDialog extends StatelessWidget {
  final Color primaryColor;
  final String currentSort;
  final String lang;
  final void Function(String sort) onSelect;

  const _SectionSortDialog({
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
      {'value': 'asc', 'label': 'A → Z'},
      {'value': 'desc', 'label': 'Z → A'},
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
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Icon(Icons.sort_by_alpha_rounded, color: primaryColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _t('Sort Order', 'Urutan Abjad', '排序方式'),
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: primaryColor),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
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
                              color: isSelected ? primaryColor : const Color(0xFF1E3A8A),
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