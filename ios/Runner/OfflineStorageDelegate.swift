import Flutter
import Foundation

/// Applies iOS file-system metadata needed by durable, re-downloadable assets.
final class OfflineStorageDelegate {
  private let channelName = "app.flymap/offline_storage"
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
    guard call.method == "excludeFromBackup" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let filePath = call.arguments as? String, !filePath.isEmpty else {
      result(
        FlutterError(
          code: "invalid_args",
          message: "excludeFromBackup expects a file path",
          details: nil
        )
      )
      return
    }

    var fileURL = URL(fileURLWithPath: filePath)
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      result(
        FlutterError(
          code: "file_not_found",
          message: "Cannot exclude a missing file from backup",
          details: filePath
        )
      )
      return
    }

    do {
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      try fileURL.setResourceValues(values)

      let applied = try fileURL.resourceValues(
        forKeys: [.isExcludedFromBackupKey]
      ).isExcludedFromBackup ?? false
      guard applied else {
        throw NSError(
          domain: "app.flymap.offline_storage",
          code: 1,
          userInfo: [NSLocalizedDescriptionKey: "The backup exclusion was not persisted"]
        )
      }
      result(nil)
    } catch {
      result(
        FlutterError(
          code: "backup_exclusion_failed",
          message: error.localizedDescription,
          details: filePath
        )
      )
    }
  }
}
