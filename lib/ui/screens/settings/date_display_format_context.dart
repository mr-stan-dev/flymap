import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/ui/screens/settings/viewmodel/settings_cubit.dart';

/// Maps the persisted setting label ('MM/DD/YYYY' | 'DD/MM/YYYY') to the enum.
/// Shared by the `watch`-based [DateDisplayFormatContext] getter and any
/// `read`-based call site (event handlers, where `watch` is illegal).
DateDisplayFormat dateDisplayFormatFromSetting(String label) =>
    label == 'DD/MM/YYYY' ? DateDisplayFormat.international : DateDisplayFormat.us;

extension DateDisplayFormatContext on BuildContext {
  /// The user's selected date display format, read from the app-level
  /// [SettingsCubit] provided above the router.
  ///
  /// Uses `watch` so any date display rebuilds — and re-orders — the instant
  /// the setting changes. Falls back to US when no [SettingsCubit] is in the
  /// tree (isolated widget tests, or any off-tree render) so a display
  /// preference can never crash a screen.
  DateDisplayFormat get dateDisplayFormat {
    try {
      return dateDisplayFormatFromSetting(
        watch<SettingsCubit>().state.dateDisplayFormat,
      );
    } on ProviderNotFoundException {
      return DateDisplayFormat.us;
    }
  }
}
