import 'package:equatable/equatable.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/entity/gps_data.dart';

/// Sealed class for flight screen states
sealed class FlightScreenState extends Equatable {
  const FlightScreenState();

  @override
  List<Object?> get props => [];
}

/// Loading state
final class FlightScreenLoading extends FlightScreenState {
  const FlightScreenLoading();
}

/// Flight in progress state
final class FlightScreenLoaded extends FlightScreenState {
  final Flight flight;
  final GpsStatus gpsStatus;
  final GpsData? gpsData;

  const FlightScreenLoaded({
    required this.flight,
    this.gpsStatus = GpsStatus.off,
    this.gpsData,
  });

  FlightScreenLoaded copyWith({
    Flight? flight,
    GpsStatus? gpsStatus,
    GpsData? gpsData,
  }) {
    return FlightScreenLoaded(
      flight: flight ?? this.flight,
      gpsStatus: gpsStatus ?? this.gpsStatus,
      gpsData: gpsData ?? this.gpsData,
    );
  }

  @override
  String toString() {
    return 'Flight: ${flight.id}, gpsStatus: ${gpsStatus.name}';
  }

  @override
  List<Object?> get props => [flight, gpsStatus, gpsData];
}

/// Deleted/Completed state to notify UI
final class FlightScreenDeleted extends FlightScreenState {
  final String message;
  const FlightScreenDeleted(this.message);

  @override
  List<Object?> get props => [message];
}

/// Error state
final class FlightScreenError extends FlightScreenState {
  final String message;
  final Flight? flight;

  const FlightScreenError(this.message, {this.flight});

  @override
  List<Object?> get props => [message, flight];
}
