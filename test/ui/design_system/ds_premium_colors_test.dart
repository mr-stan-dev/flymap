import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/widgets/premium_surface_effects.dart';
import 'package:flymap/ui/widgets/pro_widgets.dart';

void main() {
  test('premium high-emphasis colors use original dark amber', () {
    expect(
      DsPremiumColors.fillFor(Brightness.light),
      DsPremiumColors.darkAmber,
    );
    expect(DsPremiumColors.fillFor(Brightness.dark), DsPremiumColors.darkAmber);
    expect(
      DsPremiumColors.foregroundFor(Brightness.light),
      DsPremiumColors.onDarkAmber,
    );
    expect(
      DsPremiumColors.foregroundFor(Brightness.dark),
      DsPremiumColors.onDarkAmber,
    );
  });

  test('premium supporting foreground pairs meet WCAG AA contrast', () {
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
                'fill': DsPremiumColors.fill(context),
                'foreground': DsPremiumColors.foreground(context),
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
      'fill': DsPremiumColors.darkAmber,
      'foreground': DsPremiumColors.onDarkAmber,
      'accent': DsPremiumColors.lightAccent,
      'surface': DsPremiumColors.lightSurface,
      'border': DsPremiumColors.lightBorder,
      'iconSurface': DsPremiumColors.lightIconSurface,
    });
    expect(await resolve(Brightness.dark), <String, Color>{
      'fill': DsPremiumColors.darkAmber,
      'foreground': DsPremiumColors.onDarkAmber,
      'accent': DsPremiumColors.darkAccent,
      'surface': DsPremiumColors.darkSurface,
      'border': DsPremiumColors.darkBorder,
      'iconSurface': DsPremiumColors.darkIconSurface,
    });
  });

  testWidgets('premium app bar icon uses visible dark amber', (tester) async {
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
            appBar: AppBar(
              actions: const [
                ProAppBarInfoButton(
                  title: 'Pro',
                  message: 'Premium access',
                  tooltip: 'Pro access',
                ),
              ],
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(
        find.byIcon(Icons.workspace_premium_rounded),
      );
      expect(icon.color, DsPremiumColors.darkAmber);
    }
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
