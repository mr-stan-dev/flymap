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

    test('landing maneuver: final segment aims into the airport dot center',
        () {
      // Straight cruise, then a hook just short of the arrival dot — the kind
      // of turn that used to make the line graze the dot from the side.
      final points = [
        const Offset(0, 0),
        const Offset(100, 0),
        const Offset(200, 0),
        const Offset(280, 25),
        const Offset(292, 15),
        const Offset(296, 8),
        const Offset(300, 0),
      ];

      final path = ShareImagePainter.buildRoutePath(
        points,
        routeKm: 1850,
        endpointClearance: 24,
      );

      final metric = path.computeMetrics().single;
      final tangent = metric.getTangentForOffset(metric.length)!;
      expect(tangent.position, const Offset(300, 0));
      // The hook points inside the 24px clearance are dropped, so the path
      // finishes on the straight (280,25) -> (300,0) heading — into the dot
      // center, not sideways past it.
      final direction = tangent.vector / tangent.vector.distance;
      final expected = const Offset(20, -25) / const Offset(20, -25).distance;
      expect(direction.dx, closeTo(expected.dx, 0.01));
      expect(direction.dy, closeTo(expected.dy, 0.01));
    });
  });
}
