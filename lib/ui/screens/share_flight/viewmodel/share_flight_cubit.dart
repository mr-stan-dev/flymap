import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/data/local/mappers/flight_map_mapper.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/map_download_config.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'share_flight_state.dart';

class ShareFlightCubit extends Cubit<ShareFlightState> {
  ShareFlightCubit({required Flight flight})
    : super(ShareFlightState.initial(flight: flight)) {
    _loadStyle();
  }

  static const String _fallbackStyleUrl =
      'https://tiles.openfreemap.org/styles/liberty';
  final Logger _logger = const Logger('ShareFlightCubit');
  final FlightMapStyleMapper _styleMapper = FlightMapStyleMapper();

  Future<void> _loadStyle() async {
    try {
      final styleAsset = await rootBundle.loadString(
        'assets/styles/openfreemap_offline_style.json',
      );
      final storedPath = state.flight.flightMap?.filePath ?? '';
      if (storedPath.isEmpty) {
        emit(
          state.copyWith(
            status: ShareFlightStatus.ready,
            styleString: _fallbackStyleUrl,
            clearError: true,
          ),
        );
        return;
      }

      // DB path stores filename only to avoid stale iOS container paths.
      final fileName = p.basename(storedPath);
      final appDir = await getApplicationCacheDirectory();
      final resolvedPath = p.join(
        appDir.path,
        MapDownloadConfig.mbtilesDirectoryName,
        fileName,
      );
      final file = File(resolvedPath);
      if (!await file.exists()) {
        _logger.error('MBTiles file not found for share map: $resolvedPath');
        emit(
          state.copyWith(
            status: ShareFlightStatus.ready,
            styleString: _fallbackStyleUrl,
            errorMessage: t.shareFlight.offlineMapMissing,
          ),
        );
        return;
      }

      final style = _styleMapper.mapStyleWithMbtiles(
        styleAsset,
        file.absolute.path,
        cacheDir: appDir.path,
      );
      emit(
        state.copyWith(
          status: ShareFlightStatus.ready,
          styleString: style,
          clearError: true,
        ),
      );
    } catch (e) {
      _logger.error('Failed to load map style for sharing: $e');
      emit(
        state.copyWith(
          status: ShareFlightStatus.ready,
          styleString: _fallbackStyleUrl,
          errorMessage: t.shareFlight.offlineStyleFailed,
        ),
      );
    }
  }

  Future<void> shareRouteScreenshot({
    required Future<String?> Function() captureScreenshot,
    required Rect sharePositionOrigin,
  }) async {
    if (state.isSharing) return;
    emit(state.copyWith(status: ShareFlightStatus.sharing, clearError: true));

    try {
      final screenshotPath = await captureScreenshot();
      if (screenshotPath == null || screenshotPath.isEmpty) {
        emit(
          state.copyWith(
            status: ShareFlightStatus.ready,
            errorMessage: t.shareFlight.captureFailed,
          ),
        );
        return;
      }

      final route = state.flight.route;
      await Share.shareXFiles(
        [XFile(screenshotPath)],
        text: t.shareFlight.shareText(
          from: route.departure.displayCode,
          to: route.arrival.displayCode,
        ),
        sharePositionOrigin: sharePositionOrigin,
      );
      emit(state.copyWith(status: ShareFlightStatus.ready, clearError: true));
    } catch (e) {
      _logger.error('Failed to share route screenshot: $e');
      emit(
        state.copyWith(
          status: ShareFlightStatus.ready,
          errorMessage: t.shareFlight.shareFailed,
        ),
      );
    }
  }
}
