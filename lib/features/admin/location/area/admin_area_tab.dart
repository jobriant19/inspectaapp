import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/services/translation_service.dart';
import '../../../shared/code/qr_generator_screen.dart';
import '../../../user/finding/finding_pick_pic.dart';
import '../../../user/home/alert/required_field_alert.dart';
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

  // Filter lokasi bisa berasal dari salah satu level: Lokasi / Unit / Sub-Unit.
  // Area menyimpan ketiga kolom (id_lokasi, id_unit, id_subunit) secara
  // langsung, jadi filter cukup mencocokkan kolom yang sesuai tanpa resolve.
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
              'id_area, nama_area, deskripsi_area, deskripsi_area_en, deskripsi_area_zh, is_star, gambar_area, kategori, qrcode, id_subunit, id_unit, id_lokasi, id_pic, subunit(nama_subunit), unit(nama_unit), lokasi(nama_lokasi), User!fk_area_pic(nama, gambar_user, id_jabatan, is_verificator, jabatan(nama_jabatan))')
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

  String _localizedDesc(Map<String, dynamic> item) {
    switch (widget.lang) {
      case 'EN':
        return (item['deskripsi_area_en'] ?? item['deskripsi_area'] ?? '').toString();
      case 'ZH':
        return (item['deskripsi_area_zh'] ?? item['deskripsi_area'] ?? '').toString();
      default:
        return (item['deskripsi_area'] ?? '').toString();
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

  void _showDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final namaCtrl = TextEditingController(text: item?['nama_area'] ?? '');
    final descCtrl = TextEditingController(text: item != null ? _localizedDesc(item) : '');
    final kategoriCtrl = TextEditingController(text: item?['kategori'] ?? '');
    String? selectedSubunitId = item?['id_subunit']?.toString();
    String? selectedSubunitName = item?['subunit']?['nama_subunit'] as String?;
    // id_unit & id_lokasi ikut disimpan otomatis mengikuti Sub-Unit yang
    // dipilih, supaya filter berdasarkan Unit/Lokasi tetap berfungsi.
    String? derivedUnitId = item?['id_unit']?.toString();
    String? derivedLokasiId = item?['id_lokasi']?.toString();
    String? gambarUrl = item?['gambar_area'] as String?;
    Uint8List? previewBytes;

    showDialog(
      context: context,
      barrierDismissible: true,
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
              required: true,
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
          imagePickerWidget: _buildAreaPhotoPicker(
            imageUrl: gambarUrl,
            previewBytes: previewBytes,
            onTap: () async {
              final XFile? picked = await Navigator.push<XFile?>(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminAreaCameraScreen(lang: widget.lang),
                ),
              );
              if (picked == null) return;
              final bytes = await picked.readAsBytes();
              setDlg(() {
                previewBytes = bytes;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                AdminAreaCameraWarmupService.instance.warmUp();
              });
              try {
                final ext = picked.name.split('.').last.toLowerCase();
                final safeExt = ext.isEmpty ? 'jpg' : ext;
                final fileName =
                    '${item?['id_area']?.toString() ?? 'new-area'}-${DateTime.now().millisecondsSinceEpoch}.$safeExt';
                final filePath = 'area/$fileName';
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
                debugPrint('Error uploading area photo: $e');
              }
            },
          ),
          extraWidget: _buildSubunitPickerField(
            label: 'Sub-Unit',
            selectedName: selectedSubunitName,
            lang: widget.lang,
            onTap: () {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (ctx) => _AreaSubunitPickerDialog(
                  selectedId: selectedSubunitId,
                  lang: widget.lang,
                  onSelect: (id, name, unitId, lokasiId) {
                    setDlg(() {
                      selectedSubunitId = id;
                      selectedSubunitName = name;
                      derivedUnitId = unitId;
                      derivedLokasiId = lokasiId;
                    });
                  },
                ),
              );
            },
          ),
          onSave: () async {
            if (namaCtrl.text.trim().isEmpty || selectedSubunitId == null) return;

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
                descAll = await TranslationHelper.instance
                    .translateDescriptionAllLangs(descSource, widget.lang);
              } catch (e) {
                debugPrint('Error translating deskripsi area: $e');
                descAll = {'id': descSource, 'en': descSource, 'zh': descSource};
              }
            }

            if (mounted) Navigator.of(context, rootNavigator: true).pop();

            final data = {
              'nama_area': namaCtrl.text.trim(),
              'deskripsi_area': descAll['id']!.isEmpty ? null : descAll['id'],
              'deskripsi_area_en': descAll['en']!.isEmpty ? null : descAll['en'],
              'deskripsi_area_zh': descAll['zh']!.isEmpty ? null : descAll['zh'],
              'kategori': kategoriCtrl.text.trim().isEmpty ? null : kategoriCtrl.text.trim(),
              'gambar_area': gambarUrl,
              'id_subunit': selectedSubunitId,
              'id_unit': derivedUnitId,
              'id_lokasi': derivedLokasiId,
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

  Widget _buildAreaPhotoPicker({
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
          color: _primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _primary.withValues(alpha: 0.4), width: 1.3),
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
                      child: const Icon(Icons.camera_alt_rounded, size: 14, color: Color(0xFFBE185D)),
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
                        color: _primary.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFFBE185D), size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.lang == 'EN'
                          ? 'Tap to select image'
                          : widget.lang == 'ZH'
                              ? '点击选择图片'
                              : 'Tap untuk pilih gambar',
                      style: GoogleFonts.poppins(
                          color: const Color(0xFFBE185D), fontSize: 13, fontWeight: FontWeight.w600),
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
      onAdd: () => _showDialog(),
      onEdit: (item) => _showDialog(item: item),
      onDelete: (item) => _delete(item['id_area'], item['nama_area'] ?? ''),
      onRefresh: _load,
      filterWidget: _buildFilterRow(),
      onTapDetail: (item) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _AreaDetailScreen(
            item: item,
            lang: widget.lang,
            primaryColor: _primary,
            unitColor: _unitColor,
            subunitColor: _subunitColor,
            icon: Icons.place_rounded,
            nameFn: (item) => item['nama_area'] ?? '',
            onEdit: (item) => _showDialog(item: item),
            onDelete: (item) => _delete(item['id_area'], item['nama_area'] ?? ''),
          ),
        ),
      ),
    );
  }
}

