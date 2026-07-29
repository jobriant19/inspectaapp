import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../user/finding/finding_pick_pic.dart';
import 'admin_add_location.dart';
import 'admin_edit_location.dart';
import 'admin_location_detail.dart';
import 'admin_location_indicator.dart';
import 'camera/admin_location_camera.dart';

class AdminLocationTab extends StatefulWidget {
  final String lang;
  const AdminLocationTab({super.key, required this.lang});

  @override
  State<AdminLocationTab> createState() => _AdminLocationTabState();
}

class _AdminLocationTabState extends State<AdminLocationTab>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _data = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _search = '';
  int _currentPage = 1;
  static const int _perPage = 10;

  static const _primary = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _load();
    AdminLocationCameraWarmupService.instance.warmUp();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    AdminLocationCameraWarmupService.instance.release();
    super.dispose();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {
      _search = '';
      _applyFilter();
    });
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('lokasi')
          .select(
              'id_lokasi, nama_lokasi, deskripsi_lokasi, deskripsi_lokasi_en, deskripsi_lokasi_zh, is_star, gambar_lokasi, qrcode, id_pic, User!fk_lokasi_pic(nama, gambar_user, id_jabatan, is_verificator, jabatan(nama_jabatan))')
          .order('nama_lokasi');
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
    _filtered = q.isEmpty
        ? List.from(_data)
        : _data
            .where((d) => (d['nama_lokasi'] ?? '').toLowerCase().contains(q))
            .toList();
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'PIC :',
            style: GoogleFonts.poppins(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            widget.lang == 'EN' ? 'No PIC' : widget.lang == 'ZH' ? '无负责人' : 'Belum ada PIC',
            style: GoogleFonts.poppins(color: Colors.black38, fontSize: 11),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'PIC :',
          style: GoogleFonts.poppins(color: Colors.black54, fontSize: 10.5, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: _primary.withValues(alpha: 0.15),
              backgroundImage: (picImage != null && picImage.isNotEmpty) ? NetworkImage(picImage) : null,
              child: (picImage == null || picImage.isEmpty)
                  ? Icon(Icons.person_rounded, size: 14, color: _primary)
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
        ),
      ],
    );
  }

  void _openAddDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AdminAddLocationDialog(
        lang: widget.lang,
        onSaved: _load,
      ),
    );
  }

  void _openEditDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AdminEditLocationDialog(
        lang: widget.lang,
        existing: item,
        onSaved: _load,
      ),
    );
  }

  Future<void> _delete(String id, String name) async {
    final ok = await _showLocationConfirm(context, name, widget.lang);
    if (!ok) return;
    await Supabase.instance.client.from('lokasi').delete().eq('id_lokasi', id);
    _load();
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

    return _buildLocationTabContent(
      isLoading: _isLoading,
      search: _search,
      searchCtrl: _searchCtrl,
      onSearch: (v) => setState(() {
        _search = v;
        _applyFilter();
      }),
      onClearSearch: _clearSearch,
      addTitle: widget.lang == 'EN'
          ? 'Add New Location'
          : widget.lang == 'ZH'
              ? '添加新位置'
              : 'Tambah Lokasi Baru',
      addSubtitle: widget.lang == 'EN'
          ? 'Tap to add a new location'
          : widget.lang == 'ZH'
              ? '点击以添加新位置'
              : 'Ketuk untuk menambah lokasi baru',
      data: pageData,
      totalCount: _filtered.length,
      currentPage: safePage,
      totalPages: totalPages,
      onPageChanged: (p) => setState(() => _currentPage = p),
      lang: widget.lang,
      primaryColor: _primary,
      nameFn: (item) => item['nama_lokasi'] ?? '',
      subtitleFn: (item) => '-',
      subtitleWidgetBuilder: (item) => _buildPicSubtitle(item),
      icon: Icons.location_city_rounded,
      imageUrlFn: (item) => item['gambar_lokasi'] as String?,
      onAdd: () => _openAddDialog(),
      onEdit: (item) => _openEditDialog(item),
      onDelete: (item) => _delete(item['id_lokasi'], item['nama_lokasi'] ?? ''),
      onRefresh: _load,
      onTapDetail: (item) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminLocationDetailScreen(
            item: item,
            lang: widget.lang,
            primaryColor: _primary,
            icon: Icons.location_city_rounded,
            nameKey: 'lokasi',
            nameFn: (item) => item['nama_lokasi'] ?? '',
            onEdit: (item) => _openEditDialog(item),
            onDelete: (item) => _delete(item['id_lokasi'], item['nama_lokasi'] ?? ''),
          ),
        ),
      ),
    );
  }
}

