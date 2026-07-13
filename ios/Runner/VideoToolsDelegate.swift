import AVFoundation
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
    guard let assetVideoTrack = asset.tracks(withMediaType: .video).first else {
      result(FlutterError(code: "burn_failed", message: "No video track", details: nil))
      return
    }

    let composition = AVMutableComposition()
    guard
      let compositionVideoTrack = composition.addMutableTrack(
        withMediaType: .video,
        preferredTrackID: kCMPersistentTrackID_Invalid
      )
    else {
      result(FlutterError(code: "burn_failed", message: "Could not build composition", details: nil))
      return
    }
    let fullRange = CMTimeRange(start: .zero, duration: asset.duration)
    do {
      try compositionVideoTrack.insertTimeRange(fullRange, of: assetVideoTrack, at: .zero)
      if let assetAudioTrack = asset.tracks(withMediaType: .audio).first,
        let compositionAudioTrack = composition.addMutableTrack(
          withMediaType: .audio,
          preferredTrackID: kCMPersistentTrackID_Invalid
        )
      {
        try compositionAudioTrack.insertTimeRange(fullRange, of: assetAudioTrack, at: .zero)
      }
    } catch {
      result(FlutterError(code: "burn_failed", message: error.localizedDescription, details: nil))
      return
    }

    let transformedSize = assetVideoTrack.naturalSize.applying(assetVideoTrack.preferredTransform)
    let renderSize = CGSize(width: abs(transformedSize.width), height: abs(transformedSize.height))

    // Layer tree: the video renders into videoLayer; the overlay layer above
    // it steps through one pre-rendered PNG per second (discrete keyframes).
    let renderFrame = CGRect(origin: .zero, size: renderSize)
    let videoLayer = CALayer()
    videoLayer.frame = renderFrame
    let overlayLayer = CALayer()
    overlayLayer.frame = renderFrame
    overlayLayer.contentsGravity = .resize
    overlayLayer.isGeometryFlipped = true

    var overlayImages: [CGImage] = []
    for path in framePaths {
      guard let image = UIImage(contentsOfFile: path)?.cgImage else {
        result(FlutterError(code: "burn_failed", message: "Could not load overlay frame \(path)", details: nil))
        return
      }
      overlayImages.append(image)
    }

    let durationSeconds = CMTimeGetSeconds(asset.duration)
    if overlayImages.count == 1 {
      overlayLayer.contents = overlayImages[0]
    } else {
      let animation = CAKeyframeAnimation(keyPath: "contents")
      animation.calculationMode = .discrete
      animation.values = overlayImages
      // Discrete mode: keyTimes has one more entry than values; frame N shows
      // for [N, N+1) seconds, the last frame covers the tail.
      var keyTimes: [NSNumber] = []
      let frameSeconds = frameDurationMs / 1000.0
      for index in 0...overlayImages.count {
        let time = min(Double(index) * frameSeconds / durationSeconds, 1.0)
        keyTimes.append(NSNumber(value: time))
      }
      keyTimes[keyTimes.count - 1] = 1.0
      animation.keyTimes = keyTimes
      animation.duration = durationSeconds
      animation.beginTime = AVCoreAnimationBeginTimeAtZero
      animation.isRemovedOnCompletion = false
      animation.fillMode = .forwards
      overlayLayer.add(animation, forKey: "overlayTimeline")
    }

    let parentLayer = CALayer()
    parentLayer.frame = renderFrame
    parentLayer.addSublayer(videoLayer)
    parentLayer.addSublayer(overlayLayer)

    let videoComposition = AVMutableVideoComposition()
    videoComposition.renderSize = renderSize
    videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
    videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
      postProcessingAsVideoLayer: videoLayer,
      in: parentLayer
    )
    let instruction = AVMutableVideoCompositionInstruction()
    instruction.timeRange = fullRange
    let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
    layerInstruction.setTransform(assetVideoTrack.preferredTransform, at: .zero)
    instruction.layerInstructions = [layerInstruction]
    videoComposition.instructions = [instruction]

    try? FileManager.default.removeItem(atPath: outputPath)
    guard
      let exporter = AVAssetExportSession(
        asset: composition,
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
        self?.activeExports.removeValue(forKey: exportId)
        switch exporter.status {
        case .completed:
          result(nil)
        default:
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
}
