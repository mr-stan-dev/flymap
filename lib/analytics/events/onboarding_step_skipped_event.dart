import 'package:flymap/analytics/events/analytics_event.dart';

class OnboardingStepSkippedEvent extends AnalyticsEvent {
  const OnboardingStepSkippedEvent({
    required this.stepId,
    required this.stepIndex,
  });

  final String stepId;
  final int stepIndex;

  @override
  String get name => 'onboarding_step_skipped';

  @override
  Map<String, Object> get parameters => <String, Object>{
    'step_id': stepId,
    'step_index': stepIndex,
  };
}
