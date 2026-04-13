import 'dart:convert';

import 'package:flymap/entity/learn_article_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class LearnArticleProgressRepository {
  Future<Map<String, LearnArticleProgress>> getByArticleIds(
    Iterable<String> articleIds,
  );

  Future<LearnArticleProgress> toggleFavorite(String articleId);

  Future<LearnArticleProgress> markSeen(String articleId);
}

class SharedPrefsLearnArticleProgressRepository
    implements LearnArticleProgressRepository {
  static const _storageKey = 'learn.article_progress.v1';

  @override
  Future<Map<String, LearnArticleProgress>> getByArticleIds(
    Iterable<String> articleIds,
  ) async {
    final all = await _readAll();
    final result = <String, LearnArticleProgress>{};
    for (final rawId in articleIds) {
      final articleId = rawId.trim();
      if (articleId.isEmpty) continue;
      result[articleId] = all[articleId] ?? LearnArticleProgress.empty;
    }
    return result;
  }

  @override
  Future<LearnArticleProgress> toggleFavorite(String articleId) async {
    final normalizedId = articleId.trim();
    if (normalizedId.isEmpty) return LearnArticleProgress.empty;

    final all = await _readAll();
    final current = all[normalizedId] ?? LearnArticleProgress.empty;
    final updated = current.copyWith(isFavorite: !current.isFavorite);
    all[normalizedId] = updated;
    await _writeAll(all);
    return updated;
  }

  @override
  Future<LearnArticleProgress> markSeen(String articleId) async {
    final normalizedId = articleId.trim();
    if (normalizedId.isEmpty) return LearnArticleProgress.empty;

    final all = await _readAll();
    final current = all[normalizedId] ?? LearnArticleProgress.empty;
    if (current.isSeen) return current;

    final updated = current.copyWith(isSeen: true);
    all[normalizedId] = updated;
    await _writeAll(all);
    return updated;
  }

  Future<Map<String, LearnArticleProgress>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty)
      return <String, LearnArticleProgress>{};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, LearnArticleProgress>{};
      final root = decoded.cast<String, dynamic>();
      final result = <String, LearnArticleProgress>{};
      for (final entry in root.entries) {
        final articleId = entry.key.trim();
        if (articleId.isEmpty) continue;
        final value = entry.value;
        if (value is! Map) continue;
        final map = value.cast<String, dynamic>();
        final isFavorite = map['favorite'] == true;
        final isSeen = map['seen'] == true;
        final progress = LearnArticleProgress(
          isFavorite: isFavorite,
          isSeen: isSeen,
        );
        if (progress.hasAnyState) {
          result[articleId] = progress;
        }
      }
      return result;
    } catch (_) {
      return <String, LearnArticleProgress>{};
    }
  }

  Future<void> _writeAll(Map<String, LearnArticleProgress> all) async {
    final prefs = await SharedPreferences.getInstance();
    final pruned = <String, Map<String, bool>>{};
    for (final entry in all.entries) {
      final articleId = entry.key.trim();
      if (articleId.isEmpty) continue;
      final progress = entry.value;
      if (!progress.hasAnyState) continue;
      pruned[articleId] = <String, bool>{
        'favorite': progress.isFavorite,
        'seen': progress.isSeen,
      };
    }

    if (pruned.isEmpty) {
      await prefs.remove(_storageKey);
      return;
    }
    await prefs.setString(_storageKey, jsonEncode(pruned));
  }
}
