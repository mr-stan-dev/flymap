import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/flight_weather.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/cloud_field_builder.dart';
import 'package:latlong2/latlong.dart';

RouteCloudSample _sample({
  required double progress,
  required double hidden,
  double high = 0,
  double precip = 0,
}) {
  return RouteCloudSample(
    routeProgress: progress,
    latLon: const LatLng(50, 0),
    timeUtc: DateTime.utc(2026, 8, 3, 10),
    cloudLowPercent: hidden,
    cloudMidPercent: 0,
    cloudHighPercent: high,
    precipitationMm: precip,
  );
}

CloudFieldBuilder _builder(List<RouteCloudSample> samples) {
  // Samples spread evenly across the viewport diagonal.
  final positions = [
    for (var i = 0; i < samples.length; i++)
      Offset(
        540 * (i + 0.5) / samples.length,
        800 * (i + 0.5) / samples.length,
      ),
  ];
  return CloudFieldBuilder(
    samples: samples,
    positions: positions,
    viewportWidth: 540,
    viewportHeight: 800,
  );
}

double _meanAlpha(Uint8List rgba) {
  var total = 0;
  for (var i = 3; i < rgba.length; i += 4) {
    total += rgba[i];
  }
  return total / (rgba.length ~/ 4) / 255;
}

void main() {
  final start = DateTime.utc(2026, 8, 3, 9);
  final end = DateTime.utc(2026, 8, 3, 12);

  test('clear skies produce a fully transparent field', () {
    final builder = _builder([
      for (var i = 0; i < 6; i++) _sample(progress: i / 5, hidden: 0),
    ]);
    final frames = builder.buildFrameBuffers(
      frameCount: 3,
      start: start,
      end: end,
    ).toList();

    expect(frames, hasLength(3));
    expect(frames.first.length, builder.fieldWidth * builder.fieldHeight * 4);
    for (final frame in frames) {
      expect(_meanAlpha(frame), 0);
    }
  });

  test('overcast covers most of the field, but never opaque', () {
    final builder = _builder([
      for (var i = 0; i < 6; i++) _sample(progress: i / 5, hidden: 100),
    ]);
    final frame = builder.buildFrameBuffers(
      frameCount: 1,
      start: start,
      end: start,
    ).single;

    expect(_meanAlpha(frame), greaterThan(0.5));
    for (var i = 3; i < frame.length; i += 4) {
      // Semi-transparent by design: the map must always show through.
      expect(frame[i], lessThanOrEqualTo((0.85 * 255).ceil()));
    }
  });

  test('partial cover is patchy: some clear pixels, some cloudy', () {
    final builder = _builder([
      for (var i = 0; i < 6; i++) _sample(progress: i / 5, hidden: 50),
    ]);
    final frame = builder.buildFrameBuffers(
      frameCount: 1,
      start: start,
      end: start,
    ).single;

    final mean = _meanAlpha(frame);
    expect(mean, greaterThan(0.05));
    expect(mean, lessThan(0.6));
    var clear = 0;
    var cloudy = 0;
    for (var i = 3; i < frame.length; i += 4) {
      if (frame[i] == 0) clear++;
      if (frame[i] > 100) cloudy++;
    }
    expect(clear, greaterThan(0), reason: 'gaps between clouds expected');
    expect(cloudy, greaterThan(0), reason: 'cloud cores expected');
  });

  test('rain recolors cloud cores along the blue-violet ramp', () {
    Uint8List frame(double precip) => _builder([
      for (var i = 0; i < 6; i++)
        _sample(progress: i / 5, hidden: 100, precip: precip),
    ]).buildFrameBuffers(frameCount: 1, start: start, end: start).single;

    final dry = frame(0);
    final rainy = frame(5);

    var dryRed = 0, dryBlue = 0, dryAlpha = 0;
    var rainyRed = 0, rainyGreen = 0, rainyBlue = 0, rainyAlpha = 0;
    for (var i = 0; i < dry.length; i += 4) {
      dryRed += dry[i];
      dryBlue += dry[i + 2];
      dryAlpha += dry[i + 3];
      rainyRed += rainy[i];
      rainyGreen += rainy[i + 1];
      rainyBlue += rainy[i + 2];
      rainyAlpha += rainy[i + 3];
    }
    // Rain never thins the deck — thin noise spots gain a rain wash, the
    // rest keeps its coverage...
    expect(rainyAlpha, greaterThanOrEqualTo(dryAlpha));
    // ...and the wet core turns violet: blue on top, green lowest, red
    // between — a chromatic shift, not the old grey darkening (which was
    // invisible over the dark map).
    expect(rainyBlue, greaterThan(rainyRed));
    expect(rainyRed, greaterThan(rainyGreen));
    // Dry cloud is neutral grey (blue ~ red); rain opens a wide gap —
    // at least 8/255 mean per pixel.
    final pixels = dry.length ~/ 4;
    expect(rainyBlue - rainyRed, greaterThan((dryBlue - dryRed) + 8 * pixels));
  });

  test('rain stays visible even where instant cloud cover is zero', () {
    // 6-hourly horizons can forecast a rain block while the instant cloud
    // fraction is still low; the airport card then shows rain and the map
    // must not render clear air (the invisible-rain half of the JFK bug).
    final frame = _builder([
      for (var i = 0; i < 6; i++)
        _sample(progress: i / 5, hidden: 0, precip: 3),
    ]).buildFrameBuffers(frameCount: 1, start: start, end: start).single;

    final mean = _meanAlpha(frame);
    expect(mean, greaterThan(0.25), reason: 'rain wash expected');
    var red = 0, blue = 0;
    for (var i = 0; i < frame.length; i += 4) {
      red += frame[i];
      blue += frame[i + 2];
    }
    expect(blue, greaterThan(red), reason: 'rain wash reads violet, not white');
  });
}
