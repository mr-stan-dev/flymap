import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/domain/entity/units.dart';
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

  group('TravelDateFormatUtils.countdownLabel', () {
    test('past-date fallback follows the date-format setting', () {
      final schedule = FlightSchedule.dateOnly(DateTime(2020, 8, 3));
      expect(
        TravelDateFormatUtils.countdownLabel(
          schedule,
          DateDisplayFormat.international,
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
