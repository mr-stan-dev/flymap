class SkyCameraOverlaySnapshot {
  const SkyCameraOverlaySnapshot({
    required this.timestamp,
    required this.routeLabel,
    required this.originCode,
    required this.destinationCode,
    required this.originCountryCode,
    required this.destinationCountryCode,
    required this.contextLabel,
    required this.mapStatePlaceholder,
    required this.hasLiveLocation,
    required this.latitude,
    required this.longitude,
    required this.headingDegrees,
    required this.altitudeMeters,
    required this.speedMetersPerSecond,
    this.horizontalAccuracyMeters,
    this.outsideTemperatureCelsius,
  });

  final DateTime timestamp;
  final String routeLabel;
  final String originCode;
  final String destinationCode;
  final String originCountryCode;
  final String destinationCountryCode;
  final String contextLabel;
  final String mapStatePlaceholder;
  final bool hasLiveLocation;
  final double? latitude;
  final double? longitude;
  final double? headingDegrees;
  final double? altitudeMeters;
  final double? speedMetersPerSecond;
  final double? horizontalAccuracyMeters;
  final double? outsideTemperatureCelsius;

  bool get isDomestic {
    final origin = originCountryCode.trim().toUpperCase();
    final destination = destinationCountryCode.trim().toUpperCase();
    return origin.isNotEmpty && origin == destination;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'timestamp': timestamp.toIso8601String(),
      'routeLabel': routeLabel,
      'originCode': originCode,
      'destinationCode': destinationCode,
      'originCountryCode': originCountryCode,
      'destinationCountryCode': destinationCountryCode,
      'contextLabel': contextLabel,
      'mapStatePlaceholder': mapStatePlaceholder,
      'hasLiveLocation': hasLiveLocation,
      'latitude': latitude,
      'longitude': longitude,
      'headingDegrees': headingDegrees,
      'altitudeMeters': altitudeMeters,
      'speedMetersPerSecond': speedMetersPerSecond,
      'horizontalAccuracyMeters': horizontalAccuracyMeters,
      'outsideTemperatureCelsius': outsideTemperatureCelsius,
    };
  }

  static SkyCameraOverlaySnapshot? fromJson(Map<String, dynamic> json) {
    final timestampRaw = json['timestamp']?.toString().trim() ?? '';
    final routeLabel = json['routeLabel']?.toString() ?? '';
    final originCode = json['originCode']?.toString() ?? '';
    final destinationCode = json['destinationCode']?.toString() ?? '';
    final originCountryCode = json['originCountryCode']?.toString() ?? '';
    final destinationCountryCode =
        json['destinationCountryCode']?.toString() ?? '';
    final contextLabel = json['contextLabel']?.toString() ?? '';
    final mapStatePlaceholder = json['mapStatePlaceholder']?.toString() ?? '';
    final hasLiveLocation = json['hasLiveLocation'] == true;
    if (timestampRaw.isEmpty) {
      return null;
    }
    final timestamp = DateTime.tryParse(timestampRaw);
    if (timestamp == null) return null;
    return SkyCameraOverlaySnapshot(
      timestamp: timestamp,
      routeLabel: routeLabel,
      originCode: originCode,
      destinationCode: destinationCode,
      originCountryCode: originCountryCode,
      destinationCountryCode: destinationCountryCode,
      contextLabel: contextLabel,
      mapStatePlaceholder: mapStatePlaceholder,
      hasLiveLocation: hasLiveLocation,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      headingDegrees: _toDouble(json['headingDegrees']),
      altitudeMeters: _toDouble(json['altitudeMeters']),
      speedMetersPerSecond: _toDouble(json['speedMetersPerSecond']),
      horizontalAccuracyMeters: _toDouble(json['horizontalAccuracyMeters']),
      outsideTemperatureCelsius: _toDouble(json['outsideTemperatureCelsius']),
    );
  }

  static double? _toDouble(Object? value) {
    return switch (value) {
      double d => d,
      num n => n.toDouble(),
      String s => double.tryParse(s),
      _ => null,
    };
  }
}
