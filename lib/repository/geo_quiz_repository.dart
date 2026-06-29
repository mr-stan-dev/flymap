import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flymap/domain/entity/geo_quiz.dart';
import 'package:flymap/domain/entity/learn_access.dart';

typedef GeoQuizAssetStringLoader = Future<String> Function(String assetPath);

abstract interface class GeoQuizRepository {
  Future<List<GeoQuizSummary>> getQuizzes({required String collectionId});

  Future<List<GeoQuizRegion>> getRegions({required String quizId});

  Future<String?> getRegionDescription({
    required String quizId,
    required String regionId,
    required String languageCode,
  });
}

class AssetGeoQuizRepository implements GeoQuizRepository {
  AssetGeoQuizRepository({GeoQuizAssetStringLoader? assetStringLoader})
    : _assetStringLoader = assetStringLoader ?? rootBundle.loadString;

  static const _collectionConfigs = <String, _GeoQuizCollectionConfig>{
    'countries': _GeoQuizCollectionConfig(
      id: 'countries',
      quizzesAssetPath: 'assets/data/geo_quiz/countries/quizzes.json',
      geoJsonAssetPath: 'assets/data/geo_quiz/countries/countries.geojson',
      namesAssetPath: 'assets/data/geo_quiz/countries/countries_names.json',
      descriptionsAssetPathPrefix:
          'assets/data/geo_quiz/countries/countries_descriptions_',
    ),
    'geography': _GeoQuizCollectionConfig(
      id: 'geography',
      quizzesAssetPath: 'assets/data/geo_quiz/geography/quizzes.json',
      geoJsonAssetPath: 'assets/data/geo_quiz/geography/geography.geojson',
      namesAssetPath: 'assets/data/geo_quiz/geography/geography_names.json',
      descriptionsAssetPathPrefix:
          'assets/data/geo_quiz/geography/geography_descriptions_',
    ),
  };

  final GeoQuizAssetStringLoader _assetStringLoader;
  final Map<String, Future<List<_GeoQuizDefinition>>> _definitionsFutures = {};
  final Map<String, Future<Map<String, _GeoQuizCountryMeta>>>
  _countryMetaFutures = {};
  final Map<String, Future<Map<String, String>>> _descriptionFutures = {};

  @override
  Future<List<GeoQuizSummary>> getQuizzes({
    required String collectionId,
  }) async {
    final config = _collectionConfig(collectionId);
    if (config == null) return const <GeoQuizSummary>[];

    final definitions = await _loadDefinitions(config);
    return [
      for (final definition in definitions)
        GeoQuizSummary(
          id: definition.id,
          collectionId: definition.collectionId,
          title: definition.title,
          subtitle: definition.subtitle,
          totalCount: definition.totalCount,
          access: definition.access,
          iconName: definition.iconName,
          geoJsonAssetPath: config.geoJsonAssetPath,
        ),
    ];
  }

  @override
  Future<List<GeoQuizRegion>> getRegions({required String quizId}) async {
    final normalizedQuizId = quizId.trim();
    if (normalizedQuizId.isEmpty) return const <GeoQuizRegion>[];

    final definition = await _findDefinition(normalizedQuizId);
    if (definition == null) {
      return const <GeoQuizRegion>[];
    }
    final config = _collectionConfig(definition.collectionId);
    if (config == null || config.namesAssetPath == null) {
      return const <GeoQuizRegion>[];
    }

    final countryMetaById = await _loadCountryMeta(config);
    return [
      for (final regionId in definition.regionIds)
        _regionFromMeta(regionId: regionId, meta: countryMetaById[regionId]),
    ];
  }

  @override
  Future<String?> getRegionDescription({
    required String quizId,
    required String regionId,
    required String languageCode,
  }) async {
    final definition = await _findDefinition(quizId);
    if (definition == null) return null;
    final config = _collectionConfig(definition.collectionId);
    if (config?.descriptionsAssetPathPrefix == null) return null;

    final normalizedRegionId = regionId.trim();
    if (normalizedRegionId.isEmpty) return null;

    final normalizedLanguageCode = _descriptionLanguageCode(languageCode);
    final localized = await _loadDescriptions(
      config!.id,
      normalizedLanguageCode,
      config.descriptionsAssetPathPrefix!,
    );
    final localizedDescription = localized[normalizedRegionId]?.trim();
    if (localizedDescription != null && localizedDescription.isNotEmpty) {
      return localizedDescription;
    }

    if (normalizedLanguageCode == 'en') return null;
    final english = await _loadDescriptions(
      config.id,
      'en',
      config.descriptionsAssetPathPrefix!,
    );
    final englishDescription = english[normalizedRegionId]?.trim();
    return englishDescription == null || englishDescription.isEmpty
        ? null
        : englishDescription;
  }

