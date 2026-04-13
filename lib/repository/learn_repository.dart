import 'package:flymap/entity/learn_access.dart';
import 'package:flymap/entity/learn_article_content.dart';
import 'package:flymap/entity/learn_article_meta.dart';
import 'package:flymap/entity/learn_category.dart';

abstract interface class LearnRepository {
  Future<List<LearnCategory>> getCategories();

  Future<List<LearnArticleMeta>> getArticles({required String categoryId});

  Future<LearnArticleContent> getArticleContent({required String articleId});

  bool canOpenArticle({
    required LearnAccess articleAccess,
    required bool isProUser,
  });
}
