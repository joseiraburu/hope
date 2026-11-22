// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import '../models/bowel.dart';
import '../models/food.dart' show dayKey, dayOf;

/// Las deposiciones de un día.
class BowelDay {
  BowelDay(this.day, List<BowelEntry> entries)
      : entries = List.unmodifiable([...entries]..sort((a, b) => a.dateTime.compareTo(b.dateTime)));

  /// Medianoche local.
  final DateTime day;

  /// De la más temprana a la más tardía.
  final List<BowelEntry> entries;

  int get count => entries.length;

  /// Calidad media del día (null si no hubo ninguna).
  double? get mean =>
      entries.isEmpty ? null : entries.fold<int>(0, (n, e) => n + e.quality) / entries.length;
}

/// Un día por fecha, de [from] a [to] (incluidos), con sus deposiciones.
/// Los días sin ninguna también aparecen (con [BowelDay.count] 0).
List<BowelDay> bowelDays(List<BowelEntry> entries, DateTime from, DateTime to) {
  final start = dayOf(from);
  final end = dayOf(to);
  final byKey = <String, List<BowelEntry>>{};
  for (final e in entries) {
    byKey.putIfAbsent(e.dayKeyText, () => []).add(e);
  }
  final out = <BowelDay>[];
  for (var d = start; !d.isAfter(end); d = DateTime(d.year, d.month, d.day + 1)) {
    out.add(BowelDay(d, byKey[dayKey(d)] ?? const []));
  }
  return out;
}

/// Resumen de unos días: total, días con alguna y media diaria.
class BowelSummary {
  const BowelSummary({required this.total, required this.daysWith, required this.days, this.mean});

  factory BowelSummary.of(List<BowelDay> days) {
    final all = [for (final d in days) ...d.entries];
    return BowelSummary(
      total: all.length,
      daysWith: days.where((d) => d.count > 0).length,
      days: days.length,
      mean: all.isEmpty ? null : all.fold<int>(0, (n, e) => n + e.quality) / all.length,
    );
  }

  final int total;
  final int daysWith;
  final int days;

  /// Calidad media (null si no hubo ninguna).
  final double? mean;

  double get perDay => days == 0 ? 0 : total / days;
}
