import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flymap/domain/entity/geo_quiz.dart';
import 'package:flymap/domain/entity/learn_access.dart';

typedef GeoQuizAssetStringLoader = Future<String> Function(String assetPath);

abstract interface class GeoQuizRepository {
  Future<List<GeoQuizSummary>> getQuizzes();

  Future<List<GeoQuizRegion>> getRegions({required String quizId});

  Future<String?> getRegionDescription({
    required String regionId,
    required String languageCode,
  });
}

class AssetGeoQuizRepository implements GeoQuizRepository {
  AssetGeoQuizRepository({GeoQuizAssetStringLoader? assetStringLoader})
    : _assetStringLoader = assetStringLoader ?? rootBundle.loadString;

  static const String _geoQuizAssetDirectory = 'assets/data/geo_quiz/countries';
  static const String _countriesGeoJsonAssetPath =
      '$_geoQuizAssetDirectory/countries.geojson';
  static const String _quizzesAssetPath =
      '$_geoQuizAssetDirectory/quizzes.json';
  static const String _countryNamesAssetPath =
      '$_geoQuizAssetDirectory/countries_names.json';

  final GeoQuizAssetStringLoader _assetStringLoader;
  Future<List<_GeoQuizDefinition>>? _definitionsFuture;
  Future<Map<String, _GeoQuizCountryMeta>>? _countryMetaFuture;
  final Map<String, Future<Map<String, String>>> _descriptionFutures = {};

  @override
  Future<List<GeoQuizSummary>> getQuizzes() async {
    final definitions = await _loadDefinitions();
    return [
      for (final definition in definitions)
        GeoQuizSummary(
          id: definition.id,
          title: definition.title,
          subtitle: definition.subtitle,
          totalCount: definition.regionIds.length,
          access: definition.access,
          geoJsonAssetPath: _countriesGeoJsonAssetPath,
        ),
    ];
  }

  @override
  Future<List<GeoQuizRegion>> getRegions({required String quizId}) async {
    final normalizedQuizId = quizId.trim();
    if (normalizedQuizId.isEmpty) return const <GeoQuizRegion>[];

    final definitions = await _loadDefinitions();
    _GeoQuizDefinition? definition;
    for (final item in definitions) {
      if (item.id == normalizedQuizId) {
        definition = item;
        break;
      }
    }
    if (definition == null) return const <GeoQuizRegion>[];

    final countryMetaById = await _loadCountryMeta();
    return [
      for (final regionId in definition.regionIds)
        _regionFromMeta(regionId: regionId, meta: countryMetaById[regionId]),
    ];
  }

  @override
  Future<String?> getRegionDescription({
    required String regionId,
    required String languageCode,
  }) async {
    final normalizedRegionId = regionId.trim();
    if (normalizedRegionId.isEmpty) return null;

    final normalizedLanguageCode = _descriptionLanguageCode(languageCode);
    final localized = await _loadDescriptions(normalizedLanguageCode);
    final localizedDescription = localized[normalizedRegionId]?.trim();
    if (localizedDescription != null && localizedDescription.isNotEmpty) {
      return localizedDescription;
    }

    if (normalizedLanguageCode == 'en') return null;
    final english = await _loadDescriptions('en');
    final englishDescription = english[normalizedRegionId]?.trim();
    return englishDescription == null || englishDescription.isEmpty
        ? null
        : englishDescription;
  }

  Future<List<_GeoQuizDefinition>> _loadDefinitions() {
    return _definitionsFuture ??= _readDefinitions();
  }

  Future<List<_GeoQuizDefinition>> _readDefinitions() async {
    final raw = await _assetStringLoader(_quizzesAssetPath);
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
      final access = LearnAccessParser.fromRaw(
        quiz['access']?.toString() ?? 'pro',
      );
      final rawRegionIds = quiz['regionIds'];
      if (id.isEmpty || title.isEmpty || rawRegionIds is! List) continue;
      final regionIds = [
        for (final rawId in rawRegionIds)
          if (rawId.toString().trim().isNotEmpty) rawId.toString().trim(),
      ];
      if (regionIds.isEmpty) continue;
      definitions.add(
        _GeoQuizDefinition(
          id: id,
          title: title,
          subtitle: subtitle.isEmpty ? 'Countries' : subtitle,
          access: access,
          order: int.tryParse(quiz['order']?.toString() ?? '') ?? sourceIndex,
          regionIds: regionIds,
        ),
      );
    }
    definitions.sort((a, b) => a.order.compareTo(b.order));
    return definitions;
  }

  Future<Map<String, _GeoQuizCountryMeta>> _loadCountryMeta() {
    return _countryMetaFuture ??= _readCountryMeta();
  }

  Future<Map<String, _GeoQuizCountryMeta>> _readCountryMeta() async {
    final raw = await _assetStringLoader(_countryNamesAssetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const <String, _GeoQuizCountryMeta>{};
    final countries = decoded['countries'];
    if (countries is! Map) return const <String, _GeoQuizCountryMeta>{};

    final result = <String, _GeoQuizCountryMeta>{};
    for (final entry in countries.entries) {
      final id = entry.key.toString().trim();
      final rawMeta = entry.value;
      if (id.isEmpty || rawMeta is! Map) continue;
      final meta = rawMeta.cast<String, dynamic>();
      final names = <String, String>{};
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
      result[id] = _GeoQuizCountryMeta(
        countryCode: _countryCodeForMeta(meta, id),
        names: names,
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
      countryCode: meta?.countryCode ?? _countryCodeForId(regionId),
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

  Future<Map<String, String>> _loadDescriptions(String languageCode) {
    return _descriptionFutures[languageCode] ??= _readDescriptions(
      languageCode,
    );
  }

  Future<Map<String, String>> _readDescriptions(String languageCode) async {
    final raw = await _assetStringLoader(
      '$_geoQuizAssetDirectory/countries_descriptions_$languageCode.json',
    );
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const <String, String>{};
    final countries = decoded['countries'];
    if (countries is! Map) return const <String, String>{};

    final result = <String, String>{};
    for (final entry in countries.entries) {
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
    required this.title,
    required this.subtitle,
    required this.access,
    required this.order,
    required this.regionIds,
  });

  final String id;
  final String title;
  final String subtitle;
  final LearnAccess access;
  final int order;
  final List<String> regionIds;
}

class _GeoQuizCountryMeta {
  const _GeoQuizCountryMeta({required this.countryCode, required this.names});

  final String? countryCode;
  final Map<String, String> names;
}
