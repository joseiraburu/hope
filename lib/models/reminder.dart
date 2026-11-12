// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'food.dart' show MealSlot, normalizeMealTime;

/// Número de alarmas «Completa HOPE».
const int reminderCount = 5;

/// Una alarma diaria «Completa HOPE»: a qué hora suena y qué toma abre.
class Reminder {
  const Reminder({
    required this.slot,
    this.enabled = false,
    required this.hour,
    required this.minute,
  });

  /// Toma que se abre al pulsar el aviso.
  final MealSlot slot;
  final bool enabled;
  final int hour;
  final int minute;

  /// «08:00».
  String get timeText => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Reminder copyWith({MealSlot? slot, bool? enabled, int? hour, int? minute}) => Reminder(
        slot: slot ?? this.slot,
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );

  Map<String, dynamic> toJson() => {
        'toma': slot.key,
        'activo': enabled,
        'hora': timeText,
      };

  /// Lee una alarma; si falta algo, usa [fallback].
  static Reminder fromJson(Object? j, Reminder fallback) {
    if (j is! Map<String, dynamic>) return fallback;
    final time = normalizeMealTime(j['hora'] as String?);
    final parts = time?.split(':');
    return Reminder(
      slot: MealSlot.fromKey(j['toma'] as String?) ?? fallback.slot,
      enabled: (j['activo'] as bool?) ?? false,
      hour: parts == null ? fallback.hour : int.parse(parts[0]),
      minute: parts == null ? fallback.minute : int.parse(parts[1]),
    );
  }
}

/// Las cinco alarmas de partida: una por toma, a su hora habitual y
/// apagadas (el usuario decide cuáles activa).
const List<Reminder> defaultReminders = [
  Reminder(slot: MealSlot.breakfast, hour: 8, minute: 0),
  Reminder(slot: MealSlot.midMorning, hour: 11, minute: 0),
  Reminder(slot: MealSlot.lunch, hour: 14, minute: 0),
  Reminder(slot: MealSlot.snack, hour: 17, minute: 30),
  Reminder(slot: MealSlot.dinner, hour: 21, minute: 0),
];

/// Lee la lista de alarmas guardada; siempre devuelve [reminderCount].
List<Reminder> remindersFromJson(Object? j) {
  final list = j is List<dynamic> ? j : const <dynamic>[];
  return [
    for (var i = 0; i < reminderCount; i++)
      Reminder.fromJson(i < list.length ? list[i] : null, defaultReminders[i]),
  ];
}
