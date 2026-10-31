// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:math' as math;

/// Escala logarítmica para la barra de frecuencia (10–500 eventos/min).
///
/// Da más recorrido a los valores bajos, donde las diferencias importan más.
class FrequencyScale {
  const FrequencyScale(this.min, this.max);

  final int min;
  final int max;

  /// Posición de la barra (0–1) → eventos por minuto.
  int fromPosition(double position) {
    final p = math.max(0.0, math.min(1.0, position));
    final value = (min * math.pow(max / min, p)).round();
    return math.max(min, math.min(max, value));
  }

  /// Eventos por minuto → posición de la barra (0–1).
  double toPosition(int frequency) {
    final f = math.max(min, math.min(max, frequency));
    final p = math.log(f / min) / math.log(max / min);
    return math.max(0.0, math.min(1.0, p));
  }
}
