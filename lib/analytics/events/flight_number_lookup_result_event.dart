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
