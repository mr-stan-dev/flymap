import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flymap/entity/learn_access.dart';
import 'package:flymap/entity/learn_article_content.dart';
import 'package:flymap/entity/learn_article_meta.dart';
import 'package:flymap/entity/learn_category.dart';
import 'package:flymap/logger.dart';

typedef LearnAssetStringLoader = Future<String> Function(String assetPath);

class LearnPackLocalDb {
  LearnPackLocalDb({LearnAssetStringLoader? assetStringLoader})
    : _assetStringLoader = assetStringLoader ?? rootBundle.loadString;

  static const String packAssetPath =
      'assets/data/learn/knowledge_pack.en.json';
  static const String articlesAssetDir = 'assets/data/learn/articles';
  static const String _categoryImagesAssetDir =
      'assets/images/learn/categories';
  static const Map<String, String> _categoryImageAssetById = {
    'general_basic': '$_categoryImagesAssetDir/basics.webp',
    'clouds_and_weather': '$_categoryImagesAssetDir/clouds.webp',
    'flight_physics': '$_categoryImagesAssetDir/physics.webp',
    'aircraft_and_systems': '$_categoryImagesAssetDir/systems.webp',
    'navigation_and_routes': '$_categoryImagesAssetDir/navigation.webp',
    'turbulence_and_airflows': '$_categoryImagesAssetDir/turbulance.webp',
    'in_flight_experience': '$_categoryImagesAssetDir/inflight_experience.webp',
    'airport_and_flight_operations': '$_categoryImagesAssetDir/operations.webp',
    'views_from_the_window': '$_categoryImagesAssetDir/views.webp',
    'aviation_myths': '$_categoryImagesAssetDir/myth.webp',
  };

  final LearnAssetStringLoader _assetStringLoader;
  final Logger _logger = const Logger('LearnPackLocalDb');

  _LearnPackCache? _cache;
  final Map<String, String> _articleMarkdownById = <String, String>{};

  Future<List<LearnCategory>> getCategories() async {
    final cache = await _loadCache();
    return cache.categories;
  }

  Future<List<LearnArticleMeta>> getArticles({
    required String categoryId,
  }) async {
    final cache = await _loadCache();
    final category = cache.categoryById[categoryId];
    if (category == null) {
      throw StateError('Unknown learn category id: "$categoryId"');
    }
    return category.articles;
  }

  Future<LearnArticleContent> getArticleContent({
    required String articleId,
  }) async {
    final cache = await _loadCache();
    final articleMeta = cache.articleById[articleId];
    if (articleMeta == null) {
      throw StateError('Unknown learn article id: "$articleId"');
    }

    final cachedMarkdown = _articleMarkdownById[articleId];
    if (cachedMarkdown != null) {
      return LearnArticleContent(
        id: articleMeta.id,
        title: articleMeta.title,
        categoryId: articleMeta.categoryId,
        markdown: cachedMarkdown,
        categoryOrder: articleMeta.categoryOrder,
      );
    }

    final markdown = await _loadArticleMarkdown(articleMeta: articleMeta);
    final normalized = markdown.trim();
    _articleMarkdownById[articleId] = normalized;
    return LearnArticleContent(
      id: articleMeta.id,
      title: articleMeta.title,
      categoryId: articleMeta.categoryId,
      markdown: normalized,
      categoryOrder: articleMeta.categoryOrder,
    );
  }

