import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/analytics/app_analytics_initializer.dart';
import 'package:flymap/app/flymap_app.dart';
import 'package:flymap/crashlytics/app_crashlytics_initializer.dart';
import 'package:flymap/cubit_state_observer.dart';
import 'package:flymap/data/map_asset_cache_service.dart';
import 'package:flymap/data/location/app_location_service.dart';
import 'package:flymap/data/local/app_database.dart';
import 'package:flymap/data/local/migrations/flights_db_migration_runner.dart';
import 'package:flymap/domain/usecase/auto_complete_stale_in_progress_flights_use_case.dart';
import 'package:flymap/firebase_options.dart';
import 'package:flymap/i18n/app_localization.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:get_it/get_it.dart';

import 'di/di_module.dart';

void main() async {
  await runZonedGuarded(
    () async {
      // Must be initialized in the same zone where runApp is called.
      WidgetsFlutterBinding.ensureInitialized();
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
      ]);
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleAppAttestProvider(),
      );
      DiModule().register();

      await GetIt.I<AppAnalyticsInitializer>().initialize();
      await GetIt.I<AppCrashlyticsInitializer>().initialize(
        enableCollection: kReleaseMode,
      );
      await GetIt.I<AppDatabase>().initialize();
      await GetIt.I<FlightsDbMigrationRunner>().migrateIfNeeded();
      await GetIt.I<AutoCompleteStaleInProgressFlightsUseCase>().call();

      await AppLocalization.initLocalization(settingsRepository: GetIt.I());
      final hasSeenOnboarding = await GetIt.I<OnboardingRepository>()
          .hasSeenOnboarding();
      Bloc.observer = CubitStateObserver.create();

      runApp(
        TranslationProvider(
          child: FlymapApp(showOnboarding: !hasSeenOnboarding),
        ),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        GetIt.I<MapAssetCacheService>().ensureReadyInBackground();
        unawaited(GetIt.I<AppLocationService>().initializeForegroundWarmup());
      });
    },
    (error, stack) async {
      if (!GetIt.I.isRegistered<AppCrashlyticsInitializer>()) return;
      await GetIt.I<AppCrashlyticsInitializer>().recordRunZonedGuardedError(
        error,
        stack,
      );
    },
  );
}
