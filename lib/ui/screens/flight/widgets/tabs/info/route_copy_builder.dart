import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/flight_route.dart';

class RouteCopyBuilder {
  const RouteCopyBuilder._();

  static String build(FlightRoute route) {
    final departure = route.departure;
    final arrival = route.arrival;
    final distanceKm = route.distanceInKm.toStringAsFixed(0);

    return [
      'Flymap Route',
      '',
      '${departure.displayCode} -> ${arrival.displayCode}',
      'Route code: ${route.routeCode}',
      'Distance: $distanceKm km',
      '',
      'From',
      _airportSummary(departure),
      '',
      'To',
      _airportSummary(arrival),
    ].join('\n');
  }

  static String _airportSummary(Airport airport) {
    final iata = _codeOrFallback(airport.iataCode);
    final icao = _codeOrFallback(airport.icaoCode);
    return [
      'City: ${airport.city}, ${airport.countryCode}',
      'Airport: ${airport.name}',
      'Codes: IATA $iata | ICAO $icao',
    ].join('\n');
  }

  static String _codeOrFallback(String code) {
    final normalized = code.trim();
    if (normalized.isEmpty) return '-';
    return normalized;
  }
}
