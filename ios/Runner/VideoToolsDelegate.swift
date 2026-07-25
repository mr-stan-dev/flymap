import AVFoundation
import CoreImage
import Flutter
import UIKit

/// Native video toolbox for sky-camera clips: poster frames, stream info and
/// the share-time GPS-overlay burn-in (AVFoundation, hardware codecs).
final class VideoToolsDelegate {
  private let channelName = "app.flymap/video_tools"
  private var channel: FlutterMethodChannel?
  // Export sessions must stay alive until their completion handler runs.
  private var activeExports: [UUID: AVAssetExportSession] = [:]

  func register(with controller: FlutterViewController) {
    let methodChannel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: controller.binaryMessenger
    )
    methodChannel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
    channel = methodChannel
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "extractPoster":
      extractPoster(call: call, result: result)
    case "getVideoInfo":
      getVideoInfo(call: call, result: result)
    case "burnOverlay":
      burnOverlay(call: call, result: result)
    case "cancelBurn":
      cancelBurn(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func extractPoster(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let args = call.arguments as? [String: Any],
      let videoPath = args["videoPath"] as? String
    else {
      result(FlutterError(code: "invalid_args", message: "extractPoster expects videoPath", details: nil))
      return
    }
    let atMs = (args["atMs"] as? NSNumber)?.int64Value ?? 0

    DispatchQueue.global(qos: .userInitiated).async {
      let asset = AVURLAsset(url: URL(fileURLWithPath: videoPath))
      let generator = AVAssetImageGenerator(asset: asset)
      generator.appliesPreferredTrackTransform = true
      generator.requestedTimeToleranceBefore = .zero
      generator.requestedTimeToleranceAfter = CMTime(seconds: 0.5, preferredTimescale: 600)
      do {
        let time = CMTime(value: CMTimeValue(atMs), timescale: 1000)
        let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
        guard let pngData = UIImage(cgImage: cgImage).pngData() else {
          throw NSError(domain: "video_tools", code: 1)
        }
        DispatchQueue.main.async { result(FlutterStandardTypedData(bytes: pngData)) }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "poster_failed", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  private func getVideoInfo(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let args = call.arguments as? [String: Any],
      let videoPath = args["videoPath"] as? String
    else {
      result(FlutterError(code: "invalid_args", message: "getVideoInfo expects videoPath", details: nil))
      return
    }
    let asset = AVURLAsset(url: URL(fileURLWithPath: videoPath))
    guard let track = asset.tracks(withMediaType: .video).first else {
      result(FlutterError(code: "video_info_failed", message: "No video track", details: nil))
      return
    }
    let size = track.naturalSize.applying(track.preferredTransform)
    result([
      "width": Int(abs(size.width).rounded()),
      "height": Int(abs(size.height).rounded()),
      "durationMs": Int(CMTimeGetSeconds(asset.duration) * 1000),
    ])
  }

  private func burnOverlay(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let args = call.arguments as? [String: Any],
      let videoPath = args["videoPath"] as? String,
      let framePaths = args["overlayFramePaths"] as? [String],
      let frameDurationMs = (args["frameDurationMs"] as? NSNumber)?.doubleValue,
      let outputPath = args["outputPath"] as? String,
      !framePaths.isEmpty, frameDurationMs > 0
    else {
      result(
        FlutterError(
          code: "invalid_args",
          message: "burnOverlay expects videoPath, overlayFramePaths, frameDurationMs, outputPath",
          details: nil
        )
      )
      return
    }

    let asset = AVURLAsset(url: URL(fileURLWithPath: videoPath))
    guard asset.tracks(withMediaType: .video).first != nil else {
      result(FlutterError(code: "burn_failed", message: "No video track", details: nil))
      return
    }

    // Streaming compositor: each output frame composites ONE lazily-loaded
    // overlay PNG over the source frame via Core Image. Unlike the previous
    // AVVideoCompositionCoreAnimationTool approach this
    //  - keeps memory flat regardless of clip length (frames load on demand
    //    through a small cache instead of all up-front),
    //  - renders HDR (Dolby Vision) sources correctly — the CA tool
    //    silently produces black frames for 10-bit HDR input,
    //  - also works on the iOS simulator.
    let frameCache = OverlayFrameCache(paths: framePaths)
    let frameSeconds = frameDurationMs / 1000.0
    let videoComposition = AVMutableVideoComposition(asset: asset) { request in
      let seconds = request.compositionTime.seconds
      let index = max(0, min(framePaths.count - 1, Int(seconds / frameSeconds)))
      guard let overlay = frameCache.image(at: index) else {
        request.finish(with: request.sourceImage, context: nil)
        return
      }
      let renderSize = request.renderSize
      let extent = overlay.extent
      var output = request.sourceImage
      if extent.width > 0 && extent.height > 0 {
        let scaled = overlay.transformed(
          by: CGAffineTransform(
            scaleX: renderSize.width / extent.width,
            y: renderSize.height / extent.height
          )
        )
        output = scaled.composited(over: request.sourceImage)
      }
      request.finish(with: output, context: nil)
    }
    // Force an SDR (BT.709) output so HDR sources are tone-mapped instead of
    // exported as black frames.
    videoComposition.colorPrimaries = AVVideoColorPrimaries_ITU_R_709_2
    videoComposition.colorTransferFunction = AVVideoTransferFunction_ITU_R_709_2
    videoComposition.colorYCbCrMatrix = AVVideoYCbCrMatrix_ITU_R_709_2

    try? FileManager.default.removeItem(atPath: outputPath)
    guard
      let exporter = AVAssetExportSession(
        asset: asset,
        presetName: AVAssetExportPresetHighestQuality
      )
    else {
      result(FlutterError(code: "burn_failed", message: "Could not create export session", details: nil))
      return
    }
    exporter.outputURL = URL(fileURLWithPath: outputPath)
    exporter.outputFileType = .mp4
    exporter.videoComposition = videoComposition

    let exportId = UUID()
    activeExports[exportId] = exporter

    // Keep the export alive across brief app backgrounding (long clips take
    // minutes; without this the export dies when the user switches apps).
    var backgroundTask = UIBackgroundTaskIdentifier.invalid
    backgroundTask = UIApplication.shared.beginBackgroundTask {
      UIApplication.shared.endBackgroundTask(backgroundTask)
      backgroundTask = .invalid
    }
    func endBackgroundTask() {
      if backgroundTask != .invalid {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
      }
    }

    // Push 0..1 transcode progress to Dart while the export runs.
    let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) {
      [weak self] _ in
      self?.channel?.invokeMethod(
        "burnProgress",
        arguments: Double(exporter.progress)
      )
    }

    exporter.exportAsynchronously { [weak self] in
      DispatchQueue.main.async {
        progressTimer.invalidate()
        endBackgroundTask()
        self?.activeExports.removeValue(forKey: exportId)
        switch exporter.status {
        case .completed:
          result(nil)
        case .cancelled:
          try? FileManager.default.removeItem(atPath: outputPath)
          result(
            FlutterError(code: "burn_cancelled", message: "Burn cancelled", details: nil)
          )
        default:
          try? FileManager.default.removeItem(atPath: outputPath)
          result(
            FlutterError(
              code: "burn_failed",
              message: exporter.error?.localizedDescription ?? "Export failed",
              details: nil
            )
          )
        }
      }
    }
  }

  /// Cancels every in-flight burn export; their completion handlers report
  /// `burn_cancelled` to the pending Dart calls.
  private func cancelBurn(result: @escaping FlutterResult) {
    for exporter in activeExports.values {
      exporter.cancelExport()
    }
    result(nil)
  }
}

/// Lazily decodes overlay frames, holding only a small sliding window in
/// memory. The CI request handler may be invoked concurrently, hence the
/// lock.
private final class OverlayFrameCache {
  private let paths: [String]
  private var cache: [Int: CIImage] = [:]
  private let lock = NSLock()
  private let maxEntries = 4

  init(paths: [String]) {
    self.paths = paths
  }

  func image(at index: Int) -> CIImage? {
    guard index >= 0 && index < paths.count else { return nil }
    lock.lock()
    defer { lock.unlock() }
    if let cached = cache[index] {
      return cached
    }
    guard let image = CIImage(contentsOf: URL(fileURLWithPath: paths[index])) else {
      return nil
    }
    if cache.count >= maxEntries, let oldest = cache.keys.min() {
      cache.removeValue(forKey: oldest)
    }
    cache[index] = image
    return image
  }
}
