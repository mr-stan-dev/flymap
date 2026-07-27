import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_poi_type.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_route_metrics.dart';
import 'package:flymap/domain/entity/flight_route_source.dart';
import 'package:flymap/domain/entity/flight_waypoint.dart';
import 'package:flymap/domain/entity/route_poi.dart';
import 'package:flymap/domain/entity/route_poi_summary.dart';
import 'package:flymap/domain/entity/route_preview.dart';
import 'package:latlong2/latlong.dart';

class RoutePlacesApiMapper {
  RoutePreview toRoutePreview(
    Map<String, dynamic> payload, {
    required Airport departure,
    required Airport arrival,
  }) {
    final route = payload['route'];
    if (route is! Map) {
      throw const FormatException('Route payload missing route object');
    }
    final routeMap = route.cast<String, dynamic>();
    final waypoints = _parseWaypoints(routeMap);
    final corridorPolygons = _parseCorridorPolygons(routeMap);
    final corridor = corridorPolygons.isNotEmpty
        ? corridorPolygons.first
        : const <LatLng>[];
    final metrics = _parseRouteMetrics(routeMap, payload);
    if (waypoints.length < 2) {
      throw const FormatException('Route path must contain at least 2 points');
    }
    if (corridor.length < 3) {
      throw const FormatException(
        'Route corridor must contain at least 3 points',
      );
    }
    if (metrics.effectiveDistanceKm <= 0) {
      throw const FormatException('Route payload missing valid distance');
    }
    final flightRoute = FlightRoute(
      departure: departure,
      arrival: arrival,
      source: FlightRouteSource.fromRaw(routeMap['source']),
      waypoints: waypoints,
      corridor: corridor,
      corridorPolygons: corridorPolygons,
      metrics: metrics,
    );
    final topPois = _parseTopPois(payload['places']);
    return RoutePreview(route: flightRoute, topPois: topPois);
  }

  List<RoutePoiSummary> _parseTopPois(dynamic placesRaw) {
    if (placesRaw is! Map) return const [];
    final places = placesRaw.cast<String, dynamic>();
    final features = places['features'];
    if (features is! List) return const [];
    final out = <RoutePoiSummary>[];
    for (final featureRaw in features) {
      final parsed = _parseFeature(featureRaw);
      if (parsed != null) out.add(parsed);
    }
    return out;
  }

  RoutePoiSummary? _parseFeature(dynamic featureRaw) {
    if (featureRaw is! Map) return null;
    final feature = featureRaw.cast<String, dynamic>();
    final geometryRaw = feature['geometry'];
    final propsRaw = feature['properties'];
    if (geometryRaw is! Map || propsRaw is! Map) return null;
    final geometry = geometryRaw.cast<String, dynamic>();
    final properties = propsRaw.cast<String, dynamic>();
    if (geometry['type'] != 'Point') return null;
    final coordinates = geometry['coordinates'];
    if (coordinates is! List || coordinates.length < 2) return null;
    final lon = _toFiniteDouble(coordinates[0]);
    final lat = _toFiniteDouble(coordinates[1]);
    if (lat == null || lon == null) return null;
    final qid = (properties['qid'] ?? '').toString().trim();
    final name = (properties['name'] ?? '').toString().trim();
    if (qid.isEmpty || name.isEmpty) return null;
    final sitelinks = _toInt(properties['sitelinks']) ?? 0;
    final placeTypeRaw = (properties['placeType'] ?? '').toString();
    final poi = RoutePoi(
      qid: qid,
      name: name,
      latLon: LatLng(lat, lon),
      type: FlightPoiType.fromRaw(placeTypeRaw),
      sitelinks: sitelinks,
    );
    return RoutePoiSummary(
      poi: poi,
      description: (properties['description'] ?? '').toString(),
      routeProgress: _toFiniteDouble(properties['routeProgress']),
    );
  }

  List<FlightWaypoint> _parseWaypoints(Map<String, dynamic> routeMap) {
    final waypointsRaw = routeMap['waypoints'];
    if (waypointsRaw is List) {
      final parsed = waypointsRaw
          .map(_parseWaypointObject)
          .whereType<FlightWaypoint>()
          .toList(growable: false);
      if (parsed.length >= 2) return parsed;
    }
    return _parseLineStringToWaypoints(routeMap['path']);
  }

