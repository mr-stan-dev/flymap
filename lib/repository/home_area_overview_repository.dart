import 'package:flymap/data/api/route_overview_api.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_poi_type.dart';
import 'package:flymap/domain/entity/home_area_summary.dart';
import 'package:latlong2/latlong.dart';

abstract interface class HomeAreaOverviewRepository {
  Future<HomeAreaSummary> getHomeAreaSummary({required Airport airport});
}

/// Fetches a places summary for the region around an airport by reusing the
/// route-overview callable: a short synthetic north-south "route" centered on
/// the airport makes the backend build its standard ~160 km wide corridor
/// capsule around it, which doubles as the airport's surrounding area.
///
/// The capsule is longer along the route than across it, so results are
/// additionally filtered to [_maxPlaceDistanceKm] from the airport — the
/// payoff screen promises places users can genuinely spot during climb-out
/// and approach, and a smaller accurate set beats a bigger padded one.
class ApiHomeAreaOverviewRepository implements HomeAreaOverviewRepository {
  ApiHomeAreaOverviewRepository({
    required RouteOverviewApi api,
    Duration timeout = const Duration(seconds: 12),
  }) : _api = api,
       _timeout = timeout;

  /// ~50 km of latitude on each side of the airport. With the backend's
  /// 80 km corridor half-width and rounded end caps this yields a compact
  /// near-circular area, trimmed further by [_maxPlaceDistanceKm].
  static const double _latOffsetDegrees = 0.45;
  static const double _maxPlaceDistanceKm = 100;
  static const int _placesLimit = 250;
  static const int _regionsLimit = 10;
  static const int _topPlacesLimit = 5;
  static const Distance _distanceCalculator = Distance();

  /// Types excluded from [HomeAreaSummary.topPlaces]: the payoff pitch
  /// leads with natural wonders, not settlements or infrastructure.
  static const Set<FlightPoiType> _mundaneTypes = {
    FlightPoiType.city,
    FlightPoiType.region,
    FlightPoiType.airport,
    FlightPoiType.unknown,
  };

  final RouteOverviewApi _api;
  final Duration _timeout;

  @override
  Future<HomeAreaSummary> getHomeAreaSummary({required Airport airport}) async {
    final payload = await _api
        .getRouteOverview(
          departure: _shiftedByLatitude(airport, -_latOffsetDegrees),
          arrival: _shiftedByLatitude(airport, _latOffsetDegrees),
          placesLimit: _placesLimit,
          regionsLimit: _regionsLimit,
        )
        .timeout(_timeout);
    return _toSummary(payload, airport.latLon);
  }

  Airport _shiftedByLatitude(Airport airport, double deltaDegrees) {
    final centerLat = airport.latLon.latitude.clamp(
      -90 + _latOffsetDegrees,
      90 - _latOffsetDegrees,
    );
    return Airport(
      name: airport.name,
      city: airport.city,
      countryCode: airport.countryCode,
      latLon: LatLng(centerLat + deltaDegrees, airport.latLon.longitude),
      iataCode: airport.iataCode,
      icaoCode: airport.icaoCode,
      wikipediaUrl: airport.wikipediaUrl,
      type: airport.type,
    );
  }

  HomeAreaSummary _toSummary(Map<String, dynamic> payload, LatLng airport) {
    final counts = <FlightPoiType, int>{};
    final ranked = <({HomeAreaPlace place, int sitelinks})>[];

    final places = payload['places'];
    final features = places is Map ? places['features'] : null;
    if (features is List) {
      for (final featureRaw in features) {
        if (featureRaw is! Map) continue;
        final propsRaw = featureRaw['properties'];
        if (propsRaw is! Map) continue;
        final props = propsRaw.cast<String, dynamic>();
        final name = (props['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        final location = _featureLatLng(featureRaw);
        if (location == null) continue;
        final distanceKm = _distanceCalculator.as(
          LengthUnit.Kilometer,
          airport,
          location,
        );
        if (distanceKm > _maxPlaceDistanceKm) continue;
        final type = FlightPoiType.fromRaw(
          (props['placeType'] ?? '').toString(),
        );
        counts[type] = (counts[type] ?? 0) + 1;
        if (_mundaneTypes.contains(type)) continue;
        final sitelinks = props['sitelinks'];
        ranked.add((
          place: HomeAreaPlace(
            name: name,
            type: type,
            qid: (props['qid'] ?? '').toString().trim(),
            description: (props['description'] ?? '').toString().trim(),
          ),
          sitelinks: sitelinks is num ? sitelinks.toInt() : 0,
        ));
      }
    }

    ranked.sort((a, b) => b.sitelinks.compareTo(a.sitelinks));

    final regionNames = <String>[];
    final regions = payload['regions'];
    if (regions is List) {
      for (final regionRaw in regions) {
        if (regionRaw is! Map) continue;
        final propsRaw = regionRaw['properties'];
        if (propsRaw is! Map) continue;
        final name = (propsRaw['name'] ?? '').toString().trim();
        if (name.isNotEmpty) regionNames.add(name);
      }
    }

    return HomeAreaSummary(
      countsByType: counts,
      topPlaces: _pickTopPlaces(ranked),
      regionNames: regionNames,
    );
  }

  /// GeoJSON point coordinates ([lon, lat]) of a place feature, or null when
  /// absent/malformed — such places are skipped because their distance to
  /// the airport cannot be verified.
  LatLng? _featureLatLng(Map<dynamic, dynamic> feature) {
    final geometry = feature['geometry'];
    if (geometry is! Map) return null;
    final coordinates = geometry['coordinates'];
    if (coordinates is! List || coordinates.length < 2) return null;
    final lon = coordinates[0];
    final lat = coordinates[1];
    if (lon is! num || lat is! num) return null;
    final lonValue = lon.toDouble();
    final latValue = lat.toDouble();
    if (!lonValue.isFinite || !latValue.isFinite) return null;
    return LatLng(latValue, lonValue);
  }

  /// Picks the headline proof places from the rank-sorted candidates,
  /// preferring type variety (one mountain, one lake, one island beats three
  /// mountains); backfills by pure rank if variety runs out.
  List<HomeAreaPlace> _pickTopPlaces(
    List<({HomeAreaPlace place, int sitelinks})> ranked,
  ) {
    final picked = <HomeAreaPlace>[];
    final usedTypes = <FlightPoiType>{};
    for (final entry in ranked) {
      if (picked.length >= _topPlacesLimit) break;
      if (usedTypes.add(entry.place.type)) picked.add(entry.place);
    }
    for (final entry in ranked) {
      if (picked.length >= _topPlacesLimit) break;
      if (!picked.contains(entry.place)) picked.add(entry.place);
    }
    return picked;
  }
}
