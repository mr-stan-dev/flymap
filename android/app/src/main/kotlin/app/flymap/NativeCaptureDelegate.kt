package app.flymap

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Rect
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.view.PixelCopy
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import kotlin.math.roundToInt

class NativeCaptureDelegate(private val activity: FlutterActivity) {
  companion object {
    private const val channelName = "app.flymap/native_capture"
    private const val methodCaptureRectPng = "captureRectPng"
  }

  fun register(flutterEngine: FlutterEngine) {
    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      channelName,
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        methodCaptureRectPng -> handleCaptureRectPng(call, result)
        else -> result.notImplemented()
      }
    }
  }

  private fun handleCaptureRectPng(call: MethodCall, result: MethodChannel.Result) {
    val args = call.arguments as? Map<*, *>
    if (args == null) {
      result.error("invalid_args", "Arguments are required", null)
      return
    }

    val leftDp = (args["left"] as? Number)?.toDouble()
    val topDp = (args["top"] as? Number)?.toDouble()
    val widthDp = (args["width"] as? Number)?.toDouble()
    val heightDp = (args["height"] as? Number)?.toDouble()

    if (leftDp == null || topDp == null || widthDp == null || heightDp == null) {
      result.error(
        "invalid_args",
        "captureRectPng expects left, top, width, height",
        null,
      )
      return
    }

    val density = activity.resources.displayMetrics.density
    val leftPx = (leftDp * density).roundToInt()
    val topPx = (topDp * density).roundToInt()
    val widthPx = (widthDp * density).roundToInt()
    val heightPx = (heightDp * density).roundToInt()

    if (widthPx <= 0 || heightPx <= 0) {
      result.error("invalid_size", "Capture width and height must be > 0", null)
      return
    }

    val rootView = activity.window?.decorView ?: run {
      result.error("no_window", "Window is not available", null)
      return
    }

    val bounds = Rect(0, 0, rootView.width, rootView.height)
    if (bounds.width() <= 0 || bounds.height() <= 0) {
      result.error("invalid_view", "Root view is not laid out yet", null)
      return
    }

    val captureRect = Rect(leftPx, topPx, leftPx + widthPx, topPx + heightPx)
    if (!captureRect.intersect(bounds)) {
      result.error("invalid_rect", "Capture rect is out of screen bounds", null)
      return
    }

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      captureWithPixelCopy(captureRect, result)
    } else {
      val bytes = captureByViewDraw(captureRect)
      if (bytes == null) {
        result.error("capture_failed", "Failed to capture view", null)
      } else {
        result.success(bytes)
      }
    }
  }

  private fun captureWithPixelCopy(rect: Rect, result: MethodChannel.Result) {
    val window = activity.window ?: run {
      result.error("no_window", "Window is not available", null)
      return
    }

    val targetBitmap = Bitmap.createBitmap(rect.width(), rect.height(), Bitmap.Config.ARGB_8888)
    val thread = HandlerThread("native-capture").apply { start() }
    val handler = Handler(thread.looper)

    try {
      PixelCopy.request(window, rect, targetBitmap, { copyResult ->
        thread.quitSafely()
        activity.runOnUiThread {
          if (copyResult == PixelCopy.SUCCESS) {
            result.success(bitmapToPng(targetBitmap))
            targetBitmap.recycle()
            return@runOnUiThread
          }

          targetBitmap.recycle()
          val fallbackBytes = captureByViewDraw(rect)
          if (fallbackBytes == null) {
            result.error(
              "capture_failed",
              "PixelCopy failed with code: $copyResult",
              null,
            )
          } else {
            result.success(fallbackBytes)
          }
        }
      }, handler)
    } catch (t: Throwable) {
      thread.quitSafely()
      targetBitmap.recycle()
      val fallbackBytes = captureByViewDraw(rect)
      if (fallbackBytes == null) {
        result.error("capture_failed", "Native capture failed: ${t.message}", null)
      } else {
        result.success(fallbackBytes)
      }
    }
  }

  private fun captureByViewDraw(rect: Rect): ByteArray? {
    val rootView = activity.window?.decorView ?: return null
    val fullWidth = rootView.width
    val fullHeight = rootView.height
    if (fullWidth <= 0 || fullHeight <= 0) return null

    val safeRect = Rect(rect)
    val bounds = Rect(0, 0, fullWidth, fullHeight)
    if (!safeRect.intersect(bounds)) return null

    val fullBitmap = Bitmap.createBitmap(fullWidth, fullHeight, Bitmap.Config.ARGB_8888)
    val fullCanvas = Canvas(fullBitmap)
    rootView.draw(fullCanvas)

    val cropped = Bitmap.createBitmap(
      fullBitmap,
      safeRect.left,
      safeRect.top,
      safeRect.width(),
      safeRect.height(),
    )
    val bytes = bitmapToPng(cropped)
    cropped.recycle()
    fullBitmap.recycle()
    return bytes
  }

  private fun bitmapToPng(bitmap: Bitmap): ByteArray {
    val output = ByteArrayOutputStream()
    bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
    return output.toByteArray()
  }
}

