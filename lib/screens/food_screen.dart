// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../models/food.dart';
import '../state/app_controller.dart';
import '../state/food_draft.dart';
import '../utils/format.dart';
import '../widgets/dialogs.dart';
import '../widgets/food_picker.dart';
import 'food_day_screen.dart';
import 'foods_screen.dart';

/// Días que ofrece la lista desplegable (hoy y los anteriores).
const int foodDayChoices = 30;

/// Pestaña Alimentación: registrar lo que se come por la mañana y por la
/// tarde, e historial por días.
class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key, this.initialTab = 0});

  /// 0 = Registrar, 1 = Historial.
  final int initialTab;

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs =
      TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
  FoodDraft? _draft;

  /// Alimento por el que se filtra el historial.
  String? _filter;

  FoodDraft get _d => _draft!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_draft != null) return;
    final app = AppScope.read(context);
    final today = dayOf(DateTime.now());
    _draft = FoodDraft(today)..load(today, app.foodDayFor(today));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _draft?.dispose();
    super.dispose();
  }

  /// Si hay cambios sin guardar, pregunta si se descartan.
  Future<bool> _confirmDiscard() async {
    if (!_d.dirty) return true;
    final s = AppScope.read(context).strings;
    return confirmAction(context, title: s.foodUnsaved, confirmLabel: s.discard);
  }

  Future<void> _changeDay(DateTime day) async {
    if (dayKey(day) == dayKey(_d.day)) return;
    if (!await _confirmDiscard() || !mounted) return;
    _d.load(day, AppScope.read(context).foodDayFor(day));
  }

  Future<void> _save() async {
    final app = AppScope.read(context);
    final s = app.strings;
    await app.saveFoodDay(_d.toFoodDay());
    _d.markSaved();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(s.foodSaved)));
  }

  Future<void> _openDay(FoodDay day) async {
    final result = await Navigator.of(context).push<FoodDayResult>(
      MaterialPageRoute(builder: (_) => FoodDayScreen(date: day.date)),
    );
    if (result == null || !mounted) return;
    switch (result.action) {
      case FoodDayAction.edit:
        await _editDay(result.day.date);
      case FoodDayAction.deleted:
        _onDeleted(result.day);
    }
  }

  /// Abre un día del historial en la pestaña Registrar.
  Future<void> _editDay(DateTime day) async {
    if (dayKey(day) != dayKey(_d.day)) {
      if (!await _confirmDiscard() || !mounted) return;
      _d.load(day, AppScope.read(context).foodDayFor(day));
    }
    _tabs.animateTo(0);
  }

  void _onDeleted(FoodDay removed) {
    final app = AppScope.read(context);
    final s = app.strings;
    _reloadIfShowing(removed.date);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(s.foodDayDeleted),
        action: SnackBarAction(
          label: s.undo,
          onPressed: () async {
            await app.restoreFoodDay(removed);
            if (mounted) _reloadIfShowing(removed.date);
          },
        ),
      ));
  }

  /// Si el día que se está editando no tiene cambios, vuelve a cargar lo
  /// guardado (tras borrarlo o deshacer el borrado).
  void _reloadIfShowing(DateTime day) {
    if (dayKey(day) == dayKey(_d.day) && !_d.dirty) {
      _d.load(day, AppScope.read(context).foodDayFor(day));
    }
  }

  Future<void> _onBlockedPop(bool didPop) async {
    if (didPop) return;
    if (!await _confirmDiscard() || !mounted) return;
    _d.load(_d.day, AppScope.read(context).foodDayFor(_d.day));
    if (mounted) Navigator.of(context).pop();
  }

  void _openFoods() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const FoodsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).strings;
    return ListenableBuilder(
      listenable: _d,
      builder: (context, _) => PopScope<Object?>(
        canPop: !_d.dirty,
        onPopInvokedWithResult: (didPop, _) => _onBlockedPop(didPop),
        child: Scaffold(
          appBar: AppBar(
            title: Text(s.food),
            actions: [
              IconButton(
                tooltip: s.myFoods,
                icon: const Icon(Icons.tune),
                onPressed: _openFoods,
              ),
            ],
            bottom: TabBar(
              controller: _tabs,
              tabs: [
                Tab(icon: const Icon(Icons.edit_note), text: s.foodLogTab),
                Tab(icon: const Icon(Icons.calendar_month), text: s.foodHistoryTab),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: [
              _FoodLogTab(draft: _d, onChangeDay: _changeDay, onSave: _save),
              _FoodHistoryTab(
                filter: _filter,
                onFilter: (id) => setState(() => _filter = id),
                onOpen: _openDay,
                onLogNow: () => _tabs.animateTo(0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «Hoy · lun 2 nov 2026», «Ayer · …» o solo la fecha.
String foodDayLabel(AppController app, DateTime day) {
  final s = app.strings;
  final today = dayOf(DateTime.now());
  final yesterday = DateTime(today.year, today.month, today.day - 1);
  final text = formatDayLong(day, app.language);
  if (dayKey(day) == dayKey(today)) return '${s.today} · $text';
  if (dayKey(day) == dayKey(yesterday)) return '${s.yesterday} · $text';
  return text;
}

// ------------------------------------------------------------- Registrar
class _FoodLogTab extends StatelessWidget {
  const _FoodLogTab({required this.draft, required this.onChangeDay, required this.onSave});

  final FoodDraft draft;
  final Future<void> Function(DateTime day) onChangeDay;
  final Future<void> Function() onSave;

  static const _otherDate = 'otra';

  Future<void> _pickOtherDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: draft.day,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) await onChangeDay(picked);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final theme = Theme.of(context);
    final today = dayOf(DateTime.now());
    final days = [
      for (var i = 0; i < foodDayChoices; i++) DateTime(today.year, today.month, today.day - i)
    ];
    final current = dayKey(draft.day);
    if (!days.any((d) => dayKey(d) == current)) days.add(draft.day);
    final saved = app.foodDayFor(draft.day);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        InputDecorator(
          decoration: InputDecoration(
            labelText: s.foodDay,
            prefixIcon: const Icon(Icons.event),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current,
              isExpanded: true,
              items: [
                for (final d in days)
                  DropdownMenuItem<String>(
                    value: dayKey(d),
                    child: Text(foodDayLabel(app, d), overflow: TextOverflow.ellipsis),
                  ),
                DropdownMenuItem<String>(
                  value: _otherDate,
                  child: Text(s.otherDate, style: TextStyle(color: theme.colorScheme.primary)),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                if (v == _otherDate) {
                  _pickOtherDate(context);
                } else {
                  onChangeDay(parseDayKey(v));
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        _SlotField(draft: draft, slot: MealSlot.morning),
        const SizedBox(height: 16),
        _SlotField(draft: draft, slot: MealSlot.afternoon),
        const SizedBox(height: 20),
        if (saved != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: theme.colorScheme.outline),
                const SizedBox(width: 8),
                Expanded(child: Text(s.foodDayExists, style: theme.textTheme.bodySmall)),
              ],
            ),
          ),
        FilledButton.icon(
          onPressed: draft.isEmpty ? null : onSave,
          icon: const Icon(Icons.check),
          label: Text(s.save),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
      ],
    );
  }
}

/// Campo desplegable de una franja del día, con los alimentos elegidos
/// debajo como etiquetas que se pueden quitar.
class _SlotField extends StatelessWidget {
  const _SlotField({required this.draft, required this.slot});

  final FoodDraft draft;
  final MealSlot slot;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final theme = Theme.of(context);
    final ids = draft.slot(slot);
    final name = mealSlotName(app, slot);
    final summary = ids.isEmpty ? s.chooseFoods : s.foodCount(ids.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: '$name: ${ids.isEmpty ? s.noFoods : s.foodCount(ids.length)}',
          excludeSemantics: true,
          child: InkWell(
            key: ValueKey('food-slot-${slot.name}'),
            borderRadius: BorderRadius.circular(4),
            onTap: () => showFoodPicker(context, draft, slot),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: name,
                prefixIcon: Icon(mealSlotIcon(slot)),
                suffixIcon: const Icon(Icons.arrow_drop_down),
                border: const OutlineInputBorder(),
              ),
              child: Text(
                summary,
                style: ids.isEmpty
                    ? theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor)
                    : theme.textTheme.bodyLarge,
              ),
            ),
          ),
        ),
        if (ids.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final id in ids)
                  InputChip(
                    label: Text(app.foodName(id)),
                    onDeleted: () => draft.remove(slot, id),
                    deleteButtonTooltipMessage: '${s.removeFood} · ${app.foodName(id)}',
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// -------------------------------------------------------------- Historial
class _FoodHistoryTab extends StatelessWidget {
  const _FoodHistoryTab({
    required this.filter,
    required this.onFilter,
    required this.onOpen,
    required this.onLogNow,
  });

  final String? filter;
  final ValueChanged<String?> onFilter;
  final ValueChanged<FoodDay> onOpen;
  final VoidCallback onLogNow;

  Future<void> _pickFilter(BuildContext context) async {
    final app = AppScope.read(context);
    final s = app.strings;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(s.filterByFood, style: Theme.of(ctx).textTheme.titleLarge),
                ),
              ),
              const Divider(),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final f in app.usedFoods)
                      ListTile(
                        title: Text(app.foodName(f.id)),
                        trailing: f.id == filter ? const Icon(Icons.check) : null,
                        onTap: () => Navigator.of(ctx).pop(f.id),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen != null) onFilter(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final theme = Theme.of(context);
    final all = app.foodDays;
    if (all.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restaurant, size: 48, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              Text(s.foodEmpty, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onLogNow,
                icon: const Icon(Icons.edit_note),
                label: Text(s.foodLogNow),
              ),
            ],
          ),
        ),
      );
    }
    final wanted = filter;
    final active = wanted != null && app.foodById(wanted) != null ? wanted : null;
    final days = active == null ? all : [for (final d in all) if (d.contains(active)) d];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: active == null
                ? ActionChip(
                    avatar: const Icon(Icons.filter_list, size: 18),
                    label: Text(s.filterByFood),
                    onPressed: () => _pickFilter(context),
                  )
                : InputChip(
                    avatar: const Icon(Icons.filter_list, size: 18),
                    label: Text(app.foodName(active)),
                    onPressed: () => _pickFilter(context),
                    onDeleted: () => onFilter(null),
                    deleteButtonTooltipMessage: s.clearFilter,
                  ),
          ),
        ),
        Expanded(
          child: days.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(s.noDaysWithFood, style: theme.textTheme.bodyLarge),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: days.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) =>
                      _FoodDayTile(day: days[i], onTap: () => onOpen(days[i])),
                ),
        ),
      ],
    );
  }
}

class _FoodDayTile extends StatelessWidget {
  const _FoodDayTile({required this.day, required this.onTap});

  final FoodDay day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final theme = Theme.of(context);
    String names(List<String> ids) => ids.map(app.foodName).join(', ');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(foodDayLabel(app, day.date), style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(s.foodCount(day.foods.length), style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                    if (day.morning.isNotEmpty)
                      Text(
                        '${s.morning}: ${names(day.morning)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (day.afternoon.isNotEmpty)
                      Text(
                        '${s.afternoon}: ${names(day.afternoon)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
