import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ApiConfig {
  ApiConfig({required this.lambda2Url});

  final String lambda2Url;

  static ApiConfig? _cached;

  static const String _assetPath = 'lib/assets/api_config.json';

  static Future<ApiConfig> load() async {
    if (_cached != null) return _cached!;
    const String fromEnv = String.fromEnvironment(
      'LAMBDA2_URL',
      defaultValue: '',
    );
    if (fromEnv.isNotEmpty) {
      _cached = ApiConfig(lambda2Url: fromEnv);
      return _cached!;
    }
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final Map<String, dynamic> json = jsonDecode(raw);
      final String url = (json['lambda2Url'] as String?)?.trim() ?? '';
      if (url.isNotEmpty) {
        _cached = ApiConfig(lambda2Url: url);
        return _cached!;
      }
    } catch (_) {
      // fall through to default
    }
    _cached = ApiConfig(lambda2Url: 'https://example.com');
    return _cached!;
  }
}
