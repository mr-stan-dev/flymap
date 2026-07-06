package app.flymap

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
  private val nativeCaptureDelegate by lazy { NativeCaptureDelegate(this) }
  private val flightVideoEncoderDelegate by lazy { FlightVideoEncoderDelegate() }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    nativeCaptureDelegate.register(flutterEngine)
    flightVideoEncoderDelegate.register(flutterEngine)
  }
}
