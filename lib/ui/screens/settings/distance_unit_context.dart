import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/ui/screens/settings/viewmodel/settings_cubit.dart';

extension DistanceUnitContext on BuildContext {
  /// The user's selected distance unit, read from the app-level
  /// [SettingsCubit] provided above the router.
  ///
  /// Uses `watch` so any distance display rebuilds — and re-converts — the
  /// instant the setting changes, instead of only on the owning screen's
  /// next reload. Falls back to the default unit when no [SettingsCubit] is
  /// in the tree (isolated widget tests, or any off-tree render) so a
  /// display preference can never crash a screen.
  DistanceUnit get distanceUnit {
    try {
      final unit = watch<SettingsCubit>().state.distanceUnit;
      return unit == 'mi' ? DistanceUnit.mile : DistanceUnit.km;
    } on ProviderNotFoundException {
      return DistanceUnit.km;
    }
  }
}
