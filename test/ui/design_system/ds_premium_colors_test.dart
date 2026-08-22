import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/widgets/premium_surface_effects.dart';

void main() {
  test('premium foreground pairs meet WCAG AA contrast', () {
    expect(
      _contrast(DsPremiumColors.goldFill, DsPremiumColors.onGold),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(DsPremiumColors.lightSurface, DsPremiumColors.lightAccent),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(DsPremiumColors.darkSurface, DsPremiumColors.darkAccent),
      greaterThanOrEqualTo(4.5),
    );
    for (final color in <Color>[
      ...DsPremiumColors.lightHeroGradient,
      ...DsPremiumColors.darkHeroGradient,
    ]) {
      expect(_contrast(color, Colors.white), greaterThanOrEqualTo(4.5));
    }
  });

  testWidgets('premium roles resolve separately for light and dark themes', (
    tester,
  ) async {
    Future<Map<String, Color>> resolve(Brightness brightness) async {
      late Map<String, Color> colors;
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey<Brightness>(brightness),
          theme: ThemeData(brightness: brightness),
          themeAnimationDuration: Duration.zero,
          home: Builder(
            builder: (context) {
              colors = <String, Color>{
                'accent': DsPremiumColors.accent(context),
                'surface': DsPremiumColors.subtleSurface(context),
                'border': DsPremiumColors.border(context),
                'iconSurface': DsPremiumColors.iconSurface(context),
              };
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return colors;
    }

    expect(await resolve(Brightness.light), <String, Color>{
      'accent': DsPremiumColors.lightAccent,
      'surface': DsPremiumColors.lightSurface,
      'border': DsPremiumColors.lightBorder,
      'iconSurface': DsPremiumColors.lightIconSurface,
    });
    expect(await resolve(Brightness.dark), <String, Color>{
      'accent': DsPremiumColors.darkAccent,
      'surface': DsPremiumColors.darkSurface,
      'border': DsPremiumColors.darkBorder,
      'iconSurface': DsPremiumColors.darkIconSurface,
    });
  });

  test('subscription hero is light only in light theme', () {
    final light = PremiumSurfaceGradients.membershipHero(isLightTheme: true);
    final dark = PremiumSurfaceGradients.membershipHero(isLightTheme: false);

    expect(light.every((color) => color.computeLuminance() > 0.9), isTrue);
    expect(dark.every((color) => color.computeLuminance() < 0.1), isTrue);
  });
}

double _contrast(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
