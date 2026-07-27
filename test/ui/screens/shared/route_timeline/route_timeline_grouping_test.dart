import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/route_region.dart';
import 'package:flymap/domain/entity/route_region_type.dart';
import 'package:flymap/ui/screens/shared/route_timeline/route_timeline_grouping.dart';

void main() {
  test(
    'groupByTimeline can use proportional total duration for approximate routes',
    () {
      final groups = RouteTimelineGrouping.groupByTimeline(
        [_region(pathFirstEncounterKm: 744, pathFirstEncounterMinutes: -1)],
        cruiseSpeedKmh: 850,
        routeDistanceKm: 1487.5,
        blockMinutes: 160,
        useTotalDurationProportion: true,
      );

      expect(groups.single.minuteFromDeparture, 80);
    },
  );

  test('arrivalMinutes uses provided approximate total as SSOT', () {
    final groups = RouteTimelineGrouping.groupByTimeline([
      _region(pathFirstEncounterKm: 1400, pathFirstEncounterMinutes: 100),
    ], cruiseSpeedKmh: 850);

    expect(
      RouteTimelineGrouping.arrivalMinutes(
        routeDistanceKm: 1487.5,
        blockMinutes: 105,
        cruiseSpeedKmh: 850,
        groups: groups,
      ),
      105,
    );
  });

  test('arrivalMinutes can treat actual FR24 duration as authoritative', () {
    final groups = RouteTimelineGrouping.groupByTimeline(
      [_region(pathFirstEncounterKm: 6400, pathFirstEncounterMinutes: 570)],
      cruiseSpeedKmh: 800,
      maxTimelineMinutes: 480,
    );

    expect(groups.single.minuteFromDeparture, 480);
    expect(
      RouteTimelineGrouping.arrivalMinutes(
        routeDistanceKm: 6401.9,
        blockMinutes: 480,
        cruiseSpeedKmh: 800,
        groups: groups,
        blockMinutesIsAuthoritative: true,
      ),
      480,
    );
  });
}

RouteRegion _region({
  required double pathFirstEncounterKm,
  required int pathFirstEncounterMinutes,
}) {
  return RouteRegion(
    qid: 'Q1',
    name: 'Region',
    regionType: RouteRegionType.country,
    pathFirstEncounterKm: pathFirstEncounterKm,
    pathLengthInsideKm: 10,
    pathFirstEncounterMinutes: pathFirstEncounterMinutes,
    geometry: const RouteRegionGeometry(
      type: 'Polygon',
      geoJson: <String, dynamic>{'type': 'Polygon', 'coordinates': []},
    ),
  );
}
