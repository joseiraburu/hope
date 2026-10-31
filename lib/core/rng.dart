// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

/// Generador pseudoaleatorio determinista (Mulberry32).
///
/// Con la misma semilla produce siempre la misma secuencia en todas las
/// plataformas, lo que permite repetir exactamente la animación de un
/// registro antiguo.
class Mulberry32 {
  Mulberry32(int seed) : _state = seed & _mask;

  static const int _mask = 0xFFFFFFFF;
  int _state;

  int nextUint32() {
    _state = (_state + 0x6D2B79F5) & _mask;
    var t = _state;
    t = _imul(t ^ (t >>> 15), t | 1);
    t = ((t + _imul(t ^ (t >>> 7), t | 61)) & _mask) ^ t;
    return (t ^ (t >>> 14)) & _mask;
  }

  /// Número en [0, 1).
  double nextDouble() => nextUint32() / 4294967296.0;

  /// Entero en [0, max).
  int nextInt(int max) => max <= 0 ? 0 : nextUint32() % max;

  /// Multiplicación de 32 bits (equivalente a Math.imul).
  static int _imul(int a, int b) {
    final aHi = (a >>> 16) & 0xFFFF;
    final aLo = a & 0xFFFF;
    final bHi = (b >>> 16) & 0xFFFF;
    final bLo = b & 0xFFFF;
    final cross = ((aHi * bLo + aLo * bHi) & 0xFFFF) << 16;
    return (aLo * bLo + cross) & _mask;
  }
}
