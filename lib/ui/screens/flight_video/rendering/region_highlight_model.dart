import 'dart:math';
import 'dart:ui';

import 'package:flymap/domain/entity/route_region.dart';
import 'package:flymap/domain/entity/route_region_type.dart';
import 'package:flymap/ui/screens/flight_video/rendering/world_transform.dart';
import 'package:flymap/utils/country_name_utils.dart';
import 'package:latlong2/latlong.dart' show LatLng;

/// Label + artwork for chip-style UI (region chip, end card).
///
/// [artwork] (circular flag/type icon rasterized from the same assets the
/// in-app chips use) is attached asynchronously after construction; [emoji]
/// is the fallback when it is missing.
class RegionChipData {
  RegionChipData({
    required this.emoji,
    required this.label,
    this.countryCode,
    this.regionType,
  });

  final String emoji;
  final String label;
  final String? countryCode;
  final RouteRegionType? regionType;
  Image? artwork;
}

/// One polygon ring of a region in normalized Web-Mercator (0..1) space.
class RegionRing {
  RegionRing({required this.points, required this.bounds});

  final List<Offset> points;
  final Rect bounds;
}

/// A route region prepared for canvas drawing.
class RegionHighlight {
  RegionHighlight({
    required this.label,
    required this.emoji,
    required this.rings,
    required this.regionType,
    this.countryCode,
  });

  final String label;
  final String emoji;
  final List<RegionRing> rings;
  final RouteRegionType regionType;
  final String? countryCode;

  /// Circular flag/type icon; attached asynchronously, emoji is the fallback.
  Image? artwork;
}

/// One map pin: a country the route crosses, pinned once.
class RegionPin {
  RegionPin({
    required this.region,
    required this.anchor,
    required this.sPop,
  });

  final RegionHighlight region;

  /// Route point at the midpoint of the country's longest crossing segment.
  final LatLng anchor;

  /// Plane progress at which the pin pops in (first entry into the country).
  final double sPop;
}

/// When [region] is highlighted, in normalized route arc length.
class RegionHighlightSegment {
  RegionHighlightSegment({
    required this.region,
    required this.sStart,
    required this.sEnd,
    this.pinAnchor,
  });

  final RegionHighlight region;
  final double sStart;
  final double sEnd;

  /// Where this region's map pin sits: the route point at the middle of the
  /// segment (always near the camera path, never off-screen at follow zoom).
  final LatLng? pinAnchor;
}

/// Timeline of region highlights for a flight video: which region is lit and
/// chip-labelled at each point of the flight, mirroring the in-app route
/// overview experience.
///
/// Regions arrive with along-route metrics from the route overview backend
/// (`pathFirstEncounterKm`, `pathLengthInsideKm`). Overlaps (a sea inside a
/// crossing, a state inside a country) resolve to the most recently entered
/// region, so the highlight switches as the plane reaches something new and
/// falls back to the enclosing region afterwards.
class RegionHighlightModel {
  RegionHighlightModel._(this.segments, this.pins);

