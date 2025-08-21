import 'dart:convert';
import 'package:hive/hive.dart';

class LocationSample {
  final double lat;
  final double lon;
  final String tsISO; // UTC ISO-8601
  final double? acc;
  final double? speed;

  LocationSample({
    required this.lat,
    required this.lon,
    required this.tsISO,
    this.acc,
    this.speed,
  });

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lon': lon,
    'ts': tsISO,
    if (acc != null) 'acc': acc,
    if (speed != null) 'speed': speed,
  };

  static LocationSample fromJson(Map<String, dynamic> json) => LocationSample(
    lat: (json['lat'] as num).toDouble(),
    lon: (json['lon'] as num).toDouble(),
    tsISO: json['ts'] as String,
    acc: (json['acc'] as num?)?.toDouble(),
    speed: (json['speed'] as num?)?.toDouble(),
  );
}

abstract class PositionLike {
  double get latitude;
  double get longitude;
  double? get accuracy;
  double? get speed;
  DateTime get timestamp; // should be in UTC or convertible
}

class LocationStore {
  static const String _boxName = 'loc_samples';
  Box<String>? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox<String>(_boxName);
  }

  Future<void> addSample(PositionLike p) async {
    if (_box == null) {
      throw StateError('LocationStore not initialized');
    }
    final DateTime tsUtc = p.timestamp.toUtc();
    // 使用 epoch 秒作為 Hive 鍵，避免超過 0xFFFFFFFF 限制
    final int epochMs = tsUtc.millisecondsSinceEpoch ~/ 1000;
    final sample = LocationSample(
      lat: p.latitude,
      lon: p.longitude,
      tsISO: tsUtc.toIso8601String(),
      acc: p.accuracy,
      speed: p.speed,
    );
    await _box!.put(epochMs, jsonEncode(sample.toJson()));
    await _pruneOld();
  }

  Future<void> _pruneOld() async {
    if (_box == null) return;
    final int cutoff =
        (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000) - 3600;
    final keysToDelete = _box!.keys
        .where((k) => (k is int) && k < cutoff)
        .toList();
    if (keysToDelete.isNotEmpty) {
      await _box!.deleteAll(keysToDelete);
    }
  }

  List<LocationSample> lastHour() {
    if (_box == null) return [];
    final int cutoff =
        (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000) - 3600;
    final entries =
        _box!
            .toMap()
            .entries
            .where((e) => (e.key is int) && (e.key as int) >= cutoff)
            .toList()
          ..sort((a, b) => (a.key as int).compareTo(b.key as int));
    return entries
        .map((e) => LocationSample.fromJson(jsonDecode(e.value)))
        .toList();
  }

  String buildPayload({required String userId, Map<String, dynamic>? extra}) {
    final samples = lastHour().map((s) => s.toJson()).toList();
    final Map<String, dynamic> payload = {
      'mode': 'predict',
      'userId': userId,
      'samples': samples,
      if (extra != null) 'extra': extra,
    };
    return jsonEncode(payload);
  }
}
