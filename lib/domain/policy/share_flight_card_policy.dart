import 'package:equatable/equatable.dart';
import 'package:flymap/domain/entity/route_region.dart';
import 'package:flymap/domain/entity/route_region_type.dart';
import 'package:flymap/domain/policy/domestic_route_policy.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/utils/country_name_utils.dart';

enum ShareFlightCardChipKind { airport, country, region }

class ShareFlightCardChip extends Equatable {
  const ShareFlightCardChip({
    required this.kind,
    required this.label,
    required this.routeOrder,
    this.countryCode,
    this.regionType,
  });

  final ShareFlightCardChipKind kind;
  final String label;
  final double routeOrder;
  final String? countryCode;
  final RouteRegionType? regionType;

  bool get isAirport => kind == ShareFlightCardChipKind.airport;

  @override
  List<Object?> get props => [kind, label, routeOrder, countryCode, regionType];
}

class ShareFlightCardPolicy {
  const ShareFlightCardPolicy._();

  static const int defaultMaxChips = 7;

  /// Route-chip policy for share cards:
  ///
  /// 1) Always pin edge chips:
  ///    - International flight: departure/arrival countries.
  ///    - Domestic flight (same dep/arr country): departure/arrival cities.
  ///    Edge chips are always first/last.
  ///
  /// 2) Build middle chips from route regions only:
  ///    - Exclude country regions that match departure/arrival countries.
  ///    - Fill up to [maxChips] minus edge chips.
  ///
  /// 3) Prioritize oceans in the middle section:
  ///    - Include all deduped `ocean` regions first (until slots run out).
  ///    - Final display order is still timeline-based.
  ///
  /// 4) Fill remaining middle slots with countries, then non-countries:
  ///    - Countries are ranked by path intersection length (desc), then
  ///      by first encounter along route (asc), then stable tie-breakers.
  ///    - Non-country candidates use the same ranking.
  ///    - Plain `region` type is suppressed when more specific non-country
  ///      types exist (fallback only).
  ///
  /// 5) Dedupe by normalized `(regionType + label)` key to keep visual output
  ///    stable and prevent repeated equivalent chips.
  static List<ShareFlightCardChip> routeChips({
    required List<RouteRegion> regions,
    required String departureCountryCode,
    required String arrivalCountryCode,
    required String departureCity,
    required String arrivalCity,
    int maxChips = defaultMaxChips,
  }) {
    if (maxChips <= 0) return const [];
    return _routeChips(
      regions,
      departureCountryCode: departureCountryCode,
      arrivalCountryCode: arrivalCountryCode,
      departureCity: departureCity,
      arrivalCity: arrivalCity,
      maxChips: maxChips,
    );
  }

  static List<ShareFlightCardChip> _routeChips(
    List<RouteRegion> regions, {
    required String departureCountryCode,
    required String arrivalCountryCode,
    required String departureCity,
    required String arrivalCity,
    required int maxChips,
  }) {
    if (maxChips <= 0) return const [];

    final normalizedDepartureCountry = _normalizeCountryCode(
      departureCountryCode,
    );
    final normalizedArrivalCountry = _normalizeCountryCode(arrivalCountryCode);
    final isDomesticFlight = DomesticRoutePolicy.isDomestic(
      originCountryCode: normalizedDepartureCountry,
      destinationCountryCode: normalizedArrivalCountry,
    );

    final departureChip = isDomesticFlight
        ? _airportCityChip(
            city: departureCity,
            countryCode: normalizedDepartureCountry,
            isStart: true,
          )
        : _countryChipFromCode(departureCountryCode, isStart: true);
    final arrivalChip = isDomesticFlight
        ? _airportCityChip(
            city: arrivalCity,
            countryCode: normalizedArrivalCountry,
            isStart: false,
          )
        : _countryChipFromCode(arrivalCountryCode, isStart: false);

    final edgeChips = <ShareFlightCardChip>[
      if (departureChip != null) departureChip,
      if (arrivalChip != null) arrivalChip,
    ];
    final middleLimit = maxChips - edgeChips.length;
    if (middleLimit <= 0) {
      return edgeChips.take(maxChips).toList(growable: false);
    }

    final excludedCountryCodes = <String>{
      normalizedDepartureCountry,
      normalizedArrivalCountry,
    }..removeWhere((code) => code.isEmpty);

    final filteredRegions = regions
        .where((region) {
          if (region.regionType != RouteRegionType.country) return true;
          final regionCountryCode = CountryNameUtils.toCode(
            region.name,
            languageCode: LocaleSettings.currentLocale.languageCode,
          );
          if (regionCountryCode == null) return true;
          return !excludedCountryCodes.contains(
            regionCountryCode.toUpperCase(),
          );
        })
        .toList(growable: false);

    final middleChips = _middleChips(filteredRegions, maxChips: middleLimit);
    return [
      if (departureChip != null) departureChip,
      ...middleChips,
      if (arrivalChip != null) arrivalChip,
    ];
  }

