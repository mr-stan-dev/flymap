import 'package:flymap/analytics/events/analytics_event.dart';

class OnboardingStartedEvent extends AnalyticsEvent {
  const OnboardingStartedEvent({
    required this.flowVersion,
    required this.entrySource,
  });

  final String flowVersion;
  final String entrySource;

  @override
  String get name => 'onboarding_started';

  @override
  Map<String, Object> get parameters => <String, Object>{
    'flow_version': flowVersion,
    'entry_source': entrySource,
  };
}
