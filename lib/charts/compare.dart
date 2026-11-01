// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:math' as math;

import '../models/pain_record.dart';
import 'params.dart';

/// Media, mínimo y máximo de un conjunto de valores.
class Stat {
  const Stat({this.mean, this.min, this.max, this.n = 0});

  final double? mean;
  final double? min;
  final double? max;

  /// Número de valores.
  final int n;

  bool get isEmpty => n == 0;

  static Stat of(Iterable<double?> values) {
    var n = 0;
    var sum = 0.0;
    var lo = double.infinity;
    var hi = double.negativeInfinity;
    for (final v in values) {
      if (v == null) continue;
      n++;
      sum += v;
      lo = math.min(lo, v);
      hi = math.max(hi, v);
    }
    if (n == 0) return const Stat();
    return Stat(mean: sum / n, min: lo, max: hi, n: n);
  }
}

/// Estadísticas de los cuatro parámetros para un grupo de registros.
Map<Param, Stat> statsOf(Iterable<PainRecord> records) {
  final list = records.toList();
  return {
    for (final p in Param.values) p: Stat.of(list.map((r) => paramValue(p, r))),
  };
}

/// Comparación descriptiva antes y después de una fecha (inicio de un
/// tratamiento). No implica que el tratamiento sea la causa del cambio.
class BeforeAfter {
  const BeforeAfter({
    required this.pivot,
    required this.days,
    required this.before,
    required this.after,
    required this.recordsBefore,
    required this.recordsAfter,
  });

  final DateTime pivot;
  final int days;
  final Map<Param, Stat> before;
  final Map<Param, Stat> after;
  final int recordsBefore;
  final int recordsAfter;

  /// Diferencia de medias (después − antes), si hay datos en ambos lados.
  double? change(Param p) {
    final a = before[p]?.mean;
    final b = after[p]?.mean;
    if (a == null || b == null) return null;
    return b - a;
  }
}

/// Medias de los [days] días anteriores a [pivot] y de los [days] posteriores.
BeforeAfter compareAround(List<PainRecord> records, DateTime pivot, int days) {
  final from = pivot.subtract(Duration(days: days));
  final to = pivot.add(Duration(days: days));
  final before = [
    for (final r in records)
      if (!r.dateTime.isBefore(from) && r.dateTime.isBefore(pivot)) r
  ];
  final after = [
    for (final r in records)
      if (!r.dateTime.isBefore(pivot) && r.dateTime.isBefore(to)) r
  ];
  return BeforeAfter(
    pivot: pivot,
    days: days,
    before: statsOf(before),
    after: statsOf(after),
    recordsBefore: before.length,
    recordsAfter: after.length,
  );
}
