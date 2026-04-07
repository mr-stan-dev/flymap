import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/analytics/app_analytics_initializer.dart';
import 'package:flymap/app/flymap_app.dart';
import 'package:flymap/crashlytics/app_crashlytics_initializer.dart';
import 'package:flymap/cubit_state_observer.dart';
import 'package:flymap/data/glyphs_service.dart';
import 'package:flymap/data/local/app_database.dart';
import 'package:flymap/data/sprite_service.dart';
import 'package:flymap/firebase_options.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:get_it/get_it.dart';

import 'di/di_module.dart';

void main() async {
  await runZonedGuarded(
    () async {
      // Must be initialized in the same zone where runApp is called.
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      DiModule().register();

      await GetIt.I<AppAnalyticsInitializer>().initialize();
      await GetIt.I<AppCrashlyticsInitializer>().initialize(
        enableCollection: kReleaseMode,
      );

      await GlyphsService().copyGlyphsToCacheDir();
      await SpriteService().copySpritesToCacheDir();
      await GetIt.I<AppDatabase>().initialize();

      final hasSeenOnboarding = await GetIt.I<OnboardingRepository>()
          .hasSeenOnboarding();
      Bloc.observer = CubitStateObserver.create();
      LocaleSettings.setLocaleSync(AppLocale.en);

      runApp(
        TranslationProvider(
          child: FlymapApp(showOnboarding: !hasSeenOnboarding),
        ),
      );
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
