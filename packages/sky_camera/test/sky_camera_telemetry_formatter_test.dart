import 'package:flutter_test/flutter_test.dart';
import 'package:sky_camera/sky_camera.dart';

void main() {
  test(
    'formats temperature, altitude and speed using configured user units',
    () {
      final formatter = SkyCameraTelemetryFormatter(
        snapshot: _snapshot(),
        strings: _strings,
      );

      expect(formatter.temperatureLabel, '-52°C');
      expect(formatter.altitudeLabel, '5.1 km');
      expect(formatter.speedLabel, '224 mph');
    },
  );

  test('keeps telemetry visible in debug when gps is unavailable', () {
    final formatter = SkyCameraTelemetryFormatter(
      snapshot: _snapshot(
        hasLiveLocation: false,
        latitude: null,
        longitude: null,
      ),
      strings: _strings,
    );

    expect(formatter.visibleMetricDisplays, hasLength(3));
    expect(formatter.visibleMetricDisplays[0].value, '-52°C');
    expect(formatter.visibleMetricDisplays[1].value, '5.1 km');
    expect(formatter.visibleMetricDisplays[2].value, '224 mph');
  });

  test('keeps telemetry visible in debug when speed is zero', () {
    final formatter = SkyCameraTelemetryFormatter(
      snapshot: _snapshot(speedMetersPerSecond: 0),
      strings: _strings,
    );

    expect(formatter.visibleMetricDisplays, hasLength(3));
    expect(formatter.visibleMetricDisplays[2].value, '0 mph');
  });

  test(
    'keeps temperature chip visible in debug when rounded temperature is zero',
    () {
      final formatter = SkyCameraTelemetryFormatter(
        snapshot: _snapshot(outsideTemperatureCelsius: 0.2),
        strings: _strings,
      );

      expect(formatter.visibleMetricDisplays, hasLength(3));
      expect(formatter.visibleMetricDisplays.first.value, '0°C');
    },
  );

  test('maps gps accuracy to the same three signal bands as flight screen', () {
    expect(
      SkyCameraTelemetryFormatter(
        snapshot: _snapshot(horizontalAccuracyMeters: null),
        strings: _strings,
      ).gpsSignalStrength,
      SkyCameraGpsSignalStrength.none,
    );
    expect(
      SkyCameraTelemetryFormatter(
        snapshot: _snapshot(horizontalAccuracyMeters: 41),
        strings: _strings,
      ).gpsSignalStrength,
      SkyCameraGpsSignalStrength.bad,
    );
    expect(
      SkyCameraTelemetryFormatter(
        snapshot: _snapshot(horizontalAccuracyMeters: 40),
        strings: _strings,
      ).gpsSignalStrength,
      SkyCameraGpsSignalStrength.poor,
    );
    expect(
      SkyCameraTelemetryFormatter(
        snapshot: _snapshot(horizontalAccuracyMeters: 15),
        strings: _strings,
      ).gpsSignalStrength,
      SkyCameraGpsSignalStrength.good,
    );
  });
}

const _strings = SkyCameraStrings(
  loadingCamera: 'Loading camera...',
  loadingGpsData: 'Loading GPS data',
  retry: 'Retry',
  close: 'Close',
  zoom: 'Zoom',
  flash: 'Flash',
  captureFailed: 'Capture failed',
  cameraUnavailable: 'Camera unavailable',
  cameraPermissionDenied: 'Permission denied',
  savedMessage: 'Photo saved',
  share: 'Share',
  telemetrySpeed: 'Speed',
  telemetryAltitude: 'Altitude',
  telemetryHeading: 'Heading',
  telemetryTime: 'Time',
  contextCaption: 'Context',
  mapCaption: 'Map',
  coordinatesCaption: 'Coordinates',
  noValuePlaceholder: '--',
  altitudeUnit: SkyCameraAltitudeUnit.meter,
  speedUnit: SkyCameraSpeedUnit.mph,
  dateDisplayFormat: SkyCameraDateDisplayFormat.dayMonthYear,
);

SkyCameraOverlaySnapshot _snapshot({
  bool hasLiveLocation = true,
  double? latitude = 51.47,
  double? longitude = -0.45,
  double? speedMetersPerSecond = 100,
  double? outsideTemperatureCelsius = -52.4,
  double? horizontalAccuracyMeters = 12,
}) {
  return SkyCameraOverlaySnapshot(
    timestamp: DateTime.utc(2026, 7, 2, 12, 0),
    routeLabel: 'London, UK → Berlin, DE',
    originCode: 'LHR',
    destinationCode: 'BER',
    originCountryCode: 'GB',
    destinationCountryCode: 'DE',
    contextLabel: 'North Sea',
    mapStatePlaceholder: 'Route preview',
    hasLiveLocation: hasLiveLocation,
    latitude: latitude,
    longitude: longitude,
    headingDegrees: 90,
    altitudeMeters: 5100,
    speedMetersPerSecond: speedMetersPerSecond,
    horizontalAccuracyMeters: horizontalAccuracyMeters,
    outsideTemperatureCelsius: outsideTemperatureCelsius,
  );
}
