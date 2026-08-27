import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/local/mappers/flight_weather_db_mapper.dart';
import 'package:flymap/domain/entity/flight_weather.dart';
import 'package:flymap/domain/entity/weather_attribution.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('FlightWeather survives a db round trip', () {
    const mapper = FlightWeatherDbMapper();
    final weather = FlightWeather(
      departure: AirportWeather(
        timeUtc: DateTime.utc(2026, 8, 3, 8),
        utcOffsetMinutes: 60,
        temperatureC: 21.5,
        windSpeedMs: 4.2,
        precipitationMm: 0.3,
        cloudCoverPercent: 35,
        symbolCode: 'partlycloudy_day',
        timeline: [
          AirportForecastSlice(
            timeUtc: DateTime.utc(2026, 8, 3, 5),
            temperatureC: 17,
            windSpeedMs: 2.5,
            precipitationMm: 0.2,
            cloudCoverPercent: 70,
            symbolCode: 'rain',
          ),
        ],
      ),
      arrival: AirportWeather(
        timeUtc: DateTime.utc(2026, 8, 3, 11),
        utcOffsetMinutes: 120,
      ),
      samples: [
        RouteCloudSample(
          routeProgress: 0.5,
          latLon: const LatLng(48.1, 5.3),
          timeUtc: DateTime.utc(2026, 8, 3, 9, 30),
          cloudLowPercent: 40,
          cloudMidPercent: 20,
          cloudHighPercent: 10,
          precipitationMm: 1.2,
          timeline: [
            CloudTimeSlice(
              timeUtc: DateTime.utc(2026, 8, 3, 9),
              cloudLowPercent: 35,
              cloudMidPercent: 18,
              cloudHighPercent: 12,
              precipitationMm: 0.8,
            ),
          ],
        ),
      ],
      areaSamples: [
        RouteCloudSample(
          routeProgress: 0.2,
          latLon: const LatLng(49, 3),
          timeUtc: DateTime.utc(2026, 8, 3, 8, 40),
          cloudLowPercent: 5,
          cloudMidPercent: 0,
          cloudHighPercent: 60,
        ),
      ],
      fetchedAt: DateTime.utc(2026, 8, 2, 18, 5),
      isTimeEstimated: true,
      attribution: const WeatherAttribution(
        providerName: 'Weather Co',
        providerUrl: 'https://weather.example',
        licenseName: 'Example license',
        licenseUrl: 'https://weather.example/license',
      ),
    );

    final restored = mapper.fromDb(mapper.toDb(weather));

    expect(restored, weather);
  });
}
