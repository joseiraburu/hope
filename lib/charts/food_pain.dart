// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.
//
// Relación en el tiempo entre lo que se comió un día (Día 1) y el dolor de
// ese día y de los tres siguientes (Días 2, 3 y 4). Solo describe: no
// calcula correlaciones ni indica causas.

import '../models/pain_record.dart';

/// Días que se muestran: el de la comida y los tres siguientes.
const int foodPainDays = 4;

/// Días anteriores que forman la media de referencia.
const int baselineDays = 7;

/// El dolor de fondo (0–10) registrado en un día.
class PainDay {
  PainDay({required this.day, required this.records, required this.isFuture});

  /// Medianoche local del día.
  final DateTime day;

  /// Registros del día, del más antiguo al más reciente.
  final List<PainRecord> records;

  /// El día aún no ha llegado.
  final bool isFuture;

  bool get hasData => records.isNotEmpty;

  int get count => records.length;

  int? get max {
    if (records.isEmpty) return null;
    var m = records.first.painIntensity;
    for (final r in records) {
      if (r.painIntensity > m) m = r.painIntensity;
    }
    return m;
  }

  int? get min {
    if (records.isEmpty) return null;
    var m = records.first.painIntensity;
    for (final r in records) {
      if (r.painIntensity < m) m = r.painIntensity;
    }
    return m;
  }

  double? get mean {
    if (records.isEmpty) return null;
    var total = 0;
    for (final r in records) {
      total += r.painIntensity;
    }
    return total / records.length;
  }
}

/// Los cuatro días que siguen a una comida y la media de referencia.
class FoodPainWindow {
  FoodPainWindow({
    required this.foodDay,
    required this.days,
    required this.baseline,
    required this.baselineDaysWithData,
  });

  /// Día de la comida (Día 1).
  final DateTime foodDay;

  /// Día 1 a Día 4.
  final List<PainDay> days;

  /// Media del dolor de fondo de los 7 días anteriores al Día 1: la media de
  /// las medias diarias, para que un día con muchos registros no pese más.
  /// Nula si en esos días no hay registros.
  final double? baseline;

  /// Cuántos de esos 7 días tienen registros.
  final int baselineDaysWithData;

  /// Diferencia entre la media de un día y la de referencia.
  double? deltaFor(PainDay d) {
    final m = d.mean;
    final b = baseline;
    if (m == null || b == null) return null;
    return m - b;
  }
}

DateTime _midnight(DateTime d) {
  final l = d.toLocal();
  return DateTime(l.year, l.month, l.day);
}

/// Registros entre [start] (incluido) y [end] (excluido), por orden de hora.
List<PainRecord> _between(List<PainRecord> records, DateTime start, DateTime end) {
  final out = [
    for (final r in records)
      if (!r.dateTime.isBefore(start) && r.dateTime.isBefore(end)) r
  ];
  out.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  return out;
}

/// Calcula los días 1 a 4 a partir del día de la comida [foodDay].
///
/// Los días se cuentan por fecha de calendario local (de medianoche a
/// medianoche), así que el cambio de mes, de año o de horario no mueve ningún
/// registro de día. [now] permite fijar «hoy» en las pruebas.
FoodPainWindow foodPainWindow(DateTime foodDay, List<PainRecord> records, {DateTime? now}) {
  final d0 = _midnight(foodDay);
  final today = _midnight(now ?? DateTime.now());
  final days = <PainDay>[
    for (var i = 0; i < foodPainDays; i++)
      PainDay(
        day: DateTime(d0.year, d0.month, d0.day + i),
        records: _between(
          records,
          DateTime(d0.year, d0.month, d0.day + i),
          DateTime(d0.year, d0.month, d0.day + i + 1),
        ),
        isFuture: DateTime(d0.year, d0.month, d0.day + i).isAfter(today),
      ),
  ];

  var sum = 0.0;
  var withData = 0;
  for (var i = 1; i <= baselineDays; i++) {
    final day = PainDay(
      day: DateTime(d0.year, d0.month, d0.day - i),
      records: _between(
        records,
        DateTime(d0.year, d0.month, d0.day - i),
        DateTime(d0.year, d0.month, d0.day - i + 1),
      ),
      isFuture: false,
    );
    final m = day.mean;
    if (m != null) {
      sum += m;
      withData++;
    }
  }

  return FoodPainWindow(
    foodDay: d0,
    days: days,
    baseline: withData == 0 ? null : sum / withData,
    baselineDaysWithData: withData,
  );
}
