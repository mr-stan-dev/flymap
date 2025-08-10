import 'package:flymap/ui/theme/app_colour_theme.dart';
import 'package:flymap/ui/theme/app_text_theme.dart';
import 'package:flutter/material.dart';

extension AppThemeExt on BuildContext {
  AppColourTheme get colorTheme => Theme.of(this).extension<AppColourTheme>()!;

  AppTextTheme get textTheme => Theme.of(this).extension<AppTextTheme>()!;
}
