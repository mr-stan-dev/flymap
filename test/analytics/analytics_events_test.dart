import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/domain/entity/flight_route_source.dart';
import 'package:flymap/domain/entity/learn_access.dart';
import 'package:flymap/map_download_config.dart';
import 'package:flymap/subscription/paywall_source.dart';

void main() {
  group('analytics events', () {
    test('route_type_selected has stable properties', () {
      const event = RouteTypeSelectedEvent(
        routeType: SelectedRouteType.realRoute,
        isProUser: false,
        hasPendingFlightUnlock: true,
      );

      expect(event.firebaseEventName, 'route_type_selected');
      expect(event.firebaseParameters, <String, Object>{
        'route_type': 'real_route',
        'is_pro_user': false,
        'has_pending_flight_unlock': true,
      });
    });

    test('weather share events are Firebase-only with image/video names', () {
      const image = WeatherShareEvent(WeatherShareFormat.image);
      const video = WeatherShareEvent(WeatherShareFormat.video);

      expect(image.firebaseEventName, 'share_weather_image');
      expect(video.firebaseEventName, 'share_weather_video');
      expect(image.firebaseParameters, isEmpty);
      // Firebase-only: not a PostHog event, so the PostHog sink drops it.
      expect(image, isA<FirebaseAnalyticsEvent>());
      expect(image, isNot(isA<PostHogAnalyticsEvent>()));
      expect(video, isNot(isA<PostHogAnalyticsEvent>()));
    });

    test('flight_opened has stable coarse route properties', () {
      const event = FlightOpenedEvent(
        routeSource: FlightRouteSource.fr24Historical,
        routeLength: RouteLength.long,
        accessTier: FlightOpenedAccessTier.flightUnlock,
      );

      expect(event.firebaseEventName, 'flight_opened');
      expect(event.firebaseParameters, <String, Object>{
        'route_source': 'fr24_historical',
        'route_length_bucket': 'long',
        'access_tier': 'flight_unlock',
      });
    });

    test('monetization events have stable properties', () {
      const paywall = PaywallPresentedEvent(
        source: PaywallSource.settingsBanner,
        isProUser: false,
        hasProducts: true,
      );
      const restore = RestorePurchasesResultEvent(
        result: RestorePurchasesAnalyticsResult.noSubscription,
      );
      const statusChanged = SubscriptionStatusChangedEvent(
        fromStatus: 'free',
        toStatus: 'pro',
        source: 'purchase',
      );

      expect(paywall.firebaseEventName, 'paywall_presented');
      expect(paywall.firebaseParameters['source'], 'settings_banner');
      expect(paywall.firebaseParameters['has_products'], isTrue);
      expect(restore.firebaseEventName, 'restore_purchases_result');
      expect(restore.firebaseParameters['result'], 'no_subscription');
      expect(statusChanged.firebaseEventName, 'subscription_status_changed');
      expect(statusChanged.firebaseParameters['to_status'], 'pro');
    });

    test('learn events have stable privacy-safe properties', () {
      const category = LearnCategoryOpenedEvent(
        categoryId: 'flight_basics',
        articleCount: 12,
      );
      const article = LearnArticleOpenedEvent(
        articleId: 'why_planes_turn',
        categoryId: 'flight_basics',
        access: LearnAccess.free,
        isProUser: false,
      );

      expect(category.firebaseEventName, 'learn_category_opened');
      expect(category.firebaseParameters, <String, Object>{
        'category_id': 'flight_basics',
        'article_count': 12,
      });
      expect(article.firebaseEventName, 'learn_article_opened');
      expect(article.firebaseParameters, <String, Object>{
        'article_id': 'why_planes_turn',
        'category_id': 'flight_basics',
        'access': 'free',
        'is_pro_user': false,
      });
    });

    test('Geo Quiz events have stable provider-specific properties', () {
      const started = GeoQuizStartedEvent(
        quizId: 'countries_europe',
        access: LearnAccess.free,
        isProUser: false,
        solvedCount: 5,
        totalCount: 45,
        isResume: true,
      );
      const completed = GeoQuizCompletedEvent(
        quizId: 'countries_europe',
        totalCount: 45,
        durationSeconds: 90,
        isProUser: false,
      );

      expect(started.postHogEventName, 'geo_quiz_started');
      expect(started.postHogParameters['is_resume'], isTrue);
      expect(started.postHogParameters['solved_count'], 5);
      expect(completed.postHogEventName, 'geo_quiz_completed');
      expect(completed.postHogParameters['duration_seconds'], 90);
    });

    test('Geo Quiz paywall source remains distinct from articles', () {
      expect(
        PaywallSource.geoQuizLockedContent.analyticsValue,
        'geo_quiz_locked_content',
      );
      expect(
        PaywallSource.learnLockedContent.analyticsValue,
        'learn_locked_content',
      );
    });
  });
}
