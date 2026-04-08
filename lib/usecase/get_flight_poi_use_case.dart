import 'dart:math' as math;

import 'package:flymap/entity/flight_poi_type.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/entity/map_detail_level.dart';
import 'package:flymap/entity/route_poi.dart';
import 'package:flymap/entity/route_poi_summary.dart';
import 'package:flymap/repository/flight_poi_repository.dart';
import 'package:flymap/usecase/poi_selection_config.dart';
import 'package:latlong2/latlong.dart';

class GetFlightPOIUseCase {
  GetFlightPOIUseCase({required FlightPOIRepository repository})
    : _repository = repository;

  final FlightPOIRepository _repository;

  // Fix 1: Per-type visual interest boost added to sitelinks before ranking.
  // Values represent "extra sitelinks worth of interest" from a flight window.
  // Natural spectacles (volcano, glacier, waterfall) are hard to spot and
  // unique, so they are boosted enough to beat obscure cities with equal
  // sitelinks counts.
  //
  // Using a switch on the exhaustive enum so the compiler enforces that every
  // future variant gets an explicit value.
  static int _typeInterestBoost(FlightPoiType type) => switch (type) {
    FlightPoiType.volcano => 500,
    FlightPoiType.glacier => 450,
    FlightPoiType.waterfall => 400,
    FlightPoiType.mountain => 350,
    FlightPoiType.island => 350,
    FlightPoiType.lake => 300,
    FlightPoiType.desert => 200,
    FlightPoiType.bay => 150,
    FlightPoiType.sea => 100,
    FlightPoiType.river => 100,
    FlightPoiType.city => 50,
    FlightPoiType.pass => 50,
    FlightPoiType.airport => 50,
    FlightPoiType.region => 0,
    FlightPoiType.unknown => 0,
  };

  int _rankScore(RoutePoi poi) => poi.sitelinks + _typeInterestBoost(poi.type);

  Future<List<RoutePoiSummary>> call({
    required FlightRoute route,
    required MapDetailLevel mapDetail,
  }) async {
    final includeAllVolcanoes = mapDetail == MapDetailLevel.pro;
    final maxPois = PoiSelectionConfig.maxPois(mapDetail);
    final prefetchLimit = PoiSelectionConfig.prefetchLimit(mapDetail);
    final segmentCount = PoiSelectionConfig.segmentCount(mapDetail);
    final cityCap = PoiSelectionConfig.cityCap(mapDetail);
    final softCapPerType = PoiSelectionConfig.softCapPerType(mapDetail);
    final minCitySegmentGap = PoiSelectionConfig.minCitySegmentGap(mapDetail);
    final candidates = await _repository.getRoutePois(
      route: route,
      prefetchLimit: prefetchLimit,
    );
    if (candidates.isEmpty) {
      return const [];
    }

    final selected = _selectPois(
      candidates: candidates,
      route: route,
      maxPois: maxPois,
      segmentCount: segmentCount,
      cityCap: cityCap,
      softCapPerType: softCapPerType,
      minCitySegmentGap: minCitySegmentGap,
      includeAllVolcanoes: includeAllVolcanoes,
    );
    final mapped = selected
        .map(
          (entry) => RoutePoiSummary.fromRoutePoi(
            entry.poi,
            routeProgress: entry.routeProgress,
          ),
        )
        .toList(growable: false);
    return mapped;
  }

