import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_info.dart';
import 'package:flymap/domain/entity/flight_operational_data.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_route_metrics.dart';
import 'package:flymap/domain/entity/flight_route_source.dart';
import 'package:flymap/domain/entity/flight_status.dart';
import 'package:flymap/domain/entity/flight_timestamp.dart';
import 'package:flymap/domain/entity/flight_waypoint.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:latlong2/latlong.dart';

import 'airport_db_mapper.dart';
import 'flight_info_db_mapper.dart';
import 'flight_map_mapper.dart';

class FlightDBKeys {
  static const flightMaps = 'maps';
  static const id = 'id';
  static const status = 'status';
  static const inProgressAt = 'inProgressAt';
  static const completedAt = 'completedAt';
  static const flightInfo = 'flightInfo';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';
  static const departure = 'departure';
  static const arrival = 'arrival';
  static const waypoints = 'waypoints';
  static const corridor = 'corridor';
  static const corridorPolygons = 'corridorPolygons';
  static const distanceInKm = 'distanceInKm';
  static const routeSource = 'routeSource';
  static const routeMetrics = 'routeMetrics';
  static const greatCircleDistanceKm = 'greatCircleDistanceKm';
  static const approxDurationMinutes = 'approxDurationMinutes';
  static const actualDurationMinutes = 'actualDurationMinutes';
  static const latitude = 'latitude';
  static const longitude = 'longitude';
  static const waypointTimestamp = 'timestamp';
  static const waypointAltitude = 'altitude';
  static const flightAccessTier = 'flightAccessTier';
  static const routeInsights = 'routeInsights';
  static const offlineContent = 'offlineContent';
  static const routePlan = 'routePlan';
  static const overview = 'overview';
  static const poi = 'poi';
  static const routeRegions = 'routeRegions';
  static const articles = 'articles';
  static const plannedDurationMinutes = 'plannedDurationMinutes';
  static const legacyPlannedDurationMin = 'plannedDurationMin';
  static const plannedCruiseSpeedKmh = 'plannedCruiseSpeedKmh';
  static const operationalData = 'operationalData';
  static const flightNumber = 'flightNumber';
  static const airlineName = 'airlineName';
  static const airlineCode = 'airlineCode';
  static const originCode = 'originCode';
  static const destinationCode = 'destinationCode';
  static const actualDistanceKm = 'actualDistanceKm';
  static const observedAt = 'observedAt';
}

class FlightDbMapper {
  final AirportDbMapper _airportMapper;
  final FlightInfoDbMapper _infoMapper;
  final FlightMapDbMapper _mapMapper = FlightMapDbMapper();

  FlightDbMapper({
    AirportDbMapper? airportMapper,
    FlightInfoDbMapper? infoMapper,
  }) : _airportMapper = airportMapper ?? AirportDbMapper(),
       _infoMapper = infoMapper ?? FlightInfoDbMapper();

