import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/route_info_page.dart' show MetroApiService;

class StationArrivalNotifier {
  StationArrivalNotifier._internal();
  static final StationArrivalNotifier instance =
      StationArrivalNotifier._internal();

  static const int _notifId = 1001;
  static const String _channelId = 'arrival_updates';
  static const String _channelName = 'Metro Arrivals';
  static const String _channelDesc = 'Predicted station arrival countdown';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Timer? _timer;
  bool _initialized = false;
  bool get isRunning => _timer != null;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings init = InitializationSettings(
      android: androidInit,
    );
    await _plugin.initialize(init);
    _initialized = true;
  }

  Future<void> start() async {
    await _ensureInitialized();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _tick();
    });
    // run immediately
    unawaited(_tick());
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    await _plugin.cancel(_notifId);
  }

  Future<void> _tick() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('predicted_top2');
      if (raw == null || raw.isEmpty) {
        await _plugin.cancel(_notifId);
        return;
      }
      final Map<String, dynamic> j = jsonDecode(raw);
      final List<dynamic> arr = (j['stations'] as List?) ?? const [];
      final List<String> stations = arr
          .map((e) => (e ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList();
      if (stations.isEmpty) {
        await _plugin.cancel(_notifId);
        return;
      }

      final all = await MetroApiService.fetchTrackInfo();

      String body = '';
      for (final s in stations.take(2)) {
        final filtered = MetroApiService.filterByStation(all, s);
        // find earliest by CountDown parsed seconds
        int? bestSec;
        String bestDest = '';
        for (final e in filtered) {
          final cd = (e['CountDown']?.toString() ?? '').trim();
          final sec = _parseCountDownToSeconds(cd);
          if (sec != null && (bestSec == null || sec < bestSec)) {
            bestSec = sec;
            bestDest = e['DestinationName']?.toString() ?? '';
          }
        }
        final text = (bestSec != null)
            ? '$s → $bestDest ${bestSec}s'
            : '$s 資料暫無';
        body = body.isEmpty ? text : '$body | $text';
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.max,
            priority: Priority.high,
            ongoing: true,
            onlyAlertOnce: true,
            showWhen: false,
          );
      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );
      await _plugin.show(_notifId, '預測到站倒數', body, details);
    } catch (_) {}
  }

  int? _parseCountDownToSeconds(String countDown) {
    try {
      if (countDown.contains('進站')) return 0;
      final parts = countDown.split(':');
      if (parts.length != 2) return null;
      final m = int.tryParse(parts[0]);
      final s = int.tryParse(parts[1]);
      if (m == null || s == null) return null;
      return m * 60 + s;
    } catch (_) {
      return null;
    }
  }
}
