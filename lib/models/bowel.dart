// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'food.dart' show dayKey, dayOf;
import 'pain_record.dart' show isoWithOffset, newUuid;

/// Calidad de una deposición: de 1 (estreñimiento total) a 5 (diarrea
/// líquida). El 3 es una deposición normal.
const int bowelQualityMin = 1;
const int bowelQualityMax = 5;

/// Calidad que se considera normal.
const int bowelQualityNormal = 3;

/// Una deposición: cuándo fue, cómo fue y una nota opcional.
///
/// Puede haber varias el mismo día (o ninguna), así que cada una tiene su
/// propio identificador, como los registros de dolor.
class BowelEntry {
  BowelEntry({
    required this.id,
    required this.dateTime,
    required int quality,
    this.note = '',
    this.updatedAt,
  }) : quality = quality.clamp(bowelQualityMin, bowelQualityMax).toInt();

  /// Una deposición nueva con un identificador nuevo.
  factory BowelEntry.create({required DateTime dateTime, required int quality, String note = ''}) =>
      BowelEntry(id: newUuid(), dateTime: dateTime, quality: quality, note: note);

  final String id;

  /// Fecha y hora (local).
  final DateTime dateTime;

  /// 1 (estreñimiento total) a 5 (diarrea líquida).
  final int quality;
  final String note;

  /// Última vez que se guardó (para combinar datos de dos dispositivos).
  final DateTime? updatedAt;

  /// Día de la deposición (medianoche local).
  DateTime get day => dayOf(dateTime);

  /// Clave del día: «2026-11-12».
  String get dayKeyText => dayKey(dateTime);

  BowelEntry copyWith({DateTime? dateTime, int? quality, String? note, DateTime? updatedAt}) =>
      BowelEntry(
        id: id,
        dateTime: dateTime ?? this.dateTime,
        quality: quality ?? this.quality,
        note: note ?? this.note,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fecha_hora': isoWithOffset(dateTime),
        'calidad': quality,
        if (note.isNotEmpty) 'nota': note,
        if (updatedAt != null) 'actualizado': isoWithOffset(updatedAt!),
      };

  factory BowelEntry.fromJson(Map<String, dynamic> j) {
    final updated = j['actualizado'] as String?;
    return BowelEntry(
      id: (j['id'] as String?) ?? newUuid(),
      dateTime: DateTime.parse(j['fecha_hora'] as String).toLocal(),
      quality: (j['calidad'] as num?)?.toInt() ?? bowelQualityNormal,
      note: (j['nota'] as String?) ?? '',
      updatedAt: updated == null ? null : DateTime.tryParse(updated)?.toLocal(),
    );
  }
}
