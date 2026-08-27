import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/flight_unlock_repository.dart';
import 'package:flymap/repository/subscription_repository.dart';
import 'package:flymap/subscription/flight_unlock_product.dart';
import 'package:flymap/subscription/flight_unlock_purchase_result.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/subscription/subscription_product.dart';
import 'package:flymap/subscription/subscription_status.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/subscription/subscription_management_screen.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_state.dart';
import 'package:flymap/ui/theme/app_theme.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('shows active Pro membership and the complete benefit set', (
    tester,
  ) async {
    final cubit = _TestSubscriptionCubit(
      SubscriptionState(
        phase: SubscriptionPhase.pro,
        status: SubscriptionStatus(
          isPro: true,
          entitlementId: 'Flymap Pro',
          productId: 'com.flymap.pro.yearly',
          expiresAt: DateTime(2026, 8, 26),
          lastUpdatedAt: DateTime(2026, 8, 17),
        ),
        products: const [
          SubscriptionProduct(
            packageId: 'yearly',
            productId: 'com.flymap.pro.yearly',
            title: 'Yearly',
            priceText: r'$39.99',
            subscriptionPeriod: 'P1Y',
          ),
        ],
      ),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_testApp(cubit));
    await tester.pump();

    expect(
      find.text('Your window-seat explorer, fully unlocked.'),
      findsOneWidget,
    );
    expect(find.textContaining('You’re on the'), findsNothing);
    final hero = find.byKey(const Key('subscription-pro-hero'));
    final heroTitle = tester.widget<Text>(
      find.descendant(of: hero, matching: find.text('Flymap Pro')),
    );
    expect(heroTitle.style?.fontWeight, FontWeight.w700);
    expect(
      tester
          .widget<Text>(find.text('Included with your Pro plan'))
          .style
          ?.fontWeight,
      FontWeight.w600,
    );
    expect(
      tester
          .widget<Text>(find.text('Recent real-world flight routes'))
          .style
          ?.fontWeight,
      FontWeight.w600,
    );
    final lightHeroDecoration =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const Key('subscription-pro-hero-background')),
                )
                .decoration
            as BoxDecoration;
    final lightHeroGradient = lightHeroDecoration.gradient! as LinearGradient;
    expect(lightHeroDecoration.borderRadius, BorderRadius.circular(DsRadii.xl));
    expect(
      lightHeroGradient.colors.every((color) => color.computeLuminance() > 0.9),
      isTrue,
    );
    expect(find.text('Included with your Pro plan'), findsOneWidget);
    expect(find.text('Complete offline stories'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Cloud cover and airport forecasts'),
      350,
    );
    expect(find.text('Cloud cover and airport forecasts'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('subscription-plan-row')),
      350,
    );
    final planValue = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('subscription-plan-row')),
        matching: find.text('Yearly plan'),
      ),
    );
    final planEnding = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('subscription-plan-row')),
        matching: find.text('Ends Aug 26, 2026'),
      ),
    );
    expect(planValue.style?.fontWeight, FontWeight.w700);
    expect(
      planEnding.style?.color,
      AppTheme.lightTheme.colorScheme.onSurfaceVariant,
    );
    await tester.scrollUntilVisible(find.text('Cancel subscription'), 450);
    expect(find.text('Manage plan & billing'), findsOneWidget);
    expect(find.text('Cancel subscription'), findsOneWidget);
    expect(find.textContaining('Before you cancel'), findsNothing);
  });

  testWidgets('renders the active membership in dark theme', (tester) async {
    final cubit = _TestSubscriptionCubit(
      SubscriptionState(
        phase: SubscriptionPhase.pro,
        status: SubscriptionStatus(
          isPro: true,
          entitlementId: 'Flymap Pro',
          productId: 'flymap_pro',
          productPlanId: 'weekly-base',
          expiresAt: DateTime(2026, 9, 21),
          lastUpdatedAt: DateTime(2026, 8, 17),
        ),
        products: const [
          SubscriptionProduct(
            packageId: 'monthly',
            productId: 'flymap_pro',
            productPlanId: 'monthly-base',
            title: 'Monthly',
            priceText: r'$4.99',
            subscriptionPeriod: 'P1M',
          ),
          SubscriptionProduct(
            packageId: 'weekly',
            productId: 'flymap_pro',
            productPlanId: 'weekly-base',
            title: 'Weekly',
            priceText: r'$1.99',
            subscriptionPeriod: 'P1W',
          ),
        ],
      ),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_testApp(cubit, themeMode: ThemeMode.dark));
    await tester.pump();

    expect(
      find.text('Your window-seat explorer, fully unlocked.'),
      findsOneWidget,
    );
    expect(find.textContaining('You’re on the'), findsNothing);
    final darkHeroDecoration =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const Key('subscription-pro-hero-background')),
                )
                .decoration
            as BoxDecoration;
    final darkHeroGradient = darkHeroDecoration.gradient! as LinearGradient;
    expect(
      darkHeroGradient.colors.every((color) => color.computeLuminance() < 0.1),
      isTrue,
    );
    expect(find.text('Included with your Pro plan'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('subscription-plan-row')),
      450,
    );
    expect(find.text('Weekly plan'), findsOneWidget);
    expect(find.text('Ends Sep 21, 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not guess the period when the active product is unknown', (
    tester,
  ) async {
    final cubit = _TestSubscriptionCubit(
      SubscriptionState(
        phase: SubscriptionPhase.pro,
        status: SubscriptionStatus(
          isPro: true,
          entitlementId: 'Flymap Pro',
          productId: 'legacy-yearly-offer',
          lastUpdatedAt: DateTime(2026, 8, 17),
        ),
        products: const [
          SubscriptionProduct(
            packageId: 'monthly',
            productId: 'current-product',
            title: 'Monthly',
            priceText: r'$4.99',
            subscriptionPeriod: 'P1M',
          ),
        ],
      ),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_testApp(cubit));
    await tester.pump();

    expect(find.textContaining('You’re on the'), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('subscription-plan-row')),
      450,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('subscription-plan-row')),
        matching: find.text('Flymap Pro'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the entitlement product period when offerings are empty', (
    tester,
  ) async {
    final cubit = _TestSubscriptionCubit(
      SubscriptionState(
        phase: SubscriptionPhase.pro,
        status: SubscriptionStatus(
          isPro: true,
          entitlementId: 'Flymap Pro',
          productId: 'pro_yearly_1',
          expiresAt: DateTime(2026, 8, 27),
          lastUpdatedAt: DateTime(2026, 8, 17),
        ),
      ),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_testApp(cubit));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byKey(const Key('subscription-plan-row')),
      450,
    );
    expect(find.text('Yearly plan'), findsOneWidget);
    expect(find.text('Ends Aug 27, 2026'), findsOneWidget);
  });

  testWidgets('uses the entitlement base-plan period as a fallback', (
    tester,
  ) async {
    final cubit = _TestSubscriptionCubit(
      SubscriptionState(
        phase: SubscriptionPhase.pro,
        status: SubscriptionStatus(
          isPro: true,
          entitlementId: 'Flymap Pro',
          productId: 'flymap_pro',
          productPlanId: 'yearly',
          lastUpdatedAt: DateTime(2026, 8, 17),
        ),
      ),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_testApp(cubit));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byKey(const Key('subscription-plan-row')),
      450,
    );
    expect(find.text('Yearly plan'), findsOneWidget);
  });
}

