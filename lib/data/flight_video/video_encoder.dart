import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_quick_video_encoder/flutter_quick_video_encoder.dart';
import 'package:flymap/logger.dart';

/// Hardware H.264 encoder fed with raw RGBA frames.
///
/// Interface exists so the plugin can be swapped for a custom platform
/// channel (mirroring `app.flymap/native_capture`) without touching the
/// export pipeline.
abstract class FlightVideoEncoder {
  Future<void> setup({
    required int width,
    required int height,
    required int fps,
    required int bitrate,
    required String filePath,
  });

  Future<void> appendFrame(Uint8List rawRgba);

  Future<void> finish();

  /// Best-effort teardown after a failure or cancellation; deletes the
  /// partial output file.
  Future<void> abort();
}

/// [FlightVideoEncoder] backed by the app's own platform channel
/// (`FlightVideoEncoderDelegate` in Runner/MainActivity).
///
/// Android feeds MediaCodec through a hardware input Surface so RGBA->YUV
/// conversion runs on the GPU; iOS uses AVAssetWriter with a vImage BGRA
/// permute. Roughly 5-10x faster per frame than the plugin's per-pixel CPU
/// conversion.
class NativeFlightVideoEncoder implements FlightVideoEncoder {
  static const MethodChannel _channel = MethodChannel(
    'app.flymap/video_encoder',
  );

  final Logger _logger = const Logger('NativeFlightVideoEncoder');
  String? _filePath;

  @override
  Future<void> setup({
    required int width,
    required int height,
    required int fps,
    required int bitrate,
    required String filePath,
  }) async {
    _filePath = filePath;
    await _channel.invokeMethod<void>('setup', <String, Object>{
      'width': width,
      'height': height,
      'fps': fps,
      'bitrate': bitrate,
      'path': filePath,
    });
  }

  @override
  Future<void> appendFrame(Uint8List rawRgba) =>
      _channel.invokeMethod<void>('appendFrame', rawRgba);

  @override
  Future<void> finish() => _channel.invokeMethod<void>('finish');

  @override
  Future<void> abort() async {
    try {
      await _channel.invokeMethod<void>('abort');
    } catch (e) {
      _logger.error('Encoder abort failed: $e');
    }
    final path = _filePath;
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      _logger.error('Failed to delete partial video: $e');
    }
  }
}

/// Uses [primary] but falls back to [secondary] when the primary's setup
/// fails (e.g. an OEM MediaCodec quirk in the native channel).
class FallbackFlightVideoEncoder implements FlightVideoEncoder {
  FallbackFlightVideoEncoder({
    required FlightVideoEncoder primary,
    required FlightVideoEncoder secondary,
  }) : _primary = primary,
       _secondary = secondary;

  final FlightVideoEncoder _primary;
  final FlightVideoEncoder _secondary;
  final Logger _logger = const Logger('FallbackFlightVideoEncoder');
  late FlightVideoEncoder _active = _primary;

  @override
  Future<void> setup({
    required int width,
    required int height,
    required int fps,
    required int bitrate,
    required String filePath,
  }) async {
    try {
      _active = _primary;
      await _primary.setup(
        width: width,
        height: height,
        fps: fps,
        bitrate: bitrate,
        filePath: filePath,
      );
    } catch (e) {
      _logger.error('Primary encoder setup failed, falling back: $e');
      _active = _secondary;
      await _secondary.setup(
        width: width,
        height: height,
        fps: fps,
        bitrate: bitrate,
        filePath: filePath,
      );
    }
  }

  @override
  Future<void> appendFrame(Uint8List rawRgba) => _active.appendFrame(rawRgba);

  @override
  Future<void> finish() => _active.finish();

  @override
  Future<void> abort() => _active.abort();
}

/// [FlightVideoEncoder] backed by flutter_quick_video_encoder
/// (AVAssetWriter on iOS, MediaCodec on Android).
class QuickVideoEncoderAdapter implements FlightVideoEncoder {
  final Logger _logger = const Logger('QuickVideoEncoderAdapter');
  String? _filePath;

  @override
  Future<void> setup({
    required int width,
    required int height,
    required int fps,
    required int bitrate,
    required String filePath,
  }) async {
    _filePath = filePath;
    // Default log level prints a line per frame; keep errors only.
    await FlutterQuickVideoEncoder.setLogLevel(LogLevel.error);
    await FlutterQuickVideoEncoder.setup(
      width: width,
      height: height,
      fps: fps,
      videoBitrate: bitrate,
      profileLevel: ProfileLevel.highAutoLevel,
      audioChannels: 0,
      audioBitrate: 0,
      sampleRate: 0,
      filepath: filePath,
    );
  }

  @override
  Future<void> appendFrame(Uint8List rawRgba) =>
      FlutterQuickVideoEncoder.appendVideoFrame(rawRgba);

  @override
  Future<void> finish() => FlutterQuickVideoEncoder.finish();

  @override
  Future<void> abort() async {
    try {
      await FlutterQuickVideoEncoder.finish();
    } catch (e) {
      _logger.error('Encoder abort finish failed: $e');
    }
    final path = _filePath;
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      _logger.error('Failed to delete partial video: $e');
    }
  }
}