  Map<String, dynamic> toDb(Flight flight) {
    final nowIso = DateTime.now().toIso8601String();
    final out = <String, dynamic>{
      FlightDBKeys.id: flight.id,
      FlightDBKeys.status: flight.status.rawValue,
      FlightDBKeys.flightMaps: flight.maps
          .map((m) => _mapMapper.toDb(m))
          .toList(),
      FlightDBKeys.createdAt: flight.createdAt.toIso8601String(),
      if (flight.inProgressAt != null)
        FlightDBKeys.inProgressAt: flight.inProgressAt!.toIso8601String(),
      if (flight.completedAt != null)
        FlightDBKeys.completedAt: flight.completedAt!.toIso8601String(),
      FlightDBKeys.flightAccessTier: flight.flightAccessTier,
      if (flight.operationalData != null)
        FlightDBKeys.operationalData: _toOperationalDataDb(
          flight.operationalData!,
        ),
      FlightDBKeys.updatedAt: nowIso,
    };
    final legacyInfo = _infoMapper.toFlightInfoMap(flight.info);
    out[FlightDBKeys.routeInsights] = <String, dynamic>{
      FlightDBKeys.overview: legacyInfo[FlightDBKeys.overview] ?? '',
      FlightDBKeys.poi: legacyInfo[FlightDBKeys.poi] ?? const <dynamic>[],
      FlightDBKeys.routeRegions:
          legacyInfo[FlightDBKeys.routeRegions] ?? const <dynamic>[],
    };
    out[FlightDBKeys.offlineContent] = <String, dynamic>{
      FlightDBKeys.articles:
          legacyInfo[FlightDBKeys.articles] ?? const <dynamic>[],
    };
    // plannedDurationMinutes carries block minutes and plannedCruiseSpeedKmh
    // the matching average speed, so legacy readers that reconstruct distance
    // as speed * minutes stay consistent.
    final blockMinutes = flight.route.durations.blockMinutes;
    final routeDistanceKm = flight.route.distanceInKm;
    out[FlightDBKeys.routePlan] = <String, dynamic>{
      if (blockMinutes > 0) FlightDBKeys.plannedDurationMinutes: blockMinutes,
      if (blockMinutes > 0 && routeDistanceKm > 0)
        FlightDBKeys.plannedCruiseSpeedKmh:
            (routeDistanceKm / (blockMinutes / 60.0)).round(),
    };

    out[FlightDBKeys.departure] = _airportMapper.toDb(flight.route.departure);
    out[FlightDBKeys.arrival] = _airportMapper.toDb(flight.route.arrival);

    out[FlightDBKeys.waypoints] = flight.route.waypoints
        .map(
          (waypoint) => <String, dynamic>{
            FlightDBKeys.latitude: waypoint.latitude,
            FlightDBKeys.longitude: waypoint.longitude,
            FlightDBKeys.waypointTimestamp: waypoint.timestamp,
            FlightDBKeys.waypointAltitude: waypoint.altitude,
          },
        )
        .toList();
    out[FlightDBKeys.corridor] = flight.route.corridor
        .map(
          (p) => <String, dynamic>{
            FlightDBKeys.latitude: p.latitude,
            FlightDBKeys.longitude: p.longitude,
          },
        )
        .toList();
    out[FlightDBKeys.corridorPolygons] = flight.route.effectiveCorridorPolygons
        .map(
          (ring) => ring
              .map(
                (p) => <String, dynamic>{
                  FlightDBKeys.latitude: p.latitude,
                  FlightDBKeys.longitude: p.longitude,
                },
              )
              .toList(growable: false),
        )
        .toList(growable: false);
    out[FlightDBKeys.routeSource] = flight.route.source.rawValue;
    out[FlightDBKeys.routeMetrics] = _toRouteMetricsDb(flight.route.metrics);
    out[FlightDBKeys.distanceInKm] = flight.route.distanceInKm;

    return out;
  }

