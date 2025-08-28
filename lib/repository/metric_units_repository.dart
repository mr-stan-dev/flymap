import 'package:flymap/entity/units.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MetricUnitsRepository {
  static const _kAltitude = 'settings.altitudeUnit';
  static const _kSpeed = 'settings.speedUnit';
  static const _kTime = 'settings.timeFormat';

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

  // Backward-compatible parsing helpers
  AltitudeUnit _parseAltitude(String? v) {
    switch (v) {
      case 'meter':
        return AltitudeUnit.meter;
      case 'foot':
      default:
        return AltitudeUnit.foot;
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
}
