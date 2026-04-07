part of '../flight_preview_cubit.dart';

class MapAndStepNavigationDelegate {
  MapAndStepNavigationDelegate(this._cubit);

  final FlightPreviewCubit _cubit;

  Future<void> continueFromMap() async {
    if (!_cubit.state.canContinueFromMap) return;
    _cubit._emitState(
      _cubit.state.copyWith(
        step: CreateFlightStep.overview,
        clearErrorMessage: true,
        clearDownloadErrorMessage: true,
      ),
    );
  }

  void selectMapDetailLevel(MapDetailLevel detailLevel) {
    if (_cubit.state.step != CreateFlightStep.mapPreview) return;
    if (_cubit.state.selectedMapDetailLevel == detailLevel) return;
    _cubit._emitState(
      _cubit.state.copyWith(
        selectedMapDetailLevel: detailLevel,
        clearErrorMessage: true,
      ),
    );
    final route = _cubit.state.flightRoute;
    if (route != null) {
      unawaited(_cubit._prefetchLocalPois(route, mapDetail: detailLevel));
    }
  }

  void continueFromOverview() {
    if (_cubit.state.flightRoute == null) return;
    _cubit._emitState(
      _cubit.state.copyWith(
        step: CreateFlightStep.wikipediaArticles,
        clearErrorMessage: true,
        clearDownloadErrorMessage: true,
      ),
    );
  }

  Future<bool> handleBackAction() async {
    if (_cubit.state.isDownloading) return false;

    switch (_cubit.state.step) {
      case CreateFlightStep.mapPreview:
      case CreateFlightStep.routeNotSupported:
        return true;
      case CreateFlightStep.overview:
        _cubit._emitState(
          _cubit.state.copyWith(
            step: CreateFlightStep.mapPreview,
            clearErrorMessage: true,
            clearDownloadErrorMessage: true,
          ),
        );
        return false;
      case CreateFlightStep.wikipediaArticles:
        _cubit._emitState(
          _cubit.state.copyWith(
            step: CreateFlightStep.overview,
            clearErrorMessage: true,
            clearDownloadErrorMessage: true,
          ),
        );
        return false;
    }
  }
}
