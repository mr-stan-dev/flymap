class WikipediaArticleRef {
  const WikipediaArticleRef({
    required this.languageCode,
    required this.title,
    required this.encodedTitle,
    required this.canonicalUrl,
  });

  final String languageCode;
  final String title;
  final String encodedTitle;
  final String canonicalUrl;
}

class WikipediaUrlUtils {
  static WikipediaArticleRef? parseArticle(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;

    final host = uri.host.toLowerCase();
    if (!host.endsWith('.wikipedia.org')) return null;
    final languageCode = host.split('.').first;
    if (languageCode.isEmpty || languageCode == 'www') return null;

    if (uri.pathSegments.length < 2) return null;
    if (uri.pathSegments.first != 'wiki') return null;

    final rawTitleSegment = uri.pathSegments[1].trim();
    if (rawTitleSegment.isEmpty) return null;

    final title = rawTitleSegment.replaceAll('_', ' ').trim();
    if (title.isEmpty) return null;
    if (title.contains(':')) return null;

    final canonicalEncoded = Uri.encodeComponent(title.replaceAll(' ', '_'));
    final canonicalUrl =
        'https://$languageCode.wikipedia.org/wiki/$canonicalEncoded';

    return WikipediaArticleRef(
      languageCode: languageCode,
      title: title,
      encodedTitle: canonicalEncoded,
      canonicalUrl: canonicalUrl,
    );
  }
}
