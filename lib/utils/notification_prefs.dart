import 'package:shared_preferences/shared_preferences.dart';

class NotificationPrefs {
  static const String _key = 'notify_arrivals';

  static Future<bool> isEnabled() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool(_key) ?? true; // default on
    } catch (_) {
      return true;
    }
  }

  static Future<void> setEnabled(bool enabled) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_key, enabled);
    } catch (_) {}
  }
}
