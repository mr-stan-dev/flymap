import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flymap/data/api/mapbox_raster_tile_api.dart';
import 'package:flymap/data/flight_video/video_encoder.dart';
import 'package:flymap/data/flight_video/video_tile_store.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_video_spec.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/ui/screens/flight_video/rendering/camera_path_planner.dart';
import 'package:flymap/ui/screens/flight_video/rendering/map_frame_renderer.dart';
import 'package:flymap/ui/screens/flight_video/rendering/plane_model.dart';
import 'package:flymap/ui/screens/flight_video/rendering/region_artwork_rasterizer.dart';
import 'package:flymap/ui/screens/flight_video/rendering/region_highlight_model.dart';
import 'package:flymap/ui/screens/flight_video/rendering/route_path_model.dart';
import 'package:flymap/ui/screens/flight_video/rendering/tile_resolver.dart';
import 'package:flymap/ui/screens/flight_video/rendering/visible_tiles.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Localized strings baked into video frames.
class FlightVideoTexts {
  const FlightVideoTexts({
    required this.distance,
    required this.duration,
    required this.brand,
    this.madeWith = '',
    this.distanceUnitLabel = 'km',
    this.distanceUnitFactor = 1,
    this.languageCode,
  });

  final String distance;
  final String duration;
  final String brand;

  /// "Made with Flymap" credit line on the end card (empty to hide).
  final String madeWith;

  /// Unit label and km->unit factor for the animated distance ticker.
  final String distanceUnitLabel;
  final double distanceUnitFactor;

  /// For country-name -> flag resolution in region chips.
  final String? languageCode;
}

/// Everything needed to paint frames of one flight video. Created by
/// [GenerateFlightVideoUseCase.prepare]; drives both the live preview and
/// the export so they render identically. Call [dispose] when done.
class FlightVideoSession {
  FlightVideoSession({
    required this.flight,
    required this.spec,
    required this.route,
    required this.planner,
    required this.tileStore,
    required this.renderer,
    required this.manifest,
    required this.style,
    required RegionArtworkRasterizer artworkRasterizer,
  }) : _artworkRasterizer = artworkRasterizer;

  final Flight flight;
  final FlightVideoSpec spec;
  final RoutePathModel route;
  final CameraPathPlanner planner;
  final VideoTileStore tileStore;
  final MapFrameRenderer renderer;

  /// The tile set this video needs, computed once from [planner] + [spec].
  /// Cached so a style change reuses it instead of the (costly, synchronous)
  /// manifest rebuild.
  final Set<TileCoord> manifest;
  final FlightVideoMapStyle style;
  final RegionArtworkRasterizer _artworkRasterizer;

  int get tileCount => manifest.length;

  /// Decodes the tiles of frame time [t] and paints it onto [canvas].
  Future<void> paintFrame(ui.Canvas canvas, double t) async {
    await tileStore.ensureDecoded(renderer.tilesForFrame(t));
    renderer.paintFrame(canvas, t);
  }

  /// A twin session for a different map [style], reusing this session's
  /// renderer (already retiled), route, planner and artwork rasterizer. Only
  /// the tile store differs. The old tile store must be disposed separately;
  /// never call [dispose] on the session being restyled from (it would free
  /// the shared renderer/rasterizer).
  FlightVideoSession reStyled({
    required VideoTileStore tileStore,
    required FlightVideoMapStyle style,
  }) {
    return FlightVideoSession(
      flight: flight,
      spec: spec,
      route: route,
      planner: planner,
      tileStore: tileStore,
      renderer: renderer,
      manifest: manifest,
      style: style,
      artworkRasterizer: _artworkRasterizer,
    );
  }

  void dispose() {
    tileStore.dispose();
    renderer.dispose();
    _artworkRasterizer.dispose();
  }
}

/// Builds flight-video sessions (route + camera + prefetched tiles) and
/// exports them to an H.264 MP4 in the temp directory.
class GenerateFlightVideoUseCase {
  GenerateFlightVideoUseCase({
    required MapboxRasterTileApi tileApi,
    required FlightVideoEncoder encoder,
  }) : _tileApi = tileApi,
       _encoder = encoder;

  static const String _planeAssetPath = 'assets/images/icons/plane_teal.png';
  static const String planeModelAssetPath = 'assets/models/airplane_3d_3.glb';

  /// This asset's fuselage runs along world Z (wings along X); +90 degrees
  /// points its nose along the painter's +X convention (device-verified).
  static const double _planeModelYawOffset = pi / 2;
  static const String _brandLogoAssetPath =
      'assets/images/logo_new_with_text_white.png';
  static const int _videoBitrate = 10 * 1000 * 1000;

