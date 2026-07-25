import 'package:flymap/domain/entity/units.dart';

class UnitFormatUtils {
  const UnitFormatUtils._();

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
    final rounded = value.toStringAsFixed(0);
    return '$rounded ${formatDistanceUnit(unit)}';
  }

  /// Approximate distance for glanceable UI: rounded to the nearest 10 of
  /// the display unit and prefixed with "~" (e.g. "~1230 km").
  static String formatDistanceApprox(double distanceKm, DistanceUnit unit) {
    final value = unit == DistanceUnit.mile
        ? distanceKm * 0.621371
        : distanceKm;
    final rounded = (value / 10).round() * 10;
    return '~$rounded ${formatDistanceUnit(unit)}';
  }

  static String formatDate(DateTime date, {required DateDisplayFormat format}) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    if (format == DateDisplayFormat.us) return '$mm/$dd/$yyyy';
    return '$dd/$mm/$yyyy';
  }
}
