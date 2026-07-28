import 'package:equatable/equatable.dart';
import 'package:flymap/domain/entity/zoned_instant.dart';

/// When the user is flying. Always optional on a flight — every flow must
/// work unchanged when it is absent.
///
/// Two levels of precision:
/// - date-only (manual chips, approximate flights): only [travelDate] is
///   set — there is no instant to derive anything from;
/// - schedule pick (upcoming-flight search): [departure] (and usually
///   [arrival]) carry the provider's exact instants with airport offsets.
class FlightSchedule extends Equatable {
  /// Local travel date with date-only semantics: always midnight, no
  /// timezone meaning beyond "the calendar day at the departure airport".
  final DateTime travelDate;

  /// Scheduled departure (STD) with the departure airport's offset. Only
  /// from schedule picks — never hand-entered, never prefilled from stale
  /// FR24 history.
  final ZonedInstant? departure;

  /// Scheduled arrival (STA) with the arrival airport's offset, when the
  /// provider supplied it.
  final ZonedInstant? arrival;

  const FlightSchedule({
    required this.travelDate,
    this.departure,
    this.arrival,
  });

  /// Date-only schedule (manual pick); normalizes away any time component.
  factory FlightSchedule.dateOnly(DateTime date) {
    return FlightSchedule(travelDate: DateTime(date.year, date.month, date.day));
  }

  bool get hasScheduledTime => departure != null;

  /// Scheduled departure as wall-clock time at the departure airport, or
  /// null when only the date is known.
  DateTime? get departureLocal => departure?.local;

  FlightSchedule copyWith({
    DateTime? travelDate,
    ZonedInstant? departure,
    ZonedInstant? arrival,
  }) {
    return FlightSchedule(
      travelDate: travelDate ?? this.travelDate,
      departure: departure ?? this.departure,
      arrival: arrival ?? this.arrival,
    );
  }

  @override
  List<Object?> get props => [travelDate, departure, arrival];
}
