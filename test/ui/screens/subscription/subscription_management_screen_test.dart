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
          expiresAt: DateTime(2026, 9, 21),
          lastUpdatedAt: DateTime(2026, 8, 17),
        ),
      ),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_testApp(cubit));
    await tester.pump();

    expect(find.text('Your window seat, fully unlocked.'), findsOneWidget);
    expect(find.textContaining('Current period ends '), findsOneWidget);
    expect(find.text('Included with your Pro plan'), findsOneWidget);
    expect(find.text('Complete offline stories'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Cloud cover and airport forecasts'),
      350,
    );
    expect(find.text('Cloud cover and airport forecasts'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Cancel subscription'), 450);
    expect(find.text('Manage plan & billing'), findsOneWidget);
    expect(find.text('Cancel subscription'), findsOneWidget);
    expect(
      find.text(
        'Before you cancel, the App Store or Google Play will show when your '
        'Pro access ends.',
      ),
      findsOneWidget,
    );
  });
}

Widget _testApp(SubscriptionCubit cubit) {
  return TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.lightTheme,
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
