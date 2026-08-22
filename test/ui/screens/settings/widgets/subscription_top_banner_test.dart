import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/settings/widgets/subscription_top_banner.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_state.dart';
import 'package:flymap/ui/theme/app_theme.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('active Pro banner stays crisp in light theme', (tester) async {
    var manageTapCount = 0;
    await tester.pumpWidget(
      _testApp(onManage: () => manageTapCount += 1, themeMode: ThemeMode.light),
    );

    final ink = tester.widget<Ink>(
      find.byKey(const Key('settings-pro-active-banner-surface')),
    );
    final decoration = ink.decoration! as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;

    expect(gradient.colors.first, AppTheme.lightTheme.colorScheme.surface);
    expect(
      gradient.colors.every((color) => color.computeLuminance() > 0.9),
      isTrue,
    );
    expect(decoration.border, isNotNull);

    final manageText = tester.widget<Text>(find.text('Manage'));
    expect(manageText.style?.color, DsPremiumColors.lightAccent);

    await tester.tap(find.text('Flymap Pro Active'));
    await tester.pump();
    expect(manageTapCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active Pro banner retains its dark treatment', (tester) async {
    await tester.pumpWidget(
      _testApp(onManage: () {}, themeMode: ThemeMode.dark),
    );

    final ink = tester.widget<Ink>(
      find.byKey(const Key('settings-pro-active-banner-surface')),
    );
    final decoration = ink.decoration! as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;

    expect(gradient.colors.last, DsPremiumColors.darkSurface);
    expect(tester.takeException(), isNull);
  });
}

Widget _testApp({
  required VoidCallback onManage,
  required ThemeMode themeMode,
}) {
  return TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: AppLocale.en.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 390,
            child: SubscriptionTopBanner(
              state: const SubscriptionState(phase: SubscriptionPhase.pro),
              onManage: onManage,
            ),
          ),
        ),
      ),
    ),
  );
}
