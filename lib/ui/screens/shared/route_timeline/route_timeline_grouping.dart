import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flymap/domain/policy/flight_duration_estimate_policy.dart';
import 'package:flymap/domain/entity/route_region.dart';
import 'package:flymap/domain/entity/route_region_type.dart';

class RouteTimelineRegionGroup extends Equatable {
  const RouteTimelineRegionGroup({
    required this.distanceFromDepartureKm,
    required this.minuteFromDeparture,
    required this.regions,
  });

  final double distanceFromDepartureKm;
  final int minuteFromDeparture;
  final List<RouteRegion> regions;

  RouteRegion? get topRegion => regions.isEmpty ? null : regions.first;

  @override
  List<Object?> get props => [
    distanceFromDepartureKm,
    minuteFromDeparture,
    regions,
  ];
}

class RouteTimelineGrouping {
  static const int defaultMaxRegions = 50;
  static const int timelineMinuteStep = 5;
  static const double groupingDistanceKm = 15;

  const RouteTimelineGrouping._();

  static List<RouteRegion> rankAndLimit(
    List<RouteRegion> regions, {
    int maxRegions = defaultMaxRegions,
  }) {
    if (regions.isEmpty || maxRegions <= 0) return const [];
    final bestByQid = <String, RouteRegion>{};
    for (final region in regions) {
      final current = bestByQid[region.qid];
      if (current == null || _compareByRank(region, current) < 0) {
        bestByQid[region.qid] = region;
      }
    }
    final ranked = bestByQid.values.toList(growable: false)
      ..sort(_compareByRank);
    final limited = ranked.take(maxRegions).toList(growable: false);
    limited.sort(_compareByPath);
    return limited;
  }

  static List<RouteTimelineRegionGroup> groupByTimeline(
    List<RouteRegion> regions, {
    required int cruiseSpeedKmh,
    int maxRegions = defaultMaxRegions,
    int minuteStep = timelineMinuteStep,
    int? maxTimelineMinutes,
    double? routeDistanceKm,
    int? blockMinutes,
    bool useTotalDurationProportion = false,
  }) {
    final limited = rankAndLimit(regions, maxRegions: maxRegions);
    if (limited.isEmpty) return const [];
    final distanceGroups = <List<RouteRegion>>[];
    List<RouteRegion> current = <RouteRegion>[];
    double? groupStartKm;
    for (final region in limited) {
      final distanceKm = region.pathFirstEncounterKm;
      if (current.isEmpty) {
        current = <RouteRegion>[region];
        groupStartKm = distanceKm;
        continue;
      }
      final startKm = groupStartKm ?? distanceKm;
      if ((distanceKm - startKm) < groupingDistanceKm) {
        current.add(region);
        continue;
      }
      distanceGroups.add(current);
      current = <RouteRegion>[region];
      groupStartKm = distanceKm;
    }
    if (current.isNotEmpty) {
      distanceGroups.add(current);
    }

    return distanceGroups
        .map((regionsInGroup) {
          final groupRegions = [...regionsInGroup]..sort(_compareInGroup);
          final top = groupRegions.first;
          return RouteTimelineRegionGroup(
            distanceFromDepartureKm: top.pathFirstEncounterKm,
            minuteFromDeparture: _clampTimelineMinute(
              regionTimelineMinute(
                top,
                cruiseSpeedKmh: cruiseSpeedKmh,
                minuteStep: minuteStep,
                routeDistanceKm: routeDistanceKm,
                blockMinutes: blockMinutes,
                useTotalDurationProportion: useTotalDurationProportion,
              ),
              maxTimelineMinutes: maxTimelineMinutes,
            ),
            regions: groupRegions,
          );
        })
        .toList(growable: false);
  }

  static int toTimelineMinute(
    double distanceKm, {
    required int cruiseSpeedKmh,
    int minuteStep = timelineMinuteStep,
  }) {
    return FlightDurationEstimatePolicy.estimateCruiseMinutes(
      distanceKm: distanceKm,
      cruiseSpeedKmh: cruiseSpeedKmh,
      roundToMinutes: minuteStep <= 1 ? 1 : minuteStep,
    );
  }

