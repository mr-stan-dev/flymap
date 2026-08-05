import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/api/firebase_weather_forecast_api.dart';
import 'package:flymap/domain/provider/weather_forecast_provider.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('sends one provider-neutral batch and restores request order', () async {
    Map<String, dynamic>? sent;
    final api = FirebaseWeatherForecastApi(
      callable: (payload) async {
        sent = payload;
        return {
          'contractVersion': 1,
          'generatedAtUtc': '2026-08-05T09:05:00.000Z',
          'attribution': {
            'providerName': 'Weather Co',
            'providerUrl': 'https://weather.example',
            'licenseName': 'Example license',
            'licenseUrl': 'https://weather.example/license',
          },
          // Deliberately reversed: the adapter must restore request order by id.
          'locations': [
            {'id': '1', 'status': 'unavailable', 'points': <Object>[]},
            {
              'id': '0',
              'status': 'ok',
              'sourceUpdatedAtUtc': '2026-08-05T08:45:00.000Z',
              'retrievedAtUtc': '2026-08-05T09:00:00.000Z',
              'points': [
                {
                  'timeUtc': '2026-08-05T10:00:00.000Z',
                  'temperatureC': 18,
                  'windSpeedMs': 4.5,
                  'cloudCoverPercent': 60,
                  'cloudLowPercent': 40,
                  'cloudMidPercent': 20,
                  'cloudHighPercent': 5,
                  'precipitationMm': 1.5,
                  'conditionCode': 'partlycloudy_night',
                },
              ],
            },
          ],
        };
      },
    );

    final result = await api.forecastBatch(
      requests: [
        WeatherForecastRequest(
          coordinate: const LatLng(51.47, -0.45),
          targetTimeUtc: DateTime.utc(2026, 8, 5, 10),
        ),
        WeatherForecastRequest(
          coordinate: const LatLng(41.8, 12.25),
          targetTimeUtc: DateTime.utc(2026, 8, 5, 12),
        ),
      ],
      windowStartUtc: DateTime.utc(2026, 8, 5, 9),
      windowEndUtc: DateTime.utc(2026, 8, 5, 13),
    );

    expect(sent?['contractVersion'], 1);
    expect(sent?['locations'], hasLength(2));
    expect((sent?['locations'] as List).first, {
      'id': '0',
      'latitude': 51.47,
      'longitude': -0.45,
      'targetTimeUtc': '2026-08-05T10:00:00.000Z',
    });
    expect(result.seriesByRequest, hasLength(2));
    expect(result.seriesByRequest.first.single.temperatureC, 18);
    expect(
      result.seriesByRequest.first.single.symbolCode,
      'partlycloudy_night',
    );
    expect(result.seriesByRequest.last, isEmpty);
    expect(result.retrievedAtUtc, DateTime.utc(2026, 8, 5, 8, 45));
    expect(result.attribution.providerName, 'Weather Co');
    expect(result.attribution.licenseUrl, 'https://weather.example/license');
  });

  test('rejects incompatible contract versions', () async {
    final api = FirebaseWeatherForecastApi(
      callable: (_) async => {'contractVersion': 2, 'locations': <Object>[]},
    );

    await expectLater(
      api.forecastBatch(
        requests: [
          WeatherForecastRequest(
            coordinate: const LatLng(0, 0),
            targetTimeUtc: DateTime.utc(2026, 8, 5, 10),
          ),
        ],
        windowStartUtc: DateTime.utc(2026, 8, 5, 9),
        windowEndUtc: DateTime.utc(2026, 8, 5, 11),
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
