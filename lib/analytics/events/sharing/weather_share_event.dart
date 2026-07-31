import 'package:flymap/analytics/events/analytics_event.dart';

enum WeatherShareFormat { image, video }

/// The user shared the flight-weather card as an image or a video.
///
/// Firebase-only on purpose: a share is a nice-to-know volume metric, not a
/// funnel step, so it stays out of the quota-limited PostHog sink (it extends
/// [FirebaseAnalyticsEvent] without implementing [PostHogAnalyticsEvent], so
/// the PostHog sink drops it).
class WeatherShareEvent extends FirebaseAnalyticsEvent {
  const WeatherShareEvent(this.format);

  final WeatherShareFormat format;

  @override
  String get firebaseEventName => switch (format) {
    WeatherShareFormat.image => 'share_weather_image',
    WeatherShareFormat.video => 'share_weather_video',
  };

  @override
  Map<String, Object> get firebaseParameters => const <String, Object>{};
}
