import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/wiki/wikipedia_article_client.dart';
import 'package:flymap/entity/flight_article.dart';
import 'package:flymap/usecase/download_wikipedia_articles_use_case.dart';

void main() {
  group('DownloadWikipediaArticlesUseCase', () {
    test('continues on per-article failure and reports progress', () async {
      final client = _FakeWikipediaArticleClient(
        responses: {'u1': _article('u1'), 'u2': null, 'u3': _article('u3')},
      );
      final useCase = DownloadWikipediaArticlesUseCase(articleClient: client);
      final progress = <WikipediaArticlesDownloadProgress>[];

      final result = await useCase.call(
        bundleId: 'bundle',
        articleUrls: const ['u1', 'u2', 'u3'],
        onProgress: progress.add,
      );

      expect(result.cancelled, isFalse);
      expect(result.articles.length, 2);
      expect(result.failedCount, 1);
      expect(progress.last.completed, 3);
      expect(progress.last.total, 3);
      expect(progress.last.failed, 1);
    });

    test('downloads all selected urls', () async {
      final urls = List.generate(12, (i) => 'u$i');
      final client = _FakeWikipediaArticleClient(
        responses: {for (final url in urls) url: _article(url)},
      );
      final useCase = DownloadWikipediaArticlesUseCase(articleClient: client);

      final result = await useCase.call(
        bundleId: 'bundle',
        articleUrls: urls,
        onProgress: (_) {},
      );

      expect(result.articles.length, 12);
      expect(client.calls, 12);
    });

    test('supports cancellation mid-download', () async {
      final client = _FakeWikipediaArticleClient(
        responses: {'u1': _article('u1'), 'u2': _article('u2')},
      );
      final useCase = DownloadWikipediaArticlesUseCase(articleClient: client);

      final result = await useCase.call(
        bundleId: 'bundle',
        articleUrls: const ['u1', 'u2'],
        onProgress: (p) {
          if (p.completed == 1) {
            useCase.cancel();
          }
        },
      );

      expect(result.cancelled, isTrue);
      expect(result.articles.length, 1);
      expect(client.calls, 1);
    });
  });
}

FlightArticle _article(String source) {
  return FlightArticle(
    sourceUrl: source,
    title: source,
    summary: '',
    contentPlainText: 'content',
    contentHtml: '<html><body>content</body></html>',
    languageCode: 'en',
    leadImageRelativePath: '',
    inlineImageRelativePaths: const [],
    attributionText: '',
    licenseText: '',
    downloadedAt: DateTime(2026, 1, 1),
    sizeBytes: 100,
  );
}

class _FakeWikipediaArticleClient extends WikipediaArticleClient {
  _FakeWikipediaArticleClient({required this.responses});

  final Map<String, FlightArticle?> responses;
  int calls = 0;

  @override
  Future<FlightArticle?> downloadArticle({
    required String sourceUrl,
    required String bundleId,
  }) async {
    calls++;
    return responses[sourceUrl];
  }
}
