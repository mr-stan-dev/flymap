import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/wiki/wikipedia_url_utils.dart';

void main() {
  group('WikipediaUrlUtils.parseArticle', () {
    test('canonicalizes a valid wikipedia article url', () {
      final parsed = WikipediaUrlUtils.parseArticle(
        'http://en.wikipedia.org/wiki/New_York_City?foo=bar',
      );

      expect(parsed, isNotNull);
      expect(parsed!.languageCode, 'en');
      expect(parsed.title, 'New York City');
      expect(
        parsed.canonicalUrl,
        'https://en.wikipedia.org/wiki/New_York_City',
      );
    });

    test('rejects non wikipedia and invalid wiki urls', () {
      expect(
        WikipediaUrlUtils.parseArticle('https://example.com/wiki/New_York'),
        isNull,
      );
      expect(
        WikipediaUrlUtils.parseArticle('https://en.wikipedia.org/w/index.php'),
        isNull,
      );
      expect(
        WikipediaUrlUtils.parseArticle(
          'https://en.wikipedia.org/wiki/Category:Cities',
        ),
        isNull,
      );
    });

    test('does not throw on malformed percent encoding', () {
      expect(
        () => WikipediaUrlUtils.parseArticle(
          'https://en.wikipedia.org/wiki/100%_real',
        ),
        returnsNormally,
      );
    });
  });
}
