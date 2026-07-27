import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/utils/route_utils.dart';
import 'package:flymap/utils/unit_format_utils.dart';

class RouteCopyBuilder {
  const RouteCopyBuilder._();

  static String build(FlightRoute route) {
    final departure = route.departure;
    final arrival = route.arrival;
    final distanceKm = UnitFormatUtils.formatThousands(
      (route.displayDistanceKm / 10).round() * 10,
    );

    return [
      t.flight.info.copyRouteTitle,
      '',
      '${departure.displayCode} -> ${arrival.displayCode}',
      t.flight.info.copyRouteCode(routeCode: route.routeCode),
      t.flight.info.copyDistance(distance: distanceKm),
      '',
      t.flight.info.copyFrom,
      _airportSummary(departure),
      '',
      t.flight.info.copyTo,
      _airportSummary(arrival),
    ].join('\n');
  }

  static String _airportSummary(Airport airport) {
    final iata = _codeOrFallback(airport.iataCode);
    final icao = _codeOrFallback(airport.icaoCode);
    return [
      t.flight.info.copyCity(
        city: RouteUtils.cityLabel(airport.city),
        countryCode: airport.countryCode,
      ),
      t.flight.info.copyAirport(airport: airport.name),
      t.flight.info.copyCodes(iata: iata, icao: icao),
    ].join('\n');
  }

  static String _codeOrFallback(String code) {
    final normalized = code.trim();
    if (normalized.isEmpty) return '-';
    return normalized;
  }
}
