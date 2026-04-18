import 'package:flymap/data/api/flight_info_api.dart';
import 'package:flymap/entity/user_profile.dart';
import 'package:flymap/entity/wiki_article_candidate.dart';
import 'package:latlong2/latlong.dart';

class GetWikiArticlesUseCase {
  GetWikiArticlesUseCase({required FlightInfoApi flightInfoApi})
    : _flightInfoApi = flightInfoApi;

  final FlightInfoApi _flightInfoApi;

  Future<List<WikiArticleCandidate>> call({
    required String airportDeparture,
    required String airportArrival,
    required List<LatLng> waypoints,
    List<UsersInterests>? interests,
  }) async {
    return await _flightInfoApi.getFlightWikiArticles(
      airportDeparture,
      airportArrival,
      waypoints,
      interests: interests,
    );
  }
}
