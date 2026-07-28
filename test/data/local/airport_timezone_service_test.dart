import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/local/airport_timezone_service.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:latlong2/latlong.dart';

Airport _airport(String icao, String iata) {
  return Airport(
    name: icao,
    city: icao,
    countryCode: 'XX',
    latLon: const LatLng(0, 0),
    iataCode: iata,
    icaoCode: icao,
    wikipediaUrl: '',
  );
}

void main() {
  final service = AirportTimezoneService(
    airportsDatabase: AirportsDatabase.test(
      seedTimezones: {
        'EDDF': 'Europe/Berlin',
        'KJFK': 'America/New_York',
        'VNKT': 'Asia/Kathmandu',
        'JFK': 'America/New_York',
      },
    ),
  );

  test('resolves DST-correct offsets per date', () {
    final frankfurt = _airport('EDDF', 'FRA');
    expect(
      service.utcOffsetMinutes(frankfurt, DateTime.utc(2026, 8, 3, 12)),
      120,
    );
    expect(
      service.utcOffsetMinutes(frankfurt, DateTime.utc(2026, 1, 15, 12)),
      60,
    );

    final newYork = _airport('KJFK', 'JFK');
    expect(
      service.utcOffsetMinutes(newYork, DateTime.utc(2026, 7, 4, 12)),
      -240,
    );
    expect(
      service.utcOffsetMinutes(newYork, DateTime.utc(2026, 12, 24, 12)),
      -300,
    );

    // Non-hour offsets survive.
    expect(
      service.utcOffsetMinutes(
        _airport('VNKT', 'KTM'),
        DateTime.utc(2026, 8, 3, 12),
      ),
      345,
    );
  });

  test('falls back to IATA and returns null for unknown airports', () {
    // ICAO missing from the seed, IATA known.
    expect(
      service.utcOffsetMinutes(_airport('XXXX', 'JFK'), DateTime.utc(2026, 7)),
      -240,
    );
    expect(
      service.utcOffsetMinutes(_airport('ZZZZ', 'ZZZ'), DateTime.utc(2026, 7)),
      isNull,
    );
  });

  test('converts airport wall-clock noon to UTC', () {
    expect(
      service.localTimeToUtc(_airport('EDDF', 'FRA'), DateTime(2026, 8, 3)),
      DateTime.utc(2026, 8, 3, 10),
    );
    expect(
      service.localTimeToUtc(_airport('VNKT', 'KTM'), DateTime(2026, 8, 3)),
      DateTime.utc(2026, 8, 3, 6, 15),
    );
    expect(
      service.localTimeToUtc(_airport('ZZZZ', 'ZZZ'), DateTime(2026, 8, 3)),
      isNull,
    );
  });
}
