import AVFoundation
import Accelerate
import Flutter
import UIKit

/// Hardware H.264 encoder fed with raw RGBA frames from Flutter.
///
/// Uses AVAssetWriter with a pixel-buffer adaptor; the RGBA->BGRA channel
/// permutation runs through vImage (SIMD), so per-frame CPU cost stays in
/// the low milliseconds.
final class FlightVideoEncoderDelegate {
  private let channelName = "app.flymap/video_encoder"
  private let queue = DispatchQueue(label: "app.flymap.video-encoder")

  private var writer: AVAssetWriter?
  private var input: AVAssetWriterInput?
  private var adaptor: AVAssetWriterInputPixelBufferAdaptor?
  private var width = 0
  private var height = 0
  private var fps: Int32 = 30
  private var frameIndex: Int64 = 0
  private var outputPath: String?

  func register(with controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "gone", message: "Encoder released", details: nil))
        return
      }
      self.queue.async {
        do {
          switch call.method {
          case "setup":
            try self.handleSetup(call)
          case "appendFrame":
            try self.handleAppendFrame(call)
          case "finish":
            try self.handleFinish()
          case "abort":
            self.handleAbort()
          default:
            DispatchQueue.main.async { result(FlutterMethodNotImplemented) }
            return
          }
          DispatchQueue.main.async { result(nil) }
        } catch {
          self.releaseWriter(cancel: true)
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "encoder_error",
                message: "\(call.method) failed: \(error.localizedDescription)",
                details: nil
              )
            )
          }
        }
      }
    }
  }

  private struct EncoderError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
  }

  private func handleSetup(_ call: FlutterMethodCall) throws {
    releaseWriter(cancel: true)

    guard
      let args = call.arguments as? [String: Any],
      let width = (args["width"] as? NSNumber)?.intValue,
      let height = (args["height"] as? NSNumber)?.intValue,
      let fps = (args["fps"] as? NSNumber)?.int32Value,
      let bitrate = (args["bitrate"] as? NSNumber)?.intValue,
      let path = args["path"] as? String
    else {
      throw EncoderError(message: "setup expects width, height, fps, bitrate, path")
    }

    let url = URL(fileURLWithPath: path)
    try? FileManager.default.removeItem(at: url)

    let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
    let settings: [String: Any] = [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: width,
      AVVideoHeightKey: height,
      AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey: bitrate,
        AVVideoMaxKeyFrameIntervalKey: fps,
      ],
    ]
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
    input.expectsMediaDataInRealTime = false
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(
      assetWriterInput: input,
      sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        kCVPixelBufferWidthKey as String: width,
        kCVPixelBufferHeightKey as String: height,
      ]
    )
    guard writer.canAdd(input) else {
      throw EncoderError(message: "Cannot add video input to writer")
    }
    writer.add(input)
    guard writer.startWriting() else {
      throw EncoderError(message: writer.error?.localizedDescription ?? "startWriting failed")
    }
    writer.startSession(atSourceTime: .zero)

    self.writer = writer
    self.input = input
    self.adaptor = adaptor
    self.width = width
    self.height = height
    self.fps = fps
    self.frameIndex = 0
    self.outputPath = path
  }

  private func handleAppendFrame(_ call: FlutterMethodCall) throws {
    guard
      let writer = writer,
      let input = input,
      let adaptor = adaptor,
      let pool = adaptor.pixelBufferPool
    else {
      throw EncoderError(message: "Encoder is not set up")
    }
    guard let rgba = (call.arguments as? FlutterStandardTypedData)?.data else {
      throw EncoderError(message: "appendFrame expects RGBA bytes")
    }
    guard rgba.count == width * height * 4 else {
      throw EncoderError(message: "Unexpected frame byte length \(rgba.count)")
    }

    var pixelBufferOut: CVPixelBuffer?
    let status = CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBufferOut)
    guard status == kCVReturnSuccess, let pixelBuffer = pixelBufferOut else {
      throw EncoderError(message: "Failed to create pixel buffer (\(status))")
    }

    CVPixelBufferLockBaseAddress(pixelBuffer, [])
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
    guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
      throw EncoderError(message: "Pixel buffer has no base address")
    }

    let destRowBytes = CVPixelBufferGetBytesPerRow(pixelBuffer)
    try rgba.withUnsafeBytes { (rawBuffer: UnsafeRawBufferPointer) in
      guard let srcPointer = rawBuffer.baseAddress else {
        throw EncoderError(message: "Frame buffer is empty")
      }
      var src = vImage_Buffer(
        data: UnsafeMutableRawPointer(mutating: srcPointer),
        height: vImagePixelCount(height),
        width: vImagePixelCount(width),
        rowBytes: width * 4
      )
      var dest = vImage_Buffer(
        data: baseAddress,
        height: vImagePixelCount(height),
        width: vImagePixelCount(width),
        rowBytes: destRowBytes
      )
      // Byte order R,G,B,A -> B,G,R,A.
      let permuteMap: [UInt8] = [2, 1, 0, 3]
      let error = vImagePermuteChannels_ARGB8888(
        &src, &dest, permuteMap, vImage_Flags(kvImageNoFlags)
      )
      guard error == kvImageNoError else {
        throw EncoderError(message: "vImage permute failed (\(error))")
      }
    }

    while !input.isReadyForMoreMediaData {
      if writer.status == .failed {
        throw EncoderError(
          message: writer.error?.localizedDescription ?? "Writer failed"
        )
      }
      usleep(2000)
    }
    let time = CMTime(value: frameIndex, timescale: fps)
    guard adaptor.append(pixelBuffer, withPresentationTime: time) else {
      throw EncoderError(
        message: writer.error?.localizedDescription ?? "append failed"
      )
    }
    frameIndex += 1
  }

  private func handleFinish() throws {
    guard let writer = writer, let input = input else {
      throw EncoderError(message: "Encoder is not set up")
    }
    input.markAsFinished()
    let semaphore = DispatchSemaphore(value: 0)
    writer.finishWriting { semaphore.signal() }
    semaphore.wait()
    let failed = writer.status == .failed
    let message = writer.error?.localizedDescription
    releaseWriter(cancel: false)
    if failed {
      throw EncoderError(message: message ?? "finishWriting failed")
    }
  }

  private func handleAbort() {
    releaseWriter(cancel: true)
    if let path = outputPath {
      try? FileManager.default.removeItem(atPath: path)
    }
    outputPath = nil
  }

  private func releaseWriter(cancel: Bool) {
    if cancel, let writer = writer, writer.status == .writing {
      writer.cancelWriting()
    }
    writer = nil
    input = nil
    adaptor = nil
  }
}
