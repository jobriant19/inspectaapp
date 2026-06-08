import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  // ── Koordinat PT ATMI Solo ──
  // https://maps.app.goo.gl/56HVyANzftxSAf7o7
  static const double _atmiLat = -7.5585;
  static const double _atmiLng = 110.8322;

  // Radius toleransi dalam meter (sesuaikan dengan luas area PT ATMI)
  static const double _radiusMeters = 20000.0; // 2 km radius

  /// Hitung jarak antara 2 koordinat (Haversine formula) dalam meter
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0; // radius bumi dalam meter
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final dPhi = (lat2 - lat1) * pi / 180;
    final dLambda = (lng2 - lng1) * pi / 180;

    final a = sin(dPhi / 2) * sin(dPhi / 2) +
        cos(phi1) * cos(phi2) * sin(dLambda / 2) * sin(dLambda / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  /// Minta izin lokasi dari user
  /// Returns true jika izin diberikan
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Cek apakah user berada dalam radius PT ATMI Solo
  /// Returns null jika gagal mendapatkan lokasi
  Future<LocationCheckResult> checkUserAtAtmi() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        return LocationCheckResult(
          isGranted: false,
          isAtAtmi: false,
          distance: null,
          reason: 'permission_denied',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final distance = _calculateDistance(
        position.latitude,
        position.longitude,
        _atmiLat,
        _atmiLng,
      );

      final isAtAtmi = distance <= _radiusMeters;

      debugPrint('📍 User location: ${position.latitude}, ${position.longitude}');
      debugPrint('📍 Distance to ATMI: ${distance.toStringAsFixed(0)}m (max: ${_radiusMeters}m)');
      debugPrint('📍 Is at ATMI: $isAtAtmi');

      return LocationCheckResult(
        isGranted: true,
        isAtAtmi: isAtAtmi,
        distance: distance,
        reason: isAtAtmi ? 'ok' : 'out_of_range',
      );
    } catch (e) {
      debugPrint('❌ Location error: $e');
      return LocationCheckResult(
        isGranted: false,
        isAtAtmi: false,
        distance: null,
        reason: 'error',
      );
    }
  }
}

class LocationCheckResult {
  final bool isGranted;
  final bool isAtAtmi;
  final double? distance;
  final String reason;

  const LocationCheckResult({
    required this.isGranted,
    required this.isAtAtmi,
    required this.distance,
    required this.reason,
  });
}