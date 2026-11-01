// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import '../core/frequency_scale.dart';
import '../l10n/strings.dart';
import '../models/pain_record.dart';
import '../models/treatment.dart';
import '../utils/format.dart';
import 'aggregation.dart';

/// Rangos de fechas rápidos.
enum ChartRange { d7, d30, m3, m6, y1, all, custom }

/// Vistas de la pantalla de gráficos.
enum ChartMode { combined, perParam, table }

/// Fechas (días incluidos) de un rango rápido, contando hasta [today].
({DateTime from, DateTime to}) rangeDates(
  ChartRange range,
  DateTime today, {
  DateTime? earliest,
  DateTime? customFrom,
  DateTime? customTo,
}) {
  final t = startOfDay(today);
  DateTime back({int days = 0, int months = 0}) =>
      DateTime(t.year, t.month - months, t.day - days + (months > 0 ? 1 : 0));
  return switch (range) {
    ChartRange.d7 => (from: back(days: 6), to: t),
    ChartRange.d30 => (from: back(days: 29), to: t),
    ChartRange.m3 => (from: back(months: 3), to: t),
    ChartRange.m6 => (from: back(months: 6), to: t),
    ChartRange.y1 => (from: back(months: 12), to: t),
    ChartRange.all => (from: startOfDay(earliest ?? back(days: 29)), to: t),
    ChartRange.custom => (
        from: startOfDay(customFrom ?? back(days: 29)),
        to: startOfDay(customTo ?? t),
      ),
  };
}

/// Franja de un medicamento bajo la gráfica.
class ChartLane {
  ChartLane({required this.medicationId, required this.name, required this.treatments});

  final String medicationId;
  final String name;
  final List<Treatment> treatments;
}

/// Datos listos para dibujar la gráfica.
class ChartData {
  ChartData({
    required this.periods,
    required this.grouping,
    required this.from,
    required this.to,
    required this.lanes,
    required this.scale,
  });

  final List<Period> periods;
  final Grouping grouping;
  final DateTime from;
  final DateTime to;
  final List<ChartLane> lanes;
  final FrequencyScale scale;

  late final List<int> dataIndices = [
    for (var i = 0; i < periods.length; i++)
      if (periods[i].hasData) i
  ];

  bool get isEmpty => dataIndices.isEmpty;

  DateTime get domainStart => periods.isEmpty ? from : periods.first.start;

  DateTime get domainEnd => periods.isEmpty ? to : periods.last.end;

  /// Posición (0–1) de un instante en el eje horizontal.
  double fractionOf(DateTime t) {
    final total = domainEnd.difference(domainStart).inMilliseconds;
    if (total <= 0) return 0;
    final f = t.difference(domainStart).inMilliseconds / total;
    return f.clamp(0.0, 1.0).toDouble();
  }

  double fractionOfPeriod(int i) => fractionOf(periods[i].center);

  /// Periodo con datos más cercano a una posición horizontal (0–1).
  int? nearestDataIndex(double fraction) {
    int? best;
    var bestDist = double.infinity;
    for (final i in dataIndices) {
      final d = (fractionOfPeriod(i) - fraction).abs();
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }

  /// Texto del periodo: «lun 9 nov 2026», «Semana 9 nov – 15 nov 2026»...
  String periodLabel(int i, S s, String lang) {
    final p = periods[i];
    return switch (grouping) {
      Grouping.day => formatDate(p.start, lang),
      Grouping.week => s.weekOf(formatDayRange(p.start, p.lastDay, lang)),
      Grouping.month => formatMonth(p.start, lang),
    };
  }

  /// Tratamientos activos en un periodo.
  List<Treatment> treatmentsIn(int i) {
    final p = periods[i];
    return [
      for (final lane in lanes)
        for (final t in lane.treatments)
          if (t.overlaps(p.start, p.end)) t
    ];
  }
}

/// Prepara los datos de la gráfica.
ChartData buildChartData({
  required List<PainRecord> records,
  required List<Treatment> treatments,
  required DateTime from,
  required DateTime to,
  required Grouping grouping,
  required FrequencyScale scale,
  required String Function(Treatment t) medicationName,
  Set<String>? medicationFilter,
}) {
  final periods = aggregate(records, from, to, grouping);
  final domainStart = periods.isEmpty ? startOfDay(from) : periods.first.start;
  final domainEnd = periods.isEmpty ? DateTime(to.year, to.month, to.day + 1) : periods.last.end;
  final byMed = <String, List<Treatment>>{};
  final names = <String, String>{};
  for (final t in treatments) {
    if (medicationFilter != null && !medicationFilter.contains(t.medicationId)) continue;
    if (!t.overlaps(domainStart, domainEnd)) continue;
    byMed.putIfAbsent(t.medicationId, () => []).add(t);
    names[t.medicationId] = medicationName(t);
  }
  final lanes = [
    for (final e in byMed.entries)
      ChartLane(
        medicationId: e.key,
        name: names[e.key] ?? e.key,
        treatments: e.value..sort((a, b) => a.start.compareTo(b.start)),
      )
  ]..sort((a, b) => a.treatments.first.start.compareTo(b.treatments.first.start));
  return ChartData(
    periods: periods,
    grouping: grouping,
    from: from,
    to: to,
    lanes: lanes,
    scale: scale,
  );
}
