import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Map<String, dynamic> _translations = {};
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;
  Map<String, dynamic> get translations => _translations;

  Future<void> init(String langCode) async {
    _currentLanguage = langCode;
    await loadTranslations();
  }

  Future<void> loadTranslations() async {
    String data = await rootBundle.loadString('assets/lang/translation.json');
    _translations = json.decode(data);
    notifyListeners();
  }

  String getText(String key) {
    return _translations[_currentLanguage]?[key] ?? key;
  }

  dynamic getNestedText(List<String> keys) {
    dynamic result = _translations[_currentLanguage];
    for (final key in keys) {
      result = result?[key];
      if (result == null) return keys.last;
    }
    return result;
  }

  void changeLanguage(String langCode) async {
    _currentLanguage = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langCode);
    await loadTranslations();
  }
}
