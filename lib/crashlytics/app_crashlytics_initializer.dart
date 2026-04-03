import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flymap/crashlytics/app_crashlytics.dart';

class AppCrashlyticsInitializer {
  const AppCrashlyticsInitializer({required AppCrashlytics crashlytics})
    : _crashlytics = crashlytics;

  final AppCrashlytics _crashlytics;

  Future<void> initialize({required bool enableCollection}) async {
    await _crashlytics.setCollectionEnabled(enableCollection);

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(_crashlytics.recordFlutterError(details));
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(
        _crashlytics.recordError(
          error,
          stack,
          fatal: true,
          reason: 'platform_dispatcher_error',
        ),
      );
      return true;
    };
  }

  Future<void> recordRunZonedGuardedError(
    Object error,
    StackTrace stack,
  ) async {
    await _crashlytics.recordError(
      error,
      stack,
      fatal: true,
      reason: 'run_zoned_guarded_error',
    );
  }
}
