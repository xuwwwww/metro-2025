import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleManager {
  static const String _key = 'app_locale';
  static final ValueNotifier<Locale?> notifier = ValueNotifier<Locale?>(null);

  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_key);
      if (code != null && code.isNotEmpty) {
        final parts = code.split('-');
        notifier.value = parts.length == 2
            ? Locale(parts[0], parts[1])
            : Locale(parts[0]);
      }
    } catch (_) {}
  }

  static Locale? get locale => notifier.value;

  static Future<void> setLocale(Locale? locale) async {
    notifier.value = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (locale == null) {
        await prefs.remove(_key);
      } else {
        final code = locale.countryCode == null
            ? locale.languageCode
            : '${locale.languageCode}-${locale.countryCode}';
        await prefs.setString(_key, code);
      }
    } catch (_) {}
  }
}
