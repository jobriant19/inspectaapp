import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_add_section.dart';
import 'admin_edit_section.dart';
import 'admin_section_detail.dart';
import 'admin_section_filter.dart';
import 'admin_section_indicator.dart';
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
  final TextEditingController _searchCtrl = TextEditingController();

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
    _searchCtrl.dispose();
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
      _currentPage = 1;
    });
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
      builder: (ctx) => AdminSectionLocationFilterDialog(
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
      builder: (ctx) => AdminSectionSortDialog(
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

  // ADD FORM 
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

  // EDIT FORM
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
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _C.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('Section Settings', 'Pengaturan Section', '部门设置'),
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _C.primary),
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
                controller: _searchCtrl,
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
                  suffixIcon: _search.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() {
                              _search = '';
                              _currentPage = 1;
                            });
                          },
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
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
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
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
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/team_illustration.png',
                                height: 150,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    color: _C.primary.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.dashboard_customize_rounded,
                                      size: 50, color: _C.primary.withValues(alpha: 0.4)),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _isFiltering
                                    ? _t('No matching sections', 'Section Tidak Ditemukan', '未找到匹配部门')
                                    : _t('No sections yet', 'Belum Ada Section', '暂无部门'),
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _C.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isFiltering
                                    ? _t(
                                        'Try adjusting your search keyword or filter to find what you\'re looking for.',
                                        'Coba ubah kata kunci pencarian atau filter untuk menemukan yang Anda cari.',
                                        '尝试调整搜索关键词或筛选条件以查找您需要的内容。')
                                    : _t(
                                        'Sections will show up here as soon as they\'re added.',
                                        'Section akan muncul di sini setelah ditambahkan.',
                                        '添加部门后将显示在此处。'),
                                style: GoogleFonts.poppins(
                                    fontSize: 12.5, fontWeight: FontWeight.w600, color: _C.textSub, height: 1.5),
                                textAlign: TextAlign.center,
                              ),
                              if (_isFiltering) ...[
                                const SizedBox(height: 18),
                                GestureDetector(
                                  onTap: _clearSearchAndFilter,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _C.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(color: _C.primary.withValues(alpha: 0.35)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.refresh_rounded, size: 15, color: _C.primary),
                                        const SizedBox(width: 6),
                                        Text(_t('Clear search & filter', 'Hapus pencarian & filter', '清除搜索与筛选'),
                                            style: GoogleFonts.poppins(
                                                fontSize: 12, fontWeight: FontWeight.w700, color: _C.primary)),
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
                        onRefresh: _fetchAll,
                        color: _C.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          itemCount: data.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final item = data[i];
                            final imgUrl = item['gambar_section'] as String?;
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminSectionDetailScreen(
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
                                            errorBuilder: (_, __, ___) => const Icon(
                                              Icons.dashboard_customize_rounded,
                                              color: _C.primary,
                                              size: 24,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.dashboard_customize_rounded,
                                            color: _C.primary,
                                            size: 24,
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
              child: AdminSectionPageIndicator(
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