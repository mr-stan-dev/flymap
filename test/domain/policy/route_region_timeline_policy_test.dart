import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/route_region.dart';
import 'package:flymap/domain/entity/route_region_type.dart';
import 'package:flymap/domain/policy/route_region_timeline_policy.dart';
import 'package:flymap/utils/country_name_utils.dart';

RouteRegion _region(
  String name,
  RouteRegionType type, {
  required double firstKm,
  required double insideKm,
}) {
  return RouteRegion(
    qid: name,
    name: name,
    regionType: type,
    pathFirstEncounterKm: firstKm,
    pathLengthInsideKm: insideKm,
    geometry: const RouteRegionGeometry(type: 'Polygon', geoJson: {}),
  );
}

void main() {
  group('RouteRegionTimelinePolicy', () {
    test('international leads with transit flags, then fills with regions', () {
      final markers = RouteRegionTimelinePolicy.forFlight(
        regions: [
          _region(
            'Germany',
            RouteRegionType.country,
            firstKm: 200,
            insideKm: 300,
          ),
          _region(
            'Austria',
            RouteRegionType.country,
            firstKm: 600,
            insideKm: 250,
          ),
          _region(
            'Alps',
            RouteRegionType.mountainRange,
            firstKm: 450,
            insideKm: 400,
          ),
        ],
        departureCountryCode: 'FR',
        arrivalCountryCode: 'IT',
        totalRouteKm: 1000,
      );
      // Transit countries first (Germany, Austria), then the top regional
      // feature (Alps) fills a remaining slot — all route-ordered. The edge
      // countries (FR/IT) live at the strip endpoints, not here.
      expect(markers.map((m) => m.name).toList(), [
        'Germany',
        'Alps',
        'Austria',
      ]);
    });

    test('international excludes departure and arrival countries', () {
      final markers = RouteRegionTimelinePolicy.forFlight(
        regions: [
          _region(
            'France',
            RouteRegionType.country,
            firstKm: 500,
            insideKm: 400,
          ),
          _region(
            'Bay of Biscay',
            RouteRegionType.bay,
            firstKm: 300,
            insideKm: 200,
          ),
        ],
        departureCountryCode: 'GB',
        arrivalCountryCode: 'ES',
        totalRouteKm: 1246,
      );
      // Transit flag (France) leads; the bay fills the next slot. The
      // departure/arrival countries (GB/ES) are shown at the strip endpoints,
      // never repeated in the middle.
      expect(markers.map((m) => m.name).toList(), ['Bay of Biscay', 'France']);
      final gb = CountryNameUtils.fromCode('GB', languageCode: 'en');
      final es = CountryNameUtils.fromCode('ES', languageCode: 'en');
      expect(markers.map((m) => m.name), isNot(contains(gb)));
      expect(markers.map((m) => m.name), isNot(contains(es)));
    });

    test('domestic shows administrative and natural regions with artwork', () {
      final markers = RouteRegionTimelinePolicy.forFlight(
        regions: [
          _region('Nevada', RouteRegionType.state, firstKm: 100, insideKm: 400),
          _region(
            'Rocky Mountains',
            RouteRegionType.mountainRange,
            firstKm: 800,
            insideKm: 500,
          ),
          _region(
            'Great Plains',
            RouteRegionType.plain,
            firstKm: 1500,
            insideKm: 900,
          ),
          _region(
            'Mojave Desert',
            RouteRegionType.desert,
            firstKm: 150,
            insideKm: 300,
          ),
        ],
        departureCountryCode: 'US',
        arrivalCountryCode: 'US',
        totalRouteKm: 4000,
      );
      final names = markers.map((m) => m.name).toList();
      // Highest coverage (Plains, Rockies, Nevada), then route-ordered.
      expect(names, ['Nevada', 'Rocky Mountains', 'Great Plains']);
    });

    test('caps at three markers', () {
      final markers = RouteRegionTimelinePolicy.forFlight(
        regions: [
          for (var i = 0; i < 6; i++)
            _region(
              'Sea $i',
              RouteRegionType.sea,
              firstKm: i * 100.0,
              insideKm: 200.0 - i,
            ),
        ],
        departureCountryCode: 'US',
        arrivalCountryCode: 'US',
        totalRouteKm: 1000,
      );
      expect(markers, hasLength(3));
    });

    test('uses generic artwork for an administrative region', () {
      final markers = RouteRegionTimelinePolicy.forFlight(
        regions: [
          _region(
            'California',
            RouteRegionType.state,
            firstKm: 0,
            insideKm: 500,
          ),
        ],
        departureCountryCode: 'US',
        arrivalCountryCode: 'US',
        totalRouteKm: 1000,
      );
      expect(markers, hasLength(1));
      expect(markers.single.name, 'California');
      expect(markers.single.regionType, RouteRegionType.state);
    });
  });
}
