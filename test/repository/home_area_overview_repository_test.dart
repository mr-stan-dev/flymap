import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/api/route_overview_api.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_poi_type.dart';
import 'package:flymap/domain/entity/home_area_summary.dart';
import 'package:flymap/repository/home_area_overview_repository.dart';
import 'package:latlong2/latlong.dart';

void main() {
  final airport = Airport(
    name: 'Vienna International Airport',
    city: 'Vienna',
    countryCode: 'AT',
    latLon: const LatLng(48.11, 16.57),
    iataCode: 'VIE',
    icaoCode: 'LOWW',
    wikipediaUrl: '',
  );

  Map<String, dynamic> feature(
    String name,
    String type,
    int sitelinks, {
    double lat = 48.0,
    double lon = 16.0,
  }) => {
    'geometry': {
      'type': 'Point',
      'coordinates': [lon, lat],
    },
    'properties': {
      'qid': 'Q_$name',
      'name': name,
      'placeType': type,
      'sitelinks': sitelinks,
      'description': 'About $name',
    },
  };

  test('builds summary from route overview payload', () async {
    final api = _FakeRouteOverviewApi({
      'places': {
        'features': [
          feature('Schneeberg', 'mountain', 40),
          feature('Rax', 'mountain', 12),
          feature('Attersee', 'lake', 50),
          feature('Neusiedler See', 'lake', 55),
          feature('Vienna', 'city', 200),
          {'properties': <String, dynamic>{}}, // nameless -> skipped
        ],
      },
      'regions': [
        {
          'properties': {'name': 'Alps'},
        },
        {
          'properties': {'name': 'Pannonian Basin'},
        },
      ],
    });
    final repository = ApiHomeAreaOverviewRepository(api: api);

    final summary = await repository.getHomeAreaSummary(airport: airport);

    expect(summary.countsByType[FlightPoiType.mountain], 2);
    expect(summary.countsByType[FlightPoiType.lake], 2);
    expect(summary.countsByType[FlightPoiType.city], 1);
    expect(summary.totalPlaces, 5);
    // Cities are counted but never surfaced as headline proof, and picks
    // prefer type variety (Schneeberg over the higher-ranked second lake)
    // before backfilling by rank.
    expect(summary.topPlaces, const [
      HomeAreaPlace(
        name: 'Neusiedler See',
        type: FlightPoiType.lake,
        qid: 'Q_Neusiedler See',
        description: 'About Neusiedler See',
      ),
      HomeAreaPlace(
        name: 'Schneeberg',
        type: FlightPoiType.mountain,
        qid: 'Q_Schneeberg',
        description: 'About Schneeberg',
      ),
      HomeAreaPlace(
        name: 'Attersee',
        type: FlightPoiType.lake,
        qid: 'Q_Attersee',
        description: 'About Attersee',
      ),
      HomeAreaPlace(
        name: 'Rax',
        type: FlightPoiType.mountain,
        qid: 'Q_Rax',
        description: 'About Rax',
      ),
    ]);
    expect(summary.regionNames, ['Alps', 'Pannonian Basin']);
    expect(summary.isEmpty, isFalse);
  });

  test('queries a short synthetic route centered on the airport', () async {
    final api = _FakeRouteOverviewApi(const {'places': <String, dynamic>{}});
    final repository = ApiHomeAreaOverviewRepository(api: api);

    await repository.getHomeAreaSummary(airport: airport);

    final departure = api.lastDeparture!;
    final arrival = api.lastArrival!;
    expect(departure.latLon.latitude, closeTo(48.11 - 0.45, 1e-9));
    expect(arrival.latLon.latitude, closeTo(48.11 + 0.45, 1e-9));
    expect(departure.latLon.longitude, airport.latLon.longitude);
    expect(arrival.latLon.longitude, airport.latLon.longitude);
    expect(departure.countryCode, 'AT');
  });

  test('drops places beyond 100 km or without coordinates', () async {
    final api = _FakeRouteOverviewApi({
      'places': {
        'features': [
          feature('Schneeberg', 'mountain', 40),
          // ~200 km north of the airport: outside the visible area.
          feature('Distant Reserve', 'reserve', 90, lat: 49.9),
          // No geometry: distance cannot be verified.
          {
            'properties': {
              'qid': 'Q_nowhere',
              'name': 'Nowhere Peak',
              'placeType': 'mountain',
              'sitelinks': 80,
            },
          },
        ],
      },
    });
    final repository = ApiHomeAreaOverviewRepository(api: api);

    final summary = await repository.getHomeAreaSummary(airport: airport);

    expect(summary.countsByType[FlightPoiType.mountain], 1);
    expect(summary.countsByType.containsKey(FlightPoiType.reserve), isFalse);
    expect(summary.totalPlaces, 1);
    expect(summary.topPlaces, const [
      HomeAreaPlace(
        name: 'Schneeberg',
        type: FlightPoiType.mountain,
        qid: 'Q_Schneeberg',
        description: 'About Schneeberg',
      ),
    ]);
  });

  test('empty payload yields an empty summary', () async {
    final api = _FakeRouteOverviewApi(const <String, dynamic>{});
    final repository = ApiHomeAreaOverviewRepository(api: api);

    final summary = await repository.getHomeAreaSummary(airport: airport);

    expect(summary.isEmpty, isTrue);
    expect(summary.topPlaces, isEmpty);
    expect(summary.regionNames, isEmpty);
  });
}

class _FakeRouteOverviewApi extends RouteOverviewApi {
  _FakeRouteOverviewApi(this.payload);

  final Map<String, dynamic> payload;
  Airport? lastDeparture;
  Airport? lastArrival;

  @override
  Future<Map<String, dynamic>> getRouteOverview({
    required Airport departure,
    required Airport arrival,
    required int placesLimit,
    required int regionsLimit,
  }) async {
    lastDeparture = departure;
    lastArrival = arrival;
    return payload;
  }
}
