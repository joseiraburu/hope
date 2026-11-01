// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Función que dibuja una imagen completa.
typedef CanvasPainterFn = void Function(Canvas canvas, Size size);

/// Dibuja fuera de pantalla y devuelve la imagen (hay que liberarla).
Future<ui.Image> renderToImage(int width, int height, CanvasPainterFn paint) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
  paint(canvas, Size(width.toDouble(), height.toDouble()));
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(width, height);
  } finally {
    picture.dispose();
  }
}

/// Píxeles RGBA de un dibujo fuera de pantalla.
Future<Uint8List> renderRgba(int width, int height, CanvasPainterFn paint) async {
  final image = await renderToImage(width, height, paint);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } finally {
    image.dispose();
  }
}

/// PNG de un dibujo fuera de pantalla.
Future<Uint8List> renderPng(int width, int height, CanvasPainterFn paint) async {
  final image = await renderToImage(width, height, paint);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } finally {
    image.dispose();
  }
}

/// Deja respirar a la interfaz entre fotogramas largos.
Future<void> yieldToUi() => Future<void>.delayed(Duration.zero);
