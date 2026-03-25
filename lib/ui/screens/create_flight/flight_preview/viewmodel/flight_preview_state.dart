import 'package:equatable/equatable.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_route.dart';

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
final class FlightMapPreviewMapState extends FlightPreviewState {
  final FlightRoute flightRoute;
  final FlightInfo flightInfo;
  final double currentZoom;
  final bool isTooLongFlight;
  final bool isOverviewLoading;
  final String? overviewErrorMessage;

  const FlightMapPreviewMapState({
    required this.flightRoute,
    required this.flightInfo,
    required this.currentZoom,
    required this.isTooLongFlight,
    required this.isOverviewLoading,
    required this.overviewErrorMessage,
  });

  FlightMapPreviewMapState copyWith({
    FlightRoute? flightRoute,
    FlightInfo? flightInfo,
    double? currentZoom,
    bool? isTooLongFlight,
    bool? isOverviewLoading,
    String? overviewErrorMessage,
    bool clearOverviewErrorMessage = false,
  }) {
    return FlightMapPreviewMapState(
      flightRoute: flightRoute ?? this.flightRoute,
      flightInfo: flightInfo ?? this.flightInfo,
      currentZoom: currentZoom ?? this.currentZoom,
      isTooLongFlight: isTooLongFlight ?? this.isTooLongFlight,
      isOverviewLoading: isOverviewLoading ?? this.isOverviewLoading,
      overviewErrorMessage: clearOverviewErrorMessage
          ? null
          : overviewErrorMessage ?? this.overviewErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    flightRoute,
    flightInfo,
    currentZoom,
    isTooLongFlight,
    isOverviewLoading,
    overviewErrorMessage,
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
