import 'package:flymap/domain/entity/flight_weather.dart';
import 'package:flymap/domain/entity/weather_attribution.dart';
import 'package:latlong2/latlong.dart';

/// JSON persistence for a fetched forecast — the full picture including
/// the per-sample timelines, so the offline map card can animate exactly
/// what was last downloaded.
class FlightWeatherDbMapper {
  const FlightWeatherDbMapper();

  Map<String, dynamic> toDb(FlightWeather weather) {
    return {
      'departure': _airportToDb(weather.departure),
      'arrival': _airportToDb(weather.arrival),
      'samples': [for (final s in weather.samples) _sampleToDb(s)],
      'areaSamples': [for (final s in weather.areaSamples) _sampleToDb(s)],
      'fetchedAt': weather.fetchedAt.toIso8601String(),
      'isTimeEstimated': weather.isTimeEstimated,
      'attribution': {
        'providerName': weather.attribution.providerName,
        'providerUrl': weather.attribution.providerUrl,
        'licenseName': weather.attribution.licenseName,
        'licenseUrl': weather.attribution.licenseUrl,
      },
    };
  }

  FlightWeather fromDb(Map<String, dynamic> map) {
    return FlightWeather(
      departure: _airportFromDb(_asMap(map['departure'])),
      arrival: _airportFromDb(_asMap(map['arrival'])),
      samples: [
        for (final raw in (map['samples'] as List? ?? const []))
          _sampleFromDb(_asMap(raw)),
      ],
      areaSamples: [
        for (final raw in (map['areaSamples'] as List? ?? const []))
          _sampleFromDb(_asMap(raw)),
      ],
      fetchedAt: DateTime.parse(map['fetchedAt'] as String),
      isTimeEstimated: map['isTimeEstimated'] == true,
      attribution: _attributionFromDb(map['attribution']),
    );
  }

  WeatherAttribution _attributionFromDb(Object? raw) {
    if (raw is! Map) return WeatherAttribution.metNorway;
    final map = Map<String, dynamic>.from(raw);
    return WeatherAttribution(
      providerName:
          map['providerName'] as String? ??
          WeatherAttribution.metNorway.providerName,
      providerUrl:
          map['providerUrl'] as String? ??
          WeatherAttribution.metNorway.providerUrl,
      licenseName:
          map['licenseName'] as String? ??
          WeatherAttribution.metNorway.licenseName,
      licenseUrl:
          map['licenseUrl'] as String? ??
          WeatherAttribution.metNorway.licenseUrl,
    );
  }

  Map<String, dynamic> _airportToDb(AirportWeather airport) {
    return {
      'timeUtc': airport.timeUtc.toIso8601String(),
      'utcOffsetMinutes': airport.utcOffsetMinutes,
      if (airport.temperatureC != null) 'temperatureC': airport.temperatureC,
      if (airport.windSpeedMs != null) 'windSpeedMs': airport.windSpeedMs,
      if (airport.precipitationMm != null)
        'precipitationMm': airport.precipitationMm,
      if (airport.cloudCoverPercent != null)
        'cloudCoverPercent': airport.cloudCoverPercent,
      if (airport.symbolCode != null) 'symbolCode': airport.symbolCode,
    };
  }

  AirportWeather _airportFromDb(Map<String, dynamic> map) {
    return AirportWeather(
      timeUtc: DateTime.parse(map['timeUtc'] as String),
      utcOffsetMinutes: (map['utcOffsetMinutes'] as num?)?.toInt() ?? 0,
      temperatureC: (map['temperatureC'] as num?)?.toDouble(),
      windSpeedMs: (map['windSpeedMs'] as num?)?.toDouble(),
      precipitationMm: (map['precipitationMm'] as num?)?.toDouble(),
      cloudCoverPercent: (map['cloudCoverPercent'] as num?)?.toDouble(),
      symbolCode: map['symbolCode'] as String?,
    );
  }

  Map<String, dynamic> _sampleToDb(RouteCloudSample sample) {
    return {
      'routeProgress': sample.routeProgress,
      'lat': sample.latLon.latitude,
      'lon': sample.latLon.longitude,
      'timeUtc': sample.timeUtc.toIso8601String(),
      'cloudLowPercent': sample.cloudLowPercent,
      'cloudMidPercent': sample.cloudMidPercent,
      'cloudHighPercent': sample.cloudHighPercent,
      if (sample.precipitationMm != null)
        'precipitationMm': sample.precipitationMm,
      'timeline': [
        for (final slice in sample.timeline)
          {
            'timeUtc': slice.timeUtc.toIso8601String(),
            'low': slice.cloudLowPercent,
            'mid': slice.cloudMidPercent,
            'high': slice.cloudHighPercent,
            'rain': slice.precipitationMm,
          },
      ],
    };
  }

  RouteCloudSample _sampleFromDb(Map<String, dynamic> map) {
    return RouteCloudSample(
      routeProgress: (map['routeProgress'] as num).toDouble(),
      latLon: LatLng(
        (map['lat'] as num).toDouble(),
        (map['lon'] as num).toDouble(),
      ),
      timeUtc: DateTime.parse(map['timeUtc'] as String),
      cloudLowPercent: (map['cloudLowPercent'] as num).toDouble(),
      cloudMidPercent: (map['cloudMidPercent'] as num).toDouble(),
      cloudHighPercent: (map['cloudHighPercent'] as num).toDouble(),
      precipitationMm: (map['precipitationMm'] as num?)?.toDouble(),
      timeline: [
        for (final raw in (map['timeline'] as List? ?? const []))
          CloudTimeSlice(
            timeUtc: DateTime.parse(_asMap(raw)['timeUtc'] as String),
            cloudLowPercent: (_asMap(raw)['low'] as num).toDouble(),
            cloudMidPercent: (_asMap(raw)['mid'] as num).toDouble(),
            cloudHighPercent: (_asMap(raw)['high'] as num).toDouble(),
            precipitationMm: (_asMap(raw)['rain'] as num?)?.toDouble() ?? 0,
          ),
      ],
    );
  }

  Map<String, dynamic> _asMap(Object? value) =>
      Map<String, dynamic>.from(value as Map);
}
