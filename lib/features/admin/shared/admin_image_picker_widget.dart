import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminImagePickerWidget extends StatefulWidget {
  final String? currentImageUrl;
  final String storageBucket;
  final String storageFolder;
  final void Function(String newUrl) onUploaded;
  final String? hint;
  final double height;
  final bool isCircle;
  final Widget? placeholder;
  final String filePrefix;
  final Color? accentColor;
  final String? subHint;
  final String? uploadingText;
  final String? changeText;
  final String? sourceTitleText;
  final String? cameraText;
  final String? galleryText;

  const AdminImagePickerWidget({
    super.key,
    required this.currentImageUrl,
    required this.storageBucket,
    required this.storageFolder,
    required this.onUploaded,
    required this.filePrefix,
    this.hint,
    this.height = 160,
    this.isCircle = false,
    this.placeholder,
    this.accentColor,
    this.subHint,
    this.uploadingText,
    this.changeText,
    this.sourceTitleText,
    this.cameraText,
    this.galleryText,
  });

  @override
  State<AdminImagePickerWidget> createState() =>
      _AdminImagePickerWidgetState();
}

class _AdminImagePickerWidgetState extends State<AdminImagePickerWidget> {
  Uint8List? _previewBytes;
  bool _isUploading = false;

  // Warna aksen: gunakan accentColor jika ada, fallback ke indigo
  Color get _accent => widget.accentColor ?? const Color(0xFF6366F1);

  Future<void> _pickAndUpload(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final ext = picked.name.split('.').last.toLowerCase();

    setState(() {
      _previewBytes = bytes;
      _isUploading = true;
    });

    try {
      final fileName =
          '${widget.filePrefix}-${DateTime.now().millisecondsSinceEpoch}.$ext';
      final filePath = '${widget.storageFolder}/$fileName';

      final contentType = switch (ext) {
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

      await Supabase.instance.client.storage
          .from(widget.storageBucket)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions:
                FileOptions(contentType: contentType, upsert: true),
          );

      final publicUrl = Supabase.instance.client.storage
          .from(widget.storageBucket)
          .getPublicUrl(filePath);

      widget.onUploaded(publicUrl);
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Upload gagal: $e',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.sourceTitleText ?? 'Pilih Sumber Gambar',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.camera_alt_rounded,
                      label: widget.cameraText ?? 'Kamera',
                      color: _accent,
                      onTap: () {
                        Navigator.pop(context);
                        _pickAndUpload(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.photo_library_rounded,
                      label: widget.galleryText ?? 'Galeri',
                      color: _accent,
                      onTap: () {
                        Navigator.pop(context);
                        _pickAndUpload(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage =
        _previewBytes != null || (widget.currentImageUrl?.isNotEmpty ?? false);

    if (widget.isCircle) {
      return _buildCircleAvatar(hasImage);
    }
    return _buildRectangle(hasImage);
  }

  Widget _buildCircleAvatar(bool hasImage) {
    return Center(
      child: GestureDetector(
        onTap: _showSourceDialog,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: widget.height / 2,
                backgroundColor: _accent.withOpacity(0.12),
                backgroundImage: _previewBytes != null
                    ? MemoryImage(_previewBytes!) as ImageProvider
                    : (widget.currentImageUrl?.isNotEmpty ?? false)
                        ? CachedNetworkImageProvider(widget.currentImageUrl!)
                        : null,
                child: !hasImage
                    ? widget.placeholder ??
                        Icon(Icons.person, size: 40, color: _accent)
                    : null,
              ),
            ),
            if (_isUploading)
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _accent),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _accent, width: 2),
                ),
                child: Icon(Icons.camera_alt, color: _accent, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRectangle(bool hasImage) {
    return GestureDetector(
      onTap: _isUploading ? null : _showSourceDialog,
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _accent.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _accent.withOpacity(0.35),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _isUploading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
                    const SizedBox(height: 10),
                    Text(
                      widget.uploadingText ?? 'Mengunggah...',
                      style: GoogleFonts.poppins(
                          color: _accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )
            : hasImage
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      // ── Gambar preview ──
                      _previewBytes != null
                          ? Image.memory(_previewBytes!, fit: BoxFit.cover)
                          : CachedNetworkImage(
                              imageUrl: widget.currentImageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Center(
                                child: CircularProgressIndicator(
                                    color: _accent, strokeWidth: 2),
                              ),
                              errorWidget: (_, __, ___) => Center(
                                child: Icon(Icons.broken_image_rounded,
                                    color: Colors.grey.shade400, size: 40),
                              ),
                            ),
                      // ── Overlay tombol ganti ──
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.edit_rounded,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                widget.changeText ?? 'Ganti Gambar',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 32,
                          color: _accent,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.hint ?? 'Tap untuk pilih gambar',
                        style: GoogleFonts.poppins(
                          color: _accent.withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subHint ?? 'Kamera atau Galeri',
                        style: GoogleFonts.poppins(
                          color: Colors.black38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}