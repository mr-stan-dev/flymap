package app.flymap

import android.graphics.Bitmap
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.os.Handler
import android.os.Looper
import android.view.Surface
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.ByteBuffer
import java.util.concurrent.Executors

/**
 * Hardware H.264 encoder fed with raw RGBA frames from Flutter.
 *
 * Frames are drawn onto the MediaCodec input [Surface] via a hardware
 * canvas, so RGBA->YUV conversion happens on the GPU instead of a per-pixel
 * CPU loop (the bottleneck of the previous plugin-based encoder).
 *
 * The input surface stamps buffers with wall-clock time, so presentation
 * timestamps are rewritten on the muxer side from a frame counter to get an
 * exact fps timeline regardless of encoding speed.
 */
class FlightVideoEncoderDelegate {
  companion object {
    private const val channelName = "app.flymap/video_encoder"
    private const val mimeType = "video/avc"
    private const val drainTimeoutUs = 10_000L
  }

  private val executor = Executors.newSingleThreadExecutor()
  private val mainHandler = Handler(Looper.getMainLooper())

  private var codec: MediaCodec? = null
  private var muxer: MediaMuxer? = null
  private var inputSurface: Surface? = null
  private var frameBitmap: Bitmap? = null
  private val bufferInfo = MediaCodec.BufferInfo()
  private var trackIndex = -1
  private var muxerStarted = false
  private var outputFrameCount = 0L
  private var fps = 30
  private var outputPath: String? = null

  fun register(flutterEngine: FlutterEngine) {
    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      channelName,
    ).setMethodCallHandler { call, result ->
      executor.execute {
        try {
          when (call.method) {
            "setup" -> handleSetup(call)
            "appendFrame" -> handleAppendFrame(call)
            "finish" -> handleFinish()
            "abort" -> handleAbort()
            else -> {
              mainHandler.post { result.notImplemented() }
              return@execute
            }
          }
          mainHandler.post { result.success(null) }
        } catch (t: Throwable) {
          releaseQuietly()
          mainHandler.post {
            result.error("encoder_error", "${call.method} failed: ${t.message}", null)
          }
        }
      }
    }
  }

  private fun handleSetup(call: MethodCall) {
    releaseQuietly()

    val args = call.arguments as? Map<*, *> ?: error("setup expects arguments")
    val width = (args["width"] as Number).toInt()
    val height = (args["height"] as Number).toInt()
    fps = (args["fps"] as Number).toInt()
    val bitrate = (args["bitrate"] as Number).toInt()
    val path = args["path"] as String

    File(path).parentFile?.mkdirs()
    File(path).delete()

    val format = MediaFormat.createVideoFormat(mimeType, width, height).apply {
      setInteger(
        MediaFormat.KEY_COLOR_FORMAT,
        MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface,
      )
      setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
      setInteger(MediaFormat.KEY_FRAME_RATE, fps)
      setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
      // No B-frames: output order must match input order because
      // presentation timestamps are rewritten from a frame counter.
      setInteger(MediaFormat.KEY_MAX_B_FRAMES, 0)
    }

    val encoder = MediaCodec.createEncoderByType(mimeType)
    encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
    inputSurface = encoder.createInputSurface()
    encoder.start()

    codec = encoder
    muxer = MediaMuxer(path, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
    frameBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    trackIndex = -1
    muxerStarted = false
    outputFrameCount = 0
    outputPath = path
  }

  private fun handleAppendFrame(call: MethodCall) {
    val rgba = call.arguments as? ByteArray ?: error("appendFrame expects RGBA bytes")
    val bitmap = frameBitmap ?: error("Encoder is not set up")
    val surface = inputSurface ?: error("Encoder is not set up")

    // ARGB_8888 bitmaps store bytes as R,G,B,A in memory, matching rawRgba.
    bitmap.copyPixelsFromBuffer(ByteBuffer.wrap(rgba))
    val canvas = surface.lockHardwareCanvas()
    try {
      canvas.drawBitmap(bitmap, 0f, 0f, null)
    } finally {
      surface.unlockCanvasAndPost(canvas)
    }
    drainEncoder(endOfStream = false)
  }

  private fun handleFinish() {
    val encoder = codec ?: error("Encoder is not set up")
    encoder.signalEndOfInputStream()
    drainEncoder(endOfStream = true)
    releaseQuietly()
  }

  private fun handleAbort() {
    releaseQuietly()
    outputPath?.let { File(it).delete() }
    outputPath = null
  }

  private fun drainEncoder(endOfStream: Boolean) {
    val encoder = codec ?: return
    val mux = muxer ?: return

    while (true) {
      val index = encoder.dequeueOutputBuffer(
        bufferInfo,
        if (endOfStream) drainTimeoutUs else 0,
      )
      when {
        index == MediaCodec.INFO_TRY_AGAIN_LATER -> {
          if (!endOfStream) return
          // Keep draining until the end-of-stream flag arrives.
        }
        index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
          check(!muxerStarted) { "Encoder output format changed twice" }
          trackIndex = mux.addTrack(encoder.outputFormat)
          mux.start()
          muxerStarted = true
        }
        index >= 0 -> {
          val encoded = encoder.getOutputBuffer(index)
            ?: error("Encoder output buffer $index is null")
          if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
            // Codec config is carried in the track format already.
            bufferInfo.size = 0
          }
          if (bufferInfo.size > 0 && muxerStarted) {
            encoded.position(bufferInfo.offset)
            encoded.limit(bufferInfo.offset + bufferInfo.size)
            // Exact fps timeline, independent of encode wall-clock time.
            bufferInfo.presentationTimeUs = outputFrameCount * 1_000_000L / fps
            outputFrameCount++
            mux.writeSampleData(trackIndex, encoded, bufferInfo)
          }
          encoder.releaseOutputBuffer(index, false)
          if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
            return
          }
        }
      }
    }
  }

  private fun releaseQuietly() {
    try {
      codec?.stop()
    } catch (_: Throwable) {
    }
    try {
      codec?.release()
    } catch (_: Throwable) {
    }
    codec = null
    try {
      inputSurface?.release()
    } catch (_: Throwable) {
    }
    inputSurface = null
    try {
      if (muxerStarted) muxer?.stop()
    } catch (_: Throwable) {
    }
    try {
      muxer?.release()
    } catch (_: Throwable) {
    }
    muxer = null
    muxerStarted = false
    frameBitmap?.recycle()
    frameBitmap = null
  }
}
