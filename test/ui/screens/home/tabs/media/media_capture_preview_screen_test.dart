import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/sky_camera_media_item.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/home/tabs/media/media_capture_preview_screen.dart';
import 'package:sky_camera/sky_camera.dart';

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('shows share in the app bar and delete in the overflow menu', (
    tester,
  ) async {
    final capture = _capture(id: 'capture-1', routeLabel: 'LHR - BCN');
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: MediaCapturePreviewScreen(
            captures: [capture],
            initialCaptureId: capture.id,
            onDelete: (_) async {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('media.capture_preview_filmstrip')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('media.capture_preview_share')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('media.capture_preview_menu')));
    await tester.pumpAndSettle();

    expect(find.text('Share'), findsNothing);
    expect(find.text('Delete file'), findsOneWidget);
  });

  testWidgets('swipes between captures and selects from the filmstrip', (
    tester,
  ) async {
    final first = _capture(id: 'capture-1', routeLabel: 'LHR - BCN');
    final second = _capture(id: 'capture-2', routeLabel: 'BRS - BER');
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: MediaCapturePreviewScreen(
            captures: [first, second],
            initialCaptureId: first.id,
            onDelete: (_) async {},
          ),
        ),
      ),
    );

    expect(find.text('LHR - BCN'), findsOneWidget);
    expect(
      find.byKey(const Key('media.capture_preview_filmstrip')),
      findsOneWidget,
    );

    await tester.flingFrom(const Offset(700, 280), const Offset(-600, 0), 1200);
    await tester.pumpAndSettle();

    expect(find.text('BRS - BER'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('media.capture_preview_thumbnail_capture-1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('LHR - BCN'), findsOneWidget);
  });

  testWidgets('deleting the last page keeps the previous capture visible', (
    tester,
  ) async {
    final first = _capture(id: 'capture-1', routeLabel: 'LHR - BCN');
    final second = _capture(id: 'capture-2', routeLabel: 'BRS - BER');
    String? deletedCaptureId;
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: MediaCapturePreviewScreen(
            captures: [first, second],
            initialCaptureId: second.id,
            onDelete: (captureId) async {
              deletedCaptureId = captureId;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('media.capture_preview_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete file'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(deletedCaptureId, second.id);
    expect(find.text('LHR - BCN'), findsOneWidget);
    expect(
      find.byKey(const Key('media.capture_preview_thumbnail_capture-2')),
      findsNothing,
    );
  });
}

SkyCameraMediaItem _capture({required String id, required String routeLabel}) {
  final capturedAt = DateTime(2026, 7, 3, 12);
  return SkyCameraMediaItem(
    id: id,
    capturedAt: capturedAt,
    mediaType: SkyCameraMediaType.photo,
    sourcePath: '/tmp/original.png',
    snapshot: SkyCameraOverlaySnapshot(
      timestamp: capturedAt,
      routeLabel: routeLabel,
      originCode: '',
      destinationCode: '',
      originCountryCode: 'GB',
      destinationCountryCode: 'ES',
      contextLabel: '',
      mapStatePlaceholder: '',
      hasLiveLocation: false,
      latitude: null,
      longitude: null,
      headingDegrees: null,
      altitudeMeters: null,
      speedMetersPerSecond: null,
    ),
    renditions: const [
      SkyCameraMediaRendition(
        id: 'default',
        skinId: 'flymap_default_v1',
        mediaType: SkyCameraMediaType.photo,
        path: '/tmp/overlay.png',
        previewImagePath: '/tmp/overlay.png',
      ),
    ],
    trackPoints: const [],
    previewImagePath: '/tmp/overlay.png',
    selectedRenditionId: 'default',
  );
}
