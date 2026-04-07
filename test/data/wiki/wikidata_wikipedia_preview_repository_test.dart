import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/wiki/wikidata_wikipedia_preview_repository.dart';
import 'package:flymap/data/wiki/wikimedia_api_client.dart';
import 'package:http/http.dart' as http;

void main() {
  group('WikidataWikipediaPreviewRepository', () {
    test(
      'includes sanitized html content when parse response is available',
      () async {
        final apiClient = _FakeWikimediaApiClient((uri) {
          if (uri.host == 'www.wikidata.org') {
            return _json({
              'entities': {
                'Q0': {
                  'sitelinks': {
                    'enwiki': {'title': 'Sample Place'},
                  },
                },
              },
            });
          }

          final action = uri.queryParameters['action'];
          if (action == 'parse') {
            return _wikipediaParseResponse(
              html:
                  '<div><h2>History</h2><p>Sample paragraph.</p><script>alert(1)</script></div>',
            );
          }

          return _wikipediaExtractResponse(
            title: 'Sample Place',
            extract: 'Sample Place has a useful plaintext extract.',
          );
        });
        final repository = WikidataWikipediaPreviewRepository(
          apiClient: apiClient,
        );

        final result = await repository.batchGetWikiPreviews(
          qids: const ['Q0'],
          preferredLanguageCode: 'en',
        );

        final html = result['Q0']?.htmlContent ?? '';
        expect(html, contains('<h2>History</h2>'));
        expect(html, contains('<p>Sample paragraph.</p>'));
        expect(html, isNot(contains('<script')));
      },
    );

    test('uses full extract as primary source', () async {
      final apiClient = _FakeWikimediaApiClient((uri) {
        if (uri.host == 'www.wikidata.org') {
          return _json({
            'entities': {
              'Q1': {
                'sitelinks': {
                  'enwiki': {'title': 'Paris'},
                },
                'descriptions': {
                  'en': {'value': 'Capital of France'},
                },
              },
            },
          });
        }
        return _wikipediaExtractResponse(
          title: 'Paris',
          extract:
              'Paris is the capital and most populous city of France with a long history, '
              'major cultural influence, and globally recognized landmarks.',
        );
      });
      final repository = WikidataWikipediaPreviewRepository(
        apiClient: apiClient,
      );

      final result = await repository.batchGetWikiPreviews(
        qids: const ['Q1'],
        preferredLanguageCode: 'en',
      );

      expect(result['Q1'], isNotNull);
      expect(result['Q1']!.title, 'Paris');
      expect(result['Q1']!.summary, contains('capital and most populous city'));
      expect(apiClient.fullExtractCalls, 1);
    });

    test('uses full extract when intro is weak', () async {
      final apiClient = _FakeWikimediaApiClient((uri) {
        if (uri.host == 'www.wikidata.org') {
          return _json({
            'entities': {
              'Q2': {
                'sitelinks': {
                  'enwiki': {'title': 'Lanzarote'},
                },
                'descriptions': {
                  'en': {'value': 'Island in the Canary Islands'},
                },
              },
            },
          });
        }

        final isIntro = uri.queryParameters['exintro'] == '1';
        return _wikipediaExtractResponse(
          title: 'Lanzarote',
          extract: isIntro
              ? 'Lanzarote'
              : 'Lanzarote is a Spanish island in the Atlantic Ocean and the '
                    'easternmost of the autonomous Canary Islands. It features '
                    'volcanic landscapes, protected parks, and a long coastline '
                    'that makes it one of the most visited islands in the region.',
        );
      });
      final repository = WikidataWikipediaPreviewRepository(
        apiClient: apiClient,
      );

      final result = await repository.batchGetWikiPreviews(
        qids: const ['Q2'],
        preferredLanguageCode: 'en',
      );

      expect(result['Q2'], isNotNull);
      expect(result['Q2']!.summary, contains('Spanish island in the Atlantic'));
      expect(apiClient.fullExtractCalls, 1);
    });

    test(
      'falls back to Wikidata description when intro and full are both weak',
      () async {
        final apiClient = _FakeWikimediaApiClient((uri) {
          if (uri.host == 'www.wikidata.org') {
            return _json({
              'entities': {
                'Q3': {
                  'sitelinks': {
                    'enwiki': {'title': 'Example Place'},
                  },
                  'descriptions': {
                    'en': {'value': 'Historic mountain pass'},
                  },
                },
              },
            });
          }

          return _wikipediaExtractResponse(
            title: 'Example Place',
            extract: 'Example Place',
          );
        });
        final repository = WikidataWikipediaPreviewRepository(
          apiClient: apiClient,
        );

        final result = await repository.batchGetWikiPreviews(
          qids: const ['Q3'],
          preferredLanguageCode: 'en',
        );

        expect(result['Q3'], isNotNull);
        expect(result['Q3']!.summary, 'Historic mountain pass');
      },
    );

    test('falls back to title when no strong summary exists', () async {
      final apiClient = _FakeWikimediaApiClient((uri) {
        if (uri.host == 'www.wikidata.org') {
          return _json({
            'entities': {
              'Q4': {
                'sitelinks': {
                  'enwiki': {'title': 'Tiny Place'},
                },
              },
            },
          });
        }
        return _wikipediaExtractResponse(title: 'Tiny Place', extract: '');
      });
      final repository = WikidataWikipediaPreviewRepository(
        apiClient: apiClient,
      );

      final result = await repository.batchGetWikiPreviews(
        qids: const ['Q4'],
        preferredLanguageCode: 'en',
      );

      expect(result['Q4'], isNotNull);
      expect(result['Q4']!.summary, 'Tiny Place');
    });

    test('stores long full text without summary-mode truncation', () async {
      final veryLong = List.filled(
        220,
        'Lanzarote has volcanic landscapes and protected natural areas.',
      ).join(' ');
      final apiClient = _FakeWikimediaApiClient((uri) {
        if (uri.host == 'www.wikidata.org') {
          return _json({
            'entities': {
              'Q5': {
                'sitelinks': {
                  'enwiki': {'title': 'Long Place'},
                },
              },
            },
          });
        }
        return _wikipediaExtractResponse(
          title: 'Long Place',
          extract: veryLong,
        );
      });
      final repository = WikidataWikipediaPreviewRepository(
        apiClient: apiClient,
      );

      final result = await repository.batchGetWikiPreviews(
        qids: const ['Q5'],
        preferredLanguageCode: 'en',
      );

      expect(result['Q5'], isNotNull);
      final summary = result['Q5']!.summary;
      expect(summary.length, equals(veryLong.length));
    });

    test('falls back to enwiki when preferred locale is unavailable', () async {
      final apiClient = _FakeWikimediaApiClient((uri) {
        if (uri.host == 'www.wikidata.org') {
          return _json({
            'entities': {
              'Q6': {
                'sitelinks': {
                  'enwiki': {'title': 'Sydney'},
                },
                'descriptions': {
                  'en': {'value': 'City in Australia'},
                },
              },
            },
          });
        }
        return _wikipediaExtractResponse(
          title: 'Sydney',
          extract:
              'Sydney is the capital city of New South Wales and the most populous city in Australia.',
        );
      });
      final repository = WikidataWikipediaPreviewRepository(
        apiClient: apiClient,
      );

      final result = await repository.batchGetWikiPreviews(
        qids: const ['Q6'],
        preferredLanguageCode: 'fr',
      );

      expect(result['Q6'], isNotNull);
      expect(result['Q6']!.languageCode, 'en');
      expect(result['Q6']!.sourceUrl, 'https://en.wikipedia.org/wiki/Sydney');
    });

    test(
      'preserves paragraph breaks and normalizes section heading markers',
      () async {
        final apiClient = _FakeWikimediaApiClient((uri) {
          if (uri.host == 'www.wikidata.org') {
            return _json({
              'entities': {
                'Q7': {
                  'sitelinks': {
                    'enwiki': {'title': 'Readable Place'},
                  },
                },
              },
            });
          }
          return _wikipediaExtractResponse(
            title: 'Readable Place',
            extract:
                'Readable Place is a location with rich context.\n\n'
                '== History ==\n\n'
                'It has a long history and notable events across multiple eras, '
                'with several major turning points documented in regional records.',
          );
        });
        final repository = WikidataWikipediaPreviewRepository(
          apiClient: apiClient,
        );

        final result = await repository.batchGetWikiPreviews(
          qids: const ['Q7'],
          preferredLanguageCode: 'en',
        );

        final summary = result['Q7']?.summary ?? '';
        expect(summary, contains('\n\nHistory\n\n'));
        expect(summary, isNot(contains('== History ==')));
        expect(summary, contains('Readable Place is a location'));
        expect(summary, contains('It has a long history'));
      },
    );

    test(
      'fetches full extracts per title to avoid multi-title full-extract gaps',
      () async {
        final apiClient = _FakeWikimediaApiClient((uri) {
          if (uri.host == 'www.wikidata.org') {
            return _json({
              'entities': {
                'Q10': {
                  'sitelinks': {
                    'enwiki': {'title': 'First Place'},
                  },
                },
                'Q11': {
                  'sitelinks': {
                    'enwiki': {'title': 'Second Place'},
                  },
                },
              },
            });
          }

          final titles = (uri.queryParameters['titles'] ?? '').split('|');
          final isFullExtract = uri.queryParameters['exintro'] != '1';
          if (isFullExtract && titles.length > 1) {
            // Simulate Wikimedia behavior where multi-title full extracts
            // don't return text for every page.
            return _json({
              'query': {
                'pages': [
                  {'title': 'First Place', 'extract': 'First full extract'},
                  {'title': 'Second Place', 'extract': ''},
                ],
              },
            });
          }

          final title = titles.first;
          final extract = title == 'First Place'
              ? 'First full extract with meaningful details, historical notes, '
                    'geographic context, and references to landmarks that make '
                    'the content clearly longer than the weak-summary threshold.'
              : 'Second full extract with meaningful details, historical notes, '
                    'geographic context, and references to landmarks that make '
                    'the content clearly longer than the weak-summary threshold.';
          return _wikipediaExtractResponse(title: title, extract: extract);
        });
        final repository = WikidataWikipediaPreviewRepository(
          apiClient: apiClient,
        );

        final result = await repository.batchGetWikiPreviews(
          qids: const ['Q10', 'Q11'],
          preferredLanguageCode: 'en',
        );

        expect(result['Q10']?.summary, contains('First full extract'));
        expect(result['Q11']?.summary, contains('Second full extract'));
        expect(apiClient.fullExtractCalls, 2);
      },
    );
  });
}

