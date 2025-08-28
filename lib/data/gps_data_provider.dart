import 'dart:async';

import 'package:flymap/entity/gps_data.dart';
import 'package:flymap/repository/metric_units_repository.dart';
import 'package:geolocator/geolocator.dart';

/// Provides GPS data updates and status changes
class GpsDataProvider {
  StreamSubscription<Position>? _subscription;
  final MetricUnitsRepository _unitsRepository;

  GpsDataProvider({MetricUnitsRepository? unitsRepository})
    : _unitsRepository = unitsRepository ?? MetricUnitsRepository();

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

    final speedUnit = await _unitsRepository.getSpeedUnit();
    final altitudeUnit = await _unitsRepository.getAltitudeUnit();

    _subscription = Geolocator.getPositionStream(locationSettings: settings)
        .listen(
          (pos) {
            // Raw from geolocator: speed m/s, altitude meters
            final mph = speedUnit.name == 'mph';
            final speedValue = mph
                ? pos.speed * 2.23693629
                : pos.speed * 3.6; // -> mph or km/h
            final speed = SpeedValue(speedValue, mph ? 'mph' : 'km/h');

            final isMeter = altitudeUnit.name == 'meter';
            final altitudeValue = isMeter
                ? pos.altitude
                : pos.altitude * 3.28084; // -> m or ft
            final altitude = AltitudeValue(altitudeValue, isMeter ? 'm' : 'ft');

            final gps = GpsData(
              latitude: pos.latitude,
              longitude: pos.longitude,
              altitude: altitude,
              speed: speed,
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
