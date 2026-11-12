// Informe completo: datos insuficientes, evolución del dolor, sueño,
// alimentación, relaciones y conclusiones.

import 'package:flutter_test/flutter_test.dart';
import 'package:hope/charts/full_report.dart';
import 'package:hope/charts/full_report_text.dart';
import 'package:hope/export/report_pdf.dart';
import 'package:hope/l10n/strings.dart';
import 'package:hope/models/food.dart';
import 'package:hope/models/pain_record.dart';
import 'package:hope/models/sleep.dart';

import 'helpers.dart';

PainRecord pain(DateTime at, int intensity, {int events = 0, List<String> zones = const ['pies_izq']}) =>
    PainRecord(
      id: newUuid(),
      dateTime: at,
      sex: 'female',
      painIntensity: intensity,
      zones: zones,
      surfacePct: 3.5,
      eventIntensity: events,
      eventTypes: events > 0 ? const ['pinchazo'] : const [],
      eventFrequency: 60,
      seed: 1,
    );

void main() {
  final config = loadConfig();
  const es = S('es');
  String foodName(String id) => config.foodById(id)?.name('es') ?? id;

  ReportWriter writer(FullReport r) =>
      ReportWriter(report: r, s: es, lang: 'es', config: config, foodName: foodName);

  group('datos insuficientes', () {
    final now = DateTime(2026, 11, 14, 12);
    final report = buildFullReport(
      records: [
        pain(DateTime(2026, 11, 12, 9), 5),
        pain(DateTime(2026, 11, 13, 9), 6),
        pain(DateTime(2026, 11, 14, 9), 4),
      ],
      foodDays: [FoodDay.withFoods(DateTime(2026, 11, 13), {MealSlot.lunch: const ['pasta']})],
      sleep: [
        SleepEntry(date: DateTime(2026, 11, 13), quality: 2),
        SleepEntry(date: DateTime(2026, 11, 14), quality: 4),
      ],
      config: config,
      periodDays: 7,
      now: now,
    );

    test('cada apartado sin datos suficientes queda vacío', () {
      expect(report.pain, isNull);
      expect(report.sleep, isNull);
      expect(report.food, isNull);
      expect(report.relations.sleepEnough, isFalse);
      expect(report.relations.foodEnough, isFalse);
      expect(report.allInsufficient, isTrue);
      expect(report.painDays, 3);
      expect(report.sleepNights, 2);
      expect(report.foodDays, 1);
    });

    test('el texto dice «Datos insuficientes» y qué falta', () {
      final w = writer(report);
      expect(w.conclusions(), [es.cInsufficient]);
      final blocks = w.blocks();
      expect(blocks.where((b) => b.insufficient).length, 4);
      expect(blocks[1].missing.single, es.missingPainDays(3, reportMinPainDays));
      expect(blocks[1].missing.single, contains('(hay 3)'));
      expect(blocks[2].missing.single, contains('5 noches'));
      expect(w.aiSummary(), contains('Datos insuficientes'));
    });

    test('el PDF también se genera con datos insuficientes', () async {
      final w = writer(report);
      final bytes = await fullReportPdf(
        report: report,
        blocks: w.blocks(),
        conclusions: w.conclusions(),
        s: es,
        lang: 'es',
        now: now,
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      saveSample('informe_completo_insuficiente.pdf', bytes);
    });

    test('el periodo son los últimos días hasta hoy, incluido', () {
      expect(report.from, DateTime(2026, 11, 8));
      expect(report.to, DateTime(2026, 11, 14));
      expect(report.days.length, 7);
      final r = buildFullReport(
        records: [pain(DateTime(2026, 11, 7, 23, 59), 9), pain(DateTime(2026, 11, 8, 0, 1), 1)],
        foodDays: const [],
        sleep: const [],
        config: config,
        periodDays: 7,
        now: now,
      );
      expect(r.painRecords, 1);
      expect(r.days.first.pain.single.painIntensity, 1);
    });
  });

  group('14 días con un patrón claro', () {
    // Del 1 al 14 de noviembre. Cada tres días (1, 4, 7, 10 y 13) hubo
    // alcohol en la cena, una noche mala (2/5, con dolor) y dolor 7; el resto
    // de días, pescado, noche buena (4/5) y dolor 4.
    final now = DateTime(2026, 11, 14, 20);
    final records = <PainRecord>[];
    final foodDays = <FoodDay>[];
    final sleep = <SleepEntry>[];
    for (var i = 0; i < 14; i++) {
      final day = DateTime(2026, 11, 1 + i);
      final alcohol = i % 3 == 0;
      records.add(pain(day.add(const Duration(hours: 10)), alcohol ? 7 : 4, events: 3));
      foodDays.add(FoodDay(date: day, meals: {
        MealSlot.breakfast: const MealLog(foods: ['bread'], time: '08:00'),
        MealSlot.dinner: MealLog(foods: [alcohol ? 'alcohol' : 'fish']),
      }));
      sleep.add(SleepEntry(date: day, quality: alcohol ? 2 : 4, withPain: alcohol));
    }
    final report = buildFullReport(
      records: records,
      foodDays: foodDays,
      sleep: sleep,
      config: config,
      periodDays: 14,
      now: now,
    );

    test('resumen del periodo', () {
      expect(report.allInsufficient, isFalse);
      expect(report.daysWithAny, 14);
      expect(report.painRecords, 14);
      expect(report.completeDays, 14);
      expect(report.mealsEaten, 28);
      expect(report.mealsSkipped, 0);
    });

    test('evolución del dolor', () {
      final p = report.pain!;
      expect(p.days, 14);
      expect(p.mean, closeTo(71 / 14, 1e-9));
      expect(p.min, 4);
      expect(p.max, 7);
      expect(p.eventsMean, 3);
      expect(p.firstHalf, closeTo(37 / 7, 1e-9));
      expect(p.secondHalf, closeTo(34 / 7, 1e-9));
      expect(p.change, closeTo(-0.4286, 1e-3));
      expect(p.zones.single.id, 'pies');
      expect(p.eventTypes.single.id, 'pinchazo');
    });

    test('sueño', () {
      final sl = report.sleep!;
      expect(sl.nights, 14);
      expect(sl.mean, closeTo(46 / 14, 1e-9));
      expect(sl.distribution, [0, 5, 0, 9, 0]);
      expect(sl.withPain, 5);
      expect(sl.painKnown, 14);
    });

    test('alimentación', () {
      final f = report.food!;
      expect(f.days, 14);
      expect(f.eaten[MealSlot.breakfast], 14);
      expect(f.eaten[MealSlot.dinner], 14);
      expect(f.eaten[MealSlot.lunch], 0);
      expect(f.topFoods.map((c) => c.id), ['bread', 'fish', 'alcohol']);
      expect(f.topFoods.map((c) => c.count), [14, 9, 5]);
    });

    test('relación del sueño con el dolor', () {
      final rel = report.relations;
      expect(rel.sleepEnough, isTrue);
      expect(rel.badVsGoodSleep!.withMean, 7);
      expect(rel.badVsGoodSleep!.withDays, 5);
      expect(rel.badVsGoodSleep!.withoutMean, 4);
      expect(rel.badVsGoodSleep!.withoutDays, 9);
      expect(rel.sleepCorrelation, closeTo(-1, 1e-9));
      expect(rel.nightPain!.diff, 3);
    });

    test('relación de los alimentos con el dolor (mismo día y siguiente)', () {
      final rel = report.relations;
      expect(rel.foodEnough, isTrue);
      // El pan está todos los días: no hay días sin él para comparar.
      expect(rel.foodsCompared, 2);
      final alcohol = rel.morePain.single;
      expect(alcohol.foodId, 'alcohol');
      expect(alcohol.sameDay!.diff, 3);
      expect(alcohol.nextDay!.diff, closeTo(-1.5, 1e-9));
      expect(alcohol.strongest, 3);
      final fish = rel.lessPain.single;
      expect(fish.foodId, 'fish');
      expect(fish.sameDay!.diff, -3);
      expect(rel.skippedMeals, isNull);
    });

    test('conclusiones descriptivas', () {
      expect(writer(report).conclusions(), [
        es.cPainStable('5,1'),
        es.cSleepMean('3,3'),
        es.cSleepWorse('7', '4'),
        es.cNightPain('7', '4'),
        es.cFoodMore('Alcohol'),
        es.cFoodLess('Pescado'),
        es.cAssociationNote,
      ]);
    });

    test('ningún apartado queda marcado como insuficiente', () {
      final blocks = writer(report).blocks();
      expect(blocks.map((b) => b.insufficient), everyElement(isFalse));
      expect(blocks.expand((b) => b.missing), isEmpty);
      final relations = blocks.last.lines.join('\n');
      expect(relations, contains('Coincide con más dolor: Alcohol'));
      expect(relations, contains('Coincide con menos dolor: Pescado'));
    });

    test('el informe en PDF se genera (muestra para la CI)', () async {
      final w = writer(report);
      final bytes = await fullReportPdf(
        report: report,
        blocks: w.blocks(),
        conclusions: w.conclusions(),
        s: es,
        lang: 'es',
        aiText: 'Texto de prueba del análisis con IA: «comillas», tildes y −1,5.',
        now: DateTime(2026, 11, 14, 20),
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      saveSample('informe_completo.pdf', bytes);
    });

    test('el resumen para la IA no lleva fechas ni notas', () {
      final text = writer(report).aiSummary();
      expect(text, contains('últimos 14 días'));
      expect(text, contains('Alcohol'));
      expect(text, isNot(contains('2026')));
      expect(text, isNot(contains('nov')));
    });
  });

  test('las tomas no realizadas se comparan con el dolor', () {
    final now = DateTime(2026, 11, 10, 20);
    final records = <PainRecord>[];
    final foodDays = <FoodDay>[];
    for (var i = 0; i < 10; i++) {
      final day = DateTime(2026, 11, 1 + i);
      final skipped = i.isEven;
      records.add(pain(day.add(const Duration(hours: 12)), skipped ? 6 : 3));
      foodDays.add(FoodDay(date: day, meals: {
        MealSlot.breakfast: skipped ? const MealLog(skipped: true) : const MealLog(foods: ['bread']),
        MealSlot.lunch: const MealLog(foods: ['rice']),
      }));
    }
    final report = buildFullReport(
      records: records,
      foodDays: foodDays,
      sleep: const [],
      config: config,
      periodDays: 14,
      now: now,
    );
    expect(report.mealsSkipped, 5);
    expect(report.relations.skippedMeals!.diff, 3);
    expect(report.relations.sleepEnough, isFalse);
    expect(writer(report).conclusions(), contains(es.cSkippedMore('3')));
    expect(report.food, isNotNull);
    expect(report.food!.skipped[MealSlot.breakfast], 5);
  });

  test('correlación y tendencia', () {
    expect(pearson([1, 2, 3, 4], [2, 4, 6, 8]), closeTo(1, 1e-9));
    expect(pearson([1, 2, 3], [5, 5, 5]), isNull);
    expect(pearson([1, 2], [1, 2]), isNull);
    expect(trendChange(const [(0, 2), (9, 5)], 10), closeTo(3, 1e-9));
    expect(trendChange(const [(3, 4)], 10), 0);
  });
}
