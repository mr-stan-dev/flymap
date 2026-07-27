import 'package:equatable/equatable.dart';
import 'package:flymap/domain/entity/route_region.dart';

class RouteTimeline extends Equatable {
  const RouteTimeline({
    required this.regions,
    required this.blockMinutes,
    required this.cruiseSpeedKmh,
  });

  final List<RouteRegion> regions;
  final int blockMinutes;
  final int cruiseSpeedKmh;

  const RouteTimeline.empty()
    : regions = const [],
      blockMinutes = 0,
      cruiseSpeedKmh = 850;

  @override
  List<Object?> get props => [regions, blockMinutes, cruiseSpeedKmh];
}
