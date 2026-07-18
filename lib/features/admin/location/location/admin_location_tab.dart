import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../shared/code/qr_generator_screen.dart';
import '../../../user/finding/finding_pick_pic.dart';
import '../../../user/home/alert/required_field_alert.dart';
import 'camera/admin_location_camera.dart';

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
    AdminLocationCameraWarmupService.instance.release();
    super.dispose();
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

  Future<String> _translateText(String text, String langPair) async {
    if (text.trim().isEmpty) return text;
    try {
      final normalizedPair = langPair
          .replaceAll('|zh', '|zh-CN')
          .replaceAll('zh|', 'zh-CN|');
      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get'
        '?q=${Uri.encodeComponent(text)}&langpair=$normalizedPair',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final translated =
            data['responseData']?['translatedText']?.toString() ?? '';
        if (translated.isEmpty ||
            translated.toUpperCase().startsWith('MYMEMORY WARNING') ||
            translated.toUpperCase().startsWith('PLEASE')) {
          return text;
        }
        return translated;
      }
      return text;
    } catch (_) {
      return text;
    }
  }

  Future<Map<String, String>> _translateDescriptionAllLangs(String sourceText) async {
    if (sourceText.isEmpty) return {'id': '', 'en': '', 'zh': ''};
    switch (widget.lang) {
      case 'EN':
        final results = await Future.wait([
          _translateText(sourceText, 'en|id'),
          _translateText(sourceText, 'en|zh'),
        ]);
        return {'id': results[0], 'en': sourceText, 'zh': results[1]};
      case 'ZH':
        final results = await Future.wait([
          _translateText(sourceText, 'zh|id'),
          _translateText(sourceText, 'zh|en'),
        ]);
        return {'id': results[0], 'en': results[1], 'zh': sourceText};
      default:
        final results = await Future.wait([
          _translateText(sourceText, 'id|en'),
          _translateText(sourceText, 'id|zh'),
        ]);
        return {'id': sourceText, 'en': results[0], 'zh': results[1]};
    }
  }

  String _localizedDesc(Map<String, dynamic> item) {
    switch (widget.lang) {
      case 'EN':
        return (item['deskripsi_lokasi_en'] ?? item['deskripsi_lokasi'] ?? '')
            .toString();
      case 'ZH':
        return (item['deskripsi_lokasi_zh'] ?? item['deskripsi_lokasi'] ?? '')
            .toString();
      default:
        return (item['deskripsi_lokasi'] ?? '').toString();
    }
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

  void _showDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final namaCtrl = TextEditingController(text: item?['nama_lokasi'] ?? '');
    final descCtrl = TextEditingController(text: item != null ? _localizedDesc(item) : '');
    String? gambarUrl = item?['gambar_lokasi'] as String?;
    Uint8List? previewBytes;

    showDialog(
      context: context,
      barrierDismissible: true,
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
              required: true,
            ),
            _LocationFormField(
              label: widget.lang == 'EN' ? 'Description' : widget.lang == 'ZH' ? '描述' : 'Deskripsi',
              controller: descCtrl,
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
          ],
          lang: widget.lang,
          imagePickerWidget: _buildLocationPhotoPicker(
            imageUrl: gambarUrl,
            previewBytes: previewBytes,
            onTap: () async {
              final XFile? picked = await Navigator.push<XFile?>(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminLocationCameraScreen(lang: widget.lang),
                ),
              );
              if (picked == null) return;
              final bytes = await picked.readAsBytes();
              setDlg(() {
                previewBytes = bytes;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                AdminLocationCameraWarmupService.instance.warmUp();
              });
              try {
                final ext = picked.name.split('.').last.toLowerCase();
                final safeExt = ext.isEmpty ? 'jpg' : ext;
                final fileName =
                    '${item?['id_lokasi']?.toString() ?? 'new-lokasi'}-${DateTime.now().millisecondsSinceEpoch}.$safeExt';
                final filePath = 'lokasi/$fileName';
                final String contentType;
                if (safeExt == 'png') {
                  contentType = 'image/png';
                } else if (safeExt == 'gif') {
                  contentType = 'image/gif';
                } else if (safeExt == 'webp') {
                  contentType = 'image/webp';
                } else {
                  contentType = 'image/jpeg';
                }
                await Supabase.instance.client.storage
                    .from('lokasi-images')
                    .uploadBinary(filePath, bytes,
                        fileOptions: FileOptions(contentType: contentType, upsert: true));
                final newUrl = Supabase.instance.client.storage
                    .from('lokasi-images')
                    .getPublicUrl(filePath);
                setDlg(() {
                  gambarUrl = newUrl;
                });
              } catch (e) {
                debugPrint('Error uploading location photo: $e');
              }
            },
          ),
          onSave: () async {
            if (namaCtrl.text.trim().isEmpty) return;

            final descSource = descCtrl.text.trim();

            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => Dialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 42, height: 42,
                          child: CircularProgressIndicator(strokeWidth: 3, color: _primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.lang == 'EN' ? 'Translating...' : widget.lang == 'ZH' ? '翻译中...' : 'Menerjemahkan...',
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E3A8A)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            Map<String, String> descAll = {'id': '', 'en': '', 'zh': ''};
            if (descSource.isNotEmpty) {
              try {
                descAll = await _translateDescriptionAllLangs(descSource);
              } catch (e) {
                debugPrint('Error translating deskripsi lokasi: $e');
                descAll = {'id': descSource, 'en': descSource, 'zh': descSource};
              }
            }

            if (mounted) Navigator.of(context, rootNavigator: true).pop();

            final data = {
              'nama_lokasi': namaCtrl.text.trim(),
              'deskripsi_lokasi': descAll['id']!.isEmpty ? null : descAll['id'],
              'deskripsi_lokasi_en': descAll['en']!.isEmpty ? null : descAll['en'],
              'deskripsi_lokasi_zh': descAll['zh']!.isEmpty ? null : descAll['zh'],
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

  Widget _buildLocationPhotoPicker({
    required String? imageUrl,
    required Uint8List? previewBytes,
    required VoidCallback onTap,
  }) {
    final bool hasPreview = previewBytes != null || (imageUrl != null && imageUrl.isNotEmpty);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 120,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _primary.withValues(alpha: 0.3), width: 1.3),
        ),
        child: hasPreview
            ? Stack(
                fit: StackFit.expand,
                children: [
                  previewBytes != null
                      ? Image.memory(previewBytes, fit: BoxFit.cover)
                      : Image.network(imageUrl!, fit: BoxFit.cover),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: _primary, width: 1.5),
                      ),
                      child: Icon(Icons.camera_alt_rounded, size: 14, color: _primary),
                    ),
                  ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_photo_alternate_rounded, color: _primary, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.lang == 'EN'
                          ? 'Tap to select image'
                          : widget.lang == 'ZH'
                              ? '点击选择图片'
                              : 'Tap untuk pilih gambar',
                      style: GoogleFonts.poppins(
                          color: _primary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.lang == 'EN'
                          ? 'Camera or Gallery'
                          : widget.lang == 'ZH'
                              ? '相机或图库'
                              : 'Kamera atau Galeri',
                      style: GoogleFonts.poppins(color: Colors.black38, fontSize: 11),
                    ),
                  ],
                ),
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
      onAdd: () => _showDialog(),
      onEdit: (item) => _showDialog(item: item),
      onDelete: (item) => _delete(item['id_lokasi'], item['nama_lokasi'] ?? ''),
      onRefresh: _load,
      onTapDetail: (item) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _LocationDetailScreen(
            item: item,
            lang: widget.lang,
            primaryColor: _primary,
            icon: Icons.location_city_rounded,
            nameKey: 'lokasi',
            nameFn: (item) => item['nama_lokasi'] ?? '',
            onEdit: (item) => _showDialog(item: item),
            onDelete: (item) => _delete(item['id_lokasi'], item['nama_lokasi'] ?? ''),
          ),
        ),
      ),
    );
  }
}

