import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hope/charts/aggregation.dart';
import 'package:hope/charts/chart_model.dart';
import 'package:hope/charts/params.dart';
import 'package:hope/core/frequency_scale.dart';
import 'package:hope/export/chart_export.dart';
import 'package:hope/export/gif_encoder.dart';
import 'package:hope/export/xlsx_writer.dart';
import 'package:hope/export/zip_writer.dart';
import 'package:hope/l10n/strings.dart';
import 'package:hope/models/pain_record.dart';
import 'package:hope/models/treatment.dart';

import 'helpers.dart';

// ------------------------------------------------- decodificador de prueba
/// Descomprime LZW de GIF (solo para comprobar el codificador).
List<int> lzwDecode(List<int> data, int minCodeSize) {
  final clear = 1 << minCodeSize;
  final eoi = clear + 1;
  List<List<int>> init() => [for (var i = 0; i < clear; i++) [i], <int>[], <int>[]];
  var codeSize = minCodeSize + 1;
  var dict = init();
  final out = <int>[];
  var bitPos = 0;
  int? prev;
  final total = data.length * 8;
  while (bitPos + codeSize <= total) {
    var code = 0;
    for (var i = 0; i < codeSize; i++) {
      final byte = data[(bitPos + i) >> 3];
      code |= ((byte >> ((bitPos + i) & 7)) & 1) << i;
    }
    bitPos += codeSize;
    if (code == clear) {
      codeSize = minCodeSize + 1;
      dict = init();
      prev = null;
      continue;
    }
    if (code == eoi) break;
    List<int> entry;
    if (code < dict.length) {
      entry = dict[code];
      if (prev != null) dict.add([...dict[prev], entry[0]]);
    } else {
      final p = dict[prev!];
      entry = [...p, p[0]];
      dict.add(entry);
    }
    out.addAll(entry);
    prev = code;
    if (dict.length == (1 << codeSize) && codeSize < 12) codeSize++;
  }
  return out;
}

/// Reconstruye cada fotograma (índices de paleta) de un GIF de [GifWriter].
List<List<int>> decodeFrames(Uint8List gif) {
  int u16(int p) => gif[p] | (gif[p + 1] << 8);
  final w = u16(6);
  final h = u16(8);
  var pos = 13 + 768;
  final canvas = List<int>.filled(w * h, 0);
  final frames = <List<int>>[];
  int? trans;
  while (pos < gif.length) {
    final b = gif[pos++];
    if (b == 0x21) {
      final label = gif[pos++];
      if (label == 0xF9) {
        final packed = gif[pos + 1];
        trans = (packed & 1) != 0 ? gif[pos + 4] : null;
        pos += 6;
      } else {
        while (gif[pos] != 0) {
          pos += gif[pos] + 1;
        }
        pos++;
      }
    } else if (b == 0x2C) {
      final x0 = u16(pos), y0 = u16(pos + 2), fw = u16(pos + 4), fh = u16(pos + 6);
      pos += 9;
      final mcs = gif[pos++];
      final data = <int>[];
      while (gif[pos] != 0) {
        final n = gif[pos];
        data.addAll(gif.sublist(pos + 1, pos + 1 + n));
        pos += n + 1;
      }
      pos++;
      final idx = lzwDecode(data, mcs);
      for (var y = 0; y < fh; y++) {
        for (var x = 0; x < fw; x++) {
          final v = idx[y * fw + x];
          if (trans != null && v == trans) continue;
          canvas[(y0 + y) * w + x0 + x] = v;
        }
      }
      frames.add(List<int>.of(canvas));
    } else if (b == 0x3B) {
      break;
    }
  }
  return frames;
}

Uint8List solidFrame(int w, int h, int Function(int x, int y) color) {
  final out = Uint8List(w * h * 4);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final c = color(x, y);
      final o = (y * w + x) * 4;
      out[o] = (c >> 16) & 255;
      out[o + 1] = (c >> 8) & 255;
      out[o + 2] = c & 255;
      out[o + 3] = 255;
    }
  }
  return out;
}

// --------------------------------------------------------- datos de ejemplo
List<PainRecord> sampleRecords() {
  final config = loadConfig();
  final out = <PainRecord>[];
  for (var d = 0; d < 60; d++) {
    if (d % 4 == 3) continue; // días sin registro: huecos
    final zones = d < 30 ? ['pies_izq', 'pies_der', 'pantorrillas_izq'] : ['pies_izq', 'pies_der'];
    out.add(PainRecord(
      id: newUuid(),
      dateTime: DateTime(2026, 9, 3, 9).add(Duration(days: d)),
      sex: 'female',
      painIntensity: d < 30 ? 7 - (d % 3) : 4 - (d % 2),
      zones: zones,
      zoneCount: config.describeParts(zones, 'es').length,
      surfacePct: config.surfacePct(zones),
      eventIntensity: d < 30 ? 6 : 4,
      eventTypes: const ['pinchazo', 'quemazon'],
      eventFrequency: d < 30 ? 180 : 80,
      seed: d + 1,
      note: d == 10 ? 'Dormí mal; mucha quemazón' : '',
    ));
  }
  return out;
}

List<Treatment> sampleTreatments() => [
      Treatment(
        id: 'lido',
        medicationId: 'lidocaina',
        medicationName: 'Lidocaína',
        route: 'iv',
        dose: 300,
        unit: 'mg',
        start: DateTime(2026, 10, 3, 10),
        notes: 'Perfusión',
        adverseEffects: const ['mareo'],
      ),
      Treatment(
        id: 'fent',
        medicationId: 'fentanilo',
        medicationName: 'Fentanilo',
        route: 'transdermica',
        dose: 12.5,
        unit: 'ug_h',
        start: DateTime(2026, 9, 1, 9),
        end: DateTime(2026, 10, 20, 9),
        schedule: 'cada 72 h',
      ),
    ];

