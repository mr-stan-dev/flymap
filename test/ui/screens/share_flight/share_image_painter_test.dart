import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/ui/screens/share_flight/widgets/map/share_image_painter.dart';

void main() {
  group('ShareImagePainter.buildRoutePath', () {
    test('real geometry: follows the track and keeps exact endpoints', () {
      final points = [
        const Offset(0, 0),
        const Offset(40, 30),
        const Offset(90, 20),
        const Offset(140, 60),
      ];

      final path = ShareImagePainter.buildRoutePath(points, routeKm: 1850);

      final metric = path.computeMetrics().single;
      final start = metric.getTangentForOffset(0)!.position;
      final end = metric.getTangentForOffset(metric.length)!.position;
      expect(start, const Offset(0, 0));
      expect(end, const Offset(140, 60));
      // A track path hugs the real points; the stylized arc between the same
      // endpoints would be much shorter than the track's total length.
      expect(metric.length, greaterThan(150));
    });

    test('endpoint-only route: falls back to the stylized arc', () {
      final track = ShareImagePainter.buildRoutePath(
        [const Offset(0, 0), const Offset(140, 60)],
        routeKm: 1850,
      );
      final arc = ShareImagePainter.buildArcPath(
        const Offset(0, 0),
        const Offset(140, 60),
        routeKm: 1850,
      );

      expect(
        track.computeMetrics().single.length,
        arc.computeMetrics().single.length,
      );
    });

    test('dense points are simplified but endpoints survive', () {
      final dense = [
        for (var i = 0; i <= 100; i++) Offset(i.toDouble(), i.isEven ? 0 : 2),
      ];

      final path = ShareImagePainter.buildRoutePath(
        dense,
        routeKm: 500,
        minPointSpacing: 8,
      );

      final metric = path.computeMetrics().single;
      expect(metric.getTangentForOffset(0)!.position, const Offset(0, 0));
      expect(
        metric.getTangentForOffset(metric.length)!.position,
        const Offset(100, 0),
      );
      // Zigzag noise between samples is dropped, so the smoothed path stays
      // close to the 100px straight-line distance instead of tracing ~200px
      // of jitter.
      expect(metric.length, lessThan(115));
    });
  });
}
