// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.
//
// Textos del informe completo. Se usan igual en la pantalla, en el PDF y en
// el resumen que se envía a la IA (si se activa), para que digan lo mismo.

import '../core/config.dart';
import '../l10n/strings.dart';
import '../models/food.dart';
import '../utils/format.dart';
import 'full_report.dart';

/// Un apartado del informe: título, líneas y, si faltan datos, qué falta.
class ReportBlock {
  const ReportBlock({
    required this.title,
    this.lines = const [],
    this.missing = const [],
    this.insufficient = false,
  });

  final String title;
  final List<String> lines;

  /// Qué datos faltan para completar el apartado.
  final List<String> missing;

  /// El apartado entero no tiene datos suficientes.
  final bool insufficient;
}

/// Cambio de la calidad del sueño (1–5) a partir del cual no es estable.
const double sleepTrendThreshold = 0.5;

/// Correlación a partir de la cual se describe una relación.
const double correlationThreshold = 0.3;

/// Genera los textos del informe.
class ReportWriter {
  ReportWriter({
    required this.report,
    required this.s,
    required this.lang,
    required this.config,
    required this.foodName,
  });

  final FullReport report;
  final S s;
  final String lang;
  final AppConfig config;
  final String Function(String id) foodName;

  String _n(double v) => formatNumber(v, lang);

  String _signed(double v) => formatSigned(v, lang);

  String _zoneName(String id) => config.zoneById[id]?.name(lang) ?? id;

  String _typeName(String id) => config.eventTypeById[id]?.name(lang) ?? id;

  String _comparison(PainComparison c) => s.comparisonText(
        _n(c.withMean),
        _n(c.withoutMean),
        _signed(c.diff),
        c.withDays,
        c.withoutDays,
      );

  String _association(FoodAssociation a) {
    final parts = [
      if (a.sameDay != null) '${s.foodSameDay}: ${_comparison(a.sameDay!)}',
      if (a.nextDay != null) '${s.foodNextDay}: ${_comparison(a.nextDay!)}',
    ];
    return '${foodName(a.foodId)} — ${parts.join(' · ')}';
  }

  /// Todos los apartados, en orden.
  List<ReportBlock> blocks() => [
        _coverage(),
        _pain(),
        _sleep(),
        _food(),
        _relations(),
      ];

  ReportBlock _coverage() {
    final r = report;
    final pct = r.periodDays == 0 ? 0.0 : r.completeDays * 100 / r.periodDays;
    return ReportBlock(
      title: s.reportCoverage,
      lines: [
        s.coverageDays(r.daysWithAny, r.periodDays),
        s.coveragePain(r.painRecords, r.painDays),
        s.coverageSleep(r.sleepNights),
        s.coverageMeals(r.mealsEaten, r.mealsSkipped, r.foodDays),
        s.coverageComplete(r.completeDays, r.periodDays, formatPct(pct, lang)),
      ],
    );
  }

  ReportBlock _pain() {
    final p = report.pain;
    if (p == null) {
      return ReportBlock(
        title: s.reportPainTitle,
        insufficient: true,
        missing: [s.missingPainDays(report.painDays, reportMinPainDays)],
      );
    }
    return ReportBlock(
      title: s.reportPainTitle,
      lines: [
        s.reportPainMean(_n(p.mean), '${p.min}', '${p.max}', p.days),
        if (p.eventsMean != null) s.reportEventsMean(_n(p.eventsMean!)),
        _painTrend(p.change),
        if (p.firstHalf != null && p.secondHalf != null) s.halves(_n(p.firstHalf!), _n(p.secondHalf!)),
        if (p.zones.isNotEmpty)
          s.frequentZones(p.zones.map((z) => '${_zoneName(z.id)} (${z.count})').join(', ')),
        if (p.eventTypes.isNotEmpty)
          s.frequentTypes(p.eventTypes.map((t) => '${_typeName(t.id)} (${t.count})').join(', ')),
      ],
    );
  }

  String _painTrend(double change) {
    if (change.abs() < reportTrendThreshold) return s.trendStable;
    return change > 0 ? s.trendUp(_n(change.abs())) : s.trendDown(_n(change.abs()));
  }

  ReportBlock _sleep() {
    final sl = report.sleep;
    if (sl == null) {
      return ReportBlock(
        title: s.reportSleepTitle,
        insufficient: true,
        missing: [s.missingSleep(report.sleepNights, reportMinSleepNights)],
      );
    }
    final distribution = [
      for (var q = 5; q >= 1; q--) '${s.sleepQualityName(q)}: ${sl.distribution[q - 1]}',
    ].join(' · ');
    return ReportBlock(
      title: s.reportSleepTitle,
      lines: [
        s.reportSleepMean(_n(sl.mean), sl.nights),
        s.sleepDistribution(distribution),
        if (sl.painKnown > 0) s.nightsWithPain(sl.withPain, sl.painKnown),
        if (sl.change.abs() < sleepTrendThreshold)
          s.sleepTrendStable
        else if (sl.change > 0)
          s.sleepTrendUp(_n(sl.change.abs()))
        else
          s.sleepTrendDown(_n(sl.change.abs())),
      ],
    );
  }

