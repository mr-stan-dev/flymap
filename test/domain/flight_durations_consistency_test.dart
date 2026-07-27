import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/mappers/route_regions_api_mapper.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_route_metrics.dart';
import 'package:flymap/domain/entity/flight_route_source.dart';
import 'package:flymap/domain/entity/flight_waypoint.dart';
import 'package:flymap/domain/policy/flight_duration_estimate_policy.dart';
import 'package:latlong2/latlong.dart';

// Guards the invariant that every surface showing a flight duration agrees:
// FlightRoute.durations (home card, share card, Route tab) must match what
// the regions timeline mapper computes for the new-flight overview.
void main() {
  const departure = Airport(
    name: 'Madrid Barajas',
    city: 'Madrid',
    countryCode: 'ES',
    latLon: LatLng(40.47, -3.57),
    iataCode: 'MAD',
    icaoCode: 'LEMD',
    wikipediaUrl: '',
  );
  const arrival = Airport(
    name: 'Berlin Brandenburg',
    city: 'Berlin',
    countryCode: 'DE',
    latLon: LatLng(52.36, 13.5),
    iataCode: 'BER',
    icaoCode: 'EDDB',
    wikipediaUrl: '',
  );

  FlightRoute buildRoute(
    FlightRouteMetrics metrics, {
    FlightRouteSource? source,
  }) {
    return FlightRoute(
      departure: departure,
      arrival: arrival,
      source: source ?? FlightRouteSource.greatCircle,
      waypoints: const [
        FlightWaypoint(latLon: LatLng(40.47, -3.57)),
        FlightWaypoint(latLon: LatLng(52.36, 13.5)),
      ],
      corridor: const [LatLng(40.47, -3.57), LatLng(52.36, 13.5)],
      metrics: metrics,
    );
  }

  Map<String, dynamic> regionsPayload(FlightRouteMetrics metrics) {
    return <String, dynamic>{
      'route': {
        'source': 'greatCircle',
        'metrics': {
          'greatCircleDistanceKm': metrics.greatCircleDistanceKm,
          'approxDurationMinutes': metrics.cruiseMinutes,
        },
      },
      'regions': const <dynamic>[],
    };
  }

  test('estimated flight: route durations and regions timeline agree', () {
    const metrics = FlightRouteMetrics(
      greatCircleDistanceKm: 1851,
      cruiseMinutes: 130,
    );
    final route = buildRoute(metrics);
    final timeline = RouteRegionsApiMapper().toRouteTimeline(
      regionsPayload(metrics),
    );

    expect(route.durations.blockMinutes, timeline.blockMinutes);
    expect(route.durations.displayBlockMinutes, timeline.blockMinutes);
  });

  test('block estimate exceeds cruise time by the overhead', () {
    const metrics = FlightRouteMetrics(
      greatCircleDistanceKm: 1851,
      cruiseMinutes: 130,
    );
    final durations = buildRoute(metrics).durations;

    expect(durations.cruiseMinutes, 130);
    // 25 min base + 0.02 min/km distance overhead, rounded to 5.
    expect(
      durations.blockMinutes - durations.cruiseMinutes,
      inInclusiveRange(50, 70),
    );
  });

  test('historical flight: recorded block time wins and is rounded', () {
    const metrics = FlightRouteMetrics(
      greatCircleDistanceKm: 1851,
      cruiseMinutes: 130,
      actualDistanceKm: 1902,
      actualBlockMinutes: 187,
    );
    final route = buildRoute(metrics, source: FlightRouteSource.fr24Historical);

    expect(route.durations.isActual, isTrue);
    expect(route.durations.blockMinutes, 187);
    expect(route.durations.displayBlockMinutes, 185);
  });

  test('policy never doubles overhead when fed a metrics cruise speed', () {
    const metrics = FlightRouteMetrics(
      greatCircleDistanceKm: 1851,
      cruiseMinutes: 130,
      actualDistanceKm: 1902,
      actualBlockMinutes: 187,
    );
    final estimated = FlightDurationEstimatePolicy.estimateBlockMinutes(
      distanceKm: metrics.greatCircleDistanceKm,
      cruiseSpeedKmh: metrics.cruiseSpeedKmh!.round(),
      roundToMinutes: 5,
    );

    // With a block-average speed (~610 km/h) this would come out near 245.
    expect(estimated, inInclusiveRange(185, 200));
  });
}
