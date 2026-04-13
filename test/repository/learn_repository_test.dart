import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/local/learn_pack_local_db.dart';
import 'package:flymap/data/local/learn_repository_impl.dart';
import 'package:flymap/entity/learn_access.dart';

void main() {
  late LocalLearnRepository repository;

  setUp(() {
    final loader = _MapAssetLoader({
      LearnPackLocalDb.packAssetPath: '''
{
  "version": 1,
  "categories": [
    {
      "id": "free_cat",
      "title": "Free Cat",
      "description": "Free description",
      "access": "free",
      "articles": [{"id": "f1", "title": "Free One"}]
    },
    {
      "id": "pro_cat",
      "title": "Pro Cat",
      "description": "Pro description",
      "access": "pro",
      "articles": [{"id": "p1", "title": "Pro One"}]
    }
  ]
}
''',
      '${LearnPackLocalDb.articlesAssetDir}/f1.md': '# Free One',
      '${LearnPackLocalDb.articlesAssetDir}/p1.md': '# Pro One',
    });
    repository = LocalLearnRepository(
      localDb: LearnPackLocalDb(assetStringLoader: loader.load),
    );
  });

  test('returns both free and premium categories for browsing', () async {
    final categories = await repository.getCategories();

    expect(categories.length, 2);
    expect(categories.map((e) => e.id), ['free_cat', 'pro_cat']);
  });

  test('blocks free users from opening pro articles', () async {
    final freeCanOpenPro = repository.canOpenArticle(
      articleAccess: LearnAccess.pro,
      isProUser: false,
    );
    final proCanOpenPro = repository.canOpenArticle(
      articleAccess: LearnAccess.pro,
      isProUser: true,
    );

    expect(freeCanOpenPro, isFalse);
    expect(proCanOpenPro, isTrue);
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