  _GeoQuizCollectionConfig? _collectionConfig(String collectionId) {
    return _collectionConfigs[collectionId.trim()];
  }

  Future<List<_GeoQuizDefinition>> _loadDefinitions(
    _GeoQuizCollectionConfig config,
  ) {
    return _definitionsFutures[config.id] ??= _readDefinitions(config);
  }

  Future<_GeoQuizDefinition?> _findDefinition(String quizId) async {
    final normalizedQuizId = quizId.trim();
    if (normalizedQuizId.isEmpty) return null;
    for (final config in _collectionConfigs.values) {
      final definitions = await _loadDefinitions(config);
      for (final definition in definitions) {
        if (definition.id == normalizedQuizId) {
          return definition;
        }
      }
    }
    return null;
  }

  Future<List<_GeoQuizDefinition>> _readDefinitions(
    _GeoQuizCollectionConfig config,
  ) async {
    final raw = await _assetStringLoader(config.quizzesAssetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const <_GeoQuizDefinition>[];
    final quizzes = decoded['quizzes'];
    if (quizzes is! List) return const <_GeoQuizDefinition>[];

    final definitions = <_GeoQuizDefinition>[];
    for (var sourceIndex = 0; sourceIndex < quizzes.length; sourceIndex++) {
      final rawQuiz = quizzes[sourceIndex];
      if (rawQuiz is! Map) continue;
      final quiz = rawQuiz.cast<String, dynamic>();
      final id = quiz['id']?.toString().trim() ?? '';
      final title = quiz['title']?.toString().trim() ?? '';
      final subtitle = quiz['subtitle']?.toString().trim() ?? '';
      final iconName = quiz['iconName']?.toString().trim() ?? 'public';
      final access = LearnAccessParser.fromRaw(
        quiz['access']?.toString() ?? 'pro',
      );
      final rawRegionIds = quiz['regionIds'];
      if (id.isEmpty || title.isEmpty) continue;
      if (rawRegionIds is! List) continue;
      final regionIdItems = rawRegionIds;
      final regionIds = [
        for (final rawId in regionIdItems)
          if (rawId.toString().trim().isNotEmpty) rawId.toString().trim(),
      ];
      final totalCount =
          int.tryParse(quiz['totalCount']?.toString() ?? '') ??
          regionIds.length;
      if (regionIds.isEmpty) continue;
      definitions.add(
        _GeoQuizDefinition(
          id: id,
          collectionId: config.id,
          title: title,
          subtitle: subtitle.isEmpty ? 'Countries' : subtitle,
          iconName: iconName.isEmpty ? 'public' : iconName,
          access: access,
          order: int.tryParse(quiz['order']?.toString() ?? '') ?? sourceIndex,
          regionIds: regionIds,
          totalCount: totalCount,
        ),
      );
    }
    definitions.sort((a, b) => a.order.compareTo(b.order));
    return definitions;
  }

  Future<Map<String, _GeoQuizCountryMeta>> _loadCountryMeta(
    _GeoQuizCollectionConfig config,
  ) {
    return _countryMetaFutures[config.id] ??= _readCountryMeta(config);
  }

  Future<Map<String, _GeoQuizCountryMeta>> _readCountryMeta(
    _GeoQuizCollectionConfig config,
  ) async {
    final namesAssetPath = config.namesAssetPath;
    if (namesAssetPath == null) {
      return const <String, _GeoQuizCountryMeta>{};
    }

    final raw = await _assetStringLoader(namesAssetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const <String, _GeoQuizCountryMeta>{};
    final regions = decoded['regions'] ?? decoded['countries'];
    if (regions is! Map) return const <String, _GeoQuizCountryMeta>{};

    final result = <String, _GeoQuizCountryMeta>{};
    for (final entry in regions.entries) {
      final id = entry.key.toString().trim();
      final rawMeta = entry.value;
      if (id.isEmpty || rawMeta is! Map) continue;
      final meta = rawMeta.cast<String, dynamic>();
      final names = <String, String>{};
      final aliases = <String>[];
      final rawNames = meta['names'];
      if (rawNames is Map) {
        for (final nameEntry in rawNames.entries) {
          final lang = nameEntry.key.toString().trim();
          final name = nameEntry.value.toString().trim();
          if (lang.isNotEmpty && name.isNotEmpty) {
            names[lang] = name;
          }
        }
      }
      final rawAliases = meta['aliases'];
      if (rawAliases is List) {
        for (final rawAlias in rawAliases) {
          final alias = rawAlias.toString().trim();
          if (alias.isNotEmpty) {
            aliases.add(alias);
          }
        }
      }
      result[id] = _GeoQuizCountryMeta(
        countryCode: _countryCodeForMeta(meta, id),
        names: names,
        aliases: aliases,
        regionType: meta['regionType']?.toString().trim(),
      );
    }
    return result;
  }

  GeoQuizRegion _regionFromMeta({
    required String regionId,
    required _GeoQuizCountryMeta? meta,
  }) {
    final names = meta?.names ?? const <String, String>{};
    return GeoQuizRegion(
      id: regionId,
      names: names.isEmpty ? {'en': regionId} : names,
      aliases: meta?.aliases ?? const <String>[],
      countryCode: meta?.countryCode ?? _countryCodeForId(regionId),
      regionType: meta?.regionType,
    );
  }

  String? _countryCodeForMeta(Map<String, dynamic> meta, String id) {
    final value = meta['countryCode']?.toString().trim();
    if (value != null && RegExp(r'^[a-zA-Z]{2}$').hasMatch(value)) {
      return value.toUpperCase();
    }
    return _countryCodeForId(id);
  }

  String? _countryCodeForId(String id) {
    if (RegExp(r'^[a-zA-Z]{2}$').hasMatch(id)) return id.toUpperCase();
    return null;
  }

  String _descriptionLanguageCode(String languageCode) {
    final normalized = languageCode.trim().toLowerCase();
    return switch (normalized) {
      'fr' || 'de' || 'es' => normalized,
      _ => 'en',
    };
  }

  Future<Map<String, String>> _loadDescriptions(
    String collectionId,
    String languageCode,
    String descriptionsAssetPathPrefix,
  ) {
    final cacheKey = '$collectionId:$languageCode';
    return _descriptionFutures[cacheKey] ??= _readDescriptions(
      languageCode,
      descriptionsAssetPathPrefix,
    );
  }

  Future<Map<String, String>> _readDescriptions(
    String languageCode,
    String descriptionsAssetPathPrefix,
  ) async {
    final raw = await _assetStringLoader(
      '$descriptionsAssetPathPrefix$languageCode.json',
    );
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const <String, String>{};
    final regions = decoded['regions'] ?? decoded['countries'];
    if (regions is! Map) return const <String, String>{};

    final result = <String, String>{};
    for (final entry in regions.entries) {
      final id = entry.key.toString().trim();
      final description = entry.value.toString().trim();
      if (id.isNotEmpty && description.isNotEmpty) {
        result[id] = description;
      }
    }
    return result;
  }
}

class _GeoQuizDefinition {
  const _GeoQuizDefinition({
    required this.id,
    required this.collectionId,
    required this.title,
    required this.subtitle,
    required this.iconName,
    required this.access,
    required this.order,
    required this.regionIds,
    required this.totalCount,
  });

  final String id;
  final String collectionId;
  final String title;
  final String subtitle;
  final String iconName;
  final LearnAccess access;
  final int order;
  final List<String> regionIds;
  final int totalCount;
}

class _GeoQuizCountryMeta {
  const _GeoQuizCountryMeta({
    required this.countryCode,
    required this.names,
    required this.aliases,
    required this.regionType,
  });

  final String? countryCode;
  final Map<String, String> names;
  final List<String> aliases;
  final String? regionType;
}

class _GeoQuizCollectionConfig {
  const _GeoQuizCollectionConfig({
    required this.id,
    required this.quizzesAssetPath,
    this.geoJsonAssetPath,
    this.namesAssetPath,
    this.descriptionsAssetPathPrefix,
  });

  final String id;
  final String quizzesAssetPath;
  final String? geoJsonAssetPath;
  final String? namesAssetPath;
  final String? descriptionsAssetPathPrefix;
}