  final MapboxRasterTileApi _tileApi;
  final FlightVideoEncoder _encoder;
  final Logger _logger = const Logger('GenerateFlightVideoUseCase');

  /// Plans the video and prefetches all its map tiles.
  ///
  /// Returns null when the flight has no usable route or too many tiles
  /// failed to download (e.g. offline with a cold cache).
  Future<FlightVideoSession?> prepare(
    Flight flight, {
    required FlightVideoTexts texts,
    FlightVideoMapStyle style = FlightVideoMapStyle.outdoors,
    bool isPro = false,
    void Function(int done, int total)? onTileProgress,
    FlightVideoCancelToken? cancel,
  }) async {
    VideoTileStore? tileStore;
    try {
      final route = RoutePathModel.fromRoute(flight.route);
      final spec = FlightVideoSpec.forDistance(
        route.totalKm,
        // Free tier exports HD; Pro gets the full resolution.
        renderScale: isPro
            ? FlightVideoSpec.proRenderScale
            : FlightVideoSpec.freeRenderScale,
      );
      final planner = CameraPathPlanner(route: route, spec: spec);
      final manifest = buildBudgetedTileManifest(planner: planner, spec: spec);
      _logger.log(
        'Video for ${flight.routeName}: ${route.totalKm.round()} km, '
        '${spec.duration.inSeconds}s, ${manifest.length} tiles, '
        'followZoom ${planner.followZoom.toStringAsFixed(2)}',
      );

      tileStore = VideoTileStore(api: _tileApi, style: style);
      final prefetch = await tileStore.prefetch(
        manifest,
        onProgress: onTileProgress,
        cancel: cancel,
      );
      if (cancel?.isCancelled ?? false) {
        tileStore.dispose();
        return null;
      }
      if (!prefetch.isUsable) {
        _logger.error(
          'Tile prefetch unusable: ${prefetch.failed}/${prefetch.total} failed',
        );
        tileStore.dispose();
        return null;
      }

      final planeModel = await PlaneModel.loadFromAsset(planeModelAssetPath);
      final planeSprite = planeModel == null
          ? await _decodeAssetImage(_planeAssetPath)
          : null;
      final brandLogo = await _decodeAssetImage(_brandLogoAssetPath);
      final regionHighlights = RegionHighlightModel.fromRegions(
        flight.routeInsights.regions,
        totalKm: route.totalKm,
        languageCode: texts.languageCode,
        routePointAt: route.pointAt,
      );
      _logger.log(
        'Region highlights: ${regionHighlights.segments.length} segments '
        'from ${flight.routeInsights.regions.length} regions, '
        '3D plane: ${planeModel != null}, style: ${style.name}',
      );

      final endCardChips = RegionHighlightModel.endCardChips(
        flight.routeInsights.regions,
        languageCode: texts.languageCode,
      );

      // Same circular flag/type imagery the in-app chips use, rasterized
      // once per unique region for pins + chips.
      final artworkRasterizer = RegionArtworkRasterizer();
      for (final segment in regionHighlights.segments) {
        final region = segment.region;
        region.artwork = region.countryCode != null
            ? await artworkRasterizer.circularFlag(region.countryCode)
            : await artworkRasterizer.typeArtwork(region.regionType);
      }
      for (final chip in endCardChips) {
        chip.artwork = chip.countryCode != null
            ? await artworkRasterizer.circularFlag(chip.countryCode)
            : chip.regionType != null
            ? await artworkRasterizer.typeArtwork(chip.regionType!)
            : null;
      }

      final renderer = MapFrameRenderer(
        tiles: tileStore,
        route: route,
        planner: planner,
        flight: flight,
        spec: spec,
        planeSprite: planeSprite,
        planeModel: planeModel,
        planeYawOffset: _planeModelYawOffset,
        brandLogo: brandLogo,
        regionHighlights: regionHighlights,
        endCardChips: endCardChips,
        // Cyan pops on satellite imagery; a vivid red reads best on the
        // light terrain and Lè Shine styles.
        routeColor: _routeColorFor(style),
        tickerTotalKm: flight.route.metrics.effectiveDistanceKm,
        tickerUnitFactor: texts.distanceUnitFactor,
        tickerUnitLabel: texts.distanceUnitLabel,
        attributionText: style.attribution,
        statsDistanceText: texts.distance,
        statsDurationText: texts.duration,
        brandText: texts.brand,
        madeWithText: texts.madeWith,
      );

      // Warm-decode the opening frame so the preview never starts blank.
      await tileStore.ensureDecoded(renderer.tilesForFrame(0));

      return FlightVideoSession(
        flight: flight,
        spec: spec,
        route: route,
        planner: planner,
        tileStore: tileStore,
        renderer: renderer,
        manifest: manifest,
        style: style,
        artworkRasterizer: artworkRasterizer,
      );
    } catch (e, stack) {
      _logger.error('prepare failed: $e\n$stack');
      tileStore?.dispose();
      return null;
    }
  }

