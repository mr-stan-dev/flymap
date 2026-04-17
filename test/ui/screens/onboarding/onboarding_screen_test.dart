import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/favorite_airports_repository.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:flymap/repository/recent_airports_repository.dart';
import 'package:flymap/repository/subscription_repository.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/subscription/subscription_product.dart';
import 'package:flymap/subscription/subscription_status.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/onboarding/onboarding_screen.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await GetIt.I.reset();
    GetIt.I.registerSingleton<OnboardingRepository>(OnboardingRepository());
    GetIt.I.registerSingleton<AirportsDatabase>(
      AirportsDatabase.test(seedAirports: _seedAirports),
    );
    GetIt.I.registerSingleton<FavoriteAirportsRepository>(
      FavoriteAirportsRepository(),
    );
    GetIt.I.registerSingleton<RecentAirportsRepository>(
      RecentAirportsRepository(),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('skip moves only one step and does not complete onboarding', (
    tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await _pumpUntilVisible(tester, find.text('Discover what’s below'));

    expect(find.text('Discover what’s below'), findsOneWidget);

    await tester.tap(find.widgetWithText(TertiaryButton, 'Skip'));
    await _pumpUntilVisible(tester, find.text('How often do you fly?'));

    expect(find.text('How often do you fly?'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding.seen'), isNot(true));
  });

  testWidgets('frequency step blocks continue until user selects a value', (
    tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await _pumpUntilVisible(tester, find.text('Discover what’s below'));

    await tester.tap(find.widgetWithText(TertiaryButton, 'Skip'));
    await _pumpUntilVisible(tester, find.text('How often do you fly?'));

    expect(find.text('How often do you fly?'), findsOneWidget);

    await tester.tap(find.widgetWithText(PrimaryButton, 'Continue'));
    await _pumpUntilVisible(tester, find.text('How often do you fly?'));

    expect(find.text('How often do you fly?'), findsOneWidget);

    await tester.tap(find.text('This is my first flight'));
    await _pumpUi(tester);

    await tester.tap(find.widgetWithText(PrimaryButton, 'Continue'));
    await _pumpUntilVisible(tester, find.text('Set your home airport'));

    expect(find.text('Set your home airport'), findsOneWidget);
  });

  testWidgets('final CTA completes onboarding and routes to flight search', (
    tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await _pumpUntilVisible(tester, find.text('Discover what’s below'));

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.widgetWithText(TertiaryButton, 'Skip'));
      await _pumpUi(tester);
    }

    await _pumpUntilVisible(tester, find.text('Get more from every flight'));

    await tester.tap(
      find.widgetWithText(PrimaryButton, 'Start my first flight'),
    );
    await _pumpUntilVisible(tester, find.text('Flight search screen'));

    expect(find.text('Flight search screen'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding.seen'), isTrue);
  });
}

Widget _buildTestApp() {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const OnboardingScreen()),
      GoRoute(
        path: '/flight-search',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Flight search screen'))),
      ),
    ],
  );

  return TranslationProvider(
    child: BlocProvider(
      create: (_) => SubscriptionCubit(
        repository: _FakeSubscriptionRepository(),
        analytics: const _FakeAppAnalytics(),
      ),
      child: MaterialApp.router(
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: router,
      ),
    ),
  );
}

Future<void> _pumpUntilVisible(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 120; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
}

Future<void> _pumpUi(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  _FakeSubscriptionRepository()
    : _currentStatus = SubscriptionStatus(
        isPro: false,
        entitlementId: 'pro',
        lastUpdatedAt: DateTime.now(),
      );

  final SubscriptionStatus _currentStatus;

  @override
  SubscriptionStatus get currentStatus => _currentStatus;

  @override
  Stream<SubscriptionStatus> get statusStream => const Stream.empty();

  @override
  Future<SubscriptionStatus> initialize() async => _currentStatus;

  @override
  Future<SubscriptionStatus> refresh() async => _currentStatus;

  @override
  Future<SubscriptionStatus> restorePurchases() async => _currentStatus;

  @override
  Future<List<SubscriptionProduct>> getProducts() async =>
      const <SubscriptionProduct>[];

  @override
  Future<SubscriptionStatus> purchasePackage({
    required String packageId,
  }) async {
    return _currentStatus;
  }

  @override
  Future<SubscriptionPaywallResult> presentPaywallIfNeeded() async {
    return SubscriptionPaywallResult.cancelled;
  }

  @override
  Future<void> presentCustomerCenter() async {}

  @override
  Future<void> close() async {}
}

class _FakeAppAnalytics implements AppAnalytics {
  const _FakeAppAnalytics();

  @override
  Future<void> log(AnalyticsEvent event) async {}

  @override
  Future<void> setGlobalContext({
    required String appVersion,
    required String buildNumber,
    required String platform,
    required String appEnv,
  }) async {}

  @override
  Future<void> setSubscriptionContext({required bool isPro}) async {}
}

final _seedAirports = <Airport>[
  _airport(
    name: 'London Heathrow Airport',
    city: 'London',
    iata: 'LHR',
    icao: 'EGLL',
  ),
  _airport(
    name: 'Charles de Gaulle International Airport',
    city: 'Paris',
    iata: 'CDG',
    icao: 'LFPG',
  ),
  _airport(
    name: 'Amsterdam Airport Schiphol',
    city: 'Amsterdam',
    iata: 'AMS',
    icao: 'EHAM',
  ),
];

Airport _airport({
  required String name,
  required String city,
  required String iata,
  required String icao,
}) {
  return Airport(
    name: name,
    city: city,
    countryCode: 'XX',
    latLon: const LatLng(0, 0),
    iataCode: iata,
    icaoCode: icao,
    wikipediaUrl: '',
  );
}
