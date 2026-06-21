import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/geo_quiz_progress_repository.dart';
import 'package:flymap/repository/geo_quiz_repository.dart';
import 'package:flymap/ui/screens/home/tabs/learn/geo_quiz/viewmodel/geo_quiz_list_state.dart';
import 'package:get_it/get_it.dart';

class GeoQuizListCubit extends Cubit<GeoQuizListState> {
  GeoQuizListCubit({
    GeoQuizRepository? repository,
    GeoQuizProgressRepository? progressRepository,
  }) : _repository = repository ?? GetIt.I<GeoQuizRepository>(),
       _progressRepository =
           progressRepository ?? GetIt.I<GeoQuizProgressRepository>(),
       super(const GeoQuizListLoading());

  final GeoQuizRepository _repository;
  final GeoQuizProgressRepository _progressRepository;

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
