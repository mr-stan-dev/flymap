import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flymap/logger.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class GlyphsService {
  final _logger = Logger('GlyphsService');

  /// Copies the glyphs files to cache dir to allow native code to access it
  Future<void> copyGlyphsToCacheDir() async {
    var dir = (await getApplicationCacheDirectory()).path;

    /* Check if the files are present */

    var directory = Directory(dir);

    var glyphFilesInDirectory = directory
        .listSync(recursive: true)
        .where((file) => basename(file.path).startsWith('glyph'))
        .map((file) => basename(file.path));

    if (glyphFilesInDirectory.isNotEmpty) {
      _logger.log('Glyph files directories are already present');
      // Exits here if glyph files already exist
      return;
    }

    _logger.log('Start copying glyph files directories');

    final List<String> glyphsAssets = await _getGlyphAssets();
    final int glyphAmount = glyphsAssets.length;
    for (var i = 0; i < glyphAmount; i++) {
      final String asset = glyphsAssets[i];
      final String assetPath = dirname(asset);
      final String assetDir = join(dir, assetPath);
      final String assetFileName = basename(asset);

      // Create the directory structure if it's not present
      await Directory(assetDir).create(recursive: true);

      final ByteData data = await rootBundle.load(asset);
      final String path = join(assetDir, assetFileName);
      await _writeAssetToFile(data, path);
    }
  }

  Future<List<String>> _getGlyphAssets() {
    return rootBundle.loadString('AssetManifest.json').then<List<String>>((
      String manifestJson,
    ) {
      Map<String, dynamic> manifestMap = jsonDecode(manifestJson);
      return manifestMap.keys
          .where(
            (String key) =>
                key.contains('assets/glyphs') && !key.contains('.DS_Store'),
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
