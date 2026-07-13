import 'package:flutter/material.dart';
import 'package:flymap/i18n/supported_locale.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LocaleSetting { system, english, spanish, french, german }

extension LocaleSettingX on LocaleSetting {
  SupportedLocale? get supportedLocale => switch (this) {
    LocaleSetting.system => null,
    LocaleSetting.english => SupportedLocale.english,
    LocaleSetting.spanish => SupportedLocale.spanish,
    LocaleSetting.french => SupportedLocale.french,
    LocaleSetting.german => SupportedLocale.german,
  };

  String? get localeCode => supportedLocale?.languageCode;
}

extension SupportedLocaleSettingX on SupportedLocale {
  LocaleSetting get localeSetting => switch (this) {
    SupportedLocale.english => LocaleSetting.english,
    SupportedLocale.spanish => LocaleSetting.spanish,
    SupportedLocale.french => LocaleSetting.french,
    SupportedLocale.german => LocaleSetting.german,
  };
}

class SettingsRepository {
  static const _kTheme = 'settings.theme';
  static const _kLocale = 'settings.locale';
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

  Future<LocaleSetting> getLocaleSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_kLocale);
    return SupportedLocale.fromLanguageCode(value)?.localeSetting ??
        LocaleSetting.system;
  }

  Future<void> setLocaleSetting(LocaleSetting value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == LocaleSetting.system) {
      await prefs.remove(_kLocale);
      return;
    }
    await prefs.setString(_kLocale, value.localeCode!);
  }

  static const _kSkyCameraRecordAudio = 'settings.skyCameraRecordAudio';

  /// Whether sky-camera videos record microphone audio. Off by default so
  /// opening the camera never triggers a surprise permission prompt.
  Future<bool> getSkyCameraRecordAudio() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSkyCameraRecordAudio) ?? false;
  }

  Future<void> setSkyCameraRecordAudio(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSkyCameraRecordAudio, enabled);
  }
}
