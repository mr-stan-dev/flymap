import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/repository/flight_search_repository.dart';
import 'package:latlong2/latlong.dart';

class FlightRoutePreviewResult {
  final Map<String, dynamic> payload;
  final Airport departure;
  final Airport arrival;

  FlightRoutePreviewResult({
    required this.payload,
    required this.departure,
    required this.arrival,
  });
}

class BuildFlightRoutePreviewUseCase {
  BuildFlightRoutePreviewUseCase({required FlightSearchRepository repository})
    : _repository = repository;

  final FlightSearchRepository _repository;

  // The backend clamps this callable to 200 today; requesting 400 keeps the
  // client aligned with GetRouteOverviewUseCase and picks up any future
  // server-side cap raise automatically.
  static const int placesLimit = 400;
  static const int regionsLimit = 50;

  Future<FlightRoutePreviewResult> call({
    required String flightNumber,
    String? fr24Id,
    String? origCode,
    String? destCode,
    required String lang,
  }) async {
    final payload = await _repository.buildFlightRoutePreview(
      flightNumber: flightNumber,
      fr24Id: fr24Id,
      origCode: origCode,
      destCode: destCode,
      placesLimit: placesLimit,
      regionsLimit: regionsLimit,
      lang: lang,
    );

    final routeRaw = payload['route'];
    if (routeRaw is! Map) {
      throw const FormatException('Route payload missing route object');
    }
    final route = routeRaw.cast<String, dynamic>();

    final from = _parseLatLon(route['from']);
    final to = _parseLatLon(route['to']);
    if (from == null || to == null) {
      throw const FormatException('Route payload missing from/to coordinates');
    }

    final flightInfoRaw = payload['flightInfo'];
    final flightInfo = flightInfoRaw is Map
        ? flightInfoRaw.cast<String, dynamic>()
        : const <String, dynamic>{};
    final normalizedPayload = Map<String, dynamic>.of(payload);

    final resolvedOrigCode = _normalizeCode(
      flightInfo['origIcao'] ?? flightInfo['origIata'] ?? origCode,
    );
    final resolvedDestCode = _normalizeCode(
      flightInfo['destIcao'] ?? flightInfo['destIata'] ?? destCode,
    );

    final departure = await _repository.resolveAirport(
      latLon: from,
      code: resolvedOrigCode,
      fallbackName: 'Departure',
    );
    final arrival = await _repository.resolveAirport(
      latLon: to,
      code: resolvedDestCode,
      fallbackName: 'Arrival',
    );

    if (flightInfoRaw is Map) {
      final normalizedFlightInfo = Map<String, dynamic>.of(flightInfo);
      final airlineCode = _normalizeCode(
        normalizedFlightInfo['airlineCode'] ??
            normalizedFlightInfo['airline_code'] ??
            normalizedFlightInfo['operatingAs'] ??
            normalizedFlightInfo['operating_as'] ??
            normalizedFlightInfo['paintedAs'] ??
            normalizedFlightInfo['painted_as'],
      );
      final airlineName = await _repository.resolveAirlineNameByCode(
        airlineCode,
      );
      normalizedFlightInfo['airlineCode'] = airlineCode;
      normalizedFlightInfo['airlineName'] = airlineName ?? '';
      normalizedPayload['flightInfo'] = normalizedFlightInfo;
    }

    return FlightRoutePreviewResult(
      payload: normalizedPayload,
      departure: departure,
      arrival: arrival,
    );
  }

  LatLng? _parseLatLon(dynamic raw) {
    if (raw is Map) {
      final map = raw.cast<String, dynamic>();
      final lat = _toFiniteDouble(map['lat']);
      final lon = _toFiniteDouble(map['lon']);
      if (lat != null && lon != null) {
        return LatLng(lat, lon);
      }
    }
    if (raw is String) {
      final parts = raw.split(',');
      if (parts.length == 2) {
        final lat = _toFiniteDouble(parts[0]);
        final lon = _toFiniteDouble(parts[1]);
        if (lat != null && lon != null) {
          return LatLng(lat, lon);
        }
      }
    }
    return null;
  }

  String? _normalizeCode(dynamic raw) {
    if (raw == null) return null;
    final value = raw.toString().trim().toUpperCase();
    return value.isEmpty ? null : value;
  }

  double? _toFiniteDouble(dynamic raw) {
    if (raw is num) {
      final value = raw.toDouble();
      return value.isFinite ? value : null;
    }
    if (raw is String) {
      final parsed = double.tryParse(raw);
      if (parsed == null || !parsed.isFinite) return null;
      return parsed;
    }
    return null;
  }
}
