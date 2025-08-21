import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/location_tracking.dart';
import '../utils/behavior_tracker.dart';
import '../utils/api_client.dart';
import '../config/api_config.dart';
import '../utils/global_login_state.dart';
import '../services/behavior_uploader.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiDemoPage extends StatefulWidget {
  const AiDemoPage({super.key});

  @override
  State<AiDemoPage> createState() => _AiDemoPageState();
}

class _AiDemoPageState extends State<AiDemoPage> {
  final LocationTrackingService _tracking = LocationTrackingService();
  final BehaviorTracker _behavior = BehaviorTracker();
  ApiClient? _api;

  String _log = '';
  Map<String, dynamic>? _uiJson;
  List<Map<String, dynamic>> _topK = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _tracking.init();
    await _behavior.init();
    await _tracking.startForegroundStream();
    final config = await ApiConfig.load();
    setState(() {
      _api = ApiClient(baseUrl: config.lambda2Url);
    });
  }

  void _append(String s) {
    setState(() => _log = '$_log\n$s');
  }

  Future<void> _doUpload() async {
    final uid = GlobalLoginState.currentUid ?? 'anonymous';
    setState(() => _busy = true);
    try {
      final uploaded = await BehaviorUploader().flushToday(uid);
      _append('upload 成功，count=$uploaded');
    } catch (e) {
      _append('upload 失敗: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _doPredict() async {
    if (_api == null) return;
    final userId = GlobalLoginState.currentUid ?? 'guest';
    final samples = _tracking.store.lastHour();
    if (samples.isEmpty) {
      _append('樣本不足，請稍後再試');
      return;
    }
    final profile = _behavior.snapshotProfile();
    setState(() => _busy = true);
    try {
      final res = await _api!.predictDestination(
        userId: userId,
        samples: samples,
        extra: {'behavior': profile.toJson()},
      );
      // 存 top2 供主頁顯示
      final List<dynamic> tk = (res.raw['topK'] as List?) ?? [];
      final List<String> top2 = tk
          .take(2)
          .map((e) => (e['name'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'predicted_top2',
        const JsonEncoder().convert({
          'ts': DateTime.now().toUtc().toIso8601String(),
          'stations': top2,
        }),
      );
      setState(() => _topK = res.topK);
      _append('predict 成功，k=${res.k ?? _topK.length}');
      _append(const JsonEncoder.withIndent('  ').convert(res.raw));
    } catch (e) {
      _append('predict 失敗: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _doUi() async {
    if (_api == null) return;
    final userId = GlobalLoginState.currentUid;
    setState(() => _busy = true);
    try {
      final res = await _api!.fetchUiConfig(userId: userId);
      setState(() => _uiJson = res.json);
      _append('ui 成功');
      _append(const JsonEncoder.withIndent('  ').convert(res.raw));
    } catch (e) {
      setState(
        () => _uiJson = {
          'mode': 'ui',
          'ui': {
            'mainpage_block': {
              'size': 3,
              'often_use_icon_id': [1, 2, 3],
            },
            'mainpage_ad_size': 4,
          },
        },
      );
      _append('ui 失敗，使用預設');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Demo')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _busy ? null : _doUpload,
                  child: const Text('upload behavior'),
                ),
                ElevatedButton(
                  onPressed: _busy ? null : _doPredict,
                  child: const Text('predict station'),
                ),
                ElevatedButton(
                  onPressed: _busy ? null : _doUi,
                  child: const Text('ui suggestion'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('TopK: ${jsonEncode(_topK)}'),
            const SizedBox(height: 12),
            Text('UI: ${jsonEncode(_uiJson)}'),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_log, style: const TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
