import 'package:flymap/ui/screens/flight/widgets/tabs/map/day_night/solar_position_calculator.dart';
import 'package:latlong2/latlong.dart';

/// A provider-independent visual condition used by both the in-app weather
/// cards and the rasterized image/video share renderer.
enum WeatherSymbolKind {
  isolatedThunderDay,
  isolatedThunderNight,
  scatteredThunderDay,
  scatteredThunderNight,
  severeThunder,
  lightSnowDay,
  lightSnowNight,
  snowDay,
  snowNight,
  heavySnowDay,
  heavySnowNight,
  sleet,
  lightRainDay,
  lightRainNight,
  rainDay,
  rainNight,
  heavyRainDay,
  heavyRainNight,
  fogDay,
  fogNight,
  clearDay,
  clearNight,
  fairDay,
  fairNight,
  partlyCloudyDay,
  partlyCloudyNight,
  mostlyCloudyDay,
  mostlyCloudyNight,
  cloudy,
}

enum _WeatherIntensity { light, moderate, heavy }

final _solarPositionCalculator = SolarPositionCalculator();

/// Resolves day/night from the forecast instant and airport coordinates.
///
/// Solar elevation handles seasonal and polar daylight correctly. The local
/// wall-clock fallback is only used by demo/legacy content without an airport
/// coordinate.
bool weatherIsDaytime({
  required DateTime timeUtc,
  required int utcOffsetMinutes,
  LatLng? coordinate,
}) {
  if (coordinate != null) {
    final elevation = _solarPositionCalculator.solarElevationDegrees(
      dateTimeUtc: timeUtc,
      latitude: coordinate.latitude,
      longitude: coordinate.longitude,
    );
    return elevation >= SolarPositionCalculator.sunriseSunsetThresholdDegrees;
  }
  final localTime = timeUtc.add(Duration(minutes: utcOffsetMinutes));
  return localTime.hour >= 6 && localTime.hour < 20;
}

/// Maps Flymap's stable condition vocabulary to the richest honest icon.
///
/// Provider adapters normalize vendor symbols into families such as
/// `rain_showers_light`, `snow_heavy`, or `thunder`. Declared intensity wins;
/// precipitation rate supplies a provider-independent fallback for generic
/// rain/snow codes. Day/night is deliberately supplied separately so visual
/// correctness never depends on a provider's naming convention.
WeatherSymbolKind weatherSymbolKind(
  String? symbolCode,
  double? cloudCover, {
  required bool isDaytime,
  double? precipitationMm,
}) {
  final code = (symbolCode ?? '').toLowerCase();
  final compactCode = code.replaceAll(RegExp('[^a-z]'), '');
  final intensity = _weatherIntensity(code, precipitationMm);

  if (compactCode.contains('thunder')) {
    return switch (intensity) {
      _WeatherIntensity.light =>
        isDaytime
            ? WeatherSymbolKind.isolatedThunderDay
            : WeatherSymbolKind.isolatedThunderNight,
      _WeatherIntensity.moderate =>
        isDaytime
            ? WeatherSymbolKind.scatteredThunderDay
            : WeatherSymbolKind.scatteredThunderNight,
      _WeatherIntensity.heavy => WeatherSymbolKind.severeThunder,
    };
  }
  if (compactCode.contains('snow')) {
    return switch (intensity) {
      _WeatherIntensity.light =>
        isDaytime
            ? WeatherSymbolKind.lightSnowDay
            : WeatherSymbolKind.lightSnowNight,
      _WeatherIntensity.moderate =>
        isDaytime ? WeatherSymbolKind.snowDay : WeatherSymbolKind.snowNight,
      _WeatherIntensity.heavy =>
        isDaytime
            ? WeatherSymbolKind.heavySnowDay
            : WeatherSymbolKind.heavySnowNight,
    };
  }
  if (compactCode.contains('sleet')) return WeatherSymbolKind.sleet;
  if (compactCode.contains('rain')) {
    return switch (intensity) {
      _WeatherIntensity.light =>
        isDaytime
            ? WeatherSymbolKind.lightRainDay
            : WeatherSymbolKind.lightRainNight,
      _WeatherIntensity.moderate =>
        isDaytime ? WeatherSymbolKind.rainDay : WeatherSymbolKind.rainNight,
      _WeatherIntensity.heavy =>
        isDaytime
            ? WeatherSymbolKind.heavyRainDay
            : WeatherSymbolKind.heavyRainNight,
    };
  }
  if (compactCode.contains('fog')) {
    return isDaytime ? WeatherSymbolKind.fogDay : WeatherSymbolKind.fogNight;
  }
  if (compactCode.contains('clearsky') || compactCode == 'clear') {
    return isDaytime
        ? WeatherSymbolKind.clearDay
        : WeatherSymbolKind.clearNight;
  }
  if (compactCode.contains('fair') || compactCode.contains('mostlyclear')) {
    return isDaytime ? WeatherSymbolKind.fairDay : WeatherSymbolKind.fairNight;
  }
  if (compactCode.contains('partlycloudy')) {
    if ((cloudCover ?? 0) >= 70) {
      return isDaytime
          ? WeatherSymbolKind.mostlyCloudyDay
          : WeatherSymbolKind.mostlyCloudyNight;
    }
    return isDaytime
        ? WeatherSymbolKind.partlyCloudyDay
        : WeatherSymbolKind.partlyCloudyNight;
  }
  if (compactCode.contains('mostlycloudy')) {
    return isDaytime
        ? WeatherSymbolKind.mostlyCloudyDay
        : WeatherSymbolKind.mostlyCloudyNight;
  }
  if (compactCode.contains('cloudy') || compactCode.contains('overcast')) {
    return WeatherSymbolKind.cloudy;
  }
  return _cloudCoverKind(cloudCover ?? 50, isDaytime: isDaytime);
}

