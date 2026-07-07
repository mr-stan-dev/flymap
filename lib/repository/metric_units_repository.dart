import 'package:flymap/domain/entity/units.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MetricUnitsRepository {
  static const _kAltitude = 'settings.altitudeUnit';
  static const _kSpeed = 'settings.speedUnit';
  static const _kTime = 'settings.timeFormat';
  static const _kDistance = 'settings.distanceUnit';
  static const _kDateDisplay = 'settings.dateDisplayFormat';
  static const _kTemperature = 'settings.temperatureUnit';

  // Altitude
  Future<AltitudeUnit> getAltitudeUnit() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kAltitude);
    return _parseAltitude(stored);
  }

  Future<void> setAltitudeUnit(AltitudeUnit unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAltitude, unit.name);
  }

  // Speed
  Future<SpeedUnit> getSpeedUnit() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kSpeed);
    return _parseSpeed(stored);
  }

  Future<void> setSpeedUnit(SpeedUnit unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSpeed, unit.name);
  }

  // Time format
  Future<TimeFormat> getTimeFormat() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kTime);
    return _parseTime(stored);
  }

  Future<void> setTimeFormat(TimeFormat format) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTime, format.name);
  }

  // Distance unit
  Future<DistanceUnit> getDistanceUnit() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kDistance);
    return _parseDistance(stored);
  }

  Future<void> setDistanceUnit(DistanceUnit unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDistance, unit.name);
  }

  // Date display format
  Future<DateDisplayFormat> getDateDisplayFormat() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kDateDisplay);
    return _parseDateDisplay(stored);
  }

  Future<void> setDateDisplayFormat(DateDisplayFormat format) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDateDisplay, format.name);
  }

  // Temperature unit
  Future<TemperatureUnit> getTemperatureUnit() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kTemperature);
    return _parseTemperature(stored);
  }

  Future<void> setTemperatureUnit(TemperatureUnit unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTemperature, unit.name);
  }

  // Backward-compatible parsing helpers
  AltitudeUnit _parseAltitude(String? v) {
    switch (v) {
      case 'foot':
        return AltitudeUnit.foot;
      // Default (including unset) is meters: most of the user base is
      // metric, matching the km distance default. Users who picked feet have
      // 'foot' stored and are unaffected.
      case 'meter':
      default:
        return AltitudeUnit.meter;
    }
  }

  SpeedUnit _parseSpeed(String? v) {
    switch (v) {
      case 'mph':
        return SpeedUnit.mph;
      case 'kmh':
      default:
        return SpeedUnit.kmh;
    }
  }

  TimeFormat _parseTime(String? v) {
    switch (v) {
      case 'format12h':
        return TimeFormat.format12h;
      case 'format24h':
      default:
        return TimeFormat.format24h;
    }
  }

  DistanceUnit _parseDistance(String? v) {
    switch (v) {
      case 'mile':
        return DistanceUnit.mile;
      case 'km':
      default:
        return DistanceUnit.km;
    }
  }

  DateDisplayFormat _parseDateDisplay(String? v) {
    switch (v) {
      case 'international':
        return DateDisplayFormat.international;
      case 'us':
      default:
        return DateDisplayFormat.us;
    }
  }

  TemperatureUnit _parseTemperature(String? v) {
    switch (v) {
      case 'fahrenheit':
        return TemperatureUnit.fahrenheit;
      case 'celsius':
      default:
        return TemperatureUnit.celsius;
    }
  }
}
