import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/analytics/posthog_app_analytics.dart';
import 'package:flymap/analytics/posthog_client.dart';
import 'package:flymap/analytics/posthog_env_config.dart';
import 'package:flymap/domain/entity/learn_access.dart';

void main() {
  test('captures PostHog events and ignores Firebase-only events', () async {
    final client = _RecordingPostHogClient();
    final analytics = PostHogAppAnalytics(
      config: const PostHogEnvConfig(
        enabled: true,
        projectToken: 'token',
        host: 'https://example.com',
      ),
      client: client,
    );
    await analytics.initialize();

    await analytics.log(
      const LearnCategoryOpenedEvent(
        categoryId: 'flight_basics',
        articleCount: 12,
      ),
    );
    await analytics.log(
      const GeoQuizStartedEvent(
        quizId: 'countries_oceania',
        access: LearnAccess.free,
        isProUser: false,
        solvedCount: 2,
        totalCount: 14,
        isResume: true,
      ),
    );

    expect(client.captures, hasLength(1));
    expect(client.captures.single.eventName, 'geo_quiz_started');
    expect(client.captures.single.properties, containsPair('solved_count', 2));
    expect(client.captures.single.properties, containsPair('is_resume', true));
  });
}

class _PostHogCapture {
  const _PostHogCapture({required this.eventName, required this.properties});

  final String eventName;
  final Map<String, Object> properties;
}

class _RecordingPostHogClient implements PostHogAnalyticsClient {
  final List<_PostHogCapture> captures = <_PostHogCapture>[];

  @override
  Future<void> capture({
    required String eventName,
    Map<String, Object>? properties,
    Map<String, Object>? userProperties,
    Map<String, Object>? userPropertiesSetOnce,
  }) async {
    captures.add(
      _PostHogCapture(
        eventName: eventName,
        properties: properties ?? const <String, Object>{},
      ),
    );
  }

  @override
  Future<void> identify({
    required String userId,
    Map<String, Object>? userProperties,
    Map<String, Object>? userPropertiesSetOnce,
  }) async {}

  @override
  Future<void> setPersonProperties({
    Map<String, Object>? userPropertiesToSet,
    Map<String, Object>? userPropertiesToSetOnce,
  }) async {}

  @override
  Future<void> setup({
    required String projectToken,
    required String host,
    required bool debug,
    required bool captureApplicationLifecycleEvents,
  }) async {}
}
