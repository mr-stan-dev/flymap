import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

abstract class AppCrashlytics {
  Future<void> setCollectionEnabled(bool enabled);

  Future<void> setContext({
    String? screen,
    int? routeLengthKm,
    String? mapDetail,
    int? articlesSelectedCount,
    String? downloadStage,
  });

  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  });

  Future<void> recordFlutterError(FlutterErrorDetails details);
}

class FirebaseAppCrashlytics implements AppCrashlytics {
  FirebaseAppCrashlytics({FirebaseCrashlytics? crashlytics})
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    try {
      await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
    } catch (_) {
      // Keep crash reporting setup non-blocking.
    }
  }

  @override
  Future<void> setContext({
    String? screen,
    int? routeLengthKm,
    String? mapDetail,
    int? articlesSelectedCount,
    String? downloadStage,
  }) async {
    try {
      if (screen != null) {
        await _crashlytics.setCustomKey('screen', screen);
      }
      if (routeLengthKm != null) {
        await _crashlytics.setCustomKey('route_length_km', routeLengthKm);
      }
      if (mapDetail != null) {
        await _crashlytics.setCustomKey('map_detail', mapDetail);
      }
      if (articlesSelectedCount != null) {
        await _crashlytics.setCustomKey(
          'articles_selected_count',
          articlesSelectedCount,
        );
      }
      if (downloadStage != null) {
        await _crashlytics.setCustomKey('download_stage', downloadStage);
      }
    } catch (_) {
      // Ignore non-fatal context failures.
    }
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    try {
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    } catch (_) {
      // Ignore reporter errors.
    }
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    try {
      await _crashlytics.recordFlutterError(details);
    } catch (_) {
      // Ignore reporter errors.
    }
  }
}
