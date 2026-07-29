import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/translation_service.dart';
import '../../../user/home/alert/required_field_alert.dart';
import '../../user/filter/admin_user_filter.dart';
import 'admin_location_indicator.dart';
import 'camera/admin_location_camera.dart';

class _C {
  static const primary   = Color(0xFF10B981);
  static const primaryLt = Color(0xFFD1FAE5);
  static const red       = Color(0xFFEF4444);
  static const textMain  = Color(0xFF1E3A8A);
  static const textSub   = Color(0xFF64748B);
  static const divider   = Color(0xFFE2E8F0);
  static const surface   = Color(0xFFF8FAFC);
}

class AdminAddLocationDialog extends StatefulWidget {
  final String lang;
  final Future<void> Function() onSaved;

  const AdminAddLocationDialog({
    super.key,
    required this.lang,
    required this.onSaved,
  });

  @override
  State<AdminAddLocationDialog> createState() => _AdminAddLocationDialogState();
}

class _AdminAddLocationDialogState extends State<AdminAddLocationDialog> {
  final _supabase = Supabase.instance.client;

  late final TextEditingController _namaCtrl;
  late final TextEditingController _descCtrl;

  String? _gambarUrl;
  Uint8List? _previewBytes;

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

  Widget _buildLocationPhotoPicker({
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
        pageBuilder: (_, __, ___) => _LocationFullscreenImageViewer(
          imageUrl: url ?? '',
          previewBytes: _previewBytes,
        ),
      ),
    );
  }

  Future<void> _openLocationCamera() async {
    final XFile? picked = await Navigator.push<XFile?>(
      context,
      MaterialPageRoute(builder: (_) => AdminLocationCameraScreen(lang: widget.lang)),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdminLocationCameraWarmupService.instance.warmUp();
    });
    if (picked == null) return;
    await _processPickedImage(picked);
  }

  Future<void> _processPickedImage(XFile picked) async {
    final bytes = await picked.readAsBytes();
    setState(() {
      _previewBytes = bytes;
    });

    try {
      final ext = picked.name.split('.').last.toLowerCase();
      final safeExt = ext.isEmpty ? 'jpg' : ext;
      final fileName = 'new-lokasi-${DateTime.now().millisecondsSinceEpoch}.$safeExt';
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
      await _supabase.storage
          .from('lokasi-images')
          .uploadBinary(filePath, bytes, fileOptions: FileOptions(contentType: contentType, upsert: true));
      final newUrl = _supabase.storage.from('lokasi-images').getPublicUrl(filePath);
      setState(() {
        _gambarUrl = newUrl;
      });
    } catch (e) {
      debugPrint('Error uploading location photo: $e');
    }
  }

  Widget _buildPicField() {
    final hasValue = _selPicData != null;
    final name = _selPicData?['nama']?.toString() ?? '';
    final avatarUrl = _selPicData?['gambar_user']?.toString();
    final idJabatan = _selPicData?['id_jabatan'] as int?;
    final isVerificator = _selPicData?['is_verificator'] as bool?;
    final jabatanRaw = _selPicData?['jabatan'];
    final jabatanNama = jabatanRaw is Map ? jabatanRaw['nama_jabatan']?.toString() : null;

    return GestureDetector(
      onTap: _openPicPicker,
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
                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
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
                        buildAdminRoleBadge(
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
                      _t('Select PIC', 'Pilih PIC', '选择负责人'),
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.black38),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black26, size: 18),
                ],
              ),
      ),
    );
  }

  Future<void> _openPicPicker() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (dCtx) => _LocationPicPickerDialog(
        lang: widget.lang,
        selectedUserId: _selPicId,
      ),
    );
    if (result != null) {
      setState(() {
        _selPicId = result['id_user']?.toString();
        _selPicData = result;
      });
    }
  }

  Future<void> _handleSave() async {
    final text = _namaCtrl.text.trim();

    final missing = <MissingFieldItem>[];
    if (text.isEmpty) {
      missing.add(MissingFieldItem(icon: Icons.location_city_rounded, label: _t('Location Name', 'Nama Lokasi', '位置名称')));
    }
    if (_selPicId == null) {
      missing.add(MissingFieldItem(icon: Icons.badge_rounded, label: _t('Person in Charge', 'Penanggung Jawab', '负责人')));
    }
    if (missing.isNotEmpty) {
      RequiredFieldAlert.show(context, lang: widget.lang, missingFields: missing);
      return;
    }

    setState(() => _isSaving = true);

    final descSource = _descCtrl.text.trim();

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _LocationTranslatingDialog(color: _C.primary, lang: widget.lang),
      );
    }

    Map<String, String> descAll = {'id': '', 'en': '', 'zh': ''};
    if (descSource.isNotEmpty) {
      try {
        descAll = await TranslationHelper.instance.translateDescriptionAllLangs(descSource, widget.lang);
      } catch (e) {
        debugPrint('Error translating deskripsi lokasi: $e');
        descAll = {'id': descSource, 'en': descSource, 'zh': descSource};
      }
    }

    if (mounted) Navigator.of(context, rootNavigator: true).pop();

    final data = {
      'nama_lokasi': text,
      'deskripsi_lokasi': descAll['id']!.isEmpty ? null : descAll['id'],
      'deskripsi_lokasi_en': descAll['en']!.isEmpty ? null : descAll['en'],
      'deskripsi_lokasi_zh': descAll['zh']!.isEmpty ? null : descAll['zh'],
      'gambar_lokasi': _gambarUrl,
      'id_pic': _selPicId,
    };

    try {
      await _supabase.from('lokasi').insert(data);
      if (mounted) Navigator.pop(context);
      await widget.onSaved();
    } catch (e) {
      debugPrint('Error save lokasi: $e');
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  child: const Icon(Icons.location_city_rounded, color: _C.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _t('Add Location', 'Tambah Lokasi', '添加位置'),
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: _C.primary),
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
                          _t('Location Photo', 'Foto Lokasi', '位置照片'),
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _C.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildLocationPhotoPicker(
                      imageUrl: _gambarUrl,
                      previewBytes: _previewBytes,
                      onPickTap: _openLocationCamera,
                      onViewTap: _openFullscreenPreview,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Icon(Icons.location_city_rounded, size: 14, color: _C.primary),
                        const SizedBox(width: 6),
                        Text(
                          _t('Location Name', 'Nama Lokasi', '位置名称'),
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
                        hintText: _t('e.g. Building A', 'cth. Gedung A', '例如：A栋'),
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
                    const SizedBox(height: 4),
                    Text(
                      _t('Description will be auto-translated to EN / ZH.',
                          'Deskripsi akan diterjemahkan otomatis ke EN / ZH.', '描述将自动翻译为英文/中文。'),
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _C.textSub),
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
                      _t('Select a PIC for this location.',
                          'Pilih PIC untuk lokasi ini.', '请为此位置选择负责人。'),
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _C.textSub),
                    ),
                    const SizedBox(height: 6),
                    _buildPicField(),
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

class _LocationFullscreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final Uint8List? previewBytes;

  const _LocationFullscreenImageViewer({required this.imageUrl, this.previewBytes});

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

class _LocationTranslatingDialog extends StatefulWidget {
  final Color color;
  final String lang;
  const _LocationTranslatingDialog({required this.color, required this.lang});

  @override
  State<_LocationTranslatingDialog> createState() => _LocationTranslatingDialogState();
}

class _LocationTranslatingDialogState extends State<_LocationTranslatingDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.lang) {
      case 'EN':
        return 'Translating...';
      case 'ZH':
        return '翻译中...';
      default:
        return 'Menerjemahkan...';
    }
  }

  String get _subtitle {
    switch (widget.lang) {
      case 'EN':
        return 'Converting to Indonesian, English & Mandarin';
      case 'ZH':
        return '正在转换为印尼语、英语和中文';
      default:
        return 'Mengubah ke Bahasa Indonesia, Inggris & Mandarin';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = 0.90 + (_controller.value * 0.12);
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color, widget.color.withValues(alpha: 0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.translate_rounded, color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              _title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: 150,
                height: 6,
                child: LinearProgressIndicator(
                  backgroundColor: widget.color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationPicPickerDialog extends StatefulWidget {
  final String lang;
  final String? selectedUserId;

  const _LocationPicPickerDialog({
    required this.lang,
    required this.selectedUserId,
  });

  @override
  State<_LocationPicPickerDialog> createState() => _LocationPicPickerDialogState();
}

class _LocationPicPickerDialogState extends State<_LocationPicPickerDialog> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  int? _roleFilterId;
  String? _roleFilterName;
  bool _roleFilterIsVerificator = false;
  int _picCurrentPage = 1;

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

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _supabase
          .from('User')
          .select('id_user, nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)')
          .order('nama');
      final list = List<Map<String, dynamic>>.from(res)
          .where((u) => u['id_jabatan'] != 6)
          .toList();
      if (mounted) {
        setState(() {
          _items = list;
          _loading = false;
        });
        _applyFilter();
      }
    } catch (e) {
      debugPrint('Error load location PIC users: $e');
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
      _picCurrentPage = 1;
    });
  }

  Color get _activeRoleFilterColor {
    if (_roleFilterIsVerificator) return adminRoleColor(kVerificatorFilterId);
    return adminRoleColor(_roleFilterId);
  }

  IconData get _activeRoleFilterIcon {
    if (_roleFilterIsVerificator) return adminRoleIcon(kVerificatorFilterId);
    return adminRoleIcon(_roleFilterId);
  }

  void _clearRoleFilter() {
    setState(() {
      _roleFilterId = null;
      _roleFilterName = null;
      _roleFilterIsVerificator = false;
    });
    _applyFilter();
  }

  Future<void> _openRoleFilter() async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _LocationRoleFilterDialog(
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
    final int picTotalPages =
        _filtered.isEmpty ? 1 : (_filtered.length / kAdminLocationPicPageSize).ceil();
    final int picSafePage = _picCurrentPage.clamp(1, picTotalPages);
    final int picStartIdx = (picSafePage - 1) * kAdminLocationPicPageSize;
    final int picEndIdx = (picStartIdx + kAdminLocationPicPageSize) > _filtered.length
        ? _filtered.length
        : picStartIdx + kAdminLocationPicPageSize;
    final List<Map<String, dynamic>> picPageItems =
        _filtered.isEmpty ? <Map<String, dynamic>>[] : _filtered.sublist(picStartIdx, picEndIdx);
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
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: _C.primary),
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
                              onTap: () {
                                _searchCtrl.clear();
                                _applyFilter();
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
                GestureDetector(
                  onTap: _clearRoleFilter,
                  child: Container(
                    padding: const EdgeInsets.only(left: 8, right: 6, top: 3, bottom: 3),
                    decoration: BoxDecoration(
                      color: _activeRoleFilterColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _activeRoleFilterColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_activeRoleFilterIcon, size: 12, color: _activeRoleFilterColor),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 90),
                          child: Text(
                            _roleFilterName!,
                            style: GoogleFonts.poppins(
                                fontSize: 10, fontWeight: FontWeight.w700, color: _activeRoleFilterColor),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(Icons.close_rounded, size: 13, color: _activeRoleFilterColor),
                      ],
                    ),
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
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/team_illustration.png',
                                height: 110,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: _C.primary.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.person_search_rounded,
                                      size: 30, color: _C.primary.withValues(alpha: 0.4)),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _t('No Users Found', 'Pengguna Tidak Ditemukan', '未找到用户'),
                                style: GoogleFonts.poppins(
                                    fontSize: 13, fontWeight: FontWeight.w700, color: _C.textMain),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _t(
                                  'Try adjusting your search keyword or role filter.',
                                  'Coba ubah kata kunci pencarian atau filter role.',
                                  '请尝试调整搜索关键词或角色筛选。',
                                ),
                                style: GoogleFonts.poppins(
                                    fontSize: 11, fontWeight: FontWeight.w600, color: _C.textSub, height: 1.5),
                                textAlign: TextAlign.center,
                              ),
                              if (_searchCtrl.text.isNotEmpty || _roleFilterId != null) ...[
                                const SizedBox(height: 14),
                                GestureDetector(
                                  onTap: () {
                                    _searchCtrl.clear();
                                    setState(() {
                                      _roleFilterId = null;
                                      _roleFilterName = null;
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
                                        Icon(Icons.refresh_rounded, size: 14, color: _C.primary),
                                        const SizedBox(width: 6),
                                        Text(
                                          _t('Clear search & filter', 'Hapus pencarian & filter', '清除搜索与筛选'),
                                          style: GoogleFonts.poppins(
                                              fontSize: 11, fontWeight: FontWeight.w700, color: _C.primary),
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
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 6, bottom: 12),
                        itemCount: picPageItems.length,
                        itemBuilder: (_, i) {
                          final item = picPageItems[i];
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
                                      buildAdminRoleBadge(
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
          if (!_loading && picTotalPages > 1)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 10),
              child: AdminLocationPageIndicator(
                currentPage: picSafePage,
                totalPages: picTotalPages,
                onPageChanged: (p) => setState(() => _picCurrentPage = p),
                color: _C.primary,
                horizontalMargin: 14,
              ),
            ),
        ]),
      ),
    );
  }
}

