part of '../flight_preview_cubit.dart';

class MapAndStepNavigationDelegate {
  MapAndStepNavigationDelegate(this._cubit);

  final FlightPreviewCubit _cubit;

  void continueFromOverview() {
    if (_cubit.state.flightRoute == null) return;
    _cubit._emitState(
      _cubit.state.copyWith(
        step: CreateFlightStep.weather,
        clearErrorMessage: true,
        clearDownloadErrorMessage: true,
      ),
    );
    unawaited(_cubit.fetchWeather());
  }

  void continueFromWeather() {
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
      case CreateFlightStep.routeNotSupported:
      case CreateFlightStep.overview:
        await _cubit.clearPendingFlightUnlock();
        return true;
      case CreateFlightStep.weather:
        _cubit._emitState(
          _cubit.state.copyWith(
            step: CreateFlightStep.overview,
            clearErrorMessage: true,
            clearDownloadErrorMessage: true,
          ),
        );
        return false;
      case CreateFlightStep.wikipediaArticles:
        _cubit._emitState(
          _cubit.state.copyWith(
            step: CreateFlightStep.weather,
            clearErrorMessage: true,
            clearDownloadErrorMessage: true,
          ),
        );
        return false;
    }
  }
}
