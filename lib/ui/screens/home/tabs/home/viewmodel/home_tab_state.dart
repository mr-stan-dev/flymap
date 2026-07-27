import 'package:equatable/equatable.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/size_utils.dart';
import 'package:flymap/utils/unit_format_utils.dart';

enum HomeFlightsSort { mostRecent, longestDistance, alphabetical }

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
  final HomeFlightsSort sort;
  final String displayName;
  final bool hasInternet;
  final bool isRefreshing;
  final DistanceUnit distanceUnit;
  final DateDisplayFormat dateDisplayFormat;

  const HomeTabSuccess({
    required this.statistics,
    required this.flights,
    required this.sort,
    this.displayName = '',
    this.hasInternet = true,
    this.isRefreshing = false,
    this.distanceUnit = DistanceUnit.km,
    this.dateDisplayFormat = DateDisplayFormat.us,
  });

  HomeTabSuccess copyWith({
    FlightStatistics? statistics,
    List<Flight>? flights,
    HomeFlightsSort? sort,
    String? displayName,
    bool? hasInternet,
    bool? isRefreshing,
    DistanceUnit? distanceUnit,
    DateDisplayFormat? dateDisplayFormat,
  }) {
    return HomeTabSuccess(
      statistics: statistics ?? this.statistics,
      flights: flights ?? this.flights,
      sort: sort ?? this.sort,
      displayName: displayName ?? this.displayName,
      hasInternet: hasInternet ?? this.hasInternet,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      dateDisplayFormat: dateDisplayFormat ?? this.dateDisplayFormat,
    );
  }

  @override
  List<Object?> get props => [
    statistics,
    flights,
    sort,
    displayName,
    hasInternet,
    isRefreshing,
    distanceUnit,
    dateDisplayFormat,
  ];
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
  List<Object?> get props => [
    message,
    statistics,
    inProgressFlights,
    upcomingFlights,
  ];
}

/// Flight statistics data class
class FlightStatistics extends Equatable {
  final int totalFlights;
  final int totalDownloadedMaps;
  final int totalMapSize; // in bytes
  final double totalDistanceKm;
  final DistanceUnit distanceUnit;

  const FlightStatistics({
    required this.totalFlights,
    required this.totalDownloadedMaps,
    required this.totalMapSize,
    required this.totalDistanceKm,
    this.distanceUnit = DistanceUnit.km,
  });

  factory FlightStatistics.zero() {
    return const FlightStatistics(
      totalFlights: 0,
      totalDownloadedMaps: 0,
      totalMapSize: 0,
      totalDistanceKm: 0,
      distanceUnit: DistanceUnit.km,
    );
  }

  FlightStatistics copyWithDistanceUnit(DistanceUnit nextDistanceUnit) {
    return FlightStatistics(
      totalFlights: totalFlights,
      totalDownloadedMaps: totalDownloadedMaps,
      totalMapSize: totalMapSize,
      totalDistanceKm: totalDistanceKm,
      distanceUnit: nextDistanceUnit,
    );
  }

  /// Get total map size in MB
  double get totalMapSizeMB => totalMapSize / (1024 * 1024);

  /// Get total map size in GB
  double get totalMapSizeGB => totalMapSizeMB / 1024;

  /// Format total map size as string
  String get formattedTotalMapSize => SizeUtils.formatBytes(totalMapSize);

  /// Approximate total distance ("~24320 km") — sums of estimates stay
  /// estimates.
  String get formattedTotalDistance =>
      UnitFormatUtils.formatDistanceApprox(totalDistanceKm, distanceUnit);

  @override
  List<Object?> get props => [
    totalFlights,
    totalDownloadedMaps,
    totalMapSize,
    totalDistanceKm,
    distanceUnit,
  ];
}
