import 'package:equatable/equatable.dart';
import 'package:flymap/domain/entity/zoned_instant.dart';

/// Legacy coarse wall-clock periods from flights created before precise-only
/// manual time entry. Kept so persisted schedules remain readable; new UI must
/// not create period-based times.
enum ApproximateDeparturePeriod {
  morning(hour: 8),
  afternoon(hour: 14),
  evening(hour: 19),
  night(hour: 23);

  const ApproximateDeparturePeriod({required this.hour});

  final int hour;
}

/// A user-supplied wall-clock time at the departure airport. This is kept
/// separate from [FlightSchedule.departure], which is reserved for a
/// provider-supplied scheduled instant.
class ApproximateDepartureTime extends Equatable {
  const ApproximateDepartureTime({
    required this.hour,
    required this.minute,
    this.period,
  }) : assert(hour >= 0 && hour <= 23),
       assert(minute >= 0 && minute <= 59);

  factory ApproximateDepartureTime.forPeriod(
    ApproximateDeparturePeriod period,
  ) => ApproximateDepartureTime(hour: period.hour, minute: 0, period: period);

  final int hour;
  final int minute;

  /// Set only on legacy coarse choices; null for current manual time entry.
  final ApproximateDeparturePeriod? period;

  @override
  List<Object?> get props => [hour, minute, period];
}

enum FlightScheduleTimePrecision { dateOnly, approximateTime, scheduled }

/// When the user is flying. Always optional on a flight — every flow must
/// work unchanged when it is absent.
///
/// Three levels of precision:
/// - date-only (legacy persisted data): only [travelDate] is set — new UI
///   must not create this state because there is no forecast instant;
/// - approximate time: [approximateDepartureTime] is user supplied and must
///   be resolved through the departure airport's timezone;
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

  /// User-supplied local wall-clock estimate at the departure airport. It is
  /// intentionally not a [ZonedInstant]: only a provider schedule may claim
  /// an exact departure instant.
  final ApproximateDepartureTime? approximateDepartureTime;

  /// Scheduled arrival (STA) with the arrival airport's offset, when the
  /// provider supplied it.
  final ZonedInstant? arrival;

  const FlightSchedule({
    required this.travelDate,
    this.departure,
    this.approximateDepartureTime,
    this.arrival,
  }) : assert(
         departure == null || approximateDepartureTime == null,
         'A provider departure and an approximate time are mutually exclusive',
       );

  factory FlightSchedule.approximate(
    DateTime date, {
    required ApproximateDepartureTime departureTime,
  }) {
    return FlightSchedule(
      travelDate: DateTime(date.year, date.month, date.day),
      approximateDepartureTime: departureTime,
    );
  }

  bool get hasScheduledTime => departure != null;

  FlightScheduleTimePrecision get timePrecision {
    if (departure != null) return FlightScheduleTimePrecision.scheduled;
    if (approximateDepartureTime != null) {
      return FlightScheduleTimePrecision.approximateTime;
    }
    return FlightScheduleTimePrecision.dateOnly;
  }

  /// Scheduled departure as wall-clock time at the departure airport, or
  /// null when only the date is known.
  DateTime? get departureLocal => departure?.local;

  /// User-supplied wall-clock estimate on [travelDate], with no timezone
  /// meaning until a departure airport resolves it.
  DateTime? get approximateDepartureLocal {
    final time = approximateDepartureTime;
    if (time == null) return null;
    return DateTime(
      travelDate.year,
      travelDate.month,
      travelDate.day,
      time.hour,
      time.minute,
    );
  }

  FlightSchedule copyWith({
    DateTime? travelDate,
    ZonedInstant? departure,
    ApproximateDepartureTime? approximateDepartureTime,
    bool clearApproximateDepartureTime = false,
    ZonedInstant? arrival,
  }) {
    final nextDeparture = approximateDepartureTime != null
        ? null
        : departure ?? this.departure;
    final nextApproximateTime =
        departure != null || clearApproximateDepartureTime
        ? null
        : approximateDepartureTime ?? this.approximateDepartureTime;
    return FlightSchedule(
      travelDate: travelDate ?? this.travelDate,
      departure: nextDeparture,
      approximateDepartureTime: nextApproximateTime,
      arrival: arrival ?? this.arrival,
    );
  }

  @override
  List<Object?> get props => [
    travelDate,
    departure,
    approximateDepartureTime,
    arrival,
  ];
}