  Flight fromDb(Map<String, dynamic> map) {
    final mapsList = ((map[FlightDBKeys.flightMaps] as List<dynamic>?) ?? [])
        .whereType<Map>()
        .map((e) => _mapMapper.fromDb(e.cast<String, dynamic>()))
        .toList();

    final departure = _airportMapper.fromDb(
      (map[FlightDBKeys.departure] as Map).cast<String, dynamic>(),
    );
    final arrival = _airportMapper.fromDb(
      (map[FlightDBKeys.arrival] as Map).cast<String, dynamic>(),
    );
    final corridorPolygons = _toCorridorPolygons(
      map[FlightDBKeys.corridorPolygons],
    );
    final legacyCorridor = _toCorridorRing(map[FlightDBKeys.corridor]);
    final effectivePolygons = corridorPolygons.isNotEmpty
        ? corridorPolygons
        : (legacyCorridor.length >= 3
              ? <List<LatLng>>[legacyCorridor]
              : const <List<LatLng>>[]);
    final metrics = _routeMetricsFromDb(
      map,
      departure: departure,
      arrival: arrival,
    );
    final route = FlightRoute(
      departure: departure,
      arrival: arrival,
      source: FlightRouteSource.fromRaw(map[FlightDBKeys.routeSource]),
      waypoints: (map[FlightDBKeys.waypoints] as List<dynamic>? ?? [])
          .map(_toWaypoint)
          .whereType<FlightWaypoint>()
          .toList(growable: false),
      corridor: effectivePolygons.isNotEmpty
          ? effectivePolygons.first
          : const <LatLng>[],
      corridorPolygons: effectivePolygons,
      metrics: metrics,
    );

    final info = _toInfoFromDb(map);

    final createdAtStr = (map[FlightDBKeys.createdAt] ?? '').toString();
    final createdAt = createdAtStr.isNotEmpty
        ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
        : DateTime.now();
    final inProgressAtStr = (map[FlightDBKeys.inProgressAt] ?? '').toString();
    final inProgressAt = inProgressAtStr.isNotEmpty
        ? DateTime.tryParse(inProgressAtStr)
        : null;
    final completedAtStr = (map[FlightDBKeys.completedAt] ?? '').toString();
    final completedAt = completedAtStr.isNotEmpty
        ? DateTime.tryParse(completedAtStr)
        : null;

    final accessTierRaw = (map[FlightDBKeys.flightAccessTier] ?? '')
        .toString()
        .trim();
    final flightAccessTier = switch (accessTierRaw) {
      Flight.accessTierPro => Flight.accessTierPro,
      Flight.accessTierBasic => Flight.accessTierBasic,
      _ => Flight.accessTierBasic,
    };
    final operationalData = _fromOperationalDataDb(
      map[FlightDBKeys.operationalData],
    );

    return Flight(
      id: (map[FlightDBKeys.id] ?? '').toString(),
      route: route,
      maps: mapsList,
      routeInsights: info.routeInsights,
      offlineContent: info.offlineContent,
      timestamp: FlightTimestamp(
        createdAt: createdAt,
        inProgressAt: inProgressAt,
        completedAt: completedAt,
      ),
      status: FlightStatus.fromRaw((map[FlightDBKeys.status] ?? '').toString()),
      flightAccessTier: flightAccessTier,
      operationalData: operationalData,
    );
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

  int? _toInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  String? _toNonEmptyString(dynamic raw) {
    if (raw == null) return null;
    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  Map<String, dynamic> _toRouteMetricsDb(FlightRouteMetrics metrics) {
    return <String, dynamic>{
      FlightDBKeys.greatCircleDistanceKm: metrics.greatCircleDistanceKm,
      FlightDBKeys.approxDurationMinutes: metrics.cruiseMinutes,
      if (metrics.actualDistanceKm != null)
        FlightDBKeys.actualDistanceKm: metrics.actualDistanceKm,
      if (metrics.actualBlockMinutes != null)
        FlightDBKeys.actualDurationMinutes: metrics.actualBlockMinutes,
    };
  }

  FlightRouteMetrics _routeMetricsFromDb(
    Map<String, dynamic> map, {
    required Airport departure,
    required Airport arrival,
  }) {
    final metricsRaw = map[FlightDBKeys.routeMetrics];
    final metricsMap = metricsRaw is Map
        ? metricsRaw.cast<String, dynamic>()
        : const <String, dynamic>{};
    final legacyDistanceKm =
        _toFiniteDouble(map[FlightDBKeys.distanceInKm]) ??
        MapUtils.distance(departure: departure, arrival: arrival);
    final greatCircleDistanceKm =
        _toFiniteDouble(metricsMap[FlightDBKeys.greatCircleDistanceKm]) ??
        legacyDistanceKm;
    // v2.0.2 flightInfo.routeTotalMinutes is cruise-only, so it may fill the
    // cruise slot. routePlan.plannedDurationMinutes is a block value and must
    // NOT — records with only a plan fall through to the distance estimate.
    final legacyInfoRaw = map[FlightDBKeys.flightInfo];
    final legacyInfoMap = legacyInfoRaw is Map
        ? legacyInfoRaw.cast<String, dynamic>()
        : const <String, dynamic>{};
    final cruiseMinutes =
        _toInt(metricsMap[FlightDBKeys.approxDurationMinutes]) ??
        _toInt(legacyInfoMap[FlightInfoDBKeys.routeTotalMinutes]) ??
        FlightRouteMetrics.estimateCruiseMinutes(greatCircleDistanceKm);
    final actualDistanceKm = _toFiniteDouble(
      metricsMap[FlightDBKeys.actualDistanceKm],
    );
    final actualBlockMinutes = _toInt(
      metricsMap[FlightDBKeys.actualDurationMinutes],
    );
    return FlightRouteMetrics(
      greatCircleDistanceKm: greatCircleDistanceKm,
      cruiseMinutes: cruiseMinutes,
      actualDistanceKm: actualDistanceKm,
      actualBlockMinutes: actualBlockMinutes,
    );
  }

  FlightWaypoint? _toWaypoint(dynamic raw) {
    if (raw is! Map) return null;
    final point = raw.cast<String, dynamic>();
    final lat = _toFiniteDouble(point[FlightDBKeys.latitude]);
    final lon = _toFiniteDouble(point[FlightDBKeys.longitude]);
    if (lat == null || lon == null) return null;
    return FlightWaypoint(
      latLon: LatLng(lat, lon),
      timestamp: _toInt(point[FlightDBKeys.waypointTimestamp]) ?? 0,
      altitude: _toInt(point[FlightDBKeys.waypointAltitude]) ?? 0,
    );
  }

  List<LatLng> _toCorridorRing(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((point) => point.cast<String, dynamic>())
        .map((point) {
          final lat = _toFiniteDouble(point[FlightDBKeys.latitude]);
          final lon = _toFiniteDouble(point[FlightDBKeys.longitude]);
          if (lat == null || lon == null) return null;
          return LatLng(lat, lon);
        })
        .whereType<LatLng>()
        .toList(growable: false);
  }

  List<List<LatLng>> _toCorridorPolygons(dynamic raw) {
    if (raw is! List) return const [];
    final polygons = <List<LatLng>>[];
    for (final polygonRaw in raw) {
      final ring = _toCorridorRing(polygonRaw);
      if (ring.length >= 3) {
        polygons.add(ring);
      }
    }
    return polygons;
  }

  FlightInfo _toInfoFromDb(Map<String, dynamic> map) {
    final insightsRaw = map[FlightDBKeys.routeInsights];
    final offlineRaw = map[FlightDBKeys.offlineContent];
    final routePlanRaw = map[FlightDBKeys.routePlan];
    if (insightsRaw is Map || offlineRaw is Map || routePlanRaw is Map) {
      final insights = insightsRaw is Map
          ? insightsRaw.cast<String, dynamic>()
          : const <String, dynamic>{};
      final offline = offlineRaw is Map
          ? offlineRaw.cast<String, dynamic>()
          : const <String, dynamic>{};
      final plan = routePlanRaw is Map
          ? routePlanRaw.cast<String, dynamic>()
          : const <String, dynamic>{};
      final legacyMap = <String, dynamic>{
        FlightDBKeys.overview: insights[FlightDBKeys.overview] ?? '',
        FlightDBKeys.poi: insights[FlightDBKeys.poi] ?? const <dynamic>[],
        FlightDBKeys.routeRegions:
            insights[FlightDBKeys.routeRegions] ?? const <dynamic>[],
        FlightDBKeys.articles:
            offline[FlightDBKeys.articles] ?? const <dynamic>[],
        if (plan.containsKey(FlightDBKeys.plannedDurationMinutes) ||
            plan.containsKey(FlightDBKeys.legacyPlannedDurationMin))
          FlightInfoDBKeys.routeTotalMinutes:
              plan[FlightDBKeys.plannedDurationMinutes] ??
              plan[FlightDBKeys.legacyPlannedDurationMin],
        if (plan.containsKey(FlightDBKeys.plannedCruiseSpeedKmh))
          FlightInfoDBKeys.routeCruiseSpeedKmh:
              plan[FlightDBKeys.plannedCruiseSpeedKmh],
      };
      return _infoMapper.toFlightInfo(legacyMap);
    }

    final legacy = map[FlightDBKeys.flightInfo];
    if (legacy is Map<String, dynamic>) {
      return _infoMapper.toFlightInfo(legacy);
    }
    if (legacy is Map) {
      return _infoMapper.toFlightInfo(legacy.cast<String, dynamic>());
    }
    return FlightInfo.empty;
  }

  Map<String, dynamic> _toOperationalDataDb(FlightOperationalData data) {
    return <String, dynamic>{
      FlightDBKeys.flightNumber: data.flightNumber,
      FlightDBKeys.airlineCode: data.airlineCode,
      FlightDBKeys.airlineName: data.airlineName,
      FlightDBKeys.originCode: data.originCode,
      FlightDBKeys.destinationCode: data.destinationCode,
      FlightDBKeys.observedAt: data.observedAt.toIso8601String(),
    };
  }

  FlightOperationalData? _fromOperationalDataDb(dynamic raw) {
    if (raw is! Map) return null;
    final map = raw.cast<String, dynamic>();
    final flightNumber = _toNonEmptyString(map[FlightDBKeys.flightNumber]);
    final originCode = _toNonEmptyString(map[FlightDBKeys.originCode]);
    final destinationCode = _toNonEmptyString(
      map[FlightDBKeys.destinationCode],
    );
    final observedAt = _toDateTime(map[FlightDBKeys.observedAt]);
    if (flightNumber == null ||
        originCode == null ||
        destinationCode == null ||
        observedAt == null) {
      return null;
    }
    return FlightOperationalData(
      flightNumber: flightNumber,
      airlineCode: _toNonEmptyString(map[FlightDBKeys.airlineCode]),
      airlineName: _toNonEmptyString(map[FlightDBKeys.airlineName]),
      originCode: originCode,
      destinationCode: destinationCode,
      observedAt: observedAt,
    );
  }

  DateTime? _toDateTime(dynamic raw) {
    final asString = _toNonEmptyString(raw);
    return asString == null ? null : DateTime.tryParse(asString);
  }
}
