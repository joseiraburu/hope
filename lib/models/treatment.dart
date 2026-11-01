// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'pain_record.dart' show isoWithOffset;

/// Un medicamento de la lista del usuario.
///
/// Los de la configuración (lidocaína, fentanilo, oxicodona) tienen nombre
/// traducido; el usuario puede renombrarlos ([customName]) u ocultarlos. Los
/// que añade el usuario solo tienen [customName].
class MedicationDef {
  const MedicationDef({
    required this.id,
    this.customName,
    this.hidden = false,
    this.builtIn = false,
  });

  final String id;
  final String? customName;
  final bool hidden;
  final bool builtIn;

  MedicationDef copyWith({String? customName, bool? hidden}) => MedicationDef(
        id: id,
        customName: customName ?? this.customName,
        hidden: hidden ?? this.hidden,
        builtIn: builtIn,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        if (customName != null) 'nombre': customName,
        'oculto': hidden,
      };

  factory MedicationDef.fromJson(Map<String, dynamic> j, {bool builtIn = false}) => MedicationDef(
        id: j['id'] as String,
        customName: j['nombre'] as String?,
        hidden: (j['oculto'] as bool?) ?? false,
        builtIn: builtIn,
      );
}

/// Un tratamiento: una administración puntual (sin [end]) o un periodo.
class Treatment {
  const Treatment({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.route,
    required this.dose,
    required this.unit,
    required this.start,
    this.end,
    this.schedule = '',
    this.notes = '',
    this.adverseEffects = const [],
    this.adverseOther = '',
  });

  final String id;
  final String medicationId;

  /// Nombre del medicamento al guardar (se usa si el medicamento desaparece).
  final String medicationName;

  /// Identificador de la vía («iv», «topica»...).
  final String route;
  final double dose;

  /// Identificador de la unidad («mg», «ug_h»...).
  final String unit;
  final DateTime start;

  /// Vacía = administración puntual (por ejemplo, una perfusión).
  final DateTime? end;
  final String schedule;
  final String notes;

  /// Identificadores de efectos adversos («mareo», «nauseas»...).
  final List<String> adverseEffects;
  final String adverseOther;

  bool get isPunctual => end == null;

  /// Último instante en que el tratamiento está activo.
  DateTime get lastMoment => end ?? start;

  /// ¿Está activo en algún momento del intervalo [from, to)?
  bool overlaps(DateTime from, DateTime to) =>
      start.isBefore(to) && !lastMoment.isBefore(from);

  Treatment copyWith({
    String? id,
    String? medicationId,
    String? medicationName,
    String? route,
    double? dose,
    String? unit,
    DateTime? start,
    DateTime? end,
    bool clearEnd = false,
    String? schedule,
    String? notes,
    List<String>? adverseEffects,
    String? adverseOther,
  }) {
    return Treatment(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      route: route ?? this.route,
      dose: dose ?? this.dose,
      unit: unit ?? this.unit,
      start: start ?? this.start,
      end: clearEnd ? null : (end ?? this.end),
      schedule: schedule ?? this.schedule,
      notes: notes ?? this.notes,
      adverseEffects: adverseEffects ?? this.adverseEffects,
      adverseOther: adverseOther ?? this.adverseOther,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'medicamento_id': medicationId,
        'medicamento': medicationName,
        'via': route,
        'dosis': dose,
        'unidad': unit,
        'inicio': isoWithOffset(start),
        'fin': end == null ? null : isoWithOffset(end!),
        'pauta': schedule,
        'notas': notes,
        'efectos_adversos': adverseEffects,
        'otros_efectos': adverseOther,
      };

  factory Treatment.fromJson(Map<String, dynamic> j) => Treatment(
        id: j['id'] as String,
        medicationId: (j['medicamento_id'] as String?) ?? '',
        medicationName: (j['medicamento'] as String?) ?? '',
        route: (j['via'] as String?) ?? 'otra',
        dose: (j['dosis'] as num?)?.toDouble() ?? 0,
        unit: (j['unidad'] as String?) ?? 'otra',
        start: DateTime.parse(j['inicio'] as String).toLocal(),
        end: j['fin'] == null ? null : DateTime.parse(j['fin'] as String).toLocal(),
        schedule: (j['pauta'] as String?) ?? '',
        notes: (j['notas'] as String?) ?? '',
        adverseEffects: [
          for (final e in (j['efectos_adversos'] as List<dynamic>? ?? const [])) e as String
        ],
        adverseOther: (j['otros_efectos'] as String?) ?? '',
      );
}
