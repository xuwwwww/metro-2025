import 'dart:convert';
import 'package:hive/hive.dart';

class BehaviorEvent {
  final String type; // screen_view | click | font_scale
  final String tsISO; // UTC ISO-8601
  final Map<String, dynamic> props;

  BehaviorEvent({required this.type, required this.tsISO, required this.props});

  Map<String, dynamic> toJson() => {'type': type, 'ts': tsISO, 'props': props};
}

class BehaviorProfile {
  final double avgScale;
  final double lastScale;
  final Map<String, int> featureCounts;
  final Map<String, int> screenCounts;
  final String updatedAt;

  BehaviorProfile({
    required this.avgScale,
    required this.lastScale,
    required this.featureCounts,
    required this.screenCounts,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'font': {'avgScale': avgScale, 'lastScale': lastScale},
    'features': featureCounts,
    'screens': screenCounts,
    'updatedAt': updatedAt,
  };
}

class BehaviorTracker {
  static const String _eventsBox = 'events';
  static const String _profileBox = 'behavior_profile';

  Box<String>? _events;
  Box<String>? _profile;

  Future<void> init() async {
    _events ??= await Hive.openBox<String>(_eventsBox);
    _profile ??= await Hive.openBox<String>(_profileBox);
  }

  Future<void> logScreenView(String screen, {int? durationSec}) async {
    final Map<String, dynamic> props = {'screen': screen};
    if (durationSec != null && durationSec >= 0) {
      props['durationSec'] = durationSec;
    }
    await _appendEvent('screen_view', props);
  }

  Future<void> logClick(String featureId, {String? from}) async {
    final Map<String, dynamic> props = {'featureId': featureId};
    if (from != null && from.isNotEmpty) {
      props['from'] = from;
    }
    await _appendEvent('click', props);
  }

  Future<void> logFontScale(double fontScale) async {
    await _appendEvent('font_scale', {'fontScale': fontScale});
  }

  BehaviorProfile snapshotProfile({int maxKeys = 50, int avgWindow = 20}) {
    final Map<String, int> featureCounts = {};
    final Map<String, int> screenCounts = {};
    final List<double> scales = [];
    double lastScale = 1.0;

    final entries = _events?.toMap().entries.toList() ?? [];
    entries.sort((a, b) => (a.key as int).compareTo(b.key as int));
    for (final e in entries) {
      final Map<String, dynamic> ev = jsonDecode(e.value);
      final String type = ev['type'];
      final Map<String, dynamic> props = Map<String, dynamic>.from(ev['props']);
      if (type == 'click') {
        final String id = props['featureId']?.toString() ?? '';
        if (id.isNotEmpty) {
          featureCounts.update(id, (v) => v + 1, ifAbsent: () => 1);
        }
      } else if (type == 'screen_view') {
        final String name = props['screen']?.toString() ?? '';
        if (name.isNotEmpty) {
          screenCounts.update(name, (v) => v + 1, ifAbsent: () => 1);
        }
      } else if (type == 'font_scale') {
        final double? s =
            (props['fontScale'] as num?)?.toDouble() ??
            (props['scale'] as num?)?.toDouble(); // 兼容舊資料
        if (s != null) {
          scales.add(s);
          lastScale = s;
        }
      }
    }

    // sliding average over last N entries
    final int n = scales.length;
    final int take = n > avgWindow ? avgWindow : n;
    final double avgScale = take == 0
        ? lastScale
        : scales.sublist(n - take).reduce((a, b) => a + b) / take;

    Map<String, int> _topN(Map<String, int> input) {
      final entries = input.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (entries.length > maxKeys) {
        return Map.fromEntries(entries.take(maxKeys));
      }
      return input;
    }

    // 移除低頻鍵（<2）後再取 Top 50
    featureCounts.removeWhere((key, value) => value < 2);
    screenCounts.removeWhere((key, value) => value < 2);
    final limitedFeatures = _topN(featureCounts);
    final limitedScreens = _topN(screenCounts);

    final String updatedAt = DateTime.now().toUtc().toIso8601String();
    final profile = BehaviorProfile(
      avgScale: avgScale,
      lastScale: lastScale,
      featureCounts: limitedFeatures,
      screenCounts: limitedScreens,
      updatedAt: updatedAt,
    );

    _profile?.put(0, jsonEncode(profile.toJson()));
    return profile;
  }

  Future<void> _appendEvent(String type, Map<String, dynamic> props) async {
    if (_events == null) {
      throw StateError('BehaviorTracker not initialized');
    }
    // 使用 epoch 秒作為 Hive 整數鍵，避免超過 0xFFFFFFFF 限制
    final int key = (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000);
    final event = BehaviorEvent(
      type: type,
      tsISO: DateTime.now().toUtc().toIso8601String(),
      props: props,
    );
    await _events!.put(key, jsonEncode(event.toJson()));
    await _enforceCapacity();
  }

  // 限制本機事件總量，避免爆倉（預設 10k）
  Future<void> _enforceCapacity({int maxEvents = 10000}) async {
    final box = _events;
    if (box == null) return;
    final int n = box.length;
    if (n <= maxEvents) return;
    final overflow = n - maxEvents;
    final keys = box.keys.whereType<int>().toList()..sort();
    if (keys.isNotEmpty) {
      final toDelete = keys.take(overflow).toList();
      await box.deleteAll(toDelete);
    }
  }
}