class _AreaDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final String lang;
  final Color primaryColor;
  final Color unitColor;
  final Color subunitColor;
  final IconData icon;
  final String Function(Map<String, dynamic>) nameFn;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;

  const _AreaDetailScreen({
    required this.item,
    required this.lang,
    required this.primaryColor,
    required this.unitColor,
    required this.subunitColor,
    required this.icon,
    required this.nameFn,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_AreaDetailScreen> createState() => _AreaDetailScreenState();
}

class _AreaDetailScreenState extends State<_AreaDetailScreen> {
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
        return (_item['deskripsi_area_en'] ?? _item['deskripsi_area'] ?? '').toString();
      case 'ZH':
        return (_item['deskripsi_area_zh'] ?? _item['deskripsi_area'] ?? '').toString();
      default:
        return (_item['deskripsi_area'] ?? '').toString();
    }
  }

  Future<void> _openQrGenerator() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRGeneratorScreen(
          lang: widget.lang,
          levelName: 'area',
          levelId: _item['id_area'].toString(),
          itemName: widget.nameFn(_item),
        ),
      ),
    );
    if (result == true) {
      setState(() => _isRefreshing = true);
      try {
        final refreshed = await Supabase.instance.client
            .from('area')
            .select('*, subunit(nama_subunit), unit(nama_unit), lokasi(nama_lokasi), User!fk_area_pic(nama, gambar_user, id_jabatan, is_verificator, jabatan(nama_jabatan))')
            .eq('id_area', _item['id_area'].toString())
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

  Widget _breadcrumbPill({required IconData icon, required Color color, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    final name = widget.nameFn(_item);
    final deskripsi = _localizedDesc;
    final kategori = _item['kategori'] as String?;
    final isStar = (_item['is_star'] ?? 0) as int;
    final qrcode = _item['qrcode'] as String?;
    final gambarUrl = _item['gambar_area'] as String?;
    final subunitName = _item['subunit']?['nama_subunit'] as String?;
    final unitName = _item['unit']?['nama_unit'] as String?;
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
              ? 'Area Detail'
              : widget.lang == 'ZH'
                  ? '区域详情'
                  : 'Detail Area',
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
                    color: widget.primaryColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: (gambarUrl != null && gambarUrl.isNotEmpty)
                      ? Image.network(
                          gambarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(widget.icon, color: const Color(0xFFBE185D), size: 28),
                        )
                      : Icon(widget.icon, color: const Color(0xFFBE185D), size: 28),
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
                      if (subunitName != null && subunitName.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _breadcrumbPill(
                              icon: Icons.layers_rounded,
                              color: widget.subunitColor,
                              label: subunitName,
                            ),
                            if (unitName != null && unitName.isNotEmpty)
                              _breadcrumbPill(
                                icon: Icons.business_rounded,
                                color: widget.unitColor,
                                label: unitName,
                              ),
                          ],
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

            if (kategori != null && kategori.isNotEmpty) ...[
              _sectionLabel(
                Icons.category_rounded,
                widget.lang == 'EN' ? 'Category' : widget.lang == 'ZH' ? '类别' : 'Kategori',
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.25)),
                ),
                child: Text(
                  kategori,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF6D28D9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            _sectionLabel(
              Icons.notes_rounded,
              widget.lang == 'EN' ? 'Description' : widget.lang == 'ZH' ? '描述' : 'Deskripsi',
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.primaryColor.withValues(alpha: 0.25)),
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
                  color: widget.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.primaryColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: widget.primaryColor.withValues(alpha: 0.20),
                      backgroundImage: (picImage != null && picImage.isNotEmpty)
                          ? NetworkImage(picImage)
                          : null,
                      child: (picImage == null || picImage.isEmpty)
                          ? const Icon(Icons.person_rounded, color: Color(0xFFBE185D), size: 22)
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
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_off_rounded, size: 16, color: Color(0xFFF59E0B)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.lang == 'EN'
                            ? 'No PIC assigned yet'
                            : widget.lang == 'ZH'
                                ? '尚未分配负责人'
                                : 'Belum ada PIC yang ditugaskan',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFB45309),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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
                  border: Border.all(color: widget.primaryColor.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: widget.primaryColor.withValues(alpha: 0.10),
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
                        foregroundColor: const Color(0xFFBE185D),
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
  // Jarak bawah list disesuaikan: lebih kecil saat tidak ada page indicator,
  // sedikit lebih besar saat ada, supaya item terakhir tetap terlihat jelas
  // tanpa jarak kosong yang berlebihan.
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
              child: _AreaPageIndicator(
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

class _AreaPageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final Color color;

  const _AreaPageIndicator({
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
            color: isActive ? Colors.white : const Color(0xFFBE185D),
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
          color: enabled ? const Color(0xFFBE185D) : Colors.grey.shade400,
        ),
      ),
    );
  }
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

Widget _buildSubunitPickerField({
  required String label,
  required String? selectedName,
  required String lang,
  required VoidCallback onTap,
}) {
  const amber = Color(0xFFFBBF24);
  const amberText = Color(0xFFB45309);
  final hasValue = selectedName != null && selectedName.isNotEmpty;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.layers_rounded, size: 14, color: amberText),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: amberText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 3),
          Text('*',
              style: GoogleFonts.poppins(
                  color: const Color(0xFFEF4444),
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ],
      ),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.layers_rounded,
                  size: 16, color: hasValue ? amber : Colors.black26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasValue
                      ? selectedName
                      : (lang == 'EN'
                          ? 'Select Sub-Unit'
                          : lang == 'ZH'
                              ? '选择子单位'
                              : 'Pilih Sub-Unit'),
                  style: GoogleFonts.poppins(
                    color: hasValue ? const Color(0xFF1E3A8A) : Colors.black38,
                    fontSize: 13,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black45),
            ],
          ),
        ),
      ),
    ],
  );
}