  /// Trail/marker color chosen per style for contrast on its imagery.
  ui.Color _routeColorFor(FlightVideoMapStyle style) =>
      style.includesSatelliteImagery
      ? const ui.Color(0xFF47EFFF)
      : const ui.Color(0xFFE53935);

  /// Switches [session] to a different map [style] cheaply: it downloads the
  /// new style's tiles and swaps them (plus the trail color/attribution) into
  /// the existing renderer, reusing the 3D plane, region artwork, brand logo
  /// and route geometry rather than rebuilding them.
  ///
  /// Returns a new session sharing the renderer; the caller keeps using the
  /// old session until this resolves, then swaps. Returns null on
  /// cancel/failure, leaving the old session untouched. Only valid when the
  /// resolution is unchanged (a Pro upgrade changes [spec] and needs a full
  /// [prepare]).
  Future<FlightVideoSession?> restyle(
    FlightVideoSession session, {
    required FlightVideoMapStyle style,
    void Function(int done, int total)? onProgress,
    FlightVideoCancelToken? cancel,
  }) async {
    // Reuse the cached manifest — planner + spec are unchanged, so rebuilding
    // it would just burn UI-thread time (it's a heavy synchronous computation).
    final manifest = session.manifest;
    final sw = Stopwatch()..start();
    _logger.log(
      'restyle: -> ${style.name}, ${manifest.length} tiles (cached manifest)',
    );
    final tileStore = VideoTileStore(api: _tileApi, style: style);
    try {
      final prefetch = await tileStore.prefetch(
        manifest,
        onProgress: onProgress,
        cancel: cancel,
      );
      if ((cancel?.isCancelled ?? false) || !prefetch.isUsable) {
        if (!prefetch.isUsable) {
          _logger.error(
            'Restyle prefetch unusable: ${prefetch.failed}/${prefetch.total}',
          );
        }
        tileStore.dispose();
        return null;
      }

      session.renderer.retile(
        tiles: tileStore,
        routeColor: _routeColorFor(style),
        attributionText: style.attribution,
      );
      // Warm-decode the opening frame into the new store before swapping.
      final decodeSw = Stopwatch()..start();
      final frame0 = session.renderer.tilesForFrame(0);
      await tileStore.ensureDecoded(frame0);
      _logger.log(
        'restyle: decoded ${frame0.length} frame-0 tiles in '
        '${decodeSw.elapsedMilliseconds}ms; total ${sw.elapsedMilliseconds}ms',
      );

      // The old style's tiles are no longer referenced by the renderer.
      session.tileStore.dispose();
      return session.reStyled(tileStore: tileStore, style: style);
    } catch (e, stack) {
      _logger.error('restyle failed: $e\n$stack');
      tileStore.dispose();
      return null;
    }
  }

