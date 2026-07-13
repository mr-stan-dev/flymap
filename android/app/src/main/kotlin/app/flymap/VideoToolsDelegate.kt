package app.flymap

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import androidx.media3.common.Effect
import androidx.media3.common.MediaItem
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.effect.BitmapOverlay
import androidx.media3.effect.OverlayEffect
import androidx.media3.effect.TextureOverlay
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import com.google.common.collect.ImmutableList
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

/**
 * Native video toolbox for sky-camera clips: poster frames, stream info and
 * the share-time GPS-overlay burn-in (Media3 Transformer, hardware codecs).
 */
class VideoToolsDelegate(private val context: Context) {
  companion object {
    private const val channelName = "app.flymap/video_tools"
    private const val progressPollMs = 400L
  }

  // Transformers must stay referenced until their listener fires.
  private val activeTransformers = mutableSetOf<Transformer>()
  private var channel: MethodChannel? = null

  fun register(flutterEngine: FlutterEngine) {
    val methodChannel = MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      channelName,
    )
    methodChannel.setMethodCallHandler { call, result ->
      when (call.method) {
        "extractPoster" -> handleExtractPoster(call, result)
        "getVideoInfo" -> handleGetVideoInfo(call, result)
        "burnOverlay" -> handleBurnOverlay(call, result)
        else -> result.notImplemented()
      }
    }
    channel = methodChannel
  }

  private fun handleExtractPoster(call: MethodCall, result: MethodChannel.Result) {
    val args = call.arguments as? Map<*, *>
    val videoPath = args?.get("videoPath") as? String
    val atMs = (args?.get("atMs") as? Number)?.toLong() ?: 0L
    if (videoPath == null) {
      result.error("invalid_args", "extractPoster expects videoPath", null)
      return
    }
    Thread {
      val retriever = MediaMetadataRetriever()
      try {
        retriever.setDataSource(videoPath)
        val frame = retriever.getFrameAtTime(
          atMs * 1000,
          MediaMetadataRetriever.OPTION_CLOSEST_SYNC,
        )
        if (frame == null) {
          postError(result, "poster_failed", "No frame at ${atMs}ms")
          return@Thread
        }
        val stream = ByteArrayOutputStream()
        frame.compress(Bitmap.CompressFormat.PNG, 100, stream)
        frame.recycle()
        postSuccess(result, stream.toByteArray())
      } catch (error: Exception) {
        postError(result, "poster_failed", error.message)
      } finally {
        retriever.release()
      }
    }.start()
  }

  private fun handleGetVideoInfo(call: MethodCall, result: MethodChannel.Result) {
    val args = call.arguments as? Map<*, *>
    val videoPath = args?.get("videoPath") as? String
    if (videoPath == null) {
      result.error("invalid_args", "getVideoInfo expects videoPath", null)
      return
    }
    val retriever = MediaMetadataRetriever()
    try {
      retriever.setDataSource(videoPath)
      val width = retriever
        .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
        ?.toIntOrNull() ?: 0
      val height = retriever
        .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
        ?.toIntOrNull() ?: 0
      val rotation = retriever
        .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)
        ?.toIntOrNull() ?: 0
      val durationMs = retriever
        .extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
        ?.toLongOrNull() ?: 0L
      val rotated = rotation == 90 || rotation == 270
      result.success(
        mapOf(
          "width" to if (rotated) height else width,
          "height" to if (rotated) width else height,
          "durationMs" to durationMs,
        ),
      )
    } catch (error: Exception) {
      result.error("video_info_failed", error.message, null)
    } finally {
      retriever.release()
    }
  }

  private fun handleBurnOverlay(call: MethodCall, result: MethodChannel.Result) {
    val args = call.arguments as? Map<*, *>
    val videoPath = args?.get("videoPath") as? String
    val framePaths = (args?.get("overlayFramePaths") as? List<*>)
      ?.filterIsInstance<String>()
    val frameDurationMs = (args?.get("frameDurationMs") as? Number)?.toLong()
    val outputPath = args?.get("outputPath") as? String
    if (videoPath == null || framePaths.isNullOrEmpty() ||
      frameDurationMs == null || frameDurationMs <= 0 || outputPath == null
    ) {
      result.error(
        "invalid_args",
        "burnOverlay expects videoPath, overlayFramePaths, frameDurationMs, outputPath",
        null,
      )
      return
    }

    File(outputPath).delete()
    val overlay = TimelineBitmapOverlay(framePaths, frameDurationMs * 1000)
    // Java generics are invariant: the lists must be typed as the supertypes
    // the Media3 constructors declare, not the concrete overlay types.
    val videoEffects = ImmutableList.of<Effect>(
      OverlayEffect(ImmutableList.of<TextureOverlay>(overlay)),
    )
    val editedItem = EditedMediaItem.Builder(MediaItem.fromUri(File(videoPath).toURI().toString()))
      .setEffects(Effects(ImmutableList.of<AudioProcessor>(), videoEffects))
      .build()

    lateinit var transformer: Transformer
    transformer = Transformer.Builder(context)
      .addListener(object : Transformer.Listener {
        override fun onCompleted(composition: Composition, exportResult: ExportResult) {
          overlay.releaseBitmaps()
          activeTransformers.remove(transformer)
          result.success(null)
        }

        override fun onError(
          composition: Composition,
          exportResult: ExportResult,
          exportException: ExportException,
        ) {
          overlay.releaseBitmaps()
          activeTransformers.remove(transformer)
          result.error("burn_failed", exportException.message, null)
        }
      })
      .build()
    activeTransformers.add(transformer)
    try {
      transformer.start(editedItem, outputPath)
      pollBurnProgress(transformer)
    } catch (error: Exception) {
      overlay.releaseBitmaps()
      activeTransformers.remove(transformer)
      result.error("burn_failed", error.message, null)
    }
  }

  /// Pushes 0..1 transcode progress to Dart while [transformer] is active.
  private fun pollBurnProgress(transformer: Transformer) {
    val handler = android.os.Handler(android.os.Looper.getMainLooper())
    val holder = androidx.media3.transformer.ProgressHolder()
    lateinit var poll: Runnable
    poll = Runnable {
      if (!activeTransformers.contains(transformer)) return@Runnable
      val state = transformer.getProgress(holder)
      if (state == Transformer.PROGRESS_STATE_AVAILABLE) {
        channel?.invokeMethod("burnProgress", holder.progress / 100.0)
      }
      handler.postDelayed(poll, progressPollMs)
    }
    handler.postDelayed(poll, progressPollMs)
  }

  private fun postSuccess(result: MethodChannel.Result, value: Any?) {
    android.os.Handler(android.os.Looper.getMainLooper()).post {
      result.success(value)
    }
  }

  private fun postError(result: MethodChannel.Result, code: String, message: String?) {
    android.os.Handler(android.os.Looper.getMainLooper()).post {
      result.error(code, message, null)
    }
  }
}

