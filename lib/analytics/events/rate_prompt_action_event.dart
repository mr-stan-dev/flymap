import 'package:flymap/analytics/events/analytics_event.dart';

class RatePromptActionEvent extends AnalyticsEvent {
  const RatePromptActionEvent({required this.source, required this.action});

  final String source;
  final String action;

  @override
  String get name => 'rate_prompt_action';

  @override
  Map<String, Object> get parameters => <String, Object>{
    'source': source,
    'action': action,
  };
}
