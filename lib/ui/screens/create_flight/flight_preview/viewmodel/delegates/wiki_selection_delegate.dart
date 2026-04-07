part of '../flight_preview_cubit.dart';

class WikiSelectionDelegate {
  WikiSelectionDelegate(this._cubit);

  final FlightPreviewCubit _cubit;

  void toggleWikiArticleSelection(String url) {
    if (_cubit.state.step != CreateFlightStep.wikipediaArticles) return;
    if (!_cubit.state.articleCandidates.any(
      (candidate) => candidate.url == url,
    )) {
      return;
    }

    final current = _cubit.state.selectedArticleUrls.toList();
    final currentSet = current.toSet();
    if (currentSet.contains(url)) {
      current.removeWhere((item) => item == url);
      _cubit._emitState(
        _cubit.state.copyWith(
          selectedArticleUrls: current,
          clearErrorMessage: true,
        ),
      );
      return;
    }

    current.add(url);
    _cubit._emitState(
      _cubit.state.copyWith(
        selectedArticleUrls: current,
        clearErrorMessage: true,
      ),
    );
  }

  void toggleAllWikiArticleSelections() {
    if (_cubit.state.step != CreateFlightStep.wikipediaArticles) return;
    final candidateUrls = _cubit.state.articleCandidates
        .map((e) => e.url)
        .toList();
    if (candidateUrls.isEmpty) return;

    final selectedSet = _cubit.state.selectedArticleUrls.toSet();
    final allSelected = candidateUrls.every(selectedSet.contains);

    _cubit._emitState(
      _cubit.state.copyWith(
        selectedArticleUrls: allSelected ? const [] : candidateUrls,
        clearErrorMessage: true,
      ),
    );
  }
}
