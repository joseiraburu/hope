// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.
//
// Codificador de GIF animado en Dart puro.
//
// - Una paleta común para todos los fotogramas (corte por la mediana), así
//   los colores no parpadean de un fotograma a otro.
// - Solo se guarda la zona que cambia respecto al fotograma anterior; los
//   píxeles que no cambian se marcan como transparentes. Así el archivo
//   pesa poco aunque la animación dure 10 segundos.
// - Compresión LZW clásica de GIF (algoritmo de Welch, implementación de
//   Poskanzer y Weiner).

import 'dart:typed_data';

/// Índice reservado para los píxeles transparentes.
const int kTransparentIndex = 255;

/// Paleta de hasta 255 colores con búsqueda rápida (colores de 15 bits).
class GifPalette {
  GifPalette._(this.colors, this._lookup);

  /// Colores 0xRRGGBB.
  final List<int> colors;

  /// Color de 15 bits (RGB555) → índice de la paleta; 255 = aún sin calcular.
  final Uint8List _lookup;

  /// Construye la paleta a partir de fotogramas de muestra (RGBA).
  factory GifPalette.fromFrames(List<Uint8List> rgbaFrames, {int maxColors = 255}) {
    final hist = Int32List(32768);
    for (final f in rgbaFrames) {
      final pixels = f.length ~/ 4;
      final step = pixels > 400000 ? 3 : (pixels > 150000 ? 2 : 1);
      for (var p = 0; p < pixels; p += step) {
        final o = p * 4;
        hist[_key(f[o], f[o + 1], f[o + 2])]++;
      }
    }
    final bins = <int>[for (var k = 0; k < 32768; k++) if (hist[k] > 0) k];
    if (bins.isEmpty) bins.add(0);
    final boxes = <_Box>[_Box(bins, hist)];
    while (boxes.length < maxColors) {
      _Box? target;
      for (final b in boxes) {
        if (b.bins.length < 2) continue;
        if (target == null || b.score > target.score) target = b;
      }
      if (target == null) break;
      final split = target.split(hist);
      if (split == null) break;
      boxes.remove(target);
      boxes.addAll(split);
    }
    final lookup = Uint8List(32768)..fillRange(0, 32768, kTransparentIndex);
    final colors = <int>[];
    for (var i = 0; i < boxes.length; i++) {
      colors.add(boxes[i].averageColor(hist));
      for (final k in boxes[i].bins) {
        lookup[k] = i;
      }
    }
    return GifPalette._(colors, lookup);
  }

  static int _key(int r, int g, int b) => ((r >> 3) << 10) | ((g >> 3) << 5) | (b >> 3);

  /// Índice del color más parecido.
  int indexOf(int r, int g, int b) {
    final k = _key(r, g, b);
    final cached = _lookup[k];
    if (cached != kTransparentIndex) return cached;
    final rr = ((k >> 10) & 31) << 3 | 4;
    final gg = ((k >> 5) & 31) << 3 | 4;
    final bb = (k & 31) << 3 | 4;
    var best = 0;
    var bestD = 1 << 30;
    for (var i = 0; i < colors.length; i++) {
      final c = colors[i];
      final dr = ((c >> 16) & 255) - rr;
      final dg = ((c >> 8) & 255) - gg;
      final db = (c & 255) - bb;
      final d = 2 * dr * dr + 4 * dg * dg + 3 * db * db;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    _lookup[k] = best;
    return best;
  }

  /// Convierte un fotograma RGBA en índices de la paleta.
  Uint8List quantize(Uint8List rgba) {
    final n = rgba.length ~/ 4;
    final out = Uint8List(n);
    for (var p = 0; p < n; p++) {
      final o = p * 4;
      out[p] = indexOf(rgba[o], rgba[o + 1], rgba[o + 2]);
    }
    return out;
  }
}

class _Box {
  _Box(this.bins, Int32List hist) {
    var rLo = 31, rHi = 0, gLo = 31, gHi = 0, bLo = 31, bHi = 0;
    for (final k in bins) {
      final r = (k >> 10) & 31, g = (k >> 5) & 31, b = k & 31;
      if (r < rLo) rLo = r;
      if (r > rHi) rHi = r;
      if (g < gLo) gLo = g;
      if (g > gHi) gHi = g;
      if (b < bLo) bLo = b;
      if (b > bHi) bHi = b;
      count += hist[k];
    }
    rRange = rHi - rLo;
    gRange = gHi - gLo;
    bRange = bHi - bLo;
  }

