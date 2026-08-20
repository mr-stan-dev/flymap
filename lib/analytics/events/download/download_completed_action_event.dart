import 'package:flymap/analytics/events/analytics_event.dart';

enum DownloadCompletedAction {
  openFlight('open_flight'),
  shareVideo('share_video'),
  share('share'),
  home('home');

  const DownloadCompletedAction(this.analyticsValue);

  final String analyticsValue;
}

class DownloadCompletedActionEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const DownloadCompletedActionEvent({
    required this.action,
    required this.accessMode,
    this.creationAttemptId,
  });

  final DownloadCompletedAction action;
  final String accessMode;
  final String? creationAttemptId;

  @override
  String get firebaseEventName => 'download_completed_action';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'action': action.analyticsValue,
    'access_mode': accessMode,
    if (creationAttemptId case final attemptId?)
      'creation_attempt_id': attemptId,
    'tracking_version': 2,
  };

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;
}
