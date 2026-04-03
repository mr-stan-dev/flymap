import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/crashlytics/app_crashlytics.dart';
import 'package:flymap/crashlytics/app_crashlytics_initializer.dart';

void main() {
  group('AppCrashlyticsInitializer', () {
    late _FakeAppCrashlytics crashlytics;
    late AppCrashlyticsInitializer initializer;
    late FlutterExceptionHandler? previousFlutterError;
    late ErrorCallback? previousPlatformError;

    setUp(() {
      crashlytics = _FakeAppCrashlytics();
      initializer = AppCrashlyticsInitializer(crashlytics: crashlytics);
      previousFlutterError = FlutterError.onError;
      previousPlatformError = PlatformDispatcher.instance.onError;
    });

    tearDown(() {
      FlutterError.onError = previousFlutterError;
      PlatformDispatcher.instance.onError = previousPlatformError;
    });

    test('initialize sets collection enabled flag', () async {
      await initializer.initialize(enableCollection: false);

      expect(crashlytics.collectionEnabled, isFalse);
    });

    test('initialize wires FlutterError handler to crashlytics', () async {
      await initializer.initialize(enableCollection: true);

      final details = FlutterErrorDetails(
        exception: Exception('flutter_test_error'),
      );
      FlutterError.onError?.call(details);

      expect(crashlytics.recordedFlutterErrors, hasLength(1));
      expect(
        crashlytics.recordedFlutterErrors.single.exception.toString(),
        contains('flutter_test_error'),
      );
    });

    test(
      'recordRunZonedGuardedError records fatal error with reason',
      () async {
        final error = Exception('zone_error');
        final stack = StackTrace.current;

        await initializer.recordRunZonedGuardedError(error, stack);

        expect(crashlytics.recordedErrors, hasLength(1));
        final recorded = crashlytics.recordedErrors.single;
        expect(recorded.error, error);
        expect(recorded.stackTrace, stack);
        expect(recorded.reason, 'run_zoned_guarded_error');
        expect(recorded.fatal, isTrue);
      },
    );
  });
}

class _FakeAppCrashlytics implements AppCrashlytics {
  bool? collectionEnabled;
  final List<FlutterErrorDetails> recordedFlutterErrors =
      <FlutterErrorDetails>[];
  final List<_RecordedCrashError> recordedErrors = <_RecordedCrashError>[];

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    collectionEnabled = enabled;
  }

  @override
  Future<void> setContext({
    String? screen,
    int? routeLengthKm,
    String? mapDetail,
    int? articlesSelectedCount,
    String? downloadStage,
  }) async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    recordedErrors.add(
      _RecordedCrashError(
        error: error,
        stackTrace: stackTrace,
        reason: reason,
        fatal: fatal,
      ),
    );
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    recordedFlutterErrors.add(details);
  }
}

class _RecordedCrashError {
  const _RecordedCrashError({
    required this.error,
    required this.stackTrace,
    required this.reason,
    required this.fatal,
  });

  final Object error;
  final StackTrace stackTrace;
  final String? reason;
  final bool fatal;
}