  static int regionTimelineMinute(
    RouteRegion region, {
    required int cruiseSpeedKmh,
    int minuteStep = timelineMinuteStep,
    double? routeDistanceKm,
    int? blockMinutes,
    bool useTotalDurationProportion = false,
  }) {
    final timestampMinute = region.pathFirstEncounterMinutes;
    if (timestampMinute != null && timestampMinute >= 0) {
      final step = minuteStep <= 1 ? 1 : minuteStep;
      return (timestampMinute / step).round() * step;
    }
    if (useTotalDurationProportion &&
        blockMinutes != null &&
        blockMinutes > 0 &&
        routeDistanceKm != null &&
        routeDistanceKm.isFinite &&
        routeDistanceKm > 0) {
      final progress = (region.pathFirstEncounterKm / routeDistanceKm).clamp(
        0.0,
        1.0,
      );
      final rawMinutes = blockMinutes * progress;
      final step = minuteStep <= 1 ? 1 : minuteStep;
      return (rawMinutes / step).round() * step;
    }
    return toTimelineMinute(
      region.pathFirstEncounterKm,
      cruiseSpeedKmh: cruiseSpeedKmh,
      minuteStep: minuteStep,
    );
  }

  static int _compareByRank(RouteRegion a, RouteRegion b) {
    final aTypeRank = _regionTypeRank(a.regionType);
    final bTypeRank = _regionTypeRank(b.regionType);
    if (aTypeRank != bTypeRank) return aTypeRank.compareTo(bTypeRank);

    final byLength = b.pathLengthInsideKm.compareTo(a.pathLengthInsideKm);
    if (byLength != 0) return byLength;

    final byPath = a.pathFirstEncounterKm.compareTo(b.pathFirstEncounterKm);
    if (byPath != 0) return byPath;

    final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    if (byName != 0) return byName;
    return a.qid.compareTo(b.qid);
  }

  static int _compareByPath(RouteRegion a, RouteRegion b) {
    final byPath = a.pathFirstEncounterKm.compareTo(b.pathFirstEncounterKm);
    if (byPath != 0) return byPath;
    return _compareByRank(a, b);
  }

  static int _compareInGroup(RouteRegion a, RouteRegion b) {
    final byRank = _compareByRank(a, b);
    if (byRank != 0) return byRank;
    return _compareByPath(a, b);
  }

  static int _regionTypeRank(RouteRegionType type) {
    switch (type) {
      case RouteRegionType.country:
        return 0;
      case RouteRegionType.region:
        return 1;
      case RouteRegionType.state:
        return 2;
      case RouteRegionType.province:
        return 3;
      case RouteRegionType.continent:
      case RouteRegionType.geoarea:
        return 4;
      case RouteRegionType.strait:
      case RouteRegionType.channel:
      case RouteRegionType.sea:
      case RouteRegionType.ocean:
        return 20;
      case RouteRegionType.gulf:
        return 21;
      case RouteRegionType.bay:
        return 22;
      case RouteRegionType.alkalineLake:
      case RouteRegionType.lake:
        return 25;
      case RouteRegionType.archipelago:
      case RouteRegionType.island:
        return 30;
      case RouteRegionType.peninsula:
      case RouteRegionType.coast:
        return 32;
      case RouteRegionType.reservoir:
      case RouteRegionType.delta:
        return 33;
      case RouteRegionType.mountainRange:
      case RouteRegionType.valley:
      case RouteRegionType.plateau:
      case RouteRegionType.plain:
      case RouteRegionType.basin:
      case RouteRegionType.lowland:
      case RouteRegionType.tundra:
      case RouteRegionType.wetlands:
      case RouteRegionType.desert:
        return 40;
      case RouteRegionType.isthmus:
      case RouteRegionType.unknown:
        return 50;
    }
  }

  static int arrivalMinutes({
    required double routeDistanceKm,
    required int blockMinutes,
    required int cruiseSpeedKmh,
    required List<RouteTimelineRegionGroup> groups,
    bool blockMinutesIsAuthoritative = false,
  }) {
    if (blockMinutes > 0) {
      return blockMinutes;
    }
    final estimatedTotalMinutes = _kmToMinutes(
      routeDistanceKm,
      cruiseSpeedKmh: cruiseSpeedKmh,
    );
    final groupsLastMinute = groups.isEmpty
        ? 0
        : groups.last.minuteFromDeparture;
    return math.max(
      math.max(blockMinutes, estimatedTotalMinutes),
      groupsLastMinute,
    );
  }

  static int _clampTimelineMinute(
    int minute, {
    required int? maxTimelineMinutes,
  }) {
    if (maxTimelineMinutes == null || maxTimelineMinutes <= 0) {
      return minute;
    }
    return minute.clamp(0, maxTimelineMinutes);
  }

  static int _kmToMinutes(double distanceKm, {required int cruiseSpeedKmh}) {
    return FlightDurationEstimatePolicy.estimateBlockMinutes(
      distanceKm: distanceKm,
      cruiseSpeedKmh: cruiseSpeedKmh,
      roundToMinutes: timelineMinuteStep,
    );
  }
}
