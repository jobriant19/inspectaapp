import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

/// Helper untuk membuka galeri lokal HP (bukan Google Photos)
/// di Android release build.
class ImagePickerHelper {
  static final _picker = ImagePicker();

  /// Gunakan ini sebagai pengganti langsung:
  /// `_picker.pickImage(source: ImageSource.gallery)`
  static Future<XFile?> pickImageFromGallery({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      // Pada Android, requestFullMetadata: false + imageQuality
      // mendorong sistem membuka file picker biasa, bukan Google Photos.
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        requestFullMetadata: false, // ← kunci utama: bypass Google Photos
      );
      return image;
    } catch (e) {
      debugPrint('ImagePickerHelper error: $e');
      return null;
    }
  }
}