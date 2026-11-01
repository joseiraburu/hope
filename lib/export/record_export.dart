// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:io';
import 'dart:typed_data';

import 'package:hope_media/hope_media.dart';

import 'gif_encoder.dart';
import 'record_card.dart';
import 'render.dart';

/// Imagen de «1 minuto»: todos los eventos de un minuto a la vez.
Future<Uint8List> recordPng(RecordCardInput input, {int width = 1080, int height = 1350}) =>
    renderPng(width, height, (c, size) => paintRecordCard(c, size, input, longExposure: true));

/// GIF animado del bucle de 10 s.
Future<Uint8List?> recordGif(
  RecordCardInput input, {
  int width = 540,
  int height = 676,
  double fps = 15,
  void Function(double progress)? onProgress,
  bool Function()? isCancelled,
}) async {
  final frames = (input.loopSeconds * fps).round();
  // Paleta común a partir de varios momentos del bucle.
  final samples = <Uint8List>[
    for (var k = 0; k < 6; k++)
      await renderRgba(width, height,
          (c, size) => paintRecordCard(c, size, input, t: input.loopSeconds * k / 6 + 0.13)),
  ];
  final palette = GifPalette.fromFrames(samples);
  final writer = GifWriter(width: width, height: height, palette: palette, fps: fps);
  for (var k = 0; k < frames; k++) {
    if (isCancelled?.call() ?? false) return null;
    final rgba = await renderRgba(width, height, (c, size) => paintRecordCard(c, size, input, t: k / fps));
    writer.addFrame(rgba);
    onProgress?.call((k + 1) / frames);
    await yieldToUi();
  }
  return writer.finish();
}

/// Vídeo MP4 (H.264) del bucle repetido, con el codificador del sistema.
///
/// Devuelve false si este dispositivo no puede crear vídeos (entonces se
/// ofrece el GIF) o si se cancela.
Future<bool> recordMp4(
  RecordCardInput input,
  String path, {
  int width = 720,
  int height = 1280,
  int fps = 30,
  double seconds = 20,
  int bitRate = 2000000,
  void Function(double progress)? onProgress,
  bool Function()? isCancelled,
}) async {
  if (!await HopeMedia.isMp4Supported()) return false;
  final frames = (seconds * fps).round();
  Mp4Encoder? encoder;
  // Error del último fotograma enviado (se comprueba antes de seguir).
  Object? failure;
  Future<void>? pending;
  Future<void> waitPending() async {
    if (pending != null) await pending;
    pending = null;
    if (failure != null) throw failure!;
  }

  try {
    encoder = await HopeMedia.startMp4(path: path, width: width, height: height, fps: fps, bitRate: bitRate);
    for (var k = 0; k < frames; k++) {
      if (isCancelled?.call() ?? false) {
        await waitPending();
        await encoder.cancel();
        return false;
      }
      final t = (k / fps) % input.loopSeconds;
      final rgba = await renderRgba(width, height, (c, size) => paintRecordCard(c, size, input, t: t));
      // Mientras se codifica un fotograma se dibuja el siguiente.
      await waitPending();
      pending = encoder.addFrame(rgba).catchError((Object e) {
        failure ??= e;
      });
      onProgress?.call((k + 1) / frames);
    }
    await waitPending();
    await encoder.finish();
    return File(path).existsSync() && File(path).lengthSync() > 0;
  } catch (_) {
    try {
      await encoder?.cancel();
    } catch (_) {}
    return false;
  }
}
