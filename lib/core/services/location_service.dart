import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  static const double _atmiLat = -7.5585;
  static const double _atmiLng = 110.8322;
  static const double _radiusMeters = 500.0;

  // ── Cache hasil cek lokasi agar tidak berulang kali request GPS ──
  LocationCheckResult? _cachedResult;
  DateTime? _lastCheckTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Invalidate cache (panggil saat app resume dari background)
  void invalidateCache() {
    _cachedResult = null;
    _lastCheckTime = null;
  }

  /// Apakah cache masih valid?
  bool get _isCacheValid {
    if (_cachedResult == null || _lastCheckTime == null) return false;
    return DateTime.now().difference(_lastCheckTime!) < _cacheDuration;
  }

  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final dPhi = (lat2 - lat1) * pi / 180;
    final dLambda = (lng2 - lng1) * pi / 180;
    final a = sin(dPhi / 2) * sin(dPhi / 2) +
        cos(phi1) * cos(phi2) * sin(dLambda / 2) * sin(dLambda / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  /// Cek lokasi dengan cache 5 menit
  /// [forceRefresh] = true untuk bypass cache (misalnya saat user tap "Coba Lagi")
  Future<LocationCheckResult> checkUserAtAtmi({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) {
      debugPrint('📍 Using cached location result: ${_cachedResult!.reason}');
      return _cachedResult!;
    }

    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        final result = LocationCheckResult(
          isGranted: false,
          isAtAtmi: false,
          distance: null,
          reason: 'permission_denied',
        );
        // Jangan cache hasil permission denied agar user bisa coba lagi
        return result;
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

      debugPrint(
          '📍 User location: ${position.latitude}, ${position.longitude}');
      debugPrint(
          '📍 Distance to ATMI: ${distance.toStringAsFixed(0)}m (max: ${_radiusMeters}m)');
      debugPrint('📍 Is at ATMI: $isAtAtmi');

      final result = LocationCheckResult(
        isGranted: true,
        isAtAtmi: isAtAtmi,
        distance: distance,
        reason: isAtAtmi ? 'ok' : 'out_of_range',
      );

      // Simpan cache
      _cachedResult = result;
      _lastCheckTime = DateTime.now();

      return result;
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