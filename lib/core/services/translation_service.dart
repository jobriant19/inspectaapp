import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationHelper {
  TranslationHelper._();
  static final TranslationHelper instance = TranslationHelper._();

  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();
  final Map<String, OnDeviceTranslator> _translatorCache = {};

  static const List<TranslateLanguage> _supportedLanguages = [
    TranslateLanguage.indonesian,
    TranslateLanguage.english,
    TranslateLanguage.chinese,
  ];

  TranslateLanguage _sourceFromUiLang(String uiLang) {
    switch (uiLang) {
      case 'EN':
        return TranslateLanguage.english;
      case 'ZH':
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

  Future<Map<String, String>> translateDescriptionAllLangs(
    String sourceText,
    String uiLang,
  ) async {
    final trimmed = sourceText.trim();
    if (trimmed.isEmpty) {
      return {'id': '', 'en': '', 'zh': ''};
    }

    final sourceLang = _sourceFromUiLang(uiLang);

    try {
      await _ensureModelsReady(_supportedLanguages);
    } catch (e, st) {
      debugPrint('[TranslationHelper] Gagal download/siapkan model: $e');
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
        debugPrint('[TranslationHelper] Gagal translate ke ${entry.key}: $e');
        debugPrint('$st');
        results[entry.key] = trimmed;
      }
    }

    return results;
  }

  Future<void> dispose() async {
    for (final t in _translatorCache.values) {
      await t.close();
    }
    _translatorCache.clear();
  }
}