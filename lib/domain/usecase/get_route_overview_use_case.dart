import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/route_overview.dart';
import 'package:flymap/repository/route_overview_repository.dart';

class GetRouteOverviewUseCase {
  GetRouteOverviewUseCase({required RouteOverviewRepository repository})
    : _repository = repository;

  // Request a surplus over PoiLimitsPolicy.proMaxPois so the interest-aware
  // tier selection still has candidates to rank.
  static const int placesLimit = 400;
  static const int regionsLimit = 50;

  final RouteOverviewRepository _repository;

  Future<RouteOverview> call({
    required Airport departure,
    required Airport arrival,
  }) async {
    return await _repository.getRouteOverview(
      departure: departure,
      arrival: arrival,
      placesLimit: placesLimit,
      regionsLimit: regionsLimit,
    );
  }

  RouteOverview fromPayload({
    required Map<String, dynamic> payload,
    required Airport departure,
    required Airport arrival,
  }) {
    return _repository.mapRouteOverviewPayload(
      payload,
      departure: departure,
      arrival: arrival,
    );
  }
}
