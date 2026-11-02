// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import Accelerate
import AVFoundation
import CoreMedia
import CoreVideo
import Flutter
import UIKit

/// Codifica vídeos MP4 (H.264) con AVFoundation, el codificador que incluye
/// iOS. Todo el trabajo se hace en una cola propia para no bloquear la app.
public class HopeMediaPlugin: NSObject, FlutterPlugin {
  private let queue = DispatchQueue(label: "hope_media")
  private var encoder: Mp4Encoder?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "hope_media", binaryMessenger: registrar.messenger())
    let instance = HopeMediaPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "isSupported":
      run(result) { Mp4Encoder.isSupported() }
    case "start":
      guard let path = args["path"] as? String else {
        result(FlutterError(code: "hope_media", message: "Falta la ruta del vídeo", details: nil))
        return
      }
      let width = (args["width"] as? NSNumber)?.intValue ?? 720
      let height = (args["height"] as? NSNumber)?.intValue ?? 1280
      let fps = (args["fps"] as? NSNumber)?.intValue ?? 30
      let bitRate = (args["bitRate"] as? NSNumber)?.intValue ?? 2_000_000
      run(result) {
        self.encoder?.cancel()
        self.encoder = nil
        self.encoder = try Mp4Encoder(path: path, width: width, height: height, fps: fps, bitRate: bitRate)
        return nil
      }
    case "addFrame":
      guard let frame = args["rgba"] as? FlutterStandardTypedData else {
        result(FlutterError(code: "hope_media", message: "Falta el fotograma", details: nil))
        return
      }
      run(result) {
        guard let e = self.encoder else { throw HopeMediaError("El vídeo no se ha iniciado") }
        do {
          try e.addFrame(frame.data)
        } catch {
          e.cancel()
          self.encoder = nil
          throw error
        }
        return nil
      }
    case "finish":
      run(result) {
        guard let e = self.encoder else { throw HopeMediaError("El vídeo no se ha iniciado") }
        self.encoder = nil
        try e.finish()
        return nil
      }
    case "cancel":
      run(result) {
        self.encoder?.cancel()
        self.encoder = nil
        return nil
      }
    case "probe":
      guard let path = args["path"] as? String else {
        result(FlutterError(code: "hope_media", message: "Falta la ruta", details: nil))
        return
      }
      run(result) { try Mp4Encoder.probe(path: path) }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Ejecuta [block] en la cola del complemento y devuelve el resultado en
  /// el hilo principal.
  private func run(_ result: @escaping FlutterResult, _ block: @escaping () throws -> Any?) {
    queue.async {
      do {
        let value = try block()
        DispatchQueue.main.async { result(value) }
      } catch {
        let message = String(describing: error)
        DispatchQueue.main.async {
          result(FlutterError(code: "hope_media", message: message, details: nil))
        }
      }
    }
  }
}

struct HopeMediaError: Error, CustomStringConvertible {
  let description: String

  init(_ description: String) {
    self.description = description
  }
}

/// Escribe un MP4 a partir de fotogramas RGBA.
final class Mp4Encoder {
  let path: String
  private let width: Int
  private let height: Int
  private let fps: Int32
  private let writer: AVAssetWriter
  private let input: AVAssetWriterInput
  private let adaptor: AVAssetWriterInputPixelBufferAdaptor
  private var frameIndex: Int64 = 0

