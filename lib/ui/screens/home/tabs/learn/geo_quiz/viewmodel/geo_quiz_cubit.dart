import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/geo_quiz.dart';
import 'package:flymap/i18n/app_localization.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/geo_quiz_progress_repository.dart';
import 'package:flymap/repository/geo_quiz_repository.dart';
import 'package:flymap/ui/screens/home/tabs/learn/geo_quiz/viewmodel/geo_quiz_state.dart';
import 'package:flymap/utils/country_name_utils.dart';
import 'package:get_it/get_it.dart';

typedef GeoQuizLanguageCodeProvider = String Function();

class GeoQuizCubit extends Cubit<GeoQuizState> {
  GeoQuizCubit({
    required GeoQuizSummary summary,
    GeoQuizRepository? repository,
    GeoQuizProgressRepository? progressRepository,
    GeoQuizLanguageCodeProvider? languageCodeProvider,
    bool randomizeRegionOrder = true,
  }) : _summary = summary,
       _repository = repository ?? GetIt.I<GeoQuizRepository>(),
       _progressRepository =
           progressRepository ?? GetIt.I<GeoQuizProgressRepository>(),
       _languageCodeProvider =
           languageCodeProvider ?? (() => AppLocalization.currentLanguageCode),
       _randomizeRegionOrder = randomizeRegionOrder,
       super(const GeoQuizLoading());

  final GeoQuizSummary _summary;
  final GeoQuizRepository _repository;
  final GeoQuizProgressRepository _progressRepository;
  final GeoQuizLanguageCodeProvider _languageCodeProvider;
  final bool _randomizeRegionOrder;

  Future<void> load() async {
    emit(const GeoQuizLoading());
    try {
      final regions = _orderedRegions(
        await _repository.getRegions(quizId: _summary.id),
      );
      final progress = await _progressRepository.getProgress(_summary.id);
      emit(
        GeoQuizLoaded(
          summary: _summary,
          regions: regions,
          progress: _filterProgress(progress, regions),
        ),
      );
    } catch (_) {
      emit(GeoQuizError(message: t.learn.geoQuiz.failedToLoadQuiz));
    }
  }

  List<GeoQuizRegion> _orderedRegions(List<GeoQuizRegion> regions) {
    if (!_randomizeRegionOrder || regions.length < 2) return regions;
    return List<GeoQuizRegion>.of(regions)..shuffle(Random());
  }

  void updateQuery(String query) {
    final current = state;
    if (current is! GeoQuizLoaded) return;
    emit(
      current.copyWith(
        query: query,
        suggestions: _suggestionsFor(current, query: query),
        clearFeedback: true,
      ),
    );
  }

  Future<void> acceptSuggestion(GeoQuizAnswerSuggestion suggestion) async {
    final current = state;
    if (current is! GeoQuizLoaded) return;
    final currentRegion = current.currentRegion;
    if (currentRegion == null || suggestion.regionId != currentRegion.id) {
      emit(
        current.copyWith(
          query: '',
          suggestions: const [],
          feedback: GeoQuizAnswerFeedback(
            isCorrect: false,
            label: suggestion.label,
          ),
        ),
      );
      return;
    }
    if (current.progress.solvedRegionIds.contains(suggestion.regionId)) {
      emit(
        current.copyWith(
          query: '',
          suggestions: const [],
          feedback: GeoQuizAnswerFeedback(
            isCorrect: true,
            label: suggestion.label,
          ),
        ),
      );
      return;
    }
    final updated = await _progressRepository.markSolved(
      quizId: current.summary.id,
      regionId: suggestion.regionId,
    );
    emit(
      current.copyWith(
        progress: _filterProgress(updated, current.regions),
        query: '',
        suggestions: const [],
        feedback: GeoQuizAnswerFeedback(
          isCorrect: true,
          label: suggestion.label,
        ),
      ),
    );
  }

  Future<void> submitQuery() async {
    final current = state;
    if (current is! GeoQuizLoaded) return;
    final normalizedQuery = _normalizeAnswer(current.query);
    if (normalizedQuery.isEmpty) return;

    final languageCode = _languageCodeProvider();
    final matchingRegion = _matchingUnsolvedRegion(
      current,
      normalizedQuery: normalizedQuery,
      languageCode: languageCode,
    );
    if (matchingRegion != null) {
      await acceptSuggestion(
        GeoQuizAnswerSuggestion(
          regionId: matchingRegion.id,
          label: matchingRegion.labelForLanguage(languageCode),
          countryCode: matchingRegion.countryCode,
        ),
      );
      return;
    }
    emit(
      current.copyWith(
        query: '',
        suggestions: const [],
        feedback: GeoQuizAnswerFeedback(isCorrect: false, label: current.query),
      ),
    );
  }

  Future<void> reset() async {
    final current = state;
    if (current is! GeoQuizLoaded) return;
    final resetProgress = await _progressRepository.reset(current.summary.id);
    emit(
      current.copyWith(
        progress: resetProgress,
        query: '',
        suggestions: const [],
        clearFeedback: true,
      ),
    );
  }

  void clearFeedback() {
    final current = state;
    if (current is! GeoQuizLoaded) return;
    emit(current.copyWith(clearFeedback: true));
  }

  Future<String?> loadRegionDescription(String regionId) {
    return _repository.getRegionDescription(
      regionId: regionId,
      languageCode: _languageCodeProvider(),
    );
  }

