import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/repository/learn_article_progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPrefsLearnArticleProgressRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    repository = SharedPrefsLearnArticleProgressRepository();
  });

  test('returns empty progress for unseen and unfavorited article', () async {
    final result = await repository.getByArticleIds(<String>['a1']);

    expect(result['a1']?.isSeen, isFalse);
    expect(result['a1']?.isFavorite, isFalse);
  });

  test('toggle favorite persists and toggles back off', () async {
    final first = await repository.toggleFavorite('a1');
    expect(first.isFavorite, isTrue);

    final second = await repository.toggleFavorite('a1');
    expect(second.isFavorite, isFalse);

    final stored = await repository.getByArticleIds(<String>['a1']);
    expect(stored['a1']?.isFavorite, isFalse);
  });

  test('mark seen persists while preserving favorite', () async {
    await repository.toggleFavorite('a1');
    final seen = await repository.markSeen('a1');
    expect(seen.isSeen, isTrue);
    expect(seen.isFavorite, isTrue);

    final stored = await repository.getByArticleIds(<String>['a1']);
    expect(stored['a1']?.isSeen, isTrue);
    expect(stored['a1']?.isFavorite, isTrue);
  });
}
