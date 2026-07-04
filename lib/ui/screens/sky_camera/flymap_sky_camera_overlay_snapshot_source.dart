import 'dart:async';

import 'package:flymap/data/location/app_location_service.dart';
import 'package:flymap/ui/screens/sky_camera/flymap_sky_camera_session_factory.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sky_camera/sky_camera.dart';

class FlymapSkyCameraOverlaySnapshotBuilder {
  const FlymapSkyCameraOverlaySnapshotBuilder({required this.placeholderCopy});

  final FlymapSkyCameraPlaceholderCopy placeholderCopy;

  SkyCameraOverlaySnapshot build({
    required DateTime timestamp,
    required Position? position,
  }) {
    final latitude = position?.latitude;
    final longitude = position?.longitude;
    final headingDegrees = _normalizeNumeric(position?.heading, minimum: 0);
    final altitudeMeters = _normalizeNumeric(position?.altitude);
    final speedMetersPerSecond = _normalizeNumeric(position?.speed, minimum: 0);
    final horizontalAccuracyMeters = _normalizeNumeric(
      position?.accuracy,
      minimum: 0,
    );

    return SkyCameraOverlaySnapshot(
      timestamp: timestamp,
      routeLabel: placeholderCopy.routeLabel,
      originCode: placeholderCopy.originCode,
      destinationCode: placeholderCopy.destinationCode,
      originCountryCode: placeholderCopy.originCountryCode,
      destinationCountryCode: placeholderCopy.destinationCountryCode,
      contextLabel: placeholderCopy.contextLabel,
      mapStatePlaceholder: placeholderCopy.mapPlaceholder,
      hasLiveLocation: latitude != null && longitude != null,
      latitude: latitude,
      longitude: longitude,
      headingDegrees: headingDegrees,
      altitudeMeters: altitudeMeters,
      speedMetersPerSecond:
          (speedMetersPerSecond != null && speedMetersPerSecond > 0)
          ? speedMetersPerSecond
          : null,
      horizontalAccuracyMeters: horizontalAccuracyMeters,
      outsideTemperatureCelsius: null,
    );
  }

  double? _normalizeNumeric(double? value, {double? minimum}) {
    if (value == null || !value.isFinite) return null;
    if (minimum != null && value < minimum) return null;
    return value;
  }
}

class FlymapSkyCameraOverlaySnapshotSource
    implements SkyCameraOverlaySnapshotSource {
  FlymapSkyCameraOverlaySnapshotSource({
    required this.builder,
    required this.locationService,
  });

  final FlymapSkyCameraOverlaySnapshotBuilder builder;
  final AppLocationService locationService;

  final StreamController<SkyCameraOverlaySnapshot> _controller =
      StreamController<SkyCameraOverlaySnapshot>.broadcast();
  StreamSubscription<Position>? _positionSubscription;
  AppLocationSession? _locationSession;
  bool _started = false;
  bool _disposed = false;

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _emit(position: locationService.latestPosition);
    _positionSubscription = locationService.watch().listen(
      (position) => _emit(position: position),
      onError: (_) {},
    );
    final session = await locationService.startSession(
      mode: AppLocationMode.camera,
      requestPermission: true,
    );
    if (_disposed) {
      await session.close();
      return;
    }
    _locationSession = session;
    _emit(position: session.latestPosition);
  }

  @override
  Stream<SkyCameraOverlaySnapshot> watch() => _controller.stream;

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _positionSubscription?.cancel();
    await _locationSession?.close();
    await _controller.close();
  }

  void _emit({required Position? position}) {
    if (_controller.isClosed) return;
    _controller.add(
      builder.build(timestamp: DateTime.now(), position: position),
    );
  }
}
