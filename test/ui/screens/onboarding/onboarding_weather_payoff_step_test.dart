import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/onboarding/steps/onboarding_weather_payoff_step.dart';

Widget _app() {
  return TranslationProvider(
    child: MaterialApp(
      locale: AppLocale.en.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const Scaffold(body: OnboardingWeatherPayoffStep()),
    ),
  );
}

Finder _mapAsset(String name) => find.byWidgetPredicate(
  (widget) =>
      widget is Image &&
      widget.image is AssetImage &&
      (widget.image as AssetImage).assetName.contains(name),
);

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('renders the demo as a labeled example with route chips', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    // Let the canned cloud fields build and the plane fly a while — the
    // animation chain never settles, so bounded pumps only.
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(tester.takeException(), isNull);
    expect(find.text('Check the weather for your flight'), findsOneWidget);
    // Unmistakably an advertisement, not the user's flight.
    expect(find.text('EXAMPLE'), findsOneWidget);
    expect(find.text('LHR → FCO'), findsOneWidget);
    expect(find.text('LAX → JFK'), findsOneWidget);
    expect(find.text('BER → DXB'), findsOneWidget);
    expect(_mapAsset('lhr_fco'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('tapping a route chip switches the demo route', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 100));

    await tester.scrollUntilVisible(find.text('LAX → JFK'), 200);
    await tester.tap(find.text('LAX → JFK'));
    // Rebuild, run the switcher animations, then the removal frame.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(_mapAsset('lax_jfk'), findsOneWidget);
    expect(_mapAsset('lhr_fco'), findsNothing);
  });

  testWidgets('the next route rotates in only after the plane lands', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 100));

    // Mid-flight: still the first route.
    await tester.pump(const Duration(seconds: 5));
    expect(_mapAsset('lhr_fco'), findsOneWidget);

    // Past the 10s flight: landing turns the page to the next example.
    await tester.pump(const Duration(seconds: 5, milliseconds: 500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 50));

    expect(_mapAsset('lax_jfk'), findsOneWidget);
    expect(_mapAsset('lhr_fco'), findsNothing);
  });
}
