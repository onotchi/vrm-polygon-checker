import 'dart:convert';
import 'package:flutter/services.dart';

enum AppLanguage { ja, en }

class Localization {
  static AppLanguage currentLanguage = AppLanguage.ja;
  static Map<String, String> _strings = {};
  static final Map<AppLanguage, Map<String, String>> _cache = {};

  /// Called after the language changes. The app uses it to keep the document's
  /// `lang` attribute in step. It is a hook rather than a direct call so that
  /// this file stays free
  /// of web-only imports: every widget that reads a string reaches this class,
  /// and a web import here would put `package:web` on all of their compile
  /// paths, where the VM that runs widget tests cannot follow.
  static void Function(AppLanguage language)? onLanguageChanged;

  /// Load language file from assets
  static Future<void> load(AppLanguage language) async {
    currentLanguage = language;
    onLanguageChanged?.call(language);

    // Return cached strings if already loaded
    if (_cache.containsKey(language)) {
      _strings = _cache[language]!;
      return;
    }

    // Load JSON file
    final jsonString = await rootBundle.loadString(
      'assets/localization/${language.name}.json',
    );
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    _strings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    _cache[language] = _strings;
  }

  /// Get localized string by key
  static String get(String key) => _strings[key] ?? key;
}
