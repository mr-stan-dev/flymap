import 'package:flutter_test/flutter_test.dart';
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
    },
  );
}
