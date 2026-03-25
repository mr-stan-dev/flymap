import 'package:flutter/material.dart';
import 'package:flymap/ui/theme/app_colours.dart';

import 'app_colour_theme.dart';
import 'app_text_theme.dart';

/// App theme configuration
class AppTheme {
  /// Dark theme for the app
  static ThemeData get darkTheme {
    final base = ColorScheme.fromSeed(
      seedColor: AppColoursCommon.accentBlue,
      // green seed to avoid blue defaults
      brightness: Brightness.dark,
    );
    final scheme = base.copyWith(
      primary: AppColoursCommon.brandBlue,
      onPrimary: AppColoursCommon.brandWhite,
      surface: AppColoursDark.backgroundTertiary,
      secondary: AppColoursCommon.accentYellow,
      tertiary: AppColoursCommon.info,
      onSurface: AppColoursDark.textPrimary,
      onSurfaceVariant: AppColoursDark.textSecondary,
      error: AppColoursCommon.error,
    );
    final colourExtension = AppColourTheme(
      accentGreen: scheme.primary,
      accentYellow: scheme.secondary,
      brandBlue: AppColoursCommon.brandBlue,
      brandBlack: AppColoursCommon.brandBlack,
      brandWhite: AppColoursCommon.brandWhite,
      backgroundPrimary: AppColoursDark.backgroundPrimary,
      backgroundSecondary: AppColoursDark.backgroundSecondary,
      backgroundTertiary: scheme.surface,
      textPrimary: scheme.onSurface,
      textSecondary: scheme.onSurfaceVariant,
      successPrimary: AppColoursCommon.success,
      infoPrimary: scheme.tertiary,
      errorPrimary: scheme.error,
      warningPrimary: scheme.secondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColoursDark.backgroundPrimary,
      extensions: <ThemeExtension<dynamic>>[
        colourExtension,
        AppTextTheme.textTheme,
      ],
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColoursDark.backgroundSecondary,
        foregroundColor: AppColoursDark.textPrimary,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: AppColoursDark.backgroundTertiary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColoursDark.backgroundTertiary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        labelStyle: TextStyle(color: scheme.onSurface),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          foregroundColor: scheme.primary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        extendedTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primary,
        labelStyle: TextStyle(color: scheme.onSurface),
        shape: const StadiumBorder(),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        textStyle: TextStyle(color: scheme.onSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.6),
        indicatorColor: scheme.primary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(color: scheme.onSurface),
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
      dividerTheme: DividerThemeData(
        color: scheme.onSurface.withValues(alpha: 0.12),
        thickness: 1,
      ),
    );
  }

  /// Light theme for the app
  static ThemeData get lightTheme {
    final base = ColorScheme.fromSeed(
      primary: AppColoursCommon.accentBlue,
      seedColor: AppColoursCommon.accentBlue,
      brightness: Brightness.light,
    );
    final scheme = base.copyWith(
      primary: AppColoursCommon.brandBlue,
      onPrimary: AppColoursCommon.brandWhite,
      surface: AppColoursLight.backgroundTertiary,
      secondary: AppColoursCommon.accentYellow,
      tertiary: AppColoursCommon.info,
      onSurface: AppColoursLight.textPrimary,
      onSurfaceVariant: AppColoursLight.textSecondary,
      error: AppColoursCommon.error,
    );
    final colourExtension = AppColourTheme(
      accentGreen: scheme.primary,
      accentYellow: scheme.secondary,
      brandBlue: AppColoursCommon.brandBlue,
      brandBlack: AppColoursCommon.brandBlack,
      brandWhite: AppColoursCommon.brandWhite,
      backgroundPrimary: AppColoursLight.backgroundPrimary,
      backgroundSecondary: AppColoursLight.backgroundSecondary,
      backgroundTertiary: scheme.surface,
      textPrimary: scheme.onSurface,
      textSecondary: scheme.onSurfaceVariant,
      successPrimary: AppColoursCommon.success,
      infoPrimary: scheme.tertiary,
      errorPrimary: scheme.error,
      warningPrimary: scheme.secondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColoursLight.backgroundPrimary,
      extensions: <ThemeExtension<dynamic>>[
        colourExtension,
        AppTextTheme.textTheme,
      ],
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColoursLight.backgroundSecondary,
        foregroundColor: AppColoursLight.textPrimary,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: AppColoursLight.backgroundTertiary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        labelStyle: TextStyle(color: scheme.onSurface),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          foregroundColor: scheme.primary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        extendedTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primary,
        labelStyle: TextStyle(color: scheme.onSurface),
        shape: const StadiumBorder(),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        textStyle: TextStyle(color: scheme.onSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.6),
        indicatorColor: scheme.primary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(color: scheme.onSurface),
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
      dividerTheme: DividerThemeData(
        color: scheme.onSurface.withValues(alpha: 0.12),
        thickness: 1,
      ),
    );
  }
}
