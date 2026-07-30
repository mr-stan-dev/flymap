import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/data/notifications/flight_notification_scheduler.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/flight_unlock_repository.dart';
import 'package:flymap/repository/metric_units_repository.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:flymap/repository/settings_repository.dart';
import 'package:flymap/ui/screens/settings/viewmodel/settings_cubit.dart';
import 'package:flymap/ui/screens/settings/viewmodel/settings_state.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/theme/app_theme.dart';
import 'package:get_it/get_it.dart';

import '../repository/subscription_repository.dart';
import '../router/app_router.dart';

class FlymapApp extends StatefulWidget {
  const FlymapApp({required this.showOnboarding, super.key});

  final bool showOnboarding;

  @override
  State<FlymapApp> createState() => _FlymapAppState();
}

class _FlymapAppState extends State<FlymapApp> {
  late final router = AppRouter.createRouter(
    showOnboarding: widget.showOnboarding,
  );

  @override
  void initState() {
    super.initState();
    // Forecast notifications: hook taps to navigation, then let the
    // scheduler heal the system schedule (reboots, time/settings changes).
    // Guarded so widget tests without DI stay unaffected.
    if (GetIt.I.isRegistered<FlightNotificationScheduler>()) {
      final scheduler = GetIt.I.get<FlightNotificationScheduler>();
      scheduler.onOpenFlight = (flight) =>
          router.push(AppRouter.flightRoute, extra: {'flight': flight});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(() async {
          await scheduler.initialize();
          await scheduler.resyncAll();
        }());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SettingsCubit(
            repository: GetIt.I.get<SettingsRepository>(),
            unitsRepository: GetIt.I.get<MetricUnitsRepository>(),
            onboardingRepository: GetIt.I.get<OnboardingRepository>(),
            airportsDatabase: GetIt.I.get<AirportsDatabase>(),
          )..load(),
        ),
        BlocProvider(
          create: (_) => SubscriptionCubit(
            repository: GetIt.I.get<SubscriptionRepository>(),
            flightUnlockRepository: GetIt.I.get<FlightUnlockRepository>(),
            analytics: GetIt.I.get<AppAnalytics>(),
          )..initialize(),
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
          return MaterialApp.router(
            title: t.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            debugShowCheckedModeBanner: false,
            locale: TranslationProvider.of(context).flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
