import 'package:flymap/domain/entity/weather_attribution.dart';
import 'package:latlong2/latlong.dart';

/// Provider-neutral forecast values needed by the flight-weather feature.
///
/// Data sources adapt their own response models to this shape so domain
/// logic never depends on a vendor API or transport format.
class WeatherForecastPoint {
  const WeatherForecastPoint({
    required this.timeUtc,
    this.temperatureC,
    this.windSpeedMs,
    this.cloudCoverPercent,
    this.cloudLowPercent,
    this.cloudMidPercent,
    this.cloudHighPercent,
    this.precipitationMm,
    this.symbolCode,
  });

  final DateTime timeUtc;
  final double? temperatureC;
  final double? windSpeedMs;
  final double? cloudCoverPercent;
  final double? cloudLowPercent;
  final double? cloudMidPercent;
  final double? cloudHighPercent;
  final double? precipitationMm;
  final String? symbolCode;
}

class WeatherForecastRequest {
  const WeatherForecastRequest({
    required this.coordinate,
    required this.targetTimeUtc,
  });

  final LatLng coordinate;
  final DateTime targetTimeUtc;
}

class WeatherForecastBatch {
  const WeatherForecastBatch({
    required this.seriesByRequest,
    required this.retrievedAtUtc,
    required this.attribution,
  });

  /// One entry per request, in exactly the same order. An empty series means
  /// that one location was unavailable while the rest of the batch succeeded.
  final List<List<WeatherForecastPoint>> seriesByRequest;
  final DateTime retrievedAtUtc;
  final WeatherAttribution attribution;
}

/// Forecast source used by the flight-weather domain use case.
abstract interface class WeatherForecastProvider {
  Future<WeatherForecastBatch> forecastBatch({
    required List<WeatherForecastRequest> requests,
    required DateTime windowStartUtc,
    required DateTime windowEndUtc,
  });
}
