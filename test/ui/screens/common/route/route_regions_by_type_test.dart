import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/route_region.dart';
import 'package:flymap/domain/entity/route_region_type.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/common/route/route_regions_by_type.dart';
import 'package:flymap/ui/theme/app_theme.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('groups route regions by type and shows chips under each title', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        child: RouteRegionsByTypeSection(
          regions: [
            _region(
              qid: 'sea-1',
              name: 'North Sea',
              type: RouteRegionType.sea,
              pathKm: 20,
            ),
            _region(
              qid: 'sea-2',
              name: 'Baltic Sea',
              type: RouteRegionType.sea,
              pathKm: 35,
            ),
            _region(
              qid: 'country-fr',
              name: 'France',
              type: RouteRegionType.country,
              pathKm: 40,
            ),
          ],
          onOpenRegion: (_) {},
        ),
      ),
    );

    expect(find.text("You'll fly over 3 regions"), findsOneWidget);
    // Plural groups show a count; a single item is just its type label.
    expect(find.text('Seas · 2'), findsOneWidget);
    expect(find.text('Country'), findsOneWidget);
    expect(find.text('North Sea'), findsOneWidget);
    expect(find.text('Baltic Sea'), findsOneWidget);
    expect(find.text('France'), findsOneWidget);

    final seaTitleTop = tester.getTopLeft(find.text('Seas · 2')).dy;
    final countryTitleTop = tester.getTopLeft(find.text('Country')).dy;
    expect(seaTitleTop, lessThan(countryTitleTop));
  });

  testWidgets('shows premium upgrade hint for hidden route regions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        child: RouteRegionsByTypeSection(
          regions: [
            _region(
              qid: 'country-fr',
              name: 'France',
              type: RouteRegionType.country,
              pathKm: 40,
            ),
          ],
          hiddenRegions: [
            for (var i = 0; i < 4; i++)
              _region(
                qid: 'locked-country-$i',
                name: 'Hidden $i',
                type: RouteRegionType.country,
                pathKm: 100 + i * 10,
              ),
            _region(
              qid: 'locked-sea',
              name: 'Hidden Sea',
              type: RouteRegionType.sea,
              pathKm: 150,
            ),
          ],
          onPremiumGateTap: () {},
        ),
      ),
    );

    expect(find.text("You'll fly over 6 regions"), findsOneWidget);
    // 1 visible group header + 4 locked country teaser chips.
    expect(find.text('Country'), findsNWidgets(5));
    expect(find.text('Upgrade to Pro'), findsOneWidget);
    // Locked regions tease their type but never their name.
    expect(find.text('Sea'), findsOneWidget);
    expect(find.text('Hidden Sea'), findsNothing);
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(5));
    // Banner count matches the section title's route total, not just the
    // locked remainder.
    expect(
      find.text('Unlock all 6 regions on this route with Pro.'),
      findsOneWidget,
    );
  });
}

Widget _testApp({required Widget child}) {
  return TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: AppLocale.en.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(body: child),
    ),
  );
}

RouteRegion _region({
  required String qid,
  required String name,
  required RouteRegionType type,
  required double pathKm,
}) {
  return RouteRegion(
    qid: qid,
    name: name,
    regionType: type,
    pathFirstEncounterKm: pathKm,
    pathLengthInsideKm: 120,
    geometry: const RouteRegionGeometry(type: 'Polygon', geoJson: {}),
  );
}
