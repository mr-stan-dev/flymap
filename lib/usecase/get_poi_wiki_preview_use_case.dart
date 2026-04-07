import 'package:flymap/entity/poi_wiki_preview.dart';
import 'package:flymap/repository/poi_wiki_preview_repository.dart';

class GetPoiWikiPreviewUseCase {
  GetPoiWikiPreviewUseCase({required PoiWikiPreviewRepository repository})
    : _repository = repository;

  final PoiWikiPreviewRepository _repository;
  final Map<String, PoiWikiPreview?> _cache = <String, PoiWikiPreview?>{};

  Future<PoiWikiPreview?> call({
    required String qid,
    required String preferredLanguageCode,
  }) async {
    final normalizedQid = qid.trim().toUpperCase();
    if (normalizedQid.isEmpty) return null;

    if (_cache.containsKey(normalizedQid)) {
      return _cache[normalizedQid];
    }

    final preview = await _repository.getWikiPreviewByQid(
      qid: normalizedQid,
      preferredLanguageCode: preferredLanguageCode,
    );
    _cache[normalizedQid] = preview;
    return preview;
  }
}