  init(path: String, width: Int, height: Int, fps: Int, bitRate: Int) throws {
    guard width > 0, height > 0, width % 2 == 0, height % 2 == 0 else {
      throw HopeMediaError("El tamaño del vídeo debe ser par")
    }
    let url = URL(fileURLWithPath: path)
    try? FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try? FileManager.default.removeItem(at: url)
    let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
    let settings: [String: Any] = [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: width,
      AVVideoHeightKey: height,
      AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey: bitRate,
        AVVideoMaxKeyFrameIntervalKey: max(1, fps),
        AVVideoExpectedSourceFrameRateKey: max(1, fps),
        AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
      ] as [String: Any],
      // El mismo espacio de color que en Android y Windows (BT.709), el que
      // suponen los reproductores para vídeo HD.
      AVVideoColorPropertiesKey: [
        AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
        AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
        AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2,
      ],
    ]
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
    input.expectsMediaDataInRealTime = false
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(
      assetWriterInput: input,
      sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        kCVPixelBufferWidthKey as String: width,
        kCVPixelBufferHeightKey as String: height,
      ])
    guard writer.canAdd(input) else { throw HopeMediaError("No se puede añadir la pista de vídeo") }
    writer.add(input)
    guard writer.startWriting() else {
      throw HopeMediaError(writer.error?.localizedDescription ?? "No se puede escribir el vídeo")
    }
    writer.startSession(atSourceTime: .zero)

    self.path = path
    self.width = width
    self.height = height
    self.fps = Int32(max(1, fps))
    self.writer = writer
    self.input = input
    self.adaptor = adaptor
  }

  func addFrame(_ rgba: Data) throws {
    guard rgba.count >= width * height * 4 else { throw HopeMediaError("Fotograma incompleto") }
    var waited = 0
    while !input.isReadyForMoreMediaData {
      if writer.status == .failed {
        throw HopeMediaError(writer.error?.localizedDescription ?? "Error del codificador")
      }
      Thread.sleep(forTimeInterval: 0.005)
      waited += 1
      if waited > 4000 { throw HopeMediaError("El codificador no acepta más fotogramas") }
    }
    guard let pool = adaptor.pixelBufferPool else {
      throw HopeMediaError(writer.error?.localizedDescription ?? "Sin memoria para el fotograma")
    }
    var created: CVPixelBuffer?
    let status = CVPixelBufferPoolCreatePixelBuffer(nil, pool, &created)
    guard status == kCVReturnSuccess, let buffer = created else {
      throw HopeMediaError("No se pudo crear el fotograma (\(status))")
    }

    // RGBA (lo que dibuja la app) → BGRA (lo que espera el codificador).
    CVPixelBufferLockBaseAddress(buffer, [])
    var copyError: vImage_Error = kvImageNoError
    if let base = CVPixelBufferGetBaseAddress(buffer) {
      let rowBytes = CVPixelBufferGetBytesPerRow(buffer)
      let w = vImagePixelCount(width)
      let h = vImagePixelCount(height)
      copyError = rgba.withUnsafeBytes { (raw: UnsafeRawBufferPointer) -> vImage_Error in
        guard let source = raw.baseAddress else { return kvImageNullPointerArgument }
        var src = vImage_Buffer(
          data: UnsafeMutableRawPointer(mutating: source), height: h, width: w, rowBytes: width * 4)
        var dst = vImage_Buffer(data: base, height: h, width: w, rowBytes: rowBytes)
        let map: [UInt8] = [2, 1, 0, 3]
        return vImagePermuteChannels_ARGB8888(&src, &dst, map, vImage_Flags(kvImageNoFlags))
      }
    } else {
      copyError = kvImageNullPointerArgument
    }
    CVPixelBufferUnlockBaseAddress(buffer, [])
    guard copyError == kvImageNoError else {
      throw HopeMediaError("No se pudo preparar el fotograma (\(copyError))")
    }

    let time = CMTime(value: frameIndex, timescale: fps)
    guard adaptor.append(buffer, withPresentationTime: time) else {
      throw HopeMediaError(writer.error?.localizedDescription ?? "No se pudo añadir el fotograma")
    }
    frameIndex += 1
  }

  func finish() throws {
    input.markAsFinished()
    writer.endSession(atSourceTime: CMTime(value: frameIndex, timescale: fps))
    let done = DispatchSemaphore(value: 0)
    writer.finishWriting { done.signal() }
    if done.wait(timeout: .now() + 120) == .timedOut {
      throw HopeMediaError("El vídeo no termina de escribirse")
    }
    guard writer.status == .completed else {
      throw HopeMediaError(writer.error?.localizedDescription ?? "No se pudo cerrar el vídeo")
    }
  }

  func cancel() {
    if writer.status == .writing { writer.cancelWriting() }
    try? FileManager.default.removeItem(atPath: path)
  }

  /// ¿Puede este dispositivo crear vídeos H.264? (Todos los iPhone y iPad
  /// actuales, y el simulador.)
  static func isSupported() -> Bool {
    let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("hope_media_prueba.mp4")
    try? FileManager.default.removeItem(at: url)
    guard let writer = try? AVAssetWriter(outputURL: url, fileType: .mp4) else { return false }
    return writer.canApply(
      outputSettings: [
        AVVideoCodecKey: AVVideoCodecType.h264,
        AVVideoWidthKey: 720,
        AVVideoHeightKey: 1280,
      ],
      forMediaType: .video)
  }

  /// Datos de un vídeo: tamaño, duración, número de fotogramas y color
  /// (ARGB) de dos puntos del primer fotograma, a 1/6 y 5/6 de la altura.
  static func probe(path: String) throws -> [String: Any] {
    let url = URL(fileURLWithPath: path)
    let asset = AVURLAsset(url: url)
    guard let track = asset.tracks(withMediaType: .video).first else {
      throw HopeMediaError("El archivo no tiene vídeo")
    }
    let size = track.naturalSize.applying(track.preferredTransform)
    let durationMs = Int((CMTimeGetSeconds(asset.duration) * 1000).rounded())

    var frames: Any = NSNull()
    if let reader = try? AVAssetReader(asset: asset) {
      let output = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
      output.alwaysCopiesSampleData = false
      if reader.canAdd(output) {
        reader.add(output)
        if reader.startReading() {
          var count = 0
          while let sample = output.copyNextSampleBuffer() {
            count += CMSampleBufferGetNumSamples(sample)
          }
          if reader.status == .completed { frames = count }
        }
      }
    }

    var top: Any = NSNull()
    var bottom: Any = NSNull()
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.requestedTimeToleranceBefore = .zero
    generator.requestedTimeToleranceAfter = .zero
    if let image = try? generator.copyCGImage(at: .zero, actualTime: nil) {
      if let c = pixel(image, x: image.width / 2, y: image.height / 6) { top = c }
      if let c = pixel(image, x: image.width / 2, y: image.height * 5 / 6) { bottom = c }
    }

    let bytes = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
    return [
      "width": Int(abs(size.width).rounded()),
      "height": Int(abs(size.height).rounded()),
      "durationMs": durationMs,
      "frames": frames,
      "topColor": top,
      "bottomColor": bottom,
      "bytes": bytes,
    ]
  }

  /// Color ARGB del píxel (x, y), contando y desde arriba.
  private static func pixel(_ image: CGImage, x: Int, y: Int) -> Int? {
    var rgba = [UInt8](repeating: 0, count: 4)
    let ok = rgba.withUnsafeMutableBytes { (buffer: UnsafeMutableRawBufferPointer) -> Bool in
      guard
        let context = CGContext(
          data: buffer.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
          space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
      else { return false }
      context.interpolationQuality = .none
      // El origen de Core Graphics está abajo: se desplaza la imagen para
      // que el píxel buscado caiga en el único píxel del contexto.
      context.draw(
        image,
        in: CGRect(
          x: -CGFloat(x), y: -CGFloat(image.height - 1 - y),
          width: CGFloat(image.width), height: CGFloat(image.height)))
      return true
    }
    guard ok else { return nil }
    let r = Int(rgba[0])
    let g = Int(rgba[1])
    let b = Int(rgba[2])
    let a = Int(rgba[3])
    return (a << 24) | (r << 16) | (g << 8) | b
  }
}
