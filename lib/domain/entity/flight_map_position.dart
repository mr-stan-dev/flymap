import 'package:equatable/equatable.dart';
import 'package:flymap/domain/entity/gps_data.dart';

enum FlightMapPositionSource { liveGps, estimated, lastKnown }

enum FlightMapPositionConfidence { high, low, none }

/// The position rendered on the in-flight map.
///
/// This is intentionally separate from [GpsData]. Estimated coordinates must
/// never be mistaken for live telemetry by the dashboard or geo-awareness
/// features.
class FlightMapPosition extends Equatable {
  const FlightMapPosition({
    required this.data,
    required this.source,
    required this.confidence,
    required this.gpsAge,
    required this.lastGpsFixAt,
  });

  factory FlightMapPosition.live({
    required GpsData data,
    required DateTime fixAt,
  }) {
    return FlightMapPosition(
      data: data,
      source: FlightMapPositionSource.liveGps,
      confidence: FlightMapPositionConfidence.high,
      gpsAge: Duration.zero,
      lastGpsFixAt: fixAt,
    );
  }

  final GpsData data;
  final FlightMapPositionSource source;
  final FlightMapPositionConfidence confidence;
  final Duration gpsAge;
  final DateTime lastGpsFixAt;

  bool get isApproximate => source != FlightMapPositionSource.liveGps;

  @override
  List<Object?> get props => [data, source, confidence, gpsAge, lastGpsFixAt];
}