class _LocationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final String lang;
  final Color primaryColor;
  final IconData icon;
  final String nameKey;
  final String Function(Map<String, dynamic>) nameFn;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;

  const _LocationDetailScreen({
    required this.item,
    required this.lang,
    required this.primaryColor,
    required this.icon,
    required this.nameKey,
    required this.nameFn,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<_LocationDetailScreen> {
  late Map<String, dynamic> _item;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  String get _localizedDesc {
    switch (widget.lang) {
      case 'EN':
        return (_item['deskripsi_lokasi_en'] ?? _item['deskripsi_lokasi'] ?? '').toString();
      case 'ZH':
        return (_item['deskripsi_lokasi_zh'] ?? _item['deskripsi_lokasi'] ?? '').toString();
      default:
        return (_item['deskripsi_lokasi'] ?? '').toString();
    }
  }

  Future<void> _openQrGenerator() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRGeneratorScreen(
          lang: widget.lang,
          levelName: widget.nameKey,
          levelId: _item['id_${widget.nameKey}'].toString(),
          itemName: widget.nameFn(_item),
        ),
      ),
    );
    if (result == true) {
      setState(() => _isRefreshing = true);
      try {
        final refreshed = await Supabase.instance.client
            .from(widget.nameKey)
            .select('*, User!fk_lokasi_pic(nama, gambar_user, jabatan(nama_jabatan))')
            .eq('id_${widget.nameKey}', _item['id_${widget.nameKey}'].toString())
            .maybeSingle();
        if (refreshed != null && mounted) {
          setState(() => _item = {..._item, ...refreshed});
        }
      } catch (e) {
        debugPrint('Refresh QR error: $e');
      } finally {
        if (mounted) setState(() => _isRefreshing = false);
      }
    }
  }

  Widget _sectionLabel(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 15, color: widget.primaryColor),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: widget.primaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.nameFn(_item);
    final deskripsi = _localizedDesc;
    final isStar = (_item['is_star'] ?? 0) as int;
    final qrcode = _item['qrcode'] as String?;
    final gambarUrl = _item['gambar_lokasi'] as String?;
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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: widget.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.lang == 'EN'
              ? 'Location Detail'
              : widget.lang == 'ZH'
                  ? '位置详情'
                  : 'Detail Lokasi',
          style: GoogleFonts.poppins(
            color: widget.primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: widget.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: (gambarUrl != null && gambarUrl.isNotEmpty)
                            ? Image.network(
                                gambarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Icon(widget.icon, color: widget.primaryColor, size: 28),
                              )
                            : Icon(widget.icon, color: widget.primaryColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
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
                                        ? (widget.lang == 'EN' ? 'Starred' : widget.lang == 'ZH' ? '已加星标' : 'Bintang')
                                        : (widget.lang == 'EN' ? 'No Star' : widget.lang == 'ZH' ? '无星标' : 'Tanpa Bintang'),
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

                  _sectionLabel(
                    Icons.notes_rounded,
                    widget.lang == 'EN' ? 'Description' : widget.lang == 'ZH' ? '描述' : 'Deskripsi',
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: widget.primaryColor.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      deskripsi.isEmpty ? '-' : deskripsi,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1E3A8A),
                        fontSize: 13,
                        height: 1.5,
                      ),
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
                        color: widget.primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: widget.primaryColor.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: widget.primaryColor.withValues(alpha: 0.15),
                            backgroundImage: (picImage != null && picImage.isNotEmpty)
                                ? NetworkImage(picImage)
                                : null,
                            child: (picImage == null || picImage.isEmpty)
                                ? Icon(Icons.person_rounded, color: widget.primaryColor, size: 22)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  picName,
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        widget.lang == 'EN'
                            ? 'No PIC assigned'
                            : widget.lang == 'ZH'
                                ? '未分配负责人'
                                : 'Belum ada PIC',
                        style: GoogleFonts.poppins(color: Colors.black38, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 20),

                  _sectionLabel(Icons.qr_code_2_rounded, 'QR Code'),
                  const SizedBox(height: 10),
                  if (_isRefreshing)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (qrcode != null && qrcode.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: widget.primaryColor.withValues(alpha: 0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: widget.primaryColor.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          QrImageView(data: qrcode, version: QrVersions.auto, size: 220),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _openQrGenerator,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: Text(
                              widget.lang == 'EN' ? 'Regenerate QR' : widget.lang == 'ZH' ? '重新生成二维码' : 'Buat Ulang QR',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: widget.primaryColor,
                              side: BorderSide(color: widget.primaryColor),
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
                            widget.lang == 'EN'
                                ? 'QR Code has not been generated yet.'
                                : widget.lang == 'ZH'
                                    ? '二维码尚未生成。'
                                    : 'Kode QR belum dibuat.',
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black45, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _openQrGenerator,
                            icon: const Icon(Icons.add_circle_outline, size: 18),
                            label: Text(
                              widget.lang == 'EN' ? 'Generate QR Code' : widget.lang == 'ZH' ? '生成二维码' : 'Buat Kode QR',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                              shadowColor: widget.primaryColor.withValues(alpha: 0.3),
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
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  widget.lang == 'EN' ? 'Edit' : widget.lang == 'ZH' ? '编辑' : 'Edit',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
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
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  widget.lang == 'EN' ? 'Delete' : widget.lang == 'ZH' ? '删除' : 'Hapus',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFEF4444),
                                  ),
                                ),
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

Widget _buildLocationTabContent({
  required bool isLoading,
  required String search,
  required ValueChanged<String> onSearch,
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/team_illustration.png',
                              height: 140,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.location_city_rounded,
                                size: 80,
                                color: primaryColor.withValues(alpha: 0.35),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              lang == 'EN'
                                  ? 'No location data found'
                                  : lang == 'ZH'
                                      ? '未找到位置数据'
                                      : 'Data lokasi tidak ditemukan',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
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
              child: _LocationPageIndicator(
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

class _LocationPageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final Color color;

  const _LocationPageIndicator({
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
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
          color: isActive ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: isActive ? null : Border.all(color: color.withValues(alpha: 0.25)),
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
          color: enabled ? color.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08),
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
  final bool required;
  const _LocationFormField({
    required this.label,
    required this.controller,
    required this.icon,
    this.maxLines = 1,
    this.required = false,
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
                        color: color,
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
                      Row(
                        children: [
                          Icon(Icons.camera_alt_rounded, size: 14, color: color),
                          const SizedBox(width: 6),
                          Text(
                            lang == 'EN' ? 'Location Photo' : lang == 'ZH' ? '位置照片' : 'Foto Lokasi',
                            style: GoogleFonts.poppins(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      imagePickerWidget!,
                      const SizedBox(height: 20),
                    ],
                    ...fields.map((f) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(f.icon, size: 14, color: color),
                                const SizedBox(width: 6),
                                Text(
                                  f.label,
                                  style: GoogleFonts.poppins(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                if (f.required) ...[
                                  const SizedBox(width: 3),
                                  Text(
                                    '*',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFFEF4444),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
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
                                  color: Colors.black,
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
                        final missing = fields
                            .where((f) => f.required && f.controller.text.trim().isEmpty)
                            .toList();
                        if (missing.isNotEmpty) {
                          RequiredFieldAlert.show(
                            context,
                            lang: lang,
                            missingFields: missing
                                .map((f) => MissingFieldItem(icon: f.icon, label: f.label))
                                .toList(),
                          );
                          return;
                        }
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