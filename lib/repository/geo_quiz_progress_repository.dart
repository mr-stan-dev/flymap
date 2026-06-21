import 'dart:convert';

import 'package:flymap/domain/entity/geo_quiz.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class GeoQuizProgressRepository {
  Future<Map<String, GeoQuizProgress>> getByQuizIds(Iterable<String> quizIds);

  Future<GeoQuizProgress> getProgress(String quizId);

  Future<GeoQuizProgress> markSolved({
    required String quizId,
    required String regionId,
  });

  Future<GeoQuizProgress> reset(String quizId);
}

class SharedPrefsGeoQuizProgressRepository
    implements GeoQuizProgressRepository {
  static const _storageKey = 'geo_quiz.progress.v1';

  @override
  Future<Map<String, GeoQuizProgress>> getByQuizIds(
    Iterable<String> quizIds,
  ) async {
    final all = await _readAll();
    return <String, GeoQuizProgress>{
      for (final rawId in quizIds)
        if (rawId.trim().isNotEmpty)
          rawId.trim():
              all[rawId.trim()] ?? GeoQuizProgress(quizId: rawId.trim()),
    };
  }

  @override
  Future<GeoQuizProgress> getProgress(String quizId) async {
    final normalizedQuizId = quizId.trim();
    if (normalizedQuizId.isEmpty) {
      return const GeoQuizProgress(quizId: '');
    }
    final all = await _readAll();
    return all[normalizedQuizId] ?? GeoQuizProgress(quizId: normalizedQuizId);
  }

  @override
  Future<GeoQuizProgress> markSolved({
    required String quizId,
    required String regionId,
  }) async {
    final normalizedQuizId = quizId.trim();
    final normalizedRegionId = regionId.trim();
    if (normalizedQuizId.isEmpty || normalizedRegionId.isEmpty) {
      return GeoQuizProgress(quizId: normalizedQuizId);
    }

    final all = await _readAll();
    final current =
        all[normalizedQuizId] ?? GeoQuizProgress(quizId: normalizedQuizId);
    final updated = current.copyWith(
      solvedRegionIds: <String>{...current.solvedRegionIds, normalizedRegionId},
    );
    all[normalizedQuizId] = updated;
    await _writeAll(all);
    return updated;
  }

  @override
  Future<GeoQuizProgress> reset(String quizId) async {
    final normalizedQuizId = quizId.trim();
    if (normalizedQuizId.isEmpty) {
      return const GeoQuizProgress(quizId: '');
    }
    final all = await _readAll();
    all.remove(normalizedQuizId);
    await _writeAll(all);
    return GeoQuizProgress(quizId: normalizedQuizId);
  }

  Future<Map<String, GeoQuizProgress>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return <String, GeoQuizProgress>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, GeoQuizProgress>{};
      final root = decoded.cast<String, dynamic>();
      final result = <String, GeoQuizProgress>{};
      for (final entry in root.entries) {
        final quizId = entry.key.trim();
        if (quizId.isEmpty) continue;
        final rawSolved = entry.value;
        if (rawSolved is! List) continue;
        final solved = <String>{
          for (final value in rawSolved)
            if (value.toString().trim().isNotEmpty) value.toString().trim(),
        };
        if (solved.isNotEmpty) {
          result[quizId] = GeoQuizProgress(
            quizId: quizId,
            solvedRegionIds: solved,
          );
        }
      }
      return result;
    } catch (_) {
      return <String, GeoQuizProgress>{};
    }
  }

  Future<void> _writeAll(Map<String, GeoQuizProgress> all) async {
    final prefs = await SharedPreferences.getInstance();
    final pruned = <String, List<String>>{};
    for (final entry in all.entries) {
      final quizId = entry.key.trim();
      if (quizId.isEmpty || entry.value.solvedRegionIds.isEmpty) continue;
      final solved = entry.value.solvedRegionIds.toList()..sort();
      pruned[quizId] = solved;
    }

    if (pruned.isEmpty) {
      await prefs.remove(_storageKey);
      return;
    }
    await prefs.setString(_storageKey, jsonEncode(pruned));
  }
}
