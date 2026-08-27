import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/weather_symbols.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('uses calculated day/night instead of a provider suffix', () {
    expect(
      weatherSymbolKind('clearsky_night', 0, isDaytime: true),
      WeatherSymbolKind.clearDay,
    );
    expect(
      weatherSymbolKind('fair_day', 20, isDaytime: false),
      WeatherSymbolKind.fairNight,
    );
    expect(
      weatherSymbolKind('partlycloudy_day', 60, isDaytime: false),
      WeatherSymbolKind.partlyCloudyNight,
    );
  });

  test('calculates daylight from forecast UTC time and coordinates', () {
    const london = LatLng(51.47, -0.45);
    expect(
      weatherIsDaytime(
        timeUtc: DateTime.utc(2026, 6, 21, 12),
        utcOffsetMinutes: 60,
        coordinate: london,
      ),
      isTrue,
    );
    expect(
      weatherIsDaytime(
        timeUtc: DateTime.utc(2026, 6, 21),
        utcOffsetMinutes: 60,
        coordinate: london,
      ),
      isFalse,
    );
  });

  test('preserves declared rain intensity before using amount fallback', () {
    expect(
      weatherSymbolKind(
        'rain_showers_light',
        100,
        isDaytime: true,
        precipitationMm: 9,
      ),
      WeatherSymbolKind.lightRainDay,
    );
    expect(
      weatherSymbolKind(
        'rain_heavy',
        100,
        isDaytime: false,
        precipitationMm: 0.2,
      ),
      WeatherSymbolKind.heavyRainNight,
    );
  });

  test('uses three precipitation bands for generic rain codes', () {
    expect(
      weatherSymbolKind('rain', 100, isDaytime: true, precipitationMm: 0.2),
      WeatherSymbolKind.lightRainDay,
    );
    expect(
      weatherSymbolKind('rain', 100, isDaytime: true, precipitationMm: 3),
      WeatherSymbolKind.rainDay,
    );
    expect(
      weatherSymbolKind('rain', 100, isDaytime: true, precipitationMm: 8),
      WeatherSymbolKind.heavyRainDay,
    );
  });

  test('uses intensity and daylight variants for snow and thunder', () {
    expect(
      weatherSymbolKind('snow_light', 100, isDaytime: false),
      WeatherSymbolKind.lightSnowNight,
    );
    expect(
      weatherSymbolKind('snow_heavy', 100, isDaytime: true),
      WeatherSymbolKind.heavySnowDay,
    );
    expect(
      weatherSymbolKind('thunder_light', 100, isDaytime: true),
      WeatherSymbolKind.isolatedThunderDay,
    );
    expect(
      weatherSymbolKind('thunder', 100, isDaytime: false),
      WeatherSymbolKind.scatteredThunderNight,
    );
    expect(
      weatherSymbolKind('thunder_heavy', 100, isDaytime: false),
      WeatherSymbolKind.severeThunder,
    );
  });

  test('uses all cloud-cover levels when condition is unavailable', () {
    expect(
      weatherSymbolKind(null, 5, isDaytime: true),
      WeatherSymbolKind.clearDay,
    );
    expect(
      weatherSymbolKind(null, 25, isDaytime: false),
      WeatherSymbolKind.fairNight,
    );
    expect(
      weatherSymbolKind(null, 50, isDaytime: true),
      WeatherSymbolKind.partlyCloudyDay,
    );
    expect(
      weatherSymbolKind(null, 80, isDaytime: false),
      WeatherSymbolKind.mostlyCloudyNight,
    );
    expect(
      weatherSymbolKind(null, 95, isDaytime: true),
      WeatherSymbolKind.cloudy,
    );
  });

  test('emoji fallback uses the same normalized presentation', () {
    expect(
      weatherSymbolEmoji(
        'rain_light',
        100,
        isDaytime: true,
        precipitationMm: 0.2,
      ),
      '🌦️',
    );
    expect(weatherSymbolEmoji('clearsky', 0, isDaytime: false), '🌙');
  });

  testWidgets('all weather SVG assets are bundled and renderable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Wrap(
          children: [
            for (final symbol in WeatherSymbolKind.values)
              SizedBox(
                width: 56,
                height: 48,
                child: SvgPicture.asset(symbol.assetPath),
              ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byType(SvgPicture),
      findsNWidgets(WeatherSymbolKind.values.length),
    );
  });
}
