import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _kTheme = 'settings.theme';
  static const _systemValue = 'System';
  static const _darkValue = 'Dark';
  static const _lightValue = 'Light';

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_kTheme) ?? _darkValue;
    return switch (value) {
      _darkValue => ThemeMode.dark,
      _lightValue => ThemeMode.light,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.dark => _darkValue,
      ThemeMode.light => _lightValue,
      ThemeMode.system => _systemValue,
    };
    await prefs.setString(_kTheme, value);
  }
}