  final List<int> bins;
  int count = 0;
  late final int rRange;
  late final int gRange;
  late final int bRange;

  int get maxRange => [rRange, gRange, bRange].reduce((a, b) => a > b ? a : b);

  /// Prioridad para dividir: cajas grandes y con muchos píxeles.
  double get score => (maxRange + 1) * (count.toDouble() + 1);

  List<_Box>? split(Int32List hist) {
    final int shift;
    if (rRange >= gRange && rRange >= bRange) {
      shift = 10;
    } else if (gRange >= bRange) {
      shift = 5;
    } else {
      shift = 0;
    }
    final sorted = [...bins]..sort((a, b) => ((a >> shift) & 31).compareTo((b >> shift) & 31));
    final half = count / 2;
    var acc = 0;
    var cut = 1;
    for (var i = 0; i < sorted.length - 1; i++) {
      acc += hist[sorted[i]];
      if (acc >= half) {
        cut = i + 1;
        break;
      }
      cut = i + 1;
    }
    if (cut <= 0 || cut >= sorted.length) return null;
    return [_Box(sorted.sublist(0, cut), hist), _Box(sorted.sublist(cut), hist)];
  }

  int averageColor(Int32List hist) {
    var r = 0.0, g = 0.0, b = 0.0, n = 0.0;
    for (final k in bins) {
      final w = hist[k].toDouble();
      r += (((k >> 10) & 31) << 3 | 4) * w;
      g += (((k >> 5) & 31) << 3 | 4) * w;
      b += ((k & 31) << 3 | 4) * w;
      n += w;
    }
    if (n == 0) return 0;
    int c(double v) => (v / n).round().clamp(0, 255).toInt();
    return (c(r) << 16) | (c(g) << 8) | c(b);
  }
}

/// Escribe un GIF animado fotograma a fotograma.
class GifWriter {
  GifWriter({
    required this.width,
    required this.height,
    required this.palette,
    required this.fps,
  }) {
    _header();
  }

  final int width;
  final int height;
  final GifPalette palette;
  final double fps;

  final BytesBuilder _out = BytesBuilder(copy: false);
  Uint8List? _previous;
  int _frame = 0;

  int get frameCount => _frame;

  void _u16(int v) {
    _out.addByte(v & 0xff);
    _out.addByte((v >> 8) & 0xff);
  }

  void _header() {
    _out.add('GIF89a'.codeUnits);
    _u16(width);
    _u16(height);
    _out.addByte(0xF7); // tabla global de 256 colores
    _out.addByte(0);
    _out.addByte(0);
    for (var i = 0; i < 256; i++) {
      final c = i < palette.colors.length ? palette.colors[i] : 0;
      _out.addByte((c >> 16) & 255);
      _out.addByte((c >> 8) & 255);
      _out.addByte(c & 255);
    }
    // Repetir sin fin.
    _out.add(const [0x21, 0xFF, 0x0B]);
    _out.add('NETSCAPE2.0'.codeUnits);
    _out.add(const [0x03, 0x01, 0x00, 0x00, 0x00]);
  }

  /// Retardo en centésimas para el fotograma [k], repartido para que la
  /// duración total sea exacta (p. ej. 7, 7, 6... a 15 fps).
  int _delayFor(int k) =>
      (((k + 1) * 100 / fps).round() - (k * 100 / fps).round()).clamp(2, 65535).toInt();

  /// Añade un fotograma RGBA de [width] × [height].
  void addFrame(Uint8List rgba) {
    final indices = palette.quantize(rgba);
    final prev = _previous;
    var x0 = 0, y0 = 0, x1 = width - 1, y1 = height - 1;
    var transparent = false;
    if (prev != null) {
      x0 = width;
      y0 = height;
      x1 = -1;
      y1 = -1;
      for (var y = 0; y < height; y++) {
        final row = y * width;
        for (var x = 0; x < width; x++) {
          if (indices[row + x] != prev[row + x]) {
            if (x < x0) x0 = x;
            if (x > x1) x1 = x;
            if (y < y0) y0 = y;
            if (y > y1) y1 = y;
          }
        }
      }
      transparent = true;
      if (x1 < 0) {
        // Nada cambia: un píxel transparente mantiene el ritmo.
        x0 = 0;
        y0 = 0;
        x1 = 0;
        y1 = 0;
      }
    }
    final w = x1 - x0 + 1;
    final h = y1 - y0 + 1;
    final sub = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      final src = (y0 + y) * width + x0;
      for (var x = 0; x < w; x++) {
        final v = indices[src + x];
        sub[y * w + x] = transparent && prev![src + x] == v ? kTransparentIndex : v;
      }
    }
    // Extensión de control: no borrar el fotograma anterior (disposal 1).
    _out.add(const [0x21, 0xF9, 0x04]);
    _out.addByte(transparent ? 0x05 : 0x04);
    _u16(_delayFor(_frame));
    _out.addByte(kTransparentIndex);
    _out.addByte(0);
    // Descriptor de la imagen.
    _out.addByte(0x2C);
    _u16(x0);
    _u16(y0);
    _u16(w);
    _u16(h);
    _out.addByte(0);
    _out.addByte(8);
    _out.add(lzwEncode(sub, 8));
    _out.addByte(0);
    _previous = indices;
    _frame++;
  }