  Future<String> _loadArticleMarkdown({
    required LearnArticleMeta articleMeta,
  }) async {
    final flatOrderedPath =
        '$articlesAssetDir/${articleMeta.markdownFileName}';
    final orderedNestedPath =
        '$articlesAssetDir/${articleMeta.categoryFolderName}/${articleMeta.markdownFileName}';
    final canonicalNestedPath =
        '$articlesAssetDir/${articleMeta.categoryId}/${articleMeta.id}.md';
    try {
      return await _assetStringLoader(flatOrderedPath);
    } catch (error) {
      final triedCanonical =
          flatOrderedPath == canonicalNestedPath ||
          orderedNestedPath == canonicalNestedPath;
      try {
        _logger.log(
          'Learn article not found at flat path "$flatOrderedPath". '
          'Trying ordered nested path "$orderedNestedPath".',
        );
        return await _assetStringLoader(orderedNestedPath);
      } catch (_) {}
      if (triedCanonical) {
        final legacyPath = '$articlesAssetDir/${articleMeta.id}.md';
        _logger.log(
          'Learn article not found at path "$flatOrderedPath". '
          'Trying legacy flat path "$legacyPath".',
        );
        return await _assetStringLoader(legacyPath);
      }
      try {
        _logger.log(
          'Learn article not found at ordered path "$orderedNestedPath". '
          'Trying canonical nested path "$canonicalNestedPath".',
        );
        return await _assetStringLoader(canonicalNestedPath);
      } catch (canonicalError) {
        final legacyPath = '$articlesAssetDir/${articleMeta.id}.md';
        try {
          _logger.log(
            'Learn article not found at canonical nested path '
            '"$canonicalNestedPath". Trying legacy flat path "$legacyPath".',
          );
          return await _assetStringLoader(legacyPath);
        } catch (_) {
          throw canonicalError;
        }
      }
    }
  }

  Future<_LearnPackCache> _loadCache() async {
    final existing = _cache;
    if (existing != null) return existing;

    final raw = await _assetStringLoader(packAssetPath);
    final dynamic decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Learn pack must be a JSON object.');
    }
    final root = decoded.cast<String, dynamic>();
    final version = _readInt(root['version']);
    if (version != 1) {
      throw FormatException('Unsupported learn pack version: $version');
    }

    final rawCategories = root['categories'];
    if (rawCategories is! List) {
      throw const FormatException(
        'Learn pack "categories" must be a JSON array.',
      );
    }

    final categoryRecords = <_LearnCategoryRecord>[];
    final categoryById = <String, LearnCategory>{};
    final articleById = <String, LearnArticleMeta>{};
    var categoryIndex = 0;

    for (final rawCategory in rawCategories) {
      if (rawCategory is! Map) {
        throw const FormatException('Learn category must be a JSON object.');
      }
      final categoryJson = rawCategory.cast<String, dynamic>();
      final categoryId = _readNonEmptyString(categoryJson, field: 'id');
      if (categoryById.containsKey(categoryId)) {
        throw FormatException('Duplicate learn category id: "$categoryId"');
      }

      final title = _readNonEmptyString(categoryJson, field: 'title');
      final description = _readNonEmptyString(
        categoryJson,
        field: 'description',
      );
      final categoryAccess = _readOptionalAccess(
        categoryJson['access'],
        fallback: LearnAccess.free,
      );
      final categoryOrder = _readOptionalOrder(categoryJson['order']);

      final rawArticles = categoryJson['articles'];
      if (rawArticles is! List) {
        throw FormatException(
          'Learn category "$categoryId" has invalid "articles" field.',
        );
      }

      final articleRecords = <_LearnArticleRecord>[];
      var articleIndex = 0;
      for (final rawArticle in rawArticles) {
        if (rawArticle is! Map) {
          throw FormatException(
            'Learn article in category "$categoryId" must be a JSON object.',
          );
        }
        final articleJson = rawArticle.cast<String, dynamic>();
        final articleId = _readNonEmptyString(articleJson, field: 'id');
        if (articleById.containsKey(articleId)) {
          throw FormatException('Duplicate learn article id: "$articleId"');
        }

        final articleTitle = _readNonEmptyString(articleJson, field: 'title');
        final articleAccess = _readArticleAccess(
          articleJson,
          fallback: categoryAccess,
        );
        final articleOrder = _readOptionalOrder(articleJson['order']);
        final article = LearnArticleMeta(
          id: articleId,
          title: articleTitle,
          categoryId: categoryId,
          access: articleAccess,
          order: articleOrder,
          categoryOrder: categoryOrder,
        );
        articleById[articleId] = article;
        articleRecords.add(
          _LearnArticleRecord(
            article: article,
            index: articleIndex++,
            order: articleOrder,
          ),
        );
      }
      articleRecords.sort(
        (a, b) => _compareByOrderThenIndex(a.order, a.index, b.order, b.index),
      );
      final articles = articleRecords.map((item) => item.article).toList();

      final category = LearnCategory(
        id: categoryId,
        title: title,
        description: description,
        imageAssetPath:
            _categoryImageAssetById[categoryId] ??
            '$_categoryImagesAssetDir/$categoryId.webp',
        articles: articles,
      );
      categoryById[categoryId] = category;
      categoryRecords.add(
        _LearnCategoryRecord(
          category: category,
          index: categoryIndex++,
          order: categoryOrder,
        ),
      );
    }

