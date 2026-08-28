import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flymap/crashlytics/app_crashlytics.dart';
import 'package:flymap/data/local/mappers/flight_map_mapper.dart';
import 'package:flymap/data/map_asset_cache_service.dart';
import 'package:flymap/data/tiles_downloader/mbtiles_validator.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/offline_map_style.dart';
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
  FlightMapStyleLoader({
    required this.logger,
    required this.styleMapper,
    required this.mapAssetCacheService,
    required this.crashlytics,
    Future<String> Function(String assetPath)? assetStyleLoader,
    Future<Directory> Function()? applicationSupportDirectoryProvider,
    Future<Directory> Function()? cacheDirectoryProvider,
    Future<MbtilesValidationResult> Function(String path, Logger logger)?
    mbtilesValidator,
  }) : _assetStyleLoader = assetStyleLoader ?? rootBundle.loadString,
       _applicationSupportDirectoryProvider =
           applicationSupportDirectoryProvider ??
           getApplicationSupportDirectory,
       _cacheDirectoryProvider =
           cacheDirectoryProvider ?? getApplicationCacheDirectory,
       _mbtilesValidator = mbtilesValidator ?? _defaultMbtilesValidator;

  final Logger logger;
  final FlightMapStyleMapper styleMapper;
  final MapAssetCacheService mapAssetCacheService;
  final AppCrashlytics crashlytics;
  final Future<String> Function(String assetPath) _assetStyleLoader;
  final Future<Directory> Function() _applicationSupportDirectoryProvider;
  final Future<Directory> Function() _cacheDirectoryProvider;
  final Future<MbtilesValidationResult> Function(String path, Logger logger)
  _mbtilesValidator;

  static const String _libertyAssetPath =
      'assets/styles/openfreemap_offline_style.json';
  static const String _fiordAssetPath =
      'assets/styles/openfreemap_offline_fiord_style.json';

  Future<FlightMapStyleLoadResult> load(
    Flight flight, {
    required OfflineMapStyle style,
  }) async {
    final storedPath = flight.flightMap?.filePath ?? '';
    if (storedPath.isEmpty) {
      logger.log('No MBTiles file path found');
      return FlightMapStyleLoadResult.failure(t.flight.map.offlineNotAvailable);
    }

    final fileName = p.basename(storedPath);
    final supportDir = await _applicationSupportDirectoryProvider();
    final cacheDir = await _cacheDirectoryProvider();
    final durablePath = p.join(
      supportDir.path,
      MapDownloadConfig.mbtilesDirectoryName,
      fileName,
    );
    final legacyCachePath = p.join(
      cacheDir.path,
      MapDownloadConfig.mbtilesDirectoryName,
      fileName,
    );
    final durableFile = File(durablePath);
    final file = await durableFile.exists()
        ? durableFile
        : File(legacyCachePath);

    if (!await file.exists()) {
      logger.error(
        'MBTiles file not found in durable or legacy storage: '
        '$durablePath, $legacyCachePath',
      );
      return FlightMapStyleLoadResult.failure(t.flight.map.offlineMissing);
    }

    logger.log('Loading mbtiles: $fileName');
    logger.log('Resolved MBTiles path: ${file.absolute.path}');

    final validationResult = await _mbtilesValidator(
      file.absolute.path,
      logger,
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

      final styleString = await _assetStyleLoader(_assetPathFor(style));
      final updated = styleMapper.mapStyleWithMbtiles(
        styleString,
        file.absolute.path,
        cacheDir: cacheDir.path,
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

  String _assetPathFor(OfflineMapStyle style) {
    return switch (style) {
      OfflineMapStyle.liberty => _libertyAssetPath,
      OfflineMapStyle.fiord => _fiordAssetPath,
    };
  }

  static Future<MbtilesValidationResult> _defaultMbtilesValidator(
    String path,
    Logger logger,
  ) {
    return MbtilesValidator.validate(path, logger: logger);
  }
}
