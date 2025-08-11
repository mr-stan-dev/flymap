import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/repository/settings_repository.dart';
import 'package:flymap/repository/metric_units_repository.dart';
import 'package:flymap/entity/units.dart';

import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _settingsRepo;
  final MetricUnitsRepository _unitsRepo;
  SettingsCubit({
    SettingsRepository? repository,
    MetricUnitsRepository? unitsRepository,
  }) : _settingsRepo = repository ?? SettingsRepository(),
       _unitsRepo = unitsRepository ?? MetricUnitsRepository(),
       super(const SettingsState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    final theme = await _settingsRepo.getThemeMode();
    final altitude = await _unitsRepo.getAltitudeUnit();
    final speed = await _unitsRepo.getSpeedUnit();
    final time = await _unitsRepo.getTimeFormat();

    emit(
      SettingsState(
        themeMode: theme,
        altitudeUnit: _formatAltitude(altitude),
        speedUnit: _formatSpeed(speed),
        timeFormat: _formatTime(time),
        isLoading: false,
      ),
    );
  }

  Future<void> setTheme(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    await _settingsRepo.setThemeMode(mode);
  }

  Future<void> setAltitudeUnit(String unit) async {
    final enumUnit = unit == 'm' || unit == 'meter'
        ? AltitudeUnit.meter
        : AltitudeUnit.foot;
    emit(state.copyWith(altitudeUnit: unit));
    await _unitsRepo.setAltitudeUnit(enumUnit);
  }

  Future<void> setSpeedUnit(String unit) async {
    final enumUnit = unit == 'mph' ? SpeedUnit.mph : SpeedUnit.kmh;
    emit(state.copyWith(speedUnit: unit));
    await _unitsRepo.setSpeedUnit(enumUnit);
  }

  Future<void> setTimeFormat(String format) async {
    final enumFmt = format == '12h'
        ? TimeFormat.format12h
        : TimeFormat.format24h;
    emit(state.copyWith(timeFormat: format));
    await _unitsRepo.setTimeFormat(enumFmt);
  }

  String _formatAltitude(AltitudeUnit u) =>
      u == AltitudeUnit.meter ? 'm' : 'ft';
  String _formatSpeed(SpeedUnit u) => u == SpeedUnit.mph ? 'mph' : 'km/h';
  String _formatTime(TimeFormat t) => t == TimeFormat.format12h ? '12h' : '24h';
}
