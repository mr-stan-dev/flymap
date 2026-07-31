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

  /// Interpolate each cell from this many nearest samples. Gaussian-weighted
  /// (see [_weightSigmaPx]): by the time a neighbor drops out of the set its
  /// weight is negligible, so the field stays smooth — nearest-few IDW with
  /// heavy weights produces angular seams where the neighbor set switches.
  static const int _neighborCount = 8;

  /// Gaussian falloff radius for neighbor weights, in viewport px (~⅓ of
  /// the area-grid spacing). Was 75: on long routes that is a synoptic-scale
  /// blur — a 90%-cloud airport anchor averaged with clear ocean samples
  /// hundreds of km away rendered as near-clear (the LHR→JFK bug). 30 keeps
  /// the blend local so real structure (fronts, clear pockets) survives.
  static const double _weightSigmaPx = 30;

  /// Semi-transparent by design: even solid overcast keeps the map visible.
  static const double _maxCloudAlpha = 0.85;

  /// Noise-mask drift per frame, in viewport px — crossfading two adjacent
  /// frames then reads as cloud motion, not just density morphing.
  static const double _driftXPx = 5.0;
  static const double _driftYPx = 1.6;

  /// RGBA (premultiplied-alpha) pixel buffers, one per animation frame,
  /// spanning [start]..[end] flight time. Frame f's cloud densities come
  /// from each sample's hourly timeline at that frame's instant, so the
  /// field honestly evolves. Lazy: each iteration rasterizes one frame, so
  /// the caller can spread the work across event-loop turns.
  Iterable<Uint8List> buildFrameBuffers({
    required int frameCount,
    required DateTime start,
    required DateTime end,
  }) sync* {
    if (samples.isEmpty || frameCount < 1) return;
    final cells = fieldWidth * fieldHeight;
    final (neighborIndex, neighborWeight) = _precomputeNeighbors(cells);
    final spanSeconds = end.difference(start).inSeconds;
    final cellW = viewportWidth / fieldWidth;
    final cellH = viewportHeight / fieldHeight;

    final hiddenAt = Float32List(samples.length);
    final highAt = Float32List(samples.length);
    final rainAt = Float32List(samples.length);
    for (var f = 0; f < frameCount; f++) {
      final t = frameCount == 1
          ? start
          : start.add(Duration(seconds: spanSeconds * f ~/ (frameCount - 1)));
      for (var s = 0; s < samples.length; s++) {
        hiddenAt[s] = samples[s].hiddenAt(t) / 100;
        highAt[s] = samples[s].highAt(t) / 100;
        // Normalized rain intensity with a sqrt curve: light rain
        // (0.5-1 mm/h) is already subtly visible, 3+ mm/h reads as heavy.
        rainAt[s] = math.sqrt((samples[s].rainAt(t) / 3).clamp(0.0, 1.0));
      }

      final bytes = Uint8List(cells * 4);
      for (var cell = 0; cell < cells; cell++) {
        var hidden = 0.0;
        var high = 0.0;
        var rain = 0.0;
        final base = cell * _neighborCount;
        for (var k = 0; k < _neighborCount; k++) {
          final weight = neighborWeight[base + k];
          if (weight <= 0) continue;
          hidden += weight * hiddenAt[neighborIndex[base + k]];
          high += weight * highAt[neighborIndex[base + k]];
          rain += weight * rainAt[neighborIndex[base + k]];
        }

        // Noise sampled in viewport px (resolution-independent), drifting
        // per frame so the crossfaded animation reads as motion.
        final px = (cell % fieldWidth) * cellW + f * _driftXPx;
        final py = (cell ~/ fieldWidth) * cellH + f * _driftYPx;
        final noise = _fbm(px, py);

        // Coverage-as-threshold: the density decides how much of the noise
        // "passes" — 0 stays perfectly clear, partial cover turns patchy,
        // full cover approaches a solid (but still translucent) deck. The
        // wide transition band (0.60, was 0.35) matters: a narrow band
        // makes near-binary edges within 1-2 field cells, which the
        // device upscale turns into crawling pixel staircases.
        final edge = 1.02 - hidden * 1.2;
        final raw = ((noise - edge) / 0.60).clamp(0.0, 1.0);
        final cloud = raw * raw * (3 - 2 * raw);
        // Noise keeps modulating alpha even where the threshold saturates:
        // a full deck stays textured and drifts with the noise instead of
        // freezing into a flat slab that only creeps with the hourly data.
        var alpha = cloud * (0.62 + 0.38 * noise) * _maxCloudAlpha;
        // Thin high cirrus: a faint noise-textured veil over everything.
        final veil = (high * (0.16 + 0.14 * noise)).clamp(0.0, 0.3);
        alpha = (alpha + veil * (1 - alpha)).clamp(0.0, 0.85);
        // Rain keeps its own translucent floor: at 6-hourly horizons a
        // precip block can outpace the instant cloud fraction, and rain
        // that renders as nothing contradicts a rainy airport card.
        alpha = math.max(alpha, rain * 0.38);

        // Dense cores shade slightly gray — depth, like a real deck seen
        // from above; thin cover stays white.
        final brightness = 1.0 - 0.15 * cloud * (0.4 + 0.6 * noise);

        // Rain RECOLORS the deck instead of darkening it: an intensity
        // ramp from cool blue (drizzle) to saturated blue-violet (heavy),
        // the Windy/Ventusky precipitation convention. Hue contrast reads
        // both inside white cloud and over the dark map, where the old
        // slate darkening disappeared entirely. Noise keeps wet cores
        // textured instead of flat.
        final mix = rain * (0.65 + 0.30 * noise);
        final rainRed = 0.44 + 0.20 * rain;
        final rainGreen = 0.60 - 0.26 * rain;
        const rainBlue = 0.95;
        final red = brightness * (1 - mix) + rainRed * mix;
        final green = brightness * (1 - mix) + rainGreen * mix;
        final blue = brightness * (1 - mix) + rainBlue * mix;

        // PREMULTIPLIED: decodeImageFromPixels treats rgba8888 as premul,
        // so straight-alpha data (RGB=255) blows out to solid white.
        final byte = cell * 4;
        bytes[byte] = (alpha * red * 255).round();
        bytes[byte + 1] = (alpha * green * 255).round();
        bytes[byte + 2] = (alpha * blue * 255).round();
        bytes[byte + 3] = (alpha * 255).round();
      }
      yield bytes;
    }
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
      const sigma2 = 2 * _weightSigmaPx * _weightSigmaPx;
      for (var k = 0; k < found; k++) {
        // Tiny floor so a cell far from every sample still normalizes.
        final w = math.exp(-bestDistance[k] / sigma2) + 1e-9;
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

  /// Four octaves of value noise in viewport px (base wavelength ~176px on
  /// the card, finest ~16px), contrast-stretched to use the full 0..1
  /// range. The finest octave is what gives wispy edges — it only resolves
  /// when the field is rasterized at ~4px cells.
  double _fbm(double x, double y) {
    final n =
        0.42 * _valueNoise(x / 176, y / 176) +
        0.28 * _valueNoise(x / 80, y / 80) +
        0.18 * _valueNoise(x / 36, y / 36) +
        0.12 * _valueNoise(x / 16, y / 16);
    return ((n - 0.5) * 1.7 + 0.5).clamp(0.0, 1.0);
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
