import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/flight_video_spec.dart';
import 'package:flymap/ui/screens/flight_video/rendering/camera_path_planner.dart';
import 'package:flymap/ui/screens/flight_video/rendering/route_path_model.dart';
import 'package:flymap/ui/screens/flight_video/rendering/visible_tiles.dart';
import 'package:flymap/ui/screens/flight_video/rendering/world_transform.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const lhr = LatLng(51.4700, -0.4543);
  const jfk = LatLng(40.6413, -73.7781);
  const lax = LatLng(33.9416, -118.4085);
  const syd = LatLng(-33.9399, 151.1753);
  const ams = LatLng(52.3105, 4.7683);
  const cdg = LatLng(49.0097, 2.5479);

  RoutePathModel routeOf(LatLng a, LatLng b) =>
      RoutePathModel.fromPoints([a, b]);

  group('FlightVideoSpec', () {
    test('duration scales with distance and stays in range', () {
      final short = FlightVideoSpec.forDistance(300);
      final medium = FlightVideoSpec.forDistance(3000);
      final long = FlightVideoSpec.forDistance(12000);

      expect(short.duration.inSeconds, inInclusiveRange(16, 18));
      expect(medium.duration.inSeconds, inInclusiveRange(23, 26));
      expect(long.duration.inSeconds, inInclusiveRange(28, 33));
      expect(FlightVideoSpec.forDistance(1).duration.inSeconds, 16);
      expect(
        FlightVideoSpec.forDistance(double.nan).duration.inSeconds,
        greaterThanOrEqualTo(16),
      );
    });

    test('output resolution is scaled, even, and aspect-preserving', () {
      final pro = FlightVideoSpec.forDistance(1000);
      expect(pro.outputWidth, 900);
      expect(pro.outputHeight, 1600);

      final free = FlightVideoSpec.forDistance(
        1000,
        renderScale: FlightVideoSpec.freeRenderScale,
      );
      expect(free.outputWidth, 720);
      expect(free.outputHeight, 1280);

      for (final spec in [pro, free]) {
        expect(spec.outputWidth % 2, 0);
        expect(spec.outputHeight % 2, 0);
        expect(
          spec.outputWidth / spec.outputHeight,
          closeTo(spec.width / spec.height, 0.01),
        );
      }
    });
  });

  group('RoutePathModel', () {
    test('great-circle distance for LHR-JFK is realistic', () {
      final route = routeOf(lhr, jfk);
      expect(route.totalKm, inInclusiveRange(5500, 5600));
      expect(route.pointAt(0).latitude, closeTo(lhr.latitude, 0.01));
      expect(route.pointAt(1).latitude, closeTo(jfk.latitude, 0.01));
    });

    test('great-circle path arcs north of the rhumb line', () {
      final route = routeOf(lhr, jfk);
      // The LHR-JFK great circle passes well north of both endpoints.
      expect(route.pointAt(0.5).latitude, greaterThan(52));
    });

    test('antimeridian route unwraps longitudes continuously', () {
      final route = routeOf(lax, syd);
      var previous = route.pointAt(0);
      for (var i = 1; i <= 100; i++) {
        final p = route.pointAt(i / 100);
        expect(
          (p.longitude - previous.longitude).abs(),
          lessThan(10),
          reason: 'longitude jump at sample $i',
        );
        previous = p;
      }
    });

    test('arc-length parameterization is even', () {
      final route = routeOf(lhr, jfk);
      final quarter = RoutePathModel.haversineKm(
        route.pointAt(0),
        route.pointAt(0.25),
      );
      final half = RoutePathModel.haversineKm(
        route.pointAt(0.25),
        route.pointAt(0.5),
      );
      expect(quarter / half, closeTo(1, 0.05));
    });

    test('sharp jinks in real tracks are smoothed, endpoints pinned', () {
      // A track with a hard 90-degree dogleg mid-route (like an approach
      // turn on an FR24 track: >= 32 points, so no great-circle densify).
      final zigzag = <LatLng>[
        for (var i = 0; i <= 20; i++) LatLng(50.0, 0.0 + i * 0.1),
        for (var i = 1; i <= 20; i++) LatLng(50.0 + i * 0.1, 2.0),
      ];
      final route = RoutePathModel.fromPoints(zigzag);

      // Endpoints stay exactly at the airports.
      expect(route.pointAt(0).latitude, closeTo(50.0, 1e-6));
      expect(route.pointAt(0).longitude, closeTo(0.0, 1e-6));
      expect(route.pointAt(1).latitude, closeTo(52.0, 1e-6));
      expect(route.pointAt(1).longitude, closeTo(2.0, 1e-6));

      // The 90-degree corner is spread out: no near-instant bearing jump
      // between adjacent samples anywhere on the path.
      var maxDelta = 0.0;
      var previous = route.bearingDegAt(0);
      for (var i = 1; i <= 200; i++) {
        final bearing = route.bearingDegAt(i / 200);
        var delta = (bearing - previous) % 360;
        if (delta > 180) delta -= 360;
        if (delta < -180) delta += 360;
        maxDelta = max(maxDelta, delta.abs());
        previous = bearing;
      }
      expect(maxDelta, lessThan(15), reason: 'corner still too sharp');
    });

    test('degenerate route (same endpoints) stays finite', () {
      final route = routeOf(ams, ams);
      expect(route.totalKm, greaterThan(0));
      expect(route.pointAt(0.5).latitude.isFinite, isTrue);
      expect(route.bearingDegAt(0.5).isFinite, isTrue);
    });
  });

  group('WorldTransform', () {
    const viewport = Size(1080, 1920);

    test('top-down pose puts camera target at the anchor', () {
      final wt = WorldTransform.fromPose(
        pose: const CameraPose(
          center: ams,
          zoom: 6,
          pitchDeg: 0,
          bearingDeg: 0,
        ),
        viewport: viewport,
      );
      final screen = wt.projectLatLng(ams);
      expect(screen.dx, closeTo(wt.anchor.dx, 0.01));
      expect(screen.dy, closeTo(wt.anchor.dy, 0.01));
    });

    test('top-down projection matches plain mercator offsets', () {
      final wt = WorldTransform.fromPose(
        pose: const CameraPose(
          center: ams,
          zoom: 6,
          pitchDeg: 0,
          bearingDeg: 0,
        ),
        viewport: viewport,
      );
      // A point 0.1 mercator-normalized east of center at zoom 6:
      // 0.1 * 512 * 64 px east on screen.
      final east = LatLng(ams.latitude, ams.longitude + 36);
      final screen = wt.projectLatLng(east);
      final expectedDx = 0.1 * 512 * 64;
      expect(screen.dx - wt.anchor.dx, closeTo(expectedDx, 0.5));
      expect(screen.dy - wt.anchor.dy, closeTo(0, 0.5));
    });

    test('project/unproject round-trips below the horizon', () {
      final wt = WorldTransform.fromPose(
        pose: const CameraPose(
          center: ams,
          zoom: 7,
          pitchDeg: 55,
          bearingDeg: 137,
        ),
        viewport: viewport,
      );
      for (final screen in const [
        Offset(100, 900),
        Offset(540, 1200),
        Offset(1000, 1900),
        Offset(540, 700),
      ]) {
        final world = wt.unprojectScreen(screen);
        expect(world, isNotNull, reason: 'unproject failed for $screen');
        final back = wt.projectWorld(world!);
        expect(back.dx, closeTo(screen.dx, 0.5));
        expect(back.dy, closeTo(screen.dy, 0.5));
      }
    });

    test('pitch produces a horizon with sky above it', () {
      final wt = WorldTransform.fromPose(
        pose: const CameraPose(
          center: ams,
          zoom: 7,
          pitchDeg: 55,
          bearingDeg: 0,
        ),
        viewport: viewport,
      );
      expect(wt.horizonY.isFinite, isTrue);
      expect(wt.horizonY, lessThan(viewport.height * 0.5));
      expect(wt.mapClipTop, greaterThanOrEqualTo(0));
      expect(wt.mapClipTop, greaterThan(wt.horizonY));

      // Points ahead (up-screen) recede: a point further north projects
      // closer to the horizon and never below the anchor.
      final near = wt.projectWorld(const Offset(0, -500));
      final far = wt.projectWorld(const Offset(0, -3000));
      expect(far.dy, lessThan(near.dy));
      expect(far.dy, greaterThan(wt.horizonY));
    });

    test('top-down pose has no horizon and no sky clip', () {
      final wt = WorldTransform.fromPose(
        pose: const CameraPose(
          center: ams,
          zoom: 5,
          pitchDeg: 0,
          bearingDeg: 0,
        ),
        viewport: viewport,
      );
      expect(wt.horizonY, double.negativeInfinity);
      expect(wt.mapClipTop, 0);
    });

    test('bearing rotates course direction to screen-up', () {
      const bearing = 60.0;
      final wt = WorldTransform.fromPose(
        pose: const CameraPose(
          center: ams,
          zoom: 7,
          pitchDeg: 0,
          bearingDeg: bearing,
        ),
        viewport: viewport,
      );
      // World direction of travel for bearing 60: (sin60, -cos60) * step.
      final ahead = Offset(sin(bearing * pi / 180), -cos(bearing * pi / 180));
      final screen = wt.projectWorld(ahead * 100);
      expect(screen.dx - wt.anchor.dx, closeTo(0, 0.01));
      expect(screen.dy - wt.anchor.dy, closeTo(-100, 0.01));
    });
  });

  group('CameraPathPlanner', () {
    CameraPathPlanner plannerFor(LatLng a, LatLng b) {
      final route = routeOf(a, b);
      return CameraPathPlanner(
        route: route,
        spec: FlightVideoSpec.forDistance(route.totalKm),
      );
    }

    test('follow zoom is above overview zoom and within bounds', () {
      for (final pair in [
        [lhr, jfk],
        [lax, syd],
        [ams, cdg],
      ]) {
        final planner = plannerFor(pair[0], pair[1]);
        expect(
          planner.followZoom,
          greaterThanOrEqualTo(planner.overviewZoom + 0.5),
        );
        expect(planner.followZoom, lessThanOrEqualTo(10.0));
      }
    });

    test('everything is settled in the static tail', () {
      // The exporter renders one frame at staticTailStart and reuses its
      // pixels until t=1, so every pose/animation input must be constant.
      final planner = plannerFor(lhr, jfk);
      final settled = planner.poseAt(CameraPathPlanner.staticTailStart);
      for (final t in [0.95, 0.97, 0.99, 1.0]) {
        final pose = planner.poseAt(t);
        expect(pose.zoom, closeTo(settled.zoom, 1e-9), reason: 'zoom at $t');
        expect(
          pose.pitchDeg,
          closeTo(settled.pitchDeg, 1e-9),
          reason: 'pitch at $t',
        );
        expect(
          pose.center.latitude,
          closeTo(settled.center.latitude, 1e-12),
          reason: 'center lat at $t',
        );
        expect(
          pose.center.longitude,
          closeTo(settled.center.longitude, 1e-12),
          reason: 'center lng at $t',
        );
        expect(planner.statsOverlayOpacityAt(t), 1, reason: 'stats at $t');
        expect(planner.planeProgressAt(t), 1, reason: 'plane at $t');
        expect(planner.arrMarkerScaleAt(t), 1, reason: 'marker at $t');
      }
    });

    test('pose timeline is continuous (no pops)', () {
      final planner = plannerFor(lhr, jfk);
      const steps = 600;
      var previous = planner.poseAt(0);
      for (var i = 1; i <= steps; i++) {
        final pose = planner.poseAt(i / steps);
        expect(
          (pose.zoom - previous.zoom).abs(),
          // The eased dive legitimately reaches ~0.17/step; a keyframe bug
          // would jump by whole zoom levels.
          lessThan(0.35),
          reason: 'zoom jump at step $i',
        );
        expect(
          (pose.pitchDeg - previous.pitchDeg).abs(),
          lessThan(3.0),
          reason: 'pitch jump at step $i',
        );
        var bearingDelta = (pose.bearingDeg - previous.bearingDeg) % 360;
        if (bearingDelta > 180) bearingDelta -= 360;
        if (bearingDelta < -180) bearingDelta += 360;
        // The eased outro realignment legitimately reaches ~4 deg/step; a
        // seam bug would jump tens of degrees at once.
        expect(
          bearingDelta.abs(),
          lessThan(8.0),
          reason: 'bearing jump at step $i',
        );
        final worldStep =
            (WorldTransform.mercXNorm(pose.center.longitude) -
                WorldTransform.mercXNorm(previous.center.longitude))
                .abs() +
            (WorldTransform.mercYNorm(pose.center.latitude) -
                WorldTransform.mercYNorm(previous.center.latitude))
                .abs();
        expect(worldStep, lessThan(0.01), reason: 'center jump at step $i');
        previous = pose;
      }
    });

    test('phases behave as specced', () {
      final planner = plannerFor(lhr, jfk);

      // Overview: top-down, plane parked at departure.
      final intro = planner.poseAt(0.05);
      expect(intro.pitchDeg, 0);
      expect(intro.bearingDeg, 0);
      expect(planner.planeProgressAt(0.05), 0);

      // Mid-flight: tilted, zoomed in, and always north-up (the camera never
      // rotates; the plane sprite rotates instead).
      final mid = planner.poseAt(0.5);
      // Pitch is adapted to the route's width, so assert the effective value
      // (LHR-JFK is wide, so it flattens below the 55 max).
      expect(mid.pitchDeg, closeTo(planner.followPitch, 0.01));
      expect(planner.followPitch, inInclusiveRange(44.0, 55.0));
      expect(mid.zoom, closeTo(planner.followZoom, 0.01));
      expect(mid.bearingDeg, 0);
      final planeMid = planner.planeProgressAt(0.5);
      expect(planeMid, inInclusiveRange(0.3, 0.7));

      // Outro: back to overview, plane arrived, stats visible.
      final outro = planner.poseAt(1);
      expect(outro.pitchDeg, closeTo(0, 0.01));
      expect(outro.zoom, closeTo(planner.overviewZoom, 0.01));
      expect(outro.bearingDeg.abs() % 360, closeTo(0, 0.01));
      expect(planner.planeProgressAt(1), 1);
      expect(planner.statsOverlayOpacityAt(1), 1);
      expect(planner.statsOverlayOpacityAt(0.5), 0);
    });

    test('follow pitch flattens for wide routes, full tilt for compact', () {
      // A near square, short hop keeps the full dramatic tilt.
      final compact = plannerFor(
        const LatLng(48.0, 2.0),
        const LatLng(48.6, 2.9),
      );
      expect(compact.followPitch, closeTo(CameraPathPlanner.followPitchDeg, 0.01));

      // A wide, mostly east-west transatlantic flattens to trade sky for map.
      final wide = plannerFor(lhr, jfk);
      expect(wide.followPitch, lessThan(compact.followPitch));
      expect(wide.followPitch, greaterThanOrEqualTo(44.0));
    });

    test('marker pops fire in order', () {
      final planner = plannerFor(ams, cdg);
      expect(planner.depMarkerScaleAt(0), 0);
      expect(planner.depMarkerScaleAt(0.06), closeTo(1, 0.05));
      expect(planner.arrMarkerScaleAt(0.1), 0);
      expect(planner.arrMarkerScaleAt(0.18), closeTo(1, 0.05));
    });

    test('follow zoom is a fixed dive above the overview', () {
      final planner = plannerFor(lhr, jfk);
      expect(
        planner.followZoom,
        closeTo(planner.overviewZoom + CameraPathPlanner.followZoomDelta, 1e-9),
      );
    });

    test('lowerTileLevel respects the floor', () {
      final planner = plannerFor(lhr, jfk);
      final initial = planner.tileLevel;
      expect(planner.lowerTileLevel(), isTrue);
      expect(planner.tileLevel, initial - 1);
      var guard = 0;
      while (planner.lowerTileLevel() && guard < 30) {
        guard++;
      }
      expect(planner.tileLevel, CameraPathPlanner.minTileLevel);
      expect(planner.lowerTileLevel(), isFalse);
    });
  });

  group('visible tiles', () {
    test('per-frame tile count stays within budget at the fixed level', () {
      final route = routeOf(lhr, jfk);
      final planner = CameraPathPlanner(
        route: route,
        spec: FlightVideoSpec.forDistance(route.totalKm),
      );
      for (final t in [0.0, 0.1, 0.2, 0.35, 0.5, 0.65, 0.8, 0.9, 1.0]) {
        final tiles = positionedTilesForPose(
          planner.transformAt(t),
          levelOverride: planner.tileLevel,
        );
        expect(tiles, isNotEmpty, reason: 'no tiles at t=$t');
        expect(tiles.length, lessThanOrEqualTo(kMaxTilesPerFrame));
        for (final tile in tiles) {
          // Every frame of the video uses the same tile level, so zoom
          // transitions never swap imagery.
          expect(tile.coord.z, planner.tileLevel);
          final levelTiles = 1 << tile.coord.z;
          expect(tile.coord.x, inInclusiveRange(0, levelTiles - 1));
          expect(tile.coord.y, inInclusiveRange(0, levelTiles - 1));
        }
      }
    });

    test('tiles under the anchor are selected', () {
      final route = routeOf(lhr, jfk);
      final planner = CameraPathPlanner(
        route: route,
        spec: FlightVideoSpec.forDistance(route.totalKm),
      );
      final wt = planner.transformAt(0.5);
      final tiles = positionedTilesForPose(wt);
      final level = wt.pose.zoom.round();
      final tileWorldSize =
          WorldTransform.tileSizePx * pow(2.0, wt.pose.zoom - level);
      final cameraTx =
          (wt.cameraWorld.dx / tileWorldSize).floor() % (1 << level);
      final cameraTy = (wt.cameraWorld.dy / tileWorldSize).floor();
      expect(
        tiles.any(
          (tile) => tile.coord.x == cameraTx && tile.coord.y == cameraTy,
        ),
        isTrue,
        reason: 'camera tile missing from visible set',
      );
    });

    test('budgeted manifests stay within the tile budget', () {
      for (final pair in [
        [lhr, jfk],
        [lax, syd],
        [ams, cdg],
      ]) {
        final route = routeOf(pair[0], pair[1]);
        final spec = FlightVideoSpec.forDistance(route.totalKm);
        final planner = CameraPathPlanner(route: route, spec: spec);
        final manifest = buildBudgetedTileManifest(
          planner: planner,
          spec: spec,
        );
        expect(manifest, isNotEmpty);
        expect(
          manifest.length,
          lessThanOrEqualTo(kMaxManifestTiles),
          reason:
              'manifest for ${route.totalKm.round()} km route: '
              '${manifest.length} tiles (followZoom ${planner.followZoom})',
        );
      }
    });
  });
}