    categoryRecords.sort(
      (a, b) => _compareByOrderThenIndex(a.order, a.index, b.order, b.index),
    );
    final categories = categoryRecords.map((item) => item.category).toList();

    final cache = _LearnPackCache(
      categories: categories,
      categoryById: categoryById,
      articleById: articleById,
    );
    _cache = cache;
    _logger.log(
      'Learn pack loaded: categories=${categories.length} '
      'articles=${articleById.length}',
    );
    return cache;
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw const FormatException('Expected integer value.');
  }

  static LearnAccess _readArticleAccess(
    Map<String, dynamic> articleJson, {
    required LearnAccess fallback,
  }) {
    final accessRaw = articleJson['access'];
    if (accessRaw is String && accessRaw.trim().isNotEmpty) {
      return LearnAccessParser.fromRaw(accessRaw.trim());
    }

    final premium = articleJson['premium'];
    if (premium is bool) {
      return premium ? LearnAccess.pro : LearnAccess.free;
    }

    return fallback;
  }

  static LearnAccess _readOptionalAccess(
    Object? value, {
    required LearnAccess fallback,
  }) {
    if (value == null) return fallback;
    if (value is String && value.trim().isNotEmpty) {
      return LearnAccessParser.fromRaw(value.trim());
    }
    throw const FormatException('Learn access must be a non-empty string.');
  }

  static int? _readOptionalOrder(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw const FormatException('Learn order must be a number when provided.');
  }

  static int _compareByOrderThenIndex(
    int? leftOrder,
    int leftIndex,
    int? rightOrder,
    int rightIndex,
  ) {
    if (leftOrder != null && rightOrder != null) {
      final byOrder = leftOrder.compareTo(rightOrder);
      if (byOrder != 0) return byOrder;
    } else if (leftOrder != null) {
      return -1;
    } else if (rightOrder != null) {
      return 1;
    }
    return leftIndex.compareTo(rightIndex);
  }

  static String _readNonEmptyString(
    Map<String, dynamic> json, {
    required String field,
  }) {
    final value = json[field];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Learn pack field "$field" is missing or empty.');
    }
    return value.trim();
  }
}

class _LearnPackCache {
  const _LearnPackCache({
    required this.categories,
    required this.categoryById,
    required this.articleById,
  });

  final List<LearnCategory> categories;
  final Map<String, LearnCategory> categoryById;
  final Map<String, LearnArticleMeta> articleById;
}

class _LearnCategoryRecord {
  const _LearnCategoryRecord({
    required this.category,
    required this.index,
    required this.order,
  });

  final LearnCategory category;
  final int index;
  final int? order;
}

class _LearnArticleRecord {
  const _LearnArticleRecord({
    required this.article,
    required this.index,
    required this.order,
  });

  final LearnArticleMeta article;
  final int index;
  final int? order;
}
