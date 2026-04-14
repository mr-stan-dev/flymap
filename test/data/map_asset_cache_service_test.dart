import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/map_asset_cache_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDirectory;
  late List<String> copiedAssets;
  late MapAssetCacheService service;

  const glyphAsset = 'assets/glyphs/Noto Sans Regular/0-255.pbf';
  const spriteAsset = 'assets/sprites/sprite.png';
  const assets = <String>[glyphAsset, spriteAsset];

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'map_asset_cache_service_test_',
    );
    copiedAssets = <String>[];
    service = MapAssetCacheService(
      cacheDirectoryProvider: () async => tempDirectory,
      assetPathsLoader: () async => assets,
      assetDataLoader: (assetPath) async {
        copiedAssets.add(assetPath);
        final bytes = Uint8List.fromList(assetPath.codeUnits);
        return ByteData.sublistView(bytes);
      },
    );
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('copies required map assets and writes readiness marker', () async {
    await service.ensureReady();

    expect(copiedAssets, assets);
    for (final asset in assets) {
      expect(File(p.join(tempDirectory.path, asset)).existsSync(), isTrue);
    }
    expect(
      File(
        p.join(tempDirectory.path, 'assets/.map_asset_cache_ready'),
      ).readAsStringSync(),
      MapAssetCacheService.cacheVersion.toString(),
    );
  });

  test('skips recopy when marker and files are valid', () async {
    await service.ensureReady();
    copiedAssets.clear();

    await service.ensureReady();

    expect(copiedAssets, isEmpty);
  });

  test('recopies when a required asset is missing despite marker', () async {
    await service.ensureReady();
    copiedAssets.clear();
    await File(p.join(tempDirectory.path, spriteAsset)).delete();

    await service.ensureReady();

    expect(copiedAssets, assets);
  });
}