  ReportBlock _food() {
    final f = report.food;
    if (f == null) {
      return ReportBlock(
        title: s.reportFoodTitle,
        insufficient: true,
        missing: [s.missingFood(report.foodDays, reportMinFoodDays)],
      );
    }
    return ReportBlock(
      title: s.reportFoodTitle,
      lines: [
        s.foodDaysLine(f.days),
        for (final slot in MealSlot.values) s.mealStats(s.meal(slot), f.eaten[slot] ?? 0, f.skipped[slot] ?? 0),
        if (f.topFoods.isNotEmpty)
          s.frequentFoods(f.topFoods.map((c) => '${foodName(c.id)} (${c.count})').join(', ')),
      ],
    );
  }

  ReportBlock _relations() {
    final rel = report.relations;
    final lines = <String>[s.relationsMetric];
    final missing = <String>[];

    if (!rel.sleepEnough) {
      missing.add(s.missingSleepPain(rel.sleepPainDays, reportMinSleepPainDays));
    } else {
      final bg = rel.badVsGoodSleep;
      if (bg != null) {
        lines.add(s.sleepVsPain(_n(bg.withMean), bg.withDays, _n(bg.withoutMean), bg.withoutDays));
      } else {
        missing.add(s.missingSleepGroups);
      }
      final r = rel.sleepCorrelation;
      if (r != null) lines.add(s.sleepCorrelation(formatNumber(r, lang, decimals: 2), _correlationMeaning(r)));
      final np = rel.nightPain;
      if (np != null) {
        lines.add(s.nightPainVsPain(_n(np.withMean), np.withDays, _n(np.withoutMean), np.withoutDays));
      }
    }

    if (!rel.foodEnough) {
      missing.add(s.missingFoodPain(rel.foodPainDays, reportMinFoodPainDays));
    } else {
      lines.add(s.foodsCompared(rel.foodsCompared, reportMinGroupDays));
      for (final a in rel.morePain) {
        lines.add('${s.foodMorePain}: ${_association(a)}');
      }
      for (final a in rel.lessPain) {
        lines.add('${s.foodLessPain}: ${_association(a)}');
      }
      if (rel.morePain.isEmpty && rel.lessPain.isEmpty) lines.add(s.noFoodPattern);
      final sk = rel.skippedMeals;
      if (sk != null) {
        lines.add(s.skippedVsPain(_n(sk.withMean), sk.withDays, _n(sk.withoutMean), sk.withoutDays));
      }
    }

    return ReportBlock(
      title: s.reportRelationsTitle,
      lines: lines,
      missing: missing,
      insufficient: !rel.sleepEnough && !rel.foodEnough,
    );
  }

  String _correlationMeaning(double r) {
    if (r <= -correlationThreshold) return s.correlationNegative;
    if (r >= correlationThreshold) return s.correlationPositive;
    return s.correlationNone;
  }

  /// Conclusiones en lenguaje claro: describen, no explican ni recomiendan.
  List<String> conclusions() {
    final r = report;
    if (r.allInsufficient) return [s.cInsufficient];
    final out = <String>[];
    var associations = false;

    final p = r.pain;
    if (p != null) {
      if (p.change.abs() < reportTrendThreshold) {
        out.add(s.cPainStable(_n(p.mean)));
      } else if (p.change > 0) {
        out.add(s.cPainUp(_n(p.change.abs()), _n(p.mean)));
      } else {
        out.add(s.cPainDown(_n(p.change.abs()), _n(p.mean)));
      }
    }

    final sl = r.sleep;
    if (sl != null) out.add(s.cSleepMean(_n(sl.mean)));

    final rel = r.relations;
    final bg = rel.badVsGoodSleep;
    if (bg != null) {
      associations = true;
      if (bg.diff >= reportNotableDiff) {
        out.add(s.cSleepWorse(_n(bg.withMean), _n(bg.withoutMean)));
      } else if (bg.diff <= -reportNotableDiff) {
        out.add(s.cSleepBetter(_n(bg.withMean), _n(bg.withoutMean)));
      } else {
        out.add(s.cSleepNoDiff);
      }
    }
    final np = rel.nightPain;
    if (np != null && np.diff >= reportNotableDiff) {
      associations = true;
      out.add(s.cNightPain(_n(np.withMean), _n(np.withoutMean)));
    }

    if (rel.foodEnough) {
      associations = true;
      if (rel.morePain.isNotEmpty) {
        out.add(s.cFoodMore(rel.morePain.map((a) => foodName(a.foodId)).join(', ')));
      }
      if (rel.lessPain.isNotEmpty) {
        out.add(s.cFoodLess(rel.lessPain.map((a) => foodName(a.foodId)).join(', ')));
      }
      if (rel.morePain.isEmpty && rel.lessPain.isEmpty) out.add(s.cFoodNone);
      final sk = rel.skippedMeals;
      if (sk != null && sk.diff >= reportNotableDiff) out.add(s.cSkippedMore(_n(sk.diff)));
      if (sk != null && sk.diff <= -reportNotableDiff) out.add(s.cSkippedLess(_n(sk.diff.abs())));
    }

    if (associations) out.add(s.cAssociationNote);
    return out;
  }

  /// Resumen en texto para la IA: solo cifras agregadas, sin fechas, notas
  /// ni nombres.
  String aiSummary() {
    final b = StringBuffer()..writeln(s.aiUserIntro(report.periodDays));
    for (final block in blocks()) {
      b
        ..writeln()
        ..writeln('## ${block.title}');
      for (final line in block.lines) {
        b.writeln('- $line');
      }
      for (final line in block.missing) {
        b.writeln('- ${s.insufficientData}: $line');
      }
    }
    b
      ..writeln()
      ..writeln('## ${s.reportConclusions}');
    for (final c in conclusions()) {
      b.writeln('- $c');
    }
    return b.toString();
  }
}
