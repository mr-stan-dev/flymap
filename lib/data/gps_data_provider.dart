import 'dart:async';

import 'package:flymap/data/location/app_location_service.dart';
import 'package:flymap/domain/entity/gps_data.dart';
import 'package:flymap/repository/metric_units_repository.dart';
import 'package:geolocator/geolocator.dart';

class GpsDataProvider {
  GpsDataProvider({
    required AppLocationService locationService,
    required MetricUnitsRepository unitsRepository,
  }) : _locationService = locationService,
       _unitsRepository = unitsRepository;

  final AppLocationService _locationService;
  final MetricUnitsRepository _unitsRepository;

  AppLocationSession? _session;
  StreamSubscription<Position>? _subscription;

  Future<void> start({
    required void Function(GpsStatus status, {GpsData? data}) onUpdate,
  }) async {
    await stop();
    onUpdate(GpsStatus.searching);

    final speedUnit = await _unitsRepository.getSpeedUnit();
    final altitudeUnit = await _unitsRepository.getAltitudeUnit();
    final session = await _locationService.startSession(
      mode: AppLocationMode.flight,
      requestPermission: true,
    );
    _session = session;

    switch (session.availability) {
      case AppLocationAvailability.serviceDisabled:
        onUpdate(GpsStatus.off);
        return;
      case AppLocationAvailability.permissionDenied:
        onUpdate(GpsStatus.permissionsNotGranted);
        return;
      case AppLocationAvailability.available:
        break;
    }

    void publish(Position position) {
      final mph = speedUnit.name == 'mph';
      final speedValue = mph
          ? position.speed * 2.23693629
          : position.speed * 3.6;
      final speed = SpeedValue(speedValue, mph ? 'mph' : 'km/h');

      final isMeter = altitudeUnit.name == 'meter';
      final altitudeValue = isMeter
          ? position.altitude
          : position.altitude * 3.28084;
      final altitude = AltitudeValue(altitudeValue, isMeter ? 'm' : 'ft');
      final altitudeAccuracy = position.altitudeAccuracy > 0
          ? position.altitudeAccuracy
          : null;
      final data = GpsData(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: altitude,
        speed: speed,
        course: position.heading,
        accuracy: position.accuracy,
        altitudeAccuracy: altitudeAccuracy,
      );
      final status =
          position.accuracy <= 40 &&
              (altitudeAccuracy == null || altitudeAccuracy <= 1000)
          ? GpsStatus.gpsActive
          : GpsStatus.weakSignal;
      onUpdate(status, data: data);
    }

    final latestPosition = session.latestPosition;
    if (latestPosition != null) {
      publish(latestPosition);
    }
    _subscription = session.watch().listen(
      publish,
      onError: (_, _) => onUpdate(GpsStatus.searching),
    );
  }

  Future<void> stop() async {
    final subscription = _subscription;
    final session = _session;
    _subscription = null;
    _session = null;
    await subscription?.cancel();
    await session?.close();
  }
}
