import 'package:equatable/equatable.dart';
import 'package:flymap/domain/entity/flight_poi_type.dart';

/// A notable named place surfaced as proof on the onboarding payoff step.
class HomeAreaPlace extends Equatable {
  const HomeAreaPlace({
    required this.name,
    required this.type,
    this.qid = '',
    this.description = '',
  });

  final String name;
  final FlightPoiType type;

  /// Wikidata id; may be empty for malformed payload entries.
  final String qid;

  /// Localized description from the places payload, shown in the place
  /// preview sheet. Chips without one are not tappable.
  final String description;

  @override
  List<Object?> get props => [name, type, qid, description];
}

/// Aggregated view of the places we have mapped around the user's home
/// airport, used by the onboarding payoff step.
///
/// Counts come from a capped top-N sample of the area (not the full dataset),
/// so treat [totalPlaces] as a floor, not an exact total.
class HomeAreaSummary extends Equatable {
  const HomeAreaSummary({
    required this.countsByType,
    required this.topPlaces,
    required this.regionNames,
  });

  final Map<FlightPoiType, int> countsByType;

  /// Most notable natural places in the area, best first, preferring
  /// type variety (e.g. a mountain, a lake and an island over three
  /// mountains). Never contains cities, regions or airports.
  final List<HomeAreaPlace> topPlaces;

  /// Region names covering the area (e.g. "Alps"), in API order.
  final List<String> regionNames;

  int get totalPlaces =>
      countsByType.values.fold(0, (sum, count) => sum + count);

  bool get isEmpty => totalPlaces == 0;

  @override
  List<Object?> get props => [countsByType, topPlaces, regionNames];
}
