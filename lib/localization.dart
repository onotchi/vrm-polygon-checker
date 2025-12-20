import 'dart:convert';
import 'package:flutter/services.dart';

enum AppLanguage { ja, en }

class Localization {
  static AppLanguage currentLanguage = AppLanguage.ja;
  static Map<String, String> _strings = {};
  static final Map<AppLanguage, Map<String, String>> _cache = {};

  /// Load language file from assets
  static Future<void> load(AppLanguage language) async {
    currentLanguage = language;

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
