import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/domain/entity/zoned_instant.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/utils/travel_date_format_utils.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await initializeDateFormatting('en');
  });

  final date = DateTime(2026, 8, 3); // Monday, 3 August 2026

  group('TravelDateFormatUtils.formatShortDate', () {
    test('US setting orders month before day', () {
      expect(
        TravelDateFormatUtils.formatShortDate(date, DateDisplayFormat.us),
        'Mon, Aug 3',
      );
    });

    test('international setting orders day before month', () {
      expect(
        TravelDateFormatUtils.formatShortDate(
          date,
          DateDisplayFormat.international,
        ),
        'Mon, 3 Aug',
      );
    });
  });

  group('TravelDateFormatUtils.formatDateWithOptionalTime', () {
    test('appends the time when known, honouring the date order', () {
      expect(
        TravelDateFormatUtils.formatDateWithOptionalTime(
          date,
          DateTime(2026, 8, 3, 9, 15),
          DateDisplayFormat.international,
        ),
        'Mon, 3 Aug · 09:15',
      );
    });

    test('date alone when no time', () {
      expect(
        TravelDateFormatUtils.formatDateWithOptionalTime(
          date,
          null,
          DateDisplayFormat.us,
        ),
        'Mon, Aug 3',
      );
    });
  });

  group('TravelDateFormatUtils.formatUtcOffset', () {
    test('formats whole-hour and half-hour offsets', () {
      expect(TravelDateFormatUtils.formatUtcOffset(120), 'GMT+2');
      expect(TravelDateFormatUtils.formatUtcOffset(330), 'GMT+5:30');
      expect(TravelDateFormatUtils.formatUtcOffset(-240), 'GMT-4');
    });

    test('omits zero because it can mean unknown', () {
      expect(TravelDateFormatUtils.formatUtcOffset(0), isNull);
    });
  });

  group('TravelDateFormatUtils.formatForecastFreshness', () {
    final now = DateTime(2026, 8, 5, 15, 30);

    test('uses only relative age for an update from today', () {
      expect(
        TravelDateFormatUtils.formatForecastFreshness(
          DateTime(2026, 8, 5, 13, 15),
          DateDisplayFormat.us,
          now: now,
        ),
        'Updated 2 h ago',
      );
    });

    test('uses only exact date and time for an older update', () {
      expect(
        TravelDateFormatUtils.formatForecastFreshness(
          DateTime(2026, 8, 3, 15, 30),
          DateDisplayFormat.international,
          now: now,
        ),
        'Updated Mon, 3 Aug, 15:30',
      );
    });

    test('switches to exact time immediately after a local day boundary', () {
      expect(
        TravelDateFormatUtils.formatForecastFreshness(
          DateTime(2026, 8, 4, 23, 50),
          DateDisplayFormat.us,
          now: DateTime(2026, 8, 5, 0, 10),
        ),
        'Updated Tue, Aug 4, 23:50',
      );
    });

    test('handles recent and future-clock timestamps safely', () {
      expect(
        TravelDateFormatUtils.formatForecastFreshness(
          now.add(const Duration(minutes: 2)),
          DateDisplayFormat.us,
          now: now,
        ),
        'Updated just now',
      );
    });
  });

  group('TravelDateFormatUtils.formatScheduleDepartureTime', () {
    test(
      'shows a user-supplied departure time without an approximation mark',
      () {
        final schedule = FlightSchedule.approximate(
          date,
          departureTime: ApproximateDepartureTime.forPeriod(
            ApproximateDeparturePeriod.morning,
          ),
        );

        expect(
          TravelDateFormatUtils.formatScheduleDepartureTime(schedule),
          '08:00',
        );
      },
    );
  });

  group('TravelDateFormatUtils.countdownLabel', () {
    final now = DateTime(2026, 8, 12, 15, 30);

    test('shows departure time for tomorrow when available', () {
      final schedule = FlightSchedule(
        travelDate: DateTime(2026, 8, 13),
        departure: ZonedInstant(
          utc: DateTime.utc(2026, 8, 13, 8, 15),
          offsetMinutes: 60,
        ),
      );

      expect(
        TravelDateFormatUtils.countdownLabel(
          schedule,
          DateDisplayFormat.us,
          now: now,
        ),
        'Tomorrow · 09:15',
      );
    });

    test('keeps tomorrow without a time for date-only schedules', () {
      final schedule = FlightSchedule(travelDate: DateTime(2026, 8, 13));

      expect(
        TravelDateFormatUtils.countdownLabel(
          schedule,
          DateDisplayFormat.us,
          now: now,
        ),
        'Tomorrow',
      );
    });

    test('uses relative labels for flights up to a week away', () {
      final schedule = FlightSchedule(travelDate: DateTime(2026, 8, 19));

      expect(
        TravelDateFormatUtils.countdownLabel(
          schedule,
          DateDisplayFormat.us,
          now: now,
        ),
        'In 7 days',
      );
    });

    test('uses configured date format for a flight 19 days away', () {
      final schedule = FlightSchedule(travelDate: DateTime(2026, 8, 31));

      expect(
        TravelDateFormatUtils.countdownLabel(
          schedule,
          DateDisplayFormat.us,
          now: now,
        ),
        'Mon, Aug 31',
      );
      expect(
        TravelDateFormatUtils.countdownLabel(
          schedule,
          DateDisplayFormat.international,
          now: now,
        ),
        'Mon, 31 Aug',
      );
    });

    test('past-date fallback follows the date-format setting', () {
      final schedule = FlightSchedule(travelDate: DateTime(2020, 8, 3));
      expect(
        TravelDateFormatUtils.countdownLabel(
          schedule,
          DateDisplayFormat.international,
          now: now,
        ),
        'Mon, 3 Aug',
      );
    });

    test('null schedule yields null', () {
      expect(
        TravelDateFormatUtils.countdownLabel(null, DateDisplayFormat.us),
        isNull,
      );
    });
  });
}
