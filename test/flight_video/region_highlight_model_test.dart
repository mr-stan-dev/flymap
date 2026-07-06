import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/route_region.dart';
import 'package:flymap/domain/entity/route_region_type.dart';
import 'package:flymap/ui/screens/flight_video/rendering/region_highlight_model.dart';
import 'package:latlong2/latlong.dart' show LatLng;

void main() {
  RouteRegion regionOf({
    required String name,
    required RouteRegionType type,
    required double encounterKm,
    required double insideKm,
    List<List<double>>? ring,
  }) {
    final outerRing =
        ring ??
        [
          [0.0, 0.0],
          [10.0, 0.0],
          [10.0, 10.0],
          [0.0, 10.0],
          [0.0, 0.0],
        ];
    return RouteRegion(
      qid: name,
      name: name,
      regionType: type,
      pathFirstEncounterKm: encounterKm,
      pathLengthInsideKm: insideKm,
      geometry: RouteRegionGeometry(
        type: 'Polygon',
        geoJson: {
          'type': 'Polygon',
          'coordinates': [outerRing],
        },
      ),
    );
  }

  group('RegionHighlightModel', () {
    test('builds sequential segments from encounter metrics', () {
      final model = RegionHighlightModel.fromRegions([
        regionOf(
          name: 'United Kingdom',
          type: RouteRegionType.country,
          encounterKm: 0,
          insideKm: 300,
        ),
        regionOf(
          name: 'France',
          type: RouteRegionType.country,
          encounterKm: 350,
          insideKm: 650,
        ),
      ], totalKm: 1000);

      expect(model.segments, hasLength(2));
      expect(model.activeAt(0.1)!.region.label, 'United Kingdom');
      expect(model.activeAt(0.32), isNull);
      expect(model.activeAt(0.5)!.region.label, 'France');
    });

    test('most recently entered region wins overlaps, then falls back', () {
      final model = RegionHighlightModel.fromRegions([
        regionOf(
          name: 'France',
          type: RouteRegionType.country,
          encounterKm: 0,
          insideKm: 1000,
        ),
        regionOf(
          name: 'Alps',
          type: RouteRegionType.mountainRange,
          encounterKm: 400,
          insideKm: 200,
        ),
      ], totalKm: 1000);

      expect(model.activeAt(0.2)!.region.label, 'France');
      expect(model.activeAt(0.5)!.region.label, 'Alps');
      expect(model.activeAt(0.7)!.region.label, 'France');
    });

    test('drops blink-length segments', () {
      final model = RegionHighlightModel.fromRegions([
        regionOf(
          name: 'Monaco',
          type: RouteRegionType.country,
          encounterKm: 500,
          insideKm: 10, // 1% of the route, below the 5% minimum
        ),
      ], totalKm: 1000);

      expect(model.segments, isEmpty);
    });

    test('opacity fades at segment edges', () {
      final model = RegionHighlightModel.fromRegions([
        regionOf(
          name: 'France',
          type: RouteRegionType.country,
          encounterKm: 200,
          insideKm: 600,
        ),
      ], totalKm: 1000);

      expect(model.opacityAt(0.1), 0);
      expect(
        model.opacityAt(0.2 + RegionHighlightModel.fadeSpan / 2),
        closeTo(0.5, 1e-9),
      );
      expect(model.opacityAt(0.5), 1);
      expect(model.opacityAt(0.9), 0);
    });

    test('regions without polygons are skipped', () {
      final region = RouteRegion(
        qid: 'x',
        name: 'Pointless',
        regionType: RouteRegionType.country,
        pathFirstEncounterKm: 0,
        pathLengthInsideKm: 500,
        geometry: const RouteRegionGeometry(
          type: 'Point',
          geoJson: {
            'type': 'Point',
            'coordinates': [1.0, 2.0],
          },
        ),
      );
      final model = RegionHighlightModel.fromRegions([region], totalKm: 1000);
      expect(model.segments, isEmpty);
    });

    test('parses MultiPolygon rings with bounds', () {
      final region = RouteRegion(
        qid: 'x',
        name: 'Islands',
        regionType: RouteRegionType.archipelago,
        pathFirstEncounterKm: 0,
        pathLengthInsideKm: 500,
        geometry: const RouteRegionGeometry(
          type: 'MultiPolygon',
          geoJson: {
            'type': 'MultiPolygon',
            'coordinates': [
              [
                [
                  [0.0, 0.0],
                  [1.0, 0.0],
                  [1.0, 1.0],
                  [0.0, 0.0],
                ],
              ],
              [
                [
                  [5.0, 5.0],
                  [6.0, 5.0],
                  [6.0, 6.0],
                  [5.0, 5.0],
                ],
              ],
            ],
          },
        ),
      );
      final model = RegionHighlightModel.fromRegions([region], totalKm: 1000);
      expect(model.segments, hasLength(1));
      final rings = model.segments.first.region.rings;
      expect(rings, hasLength(2));
      expect(rings.first.points, hasLength(4));
      expect(rings.first.bounds.width, greaterThan(0));
    });

    test('pin anchors sit at segment midpoints on the route', () {
      final model = RegionHighlightModel.fromRegions(
        [
          regionOf(
            name: 'France',
            type: RouteRegionType.country,
            encounterKm: 200,
            insideKm: 600,
          ),
        ],
        totalKm: 1000,
        routePointAt: (s) => LatLng(s * 10, s * 20),
      );
      expect(model.segments.single.pinAnchor, const LatLng(5.0, 10.0));
      expect(model.pins.single.region.label, 'France');
    });

    test('short country crossings still get a pin (no min-span for pins)', () {
      // A brief clip of Switzerland (2% of the route) is below the display
      // min-span but must still produce a pin.
      final model = RegionHighlightModel.fromRegions(
        [
          regionOf(
            name: 'Switzerland',
            type: RouteRegionType.country,
            encounterKm: 500,
            insideKm: 20,
          ),
        ],
        totalKm: 1000,
        routePointAt: (s) => LatLng(s, 0),
      );
      expect(model.segments, isEmpty, reason: 'below display min-span');
      expect(model.pins, hasLength(1));
      expect(model.pins.single.region.label, 'Switzerland');
    });

    test('one pin per country even when a sea splits its window', () {
      // Italy's window is interrupted by a sea (entered later, wins overlap),
      // producing two Italy segments — but only ONE pin, popping at first
      // entry and anchored at the LONGEST Italy crossing.
      final model = RegionHighlightModel.fromRegions(
        [
          regionOf(
            name: 'Italy',
            type: RouteRegionType.country,
            encounterKm: 200,
            insideKm: 800,
          ),
          regionOf(
            name: 'Tyrrhenian Sea',
            type: RouteRegionType.sea,
            encounterKm: 300,
            insideKm: 200,
          ),
        ],
        totalKm: 1000,
        routePointAt: (s) => LatLng(s, 0),
      );

      final italySegments = model.segments
          .where((s) => s.region.label == 'Italy')
          .toList();
      expect(italySegments, hasLength(2));

      final pins = model.pins;
      expect(pins, hasLength(1), reason: 'seas get no pins, Italy only one');
      final pin = pins.single;
      expect(pin.region.label, 'Italy');
      expect(pin.sPop, closeTo(0.2, 1e-9));
      // Longest Italy segment is 0.5-1.0 -> anchor at s=0.75.
      expect(pin.anchor.latitude, closeTo(0.75, 1e-9));
    });

    test('end card chips list every country crossed, in encounter order', () {
      // Countries only (Alps, container islands excluded), and EVERY one the
      // route crosses appears — no ranking/truncation that could hide a
      // country the map pins already showed.
      final chips = RegionHighlightModel.endCardChips([
        regionOf(
          name: 'United Kingdom',
          type: RouteRegionType.country,
          encounterKm: 0,
          insideKm: 300,
        ),
        regionOf(
          name: 'Great Britain',
          type: RouteRegionType.island,
          encounterKm: 0,
          insideKm: 300,
        ),
        regionOf(
          name: 'Alps',
          type: RouteRegionType.mountainRange,
          encounterKm: 700,
          insideKm: 300,
        ),
        regionOf(
          name: 'Italy',
          type: RouteRegionType.country,
          encounterKm: 1000,
          insideKm: 430,
        ),
        regionOf(
          name: 'France',
          type: RouteRegionType.country,
          encounterKm: 320,
          insideKm: 650,
        ),
      ]);
      final labels = chips.map((c) => c.label).toList();
      // Countries in first-encounter order; natural regions dropped.
      expect(labels, ['United Kingdom', 'France', 'Italy']);
      expect(labels, isNot(contains('Alps')));
      expect(labels, isNot(contains('Great Britain')));
      expect(chips.first.countryCode, isNotNull);
      expect(chips.last.countryCode, isNotNull);
    });

    test('end card chips dedupe a country crossed twice', () {
      final chips = RegionHighlightModel.endCardChips([
        regionOf(
          name: 'Russia',
          type: RouteRegionType.country,
          encounterKm: 0,
          insideKm: 200,
        ),
        regionOf(
          name: 'Kazakhstan',
          type: RouteRegionType.country,
          encounterKm: 200,
          insideKm: 100,
        ),
        regionOf(
          name: 'Russia',
          type: RouteRegionType.country,
          encounterKm: 300,
          insideKm: 200,
        ),
      ]);
      expect(chips.map((c) => c.label).toList(), ['Russia', 'Kazakhstan']);
    });

    test('flag emoji conversion', () {
      expect(RegionHighlightModel.flagEmoji('FR'), '🇫🇷');
      expect(RegionHighlightModel.flagEmoji('gb'), '🇬🇧');
      expect(RegionHighlightModel.flagEmoji('X'), isNull);
      expect(RegionHighlightModel.flagEmoji('12'), isNull);
      expect(RegionHighlightModel.flagEmoji(null), isNull);
    });

    test('non-country types map to themed emoji', () {
      expect(
        RegionHighlightModel.emojiFor(
          regionOf(
            name: 'Mediterranean Sea',
            type: RouteRegionType.sea,
            encounterKm: 0,
            insideKm: 1,
          ),
        ),
        '🌊',
      );
      expect(
        RegionHighlightModel.emojiFor(
          regionOf(
            name: 'Alps',
            type: RouteRegionType.mountainRange,
            encounterKm: 0,
            insideKm: 1,
          ),
        ),
        '⛰️',
      );
    });
  });
}
