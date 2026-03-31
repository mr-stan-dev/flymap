import 'package:flymap/entity/flight_article.dart';

import 'mapper_utils.dart';

class FlightArticleDBKeys {
  static const sourceUrl = 'sourceUrl';
  static const title = 'title';
  static const summary = 'summary';
  static const contentPlainText = 'contentPlainText';
  static const contentHtml = 'contentHtml';
  static const languageCode = 'languageCode';
  static const leadImageRelativePath = 'leadImageRelativePath';
  static const inlineImageRelativePaths = 'inlineImageRelativePaths';
  static const attributionText = 'attributionText';
  static const licenseText = 'licenseText';
  static const downloadedAt = 'downloadedAt';
  static const sizeBytes = 'sizeBytes';
}

class FlightArticleDbMapper {
  FlightArticle? fromDb(Map<String, dynamic> map) {
    final sourceUrl = map.getString(FlightArticleDBKeys.sourceUrl);
    final title = map.getString(FlightArticleDBKeys.title);
    final downloadedAtRaw = map.getString(FlightArticleDBKeys.downloadedAt);
    final downloadedAt = DateTime.tryParse(downloadedAtRaw);
    if (sourceUrl.isEmpty || title.isEmpty || downloadedAt == null) {
      return null;
    }

    return FlightArticle(
      sourceUrl: sourceUrl,
      title: title,
      summary: map.getString(FlightArticleDBKeys.summary),
      contentPlainText: map.getString(FlightArticleDBKeys.contentPlainText),
      contentHtml: map.getString(FlightArticleDBKeys.contentHtml),
      languageCode: map.getString(FlightArticleDBKeys.languageCode),
      leadImageRelativePath: map.getString(
        FlightArticleDBKeys.leadImageRelativePath,
      ),
      inlineImageRelativePaths: map
          .getList(FlightArticleDBKeys.inlineImageRelativePaths)
          .whereType<String>()
          .where((path) => path.trim().isNotEmpty)
          .toList(),
      attributionText: map.getString(FlightArticleDBKeys.attributionText),
      licenseText: map.getString(FlightArticleDBKeys.licenseText),
      downloadedAt: downloadedAt,
      sizeBytes: map.getInt(FlightArticleDBKeys.sizeBytes),
    );
  }

  Map<String, dynamic> toDb(FlightArticle article) => <String, dynamic>{
    FlightArticleDBKeys.sourceUrl: article.sourceUrl,
    FlightArticleDBKeys.title: article.title,
    FlightArticleDBKeys.summary: article.summary,
    FlightArticleDBKeys.contentPlainText: article.contentPlainText,
    FlightArticleDBKeys.contentHtml: article.contentHtml,
    FlightArticleDBKeys.languageCode: article.languageCode,
    FlightArticleDBKeys.leadImageRelativePath: article.leadImageRelativePath,
    FlightArticleDBKeys.inlineImageRelativePaths:
        article.inlineImageRelativePaths,
    FlightArticleDBKeys.attributionText: article.attributionText,
    FlightArticleDBKeys.licenseText: article.licenseText,
    FlightArticleDBKeys.downloadedAt: article.downloadedAt.toIso8601String(),
    FlightArticleDBKeys.sizeBytes: article.sizeBytes,
  };
}
