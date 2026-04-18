import 'package:flymap/analytics/events/analytics_event.dart';

class OnboardingStepCompletedEvent extends AnalyticsEvent {
  const OnboardingStepCompletedEvent({
    required this.stepId,
    required this.stepIndex,
    required this.inputState,
  });

  final String stepId;
  final int stepIndex;
  final String inputState;

  @override
  String get name => 'onboarding_step_completed';

  @override
  Map<String, Object> get parameters => <String, Object>{
    'step_id': stepId,
    'step_index': stepIndex,
    'input_state': inputState,
  };
}
