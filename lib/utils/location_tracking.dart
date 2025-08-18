import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'loc_store.dart';

class LocationTracking {
  static StreamSubscription<Position>? _sub;

  static Future<void> startForegroundTracking() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return;
    }

    final Stream<Position> stream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 75,
      ),
    );

    await _sub?.cancel();
    _sub = stream.listen((Position pos) {
      LocStore.addSample(pos);
    });
  }

  static Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}
