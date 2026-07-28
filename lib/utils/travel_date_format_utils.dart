import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:intl/intl.dart';

/// Formats travel dates / scheduled times in the app language (slang locale),
/// so dates match the surrounding translated text.
class TravelDateFormatUtils {
  const TravelDateFormatUtils._();

  static String get _locale => LocaleSettings.currentLocale.languageCode;

  /// "Mon, Aug 3" (en) / "Mo., 3. Aug." (de) — weekday + short date.
  static String formatShortDate(DateTime date) {
    return DateFormat.MMMEd(_locale).format(date);
  }

  /// "09:15" — 24h wall-clock time.
  static String formatTime(DateTime time) {
    return DateFormat.Hm(_locale).format(time);
  }

  /// "Mon, Aug 3 · 09:15" when a time is known, date alone otherwise.
  static String formatDateWithOptionalTime(DateTime date, DateTime? time) {
    final formattedDate = formatShortDate(date);
    if (time == null) return formattedDate;
    return '$formattedDate · ${formatTime(time)}';
  }

  /// Home-card countdown: "Today · 09:15" / "Tomorrow" / "In 3 days";
  /// past dates fall back to the plain date ("Mon, Jul 20"). Null when the
  /// flight has no schedule.
  static String? countdownLabel(FlightSchedule? schedule) {
    if (schedule == null) return null;
    final dateT = t.createFlight.travelDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysAway = schedule.travelDate.difference(today).inDays;
    if (daysAway == 0) {
      final departureLocal = schedule.scheduledDepartureLocal;
      return departureLocal == null
          ? dateT.today
          : '${dateT.today} · ${formatTime(departureLocal)}';
    }
    if (daysAway == 1) return dateT.tomorrow;
    if (daysAway > 1) return dateT.inDays(count: daysAway);
    return formatShortDate(schedule.travelDate);
  }
}
