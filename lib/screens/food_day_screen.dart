// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../models/food.dart';
import '../state/app_controller.dart';
import '../utils/format.dart';
import '../widgets/dialogs.dart';
import '../widgets/food_picker.dart';
import 'food_pain_screen.dart';

/// Lo que se ha hecho en el detalle de un día.
enum FoodDayAction { edit, deleted }

/// Resultado del detalle de un día: editarlo (en la pestaña Registrar) o
/// que se ha borrado (para ofrecer deshacer).
class FoodDayResult {
  const FoodDayResult(this.action, this.day);

  final FoodDayAction action;
  final FoodDay day;
}

/// Detalle de un día del historial de alimentación.
class FoodDayScreen extends StatelessWidget {
  const FoodDayScreen({super.key, required this.date});

  final DateTime date;

  Future<void> _delete(BuildContext context, FoodDay day) async {
    final app = AppScope.read(context);
    final s = app.strings;
    final ok = await confirmAction(
      context,
      title: s.deleteFoodDayQuestion,
      message: formatDayLong(day.date, app.language),
      confirmLabel: s.delete,
    );
    if (!ok || !context.mounted) return;
    final removed = await app.deleteFoodDay(day.date);
    if (removed == null || !context.mounted) return;
    Navigator.of(context).pop(FoodDayResult(FoodDayAction.deleted, removed));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final theme = Theme.of(context);
    final day = app.foodDayFor(date);
    if (day == null) return Scaffold(appBar: AppBar());
    return Scaffold(
      appBar: AppBar(title: Text(formatDayLong(day.date, app.language))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(s.foodCount(day.foods.length), style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          for (final slot in MealSlot.values) ...[
            Row(
              children: [
                Icon(mealSlotIcon(slot), color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(mealSlotName(app, slot), style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            FoodChips(ids: day.slot(slot)),
            const SizedBox(height: 20),
          ],
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => FoodPainScreen(date: day.date)),
            ),
            icon: const Icon(Icons.insights),
            label: Text(s.seeFoodPain),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(FoodDayResult(FoodDayAction.edit, day)),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(s.edit),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _delete(context, day),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(s.delete),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
