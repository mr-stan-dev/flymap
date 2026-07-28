import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'package:flymap/domain/entity/flight_weather.dart';

/// Rasterizes the sparse forecast samples into small continuous cloud-field
/// frames — the Windy approach: the DATA stays coarse (one forecast per
/// sample point), but every PIXEL gets a value by interpolating between the
/// surrounding samples, and a fractal noise mask breaks the smooth field
/// into cloud-like shapes. The result is a low-res RGBA buffer per animation
/// frame; drawn upscaled with bilinear filtering it reads as a weather
/// layer, not a grid of blobs.
class CloudFieldBuilder {
  CloudFieldBuilder({
    required this.samples,
    required this.positions,
    required this.viewportWidth,
    required this.viewportHeight,
    this.fieldWidth = 68,
    this.fieldHeight = 100,
  }) : assert(samples.length == positions.length);

  final List<RouteCloudSample> samples;

  /// Projected sample centers in viewport coordinates (same space as
  /// [viewportWidth] x [viewportHeight]).
  final List<Offset> positions;
  final double viewportWidth;
  final double viewportHeight;

  /// Field resolution: ~8 viewport px per cell at the 540x800 card.
  final int fieldWidth;
  final int fieldHeight;

  /// Interpolate each cell from this many nearest samples (Shepard/IDW).
  static const int _neighborCount = 4;

  /// Semi-transparent by design: even solid overcast keeps the map visible.
  static const double _maxCloudAlpha = 0.8;

  /// RGBA (premultiplied-alpha) pixel buffers, one per animation frame, spanning
  /// [start]..[end] flight time. Frame f's cloud densities come from each
  /// sample's hourly timeline at that frame's instant, so the field honestly
  /// evolves; the noise mask drifts slightly per frame so the crossfaded
  /// animation reads as cloud motion.
  List<Uint8List> buildFrameBuffers({
    required int frameCount,
    required DateTime start,
    required DateTime end,
  }) {
    if (samples.isEmpty || frameCount < 1) return const [];
    final cells = fieldWidth * fieldHeight;
    final (neighborIndex, neighborWeight) = _precomputeNeighbors(cells);
    final spanSeconds = end.difference(start).inSeconds;

    final frames = <Uint8List>[];
    final hiddenAt = Float32List(samples.length);
    final highAt = Float32List(samples.length);
    for (var f = 0; f < frameCount; f++) {
      final t = frameCount == 1
          ? start
          : start.add(
              Duration(seconds: spanSeconds * f ~/ (frameCount - 1)),
            );
      for (var s = 0; s < samples.length; s++) {
        hiddenAt[s] = samples[s].hiddenAt(t) / 100;
        highAt[s] = samples[s].highAt(t) / 100;
      }

      final bytes = Uint8List(cells * 4);
      for (var cell = 0; cell < cells; cell++) {
        var hidden = 0.0;
        var high = 0.0;
        final base = cell * _neighborCount;
        for (var k = 0; k < _neighborCount; k++) {
          final weight = neighborWeight[base + k];
          if (weight <= 0) continue;
          hidden += weight * hiddenAt[neighborIndex[base + k]];
          high += weight * highAt[neighborIndex[base + k]];
        }

        final cx = cell % fieldWidth;
        final cy = cell ~/ fieldWidth;
        // Per-frame offset drifts the noise so crossfades read as motion.
        final noise = _fbm(cx + f * 1.3, cy + f * 0.5);

        // Coverage-as-threshold: the density decides how much of the noise
        // "passes" — 0 stays perfectly clear, partial cover turns patchy,
        // full cover approaches a solid (but still translucent) deck.
        final edge = 1.02 - hidden * 1.3;
        final raw = ((noise - edge) / 0.32).clamp(0.0, 1.0);
        final cloud = raw * raw * (3 - 2 * raw);
        var alpha = cloud * _maxCloudAlpha;
        // Thin high cirrus: a faint noise-textured veil over everything.
        final veil = (high * (0.16 + 0.14 * noise)).clamp(0.0, 0.3);
        alpha = (alpha + veil * (1 - alpha)).clamp(0.0, 0.85);

        // PREMULTIPLIED white: decodeImageFromPixels treats rgba8888 as
        // premul, so straight-alpha data (RGB=255) blows out to solid white.
        final byte = cell * 4;
        final value = (alpha * 255).round();
        bytes[byte] = value;
        bytes[byte + 1] = value;
        bytes[byte + 2] = value;
        bytes[byte + 3] = value;
      }
      frames.add(bytes);
    }
    return frames;
  }

  /// For each field cell: the [_neighborCount] nearest samples and their
  /// normalized inverse-distance weights. Computed once; every frame is then
  /// just dot products.
  (Int32List, Float32List) _precomputeNeighbors(int cells) {
    final index = Int32List(cells * _neighborCount);
    final weight = Float32List(cells * _neighborCount);
    final cellW = viewportWidth / fieldWidth;
    final cellH = viewportHeight / fieldHeight;

    final bestDistance = Float64List(_neighborCount);
    final bestIndex = Int32List(_neighborCount);
    for (var cell = 0; cell < cells; cell++) {
      final px = ((cell % fieldWidth) + 0.5) * cellW;
      final py = ((cell ~/ fieldWidth) + 0.5) * cellH;

      var found = 0;
      for (var s = 0; s < positions.length; s++) {
        final dx = positions[s].dx - px;
        final dy = positions[s].dy - py;
        final d2 = dx * dx + dy * dy;
        if (found < _neighborCount) {
          bestDistance[found] = d2;
          bestIndex[found] = s;
          found++;
        } else {
          var worst = 0;
          for (var k = 1; k < _neighborCount; k++) {
            if (bestDistance[k] > bestDistance[worst]) worst = k;
          }
          if (d2 < bestDistance[worst]) {
            bestDistance[worst] = d2;
            bestIndex[worst] = s;
          }
        }
      }

      var totalWeight = 0.0;
      final base = cell * _neighborCount;
      for (var k = 0; k < found; k++) {
        // +900 (~30px) softening keeps on-top samples from spiking.
        final w = 1.0 / (bestDistance[k] + 900);
        index[base + k] = bestIndex[k];
        weight[base + k] = w;
        totalWeight += w;
      }
      if (totalWeight > 0) {
        for (var k = 0; k < found; k++) {
          weight[base + k] /= totalWeight;
        }
      }
    }
    return (index, weight);
  }

  /// Three octaves of value noise in cell units (base wavelength ~22 cells,
  /// ~170px on the card), contrast-stretched to use the full 0..1 range.
  double _fbm(double x, double y) {
    final n = 0.55 * _valueNoise(x / 22, y / 22) +
        0.30 * _valueNoise(x / 10, y / 10) +
        0.15 * _valueNoise(x / 4.5, y / 4.5);
    return ((n - 0.5) * 1.6 + 0.5).clamp(0.0, 1.0);
  }

  double _valueNoise(double x, double y) {
    final x0 = x.floorToDouble();
    final y0 = y.floorToDouble();
    final fx = x - x0;
    final fy = y - y0;
    final u = fx * fx * (3 - 2 * fx);
    final v = fy * fy * (3 - 2 * fy);
    final a = _hash(x0, y0);
    final b = _hash(x0 + 1, y0);
    final c = _hash(x0, y0 + 1);
    final d = _hash(x0 + 1, y0 + 1);
    return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v;
  }

  /// Deterministic pseudo-random 0..1 (no Random — frames must be stable).
  double _hash(double x, double y) {
    final n = math.sin(x * 127.1 + y * 311.7) * 43758.5453123;
    return n - n.floorToDouble();
  }
}