  String regionLabel(GeoQuizRegion region) {
    return region.labelForLanguage(_languageCodeProvider());
  }

  void skipCurrentRegion() {
    final current = state;
    if (current is! GeoQuizLoaded) return;
    final currentRegionId = current.currentRegionId;
    if (currentRegionId == null) return;

    final nextRegions = List<GeoQuizRegion>.of(current.regions);
    final index = nextRegions.indexWhere(
      (region) => region.id == currentRegionId,
    );
    if (index < 0) return;
    final region = nextRegions.removeAt(index);
    nextRegions.add(region);
    emit(
      current.copyWith(
        regions: nextRegions,
        query: '',
        suggestions: const [],
        clearFeedback: true,
      ),
    );
  }

  GeoQuizRegion? _matchingUnsolvedRegion(
    GeoQuizLoaded state, {
    required String normalizedQuery,
    required String languageCode,
  }) {
    for (final region in state.regions) {
      if (state.progress.solvedRegionIds.contains(region.id)) continue;
      final matches = region
          .answerLabelsForLanguage(languageCode)
          .map(_normalizeAnswer);
      if (matches.contains(normalizedQuery)) return region;
    }
    return null;
  }

  GeoQuizProgress _filterProgress(
    GeoQuizProgress progress,
    List<GeoQuizRegion> regions,
  ) {
    final validIds = regions.map((region) => region.id).toSet();
    if (validIds.isEmpty) {
      return progress.copyWith(solvedRegionIds: const <String>{});
    }
    return progress.copyWith(
      solvedRegionIds: progress.solvedRegionIds
          .where(validIds.contains)
          .toSet(),
    );
  }

  List<GeoQuizAnswerSuggestion> _suggestionsFor(
    GeoQuizLoaded state, {
    required String query,
  }) {
    final normalizedQuery = _normalizeAnswer(query);
    if (normalizedQuery.length < 2) {
      return const <GeoQuizAnswerSuggestion>[];
    }

    final languageCode = _languageCodeProvider();
    final suggestions = <GeoQuizAnswerSuggestion>[];
    final addedRegionIds = <String>{};
    final addedLabels = <String>{};
    final quizRegionByCountryCode = _quizRegionByCountryCode(state);
    void addSuggestion(GeoQuizAnswerSuggestion suggestion) {
      final normalizedLabel = _normalizeAnswer(suggestion.label);
      if (normalizedLabel.isEmpty || addedLabels.contains(normalizedLabel)) {
        return;
      }
      if (!suggestion.regionId.startsWith('country:') &&
          addedRegionIds.contains(suggestion.regionId)) {
        return;
      }
      suggestions.add(suggestion);
      addedLabels.add(normalizedLabel);
      if (!suggestion.regionId.startsWith('country:')) {
        addedRegionIds.add(suggestion.regionId);
      }
    }

    for (final countryCode in CountryNameUtils.countryCodes) {
      final label = CountryNameUtils.fromCode(
        countryCode,
        languageCode: languageCode,
      );
      if (!_normalizeAnswer(label).startsWith(normalizedQuery)) continue;

      final quizRegion = quizRegionByCountryCode[countryCode];
      if (quizRegion != null &&
          state.progress.solvedRegionIds.contains(quizRegion.id)) {
        continue;
      }
      addSuggestion(
        GeoQuizAnswerSuggestion(
          regionId: quizRegion?.id ?? 'country:$countryCode',
          label: label,
          countryCode: countryCode,
        ),
      );
    }

    for (final region in state.regions) {
      if (state.progress.solvedRegionIds.contains(region.id)) continue;
      final labels = region.answerLabelsForLanguage(languageCode);
      for (final label in labels) {
        if (!_normalizeAnswer(label).startsWith(normalizedQuery)) continue;
        addSuggestion(
          GeoQuizAnswerSuggestion(
            regionId: region.id,
            label: label,
            countryCode: region.countryCode,
          ),
        );
        break;
      }
    }

    suggestions.sort((a, b) => a.label.compareTo(b.label));
    return suggestions.take(6).toList(growable: false);
  }

  Map<String, GeoQuizRegion> _quizRegionByCountryCode(GeoQuizLoaded state) {
    final result = <String, GeoQuizRegion>{};
    for (final region in state.regions) {
      final countryCode = region.countryCode?.trim().toUpperCase();
      if (countryCode == null || countryCode.isEmpty) continue;
      result[countryCode] = region;
    }
    return result;
  }

  String _normalizeAnswer(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.isEmpty) return '';
    return lower
        .replaceAll(RegExp(r'[àáâãäåāăą]'), 'a')
        .replaceAll(RegExp(r'[çćč]'), 'c')
        .replaceAll(RegExp(r'[ďđ]'), 'd')
        .replaceAll(RegExp(r'[èéêëēėęě]'), 'e')
        .replaceAll(RegExp(r'[ìíîïīįı]'), 'i')
        .replaceAll(RegExp(r'[ł]'), 'l')
        .replaceAll(RegExp(r'[ñń]'), 'n')
        .replaceAll(RegExp(r'[òóôõöøō]'), 'o')
        .replaceAll(RegExp(r'[ř]'), 'r')
        .replaceAll(RegExp(r'[śš]'), 's')
        .replaceAll(RegExp(r'[ť]'), 't')
        .replaceAll(RegExp(r'[ùúûüūů]'), 'u')
        .replaceAll(RegExp(r'[ýÿ]'), 'y')
        .replaceAll(RegExp(r'[źżž]'), 'z')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
