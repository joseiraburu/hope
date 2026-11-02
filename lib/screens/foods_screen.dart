// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../models/food.dart';
import '../state/app_controller.dart';
import '../widgets/dialogs.dart';
import '../widgets/food_picker.dart';

/// «Mis alimentos»: añadir, cambiar el nombre, ocultar y borrar alimentos.
class FoodsScreen extends StatelessWidget {
  const FoodsScreen({super.key});

  void _notify(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _add(BuildContext context) async {
    final added = await askNewFood(context);
    if (added == null || !context.mounted) return;
    final app = AppScope.read(context);
    final name = app.foodName(added.id);
    _notify(context, added.existed ? app.strings.foodDuplicate(name) : app.strings.foodAdded(name));
  }

  Future<void> _rename(BuildContext context, FoodDef food) async {
    final app = AppScope.read(context);
    final s = app.strings;
    final name = await askText(
      context,
      title: s.renameFood,
      label: s.foodName,
      initial: app.foodName(food.id),
      maxLength: foodNameMaxLength,
    );
    if (name == null || cleanFoodName(name).isEmpty) return;
    final ok = await app.renameFood(food.id, name);
    if (!ok && context.mounted) _notify(context, s.foodNameTaken);
  }

  Future<void> _delete(BuildContext context, FoodDef food) async {
    final app = AppScope.read(context);
    final s = app.strings;
    final ok = await confirmAction(
      context,
      title: s.deleteFoodQuestion,
      message: app.foodName(food.id),
      confirmLabel: s.delete,
    );
    if (!ok) return;
    final deleted = await app.deleteFood(food.id);
    if (context.mounted) _notify(context, deleted ? s.foodDeleted : s.foodArchived);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final theme = Theme.of(context);
    final custom = app.sortFoods([for (final f in app.foods) if (!f.builtIn) f]);
    final basic = app.sortFoods([for (final f in app.foods) if (f.builtIn) f]);

    Widget section(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        );

    Widget tile(FoodDef f) {
      final name = app.foodName(f.id);
      return ListTile(
        leading: Icon(
          Icons.restaurant,
          color: f.hidden ? theme.disabledColor : theme.colorScheme.primary,
        ),
        title: Text(name, style: f.hidden ? TextStyle(color: theme.disabledColor) : null),
        subtitle: f.hidden ? Text(s.hiddenLabel) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!f.builtIn)
              IconButton(
                tooltip: '${s.renameFood} · $name',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _rename(context, f),
              ),
            IconButton(
              tooltip: '${f.hidden ? s.showMedication : s.hideMedication} · $name',
              icon: Icon(f.hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => app.setFoodHidden(f.id, !f.hidden),
            ),
            if (!f.builtIn)
              IconButton(
                tooltip: '${s.delete} · $name',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(context, f),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.myFoods)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: Text(s.addFoodTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(s.foodsHelp, style: theme.textTheme.bodySmall),
          ),
          section(s.customFoods),
          if (custom.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(s.noFoods, style: theme.textTheme.bodyMedium),
            ),
          for (final f in custom) tile(f),
          section(s.basicFoods),
          for (final f in basic) tile(f),
        ],
      ),
    );
  }
}
