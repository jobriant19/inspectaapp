import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../shared/code/qr_generator_screen.dart';
import '../shared/admin_image_picker_widget.dart';

class AdminLocationTab extends StatefulWidget {
  final String lang;
  const AdminLocationTab({super.key, required this.lang});

  @override
  State<AdminLocationTab> createState() => _AdminLocationTabState();
}

class _AdminLocationTabState extends State<AdminLocationTab>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _data = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _search = '';

  static const _primary = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('lokasi')
          .select(
              'id_lokasi, nama_lokasi, deskripsi_lokasi, is_star, gambar_lokasi, kategori, qrcode, id_pic, User!fk_lokasi_pic(nama)')
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
  }

  void _showDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final namaCtrl = TextEditingController(text: item?['nama_lokasi'] ?? '');
    final descCtrl = TextEditingController(text: item?['deskripsi_lokasi'] ?? '');
    final kategoriCtrl = TextEditingController(text: item?['kategori'] ?? '');
    String? gambarUrl = item?['gambar_lokasi'] as String?;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => _AdminLocationFormDialog(
          title: isEdit
              ? (widget.lang == 'EN' ? 'Edit Location' : widget.lang == 'ZH' ? '编辑位置' : 'Edit Lokasi')
              : (widget.lang == 'EN' ? 'Add Location' : widget.lang == 'ZH' ? '添加位置' : 'Tambah Lokasi'),
          icon: Icons.location_city_rounded,
          color: _primary,
          fields: [
            _LocationFormField(
              label: widget.lang == 'EN' ? 'Location Name' : widget.lang == 'ZH' ? '位置名称' : 'Nama Lokasi',
              controller: namaCtrl,
              icon: Icons.location_city_rounded,
            ),
            _LocationFormField(
              label: widget.lang == 'EN' ? 'Description' : widget.lang == 'ZH' ? '描述' : 'Deskripsi',
              controller: descCtrl,
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            _LocationFormField(
              label: widget.lang == 'EN' ? 'Category' : widget.lang == 'ZH' ? '类别' : 'Kategori',
              controller: kategoriCtrl,
              icon: Icons.category_rounded,
            ),
          ],
          lang: widget.lang,
          imagePickerWidget: AdminImagePickerWidget(
            currentImageUrl: gambarUrl,
            storageBucket: 'lokasi-images',
            storageFolder: 'lokasi',
            filePrefix: item?['id_lokasi']?.toString() ?? 'new-lokasi',
            height: 120,
            isCircle: false,
            accentColor: _primary,
            placeholder: Icon(Icons.location_city_rounded, color: _primary, size: 28),
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
          onSave: () async {
            if (namaCtrl.text.trim().isEmpty) return;
            final data = {
              'nama_lokasi': namaCtrl.text.trim(),
              'deskripsi_lokasi': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
              'kategori': kategoriCtrl.text.trim().isEmpty ? null : kategoriCtrl.text.trim(),
              'gambar_lokasi': gambarUrl,
            };
            if (isEdit) {
              await Supabase.instance.client
                  .from('lokasi').update(data).eq('id_lokasi', item['id_lokasi']);
            } else {
              await Supabase.instance.client.from('lokasi').insert(data);
            }
            _load();
          },
        ),
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
    return _buildLocationTabContent(
      isLoading: _isLoading,
      search: _search,
      onSearch: (v) => setState(() {
        _search = v;
        _applyFilter();
      }),
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
      data: _filtered,
      lang: widget.lang,
      primaryColor: _primary,
      nameFn: (item) => item['nama_lokasi'] ?? '',
      subtitleFn: (item) => item['deskripsi_lokasi'] ?? '-',
      icon: Icons.location_city_rounded,
      onAdd: () => _showDialog(),
      onEdit: (item) => _showDialog(item: item),
      onDelete: (item) => _delete(item['id_lokasi'], item['nama_lokasi'] ?? ''),
      onRefresh: _load,
      onTapDetail: (item) => _showLocationDetailSheet(
        context: context,
        item: item,
        lang: widget.lang,
        primaryColor: _primary,
        icon: Icons.location_city_rounded,
        nameKey: 'lokasi',
        nameFn: (item) => item['nama_lokasi'] ?? '',
        subtitleFn: (item) => item['deskripsi_lokasi'] ?? '-',
        onEdit: (item) => _showDialog(item: item),
        onDelete: (item) => _delete(item['id_lokasi'], item['nama_lokasi'] ?? ''),
      ),
    );
  }
}

void _showLocationDetailSheet({
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
  final deskripsi = (item['deskripsi_lokasi'] ?? '') as String;
  final isStar = (item['is_star'] ?? 0) as int;
  final kategori = item['kategori'] as String?;
  final qrcode = item['qrcode'] as String?;
  final picName = item['User']?['nama'] as String?;

  final List<Map<String, dynamic>> infoRows = [];

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
                          color: primaryColor.withValues(alpha: 0.12),
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
                                style: GoogleFonts.poppins(color: Colors.black45, fontSize: 12),
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
                    _locDetailSection(
                      lang == 'EN' ? 'Description' : lang == 'ZH' ? '描述' : 'Deskripsi',
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
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
                    _locDetailSection(
                      lang == 'EN' ? 'Information' : lang == 'ZH' ? '信息' : 'Informasi',
                    ),
                    const SizedBox(height: 10),
                    ...infoRows.map((row) => _locDetailRow(
                          icon: row['icon'] as IconData,
                          label: row['label'] as String,
                          value: row['value'] as String,
                          color: row['color'] as Color,
                        )),
                  ],
                  const SizedBox(height: 20),
                  _locDetailSection('QR Code'),
                  const SizedBox(height: 10),
                  if (qrcode != null && qrcode.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.08),
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
                                    _showLocationDetailSheet(
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
                                    _showLocationDetailSheet(
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
                              shadowColor: primaryColor.withValues(alpha: 0.3),
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

Widget _locDetailSection(String title) {
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

Widget _locDetailRow({
  required IconData icon,
  required String label,
  required String value,
  required Color color,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.15)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
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

Widget _buildLocationTabContent({
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
                              fontSize: 10, color: Colors.white.withValues(alpha: 0.85)),
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
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.10),
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
                                        color: const Color(0xFF2563EB).withValues(alpha: 0.10),
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
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.10),
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

class _LocationFormField {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final int maxLines;
  const _LocationFormField({
    required this.label,
    required this.controller,
    required this.icon,
    this.maxLines = 1,
  });
}

class _AdminLocationFormDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_LocationFormField> fields;
  final Widget? extraWidget;
  final Widget? imagePickerWidget;
  final String lang;
  final Future<void> Function() onSave;

  const _AdminLocationFormDialog({
    required this.title,
    required this.icon,
    required this.color,
    required this.fields,
    required this.lang,
    required this.onSave,
    // ignore: unused_element_parameter
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
                    color: Colors.black.withValues(alpha: 0.04),
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
                      color: color.withValues(alpha: 0.12),
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
                                  hintStyle: GoogleFonts.poppins(color: Colors.black26, fontSize: 13),
                                  prefixIcon: f.maxLines == 1
                                      ? Icon(f.icon, color: Colors.black38, size: 18)
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                    color: Colors.black.withValues(alpha: 0.05),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        shadowColor: color.withValues(alpha: 0.3),
                      ),
                      child: Text(
                        lang == 'EN' ? 'Save' : lang == 'ZH' ? '保存' : 'Simpan',
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
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