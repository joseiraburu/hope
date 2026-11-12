// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.
//
// Recordatorios «Completa HOPE».
//
// - Android e iOS: avisos del sistema programados con
//   flutter_local_notifications. Suenan aunque HOPE esté cerrada. Se
//   programan uno a uno para los próximos días (así respetan los cambios de
//   hora) y se renuevan cada vez que se abre la app.
// - Windows y macOS: HOPE avisa con una ventana mientras está abierta. Para
//   recibir los avisos con la app cerrada, se pueden exportar al calendario
//   (.ics).

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/strings.dart';
import '../models/food.dart';
import '../models/reminder.dart';

/// Días por adelantado que se programan los avisos.
const int reminderDaysAhead = 12;

/// Máximo de avisos pendientes (iOS no admite más de 64).
const int maxPendingReminders = 60;

/// Identificador del primer aviso programado.
const int _firstNotificationId = 100;

/// Dato que lleva cada aviso: la toma que abre («toma:desayuno»).
String reminderPayload(MealSlot slot) => 'toma:${slot.key}';

/// Toma de un aviso, o null si el dato no es de un recordatorio.
MealSlot? slotFromPayload(String? payload) {
  if (payload == null || !payload.startsWith('toma:')) return null;
  return MealSlot.fromKey(payload.substring(5));
}

/// Un aviso concreto: cuándo suena y qué toma abre.
class ScheduledReminder {
  const ScheduledReminder(this.at, this.slot);

  /// Fecha y hora local.
  final DateTime at;
  final MealSlot slot;
}

/// Próximos avisos de las alarmas activas a partir de [now], en orden.
List<ScheduledReminder> upcomingReminders(
  List<Reminder> reminders,
  DateTime now, {
  int days = reminderDaysAhead,
  int max = maxPendingReminders,
}) {
  final out = <ScheduledReminder>[];
  for (var d = 0; d <= days; d++) {
    for (final r in reminders) {
      if (!r.enabled) continue;
      final at = DateTime(now.year, now.month, now.day + d, r.hour, r.minute);
      if (at.isAfter(now)) out.add(ScheduledReminder(at, r.slot));
    }
  }
  out.sort((a, b) => a.at.compareTo(b.at));
  return out.take(max).toList();
}

/// HOPE puede programar avisos del sistema en esta plataforma.
bool get systemRemindersSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// HOPE avisa con una ventana mientras está abierta (ordenador).
bool get inAppRemindersSupported => !kIsWeb && (Platform.isWindows || Platform.isMacOS);