  factory RegionHighlightModel.fromRegions(
    List<RouteRegion> regions, {
    required double totalKm,
    double minSegmentSpan = defaultMinSegmentSpan,
    String? languageCode,
    LatLng Function(double s)? routePointAt,
  }) {
    if (totalKm <= 0 || regions.isEmpty) {
      return RegionHighlightModel._(const [], const []);
    }

    final windows = <({RegionHighlight region, double sStart, double sEnd})>[];
    for (final region in regions) {
      final rings = _parseRings(region.geometry.geoJson);
      if (rings.isEmpty) continue;
      final sStart = (region.pathFirstEncounterKm / totalKm).clamp(0.0, 1.0);
      final sEnd = ((region.pathFirstEncounterKm + region.pathLengthInsideKm) /
              totalKm)
          .clamp(0.0, 1.0);
      if (sEnd - sStart < 1e-4) continue;
      windows.add((
        region: RegionHighlight(
          label: region.name,
          emoji: emojiFor(region, languageCode: languageCode),
          rings: rings,
          regionType: region.regionType,
          countryCode: region.regionType == RouteRegionType.country
              ? CountryNameUtils.toCode(
                  region.name,
                  languageCode: languageCode ?? 'en',
                )
              : null,
        ),
        sStart: sStart,
        sEnd: sEnd,
      ));
    }
    if (windows.isEmpty) return RegionHighlightModel._(const [], const []);

    // Resolve overlaps: at every point the active region is the one entered
    // most recently. Build flat segments over the boundary grid, then merge.
    final boundaries = <double>{
      for (final w in windows) ...[w.sStart, w.sEnd],
    }.toList()..sort();

    final flat = <RegionHighlightSegment>[];
    for (var i = 0; i < boundaries.length - 1; i++) {
      final from = boundaries[i];
      final to = boundaries[i + 1];
      final mid = (from + to) / 2;
      ({RegionHighlight region, double sStart, double sEnd})? active;
      for (final w in windows) {
        if (w.sStart <= mid && mid < w.sEnd) {
          if (active == null || w.sStart > active.sStart) active = w;
        }
      }
      if (active == null) continue;
      if (flat.isNotEmpty &&
          identical(flat.last.region, active.region) &&
          (flat.last.sEnd - from).abs() < 1e-9) {
        flat[flat.length - 1] = RegionHighlightSegment(
          region: flat.last.region,
          sStart: flat.last.sStart,
          sEnd: to,
        );
      } else {
        flat.add(
          RegionHighlightSegment(
            region: active.region,
            sStart: from,
            sEnd: to,
          ),
        );
      }
    }

    final withAnchors = [
      for (final segment in flat)
        RegionHighlightSegment(
          region: segment.region,
          sStart: segment.sStart,
          sEnd: segment.sEnd,
          pinAnchor: routePointAt?.call((segment.sStart + segment.sEnd) / 2),
        ),
    ];

    // Pins come from the UNFILTERED timeline: even a brief crossing (a
    // corner of Switzerland) deserves its country pin. The min-span filter
    // below only removes blink-length display segments.
    final pins = _buildPins(withAnchors);

    final segments = [
      for (final segment in withAnchors)
        if (segment.sEnd - segment.sStart >= minSegmentSpan) segment,
    ];
    return RegionHighlightModel._(segments, pins);
  }

  /// Chips for the outro card: EVERY country the route crosses, in order of
  /// first encounter, deduped by country. This mirrors the map pins exactly
  /// (which are also one-per-country crossed) so the recap can never hide a
  /// country the viewer just watched the plane fly over — the old share-card
  /// ranking dropped brief crossings and confused users. Countries only:
  /// natural regions read as noise on the card.
  static List<RegionChipData> endCardChips(
    List<RouteRegion> regions, {
    String? languageCode,
  }) {
    final lang = languageCode ?? 'en';
    final countryRegions = [
      for (final region in regions)
        if (region.regionType == RouteRegionType.country) region,
    ]..sort(
        (a, b) => a.pathFirstEncounterKm.compareTo(b.pathFirstEncounterKm),
      );

    final seen = <String>{};
    final chips = <RegionChipData>[];
    for (final region in countryRegions) {
      final code = CountryNameUtils.toCode(region.name, languageCode: lang);
      final key = (code ?? region.name).trim().toUpperCase();
      if (key.isEmpty || !seen.add(key)) continue;
      chips.add(
        RegionChipData(
          label: region.name,
          countryCode: code,
          regionType: RouteRegionType.country,
          emoji: flagEmoji(code) ?? emojiForType(RouteRegionType.country),
        ),
      );
    }
    return chips;
  }

  /// Highlights shorter than this fraction of the route are dropped.
  static const double defaultMinSegmentSpan = 0.05;

  /// Fade in/out span at segment edges, in arc-length fraction.
  static const double fadeSpan = 0.02;

  final List<RegionHighlightSegment> segments;

  /// One pin per country crossed. A country's window can be split into
  /// several segments by overlapping regions (e.g. a sea crossing), so pins
  /// dedupe by region: pop at the FIRST entry, anchor at the midpoint of the
  /// LONGEST crossing (the most representative spot).
  final List<RegionPin> pins;

  static List<RegionPin> _buildPins(List<RegionHighlightSegment> segments) {
    final byRegion = <RegionHighlight, List<RegionHighlightSegment>>{};
    for (final segment in segments) {
      if (segment.region.regionType != RouteRegionType.country) continue;
      if (segment.pinAnchor == null) continue;
      byRegion.putIfAbsent(segment.region, () => []).add(segment);
    }
    final pins = <RegionPin>[];
    for (final entry in byRegion.entries) {
      final longest = entry.value.reduce(
        (a, b) => (a.sEnd - a.sStart) >= (b.sEnd - b.sStart) ? a : b,
      );
      final first = entry.value.reduce((a, b) => a.sStart <= b.sStart ? a : b);
      pins.add(
        RegionPin(
          region: entry.key,
          anchor: longest.pinAnchor!,
          sPop: first.sStart,
        ),
      );
    }
    pins.sort((a, b) => a.sPop.compareTo(b.sPop));
    return pins;
  }

