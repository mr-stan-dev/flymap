import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:intl/intl.dart';

class UnitFormatUtils {
  const UnitFormatUtils._();

  /// Locale-aware thousands grouping ("10,450" en / "10.450" de / "10 450"
  /// fr), following the app language rather than the device locale so
  /// numbers match the surrounding translated text.
  static String formatThousands(num value) {
    return NumberFormat.decimalPattern(
      LocaleSettings.currentLocale.languageCode,
    ).format(value);
  }

  static String formatAltitude(AltitudeUnit unit) =>
      unit == AltitudeUnit.meter ? 'm' : 'ft';

  static String formatSpeed(SpeedUnit unit) =>
      unit == SpeedUnit.mph ? 'mph' : 'km/h';

  static String formatTime(TimeFormat format) =>
      format == TimeFormat.format12h ? '12h' : '24h';

  static String formatDistanceUnit(DistanceUnit unit) =>
      unit == DistanceUnit.mile ? 'mi' : 'km';

  static String formatDateDisplay(DateDisplayFormat format) =>
      format == DateDisplayFormat.us ? 'MM/DD/YYYY' : 'DD/MM/YYYY';

  static String formatTemperature(TemperatureUnit unit) =>
      unit == TemperatureUnit.fahrenheit ? '°F' : '°C';

  static String formatDistance(double distanceKm, DistanceUnit unit) {
    final value = unit == DistanceUnit.mile
        ? distanceKm * 0.621371
        : distanceKm;
    return '${formatThousands(value.round())} ${formatDistanceUnit(unit)}';
  }

  /// Approximate distance for glanceable UI: rounded to the nearest 10 of
  /// the display unit with thousands grouping (e.g. "10,450 km"). No "~"
  /// prefix — at small sizes it reads as a minus; the round number alone
  /// signals an estimate.
  static String formatDistanceApprox(double distanceKm, DistanceUnit unit) {
    final value = unit == DistanceUnit.mile
        ? distanceKm * 0.621371
        : distanceKm;
    final rounded = (value / 10).round() * 10;
    return '${formatThousands(rounded)} ${formatDistanceUnit(unit)}';
  }

  static String formatDate(DateTime date, {required DateDisplayFormat format}) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    if (format == DateDisplayFormat.us) return '$mm/$dd/$yyyy';
    return '$dd/$mm/$yyyy';
  }
}
