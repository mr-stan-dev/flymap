import 'package:flutter/material.dart';

class AppColoursCommon {
  static const brandBlue = Color(0xFF1565C0);
  static const brandBlack = Color(0xFF2A2A2A);
  static const brandWhite = Color(0xFFFFFFFF);
  static const brandTeal = Color(0xFF00838F);

  static const accentBlue = brandBlue;
  static const accentYellow = warning; // Use warning (amber) as yellow accent

  static const success = Color(0xFF00A512);
  static const warning = Color(0xFFFFA438);
  static const error = Color(0xFFF95959);
  static const info = Color(0xFF3F96FD);
}

class AppColoursDark {
  // Backgrounds tuned to match ThemeData.dark
  static const Color backgroundPrimary = Color(0xFF1C1C1C); // scaffold
  static const Color backgroundSecondary = Color(
    0xFF222222,
  ); // app bar / containers
  static const Color backgroundTertiary = Color(0xFF292929); // cards
  static const Color backgroundQuaternary = Color(0xFF3E3E3E);

  static const textPrimary = Color(0xFFE7E7E7);
  static const textSecondary = Color(0xFF9B9B9B);
}

class AppColoursLight {
  // Backgrounds tuned to match ThemeData.light
  static const Color backgroundPrimary = Color(0xFFF5F5F5); // scaffold
  static const Color backgroundSecondary = Color(
    0xFFFFFFFF,
  ); // app bar / containers
  static const Color backgroundTertiary = Color(0xFFFFFFFF); // cards
  static const Color backgroundQuaternary = Color(0xFFEFEFEF);

  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF616161);
}
