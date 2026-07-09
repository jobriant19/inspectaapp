import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/services/location_service.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// LocationPermissionPopup
/// Popup custom Inspecta yang tampil SEBELUM dialog izin lokasi asli
/// dari browser/OS muncul. Fungsinya menjelaskan ke user kenapa lokasi
/// dibutuhkan dengan tampilan yang lebih menarik & branded, dibanding
/// langsung menampilkan dialog native browser yang menampilkan URL mentah.
///
/// Setelah user memilih sekali (Izinkan / Nanti Saja), popup ini TIDAK
/// akan muncul lagi di sesi-sesi berikutnya — status izin selanjutnya
/// murni mengikuti keputusan asli dari OS/browser (konsisten & permanen).
/// ─────────────────────────────────────────────────────────────────────────
class LocationPermissionPopup {
  static const String _prefKeyPrimed = 'location_permission_primed';

  /// Panggil ini menggantikan LocationService.instance.checkUserAtAtmi()
  /// secara langsung. Akan otomatis menampilkan popup custom HANYA jika
  /// izin lokasi belum pernah diputuskan & popup belum pernah ditampilkan.
  static Future<LocationCheckResult> requestWithPopup(
    BuildContext context, {
    String lang = 'ID',
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final currentPermission = await Geolocator.checkPermission();

    // Jika izin sudah pernah diputuskan (granted / denied forever) atau
    // GPS mati, langsung proses seperti biasa tanpa popup custom apapun.
    final bool alreadyDecided = !serviceEnabled ||
        currentPermission == LocationPermission.always ||
        currentPermission == LocationPermission.whileInUse ||
        currentPermission == LocationPermission.deniedForever;

    if (alreadyDecided) {
      return LocationService.instance.checkUserAtAtmi(forceRefresh: true);
    }

    final prefs = await SharedPreferences.getInstance();
    final bool alreadyPrimed = prefs.getBool(_prefKeyPrimed) ?? false;

    if (alreadyPrimed) {
      // Sudah pernah lihat popup custom sebelumnya → langsung proses.
      return LocationService.instance.checkUserAtAtmi(forceRefresh: true);
    }

    if (!context.mounted) {
      return LocationService.instance.checkUserAtAtmi(forceRefresh: true);
    }

    final bool? proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: true, // tap di luar area popup = close
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _LocationPermissionDialog(lang: lang),
    );

    // Tandai sudah pernah di-primed, apapun pilihannya, agar popup
    // custom ini tidak muncul berulang-ulang selamanya.
    await prefs.setBool(_prefKeyPrimed, true);

    if (proceed != true) {
      return const LocationCheckResult(
        isGranted: false,
        isAtAtmi: false,
        distance: null,
        reason: 'permission_denied',
      );
    }

    return LocationService.instance.checkUserAtAtmi(forceRefresh: true);
  }
}

class _LocationPermissionDialog extends StatelessWidget {
  final String lang;
  const _LocationPermissionDialog({required this.lang});

  static const Color _primaryColor = Color(0xFF1D72F3);

  static const Map<String, Map<String, String>> _texts = {
    'EN': {
      'title': 'Inspecta Wants to Access\nYour Location',
      'desc':
          'We use your location to make sure you are within the PT ATMI Solo area when creating findings or audits.',
      'allow': 'Allow Location Access',
      'later': 'Not Now',
    },
    'ID': {
      'title': 'Inspecta Ingin Mengakses\nLokasi Anda',
      'desc':
          'Kami menggunakan lokasi Anda untuk memastikan Anda berada di area PT ATMI Solo saat membuat temuan atau audit.',
      'allow': 'Izinkan Akses Lokasi',
      'later': 'Nanti Saja',
    },
    'ZH': {
      'title': 'Inspecta 想要访问\n您的位置',
      'desc': '我们使用您的位置信息，以确保您在创建发现或审计时位于 PT ATMI Solo 区域内。',
      'allow': '允许访问位置',
      'later': '暂不允许',
    },
  };

  String _t(String key) => _texts[lang]?[key] ?? _texts['ID']![key]!;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withValues(alpha: 0.25),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Tombol close (X) ──
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 12),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: _primaryColor),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Icon lokasi bulat gradient ──
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF64B5F6), _primaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        color: Colors.white, size: 38),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    _t('title'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    _t('desc'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Tombol Izinkan ──
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.my_location_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _t('allow'),
                            style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Tombol Nanti Saja ──
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        _t('later'),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
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