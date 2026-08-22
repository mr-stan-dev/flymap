import 'package:flutter/material.dart';

class DsPremiumColors {
  const DsPremiumColors._();

  /// High-emphasis gold surfaces such as premium CTAs and compact badges.
  static const Color goldFill = Color(0xFFF6C453);
  static const Color goldHighlight = Color(0xFFFFD97A);
  static const Color onGold = Color(0xFF2A210F);

  /// Theme-adjusted accent used for premium icons and text.
  static const Color lightAccent = Color(0xFF8A5600);
  static const Color darkAccent = Color(0xFFFFD36A);

  /// Low-emphasis premium surfaces keep gold out of large background areas.
  static const Color lightSurface = Color(0xFFFFF8E8);
  static const Color darkSurface = Color(0xFF1D2637);
  static const Color lightBorder = Color(0xFFF2D18B);
  static const Color darkBorder = Color(0xFF6E5727);
  static const Color lightIconSurface = Color(0xFFFFF0C2);
  static const Color darkIconSurface = Color(0xFF332D20);

  /// Large premium surfaces use a navy foundation with gold as an accent.
  static const List<Color> lightHeroGradient = <Color>[
    Color(0xFF14233A),
    Color(0xFF1F3A5A),
    Color(0xFF284F73),
  ];
  static const List<Color> darkHeroGradient = <Color>[
    Color(0xFF0C1728),
    Color(0xFF12223A),
    Color(0xFF192A43),
  ];

  static Color accent(BuildContext context) =>
      accentFor(Theme.of(context).brightness);

  static Color accentFor(Brightness brightness) =>
      brightness == Brightness.light ? lightAccent : darkAccent;

  static Color subtleSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? lightSurface
      : darkSurface;

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? lightBorder
      : darkBorder;

  static Color iconSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? lightIconSurface
      : darkIconSurface;

  static List<Color> heroGradientFor(Brightness brightness) =>
      brightness == Brightness.light ? lightHeroGradient : darkHeroGradient;
}
