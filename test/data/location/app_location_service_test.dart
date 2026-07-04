import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/location/app_location_client.dart';
import 'package:flymap/data/location/app_location_service.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  test('foreground warmup seeds location without owning a stream', () async {
    final client = _FakeAppLocationClient(
      serviceEnabled: true,
      permission: LocationPermission.whileInUse,
      currentPosition: _position(latitude: 51.5, longitude: -0.4),
    );
    final service = AppLocationService(client: client);

    await service.warmUpIfPermitted();
    await Future<void>.delayed(Duration.zero);

    expect(service.latestPosition?.latitude, 51.5);
    expect(service.latestPosition?.longitude, -0.4);
    expect(client.streamSettings, isEmpty);
    expect(client.currentPositionAccuracies, [LocationAccuracy.medium]);
  });

  test('foreground warmup discards stale positions', () async {
    final client = _FakeAppLocationClient(
      serviceEnabled: true,
      permission: LocationPermission.whileInUse,
      currentPosition: _positionAt(
        latitude: 51.5,
        longitude: -0.4,
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    );
    final service = AppLocationService(client: client);

    await service.warmUpIfPermitted();
    await Future<void>.delayed(Duration.zero);

    expect(service.latestPosition, isNull);
  });

  test(
    'camera session uses navigation settings and releases its stream',
    () async {
      final client = _FakeAppLocationClient(
        serviceEnabled: true,
        permission: LocationPermission.denied,
        requestedPermissionResult: LocationPermission.whileInUse,
        currentPosition: _position(latitude: 41.38, longitude: 2.17),
      );
      final service = AppLocationService(client: client);

      final session = await service.startSession(
        mode: AppLocationMode.camera,
        requestPermission: true,
      );

      expect(session.availability, AppLocationAvailability.available);
      expect(client.requestPermissionCallCount, 1);
      expect(client.streamSettings, hasLength(1));
      expect(
        client.streamSettings.single.accuracy,
        LocationAccuracy.bestForNavigation,
      );

      await session.close();

      expect(client.streamCancelCount, 1);
    },
  );

  test('camera and flight sessions share one navigation stream', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final client = _FakeAppLocationClient(
      serviceEnabled: true,
      permission: LocationPermission.whileInUse,
      currentPosition: _position(latitude: 51.5, longitude: -0.4),
    );
    final service = AppLocationService(client: client);
    final cameraSession = await service.startSession(
      mode: AppLocationMode.camera,
      requestPermission: false,
    );

    final flightSession = await service.startSession(
      mode: AppLocationMode.flight,
      requestPermission: false,
    );

    expect(client.streamSettings, hasLength(1));
    final cameraSettings = client.streamSettings[0] as AppleSettings;
    expect(cameraSettings.accuracy, LocationAccuracy.bestForNavigation);
    expect(cameraSettings.activityType, ActivityType.airborne);
    expect(cameraSettings.distanceFilter, 0);
    expect(cameraSettings.pauseLocationUpdatesAutomatically, isFalse);
    expect(client.streamCancelCount, 0);

    await flightSession.close();

    expect(client.streamSettings, hasLength(1));
    expect(client.streamCancelCount, 0);

    await cameraSession.close();
    expect(client.streamCancelCount, 1);
  });

  test('pending one-shot fix does not block a flight session', () async {
    final currentPositionCompleter = Completer<Position>();
    final client = _FakeAppLocationClient(
      serviceEnabled: true,
      permission: LocationPermission.whileInUse,
      currentPositionCompleter: currentPositionCompleter,
    );
    final service = AppLocationService(client: client);

    await service.warmUpIfPermitted();
    final session = await service.startSession(
      mode: AppLocationMode.flight,
      requestPermission: false,
    );

    expect(session.availability, AppLocationAvailability.available);
    expect(
      client.streamSettings.single.accuracy,
      LocationAccuracy.bestForNavigation,
    );

    await session.close();
    currentPositionCompleter.complete(
      _position(latitude: 51.47, longitude: -0.45),
    );
  });

  test('new consumers can immediately read the latest seeded fix', () async {
    final current = _position(latitude: 40.64, longitude: -73.78);
    final client = _FakeAppLocationClient(
      serviceEnabled: true,
      permission: LocationPermission.whileInUse,
      currentPosition: current,
    );
    final service = AppLocationService(client: client);

    await service.warmUpIfPermitted();
    final session = await service.startSession(
      mode: AppLocationMode.flight,
      requestPermission: false,
    );

    expect(session.latestPosition, current);

    await session.close();
  });
}

class _FakeAppLocationClient implements AppLocationClient {
  _FakeAppLocationClient({
    required this.serviceEnabled,
    required this.permission,
    this.requestedPermissionResult,
    this.currentPosition,
    this.currentPositionCompleter,
  });

  final bool serviceEnabled;
  LocationPermission permission;
  final LocationPermission? requestedPermissionResult;
  final Position? currentPosition;
  final Completer<Position>? currentPositionCompleter;
  final List<LocationSettings> streamSettings = [];
  final List<LocationAccuracy> currentPositionAccuracies = [];
  int requestPermissionCallCount = 0;
  int streamCancelCount = 0;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<Position> getCurrentPosition({
    required LocationAccuracy accuracy,
  }) async {
    currentPositionAccuracies.add(accuracy);
    final completer = currentPositionCompleter;
    if (completer != null) {
      return completer.future;
    }
    final position = currentPosition;
    if (position == null) {
      throw Exception('No current position');
    }
    return position;
  }

  @override
  Stream<Position> getPositionStream({
    required LocationSettings locationSettings,
  }) {
    streamSettings.add(locationSettings);
    late StreamController<Position> controller;
    controller = StreamController<Position>.broadcast(
      onCancel: () {
        streamCancelCount += 1;
        unawaited(controller.close());
      },
    );
    return controller.stream;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> requestPermission() async {
    requestPermissionCallCount += 1;
    final next = requestedPermissionResult ?? permission;
    permission = next;
    return next;
  }
}

Position _position({required double latitude, required double longitude}) {
  return _positionAt(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.now(),
  );
}

Position _positionAt({
  required double latitude,
  required double longitude,
  required DateTime timestamp,
}) {
  return Position(
    longitude: longitude,
    latitude: latitude,
    timestamp: timestamp,
    accuracy: 12,
    altitude: 300,
    altitudeAccuracy: 8,
    heading: 90,
    headingAccuracy: 4,
    speed: 120,
    speedAccuracy: 6,
  );
}
