import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

sealed class FlightPreviewState extends Equatable {
  const FlightPreviewState();

  @override
  List<Object?> get props => [];
}

/// Loading state - calculating route and corridor
final class FlightMapPreviewLoading extends FlightPreviewState {
  const FlightMapPreviewLoading();
}

/// Route and corridor calculated successfully
final class FlightMapPreviewLoaded extends FlightPreviewState {
  final List<LatLng> flightRoute;
  final List<LatLng> flightCorridor;
  final double currentZoom;
  final bool isTooLongFlight;

  const FlightMapPreviewLoaded({
    required this.flightRoute,
    required this.flightCorridor,
    required this.currentZoom,
    required this.isTooLongFlight,
  });

  @override
  List<Object?> get props => [
    flightRoute,
    flightCorridor,
    currentZoom,
    isTooLongFlight,
  ];
}

final class MapDownloadingState extends FlightPreviewState {
  final double progress;
  final bool? done;
  final String? errorMessage;

  const MapDownloadingState({
    required this.progress,
    this.done,
    this.errorMessage,
  });

  bool get isDownloaded => progress == 1.0;

  @override
  List<Object?> get props => [progress, done, errorMessage];
}

/// Error state
final class FlightMapPreviewError extends FlightPreviewState {
  final String message;

  const FlightMapPreviewError(this.message);

  @override
  List<Object?> get props => [message];
}