class _LocationRoleFilterDialog extends StatefulWidget {
  final String lang;
  final int? selectedId;
  final bool isVerificatorSelected;
  const _LocationRoleFilterDialog({
    required this.lang,
    required this.selectedId,
    this.isVerificatorSelected = false,
  });

  @override
  State<_LocationRoleFilterDialog> createState() => _LocationRoleFilterDialogState();
}

class _LocationRoleFilterDialogState extends State<_LocationRoleFilterDialog> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _allRoles = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;

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
    List<Map<String, dynamic>> jabatanList = [];
    try {
      final res = await _supabase
          .from('jabatan')
          .select('id_jabatan, nama_jabatan')
          .order('id_jabatan', ascending: true);
      jabatanList = List<Map<String, dynamic>>.from(res)
          .where((j) => j['id_jabatan'] != 6)
          .toList();
    } catch (e) {
      debugPrint('Error load jabatan: $e');
      jabatanList = [];
    }
    _allRoles = [
      ...jabatanList,
      {
        'id_jabatan': null,
        'nama_jabatan': _t('Verificator', 'Verifikator', '验证员'),
        'is_verificator': true,
      },
    ];
    _filtered = List.from(_allRoles);
    if (mounted) setState(() => _loading = false);
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_allRoles)
          : _allRoles
              .where((e) => (e['nama_jabatan'] ?? '').toString().toLowerCase().contains(q))
              .toList();
    });
  }

  void _resetSearch() {
    _searchCtrl.clear();
  }

  Color _colorForItem(Map<String, dynamic> item) {
    if (item['is_verificator'] == true) return adminRoleColor(kVerificatorFilterId);
    return adminRoleColor(item['id_jabatan'] as int?);
  }

  IconData _iconForItem(Map<String, dynamic> item) {
    if (item['is_verificator'] == true) return adminRoleIcon(kVerificatorFilterId);
    return adminRoleIcon(item['id_jabatan'] as int?);
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
                child: const Icon(Icons.badge_rounded, color: _C.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(_t('Select Role', 'Pilih Role', '选择角色'),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: _C.primary)),
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
                      if (_filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/team_illustration.png',
                                height: 100,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: _C.primary.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.badge_rounded,
                                      size: 28, color: _C.primary.withValues(alpha: 0.4)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _t('No Roles Found', 'Role Tidak Ditemukan', '未找到角色'),
                                style: GoogleFonts.poppins(
                                    fontSize: 13, fontWeight: FontWeight.w700, color: _C.textMain),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _t(
                                  'Try adjusting your search keyword.',
                                  'Coba ubah kata kunci pencarian.',
                                  '请尝试调整搜索关键词。',
                                ),
                                style: GoogleFonts.poppins(
                                    fontSize: 11, fontWeight: FontWeight.w600, color: _C.textSub, height: 1.5),
                                textAlign: TextAlign.center,
                              ),
                              if (_searchCtrl.text.isNotEmpty) ...[
                                const SizedBox(height: 12),
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
                                        Icon(Icons.refresh_rounded, size: 14, color: _C.primary),
                                        const SizedBox(width: 6),
                                        Text(
                                          _t('Clear search', 'Hapus pencarian', '清除搜索'),
                                          style: GoogleFonts.poppins(
                                              fontSize: 11, fontWeight: FontWeight.w700, color: _C.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      else
                        ..._filtered.map((item) {
                          final isVerif = item['is_verificator'] == true;
                          final id = item['id_jabatan'] as int?;
                          final nama = item['nama_jabatan']?.toString() ?? '-';
                          final isSelected = isVerif
                              ? widget.isVerificatorSelected
                              : (id != null && id == widget.selectedId);
                          final color = _colorForItem(item);
                          final icon = _iconForItem(item);
                          return InkWell(
                            onTap: () => Navigator.pop(
                              context,
                              isVerif ? <String, dynamic>{'is_verificator': true} : item,
                            ),
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
                                  child: Icon(icon, size: 17, color: color),
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