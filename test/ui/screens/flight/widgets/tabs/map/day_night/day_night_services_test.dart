import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_route_metrics.dart';
import 'package:flymap/domain/entity/flight_waypoint.dart';
import 'package:flymap/domain/entity/gps_data.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/day_night/day_night_overlay_controller.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/day_night/route_sun_event_forecast.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/day_night/route_sun_event_forecast_service.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/day_night/solar_position_calculator.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('solar elevation is high at equator noon and low at midnight', () {
    final calculator = SolarPositionCalculator();

    final noon = calculator.solarElevationDegrees(
      dateTimeUtc: DateTime.utc(2026, 3, 20, 12),
      latitude: 0,
      longitude: 0,
    );
    final midnight = calculator.solarElevationDegrees(
      dateTimeUtc: DateTime.utc(2026, 3, 20, 0),
      latitude: 0,
      longitude: 0,
    );

    expect(noon, greaterThan(80));
    expect(midnight, lessThan(-80));
  });

  test('day-night overlay builder returns polygon features', () {
    final builder = DayNightOverlayGeoJsonBuilder(
      thresholdDegrees: SolarPositionCalculator.sunriseSunsetThresholdDegrees,
    );

    final geoJson = builder.build(DateTime.utc(2026, 3, 20, 0));
    final features = geoJson['features'] as List<dynamic>;

    expect(geoJson['type'], 'FeatureCollection');
    expect(features, isNotEmpty);
    expect(
      (features.first as Map<String, dynamic>)['geometry']['type'],
      'Polygon',
    );
  });

  test('route forecast finds sunrise ahead when it is within 60 minutes', () {
    final service = RouteSunEventForecastService();
    final route = _buildEquatorialRoute(
      startLongitude: 75,
      endLongitude: 85,
      speedKmh: 900,
    );

    final forecast = service.compute(
      route: route,
      gpsData: const GpsData(
        latitude: 0,
        longitude: 80,
        course: 90,
        accuracy: 8.0,
      ),
      speedKmhOverride: 900,
      nowUtc: DateTime.utc(2026, 3, 20, 0),
    );

    expect(forecast, isNotNull);
    expect(forecast!.type, RouteSunEventType.sunrise);
    expect(forecast.eta.inMinutes, inInclusiveRange(1, 60));
  });

  test('route forecast uses GPS speed override when provided', () {
    final service = RouteSunEventForecastService();
    final route = _buildEquatorialRoute(
      startLongitude: 75,
      endLongitude: 85,
      speedKmh: 900,
    );
    const gpsData = GpsData(
      latitude: 0,
      longitude: 80,
      course: 90,
      accuracy: 8.0,
    );

    final slowerForecast = service.compute(
      route: route,
      gpsData: gpsData,
      speedKmhOverride: 600,
      nowUtc: DateTime.utc(2026, 3, 20, 0),
    );
    final fasterForecast = service.compute(
      route: route,
      gpsData: gpsData,
      speedKmhOverride: 1000,
      nowUtc: DateTime.utc(2026, 3, 20, 0),
    );

    expect(slowerForecast, isNotNull);
    expect(fasterForecast, isNotNull);
    expect(
      fasterForecast!.eta.inMinutes,
      lessThan(slowerForecast!.eta.inMinutes),
    );
  });

  test(
    'route forecast returns null when event is more than 60 minutes away',
    () {
      final service = RouteSunEventForecastService();
      final route = _buildEquatorialRoute(
        startLongitude: 0,
        endLongitude: 150,
        speedKmh: 900,
      );

      final forecast = service.compute(
        route: route,
        gpsData: const GpsData(
          latitude: 0,
          longitude: 30,
          course: 90,
          accuracy: 8.0,
        ),
        speedKmhOverride: 900,
        nowUtc: DateTime.utc(2026, 3, 20, 0),
      );

      expect(forecast, isNull);
    },
  );

  test('route forecast returns null without live course', () {
    final service = RouteSunEventForecastService();
    final route = _buildEquatorialRoute(
      startLongitude: 0,
      endLongitude: 150,
      speedKmh: 900,
    );

    final forecast = service.compute(
      route: route,
      gpsData: const GpsData(latitude: 0, longitude: 30, accuracy: 8.0),
      speedKmhOverride: 900,
      nowUtc: DateTime.utc(2026, 3, 20, 0),
    );

    expect(forecast, isNull);
  });

  test('route forecast returns null without reliable live speed', () {
    final service = RouteSunEventForecastService();
    final route = _buildEquatorialRoute(
      startLongitude: 0,
      endLongitude: 150,
      speedKmh: 900,
    );

    final forecast = service.compute(
      route: route,
      gpsData: const GpsData(
        latitude: 0,
        longitude: 30,
        course: 90,
        accuracy: 8.0,
      ),
      nowUtc: DateTime.utc(2026, 3, 20, 0),
    );

    expect(forecast, isNull);
  });

  test(
    'route forecast returns null when no sun event occurs before arrival',
    () {
      final service = RouteSunEventForecastService();
      final route = _buildEquatorialRoute(
        startLongitude: 30,
        endLongitude: 50,
        speedKmh: 900,
      );

      final forecast = service.compute(
        route: route,
        gpsData: const GpsData(
          latitude: 0,
          longitude: 30,
          course: 90,
          accuracy: 8.0,
        ),
        speedKmhOverride: 900,
        nowUtc: DateTime.utc(2026, 3, 20, 0),
      );

      expect(forecast, isNull);
    },
  );
}

FlightRoute _buildEquatorialRoute({
  required double startLongitude,
  required double endLongitude,
  required double speedKmh,
}) {
  final departure = Airport(
    name: 'Start',
    city: 'Start',
    countryCode: 'AA',
    latLon: LatLng(0, startLongitude),
    iataCode: 'STA',
    icaoCode: 'STAA',
    wikipediaUrl: '',
  );
  final arrival = Airport(
    name: 'End',
    city: 'End',
    countryCode: 'BB',
    latLon: LatLng(0, endLongitude),
    iataCode: 'END',
    icaoCode: 'ENDB',
    wikipediaUrl: '',
  );
  final distanceKm = MapUtils.distanceKm(
    departure: departure.latLon,
    arrival: arrival.latLon,
  );
  final cruiseMinutes = ((distanceKm / speedKmh) * 60).round();

  return FlightRoute(
    departure: departure,
    arrival: arrival,
    waypoints: [
      FlightWaypoint(latLon: LatLng(0, startLongitude)),
      FlightWaypoint(latLon: LatLng(0, endLongitude)),
    ],
    corridor: [LatLng(0, startLongitude), LatLng(0, endLongitude)],
    metrics: FlightRouteMetrics(
      greatCircleDistanceKm: distanceKm,
      cruiseMinutes: cruiseMinutes,
    ),
  );
}
