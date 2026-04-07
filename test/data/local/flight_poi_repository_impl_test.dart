import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/local/flight_poi_repository_impl.dart';
import 'package:flymap/data/local/places_wiki_local_data_source.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/flight_poi_type.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/entity/route_poi.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('LocalFlightPOIRepository', () {
    test('returns all corridor POIs and keeps outside points out', () async {
      final dataSource = _FakePlacesWikiLocalDataSource([
        _poi('Q-CITY-OUT', 'Outside City', 50, 50, FlightPoiType.city, 200),
        _poi('Q-CITY-1', 'City 1', 1, 1, FlightPoiType.city, 100),
        _poi('Q-CITY-2', 'City 2', 1, 2, FlightPoiType.city, 95),
        _poi('Q-RIVER-1', 'River 1', 2, 2, FlightPoiType.river, 90),
        _poi('Q-RIVER-2', 'River 2', 2, 3, FlightPoiType.river, 85),
        _poi('Q-MOUNTAIN-1', 'Mountain 1', 3, 3, FlightPoiType.mountain, 80),
        _poi('Q-MOUNTAIN-2', 'Mountain 2', 3, 4, FlightPoiType.mountain, 70),
      ]);
      final repository = LocalFlightPOIRepository(localDataSource: dataSource);

      final result = await repository.getRoutePois(
        route: _route(),
        prefetchLimit: 1200,
      );

      expect(result.length, 6);
      expect(result.map((e) => e.type).toList(), [
        FlightPoiType.city,
        FlightPoiType.city,
        FlightPoiType.river,
        FlightPoiType.river,
        FlightPoiType.mountain,
        FlightPoiType.mountain,
      ]);
      expect(result.any((e) => e.qid == 'Q-CITY-OUT'), isFalse);
    });

    test('preserves source ordering for equal items', () async {
      final dataSource = _FakePlacesWikiLocalDataSource([
        _poi('Q2', 'City B', 1, 1, FlightPoiType.city, 50),
        _poi('Q1', 'City A', 1, 1, FlightPoiType.city, 50),
      ]);
      final repository = LocalFlightPOIRepository(localDataSource: dataSource);

      final result = await repository.getRoutePois(
        route: _route(),
        prefetchLimit: 2,
      );

      expect(result.map((e) => e.qid).toList(), ['Q2', 'Q1']);
    });
  });
}

RoutePoi _poi(
  String qid,
  String name,
  double lat,
  double lon,
  FlightPoiType type,
  int sitelinks,
) {
  return RoutePoi(
    qid: qid,
    name: name,
    latLon: LatLng(lat, lon),
    type: type,
    sitelinks: sitelinks,
  );
}

FlightRoute _route() {
  const departure = Airport(
    name: 'A',
    city: 'A',
    countryCode: 'US',
    latLon: LatLng(0, 0),
    iataCode: 'AAA',
    icaoCode: 'AAAA',
    wikipediaUrl: '',
  );
  const arrival = Airport(
    name: 'B',
    city: 'B',
    countryCode: 'US',
    latLon: LatLng(10, 10),
    iataCode: 'BBB',
    icaoCode: 'BBBB',
    wikipediaUrl: '',
  );
  return const FlightRoute(
    departure: departure,
    arrival: arrival,
    waypoints: [LatLng(0, 0), LatLng(10, 10)],
    corridor: [LatLng(0, 0), LatLng(0, 10), LatLng(10, 10), LatLng(10, 0)],
  );
}

class _FakePlacesWikiLocalDataSource extends PlacesWikiLocalDataSource {
  _FakePlacesWikiLocalDataSource(this._pois);

  final List<RoutePoi> _pois;

  @override
  Future<void> initialize() async {}

  @override
  Future<List<RoutePoi>> queryByBounds({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    required int limit,
  }) async {
    if (limit <= 0) return _pois;
    return _pois.take(limit).toList(growable: false);
  }
}