  List<_SelectedPoi> _selectPois({
    required List<RoutePoi> candidates,
    required FlightRoute route,
    required int maxPois,
    required int segmentCount,
    required int cityCap,
    required int softCapPerType,
    required int minCitySegmentGap,
    required bool includeAllVolcanoes,
  }) {
    // Deduplicate by QID.
    final uniqueByQid = <String, RoutePoi>{};
    for (final poi in candidates) {
      final key = poi.qid.trim();
      if (key.isEmpty) continue;
      uniqueByQid.putIfAbsent(key, () => poi);
    }

    // Fix 3: Exclude unknown type — no visual interest metadata available.
    final deduped = uniqueByQid.values
        .where((p) => p.type != FlightPoiType.unknown)
        .toList(growable: false);

    if (deduped.isEmpty || route.waypoints.length < 2 || maxPois <= 0) {
      return const [];
    }

    // Fix 5: Use nearest-point-on-segment projection for accurate route
    // progress instead of snapping to the nearest waypoint vertex. This
    // matters on routes with sparse waypoints (long open-ocean legs).
    final enriched = deduped
        .map((poi) {
          final routeProgress = _nearestProgressOnRoute(
            poi.latLon,
            route.waypoints,
          );
          final segmentIndex = ((routeProgress * segmentCount).floor()).clamp(
            0,
            segmentCount - 1,
          );
          return _SegmentPoi(
            poi: poi,
            segmentIndex: segmentIndex,
            routeProgress: routeProgress,
          );
        })
        .toList(growable: false);

    final selectedQids = <String>{};
    final selected = <_SelectedPoi>[];
    final typeCounts = <FlightPoiType, int>{};
    final segmentSelectedCounts = List<int>.filled(
      segmentCount,
      0,
      growable: false,
    );
    final citySegments = <int>[];
    var selectedCityCount = 0;

    if (includeAllVolcanoes) {
      final volcanoes =
          enriched
              .where((item) => item.poi.type == FlightPoiType.volcano)
              .toList(growable: false)
            ..sort((a, b) {
              final scoreDiff = _rankScore(b.poi).compareTo(_rankScore(a.poi));
              if (scoreDiff != 0) return scoreDiff;
              return a.poi.qid.compareTo(b.poi.qid);
            });
      for (final volcano in volcanoes) {
        selected.add(
          _SelectedPoi(
            poi: volcano.poi,
            segmentIndex: volcano.segmentIndex,
            routeProgress: volcano.routeProgress,
          ),
        );
        selectedQids.add(volcano.poi.qid);
        segmentSelectedCounts[volcano.segmentIndex]++;
        typeCounts.update(
          FlightPoiType.volcano,
          (v) => v + 1,
          ifAbsent: () => 1,
        );
      }
      if (selected.length >= maxPois) {
        return selected;
      }
    }

    final segments = List.generate(
      segmentCount,
      (_) => <_SegmentPoi>[],
      growable: false,
    );
    for (final item in enriched) {
      if (selectedQids.contains(item.poi.qid)) continue;
      segments[item.segmentIndex].add(item);
    }
    // Fix 1: Sort each segment bucket by composite rank score.
    for (final list in segments) {
      list.sort((a, b) {
        final scoreDiff = _rankScore(b.poi).compareTo(_rankScore(a.poi));
        if (scoreDiff != 0) return scoreDiff;
        return a.poi.qid.compareTo(b.poi.qid);
      });
    }

    final segmentCursor = List<int>.filled(segmentCount, 0, growable: false);

    bool trySelect(_SegmentPoi item, {required bool enforceSoftCap}) {
      if (selected.length >= maxPois) return false;
      if (selectedQids.contains(item.poi.qid)) return false;

      final type = item.poi.type;
      if (type == FlightPoiType.city) {
        if (selectedCityCount >= cityCap) return false;
        final hasNearbyCity = citySegments.any(
          (segment) => (segment - item.segmentIndex).abs() < minCitySegmentGap,
        );
        if (hasNearbyCity) return false;
      } else if (enforceSoftCap && (typeCounts[type] ?? 0) >= softCapPerType) {
        return false;
      }

      selected.add(
        _SelectedPoi(
          poi: item.poi,
          segmentIndex: item.segmentIndex,
          routeProgress: item.routeProgress,
        ),
      );
      selectedQids.add(item.poi.qid);
      segmentSelectedCounts[item.segmentIndex]++;
      typeCounts.update(type, (v) => v + 1, ifAbsent: () => 1);
      if (type == FlightPoiType.city) {
        selectedCityCount++;
        citySegments.add(item.segmentIndex);
      }
      return true;
    }

    // Coverage pass: walk each segment round-robin, taking top-ranked allowed POIs.
    var progress = true;
    while (selected.length < maxPois && progress) {
      progress = false;
      for (var i = 0; i < segmentCount; i++) {
        final bucket = segments[i];
        var cursor = segmentCursor[i];
        while (cursor < bucket.length) {
          final candidate = bucket[cursor];
          cursor++;
          if (trySelect(candidate, enforceSoftCap: true)) {
            progress = true;
            break;
          }
        }
        segmentCursor[i] = cursor;
      }
    }

    // Second coverage pass: relax type soft caps but keep city hard rules.
    // This keeps distribution across the route more even before any global fill.
    progress = true;
    while (selected.length < maxPois && progress) {
      progress = false;
      for (var i = 0; i < segmentCount; i++) {
        final bucket = segments[i];
        var cursor = segmentCursor[i];
        while (cursor < bucket.length) {
          final candidate = bucket[cursor];
          cursor++;
          if (trySelect(candidate, enforceSoftCap: false)) {
            progress = true;
            break;
          }
        }
        segmentCursor[i] = cursor;
      }
    }

    if (selected.length >= maxPois) {
      return selected;
    }

    // Gather skipped candidates and re-sort by composite rank score for fill.
    final remaining = <_SegmentPoi>[];
    for (var i = 0; i < segmentCount; i++) {
      final bucket = segments[i];
      for (var j = segmentCursor[i]; j < bucket.length; j++) {
        remaining.add(bucket[j]);
      }
    }
    remaining.sort((a, b) {
      final segmentCountDiff = segmentSelectedCounts[a.segmentIndex].compareTo(
        segmentSelectedCounts[b.segmentIndex],
      );
      if (segmentCountDiff != 0) return segmentCountDiff;
      final scoreDiff = _rankScore(b.poi).compareTo(_rankScore(a.poi));
      if (scoreDiff != 0) return scoreDiff;
      if (a.segmentIndex != b.segmentIndex) {
        return a.segmentIndex.compareTo(b.segmentIndex);
      }
      return a.poi.qid.compareTo(b.poi.qid);
    });

    // Fill pass with soft caps.
    for (final item in remaining) {
      if (selected.length >= maxPois) break;
      trySelect(item, enforceSoftCap: true);
    }
    // Fill pass without soft caps (hard city constraints still enforced).
    for (final item in remaining) {
      if (selected.length >= maxPois) break;
      trySelect(item, enforceSoftCap: false);
    }

    return selected;
  }