  static List<ShareFlightCardChip> _middleChips(
    List<RouteRegion> regions, {
    required int maxChips,
  }) {
    if (regions.isEmpty || maxChips <= 0) return const [];

    final selected = <RouteRegion>[];
    final selectedKeys = <String>{};

    final oceans = _allOceans(regions);
    for (final ocean in oceans) {
      if (selected.length >= maxChips) break;
      selected.add(ocean);
      selectedKeys.add(_regionKey(ocean));
    }

    final dedupedCountries = _dedupeBestByLabel(
      regions.where(
        (region) =>
            region.regionType == RouteRegionType.country &&
            !selectedKeys.contains(_regionKey(region)),
      ),
    );
    final remainingAfterOceans = maxChips - selected.length;
    if (remainingAfterOceans > 0) {
      final countries = _topByIntersection(
        dedupedCountries,
        remainingAfterOceans,
      );
      selected.addAll(countries);
      selectedKeys.addAll(countries.map(_regionKey));
    }
    final remainingSlots = maxChips - selected.length;

    if (remainingSlots > 0) {
      final dedupedNonCountries = _dedupeBestByLabel(
        regions.where(
          (region) =>
              region.regionType != RouteRegionType.country &&
              !selectedKeys.contains(_regionKey(region)),
        ),
      );
      final prioritizedNonCountries = _prioritizeNonCountryCandidates(
        dedupedNonCountries,
      );
      selected.addAll(
        _topByIntersection(prioritizedNonCountries, remainingSlots),
      );
    }

    // Always return middle chips in real route timeline order.
    selected.sort(_compareByRouteOrder);
    return selected
        .map((region) {
          final isCountry = region.regionType == RouteRegionType.country;
          return ShareFlightCardChip(
            kind: isCountry
                ? ShareFlightCardChipKind.country
                : ShareFlightCardChipKind.region,
            label: region.name,
            regionType: region.regionType,
            routeOrder: region.pathFirstEncounterKm,
            countryCode: isCountry
                ? CountryNameUtils.toCode(
                    region.name,
                    languageCode: LocaleSettings.currentLocale.languageCode,
                  )
                : null,
          );
        })
        .toList(growable: false);
  }

  static List<RouteRegion> _allOceans(List<RouteRegion> regions) {
    final deduped = _dedupeBestByLabel(
      regions.where((region) => region.regionType == RouteRegionType.ocean),
    );
    final ordered = List<RouteRegion>.of(deduped)..sort(_compareByRouteOrder);
    return ordered;
  }

  static ShareFlightCardChip? _countryChipFromCode(
    String countryCode, {
    required bool isStart,
  }) {
    final normalized = _normalizeCountryCode(countryCode);
    if (normalized.isEmpty) return null;
    return ShareFlightCardChip(
      kind: ShareFlightCardChipKind.country,
      label: CountryNameUtils.fromCode(
        normalized,
        languageCode: LocaleSettings.currentLocale.languageCode,
      ),
      routeOrder: isStart ? -1 : double.maxFinite,
      countryCode: normalized,
      regionType: RouteRegionType.country,
    );
  }

  static ShareFlightCardChip? _airportCityChip({
    required String city,
    required String countryCode,
    required bool isStart,
  }) {
    final label = city.trim();
    if (label.isEmpty) return null;
    return ShareFlightCardChip(
      kind: ShareFlightCardChipKind.airport,
      label: label,
      routeOrder: isStart ? -1 : double.maxFinite,
      countryCode: _normalizeCountryCode(countryCode),
      regionType: null,
    );
  }

  static List<RouteRegion> _prioritizeNonCountryCandidates(
    List<RouteRegion> candidates,
  ) {
    // Suppress plain "region" when more specific non-country types exist.
    final specific = candidates
        .where((region) => region.regionType != RouteRegionType.region)
        .toList(growable: false);
    return specific.isNotEmpty ? specific : candidates;
  }

  static List<RouteRegion> _dedupeBestByLabel(Iterable<RouteRegion> regions) {
    final bestByLabel = <String, RouteRegion>{};
    for (final region in regions) {
      final key = _regionKey(region);
      final current = bestByLabel[key];
      if (current == null || _compareByIntersection(region, current) < 0) {
        bestByLabel[key] = region;
      }
    }
    return bestByLabel.values.toList(growable: false);
  }

  static List<RouteRegion> _topByIntersection(
    List<RouteRegion> regions,
    int count,
  ) {
    final ranked = List<RouteRegion>.of(regions)..sort(_compareByIntersection);
    return ranked.take(count).toList(growable: false);
  }

  static int _compareByIntersection(RouteRegion a, RouteRegion b) {
    final byLength = b.pathLengthInsideKm.compareTo(a.pathLengthInsideKm);
    if (byLength != 0) return byLength;

    final byPath = a.pathFirstEncounterKm.compareTo(b.pathFirstEncounterKm);
    if (byPath != 0) return byPath;

    final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    if (byName != 0) return byName;
    return a.qid.compareTo(b.qid);
  }

  static int _compareByRouteOrder(RouteRegion a, RouteRegion b) {
    final byPath = a.pathFirstEncounterKm.compareTo(b.pathFirstEncounterKm);
    if (byPath != 0) return byPath;
    return _compareByIntersection(a, b);
  }

  static String _regionKey(RouteRegion region) {
    final nameKey = region.name.trim().toLowerCase();
    if (nameKey.isNotEmpty) {
      return '${region.regionType.apiValue}:$nameKey';
    }
    final qid = region.qid.trim();
    if (qid.isNotEmpty) return qid.toLowerCase();
    return region.regionType.apiValue;
  }

  static String _normalizeCountryCode(String value) =>
      value.trim().toUpperCase();
}
