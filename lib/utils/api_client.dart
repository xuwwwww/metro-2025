import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'loc_store.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';
}

class PredictionResult {
  final List<Map<String, dynamic>> topK;
  final Map<String, dynamic>? algoMeta;
  final Map<String, dynamic>? weights;
  final int? k;
  final Map<String, dynamic>? llmSummary;
  final Map<String, dynamic> raw;

  PredictionResult({
    required this.topK,
    this.algoMeta,
    this.weights,
    this.k,
    this.llmSummary,
    required this.raw,
  });
}

class UiConfigResult {
  final Map<String, dynamic> json;
  UiConfigResult(Map<String, dynamic> input)
    : json = _sanitizeUi(input),
      raw = input;
  final Map<String, dynamic> raw;

  static Map<String, dynamic> _defaultUi() => {
    'mode': 'ui',
    'ui': {
      'mainpage_block': {
        'size': 3,
        'often_use_icon_id': [1, 2, 3],
      },
      'mainpage_ad_size': 4,
    },
  };

  static Map<String, dynamic> _sanitizeUi(Map<String, dynamic> raw) {
    try {
      final ui = Map<String, dynamic>.from(raw['ui'] ?? {});
      final block = Map<String, dynamic>.from(ui['mainpage_block'] ?? {});
      int size = _toInt(block['size']);
      if (size <= 0) size = 3;
      final idsRaw = (block['often_use_icon_id'] as List?) ?? const [];
      final ids = idsRaw.map((e) => _toInt(e)).where((e) => e > 0).toList();
      int ad = _toInt(ui['mainpage_ad_size']);
      if (ad <= 0) ad = 4;
      return {
        'mode': 'ui',
        'ui': {
          'mainpage_block': {'size': size, 'often_use_icon_id': ids},
          'mainpage_ad_size': ad,
        },
      };
    } catch (_) {
      return _defaultUi();
    }
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) {
      final parsed = int.tryParse(v);
      if (parsed != null) return parsed;
      final parsedD = double.tryParse(v);
      if (parsedD != null) return parsedD.round();
    }
    return 0;
  }
}

class ApiClient {
  ApiClient({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 20),
  });

  final String baseUrl; // e.g. https://your-lambda-url
  final Duration timeout;

  static void _log(String message) {
    final ts = DateTime.now().toIso8601String();
    // 使用 print 避免被截斷
    print('[ApiClient][$ts] $message');
  }

  static void _logLarge(String label, String content) {
    const int chunk = 1000;
    if (content.length <= chunk) {
      _log('$label: $content');
      return;
    }
    int i = 0;
    while (i < content.length) {
      final end = (i + chunk > content.length) ? content.length : i + chunk;
      _log('$label(${i}..${end}): ${content.substring(i, end)}');
      i = end;
    }
  }

  Future<PredictionResult> predictDestination({
    required String userId,
    required List<LocationSample> samples,
    Map<String, dynamic>? extra,
  }) async {
    if (samples.isEmpty) {
      throw ApiException('No samples provided');
    }

    final List<LocationSample> capped = _downsample(samples, maxPoints: 120);
    final enrichedExtra = await _withDeviceInfo(extra);
    final body = jsonEncode({
      'mode': 'predict',
      'userId': userId,
      'samples': capped.map((s) => s.toJson()).toList(),
      if (enrichedExtra != null) 'extra': enrichedExtra,
    });

    _log(
      'predictDestination start url=$baseUrl userId=$userId samples=${capped.length}',
    );
    _logLarge('predict.req', body);
    final Map<String, dynamic> jsonResp = await _postWithRetry(body);
    final List<dynamic> topK = (jsonResp['topK'] as List?) ?? [];
    _log('predictDestination ok topK=${topK.length}');
    return PredictionResult(
      topK: topK.cast<Map<String, dynamic>>(),
      algoMeta: jsonResp['algo_meta'] as Map<String, dynamic>?,
      weights: jsonResp['weights'] as Map<String, dynamic>?,
      k: jsonResp['k'] as int?,
      llmSummary: jsonResp['llm_summary'] as Map<String, dynamic>?,
      raw: jsonResp,
    );
  }

  List<LocationSample> _downsample(
    List<LocationSample> input, {
    required int maxPoints,
  }) {
    if (input.length <= maxPoints) return input;
    final List<LocationSample> out = [];
    final double step = input.length / maxPoints;
    double idx = 0;
    for (int i = 0; i < maxPoints; i++) {
      out.add(input[idx.floor()]);
      idx += step;
    }
    // ensure the last point is included
    if (out.isNotEmpty && out.last != input.last) {
      out[out.length - 1] = input.last;
    }
    return out;
  }

  Future<UiConfigResult> fetchUiConfig({String? userId}) async {
    final body = jsonEncode({
      'mode': 'ui',
      if (userId != null) 'userId': userId,
    });
    _log('fetchUiConfig start url=$baseUrl userId=${userId ?? '(null)'}');
    _logLarge('ui.req', body);
    final Map<String, dynamic> jsonResp = await _postWithRetry(body);
    _log('fetchUiConfig ok');
    return UiConfigResult(jsonResp);
  }

  Future<Map<String, dynamic>?> _withDeviceInfo(
    Map<String, dynamic>? extra,
  ) async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      final android = await deviceInfo.androidInfo;
      final device = {'brand': android.brand, 'model': android.model};
      final merged = Map<String, dynamic>.from(extra ?? {});
      merged['schemaVersion'] = 1;
      merged['device'] = device;
      return merged;
    } catch (_) {
      return extra;
    }
  }

  Future<Map<String, dynamic>> _postWithRetry(String body) async {
    final uri = Uri.parse(baseUrl);
    int attempt = 0;
    int maxRetries = 2; // retry up to 2 times (total 3 attempts)
    Duration backoff = const Duration(milliseconds: 600);
    while (true) {
      try {
        _log('HTTP POST attempt=${attempt + 1}');
        final resp = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(timeout);
        final int code = resp.statusCode;
        _log('HTTP status=$code');
        _logLarge('HTTP resp', resp.body);
        if (code >= 200 && code < 300) {
          return jsonDecode(resp.body) as Map<String, dynamic>;
        }
        // 5xx -> retry, 4xx -> throw
        if (code >= 500 && code <= 599 && attempt < maxRetries) {
          // fall through to retry
        } else {
          throw ApiException(resp.body, statusCode: code);
        }
      } on ApiException catch (e) {
        _log('ApiException status=${e.statusCode} message=${e.message}');
        rethrow; // don't retry on non-2xx after it occurred
      } on TimeoutException catch (e) {
        _log('TimeoutException: ${e.message ?? ''}');
        if (attempt >= maxRetries) {
          throw ApiException('Timeout: ${e.message ?? ''}');
        }
      } catch (e) {
        // network or other errors -> retry
        _log('Network error: $e');
        if (attempt >= maxRetries) {
          throw ApiException('Network error: $e');
        }
      }
      // jitter backoff
      await Future.delayed(backoff);
      backoff *= 2;
      attempt += 1;
    }
  }
}
