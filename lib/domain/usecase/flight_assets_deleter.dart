import 'dart:io';

import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_article.dart';
import 'package:flymap/domain/entity/flight_map.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/map_download_config.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Deletes a flight's on-disk assets (MBTiles maps, article media) while
/// preserving anything still referenced by ANOTHER flight.
///
/// Offline maps and article bundles are keyed by ROUTE, not flight
/// (`{routeCode}_{layer}.mbtiles`, `article_media/{routeCode}_...`), so two
/// flights on the same route share physical files. Deletion must therefore
/// be reference-counted: without it, deleting or completing flight A
/// destroys flight B's offline data — discovered mid-flight, offline.
///
/// This is the single owner of asset deletion; DeleteFlightUseCase and
/// CompleteFlightUseCase both delegate here so the logic cannot drift apart
/// again.
class FlightAssetsDeleter {
  FlightAssetsDeleter({
    required Future<List<Flight>> Function() getAllFlights,
    Future<Directory> Function()? cacheDirectoryProvider,
    Future<Directory> Function()? documentsDirectoryProvider,
  }) : _getAllFlights = getAllFlights,
       _cacheDirectoryProvider =
           cacheDirectoryProvider ?? getApplicationCacheDirectory,
       _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final Future<List<Flight>> Function() _getAllFlights;
  final Future<Directory> Function() _cacheDirectoryProvider;
  final Future<Directory> Function() _documentsDirectoryProvider;
  final _logger = Logger('FlightAssetsDeleter');

  /// Deletes [flight]'s map + article files unless another flight (by id)
  /// still references the same file.
  Future<void> deleteAssets(Flight flight) async {
    final others = (await _getAllFlights())
        .where((other) => other.id != flight.id)
        .toList(growable: false);

    final referencedMapFiles = <String>{
      for (final other in others)
        for (final map in other.maps)
          if (map.filePath.isNotEmpty) map.filePath,
    };
    final referencedImagePaths = <String>{
      for (final other in others)
        for (final article in other.offlineContent.articles)
          ..._articleImagePaths(article),
    };

    await _deleteMbtilesFiles(flight.maps, referencedMapFiles);
    await _deleteArticleFiles(
      flight.offlineContent.articles,
      referencedImagePaths,
    );
  }

  Future<void> _deleteMbtilesFiles(
    List<FlightMap> maps,
    Set<String> referencedFiles,
  ) async {
    if (maps.isEmpty) return;
    final cacheDir = await _cacheDirectoryProvider();
    for (final map in maps) {
      if (map.filePath.isEmpty) continue;
      if (referencedFiles.contains(map.filePath)) {
        _logger.log(
          'Keeping shared MBTiles (still referenced by another flight): '
          '${map.filePath}',
        );
        continue;
      }
      final filePath = p.join(
        cacheDir.path,
        MapDownloadConfig.mbtilesDirectoryName,
        map.filePath,
      );
      final file = File(filePath);
      if (file.existsSync()) {
        try {
          file.deleteSync();
          _logger.log('Deleted MBTiles file: $filePath');
        } catch (e) {
          _logger.error('Failed to delete MBTiles $filePath: $e');
        }
      }
      _deleteSidecars(filePath);
    }
  }

  Future<void> _deleteArticleFiles(
    List<FlightArticle> articles,
    Set<String> referencedPaths,
  ) async {
    if (articles.isEmpty) return;
    final docsDir = await _documentsDirectoryProvider();
    final articleRootPath = p.join(docsDir.path, 'article_media');
    for (final article in articles) {
      for (final relativePath in _articleImagePaths(article)) {
        if (referencedPaths.contains(relativePath)) {
          _logger.log(
            'Keeping shared article image (still referenced): $relativePath',
          );
          continue;
        }
        final imagePath = p.join(docsDir.path, relativePath);
        final imageFile = File(imagePath);
        if (!imageFile.existsSync()) continue;
        try {
          imageFile.deleteSync();
          _logger.log('Deleted article image: $imagePath');
          _deleteEmptyArticleDirs(
            startDir: imageFile.parent,
            articleRootPath: articleRootPath,
          );
        } catch (e) {
          _logger.error('Failed to delete article image $imagePath: $e');
        }
      }
    }
  }

  static Iterable<String> _articleImagePaths(FlightArticle article) sync* {
    if (article.leadImageRelativePath.isNotEmpty) {
      yield article.leadImageRelativePath;
    }
    yield* article.inlineImageRelativePaths;
  }

  void _deleteSidecars(String mainPath) {
    for (final suffix in const ['-wal', '-shm', '-journal']) {
      final sidecar = File('$mainPath$suffix');
      if (!sidecar.existsSync()) continue;
      try {
        sidecar.deleteSync();
        _logger.log('Deleted sidecar: ${sidecar.path}');
      } catch (e) {
        _logger.error('Failed to delete sidecar ${sidecar.path}: $e');
      }
    }
  }

  void _deleteEmptyArticleDirs({
    required Directory startDir,
    required String articleRootPath,
  }) {
    var current = startDir;
    while (true) {
      final currentPath = current.path;
      if (currentPath == articleRootPath ||
          !p.isWithin(articleRootPath, currentPath)) {
        break;
      }
      if (current.listSync().isNotEmpty) break;
      try {
        current.deleteSync();
      } catch (_) {
        break;
      }
      current = current.parent;
    }
  }
}
