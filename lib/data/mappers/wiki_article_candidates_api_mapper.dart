import 'package:flymap/data/wiki/wikipedia_url_utils.dart';
import 'package:flymap/entity/wiki_article_candidate.dart';
import 'package:flymap/logger.dart';

class WikiArticleCandidatesApiMapper {
  final _logger = const Logger('WikiArticleCandidatesApiMapper');

  List<WikiArticleCandidate> toWikiArticleCandidates(dynamic data) {
    final seen = <String>{};
    final out = <WikiArticleCandidate>[];
    var skippedInvalidUrl = 0;
    var skippedDuplicate = 0;
    var skippedUnsupported = 0;

    final items = _extractWikiItems(data);
    _logger.log(
      'toWikiArticleCandidates inputType=${data.runtimeType} '
      'extractedItems=${items.length}',
    );

    for (final item in items) {
      if (item is String) {
        final parsed = WikipediaUrlUtils.parseArticle(item);
        if (parsed == null) {
          skippedInvalidUrl++;
          continue;
        }
        if (!seen.add(parsed.canonicalUrl)) {
          skippedDuplicate++;
          continue;
        }
        out.add(
          WikiArticleCandidate(
            url: parsed.canonicalUrl,
            title: parsed.title,
            languageCode: parsed.languageCode,
          ),
        );
        continue;
      }

      if (item is! Map) {
        skippedUnsupported++;
        continue;
      }
      final map = item.cast<dynamic, dynamic>();
      final rawUrl = _firstNonEmptyString(map, const [
        'url',
        'wiki_url',
        'wiki',
        'article_url',
        'sourceUrl',
        'source_url',
      ]);
      final parsed = WikipediaUrlUtils.parseArticle(rawUrl);
      if (parsed == null) {
        skippedInvalidUrl++;
        continue;
      }
      if (!seen.add(parsed.canonicalUrl)) {
        skippedDuplicate++;
        continue;
      }

      final title = _firstNonEmptyString(map, const ['title', 'name']);
      final languageCode = _firstNonEmptyString(map, const [
        'languageCode',
        'language_code',
        'lang',
      ]);

      out.add(
        WikiArticleCandidate(
          url: parsed.canonicalUrl,
          title: title.isEmpty ? parsed.title : title,
          languageCode: _isLanguageCodeLike(languageCode)
              ? languageCode
              : parsed.languageCode,
        ),
      );
    }

    final sample = out.take(3).map((e) => e.url).join(', ');
    _logger.log(
      'toWikiArticleCandidates mapped=${out.length} '
      'skippedInvalid=$skippedInvalidUrl '
      'skippedDuplicate=$skippedDuplicate '
      'skippedUnsupported=$skippedUnsupported'
      '${sample.isEmpty ? '' : ' sample=[$sample]'}',
    );

    return out;
  }

  List<dynamic> _extractWikiItems(dynamic data) {
    if (data == null) return const [];
    if (data is List) return data;
    if (data is! Map) return const [];

    final map = data.cast<dynamic, dynamic>();
    final keyed = _firstList(map, const [
      'results',
      'wiki_articles',
      'wikipedia_articles',
      'articles',
      'items',
      'data',
    ]);
    if (keyed != null) return keyed;

    if (map.containsKey('url') || map.containsKey('wiki')) {
      return [map];
    }
    return const [];
  }

  List<dynamic>? _firstList(Map<dynamic, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is List) return value;
    }
    return null;
  }

  String _firstNonEmptyString(Map<dynamic, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = (map[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  bool _isLanguageCodeLike(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    return RegExp(
      r'^[a-z]{2,12}(?:-[a-z0-9]{2,12})*$',
      caseSensitive: false,
    ).hasMatch(trimmed);
  }
}
