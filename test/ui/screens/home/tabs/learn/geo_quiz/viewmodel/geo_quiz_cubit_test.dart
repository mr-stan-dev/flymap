import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/domain/entity/geo_quiz.dart';
import 'package:flymap/domain/entity/learn_access.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/geo_quiz_progress_repository.dart';
import 'package:flymap/repository/geo_quiz_repository.dart';
import 'package:flymap/ui/screens/home/tabs/learn/geo_quiz/viewmodel/geo_quiz_cubit.dart';
import 'package:flymap/ui/screens/home/tabs/learn/geo_quiz/viewmodel/geo_quiz_list_cubit.dart';
import 'package:flymap/ui/screens/home/tabs/learn/geo_quiz/viewmodel/geo_quiz_list_state.dart';
import 'package:flymap/ui/screens/home/tabs/learn/geo_quiz/viewmodel/geo_quiz_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  test('loads geo quiz summaries', () async {
    final cubit = _buildListCubit(
      repository: AssetGeoQuizRepository(),
      progressRepository: _InMemoryGeoQuizProgressRepository(),
    );
    addTearDown(cubit.close);

    await cubit.load();

    final state = cubit.state;
    expect(state, isA<GeoQuizListLoaded>());
    expect((state as GeoQuizListLoaded).quizzes.map((quiz) => quiz.title), [
      'Europe',
      'Oceania',
      'Africa',
      'Asia',
      'North America',
      'South America',
      'All Countries',
    ]);
    expect(state.quizzes.take(2).every((quiz) => !quiz.isProOnly), isTrue);
    expect(
      state.quizzes.skip(2).every((quiz) => quiz.access == LearnAccess.pro),
      isTrue,
    );
  });

  test('logs list opened only for explicit open action', () async {
    final analytics = _RecordingAnalytics();
    final cubit = _buildListCubit(
      repository: AssetGeoQuizRepository(),
      progressRepository: _InMemoryGeoQuizProgressRepository(),
      analytics: analytics,
    );
    addTearDown(cubit.close);

    await cubit.load();
    expect(analytics.events.whereType<GeoQuizListOpenedEvent>(), isEmpty);

    await cubit.open(isProUser: false);
    await cubit.open(isProUser: false);

    final opened = analytics.events.whereType<GeoQuizListOpenedEvent>().single;
    expect(opened.quizCount, 7);
    expect(opened.isProUser, isFalse);
  });

  test('loads generated country regions from bundled GeoJSON assets', () async {
    final repository = AssetGeoQuizRepository();

    final europe = await repository.getRegions(quizId: 'countries_europe');
    final allCountries = await repository.getRegions(quizId: 'countries_all');

    expect(europe.length, 45);
    expect(allCountries.length, 198);
    expect(europe.map((region) => region.id), contains('VA'));
    expect(allCountries.map((region) => region.id), contains('TV'));
    expect(
      europe.firstWhere((region) => region.id == 'FR').names,
      containsPair('de', 'Frankreich'),
    );
    expect(
      europe.map((region) => region.labelForLanguage('en')),
      contains('Germany'),
    );
  });

  test('bundled country geometry preserves multipart countries', () async {
    final raw = await rootBundle.loadString(
      'assets/data/geo_quiz/countries/countries.geojson',
    );
    final geoJson = jsonDecode(raw) as Map<String, dynamic>;
    final features = geoJson['features'] as List<dynamic>;
    for (final rawFeature in features) {
      final feature = rawFeature as Map<String, dynamic>;
      final id = feature['id'];
      final properties = feature['properties'] as Map<String, dynamic>;
      expect(properties['id'], id);
      expect(properties['countryCode'], id);
    }
    final japan =
        features.firstWhere(
              (feature) => (feature as Map<String, dynamic>)['id'] == 'JP',
            )
            as Map<String, dynamic>;
    final geometry = japan['geometry'] as Map<String, dynamic>;

    expect(geometry['type'], 'MultiPolygon');
    expect((geometry['coordinates'] as List<dynamic>).length, greaterThan(1));
  });

  test('loads country descriptions with language fallback', () async {
    final repository = AssetGeoQuizRepository();

    final french = await repository.getRegionDescription(
      regionId: 'FR',
      languageCode: 'fr',
    );
    final fallback = await repository.getRegionDescription(
      regionId: 'FR',
      languageCode: 'it',
    );
    final missing = await repository.getRegionDescription(
      regionId: 'AG',
      languageCode: 'en',
    );

    expect(french, contains('plaines'));
    expect(fallback, contains('coastal plains'));
    expect(missing, isNull);
  });

  test('filters suggestions from query and marks answer solved', () async {
    final progressRepository = _InMemoryGeoQuizProgressRepository();
    final cubit = _buildGeoQuizCubit(
      summary: const GeoQuizSummary(
        id: 'countries_africa',
        title: 'Africa',
        subtitle: 'Countries',
        totalCount: 54,
      ),
      repository: _StaticGeoQuizRepository(),
      progressRepository: progressRepository,
    );
    addTearDown(cubit.close);

    await cubit.load();
    var state = cubit.state as GeoQuizLoaded;
    expect(state.currentRegionId, 'ao');

    cubit.updateQuery('a');
    state = cubit.state as GeoQuizLoaded;
    expect(state.suggestions, isEmpty);

    cubit.updateQuery('eg');
    state = cubit.state as GeoQuizLoaded;
    expect(state.suggestions.map((item) => item.label), ['Egypt']);

    await cubit.acceptSuggestion(state.suggestions.single);
    state = cubit.state as GeoQuizLoaded;
    expect(state.solvedCount, 0);
    expect(state.feedback?.isCorrect, isFalse);
    expect(state.feedback?.label, 'Egypt');

    cubit.updateQuery('can');
    state = cubit.state as GeoQuizLoaded;
    expect(state.suggestions.map((item) => item.label), ['Canada']);

    await cubit.acceptSuggestion(state.suggestions.single);
    state = cubit.state as GeoQuizLoaded;
    expect(state.solvedCount, 0);
    expect(state.feedback?.isCorrect, isFalse);
    expect(state.feedback?.label, 'Canada');

    cubit.updateQuery('an');

    state = cubit.state as GeoQuizLoaded;
    expect(state.suggestions.map((item) => item.label), contains('Angola'));
    expect(state.feedback, isNull);

    await cubit.acceptSuggestion(
      state.suggestions.firstWhere((item) => item.label == 'Angola'),
    );

    state = cubit.state as GeoQuizLoaded;
    expect(state.solvedCount, 1);
    expect(state.progress.solvedRegionIds, contains('ao'));
    expect(state.query, isEmpty);
    expect(state.suggestions, isEmpty);
    expect(state.feedback?.isCorrect, isTrue);
    expect(state.feedback?.label, 'Angola');
    expect(state.currentRegionId, 'eg');

    cubit.updateQuery('egy');
    state = cubit.state as GeoQuizLoaded;
    expect(state.suggestions.map((item) => item.label), ['Egypt']);
  });

  test('accepting duplicate solved answer leaves progress unchanged', () async {
    final cubit = _buildGeoQuizCubit(
      summary: const GeoQuizSummary(
        id: 'countries_africa',
        title: 'Africa',
        subtitle: 'Countries',
        totalCount: 54,
      ),
      repository: _StaticGeoQuizRepository(),
      progressRepository: _InMemoryGeoQuizProgressRepository(),
    );
    addTearDown(cubit.close);

    await cubit.load();
    await cubit.acceptSuggestion(
      const GeoQuizAnswerSuggestion(regionId: 'ao', label: 'Angola'),
    );
    await cubit.acceptSuggestion(
      const GeoQuizAnswerSuggestion(regionId: 'ao', label: 'Angola'),
    );

    final state = cubit.state as GeoQuizLoaded;
    expect(state.solvedCount, 1);
  });

  test('fresh quiz session restores previously solved regions', () async {
    final progressRepository = _InMemoryGeoQuizProgressRepository();
    await progressRepository.markSolved(
      quizId: 'countries_africa',
      regionId: 'ao',
    );
    final cubit = _buildGeoQuizCubit(
      summary: const GeoQuizSummary(
        id: 'countries_africa',
        title: 'Africa',
        subtitle: 'Countries',
        totalCount: 2,
      ),
      repository: _StaticGeoQuizRepository(),
      progressRepository: progressRepository,
    );
    addTearDown(cubit.close);

    await cubit.load();

    final state = cubit.state as GeoQuizLoaded;
    expect(state.progress.solvedRegionIds, {'ao'});
    expect(state.solvedCount, 1);
    expect(state.currentRegionId, 'eg');
  });

  test('skip moves current region to the end without marking solved', () async {
    final cubit = _buildGeoQuizCubit(
      summary: const GeoQuizSummary(
        id: 'countries_africa',
        title: 'Africa',
        subtitle: 'Countries',
        totalCount: 54,
      ),
      repository: _StaticGeoQuizRepository(),
      progressRepository: _InMemoryGeoQuizProgressRepository(),
    );
    addTearDown(cubit.close);

    await cubit.load();
    var state = cubit.state as GeoQuizLoaded;
    expect(state.currentRegionId, 'ao');

    cubit.skipCurrentRegion();

    state = cubit.state as GeoQuizLoaded;
    expect(state.currentRegionId, 'eg');
    expect(state.solvedCount, 0);
    expect(state.regions.last.id, 'ao');
  });

  test('reset clears solved ids for quiz', () async {
    final cubit = _buildGeoQuizCubit(
      summary: const GeoQuizSummary(
        id: 'countries_africa',
        title: 'Africa',
        subtitle: 'Countries',
        totalCount: 54,
      ),
      repository: _StaticGeoQuizRepository(),
      progressRepository: _InMemoryGeoQuizProgressRepository(),
    );
    addTearDown(cubit.close);

    await cubit.load();
    await cubit.acceptSuggestion(
      const GeoQuizAnswerSuggestion(regionId: 'ao', label: 'Angola'),
    );
    await cubit.reset();

    final state = cubit.state as GeoQuizLoaded;
    expect(state.solvedCount, 0);
  });

  test('logs quiz start and completion once with session details', () async {
    final analytics = _RecordingAnalytics();
    var now = DateTime(2026, 1, 1, 12);
    final cubit = _buildGeoQuizCubit(
      summary: const GeoQuizSummary(
        id: 'countries_africa',
        title: 'Africa',
        subtitle: 'Countries',
        totalCount: 2,
        access: LearnAccess.pro,
      ),
      repository: _StaticGeoQuizRepository(),
      progressRepository: _InMemoryGeoQuizProgressRepository(),
      analytics: analytics,
      isProUser: true,
      nowProvider: () => now,
    );
    addTearDown(cubit.close);

    await cubit.load();
    now = now.add(const Duration(seconds: 15));
    await cubit.acceptSuggestion(
      const GeoQuizAnswerSuggestion(regionId: 'ao', label: 'Angola'),
    );
    await cubit.acceptSuggestion(
      const GeoQuizAnswerSuggestion(regionId: 'eg', label: 'Egypt'),
    );
    await cubit.acceptSuggestion(
      const GeoQuizAnswerSuggestion(regionId: 'eg', label: 'Egypt'),
    );

    final started = analytics.events.whereType<GeoQuizStartedEvent>().single;
    final completed = analytics.events
        .whereType<GeoQuizCompletedEvent>()
        .single;
    expect(started.postHogParameters, <String, Object>{
      'quiz_id': 'countries_africa',
      'access': 'pro',
      'is_pro_user': true,
      'solved_count': 0,
      'total_count': 2,
      'is_resume': false,
    });
    expect(completed.postHogParameters['duration_seconds'], 15);
  });

  test('does not log started when reopening a completed quiz', () async {
    final analytics = _RecordingAnalytics();
    final progressRepository = _InMemoryGeoQuizProgressRepository();
    await progressRepository.markSolved(
      quizId: 'countries_africa',
      regionId: 'ao',
    );
    await progressRepository.markSolved(
      quizId: 'countries_africa',
      regionId: 'eg',
    );
    final cubit = _buildGeoQuizCubit(
      summary: const GeoQuizSummary(
        id: 'countries_africa',
        title: 'Africa',
        subtitle: 'Countries',
        totalCount: 2,
      ),
      repository: _StaticGeoQuizRepository(),
      progressRepository: progressRepository,
      analytics: analytics,
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(analytics.events.whereType<GeoQuizStartedEvent>(), isEmpty);
    expect(analytics.events.whereType<GeoQuizCompletedEvent>(), isEmpty);
  });

  test('logs started when resetting a completed quiz for replay', () async {
    final analytics = _RecordingAnalytics();
    final progressRepository = _InMemoryGeoQuizProgressRepository();
    await progressRepository.markSolved(
      quizId: 'countries_africa',
      regionId: 'ao',
    );
    await progressRepository.markSolved(
      quizId: 'countries_africa',
      regionId: 'eg',
    );
    final cubit = _buildGeoQuizCubit(
      summary: const GeoQuizSummary(
        id: 'countries_africa',
        title: 'Africa',
        subtitle: 'Countries',
        totalCount: 2,
      ),
      repository: _StaticGeoQuizRepository(),
      progressRepository: progressRepository,
      analytics: analytics,
    );
    addTearDown(cubit.close);

    await cubit.load();
    await cubit.reset();

    final started = analytics.events.whereType<GeoQuizStartedEvent>().single;
    expect(started.postHogParameters, <String, Object>{
      'quiz_id': 'countries_africa',
      'access': 'free',
      'is_pro_user': false,
      'solved_count': 0,
      'total_count': 2,
      'is_resume': false,
    });
  });
}

