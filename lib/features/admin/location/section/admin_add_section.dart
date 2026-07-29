import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/translation_service.dart';
import '../../../user/finding/finding_pick_pic.dart';
import '../../../user/home/alert/required_field_alert.dart';
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

class AdminAddSectionDialog extends StatefulWidget {
  final String lang;
  final List<Map<String, dynamic>> sections;
  final List<Map<String, dynamic>> lokasiList;
  final List<Map<String, dynamic>> unitList;
  final List<Map<String, dynamic>> subunitList;
  final List<Map<String, dynamic>> areaList;

  final Future<void> Function() onSaved;

  final void Function({
    required bool isSuccess,
    required String titleEn,
    required String titleId,
    required String titleZh,
    required String msgEn,
    required String msgId,
    required String msgZh,
  }) showResultPopup;

  const AdminAddSectionDialog({
    super.key,
    required this.lang,
    required this.sections,
    required this.lokasiList,
    required this.unitList,
    required this.subunitList,
    required this.areaList,
    required this.onSaved,
    required this.showResultPopup,
  });

  @override
  State<AdminAddSectionDialog> createState() => _AdminAddSectionDialogState();
}

class _AdminAddSectionDialogState extends State<AdminAddSectionDialog> {
  final _supabase = Supabase.instance.client;

  late final TextEditingController _namaCtrl;
  late final TextEditingController _descCtrl;

  String? _gambarUrl;
  Uint8List? _previewBytes;

  String? _selLokasi;
  String? _selUnit;
  String? _selSubunit;
  String? _selArea;
  String? _selPicId;
  Map<String, dynamic>? _selPicData;

