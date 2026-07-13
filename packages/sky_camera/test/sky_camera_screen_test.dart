import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_camera/sky_camera.dart';

void main() {
  testWidgets('renders preview and placeholder overlay zones', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SkyCameraScreen(
          driver: _FakeSkyCameraDriver(),
          snapshotSource: const _FakeSnapshotSource(),
          exportService: _FakeExportService(),
          observer: const _FakeObserver(),
          photoCropper: const _FakePhotoCropper(),
          openCapturePreview: _openFakeCapturePreview,
          overlayComposer: const SkyCameraOverlayComposer(),
          strings: _strings,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('test.preview')), findsOneWidget);
    expect(find.byKey(const Key('sky_camera.flash_button')), findsNothing);
    expect(find.textContaining('LHR'), findsOneWidget);
    expect(find.textContaining('BCN'), findsOneWidget);
    expect(find.byKey(const Key('sky_camera.brand_logo')), findsOneWidget);
    final signalBarsSize = tester.getSize(
      find.byKey(const Key('sky_camera.gps_signal_bars')),
    );
    expect(signalBarsSize.width, closeTo(14.4, 0.01));
    expect(signalBarsSize.height, closeTo(14.4, 0.01));
  });

  testWidgets('records a video and saves it with its track', (tester) async {
    final driver = _FakeSkyCameraDriver();
    final exportService = _FakeExportService();
    await tester.pumpWidget(
      MaterialApp(
        home: SkyCameraScreen(
          driver: driver,
          snapshotSource: const _FakeSnapshotSource(),
          exportService: exportService,
          observer: const _FakeObserver(),
          photoCropper: const _FakePhotoCropper(),
          openCapturePreview: _openFakeCapturePreview,
          overlayComposer: const SkyCameraOverlayComposer(),
          strings: _strings,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sky_camera.mode_video')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('sky_camera.capture_button')));
    await tester.pump();

    expect(driver.didStartVideo, isTrue);
    expect(driver.isRecordingVideo, isTrue);
    expect(find.byKey(const Key('sky_camera.recording_chip')), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    // Shutter countdown: the cap minus 2 elapsed seconds.
    expect(
      tester
          .widget<Text>(
            find.byKey(const Key('sky_camera.recording_countdown_seconds')),
          )
          .data,
      '${SkyCameraMediaFormat.maxVideoDuration.inSeconds - 2}',
    );
    await tester.tap(find.byKey(const Key('sky_camera.capture_button')));
    await tester.pumpAndSettle();

    expect(driver.didStopVideo, isTrue);
    expect(exportService.didSave, isTrue);
    expect(find.byKey(const Key('sky_camera.recording_chip')), findsNothing);
    expect(
      find.byKey(const Key('sky_camera.last_capture_thumbnail')),
      findsOneWidget,
    );
  });

  testWidgets('locks capture and mode controls while video start is pending', (
    tester,
  ) async {
    final startCompleter = Completer<void>();
    final driver = _FakeSkyCameraDriver(startVideoCompleter: startCompleter);
    await tester.pumpWidget(
      MaterialApp(
        home: SkyCameraScreen(
          driver: driver,
          snapshotSource: const _FakeSnapshotSource(),
          exportService: _FakeExportService(),
          observer: const _FakeObserver(),
          photoCropper: const _FakePhotoCropper(),
          openCapturePreview: _openFakeCapturePreview,
          overlayComposer: const SkyCameraOverlayComposer(),
          strings: _strings,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sky_camera.mode_video')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('sky_camera.capture_button')));
    await tester.pump();

    expect(driver.startVideoCount, 1);
    expect(find.byKey(const Key('sky_camera.recording_chip')), findsNothing);

    await tester.tap(find.byKey(const Key('sky_camera.mode_photo')));
    await tester.tap(find.byKey(const Key('sky_camera.capture_button')));
    await tester.pump();
    expect(driver.startVideoCount, 1);

    startCompleter.complete();
    await tester.pump();
    expect(find.byKey(const Key('sky_camera.recording_chip')), findsOneWidget);

    await tester.tap(find.byKey(const Key('sky_camera.capture_button')));
    await tester.pumpAndSettle();
    expect(driver.didStopVideo, isTrue);
    expect(driver.didCapture, isFalse);
  });

  testWidgets('close waits for pending video start and saves before popping', (
    tester,
  ) async {
    final startCompleter = Completer<void>();
    final driver = _FakeSkyCameraDriver(startVideoCompleter: startCompleter);
    final exportService = _FakeExportService();
    await tester.pumpWidget(
      _cameraRouteHost(driver: driver, exportService: exportService),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sky_camera.mode_video')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('sky_camera.capture_button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('sky_camera.close_button')));
    await tester.pump();

    expect(find.byKey(const Key('sky_camera.close_button')), findsOneWidget);
    expect(driver.didStopVideo, isFalse);

    startCompleter.complete();
    await tester.pumpAndSettle();

    expect(driver.didStopVideo, isTrue);
    expect(exportService.didSave, isTrue);
    expect(find.byKey(const Key('sky_camera.close_button')), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('system back saves an active video before popping', (
    tester,
  ) async {
    final driver = _FakeSkyCameraDriver();
    final exportService = _FakeExportService();
    await tester.pumpWidget(
      _cameraRouteHost(driver: driver, exportService: exportService),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sky_camera.mode_video')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('sky_camera.capture_button')));
    await tester.pump();
    expect(driver.isRecordingVideo, isTrue);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(driver.didStopVideo, isTrue);
    expect(exportService.didSave, isTrue);
    expect(find.byKey(const Key('sky_camera.close_button')), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('swiping the mode strip left enters video mode', (tester) async {
    final driver = _FakeSkyCameraDriver();
    await tester.pumpWidget(
      MaterialApp(
        home: SkyCameraScreen(
          driver: driver,
          snapshotSource: const _FakeSnapshotSource(),
          exportService: _FakeExportService(),
          observer: const _FakeObserver(),
          photoCropper: const _FakePhotoCropper(),
          openCapturePreview: _openFakeCapturePreview,
          overlayComposer: const _FakeOverlayComposer(),
          strings: _strings,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.fling(
      find.byKey(const Key('sky_camera.mode_selector')),
      const Offset(-60, 0),
      600,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('sky_camera.capture_button')));
    await tester.pump();
    expect(driver.didStartVideo, isTrue);
    await tester.tap(find.byKey(const Key('sky_camera.capture_button')));
    await tester.pumpAndSettle();
    expect(driver.didStopVideo, isTrue);
  });

  testWidgets('swiping the mode strip right returns to photo mode', (
    tester,
  ) async {
    final driver = _FakeSkyCameraDriver();
    await tester.pumpWidget(
      MaterialApp(
        home: SkyCameraScreen(
          driver: driver,
          snapshotSource: const _FakeSnapshotSource(),
          exportService: _FakeExportService(),
          observer: const _FakeObserver(),
          photoCropper: const _FakePhotoCropper(),
          openCapturePreview: _openFakeCapturePreview,
          overlayComposer: const _FakeOverlayComposer(),
          strings: _strings,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sky_camera.mode_video')));
    await tester.pump();
    await tester.fling(
      find.byKey(const Key('sky_camera.mode_selector')),
      const Offset(60, 0),
      600,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('sky_camera.capture_button')));
    // Real image work inside the fake driver needs wall-clock turns that
    // pumpAndSettle's tight loop can starve after a fling; bounded pumps
    // give the engine callbacks room to land.
    for (var i = 0; i < 20 && !driver.didCapture; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 100));
    }

    // A photo capture (not a recording) proves the swipe landed on PHOTO.
    expect(driver.didCapture, isTrue);
    expect(driver.didStartVideo, isFalse);
  });

  testWidgets('auto-stops recording at the maximum duration', (tester) async {
    final driver = _FakeSkyCameraDriver();
    final exportService = _FakeExportService();
    await tester.pumpWidget(
      MaterialApp(
        home: SkyCameraScreen(
          driver: driver,
          snapshotSource: const _FakeSnapshotSource(),
          exportService: exportService,
          observer: const _FakeObserver(),
          photoCropper: const _FakePhotoCropper(),
          openCapturePreview: _openFakeCapturePreview,
          overlayComposer: const SkyCameraOverlayComposer(),
          strings: _strings,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sky_camera.mode_video')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('sky_camera.capture_button')));
    await tester.pump();
    expect(driver.isRecordingVideo, isTrue);

    await tester.pump(SkyCameraMediaFormat.maxVideoDuration);
    await tester.pumpAndSettle();

    expect(driver.didStopVideo, isTrue);
    expect(exportService.didSave, isTrue);
  });

  testWidgets('uses a fixed portrait 9:16 camera viewport', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SkyCameraScreen(
          driver: _FakeSkyCameraDriver(),
          snapshotSource: const _FakeSnapshotSource(),
          exportService: _FakeExportService(),
          observer: const _FakeObserver(),
          photoCropper: const _FakePhotoCropper(),
          openCapturePreview: _openFakeCapturePreview,
          overlayComposer: const SkyCameraOverlayComposer(),
          strings: _strings,
        ),
      ),
    );

    await tester.pumpAndSettle();

    final viewportSize = tester.getSize(
      find.byKey(const Key('sky_camera.viewport')),
    );
    expect(viewportSize.width / viewportSize.height, closeTo(9 / 16, 0.001));
  });

  testWidgets('keeps exported overlay content inside the media viewport', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SkyCameraScreen(
          driver: _FakeSkyCameraDriver(),
          snapshotSource: const _FakeSnapshotSource(),
          exportService: _FakeExportService(),
          observer: const _FakeObserver(),
          photoCropper: const _FakePhotoCropper(),
          openCapturePreview: _openFakeCapturePreview,
          overlayComposer: const SkyCameraOverlayComposer(),
          strings: _strings,
        ),
      ),
    );

    await tester.pumpAndSettle();

    final viewport = find.byKey(const Key('sky_camera.viewport'));
    expect(
      find.descendant(
        of: viewport,
        matching: find.byKey(const Key('sky_camera.brand_logo')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: viewport,
        matching: find.byKey(const Key('sky_camera.capture_button')),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: viewport,
        matching: find.byKey(const Key('sky_camera.close_button')),
      ),
      findsNothing,
    );
  });

  testWidgets('hides route header when snapshot has no flight info', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SkyCameraScreen(
          driver: _FakeSkyCameraDriver(),
          snapshotSource: _FakeSnapshotSource(
            snapshot: _testSnapshot(
              routeLabel: '',
              originCode: '',
              destinationCode: '',
              originCountryCode: '',
              destinationCountryCode: '',
            ),
          ),
          exportService: _FakeExportService(),
          observer: const _FakeObserver(),
          photoCropper: const _FakePhotoCropper(),
          openCapturePreview: _openFakeCapturePreview,
          overlayComposer: const SkyCameraOverlayComposer(),
          strings: _strings,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('LHR'), findsNothing);
    expect(find.textContaining('BCN'), findsNothing);
    expect(find.textContaining('London'), findsNothing);
    expect(find.textContaining('Barcelona'), findsNothing);
    expect(find.byKey(const Key('sky_camera.brand_logo')), findsOneWidget);
  });

  testWidgets('domestic route keeps flags and omits country codes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SkyCameraScreen(
          driver: _FakeSkyCameraDriver(),
          snapshotSource: _FakeSnapshotSource(
            snapshot: _testSnapshot(
              routeLabel: 'London, GB → Manchester, GB',
              originCode: 'LHR',
              destinationCode: 'MAN',
              originCountryCode: 'GB',
              destinationCountryCode: 'GB',
            ),
          ),
          exportService: _FakeExportService(),
          observer: const _FakeObserver(),
          photoCropper: const _FakePhotoCropper(),
          openCapturePreview: _openFakeCapturePreview,
          overlayComposer: const SkyCameraOverlayComposer(),
          strings: _strings,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('London → Manchester'), findsOneWidget);
    expect(find.textContaining('🇬🇧'), findsOneWidget);
    expect(find.textContaining(', GB'), findsNothing);
  });

  testWidgets('captures and saves an overlay photo', (tester) async {
    final exportService = _FakeExportService();
    final driver = _FakeSkyCameraDriver();

    await tester.pumpWidget(
      MaterialApp(
        home: SkyCameraScreen(
          driver: driver,
          snapshotSource: const _FakeSnapshotSource(),
          exportService: exportService,
          observer: const _FakeObserver(),
          photoCropper: const _FakePhotoCropper(),
          openCapturePreview: _openFakeCapturePreview,
          overlayComposer: const _FakeOverlayComposer(),
          strings: _strings,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('LHR'), findsOneWidget);
    expect(find.textContaining('BCN'), findsOneWidget);
    expect(find.byKey(const Key('sky_camera.capture_button')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('sky_camera.capture_button')),
    );
    await tester.tapAt(
      tester.getCenter(find.byKey(const Key('sky_camera.capture_button'))),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(driver.didCapture, isTrue);
    expect(exportService.didSave, isTrue);
    expect(find.text('Photo saved'), findsNothing);
    expect(find.text('DONE'), findsNothing);
    expect(find.text('PHOTO'), findsOneWidget);
    expect(
      find.byKey(const Key('sky_camera.last_capture_thumbnail')),
      findsOneWidget,
    );
    final shutterCenter = tester.getCenter(
      find.byKey(const Key('sky_camera.capture_button')),
    );
    final thumbnailCenter = tester.getCenter(
      find.byKey(const Key('sky_camera.last_capture_thumbnail')),
    );
    final thumbnailSize = tester.getSize(
      find.byKey(const Key('sky_camera.last_capture_thumbnail')),
    );
    final bottomBarLeft = tester
        .getTopLeft(find.byKey(const Key('sky_camera.bottom_bar')))
        .dx;
    final shutterLeft = tester
        .getTopLeft(find.byKey(const Key('sky_camera.capture_button')))
        .dx;
    final expectedThumbnailCenter = (bottomBarLeft + shutterLeft) / 2;
    final screenCenter = tester.getCenter(find.byType(Scaffold));
    expect(shutterCenter.dx, closeTo(screenCenter.dx, 0.01));
    expect(thumbnailCenter.dy, closeTo(shutterCenter.dy, 0.01));
    expect(thumbnailCenter.dx, closeTo(expectedThumbnailCenter, 0.01));
    expect(thumbnailSize.width, thumbnailSize.height);
    expect(thumbnailSize.width, closeTo(57.6, 0.01));
  });

  testWidgets('tap on thumbnail opens full screen preview', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SkyCameraScreen(
          driver: _FakeSkyCameraDriver(),
          snapshotSource: const _FakeSnapshotSource(),
          exportService: _FakeExportService(),
          observer: const _FakeObserver(),
          photoCropper: const _FakePhotoCropper(),
          openCapturePreview: _openFakeCapturePreview,
          overlayComposer: const _FakeOverlayComposer(),
          strings: _strings,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sky_camera.capture_button')));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('sky_camera.last_capture_thumbnail')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('sky_camera.full_screen_preview_close')),
      findsOneWidget,
    );
  });

  testWidgets('thumbnail preview receives all camera session captures', (
    tester,
  ) async {
    var captures = const <SkyCameraSavedCapture>[];
    String? initialCaptureId;

    await tester.pumpWidget(
      MaterialApp(
        home: SkyCameraScreen(
          driver: _FakeSkyCameraDriver(),
          snapshotSource: const _FakeSnapshotSource(),
          exportService: _FakeExportService(),
          observer: const _FakeObserver(),
          photoCropper: const _FakePhotoCropper(),
          openCapturePreview: (context, sessionCaptures, captureId) async {
            captures = sessionCaptures;
            initialCaptureId = captureId;
            return const <String>{};
          },
          overlayComposer: const _FakeOverlayComposer(),
          strings: _strings,
        ),
      ),
    );

    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const Key('sky_camera.capture_button')));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
    }

    await tester.tap(
      find.byKey(const Key('sky_camera.last_capture_thumbnail')),
    );
    await tester.pump();

    expect(captures.map((capture) => capture.id), ['capture-1', 'capture-2']);
    expect(initialCaptureId, 'capture-2');
  });

  testWidgets('close button pops the camera screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => SkyCameraScreen(
                        driver: _FakeSkyCameraDriver(),
                        snapshotSource: const _FakeSnapshotSource(),
                        exportService: _FakeExportService(),
                        observer: const _FakeObserver(),
                        photoCropper: const _FakePhotoCropper(),
                        openCapturePreview: _openFakeCapturePreview,
                        overlayComposer: const SkyCameraOverlayComposer(),
                        strings: _strings,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sky_camera.close_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('sky_camera.close_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sky_camera.close_button')), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('shows save progress in thumbnail slot while export is running', (
    tester,
  ) async {
    final exportService = _DelayedExportService();

    await tester.pumpWidget(
      MaterialApp(
        home: SkyCameraScreen(
          driver: _FakeSkyCameraDriver(),
          snapshotSource: const _FakeSnapshotSource(),
          exportService: exportService,
          observer: const _FakeObserver(),
          photoCropper: const _FakePhotoCropper(),
          openCapturePreview: _openFakeCapturePreview,
          overlayComposer: const _FakeOverlayComposer(),
          strings: _strings,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sky_camera.capture_button')));
    await tester.pump();

    expect(
      find.byKey(const Key('sky_camera.saving_thumbnail_indicator')),
      findsOneWidget,
    );

    exportService.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(
      find.byKey(const Key('sky_camera.last_capture_thumbnail')),
      findsOneWidget,
    );
  });

  testWidgets('tap on preview forwards focus point to the driver', (
    tester,
  ) async {
    final driver = _FakeSkyCameraDriver();

    await tester.pumpWidget(
      MaterialApp(
        home: SkyCameraScreen(
          driver: driver,
          snapshotSource: const _SilentSnapshotSource(),
          exportService: _FakeExportService(),
          observer: const _FakeObserver(),
          photoCropper: const _FakePhotoCropper(),
          openCapturePreview: _openFakeCapturePreview,
          overlayComposer: const SkyCameraOverlayComposer(),
          strings: _strings,
        ),
      ),
    );

    await tester.pumpAndSettle();

    final preview = find.byKey(const Key('sky_camera.preview_gesture_area'));
    final previewRect = tester.getRect(preview);
    final previewTapPoint = Offset(
      previewRect.center.dx,
      previewRect.top + (previewRect.height * 0.22),
    );
    await tester.tapAt(previewTapPoint);
    await tester.pump();

    expect(driver.lastFocusPoint, isNotNull);
    expect(driver.lastFocusPoint!.dx, closeTo(0.5, 0.01));
    expect(driver.lastFocusPoint!.dy, closeTo(0.22, 0.02));
  });

  testWidgets('pinch on preview updates zoom level', (tester) async {
    final driver = _FakeSkyCameraDriver();

    await tester.pumpWidget(
      MaterialApp(
        home: SkyCameraScreen(
          driver: driver,
          snapshotSource: const _SilentSnapshotSource(),
          exportService: _FakeExportService(),
          observer: const _FakeObserver(),
          photoCropper: const _FakePhotoCropper(),
          openCapturePreview: _openFakeCapturePreview,
          overlayComposer: const SkyCameraOverlayComposer(),
          strings: _strings,
        ),
      ),
    );

    await tester.pumpAndSettle();

    final preview = find.byKey(const Key('sky_camera.preview_gesture_area'));
    final previewRect = tester.getRect(preview);
    final center = Offset(
      previewRect.center.dx,
      previewRect.top + (previewRect.height * 0.2),
    );
    final gesture1 = await tester.startGesture(
      Offset(center.dx - 24, center.dy),
      pointer: 1,
    );
    final gesture2 = await tester.startGesture(
      Offset(center.dx + 24, center.dy),
      pointer: 2,
    );
    await tester.pump();

    await gesture1.moveTo(Offset(center.dx - 72, center.dy));
    await gesture2.moveTo(Offset(center.dx + 72, center.dy));
    await tester.pump();

    await gesture1.up();
    await gesture2.up();
    await tester.pump();

    expect(driver.zoomUpdates, isNotEmpty);
    expect(driver.zoomUpdates.last, greaterThan(1.0));
  });

  testWidgets('zoom selector shows 1x through 4x and selects exact zoom', (
    tester,
  ) async {
    final driver = _FakeSkyCameraDriver();

    await tester.pumpWidget(
      MaterialApp(
        home: SkyCameraScreen(
          driver: driver,
          snapshotSource: const _SilentSnapshotSource(),
          exportService: _FakeExportService(),
          observer: const _FakeObserver(),
          photoCropper: const _FakePhotoCropper(),
          openCapturePreview: _openFakeCapturePreview,
          overlayComposer: const SkyCameraOverlayComposer(),
          strings: _strings,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('1x'), findsOneWidget);
    expect(find.text('2x'), findsOneWidget);
    expect(find.text('3x'), findsOneWidget);
    expect(find.text('4x'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sky_camera.zoom_3')));
    await tester.pumpAndSettle();

    expect(driver.zoomUpdates.last, 3);
  });

  testWidgets('plain drag does not move metrics panel', (tester) async {
    final overlayComposer = _FakeOverlayComposer();

    await tester.pumpWidget(
      MaterialApp(
        home: SkyCameraScreen(
          driver: _FakeSkyCameraDriver(),
          snapshotSource: const _FakeSnapshotSource(),
          exportService: _FakeExportService(),
          observer: const _FakeObserver(),
          photoCropper: const _FakePhotoCropper(),
          openCapturePreview: _openFakeCapturePreview,
          overlayComposer: overlayComposer,
          strings: _strings,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('sky_camera.metrics_panel_drag_area')),
      const Offset(80, 60),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sky_camera.capture_button')));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    final position = overlayComposer.lastMetricsPosition;
    expect(position, isNotNull);
    expect(position!.x, 0);
    expect(position.y, 0.5);
  });

  testWidgets('long press drag updates capture overlay position', (
    tester,
  ) async {
    final overlayComposer = _FakeOverlayComposer();

    await tester.pumpWidget(
      MaterialApp(
        home: SkyCameraScreen(
          driver: _FakeSkyCameraDriver(),
          snapshotSource: const _FakeSnapshotSource(),
          exportService: _FakeExportService(),
          observer: const _FakeObserver(),
          photoCropper: const _FakePhotoCropper(),
          openCapturePreview: _openFakeCapturePreview,
          overlayComposer: overlayComposer,
          strings: _strings,
        ),
      ),
    );

    await tester.pumpAndSettle();
    final dragTarget = find.byKey(
      const Key('sky_camera.metrics_panel_drag_area'),
    );
    final gesture = await tester.startGesture(tester.getCenter(dragTarget));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveBy(const Offset(80, 60));
    await gesture.up();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sky_camera.capture_button')));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    final position = overlayComposer.lastMetricsPosition;
    expect(position, isNotNull);
    expect(position!.x != 0 || position.y != 0.5, isTrue);
  });

  testWidgets('keeps available metrics visible when gps data is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SkyCameraScreen(
          driver: _FakeSkyCameraDriver(),
          snapshotSource: _FakeSnapshotSource(
            snapshot: _testSnapshot(
              hasLiveLocation: false,
              latitude: null,
              longitude: null,
            ),
          ),
          exportService: _FakeExportService(),
          observer: const _FakeObserver(),
          photoCropper: const _FakePhotoCropper(),
          openCapturePreview: _openFakeCapturePreview,
          overlayComposer: const _FakeOverlayComposer(),
          strings: _strings,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.byKey(const Key('sky_camera.metrics_panel_drag_area')),
      findsOneWidget,
    );
  });

  testWidgets('camera preview shows before gps startup completes', (
    tester,
  ) async {
    final snapshotSource = _DelayedSnapshotSource(
      snapshot: _testSnapshot(
        hasLiveLocation: false,
        latitude: null,
        longitude: null,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SkyCameraScreen(
          driver: _FakeSkyCameraDriver(),
          snapshotSource: snapshotSource,
          exportService: _FakeExportService(),
          observer: const _FakeObserver(),
          photoCropper: const _FakePhotoCropper(),
          openCapturePreview: _openFakeCapturePreview,
          overlayComposer: const SkyCameraOverlayComposer(),
          strings: _strings,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byKey(const Key('test.preview')), findsOneWidget);
    expect(
      find.byKey(const Key('sky_camera.gps_loading_badge')),
      findsOneWidget,
    );

    snapshotSource.completeStart();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byKey(const Key('sky_camera.gps_loading_badge')), findsNothing);
  });

  testWidgets('zoom capability failure does not mark camera unavailable', (
    tester,
  ) async {
    final driver = _FakeSkyCameraDriver(throwOnZoomBounds: true);
    await tester.pumpWidget(
      MaterialApp(
        home: SkyCameraScreen(
          driver: driver,
          snapshotSource: const _FakeSnapshotSource(),
          exportService: _FakeExportService(),
          observer: const _FakeObserver(),
          photoCropper: const _FakePhotoCropper(),
          openCapturePreview: _openFakeCapturePreview,
          overlayComposer: const _FakeOverlayComposer(),
          strings: _strings,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Camera unavailable'), findsNothing);
    expect(find.byKey(const Key('test.preview')), findsOneWidget);

    await tester.tap(find.byKey(const Key('sky_camera.capture_button')));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(driver.didCapture, isTrue);
  });
}

Widget _cameraRouteHost({
  required _FakeSkyCameraDriver driver,
  required SkyCameraExportService exportService,
}) {
  return MaterialApp(
    theme: ThemeData(splashFactory: NoSplash.splashFactory),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => SkyCameraScreen(
                    driver: driver,
                    snapshotSource: const _FakeSnapshotSource(),
                    exportService: exportService,
                    observer: const _FakeObserver(),
                    photoCropper: const _FakePhotoCropper(),
                    openCapturePreview: _openFakeCapturePreview,
                    overlayComposer: const SkyCameraOverlayComposer(),
                    strings: _strings,
                  ),
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
}

const _strings = SkyCameraStrings(
  loadingCamera: 'Loading camera...',
  loadingGpsData: 'Loading GPS data',
  retry: 'Retry',
  close: 'Close',
  zoom: 'Zoom',
  flash: 'Flash',
  captureFailed: 'Capture failed',
  cameraUnavailable: 'Camera unavailable',
  cameraPermissionDenied: 'Permission denied',
  savedMessage: 'Photo saved',
  share: 'Share',
  telemetrySpeed: 'Speed',
  telemetryAltitude: 'Altitude',
  telemetryHeading: 'Heading',
  telemetryTime: 'Time',
  contextCaption: 'Context',
  mapCaption: 'Map',
  coordinatesCaption: 'Coordinates',
  noValuePlaceholder: '--',
  altitudeUnit: SkyCameraAltitudeUnit.foot,
  speedUnit: SkyCameraSpeedUnit.kmh,
  temperatureUnit: SkyCameraTemperatureUnit.celsius,
  dateDisplayFormat: SkyCameraDateDisplayFormat.dayMonthYear,
);

Future<Set<String>> _openFakeCapturePreview(
  BuildContext context,
  List<SkyCameraSavedCapture> captures,
  String initialCaptureId,
) async {
  return await Navigator.of(context).push<Set<String>>(
        MaterialPageRoute<Set<String>>(
          builder: (_) => Scaffold(
            backgroundColor: Colors.black,
            body: IconButton(
              key: const Key('sky_camera.full_screen_preview_close'),
              onPressed: () => Navigator.of(context).pop(const <String>{}),
              icon: const Icon(Icons.close),
            ),
          ),
        ),
      ) ??
      const <String>{};
}

class _FakeSkyCameraDriver implements SkyCameraDriver {
  _FakeSkyCameraDriver({
    this.throwOnZoomBounds = false,
    this.startVideoCompleter,
  });

  final bool throwOnZoomBounds;
  final Completer<void>? startVideoCompleter;
  bool _isInitialized = false;
  bool didCapture = false;
  bool didStartVideo = false;
  int startVideoCount = 0;
  bool didStopVideo = false;
  bool _isRecordingVideo = false;
  bool _audioEnabled = false;
  Offset? lastFocusPoint;
  final List<double> zoomUpdates = <double>[];

  @override
  SkyCameraFlashState get flashState => SkyCameraFlashState.off;

  @override
  bool get isAudioEnabled => _audioEnabled;

  @override
  Future<void> setAudioEnabled(bool enabled) async {
    _audioEnabled = enabled;
  }

  @override
  bool get isRecordingVideo => _isRecordingVideo;

  @override
  Future<void> startVideoRecording() async {
    didStartVideo = true;
    startVideoCount += 1;
    await startVideoCompleter?.future;
    _isRecordingVideo = true;
  }

  @override
  Future<SkyCameraCapturedVideo> stopVideoRecording() async {
    didStopVideo = true;
    _isRecordingVideo = false;
    return SkyCameraCapturedVideo(
      filePath: '/tmp/sky_camera_test.mp4',
      fileExtension: 'mp4',
      capturedAt: DateTime(2026, 6, 29, 12, 0),
      duration: const Duration(seconds: 3),
    );
  }

  @override
  bool get isInitialized => _isInitialized;

  @override
  Widget buildPreview() {
    return const ColoredBox(
      key: Key('test.preview'),
      color: Colors.black,
      child: SizedBox.expand(),
    );
  }

  @override
  Future<SkyCameraCapturedPhoto> capturePhoto() async {
    didCapture = true;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 80, 80),
      Paint()..color = const Color(0xFF112233),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(80, 80);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return SkyCameraCapturedPhoto(
      bytes: bytes!.buffer.asUint8List(),
      fileExtension: 'png',
      capturedAt: DateTime(2026, 6, 29, 12, 0),
    );
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<void> initialize() async {
    _isInitialized = true;
  }

  @override
  Future<void> onAppLifecycleStateChanged(AppLifecycleState state) async {}

  @override
  Future<void> setFocusPoint(Offset normalizedPoint) async {
    lastFocusPoint = normalizedPoint;
  }

  @override
  Future<SkyCameraZoomBounds> getZoomBounds() async {
    if (throwOnZoomBounds) {
      throw StateError('Zoom bounds are unavailable.');
    }
    return const SkyCameraZoomBounds(min: 1.0, max: 4.0);
  }

  @override
  Future<void> setZoomLevel(double zoomLevel) async {
    zoomUpdates.add(zoomLevel);
  }

  @override
  Future<void> toggleFlash() async {}
}

class _FakeSnapshotSource implements SkyCameraOverlaySnapshotSource {
  const _FakeSnapshotSource({this.snapshot});

  final SkyCameraOverlaySnapshot? snapshot;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> start() async {}

  @override
  Stream<SkyCameraOverlaySnapshot> watch() {
    return Stream<SkyCameraOverlaySnapshot>.value(snapshot ?? _testSnapshot());
  }
}

class _SilentSnapshotSource implements SkyCameraOverlaySnapshotSource {
  const _SilentSnapshotSource();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> start() async {}

  @override
  Stream<SkyCameraOverlaySnapshot> watch() =>
      const Stream<SkyCameraOverlaySnapshot>.empty();
}

class _DelayedSnapshotSource implements SkyCameraOverlaySnapshotSource {
  _DelayedSnapshotSource({required this.snapshot});

  final SkyCameraOverlaySnapshot snapshot;
  final Completer<void> _startCompleter = Completer<void>();

  void completeStart() {
    if (!_startCompleter.isCompleted) {
      _startCompleter.complete();
    }
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<void> start() => _startCompleter.future;

  @override
  Stream<SkyCameraOverlaySnapshot> watch() {
    return Stream<SkyCameraOverlaySnapshot>.value(snapshot);
  }
}

class _FakeExportService implements SkyCameraExportService {
  bool didSave = false;
  int _saveCount = 0;

  @override
  Future<SkyCameraSavedCapture> saveCapture({
    required SkyCameraCapturedPhoto originalPhoto,
    required SkyCameraOverlaySnapshot snapshot,
    required List<int> overlayBytes,
  }) async {
    didSave = true;
    _saveCount += 1;
    expect(overlayBytes, isNotEmpty);
    return SkyCameraSavedCapture(
      id: 'capture-$_saveCount',
      originalPath: '/tmp/original.png',
      overlayPath: '/tmp/overlay.png',
    );
  }

  @override
  Future<SkyCameraSavedCapture> saveVideoCapture({
    required SkyCameraCapturedVideo video,
    required SkyCameraOverlaySnapshot snapshot,
    required List<SkyCameraVideoTrackSample> track,
  }) async {
    didSave = true;
    _saveCount += 1;
    return SkyCameraSavedCapture(
      id: 'capture-$_saveCount',
      originalPath: video.filePath,
      overlayPath: '/tmp/poster.png',
      isVideo: true,
    );
  }
}

class _DelayedExportService implements SkyCameraExportService {
  final Completer<void> _completer = Completer<void>();

  void complete() {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }

  @override
  Future<SkyCameraSavedCapture> saveCapture({
    required SkyCameraCapturedPhoto originalPhoto,
    required SkyCameraOverlaySnapshot snapshot,
    required List<int> overlayBytes,
  }) async {
    await _completer.future;
    return const SkyCameraSavedCapture(
      id: 'capture-1',
      originalPath: '/tmp/original.png',
      overlayPath: '/tmp/overlay.png',
    );
  }

  @override
  Future<SkyCameraSavedCapture> saveVideoCapture({
    required SkyCameraCapturedVideo video,
    required SkyCameraOverlaySnapshot snapshot,
    required List<SkyCameraVideoTrackSample> track,
  }) async {
    await _completer.future;
    return const SkyCameraSavedCapture(
      id: 'capture-1',
      originalPath: '/tmp/original.mp4',
      overlayPath: '/tmp/poster.png',
      isVideo: true,
    );
  }
}

class _FakeOverlayComposer extends SkyCameraOverlayComposer {
  const _FakeOverlayComposer();

  static SkyCameraMetricsPosition? _lastMetricsPosition;

  SkyCameraMetricsPosition? get lastMetricsPosition => _lastMetricsPosition;

  @override
  Future<Uint8List> compose({
    required Uint8List originalBytes,
    required SkyCameraOverlaySnapshot snapshot,
    required SkyCameraStrings strings,
    required SkyCameraMetricsPosition metricsPosition,
  }) async {
    _lastMetricsPosition = metricsPosition;
    return Uint8List.fromList(<int>[1, 2, 3, 4]);
  }
}

class _FakePhotoCropper extends SkyCameraPhotoCropper {
  const _FakePhotoCropper();

  @override
  Future<SkyCameraCapturedPhoto> cropToMediaFormat(
    SkyCameraCapturedPhoto photo,
  ) async {
    return photo;
  }
}

class _FakeObserver implements SkyCameraObserver {
  const _FakeObserver();

  @override
  Future<void> onOpened({required SkyCameraOverlaySnapshot snapshot}) async {}

  @override
  Future<void> onPhotoCaptured({
    required SkyCameraOverlaySnapshot snapshot,
  }) async {}

  @override
  Future<void> onVideoCaptured({
    required SkyCameraOverlaySnapshot snapshot,
    required Duration duration,
  }) async {}
}

SkyCameraOverlaySnapshot _testSnapshot({
  bool hasLiveLocation = true,
  double? latitude = 41.3851,
  double? longitude = 2.1734,
  double? speedMetersPerSecond = 100,
  double? outsideTemperatureCelsius = -52,
  String routeLabel = 'London, UK → Barcelona, ES',
  String originCode = 'LHR',
  String destinationCode = 'BCN',
  String originCountryCode = 'GB',
  String destinationCountryCode = 'ES',
}) {
  return SkyCameraOverlaySnapshot(
    timestamp: DateTime(2026, 6, 29, 12, 0),
    routeLabel: routeLabel,
    originCode: originCode,
    destinationCode: destinationCode,
    originCountryCode: originCountryCode,
    destinationCountryCode: destinationCountryCode,
    contextLabel: 'Mediterranean Sea',
    mapStatePlaceholder: 'Route preview',
    hasLiveLocation: hasLiveLocation,
    latitude: latitude,
    longitude: longitude,
    headingDegrees: 180,
    altitudeMeters: 1000,
    speedMetersPerSecond: speedMetersPerSecond,
    horizontalAccuracyMeters: 12,
    outsideTemperatureCelsius: outsideTemperatureCelsius,
  );
}
