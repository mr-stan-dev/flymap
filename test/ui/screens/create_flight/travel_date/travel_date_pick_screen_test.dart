import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/create_flight/travel_date/travel_date_pick_screen.dart';
import 'package:latlong2/latlong.dart';

const _departure = Airport(
  name: 'Bristol',
  city: 'Bristol',
  countryCode: 'GB',
  latLon: LatLng(51.38, -2.72),
  iataCode: 'BRS',
  icaoCode: 'EGGD',
  wikipediaUrl: '',
);
const _arrival = Airport(
  name: 'Krakow',
  city: 'Krakow',
  countryCode: 'PL',
  latLon: LatLng(50.08, 19.78),
  iataCode: 'KRK',
  icaoCode: 'EPKK',
  wikipediaUrl: '',
);

Widget _app(TravelDatePickArgs args) {
  return TranslationProvider(
    child: MaterialApp(
      locale: AppLocale.en.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: TravelDatePickScreen(args: args),
    ),
  );
}

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('approximate flight shows all 7 days plus custom date at once', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const TravelDatePickArgs(departure: _departure, arrival: _arrival)),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);
    // All seven days render as a compact grid, custom-date row below.
    expect(find.byIcon(Icons.event_rounded), findsNWidgets(7));
    expect(find.byType(GridView), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Pick another date'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Pick another date'), findsOneWidget);
    // Continue stays disabled until an explicit choice; the dateless hatch
    // is always available.
    expect(find.text('Continue without a date'), findsOneWidget);
  });
}