_WeatherIntensity _weatherIntensity(String code, double? precipitationMm) {
  if (code.contains('heavy')) return _WeatherIntensity.heavy;
  if (code.contains('light')) return _WeatherIntensity.light;
  if (precipitationMm == null) return _WeatherIntensity.moderate;
  if (precipitationMm < 2.5) return _WeatherIntensity.light;
  if (precipitationMm < 7.5) return _WeatherIntensity.moderate;
  return _WeatherIntensity.heavy;
}

WeatherSymbolKind _cloudCoverKind(
  double cloudCover, {
  required bool isDaytime,
}) {
  if (cloudCover < 12.5) {
    return isDaytime
        ? WeatherSymbolKind.clearDay
        : WeatherSymbolKind.clearNight;
  }
  if (cloudCover < 37.5) {
    return isDaytime ? WeatherSymbolKind.fairDay : WeatherSymbolKind.fairNight;
  }
  if (cloudCover < 70) {
    return isDaytime
        ? WeatherSymbolKind.partlyCloudyDay
        : WeatherSymbolKind.partlyCloudyNight;
  }
  if (cloudCover < 90) {
    return isDaytime
        ? WeatherSymbolKind.mostlyCloudyDay
        : WeatherSymbolKind.mostlyCloudyNight;
  }
  return WeatherSymbolKind.cloudy;
}

extension WeatherSymbolKindPresentation on WeatherSymbolKind {
  static const _assetRoot = 'assets/images/weather';

