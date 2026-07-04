import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('isDomestic compares normalized non-empty country codes', () {
    expect(
      _route(
        originCountryCode: ' gb ',
        destinationCountryCode: 'GB',
      ).isDomestic,
      isTrue,
    );
    expect(
      _route(originCountryCode: 'GB', destinationCountryCode: 'ES').isDomestic,
      isFalse,
    );
    expect(
      _route(originCountryCode: '', destinationCountryCode: '').isDomestic,
      isFalse,
    );
  });
}

FlightRoute _route({
  required String originCountryCode,
  required String destinationCountryCode,
}) {
  return FlightRoute(
    departure: _airport(code: 'AAA', countryCode: originCountryCode),
    arrival: _airport(code: 'BBB', countryCode: destinationCountryCode),
    waypoints: const [],
    corridor: const [],
  );
}

Airport _airport({required String code, required String countryCode}) {
  return Airport(
    name: code,
    city: code,
    countryCode: countryCode,
    latLon: const LatLng(0, 0),
    iataCode: code,
    icaoCode: '',
    wikipediaUrl: '',
  );
}
