import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_poi.dart';
import 'package:flymap/usecase/build_wikipedia_candidates_use_case.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('BuildWikipediaCandidatesUseCase', () {
    test('builds ordered deduped candidates from poi only', () {
      final info = FlightInfo('', [
        _poi('https://en.wikipedia.org/wiki/London'),
        _poi('https://en.wikipedia.org/wiki/London'),
        _poi('https://example.com/wiki/Fake'),
      ]);

      final result = const BuildWikipediaCandidatesUseCase().call(
        flightInfo: info,
      );

      expect(result.length, 1);
      expect(result[0].title, 'London');
    });
  });
}

FlightPoi _poi(String wiki) {
  return FlightPoi(
    coordinates: const LatLng(0, 0),
    type: '',
    description: '',
    name: 'poi',
    flyView: '',
    wiki: wiki,
  );
}
