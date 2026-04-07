import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/flight_poi_type.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/entity/map_detail_level.dart';
import 'package:flymap/entity/route_poi.dart';
import 'package:flymap/repository/flight_poi_repository.dart';
import 'package:flymap/usecase/get_flight_poi_use_case.dart';
import 'package:flymap/usecase/poi_selection_config.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('GetFlightPOIUseCase', () {
    test('basic mode enforces <=10 POIs with strict city cap', () async {
      final repo = _FakeFlightPOIRepository(candidates: _buildCandidates());
      final useCase = GetFlightPOIUseCase(repository: repo);
      final route = _route();

      final result = await useCase.call(
        route: route,
        mapDetail: MapDetailLevel.basic,
      );

      expect(repo.lastPrefetchLimit, PoiSelectionConfig.basicPrefetchLimit);
      expect(result.length, lessThanOrEqualTo(PoiSelectionConfig.basicMaxPois));
      expect(
        result.where((poi) => poi.type == FlightPoiType.city).length,
        lessThanOrEqualTo(PoiSelectionConfig.basicCityCap),
      );
      expect(result.every((poi) => poi.routeProgress != null), isTrue);
    });

    test('pro mode allows many POIs but keeps city cap', () async {
      final repo = _FakeFlightPOIRepository(candidates: _buildCandidates());
      final useCase = GetFlightPOIUseCase(repository: repo);
      final route = _route();

      final result = await useCase.call(
        route: route,
        mapDetail: MapDetailLevel.pro,
      );

      expect(repo.lastPrefetchLimit, PoiSelectionConfig.proPrefetchLimit);
      expect(result.length, lessThanOrEqualTo(PoiSelectionConfig.proMaxPois));
      expect(
        result.where((poi) => poi.type == FlightPoiType.city).length,
        lessThanOrEqualTo(PoiSelectionConfig.proCityCap),
      );
      expect(result.length, greaterThan(PoiSelectionConfig.basicMaxPois));
    });

    test('selection is deterministic and spans route segments', () async {
      final repo = _FakeFlightPOIRepository(candidates: _buildCandidates());
      final useCase = GetFlightPOIUseCase(repository: repo);
      final route = _route();

      final first = await useCase.call(
        route: route,
        mapDetail: MapDetailLevel.basic,
      );
      final second = await useCase.call(
        route: route,
        mapDetail: MapDetailLevel.basic,
      );
      expect(
        first.map((e) => e.qid).toList(),
        equals(second.map((e) => e.qid).toList()),
      );

      final progresses = first.map((e) => e.routeProgress ?? 0).toList();
      expect(progresses.reduce((a, b) => a < b ? a : b), lessThan(0.25));
      expect(progresses.reduce((a, b) => a > b ? a : b), greaterThan(0.75));
    });

    test(
      'pro mode includes all volcanoes even when count exceeds max cap',
      () async {
        final volcanoCount = PoiSelectionConfig.proMaxPois + 35;
        final repo = _FakeFlightPOIRepository(
          candidates: _buildVolcanoHeavyCandidates(volcanoCount),
        );
        final useCase = GetFlightPOIUseCase(repository: repo);
        final route = _route();

        final result = await useCase.call(
          route: route,
          mapDetail: MapDetailLevel.pro,
        );

        expect(
          result.where((poi) => poi.type == FlightPoiType.volcano).length,
          volcanoCount,
        );
        expect(result.length, greaterThan(PoiSelectionConfig.proMaxPois));
      },
    );
  });
}

FlightRoute _route() {
  final waypoints = List<LatLng>.generate(
    101,
    (index) => LatLng(index.toDouble(), 0),
  );
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
    latLon: LatLng(100, 0),
    iataCode: 'BBB',
    icaoCode: 'BBBB',
    wikipediaUrl: '',
  );
  return FlightRoute(
    departure: departure,
    arrival: arrival,
    waypoints: waypoints,
    corridor: const [
      LatLng(-1, -2),
      LatLng(-1, 2),
      LatLng(101, 2),
      LatLng(101, -2),
    ],
  );
}

class _FakeFlightPOIRepository implements FlightPOIRepository {
  _FakeFlightPOIRepository({required this.candidates});

  final List<RoutePoi> candidates;
  int? lastPrefetchLimit;

  @override
  Future<List<RoutePoi>> getRoutePois({
    required FlightRoute route,
    required int prefetchLimit,
  }) async {
    lastPrefetchLimit = prefetchLimit;
    return candidates;
  }
}

List<RoutePoi> _buildCandidates() {
  final out = <RoutePoi>[];
  for (var i = 0; i < 120; i++) {
    final lat = (i % 100).toDouble();
    out.add(
      RoutePoi(
        qid: 'Q-RIVER-$i',
        name: 'River $i',
        latLon: LatLng(lat, 0.2),
        type: FlightPoiType.river,
        sitelinks: 1500 - i,
      ),
    );
  }
  for (var i = 0; i < 40; i++) {
    final lat = (i * 2).toDouble().clamp(0, 99).toDouble();
    out.add(
      RoutePoi(
        qid: 'Q-CITY-$i',
        name: 'City $i',
        latLon: LatLng(lat, 0.1),
        type: FlightPoiType.city,
        sitelinks: 2500 - i,
      ),
    );
  }
  for (var i = 0; i < 30; i++) {
    final lat = (i * 3).toDouble().clamp(0, 99).toDouble();
    out.add(
      RoutePoi(
        qid: 'Q-MOUNTAIN-$i',
        name: 'Mountain $i',
        latLon: LatLng(lat, -0.3),
        type: FlightPoiType.mountain,
        sitelinks: 1800 - i,
      ),
    );
  }
  return out;
}

List<RoutePoi> _buildVolcanoHeavyCandidates(int volcanoCount) {
  final out = <RoutePoi>[];
  for (var i = 0; i < volcanoCount; i++) {
    out.add(
      RoutePoi(
        qid: 'Q-VOLCANO-$i',
        name: 'Volcano $i',
        latLon: const LatLng(50, 0.05),
        type: FlightPoiType.volcano,
        sitelinks: 5000 - i,
      ),
    );
  }
  for (var i = 0; i < 30; i++) {
    out.add(
      RoutePoi(
        qid: 'Q-RIVER-$i',
        name: 'River $i',
        latLon: LatLng(i.toDouble(), 0.2),
        type: FlightPoiType.river,
        sitelinks: 1000 - i,
      ),
    );
  }
  return out;
}
