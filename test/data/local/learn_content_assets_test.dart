import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const locales = ['en', 'de', 'es', 'fr'];

  test('bundled Learn packs and Markdown stay in locale parity', () {
    _LocaleContent? english;

    for (final locale in locales) {
      final content = _readLocaleContent(locale);

      expect(
        content.categoryOrders,
        List<int>.generate(content.categoryOrders.length, (index) => index + 1),
        reason: '$locale category orders must be contiguous',
      );
      expect(
        content.articleIds.toSet().length,
        content.articleIds.length,
        reason: '$locale article IDs must be unique',
      );

      for (final category in content.categories) {
        expect(
          category.articleOrders,
          List<int>.generate(
            category.articleOrders.length,
            (index) => index + 1,
          ),
          reason: '$locale/${category.id} article orders must be contiguous',
        );
      }

      expect(
        content.markdownIds,
        content.articleIds.toSet(),
        reason: '$locale metadata and Markdown filenames must match',
      );

      for (final article in content.articles) {
        final body = File('${content.articlesDirectory}/${article.id}.md');
        final lines = body.readAsLinesSync();
        final heading = lines.first;
        expect(
          heading,
          '# ${article.title}',
          reason: '$locale/${article.id} H1 must match its metadata title',
        );
        expect(
          lines.any((line) => line.trim() == '---'),
          isFalse,
          reason: '$locale/${article.id} must not contain section dividers',
        );
      }

      if (locale == 'en') {
        english = content;
      } else {
        final reference = english!;
        expect(
          content.categoryIds,
          reference.categoryIds,
          reason: '$locale category IDs and order must match English',
        );
        expect(
          content.articleIds,
          reference.articleIds,
          reason: '$locale article IDs and order must match English',
        );
        expect(
          content.articlePremiumFlags,
          reference.articlePremiumFlags,
          reason: '$locale premium flags must match English',
        );
      }
    }
  });
}

_LocaleContent _readLocaleContent(String locale) {
  final pack = File('assets/data/learn/knowledge_pack.$locale.json');
  final root = jsonDecode(pack.readAsStringSync()) as Map<String, dynamic>;
  final rawCategories = (root['categories'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final categories = <_CategoryContent>[];
  final articles = <_ArticleContent>[];

  for (final rawCategory in rawCategories) {
    final rawArticles = (rawCategory['articles'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final categoryArticles = rawArticles
        .map(
          (rawArticle) => _ArticleContent(
            id: rawArticle['id'] as String,
            title: rawArticle['title'] as String,
            order: rawArticle['order'] as int,
            premium: rawArticle['premium'] as bool,
          ),
        )
        .toList(growable: false);

    categories.add(
      _CategoryContent(
        id: rawCategory['id'] as String,
        order: rawCategory['order'] as int,
        articles: categoryArticles,
      ),
    );
    articles.addAll(categoryArticles);
  }

  final articlesDirectory = locale == 'en'
      ? 'assets/data/learn/articles'
      : 'assets/data/learn/articles_$locale';
  final markdownIds = Directory(articlesDirectory)
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.md'))
      .map(
        (file) => file.uri.pathSegments.last.replaceFirst(RegExp(r'\.md$'), ''),
      )
      .toSet();

  return _LocaleContent(
    categories: categories,
    articles: articles,
    articlesDirectory: articlesDirectory,
    markdownIds: markdownIds,
  );
}

class _LocaleContent {
  const _LocaleContent({
    required this.categories,
    required this.articles,
    required this.articlesDirectory,
    required this.markdownIds,
  });

  final List<_CategoryContent> categories;
  final List<_ArticleContent> articles;
  final String articlesDirectory;
  final Set<String> markdownIds;

  List<String> get categoryIds =>
      categories.map((category) => category.id).toList();
  List<int> get categoryOrders =>
      categories.map((category) => category.order).toList();
  List<String> get articleIds => articles.map((article) => article.id).toList();
  List<bool> get articlePremiumFlags =>
      articles.map((article) => article.premium).toList();
}

class _CategoryContent {
  const _CategoryContent({
    required this.id,
    required this.order,
    required this.articles,
  });

  final String id;
  final int order;
  final List<_ArticleContent> articles;

  List<int> get articleOrders =>
      articles.map((article) => article.order).toList();
}

class _ArticleContent {
  const _ArticleContent({
    required this.id,
    required this.title,
    required this.order,
    required this.premium,
  });

  final String id;
  final String title;
  final int order;
  final bool premium;
}
