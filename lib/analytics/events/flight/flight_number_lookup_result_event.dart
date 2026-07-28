import 'package:cloud_functions/cloud_functions.dart';
import 'package:flymap/analytics/events/analytics_event.dart';

enum FlightNumberLookupResult {
  success('success'),
  notFound('not_found'),
  providerUnavailable('provider_unavailable'),
  providerTimeout('provider_timeout'),
  providerInvalidResponse('provider_invalid_response'),
  invalidArgument('invalid_argument'),
  permissionDenied('permission_denied'),
  resourceExhausted('resource_exhausted'),
  deadlineExceeded('deadline_exceeded'),
  internal('internal'),
  failed('failed');

  const FlightNumberLookupResult(this.analyticsValue);

  final String analyticsValue;

  /// True for provider-side failures worth a Crashlytics non-fatal;
  /// expected outcomes (success, not-found, bad input) are analytics-only.
  bool get isProviderFailure => switch (this) {
    success ||
    notFound ||
    invalidArgument ||
    permissionDenied => false,
    _ => true,
  };
}

/// Shared callable-error → result-bucket mapping (used by search cubits and
/// the travel-date step so all surfaces report identical buckets).
FlightNumberLookupResult flightNumberLookupResultFromError(Object error) {
  if (error is FirebaseFunctionsException) {
    final details = error.details;
    final reason = details is Map ? details['reason'] : null;
    return switch (error.code) {
      'not-found' => FlightNumberLookupResult.notFound,
      'unavailable' => switch (reason) {
        'provider_timeout' => FlightNumberLookupResult.providerTimeout,
        'provider_invalid_response' =>
          FlightNumberLookupResult.providerInvalidResponse,
        _ => FlightNumberLookupResult.providerUnavailable,
      },
      'invalid-argument' => FlightNumberLookupResult.invalidArgument,
      'permission-denied' => FlightNumberLookupResult.permissionDenied,
      'resource-exhausted' => FlightNumberLookupResult.resourceExhausted,
      'deadline-exceeded' => FlightNumberLookupResult.deadlineExceeded,
      'internal' => FlightNumberLookupResult.internal,
      _ => FlightNumberLookupResult.failed,
    };
  }
  return FlightNumberLookupResult.failed;
}

/// Where a schedule (upcoming departures) lookup happened.
enum ScheduleLookupSource {
  numberSearch('number_search'),
  travelDateStep('travel_date_step');

  const ScheduleLookupSource(this.analyticsValue);

  final String analyticsValue;
}

/// Outcome of an AeroDataBox upcoming-schedule lookup. Separate from
/// [FlightNumberLookupResultEvent] because a failed schedule lookup usually
/// still ends in a successful (dateless) flight creation — without this
/// event, rate limiting would be invisible in analytics.
///
/// Firebase-only ON PURPOSE: it fires on every lookup (successes included),
/// which is diagnostic volume — PostHog is reserved for product events with
/// quota to protect. The rate-limited share (tier-upgrade signal) is read in
/// Firebase; alerting comes from Crashlytics non-fatals and backend logs.
class ScheduleLookupResultEvent extends FirebaseAnalyticsEvent {
  const ScheduleLookupResultEvent({required this.result, required this.source});

  final FlightNumberLookupResult result;
  final ScheduleLookupSource source;

  @override
  String get firebaseEventName => 'schedule_lookup_result';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'result': result.analyticsValue,
    'source': source.analyticsValue,
  };
}

class FlightNumberLookupResultEvent extends FirebaseAnalyticsEvent {
  const FlightNumberLookupResultEvent({required this.result});

  final FlightNumberLookupResult result;

  @override
  String get firebaseEventName => 'flight_number_lookup_result';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'result': result.analyticsValue,
  };
}
