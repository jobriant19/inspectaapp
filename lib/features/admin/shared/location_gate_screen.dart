import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/location_service.dart';

class LocationGateScreen extends StatefulWidget {
  final String lang;
  final VoidCallback onAccessGranted;

  const LocationGateScreen({
    super.key,
    required this.lang,
    required this.onAccessGranted,
  });

  @override
  State<LocationGateScreen> createState() => _LocationGateScreenState();
}

class _LocationGateScreenState extends State<LocationGateScreen> {
  bool _isChecking = false;
  String? _errorReason;
  double? _distance;

  static const Map<String, Map<String, String>> _texts = {
    'EN': {
      'title': 'Location Access Required',
      'subtitle': 'This app can only be used within the PT ATMI Solo area.',
      'checking': 'Checking your location...',
      'btn_check': 'Check My Location',
      'btn_retry': 'Try Again',
      'out_of_range': 'You are outside the PT ATMI Solo area.',
      'distance_info': 'Your distance from ATMI',
      'permission_denied': 'Location permission was denied.\nPlease allow location access in your device settings.',
      'error': 'Failed to get location.\nPlease ensure GPS is enabled.',
      'open_settings': 'Open Settings',
      'meters': 'meters away',
    },
    'ID': {
      'title': 'Akses Lokasi Diperlukan',
      'subtitle': 'Aplikasi ini hanya dapat digunakan di area PT ATMI Solo.',
      'checking': 'Memeriksa lokasi Anda...',
      'btn_check': 'Periksa Lokasi Saya',
      'btn_retry': 'Coba Lagi',
      'out_of_range': 'Anda berada di luar area PT ATMI Solo.',
      'distance_info': 'Jarak Anda dari ATMI',
      'permission_denied': 'Izin lokasi ditolak.\nSilakan izinkan akses lokasi di pengaturan perangkat Anda.',
      'error': 'Gagal mendapatkan lokasi.\nPastikan GPS aktif.',
      'open_settings': 'Buka Pengaturan',
      'meters': 'meter dari ATMI',
    },
    'ZH': {
      'title': '需要位置访问权限',
      'subtitle': '此应用仅可在PT ATMI Solo区域内使用。',
      'checking': '正在检查您的位置...',
      'btn_check': '检查我的位置',
      'btn_retry': '重试',
      'out_of_range': '您在PT ATMI Solo区域之外。',
      'distance_info': '您与ATMI的距离',
      'permission_denied': '位置权限被拒绝。\n请在设备设置中允许位置访问。',
      'error': '无法获取位置。\n请确保GPS已启用。',
      'open_settings': '打开设置',
      'meters': '米外',
    },
  };

  String _t(String key) => _texts[widget.lang]?[key] ?? _texts['ID']![key]!;

  Future<void> _checkLocation() async {
    setState(() {
      _isChecking = true;
      _errorReason = null;
      _distance = null;
    });

    final result = await LocationService.instance.checkUserAtAtmi();

    if (!mounted) return;

    if (result.isAtAtmi) {
      widget.onAccessGranted();
      return;
    }

    setState(() {
      _isChecking = false;
      _errorReason = result.reason;
      _distance = result.distance;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ikon lokasi
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00C9E4).withOpacity(0.1),
                  border: Border.all(
                    color: const Color(0xFF00C9E4).withOpacity(0.3), width: 2),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF00C9E4),
                  size: 60,
                ),
              ),
              const SizedBox(height: 28),

              Text(
                _t('title'),
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E3A8A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _t('subtitle'),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Error state
              if (_errorReason != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _errorReason == 'out_of_range'
                        ? const Color(0xFFFFF3CD)
                        : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _errorReason == 'out_of_range'
                          ? const Color(0xFFF59E0B).withOpacity(0.4)
                          : const Color(0xFFDC2626).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _errorReason == 'out_of_range'
                            ? Icons.wrong_location_rounded
                            : Icons.location_off_rounded,
                        color: _errorReason == 'out_of_range'
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFDC2626),
                        size: 36,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _errorReason == 'out_of_range'
                            ? _t('out_of_range')
                            : _errorReason == 'permission_denied'
                                ? _t('permission_denied')
                                : _t('error'),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _errorReason == 'out_of_range'
                              ? const Color(0xFF92400E)
                              : const Color(0xFF7F1D1D),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_distance != null && _errorReason == 'out_of_range') ...[
                        const SizedBox(height: 8),
                        Text(
                          '${_distance!.toStringAsFixed(0)} ${_t('meters')}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Loading
              if (_isChecking) ...[
                const CircularProgressIndicator(color: Color(0xFF00C9E4)),
                const SizedBox(height: 16),
                Text(
                  _t('checking'),
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.grey.shade500),
                ),
              ],

              // Tombol
              if (!_isChecking) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _checkLocation,
                    icon: const Icon(Icons.my_location_rounded,
                        color: Colors.white, size: 20),
                    label: Text(
                      _errorReason != null ? _t('btn_retry') : _t('btn_check'),
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C9E4),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                if (_errorReason == 'permission_denied') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => Geolocator.openAppSettings(),
                      icon: const Icon(Icons.settings_rounded,
                          color: Color(0xFF1E3A8A), size: 20),
                      label: Text(
                        _t('open_settings'),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFF1E3A8A), width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 40),

              // Info PT ATMI
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.factory_rounded,
                      color: Color(0xFF1E3A8A), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'PT ATMI Solo, Jl. Mojo No.1, Karangasem',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}