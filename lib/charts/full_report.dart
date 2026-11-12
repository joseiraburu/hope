// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.
//
// Informe completo: evolución del dolor en un periodo y su relación con el
// sueño y la alimentación. Solo describe lo registrado: compara medias entre
// grupos de días y no indica causas, diagnósticos ni tratamientos.

import 'dart:math' as math;

import '../core/config.dart';
import '../models/food.dart';
import '../models/pain_record.dart';
import '../models/sleep.dart';

/// Periodos que se pueden elegir, en días.
const List<int> reportPeriods = [7, 14, 30];

/// Mínimo de días con registro de dolor para describir su evolución.
const int reportMinPainDays = 7;

/// Mínimo de noches registradas para describir el sueño.
const int reportMinSleepNights = 5;

/// Mínimo de días con comidas registradas para describir la alimentación.
const int reportMinFoodDays = 7;

/// Mínimo de días con sueño y dolor registrados para relacionarlos.
const int reportMinSleepPainDays = 5;

/// Mínimo de días con comidas y dolor registrados para relacionarlos.
const int reportMinFoodPainDays = 7;

/// Mínimo de días en cada grupo al comparar alimentos o tomas saltadas.
const int reportMinGroupDays = 3;

/// Mínimo de noches en cada grupo al comparar noches buenas y malas.
const int reportMinSleepGroupDays = 2;

/// Diferencia de dolor (puntos de 0 a 10) a partir de la cual se señala.
const double reportNotableDiff = 1.0;

/// Cambio de dolor en el periodo a partir del cual no se considera estable.
const double reportTrendThreshold = 1.0;

/// Alimentos que se muestran como mucho en cada lista.
const int reportMaxFoods = 5;

double _mean(Iterable<num> values) {
  var sum = 0.0;
  var n = 0;
  for (final v in values) {
    sum += v;
    n++;
  }
  return n == 0 ? 0 : sum / n;
}

/// Media del dolor de fondo en dos grupos de días.
class PainComparison {
  const PainComparison({
    required this.withMean,
    required this.withDays,
    required this.withoutMean,
    required this.withoutDays,
  });

  final double withMean;
  final int withDays;
  final double withoutMean;
  final int withoutDays;

  /// Positiva: más dolor en el primer grupo.
  double get diff => withMean - withoutMean;
}

/// Compara dos grupos si cada uno tiene al menos [minEach] días.
PainComparison? comparePain(List<double> withValues, List<double> withoutValues, int minEach) {
  if (withValues.length < minEach || withoutValues.length < minEach) return null;
  return PainComparison(
    withMean: _mean(withValues),
    withDays: withValues.length,
    withoutMean: _mean(withoutValues),
    withoutDays: withoutValues.length,
  );
}

/// Coeficiente de correlación de Pearson; null si no se puede calcular.
double? pearson(List<double> x, List<double> y) {
  final n = math.min(x.length, y.length);
  if (n < 3) return null;
  final mx = _mean(x.take(n));
  final my = _mean(y.take(n));
  var sxy = 0.0;
  var sxx = 0.0;
  var syy = 0.0;
  for (var i = 0; i < n; i++) {
    final dx = x[i] - mx;
    final dy = y[i] - my;
    sxy += dx * dy;
    sxx += dx * dx;
    syy += dy * dy;
  }
  if (sxx == 0 || syy == 0) return null;
  return sxy / math.sqrt(sxx * syy);
}

/// Cambio estimado a lo largo del periodo (recta de regresión de los valores
/// diarios). [points] son pares (día dentro del periodo, valor).
double trendChange(List<(int, double)> points, int periodDays) {
  if (points.length < 2) return 0;
  final mx = _mean(points.map((p) => p.$1));
  final my = _mean(points.map((p) => p.$2));
  var sxy = 0.0;
  var sxx = 0.0;
  for (final p in points) {
    sxy += (p.$1 - mx) * (p.$2 - my);
    sxx += (p.$1 - mx) * (p.$1 - mx);
  }
  if (sxx == 0) return 0;
  return sxy / sxx * (periodDays - 1);
}

/// Un elemento contado (zona, tipo de evento o alimento) y cuántas veces.
class CountItem {
  const CountItem(this.id, this.count);

  final String id;
  final int count;
}

List<CountItem> _top(Map<String, int> counts, int max) {
  final list = [for (final e in counts.entries) CountItem(e.key, e.value)]
    ..sort((a, b) => b.count != a.count ? b.count.compareTo(a.count) : a.id.compareTo(b.id));
  return list.take(max).toList();
}

/// Lo registrado un día del periodo.
class ReportDay {
  ReportDay({required this.day, required this.index, required this.pain, this.food, this.sleep});

  /// Medianoche local.
  final DateTime day;

