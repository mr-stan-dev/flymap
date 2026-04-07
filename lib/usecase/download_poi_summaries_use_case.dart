import 'dart:math' as math;

import 'package:flymap/entity/poi_wiki_preview.dart';
import 'package:flymap/entity/route_poi_summary.dart';
import 'package:flymap/repository/poi_wiki_preview_repository.dart';

class PoiSummariesDownloadProgress {
  const PoiSummariesDownloadProgress({
    required this.completed,
    required this.total,
    required this.failed,
  });

  final int completed;
  final int total;
  final int failed;
}

class PoiSummariesDownloadResult {
  const PoiSummariesDownloadResult({
    required this.pois,
    required this.failedCount,
    required this.cancelled,
  });

  final List<RoutePoiSummary> pois;
  final int failedCount;
  final bool cancelled;
}

class DownloadPoiSummariesUseCase {
  DownloadPoiSummariesUseCase({required PoiWikiPreviewRepository repository})
    : _repository = repository;

  // Smaller chunks provide smoother UI progress updates while keeping
  // repository batching overhead reasonable for large POI sets.
  static const _progressChunkSize = 10;

  final PoiWikiPreviewRepository _repository;
  bool _cancelled = false;

  void cancel() {
    _cancelled = true;
  }

  Future<PoiSummariesDownloadResult> call({
    required List<RoutePoiSummary> pois,
    required String preferredLanguageCode,
    required void Function(PoiSummariesDownloadProgress progress) onProgress,
  }) async {
    _cancelled = false;

    final targetPois = pois
        .where((p) => p.qid.trim().isNotEmpty)
        .toList(growable: false);

    if (targetPois.isEmpty) {
      return PoiSummariesDownloadResult(
        pois: List<RoutePoiSummary>.from(pois),
        failedCount: 0,
        cancelled: false,
      );
    }

    if (_cancelled) {
      return PoiSummariesDownloadResult(
        pois: List<RoutePoiSummary>.from(pois),
        failedCount: 0,
        cancelled: true,
      );
    }

    onProgress(
      PoiSummariesDownloadProgress(
        completed: 0,
        total: targetPois.length,
        failed: 0,
      ),
    );

    final qids = targetPois
        .map((p) => p.qid.trim().toUpperCase())
        .toList(growable: false);

    final previews = <String, PoiWikiPreview>{};
    var completed = 0;
    var failed = 0;

    for (var offset = 0; offset < qids.length; offset += _progressChunkSize) {
      if (_cancelled) {
        return PoiSummariesDownloadResult(
          pois: List<RoutePoiSummary>.from(pois),
          failedCount: failed,
          cancelled: true,
        );
      }

      final end = math.min(offset + _progressChunkSize, qids.length);
      final chunk = qids.sublist(offset, end);
      final chunkPreviews = await _repository.batchGetWikiPreviews(
        qids: chunk,
        preferredLanguageCode: preferredLanguageCode,
      );
      previews.addAll(chunkPreviews);

      for (final qid in chunk) {
        if (!chunkPreviews.containsKey(qid)) {
          failed++;
        }
      }
      completed += chunk.length;
      onProgress(
        PoiSummariesDownloadProgress(
          completed: completed,
          total: targetPois.length,
          failed: failed,
        ),
      );
    }

    final updatedPois = List<RoutePoiSummary>.from(pois);

    for (var i = 0; i < pois.length; i++) {
      final poi = pois[i];
      final normalizedQid = poi.qid.trim().toUpperCase();
      if (normalizedQid.isEmpty) continue;

      final preview = previews[normalizedQid];
      if (preview != null) {
        final summary = preview.summary.trim();
        final title = preview.title.trim();
        final sourceUrl = preview.sourceUrl.trim();
        updatedPois[i] = poi.copyWith(
          description: summary.isNotEmpty
              ? summary
              : (title.isNotEmpty ? title : poi.description),
          descriptionHtml: preview.htmlContent.trim().isNotEmpty
              ? preview.htmlContent
              : poi.descriptionHtml,
          wiki: sourceUrl.isNotEmpty ? sourceUrl : poi.wiki,
        );
      }
    }

    return PoiSummariesDownloadResult(
      pois: updatedPois,
      failedCount: failed,
      cancelled: false,
    );
  }
}
