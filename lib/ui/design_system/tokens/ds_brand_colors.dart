import 'package:flutter/material.dart';

class DsPremiumColors {
  const DsPremiumColors._();

  /// High-emphasis premium colors.
  static const Color amber = Color(0xFFFFBF00);
  static const Color darkAmber = Color(0xFFD59000);
  static const Color onAmber = Color(0xFF2A210F);
  static const Color onDarkAmber = Colors.white;

  /// Theme-adjusted accent used for premium icons and text.
  static const Color lightAccent = Color(0xFF8A5600);
  static const Color darkAccent = darkAmber;

  /// Low-emphasis premium surfaces keep amber out of large background areas.
  static const Color lightSurface = Color(0xFFFFF6E5);
  static const Color darkSurface = Color(0xFF1D2637);
  static const Color lightBorder = Color(0xFFD9A24A);
  static const Color darkBorder = Color(0xFF765321);
  static const Color lightIconSurface = Color(0xFFF6E2BE);
  static const Color darkIconSurface = Color(0xFF342A1C);

  /// Large premium surfaces use a navy foundation with amber as an accent.
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

  static Color fill(BuildContext context) =>
      fillFor(Theme.of(context).brightness);

  /// Premium buttons and badges use the original dark amber in both themes.
  static Color fillFor(Brightness brightness) => darkAmber;

  static Color foreground(BuildContext context) =>
      foregroundFor(Theme.of(context).brightness);

  static Color foregroundFor(Brightness brightness) => onDarkAmber;

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

  static List<Color> activeCardGradient(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return theme.brightness == Brightness.light
        ? <Color>[
            colorScheme.surface,
            Color.alphaBlend(
              amber.withValues(alpha: 0.055),
              colorScheme.surface,
            ),
          ]
        : <Color>[
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
            darkSurface,
          ];
  }

  static Color activeCardIconSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? amber.withValues(alpha: 0.24)
      : darkIconSurface;

  static Color? activeCardIconBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? amber.withValues(alpha: 0.58)
      : null;

  static Color activeCardPillSurface(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.light
        ? amber.withValues(alpha: 0.12)
        : theme.colorScheme.surface.withValues(alpha: 0.72);
  }

  static Color activeCardPillBorder(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.light
        ? lightAccent.withValues(alpha: 0.24)
        : theme.colorScheme.outline.withValues(alpha: 0.2);
  }

  static Color? activeCardPillForeground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light ? lightAccent : null;

  static List<Color> heroGradientFor(Brightness brightness) =>
      brightness == Brightness.light ? lightHeroGradient : darkHeroGradient;
}