GeoQuizListCubit _buildListCubit({
  required GeoQuizRepository repository,
  required GeoQuizProgressRepository progressRepository,
  AppAnalytics? analytics,
}) {
  return GeoQuizListCubit(
    repository: repository,
    progressRepository: progressRepository,
    analytics: analytics ?? _RecordingAnalytics(),
  );
}

GeoQuizCubit _buildGeoQuizCubit({
  required GeoQuizSummary summary,
  required GeoQuizRepository repository,
  required GeoQuizProgressRepository progressRepository,
  AppAnalytics? analytics,
  bool isProUser = false,
  GeoQuizNowProvider? nowProvider,
}) {
  return GeoQuizCubit(
    summary: summary,
    repository: repository,
    progressRepository: progressRepository,
    languageCodeProvider: () => 'en',
    analytics: analytics ?? _RecordingAnalytics(),
    isProUser: isProUser,
    nowProvider: nowProvider ?? DateTime.now,
  );
}

class _RecordingAnalytics implements AppAnalytics {
  final List<AnalyticsEvent> events = <AnalyticsEvent>[];

  @override
  Future<void> log(AnalyticsEvent event) async {
    events.add(event);
  }

  @override
  Future<void> setGlobalContext({
    required String appVersion,
    required String buildNumber,
    required String platform,
    required String appEnv,
  }) async {}

