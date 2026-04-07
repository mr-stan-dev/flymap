import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/entity/poi_wiki_preview.dart';
import 'package:flymap/repository/poi_wiki_preview_repository.dart';
import 'package:flymap/usecase/get_poi_wiki_preview_use_case.dart';

void main() {
  group('GetPoiWikiPreviewUseCase', () {
    test('returns cached result for repeated qid lookups', () async {
      final repository = _FakePoiWikiPreviewRepository();
      final useCase = GetPoiWikiPreviewUseCase(repository: repository);

      final first = await useCase.call(
        qid: 'q123',
        preferredLanguageCode: 'fr',
      );
      final second = await useCase.call(
        qid: 'Q123',
        preferredLanguageCode: 'en',
      );

      expect(first, isNotNull);
      expect(second, first);
      expect(repository.calls, 1);
    });
  });
}

class _FakePoiWikiPreviewRepository implements PoiWikiPreviewRepository {
  int calls = 0;

  @override
  Future<Map<String, PoiWikiPreview>> batchGetWikiPreviews({
    required List<String> qids,
    required String preferredLanguageCode,
  }) async {
    return {
      for (final qid in qids)
        qid: PoiWikiPreview(
          qid: qid,
          title: 'Sample',
          summary: 'Summary',
          sourceUrl: 'https://en.wikipedia.org/wiki/Sample',
          languageCode: 'en',
        ),
    };
  }

  @override
  Future<PoiWikiPreview?> getWikiPreviewByQid({
    required String qid,
    required String preferredLanguageCode,
  }) async {
    calls++;
    return PoiWikiPreview(
      qid: qid,
      title: 'Sample',
      summary: 'Summary',
      sourceUrl: 'https://en.wikipedia.org/wiki/Sample',
      languageCode: 'en',
    );
  }
}
