package app.flymap

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
  private val nativeCaptureDelegate by lazy { NativeCaptureDelegate(this) }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    nativeCaptureDelegate.register(flutterEngine)
  }
}

