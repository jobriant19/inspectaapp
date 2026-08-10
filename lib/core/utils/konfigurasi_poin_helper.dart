import 'package:supabase_flutter/supabase_flutter.dart';

class KonfigurasiPoinHelper {
  KonfigurasiPoinHelper._();

  static Map<String, Map<String, dynamic>>? _cache;
  static Future<Map<String, Map<String, dynamic>>>? _inflight;

  static Future<Map<String, Map<String, dynamic>>> getMap() {
    if (_cache != null) return Future.value(_cache);
    if (_inflight != null) return _inflight!;
    _inflight = _fetch();
    return _inflight!;
  }

  static Future<Map<String, Map<String, dynamic>>> _fetch() async {
    try {
      final data = await Supabase.instance.client.from('konfigurasi_poin').select(
          'kode, nama, nama_en, nama_zh, deskripsi_template, deskripsi_template_en, deskripsi_template_zh');
      final map = <String, Map<String, dynamic>>{};
      for (final row in (data as List)) {
        final kode = row['kode']?.toString().trim().toLowerCase();
        if (kode == null || kode.isEmpty) continue;
        map[kode] = Map<String, dynamic>.from(row);
      }
      _cache = map;
      return map;
    } catch (e) {
      _cache = {};
      return {};
    }
  }

  static void clearCache() {
    _cache = null;
    _inflight = null;
  }

  static Map<String, dynamic>? findMatchingRow({
    required Map<String, Map<String, dynamic>> map,
    required String? tipeAktivitas,
    required Map<String, dynamic> log,
  }) {
    final key = (tipeAktivitas ?? '').trim().toLowerCase();

    if (key.isNotEmpty && map.containsKey(key)) {
      return map[key];
    }

    if (key.isNotEmpty) {
      for (final entry in map.entries) {
        if (entry.key.contains(key) || key.contains(entry.key)) {
          return entry.value;
        }
      }
    }

    final desk = (log['deskripsi'] ?? '').toString().toLowerCase().trim();
    if (desk.isNotEmpty) {
      for (final entry in map.entries) {
        final tmpl = (entry.value['deskripsi_template'] ?? '').toString().toLowerCase();
        if (tmpl.isEmpty) continue;
        final staticPart = tmpl.split('{').first.trim();
        if (staticPart.length >= 5 && desk.contains(staticPart)) {
          return entry.value;
        }
      }
    }

    return null;
  }

  static String resolveNama({
    required Map<String, Map<String, dynamic>> map,
    required String? tipeAktivitas,
    required String lang,
    required String fallbackDeskripsi,
    Map<String, dynamic>? log,
  }) {
    final row = findMatchingRow(
      map: map,
      tipeAktivitas: tipeAktivitas,
      log: log ?? const {},
    );
    if (row == null) return fallbackDeskripsi;

    String? v;
    if (lang == 'EN') {
      v = row['nama_en'] as String?;
    } else if (lang == 'ZH') {
      v = row['nama_zh'] as String?;
    }
    if (v != null && v.trim().isNotEmpty) return v;

    final base = row['nama'] as String?;
    if (base != null && base.trim().isNotEmpty) return base;

    return fallbackDeskripsi;
  }

  static String resolveDeskripsi({
    required Map<String, dynamic> log,
    required String lang,
  }) {
    final base = (log['deskripsi'] ?? '').toString();
    if (lang == 'EN') {
      final en = log['deskripsi_en'] as String?;
      return (en != null && en.trim().isNotEmpty) ? en : base;
    }
    if (lang == 'ZH') {
      final zh = log['deskripsi_zh'] as String?;
      return (zh != null && zh.trim().isNotEmpty) ? zh : base;
    }
    return base;
  }

  static String resolvePopupDeskripsi({
    required Map<String, Map<String, dynamic>> map,
    required String? tipeAktivitas,
    required String lang,
    required Map<String, dynamic> log,
  }) {
    final row = findMatchingRow(map: map, tipeAktivitas: tipeAktivitas, log: log);
    if (row != null) {
      String? v;
      if (lang == 'EN') {
        v = row['deskripsi_template_en'] as String?;
      } else if (lang == 'ZH') {
        v = row['deskripsi_template_zh'] as String?;
      }
      if (v != null && v.trim().isNotEmpty) return v;
      final base = row['deskripsi_template'] as String?;
      if (base != null && base.trim().isNotEmpty) return base;
    }
    return resolveDeskripsi(log: log, lang: lang);
  }
}