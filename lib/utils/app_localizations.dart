import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);
  final Locale locale;

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _values = {
    'zh': {
      'language_settings': '語言設定',
      'close': '關閉',
      'ai_demo': 'AI Demo',
      'notifications': '推播通知',
      'notifications_desc': '開啟或關閉預測站點到站倒數通知',
      'theme_settings': '主題設定',
      'dark_mode': '深色模式',
      'dark_mode_desc': '切換淺色/深色主題',
      'confirm': '確定',
    },
    'en': {
      'language_settings': 'Language',
      'close': 'Close',
      'ai_demo': 'AI Demo',
      'notifications': 'Notifications',
      'notifications_desc': 'Enable arrival countdown notification',
      'theme_settings': 'Theme',
      'dark_mode': 'Dark Mode',
      'dark_mode_desc': 'Toggle light/dark theme',
      'confirm': 'OK',
    },
    'ja': {
      'language_settings': '言語設定',
      'close': '閉じる',
      'ai_demo': 'AI デモ',
      'notifications': '通知',
      'notifications_desc': '到着カウントダウン通知を有効化',
      'theme_settings': 'テーマ',
      'dark_mode': 'ダークモード',
      'dark_mode_desc': 'ライト/ダークの切替',
      'confirm': '確認',
    },
    'ko': {
      'language_settings': '언어 설정',
      'close': '닫기',
      'ai_demo': 'AI 데모',
      'notifications': '알림',
      'notifications_desc': '도착 카운트다운 알림 사용',
      'theme_settings': '테마',
      'dark_mode': '다크 모드',
      'dark_mode_desc': '라이트/다크 전환',
      'confirm': '확인',
    },
  };

  String t(String key) {
    final lang = locale.languageCode;
    return _values[lang]?[key] ?? _values['en']![key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['zh', 'en', 'ja', 'ko'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
