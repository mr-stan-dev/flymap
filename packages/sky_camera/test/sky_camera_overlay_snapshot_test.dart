import 'package:flutter_test/flutter_test.dart';
import 'package:sky_camera/sky_camera.dart';

void main() {
  test('round-trips snapshot through json', () {
    final snapshot = SkyCameraOverlaySnapshot(
      timestamp: DateTime.utc(2026, 7, 1, 12, 34, 56),
      routeLabel: 'LHR -> BCN',
      originCode: 'LHR',
      destinationCode: 'BCN',
      originCountryCode: 'GB',
      destinationCountryCode: 'ES',
      contextLabel: 'Mediterranean Sea',
      mapStatePlaceholder: 'Route preview',
      hasLiveLocation: true,
      latitude: 41.3851,
      longitude: 2.1734,
      headingDegrees: 180.0,
      altitudeMeters: 11000.0,
      speedMetersPerSecond: 230.0,
      horizontalAccuracyMeters: 12.0,
      outsideTemperatureCelsius: -48.5,
    );

    final decoded = SkyCameraOverlaySnapshot.fromJson(snapshot.toJson());

    expect(decoded, isNotNull);
    expect(decoded!.timestamp, snapshot.timestamp);
    expect(decoded.routeLabel, snapshot.routeLabel);
    expect(decoded.originCode, snapshot.originCode);
    expect(decoded.destinationCode, snapshot.destinationCode);
    expect(decoded.originCountryCode, snapshot.originCountryCode);
    expect(decoded.destinationCountryCode, snapshot.destinationCountryCode);
    expect(decoded.contextLabel, snapshot.contextLabel);
    expect(decoded.mapStatePlaceholder, snapshot.mapStatePlaceholder);
    expect(decoded.hasLiveLocation, snapshot.hasLiveLocation);
    expect(decoded.latitude, snapshot.latitude);
    expect(decoded.longitude, snapshot.longitude);
    expect(decoded.headingDegrees, snapshot.headingDegrees);
    expect(decoded.altitudeMeters, snapshot.altitudeMeters);
    expect(decoded.speedMetersPerSecond, snapshot.speedMetersPerSecond);
    expect(decoded.horizontalAccuracyMeters, snapshot.horizontalAccuracyMeters);
    expect(
      decoded.outsideTemperatureCelsius,
      snapshot.outsideTemperatureCelsius,
    );
  });
}
