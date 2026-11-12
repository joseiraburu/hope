// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:async';

import 'package:flutter/material.dart';

import '../models/food.dart';
import '../models/reminder.dart';
import '../services/reminders.dart';
import '../state/app_controller.dart';
import '../state/navigation.dart';

/// En el ordenador (Windows y macOS) no hay avisos programados del sistema:
/// mientras HOPE está abierta, este vigilante muestra el aviso «Completa
/// HOPE» a la hora de cada alarma activa.
class ReminderWatcher extends StatefulWidget {
  const ReminderWatcher({super.key, required this.child});

  final Widget child;

  @override
  State<ReminderWatcher> createState() => _ReminderWatcherState();
}

class _ReminderWatcherState extends State<ReminderWatcher> {
  Timer? _timer;

  /// Avisos ya mostrados («2026-11-12 desayuno 08:00»).
  final Set<String> _shown = {};

  @override
  void initState() {
    super.initState();
    if (inAppRemindersSupported) {
      _timer = Timer.periodic(const Duration(seconds: 20), (_) => _check());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _check() {
    if (!mounted) return;
    final app = AppScope.read(context);
    final now = DateTime.now();
    for (final r in app.settings.reminders) {
      if (!r.enabled || r.hour != now.hour || r.minute != now.minute) continue;
      if (!_shown.add('${dayKey(now)} ${r.slot.key} ${r.timeText}')) continue;
      _show(r);
    }
  }

  void _show(Reminder r) {
    final overlay = hopeNavigatorKey.currentState?.overlay;
    if (overlay == null) return;
    final s = AppScope.read(context).strings;
    showDialog<void>(
      context: overlay.context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.notifications_active_outlined),
        title: Text(s.reminderTitle),
        content: Text(s.reminderBody(s.meal(r.slot))),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(s.later)),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openReminderMeal(r.slot);
            },
            child: Text(s.open),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