/**
 * Picks the overlay PNG for each presentation timestamp: frame N covers
 * [N*frameDuration, (N+1)*frameDuration); the last frame covers the tail.
 *
 * Transcode reads timestamps sequentially, so only a small sliding window
 * of decoded bitmaps is kept — memory stays flat regardless of clip length.
 */
private class TimelineBitmapOverlay(
  private val framePaths: List<String>,
  private val frameDurationUs: Long,
) : BitmapOverlay() {
  companion object {
    private const val maxCachedFrames = 4
  }

  private val cache = LinkedHashMap<Int, Bitmap>()

  override fun getBitmap(presentationTimeUs: Long): Bitmap {
    val index = (presentationTimeUs / frameDurationUs)
      .coerceIn(0L, (framePaths.size - 1).toLong())
      .toInt()
    cache[index]?.let { return it }
    val bitmap = BitmapFactory.decodeFile(framePaths[index])
      ?: throw IllegalStateException("Could not decode overlay frame $index")
    cache[index] = bitmap
    while (cache.size > maxCachedFrames) {
      val oldest = cache.keys.first()
      cache.remove(oldest)?.recycle()
    }
    return bitmap
  }

  fun releaseBitmaps() {
    for (bitmap in cache.values) {
      bitmap.recycle()
    }
    cache.clear()
  }
}
