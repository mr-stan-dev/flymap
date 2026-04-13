import 'package:flymap/data/local/learn_pack_local_db.dart';
import 'package:flymap/entity/learn_access.dart';
import 'package:flymap/entity/learn_article_content.dart';
import 'package:flymap/entity/learn_article_meta.dart';
import 'package:flymap/entity/learn_category.dart';
import 'package:flymap/repository/learn_repository.dart';

class LocalLearnRepository implements LearnRepository {
  LocalLearnRepository({required LearnPackLocalDb localDb})
    : _localDb = localDb;

  final LearnPackLocalDb _localDb;

  @override
  Future<List<LearnCategory>> getCategories() {
    return _localDb.getCategories();
  }

  @override
  Future<List<LearnArticleMeta>> getArticles({required String categoryId}) {
    return _localDb.getArticles(categoryId: categoryId);
  }

  @override
  Future<LearnArticleContent> getArticleContent({required String articleId}) {
    return _localDb.getArticleContent(articleId: articleId);
  }

  @override
  bool canOpenArticle({
    required LearnAccess articleAccess,
    required bool isProUser,
  }) {
    return articleAccess == LearnAccess.free || isProUser;
  }
}
