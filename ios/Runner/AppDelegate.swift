import Flutter
import UIKit
import MapLibre

@main
@objc class AppDelegate: FlutterAppDelegate {
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
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
