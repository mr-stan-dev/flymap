import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flymap/crashlytics/app_crashlytics.dart';
import 'package:flymap/data/local/mappers/flight_map_mapper.dart';
import 'package:flymap/data/map_asset_cache_service.dart';
import 'package:flymap/data/tiles_downloader/mbtiles_validator.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/map_download_config.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FlightMapStyleLoadResult {
  const FlightMapStyleLoadResult._({
    required this.styleString,
    required this.errorMessage,
  });

  final String? styleString;
  final String? errorMessage;

  bool get isSuccess => styleString != null;

  factory FlightMapStyleLoadResult.success(String styleString) {
    return FlightMapStyleLoadResult._(
      styleString: styleString,
      errorMessage: null,
    );
  }

  factory FlightMapStyleLoadResult.failure(String errorMessage) {
    return FlightMapStyleLoadResult._(
      styleString: null,
      errorMessage: errorMessage,
    );
  }
}

class FlightMapStyleLoader {
  const FlightMapStyleLoader({
    required this.logger,
    required this.styleMapper,
    required this.mapAssetCacheService,
    required this.crashlytics,
  });

  final Logger logger;
  final FlightMapStyleMapper styleMapper;
  final MapAssetCacheService mapAssetCacheService;
  final AppCrashlytics crashlytics;

  Future<FlightMapStyleLoadResult> load(Flight flight) async {
    final storedPath = flight.flightMap?.filePath ?? '';
    if (storedPath.isEmpty) {
      logger.log('No MBTiles file path found');
      return FlightMapStyleLoadResult.failure(t.flight.map.offlineNotAvailable);
    }

    final fileName = p.basename(storedPath);
    final appDir = await getApplicationCacheDirectory();
    final resolvedPath = p.join(
      appDir.path,
      MapDownloadConfig.mbtilesDirectoryName,
      fileName,
    );
    final file = File(resolvedPath);

    if (!await file.exists()) {
      logger.error('MBTiles file not found: $resolvedPath');
      return FlightMapStyleLoadResult.failure(t.flight.map.offlineMissing);
    }

    logger.log('Loading mbtiles: $fileName');
    logger.log('Resolved MBTiles path: ${file.absolute.path}');

    final validationResult = await MbtilesValidator.validate(
      file.absolute.path,
      logger: logger,
    );
    if (!validationResult.isValid) {
      logger.error(
        'MBTiles validation failed for ${file.absolute.path}: '
        '${validationResult.errorMessage}',
      );
      return FlightMapStyleLoadResult.failure(
        validationResult.errorMessage ?? t.flight.map.validationFailed,
      );
    }

    try {
      mapAssetCacheService.ensureReadyInBackground();

      final styleString = await rootBundle.loadString(
        'assets/styles/openfreemap_offline_style.json',
      );
      final cacheDir = (await getApplicationCacheDirectory()).path;
      final updated = styleMapper.mapStyleWithMbtiles(
        styleString,
        file.absolute.path,
        cacheDir: cacheDir,
      );
      return FlightMapStyleLoadResult.success(updated);
    } catch (error, stack) {
      logger.error('Error loading style from assets: $error');
      await crashlytics.recordError(
        error,
        stack,
        fatal: false,
        reason: 'flight_map_prepare_local_style',
      );
      return FlightMapStyleLoadResult.failure(t.flight.map.loadStyleFailed);
    }
  }
}