Widget _testApp(
  SubscriptionCubit cubit, {
  ThemeMode themeMode = ThemeMode.light,
}) {
  return TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: AppLocale.en.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: BlocProvider<SubscriptionCubit>.value(
        value: cubit,
        child: const SubscriptionManagementScreen(),
      ),
    ),
  );
}

class _TestSubscriptionCubit extends SubscriptionCubit {
  _TestSubscriptionCubit(SubscriptionState state)
    : super(
        repository: _FakeSubscriptionRepository(),
        flightUnlockRepository: _FakeFlightUnlockRepository(),
        analytics: _FakeAppAnalytics(),
      ) {
    emit(state);
  }

  @override
  Future<void> refresh({String source = 'refresh'}) async {}
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  @override
  SubscriptionStatus get currentStatus => SubscriptionStatus(
    isPro: false,
    entitlementId: 'Flymap Pro',
    lastUpdatedAt: DateTime(2026, 8, 17),
  );

  @override
  Stream<SubscriptionStatus> get statusStream => const Stream.empty();

  @override
  Future<void> close() async {}

  @override
  Future<List<SubscriptionProduct>> getProducts() async => const [];

  @override
  Future<SubscriptionStatus> initialize() async => currentStatus;

  @override
  Future<SubscriptionPaywallResult> presentPaywallIfNeeded() async =>
      SubscriptionPaywallResult.notPresented;

  @override
  Future<void> presentCustomerCenter() async {}

  @override
  Future<SubscriptionStatus> purchasePackage({
    required String packageId,
  }) async => currentStatus;

  @override
  Future<SubscriptionStatus> refresh() async => currentStatus;

  @override
  Future<SubscriptionStatus> restorePurchases() async => currentStatus;
}

class _FakeFlightUnlockRepository implements FlightUnlockRepository {
  @override
  Stream<int> get balanceStream => const Stream.empty();

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
