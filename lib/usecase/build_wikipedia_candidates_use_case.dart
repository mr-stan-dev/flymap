import 'package:flymap/data/wiki/wikipedia_url_utils.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/wiki_article_candidate.dart';

class BuildWikipediaCandidatesUseCase {
  const BuildWikipediaCandidatesUseCase();

  List<WikiArticleCandidate> call({required FlightInfo flightInfo}) {
    final orderedUrls = <String>[...flightInfo.poi.map((poi) => poi.wiki)];

    final seen = <String>{};
    final out = <WikiArticleCandidate>[];

    for (final rawUrl in orderedUrls) {
      final parsed = WikipediaUrlUtils.parseArticle(rawUrl);
      if (parsed == null) continue;
      if (!seen.add(parsed.canonicalUrl)) continue;
      out.add(
        WikiArticleCandidate(
          url: parsed.canonicalUrl,
          title: parsed.title,
          languageCode: parsed.languageCode,
        ),
      );
    }

    return out;
  }
}
