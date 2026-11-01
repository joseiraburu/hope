// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

package io.github.joseiraburu.hope_media

import android.graphics.Bitmap
import android.media.Image
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.media.MediaMuxer
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Codifica vídeos MP4 (H.264) con MediaCodec, el codificador que incluye
 * Android. Todo el trabajo se hace en un hilo propio para no bloquear la app.
 */
class HopeMediaPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private var worker: HandlerThread? = null
    private var workerHandler: Handler? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var encoder: Mp4Encoder? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val thread = HandlerThread("hope_media").also { it.start() }
        worker = thread
        workerHandler = Handler(thread.looper)
        channel = MethodChannel(binding.binaryMessenger, "hope_media").also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        workerHandler?.post {
            encoder?.release()
            encoder = null
        }
        worker?.quitSafely()
        worker = null
        workerHandler = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> runAsync(result) { Mp4Encoder.isSupported() }
            "start" -> {
                val path = call.argument<String>("path")
                val width = call.argument<Int>("width") ?: 720
                val height = call.argument<Int>("height") ?: 1280
                val fps = call.argument<Int>("fps") ?: 30
                val bitRate = call.argument<Int>("bitRate") ?: 2_000_000
                if (path == null) {
                    result.error("hope_media", "Falta la ruta del vídeo", null)
                    return
                }
                runAsync(result) {
                    encoder?.release()
                    encoder = null
                    val e = Mp4Encoder(path, width, height, fps, bitRate)
                    try {
                        e.start()
                    } catch (t: Throwable) {
                        e.release()
                        throw t
                    }
                    encoder = e
                    null
                }
            }
            "addFrame" -> {
                val rgba = call.argument<ByteArray>("rgba")
                if (rgba == null) {
                    result.error("hope_media", "Falta el fotograma", null)
                    return
                }
                runAsync(result) {
                    val e = encoder ?: throw IllegalStateException("El vídeo no se ha iniciado")
                    try {
                        e.addFrame(rgba)
                    } catch (t: Throwable) {
                        e.release()
                        encoder = null
                        throw t
                    }
                    null
                }
            }
            "finish" -> runAsync(result) {
                val e = encoder ?: throw IllegalStateException("El vídeo no se ha iniciado")
                encoder = null
                e.finish()
                null
            }
            "cancel" -> runAsync(result) {
                encoder?.let {
                    it.release()
                    File(it.path).delete()
                }
                encoder = null
                null
            }
            "probe" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("hope_media", "Falta la ruta", null)
                    return
                }
                runAsync(result) { Mp4Encoder.probe(path) }
            }
            else -> result.notImplemented()
        }
    }

    private fun runAsync(result: MethodChannel.Result, block: () -> Any?) {
        val handler = workerHandler
        if (handler == null) {
            result.error("hope_media", "El plugin no está listo", null)
            return
        }
        handler.post {
            try {
                val value = block()
                mainHandler.post { result.success(value) }
            } catch (t: Throwable) {
                mainHandler.post { result.error("hope_media", t.message ?: t.toString(), null) }
            }
        }
    }
}

