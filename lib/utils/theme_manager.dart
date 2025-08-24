import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  static const String _key = 'theme_mode';
  static final ValueNotifier<ThemeMode> notifier = ValueNotifier<ThemeMode>(
    ThemeMode.dark,
  );

  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? m = prefs.getString(_key);
      if (m == 'light') {
        notifier.value = ThemeMode.light;
      } else if (m == 'dark') {
        notifier.value = ThemeMode.dark;
      } else {
        notifier.value = ThemeMode.dark; // default dark
      }
    } catch (_) {
      notifier.value = ThemeMode.dark;
    }
  }

  static ThemeMode get mode => notifier.value;

  static Future<void> setMode(ThemeMode mode) async {
    if (mode == notifier.value) return;
    notifier.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode == ThemeMode.light ? 'light' : 'dark');
    } catch (_) {}
  }
}
