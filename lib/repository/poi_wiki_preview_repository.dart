import 'package:flymap/entity/poi_wiki_preview.dart';

abstract interface class PoiWikiPreviewRepository {
  /// Fetches a single POI preview (dialog tap, live/online use).
  Future<PoiWikiPreview?> getWikiPreviewByQid({
    required String qid,
    required String preferredLanguageCode,
  });

  /// Fetches previews for many QIDs in bulk using batched API calls.
  /// Returns a map of normalised QID → preview; missing QIDs are absent.
  Future<Map<String, PoiWikiPreview>> batchGetWikiPreviews({
    required List<String> qids,
    required String preferredLanguageCode,
  });
}