http.Response _json(Map<String, dynamic> body) {
  return http.Response(jsonEncode(body), 200);
}

http.Response _wikipediaExtractResponse({
  required String title,
  required String extract,
}) {
  return _json({
    'query': {
      'pages': [
        {'title': title, 'extract': extract},
      ],
    },
  });
}

http.Response _wikipediaParseResponse({required String html}) {
  return _json({
    'parse': {'text': html},
  });
}

class _FakeWikimediaApiClient extends WikimediaApiClient {
  _FakeWikimediaApiClient(this._handler)
    : super(
        httpClient: http.Client(),
        userAgentProvider: _StaticWikimediaUserAgentProvider(),
      );

  final http.Response Function(Uri uri) _handler;
  int fullExtractCalls = 0;

  @override
  Future<http.Response> get(
    Uri uri, {
    required Duration timeout,
    Map<String, String>? headers,
  }) async {
    if (uri.host.endsWith('.wikipedia.org') &&
        uri.queryParameters['action'] == 'query' &&
        uri.queryParameters['prop'] == 'extracts' &&
        uri.queryParameters['exintro'] != '1') {
      fullExtractCalls++;
    }
    return _handler(uri);
  }
}

class _StaticWikimediaUserAgentProvider implements WikimediaUserAgentProvider {
  @override
  Future<String> getUserAgent() async => 'test-agent';
}