  /// Posición dentro del periodo (0 = primer día).
  final int index;

  /// Registros de dolor del día.
  final List<PainRecord> pain;
  final FoodDay? food;

  /// La noche que termina este día.
  final SleepEntry? sleep;

  /// Media del dolor de fondo del día (null si no hay registros).
  double? get painMean => pain.isEmpty ? null : _mean(pain.map((r) => r.painIntensity));

  bool get hasAny => pain.isNotEmpty || food != null || sleep != null;

  /// Dolor, sueño y comidas registrados.
  bool get complete => pain.isNotEmpty && food != null && sleep != null;
}

/// Evolución del dolor.
class PainSection {
  const PainSection({
    required this.days,
    required this.records,
    required this.mean,
    required this.min,
    required this.max,
    required this.eventsMean,
    required this.firstHalf,
    required this.secondHalf,
    required this.change,
    required this.zones,
    required this.eventTypes,
  });

  /// Días con registros y número de registros.
  final int days;
  final int records;

  /// Media de las medias diarias del dolor de fondo, y mínimo y máximo de los
  /// registros.
  final double mean;
  final int min;
  final int max;

  /// Intensidad media de los eventos (null si no hubo eventos).
  final double? eventsMean;

  /// Medias de la primera y la segunda mitad del periodo.
  final double? firstHalf;
  final double? secondHalf;

  /// Cambio estimado a lo largo del periodo.
  final double change;

  /// Zonas y tipos de evento más frecuentes (número de registros).
  final List<CountItem> zones;
  final List<CountItem> eventTypes;
}

/// Calidad del sueño.
class SleepSection {
  const SleepSection({
    required this.nights,
    required this.mean,
    required this.distribution,
    required this.withPain,
    required this.painKnown,
    required this.change,
  });

  final int nights;

  /// Media de 1 a 5.
  final double mean;

  /// Noches con calidad 1, 2, 3, 4 y 5.
  final List<int> distribution;

  /// Noches «con dolor» y noches en las que se indicó con o sin dolor.
  final int withPain;
  final int painKnown;

  /// Cambio estimado de la calidad a lo largo del periodo.
  final double change;
}

/// Alimentación.
class FoodSection {
  const FoodSection({
    required this.days,
    required this.eaten,
    required this.skipped,
    required this.topFoods,
  });

  final int days;

  /// Tomas con alimentos y tomas «No realizada», por toma.
  final Map<MealSlot, int> eaten;
  final Map<MealSlot, int> skipped;

  /// Alimentos más frecuentes (número de días).
  final List<CountItem> topFoods;
}

/// Un alimento y el dolor de los días en que se tomó frente a los demás.
class FoodAssociation {
  const FoodAssociation({required this.foodId, this.sameDay, this.nextDay});

  final String foodId;

  /// Dolor del mismo día.
  final PainComparison? sameDay;

  /// Dolor del día siguiente.
  final PainComparison? nextDay;

  /// La mayor diferencia (con su signo) entre el mismo día y el siguiente.
  double get strongest {
    final a = sameDay?.diff ?? 0;
    final b = nextDay?.diff ?? 0;
    return a.abs() >= b.abs() ? a : b;
  }
}

/// Relación del dolor con el sueño y la alimentación.
class RelationsSection {
  const RelationsSection({
    required this.sleepPainDays,
    required this.badVsGoodSleep,
    required this.sleepCorrelation,
    required this.nightPain,
    required this.foodPainDays,
    required this.foodsCompared,
    required this.morePain,
    required this.lessPain,
    required this.skippedMeals,
  });

  /// Días con sueño y dolor registrados.
  final int sleepPainDays;

  /// Dolor tras noches malas (1–2) frente a noches buenas (4–5).
  final PainComparison? badVsGoodSleep;

  /// Correlación entre calidad del sueño y dolor del día.
  final double? sleepCorrelation;

  /// Dolor tras noches «con dolor» frente a noches «sin dolor».
  final PainComparison? nightPain;

  /// Días con comidas y dolor registrados.
  final int foodPainDays;

  /// Alimentos con días suficientes para compararlos.
  final int foodsCompared;

  /// Alimentos que coinciden con más o con menos dolor.
  final List<FoodAssociation> morePain;
  final List<FoodAssociation> lessPain;

  /// Dolor los días con alguna toma «No realizada» frente a los demás.
  final PainComparison? skippedMeals;

  bool get sleepEnough => sleepPainDays >= reportMinSleepPainDays;
  bool get foodEnough => foodPainDays >= reportMinFoodPainDays;
}

/// Informe completo de un periodo.
class FullReport {
  const FullReport({
    required this.from,
    required this.to,
    required this.periodDays,
    required this.days,
    required this.pain,
    required this.sleep,
    required this.food,
    required this.relations,
  });

