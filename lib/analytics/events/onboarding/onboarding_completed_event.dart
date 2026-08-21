import 'package:flymap/analytics/events/analytics_event.dart';

class OnboardingCompletedEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const OnboardingCompletedEvent({
    required this.flowVersion,
    required this.stepsTotal,
    required this.stepsSkippedCount,
    required this.durationSec,
    this.experimentKey,
    this.experimentVariant,
    this.experimentEnrolled,
  });

  final String flowVersion;
  final int stepsTotal;
  final int stepsSkippedCount;
  final int durationSec;
  final String? experimentKey;
  final String? experimentVariant;
  final bool? experimentEnrolled;

  @override
  String get firebaseEventName => 'onboarding_completed';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'flow_version': flowVersion,
    'steps_total': stepsTotal,
    'steps_skipped_count': stepsSkippedCount,
    'duration_sec': durationSec,
    if (experimentKey != null) 'experiment_key': experimentKey!,
    if (experimentVariant != null) 'experiment_variant': experimentVariant!,
    if (experimentEnrolled != null) 'experiment_enrolled': experimentEnrolled!,
  };

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;
}
