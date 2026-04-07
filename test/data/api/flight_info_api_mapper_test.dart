import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/api/flight_info_api_mapper.dart';

void main() {
  group('FlightInfoApiMapper.toWikiArticleCandidates', () {
    test('parses firebase results with wiki_url', () {
      final mapper = FlightInfoApiMapper();

      final result = mapper.toWikiArticleCandidates({
        'results': [
          {
            'title': 'London Heathrow Airport',
            'wiki_url': 'https://en.wikipedia.org/wiki/Heathrow_Airport',
          },
          {
            'title': 'Adolfo Suarez Madrid-Barajas Airport',
            'wiki_url':
                'https://en.wikipedia.org/wiki/Adolfo_Su%C3%A1rez_Madrid%E2%80%93Barajas_Airport',
          },
        ],
      });

      expect(result.length, 2);
      expect(result[0].url, 'https://en.wikipedia.org/wiki/Heathrow_Airport');
      expect(result[0].title, 'London Heathrow Airport');
      expect(result[0].languageCode, 'en');
      expect(
        result[1].url,
        'https://en.wikipedia.org/wiki/Adolfo_Su%C3%A1rez_Madrid%E2%80%93Barajas_Airport',
      );
      expect(result[1].title, 'Adolfo Suarez Madrid-Barajas Airport');
      expect(result[1].languageCode, 'en');
    });

    test('parses and dedupes candidates from map response', () {
      final mapper = FlightInfoApiMapper();

      final result = mapper.toWikiArticleCandidates({
        'wiki_articles': [
          {
            'url': 'https://en.wikipedia.org/wiki/London',
            'title': 'London (city)',
            'language_code': 'en',
          },
          'https://en.wikipedia.org/wiki/London',
          {'wiki': 'https://fr.wikipedia.org/wiki/Paris'},
        ],
      });

      expect(result.length, 2);
      expect(result[0].url, 'https://en.wikipedia.org/wiki/London');
      expect(result[0].title, 'London (city)');
      expect(result[0].languageCode, 'en');
      expect(result[1].url, 'https://fr.wikipedia.org/wiki/Paris');
      expect(result[1].title, 'Paris');
      expect(result[1].languageCode, 'fr');
    });

    test('parses list response with mixed shapes', () {
      final mapper = FlightInfoApiMapper();

      final result = mapper.toWikiArticleCandidates([
        'not-a-url',
        {
          'source_url': 'https://en.wikipedia.org/wiki/Heathrow_Airport',
          'lang': 'en',
        },
      ]);

      expect(result.length, 1);
      expect(
        result.single.url,
        'https://en.wikipedia.org/wiki/Heathrow_Airport',
      );
      expect(result.single.title, 'Heathrow Airport');
      expect(result.single.languageCode, 'en');
    });

    test('parses single-map response', () {
      final mapper = FlightInfoApiMapper();

      final result = mapper.toWikiArticleCandidates({
        'url': 'https://en.wikipedia.org/wiki/Charles_de_Gaulle_Airport',
      });

      expect(result.length, 1);
      expect(
        result.single.url,
        'https://en.wikipedia.org/wiki/Charles_de_Gaulle_Airport',
      );
      expect(result.single.title, 'Charles de Gaulle Airport');
      expect(result.single.languageCode, 'en');
    });
  });

  group('FlightInfoApiMapper.toFlightInfo', () {
    test('maps overview and ignores poi payload in active flow', () {
      final mapper = FlightInfoApiMapper();

      final info = mapper.toFlightInfo({
        'overview': 'Route overview',
        'poi': [
          {
            'name': 'Alps',
            'type': 'mountain_range',
            'coordinates': [46.5, 10.5],
            'qid': 'Q1286',
            'sitelinks': 1200,
          },
        ],
      });

      expect(info.overview, 'Route overview');
      expect(info.poi, isEmpty);
    });

    test('maps nested overview and ignores nested pois payload', () {
      final mapper = FlightInfoApiMapper();

      final info = mapper.toFlightInfo({
        'results': {
          'overview': 'Nested overview',
          'pois': [
            {
              'title': 'Danube',
              'place_type': 'river',
              'lat': 48.2,
              'lon': 16.37,
              'id': 'Q1653',
            },
          ],
        },
      });

      expect(info.overview, 'Nested overview');
      expect(info.poi, isEmpty);
    });
  });
}
