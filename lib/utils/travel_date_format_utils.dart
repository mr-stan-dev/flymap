import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:intl/intl.dart';

/// Formats travel dates / scheduled times in the app language (slang locale),
/// so dates match the surrounding translated text. Day/month ordering follows
/// the user's [DateDisplayFormat] setting rather than the language locale's
/// own convention — a UK user on English still gets "3 Aug" when they picked
/// the international format.
class TravelDateFormatUtils {
  const TravelDateFormatUtils._();

  static String get _locale => LocaleSettings.currentLocale.languageCode;

  /// "Mon, Aug 3" (US) / "Mon, 3 Aug" (international) — weekday + short date,
  /// month/weekday names localised, day/month order from [format].
  static String formatShortDate(DateTime date, DateDisplayFormat format) {
    final pattern = format == DateDisplayFormat.us ? 'EEE, MMM d' : 'EEE, d MMM';
    return DateFormat(pattern, _locale).format(date);
  }

  /// "09:15" — 24h wall-clock time.
  static String formatTime(DateTime time) {
    return DateFormat.Hm(_locale).format(time);
  }

  /// "Mon, Aug 3 · 09:15" when a time is known, date alone otherwise.
  static String formatDateWithOptionalTime(
    DateTime date,
    DateTime? time,
    DateDisplayFormat format,
  ) {
    final formattedDate = formatShortDate(date, format);
    if (time == null) return formattedDate;
    return '$formattedDate · ${formatTime(time)}';
  }

  /// Home-card countdown: "Today · 09:15" / "Tomorrow" / "In 3 days";
  /// past dates fall back to the plain date ("Mon, Jul 20"). Null when the
  /// flight has no schedule.
  static String? countdownLabel(
    FlightSchedule? schedule,
    DateDisplayFormat format,
  ) {
    if (schedule == null) return null;
    final dateT = t.createFlight.travelDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysAway = schedule.travelDate.difference(today).inDays;
    if (daysAway == 0) {
      final departureLocal = schedule.departureLocal;
      return departureLocal == null
          ? dateT.today
          : '${dateT.today} · ${formatTime(departureLocal)}';
    }
    if (daysAway == 1) return dateT.tomorrow;
    if (daysAway > 1) return dateT.inDays(count: daysAway);
    return formatShortDate(schedule.travelDate, format);
  }
}
