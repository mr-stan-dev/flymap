import Flutter
import UIKit

final class NativeCaptureDelegate {
  private let channelName = "app.flymap/native_capture"
  private let methodCaptureRectPng = "captureRectPng"
  private var channel: FlutterMethodChannel?

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
    guard call.method == methodCaptureRectPng else {
      result(FlutterMethodNotImplemented)
      return
    }

    guard
      let args = call.arguments as? [String: Any],
      let left = (args["left"] as? NSNumber)?.doubleValue,
      let top = (args["top"] as? NSNumber)?.doubleValue,
      let width = (args["width"] as? NSNumber)?.doubleValue,
      let height = (args["height"] as? NSNumber)?.doubleValue
    else {
      result(
        FlutterError(
          code: "invalid_args",
          message: "captureRectPng expects left, top, width, height",
          details: nil
        )
      )
      return
    }

    DispatchQueue.main.async {
      guard let targetWindow = self.activeWindow() else {
        result(
          FlutterError(
            code: "no_window",
            message: "Could not find active window for screenshot",
            details: nil
          )
        )
        return
      }

      let requestedRect = CGRect(x: left, y: top, width: width, height: height)
      let clippedRect = requestedRect.intersection(targetWindow.bounds)
      guard clippedRect.width > 0, clippedRect.height > 0 else {
        result(
          FlutterError(
            code: "invalid_rect",
            message: "Requested capture rect is out of bounds",
            details: nil
          )
        )
        return
      }

      let format = UIGraphicsImageRendererFormat.default()
      format.scale = UIScreen.main.scale
      let renderer = UIGraphicsImageRenderer(size: clippedRect.size, format: format)

      let image = renderer.image { context in
        let drawRect = CGRect(
          x: -clippedRect.origin.x,
          y: -clippedRect.origin.y,
          width: targetWindow.bounds.width,
          height: targetWindow.bounds.height
        )
        let drawn = targetWindow.drawHierarchy(in: drawRect, afterScreenUpdates: true)
        if !drawn {
          targetWindow.layer.render(in: context.cgContext)
        }
      }

      guard let pngData = image.pngData() else {
        result(
          FlutterError(
            code: "encode_failed",
            message: "Failed to encode screenshot PNG data",
            details: nil
          )
        )
        return
      }

      result(FlutterStandardTypedData(bytes: pngData))
    }
  }

  private func activeWindow() -> UIWindow? {
    if #available(iOS 13.0, *) {
      let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
      for scene in scenes {
        if let keyWindow = scene.windows.first(where: { $0.isKeyWindow }) {
          return keyWindow
        }
      }
      return scenes.first?.windows.first
    } else {
      return UIApplication.shared.windows.first
    }
  }
}

