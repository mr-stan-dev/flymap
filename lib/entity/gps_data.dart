import 'package:equatable/equatable.dart';

/// GPS status enum
enum GpsStatus {
  off,
  permissionsNotGranted,
  searching,
  weakSignal,
  gpsActive,
}

/// GPS data model
class GpsData extends Equatable {
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? speed;
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
    double? altitude,
    double? speed,
    double? course,
    double? accuracy,
    double? distanceFromRoute,
    double? distanceFromCorridor,
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
