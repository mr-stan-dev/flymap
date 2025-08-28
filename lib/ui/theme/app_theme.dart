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
      background: AppColoursDark.backgroundPrimary,
      surface: AppColoursDark.backgroundTertiary,
      secondary: AppColoursCommon.accentYellow,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColoursDark.backgroundPrimary,
      extensions: const <ThemeExtension<dynamic>>[
        AppColourTheme.dark,
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
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        hintStyle: TextStyle(color: Colors.grey.shade400),
        labelStyle: TextStyle(color: scheme.onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
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
        unselectedLabelColor: scheme.onSurface.withOpacity(0.6),
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
        color: scheme.onSurface.withOpacity(0.12),
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
      background: AppColoursLight.backgroundPrimary,
      surface: AppColoursLight.backgroundTertiary,
      secondary: AppColoursCommon.accentYellow,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColoursLight.backgroundPrimary,
      extensions: const <ThemeExtension<dynamic>>[
        AppColourTheme.light,
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
        fillColor: const Color(0xFFF0F0F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        hintStyle: TextStyle(color: Colors.grey.shade600),
        labelStyle: TextStyle(color: scheme.onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColoursLight.backgroundQuaternary,
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
        unselectedLabelColor: scheme.onSurface.withOpacity(0.6),
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
        color: scheme.onSurface.withOpacity(0.12),
        thickness: 1,
      ),
    );
  }
}
