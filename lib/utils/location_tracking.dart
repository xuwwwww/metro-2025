import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'loc_store.dart';

class GeolocatorPositionAdapter implements PositionLike {
  GeolocatorPositionAdapter(this._p);
  final Position _p;
  @override
  double get latitude => _p.latitude;
  @override
  double get longitude => _p.longitude;
  @override
  double? get accuracy => _p.accuracy;
  @override
  double? get speed => _p.speed;
  @override
  DateTime get timestamp => _p.timestamp.toUtc();
}

class LocationTrackingService {
  LocationTrackingService({
    this.distanceFilterMeters = 75,
    this.intervalSeconds = 20,
  });

  final int distanceFilterMeters;
  final int intervalSeconds;

  final LocationStore _store = LocationStore();
  StreamSubscription<Position>? _sub;
  bool _initialized = false;

  Future<void> init() async {
    if (!_initialized) {
      await _store.init();
      _initialized = true;
    }
  }

  Future<bool> ensurePermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }
    return true;
  }

  Future<void> startForegroundStream() async {
    final ok = await ensurePermissions();
    if (!ok) return;
    await init();
    _sub?.cancel();
    _sub =
        Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.medium,
            distanceFilter: distanceFilterMeters,
          ),
        ).listen(
          (p) async {
            try {
              await _store.addSample(GeolocatorPositionAdapter(p));
            } catch (_) {}
          },
          onError: (Object error, StackTrace stack) async {
            await stop();
          },
          cancelOnError: true,
        );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  LocationStore get store => _store;
}
