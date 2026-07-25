import 'package:flymap/domain/entity/flight_poi_type.dart';
import 'package:flymap/domain/entity/route_poi_summary.dart';
import 'package:flymap/domain/entity/user_interests_poi_types.dart';
import 'package:flymap/domain/entity/user_profile.dart';
import 'package:flymap/domain/policy/poi_limits_policy.dart';

/// Decides which POIs make the tier cap, letting the user's interest topics
/// influence the selection instead of pure popularity.
///
/// The incoming list arrives popularity-ranked (sitelinks desc) from the
/// backend. POIs whose type matches a selected interest score
/// `(sitelinks + 1) × boost` vs `(sitelinks + 1)` for the rest, so a
/// moderately notable volcano can beat a slightly more famous ridge for a
/// volcano lover, while world-famous places still win overall. The chosen
/// subset is returned in the backend's original order so downstream display
/// stays consistent with today's behavior.
class PoiInterestRankingPolicy {
  const PoiInterestRankingPolicy._();

  /// Matching POIs count this many times their popularity.
  static const double interestBoost = 2.0;

  static List<RoutePoiSummary> selectForTier(
    List<RoutePoiSummary> pois, {
    required bool isProUser,
    List<UsersInterests> interests = const [],
  }) {
    final limit = PoiLimitsPolicy.maxPoisForTier(isProUser: isProUser);
    if (pois.length <= limit) return List.of(pois);
    if (interests.isEmpty) return pois.take(limit).toList(growable: false);

    final boostedTypes = <FlightPoiType>{
      for (final interest in interests) ...interest.poiTypes,
    };

    double score(RoutePoiSummary poi) {
      final base = (poi.sitelinks < 0 ? 0 : poi.sitelinks) + 1.0;
      return boostedTypes.contains(poi.type) ? base * interestBoost : base;
    }

    final indices = List<int>.generate(pois.length, (index) => index)
      ..sort((a, b) {
        final byScore = score(pois[b]).compareTo(score(pois[a]));
        // Stable: preserve backend rank among equal scores.
        return byScore != 0 ? byScore : a.compareTo(b);
      });
    final selected = indices.take(limit).toList(growable: false)..sort();
    return [for (final index in selected) pois[index]];
  }
}
