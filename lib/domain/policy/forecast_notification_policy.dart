import 'package:flymap/domain/entity/flight_schedule.dart';

/// Which forecast alert a planned notification is.
enum ForecastNotificationType {
  /// The flight just entered the reliable forecast horizon.
  forecastReady,

  /// Day-before reminder to open Flymap for the latest forecast.
  forecastUpdated,
}

/// One notification the scheduler should place: a wall-clock instant in the
/// DEPARTURE AIRPORT's local calendar (the scheduler resolves it to an
/// absolute instant via the airport timezone).
class PlannedForecastNotification {
  const PlannedForecastNotification({
    required this.type,
    required this.localWallClock,
  });

  final ForecastNotificationType type;

  /// Naive local date-time (no timezone meaning on its own).
  final DateTime localWallClock;
}

/// When the two forecast alerts should fire for a flight. Pure calendar
/// math — no timezone resolution, no "is it in the past" filtering; the
/// scheduler owns both.
class ForecastNotificationPolicy {
  const ForecastNotificationPolicy._();

  /// "Forecast is ready": 6 days before, NOT 7 — the reliable horizon is
  /// 7 days, so a one-day safety gap guarantees the fetch on tap is
  /// comfortably inside it.
  static const int readyDaysBefore = 6;
  static const int readyLocalHour = 10;

  /// Day-before reminder: the evening before the flight, covering
  /// early-morning departures without claiming a background refresh occurred.
  static const int updatedDaysBefore = 1;
  static const int updatedLocalHour = 18;

  static List<PlannedForecastNotification> planFor(FlightSchedule? schedule) {
    if (schedule == null) return const [];
    final travel = schedule.travelDate;
    // Calendar-component math (Dart normalizes out-of-range days), NOT
    // Duration arithmetic — durations on local DateTimes shift across DST.
    return [
      PlannedForecastNotification(
        type: ForecastNotificationType.forecastReady,
        localWallClock: DateTime(
          travel.year,
          travel.month,
          travel.day - readyDaysBefore,
          readyLocalHour,
        ),
      ),
      PlannedForecastNotification(
        type: ForecastNotificationType.forecastUpdated,
        localWallClock: DateTime(
          travel.year,
          travel.month,
          travel.day - updatedDaysBefore,
          updatedLocalHour,
        ),
      ),
    ];
  }
}