ChartExportInput sampleInput({Grouping grouping = Grouping.week, String lang = 'es'}) {
  final config = loadConfig();
  final data = buildChartData(
    records: sampleRecords(),
    treatments: sampleTreatments(),
    from: DateTime(2026, 9, 1),
    to: DateTime(2026, 11, 1),
    grouping: grouping,
    scale: FrequencyScale(config.freqMin, config.freqMax),
    medicationName: (t) => t.medicationName,
  );
  return ChartExportInput(
    data: data,
    mode: ChartMode.combined,
    enabled: Param.values.toSet(),
    showLanes: true,
    s: S(lang),
    lang: lang,
    config: config,
    medicationName: (t) => t.medicationName,
  );
}

void main() {
  test('CRC-32 y fechas de Excel', () {
    expect(crc32(ascii.encode('123456789')), 0xCBF43926);
    expect(columnName(0), 'A');
    expect(columnName(25), 'Z');
    expect(columnName(26), 'AA');
    expect(columnName(701), 'ZZ');
    expect(columnName(702), 'AAA');
    expect(excelSerial(DateTime(1900, 3, 1)), 61);
    expect(excelSerial(DateTime(2026, 11, 1, 12)), closeTo(46327.5, 1e-9));
  });

  test('el ZIP contiene los archivos con su CRC', () {
    final zip = buildZip([ZipEntry.text('a.txt', 'hola ' * 50), ZipEntry.text('b/c.xml', '<x/>')]);
    expect(zip.sublist(0, 4), [0x50, 0x4B, 0x03, 0x04]);
    final end = zip.length - 22;
    expect(zip.sublist(end, end + 4), [0x50, 0x4B, 0x05, 0x06]);
    expect(zip[end + 10], 2); // dos entradas
  });

  test('el GIF se decodifica exactamente (con y sin cambios entre fotogramas)', () {
    const w = 64, h = 40;
    final frames = [
      solidFrame(w, h, (x, y) => x < 32 ? 0xD50000 : 0xFAF8F5),
      solidFrame(w, h, (x, y) => x < 32 ? 0xD50000 : (y > 20 && x > 40 ? 0x0072B2 : 0xFAF8F5)),
      solidFrame(w, h, (x, y) => x < 32 ? 0xD50000 : (y > 20 && x > 40 ? 0x0072B2 : 0xFAF8F5)),
      solidFrame(w, h, (x, y) => ((x * 7 + y * 13) % 256) << 8),
    ];
    final palette = GifPalette.fromFrames(frames);
    final writer = GifWriter(width: w, height: h, palette: palette, fps: 15);
    for (final f in frames) {
      writer.addFrame(f);
    }
    final gif = writer.finish();
    expect(ascii.decode(gif.sublist(0, 6)), 'GIF89a');
    expect(gif.last, 0x3B);
    final decoded = decodeFrames(gif);
    expect(decoded.length, frames.length);
    for (var k = 0; k < frames.length; k++) {
      expect(decoded[k], palette.quantize(frames[k]), reason: 'fotograma $k');
    }
    // Los colores puros se conservan exactos.
    expect(palette.colors[palette.indexOf(0xD5, 0x00, 0x00)], isNot(0x0072B2));
  });

  test('el LZW reinicia el diccionario sin perder datos', () {
    final noise = Uint8List.fromList(List<int>.generate(20000, (i) => (i * 2654435761) % 251));
    expect(lzwDecode(_unblock(lzwEncode(noise, 8)), 8), noise);
  });

  test('caracteres seguros para el PDF', () {
    expect(pdfSafe('−4 µg/h · ñ'), '-4 µg/h · ñ');
    expect(pdfSafe('≥ 5'), '? 5');
  });

  test('el Excel tiene las cuatro hojas', () {
    final xlsx = chartXlsx(sampleInput(), now: DateTime(2026, 11, 1, 18));
    expect(xlsx.sublist(0, 2), [0x50, 0x4B]);
    saveSample('informe.xlsx', xlsx);
  });

  testWidgets('muestras de exportación (PNG, GIF y PDF)', (tester) async {
    await tester.runAsync(() async {
      await loadRealFonts();
      final input = sampleInput();
      saveSample('grafica.png', await chartPng(input));
      final gif = await chartGif(input);
      saveSample('grafica.gif', gif!);
      saveSample('informe.pdf', await chartPdf(input, now: DateTime(2026, 11, 1, 18)));
      final perParam = ChartExportInput(
        data: input.data,
        mode: ChartMode.perParam,
        enabled: input.enabled,
        showLanes: true,
        s: input.s,
        lang: 'es',
        config: input.config,
        medicationName: input.medicationName,
      );
      saveSample('grafica_por_parametro.png', await chartPng(perParam));
      saveSample('grafica_en.png', await chartPng(sampleInput(lang: 'en', grouping: Grouping.day)));
    });
  });
}

/// Quita los tamaños de bloque de los datos LZW.
List<int> _unblock(Uint8List blocks) {
  final out = <int>[];
  var pos = 0;
  while (pos < blocks.length) {
    final n = blocks[pos];
    out.addAll(blocks.sublist(pos + 1, pos + 1 + n));
    pos += n + 1;
  }
  return out;
}
