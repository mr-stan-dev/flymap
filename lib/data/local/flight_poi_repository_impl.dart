import 'dart:math' as math;

import 'package:flymap/data/local/places_wiki_local_data_source.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/entity/route_poi.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/repository/flight_poi_repository.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:latlong2/latlong.dart';

class LocalFlightPOIRepository implements FlightPOIRepository {
  LocalFlightPOIRepository({required PlacesWikiLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  final Logger _logger = const Logger('LocalFlightPOIRepository');
  final PlacesWikiLocalDataSource _localDataSource;
  final MapUtils _mapUtils = MapUtils();

  @override
  Future<List<RoutePoi>> getRoutePois({
    required FlightRoute route,
    required int prefetchLimit,
  }) async {
    if (route.corridor.length < 3) {
      _logger.log(
        'Skip getRoutePois: invalid inputs corridor=${route.corridor.length}',
      );
      return const [];
    }
    final totalStopwatch = Stopwatch()..start();

    final bbox = _buildBounds(route.corridor);
    _logger.log(
      'getRoutePois route=${route.routeCode} prefetch=$prefetchLimit '
      'bbox=(${bbox.minLat},${bbox.maxLat},${bbox.minLon},${bbox.maxLon}) '
      'waypoints=${route.waypoints.length} corridor=${route.corridor.length}',
    );
    final queryStopwatch = Stopwatch()..start();
    final rawCandidates = await _localDataSource.queryByBounds(
      minLat: bbox.minLat,
      maxLat: bbox.maxLat,
      minLon: bbox.minLon,
      maxLon: bbox.maxLon,
      limit: prefetchLimit,
    );
    queryStopwatch.stop();

    if (rawCandidates.isEmpty) {
      _logger.log('getRoutePois no raw candidates');
      return const [];
    }

    final corridorStopwatch = Stopwatch()..start();
    final insideCorridor = rawCandidates
        .where((poi) => _mapUtils.isPointInPolygon(poi.latLon, route.corridor))
        .toList(growable: false);
    corridorStopwatch.stop();
    _logger.log(
      'getRoutePois candidates raw=${rawCandidates.length} insideCorridor=${insideCorridor.length} '
      'queryMs=${queryStopwatch.elapsedMilliseconds} '
      'corridorFilterMs=${corridorStopwatch.elapsedMilliseconds}',
    );

    if (insideCorridor.isEmpty) {
      _logger.log('getRoutePois insideCorridor=0');
      return const [];
    }

    final result = insideCorridor;
    final typeCounts = <String, int>{};
    for (final poi in result) {
      typeCounts.update(poi.type.rawValue, (v) => v + 1, ifAbsent: () => 1);
    }
    final sample = result
        .take(5)
        .map((e) => '${e.name}/${e.type.rawValue}')
        .join(', ');
    totalStopwatch.stop();
    _logger.log(
      'getRoutePois result=${result.length} mode=all_corridor_pois '
      'totalMs=${totalStopwatch.elapsedMilliseconds} '
      'typeCounts=$typeCounts'
      '${sample.isEmpty ? '' : ' sample=[$sample]'}',
    );
    return result;
  }

  _Bounds _buildBounds(List<LatLng> points) {
    var minLat = double.infinity;
    var maxLat = -double.infinity;
    var minLon = double.infinity;
    var maxLon = -double.infinity;

    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLon = math.min(minLon, point.longitude);
      maxLon = math.max(maxLon, point.longitude);
    }

    return _Bounds(
      minLat: minLat,
      maxLat: maxLat,
      minLon: minLon,
      maxLon: maxLon,
    );
  }
}

class _Bounds {
  const _Bounds({
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });

  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;
}
