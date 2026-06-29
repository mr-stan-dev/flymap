import 'package:flymap/domain/entity/geo_quiz.dart';
import 'package:flymap/i18n/strings.g.dart';

String localizedGeoQuizTitle(Translations t, GeoQuizSummary summary) {
  return switch (summary.id) {
    'countries_africa' => t.learn.geoQuiz.quizCountriesAfricaTitle,
    'countries_europe' => t.learn.geoQuiz.quizCountriesEuropeTitle,
    'countries_asia' => t.learn.geoQuiz.quizCountriesAsiaTitle,
    'countries_north_america' => t.learn.geoQuiz.quizCountriesNorthAmericaTitle,
    'countries_south_america' => t.learn.geoQuiz.quizCountriesSouthAmericaTitle,
    'countries_oceania' => t.learn.geoQuiz.quizCountriesOceaniaTitle,
    'countries_all' ||
    'countries_world' => t.learn.geoQuiz.quizCountriesAllTitle,
    'geography_seas' => t.learn.geoQuiz.quizGeographySeasTitle,
    'geography_mountain_ranges' =>
      t.learn.geoQuiz.quizGeographyMountainRangesTitle,
    'geography_lakes' => t.learn.geoQuiz.quizGeographyLakesTitle,
    'geography_islands' => t.learn.geoQuiz.quizGeographyIslandsTitle,
    'geography_other' => t.learn.geoQuiz.quizGeographyOtherTitle,
    _ => summary.title,
  };
}

String localizedGeoQuizSubtitle(Translations t, GeoQuizSummary summary) {
  return switch (summary.id) {
    'countries_africa' ||
    'countries_europe' ||
    'countries_asia' ||
    'countries_north_america' ||
    'countries_south_america' ||
    'countries_oceania' => t.learn.geoQuiz.quizCountriesSubtitle,
    'countries_all' ||
    'countries_world' => t.learn.geoQuiz.quizCountriesAllSubtitle,
    'geography_seas' => t.learn.geoQuiz.quizGeographySeasTitle,
    'geography_mountain_ranges' =>
      t.learn.geoQuiz.quizGeographyMountainRangesTitle,
    'geography_lakes' => t.learn.geoQuiz.quizGeographyLakesTitle,
    'geography_islands' => t.learn.geoQuiz.quizGeographyIslandsTitle,
    'geography_other' => t.learn.geoQuiz.quizGeographyOtherSubtitle,
    _ => summary.subtitle,
  };
}
