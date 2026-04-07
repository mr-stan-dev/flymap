import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flymap/data/api/flight_info_api_mapper.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/wiki_article_candidate.dart';
import 'package:flymap/logger.dart';
import 'package:latlong2/latlong.dart';

class FlightInfoApi {
  final functions = FirebaseFunctions.instance;
  static const _overviewPromptVersion = 3;
  static const _getOverviewFunction = 'get_flight_overview';
  static const _wikiArticlesPromptVersion = 2;
  static const _getWikiArticlesFunction = 'get_flight_wiki_articles';
  final _logger = Logger('FlightInfoApi');

  final FlightInfoApiMapper _mapper;

  FlightInfoApi({required FlightInfoApiMapper apiMapper}) : _mapper = apiMapper;

  Future<FlightInfo> getFlightOverview(
    String airportDeparture,
    String airportArrival,
    List<LatLng> waypoints,
  ) async {
    _logger.log(
      'getFlightOverview dep="$airportDeparture" arr="$airportArrival" '
      'waypoints=${waypoints.length}',
    );
    final result = await functions
        .httpsCallable(_getOverviewFunction)
        .call(
          _buildFunctionRequest(
            airportDeparture: airportDeparture,
            airportArrival: airportArrival,
            waypoints: waypoints,
            promptVersion: _overviewPromptVersion,
          ),
        );
    final decoded = _decodeFunctionData(result.data);
    _logger.log('Overview response decoded type=${decoded.runtimeType}');
    if (decoded is! Map) {
      throw const FormatException('Invalid overview response payload');
    }
    final map = decoded.cast<String, dynamic>();
    _logger.log('Overview payload keys=[${map.keys.take(10).join(', ')}]');
    final info = _mapper.toFlightInfo(map);
    _logger.log('Overview mapped overviewLen=${info.overview.length}');
    return info;
  }

  Future<List<WikiArticleCandidate>> getFlightWikiArticles(
    String airportDeparture,
    String airportArrival,
    List<LatLng> waypoints,
  ) async {
    _logger.log(
      'getFlightWikiArticles dep="$airportDeparture" arr="$airportArrival" '
      'waypoints=${waypoints.length} prompt=$_wikiArticlesPromptVersion',
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
        .call(
          _buildFunctionRequest(
            airportDeparture: airportDeparture,
            airportArrival: airportArrival,
            waypoints: waypoints,
            promptVersion: _wikiArticlesPromptVersion,
          ),
        );
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
  }) {
    return <String, dynamic>{
      'waypoints': waypoints.map((c) => [c.latitude, c.longitude]).toList(),
      'airport_departure': airportDeparture,
      'airport_arrival': airportArrival,
      'prompt_version': promptVersion.toString(),
    };
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
