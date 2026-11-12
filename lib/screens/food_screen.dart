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
import 'sleep_screen.dart';

/// Días que ofrece la lista desplegable (hoy y los anteriores).
const int foodDayChoices = 30;

/// Pestaña Alimentación: registrar lo que se come en las cinco tomas del día
/// (desayuno, almuerzo, comida, merienda y cena), e historial por días.
class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key, this.initialTab = 0, this.initialSlot});

  /// 0 = Registrar, 1 = Historial.
  final int initialTab;

  /// Toma que se resalta al abrir (desde un recordatorio).
  final MealSlot? initialSlot;

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs =
      TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
  FoodDraft? _draft;

  /// Alimento por el que se filtra el historial.
  String? _filter;

  /// Para llevar a la vista la toma de un recordatorio.
  final Map<MealSlot, GlobalKey> _slotKeys = {for (final s in MealSlot.values) s: GlobalKey()};

  FoodDraft get _d => _draft!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_draft != null) return;
    final app = AppScope.read(context);
    final today = dayOf(DateTime.now());
    _draft = FoodDraft(today)..load(today, app.foodDayFor(today));
    final slot = widget.initialSlot;
    if (slot != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _slotKeys[slot]?.currentContext;
        if (target != null && target.mounted) {
          Scrollable.ensureVisible(
            target,
            alignment: 0.2,
            duration: const Duration(milliseconds: 300),
          );
        }
      });
    }
  }

  /// Vuelve a la pantalla principal para evaluar el dolor.
  Future<void> _ratePain() async {
    if (!await _confirmDiscard() || !mounted) return;
    _d.load(_d.day, AppScope.read(context).foodDayFor(_d.day));
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openSleep() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SleepScreen()));
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
              _FoodLogTab(
                draft: _d,
                onChangeDay: _changeDay,
                onSave: _save,
                slotKeys: _slotKeys,
                highlight: widget.initialSlot,
                onRatePain: _ratePain,
                onLogSleep: _openSleep,
              ),
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
  const _FoodLogTab({
    required this.draft,
    required this.onChangeDay,
    required this.onSave,
    required this.slotKeys,
    required this.highlight,
    required this.onRatePain,
    required this.onLogSleep,
  });

  final FoodDraft draft;
  final Future<void> Function(DateTime day) onChangeDay;
  final Future<void> Function() onSave;
  final Map<MealSlot, GlobalKey> slotKeys;
  final MealSlot? highlight;
  final VoidCallback onRatePain;
  final VoidCallback onLogSleep;

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

    // Se construyen todas las tomas (no una lista perezosa) para poder llevar
    // a la vista la de un recordatorio.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          if (draft.isToday) ...[
            CompleteHopeCard(
              draft: draft,
              reminderSlot: highlight,
              onRatePain: onRatePain,
              onLogSleep: onLogSleep,
            ),
            const SizedBox(height: 20),
          ],
          for (final slot in MealSlot.values) ...[
            _SlotField(
              key: slotKeys[slot],
              draft: draft,
              slot: slot,
              highlighted: slot == highlight && draft.isToday,
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 4),
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
      ),
    );
  }
}

/// Campo desplegable de una toma, con los alimentos elegidos debajo como
/// etiquetas que se pueden quitar, su hora y la casilla «No realizada».
class _SlotField extends StatelessWidget {
  const _SlotField({
    super.key,
    required this.draft,
    required this.slot,
    this.highlighted = false,
  });

  final FoodDraft draft;
  final MealSlot slot;

  /// Toma de un recordatorio: se resalta.
  final bool highlighted;

