import 'package:equatable/equatable.dart';

/// GPS status enum
enum GpsStatus { off, permissionsNotGranted, searching, weakSignal, gpsActive }

class SpeedValue extends Equatable {
  final double value;
  final String unit; // e.g., 'km/h' or 'mph'
  const SpeedValue(this.value, this.unit);
  @override
  List<Object?> get props => [value, unit];
}

class AltitudeValue extends Equatable {
  final double value;
  final String unit; // e.g., 'm' or 'ft'
  const AltitudeValue(this.value, this.unit);
  @override
  List<Object?> get props => [value, unit];
}

/// GPS data model
class GpsData extends Equatable {
  final double? latitude;
  final double? longitude;
  final AltitudeValue? altitude;
  final SpeedValue? speed;
  final double? course;
  final double? accuracy;

  const GpsData({
    this.latitude,
    this.longitude,
    this.altitude,
    this.speed,
    this.course,
    this.accuracy,
  });

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    altitude,
    speed,
    course,
    accuracy,
  ];

  GpsData copyWith({
    double? latitude,
    double? longitude,
    AltitudeValue? altitude,
    SpeedValue? speed,
    double? course,
    double? accuracy,
  }) {
    return GpsData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      course: course ?? this.course,
      accuracy: accuracy ?? this.accuracy,
    );
  }
}