/** Escribe un MP4 a partir de fotogramas RGBA. */
class Mp4Encoder(
    val path: String,
    private val width: Int,
    private val height: Int,
    private val fps: Int,
    private val bitRate: Int,
) {
    private var codec: MediaCodec? = null
    private var muxer: MediaMuxer? = null
    private var track = -1
    private var muxerStarted = false
    private var frameIndex = 0L
    private val info = MediaCodec.BufferInfo()

    fun start() {
        require(width % 2 == 0 && height % 2 == 0) { "El tamaño del vídeo debe ser par" }
        val format = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, width, height).apply {
            setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible)
            setInteger(MediaFormat.KEY_BIT_RATE, bitRate)
            setInteger(MediaFormat.KEY_FRAME_RATE, fps)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
            if (Build.VERSION.SDK_INT >= 24) {
                // Se declara el espacio de color usado en fillYuv (BT.709, rango
                // limitado), el que suponen los reproductores para vídeo HD.
                setInteger(MediaFormat.KEY_COLOR_STANDARD, MediaFormat.COLOR_STANDARD_BT709)
                setInteger(MediaFormat.KEY_COLOR_RANGE, MediaFormat.COLOR_RANGE_LIMITED)
                setInteger(MediaFormat.KEY_COLOR_TRANSFER, MediaFormat.COLOR_TRANSFER_SDR_VIDEO)
            }
        }
        val c = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
        codec = c
        c.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        c.start()
        File(path).parentFile?.mkdirs()
        File(path).delete()
        muxer = MediaMuxer(path, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
    }

    fun addFrame(rgba: ByteArray) {
        val c = codec ?: throw IllegalStateException("Codificador cerrado")
        require(rgba.size >= width * height * 4) { "Fotograma incompleto" }
        var index: Int
        var waited = 0
        while (true) {
            index = c.dequeueInputBuffer(10_000)
            if (index >= 0) break
            drain(false)
            waited++
            if (waited > 500) throw IllegalStateException("El codificador no acepta más fotogramas")
        }
        val image = c.getInputImage(index) ?: throw IllegalStateException("Sin imagen de entrada")
        fillYuv(image, rgba)
        val pts = frameIndex * 1_000_000L / fps
        c.queueInputBuffer(index, 0, width * height * 3 / 2, pts, 0)
        frameIndex++
        drain(false)
    }

    fun finish() {
        val c = codec ?: return
        var index: Int
        var waited = 0
        while (true) {
            index = c.dequeueInputBuffer(10_000)
            if (index >= 0) break
            drain(false)
            waited++
            if (waited > 500) break
        }
        if (index >= 0) {
            val pts = frameIndex * 1_000_000L / fps
            c.queueInputBuffer(index, 0, 0, pts, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
            drain(true)
        }
        release()
    }

    fun release() {
        try {
            codec?.stop()
        } catch (ignored: Throwable) {
        }
        try {
            codec?.release()
        } catch (ignored: Throwable) {
        }
        codec = null
        try {
            if (muxerStarted) muxer?.stop()
        } catch (ignored: Throwable) {
        }
        try {
            muxer?.release()
        } catch (ignored: Throwable) {
        }
        muxer = null
        muxerStarted = false
    }

    private fun drain(endOfStream: Boolean) {
        val c = codec ?: return
        var idle = 0
        while (true) {
            val index = c.dequeueOutputBuffer(info, if (endOfStream) 10_000 else 0)
            when {
                index == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                    if (!endOfStream) return
                    idle++
                    if (idle > 300) return
                }
                index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    val m = muxer ?: return
                    if (!muxerStarted) {
                        track = m.addTrack(c.outputFormat)
                        m.start()
                        muxerStarted = true
                    }
                }
                index >= 0 -> {
                    val data = c.getOutputBuffer(index)
                    if ((info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG) != 0) info.size = 0
                    if (data != null && info.size > 0 && muxerStarted) {
                        data.position(info.offset)
                        data.limit(info.offset + info.size)
                        muxer?.writeSampleData(track, data, info)
                    }
                    c.releaseOutputBuffer(index, false)
                    if ((info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) return
                }
                else -> {
                    // Otros avisos del codificador: se ignoran.
                }
            }
        }
    }

    /**
     * Convierte RGBA en YUV 4:2:0 (BT.709, rango limitado) respetando el
     * formato de planos del codificador.
     */
    private fun fillYuv(image: Image, rgba: ByteArray) {
        val planes = image.planes
        val yBuf = planes[0].buffer
        val uBuf = planes[1].buffer
        val vBuf = planes[2].buffer
        val yRow = planes[0].rowStride
        val yPix = planes[0].pixelStride
        val uRow = planes[1].rowStride
        val uPix = planes[1].pixelStride
        val vRow = planes[2].rowStride
        val vPix = planes[2].pixelStride
        val row = ByteArray(width)
        for (j in 0 until height) {
            val base = j * width * 4
            for (i in 0 until width) {
                val p = base + i * 4
                val r = rgba[p].toInt() and 0xFF
                val g = rgba[p + 1].toInt() and 0xFF
                val b = rgba[p + 2].toInt() and 0xFF
                row[i] = (((47 * r + 157 * g + 16 * b + 128) shr 8) + 16).toByte()
            }
            if (yPix == 1) {
                yBuf.position(j * yRow)
                yBuf.put(row, 0, width)
            } else {
                for (i in 0 until width) yBuf.put(j * yRow + i * yPix, row[i])
            }
            if (j % 2 == 0) {
                val cj = j / 2
                var i = 0
                while (i < width) {
                    val p = base + i * 4
                    // Media de los dos píxeles de la fila para suavizar el color.
                    val r = ((rgba[p].toInt() and 0xFF) + (rgba[p + 4].toInt() and 0xFF)) / 2
                    val g = ((rgba[p + 1].toInt() and 0xFF) + (rgba[p + 5].toInt() and 0xFF)) / 2
                    val b = ((rgba[p + 2].toInt() and 0xFF) + (rgba[p + 6].toInt() and 0xFF)) / 2
                    val u = ((-26 * r - 86 * g + 112 * b + 128) shr 8) + 128
                    val v = ((112 * r - 102 * g - 10 * b + 128) shr 8) + 128
                    val ci = i / 2
                    uBuf.put(cj * uRow + ci * uPix, u.coerceIn(0, 255).toByte())
                    vBuf.put(cj * vRow + ci * vPix, v.coerceIn(0, 255).toByte())
                    i += 2
                }
            }
        }
    }

    companion object {
        fun isSupported(): Boolean {
            return try {
                val c = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
                c.release()
                true
            } catch (ignored: Throwable) {
                false
            }
        }

        /** Datos de un vídeo: tamaño, duración y colores de un fotograma. */
        fun probe(path: String): Map<String, Any?> {
            val r = MediaMetadataRetriever()
            try {
                r.setDataSource(path)
                val width = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull()
                val height = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull()
                val duration = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull()
                val frames = if (Build.VERSION.SDK_INT >= 28) {
                    r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_FRAME_COUNT)?.toIntOrNull()
                } else {
                    null
                }
                val frame: Bitmap? = r.getFrameAtTime(0)
                val top = frame?.getPixel(frame.width / 2, frame.height / 6)
                val bottom = frame?.getPixel(frame.width / 2, frame.height * 5 / 6)
                return mapOf(
                    "width" to width,
                    "height" to height,
                    "durationMs" to duration,
                    "frames" to frames,
                    "topColor" to top,
                    "bottomColor" to bottom,
                    "bytes" to File(path).length(),
                )
            } finally {
                r.release()
            }
        }
    }
}