Widget _buildLocationTabContent({
  required bool isLoading,
  required String search,
  TextEditingController? searchCtrl,
  required ValueChanged<String> onSearch,
  VoidCallback? onClearSearch,
  required List<Map<String, dynamic>> data,
  required String lang,
  required Color primaryColor,
  required String Function(Map<String, dynamic>) nameFn,
  required String Function(Map<String, dynamic>) subtitleFn,
  Widget Function(Map<String, dynamic>)? subtitleWidgetBuilder,
  IconData? subtitleIcon,
  required IconData icon,
  String? Function(Map<String, dynamic>)? imageUrlFn,
  int? totalCount,
  int currentPage = 1,
  int totalPages = 1,
  ValueChanged<int>? onPageChanged,
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
                  colors: [primaryColor, primaryColor.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.35),
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
                      color: Colors.white.withValues(alpha: 0.25),
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
                              fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
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
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            ),
            child: TextField(
              controller: searchCtrl,
              onChanged: onSearch,
              textAlignVertical: TextAlignVertical.center,
              style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 14),
              decoration: InputDecoration(
                hintText: lang == 'EN' ? 'Search location...' : lang == 'ZH' ? '搜索位置...' : 'Cari lokasi...',
                hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 20),
                suffixIcon: search.isNotEmpty
                    ? GestureDetector(
                        onTap: onClearSearch,
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
                color: primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.list_alt_rounded, size: 13, color: primaryColor),
                  const SizedBox(width: 5),
                  Text(
                    '${totalCount ?? data.length} ${lang == 'EN' ? 'items' : lang == 'ZH' ? '条数据' : 'data'}',
                    style: GoogleFonts.poppins(
                      color: primaryColor,
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
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
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
                                search.isNotEmpty ? Icons.search_off_rounded : Icons.location_city_rounded,
                                size: 80,
                                color: primaryColor.withValues(alpha: 0.35),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              search.isNotEmpty
                                  ? (lang == 'EN'
                                      ? 'No matching locations'
                                      : lang == 'ZH'
                                          ? '未找到匹配位置'
                                          : 'Lokasi Tidak Ditemukan')
                                  : (lang == 'EN'
                                      ? 'No location data found'
                                      : lang == 'ZH'
                                          ? '未找到位置数据'
                                          : 'Data lokasi tidak ditemukan'),
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              search.isNotEmpty
                                  ? (lang == 'EN'
                                      ? 'Try adjusting your search keyword to find what you\'re looking for.'
                                      : lang == 'ZH'
                                          ? '尝试调整搜索关键词以查找您需要的内容。'
                                          : 'Coba ubah kata kunci pencarian untuk menemukan yang Anda cari.')
                                  : (lang == 'EN'
                                      ? 'Locations will show up here as soon as they\'re added.'
                                      : lang == 'ZH'
                                          ? '添加位置后将显示在此处。'
                                          : 'Lokasi akan muncul di sini setelah ditambahkan.'),
                              style: GoogleFonts.poppins(
                                  fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black45, height: 1.5),
                              textAlign: TextAlign.center,
                            ),
                            if (search.isNotEmpty && onClearSearch != null) ...[
                              const SizedBox(height: 18),
                              GestureDetector(
                                onTap: onClearSearch,
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
                                            ? 'Clear search'
                                            : lang == 'ZH'
                                                ? '清除搜索'
                                                : 'Hapus pencarian',
                                        style: GoogleFonts.poppins(
                                            fontSize: 12, fontWeight: FontWeight.w700, color: primaryColor),
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
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
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
                                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
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
                                      color: primaryColor.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: (imageUrlFn != null &&
                                            (imageUrlFn(item) ?? '').isNotEmpty)
                                        ? Image.network(
                                            imageUrlFn(item)!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Icon(icon, color: primaryColor, size: 38),
                                          )
                                        : Icon(icon, color: primaryColor, size: 38),
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
                                        ] else if (subtitleFn(item) != '-') ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (subtitleIcon != null)
                                                Icon(subtitleIcon, size: 12, color: Colors.black45),
                                              if (subtitleIcon != null) const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  subtitleFn(item),
                                                  style: GoogleFonts.poppins(
                                                      color: Colors.black87, fontSize: 11),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
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
              child: AdminLocationPageIndicator(
                currentPage: currentPage,
                totalPages: totalPages,
                onPageChanged: onPageChanged,
                color: primaryColor,
              ),
            ),
          ),
      ],
    ),
  );
}

Future<bool> _showLocationConfirm(BuildContext context, String name, String lang) async {
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
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${lang == 'EN' ? 'Are you sure to delete' : lang == 'ZH' ? '确定要删除' : 'Yakin menghapus'} "$name"?',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 18),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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