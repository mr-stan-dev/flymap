import 'package:flymap/analytics/events/analytics_event.dart';

class OnboardingCompletedEvent extends AnalyticsEvent {
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
  String get name => 'onboarding_completed';

  @override
  Map<String, Object> get parameters => <String, Object>{
    'flow_version': flowVersion,
    'steps_total': stepsTotal,
    'steps_skipped_count': stepsSkippedCount,
    'duration_sec': durationSec,
  };
}
