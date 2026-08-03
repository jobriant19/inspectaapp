import 'package:supabase_flutter/supabase_flutter.dart';

class AppLogoCache {
  AppLogoCache._();

  static String? cachedUrl;
  static bool _fetched = false;
  static bool _fetching = false;

  static Future<void> prefetch({void Function()? onUpdated}) async {
    if (_fetched || _fetching) return;
    _fetching = true;
    try {
      final res = await Supabase.instance.client
          .from('app_info')
          .select('logo_url')
          .order('id')
          .limit(1)
          .maybeSingle();
      cachedUrl = res?['logo_url'] as String?;
    } catch (_) {
    } finally {
      _fetched = true;
      _fetching = false;
      onUpdated?.call();
    }
  }
}