  bool _isSaving = false;

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: '');
    _descCtrl = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Widget _buildSectionPhotoPicker({
    required String? imageUrl,
    required Uint8List? previewBytes,
    required VoidCallback onPickTap,
    required VoidCallback onViewTap,
  }) {
    final bool hasPreview = previewBytes != null || (imageUrl != null && imageUrl.isNotEmpty);
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _C.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.primary.withValues(alpha: 0.3), width: 1.3),
        ),
        child: hasPreview
            ? Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTap: onViewTap,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.7),
                      child: previewBytes != null
                          ? Image.memory(previewBytes, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                          : Image.network(imageUrl!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: GestureDetector(
                      onTap: onPickTap,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: _C.primary, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 14, color: _C.primary),
                      ),
                    ),
                  ),
                ],
              )
            : GestureDetector(
                onTap: onPickTap,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _C.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_photo_alternate_rounded, color: _C.primary, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _t('Tap to select image', 'Tap untuk pilih gambar', '点击选择图片'),
                        style: GoogleFonts.poppins(color: _C.primary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _t('Camera or Gallery', 'Kamera atau Galeri', '相机或图库'),
                        style: GoogleFonts.poppins(color: Colors.black38, fontWeight: FontWeight.w600, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  void _openFullscreenPreview() {
    final url = _gambarUrl;
    if (_previewBytes == null && (url == null || url.isEmpty)) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => _SectionFullscreenImageViewer(
          imageUrl: url ?? '',
          previewBytes: _previewBytes,
        ),
      ),
    );
  }

  Future<void> _onTapPhoto() async {
    final XFile? picked = await Navigator.of(context, rootNavigator: true).push<XFile?>(
      MaterialPageRoute(builder: (_) => AdminSectionCameraScreen(lang: widget.lang)),
    );
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _previewBytes = bytes;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdminSectionCameraWarmupService.instance.warmUp();
    });

    try {
      final ext = picked.name.split('.').last.toLowerCase();
      final safeExt = ext.isEmpty ? 'jpg' : ext;
      final fileName = 'new-section-${DateTime.now().millisecondsSinceEpoch}.$safeExt';
      final filePath = 'section/$fileName';
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
      await _supabase.storage
          .from('lokasi-images')
          .uploadBinary(filePath, bytes, fileOptions: FileOptions(contentType: contentType, upsert: true));
      final newUrl = _supabase.storage.from('lokasi-images').getPublicUrl(filePath);
      if (!mounted) return;
      setState(() {
        _gambarUrl = newUrl;
      });
    } catch (e) {
      debugPrint('Error uploading section photo: $e');
    }
  }

  Widget _sectionPickerField({
    required String label,
    required IconData icon,
    required Color color,
    required String? selectedName,
    required VoidCallback onTap,
  }) {
    final hasValue = selectedName != null && selectedName.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 15, color: hasValue ? color : Colors.black26),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasValue ? selectedName : _t('None', 'Tidak ada', '无'),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: hasValue ? _C.textMain : Colors.black38,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, color: color.withValues(alpha: 0.7), size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPicField({
    required bool enabled,
    required Map<String, dynamic>? picData,
    required VoidCallback? onTap,
  }) {
    final hasValue = picData != null;
    final name = picData?['nama']?.toString() ?? '';
    final avatarUrl = picData?['gambar_user']?.toString();
    final idJabatan = picData?['id_jabatan'] as int?;
    final isVerificator = picData?['is_verificator'] as bool?;
    final jabatanRaw = picData?['jabatan'];
    final jabatanNama = jabatanRaw is Map ? jabatanRaw['nama_jabatan']?.toString() : null;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: hasValue ? _C.primary.withValues(alpha: 0.06) : _C.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: hasValue ? _C.primary.withValues(alpha: 0.3) : _C.divider),
          ),
          child: hasValue
              ? Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: _C.primaryLt,
                      backgroundImage:
                          (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? const Icon(Icons.person_rounded, color: _C.primary, size: 18)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _C.textMain),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          buildJabatanBadge(
                            idJabatan: idJabatan,
                            jabatanNama: jabatanNama,
                            isVerificator: isVerificator,
                            lang: widget.lang,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded, color: _C.primary.withValues(alpha: 0.7), size: 18),
                  ],
                )
              : Row(
                  children: [
                    const Icon(Icons.person_off_rounded, size: 16, color: Colors.black26),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        enabled
                            ? _t('Select PIC', 'Pilih PIC', '选择负责人')
                            : _t('Select Location Mapping first', 'Pilih Pemetaan Lokasi dahulu', '请先选择位置映射'),
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.black38),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black26, size: 18),
                  ],
                ),
        ),
      ),
    );
  }

  void _openSectionPicker({
    required String title,
    required IconData icon,
    required Color color,
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String nameKey,
    required String? selectedId,
    required ValueChanged<String?> onSelect,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _SectionPickerDialog(
        title: title,
        icon: icon,
        color: color,
        items: items,
        idKey: idKey,
        nameKey: nameKey,
        selectedId: selectedId,
        lang: widget.lang,
        onSelect: onSelect,
      ),
    );
  }

  String? _nameById(List<Map<String, dynamic>> list, String idKey, String nameKey, String? id) {
    if (id == null) return null;
    for (final item in list) {
      if (item[idKey]?.toString() == id) return item[nameKey]?.toString();
    }
    return null;
  }

  Future<void> _handleSave() async {
    final text = _namaCtrl.text.trim();
    final hasMapping = _selLokasi != null || _selUnit != null || _selSubunit != null || _selArea != null;

    final missing = <MissingFieldItem>[];
    if (text.isEmpty) {
      missing.add(MissingFieldItem(icon: Icons.badge_rounded, label: _t('Section Name', 'Nama Section', '部门名称')));
    }
    if (!hasMapping) {
      missing.add(MissingFieldItem(icon: Icons.map_rounded, label: _t('Location Mapping', 'Pemetaan Lokasi', '位置映射')));
    }
    if (_selPicId == null) {
      missing.add(MissingFieldItem(icon: Icons.badge_rounded, label: _t('Person in Charge', 'Penanggung Jawab', '负责人')));
    }
    if (missing.isNotEmpty) {
      RequiredFieldAlert.show(context, lang: widget.lang, missingFields: missing);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final isDup = widget.sections.any((s) =>
          (s['nama_section_id']?.toString().trim().toLowerCase() ?? '') == text.toLowerCase());
      if (isDup) {
        setState(() => _isSaving = false);
        widget.showResultPopup(
          isSuccess: false,
          titleEn: 'Duplicate Section',
          titleId: 'Section Duplikat',
          titleZh: '部门重复',
          msgEn: 'This section name already exists.',
          msgId: 'Nama section ini sudah ada.',
          msgZh: '该部门名称已存在。',
        );
        return;
      }
      final namaTranslated = await TranslationHelper.instance.translateDescriptionAllLangs(text, widget.lang);
      final descSource = _descCtrl.text.trim();
      Map<String, String> descTranslated = {'id': '', 'en': '', 'zh': ''};
      if (descSource.isNotEmpty) {
        descTranslated = await TranslationHelper.instance.translateDescriptionAllLangs(descSource, widget.lang);
      }
      final data = {
        'nama_section_id': namaTranslated['id'],
        'nama_section_en': namaTranslated['en'],
        'nama_section_zh': namaTranslated['zh'],
        'deskripsi_section': descTranslated['id']!.isEmpty ? null : descTranslated['id'],
        'deskripsi_section_en': descTranslated['en']!.isEmpty ? null : descTranslated['en'],
        'deskripsi_section_zh': descTranslated['zh']!.isEmpty ? null : descTranslated['zh'],
        'gambar_section': _gambarUrl,
        'id_lokasi': _selLokasi,
        'id_unit': _selUnit,
        'id_subunit': _selSubunit,
        'id_area': _selArea,
        'id_pic': _selPicId,
      };
      await _supabase.from('section').insert({
        ...data,
        'urutan': widget.sections.length + 1,
      });
      if (mounted) Navigator.pop(context);
      await widget.onSaved();
      widget.showResultPopup(
        isSuccess: true,
        titleEn: 'Section Added!',
        titleId: 'Section Ditambahkan!',
        titleZh: '部门已添加！',
        msgEn: 'New section has been saved successfully.',
        msgId: 'Section baru berhasil disimpan.',
        msgZh: '新部门已成功保存。',
      );
    } catch (e) {
      debugPrint('Error save section: $e');
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitOptions = _selLokasi == null
        ? widget.unitList
        : widget.unitList.where((u) => u['id_lokasi']?.toString() == _selLokasi).toList();
    final subunitOptions = _selUnit == null
        ? widget.subunitList
        : widget.subunitList.where((s) => s['id_unit']?.toString() == _selUnit).toList();
    final areaOptions = _selSubunit == null
        ? widget.areaList
        : widget.areaList.where((a) => a['id_subunit']?.toString() == _selSubunit).toList();
    final hasMapping = _selLokasi != null || _selUnit != null || _selSubunit != null || _selArea != null;
    final currentLocFilter = _selArea != null
        ? {'idCol': 'id_area', 'id': _selArea!}
        : _selSubunit != null
            ? {'idCol': 'id_subunit', 'id': _selSubunit!}
            : _selUnit != null
                ? {'idCol': 'id_unit', 'id': _selUnit!}
                : _selLokasi != null
                    ? {'idCol': 'id_lokasi', 'id': _selLokasi!}
                    : null;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 22, 20, 16),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _C.primaryLt, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.dashboard_customize_rounded, color: _C.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _t('Add Section', 'Tambah Section', '添加部门'),
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: _C.textMain),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
                  ),
                ),
              ]),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.camera_alt_rounded, size: 14, color: _C.primary),
                        const SizedBox(width: 6),
                        Text(
                          _t('Photo', 'Foto', '图片'),
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _C.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildSectionPhotoPicker(
                      imageUrl: _gambarUrl,
                      previewBytes: _previewBytes,
                      onPickTap: _onTapPhoto,
                      onViewTap: _openFullscreenPreview,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Icon(Icons.badge_rounded, size: 14, color: _C.primary),
                        const SizedBox(width: 6),
                        Text(
                          _t('Section Name', 'Nama Section', '部门名称'),
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _C.primary),
                        ),
                        const SizedBox(width: 3),
                        Text('*', style: GoogleFonts.poppins(color: _C.red, fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _namaCtrl,
                      decoration: InputDecoration(
                        hintText: _t('e.g. Assembly', 'cth. Assy', '例如：组装'),
                        hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
                        filled: true,
                        fillColor: _C.surface,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.divider)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.divider)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _C.primary, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _t('Name will be auto-translated to EN / ZH.',
                          'Nama akan diterjemahkan otomatis ke EN / ZH.', '名称将自动翻译为英文/中文。'),
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _C.textSub),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.notes_rounded, size: 14, color: _C.primary),
                        const SizedBox(width: 6),
                        Text(
                          _t('Description', 'Deskripsi', '描述'),
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _C.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: _t('Optional', 'Opsional', '可选'),
                        hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
                        filled: true,
                        fillColor: _C.surface,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.divider)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.divider)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _C.primary, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Icon(Icons.map_rounded, size: 14, color: _C.primary),
                        const SizedBox(width: 6),
                        Text(
                          _t('Location Mapping', 'Pemetaan Lokasi', '位置映射'),
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _C.primary),
                        ),
                        const SizedBox(width: 3),
                        Text('*', style: GoogleFonts.poppins(color: _C.red, fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _t('Choose at least one level below.', 'Pilih minimal satu level di bawah ini.', '请至少选择以下一个级别。'),
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _C.textSub),
                    ),
                    const SizedBox(height: 10),
                    _sectionPickerField(
                      label: _t('Location', 'Lokasi', '位置'),
                      icon: Icons.location_city_rounded,
                      color: const Color(0xFF10B981),
                      selectedName: _nameById(widget.lokasiList, 'id_lokasi', 'nama_lokasi', _selLokasi),
                      onTap: () => _openSectionPicker(
                        title: _t('Select Location', 'Pilih Lokasi', '选择位置'),
                        icon: Icons.location_city_rounded,
                        color: const Color(0xFF10B981),
                        items: widget.lokasiList,
                        idKey: 'id_lokasi',
                        nameKey: 'nama_lokasi',
                        selectedId: _selLokasi,
                        onSelect: (v) => setState(() {
                          _selLokasi = v;
                          _selUnit = null;
                          _selSubunit = null;
                          _selArea = null;
                          _selPicId = null;
                          _selPicData = null;
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _sectionPickerField(
                      label: _t('Unit', 'Unit', '单位'),
                      icon: Icons.business_rounded,
                      color: const Color(0xFF6366F1),
                      selectedName: _nameById(unitOptions, 'id_unit', 'nama_unit', _selUnit),
                      onTap: () => _openSectionPicker(
                        title: _t('Select Unit', 'Pilih Unit', '选择单位'),
                        icon: Icons.business_rounded,
                        color: const Color(0xFF6366F1),
                        items: unitOptions,
                        idKey: 'id_unit',
                        nameKey: 'nama_unit',
                        selectedId: _selUnit,
                        onSelect: (v) => setState(() {
                          _selUnit = v;
                          _selSubunit = null;
                          _selArea = null;
                          _selPicId = null;
                          _selPicData = null;
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _sectionPickerField(
                      label: _t('Sub-Unit', 'Sub-Unit', '子单位'),
                      icon: Icons.layers_rounded,
                      color: const Color(0xFFFBBF24),
                      selectedName: _nameById(subunitOptions, 'id_subunit', 'nama_subunit', _selSubunit),
                      onTap: () => _openSectionPicker(
                        title: _t('Select Sub-Unit', 'Pilih Sub-Unit', '选择子单位'),
                        icon: Icons.layers_rounded,
                        color: const Color(0xFFFBBF24),
                        items: subunitOptions,
                        idKey: 'id_subunit',
                        nameKey: 'nama_subunit',
                        selectedId: _selSubunit,
                        onSelect: (v) => setState(() {
                          _selSubunit = v;
                          _selArea = null;
                          _selPicId = null;
                          _selPicData = null;
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _sectionPickerField(
                      label: _t('Area', 'Area', '区域'),
                      icon: Icons.place_rounded,
                      color: const Color(0xFFF472B6),
                      selectedName: _nameById(areaOptions, 'id_area', 'nama_area', _selArea),
                      onTap: () => _openSectionPicker(
                        title: _t('Select Area', 'Pilih Area', '选择区域'),
                        icon: Icons.place_rounded,
                        color: const Color(0xFFF472B6),
                        items: areaOptions,
                        idKey: 'id_area',
                        nameKey: 'nama_area',
                        selectedId: _selArea,
                        onSelect: (v) => setState(() {
                          _selArea = v;
                          _selPicId = null;
                          _selPicData = null;
                        }),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Icon(Icons.badge_rounded, size: 14, color: _C.primary),
                        const SizedBox(width: 6),
                        Text(
                          _t('Person in Charge', 'Penanggung Jawab', '负责人'),
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _C.primary),
                        ),
                        const SizedBox(width: 3),
                        Text('*', style: GoogleFonts.poppins(color: _C.red, fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasMapping
                          ? _t('Only users at the selected location can be assigned.',
                              'Hanya pengguna pada lokasi terpilih yang bisa ditugaskan.', '只能指派所选位置的用户。')
                          : _t('Select a Location Mapping level above first.',
                              'Pilih salah satu level Pemetaan Lokasi di atas terlebih dahulu.', '请先选择上方的位置映射级别。'),
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _C.textSub),
                    ),
                    const SizedBox(height: 6),
                    _buildPicField(
                      enabled: hasMapping,
                      picData: _selPicData,
                      onTap: !hasMapping
                          ? null
                          : () async {
                              final loc = currentLocFilter!;
                              final result = await showDialog<Map<String, dynamic>>(
                                context: context,
                                barrierDismissible: true,
                                builder: (dCtx) => _SectionPicPickerDialog(
                                  lang: widget.lang,
                                  idCol: loc['idCol']!,
                                  locId: loc['id']!,
                                  excludeSectionId: null,
                                  selectedUserId: _selPicId,
                                ),
                              );
                              if (result != null) {
                                setState(() {
                                  _selPicId = result['id_user']?.toString();
                                  _selPicData = result;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, -2)),
                ],
              ),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _C.divider),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(
                      _t('Cancel', 'Batal', '取消'),
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _C.textSub),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: _isSaving
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _t('Saving...', 'Menyimpan...', '保存中...'),
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ],
                          )
                        : Text(
                            _t('Save', 'Simpan', '保存'),
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionFullscreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final Uint8List? previewBytes;

  const _SectionFullscreenImageViewer({required this.imageUrl, this.previewBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black.withValues(alpha: 0.95)),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: Center(
                  child: previewBytes != null
                      ? Image.memory(previewBytes!, fit: BoxFit.contain)
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_rounded,
                            color: Colors.white54,
                            size: 64,
                          ),
                        ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _C.red.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.2),
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionPickerDialog extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Map<String, dynamic>> items;
  final String idKey;
  final String nameKey;
  final String? selectedId;
  final String lang;
  final ValueChanged<String?> onSelect;

  const _SectionPickerDialog({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.idKey,
    required this.nameKey,
    required this.selectedId,
    required this.lang,
    required this.onSelect,
  });

  @override
  State<_SectionPickerDialog> createState() => _SectionPickerDialogState();
}

class _SectionPickerDialogState extends State<_SectionPickerDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];
  int _currentPage = 1;
  static const int _perPage = 5;

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyFilter);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.items
          : widget.items.where((e) => (e[widget.nameKey]?.toString() ?? '').toLowerCase().contains(q)).toList();
      _currentPage = 1;
    });
  }

  void _resetSearch() {
    _searchCtrl.clear();
    setState(() => _currentPage = 1);
  }

  Widget _buildNoneCard(BuildContext context) {
    final isSel = widget.selectedId == null;
    return GestureDetector(
      onTap: () {
        widget.onSelect(null);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSel ? widget.color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSel ? widget.color : Colors.grey.shade200, width: isSel ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.block_rounded, size: 18, color: Colors.black38),
            ),
            const SizedBox(width: 12),
            Text(
              _t('None', 'Tidak ada', '无'),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, Map<String, dynamic> item) {
    final id = item[widget.idKey]?.toString() ?? '';
    final name = item[widget.nameKey]?.toString() ?? '-';
    final isSel = id == widget.selectedId;
    return GestureDetector(
      onTap: () {
        widget.onSelect(id);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSel ? widget.color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSel ? widget.color : Colors.grey.shade200, width: isSel ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
              child: Icon(widget.icon, size: 18, color: widget.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF1E3A8A)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (isSel) Icon(Icons.check_circle_rounded, color: widget.color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isSearching = _searchCtrl.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              height: 100,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: Icon(Icons.search_off_rounded, size: 34, color: widget.color.withValues(alpha: 0.5)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _t('No results found', 'Tidak ada hasil', '没有结果'),
              style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A8A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? _t('Try a different keyword.', 'Coba kata kunci lain.', '请尝试其他关键词。')
                  : _t('No items available.', 'Tidak ada item tersedia.', '没有可用项目。'),
              style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF64748B), height: 1.4),
              textAlign: TextAlign.center,
            ),
            if (isSearching) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _resetSearch,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: widget.color.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 14, color: widget.color),
                      const SizedBox(width: 6),
                      Text(_t('Clear search', 'Hapus pencarian', '清除搜索'),
                          style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: widget.color)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = _filtered.isEmpty ? 1 : (_filtered.length / _perPage).ceil();
    final safePage = _currentPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * _perPage;
    final endIdx = (startIdx + _perPage) > _filtered.length ? _filtered.length : startIdx + _perPage;
    final pageItems = _filtered.isEmpty ? <Map<String, dynamic>>[] : _filtered.sublist(startIdx, endIdx);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75, maxWidth: 420),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 10, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration:
                          BoxDecoration(color: widget.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                      child: Icon(widget.icon, color: widget.color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(widget.title,
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: widget.color)),
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
              const SizedBox(height: 10),
              Container(height: 1, color: const Color(0xFFF1F5F9)),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: widget.color.withValues(alpha: 0.3), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, size: 18, color: widget.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          textAlignVertical: TextAlignVertical.center,
                          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1E3A8A)),
                          decoration: InputDecoration(
                            hintText: _t('Search...', 'Cari...', '搜索...'),
                            hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_searchCtrl.text.isNotEmpty)
                        GestureDetector(
                          onTap: _resetSearch,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: _C.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded, size: 14, color: _C.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Container(height: 1, color: const Color(0xFFF1F5F9)),
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  shrinkWrap: true,
                  children: [
                    _buildNoneCard(context),
                    if (_filtered.isEmpty)
                      _buildEmptyState()
                    else
                      ...pageItems.map((item) => _buildItemCard(context, item)),
                  ],
                ),
              ),
              if (_filtered.isNotEmpty && totalPages > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 14),
                  child: AdminSectionPageIndicator(
                    currentPage: safePage,
                    totalPages: totalPages,
                    onPageChanged: (p) => setState(() => _currentPage = p),
                    color: widget.color,
                    horizontalMargin: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionPicPickerDialog extends StatefulWidget {
  final String lang;
  final String idCol;
  final String locId;
  final String? excludeSectionId;
  final String? selectedUserId;

  const _SectionPicPickerDialog({
    required this.lang,
    required this.idCol,
    required this.locId,
    required this.excludeSectionId,
    required this.selectedUserId,
  });

  @override
  State<_SectionPicPickerDialog> createState() => _SectionPicPickerDialogState();
}

class _SectionPicPickerDialogState extends State<_SectionPicPickerDialog> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  int? _roleFilterId;
  String? _roleFilterName;
  bool _roleFilterIsVerificator = false;
  int _currentPage = 1;
  static const int _perPage = 5;

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<Set<String>> _fetchExcludedPicIds() async {
    final excluded = <String>{};
    for (final t in ['lokasi', 'unit', 'subunit', 'area']) {
      try {
        final res = await _supabase.from(t).select('id_pic').not('id_pic', 'is', null);
        for (final row in (res as List)) {
          final id = row['id_pic']?.toString();
          if (id != null) excluded.add(id);
        }
      } catch (e) {
        debugPrint('Error fetch excluded pic ($t): $e');
      }
    }
    try {
      final res = await _supabase.from('section').select('id_section, id_pic').not('id_pic', 'is', null);
      for (final row in (res as List)) {
        if (widget.excludeSectionId != null && row['id_section']?.toString() == widget.excludeSectionId) {
          continue;
        }
        final id = row['id_pic']?.toString();
        if (id != null) excluded.add(id);
      }
    } catch (e) {
      debugPrint('Error fetch excluded pic (section): $e');
    }
    return excluded;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final excluded = await _fetchExcludedPicIds();
      final res = await _supabase
          .from('User')
          .select('id_user, nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)')
          .eq(widget.idCol, widget.locId)
          .order('nama');
      final list = List<Map<String, dynamic>>.from(res)
          .where((u) => !excluded.contains(u['id_user']?.toString()) || u['id_user']?.toString() == widget.selectedUserId)
          .toList();
      if (mounted) {
        setState(() {
          _items = list;
          _loading = false;
        });
        _applyFilter();
      }
    } catch (e) {
      debugPrint('Error load section PIC users: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = _items.where((u) {
        final matchesSearch = q.isEmpty || (u['nama'] ?? '').toString().toLowerCase().contains(q);
        final matchesRole = _roleFilterIsVerificator
            ? (u['is_verificator'] == true)
            : (_roleFilterId == null || u['id_jabatan'] == _roleFilterId);
        return matchesSearch && matchesRole;
      }).toList();
      _currentPage = 1;
    });
  }

  void _resetSearch() {
    _searchCtrl.clear();
    _applyFilter();
  }

  Future<void> _openRoleFilter() async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _SectionRoleFilterDialog(
        lang: widget.lang,
        selectedId: _roleFilterId,
        isVerificatorSelected: _roleFilterIsVerificator,
      ),
    );
    if (result != null) {
      setState(() {
        if (result.isEmpty) {
          _roleFilterId = null;
          _roleFilterName = null;
          _roleFilterIsVerificator = false;
        } else if (result['is_verificator'] == true) {
          _roleFilterId = null;
          _roleFilterIsVerificator = true;
          _roleFilterName = _t('Verificator', 'Verifikator', '验证员');
        } else {
          _roleFilterId = result['id_jabatan'] as int?;
          _roleFilterIsVerificator = false;
          _roleFilterName = result['nama_jabatan']?.toString();
        }
      });
      _applyFilter();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final totalPages = _filtered.isEmpty ? 1 : (_filtered.length / _perPage).ceil();
    final safePage = _currentPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * _perPage;
    final endIdx = (startIdx + _perPage) > _filtered.length ? _filtered.length : startIdx + _perPage;
    final pageItems = _filtered.isEmpty ? <Map<String, dynamic>>[] : _filtered.sublist(startIdx, endIdx);
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
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _C.primaryLt, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.person_search_rounded, color: _C.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _t('Select Person in Charge', 'Pilih Penanggung Jawab', '选择负责人'),
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
            ]),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _C.primary.withValues(alpha: 0.35), width: 1.3),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => _applyFilter(),
                    textAlignVertical: TextAlignVertical.center,
                    style: GoogleFonts.poppins(fontSize: 13, color: _C.textMain, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: _t('Search user...', 'Cari pengguna...', '搜索用户...'),
                      hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black38),
                      prefixIcon: const Icon(Icons.search_rounded, color: _C.primary, size: 19),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? GestureDetector(
                              onTap: _resetSearch,
                              child: Container(
                                margin: const EdgeInsets.all(10),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: _C.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.close_rounded, size: 14, color: _C.red),
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
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _openRoleFilter,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _roleFilterId != null ? _C.primary : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _roleFilterId != null ? _C.primary : _C.primary.withValues(alpha: 0.35),
                      width: 1.3,
                    ),
                  ),
                  child: Icon(Icons.filter_list_rounded, color: _roleFilterId != null ? Colors.white : _C.primary, size: 20),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, bottom: 4),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _C.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _C.primary.withValues(alpha: 0.30)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_alt_rounded, size: 13, color: _C.primary),
                    const SizedBox(width: 5),
                    Text('${_filtered.length} ${_t('users', 'pengguna', '位用户')}',
                        style: GoogleFonts.poppins(color: _C.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              if (_roleFilterName != null) ...[
                const Spacer(),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _C.primaryLt, borderRadius: BorderRadius.circular(20)),
                    child: Text(_roleFilterName!,
                        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: _C.primary),
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Expanded(
            child: _loading
                ? Shimmer.fromColors(
                    baseColor: Colors.grey.shade200,
                    highlightColor: Colors.grey.shade50,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 6, bottom: 12),
                      itemCount: 6,
                      itemBuilder: (_, __) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        height: 62,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                : _filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 6, bottom: 12),
                        itemCount: pageItems.length,
                        itemBuilder: (_, i) {
                          final item = pageItems[i];
                          final name = (item['nama'] ?? '').toString();
                          final id = item['id_user']?.toString();
                          final avatarUrl = item['gambar_user'] as String?;
                          final idJabatan = item['id_jabatan'] as int?;
                          final isVerificator = item['is_verificator'] as bool?;
                          final jabatanRaw = item['jabatan'];
                          final jabatanNama = jabatanRaw is Map ? jabatanRaw['nama_jabatan']?.toString() : null;
                          final isSelected = id != null && id == widget.selectedUserId;

                          return InkWell(
                            onTap: () => Navigator.pop(context, item),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? _C.primaryLt : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? _C.primary : _C.divider, width: isSelected ? 1.5 : 1),
                              ),
                              child: Row(children: [
                                if (avatarUrl != null && avatarUrl.isNotEmpty)
                                  CircleAvatar(radius: 20, backgroundImage: NetworkImage(avatarUrl), backgroundColor: _C.primaryLt)
                                else
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: isSelected ? _C.primary : _C.primaryLt,
                                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: isSelected ? Colors.white : _C.primary)),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected ? _C.primary : _C.textMain)),
                                      const SizedBox(height: 4),
                                      buildJabatanBadge(
                                          idJabatan: idJabatan, jabatanNama: jabatanNama, isVerificator: isVerificator, lang: widget.lang),
                                    ],
                                  ),
                                ),
                                if (isSelected) const Icon(Icons.check_circle_rounded, color: _C.primary, size: 18),
                              ]),
                            ),
                          );
                        },
                      ),
          ),
          if (!_loading && _filtered.isNotEmpty && totalPages > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
              child: AdminSectionPageIndicator(
                currentPage: safePage,
                totalPages: totalPages,
                onPageChanged: (p) => setState(() => _currentPage = p),
                color: _C.primary,
                horizontalMargin: 14,
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isSearching = _searchCtrl.text.trim().isNotEmpty || _roleFilterId != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: _C.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: const Icon(Icons.person_search_rounded, size: 34, color: _C.primary),
            ),
            const SizedBox(height: 14),
            Text(
              _t('No users found', 'Pengguna tidak ditemukan', '未找到用户'),
              style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: _C.textMain),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? _t('Try a different keyword or role.', 'Coba kata kunci atau role lain.', '请尝试其他关键词或角色。')
                  : _t('No users available at this location.', 'Tidak ada pengguna di lokasi ini.', '此位置没有可用用户。'),
              style: GoogleFonts.poppins(fontSize: 11.5, color: _C.textSub, height: 1.4),
              textAlign: TextAlign.center,
            ),
            if (isSearching) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () {
                  _resetSearch();
                  setState(() {
                    _roleFilterId = null;
                    _roleFilterName = null;
                    _roleFilterIsVerificator = false;
                  });
                  _applyFilter();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: _C.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _C.primary.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh_rounded, size: 14, color: _C.primary),
                      const SizedBox(width: 6),
                      Text(_t('Clear search', 'Hapus pencarian', '清除搜索'),
                          style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: _C.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionRoleFilterDialog extends StatefulWidget {
  final String lang;
  final int? selectedId;
  final bool isVerificatorSelected;
  const _SectionRoleFilterDialog({
    required this.lang,
    required this.selectedId,
    this.isVerificatorSelected = false,
  });

  @override
  State<_SectionRoleFilterDialog> createState() => _SectionRoleFilterDialogState();
}

class _SectionRoleFilterDialogState extends State<_SectionRoleFilterDialog> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _jabatanList = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;

  static const List<Color> _palette = [
    Color(0xFF6366F1), Color(0xFF10B981), Color(0xFFF59E0B),
    Color(0xFFEC4899), Color(0xFF06B6D4), Color(0xFFEF4444),
    Color(0xFF8B5CF6), Color(0xFF14B8A6),
  ];

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyFilter);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await _supabase.from('jabatan').select('id_jabatan, nama_jabatan').order('id_jabatan', ascending: true);
      _jabatanList = List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error load jabatan: $e');
      _jabatanList = [];
    }
    _filtered = List.from(_jabatanList);
    if (mounted) setState(() => _loading = false);
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_jabatanList)
          : _jabatanList.where((e) => (e['nama_jabatan'] ?? '').toString().toLowerCase().contains(q)).toList();
    });
  }

  void _resetSearch() {
    _searchCtrl.clear();
  }

  Color _colorFor(int? id) => _palette[(id ?? 0) % _palette.length];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
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
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _C.primaryLt, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.badge_rounded, color: _C.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(_t('Select Role', 'Pilih Role', '选择角色'),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16, color: _C.primary)),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.primary.withValues(alpha: 0.35), width: 1.3),
              ),
              child: TextField(
                controller: _searchCtrl,
                textAlignVertical: TextAlignVertical.center,
                style: GoogleFonts.poppins(fontSize: 13, color: _C.textMain, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: _t('Search role...', 'Cari role...', '搜索角色...'),
                  hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black38),
                  prefixIcon: const Icon(Icons.search_rounded, color: _C.primary, size: 19),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? GestureDetector(
                          onTap: _resetSearch,
                          child: Container(
                            margin: const EdgeInsets.all(10),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: _C.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded, size: 14, color: _C.red),
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
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Expanded(
            child: _loading
                ? Shimmer.fromColors(
                    baseColor: Colors.grey.shade200,
                    highlightColor: Colors.grey.shade50,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 6, bottom: 12),
                      itemCount: 6,
                      itemBuilder: (_, __) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        height: 58,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(top: 6, bottom: 12),
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context, <String, dynamic>{}),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: widget.selectedId == null && !widget.isVerificatorSelected ? _C.primaryLt : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: widget.selectedId == null && !widget.isVerificatorSelected ? _C.primary : _C.divider,
                                width: widget.selectedId == null && !widget.isVerificatorSelected ? 1.5 : 1),
                          ),
                          child: Row(children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.apps_rounded, size: 18, color: Colors.black38),
                            ),
                            const SizedBox(width: 12),
                            Text(_t('All Roles', 'Semua Role', '所有角色'),
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black54)),
                          ]),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context, <String, dynamic>{'is_verificator': true}),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: widget.isVerificatorSelected ? const Color(0xFFFEF3C7) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: widget.isVerificatorSelected ? const Color(0xFFF59E0B) : _C.divider,
                                width: widget.isVerificatorSelected ? 1.5 : 1),
                          ),
                          child: Row(children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.verified_rounded, size: 18, color: Color(0xFFF59E0B)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(_t('Verificator', 'Verifikator', '验证员'),
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: widget.isVerificatorSelected ? const Color(0xFFB45309) : _C.textMain)),
                            ),
                            if (widget.isVerificatorSelected)
                              const Icon(Icons.check_circle_rounded, color: Color(0xFFF59E0B), size: 18),
                          ]),
                        ),
                      ),
                      if (_filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/team_illustration.png',
                                  height: 100,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(color: _C.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
                                    child: const Icon(Icons.search_off_rounded, size: 34, color: _C.primary),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _t('No roles found', 'Role tidak ditemukan', '未找到角色'),
                                  style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: _C.textMain),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _t('Try a different keyword.', 'Coba kata kunci lain.', '请尝试其他关键词。'),
                                  style: GoogleFonts.poppins(fontSize: 11.5, color: _C.textSub, height: 1.4),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 14),
                                GestureDetector(
                                  onTap: _resetSearch,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                    decoration: BoxDecoration(
                                      color: _C.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(color: _C.primary.withValues(alpha: 0.35)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.refresh_rounded, size: 14, color: _C.primary),
                                        const SizedBox(width: 6),
                                        Text(_t('Clear search', 'Hapus pencarian', '清除搜索'),
                                            style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: _C.primary)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._filtered.map((item) {
                          final id = item['id_jabatan'] as int?;
                          final nama = item['nama_jabatan']?.toString() ?? '-';
                          final isSelected = id != null && id == widget.selectedId;
                          final color = _colorFor(id);
                          return InkWell(
                            onTap: () => Navigator.pop(context, item),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? color : _C.divider, width: isSelected ? 1.5 : 1),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                                  child: Icon(Icons.badge_rounded, size: 17, color: color),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(nama,
                                      style: GoogleFonts.poppins(
                                          fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? color : _C.textMain)),
                                ),
                                if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 18),
                              ]),
                            ),
                          );
                        }),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }
}