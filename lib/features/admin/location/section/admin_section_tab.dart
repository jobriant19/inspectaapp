import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/translation_service.dart';
import '../../../shared/code/qr_generator_screen.dart';
import '../../../user/finding/finding_pick_pic.dart';
import '../../../user/home/alert/required_field_alert.dart';
import 'camera/admin_section_camera.dart';

class _C {
  static const primary   = Color(0xFF1D72F3);
  static const primaryLt = Color(0xFFDCEAFE);
  static const red       = Color(0xFFEF4444);
  static const textMain  = Color(0xFF1E3A8A);
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

  String _localizedDesc(Map<String, dynamic> s) {
    if (widget.lang == 'EN') {
      return (s['deskripsi_section_en'] ?? s['deskripsi_section'] ?? '').toString();
    }
    if (widget.lang == 'ZH') {
      return (s['deskripsi_section_zh'] ?? s['deskripsi_section'] ?? '').toString();
    }
    return (s['deskripsi_section'] ?? '').toString();
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
    if (_search.trim().isEmpty) return _sections;
    final q = _search.toLowerCase();
    return _sections.where((s) => _nameOf(s).toLowerCase().contains(q)).toList();
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

  // --------------------------------------------------------------------
  // Foto Section: kamera instan (sama seperti pola di Location/Area/dst)
  // --------------------------------------------------------------------
  Widget _buildSectionPhotoPicker({
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
          color: _C.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.primary.withValues(alpha: 0.3), width: 1.3),
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
                        border: Border.all(color: _C.primary, width: 1.5),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 14, color: _C.primary),
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
                      style: GoogleFonts.poppins(color: Colors.black38, fontSize: 11),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // --------------------------------------------------------------------
  // Picker Lokasi/Unit/Sub-Unit/Area: popup di tengah, bukan dropdown
  // --------------------------------------------------------------------
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

  // ADD / EDIT FORM
  Future<void> _showFormDialog({Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;
    final namaCtrl =
        TextEditingController(text: isEdit ? existing['nama_section_id']?.toString() ?? '' : '');
    final descCtrl =
        TextEditingController(text: isEdit ? _localizedDesc(existing) : '');
    String? gambarUrl = isEdit ? existing['gambar_section'] as String? : null;
    Uint8List? previewBytes;

    String? selLokasi = isEdit ? existing['id_lokasi']?.toString() : null;
    String? selUnit = isEdit ? existing['id_unit']?.toString() : null;
    String? selSubunit = isEdit ? existing['id_subunit']?.toString() : null;
    String? selArea = isEdit ? existing['id_area']?.toString() : null;
    String? selPicId = isEdit ? existing['id_pic']?.toString() : null;
    Map<String, dynamic>? selPicData = isEdit ? existing['User'] as Map<String, dynamic>? : null;

    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final unitOptions = selLokasi == null
              ? _unitList
              : _unitList.where((u) => u['id_lokasi']?.toString() == selLokasi).toList();
          final subunitOptions = selUnit == null
              ? _subunitList
              : _subunitList.where((s) => s['id_unit']?.toString() == selUnit).toList();
          final areaOptions = selSubunit == null
              ? _areaList
              : _areaList.where((a) => a['id_subunit']?.toString() == selSubunit).toList();
          final hasMapping =
              selLokasi != null || selUnit != null || selSubunit != null || selArea != null;
          final currentLocFilter = selArea != null
              ? {'idCol': 'id_area', 'id': selArea!}
              : selSubunit != null
                  ? {'idCol': 'id_subunit', 'id': selSubunit!}
                  : selUnit != null
                      ? {'idCol': 'id_unit', 'id': selUnit!}
                      : selLokasi != null
                          ? {'idCol': 'id_lokasi', 'id': selLokasi!}
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
                        decoration:
                            BoxDecoration(color: _C.primaryLt, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.dashboard_customize_rounded, color: _C.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isEdit
                              ? _t('Edit Section', 'Edit Section', '编辑部门')
                              : _t('Add Section', 'Tambah Section', '添加部门'),
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w700, color: _C.textMain),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
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
                                style: GoogleFonts.poppins(
                                    fontSize: 12, fontWeight: FontWeight.w700, color: _C.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildSectionPhotoPicker(
                            imageUrl: gambarUrl,
                            previewBytes: previewBytes,
                            onTap: () async {
                              final XFile? picked = await Navigator.push<XFile?>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminSectionCameraScreen(lang: widget.lang),
                                ),
                              );
                              if (picked == null) return;
                              final bytes = await picked.readAsBytes();
                              setDlg(() {
                                previewBytes = bytes;
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                AdminSectionCameraWarmupService.instance.warmUp();
                              });
                              try {
                                final ext = picked.name.split('.').last.toLowerCase();
                                final safeExt = ext.isEmpty ? 'jpg' : ext;
                                final fileName =
                                    '${existing?['id_section']?.toString() ?? 'new-section'}-${DateTime.now().millisecondsSinceEpoch}.$safeExt';
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
                                    .uploadBinary(filePath, bytes,
                                        fileOptions: FileOptions(contentType: contentType, upsert: true));
                                final newUrl =
                                    _supabase.storage.from('lokasi-images').getPublicUrl(filePath);
                                setDlg(() {
                                  gambarUrl = newUrl;
                                });
                              } catch (e) {
                                debugPrint('Error uploading section photo: $e');
                              }
                            },
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              const Icon(Icons.badge_rounded, size: 14, color: _C.primary),
                              const SizedBox(width: 6),
                              Text(
                                _t('Section Name', 'Nama Section', '部门名称'),
                                style: GoogleFonts.poppins(
                                    fontSize: 12, fontWeight: FontWeight.w700, color: _C.primary),
                              ),
                              const SizedBox(width: 3),
                              Text('*',
                                  style: GoogleFonts.poppins(
                                      color: _C.red, fontSize: 13, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: namaCtrl,
                            decoration: InputDecoration(
                              hintText: _t('e.g. Assembly', 'cth. Assy', '例如：组装'),
                              hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
                              filled: true,
                              fillColor: _C.surface,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _C.divider)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _C.divider)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _C.primary, width: 1.5)),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            style: GoogleFonts.poppins(fontSize: 14, color: _C.textMain),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _t('Name will be auto-translated to EN / ZH.',
                                'Nama akan diterjemahkan otomatis ke EN / ZH.', '名称将自动翻译为英文/中文。'),
                            style: GoogleFonts.poppins(fontSize: 10, color: _C.textSub),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.notes_rounded, size: 14, color: _C.primary),
                              const SizedBox(width: 6),
                              Text(
                                _t('Description', 'Deskripsi', '描述'),
                                style: GoogleFonts.poppins(
                                    fontSize: 12, fontWeight: FontWeight.w700, color: _C.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: descCtrl,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: _t('Optional', 'Opsional', '可选'),
                              hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
                              filled: true,
                              fillColor: _C.surface,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _C.divider)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _C.divider)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _C.primary, width: 1.5)),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            style: GoogleFonts.poppins(fontSize: 13, color: _C.textMain),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              const Icon(Icons.map_rounded, size: 14, color: _C.primary),
                              const SizedBox(width: 6),
                              Text(
                                _t('Location Mapping', 'Pemetaan Lokasi', '位置映射'),
                                style: GoogleFonts.poppins(
                                    fontSize: 12, fontWeight: FontWeight.w700, color: _C.primary),
                              ),
                              const SizedBox(width: 3),
                              Text('*',
                                  style: GoogleFonts.poppins(
                                      color: _C.red, fontSize: 13, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _t('Choose at least one level below.',
                                'Pilih minimal satu level di bawah ini.', '请至少选择以下一个级别。'),
                            style: GoogleFonts.poppins(fontSize: 10, color: _C.textSub),
                          ),
                          const SizedBox(height: 10),
                          _sectionPickerField(
                            label: _t('Location', 'Lokasi', '位置'),
                            icon: Icons.location_city_rounded,
                            color: const Color(0xFF10B981),
                            selectedName: _nameById(_lokasiList, 'id_lokasi', 'nama_lokasi', selLokasi),
                            onTap: () => _openSectionPicker(
                              title: _t('Select Location', 'Pilih Lokasi', '选择位置'),
                              icon: Icons.location_city_rounded,
                              color: const Color(0xFF10B981),
                              items: _lokasiList,
                              idKey: 'id_lokasi',
                              nameKey: 'nama_lokasi',
                              selectedId: selLokasi,
                              onSelect: (v) => setDlg(() {
                                selLokasi = v;
                                selUnit = null;
                                selSubunit = null;
                                selArea = null;
                                selPicId = null;
                                selPicData = null;
                              }),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _sectionPickerField(
                            label: _t('Unit', 'Unit', '单位'),
                            icon: Icons.business_rounded,
                            color: const Color(0xFF6366F1),
                            selectedName: _nameById(unitOptions, 'id_unit', 'nama_unit', selUnit),
                            onTap: () => _openSectionPicker(
                              title: _t('Select Unit', 'Pilih Unit', '选择单位'),
                              icon: Icons.business_rounded,
                              color: const Color(0xFF6366F1),
                              items: unitOptions,
                              idKey: 'id_unit',
                              nameKey: 'nama_unit',
                              selectedId: selUnit,
                              onSelect: (v) => setDlg(() {
                                selUnit = v;
                                selSubunit = null;
                                selArea = null;
                                selPicId = null;
                                selPicData = null;
                              }),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _sectionPickerField(
                            label: _t('Sub-Unit', 'Sub-Unit', '子单位'),
                            icon: Icons.layers_rounded,
                            color: const Color(0xFFFBBF24),
                            selectedName:
                                _nameById(subunitOptions, 'id_subunit', 'nama_subunit', selSubunit),
                            onTap: () => _openSectionPicker(
                              title: _t('Select Sub-Unit', 'Pilih Sub-Unit', '选择子单位'),
                              icon: Icons.layers_rounded,
                              color: const Color(0xFFFBBF24),
                              items: subunitOptions,
                              idKey: 'id_subunit',
                              nameKey: 'nama_subunit',
                              selectedId: selSubunit,
                              onSelect: (v) => setDlg(() {
                                selSubunit = v;
                                selArea = null;
                                selPicId = null;
                                selPicData = null;
                              }),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _sectionPickerField(
                            label: _t('Area', 'Area', '区域'),
                            icon: Icons.place_rounded,
                            color: const Color(0xFFF472B6),
                            selectedName: _nameById(areaOptions, 'id_area', 'nama_area', selArea),
                            onTap: () => _openSectionPicker(
                              title: _t('Select Area', 'Pilih Area', '选择区域'),
                              icon: Icons.place_rounded,
                              color: const Color(0xFFF472B6),
                              items: areaOptions,
                              idKey: 'id_area',
                              nameKey: 'nama_area',
                              selectedId: selArea,
                              onSelect: (v) => setDlg(() {
                                selArea = v;
                                selPicId = null;
                                selPicData = null;
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
                                style: GoogleFonts.poppins(
                                    fontSize: 12, fontWeight: FontWeight.w700, color: _C.primary),
                              ),
                              const SizedBox(width: 3),
                              Text('*',
                                  style: GoogleFonts.poppins(
                                      color: _C.red, fontSize: 13, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasMapping
                                ? _t('Only users at the selected location can be assigned.',
                                    'Hanya pengguna pada lokasi terpilih yang bisa ditugaskan.', '只能指派所选位置的用户。')
                                : _t('Select a Location Mapping level above first.',
                                    'Pilih salah satu level Pemetaan Lokasi di atas terlebih dahulu.', '请先选择上方的位置映射级别。'),
                            style: GoogleFonts.poppins(fontSize: 10, color: _C.textSub),
                          ),
                          const SizedBox(height: 6),
                          _buildPicField(
                            enabled: hasMapping,
                            picData: selPicData,
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
                                        excludeSectionId: existing?['id_section']?.toString(),
                                        selectedUserId: selPicId,
                                      ),
                                    );
                                    if (result != null) {
                                      setDlg(() {
                                        selPicId = result['id_user']?.toString();
                                        selPicData = result;
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
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, -2)),
                      ],
                    ),
                    child: Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSaving ? null : () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _C.divider),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: Text(
                            _t('Cancel', 'Batal', '取消'),
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w600, color: _C.textSub),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final text = namaCtrl.text.trim();
                                  final hasMapping = selLokasi != null ||
                                      selUnit != null ||
                                      selSubunit != null ||
                                      selArea != null;

                                  final missing = <MissingFieldItem>[];
                                  if (text.isEmpty) {
                                    missing.add(MissingFieldItem(
                                      icon: Icons.badge_rounded,
                                      label: _t('Section Name', 'Nama Section', '部门名称'),
                                    ));
                                  }
                                  if (!hasMapping) {
                                    missing.add(MissingFieldItem(
                                      icon: Icons.map_rounded,
                                      label: _t('Location Mapping', 'Pemetaan Lokasi', '位置映射'),
                                    ));
                                  }
                                  if (selPicId == null) {
                                    missing.add(MissingFieldItem(
                                      icon: Icons.badge_rounded,
                                      label: _t('Person in Charge', 'Penanggung Jawab', '负责人'),
                                    ));
                                  }
                                  if (missing.isNotEmpty) {
                                    RequiredFieldAlert.show(
                                      context,
                                      lang: widget.lang,
                                      missingFields: missing,
                                    );
                                    return;
                                  }

                                  setDlg(() => isSaving = true);
                                  try {
                                    final isDup = _sections.any((s) =>
                                        (s['nama_section_id']?.toString().trim().toLowerCase() ?? '') ==
                                            text.toLowerCase() &&
                                        (!isEdit || s['id_section'] != existing['id_section']));
                                    if (isDup) {
                                      setDlg(() => isSaving = false);
                                      _showSuccessPopup(
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
                                    final namaTranslated = await TranslationHelper.instance
                                        .translateDescriptionAllLangs(text, widget.lang);
                                    final descSource = descCtrl.text.trim();
                                    Map<String, String> descTranslated = {'id': '', 'en': '', 'zh': ''};
                                    if (descSource.isNotEmpty) {
                                      descTranslated = await TranslationHelper.instance
                                          .translateDescriptionAllLangs(descSource, widget.lang);
                                    }
                                    final data = {
                                      'nama_section_id': namaTranslated['id'],
                                      'nama_section_en': namaTranslated['en'],
                                      'nama_section_zh': namaTranslated['zh'],
                                      'deskripsi_section':
                                          descTranslated['id']!.isEmpty ? null : descTranslated['id'],
                                      'deskripsi_section_en':
                                          descTranslated['en']!.isEmpty ? null : descTranslated['en'],
                                      'deskripsi_section_zh':
                                          descTranslated['zh']!.isEmpty ? null : descTranslated['zh'],
                                      'gambar_section': gambarUrl,
                                      'id_lokasi': selLokasi,
                                      'id_unit': selUnit,
                                      'id_subunit': selSubunit,
                                      'id_area': selArea,
                                      'id_pic': selPicId,
                                    };
                                    if (isEdit) {
                                      await _supabase
                                          .from('section')
                                          .update(data)
                                          .eq('id_section', existing['id_section']);
                                    } else {
                                      await _supabase.from('section').insert({
                                        ...data,
                                        'urutan': _sections.length + 1,
                                      });
                                    }
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    await _fetchAll();
                                    _showSuccessPopup(
                                      isSuccess: true,
                                      titleEn: isEdit ? 'Section Updated!' : 'Section Added!',
                                      titleId: isEdit ? 'Section Diperbarui!' : 'Section Ditambahkan!',
                                      titleZh: isEdit ? '部门已更新！' : '部门已添加！',
                                      msgEn: isEdit
                                          ? 'Section has been updated successfully.'
                                          : 'New section has been saved successfully.',
                                      msgId: isEdit
                                          ? 'Section berhasil diperbarui.'
                                          : 'Section baru berhasil disimpan.',
                                      msgZh: isEdit ? '部门已成功更新。' : '新部门已成功保存。',
                                    );
                                  } catch (e) {
                                    debugPrint('Error save section: $e');
                                    if (ctx.mounted) setDlg(() => isSaving = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _C.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: isSaving
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _t('Saving...', 'Menyimpan...', '保存中...'),
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white),
                                    ),
                                  ],
                                )
                              : Text(
                                  _t('Save', 'Simpan', '保存'),
                                  style: GoogleFonts.poppins(
                                      fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          );
        },
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
                        fontSize: 16, fontWeight: FontWeight.w700, color: _C.textMain),
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
              onTap: () => _showFormDialog(),
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
                              fontSize: 10, color: Colors.white.withValues(alpha: 0.82)),
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
                ? const Center(child: CircularProgressIndicator(color: _C.primary, strokeWidth: 2))
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
                                    onEdit: (it) => _showFormDialog(existing: it),
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
                                    onTap: () => _showFormDialog(existing: item),
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
                Container(
                  width: 64,
                  height: 64,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: _C.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: (gambarUrl != null && gambarUrl.isNotEmpty)
                      ? Image.network(
                          gambarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.dashboard_customize_rounded, color: _C.primary, size: 28),
                        )
                      : const Icon(Icons.dashboard_customize_rounded, color: _C.primary, size: 28),
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

// --------------------------------------------------------------------
// Popup picker generik untuk Lokasi/Unit/Sub-Unit/Area
// --------------------------------------------------------------------
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
          : widget.items
              .where((e) => (e[widget.nameKey]?.toString() ?? '').toLowerCase().contains(q))
              .toList();
    });
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
          maxWidth: 420,
        ),
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
                      decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                      child: Icon(widget.icon, color: widget.color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: widget.color),
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
                    ..._filtered.map((item) => _buildItemCard(context, item)),
                    if (_filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(_t('No results found', 'Tidak ada hasil', '没有结果'),
                              style: GoogleFonts.poppins(color: Colors.grey.shade500)),
                        ),
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
// Popup pilih PIC Section: difilter berdasarkan level lokasi paling
// spesifik yang sudah dipilih di form (Area > Sub-Unit > Unit > Lokasi),
// mengecualikan user yang sudah jadi PIC di lokasi/unit/subunit/area/
// section lain.
// --------------------------------------------------------------------
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
          .where((u) =>
              !excluded.contains(u['id_user']?.toString()) ||
              u['id_user']?.toString() == widget.selectedUserId)
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
        final matchesRole = _roleFilterId == null || u['id_jabatan'] == _roleFilterId;
        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  Future<void> _openRoleFilter() async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _SectionRoleFilterDialog(lang: widget.lang, selectedId: _roleFilterId),
    );
    if (result != null) {
      setState(() {
        if (result.isEmpty) {
          _roleFilterId = null;
          _roleFilterName = null;
        } else {
          _roleFilterId = result['id_jabatan'] as int?;
          _roleFilterName = result['nama_jabatan']?.toString();
        }
      });
      _applyFilter();
    }
  }

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
                  child: Icon(Icons.filter_list_rounded,
                      color: _roleFilterId != null ? Colors.white : _C.primary, size: 20),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, bottom: 4),
            child: Row(children: [
              Text('${_filtered.length} ${_t('users', 'pengguna', '位用户')}',
                  style: GoogleFonts.poppins(fontSize: 11, color: _C.textSub)),
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
                ? const Center(child: CircularProgressIndicator(color: _C.primary, strokeWidth: 2))
                : _filtered.isEmpty
                    ? Center(
                        child: Text(_t('No users found', 'Pengguna tidak ditemukan', '未找到用户'),
                            style: GoogleFonts.poppins(fontSize: 12.5, color: _C.textSub)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 6, bottom: 12),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final item = _filtered[i];
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
                                border: Border.all(
                                    color: isSelected ? _C.primary : _C.divider, width: isSelected ? 1.5 : 1),
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
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                              color: isSelected ? _C.primary : _C.textMain)),
                                      const SizedBox(height: 4),
                                      buildJabatanBadge(
                                          idJabatan: idJabatan,
                                          jabatanNama: jabatanNama,
                                          isVerificator: isVerificator,
                                          lang: widget.lang),
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
        ]),
      ),
    );
  }
}

// --------------------------------------------------------------------
// Popup filter Jabatan (role) untuk picker PIC di atas
// --------------------------------------------------------------------
class _SectionRoleFilterDialog extends StatefulWidget {
  final String lang;
  final int? selectedId;
  const _SectionRoleFilterDialog({required this.lang, required this.selectedId});

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
      final res = await _supabase.from('jabatan').select('id_jabatan, nama_jabatan').order('id_jabatan');
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
                ? const Center(child: CircularProgressIndicator(color: _C.primary, strokeWidth: 2))
                : ListView(
                    padding: const EdgeInsets.only(top: 6, bottom: 12),
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context, <String, dynamic>{}),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: widget.selectedId == null ? _C.primaryLt : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: widget.selectedId == null ? _C.primary : _C.divider,
                                width: widget.selectedId == null ? 1.5 : 1),
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
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
                          ]),
                        ),
                      ),
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
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? color : _C.textMain)),
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