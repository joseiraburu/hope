// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:math' as math;

/// Un registro del histórico: el estado del dolor en un momento dado.
class PainRecord {
  const PainRecord({
    required this.id,
    required this.dateTime,
    required this.sex,
    required this.painIntensity,
    required this.zones,
    required this.surfacePct,
    required this.eventIntensity,
    required this.eventTypes,
    required this.eventFrequency,
    required this.seed,
    this.note = '',
    this.videoPath,
    int? zoneCount,
  }) : _zoneCount = zoneCount;

  final String id;
  final DateTime dateTime;

  /// 'female' o 'male'.
  final String sex;
  final int painIntensity;
  final List<String> zones;
  final double surfacePct;
  final int eventIntensity;
  final List<String> eventTypes;

  /// Eventos por minuto (10–500).
  final int eventFrequency;

  /// Semilla de la animación: reproduce exactamente el mismo bucle.
  final int seed;
  final String note;
  final String? videoPath;
  final int? _zoneCount;

  /// Número de zonas afectadas («Pies (ambos)» cuenta como una).
  int get zoneCount => _zoneCount ?? zones.length;

  PainRecord copyWith({
    DateTime? dateTime,
    String? sex,
    int? painIntensity,
    List<String>? zones,
    double? surfacePct,
    int? eventIntensity,
    List<String>? eventTypes,
    int? eventFrequency,
    int? seed,
    String? note,
    String? videoPath,
    int? zoneCount,
  }) {
    return PainRecord(
      id: id,
      dateTime: dateTime ?? this.dateTime,
      sex: sex ?? this.sex,
      painIntensity: painIntensity ?? this.painIntensity,
      zones: zones ?? this.zones,
      surfacePct: surfacePct ?? this.surfacePct,
      eventIntensity: eventIntensity ?? this.eventIntensity,
      eventTypes: eventTypes ?? this.eventTypes,
      eventFrequency: eventFrequency ?? this.eventFrequency,
      seed: seed ?? this.seed,
      note: note ?? this.note,
      videoPath: videoPath ?? this.videoPath,
      zoneCount: zoneCount ?? _zoneCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fecha_hora': isoWithOffset(dateTime),
        'perfil_sexo': sex,
        'intensidad_dolor': painIntensity,
        'zonas': zones,
        'num_zonas': zoneCount,
        'superficie_pct': surfacePct,
        'intensidad_eventos': eventIntensity,
        'tipos_evento': eventTypes,
        'frecuencia_eventos': eventFrequency,
        'semilla_animacion': seed,
        'nota': note,
        'video_ruta': videoPath,
      };

  factory PainRecord.fromJson(Map<String, dynamic> j) => PainRecord(
        id: j['id'] as String,
        dateTime: DateTime.parse(j['fecha_hora'] as String).toLocal(),
        sex: (j['perfil_sexo'] as String?) ?? 'female',
        painIntensity: (j['intensidad_dolor'] as num?)?.toInt() ?? 0,
        zones: [for (final z in (j['zonas'] as List<dynamic>? ?? const [])) z as String],
        surfacePct: (j['superficie_pct'] as num?)?.toDouble() ?? 0,
        eventIntensity: (j['intensidad_eventos'] as num?)?.toInt() ?? 0,
        eventTypes: [
          for (final t in (j['tipos_evento'] as List<dynamic>? ?? const [])) t as String
        ],
        eventFrequency: (j['frecuencia_eventos'] as num?)?.toInt() ?? 60,
        seed: (j['semilla_animacion'] as num?)?.toInt() ?? 1,
        note: (j['nota'] as String?) ?? '',
        videoPath: j['video_ruta'] as String?,
        zoneCount: (j['num_zonas'] as num?)?.toInt(),
      );
}

/// Fecha y hora local en ISO 8601 con zona horaria (p. ej. 2026-10-31T14:24:00+01:00).
String isoWithOffset(DateTime dt) {
  final local = dt.toLocal();
  final off = local.timeZoneOffset;
  final sign = off.isNegative ? '-' : '+';
  final h = off.inHours.abs();
  final m = off.inMinutes.abs() % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year.toString().padLeft(4, '0')}-${two(local.month)}-${two(local.day)}'
      'T${two(local.hour)}:${two(local.minute)}:${two(local.second)}'
      '$sign${two(h)}:${two(m)}';
}

final math.Random _secure = math.Random.secure();

/// Identificador UUID versión 4.
String newUuid() {
  final b = List<int>.generate(16, (_) => _secure.nextInt(256));
  b[6] = (b[6] & 0x0F) | 0x40;
  b[8] = (b[8] & 0x3F) | 0x80;
  final hex = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Semilla aleatoria nueva para una animación.
int newSeed() => _secure.nextInt(1 << 31);
