package app.flymap

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
  private val nativeCaptureDelegate by lazy { NativeCaptureDelegate(this) }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    nativeCaptureDelegate.register(flutterEngine)
  }
}