/// Avisos del sistema (Android e iOS).
class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  MealSlot? _pending;
  void Function(MealSlot slot)? _onOpen;

  /// Qué hacer al pulsar un aviso. Si se pulsó antes de que la app estuviera
  /// lista, se atiende en cuanto se asigna.
  set onOpen(void Function(MealSlot slot)? handler) {
    _onOpen = handler;
    final pending = _pending;
    if (handler != null && pending != null) {
      _pending = null;
      handler(pending);
    }
  }

  void _open(MealSlot slot) {
    final handler = _onOpen;
    if (handler == null) {
      _pending = slot;
    } else {
      handler(slot);
    }
  }

  /// Prepara los avisos. Si la app se abrió desde un aviso, lo atiende.
  Future<void> init() async {
    if (!systemRemindersSupported || _initialized) return;
    try {
      tzdata.initializeTimeZones();
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_hope'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (response) {
          final slot = slotFromPayload(response.payload);
          if (slot != null) _open(slot);
        },
      );
      _initialized = true;
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch != null && launch.didNotificationLaunchApp) {
        final slot = slotFromPayload(launch.notificationResponse?.payload);
        if (slot != null) _open(slot);
      }
    } catch (e) {
      debugPrint('HOPE: los avisos no están disponibles ($e)');
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// Pide permiso para mostrar avisos. Devuelve false si se deniega.
  Future<bool> requestPermission() async {
    if (!systemRemindersSupported) return true;
    await init();
    if (!_initialized) return false;
    try {
      if (Platform.isAndroid) {
        return await _android?.requestNotificationsPermission() ?? true;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, sound: true) ?? true;
    } catch (_) {
      return false;
    }
  }

  /// En Android, ¿puede programar avisos a la hora exacta?
  Future<bool> canScheduleExact() async {
    if (!systemRemindersSupported || !Platform.isAndroid) return true;
    await init();
    try {
      return await _android?.canScheduleExactNotifications() ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Abre el ajuste de Android para permitir las alarmas exactas.
  Future<void> requestExactAlarms() async {
    if (!systemRemindersSupported || !Platform.isAndroid) return;
    await init();
    try {
      await _android?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  /// Borra los avisos pendientes y programa los de las alarmas activas.
  Future<void> reschedule(List<Reminder> reminders, S s) async {
    if (!systemRemindersSupported) return;
    await init();
    if (!_initialized) return;
    try {
      await _plugin.cancelAll();
      final upcoming = upcomingReminders(reminders, DateTime.now());
      if (upcoming.isEmpty) return;
      final exact = await canScheduleExact();
      final mode = exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          'hope_recordatorios',
          s.remindersChannelName,
          channelDescription: s.remindersChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );
      var id = _firstNotificationId;
      for (final u in upcoming) {
        await _plugin.zonedSchedule(
          id: id++,
          title: s.reminderTitle,
          body: s.reminderBody(s.meal(u.slot)),
          // La hora local se pasa a UTC aquí, día a día: así un aviso de las
          // 8:00 sigue sonando a las 8:00 después del cambio de hora.
          scheduledDate: tz.TZDateTime.from(u.at, tz.UTC),
          notificationDetails: details,
          androidScheduleMode: mode,
          payload: reminderPayload(u.slot),
        );
      }
    } catch (e) {
      debugPrint('HOPE: no se pudieron programar los avisos ($e)');
    }
  }
}

// ------------------------------------------------------------ calendario
String _two(int n) => n.toString().padLeft(2, '0');

/// Fecha y hora local «flotante» de iCalendar: 20261112T080000.
String _icsLocal(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}${_two(d.month)}${_two(d.day)}T${_two(d.hour)}${_two(d.minute)}00';

/// Fecha y hora UTC de iCalendar: 20261112T070000Z.
String _icsUtc(DateTime d) {
  final u = d.toUtc();
  return '${u.year.toString().padLeft(4, '0')}${_two(u.month)}${_two(u.day)}'
      'T${_two(u.hour)}${_two(u.minute)}${_two(u.second)}Z';
}

/// Escapa un texto de iCalendar.
String _icsText(String text) => text
    .replaceAll(r'\', r'\\')
    .replaceAll(';', r'\;')
    .replaceAll(',', r'\,')
    .replaceAll('\n', r'\n');

/// Parte una línea en trozos de 75 bytes como máximo (RFC 5545): las
/// líneas siguientes empiezan con un espacio.
String foldIcsLine(String line) {
  final out = StringBuffer();
  var current = StringBuffer();
  var bytes = 0;
  var limit = 75;
  for (final rune in line.runes) {
    final ch = String.fromCharCode(rune);
    final size = utf8.encode(ch).length;
    if (bytes + size > limit) {
      out
        ..write(current.toString())
        ..write('\r\n ');
      current = StringBuffer();
      bytes = 0;
      limit = 74;
    }
    current.write(ch);
    bytes += size;
  }
  out.write(current.toString());
  return out.toString();
}

/// Calendario con las alarmas activas, repetidas cada día.
String buildRemindersIcs(List<Reminder> reminders, S s, {DateTime? now}) {
  final at = now ?? DateTime.now();
  final stamp = _icsUtc(at);
  final lines = <String>[
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//HOPE//Recordatorios//ES',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
  ];
  for (final r in reminders) {
    if (!r.enabled) continue;
    var start = DateTime(at.year, at.month, at.day, r.hour, r.minute);
    if (!start.isAfter(at)) start = DateTime(at.year, at.month, at.day + 1, r.hour, r.minute);
    final body = s.reminderBody(s.meal(r.slot));
    lines.addAll([
      'BEGIN:VEVENT',
      'UID:hope-${r.slot.key}-${r.timeText.replaceAll(':', '')}-$stamp@hope',
      'DTSTAMP:$stamp',
      'DTSTART:${_icsLocal(start)}',
      'DURATION:PT10M',
      'RRULE:FREQ=DAILY',
      'SUMMARY:${_icsText('${s.reminderTitle} · ${s.meal(r.slot)}')}',
      'DESCRIPTION:${_icsText(body)}',
      'BEGIN:VALARM',
      'ACTION:DISPLAY',
      'TRIGGER:PT0M',
      'DESCRIPTION:${_icsText(s.reminderTitle)}',
      'END:VALARM',
      'END:VEVENT',
    ]);
  }
  lines.add('END:VCALENDAR');
  return '${lines.map(foldIcsLine).join('\r\n')}\r\n';
}
