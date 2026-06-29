import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/geo_quiz_progress_repository.dart';
import 'package:flymap/repository/geo_quiz_repository.dart';
import 'package:flymap/ui/screens/home/tabs/learn/geo_quiz/viewmodel/geo_quiz_list_state.dart';

class GeoQuizListCubit extends Cubit<GeoQuizListState> {
  GeoQuizListCubit({
    required GeoQuizRepository repository,
    required GeoQuizProgressRepository progressRepository,
    required AppAnalytics analytics,
  }) : _repository = repository,
       _progressRepository = progressRepository,
       _analytics = analytics,
       super(const GeoQuizListLoading());

  final GeoQuizRepository _repository;
  final GeoQuizProgressRepository _progressRepository;
  final AppAnalytics _analytics;
  bool _openedLogged = false;

  Future<void> open({required bool isProUser}) async {
    await load();
    final current = state;
    if (_openedLogged || current is! GeoQuizListLoaded) {
      return;
    }
    _openedLogged = true;
    unawaited(
      _analytics.log(
        GeoQuizListOpenedEvent(
          quizCount: current.quizzes.length,
          isProUser: isProUser,
        ),
      ),
    );
  }

  Future<void> load() async {
    emit(const GeoQuizListLoading());
    try {
      final quizzes = await _repository.getQuizzes();
      final progressByQuizId = await _progressRepository.getByQuizIds(
        quizzes.map((quiz) => quiz.id),
      );
      emit(
        GeoQuizListLoaded(quizzes: quizzes, progressByQuizId: progressByQuizId),
      );
    } catch (_) {
      emit(GeoQuizListError(message: t.learn.geoQuiz.failedToLoad));
    }
  }

  Future<void> refreshProgress() async {
    final current = state;
    if (current is! GeoQuizListLoaded) return;
    final progressByQuizId = await _progressRepository.getByQuizIds(
      current.quizzes.map((quiz) => quiz.id),
    );
    emit(
      GeoQuizListLoaded(
        quizzes: current.quizzes,
        progressByQuizId: progressByQuizId,
      ),
    );
  }
}
