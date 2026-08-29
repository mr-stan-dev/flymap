import Flutter
import FirebaseAppCheck
import UIKit
import MapLibre

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let nativeCaptureDelegate = NativeCaptureDelegate()
  private let flightVideoEncoderDelegate = FlightVideoEncoderDelegate()
  private let videoToolsDelegate = VideoToolsDelegate()
  private let offlineStorageDelegate = OfflineStorageDelegate()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register globally (for non-MapLibre URLSession usage)
    URLProtocol.registerClass(MBTilesURLProtocol.self)

    // Register with MapLibre's own URLSession config — MapLibre does NOT use
    // the shared URLSession, so globally-registered protocols are invisible to it.
    let config = URLSessionConfiguration.default
    config.protocolClasses = [MBTilesURLProtocol.self] + (config.protocolClasses ?? [])
    MLNNetworkConfiguration.sharedManager.sessionConfiguration = config

    GeneratedPluginRegistrant.register(with: self)

    #if !DEBUG
      // FlutterFire installs its provider factory during plugin registration.
      // Override it before Dart initializes Firebase so production never starts
      // with FlutterFire's temporary DeviceCheck default.
      AppCheck.setAppCheckProviderFactory(AppAttestProviderFactory())
    #endif

    if let controller = window?.rootViewController as? FlutterViewController {
      nativeCaptureDelegate.register(with: controller)
      flightVideoEncoderDelegate.register(with: controller)
      videoToolsDelegate.register(with: controller)
      offlineStorageDelegate.register(with: controller)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
