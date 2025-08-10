import 'package:flymap/ui/theme/app_colours.dart';
import 'package:flutter/material.dart';

class AppColourTheme extends ThemeExtension<AppColourTheme> {
  const AppColourTheme({
    required this.accentGreen,
    required this.accentYellow,
    required this.brandGreen1,
    required this.brandGreen2,
    required this.brandBlack,
    required this.brandWhite,
    required this.backgroundPrimary,
    required this.backgroundSecondary,
    required this.backgroundTertiary,
    required this.textPrimary,
    required this.textSecondary,
    required this.successPrimary,
    required this.infoPrimary,
    required this.errorPrimary,
    required this.warningPrimary,
  });

  // Accent Colors
  final Color accentGreen;
  final Color accentYellow;

  // Brand Colors
  final Color brandGreen1;
  final Color brandGreen2;
  final Color brandBlack;
  final Color brandWhite;

  // Background
  final Color backgroundPrimary;
  final Color backgroundSecondary;
  final Color backgroundTertiary;

  // Text Colors
  final Color textPrimary;
  final Color textSecondary;

  // Semantics
  final Color successPrimary;
  final Color errorPrimary;
  final Color warningPrimary;
  final Color infoPrimary;

  static const dark = AppColourTheme(
    accentGreen: AppColoursCommon.accentBlue,
    accentYellow: AppColoursCommon.accentYellow,
    brandGreen1: AppColoursCommon.brandBlue,
    brandGreen2: AppColoursCommon.brandBlueAccent,
    brandBlack: AppColoursCommon.brandBlack,
    brandWhite: AppColoursCommon.brandWhite,
    backgroundPrimary: AppColoursDark.backgroundPrimary,
    backgroundSecondary: AppColoursDark.backgroundSecondary,
    backgroundTertiary: AppColoursDark.backgroundTertiary,
    textPrimary: AppColoursDark.textPrimary,
    textSecondary: AppColoursDark.textSecondary,
    successPrimary: AppColoursCommon.success,
    infoPrimary: AppColoursCommon.info,
    errorPrimary: AppColoursCommon.error,
    warningPrimary: AppColoursCommon.warning,
  );

  static const light = AppColourTheme(
    accentGreen: AppColoursCommon.accentBlue,
    accentYellow: AppColoursCommon.accentYellow,
    brandGreen1: AppColoursCommon.brandBlue,
    brandGreen2: AppColoursCommon.brandBlueAccent,
    brandBlack: AppColoursCommon.brandBlack,
    brandWhite: AppColoursCommon.brandWhite,
    backgroundPrimary: AppColoursLight.backgroundPrimary,
    backgroundSecondary: AppColoursLight.backgroundSecondary,
    backgroundTertiary: AppColoursLight.backgroundTertiary,
    textPrimary: AppColoursLight.textPrimary,
    textSecondary: AppColoursLight.textSecondary,
    successPrimary: AppColoursCommon.success,
    infoPrimary: AppColoursCommon.info,
    errorPrimary: AppColoursCommon.error,
    warningPrimary: AppColoursCommon.warning,
  );

  @override
  AppColourTheme copyWith({
    Color? backgroundPrimary,
    Color? backgroundSecondary,
    Color? backgroundTertiary,
    Color? accentGreen,
    Color? accentYellow,
    Color? brand1,
    Color? brand2,
    Color? brandBlack,
    Color? brandWhite,
    Color? onButtonColorSecondary,
    Color? onButtonColorTertiary,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textAccent,
    Color? linkTextPrimary,
    Color? primaryButtonDefault,
    Color? primaryButtonHover,
    Color? primaryButtonDisabled,
    Color? onPrimaryButtonDefault,
    Color? onPrimaryButtonHover,
    Color? onPrimaryButtonDisabled,
    Color? iconSurfaceDefault,
    Color? iconSurfaceHover,
    Color? iconSurfaceDisabled,
    Color? iconSurfaceAccent,
    Color? iconDefault,
    Color? iconHover,
    Color? successPrimary,
    Color? infoPrimary,
    Color? errorPrimary,
    Color? warningPrimary,
  }) {
    return AppColourTheme(
      accentGreen: accentGreen ?? this.accentGreen,
      accentYellow: accentYellow ?? this.accentYellow,
      brandGreen1: brand1 ?? brandGreen1,
      brandGreen2: brand2 ?? brandGreen2,
      brandBlack: brandBlack ?? this.brandBlack,
      brandWhite: brandWhite ?? this.brandWhite,
      backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      backgroundTertiary: backgroundTertiary ?? this.backgroundTertiary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      successPrimary: successPrimary ?? this.successPrimary,
      infoPrimary: infoPrimary ?? this.infoPrimary,
      errorPrimary: errorPrimary ?? this.errorPrimary,
      warningPrimary: warningPrimary ?? this.warningPrimary,
    );
  }

  @override
  AppColourTheme lerp(ThemeExtension<AppColourTheme>? other, double t) {
    if (other is! AppColourTheme) {
      return this;
    }
    return AppColourTheme(
      accentGreen: Color.lerp(accentGreen, other.accentGreen, t)!,
      accentYellow: Color.lerp(accentYellow, other.accentYellow, t)!,
      brandGreen1: Color.lerp(brandGreen1, other.brandGreen1, t)!,
      brandGreen2: Color.lerp(brandGreen2, other.brandGreen2, t)!,
      brandBlack: Color.lerp(brandBlack, other.brandBlack, t)!,
      brandWhite: Color.lerp(brandWhite, other.brandWhite, t)!,
      backgroundPrimary: Color.lerp(
        backgroundPrimary,
        other.backgroundPrimary,
        t,
      )!,
      backgroundSecondary: Color.lerp(
        backgroundSecondary,
        other.backgroundSecondary,
        t,
      )!,
      backgroundTertiary: Color.lerp(
        backgroundTertiary,
        other.backgroundTertiary,
        t,
      )!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      successPrimary: Color.lerp(successPrimary, other.successPrimary, t)!,
      infoPrimary: Color.lerp(infoPrimary, other.infoPrimary, t)!,
      errorPrimary: Color.lerp(errorPrimary, other.errorPrimary, t)!,
      warningPrimary: Color.lerp(warningPrimary, other.warningPrimary, t)!,
    );
  }
}