  String get assetPath => switch (this) {
    WeatherSymbolKind.isolatedThunderDay =>
      '$_assetRoot/isolated-thunderstorms-day.svg',
    WeatherSymbolKind.isolatedThunderNight =>
      '$_assetRoot/isolated-thunderstorms-night.svg',
    WeatherSymbolKind.scatteredThunderDay =>
      '$_assetRoot/scattered-thunderstorms-day.svg',
    WeatherSymbolKind.scatteredThunderNight =>
      '$_assetRoot/scattered-thunderstorms-night.svg',
    WeatherSymbolKind.severeThunder => '$_assetRoot/severe-thunderstorm.svg',
    WeatherSymbolKind.lightSnowDay => '$_assetRoot/snowy-1-day.svg',
    WeatherSymbolKind.lightSnowNight => '$_assetRoot/snowy-1-night.svg',
    WeatherSymbolKind.snowDay => '$_assetRoot/snowy-2-day.svg',
    WeatherSymbolKind.snowNight => '$_assetRoot/snowy-2-night.svg',
    WeatherSymbolKind.heavySnowDay => '$_assetRoot/snowy-3-day.svg',
    WeatherSymbolKind.heavySnowNight => '$_assetRoot/snowy-3-night.svg',
    WeatherSymbolKind.sleet => '$_assetRoot/rain-and-sleet-mix.svg',
    WeatherSymbolKind.lightRainDay => '$_assetRoot/rainy-1-day.svg',
    WeatherSymbolKind.lightRainNight => '$_assetRoot/rainy-1-night.svg',
    WeatherSymbolKind.rainDay => '$_assetRoot/rainy-2-day.svg',
    WeatherSymbolKind.rainNight => '$_assetRoot/rainy-2-night.svg',
    WeatherSymbolKind.heavyRainDay => '$_assetRoot/rainy-3-day.svg',
    WeatherSymbolKind.heavyRainNight => '$_assetRoot/rainy-3-night.svg',
    WeatherSymbolKind.fogDay => '$_assetRoot/fog-day.svg',
    WeatherSymbolKind.fogNight => '$_assetRoot/fog-night.svg',
    WeatherSymbolKind.clearDay => '$_assetRoot/clear-day.svg',
    WeatherSymbolKind.clearNight => '$_assetRoot/clear-night.svg',
    WeatherSymbolKind.fairDay => '$_assetRoot/cloudy-1-day.svg',
    WeatherSymbolKind.fairNight => '$_assetRoot/cloudy-1-night.svg',
    WeatherSymbolKind.partlyCloudyDay => '$_assetRoot/cloudy-2-day.svg',
    WeatherSymbolKind.partlyCloudyNight => '$_assetRoot/cloudy-2-night.svg',
    WeatherSymbolKind.mostlyCloudyDay => '$_assetRoot/cloudy-3-day.svg',
    WeatherSymbolKind.mostlyCloudyNight => '$_assetRoot/cloudy-3-night.svg',
    WeatherSymbolKind.cloudy => '$_assetRoot/cloudy.svg',
  };

  String get emoji => switch (this) {
    WeatherSymbolKind.isolatedThunderDay => '⛈️',
    WeatherSymbolKind.isolatedThunderNight => '⛈️',
    WeatherSymbolKind.scatteredThunderDay => '⛈️',
    WeatherSymbolKind.scatteredThunderNight => '⛈️',
    WeatherSymbolKind.severeThunder => '⛈️',
    WeatherSymbolKind.lightSnowDay => '🌨️',
    WeatherSymbolKind.lightSnowNight => '🌨️',
    WeatherSymbolKind.snowDay => '🌨️',
    WeatherSymbolKind.snowNight => '🌨️',
    WeatherSymbolKind.heavySnowDay => '🌨️',
    WeatherSymbolKind.heavySnowNight => '🌨️',
    WeatherSymbolKind.sleet => '🌨️',
    WeatherSymbolKind.lightRainDay => '🌦️',
    WeatherSymbolKind.lightRainNight => '🌧️',
    WeatherSymbolKind.rainDay => '🌧️',
    WeatherSymbolKind.rainNight => '🌧️',
    WeatherSymbolKind.heavyRainDay => '🌧️',
    WeatherSymbolKind.heavyRainNight => '🌧️',
    WeatherSymbolKind.fogDay => '🌫️',
    WeatherSymbolKind.fogNight => '🌫️',
    WeatherSymbolKind.clearDay => '☀️',
    WeatherSymbolKind.clearNight => '🌙',
    WeatherSymbolKind.fairDay => '🌤️',
    WeatherSymbolKind.fairNight => '🌙',
    WeatherSymbolKind.partlyCloudyDay => '⛅',
    WeatherSymbolKind.partlyCloudyNight => '☁️',
    WeatherSymbolKind.mostlyCloudyDay => '☁️',
    WeatherSymbolKind.mostlyCloudyNight => '☁️',
    WeatherSymbolKind.cloudy => '☁️',
  };
}

/// Emoji fallback for exports when an SVG asset cannot be loaded.
String weatherSymbolEmoji(
  String? symbolCode,
  double? cloudCover, {
  required bool isDaytime,
  double? precipitationMm,
}) {
  return weatherSymbolKind(
    symbolCode,
    cloudCover,
    isDaytime: isDaytime,
    precipitationMm: precipitationMm,
  ).emoji;
}
