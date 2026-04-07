import 'package:flymap/data/mappers/flight_info_overview_api_mapper.dart';
import 'package:flymap/data/mappers/wiki_article_candidates_api_mapper.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/wiki_article_candidate.dart';

class FlightInfoApiMapper {
  FlightInfoApiMapper({
    FlightInfoOverviewApiMapper? overviewMapper,
    WikiArticleCandidatesApiMapper? wikiCandidatesMapper,
  }) : _overviewMapper = overviewMapper ?? FlightInfoOverviewApiMapper(),
       _wikiCandidatesMapper =
           wikiCandidatesMapper ?? WikiArticleCandidatesApiMapper();

  final FlightInfoOverviewApiMapper _overviewMapper;
  final WikiArticleCandidatesApiMapper _wikiCandidatesMapper;

  FlightInfo toFlightInfo(Map<String, dynamic> map) =>
      _overviewMapper.toFlightInfo(map);

  List<WikiArticleCandidate> toWikiArticleCandidates(dynamic data) =>
      _wikiCandidatesMapper.toWikiArticleCandidates(data);
}
