import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/repository/geo_quiz_progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPrefsGeoQuizProgressRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    repository = SharedPrefsGeoQuizProgressRepository();
  });

  test('persists solved region ids per quiz', () async {
    await repository.markSolved(quizId: 'countries_africa', regionId: 'ao');
    await repository.markSolved(quizId: 'countries_africa', regionId: 'eg');
    await repository.markSolved(quizId: 'countries_europe', regionId: 'fr');

    final africa = await repository.getProgress('countries_africa');
    final europe = await repository.getProgress('countries_europe');

    expect(africa.solvedRegionIds, {'ao', 'eg'});
    expect(europe.solvedRegionIds, {'fr'});
  });

  test('reset clears only selected quiz', () async {
    await repository.markSolved(quizId: 'countries_africa', regionId: 'ao');
    await repository.markSolved(quizId: 'countries_europe', regionId: 'fr');

    await repository.reset('countries_africa');

    expect(
      (await repository.getProgress('countries_africa')).solvedRegionIds,
      isEmpty,
    );
    expect((await repository.getProgress('countries_europe')).solvedRegionIds, {
      'fr',
    });
  });
}
