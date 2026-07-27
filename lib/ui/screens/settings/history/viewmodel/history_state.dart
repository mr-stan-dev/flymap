import 'package:equatable/equatable.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/utils/unit_format_utils.dart';

enum HistorySort { name, distance, date }

class HistoryItem extends Equatable {
  const HistoryItem({required this.flight});

  final Flight flight;

  @override
  List<Object?> get props => [flight];
}

sealed class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

final class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

final class HistorySuccess extends HistoryState {
  const HistorySuccess({
    required this.items,
    required this.sort,
    required this.totalFlights,
    required this.totalDistanceKm,
    this.distanceUnit = DistanceUnit.km,
    this.dateDisplayFormat = DateDisplayFormat.us,
  });

  final List<HistoryItem> items;
  final HistorySort sort;
  final int totalFlights;
  final double totalDistanceKm;
  final DistanceUnit distanceUnit;
  final DateDisplayFormat dateDisplayFormat;

  String get formattedTotalDistance =>
      UnitFormatUtils.formatDistanceApprox(totalDistanceKm, distanceUnit);

  HistorySuccess copyWith({
    List<HistoryItem>? items,
    HistorySort? sort,
    int? totalFlights,
    double? totalDistanceKm,
    DistanceUnit? distanceUnit,
    DateDisplayFormat? dateDisplayFormat,
  }) {
    return HistorySuccess(
      items: items ?? this.items,
      sort: sort ?? this.sort,
      totalFlights: totalFlights ?? this.totalFlights,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      dateDisplayFormat: dateDisplayFormat ?? this.dateDisplayFormat,
    );
  }

  @override
  List<Object?> get props => [
    items,
    sort,
    totalFlights,
    totalDistanceKm,
    distanceUnit,
    dateDisplayFormat,
  ];
}

final class HistoryError extends HistoryState {
  const HistoryError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
