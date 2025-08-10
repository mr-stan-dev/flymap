import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _kTheme = 'settings.theme';
  static const _kAltitude = 'settings.altitudeUnit';
  static const _kSpeed = 'settings.speedUnit';
  static const _kTime = 'settings.timeFormat';

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_kTheme) ?? 'Dark';
    return value == 'Dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTheme, mode == ThemeMode.dark ? 'Dark' : 'Light');
  }

  Future<String> getAltitudeUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAltitude) ?? 'ft';
  }

  Future<void> setAltitudeUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAltitude, unit);
  }

  Future<String> getSpeedUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSpeed) ?? 'km/h';
  }

  Future<void> setSpeedUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSpeed, unit);
  }

  Future<String> getTimeFormat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTime) ?? '24h';
  }

  Future<void> setTimeFormat(String format) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTime, format);
  }
}
