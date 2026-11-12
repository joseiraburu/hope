// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:convert';

import 'package:flutter/material.dart';

import '../export/share_service.dart';
import '../models/food.dart';
import '../models/reminder.dart';
import '../services/reminders.dart';
import '../state/app_controller.dart';
import '../utils/format.dart';
import '../widgets/food_picker.dart' show mealSlotIcon;

/// Recordatorios «Completa HOPE»: hasta cinco alarmas diarias, cada una con
/// su hora y la toma que abre.
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> with WidgetsBindingObserver {
  /// En Android: si se pueden programar avisos a la hora exacta.
  bool? _exact;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkExact();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Al volver de los ajustes del sistema, se comprueba otra vez el permiso.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _checkExact(reschedule: true);
  }

  Future<void> _checkExact({bool reschedule = false}) async {
    if (!systemRemindersSupported) return;
    final exact = await ReminderService.instance.canScheduleExact();
    if (!mounted) return;
    final changed = exact != _exact;
    setState(() => _exact = exact);
    if (reschedule && changed) {
      final app = AppScope.read(context);
      await ReminderService.instance.reschedule(app.settings.reminders, app.strings);
    }
  }

  Future<void> _update(int index, Reminder reminder) async {
    final app = AppScope.read(context);
    final s = app.strings;
    final wasAnyOn = app.settings.anyReminderEnabled;
    final list = [...app.settings.reminders];
    list[index] = reminder;
    await app.updateSettings(app.settings.copyWith(reminders: list));
    // El permiso se pide solo al activar la primera alarma.
    if (reminder.enabled && !wasAnyOn && systemRemindersSupported) {
      final granted = await ReminderService.instance.requestPermission();
      if (!granted && mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.notifications_off_outlined),
            title: Text(s.reminders),
            content: Text(s.notificationsDenied),
            actions: [
              FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(s.accept)),
            ],
          ),
        );
      }
      await _checkExact();
    }
    await ReminderService.instance.reschedule(list, s);
  }

  Future<void> _pickTime(int index, Reminder reminder) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
    );
    if (picked == null || !mounted) return;
    await _update(index, reminder.copyWith(hour: picked.hour, minute: picked.minute));
  }

  Future<void> _exportCalendar() async {
    final app = AppScope.read(context);
    final s = app.strings;
    if (!app.settings.anyReminderEnabled) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(s.noRemindersEnabled)));
      return;
    }
    final text = buildRemindersIcs(app.settings.reminders, s);
    final file = await writeExportFile('HOPE_recordatorios_${isoDate(DateTime.now())}.ics', utf8.encode(text));
    if (!mounted) return;
    await deliverFile(context, file, mimeType: 'text/calendar', subject: s.reminderTitle);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final theme = Theme.of(context);
    final reminders = app.settings.reminders;
    return Scaffold(
      appBar: AppBar(title: Text(s.reminders)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(s.remindersHelp, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          for (var i = 0; i < reminders.length; i++) ...[
            _ReminderCard(
              index: i,
              reminder: reminders[i],
              onChanged: (r) => _update(i, r),
              onPickTime: () => _pickTime(i, reminders[i]),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: theme.colorScheme.outline),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  systemRemindersSupported ? s.remindersLimitsMobile : s.remindersLimitsDesktop,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          if (_exact == false && app.settings.anyReminderEnabled) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.alarm_on_outlined),
                title: Text(s.exactAlarms),
                subtitle: Text(s.exactAlarmsHelp),
                trailing: TextButton(
                  onPressed: () => ReminderService.instance.requestExactAlarms(),
                  child: Text(s.allow),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_available_outlined),
              title: Text(s.addToCalendar),
              subtitle: Text(s.addToCalendarHelp),
              onTap: _exportCalendar,
            ),
          ),
        ],
      ),
    );
  }
}

/// Una alarma: interruptor, hora y toma que abre.
class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.index,
    required this.reminder,
    required this.onChanged,
    required this.onPickTime,
  });

  final int index;
  final Reminder reminder;
  final ValueChanged<Reminder> onChanged;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final theme = Theme.of(context);
    final on = reminder.enabled;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              key: ValueKey('reminder-switch-$index'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              title: Text('${s.reminderN(index + 1)} · ${reminder.timeText}'),
              subtitle: Text(s.meal(reminder.slot)),
              value: on,
              onChanged: (v) => onChanged(reminder.copyWith(enabled: v)),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    key: ValueKey('reminder-time-$index'),
                    onPressed: onPickTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(reminder.timeText, style: theme.textTheme.titleMedium),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: s.reminderOpens,
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<MealSlot>(
                          value: reminder.slot,
                          isExpanded: true,
                          onChanged: (v) {
                            if (v != null) onChanged(reminder.copyWith(slot: v));
                          },
                          items: [
                            for (final slot in MealSlot.values)
                              DropdownMenuItem<MealSlot>(
                                value: slot,
                                child: Row(
                                  children: [
                                    Icon(mealSlotIcon(slot), size: 18),
                                    const SizedBox(width: 6),
                                    Flexible(child: Text(s.meal(slot), overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
