import 'package:shared_preferences/shared_preferences.dart';

class AppBrandingCache {
  static const _kAppName   = 'branding_app_name';
  static const _kLogoUrl   = 'branding_logo_url';
  static const _kTaglineId = 'branding_tagline_id';
  static const _kTaglineEn = 'branding_tagline_en';
  static const _kTaglineZh = 'branding_tagline_zh';

  static Future<void> save(Map<String, dynamic> row) async {
    final prefs = await SharedPreferences.getInstance();

    Future<void> setIfPresent(String key, String prefKey) async {
      if (row.containsKey(key)) {
        await prefs.setString(prefKey, (row[key] ?? '').toString());
      }
    }

    await setIfPresent('app_name', _kAppName);
    await setIfPresent('logo_url', _kLogoUrl);
    await setIfPresent('tagline', _kTaglineId);
    await setIfPresent('tagline_en', _kTaglineEn);
    await setIfPresent('tagline_zh', _kTaglineZh);
  }

  static Future<Map<String, String?>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'app_name': prefs.getString(_kAppName),
      'logo_url': prefs.getString(_kLogoUrl),
      'tagline': prefs.getString(_kTaglineId),
      'tagline_en': prefs.getString(_kTaglineEn),
      'tagline_zh': prefs.getString(_kTaglineZh),
    };
  }
}