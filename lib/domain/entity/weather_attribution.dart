import 'package:equatable/equatable.dart';

/// Provider metadata carried with weather data so attribution can change on
/// the backend without requiring a mobile release.
class WeatherAttribution extends Equatable {
  const WeatherAttribution({
    required this.providerName,
    required this.providerUrl,
    required this.licenseName,
    required this.licenseUrl,
  });

  static const metNorway = WeatherAttribution(
    providerName: 'MET Norway',
    providerUrl: 'https://www.met.no/en',
    licenseName: 'CC BY 4.0',
    licenseUrl: 'https://creativecommons.org/licenses/by/4.0/',
  );

  final String providerName;
  final String providerUrl;
  final String licenseName;
  final String licenseUrl;

  @override
  List<Object?> get props => [
    providerName,
    providerUrl,
    licenseName,
    licenseUrl,
  ];
}
