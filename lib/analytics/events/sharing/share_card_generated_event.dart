import 'package:flymap/analytics/events/analytics_event.dart';

class ShareCardGeneratedEvent extends FirebaseAnalyticsEvent {
  const ShareCardGeneratedEvent({required this.success, required this.error});

  final bool success;
  final String error;

  @override
  String get firebaseEventName => 'share_card_generated';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'success': success ? 1 : 0,
    'error': error,
  };
}
