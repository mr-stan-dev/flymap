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
    final pattern = format == DateDisplayFormat.us
        ? 'EEE, MMM d'
        : 'EEE, d MMM';
    return DateFormat(pattern, _locale).format(date);
  }

  /// "09:15" — 24h wall-clock time.
  static String formatTime(DateTime time) {
    return DateFormat.Hm(_locale).format(time);
  }

  /// "GMT+2" / "GMT+5:30" from an offset in minutes. Zero returns null:
  /// persisted weather also uses zero when the airport timezone is unknown.
  static String? formatUtcOffset(int offsetMinutes) {
    if (offsetMinutes == 0) return null;
    final sign = offsetMinutes < 0 ? '-' : '+';
    final absolute = offsetMinutes.abs();
    final hours = absolute ~/ 60;
    final minutes = absolute % 60;
    final minuteText = minutes == 0
        ? ''
        : ':${minutes.toString().padLeft(2, '0')}';
    return 'GMT$sign$hours$minuteText';
  }

  /// Forecast freshness uses one representation at a time:
  /// - today's updates are relative ("Updated 2 h ago");
  /// - older updates use an exact local date and time
  ///   ("Updated Wed, Aug 5, 15:30").
  static String formatForecastFreshness(
    DateTime fetchedAt,
    DateDisplayFormat format, {
    DateTime? now,
  }) {
    final localFetchedAt = fetchedAt.toLocal();
    final localNow = (now ?? DateTime.now()).toLocal();
    final isToday =
        localFetchedAt.year == localNow.year &&
        localFetchedAt.month == localNow.month &&
        localFetchedAt.day == localNow.day;
    final weatherT = t.createFlight.weather;
    if (!isToday) {
      return weatherT.updatedExact(
        date: formatShortDate(localFetchedAt, format),
        time: formatTime(localFetchedAt),
      );
    }

    final difference = localNow.difference(localFetchedAt);
    final age = difference.isNegative ? Duration.zero : difference;
    final relative = switch (age) {
      Duration(inMinutes: < 1) => weatherT.updatedJustNow,
      Duration(inMinutes: < 60) => weatherT.updatedMinutesAgo(
        minutes: age.inMinutes,
      ),
      _ => weatherT.updatedHoursAgo(hours: age.inHours),
    };
    return weatherT.updatedRelative(relative: relative);
  }

  /// Provider schedule as a plain time, or a user-supplied time prefixed by
  /// `~` so summary surfaces keep the precision honest.
  static String? formatScheduleDepartureTime(FlightSchedule? schedule) {
    if (schedule == null) return null;
    final scheduled = schedule.departureLocal;
    if (scheduled != null) return formatTime(scheduled);
    final approximate = schedule.approximateDepartureLocal;
    return approximate == null ? null : '~${formatTime(approximate)}';
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
      final departureTime = formatScheduleDepartureTime(schedule);
      return departureTime == null
          ? dateT.today
          : '${dateT.today} · $departureTime';
    }
    if (daysAway == 1) return dateT.tomorrow;
    if (daysAway > 1) return dateT.inDays(count: daysAway);
    return formatShortDate(schedule.travelDate, format);
  }
}
