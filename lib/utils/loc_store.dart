import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class LocStore {
  static const String _boxName = 'loc_samples';
  static late Box _box;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(dir.path);
    _box = await Hive.openBox(_boxName);
  }

  static Future<void> addSample(Position position) async {
    final DateTime nowUtc = DateTime.now().toUtc();
    final Map<String, dynamic> sample = <String, dynamic>{
      'lat': position.latitude,
      'lon': position.longitude,
      'ts': nowUtc.toIso8601String(),
      'acc': position.accuracy,
      'speed': position.speed,
    };
    await _box.put(nowUtc.millisecondsSinceEpoch, jsonEncode(sample));
    await _pruneOlderThan(const Duration(hours: 1));
  }

  static Future<void> _pruneOlderThan(Duration duration) async {
    final int cutoff = DateTime.now()
        .toUtc()
        .subtract(duration)
        .millisecondsSinceEpoch;
    final List<dynamic> keysToDelete = _box.keys
        .where((dynamic k) => k is int && k < cutoff)
        .toList(growable: false);
    if (keysToDelete.isNotEmpty) {
      await _box.deleteAll(keysToDelete);
    }
  }

  static List<Map<String, dynamic>> lastHour() {
    final int cutoff = DateTime.now()
        .toUtc()
        .subtract(const Duration(hours: 1))
        .millisecondsSinceEpoch;
    final List<MapEntry<dynamic, dynamic>> entries =
        _box
            .toMap()
            .entries
            .where(
              (MapEntry<dynamic, dynamic> e) =>
                  e.key is int && (e.key as int) >= cutoff,
            )
            .toList()
          ..sort(
            (MapEntry<dynamic, dynamic> a, MapEntry<dynamic, dynamic> b) =>
                (a.key as int).compareTo(b.key as int),
          );
    return entries
        .map(
          (MapEntry<dynamic, dynamic> e) =>
              jsonDecode(e.value as String) as Map<String, dynamic>,
        )
        .toList(growable: false);
  }

  static String buildPayload({
    required String userId,
    Map<String, dynamic>? extra,
  }) {
    final List<Map<String, dynamic>> samples = lastHour();
    final Map<String, dynamic> payload = <String, dynamic>{
      'userId': userId,
      'capturedAt': DateTime.now().toUtc().toIso8601String(),
      'window': <String, int>{'hours': 1},
      'samples': samples,
      if (extra != null) ...extra,
    };
    return jsonEncode(payload);
  }
}