class _AreaSubunitPickerDialog extends StatefulWidget {
  final String? selectedId;
  final String lang;
  final void Function(String? id, String? name, String? unitId, String? lokasiId) onSelect;

  const _AreaSubunitPickerDialog({
    required this.selectedId,
    required this.lang,
    required this.onSelect,
  });

  @override
  State<_AreaSubunitPickerDialog> createState() => _AreaSubunitPickerDialogState();
}

class _AreaSubunitPickerDialogState extends State<_AreaSubunitPickerDialog> {
  static const _amber = Color(0xFFFBBF24);
  static const _amberText = Color(0xFFB45309);

  List<Map<String, dynamic>>? _data;
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

  String get _lang => widget.lang;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_applyFilter);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyFilter);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await Supabase.instance.client
          .from('subunit')
          .select('id_subunit, nama_subunit, id_unit, id_lokasi')
          .order('nama_subunit');
      if (mounted) {
        final list = List<Map<String, dynamic>>.from(res);
        setState(() {
          _data = list;
          _filtered = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading subunit picker: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    final data = _data ?? [];
    if (q.isEmpty) {
      setState(() => _filtered = List.from(data));
      return;
    }
    setState(() {
      _filtered = data
          .where((item) => (item['nama_subunit'] ?? '').toString().toLowerCase().contains(q))
          .toList();
    });
  }

  String _t(String id, String en, String zh) => _lang == 'EN' ? en : _lang == 'ZH' ? zh : id;

  Widget _buildSubunitCard(Map<String, dynamic> item) {
    final id = item['id_subunit']?.toString() ?? '';
    final name = item['nama_subunit']?.toString() ?? '';
    final unitId = item['id_unit']?.toString();
    final lokasiId = item['id_lokasi']?.toString();
    final isSelected = id == widget.selectedId;

    return GestureDetector(
      onTap: () {
        widget.onSelect(id, name, unitId, lokasiId);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _amber.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSelected ? _amber : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _amber.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.layers_rounded, color: _amberText, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: _amberText, size: 20)
            else
              const Icon(Icons.chevron_right_rounded, color: _amberText, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 440,
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: _amber.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.layers_rounded, color: _amberText, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _t('PILIH SUB-UNIT', 'SELECT SUB-UNIT', '选择子单位'),
                        style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w800, color: _amberText),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration:
                            BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: const Color(0xFFF1F5F9)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _amber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _amber.withValues(alpha: 0.4), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 20, color: _amberText),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          style: GoogleFonts.poppins(
                              fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E3A8A)),
                          decoration: InputDecoration(
                            hintText: _t('Cari Sub-Unit...', 'Search Sub-Unit...', '搜索子单位...'),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 13),
                            hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
                          ),
                        ),
                      ),
                      if (_searchCtrl.text.isNotEmpty)
                        GestureDetector(
                          onTap: () => _searchCtrl.clear(),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration:
                                BoxDecoration(color: _amber.withValues(alpha: 0.20), shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded, size: 14, color: _amberText),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Container(height: 1, color: const Color(0xFFF1F5F9)),
              Expanded(
                child: _isLoading
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey.shade200,
                        highlightColor: Colors.grey.shade50,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          itemCount: 5,
                          itemBuilder: (_, __) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            height: 68,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      )
                    : _filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 48),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off_rounded, size: 44, color: Colors.grey.shade300),
                                  const SizedBox(height: 10),
                                  Text(_t('Tidak ada hasil', 'No results found', '没有结果'),
                                      style: GoogleFonts.poppins(color: Colors.grey.shade500)),
                                ],
                              ),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                            children: _filtered.map(_buildSubunitCard).toList(),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AreaFormField {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final int maxLines;
  final bool required;
  const _AreaFormField({
    required this.label,
    required this.controller,
    required this.icon,
    this.maxLines = 1,
    this.required = false,
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
                      color: color.withValues(alpha:0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: const Color(0xFFBE185D), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFBE185D),
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
                          const Icon(Icons.camera_alt_rounded, size: 14, color: Color(0xFFBE185D)),
                          const SizedBox(width: 6),
                          Text(
                            lang == 'EN' ? 'Area Photo' : lang == 'ZH' ? '区域照片' : 'Foto Area',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFBE185D),
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
                                Icon(f.icon, size: 14, color: const Color(0xFFBE185D)),
                                const SizedBox(width: 6),
                                Text(
                                  f.label,
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFBE185D),
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

/// Dialog filter dengan 3 tab: Lokasi, Unit, dan Sub-Unit.
/// Karena tabel `area` sudah menyimpan id_lokasi, id_unit, dan id_subunit
/// secara langsung, setiap tab tinggal mencocokkan kolom yang sesuai tanpa
/// perlu resolve lewat tabel lain.
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