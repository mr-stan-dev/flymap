import 'package:flymap/analytics/events/analytics_event.dart';

class OnboardingStartedEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const OnboardingStartedEvent({
    required this.flowVersion,
    required this.entrySource,
  });

  final String flowVersion;
  final String entrySource;

  @override
  String get firebaseEventName => 'onboarding_started';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'flow_version': flowVersion,
    'entry_source': entrySource,
  };

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;
}