  /// Primer y último día (medianoche local).
  final DateTime from;
  final DateTime to;
  final int periodDays;
  final List<ReportDay> days;

  /// Null si no hay datos suficientes.
  final PainSection? pain;
  final SleepSection? sleep;
  final FoodSection? food;
  final RelationsSection relations;

  int get daysWithAny => days.where((d) => d.hasAny).length;
  int get painDays => days.where((d) => d.pain.isNotEmpty).length;
  int get painRecords => days.fold(0, (n, d) => n + d.pain.length);
  int get foodDays => days.where((d) => d.food != null).length;
  int get sleepNights => days.where((d) => d.sleep != null).length;
  int get completeDays => days.where((d) => d.complete).length;
  int get mealsEaten => days.fold(0, (n, d) => n + (d.food?.eatenSlots.length ?? 0));
  int get mealsSkipped => days.fold(0, (n, d) => n + (d.food?.skippedSlots.length ?? 0));

  /// Ningún apartado tiene datos suficientes.
  bool get allInsufficient =>
      pain == null && sleep == null && food == null && !relations.sleepEnough && !relations.foodEnough;
}

/// Calcula el informe de los últimos [periodDays] días hasta hoy ([now]).
FullReport buildFullReport({
  required List<PainRecord> records,
  required List<FoodDay> foodDays,
  required List<SleepEntry> sleep,
  required AppConfig config,
  required int periodDays,
  DateTime? now,
}) {
  final today = dayOf(now ?? DateTime.now());
  final from = DateTime(today.year, today.month, today.day - (periodDays - 1));
  final foodByKey = {for (final d in foodDays) if (!d.isEmpty) d.key: d};
  final sleepByKey = {for (final e in sleep) e.key: e};
  final painByKey = <String, List<PainRecord>>{};
  for (final r in records) {
    painByKey.putIfAbsent(dayKey(r.dateTime), () => []).add(r);
  }
  final days = <ReportDay>[];
  for (var i = 0; i < periodDays; i++) {
    final day = DateTime(from.year, from.month, from.day + i);
    final key = dayKey(day);
    days.add(ReportDay(
      day: day,
      index: i,
      pain: painByKey[key] ?? const [],
      food: foodByKey[key],
      sleep: sleepByKey[key],
    ));
  }

  return FullReport(
    from: from,
    to: today,
    periodDays: periodDays,
    days: days,
    pain: _painSection(days, periodDays, config),
    sleep: _sleepSection(days, periodDays),
    food: _foodSection(days),
    relations: _relations(days),
  );
}

PainSection? _painSection(List<ReportDay> days, int periodDays, AppConfig config) {
  final withPain = [for (final d in days) if (d.pain.isNotEmpty) d];
  if (withPain.length < reportMinPainDays) return null;
  final all = [for (final d in withPain) ...d.pain];
  final half = periodDays / 2;
  final first = [for (final d in withPain) if (d.index < half) d.painMean!];
  final second = [for (final d in withPain) if (d.index >= half) d.painMean!];
  final withEvents = [for (final r in all) if (r.eventIntensity > 0) r];

  final zoneCounts = <String, int>{};
  final typeCounts = <String, int>{};
  for (final r in all) {
    final zones = <String>{
      for (final part in r.zones)
        if (config.zoneOfPart(part) != null) config.zoneOfPart(part)!.id,
    };
    for (final z in zones) {
      zoneCounts[z] = (zoneCounts[z] ?? 0) + 1;
    }
    if (r.eventIntensity > 0) {
      for (final t in r.eventTypes.toSet()) {
        typeCounts[t] = (typeCounts[t] ?? 0) + 1;
      }
    }
  }

  return PainSection(
    days: withPain.length,
    records: all.length,
    mean: _mean(withPain.map((d) => d.painMean!)),
    min: all.map((r) => r.painIntensity).reduce(math.min),
    max: all.map((r) => r.painIntensity).reduce(math.max),
    eventsMean: withEvents.isEmpty ? null : _mean(withEvents.map((r) => r.eventIntensity)),
    firstHalf: first.isEmpty ? null : _mean(first),
    secondHalf: second.isEmpty ? null : _mean(second),
    change: trendChange([for (final d in withPain) (d.index, d.painMean!)], periodDays),
    zones: _top(zoneCounts, 3),
    eventTypes: _top(typeCounts, 3),
  );
}

SleepSection? _sleepSection(List<ReportDay> days, int periodDays) {
  final nights = [for (final d in days) if (d.sleep != null) d];
  if (nights.length < reportMinSleepNights) return null;
  final distribution = List<int>.filled(5, 0);
  var withPain = 0;
  var known = 0;
  for (final d in nights) {
    final e = d.sleep!;
    distribution[e.quality - 1]++;
    if (e.withPain != null) {
      known++;
      if (e.withPain!) withPain++;
    }
  }
  return SleepSection(
    nights: nights.length,
    mean: _mean(nights.map((d) => d.sleep!.quality)),
    distribution: distribution,
    withPain: withPain,
    painKnown: known,
    change: trendChange([for (final d in nights) (d.index, d.sleep!.quality.toDouble())], periodDays),
  );
}

