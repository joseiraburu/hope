// Compartir un registro: imagen de 1 minuto, GIF del bucle y vídeo.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:hope/export/record_card.dart';
import 'package:hope/export/record_export.dart';
import 'package:hope/l10n/strings.dart';
import 'package:hope/models/pain_record.dart';

import 'helpers.dart';

PainRecord _record({int freq = 120, int events = 7, String sex = 'female'}) {
  final config = loadConfig();
  const zones = ['pies_izq', 'pies_der', 'pantorrillas_izq', 'manos_der', 'cuello_detras'];
  return PainRecord(
    id: 'registro-prueba',
    dateTime: DateTime(2026, 11, 1, 14, 24),
    sex: sex,
    painIntensity: 6,
    zones: zones,
    zoneCount: config.describeParts(zones, 'es').length,
    surfacePct: config.surfacePct(zones),
    eventIntensity: events,
    eventTypes: const ['pinchazo', 'quemazon', 'punzada'],
    eventFrequency: freq,
    seed: 4242,
  );
}

RecordCardInput _input({PainRecord? record, bool hideDate = false, String lang = 'es'}) =>
    RecordCardInput(
      record: record ?? _record(),
      config: loadConfig(),
      geometry: loadGeometry(),
      s: S(lang),
      lang: lang,
      hideDate: hideDate,
    );

Future<(int, int)> _pngSize(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  final frame = await codec.getNextFrame();
  final size = (frame.image.width, frame.image.height);
  frame.image.dispose();
  codec.dispose();
  return size;
}

/// Número de fotogramas de un GIF (descriptores de imagen).
int _gifFrames(Uint8List gif) {
  var pos = 13 + 768; // cabecera + paleta global
  var frames = 0;
  while (pos < gif.length) {
    final b = gif[pos++];
    if (b == 0x3B) break;
    if (b == 0x21) {
      pos++; // etiqueta
      while (gif[pos] != 0) {
        pos += gif[pos] + 1;
      }
      pos++;
    } else if (b == 0x2C) {
      frames++;
      final packed = gif[pos + 8];
      pos += 9;
      if ((packed & 0x80) != 0) pos += 3 * (1 << ((packed & 7) + 1));
      pos++; // tamaño mínimo del código LZW
      while (gif[pos] != 0) {
        pos += gif[pos] + 1;
      }
      pos++;
    } else {
      fail('byte inesperado $b en $pos');
    }
  }
  return frames;
}

void main() {
  test('la imagen de 1 minuto tiene exactamente los eventos de un minuto', () {
    for (final freq in [10, 120, 500]) {
      final input = _input(record: _record(freq: freq));
      expect(input.minute.sparks.length, freq, reason: 'frecuencia $freq/min');
      expect(input.minute.loopSeconds, 60);
      expect(input.scene.loopSeconds, 10);
    }
  });

  test('nombre de archivo del registro', () {
    expect(_input().baseName, 'HOPE_registro_2026-11-01_1424');
  });

  testWidgets('el vídeo se descarta si no hay codificador (en las pruebas no lo hay)', (tester) async {
    await tester.runAsync(() async {
      final dir = Directory.systemTemp.createTempSync('hope_mp4');
      final ok = await recordMp4(_input(), '${dir.path}/registro.mp4', seconds: 1);
      expect(ok, isFalse);
      dir.deleteSync(recursive: true);
    });
  });

  testWidgets('muestras del registro (PNG de 1 minuto y GIF)', (tester) async {
    await tester.runAsync(() async {
      await loadRealFonts();
      final input = _input();
      final png = await recordPng(input);
      expect(await _pngSize(png), (1080, 1350));
      saveSample('registro_1min.png', png);

      final hidden = await recordPng(_input(hideDate: true));
      expect(hidden, isNot(equals(png)), reason: 'ocultar la fecha cambia la imagen');
      saveSample('registro_1min_sin_fecha.png', hidden);

      final english = await recordPng(_input(lang: 'en', record: _record(sex: 'male', freq: 40)));
      saveSample('registro_1min_en.png', english);

      final noEvents = await recordPng(_input(record: _record(events: 0)));
      saveSample('registro_sin_eventos.png', noEvents);

      var last = 0.0;
      final gif = await recordGif(input, onProgress: (p) => last = p);
      expect(gif, isNotNull);
      expect(last, 1.0);
      expect(String.fromCharCodes(gif!.sublist(0, 6)), 'GIF89a');
      expect(_gifFrames(gif), 150);
      saveSample('registro.gif', gif);

      var calls = 0;
      final cancelled = await recordGif(input, isCancelled: () => ++calls > 3);
      expect(cancelled, isNull);
    });
  });
}