  FlightRouteMetrics _parseRouteMetrics(
    Map<String, dynamic> routeMap,
    Map<String, dynamic> payload,
  ) {
    final metricsRaw = routeMap['metrics'];
    final metricsMap = metricsRaw is Map
        ? metricsRaw.cast<String, dynamic>()
        : const <String, dynamic>{};
    final flightInfoRaw = payload['flightInfo'];
    final flightInfo = flightInfoRaw is Map
        ? flightInfoRaw.cast<String, dynamic>()
        : const <String, dynamic>{};
    final greatCircleDistanceKm =
        _toFiniteDouble(metricsMap['greatCircleDistanceKm']) ?? 0;
    final actualDistanceKm = _toFiniteDouble(metricsMap['actualDistanceKm']);
    final cruiseMinutes =
        _toInt(metricsMap['approxDurationMinutes']) ??
        FlightRouteMetrics.estimateCruiseMinutes(greatCircleDistanceKm);
    final actualBlockMinutes =
        _toInt(metricsMap['actualDurationMinutes']) ??
        _toInt(flightInfo['actualDurationMinutes']);
    return FlightRouteMetrics(
      greatCircleDistanceKm: greatCircleDistanceKm,
      cruiseMinutes: cruiseMinutes,
      actualDistanceKm: actualDistanceKm,
      actualBlockMinutes: actualBlockMinutes,
    );
  }

  List<FlightWaypoint> _parseLineStringToWaypoints(dynamic lineRaw) {
    if (lineRaw is! Map) return const [];
    final line = lineRaw.cast<String, dynamic>();
    if (line['type'] != 'LineString') return const [];
    final coordinates = line['coordinates'];
    if (coordinates is! List) return const [];
    return coordinates
        .map(_parseLonLatPointForWaypoints)
        .whereType<FlightWaypoint>()
        .toList(growable: false);
  }

  FlightWaypoint? _parseWaypointObject(dynamic raw) {
    if (raw is! Map) return null;
    final map = raw.cast<String, dynamic>();
    final lat = _toFiniteDouble(map['lat']);
    final lon = _toFiniteDouble(map['lon']);
    if (lat == null || lon == null) return null;
    return FlightWaypoint(
      latLon: LatLng(lat, lon),
      timestamp: _toInt(map['timestamp']) ?? 0,
      altitude: _toInt(map['altitude']) ?? 0,
    );
  }

  List<LatLng> _parsePolygonExterior(dynamic polygonRaw) {
    if (polygonRaw is! Map) return const [];
    final polygon = polygonRaw.cast<String, dynamic>();
    if (polygon['type'] != 'Polygon') return const [];
    final coordinates = polygon['coordinates'];
    if (coordinates is! List || coordinates.isEmpty) return const [];
    final exterior = coordinates.first;
    if (exterior is! List) return const [];
    return exterior
        .map(_parseLonLatPoint)
        .whereType<LatLng>()
        .toList(growable: false);
  }

  List<List<LatLng>> _parseCorridorPolygons(Map<String, dynamic> routeMap) {
    final multiRaw = routeMap['corridorMultiPolygon'];
    final parsedMulti = _parseMultiPolygonExteriors(multiRaw);
    if (parsedMulti.isNotEmpty) {
      return parsedMulti;
    }
    final parsedLegacy = _parsePolygonExterior(routeMap['corridor']);
    if (parsedLegacy.length >= 3) {
      return [parsedLegacy];
    }
    return const [];
  }

  List<List<LatLng>> _parseMultiPolygonExteriors(dynamic multiPolygonRaw) {
    if (multiPolygonRaw is! Map) return const [];
    final multi = multiPolygonRaw.cast<String, dynamic>();
    if (multi['type'] != 'MultiPolygon') return const [];
    final coordinates = multi['coordinates'];
    if (coordinates is! List || coordinates.isEmpty) return const [];

    final out = <List<LatLng>>[];
    for (final polygonRaw in coordinates) {
      if (polygonRaw is! List || polygonRaw.isEmpty) continue;
      final exteriorRaw = polygonRaw.first;
      if (exteriorRaw is! List) continue;
      final ring = exteriorRaw
          .map(_parseLonLatPoint)
          .whereType<LatLng>()
          .toList(growable: false);
      if (ring.length >= 3) {
        out.add(ring);
      }
    }
    return out;
  }

  LatLng? _parseLonLatPoint(dynamic pointRaw) {
    if (pointRaw is! List || pointRaw.length < 2) return null;
    final lon = _toFiniteDouble(pointRaw[0]);
    final lat = _toFiniteDouble(pointRaw[1]);
    if (lat == null || lon == null) return null;
    return LatLng(lat, lon);
  }

  FlightWaypoint? _parseLonLatPointForWaypoints(dynamic pointRaw) {
    final latLon = _parseLonLatPoint(pointRaw);
    if (latLon == null) return null;
    return FlightWaypoint(latLon: latLon, timestamp: 0, altitude: 0);
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
}
