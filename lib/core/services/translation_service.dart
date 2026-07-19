import 'package:flutter/foundation.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TranslationHelper {
  TranslationHelper._();
  static final TranslationHelper instance = TranslationHelper._();

  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();
  final Map<String, OnDeviceTranslator> _translatorCache = {};
  final LanguageIdentifier _languageIdentifier =
      LanguageIdentifier(confidenceThreshold: 0.4);

  static const List<TranslateLanguage> _supportedLanguages = [
    TranslateLanguage.indonesian,
    TranslateLanguage.english,
    TranslateLanguage.chinese,
  ];

  TranslateLanguage _mapBcpToTranslateLanguage(String bcp) {
    switch (bcp) {
      case 'en':
        return TranslateLanguage.english;
      case 'zh':
      case 'zh-Hans':
      case 'zh-Hant':
        return TranslateLanguage.chinese;
      default:
        return TranslateLanguage.indonesian;
    }
  }

  Future<void> _ensureModelsReady(List<TranslateLanguage> langs) async {
    for (final lang in langs) {
      final tag = lang.bcpCode;
      final isDownloaded = await _modelManager.isModelDownloaded(tag);
      if (!isDownloaded) {
        await _modelManager.downloadModel(tag, isWifiRequired: false);
      }
    }
  }

  OnDeviceTranslator _translator(
      TranslateLanguage source, TranslateLanguage target) {
    final key = '${source.bcpCode}-${target.bcpCode}';
    return _translatorCache.putIfAbsent(
      key,
      () => OnDeviceTranslator(sourceLanguage: source, targetLanguage: target),
    );
  }

  Future<Map<String, String>> _translateWithMlKit(String trimmed) async {
    TranslateLanguage sourceLang;
    try {
      final detectedBcp = await _languageIdentifier.identifyLanguage(trimmed);
      sourceLang = _mapBcpToTranslateLanguage(detectedBcp);
      debugPrint('[TranslationHelper] Bahasa terdeteksi dari teks: $detectedBcp -> ${sourceLang.bcpCode}');
    } catch (e) {
      debugPrint('[TranslationHelper] Gagal deteksi bahasa, fallback ke Indonesia: $e');
      sourceLang = TranslateLanguage.indonesian;
    }

    try {
      await _ensureModelsReady(_supportedLanguages);
    } catch (e, st) {
      debugPrint('[TranslationHelper] Gagal download/siapkan model ML Kit: $e');
      debugPrint('$st');
      return {'id': trimmed, 'en': trimmed, 'zh': trimmed};
    }

    final results = <String, String>{
      'id': trimmed,
      'en': trimmed,
      'zh': trimmed,
    };

    final targets = <String, TranslateLanguage>{
      'id': TranslateLanguage.indonesian,
      'en': TranslateLanguage.english,
      'zh': TranslateLanguage.chinese,
    }..removeWhere((_, lang) => lang == sourceLang);

    for (final entry in targets.entries) {
      try {
        final translator = _translator(sourceLang, entry.value);
        results[entry.key] = await translator.translateText(trimmed);
      } catch (e, st) {
        debugPrint('[TranslationHelper] Gagal translate ML Kit ke ${entry.key}: $e');
        debugPrint('$st');
        results[entry.key] = trimmed;
      }
    }

    return results;
  }

  Future<Map<String, String>> _translateWithEdgeFunction(String trimmed) async {
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'translate-text',
        body: {'text': trimmed},
      );
      final data = res.data;
      if (data is Map) {
        return {
          'id': (data['id'] ?? trimmed).toString(),
          'en': (data['en'] ?? trimmed).toString(),
          'zh': (data['zh'] ?? trimmed).toString(),
        };
      }
      return {'id': trimmed, 'en': trimmed, 'zh': trimmed};
    } catch (e, st) {
      debugPrint('[TranslationHelper] Gagal translate via Edge Function: $e');
      debugPrint('$st');
      return {'id': trimmed, 'en': trimmed, 'zh': trimmed};
    }
  }

  Future<Map<String, String>> translateDescriptionAllLangs(
    String sourceText,
    String uiLang,
  ) async {
    final trimmed = sourceText.trim();
    if (trimmed.isEmpty) {
      return {'id': '', 'en': '', 'zh': ''};
    }

    if (kIsWeb) {
      return _translateWithEdgeFunction(trimmed);
    }
    return _translateWithMlKit(trimmed);
  }

  Future<void> dispose() async {
    for (final t in _translatorCache.values) {
      await t.close();
    }
    _translatorCache.clear();
    await _languageIdentifier.close();
  }
}