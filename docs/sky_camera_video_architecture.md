# Sky Camera video architecture

Status: **experimental and disabled for release by default as of 2026-08-16.**

Sky Camera photo capture remains enabled. Video recording can be enabled for
development with:

```bash
fvm flutter run --dart-define=FLYMAP_SKY_CAMERA_VIDEO=true
```

The release default is controlled by
[`FeatureFlags.skyCameraVideoCapture`](../lib/app/feature_flags.dart). No build
configuration currently overrides it. Existing video implementation code is
being retained so the architecture can be evaluated and replaced without
losing the completed playback, telemetry, resource-monitoring, and media-model
work.

## 1. Release decision

Do not expose Sky Camera video recording in the next release.

The current implementation records reliably and previews efficiently, but the
first share of a long branded video requires a full post-recording transcode.
A ten-minute clip can consequently spend minutes in "Preparing video". That is
not acceptable as the first public version of the feature.

The video feature should remain opt-in until either:

1. a share-ready branded file is produced during recording; or
2. a measured alternative makes first-share latency acceptably short across
   the supported device range.

## 2. Current architecture

The current design deliberately separates capture from presentation:

```text
Camera records a clean compressed MP4
              +
Flutter records a 1 Hz GPS/telemetry sidecar
              |
              v
In-app preview plays the clean MP4 and draws the overlay live
              |
              v
First Share renders overlay PNGs and transcodes a branded MP4
              |
              v
The branded rendition is cached; later shares are fast
```

Relevant components:

- [`SkyCameraCaptureCoordinator`](../packages/sky_camera/lib/src/presentation/sky_camera_capture_coordinator.dart)
  stops the native recording and persists the clean file plus telemetry.
- [`FlymapSkyCameraExportService`](../lib/ui/screens/sky_camera/flymap_sky_camera_export_service.dart)
  moves the source MP4 into app storage and saves the 1 Hz track.
- [`MediaVideoPreview`](../lib/ui/screens/home/tabs/media/widgets/media_video_preview.dart)
  draws the Flutter overlay over clean video playback without preparing a
  branded file.
- [`SkyCameraVideoRenditionService`](../lib/ui/screens/sky_camera/sky_camera_video_rendition_service.dart)
  creates the branded rendition lazily on first share.
- [`VideoToolsDelegate.swift`](../ios/Runner/VideoToolsDelegate.swift) and
  [`VideoToolsDelegate.kt`](../android/app/src/main/kotlin/app/flymap/VideoToolsDelegate.kt)
  perform the native iOS and Android overlay transcodes.

This design makes recording stop quickly, preserves an unbranded original, and
allows the in-app overlay to be rebuilt from telemetry. Its cost is deferred to
the exact moment the user asks to share.

## 3. Why a ten-minute first share takes minutes

At the current one-second overlay interval, a ten-minute video creates up to
600 distinct full-resolution transparent PNG files. At 30 fps, the following
native transcode must then decode, composite, and encode approximately 18,000
video frames.

The overlay changes video pixels. A passthrough/remux operation therefore
cannot produce the branded result: every video frame must be processed and a
new compressed video stream must be written. Export time consequently grows
roughly with clip duration.

There is also avoidable work before the unavoidable transcode:

- overlay frames are rasterized sequentially in Dart;
- each full-resolution PNG is written with `flush: true`;
- the brand asset is loaded and decoded for every overlay frame;
- free storage is queried repeatedly during frame generation; and
- the temporary PNG sequence adds substantial file I/O and storage pressure.

The rendition service currently assigns 35% of UI progress to rasterization
and 65% to native transcoding. That split is an implementation estimate, not
production timing telemetry. Stage-level duration, resolution, source fps,
platform, encoder, file size, and thermal-state measurements should be added
before using percentage improvement claims.

Explicitly requesting 30 fps limits the amount of work for devices that might
otherwise record at a higher frame rate, but it does not remove the full-video
transcode.

## 4. Alternatives considered

