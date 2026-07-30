import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/flight_unlock_repository.dart';
import 'package:flymap/repository/favorite_airports_repository.dart';
import 'package:flymap/repository/feature_announcement_repository.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:flymap/repository/recent_airports_repository.dart';
import 'package:flymap/repository/subscription_repository.dart';
import 'package:flymap/repository/user_flight_prefs_storage.dart';
import 'package:flymap/subscription/flight_unlock_product.dart';
import 'package:flymap/subscription/flight_unlock_purchase_result.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/subscription/subscription_product.dart';
import 'package:flymap/subscription/subscription_status.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/create_flight/route_type_selector/route_type_selector_screen.dart';
import 'package:flymap/ui/screens/onboarding/onboarding_screen.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/theme/app_theme.dart';
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
    GetIt.I.registerSingleton<OnboardingRepository>(
      OnboardingRepository(prefsStorage: UserFlightPrefsStorage()),
    );
    GetIt.I.registerSingleton<FeatureAnnouncementRepository>(
      FeatureAnnouncementRepository(
        onboarding: GetIt.I.get<OnboardingRepository>(),
      ),
    );
    GetIt.I.registerSingleton<AppAnalytics>(const _FakeAppAnalytics());
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
    await _pumpUntilVisible(
      tester,
      find.text('Which places do you want to see more of on your map?'),
    );

    expect(
      find.text('Which places do you want to see more of on your map?'),
      findsOneWidget,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding.seen'), isNot(true));
  });

  testWidgets(
    'home airport step blocks continue and offers no skip',
    (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await _pumpUntilVisible(tester, find.text('Discover what’s below'));

      await tester.tap(find.widgetWithText(TertiaryButton, 'Skip'));
      await _pumpUi(tester);
      await tester.tap(find.widgetWithText(TertiaryButton, 'Skip'));
      await _pumpUntilVisible(tester, find.text('Set your home airport'));

      expect(find.text('Set your home airport'), findsOneWidget);
      // The airport is required: no Skip on this step.
      expect(find.widgetWithText(TertiaryButton, 'Skip'), findsNothing);

      await tester.tap(
        find.widgetWithText(PrimaryButton, 'Continue'),
        warnIfMissed: false,
      );
      await _pumpUi(tester);

      expect(find.text('Set your home airport'), findsOneWidget);
    },
  );

  testWidgets(
    'selecting a popular airport shows no not-found message and unlocks continue',
    (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await _pumpUntilVisible(tester, find.text('Discover what’s below'));

      await tester.tap(find.widgetWithText(TertiaryButton, 'Skip'));
      await _pumpUi(tester);
      await tester.tap(find.widgetWithText(TertiaryButton, 'Skip'));
      await _pumpUntilVisible(tester, find.text('Set your home airport'));

      await tester.tap(find.textContaining('London Heathrow').first);
      await _pumpUi(tester);

      // Selection fills the query and clears results; this must not render
      // as a failed search.
      expect(find.text('No airports found for that search.'), findsNothing);

      await tester.tap(find.widgetWithText(PrimaryButton, 'Continue'));
      await _pumpUntilVisible(tester, find.text("Stop missing what's below"));

      expect(find.text("Stop missing what's below"), findsOneWidget);

      // Let the payoff grace timer elapse so no timer is pending at teardown.
      await tester.pump(const Duration(seconds: 4));
    },
  );

  testWidgets(
    'final CTA completes onboarding and route selector back returns home',
    (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await _pumpUntilVisible(tester, find.text('Discover what’s below'));

      for (var i = 0; i < 2; i++) {
        await tester.tap(find.widgetWithText(TertiaryButton, 'Skip'));
        await _pumpUi(tester);
      }

      // The home airport is mandatory now; select one to reach the payoff.
      await _pumpUntilVisible(tester, find.text('Set your home airport'));
      await tester.tap(find.textContaining('London Heathrow').first);
      await _pumpUi(tester);
      await tester.tap(find.widgetWithText(PrimaryButton, 'Continue'));

      // Area payoff continues into the weather payoff — the last step,
      // whose CTA presents the paywall (the fake repository reports it as
      // cancelled) and finishes onboarding.
      await _pumpUntilVisible(tester, find.text("Stop missing what's below"));
      await tester.tap(find.widgetWithText(PrimaryButton, 'Continue'));
      await _pumpUntilVisible(
        tester,
        find.text('Check the weather for your flight'),
      );

      await tester.tap(
        find.widgetWithText(PrimaryButton, 'Start my first flight'),
      );
      await _pumpUntilVisible(tester, find.text('New flight'));

      expect(find.text('New flight'), findsOneWidget);
      expect(
        tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
        isFalse,
      );

      await tester.tap(find.byIcon(Icons.arrow_back));
      await _pumpUntilVisible(tester, find.text('Home screen'));

      expect(find.text('Home screen'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding.seen'), isTrue);
      expect(
        prefs.getBool(
          FeatureAnnouncementRepository.seenKey(
            FeatureAnnouncement.geoQuizLearn,
          ),
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'Android skips the onboarding paywall and lands on the flight selector',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final repo = _FakeSubscriptionRepository();

        await tester.pumpWidget(_buildTestApp(subscriptionRepository: repo));
        await _completeOnboardingToFirstFlight(tester);

        expect(find.text('New flight'), findsOneWidget);
        expect(repo.paywallPresentedCount, 0);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'iOS still presents the onboarding paywall before the flight selector',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        final repo = _FakeSubscriptionRepository();

        await tester.pumpWidget(_buildTestApp(subscriptionRepository: repo));
        await _completeOnboardingToFirstFlight(tester);

        expect(find.text('New flight'), findsOneWidget);
        expect(repo.paywallPresentedCount, 1);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}

/// Walks the onboarding flow from the welcome step to tapping the final
/// "Start my first flight" CTA and waiting for the route selector.
Future<void> _completeOnboardingToFirstFlight(WidgetTester tester) async {
  await _pumpUntilVisible(tester, find.text('Discover what’s below'));
  for (var i = 0; i < 2; i++) {
    await tester.tap(find.widgetWithText(TertiaryButton, 'Skip'));
    await _pumpUi(tester);
  }
  await _pumpUntilVisible(tester, find.text('Set your home airport'));
  await tester.tap(find.textContaining('London Heathrow').first);
  await _pumpUi(tester);
  await tester.tap(find.widgetWithText(PrimaryButton, 'Continue'));
  await _pumpUntilVisible(tester, find.text("Stop missing what's below"));
  await tester.tap(find.widgetWithText(PrimaryButton, 'Continue'));
  await _pumpUntilVisible(
    tester,
    find.text('Check the weather for your flight'),
  );
  await tester.tap(find.widgetWithText(PrimaryButton, 'Start my first flight'));
  await _pumpUntilVisible(tester, find.text('New flight'));
}

Widget _buildTestApp({_FakeSubscriptionRepository? subscriptionRepository}) {
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Home screen'))),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/flight-search',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Flight search screen'))),
      ),
      GoRoute(
        path: '/route-type-selector',
        builder: (context, state) => const FlightRouteTypeSelector(),
      ),
    ],
  );

  return TranslationProvider(
    child: BlocProvider(
      create: (_) => SubscriptionCubit(
        repository: subscriptionRepository ?? _FakeSubscriptionRepository(),
        flightUnlockRepository: _FakeFlightUnlockRepository(),
        analytics: const _FakeAppAnalytics(),
      ),
      child: MaterialApp.router(
        locale: AppLocale.en.flutterLocale,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
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

  /// How many times a paywall was presented — lets the platform tests assert
  /// Android never shows one while iOS does.
  int paywallPresentedCount = 0;

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
    paywallPresentedCount += 1;
    return SubscriptionPaywallResult.cancelled;
  }

  @override
  Future<void> presentCustomerCenter() async {}

  @override
  Future<void> close() async {}
}

class _FakeFlightUnlockRepository implements FlightUnlockRepository {
  @override
  Stream<int> get balanceStream => const Stream<int>.empty();

  @override
  int get currentUnusedUnlockCount => 0;

  @override
  Future<void> close() async {}

  @override
  Future<int> consumeUnlock() async => 0;

  @override
  Future<FlightUnlockProduct?> getUnlockProduct() async => null;

  @override
  Future<int> initialize() async => 0;

  @override
  Future<FlightUnlockPurchaseResult> purchaseUnlock() async =>
      const FlightUnlockPurchaseResult.cancelled();

  @override
  Future<int> restoreUnlock() async => 0;
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