  /// Cierra el archivo y devuelve sus bytes.
  Uint8List finish() {
    _out.addByte(0x3B);
    return _out.takeBytes();
  }
}

const List<int> _masks = [
  0x0000, 0x0001, 0x0003, 0x0007, 0x000F, 0x001F, 0x003F, 0x007F, 0x00FF, //
  0x01FF, 0x03FF, 0x07FF, 0x0FFF, 0x1FFF, 0x3FFF, 0x7FFF, 0xFFFF,
];

/// Comprime índices de color con LZW de GIF y los devuelve en bloques de
/// hasta 255 bytes (sin el tamaño de código inicial ni el terminador).
Uint8List lzwEncode(Uint8List pixels, int initCodeSize) {
  const bits = 12;
  const hsize = 5003;
  const maxMaxCode = 1 << bits;
  final out = BytesBuilder(copy: true);
  final accum = Uint8List(256);
  var aCount = 0;
  var curAccum = 0;
  var curBits = 0;
  final htab = Int32List(hsize)..fillRange(0, hsize, -1);
  final codetab = Int32List(hsize);
  final gInitBits = initCodeSize + 1;
  var nBits = gInitBits;
  var maxCode = (1 << nBits) - 1;
  final clearCode = 1 << initCodeSize;
  final eofCode = clearCode + 1;
  var freeEnt = clearCode + 2;
  var clearFlg = false;

  void flush() {
    if (aCount > 0) {
      out.addByte(aCount);
      out.add(Uint8List.sublistView(accum, 0, aCount));
      aCount = 0;
    }
  }

  void charOut(int c) {
    accum[aCount++] = c & 0xff;
    if (aCount >= 254) flush();
  }

  void output(int code) {
    curAccum &= _masks[curBits];
    if (curBits > 0) {
      curAccum |= code << curBits;
    } else {
      curAccum = code;
    }
    curBits += nBits;
    while (curBits >= 8) {
      charOut(curAccum & 0xff);
      curAccum >>= 8;
      curBits -= 8;
    }
    if (freeEnt > maxCode || clearFlg) {
      if (clearFlg) {
        nBits = gInitBits;
        maxCode = (1 << nBits) - 1;
        clearFlg = false;
      } else {
        nBits++;
        maxCode = nBits == bits ? maxMaxCode : (1 << nBits) - 1;
      }
    }
    if (code == eofCode) {
      while (curBits > 0) {
        charOut(curAccum & 0xff);
        curAccum >>= 8;
        curBits -= 8;
      }
      flush();
    }
  }

  var hshift = 0;
  for (var f = hsize; f < 65536; f *= 2) {
    hshift++;
  }
  hshift = 8 - hshift;

  output(clearCode);
  if (pixels.isEmpty) {
    output(eofCode);
    return out.takeBytes();
  }
  var ent = pixels[0];
  outer:
  for (var i = 1; i < pixels.length; i++) {
    final c = pixels[i];
    final fcode = (c << bits) + ent;
    var h = (c << hshift) ^ ent;
    if (htab[h] == fcode) {
      ent = codetab[h];
      continue;
    }
    if (htab[h] >= 0) {
      var disp = hsize - h;
      if (h == 0) disp = 1;
      do {
        h -= disp;
        if (h < 0) h += hsize;
        if (htab[h] == fcode) {
          ent = codetab[h];
          continue outer;
        }
      } while (htab[h] >= 0);
    }
    output(ent);
    ent = c;
    if (freeEnt < maxMaxCode) {
      codetab[h] = freeEnt++;
      htab[h] = fcode;
    } else {
      htab.fillRange(0, hsize, -1);
      freeEnt = clearCode + 2;
      clearFlg = true;
      output(clearCode);
    }
  }
  output(ent);
  output(eofCode);
  return out.takeBytes();
}