FoodSection? _foodSection(List<ReportDay> days) {
  final withFood = [for (final d in days) if (d.food != null) d.food!];
  if (withFood.length < reportMinFoodDays) return null;
  final eaten = {for (final s in MealSlot.values) s: 0};
  final skipped = {for (final s in MealSlot.values) s: 0};
  final foodCounts = <String, int>{};
  for (final f in withFood) {
    for (final s in f.eatenSlots) {
      eaten[s] = eaten[s]! + 1;
    }
    for (final s in f.skippedSlots) {
      skipped[s] = skipped[s]! + 1;
    }
    for (final id in f.foods) {
      foodCounts[id] = (foodCounts[id] ?? 0) + 1;
    }
  }
  return FoodSection(
    days: withFood.length,
    eaten: eaten,
    skipped: skipped,
    topFoods: _top(foodCounts, 8),
  );
}

RelationsSection _relations(List<ReportDay> days) {
  // Sueño ↔ dolor del día en que termina la noche.
  final sleepPain = [for (final d in days) if (d.sleep != null && d.painMean != null) d];
  PainComparison? badVsGood;
  double? correlation;
  PainComparison? nightPain;
  if (sleepPain.length >= reportMinSleepPainDays) {
    badVsGood = comparePain(
      [for (final d in sleepPain) if (d.sleep!.quality <= 2) d.painMean!],
      [for (final d in sleepPain) if (d.sleep!.quality >= 4) d.painMean!],
      reportMinSleepGroupDays,
    );
    correlation = pearson(
      [for (final d in sleepPain) d.sleep!.quality.toDouble()],
      [for (final d in sleepPain) d.painMean!],
    );
    nightPain = comparePain(
      [for (final d in sleepPain) if (d.sleep!.withPain == true) d.painMean!],
      [for (final d in sleepPain) if (d.sleep!.withPain == false) d.painMean!],
      reportMinSleepGroupDays,
    );
  }

  // Alimentación ↔ dolor del mismo día y del día siguiente.
  final foodPain = [for (final d in days) if (d.food != null && d.painMean != null) d];
  final more = <FoodAssociation>[];
  final less = <FoodAssociation>[];
  var compared = 0;
  PainComparison? skipped;
  if (foodPain.length >= reportMinFoodPainDays) {
    // Pares (día con comidas, dolor del día siguiente) dentro del periodo.
    final nextPairs = <(FoodDay, double)>[
      for (var i = 0; i + 1 < days.length; i++)
        if (days[i].food != null && days[i + 1].painMean != null)
          (days[i].food!, days[i + 1].painMean!),
    ];
    final foods = <String>{for (final d in foodPain) ...d.food!.foods};
    for (final id in foods) {
      final same = comparePain(
        [for (final d in foodPain) if (d.food!.contains(id)) d.painMean!],
        [for (final d in foodPain) if (!d.food!.contains(id)) d.painMean!],
        reportMinGroupDays,
      );
      final next = comparePain(
        [for (final p in nextPairs) if (p.$1.contains(id)) p.$2],
        [for (final p in nextPairs) if (!p.$1.contains(id)) p.$2],
        reportMinGroupDays,
      );
      if (same == null && next == null) continue;
      compared++;
      final a = FoodAssociation(foodId: id, sameDay: same, nextDay: next);
      if (a.strongest >= reportNotableDiff) more.add(a);
      if (a.strongest <= -reportNotableDiff) less.add(a);
    }
    int byStrength(FoodAssociation x, FoodAssociation y) {
      final c = y.strongest.abs().compareTo(x.strongest.abs());
      return c != 0 ? c : x.foodId.compareTo(y.foodId);
    }

    more.sort(byStrength);
    less.sort(byStrength);
    skipped = comparePain(
      [for (final d in foodPain) if (d.food!.skippedSlots.isNotEmpty) d.painMean!],
      [for (final d in foodPain) if (d.food!.skippedSlots.isEmpty) d.painMean!],
      reportMinGroupDays,
    );
  }

  return RelationsSection(
    sleepPainDays: sleepPain.length,
    badVsGoodSleep: badVsGood,
    sleepCorrelation: correlation,
    nightPain: nightPain,
    foodPainDays: foodPain.length,
    foodsCompared: compared,
    morePain: more.take(reportMaxFoods).toList(),
    lessPain: less.take(reportMaxFoods).toList(),
    skippedMeals: skipped,
  );
}
