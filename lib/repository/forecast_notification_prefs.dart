import 'package:shared_preferences/shared_preferences.dart';

/// User-facing toggles for the two forecast alerts. Both default ON — the
/// system notification permission is the real gate; these let users mute a
/// specific alert without revoking it.
class ForecastNotificationPrefs {
  static const _kReadyEnabled = 'notifications.forecast_ready.enabled';
  static const _kUpdatedEnabled = 'notifications.forecast_updated.enabled';

  Future<bool> isReadyEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kReadyEnabled) ?? true;
  }

  Future<bool> isUpdatedEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kUpdatedEnabled) ?? true;
  }

  Future<void> setReadyEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kReadyEnabled, enabled);
  }

  Future<void> setUpdatedEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kUpdatedEnabled, enabled);
  }
}
