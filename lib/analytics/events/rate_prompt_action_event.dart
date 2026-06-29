import 'package:flymap/analytics/events/analytics_event.dart';

class RatePromptActionEvent extends FirebaseAnalyticsEvent {
  const RatePromptActionEvent({required this.source, required this.action});

  final String source;
  final String action;

  @override
  String get firebaseEventName => 'rate_prompt_action';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'source': source,
    'action': action,
  };
}