  Future<void> _pickTime(BuildContext context) async {
    final current = draft.time(slot) ?? slot.defaultTime;
    final parts = current.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
    );
    if (picked == null) return;
    draft.setTime(slot, '${picked.hour}:${picked.minute}');
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final theme = Theme.of(context);
    final ids = draft.slot(slot);
    final skipped = draft.isSkipped(slot);
    final time = draft.time(slot);
    final name = mealSlotName(app, slot);
    final summary = skipped ? s.mealSkipped : (ids.isEmpty ? s.chooseFoods : s.foodCount(ids.length));
    final border = highlighted
        ? OutlineInputBorder(borderSide: BorderSide(color: theme.colorScheme.primary, width: 2))
        : const OutlineInputBorder();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: '$name: ${skipped ? s.mealSkipped : (ids.isEmpty ? s.noFoods : s.foodCount(ids.length))}',
          excludeSemantics: true,
          child: InkWell(
            key: ValueKey('food-slot-${slot.key}'),
            borderRadius: BorderRadius.circular(4),
            onTap: () => showFoodPicker(context, draft, slot),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: name,
                prefixIcon: Icon(mealSlotIcon(slot)),
                suffixIcon: const Icon(Icons.arrow_drop_down),
                border: border,
                enabledBorder: border,
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
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            if (!skipped)
              ActionChip(
                key: ValueKey('food-time-${slot.key}'),
                avatar: const Icon(Icons.schedule, size: 18),
                label: Text(time ?? s.noMealTime),
                tooltip: s.mealTimeTooltip(name),
                onPressed: () => _pickTime(context),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  key: ValueKey('food-skip-${slot.key}'),
                  value: skipped,
                  onChanged: (v) => draft.setSkipped(slot, v ?? false),
                ),
                GestureDetector(
                  onTap: () => draft.setSkipped(slot, !skipped),
                  child: Text(s.mealSkipped, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ],
        ),
        if (ids.isNotEmpty)
          Wrap(
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
      ],
    );
  }
}

/// Tarjeta «Completa HOPE»: lo registrado hoy (dolor, sueño de anoche y
/// comidas) con accesos directos a lo que falta.
class CompleteHopeCard extends StatelessWidget {
  const CompleteHopeCard({
    super.key,
    required this.draft,
    required this.onRatePain,
    required this.onLogSleep,
    this.reminderSlot,
  });

  final FoodDraft draft;
  final VoidCallback onRatePain;
  final VoidCallback onLogSleep;

  /// Toma del recordatorio que abrió la pantalla.
  final MealSlot? reminderSlot;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final theme = Theme.of(context);
    final today = dayOf(DateTime.now());
    final pain = app.recordsOn(today);
    final sleep = app.sleepFor(today);
    var eaten = 0;
    var skipped = 0;
    for (final slot in MealSlot.values) {
      if (draft.isSkipped(slot)) {
        skipped++;
      } else if (draft.slot(slot).isNotEmpty) {
        eaten++;
      }
    }
    Widget row({
      required bool ok,
      required String title,
      required String subtitle,
      String? action,
      VoidCallback? onAction,
    }) =>
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                ok ? Icons.check_circle : Icons.radio_button_unchecked,
                color: ok ? theme.colorScheme.primary : theme.colorScheme.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                    if (action != null)
                      TextButton.icon(
                        onPressed: onAction,
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: Text(action),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
    final slot = reminderSlot;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.notifications_active_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.completeHope,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Text(
                slot == null ? s.completeHopeHelp : '${s.reminderFor(s.meal(slot))} · ${s.completeHopeHelp}',
                style: theme.textTheme.bodySmall,
              ),
            ),
            row(
              ok: pain.isNotEmpty,
              title: s.checkPain,
              subtitle: pain.isEmpty ? s.painNotLoggedToday : s.painLoggedAt(formatTime(pain.first.dateTime)),
              action: pain.isEmpty ? s.ratePainNow : null,
              onAction: onRatePain,
            ),
            row(
              ok: sleep != null,
              title: s.checkSleep,
              subtitle: sleep == null ? s.notLogged : s.sleepQualityValue(sleep.quality),
              action: sleep == null ? s.logSleepNow : null,
              onAction: onLogSleep,
            ),
            row(
              ok: eaten + skipped == MealSlot.values.length,
              title: s.checkMeals,
              subtitle: s.mealsDone(eaten, skipped),
            ),
          ],
        ),
      ),
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
                    for (final slot in MealSlot.values)
                      if (day.isSkipped(slot))
                        Text(s.mealSkippedLine(s.meal(slot)), maxLines: 1, overflow: TextOverflow.ellipsis)
                      else if (day.slot(slot).isNotEmpty)
                        Text(
                          s.mealLine(s.meal(slot), day.meal(slot).time, names(day.slot(slot))),
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
