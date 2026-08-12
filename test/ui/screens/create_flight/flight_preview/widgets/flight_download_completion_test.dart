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
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          locale: AppLocale.en.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: FlightDownloadCompletion(
              onHomePressed: () {},
              onSharePressed: () {},
              onShareVideoPressed: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Share flight video'), findsOneWidget);
    expect(find.byIcon(Icons.movie_creation_rounded), findsOneWidget);
    expect(find.text('NEW'), findsNothing);
  });
}
