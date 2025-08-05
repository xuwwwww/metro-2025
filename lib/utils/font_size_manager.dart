import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 全局字體大小管理器
class FontSizeManager {
  static const String _fontSizeKey = 'app_font_size';
  static const double _defaultFontSize = 16.0;
  static const double _minFontSize = 12.0;
  static const double _maxFontSize = 24.0;

  static double _currentFontSize = _defaultFontSize;
  static final List<Function(double)> _listeners = [];

  /// 獲取當前字體大小
  static double get fontSize => _currentFontSize;

  /// 獲取最小字體大小
  static double get minFontSize => _minFontSize;

  /// 獲取最大字體大小
  static double get maxFontSize => _maxFontSize;

  /// 獲取預設字體大小
  static double get defaultFontSize => _defaultFontSize;

  /// 初始化字體大小管理器
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentFontSize = prefs.getDouble(_fontSizeKey) ?? _defaultFontSize;
      // 確保字體大小在有效範圍內
      _currentFontSize = _currentFontSize.clamp(_minFontSize, _maxFontSize);
    } catch (e) {
      print('載入字體大小設定失敗: $e');
      _currentFontSize = _defaultFontSize;
    }
  }

  /// 設置字體大小
  static Future<void> setFontSize(double fontSize) async {
    // 確保字體大小在有效範圍內
    final clampedFontSize = fontSize.clamp(_minFontSize, _maxFontSize);

    if (_currentFontSize != clampedFontSize) {
      _currentFontSize = clampedFontSize;

      // 保存到本地存儲
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(_fontSizeKey, _currentFontSize);
      } catch (e) {
        print('保存字體大小設定失敗: $e');
      }

      // 通知所有監聽器
      _notifyListeners();
    }
  }

  /// 重置為預設字體大小
  static Future<void> resetToDefault() async {
    await setFontSize(_defaultFontSize);
  }

  /// 添加字體大小變更監聽器
  static void addListener(Function(double) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  /// 移除字體大小變更監聽器
  static void removeListener(Function(double) listener) {
    _listeners.remove(listener);
  }

  /// 通知所有監聽器
  static void _notifyListeners() {
    for (final listener in _listeners) {
      try {
        listener(_currentFontSize);
      } catch (e) {
        print('通知字體大小監聽器失敗: $e');
      }
    }
  }

  /// 獲取字體大小等級描述
  static String getFontSizeDescription(double fontSize) {
    if (fontSize <= 14.0) return '小';
    if (fontSize <= 18.0) return '中';
    if (fontSize <= 22.0) return '大';
    return '特大';
  }

  /// 獲取當前字體大小等級描述
  static String get currentFontSizeDescription =>
      getFontSizeDescription(_currentFontSize);
}
