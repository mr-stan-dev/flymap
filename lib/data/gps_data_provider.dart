import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flymap/entity/gps_data.dart';

/// Provides GPS data updates and status changes
class GpsDataProvider {
  StreamSubscription<Position>? _subscription;

  Future<void> start({
    required void Function(GpsStatus status, {GpsData? data}) onUpdate,
  }) async {
    // Service enabled?
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      onUpdate(GpsStatus.off);
      return;
    }

    // Permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        onUpdate(GpsStatus.permissionsNotGranted);
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      onUpdate(GpsStatus.permissionsNotGranted);
      return;
    }

    onUpdate(GpsStatus.searching);

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _subscription = Geolocator.getPositionStream(locationSettings: settings)
        .listen(
          (pos) {
            final gps = GpsData(
              latitude: pos.latitude,
              longitude: pos.longitude,
              altitude: pos.altitude, // meters
              speed: pos.speed, // m/s
              course: pos.heading, // degrees
              accuracy: pos.accuracy, // meters
            );
            onUpdate(GpsStatus.gpsActive, data: gps);
          },
          onError: (err) {
            onUpdate(
              GpsStatus.weakSignal,
              data: const GpsData(accuracy: 100.0),
            );
          },
        );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
