import 'package:equatable/equatable.dart';

/// When the user is flying. Always optional on a flight — every flow must
/// work unchanged when it is absent.
///
/// Two levels of precision:
/// - date-only (manual chips, approximate flights): only [travelDate] is set;
/// - schedule pick (upcoming-flight search): [scheduledDepartureUtc] and
///   [departureUtcOffsetMinutes] are set too, ready for weather later.
class FlightSchedule extends Equatable {
  /// Local travel date with date-only semantics: always midnight, no
  /// timezone meaning beyond "the calendar day at the departure airport".
  final DateTime travelDate;

  /// Exact scheduled departure (STD) in UTC. Only from schedule picks —
  /// never hand-entered, never prefilled from stale FR24 history.
  final DateTime? scheduledDepartureUtc;

  /// Departure airport UTC offset at the scheduled time, in minutes
  /// (e.g. +02:00 -> 120). Stored so local times survive DST changes.
  final int? departureUtcOffsetMinutes;

  const FlightSchedule({
    required this.travelDate,
    this.scheduledDepartureUtc,
    this.departureUtcOffsetMinutes,
  });

  /// Date-only schedule (manual pick); normalizes away any time component.
  factory FlightSchedule.dateOnly(DateTime date) {
    return FlightSchedule(travelDate: DateTime(date.year, date.month, date.day));
  }

  bool get hasScheduledTime => scheduledDepartureUtc != null;

  /// Scheduled departure as local wall-clock time at the departure airport,
  /// or null when only the date is known.
  DateTime? get scheduledDepartureLocal {
    final utc = scheduledDepartureUtc;
    if (utc == null) return null;
    return utc.add(Duration(minutes: departureUtcOffsetMinutes ?? 0));
  }

  FlightSchedule copyWith({
    DateTime? travelDate,
    DateTime? scheduledDepartureUtc,
    int? departureUtcOffsetMinutes,
  }) {
    return FlightSchedule(
      travelDate: travelDate ?? this.travelDate,
      scheduledDepartureUtc:
          scheduledDepartureUtc ?? this.scheduledDepartureUtc,
      departureUtcOffsetMinutes:
          departureUtcOffsetMinutes ?? this.departureUtcOffsetMinutes,
    );
  }

  @override
  List<Object?> get props => [
    travelDate,
    scheduledDepartureUtc,
    departureUtcOffsetMinutes,
  ];
}
