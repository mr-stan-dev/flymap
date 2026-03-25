import 'package:flutter/material.dart';
import 'package:flymap/ui/theme/app_colour_theme.dart';

class DsSemanticColors {
  const DsSemanticColors._();

  static Color success(BuildContext context) {
    final extension = Theme.of(context).extension<AppColourTheme>();
    return extension?.successPrimary ?? Theme.of(context).colorScheme.primary;
  }

  static Color warning(BuildContext context) {
    final extension = Theme.of(context).extension<AppColourTheme>();
    return extension?.warningPrimary ?? Theme.of(context).colorScheme.secondary;
  }

  static Color info(BuildContext context) {
    final extension = Theme.of(context).extension<AppColourTheme>();
    return extension?.infoPrimary ?? Theme.of(context).colorScheme.tertiary;
  }

  static Color error(BuildContext context) {
    final extension = Theme.of(context).extension<AppColourTheme>();
    return extension?.errorPrimary ?? Theme.of(context).colorScheme.error;
  }
}
