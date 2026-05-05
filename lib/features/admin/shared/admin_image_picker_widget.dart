// ============================================================
// FILE BARU: lib/features/admin/shared/admin_image_picker_widget.dart
//
// Widget reusable untuk memilih gambar (kamera / galeri) di
// admin screen — menggantikan input URL teks.
// Dipakai oleh admin_user_screen.dart & admin_location_screen.dart
// ============================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Hasil upload gambar
class ImageUploadResult {
  final String publicUrl;
  const ImageUploadResult(this.publicUrl);
}

// ─────────────────────────────────────────────────────────────
// AdminImagePickerWidget
// Tampilkan preview gambar + tombol ganti via kamera/galeri.
// Setelah user memilih, gambar di-upload ke Supabase Storage
// dan [onUploaded] dipanggil dengan URL publiknya.
// ─────────────────────────────────────────────────────────────
class AdminImagePickerWidget extends StatefulWidget {
  /// URL gambar saat ini (bisa null jika belum ada)
  final String? currentImageUrl;

  /// Bucket Supabase Storage target, misal: 'avatars' atau 'locations'
  final String storageBucket;

  /// Subfolder dalam bucket, misal: 'user' | 'lokasi' | 'unit'
  final String storageFolder;

  /// Dipanggil setelah upload berhasil dengan URL publik baru
  final void Function(String newUrl) onUploaded;

  /// Label / hint yang muncul saat belum ada gambar
  final String? hint;

  /// Tinggi area gambar
  final double height;

  /// Bentuk: circle (untuk avatar user) atau rectangle (untuk lokasi)
  final bool isCircle;

  /// Widget icon / placeholder saat belum ada gambar
  final Widget? placeholder;

  /// Nama file unik prefix, misal: id_user / id_lokasi
  final String filePrefix;

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
  });

  @override
  State<AdminImagePickerWidget> createState() =>
      _AdminImagePickerWidgetState();
}

class _AdminImagePickerWidgetState extends State<AdminImagePickerWidget> {
  Uint8List? _previewBytes;
  bool _isUploading = false;

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
    final ext   = picked.name.split('.').last.toLowerCase();

    setState(() {
      _previewBytes = bytes;
      _isUploading  = true;
    });

    try {
      final fileName =
          '${widget.filePrefix}-${DateTime.now().millisecondsSinceEpoch}.$ext';
      final filePath = '${widget.storageFolder}/$fileName';

      final contentType = switch (ext) {
        'png'  => 'image/png',
        'gif'  => 'image/gif',
        'webp' => 'image/webp',
        _      => 'image/jpeg',
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
            content: Text('Upload gagal: $e'),
            backgroundColor: Colors.red,
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
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Sumber Gambar',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 15,
                    color: const Color(0xFF1E3A8A)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Kamera',
                      color: const Color(0xFF0891B2),
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
                      label: 'Galeri',
                      color: const Color(0xFF6366F1),
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

  // ── Circle (untuk user avatar) ──
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
                      offset: const Offset(0, 4)),
                ],
              ),
              child: CircleAvatar(
                radius: widget.height / 2,
                backgroundColor: const Color(0xFFEDE9FE),
                backgroundImage: _previewBytes != null
                    ? MemoryImage(_previewBytes!) as ImageProvider
                    : (widget.currentImageUrl?.isNotEmpty ?? false)
                        ? CachedNetworkImageProvider(widget.currentImageUrl!)
                        : null,
                child: !hasImage
                    ? widget.placeholder ??
                        const Icon(Icons.person, size: 40,
                            color: Color(0xFF6366F1))
                    : null,
              ),
            ),
            if (_isUploading)
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFF6366F1), width: 2),
                ),
                child: const Icon(Icons.camera_alt,
                    color: Color(0xFF6366F1), size: 16),
              ),
          ],
        ),
      ),
    );
  }

  // ── Rectangle (untuk gambar lokasi) ──
  Widget _buildRectangle(bool hasImage) {
    return GestureDetector(
      onTap: _showSourceDialog,
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            width: 1.5,
          ),
          image: (_previewBytes != null)
              ? DecorationImage(
                  image: MemoryImage(_previewBytes!), fit: BoxFit.cover)
              : (widget.currentImageUrl?.isNotEmpty ?? false)
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(
                          widget.currentImageUrl!),
                      fit: BoxFit.cover)
                  : null,
        ),
        child: _isUploading
            ? const Center(child: CircularProgressIndicator())
            : !hasImage
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_rounded,
                          size: 40,
                          color: const Color(0xFF6366F1).withOpacity(0.5)),
                      const SizedBox(height: 8),
                      Text(
                        widget.hint ?? 'Tap untuk pilih gambar',
                        style: GoogleFonts.poppins(
                            color: Colors.black38, fontSize: 13),
                      ),
                    ],
                  )
                : Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Helper tombol sumber gambar
// ─────────────────────────────────────────
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
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}