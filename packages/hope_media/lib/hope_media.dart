// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('hope_media');

/// Codificación de vídeo MP4 (H.264) con el codificador que ya incluye el
/// sistema: MediaCodec en Android, AVFoundation en iOS y Media Foundation en
/// Windows.
class HopeMedia {
  const HopeMedia._();

  /// ¿Puede este dispositivo crear vídeos MP4?
  static Future<bool> isMp4Supported() async {
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Empieza un vídeo en [path]. Los fotogramas se envían con
  /// [Mp4Encoder.addFrame] en formato RGBA de [width] × [height].
  static Future<Mp4Encoder> startMp4({
    required String path,
    required int width,
    required int height,
    required int fps,
    int bitRate = 2000000,
  }) async {
    await _channel.invokeMethod<void>('start', <String, Object>{
      'path': path,
      'width': width,
      'height': height,
      'fps': fps,
      'bitRate': bitRate,
    });
    return const Mp4Encoder._();
  }

  /// Información de un vídeo leída con el decodificador del sistema: tamaño,
  /// duración, número de fotogramas y color (ARGB) de dos puntos del primer
  /// fotograma, a 1/6 y 5/6 de la altura. Se usa en las pruebas.
  static Future<Map<String, Object?>?> probe(String path) async {
    try {
      final result = await _channel.invokeMapMethod<String, Object?>('probe', {'path': path});
      return result;
    } on MissingPluginException {
      return null;
    }
  }
}

/// Un vídeo en curso.
class Mp4Encoder {
  const Mp4Encoder._();

  /// Añade un fotograma RGBA.
  Future<void> addFrame(Uint8List rgba) =>
      _channel.invokeMethod<void>('addFrame', <String, Object>{'rgba': rgba});

  /// Cierra el archivo.
  Future<void> finish() => _channel.invokeMethod<void>('finish');

  /// Cancela y descarta el vídeo.
  Future<void> cancel() => _channel.invokeMethod<void>('cancel');
}