  // Fix 5: Finds the parametric position [0,1] of the nearest point on the
  // route polyline to [point]. Projects [point] onto each consecutive segment
  // and picks the segment with the smallest perpendicular distance, then
  // computes progress as cumulative arc length up to that projection divided
  // by total route arc length.
  //
  // Uses equirectangular (lat/lon Euclidean) approximation — accurate enough
  // for relative progress computation at all but the highest latitudes.
  double _nearestProgressOnRoute(LatLng point, List<LatLng> waypoints) {
    final n = waypoints.length;
    if (n < 2) return 0.0;

    // Pre-compute segment lengths.
    final segLengths = List<double>.filled(n - 1, 0.0);
    var totalLength = 0.0;
    for (var i = 0; i < n - 1; i++) {
      segLengths[i] = _segmentLength(waypoints[i], waypoints[i + 1]);
      totalLength += segLengths[i];
    }
    if (totalLength == 0) return 0.0;

    var bestDistSq = double.infinity;
    var bestProgress = 0.0;
    var cumLength = 0.0;

    for (var i = 0; i < n - 1; i++) {
      final a = waypoints[i];
      final b = waypoints[i + 1];
      final t = _projectOntoSegment(point, a, b);
      final nearestLat = a.latitude + t * (b.latitude - a.latitude);
      final nearestLon = a.longitude + t * (b.longitude - a.longitude);
      final distSq = _squaredDistance(point, LatLng(nearestLat, nearestLon));
      if (distSq < bestDistSq) {
        bestDistSq = distSq;
        bestProgress = (cumLength + t * segLengths[i]) / totalLength;
      }
      cumLength += segLengths[i];
    }

    return bestProgress.clamp(0.0, 1.0);
  }

  // Returns t in [0,1] for the projection of p onto segment a→b.
  double _projectOntoSegment(LatLng p, LatLng a, LatLng b) {
    final abLat = b.latitude - a.latitude;
    final abLon = b.longitude - a.longitude;
    final ab2 = abLat * abLat + abLon * abLon;
    if (ab2 == 0) return 0.0;
    final apLat = p.latitude - a.latitude;
    final apLon = p.longitude - a.longitude;
    return ((apLat * abLat + apLon * abLon) / ab2).clamp(0.0, 1.0);
  }

  double _segmentLength(LatLng a, LatLng b) {
    final dLat = a.latitude - b.latitude;
    final dLon = a.longitude - b.longitude;
    return math.sqrt(dLat * dLat + dLon * dLon);
  }

  double _squaredDistance(LatLng a, LatLng b) {
    final dLat = a.latitude - b.latitude;
    final dLon = a.longitude - b.longitude;
    return dLat * dLat + dLon * dLon;
  }
}

class _SegmentPoi {
  const _SegmentPoi({
    required this.poi,
    required this.segmentIndex,
    required this.routeProgress,
  });

  final RoutePoi poi;
  final int segmentIndex;
  final double routeProgress;
}

class _SelectedPoi {
  const _SelectedPoi({
    required this.poi,
    required this.segmentIndex,
    required this.routeProgress,
  });

  final RoutePoi poi;
  final int segmentIndex;
  final double routeProgress;
}
