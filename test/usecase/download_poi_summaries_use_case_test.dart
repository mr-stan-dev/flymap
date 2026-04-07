import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/entity/flight_poi_type.dart';
import 'package:flymap/entity/poi_wiki_preview.dart';
import 'package:flymap/entity/route_poi.dart';
import 'package:flymap/entity/route_poi_summary.dart';
import 'package:flymap/repository/poi_wiki_preview_repository.dart';
import 'package:flymap/usecase/download_poi_summaries_use_case.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('DownloadPoiSummariesUseCase', () {
    test('emits incremental progress in chunks', () async {
      final pois = List.generate(45, (i) => _poi('Q${i + 1}'));
      final repository = _FakePoiWikiPreviewRepository();
      final useCase = DownloadPoiSummariesUseCase(repository: repository);
      final progress = <PoiSummariesDownloadProgress>[];

      final result = await useCase.call(
        pois: pois,
        preferredLanguageCode: 'en',
        onProgress: progress.add,
      );

      expect(result.cancelled, isFalse);
      expect(result.failedCount, 0);
      expect(progress.map((p) => p.completed), [0, 10, 20, 30, 40, 45]);
      expect(progress.last.total, 45);
      expect(repository.calls.map((c) => c.length), [10, 10, 10, 10, 5]);
    });

    test('tracks failed preview count across chunks', () async {
      final pois = List.generate(45, (i) => _poi('Q${i + 1}'));
      final repository = _FakePoiWikiPreviewRepository(
        missingQids: const {'Q3', 'Q21', 'Q44'},
      );
      final useCase = DownloadPoiSummariesUseCase(repository: repository);
      final progress = <PoiSummariesDownloadProgress>[];

      final result = await useCase.call(
        pois: pois,
        preferredLanguageCode: 'en',
        onProgress: progress.add,
      );

      expect(result.cancelled, isFalse);
      expect(result.failedCount, 3);
      expect(progress.last.failed, 3);
    });
  });
}

RoutePoiSummary _poi(String qid) {
  return RoutePoiSummary(
    poi: RoutePoi(
      qid: qid,
      name: qid,
      latLon: const LatLng(0, 0),
      type: FlightPoiType.city,
      sitelinks: 100,
    ),
  );
}

class _FakePoiWikiPreviewRepository implements PoiWikiPreviewRepository {
  _FakePoiWikiPreviewRepository({this.missingQids = const <String>{}});

  final Set<String> missingQids;
  final List<List<String>> calls = <List<String>>[];

  @override
  Future<PoiWikiPreview?> getWikiPreviewByQid({
    required String qid,
    required String preferredLanguageCode,
  }) async {
    if (missingQids.contains(qid)) return null;
    return PoiWikiPreview(
      qid: qid,
      title: qid,
      summary: 'Summary for $qid',
      sourceUrl: 'https://en.wikipedia.org/wiki/$qid',
      languageCode: preferredLanguageCode,
    );
  }

  @override
  Future<Map<String, PoiWikiPreview>> batchGetWikiPreviews({
    required List<String> qids,
    required String preferredLanguageCode,
  }) async {
    calls.add(List<String>.from(qids));
    final map = <String, PoiWikiPreview>{};
    for (final qid in qids) {
      if (missingQids.contains(qid)) continue;
      map[qid] = PoiWikiPreview(
        qid: qid,
        title: qid,
        summary: 'Summary for $qid',
        sourceUrl: 'https://en.wikipedia.org/wiki/$qid',
        languageCode: preferredLanguageCode,
      );
    }
    return map;
  }
}
