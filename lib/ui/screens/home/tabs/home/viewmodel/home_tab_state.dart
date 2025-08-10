import 'package:equatable/equatable.dart';
import 'package:flymap/entity/flight.dart';

/// Sealed class for home tab states
sealed class HomeTabState extends Equatable {
  const HomeTabState();

  @override
  List<Object?> get props => [];
}

/// Loading state
final class HomeTabLoading extends HomeTabState {
  const HomeTabLoading();
}

/// Success state with all data loaded
final class HomeTabSuccess extends HomeTabState {
  final FlightStatistics statistics;
  final List<Flight> flights;
  final bool isRefreshing;

  const HomeTabSuccess({
    required this.statistics,
    required this.flights,
    this.isRefreshing = false,
  });

  HomeTabSuccess copyWith({
    FlightStatistics? statistics,
    List<Flight>? inProgressFlights,
    List<Flight>? upcomingFlights,
    bool? isRefreshing,
  }) {
    return HomeTabSuccess(
      statistics: statistics ?? this.statistics,
      flights: upcomingFlights ?? this.flights,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [statistics, flights, isRefreshing];
}

/// Error state
final class HomeTabError extends HomeTabState {
  final String message;
  final FlightStatistics? statistics;
  final List<Flight>? inProgressFlights;
  final List<Flight>? upcomingFlights;

  const HomeTabError(
    this.message, {
    this.statistics,
    this.inProgressFlights,
    this.upcomingFlights,
  });

  @override
  List<Object?> get props => [message, statistics, inProgressFlights, upcomingFlights];
}

/// Flight statistics data class
class FlightStatistics extends Equatable {
  final int totalFlights;
  final int totalDownloadedMaps;
  final int totalMapSize; // in bytes

  const FlightStatistics({
    required this.totalFlights,
    required this.totalDownloadedMaps,
    required this.totalMapSize,
  });

  factory FlightStatistics.zero() {
    return const FlightStatistics(
      totalFlights: 0,
      totalDownloadedMaps: 0,
      totalMapSize: 0,
    );
  }

  /// Get total map size in MB
  double get totalMapSizeMB => totalMapSize / (1024 * 1024);

  /// Get total map size in GB
  double get totalMapSizeGB => totalMapSizeMB / 1024;

  /// Format total map size as string
  String get formattedTotalMapSize {
    if (totalMapSizeGB >= 1) {
      return '${totalMapSizeGB.toStringAsFixed(1)} GB';
    } else {
      return '${totalMapSizeMB.toStringAsFixed(1)} MB';
    }
  }

  @override
  List<Object?> get props => [totalFlights, totalDownloadedMaps, totalMapSize];
}
