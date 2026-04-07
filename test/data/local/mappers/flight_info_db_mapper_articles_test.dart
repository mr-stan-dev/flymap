import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/local/mappers/flight_article_db_mapper.dart';
import 'package:flymap/data/local/mappers/flight_info_db_mapper.dart';
import 'package:flymap/entity/flight_article.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_poi_type.dart';
import 'package:flymap/entity/route_poi.dart';
import 'package:flymap/entity/route_poi_summary.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('FlightInfoDbMapper articles', () {
    test('roundtrips articles with poi and overview', () {
      final mapper = FlightInfoDbMapper();
      final info = FlightInfo(
        'overview',
        [
          RoutePoiSummary(
            poi: const RoutePoi(
              qid: 'Q786',
              name: 'Alps',
              latLon: LatLng(1, 2),
              type: FlightPoiType.mountain,
              sitelinks: 100,
            ),
            description: 'desc',
            wiki: 'https://en.wikipedia.org/wiki/Alps',
          ),
        ],
        [
          FlightArticle(
            sourceUrl: 'https://en.wikipedia.org/wiki/Alps',
            title: 'Alps',
            summary: 'summary',
            contentPlainText: 'content',
            contentHtml: '<html><body><p>content</p></body></html>',
            languageCode: 'en',
            leadImageRelativePath: 'article_media/test/alps.jpg',
            inlineImageRelativePaths: const [
              'article_media/test/alps_1.jpg',
              'article_media/test/alps_2.jpg',
            ],
            attributionText: 'attr',
            licenseText: 'license',
            downloadedAt: DateTime(2026, 1, 1),
            sizeBytes: 1234,
          ),
        ],
      );

      final map = mapper.toFlightInfoMap(info);
      final restored = mapper.toFlightInfo(map);

      expect(restored, info);
      expect(restored.articles.single.title, 'Alps');
    });

    test('reads old records that do not contain articles key', () {
      final mapper = FlightInfoDbMapper();
      final legacyMap = <String, dynamic>{
        FlightInfoDBKeys.overview: 'legacy',
        FlightInfoDBKeys.poi: const <Map<String, dynamic>>[],
      };

      final restored = mapper.toFlightInfo(legacyMap);

      expect(restored.overview, 'legacy');
      expect(restored.articles, isEmpty);
    });

    test('reads legacy article records without html fields', () {
      final mapper = FlightInfoDbMapper();
      final legacyMap = <String, dynamic>{
        FlightInfoDBKeys.overview: 'legacy',
        FlightInfoDBKeys.poi: const <Map<String, dynamic>>[],
        FlightInfoDBKeys.articles: <Map<String, dynamic>>[
          <String, dynamic>{
            FlightArticleDBKeys.sourceUrl: 'https://en.wikipedia.org/wiki/Alps',
            FlightArticleDBKeys.title: 'Alps',
            FlightArticleDBKeys.summary: 'summary',
            FlightArticleDBKeys.contentPlainText: 'content',
            FlightArticleDBKeys.languageCode: 'en',
            FlightArticleDBKeys.leadImageRelativePath: '',
            FlightArticleDBKeys.attributionText: 'Source',
            FlightArticleDBKeys.licenseText: 'CC BY-SA',
            FlightArticleDBKeys.downloadedAt: DateTime(
              2026,
              1,
              1,
            ).toIso8601String(),
            FlightArticleDBKeys.sizeBytes: 42,
          },
        ],
      };

      final restored = mapper.toFlightInfo(legacyMap);
      final article = restored.articles.single;

      expect(article.contentHtml, isEmpty);
      expect(article.inlineImageRelativePaths, isEmpty);
    });
  });
}
