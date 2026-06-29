import 'package:flymap/analytics/events/analytics_event.dart';

class OnboardingCompletedEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const OnboardingCompletedEvent({
    required this.flowVersion,
    required this.stepsTotal,
    required this.stepsSkippedCount,
    required this.durationSec,
  });

  final String flowVersion;
  final int stepsTotal;
  final int stepsSkippedCount;
  final int durationSec;

  @override
  String get firebaseEventName => 'onboarding_completed';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'flow_version': flowVersion,
    'steps_total': stepsTotal,
    'steps_skipped_count': stepsSkippedCount,
    'duration_sec': durationSec,
  };

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;
}
