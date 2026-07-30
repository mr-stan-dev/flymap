import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/ui/screens/settings/viewmodel/settings_cubit.dart';

/// Maps the persisted setting label ('°C' | '°F') to the unit enum. Shared by
/// the `watch`-based [TemperatureUnitContext] getter and any `read`-based call
/// site (event handlers, where `watch` is illegal).
TemperatureUnit temperatureUnitFromSetting(String label) =>
    label == '°F' ? TemperatureUnit.fahrenheit : TemperatureUnit.celsius;

extension TemperatureUnitContext on BuildContext {
  /// The user's selected temperature unit, read from the app-level
  /// [SettingsCubit] provided above the router.
  ///
  /// Uses `watch` so any temperature display rebuilds — and re-converts — the
  /// instant the setting changes. Falls back to Celsius when no [SettingsCubit]
  /// is in the tree (isolated widget tests, or any off-tree render) so a
  /// display preference can never crash a screen.
  TemperatureUnit get temperatureUnit {
    try {
      return temperatureUnitFromSetting(
        watch<SettingsCubit>().state.temperatureUnit,
      );
    } on ProviderNotFoundException {
      return TemperatureUnit.celsius;
    }
  }
}
