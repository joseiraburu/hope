// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import '../models/pain_record.dart';
import 'compare.dart';
import 'params.dart';

/// Agrupación de los registros en la gráfica.
enum Grouping { day, week, month }

/// Inicio del día (medianoche local).
DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

/// Inicio del periodo que contiene [d]. Las semanas empiezan en lunes (ISO).
DateTime periodStart(DateTime d, Grouping g) => switch (g) {
      Grouping.day => DateTime(d.year, d.month, d.day),
      Grouping.week => DateTime(d.year, d.month, d.day - (d.weekday - 1)),
      Grouping.month => DateTime(d.year, d.month),
    };

/// Inicio del periodo siguiente.
DateTime nextPeriodStart(DateTime start, Grouping g) => switch (g) {
      Grouping.day => DateTime(start.year, start.month, start.day + 1),
      Grouping.week => DateTime(start.year, start.month, start.day + 7),
      Grouping.month => DateTime(start.year, start.month + 1),
    };

/// Un periodo de la gráfica (un día, una semana o un mes) y sus registros.
class Period {
  Period({required this.start, required this.end, required this.records});

  /// Inicio (incluido) y fin (excluido).
  final DateTime start;
  final DateTime end;
  final List<PainRecord> records;

  late final Map<Param, Stat> stats = statsOf(records);

  int get count => records.length;

  bool get hasData => records.isNotEmpty;

  /// Último día del periodo.
  DateTime get lastDay => DateTime(end.year, end.month, end.day - 1);

  DateTime get center => start.add(end.difference(start) ~/ 2);

  /// Registro más reciente del periodo.
  PainRecord? get latest {
    PainRecord? best;
    for (final r in records) {
      if (best == null || r.dateTime.isAfter(best.dateTime)) best = r;
    }
    return best;
  }
}

/// Agrupa los registros entre [from] y [to] (días incluidos).
///
/// Agrupar es calcular la media de cada periodo, no sumar. Los periodos sin
/// registros se devuelven vacíos para dibujarlos como huecos, nunca como cero.
List<Period> aggregate(List<PainRecord> records, DateTime from, DateTime to, Grouping g) {
  final first = startOfDay(from);
  final endExclusive = DateTime(to.year, to.month, to.day + 1);
  if (!first.isBefore(endExclusive)) return const [];
  final inRange = [
    for (final r in records)
      if (!r.dateTime.isBefore(first) && r.dateTime.isBefore(endExclusive)) r
  ]..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  final periods = <Period>[];
  var start = periodStart(first, g);
  var i = 0;
  while (start.isBefore(endExclusive)) {
    final next = nextPeriodStart(start, g);
    final bucket = <PainRecord>[];
    while (i < inRange.length && inRange[i].dateTime.isBefore(next)) {
      bucket.add(inRange[i]);
      i++;
    }
    periods.add(Period(start: start, end: next, records: bucket));
    start = next;
  }
  return periods;
}
