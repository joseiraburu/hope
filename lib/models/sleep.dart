// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'food.dart' show dayKey, dayOf, parseDayKey;
import 'pain_record.dart' show isoWithOffset;

/// Calidad del sueño: de 1 (muy malo) a 5 (muy bueno).
const int sleepQualityMin = 1;
const int sleepQualityMax = 5;

/// Cómo se durmió una noche.
///
/// La noche se guarda con la fecha del día en que uno se levanta: la noche
/// del 11 al 12 tiene fecha 12. Así se relaciona directamente con el dolor
/// de ese día.
class SleepEntry {
  SleepEntry({
    required DateTime date,
    required int quality,
    this.withPain,
    this.note = '',
    this.updatedAt,
  })  : date = dayOf(date),
        quality = quality.clamp(sleepQualityMin, sleepQualityMax).toInt();

  /// Día en que termina la noche (medianoche local).
  final DateTime date;

  /// 1 (muy malo) a 5 (muy bueno).
  final int quality;

  /// «Con dolor» (true), «Sin dolor» (false) o sin indicar (null).
  final bool? withPain;
  final String note;

  /// Última vez que se guardó.
  final DateTime? updatedAt;

  /// Clave del día: «2026-11-12».
  String get key => dayKey(date);

  /// Día en que empieza la noche.
  DateTime get nightStart => DateTime(date.year, date.month, date.day - 1);

  SleepEntry copyWith({
    int? quality,
    bool? withPain,
    bool clearPain = false,
    String? note,
    DateTime? updatedAt,
  }) =>
      SleepEntry(
        date: date,
        quality: quality ?? this.quality,
        withPain: clearPain ? null : (withPain ?? this.withPain),
        note: note ?? this.note,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'fecha': key,
        'calidad': quality,
        if (withPain != null) 'con_dolor': withPain,
        if (note.isNotEmpty) 'nota': note,
        if (updatedAt != null) 'actualizado': isoWithOffset(updatedAt!),
      };

  factory SleepEntry.fromJson(Map<String, dynamic> j) {
    final updated = j['actualizado'] as String?;
    return SleepEntry(
      date: parseDayKey(j['fecha'] as String),
      quality: (j['calidad'] as num?)?.toInt() ?? 3,
      withPain: j['con_dolor'] as bool?,
      note: (j['nota'] as String?) ?? '',
      updatedAt: updated == null ? null : DateTime.tryParse(updated)?.toLocal(),
    );
  }
}
