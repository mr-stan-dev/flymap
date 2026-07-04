import 'package:flutter_test/flutter_test.dart';
import 'package:sky_camera/src/domain/models/sky_camera_overlay_snapshot.dart';
import 'package:sky_camera/src/presentation/formatters/sky_camera_route_presentation.dart';

void main() {
  test('domestic routes keep flags and omit subtitle country codes', () {
    final route = SkyCameraRoutePresentation.fromSnapshot(
      _snapshot(
        routeLabel: 'London, GB → Manchester, GB',
        originCountryCode: 'GB',
        destinationCountryCode: 'GB',
      ),
    );

    expect(route.isDomestic, isTrue);
    expect(route.originDisplay, '🇬🇧 LHR');
    expect(route.destinationDisplay, '🇬🇧 MAN');
    expect(route.subtitle, 'London → Manchester');
  });

  test('international routes retain flags and country codes', () {
    final route = SkyCameraRoutePresentation.fromSnapshot(
      _snapshot(
        routeLabel: 'London, GB → Barcelona, ES',
        originCountryCode: 'GB',
        destinationCountryCode: 'ES',
      ),
    );

    expect(route.isDomestic, isFalse);
    expect(route.originDisplay, '🇬🇧 LHR');
    expect(route.destinationDisplay, '🇪🇸 MAN');
    expect(route.subtitle, 'London, GB → Barcelona, ES');
  });
}

SkyCameraOverlaySnapshot _snapshot({
  required String routeLabel,
  required String originCountryCode,
  required String destinationCountryCode,
}) {
  return SkyCameraOverlaySnapshot(
    timestamp: DateTime(2026, 7, 4),
    routeLabel: routeLabel,
    originCode: 'LHR',
    destinationCode: 'MAN',
    originCountryCode: originCountryCode,
    destinationCountryCode: destinationCountryCode,
    contextLabel: '',
    mapStatePlaceholder: '',
    hasLiveLocation: false,
    latitude: null,
    longitude: null,
    headingDegrees: null,
    altitudeMeters: null,
    speedMetersPerSecond: null,
  );
}
