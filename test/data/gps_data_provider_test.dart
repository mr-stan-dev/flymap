import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/gps_data_provider.dart';
import 'package:flymap/data/location/app_location_client.dart';
import 'package:flymap/data/location/app_location_service.dart';
import 'package:flymap/domain/entity/gps_data.dart';
import 'package:flymap/repository/metric_units_repository.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'publishes latest fix immediately from a flight location session',
    () async {
      SharedPreferences.setMockInitialValues({});
      final client = _FakeAppLocationClient(
        position: _position(latitude: 51.47, longitude: -0.45),
      );
      final provider = GpsDataProvider(
        locationService: AppLocationService(client: client),
        unitsRepository: MetricUnitsRepository(),
      );
      final updates = <({GpsStatus status, GpsData? data})>[];

      await provider.start(
        onUpdate: (status, {data}) {
          updates.add((status: status, data: data));
        },
      );
      await Future<void>.delayed(Duration.zero);

      expect(updates.first.status, GpsStatus.searching);
      expect(updates.last.status, GpsStatus.gpsActive);
      expect(updates.last.data?.latitude, 51.47);
      expect(updates.last.data?.speed?.unit, 'km/h');
      expect(updates.last.data?.speedAccuracy, 5);
      expect(updates.last.data?.courseAccuracy, 5);
      expect(updates.last.data?.recordedAt, client.position.timestamp.toUtc());
      expect(
        client.streamSettings.single.accuracy,
        LocationAccuracy.bestForNavigation,
      );

      await provider.stop();
      await client.dispose();
    },
  );
}

class _FakeAppLocationClient implements AppLocationClient {
  _FakeAppLocationClient({required this.position});

  final Position position;
  final List<LocationSettings> streamSettings = [];
  final StreamController<Position> _controller =
      StreamController<Position>.broadcast();

  @override
  Future<LocationPermission> checkPermission() async {
    return LocationPermission.whileInUse;
  }

  @override
  Future<Position> getCurrentPosition({
    required LocationAccuracy accuracy,
  }) async {
    return position;
  }

  @override
  Stream<Position> getPositionStream({
    required LocationSettings locationSettings,
  }) {
    streamSettings.add(locationSettings);
    return _controller.stream;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> requestPermission() async {
    return LocationPermission.whileInUse;
  }

  Future<void> dispose() => _controller.close();
}

Position _position({required double latitude, required double longitude}) {
  return Position(
    longitude: longitude,
    latitude: latitude,
    timestamp: DateTime.now(),
    accuracy: 12,
    altitude: 1000,
    altitudeAccuracy: 20,
    heading: 90,
    headingAccuracy: 5,
    speed: 200,
    speedAccuracy: 5,
  );
}
