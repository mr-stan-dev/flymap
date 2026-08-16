import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/location/app_location_client.dart';
import 'package:flymap/data/location/app_location_service.dart';
import 'package:flymap/ui/screens/sky_camera/flymap_sky_camera_overlay_snapshot_source.dart';
import 'package:flymap/ui/screens/sky_camera/flymap_sky_camera_session_factory.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  test(
    'overlay snapshot builder merges live device values with placeholders',
    () {
      const builder = FlymapSkyCameraOverlaySnapshotBuilder(
        placeholderCopy: FlymapSkyCameraPlaceholderCopy(
          routeLabel: 'London, UK → Barcelona, ES',
          originCode: 'LHR',
          destinationCode: 'BCN',
          originCountryCode: 'GB',
          destinationCountryCode: 'ES',
          contextLabel: 'Mediterranean Sea',
          mapPlaceholder: 'Route preview',
        ),
      );

      final snapshot = builder.build(
        timestamp: DateTime(2026, 6, 29, 12, 30),
        position: Position(
          longitude: 2.1734,
          latitude: 41.3851,
          timestamp: DateTime(2026, 6, 29, 12, 30),
          accuracy: 12,
          altitude: 1240,
          altitudeAccuracy: 18,
          heading: 187,
          headingAccuracy: 4,
          speed: 128,
          speedAccuracy: 6,
        ),
      );

      expect(snapshot.routeLabel, 'London, UK → Barcelona, ES');
      expect(snapshot.originCountryCode, 'GB');
      expect(snapshot.destinationCountryCode, 'ES');
      expect(snapshot.contextLabel, 'Mediterranean Sea');
      expect(snapshot.mapStatePlaceholder, 'Route preview');
      expect(snapshot.hasLiveLocation, isTrue);
      expect(snapshot.latitude, 41.3851);
      expect(snapshot.longitude, 2.1734);
      expect(snapshot.headingDegrees, 187);
      expect(snapshot.altitudeMeters, 1240);
      expect(snapshot.speedMetersPerSecond, 128);
      expect(snapshot.outsideTemperatureCelsius, isNull);
      expect(snapshot.outsideTemperatureIsEstimated, isFalse);
    },
  );

  test(
    'overlay snapshot builder keeps placeholders and leaves telemetry empty when live values are absent',
    () {
      const builder = FlymapSkyCameraOverlaySnapshotBuilder(
        placeholderCopy: FlymapSkyCameraPlaceholderCopy(
          routeLabel: 'London, UK → Barcelona, ES',
          originCode: 'LHR',
          destinationCode: 'BCN',
          originCountryCode: 'GB',
          destinationCountryCode: 'ES',
          contextLabel: 'Mediterranean Sea',
          mapPlaceholder: 'Route preview',
        ),
      );

      final snapshot = builder.build(
        timestamp: DateTime(2026, 6, 29, 12, 30),
        position: null,
      );

      expect(snapshot.routeLabel, 'London, UK → Barcelona, ES');
      expect(snapshot.hasLiveLocation, isFalse);
      expect(snapshot.latitude, isNull);
      expect(snapshot.longitude, isNull);
      expect(snapshot.headingDegrees, isNull);
      expect(snapshot.altitudeMeters, isNull);
      expect(snapshot.speedMetersPerSecond, isNull);
      expect(snapshot.horizontalAccuracyMeters, isNull);
      expect(snapshot.outsideTemperatureCelsius, isNull);
      expect(snapshot.outsideTemperatureIsEstimated, isFalse);
    },
  );

  test(
    'overlay snapshot builder keeps live coordinates but does not fake telemetry when speed is zero',
    () {
      const builder = FlymapSkyCameraOverlaySnapshotBuilder(
        placeholderCopy: FlymapSkyCameraPlaceholderCopy(
          routeLabel: 'London, UK → Barcelona, ES',
          originCode: 'LHR',
          destinationCode: 'BCN',
          originCountryCode: 'GB',
          destinationCountryCode: 'ES',
          contextLabel: 'Mediterranean Sea',
          mapPlaceholder: 'Route preview',
        ),
      );

      final snapshot = builder.build(
        timestamp: DateTime(2026, 6, 29, 12, 30),
        position: Position(
          longitude: 2.1734,
          latitude: 41.3851,
          timestamp: DateTime(2026, 6, 29, 12, 30),
          accuracy: 12,
          altitude: 18,
          altitudeAccuracy: 8,
          heading: 0,
          headingAccuracy: 4,
          speed: 0,
          speedAccuracy: 0,
        ),
      );

      expect(snapshot.hasLiveLocation, isTrue);
      expect(snapshot.latitude, 41.3851);
      expect(snapshot.longitude, 2.1734);
      expect(snapshot.speedMetersPerSecond, isNull);
      expect(snapshot.outsideTemperatureCelsius, isNull);
      expect(snapshot.outsideTemperatureIsEstimated, isFalse);
    },
  );

  test('estimates outside temperature only at reliable altitude', () {
    const builder = FlymapSkyCameraOverlaySnapshotBuilder(
      placeholderCopy: FlymapSkyCameraPlaceholderCopy(
        routeLabel: 'London, UK → Barcelona, ES',
        originCode: 'LHR',
        destinationCode: 'BCN',
        originCountryCode: 'GB',
        destinationCountryCode: 'ES',
        contextLabel: 'Mediterranean Sea',
        mapPlaceholder: 'Route preview',
      ),
    );

    final snapshot = builder.build(
      timestamp: DateTime.utc(2026, 6, 29, 12, 30),
      position: Position(
        longitude: 2.1734,
        latitude: 41.3851,
        timestamp: DateTime.utc(2026, 6, 29, 12, 30),
        accuracy: 12,
        altitude: 11000,
        altitudeAccuracy: 18,
        heading: 187,
        headingAccuracy: 4,
        speed: 230,
        speedAccuracy: 6,
      ),
    );

    expect(snapshot.outsideTemperatureCelsius, isNotNull);
    expect(snapshot.outsideTemperatureIsEstimated, isTrue);
  });

  test('suspend releases camera GPS and start restores it', () async {
    final locationClient = _TrackingLocationClient();
    final source = FlymapSkyCameraOverlaySnapshotSource(
      builder: const FlymapSkyCameraOverlaySnapshotBuilder(
        placeholderCopy: FlymapSkyCameraPlaceholderCopy(
          routeLabel: 'London, UK → Barcelona, ES',
          originCode: 'LHR',
          destinationCode: 'BCN',
          originCountryCode: 'GB',
          destinationCountryCode: 'ES',
          contextLabel: 'Mediterranean Sea',
          mapPlaceholder: 'Route preview',
        ),
      ),
      locationService: AppLocationService(client: locationClient),
    );

    await source.start();
    expect(locationClient.streamStartCount, 1);

    await source.suspend();
    expect(locationClient.streamCancelCount, 1);

    await source.start();
    expect(locationClient.streamStartCount, 2);

    await source.dispose();
    expect(locationClient.streamCancelCount, 2);
  });
}

class _TrackingLocationClient implements AppLocationClient {
  int streamStartCount = 0;
  int streamCancelCount = 0;

  @override
  Future<LocationPermission> checkPermission() async {
    return LocationPermission.whileInUse;
  }

  @override
  Future<Position> getCurrentPosition({
    required LocationAccuracy accuracy,
  }) async {
    throw StateError('No test position');
  }

  @override
  Stream<Position> getPositionStream({
    required LocationSettings locationSettings,
  }) {
    streamStartCount += 1;
    late final StreamController<Position> controller;
    controller = StreamController<Position>.broadcast(
      onCancel: () {
        streamCancelCount += 1;
        unawaited(controller.close());
      },
    );
    return controller.stream;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> requestPermission() async {
    return LocationPermission.whileInUse;
  }
}
