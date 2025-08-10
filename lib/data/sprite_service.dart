import 'dart:convert';
import 'dart:io';

import 'package:flymap/logger.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class SpriteService {
  final _logger = Logger('SpriteService');

  /// Copies the sprite files to cache dir to allow native code to access it
  Future<void> copySpritesToCacheDir() async {
    var dir = (await getApplicationCacheDirectory()).path;

    /* Check if the files are present */
    var directory = Directory(dir);
    var spriteFilesInDirectory = directory
        .listSync(recursive: true)
        .where((file) => basename(file.path).startsWith('sprite'))
        .map((file) => basename(file.path));

    if (spriteFilesInDirectory.isNotEmpty) {
      _logger.log('Sprite files are already present');
      // Exits here if sprite files already exist
      return;
    }

    _logger.log('Start copying sprite files');

    final List<String> spriteAssets = await _getSpriteAssets();
    final int spriteAmount = spriteAssets.length;
    for (var i = 0; i < spriteAmount; i++) {
      final String asset = spriteAssets[i];
      final String assetPath = dirname(asset);
      final String assetDir = join(dir, assetPath);
      final String assetFileName = basename(asset);

      // Create the directory structure if it's not present
      await Directory(assetDir).create(recursive: true);

      final ByteData data = await rootBundle.load(asset);
      final String path = join(assetDir, assetFileName);
      await _writeAssetToFile(data, path);
      _logger.log('[${i + 1}/$spriteAmount] "$asset" copied to "$path".');
    }
  }

  Future<List<String>> _getSpriteAssets() {
    return rootBundle.loadString('AssetManifest.json').then<List<String>>((
      String manifestJson,
    ) {
      Map<String, dynamic> manifestMap = jsonDecode(manifestJson);
      return manifestMap.keys
          .where(
            (String key) =>
                key.contains('assets/sprites') && !key.contains('.DS_Store'),
          )
          .toList();
    });
  }

  Future<void> _writeAssetToFile(ByteData data, String path) {
    final buffer = data.buffer;
    return File(
      path,
    ).writeAsBytes(buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }
}