  /// Renders every frame through the hardware encoder and returns the MP4
  /// path, or null on failure/cancellation.
  Future<String?> export(
    FlightVideoSession session, {
    void Function(double fraction)? onProgress,
    FlightVideoCancelToken? cancel,
  }) async {
    final spec = session.spec;
    final stopwatch = Stopwatch()..start();
    String? filePath;
    try {
      final tempDir = await getTemporaryDirectory();
      final routeCode = _safeRouteCode(session.flight.route.routeCode);
      filePath = p.join(tempDir.path, 'flymap_video_$routeCode.mp4');
      final existing = File(filePath);
      if (await existing.exists()) await existing.delete();

      final outputWidth = spec.outputWidth;
      final outputHeight = spec.outputHeight;
      final renderScale = outputWidth / spec.width;
      await _encoder.setup(
        width: outputWidth,
        height: outputHeight,
        fps: spec.fps,
        bitrate: _videoBitrate,
        filePath: filePath,
      );

      // Per-stage timing so device logs pinpoint any bottleneck. Encoding
      // and readback are pipelined (not awaited per frame), so encodeWaitMs
      // only counts real stalls on the encoder, and readbackMs absorbs
      // whatever GPU raster time the pipeline failed to hide.
      var decodeMs = 0, recordMs = 0, readbackMs = 0, encodeWaitMs = 0;
      final stageWatch = Stopwatch();

      // Native encoding overlaps rendering of the next frame; the channel
      // preserves call order. Keep at most 2 frames in flight (~17 MB).
      final pendingAppends = <Future<void>>[];
      Object? appendError;
      void trackAppend(Future<void> future) {
        pendingAppends.add(
          future.then((_) {}, onError: (Object e) => appendError ??= e),
        );
      }

      // Frames are fully opaque, so premultiplied vs straight alpha is
      // byte-identical and rawUnmodified just skips the per-pixel
      // un-premultiply pass that rawRgba runs on the CPU for every frame.
      // Android backs offscreen images with RGBA8888 (GLES and Vulkan), so
      // the raw bytes already match what the encoders expect; iOS renders
      // into BGRA Metal textures and must keep rawRgba. If exports ever
      // come out with red/blue swapped, revert Android to rawRgba.
      final readbackFormat = Platform.isAndroid
          ? ui.ImageByteFormat.rawUnmodified
          : ui.ImageByteFormat.rawRgba;

      // Batch frames into one tall offscreen: device logs showed the pixels
      // themselves are cheap (record 3 ms/frame) while the per-call GPU
      // costs -- render-target setup, readback stall, cross-thread dispatch
      // -- ate ~90 ms/frame regardless of resolution. Batching pays them
      // once per K frames. 4096 is a safe universal max texture dimension
      // (720x1280 batches 3, 900x1600 batches 2).
      final framesPerBatch = min(3, max(1, 4096 ~/ outputHeight));
      final frameBytes = outputWidth * outputHeight * 4;

      final lastFrame = spec.frameCount - 1;

      // Every frame from staticTailStart to 1.0 is pixel-identical (camera,
      // stats card, pins and pulse all settled, plane vanished): the first
      // rendered tail frame is cached and re-appended for the rest, so the
      // resting end card costs no GPU at all.
      Uint8List? staticTailBytes;

      // The GPU rasterizes batch N+1 while batch N reads back: toImage is
      // queued without awaiting and the readback chains onto its completion,
      // so the UI thread never blocks on the GPU (the eager toByteData
      // dispatch on a toImageSync texture was the previous hidden ~40
      // ms/frame "other" cost). Two batches stay in flight; deeper buys
      // nothing once the GPU is saturated. The decoded-tile LRU (capacity
      // 160) still covers every pending batch: up to 6 consecutive frames
      // share most of their <= 80 tiles.
      final pendingReads = <_PendingFrameRead>[];

      Future<void> flushOldestRead() async {
        final read = pendingReads.removeAt(0);
        stageWatch
          ..reset()
          ..start();
        final byteData = await read.bytes;
        readbackMs += stageWatch.elapsedMilliseconds;
        if (byteData == null) {
          throw StateError('Frames at ${read.frame} produced no pixels');
        }

        stageWatch
          ..reset()
          ..start();
        for (var k = 0; k < read.frameCount; k++) {
          final slice = Uint8List.sublistView(
            byteData,
            k * frameBytes,
            (k + 1) * frameBytes,
          );
          if (staticTailBytes == null &&
              (read.frame + k) / lastFrame >=
                  CameraPathPlanner.staticTailStart) {
            staticTailBytes = Uint8List.fromList(slice);
          }
          trackAppend(_encoder.appendFrame(slice));
          if (pendingAppends.length > 2) {
            await pendingAppends.removeAt(0);
          }
        }
        encodeWaitMs += stageWatch.elapsedMilliseconds;
      }

      var lastProgressTick = -1;
      try {
        var frame = 0;
        while (frame <= lastFrame) {
          if (cancel?.isCancelled ?? false) {
            await Future.wait(pendingAppends);
            await _encoder.abort();
            return null;
          }
          if (appendError != null) throw appendError!;

          // Entering the static tail: drain the pipeline (which renders and
          // captures the tail frame) and switch to append-only.
          if (frame / lastFrame >= CameraPathPlanner.staticTailStart) {
            while (pendingReads.isNotEmpty) {
              await flushOldestRead();
            }
            if (staticTailBytes != null) break;
          }

          final batchCount = min(framesPerBatch, lastFrame - frame + 1);

          stageWatch
            ..reset()
            ..start();
          final tiles = {...session.renderer.tilesForFrame(frame / lastFrame)};
          for (var k = 1; k < batchCount; k++) {
            tiles.addAll(
              session.renderer.tilesForFrame((frame + k) / lastFrame),
            );
          }
          await session.tileStore.ensureDecoded(tiles);
          decodeMs += stageWatch.elapsedMilliseconds;

          stageWatch
            ..reset()
            ..start();
          final recorder = ui.PictureRecorder();
          final canvas = ui.Canvas(
            recorder,
            ui.Rect.fromLTWH(
              0,
              0,
              outputWidth.toDouble(),
              (outputHeight * batchCount).toDouble(),
            ),
          );
          canvas.scale(renderScale);
          for (var k = 0; k < batchCount; k++) {
            canvas.save();
            canvas.translate(0, (k * spec.height).toDouble());
            canvas.clipRect(
              ui.Rect.fromLTWH(
                0,
                0,
                spec.width.toDouble(),
                spec.height.toDouble(),
              ),
            );
            session.renderer.paintFrame(canvas, (frame + k) / lastFrame);
            canvas.restore();
          }
          final picture = recorder.endRecording();
          final bytes = picture
              .toImage(outputWidth, outputHeight * batchCount)
              .then((image) async {
                try {
                  return await image.toByteData(format: readbackFormat);
                } finally {
                  image.dispose();
                }
              })
              .whenComplete(picture.dispose);
          recordMs += stageWatch.elapsedMilliseconds;

          pendingReads.add(
            _PendingFrameRead(
              frame: frame,
              frameCount: batchCount,
              bytes: bytes,
            ),
          );
          if (pendingReads.length >= 2) await flushOldestRead();

          frame += batchCount;

          // Cap progress at ~100 emits; every emit rebuilds the progress UI,
          // which competes with the export for the UI thread.
          final tick = (frame - 1) * 100 ~/ lastFrame;
          if (tick != lastProgressTick) {
            lastProgressTick = tick;
            onProgress?.call((frame - 1) / lastFrame);
          }
        }
        while (pendingReads.isNotEmpty) {
          await flushOldestRead();
        }

        // Append-only static tail: the end card at rest, zero GPU work.
        final tailBytes = staticTailBytes;
        stageWatch
          ..reset()
          ..start();
        while (frame <= lastFrame && tailBytes != null) {
          if (cancel?.isCancelled ?? false) {
            await Future.wait(pendingAppends);
            await _encoder.abort();
            return null;
          }
          if (appendError != null) throw appendError!;
          trackAppend(_encoder.appendFrame(tailBytes));
          if (pendingAppends.length > 2) {
            await pendingAppends.removeAt(0);
          }
          frame++;
        }
        encodeWaitMs += stageWatch.elapsedMilliseconds;
        onProgress?.call(1);
      } finally {
        for (final read in pendingReads) {
          read.bytes.ignore();
        }
      }

      await Future.wait(pendingAppends);
      if (appendError != null) throw appendError!;
      await _encoder.finish();
      final frames = spec.frameCount;
      // "other" is wall time none of the stage watches saw: encoder
      // setup/finish, progress emits, GC, event-loop scheduling.
      final otherMs =
          stopwatch.elapsedMilliseconds -
          decodeMs -
          recordMs -
          readbackMs -
          encodeWaitMs;
      _logger.log(
        'Exported $frames frames (${outputWidth}x$outputHeight) in '
        '${stopwatch.elapsedMilliseconds} ms '
        '(avg/frame: decode ${decodeMs ~/ frames} ms, '
        'record ${recordMs ~/ frames} ms, '
        'readback ${readbackMs ~/ frames} ms, '
        'encodeWait ${encodeWaitMs ~/ frames} ms, '
        'other ${otherMs ~/ frames} ms) -> $filePath',
      );
      return filePath;
    } catch (e, stack) {
      _logger.error('export failed: $e\n$stack');
      await _encoder.abort();
      return null;
    }
  }

  String _safeRouteCode(String routeCode) {
    final sanitized = routeCode.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return sanitized.isEmpty ? 'route' : sanitized;
  }

  Future<ui.Image?> _decodeAssetImage(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
      );
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      _logger.error('Failed to load plane sprite: $e');
      return null;
    }
  }
}

/// A batch of frames stacked into one offscreen image whose GPU
/// rasterization and pixel readback are still in flight. The readback chain
/// owns and disposes the picture and image.
class _PendingFrameRead {
  _PendingFrameRead({
    required this.frame,
    required this.frameCount,
    required this.bytes,
  });

  /// Index of the first frame in the batch.
  final int frame;
  final int frameCount;
  final Future<ByteData?> bytes;
}
