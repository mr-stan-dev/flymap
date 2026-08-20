import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/flight_download_completion.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('shows the flight video action without a new badge', (
    tester,
  ) async {
    var openedFlight = false;
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          locale: AppLocale.en.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: FlightDownloadCompletion(
              onOpenFlightPressed: () => openedFlight = true,
              onHomePressed: () {},
              onSharePressed: () {},
              onShareVideoPressed: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Open flight'), findsOneWidget);
    expect(find.byIcon(Icons.map_rounded), findsOneWidget);
    expect(find.text('Share flight video'), findsOneWidget);
    expect(find.byIcon(Icons.movie_creation_rounded), findsOneWidget);
    expect(find.text('NEW'), findsNothing);

    await tester.tap(find.text('Open flight'));
    expect(openedFlight, isTrue);
  });
}
