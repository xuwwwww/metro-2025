import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../utils/api_client.dart';
import '../utils/behavior_tracker.dart';
import '../utils/global_login_state.dart';
import '../utils/loc_store.dart';
import '../utils/location_tracking.dart';

/// Schedules periodic station prediction based on recent location movement.
///
/// Behavior:
/// - Checks movement over recent samples; if moving, runs prediction at most
///   once per [pollInterval].
/// - When movement stops, runs one final prediction, then idles until moving
///   again.
class StationPredictionScheduler {
  StationPredictionScheduler({
    this.pollInterval = const Duration(minutes: 5),
    this.movementThresholdMeters = 120.0,
    this.recentWindow = const Duration(minutes: 5),
  });

  final Duration pollInterval;
  final double movementThresholdMeters;
  final Duration recentWindow;

  final LocationTrackingService _tracking = LocationTrackingService();
  final BehaviorTracker _behavior = BehaviorTracker();

  ApiClient? _apiClient;
  Timer? _timer;
  DateTime? _lastPredAtUtc;
  bool _wasMoving = false;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _tracking.init();
    await _behavior.init();
    final cfg = await ApiConfig.load();
    _apiClient = ApiClient(baseUrl: cfg.lambda2Url);
    _initialized = true;
  }

  Future<void> start() async {
    await init();
    // Ensure foreground stream is running so samples keep collecting.
    // Caller may have already started it; safe to call again.
    unawaited(_tracking.startForegroundStream());
    _timer?.cancel();
    _timer = Timer.periodic(pollInterval, (_) {
      unawaited(_tick());
    });
    // Also perform an immediate check on start.
    unawaited(_tick());
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> dispose() async {
    await stop();
  }

  Future<void> _tick() async {
    try {
      final bool moving = _isMovingNow();
      final DateTime now = DateTime.now().toUtc();

      // Predict if moving and interval elapsed.
      if (moving) {
        final bool due =
            _lastPredAtUtc == null ||
            now.difference(_lastPredAtUtc!).compareTo(pollInterval) >= 0;
        if (due) {
          await _runPredictAndPersist();
          _lastPredAtUtc = now;
        }
      } else {
        // If just stopped moving, run one final prediction.
        if (_wasMoving) {
          await _runPredictAndPersist();
          _lastPredAtUtc = now;
        }
      }

      _wasMoving = moving;
    } catch (_) {
      // Swallow to avoid crashing the scheduler.
    }
  }

  bool _isMovingNow() {
    final List<LocationSample> samples = _tracking.store.lastHour();
    if (samples.length < 2) return false;

    final DateTime cutoff = DateTime.now().toUtc().subtract(recentWindow);
    final List<LocationSample> recent = samples
        .where((s) => DateTime.tryParse(s.tsISO)?.isAfter(cutoff) ?? false)
        .toList();
    if (recent.length < 2) return false;

    // Compare first and last point in the recent window.
    final LocationSample first = recent.first;
    final LocationSample last = recent.last;
    final double dist = _haversineMeters(
      first.lat,
      first.lon,
      last.lat,
      last.lon,
    );
    // Also consider speed hint if available.
    final double lastSpeed = (last.speed ?? 0.0);
    return dist >= movementThresholdMeters || lastSpeed >= 0.5;
  }

  Future<void> _runPredictAndPersist() async {
    final api = _apiClient;
    if (api == null) return;
    final List<LocationSample> samples = _tracking.store.lastHour();
    if (samples.isEmpty) return;

    final String userId = GlobalLoginState.currentUid ?? 'guest';
    final BehaviorProfile profile = _behavior.snapshotProfile();
    final PredictionResult res = await api.predictDestination(
      userId: userId,
      samples: samples,
      extra: {'behavior': profile.toJson()},
    );

    // Extract top-2 station names and persist for UI consumption.
    final List<dynamic> tk = (res.raw['topK'] as List?) ?? [];
    final List<String> top2 = tk
        .take(2)
        .map((e) => (e['name'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toList();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'predicted_top2',
      const JsonEncoder().convert({
        'ts': DateTime.now().toUtc().toIso8601String(),
        'stations': top2,
      }),
    );
  }

  // Haversine distance in meters.
  double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371000.0; // earth radius in meters
    final double dLat = _degToRad(lat2 - lat1);
    final double dLon = _degToRad(lon2 - lon1);
    final double a =
        (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            (math.sin(dLon / 2) * math.sin(dLon / 2));
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _degToRad(double deg) => deg * 3.1415926535897932 / 180.0;
}
