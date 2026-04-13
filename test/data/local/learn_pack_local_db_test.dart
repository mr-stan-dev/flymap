import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/local/learn_pack_local_db.dart';
import 'package:flymap/entity/learn_access.dart';

void main() {
  test(
    'defaults category access to free when access field is absent',
    () async {
      final loader = _MapAssetLoader({
        LearnPackLocalDb.packAssetPath: '''
{
  "version": 1,
  "categories": [
    {
      "id": "general_basic",
      "title": "General Basics",
      "description": "Desc",
      "articles": [
        {
          "id": "a1",
          "title": "Article One"
        }
      ]
    }
  ]
}
''',
        '${LearnPackLocalDb.articlesAssetDir}/a1.md': '# Article One',
      });
      final db = LearnPackLocalDb(assetStringLoader: loader.load);

      final categories = await db.getCategories();
      expect(categories.length, 1);
      expect(categories.first.articles.single.access, LearnAccess.free);
      expect(
        categories.first.imageAssetPath,
        'assets/images/learn/categories/basics.webp',
      );
      expect(categories.first.articles.single.id, 'a1');

      final content = await db.getArticleContent(articleId: 'a1');
      expect(content.title, 'Article One');
      expect(content.markdown, '# Article One');
    },
  );

  test('parses learn pack when legacy article.premium is present', () async {
    final loader = _MapAssetLoader({
      LearnPackLocalDb.packAssetPath: '''
{
  "version": 1,
  "categories": [
    {
      "id": "clouds",
      "title": "Clouds",
      "description": "Desc",
      "access": "pro",
      "articles": [
        {
          "id": "a2",
          "title": "Article Two",
          "premium": true
        }
      ]
    }
  ]
}
''',
      '${LearnPackLocalDb.articlesAssetDir}/a2.md': '# Article Two',
    });
    final db = LearnPackLocalDb(assetStringLoader: loader.load);

    final categories = await db.getCategories();
    expect(categories.length, 1);
    expect(categories.first.articles.single.access, LearnAccess.pro);
    expect(categories.first.articles.single.id, 'a2');

    final content = await db.getArticleContent(articleId: 'a2');
    expect(content.markdown, '# Article Two');
  });

  test(
    'falls back to legacy flat article path when nested path is missing',
    () async {
      final loader = _MapAssetLoader({
        LearnPackLocalDb.packAssetPath: '''
{
  "version": 1,
  "categories": [
    {
      "id": "general_basic",
      "title": "General Basics",
      "description": "Desc",
      "access": "free",
      "articles": [
        {
          "id": "a3",
          "title": "Article Three"
        }
      ]
    }
  ]
}
''',
        '${LearnPackLocalDb.articlesAssetDir}/a3.md': '# Article Three',
      });
      final db = LearnPackLocalDb(assetStringLoader: loader.load);

      final content = await db.getArticleContent(articleId: 'a3');
      expect(content.markdown, '# Article Three');
    },
  );

  test('sorts categories and articles by optional order', () async {
    final loader = _MapAssetLoader({
      LearnPackLocalDb.packAssetPath: '''
{
  "version": 1,
  "categories": [
    {
      "id": "c2",
      "title": "Second",
      "description": "Desc",
      "order": 2,
      "articles": [
        {"id": "a22", "title": "A22", "order": 2},
        {"id": "a21", "title": "A21", "order": 1}
      ]
    },
    {
      "id": "c1",
      "title": "First",
      "description": "Desc",
      "order": 1,
      "articles": [
        {"id": "a11", "title": "A11", "order": 2},
        {"id": "a10", "title": "A10", "order": 1}
      ]
    }
  ]
}
''',
      '${LearnPackLocalDb.articlesAssetDir}/a10.md': '# A10',
      '${LearnPackLocalDb.articlesAssetDir}/a11.md': '# A11',
      '${LearnPackLocalDb.articlesAssetDir}/a21.md': '# A21',
      '${LearnPackLocalDb.articlesAssetDir}/a22.md': '# A22',
    });
    final db = LearnPackLocalDb(assetStringLoader: loader.load);

    final categories = await db.getCategories();
    expect(categories.map((c) => c.id), ['c1', 'c2']);
    expect(categories[0].articles.map((a) => a.id), ['a10', 'a11']);
    expect(categories[1].articles.map((a) => a.id), ['a21', 'a22']);
  });

  test('loads markdown by flat article id filename', () async {
    final loader = _MapAssetLoader({
      LearnPackLocalDb.packAssetPath: '''
{
  "version": 1,
  "categories": [
    {
      "id": "general_basic",
      "title": "General Basics",
      "description": "Desc",
      "order": 1,
      "articles": [
        {
          "id": "a1",
          "title": "Article One",
          "order": 1
        }
      ]
    }
  ]
}
''',
      '${LearnPackLocalDb.articlesAssetDir}/a1.md': '# Article One',
    });
    final db = LearnPackLocalDb(assetStringLoader: loader.load);

    final content = await db.getArticleContent(articleId: 'a1');
    expect(content.markdown, '# Article One');
  });
}

class _MapAssetLoader {
  _MapAssetLoader(this._assets);

  final Map<String, String> _assets;

  Future<String> load(String path) async {
    final value = _assets[path];
    if (value == null) {
      throw StateError('Missing test asset: $path');
    }
    return value;
  }
}
