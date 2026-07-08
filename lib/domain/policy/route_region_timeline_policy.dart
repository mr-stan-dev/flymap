import 'package:equatable/equatable.dart';
import 'package:flymap/domain/entity/route_region.dart';
import 'package:flymap/domain/entity/route_region_type.dart';
import 'package:flymap/domain/policy/domestic_route_policy.dart';
import 'package:flymap/utils/country_name_utils.dart';

/// One marker on the home-card route timeline: a region the flight crosses,
/// placed by its position along the route.
class RouteRegionMarker extends Equatable {
  const RouteRegionMarker({
    required this.name,
    required this.regionType,
    required this.routeProgress,
  });

  final String name;
  final RouteRegionType regionType;

  /// 0..1 along the route (departure -> arrival).
  final double routeProgress;

  @override
  List<Object?> get props => [name, regionType, routeProgress];
}

/// Picks the regions shown as circles on a saved flight card, "adaptive"
/// style: countries abroad, nature at home.
///
/// - International flights lead with the transit countries overflown (their
///   flags), then fill any remaining slots with the biggest natural features
///   crossed (an ocean, a mountain range). The departure and arrival countries
///   are NOT included here — they are drawn as flags at the strip endpoints.
/// - Domestic flights have no transit countries, so they show natural
///   features only.
///
/// Only ICON-ABLE regions are ever shown — countries (rendered as a flag) or
/// natural features that have artwork. Admin sub-regions (state / province /
/// generic region / geoarea) have no icon and are excluded, which is why
/// domestic routes fall back to nature rather than states.
class RouteRegionTimelinePolicy {
  const RouteRegionTimelinePolicy._();

  static const int maxMarkers = 3;

  static List<RouteRegionMarker> forFlight({
    required List<RouteRegion> regions,
    required String departureCountryCode,
    required String arrivalCountryCode,
    required double totalRouteKm,
    String? languageCode,
  }) {
    if (regions.isEmpty || totalRouteKm <= 0) return const [];
    final lang = languageCode ?? 'en';
    final dep = departureCountryCode.trim().toUpperCase();
    final arr = arrivalCountryCode.trim().toUpperCase();

    bool iconable(RouteRegion r) => r.regionType == RouteRegionType.country
        ? CountryNameUtils.toCode(r.name, languageCode: lang) != null
        : r.regionType.assetImagePath != null;

    final nature = _rankByCoverage(
      _dedupeByKey(
        regions.where(
          (r) => r.regionType != RouteRegionType.country && iconable(r),
        ),
      ),
    );

    final markers = <RouteRegionMarker>[];
    final seen = <String>{};
    double progress(double km) => (km / totalRouteKm).clamp(0.05, 0.95);

    void addFlag(String countryName, double atProgress) {
      if (markers.length >= maxMarkers) return;
      final code = CountryNameUtils.toCode(countryName, languageCode: lang)
          ?.toUpperCase();
      final key = 'c:${code ?? countryName.trim().toLowerCase()}';
      if (key == 'c:' || !seen.add(key)) return;
      markers.add(
        RouteRegionMarker(
          name: countryName,
          regionType: RouteRegionType.country,
          routeProgress: atProgress.clamp(0.05, 0.95),
        ),
      );
    }

    void addNature(RouteRegion r) {
      if (markers.length >= maxMarkers) return;
      final key = 'n:${r.regionType.apiValue}:${r.name.trim().toLowerCase()}';
      if (!seen.add(key)) return;
      markers.add(
        RouteRegionMarker(
          name: r.name,
          regionType: r.regionType,
          routeProgress: progress(r.pathFirstEncounterKm),
        ),
      );
    }

    final isDomestic = DomesticRoutePolicy.isDomestic(
      originCountryCode: dep,
      destinationCountryCode: arr,
    );

    if (isDomestic) {
      // No country flags to show (one country); natural features it is.
      for (final r in nature) {
        addNature(r);
      }
    } else {
      // Flags are strongly preferred: transit countries first, then pad with
      // the departure and arrival country flags, and only fall back to
      // natural features if there still aren't enough flags to fill.
      final excluded = {dep, arr}..removeWhere((c) => c.isEmpty);
      final transit = _rankByCoverage(
        _dedupeByCountryCode(
          regions.where(
            (r) =>
                r.regionType == RouteRegionType.country &&
                iconable(r) &&
                !excluded.contains(
                  (CountryNameUtils.toCode(r.name, languageCode: lang) ?? '')
                      .toUpperCase(),
                ),
          ),
          lang,
        ),
      );
      for (final r in transit) {
        addFlag(r.name, progress(r.pathFirstEncounterKm));
      }
      // The departure and arrival country flags are shown at the strip's
      // endpoints (next to the airport codes), so we deliberately do NOT repeat
      // them here — the middle only carries transit countries, then nature.
      for (final r in nature) {
        addNature(r);
      }
    }

    markers.sort((a, b) => a.routeProgress.compareTo(b.routeProgress));
    return List.unmodifiable(markers);
  }

  /// Highest route coverage first, then earliest crossing.
  static List<RouteRegion> _rankByCoverage(Iterable<RouteRegion> regions) {
    final list = regions.toList()
      ..sort((a, b) {
        final byLength = b.pathLengthInsideKm.compareTo(a.pathLengthInsideKm);
        if (byLength != 0) return byLength;
        return a.pathFirstEncounterKm.compareTo(b.pathFirstEncounterKm);
      });
    return list;
  }

  static List<RouteRegion> _dedupeByKey(Iterable<RouteRegion> regions) {
    final best = <String, RouteRegion>{};
    for (final r in regions) {
      final key = '${r.regionType.apiValue}:${r.name.trim().toLowerCase()}';
      final current = best[key];
      if (current == null ||
          r.pathLengthInsideKm > current.pathLengthInsideKm) {
        best[key] = r;
      }
    }
    return best.values.toList();
  }

  static List<RouteRegion> _dedupeByCountryCode(
    Iterable<RouteRegion> regions,
    String lang,
  ) {
    final best = <String, RouteRegion>{};
    for (final r in regions) {
      final code = CountryNameUtils.toCode(r.name, languageCode: lang)
              ?.toUpperCase() ??
          r.name.trim().toLowerCase();
      final current = best[code];
      if (current == null ||
          r.pathLengthInsideKm > current.pathLengthInsideKm) {
        best[code] = r;
      }
    }
    return best.values.toList();
  }
}
