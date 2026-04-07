import 'package:flymap/data/wiki/wikipedia_article_client.dart';
import 'package:flymap/entity/flight_article.dart';

class WikipediaArticlesDownloadProgress {
  const WikipediaArticlesDownloadProgress({
    required this.completed,
    required this.total,
    required this.failed,
  });

  final int completed;
  final int total;
  final int failed;
}

class WikipediaArticlesDownloadResult {
  const WikipediaArticlesDownloadResult({
    required this.articles,
    required this.failedCount,
    required this.cancelled,
  });

  final List<FlightArticle> articles;
  final int failedCount;
  final bool cancelled;
}

class DownloadWikipediaArticlesUseCase {
  DownloadWikipediaArticlesUseCase({
    required WikipediaArticleClient articleClient,
  }) : _articleClient = articleClient;

  final WikipediaArticleClient _articleClient;
  bool _cancelled = false;

  void cancel() {
    _cancelled = true;
  }

  Future<void> cleanupBundleMedia(String bundleId) async {
    await _articleClient.cleanupBundleMedia(bundleId);
  }

  Future<WikipediaArticlesDownloadResult> call({
    required String bundleId,
    required List<String> articleUrls,
    required void Function(WikipediaArticlesDownloadProgress progress)
    onProgress,
  }) async {
    _cancelled = false;
    final urls = articleUrls.toSet().toList();

    if (urls.isEmpty) {
      return const WikipediaArticlesDownloadResult(
        articles: <FlightArticle>[],
        failedCount: 0,
        cancelled: false,
      );
    }

    final downloadedArticles = <FlightArticle>[];
    var completed = 0;
    var failed = 0;

    for (final url in urls) {
      if (_cancelled) {
        return WikipediaArticlesDownloadResult(
          articles: downloadedArticles,
          failedCount: failed,
          cancelled: true,
        );
      }

      try {
        final article = await _articleClient.downloadArticle(
          sourceUrl: url,
          bundleId: bundleId,
        );
        if (article != null) {
          downloadedArticles.add(article);
        } else {
          failed++;
        }
      } catch (_) {
        failed++;
      }

      completed++;
      onProgress(
        WikipediaArticlesDownloadProgress(
          completed: completed,
          total: urls.length,
          failed: failed,
        ),
      );
    }

    return WikipediaArticlesDownloadResult(
      articles: downloadedArticles,
      failedCount: failed,
      cancelled: false,
    );
  }
}
