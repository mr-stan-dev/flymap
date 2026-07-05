import 'package:flutter_test/flutter_test.dart';
import 'package:sky_camera/sky_camera.dart';

void main() {
  test('shows each available metric using configured user units', () {
    final formatter = SkyCameraTelemetryFormatter(
      snapshot: _snapshot(),
      strings: _strings,
    );

    expect(formatter.visibleMetricDisplays.map((metric) => metric.value), [
      '~-52°C',
      '5.1 km',
      '224 mph',
    ]);
  });

  test('formats estimated temperature in Fahrenheit when configured', () {
    final formatter = SkyCameraTelemetryFormatter(
      snapshot: _snapshot(outsideTemperatureCelsius: 0),
      strings: _stringsFahrenheit,
    );

    expect(formatter.temperatureLabel, '~32°F');
  });

  test('shows tech strip with valid GPS even when speed is unavailable', () {
    final formatter = SkyCameraTelemetryFormatter(
      snapshot: _snapshot(
        speedMetersPerSecond: null,
        outsideTemperatureCelsius: null,
      ),
      strings: _strings,
    );

    expect(formatter.shouldShowTechStrip, isTrue);
    expect(formatter.visibleMetricDisplays.map((metric) => metric.value), [
      '5.1 km',
    ]);
  });

  test('hides tech strip when coordinates are outside valid ranges', () {
    final formatter = SkyCameraTelemetryFormatter(
      snapshot: _snapshot(latitude: 91),
      strings: _strings,
    );

    expect(formatter.shouldShowTechStrip, isFalse);
  });

  test('filters speed below the stationary noise threshold', () {
    final formatter = SkyCameraTelemetryFormatter(
      snapshot: _snapshot(
        speedMetersPerSecond: 4.99,
        outsideTemperatureCelsius: null,
      ),
      strings: _strings,
    );

    expect(formatter.visibleMetricDisplays.map((metric) => metric.value), [
      '5.1 km',
    ]);
  });

  test('treats zero Celsius as valid data', () {
    final formatter = SkyCameraTelemetryFormatter(
      snapshot: _snapshot(
        altitudeMeters: null,
        speedMetersPerSecond: null,
        outsideTemperatureCelsius: 0,
      ),
      strings: _strings,
    );

    expect(formatter.visibleMetricDisplays.map((metric) => metric.value), [
      '~0°C',
    ]);
  });

  test('can explicitly show unavailable metrics for component previews', () {
    final formatter = SkyCameraTelemetryFormatter(
      snapshot: _snapshot(
        hasLiveLocation: false,
        latitude: null,
        longitude: null,
        altitudeMeters: null,
        speedMetersPerSecond: null,
        outsideTemperatureCelsius: null,
      ),
      strings: _strings,
      visibilityPolicy: const SkyCameraTelemetryVisibilityPolicy.debug(),
    );

    expect(formatter.shouldShowTechStrip, isTrue);
    expect(formatter.visibleMetricDisplays.map((metric) => metric.value), [
      '--',
      '--',
      '--',
    ]);
  });

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
  temperatureUnit: SkyCameraTemperatureUnit.celsius,
  dateDisplayFormat: SkyCameraDateDisplayFormat.dayMonthYear,
);

const _stringsFahrenheit = SkyCameraStrings(
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
  temperatureUnit: SkyCameraTemperatureUnit.fahrenheit,
  dateDisplayFormat: SkyCameraDateDisplayFormat.dayMonthYear,
);

SkyCameraOverlaySnapshot _snapshot({
  bool hasLiveLocation = true,
  double? latitude = 51.47,
  double? longitude = -0.45,
  double? altitudeMeters = 5100,
  double? speedMetersPerSecond = 100,
  double? outsideTemperatureCelsius = -52.4,
  double? horizontalAccuracyMeters = 12,
  bool outsideTemperatureIsEstimated = true,
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
    altitudeMeters: altitudeMeters,
    speedMetersPerSecond: speedMetersPerSecond,
    horizontalAccuracyMeters: horizontalAccuracyMeters,
    outsideTemperatureCelsius: outsideTemperatureCelsius,
    outsideTemperatureIsEstimated: outsideTemperatureIsEstimated,
  );
}
