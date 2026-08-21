import 'package:flymap/analytics/events/analytics_event.dart';

class OnboardingStartedEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const OnboardingStartedEvent({
    required this.flowVersion,
    required this.entrySource,
    this.experimentKey,
    this.experimentVariant,
    this.experimentEnrolled,
  });

  final String flowVersion;
  final String entrySource;
  final String? experimentKey;
  final String? experimentVariant;
  final bool? experimentEnrolled;

  @override
  String get firebaseEventName => 'onboarding_started';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'flow_version': flowVersion,
    'entry_source': entrySource,
    if (experimentKey != null) 'experiment_key': experimentKey!,
    if (experimentVariant != null) 'experiment_variant': experimentVariant!,
    if (experimentEnrolled != null) 'experiment_enrolled': experimentEnrolled!,
  };

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;
}
