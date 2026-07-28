import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flymap/data/api/flight_info_api_mapper.dart';
import 'package:flymap/domain/entity/user_profile.dart';
import 'package:flymap/domain/entity/user_interests_payload.dart';
import 'package:flymap/domain/entity/wiki_article_candidate.dart';
import 'package:flymap/i18n/app_localization.dart';
import 'package:flymap/logger.dart';
import 'package:latlong2/latlong.dart';

const _waypointFractionDigits = 2;
const flightInfoRequestMaxWaypoints = 200;
const wikiArticlesRequestMaxWaypoints = 20;
const _maxLatitude = 90.0;
const _minLatitude = -90.0;
const _maxLongitude = 180.0;
const _minLongitude = -180.0;

Map<String, dynamic> buildFlightInfoFunctionRequest({
  required String airportDeparture,
  required String airportArrival,
  required List<LatLng> waypoints,
  required int promptVersion,
  String languageCode = 'en',
  List<UsersInterests>? interests,
  int maxWaypoints = flightInfoRequestMaxWaypoints,
}) {
  final normalizedLanguageCode = languageCode.trim();
  final sampledWaypoints = sampleWaypointsForFlightRequest(
    waypoints,
    maxWaypoints: maxWaypoints,
  );
  final request = <String, dynamic>{
    'waypoints': sampledWaypoints
        .map(
          (c) => [
            _roundCoordinate(
              _clampLatitude(c.latitude),
              fractionDigits: _waypointFractionDigits,
            ),
            _roundCoordinate(
              _normalizeLongitude(c.longitude),
              fractionDigits: _waypointFractionDigits,
            ),
          ],
        )
        .toList(),
    'airport_departure': airportDeparture,
    'airport_arrival': airportArrival,
    'prompt_version': promptVersion.toString(),
    'lang': normalizedLanguageCode.isEmpty
        ? 'en'
        : normalizedLanguageCode.toLowerCase(),
  };
  final preferenceInterests = interests
      ?.map((interest) => interest.payloadValue)
      .toList(growable: false);
  if (preferenceInterests != null && preferenceInterests.isNotEmpty) {
    request['user_preferences'] = <String, dynamic>{
      'interests': preferenceInterests,
    };
  }
  return request;
}

double _roundCoordinate(double value, {required int fractionDigits}) =>
    double.parse(value.toStringAsFixed(fractionDigits));

double _clampLatitude(double value) {
  if (!value.isFinite) return 0;
  return value.clamp(_minLatitude, _maxLatitude).toDouble();
}

double _normalizeLongitude(double value) {
  if (!value.isFinite) return 0;
  var normalized = value;
  while (normalized > _maxLongitude) {
    normalized -= 360.0;
  }
  while (normalized < _minLongitude) {
    normalized += 360.0;
  }
  if (normalized == -180.0) return 180.0;
  return normalized;
}

List<LatLng> sampleWaypointsForFlightRequest(
  List<LatLng> waypoints, {
  required int maxWaypoints,
}) {
  if (waypoints.length <= maxWaypoints) {
    return waypoints;
  }

  final lastIndex = waypoints.length - 1;
  return List.generate(maxWaypoints, (index) {
    final sourceIndex = (index * lastIndex / (maxWaypoints - 1)).round();
    return waypoints[sourceIndex.clamp(0, lastIndex)];
  }, growable: false);
}

class FlightInfoApi {
  final functions = FirebaseFunctions.instance;
  static const _wikiArticlesPromptVersion = 7;
  static const _getWikiArticlesFunction = 'get_flight_wiki_articles';
  final _logger = Logger('FlightInfoApi');

  final FlightInfoApiMapper _mapper;

  FlightInfoApi({required FlightInfoApiMapper apiMapper}) : _mapper = apiMapper;

  Future<List<WikiArticleCandidate>> getFlightWikiArticles(
    String airportDeparture,
    String airportArrival,
    List<LatLng> waypoints, {
    List<UsersInterests>? interests,
  }) async {
    final request = _buildFunctionRequest(
      airportDeparture: airportDeparture,
      airportArrival: airportArrival,
      waypoints: waypoints,
      promptVersion: _wikiArticlesPromptVersion,
      interests: interests,
      maxWaypoints: wikiArticlesRequestMaxWaypoints,
    );
    final requestWaypoints = request['waypoints'] is List
        ? (request['waypoints'] as List).length
        : waypoints.length;
    _logger.log(
      'getFlightWikiArticles dep="$airportDeparture" arr="$airportArrival" '
      'waypoints=${waypoints.length} requestWaypoints=$requestWaypoints '
      'prompt=$_wikiArticlesPromptVersion',
    );
    if (waypoints.isNotEmpty) {
      final first = waypoints.first;
      final last = waypoints.last;
      _logger.log(
        'Wiki request endpoints first=${first.latitude},${first.longitude} '
        'last=${last.latitude},${last.longitude}',
      );
    }
    final result = await functions
        .httpsCallable(_getWikiArticlesFunction)
        .call(request);
    _logger.log(
      'Wiki callable raw result type=${result.data.runtimeType} '
      'preview=${_previewData(result.data)}',
    );
    final decoded = _decodeFunctionData(result.data);
    _logger.log(
      'Wiki decoded type=${decoded.runtimeType} '
      'preview=${_previewData(decoded)}',
    );
    final candidates = _mapper.toWikiArticleCandidates(decoded);
    final firstUrls = candidates.take(3).map((e) => e.url).join(', ');
    _logger.log(
      'Wiki mapped candidates=${candidates.length}'
      '${firstUrls.isEmpty ? '' : ' first=[$firstUrls]'}',
    );
    return candidates;
  }

  Map<String, dynamic> _buildFunctionRequest({
    required String airportDeparture,
    required String airportArrival,
    required List<LatLng> waypoints,
    required int promptVersion,
    List<UsersInterests>? interests,
    int maxWaypoints = flightInfoRequestMaxWaypoints,
  }) {
    return buildFlightInfoFunctionRequest(
      airportDeparture: airportDeparture,
      airportArrival: airportArrival,
      waypoints: waypoints,
      promptVersion: promptVersion,
      languageCode: AppLocalization.currentLanguageCode,
      interests: interests,
      maxWaypoints: maxWaypoints,
    );
  }

  dynamic _decodeFunctionData(dynamic rawData) {
    if (rawData is String) {
      try {
        return jsonDecode(rawData);
      } catch (_) {
        return rawData;
      }
    }
    return rawData;
  }

  String _previewData(dynamic value) {
    if (value == null) return 'null';
    if (value is String) {
      final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (compact.length <= 180) return compact;
      return '${compact.substring(0, 180)}...';
    }
    if (value is List) return 'List(len=${value.length})';
    if (value is Map) {
      final keys = value.keys.map((e) => e.toString()).take(8).join(', ');
      return 'Map(keys=[$keys])';
    }
    return value.toString();
  }
}
