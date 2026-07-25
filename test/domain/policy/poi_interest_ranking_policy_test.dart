import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/flight_poi_type.dart';
import 'package:flymap/domain/entity/route_poi.dart';
import 'package:flymap/domain/entity/route_poi_summary.dart';
import 'package:flymap/domain/entity/user_profile.dart';
import 'package:flymap/domain/policy/poi_interest_ranking_policy.dart';
import 'package:flymap/domain/policy/poi_limits_policy.dart';
import 'package:latlong2/latlong.dart';

RoutePoiSummary _poi(String name, FlightPoiType type, int sitelinks) {
  return RoutePoiSummary(
    poi: RoutePoi(
      qid: 'Q_$name',
      name: name,
      latLon: const LatLng(0, 0),
      type: type,
      sitelinks: sitelinks,
    ),
  );
}

/// Popularity-ranked list (sitelinks desc), like the backend returns.
List<RoutePoiSummary> _rankedPois(List<(String, FlightPoiType, int)> specs) {
  final pois = [
    for (final (name, type, links) in specs) _poi(name, type, links),
  ];
  pois.sort((a, b) => b.sitelinks.compareTo(a.sitelinks));
  return pois;
}

void main() {
  test('no interests keeps the plain popularity cut', () {
    final pois = _rankedPois([
      for (var i = 0; i < 20; i++) ('city$i', FlightPoiType.city, 100 - i),
    ]);

    final selected = PoiInterestRankingPolicy.selectForTier(
      pois,
      isProUser: false,
    );

    expect(selected, pois.take(PoiLimitsPolicy.freeMaxPois).toList());
  });

  test('short lists are returned unchanged regardless of interests', () {
    final pois = _rankedPois([
      ('Etna', FlightPoiType.volcano, 90),
      ('Alps', FlightPoiType.mountain, 80),
    ]);

    final selected = PoiInterestRankingPolicy.selectForTier(
      pois,
      isProUser: false,
      interests: const [UsersInterests.volcanoes],
    );

    expect(selected, pois);
  });

  test('interest boost pulls matching POIs into the free cut', () {
    const free = PoiLimitsPolicy.freeMaxPois;
    // Enough famous cities to fill the free cut, followed by a volcano that
    // would miss the plain cut.
    final pois = _rankedPois([
      for (var i = 0; i < free; i++) ('city$i', FlightPoiType.city, 200 - i),
      ('Stromboli', FlightPoiType.volcano, 120),
      ('city_tail', FlightPoiType.city, 110),
    ]);

    final plain = PoiInterestRankingPolicy.selectForTier(
      pois,
      isProUser: false,
    );
    expect(plain.map((p) => p.name), isNot(contains('Stromboli')));

    final boosted = PoiInterestRankingPolicy.selectForTier(
      pois,
      isProUser: false,
      interests: const [UsersInterests.volcanoes],
    );
    expect(boosted.map((p) => p.name), contains('Stromboli'));
    expect(boosted.length, PoiLimitsPolicy.freeMaxPois);
  });

  test('boost does not let obscure matches beat world-famous places', () {
    const free = PoiLimitsPolicy.freeMaxPois;
    final pois = _rankedPois([
      ('Grand Canyon', FlightPoiType.park, 300),
      for (var i = 0; i < free; i++) ('peak$i', FlightPoiType.mountain, 50 - i),
      ('pond', FlightPoiType.lake, 2),
    ]);

    final selected = PoiInterestRankingPolicy.selectForTier(
      pois,
      isProUser: false,
      interests: const [UsersInterests.rivers],
    );

    // 2×(2+1) = 6 < 50: the famous non-matching places keep their spots.
    expect(selected.map((p) => p.name), contains('Grand Canyon'));
    expect(selected.map((p) => p.name), isNot(contains('pond')));
  });

  test('selection preserves the backend popularity order', () {
    const overCap = PoiLimitsPolicy.freeMaxPois + 5;
    final pois = _rankedPois([
      for (var i = 0; i < overCap; i++)
        ('city$i', FlightPoiType.city, 200 - i),
      ('Vesuvius', FlightPoiType.volcano, 150),
    ]);

    final selected = PoiInterestRankingPolicy.selectForTier(
      pois,
      isProUser: false,
      interests: const [UsersInterests.volcanoes],
    );

    final sitelinks = selected.map((p) => p.sitelinks).toList();
    final sorted = [...sitelinks]..sort((a, b) => b.compareTo(a));
    expect(sitelinks, sorted);
  });
}
