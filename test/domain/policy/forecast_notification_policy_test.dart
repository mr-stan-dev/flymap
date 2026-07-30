import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/domain/policy/forecast_notification_policy.dart';

void main() {
  group('ForecastNotificationPolicy', () {
    test('no schedule plans nothing', () {
      expect(ForecastNotificationPolicy.planFor(null), isEmpty);
    });

    test('plans ready at T-6d 10:00 and updated at T-1d 18:00', () {
      final planned = ForecastNotificationPolicy.planFor(
        FlightSchedule.dateOnly(DateTime(2026, 8, 10)),
      );

      expect(planned, hasLength(2));
      final ready = planned.firstWhere(
        (p) => p.type == ForecastNotificationType.forecastReady,
      );
      final updated = planned.firstWhere(
        (p) => p.type == ForecastNotificationType.forecastUpdated,
      );
      expect(ready.localWallClock, DateTime(2026, 8, 4, 10));
      expect(updated.localWallClock, DateTime(2026, 8, 9, 18));
    });

    test('calendar math crosses month boundaries', () {
      final planned = ForecastNotificationPolicy.planFor(
        FlightSchedule.dateOnly(DateTime(2026, 8, 3)),
      );

      final ready = planned.firstWhere(
        (p) => p.type == ForecastNotificationType.forecastReady,
      );
      expect(ready.localWallClock, DateTime(2026, 7, 28, 10));
    });
  });
}
