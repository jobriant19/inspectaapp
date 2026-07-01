import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../shared/code/qr_generator_screen.dart';
import '../shared/admin_image_picker_widget.dart';

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
  List<Map<String, dynamic>> _subunitList = [];
  bool _isLoading = true;
  String _search = '';

  String? _filterSubunitId;
  String? _filterSubunitName;
  String _sortOrder = 'none';

  static const _primary = Color(0xFFF472B6);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        Supabase.instance.client
            .from('area')
            .select('id_area, nama_area, deskripsi_area, is_star, gambar_area, kategori, qrcode, id_subunit, id_unit, id_lokasi, id_pic, subunit(nama_subunit), unit(nama_unit), lokasi(nama_lokasi), User!fk_area_pic(nama)')
            .order('nama_area'),
        Supabase.instance.client
            .from('subunit')
            .select('id_subunit, nama_subunit')
            .order('nama_subunit'),
      ]);
      if (mounted) {
        setState(() {
          _data = List<Map<String, dynamic>>.from(results[0] as List);
          _subunitList = List<Map<String, dynamic>>.from(results[1] as List);
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
    if (_filterSubunitId != null) {
      result = result.where((d) => d['id_subunit']?.toString() == _filterSubunitId).toList();
    }
    if (_sortOrder == 'asc') {
      result.sort((a, b) => (a['nama_area'] ?? '').compareTo(b['nama_area'] ?? ''));
    } else if (_sortOrder == 'desc') {
      result.sort((a, b) => (b['nama_area'] ?? '').compareTo(a['nama_area'] ?? ''));
    }
    _filtered = result;
  }

  Widget? _buildActiveChips() {
    final chips = <Widget>[];
    if (_filterSubunitId != null && _filterSubunitName != null) {
      chips.add(_buildFilterChip(
        '📍 $_filterSubunitName',
        _primary,
        () => setState(() { _filterSubunitId = null; _filterSubunitName = null; _applyFilter(); }),
      ));
    }
    if (_sortOrder != 'none') {
      chips.add(_buildFilterChip(
        _sortOrder == 'asc' ? '🔤 A→Z' : '🔤 Z→A',
        _primary,
        () => setState(() { _sortOrder = 'none'; _applyFilter(); }),
      ));
    }
    if (chips.isEmpty) return null;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(spacing: 8, runSpacing: 4, children: chips),
    );
  }

  Widget _buildFilterChip(String label, Color color, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 13, color: color),
          ),
        ],
      ),
    );
  }

  void _showDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final namaCtrl = TextEditingController(text: item?['nama_area'] ?? '');
    final descCtrl = TextEditingController(text: item?['deskripsi_area'] ?? '');
    final kategoriCtrl = TextEditingController(text: item?['kategori'] ?? '');
    String? selectedSubunitId = item?['id_subunit']?.toString();
    String? gambarUrl = item?['gambar_area'] as String?;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => _AdminAreaFormDialog(
          title: isEdit
              ? (widget.lang == 'EN' ? 'Edit Area' : widget.lang == 'ZH' ? '编辑区域' : 'Edit Area')
              : (widget.lang == 'EN' ? 'Add Area' : widget.lang == 'ZH' ? '添加区域' : 'Tambah Area'),
          icon: Icons.place_rounded,
          color: _primary,
          lang: widget.lang,
          fields: [
            _AreaFormField(
              label: widget.lang == 'EN' ? 'Area Name' : widget.lang == 'ZH' ? '区域名称' : 'Nama Area',
              controller: namaCtrl,
              icon: Icons.place_rounded,
            ),
            _AreaFormField(
              label: widget.lang == 'EN' ? 'Description' : widget.lang == 'ZH' ? '描述' : 'Deskripsi',
              controller: descCtrl,
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            _AreaFormField(
              label: widget.lang == 'EN' ? 'Category' : widget.lang == 'ZH' ? '类别' : 'Kategori',
              controller: kategoriCtrl,
              icon: Icons.category_rounded,
            ),
          ],
          imagePickerWidget: AdminImagePickerWidget(
            currentImageUrl: gambarUrl,
            storageBucket: 'lokasi-images',
            storageFolder: 'area',
            filePrefix: item?['id_area']?.toString() ?? 'new-area',
            height: 120,
            isCircle: false,
            accentColor: _primary,
            placeholder: Icon(Icons.place_rounded, color: _primary, size: 28),
            hint: widget.lang == 'EN'
                ? 'Tap to select image'
                : widget.lang == 'ZH'
                    ? '点击选择图片'
                    : 'Tap untuk pilih gambar',
            subHint: widget.lang == 'EN'
                ? 'Camera or Gallery'
                : widget.lang == 'ZH'
                    ? '相机或图库'
                    : 'Kamera atau Galeri',
            uploadingText: widget.lang == 'EN'
                ? 'Uploading...'
                : widget.lang == 'ZH'
                    ? '上传中...'
                    : 'Mengunggah...',
            changeText: widget.lang == 'EN'
                ? 'Change Image'
                : widget.lang == 'ZH'
                    ? '更换图片'
                    : 'Ganti Gambar',
            sourceTitleText: widget.lang == 'EN'
                ? 'Select Image Source'
                : widget.lang == 'ZH'
                    ? '选择图片来源'
                    : 'Pilih Sumber Gambar',
            cameraText: widget.lang == 'EN'
                ? 'Camera'
                : widget.lang == 'ZH'
                    ? '相机'
                    : 'Kamera',
            galleryText: widget.lang == 'EN'
                ? 'Gallery'
                : widget.lang == 'ZH'
                    ? '图库'
                    : 'Galeri',
            onUploaded: (newUrl) => setDlg(() => gambarUrl = newUrl),
          ),
          extraWidget: _buildParentDropdown(
            label: 'Sub-Unit',
            items: _subunitList,
            idKey: 'id_subunit',
            nameKey: 'nama_subunit',
            selectedId: selectedSubunitId,
            onChanged: (v) => setDlg(() => selectedSubunitId = v),
          ),
          onSave: () async {
            if (namaCtrl.text.trim().isEmpty || selectedSubunitId == null) return;
            final data = {
              'nama_area': namaCtrl.text.trim(),
              'deskripsi_area': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
              'kategori': kategoriCtrl.text.trim().isEmpty ? null : kategoriCtrl.text.trim(),
              'gambar_area': gambarUrl,
              'id_subunit': selectedSubunitId,
            };
            if (isEdit) {
              await Supabase.instance.client
                  .from('area').update(data).eq('id_area', item['id_area']);
            } else {
              await Supabase.instance.client.from('area').insert(data);
            }
            _load();
          },
        ),
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
    return Row(
      children: [
        Expanded(
          child: _AreaFilterButton(
            label: 'Sub-Unit',
            icon: Icons.layers_rounded,
            isActive: _filterSubunitId != null,
            activeLabel: _filterSubunitName,
            primaryColor: _primary,
            onTap: () => _showSubunitFilterDialog(),
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

  void _showSubunitFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _buildSimpleFilterDialog(
        ctx: ctx,
        title: widget.lang == 'EN' ? 'Filter by Sub-Unit' : widget.lang == 'ZH' ? '按子单位筛选' : 'Filter Sub-Unit',
        icon: Icons.layers_rounded,
        primaryColor: _primary,
        items: _subunitList,
        idKey: 'id_subunit',
        nameKey: 'nama_subunit',
        selectedId: _filterSubunitId,
        lang: widget.lang,
        onSelect: (id, name) {
          setState(() {
            _filterSubunitId = id;
            _filterSubunitName = name;
            _applyFilter();
          });
          Navigator.pop(ctx);
        },
        onClear: () {
          setState(() {
            _filterSubunitId = null;
            _filterSubunitName = null;
            _applyFilter();
          });
          Navigator.pop(ctx);
        },
      ),
    );
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
      activeChipsWidget: _buildActiveChips(),
      data: _filtered,
      lang: widget.lang,
      primaryColor: _primary,
      nameFn: (item) => item['nama_area'] ?? '',
      subtitleFn: (item) => item['subunit']?['nama_subunit'] ?? '-',
      subtitleIcon: Icons.layers_rounded,
      icon: Icons.place_rounded,
      onAdd: () => _showDialog(),
      onEdit: (item) => _showDialog(item: item),
      onDelete: (item) => _delete(item['id_area'], item['nama_area'] ?? ''),
      onRefresh: _load,
      filterWidget: _buildFilterRow(),
      onTapDetail: (item) => _showAreaDetailSheet(
        context: context,
        item: item,
        lang: widget.lang,
        primaryColor: _primary,
        icon: Icons.place_rounded,
        nameKey: 'area',
        nameFn: (item) => item['nama_area'] ?? '',
        subtitleFn: (item) => item['subunit']?['nama_subunit'] ?? '-',
        onEdit: (item) => _showDialog(item: item),
        onDelete: (item) => _delete(item['id_area'], item['nama_area'] ?? ''),
      ),
    );
  }
}

void _showAreaDetailSheet({
  required BuildContext context,
  required Map<String, dynamic> item,
  required String lang,
  required Color primaryColor,
  required IconData icon,
  required String nameKey,
  required String Function(Map<String, dynamic>) nameFn,
  required String Function(Map<String, dynamic>) subtitleFn,
  required void Function(Map<String, dynamic>) onEdit,
  required void Function(Map<String, dynamic>) onDelete,
}) {
  final name = nameFn(item);
  final subtitle = subtitleFn(item);
  final deskripsi = (item['deskripsi_area'] ?? '') as String;
  final isStar = (item['is_star'] ?? 0) as int;
  final kategori = item['kategori'] as String?;
  final qrcode = item['qrcode'] as String?;
  final picName = item['User']?['nama'] as String?;

  final List<Map<String, dynamic>> infoRows = [];

  if (item['unit']?['nama_unit'] != null) {
    infoRows.add({
      'icon': Icons.business_rounded,
      'label': lang == 'EN' ? 'Unit' : lang == 'ZH' ? '单位' : 'Unit',
      'value': item['unit']['nama_unit'],
      'color': const Color(0xFF6366F1),
    });
  }
  if (item['subunit']?['nama_subunit'] != null) {
    infoRows.add({
      'icon': Icons.layers_rounded,
      'label': lang == 'EN' ? 'Sub-Unit' : lang == 'ZH' ? '子单位' : 'Sub-Unit',
      'value': item['subunit']['nama_subunit'],
      'color': const Color(0xFFFBBF24),
    });
  }
  if (kategori != null && kategori.isNotEmpty) {
    infoRows.add({
      'icon': Icons.category_rounded,
      'label': lang == 'EN' ? 'Category' : lang == 'ZH' ? '类别' : 'Kategori',
      'value': kategori,
      'color': const Color(0xFF8B5CF6),
    });
  }
  if (picName != null && picName.isNotEmpty) {
    infoRows.add({
      'icon': Icons.person_outline_rounded,
      'label': lang == 'EN' ? 'PIC' : lang == 'ZH' ? '负责人' : 'PIC',
      'value': picName,
      'color': const Color(0xFF0891B2),
    });
  }

  const editBlue = Color(0xFF2563EB);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha:0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: primaryColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF1E3A8A),
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            if (subtitle.isNotEmpty && subtitle != '-') ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: GoogleFonts.poppins(
                                  color: Colors.black45,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isStar > 0 ? const Color(0xFFFEF3C7) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isStar > 0 ? const Color(0xFFFBBF24) : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isStar > 0 ? Icons.star_rounded : Icons.star_border_rounded,
                                    size: 12,
                                    color: isStar > 0 ? const Color(0xFFFBBF24) : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isStar > 0
                                        ? (lang == 'EN' ? 'Starred' : lang == 'ZH' ? '已加星标' : 'Bintang')
                                        : (lang == 'EN' ? 'No Star' : lang == 'ZH' ? '无星标' : 'Tanpa Bintang'),
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isStar > 0 ? const Color(0xFFF59E0B) : Colors.grey,
                                    ),
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

                  if (deskripsi.isNotEmpty) ...[
                    _areaDetailSection(
                      lang == 'EN' ? 'Description' : lang == 'ZH' ? '描述' : 'Deskripsi',
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha:0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryColor.withValues(alpha:0.15)),
                      ),
                      child: Text(
                        deskripsi,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1E3A8A),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (infoRows.isNotEmpty) ...[
                    _areaDetailSection(
                      lang == 'EN' ? 'Information' : lang == 'ZH' ? '信息' : 'Informasi',
                    ),
                    const SizedBox(height: 10),
                    ...infoRows.map((row) => _areaDetailRow(
                          icon: row['icon'] as IconData,
                          label: row['label'] as String,
                          value: row['value'] as String,
                          color: row['color'] as Color,
                        )),
                  ],

                  const SizedBox(height: 20),

                  _areaDetailSection('QR Code'),
                  const SizedBox(height: 10),

                  if (qrcode != null && qrcode.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryColor.withValues(alpha:0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha:0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          QrImageView(
                            data: qrcode,
                            version: QrVersions.auto,
                            size: 220,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QRGeneratorScreen(
                                    lang: lang,
                                    levelName: nameKey,
                                    levelId: item['id_$nameKey'].toString(),
                                    itemName: nameFn(item),
                                  ),
                                ),
                              );
                              if (result == true) {
                                try {
                                  final refreshed = await Supabase.instance.client
                                      .from(nameKey)
                                      .select('*, User!fk_${nameKey}_pic(nama)')
                                      .eq('id_$nameKey', item['id_$nameKey'].toString())
                                      .maybeSingle();
                                  if (refreshed != null && context.mounted) {
                                    item.addAll(refreshed);
                                    _showAreaDetailSheet(
                                      context: context,
                                      item: item,
                                      lang: lang,
                                      primaryColor: primaryColor,
                                      icon: icon,
                                      nameKey: nameKey,
                                      nameFn: nameFn,
                                      subtitleFn: subtitleFn,
                                      onEdit: onEdit,
                                      onDelete: onDelete,
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('Refresh QR error: $e');
                                }
                              }
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: Text(
                              lang == 'EN' ? 'Regenerate QR' : lang == 'ZH' ? '重新生成二维码' : 'Buat Ulang QR',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryColor,
                              side: BorderSide(color: primaryColor),
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
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.qr_code_scanner_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            lang == 'EN'
                                ? 'QR Code has not been generated yet.'
                                : lang == 'ZH'
                                    ? '二维码尚未生成。'
                                    : 'Kode QR belum dibuat.',
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: Colors.black45, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QRGeneratorScreen(
                                    lang: lang,
                                    levelName: nameKey,
                                    levelId: item['id_$nameKey'].toString(),
                                    itemName: nameFn(item),
                                  ),
                                ),
                              );
                              if (result == true) {
                                try {
                                  final refreshed = await Supabase.instance.client
                                      .from(nameKey)
                                      .select('*, User!fk_${nameKey}_pic(nama)')
                                      .eq('id_$nameKey', item['id_$nameKey'].toString())
                                      .maybeSingle();
                                  if (refreshed != null && context.mounted) {
                                    item.addAll(refreshed);
                                    _showAreaDetailSheet(
                                      context: context,
                                      item: item,
                                      lang: lang,
                                      primaryColor: primaryColor,
                                      icon: icon,
                                      nameKey: nameKey,
                                      nameFn: nameFn,
                                      subtitleFn: subtitleFn,
                                      onEdit: onEdit,
                                      onDelete: onDelete,
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('Refresh QR error: $e');
                                }
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline, size: 18),
                            label: Text(
                              lang == 'EN' ? 'Generate QR Code' : lang == 'ZH' ? '生成二维码' : 'Buat Kode QR',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                              shadowColor: primaryColor.withValues(alpha:0.3),
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
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onEdit(item);
                          },
                          icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                          label: Text(
                            lang == 'EN' ? 'Edit' : lang == 'ZH' ? '编辑' : 'Edit',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: editBlue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onDelete(item);
                          },
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.white),
                          label: Text(
                            lang == 'EN' ? 'Delete' : lang == 'ZH' ? '删除' : 'Hapus',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _areaDetailSection(String title) {
  return Row(
    children: [
      Container(
        width: 3,
        height: 16,
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: GoogleFonts.poppins(
          color: const Color(0xFF1E3A8A),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

Widget _areaDetailRow({
  required IconData icon,
  required String label,
  required String value,
  required Color color,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: color.withValues(alpha:0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha:0.15)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.black45,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1E3A8A),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildAreaTabContent({
  required bool isLoading,
  required String search,
  required ValueChanged<String> onSearch,
  required List<Map<String, dynamic>> data,
  required String lang,
  required Color primaryColor,
  required String Function(Map<String, dynamic>) nameFn,
  required String Function(Map<String, dynamic>) subtitleFn,
  IconData? subtitleIcon,
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
                              fontSize: 10, color: Colors.white.withValues(alpha:0.85)),
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
              style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 14),
              decoration: InputDecoration(
                hintText: lang == 'EN' ? 'Search...' : lang == 'ZH' ? '搜索...' : 'Cari...',
                hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 20),
                border: InputBorder.none,
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
            child: Text(
              '${data.length} ${lang == 'EN' ? 'items' : lang == 'ZH' ? '条数据' : 'data'}',
              style: GoogleFonts.poppins(color: Colors.black38, fontSize: 12),
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
                      child: Text(
                        lang == 'EN'
                            ? 'No data found'
                            : lang == 'ZH'
                                ? '未找到数据'
                                : 'Tidak ada data',
                        style: GoogleFonts.poppins(color: Colors.black38),
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
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha:0.10),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(icon, color: primaryColor, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nameFn(item),
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF1E3A8A),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (subtitleFn(item) != '-') ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (subtitleIcon != null)
                                                Icon(subtitleIcon, size: 12, color: Colors.black38),
                                              if (subtitleIcon != null) const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  subtitleFn(item),
                                                  style: GoogleFonts.poppins(
                                                      color: Colors.black38, fontSize: 11),
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
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB).withValues(alpha:0.10),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.edit_outlined,
                                          color: Color(0xFF2563EB), size: 16),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => onDelete(item),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withValues(alpha:0.10),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.delete_outline_rounded,
                                          color: Color(0xFFEF4444), size: 16),
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

Widget _buildParentDropdown({
  required String label,
  required List<Map<String, dynamic>> items,
  required String idKey,
  required String nameKey,
  required String? selectedId,
  required ValueChanged<String?> onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.black54,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedId,
            isExpanded: true,
            dropdownColor: Colors.white,
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.black45),
            hint: Text(
              'Select $label',
              style: GoogleFonts.poppins(
                  color: Colors.black38, fontSize: 13),
            ),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item[idKey]?.toString(),
                child: Text(
                  item[nameKey] ?? '-',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1E3A8A),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ],
  );
}

class _AreaFormField {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final int maxLines;
  const _AreaFormField({
    required this.label,
    required this.controller,
    required this.icon,
    this.maxLines = 1,
  });
}

class _AdminAreaFormDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_AreaFormField> fields;
  final Widget? extraWidget;
  final Widget? imagePickerWidget;
  final String lang;
  final Future<void> Function() onSave;

  const _AdminAreaFormDialog({
    required this.title,
    required this.icon,
    required this.color,
    required this.fields,
    required this.lang,
    required this.onSave,
    this.extraWidget,
    this.imagePickerWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha:0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1E3A8A),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imagePickerWidget != null) ...[
                      Text(
                        lang == 'EN' ? 'Photo' : lang == 'ZH' ? '图片' : 'Foto',
                        style: GoogleFonts.poppins(
                          color: Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      imagePickerWidget!,
                      const SizedBox(height: 20),
                    ],
                    ...fields.map((f) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.label,
                              style: GoogleFonts.poppins(
                                color: Colors.black54,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: TextField(
                                controller: f.controller,
                                maxLines: f.maxLines,
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF1E3A8A),
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: f.label,
                                  hintStyle: GoogleFonts.poppins(
                                      color: Colors.black26, fontSize: 13),
                                  prefixIcon: f.maxLines == 1
                                      ? Icon(f.icon, color: Colors.black38, size: 18)
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                        )),
                    if (extraWidget != null) ...[
                      extraWidget!,
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.05),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        lang == 'EN' ? 'Cancel' : lang == 'ZH' ? '取消' : 'Batal',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await onSave();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        shadowColor: color.withValues(alpha:0.3),
                      ),
                      child: Text(
                        lang == 'EN' ? 'Save' : lang == 'ZH' ? '保存' : 'Simpan',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaFilterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final String? activeLabel;
  final Color primaryColor;
  final VoidCallback onTap;

  const _AreaFilterButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.primaryColor,
    required this.onTap,
    this.activeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? primaryColor : Colors.grey.shade200,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha:0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: isActive ? Colors.white : primaryColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                isActive && activeLabel != null ? activeLabel! : label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : primaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 13, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _buildSimpleFilterDialog({
  required BuildContext ctx,
  required String title,
  required IconData icon,
  required Color primaryColor,
  required List<Map<String, dynamic>> items,
  required String idKey,
  required String nameKey,
  required String? selectedId,
  required String lang,
  required void Function(String id, String name) onSelect,
  required VoidCallback onClear,
}) {
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
            color: primaryColor.withValues(alpha:0.04),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            children: [
              Icon(icon, color: primaryColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
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
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: onClear,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: selectedId == null
                          ? primaryColor.withValues(alpha:0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedId == null ? primaryColor : Colors.grey.shade200,
                        width: selectedId == null ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            lang == 'EN' ? 'All (No Filter)' : lang == 'ZH' ? '全部' : 'Semua (Tanpa Filter)',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: selectedId == null ? FontWeight.w600 : FontWeight.w400,
                              color: selectedId == null ? primaryColor : const Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                        if (selectedId == null)
                          Icon(Icons.check_circle_rounded, color: primaryColor, size: 18),
                      ],
                    ),
                  ),
                ),
                ...items.map((item) {
                  final id = item[idKey]?.toString() ?? '';
                  final name = item[nameKey]?.toString() ?? '';
                  final isSelected = selectedId == id;
                  return GestureDetector(
                    onTap: () => onSelect(id, name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor.withValues(alpha:0.08) : Colors.white,
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
                              name,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected ? primaryColor : const Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded, color: primaryColor, size: 18),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    ),
  );
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
            color: primaryColor.withValues(alpha:0.04),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            children: [
              Icon(Icons.sort_by_alpha_rounded, color: primaryColor, size: 20),
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
                    color: isSelected ? primaryColor.withValues(alpha:0.08) : Colors.white,
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
                            color: isSelected ? primaryColor : const Color(0xFF1E3A8A),
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded, color: primaryColor, size: 18),
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