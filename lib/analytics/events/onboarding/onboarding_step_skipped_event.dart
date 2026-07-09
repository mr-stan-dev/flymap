import 'package:flymap/analytics/events/analytics_event.dart';

class OnboardingStepSkippedEvent extends FirebaseAnalyticsEvent {
  const OnboardingStepSkippedEvent({
    required this.stepId,
    required this.stepIndex,
  });

  final String stepId;
  final int stepIndex;

  @override
  String get firebaseEventName => 'onboarding_step_skipped';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'step_id': stepId,
    'step_index': stepIndex,
  };
}