  @override
  Future<void> setSubscriptionContext({required bool isPro}) async {}
}

class _InMemoryGeoQuizProgressRepository implements GeoQuizProgressRepository {
  final Map<String, GeoQuizProgress> _state = <String, GeoQuizProgress>{};

  @override
  Future<Map<String, GeoQuizProgress>> getByQuizIds(
    Iterable<String> quizIds,
  ) async {
    return <String, GeoQuizProgress>{
      for (final id in quizIds) id: _state[id] ?? GeoQuizProgress(quizId: id),
    };
  }

  @override
  Future<GeoQuizProgress> getProgress(String quizId) async {
    return _state[quizId] ?? GeoQuizProgress(quizId: quizId);
  }

  @override
  Future<GeoQuizProgress> markSolved({
    required String quizId,
    required String regionId,
  }) async {
    final current = _state[quizId] ?? GeoQuizProgress(quizId: quizId);
    final updated = current.copyWith(
      solvedRegionIds: <String>{...current.solvedRegionIds, regionId},
    );
    _state[quizId] = updated;
    return updated;
  }

  @override
  Future<GeoQuizProgress> reset(String quizId) async {
    _state.remove(quizId);
    return GeoQuizProgress(quizId: quizId);
  }
}

class _StaticGeoQuizRepository implements GeoQuizRepository {
  static const _summary = GeoQuizSummary(
    id: 'countries_africa',
    title: 'Africa',
    subtitle: 'Countries',
    totalCount: 2,
  );

  static const _regions = <GeoQuizRegion>[
    GeoQuizRegion(
      id: 'ao',
      countryCode: 'AO',
      names: {'en': 'Angola', 'fr': 'Angola', 'de': 'Angola', 'es': 'Angola'},
    ),
    GeoQuizRegion(
      id: 'eg',
      countryCode: 'EG',
      names: {'en': 'Egypt', 'fr': 'Egypte', 'de': 'Agypten', 'es': 'Egipto'},
    ),
  ];

  @override
  Future<List<GeoQuizSummary>> getQuizzes() async => const [_summary];

  @override
  Future<List<GeoQuizRegion>> getRegions({required String quizId}) async {
    return quizId == _summary.id ? _regions : const <GeoQuizRegion>[];
  }

  @override
  Future<String?> getRegionDescription({
    required String regionId,
    required String languageCode,
  }) async {
    return null;
  }
}
