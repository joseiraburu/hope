import 'package:flutter_test/flutter_test.dart';
import 'package:hope/charts/aggregation.dart';
import 'package:hope/charts/chart_model.dart';
import 'package:hope/charts/params.dart';
import 'package:hope/core/frequency_scale.dart';
import 'package:hope/models/pain_record.dart';
import 'package:hope/models/treatment.dart';

PainRecord rec(DateTime at, int pain, {double surface = 10, int events = 5, int freq = 100}) => PainRecord(
      id: newUuid(),
      dateTime: at,
      sex: 'female',
      painIntensity: pain,
      zones: const ['pies_izq'],
      surfacePct: surface,
      eventIntensity: events,
      eventTypes: const ['pinchazo'],
      eventFrequency: freq,
      seed: 1,
    );

Treatment tr(String med, DateTime start, {DateTime? end}) => Treatment(
      id: newUuid(),
      medicationId: med,
      medicationName: med,
      route: 'iv',
      dose: 1,
      unit: 'mg',
      start: start,
      end: end,
    );

void main() {
  test('las semanas empiezan en lunes (ISO)', () {
    // 1 de noviembre de 2026 es domingo.
    expect(periodStart(DateTime(2026, 11, 1, 18), Grouping.week), DateTime(2026, 10, 26));
    expect(periodStart(DateTime(2026, 11, 2), Grouping.week), DateTime(2026, 11, 2));
    expect(periodStart(DateTime(2026, 11, 15), Grouping.month), DateTime(2026, 11, 1));
    expect(nextPeriodStart(DateTime(2026, 12, 1), Grouping.month), DateTime(2027, 1, 1));
  });

  test('agrupar es hacer la media, con huecos donde no hay datos', () {
    final records = [
      rec(DateTime(2026, 11, 2, 9), 6), // lunes
      rec(DateTime(2026, 11, 3, 9), 4),
      rec(DateTime(2026, 11, 8, 23), 8), // domingo, misma semana
      rec(DateTime(2026, 11, 16, 9), 2), // la semana del 9 queda vacía
    ];
    final weeks = aggregate(records, DateTime(2026, 11, 2), DateTime(2026, 11, 20), Grouping.week);
    expect(weeks.length, 3);
    expect(weeks[0].count, 3);
    expect(weeks[0].stats[Param.pain]!.mean, 6);
    expect(weeks[0].stats[Param.pain]!.min, 4);
    expect(weeks[0].stats[Param.pain]!.max, 8);
    expect(weeks[1].hasData, isFalse);
    expect(weeks[1].stats[Param.pain]!.mean, isNull);
    expect(weeks[2].stats[Param.pain]!.mean, 2);

    final days = aggregate(records, DateTime(2026, 11, 2), DateTime(2026, 11, 8), Grouping.day);
    expect(days.length, 7);
    expect(days.where((d) => d.hasData).length, 3);

    final months = aggregate(records, DateTime(2026, 10, 1), DateTime(2026, 12, 31), Grouping.month);
    expect(months.length, 3);
    expect(months[0].hasData, isFalse);
    expect(months[1].count, 4);
  });

  test('rangos rápidos de fechas', () {
    final today = DateTime(2026, 11, 1, 18, 30);
    expect(rangeDates(ChartRange.d7, today).from, DateTime(2026, 10, 26));
    expect(rangeDates(ChartRange.d30, today).from, DateTime(2026, 10, 3));
    expect(rangeDates(ChartRange.m3, today).from, DateTime(2026, 8, 2));
    expect(rangeDates(ChartRange.y1, today).from, DateTime(2025, 11, 2));
    expect(rangeDates(ChartRange.d7, today).to, DateTime(2026, 11, 1));
    expect(rangeDates(ChartRange.all, today, earliest: DateTime(2025, 3, 4, 10)).from, DateTime(2025, 3, 4));
  });

  test('escala relativa común (0-100 %)', () {
    const scale = FrequencyScale(10, 500);
    expect(relativeValue(Param.pain, 5, scale), 0.5);
    expect(relativeValue(Param.surface, 25, scale), 0.25);
    expect(relativeValue(Param.eventIntensity, 10, scale), 1.0);
    expect(relativeValue(Param.eventFrequency, 10, scale), 0.0);
    expect(relativeValue(Param.eventFrequency, 500, scale), 1.0);
  });

  test('datos de la gráfica: posición, cursor y tratamientos', () {
    final records = [
      rec(DateTime(2026, 10, 5, 9), 7),
      rec(DateTime(2026, 10, 20, 9), 3),
    ];
    final treatments = [
      tr('lidocaina', DateTime(2026, 10, 12, 10)),
      tr('fentanilo', DateTime(2026, 9, 1), end: DateTime(2026, 10, 15)),
      tr('oxicodona', DateTime(2025, 1, 1), end: DateTime(2025, 2, 1)), // fuera del rango
    ];
    final data = buildChartData(
      records: records,
      treatments: treatments,
      from: DateTime(2026, 10, 1),
      to: DateTime(2026, 10, 31),
      grouping: Grouping.day,
      scale: const FrequencyScale(10, 500),
      medicationName: (t) => t.medicationName,
    );
    expect(data.periods.length, 31);
    expect(data.dataIndices, [4, 19]);
    expect(data.fractionOf(DateTime(2026, 10, 1)), 0);
    expect(data.fractionOf(DateTime(2026, 11, 1)), 1);
    expect(data.nearestDataIndex(0.1), 4);
    expect(data.nearestDataIndex(0.9), 19);
    // Los carriles se ordenan por la fecha del primer tratamiento.
    expect(data.lanes.map((l) => l.medicationId), ['fentanilo', 'lidocaina']);
    expect(data.treatmentsIn(4).map((t) => t.medicationId), ['fentanilo']);
    expect(data.treatmentsIn(11).map((t) => t.medicationId).toSet(), {'fentanilo', 'lidocaina'});
    expect(data.treatmentsIn(19), isEmpty);
  });
}