### A. Optimize the current lazy exporter

Potential improvements include caching the logo, removing per-frame durable
flushes, reducing storage queries, reusing static overlay layers, and replacing
the 600-file intermediary with an in-memory or native timeline renderer.

These changes should shorten preparation and reduce temporary storage, but the
source video still has to be decoded and re-encoded. They cannot guarantee an
almost-instant first share of a ten-minute clip.

### B. Prepare the rendition before Share

A single deduplicated rendition job could start when media preview opens. This
is preferable to starting immediately after recording because Sky Camera now
suspends its camera and camera-GPS sessions while preview is open, leaving more
thermal headroom. The Share action would join the in-flight job and use the
cached result when ready.

This can make sharing *feel* instant when the user watches the preview first,
but an immediate Share tap still waits for the remaining transcode. Running a
video decoder for playback alongside the transcoder also needs thermal and
playback-smoothness testing.

### C. Share the clean video immediately

The original MP4 is already shareable and would open the system share sheet
quickly. It would not contain the Flymap route, telemetry, gradients, or brand,
so this is only viable as an explicit "Share original" product choice. It does
not satisfy the branded-video promise.

### D. Record the branded video directly

This is the recommended direction before video is released publicly.

```text
Camera frames + latest overlay texture (updated about once per second)
                              |
                              v
                    GPU composition
                              |
                              v
                    Hardware video encoder
                              |
                              v
                    Share-ready branded MP4
```

The overlay texture can be reused for every camera frame until the next
telemetry update. Recording stop then needs only normal encoder finalization
and container muxing; sharing uses the stored file directly.

The 1 Hz telemetry sidecar should still be retained for media geolocation,
analytics, diagnostics, and possible future features. Playback must recognize
that the overlay is already embedded and must not draw the Flutter overlay a
second time.

Platform direction:

- **iOS:** custom AVFoundation capture using video/audio sample outputs,
  Core Image or Metal composition, and `AVAssetWriter` hardware encoding.
- **Android:** custom CameraX/OpenGL effect pipeline feeding the video encoder.
  The current Flutter camera package does not expose the required recording
  effect, so a native bridge is required.

## 5. Direct-recording tradeoffs

Advantages:

- first share is near-instant;
- only one final video needs to be retained;
- no temporary overlay-frame directory;
- no post-capture full-video transcode;
- fewer cancellation, low-storage, background-export, and partial-file cases;
  and
- lower total encode/decode work across recording and sharing.

Costs and risks:

- the unbranded original cannot be recovered if only the branded file is
  stored;
- overlay or localization mistakes are permanently baked into a recording;
- capture becomes a custom native subsystem on both platforms;
- GPU composition moves additional work into the recording session; and
- audio sync, frame pacing, orientation, stabilization, lifecycle recovery,
  and device-specific encoder behavior require extensive validation.

Do not encode clean and branded files simultaneously by default. That would
undermine the thermal and storage benefits. If retaining a clean original
becomes a product requirement, treat dual output as a separate, measured
decision.

## 6. Validation gate before re-enabling

The feature should not return to its default-on state until direct branded
recording, or another selected architecture, passes all of the following:

- ten-minute recordings on older and current supported iPhones;
- ten-minute recordings across representative low-, mid-, and high-end Android
  devices;
- stable 30 fps target without unacceptable dropped frames;
- correct audio/video synchronization at the end of a ten-minute clip;
- correct portrait orientation, crop, stabilization, and overlay placement;
- interruption tests for backgrounding, calls, permission changes, and quick
  resume;
- thermal and battery comparison against photo-only preview and the current
  clean-video recorder;
- low-storage handling and recoverable partial-file cleanup;
- immediate playback and native sharing after recording stops; and
- deletion, persistence, migration, and app-restart tests for the final media
  model.

Until that gate is satisfied, release builds remain photo-only and experimental
video work must explicitly set `FLYMAP_SKY_CAMERA_VIDEO=true`.