  /// The active segment at plane progress [s], or null between highlights.
  RegionHighlightSegment? activeAt(double s) {
    for (final segment in segments) {
      if (segment.sStart <= s && s < segment.sEnd) return segment;
    }
    return null;
  }

  /// Opacity multiplier for the segment active at [s] (edge fades).
  double opacityAt(double s) {
    final segment = activeAt(s);
    if (segment == null) return 0;
    final fadeIn = (s - segment.sStart) / fadeSpan;
    final fadeOut = (segment.sEnd - s) / fadeSpan;
    return min(1.0, min(fadeIn, fadeOut)).clamp(0.0, 1.0);
  }

  /// Chip emoji: country flag when resolvable, otherwise a type glyph.
  static String emojiFor(RouteRegion region, {String? languageCode}) {
    if (region.regionType == RouteRegionType.country) {
      final code = CountryNameUtils.toCode(
        region.name,
        languageCode: languageCode ?? 'en',
      );
      final flag = flagEmoji(code);
      if (flag != null) return flag;
    }
    return emojiForType(region.regionType);
  }

  /// Fallback glyph per region type (when no artwork/flag is available).
  static String emojiForType(RouteRegionType regionType) {
    switch (regionType) {
      case RouteRegionType.sea:
      case RouteRegionType.ocean:
      case RouteRegionType.strait:
      case RouteRegionType.channel:
      case RouteRegionType.gulf:
      case RouteRegionType.bay:
      case RouteRegionType.lake:
      case RouteRegionType.alkalineLake:
      case RouteRegionType.reservoir:
      case RouteRegionType.delta:
        return '🌊';
      case RouteRegionType.mountainRange:
      case RouteRegionType.valley:
      case RouteRegionType.plateau:
        return '⛰️';
      case RouteRegionType.desert:
        return '🏜️';
      case RouteRegionType.island:
      case RouteRegionType.archipelago:
      case RouteRegionType.peninsula:
      case RouteRegionType.coast:
      case RouteRegionType.isthmus:
        return '🏝️';
      case RouteRegionType.plain:
      case RouteRegionType.basin:
      case RouteRegionType.lowland:
      case RouteRegionType.tundra:
      case RouteRegionType.wetlands:
        return '🌿';
      case RouteRegionType.country:
      case RouteRegionType.region:
      case RouteRegionType.state:
      case RouteRegionType.province:
      case RouteRegionType.continent:
      case RouteRegionType.geoarea:
      case RouteRegionType.unknown:
        return '📍';
    }
  }

  /// ISO 3166-1 alpha-2 code -> flag emoji (regional indicator symbols).
  static String? flagEmoji(String? countryCode) {
    final code = countryCode?.trim().toUpperCase();
    if (code == null || code.length != 2) return null;
    final a = code.codeUnitAt(0);
    final b = code.codeUnitAt(1);
    if (a < 0x41 || a > 0x5A || b < 0x41 || b > 0x5A) return null;
    return String.fromCharCodes([0x1F1E6 + a - 0x41, 0x1F1E6 + b - 0x41]);
  }

  static List<RegionRing> _parseRings(Map<String, dynamic> geoJson) {
    final type = geoJson['type'] as String?;
    final coordinates = geoJson['coordinates'];
    if (coordinates is! List) return const [];

    final polygons = <List<dynamic>>[];
    if (type == 'Polygon') {
      polygons.add(coordinates);
    } else if (type == 'MultiPolygon') {
      for (final polygon in coordinates) {
        if (polygon is List) polygons.add(polygon);
      }
    } else {
      return const [];
    }

    final rings = <RegionRing>[];
    for (final polygon in polygons) {
      // Outer ring only: holes are invisible at flight-video zooms.
      if (polygon.isEmpty || polygon.first is! List) continue;
      final rawRing = polygon.first as List;
      final points = <Offset>[];
      var minX = double.infinity, maxX = double.negativeInfinity;
      var minY = double.infinity, maxY = double.negativeInfinity;
      for (final position in rawRing) {
        if (position is! List || position.length < 2) continue;
        final lon = (position[0] as num).toDouble();
        final lat = (position[1] as num).toDouble();
        final x = WorldTransform.mercXNorm(lon);
        final y = WorldTransform.mercYNorm(lat);
        points.add(Offset(x, y));
        minX = min(minX, x);
        maxX = max(maxX, x);
        minY = min(minY, y);
        maxY = max(maxY, y);
      }
      if (points.length < 3) continue;
      rings.add(
        RegionRing(
          points: points,
          bounds: Rect.fromLTRB(minX, minY, maxX, maxY),
        ),
      );
    }
    return rings;
  }
}
