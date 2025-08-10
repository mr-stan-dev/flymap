import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/repository/settings_repository.dart';

import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repo;
  SettingsCubit({SettingsRepository? repository})
    : _repo = repository ?? SettingsRepository(),
      super(const SettingsState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    final theme = await _repo.getThemeMode();
    final altitude = await _repo.getAltitudeUnit();
    final speed = await _repo.getSpeedUnit();
    final time = await _repo.getTimeFormat();

    emit(
      SettingsState(
        themeMode: theme,
        altitudeUnit: altitude,
        speedUnit: speed,
        timeFormat: time,
        isLoading: false,
      ),
    );
  }

  Future<void> setTheme(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    await _repo.setThemeMode(mode);
  }

  Future<void> setAltitudeUnit(String unit) async {
    emit(state.copyWith(altitudeUnit: unit));
    await _repo.setAltitudeUnit(unit);
  }

  Future<void> setSpeedUnit(String unit) async {
    emit(state.copyWith(speedUnit: unit));
    await _repo.setSpeedUnit(unit);
  }

  Future<void> setTimeFormat(String format) async {
    emit(state.copyWith(timeFormat: format));
    await _repo.setTimeFormat(format);
  }
}
