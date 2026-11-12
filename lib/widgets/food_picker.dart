// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../models/food.dart';
import '../state/app_controller.dart';
import '../state/food_draft.dart';
import 'dialogs.dart';

/// Con más alimentos que estos, la lista muestra un buscador.
const int foodSearchThreshold = 15;

/// Nombre de una toma: «Desayuno», «Almuerzo», «Comida», «Merienda» o «Cena».
String mealSlotName(AppController app, MealSlot slot) => app.strings.meal(slot);

/// Icono de una toma.
IconData mealSlotIcon(MealSlot slot) => switch (slot) {
      MealSlot.breakfast => Icons.free_breakfast_outlined,
      MealSlot.midMorning => Icons.bakery_dining_outlined,
      MealSlot.lunch => Icons.lunch_dining_outlined,
      MealSlot.snack => Icons.cookie_outlined,
      MealSlot.dinner => Icons.dinner_dining_outlined,
    };

/// Pide el nombre de un alimento nuevo y lo añade a la lista. Si ya existe,
/// devuelve el existente. Devuelve null si se cancela.
Future<({String id, bool existed})?> askNewFood(BuildContext context) async {
  final app = AppScope.read(context);
  final s = app.strings;
  final name = await askText(
    context,
    title: s.addFoodTitle,
    label: s.foodName,
    maxLength: foodNameMaxLength,
  );
  if (name == null || cleanFoodName(name).isEmpty) return null;
  final result = await app.addFood(name);
  return (id: result.food.id, existed: result.existed);
}

/// Hoja inferior para elegir los alimentos de una toma (selección
/// múltiple). La última opción añade un alimento nuevo, que queda marcado y
/// disponible en todas las tomas para cualquier día.
Future<void> showFoodPicker(BuildContext context, FoodDraft draft, MealSlot slot) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(child: _FoodPickerSheet(draft: draft, slot: slot)),
  );
}

class _FoodPickerSheet extends StatefulWidget {
  const _FoodPickerSheet({required this.draft, required this.slot});

  final FoodDraft draft;
  final MealSlot slot;

  @override
  State<_FoodPickerSheet> createState() => _FoodPickerSheetState();
}

class _FoodPickerSheetState extends State<_FoodPickerSheet> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String? _notice;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final added = await askNewFood(context);
    if (added == null || !mounted) return;
    widget.draft.add(widget.slot, added.id);
    final app = AppScope.read(context);
    final name = app.foodName(added.id);
    setState(() {
      _notice = added.existed ? app.strings.foodDuplicate(name) : app.strings.foodAdded(name);
      _query = '';
      _search.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
        child: ListenableBuilder(
          listenable: widget.draft,
          builder: (context, _) {
            final selected = widget.draft.slot(widget.slot);
            final all = app.pickableFoods(selected);
            final query = normalizeFoodName(_query);
            final shown = query.isEmpty
                ? all
                : [
                    for (final f in all)
                      if (normalizeFoodName(app.foodName(f.id)).contains(query)) f
                  ];
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
                  child: Row(
                    children: [
                      Icon(mealSlotIcon(widget.slot), color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(mealSlotName(app, widget.slot),
                            style: theme.textTheme.titleLarge),
                      ),
                      TextButton(
                        onPressed: selected.isEmpty ? null : () => widget.draft.clear(widget.slot),
                        child: Text(s.none),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      selected.isEmpty ? s.noFoods : s.foodCount(selected.length),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
                if (all.length > foodSearchThreshold)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: TextField(
                      controller: _search,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: s.searchFood,
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                if (_notice != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _notice!,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ),
                  ),
                const Divider(),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final f in shown)
                        CheckboxListTile(
                          value: selected.contains(f.id),
                          onChanged: (_) => widget.draft.toggle(widget.slot, f.id),
                          title: Text(app.foodName(f.id)),
                        ),
                      ListTile(
                        leading: Icon(Icons.add, color: theme.colorScheme.primary),
                        title: Text(
                          s.addFood,
                          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                        ),
                        onTap: _add,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(s.done),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Etiquetas con los alimentos (de solo lectura).
class FoodChips extends StatelessWidget {
  const FoodChips({super.key, required this.ids, this.dense = false});

  final List<String> ids;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (ids.isEmpty) {
      return Text(app.strings.noFoods, style: Theme.of(context).textTheme.bodySmall);
    }
    return Wrap(
      spacing: 6,
      runSpacing: dense ? 4 : 6,
      children: [
        for (final id in ids)
          Chip(
            label: Text(app.foodName(id)),
            visualDensity: dense ? VisualDensity.compact : VisualDensity.standard,
            materialTapTargetSize: dense ? MaterialTapTargetSize.shrinkWrap : null,
          ),
      ],
    );
  }
}
