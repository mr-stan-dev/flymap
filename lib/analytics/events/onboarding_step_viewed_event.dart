import 'package:flymap/analytics/events/analytics_event.dart';

class OnboardingStepViewedEvent extends AnalyticsEvent {
  const OnboardingStepViewedEvent({
    required this.stepId,
    required this.stepIndex,
    required this.isSkippable,
  });

  final String stepId;
  final int stepIndex;
  final bool isSkippable;

  @override
  String get name => 'onboarding_step_viewed';

  @override
  Map<String, Object> get parameters => <String, Object>{
    'step_id': stepId,
    'step_index': stepIndex,
    'is_skippable': isSkippable ? 1 : 0,
  };
}
