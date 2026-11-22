// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../animation/pain_scene.dart';
import '../core/body_geometry.dart';
import '../core/config.dart';
import '../export/record_share.dart';
import '../models/bowel.dart';
import '../models/food.dart';
import '../models/pain_record.dart';
import '../models/treatment.dart';
import '../state/app_controller.dart';
import '../state/pain_state.dart';
import '../utils/format.dart';
import '../widgets/body_figure.dart';
import '../widgets/bowel_style.dart';
import '../widgets/dialogs.dart';
import '../widgets/home_action.dart';
import 'bowel_screen.dart';
import 'food_day_screen.dart';
import 'food_screen.dart';
import 'home_screen.dart';
import 'record_player_screen.dart';
import 'sleep_screen.dart';
import 'treatment_editor_screen.dart';

/// Acciones posibles sobre un registro del histórico.
enum RecordAction { edit, duplicate, share, delete }

/// Pestañas del Historial, en orden.
enum HistoryTab { pain, bowel, sleep, food, medication }

/// Historial de todo lo registrado, del más reciente al más antiguo, en una
/// pestaña por sección: dolor, deposiciones, sueño, alimentación y
/// medicación. El filtro de fechas se aplica a todas.
///
/// Si el usuario elige «usar como punto de partida» en un registro de dolor,
/// la pantalla se cierra devolviendo ese registro.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.initialTab = HistoryTab.pain});

  final HistoryTab initialTab;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  AnimationController? _clock;
  DateTimeRange? _range;
  final Map<PainRecord, PainScene> _scenes = Map.identity();
  late final TabController _tabs = TabController(
    length: HistoryTab.values.length,
    vsync: this,
    initialIndex: widget.initialTab.index,
  )..addListener(_onTab);

  void _onTab() {
    if (!_tabs.indexIsChanging && mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_clock != null) return;
    final loop = AppScope.read(context).config.loopSeconds;
    _clock = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (loop * 1000).round()),
    )..repeat();
  }

  @override
  void dispose() {
    _tabs
      ..removeListener(_onTab)
      ..dispose();
    _clock?.dispose();
    super.dispose();
  }

  /// ¿Está [d] dentro del filtro de fechas? (sin filtro, siempre).
  bool _inRange(DateTime d) {
    final range = _range;
    if (range == null) return true;
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day).add(const Duration(days: 1));
    return !d.isBefore(start) && d.isBefore(end);
  }

  bool _treatmentInRange(Treatment t) {
    final range = _range;
    if (range == null) return true;
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day).add(const Duration(days: 1));
    return t.overlaps(start, end);
  }

  PainScene _sceneFor(AppConfig config, PainRecord r) =>
      _scenes.putIfAbsent(r, () => sceneForRecord(config, r));

  List<PainRecord> _filtered(List<PainRecord> all) {
    final range = _range;
    if (range == null) return all;
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day)
        .add(const Duration(days: 1));
    return [
      for (final r in all)
        if (!r.dateTime.isBefore(start) && r.dateTime.isBefore(end)) r
    ];
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day).add(const Duration(days: 1)),
      initialDateRange: _range,
    );
    if (picked != null && mounted) setState(() => _range = picked);
  }

  Future<void> _addPastRecord() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
    if (!mounted) return;
    final when = DateTime(d.year, d.month, d.day, t?.hour ?? 12, t?.minute ?? 0);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HomeScreen(backdatedAt: when)),
    );
  }

  Future<void> handleAction(PainRecord record, RecordAction action) async {
    final app = AppScope.read(context);
    final s = app.strings;
    switch (action) {
      case RecordAction.edit:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => HomeScreen(editing: record)),
        );
      case RecordAction.duplicate:
        Navigator.of(context).pop(record);
      case RecordAction.share:
        await showRecordShareSheet(context, record);
      case RecordAction.delete:
        final ok = await confirmAction(
          context,
          title: s.deleteRecordQuestion,
          message: formatDateTime(record.dateTime, app.language),
          confirmLabel: s.delete,
        );
        if (!ok) return;
        final removed = await app.deleteRecord(record.id);
        if (removed == null || !mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(s.recordDeleted),
            action: SnackBarAction(label: s.undo, onPressed: () => app.addRecord(removed)),
          ));
    }
  }

  Future<void> _openPlayer(PainRecord record) async {
    final action = await Navigator.of(context).push<RecordAction>(
      MaterialPageRoute(builder: (_) => RecordPlayerScreen(recordId: record.id)),
    );
    if (action != null && mounted) {
      final current = AppScope.read(context).recordById(record.id) ?? record;
      await handleAction(current, action);
    }
  }

  Widget _empty(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final range = _range;
    final painTab = _tabs.index == HistoryTab.pain.index;

    // Libera escenas de registros que ya no existen o han cambiado.
    final alive = Set<PainRecord>.identity()..addAll(app.records);
    _scenes.removeWhere((r, _) => !alive.contains(r));

    return Scaffold(
      appBar: AppBar(
        title: Text(s.history),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(key: const ValueKey('history-tab-pain'), text: s.seriesPain),
            Tab(key: const ValueKey('history-tab-bowel'), text: s.bowel),
            Tab(key: const ValueKey('history-tab-sleep'), text: s.sleep),
            Tab(key: const ValueKey('history-tab-food'), text: s.food),
            Tab(key: const ValueKey('history-tab-medication'), text: s.tileMedication),
          ],
        ),
        actions: [
          IconButton(
            tooltip: s.filterDates,
            icon: const Icon(Icons.date_range),
            onPressed: _pickRange,
          ),
          if (painTab)
            IconButton(
              tooltip: s.addPastRecord,
              icon: const Icon(Icons.more_time),
              onPressed: _addPastRecord,
            ),
          const HomeAction(),
        ],
      ),
      body: Column(
        children: [
          if (range != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  label: Text('${formatDate(range.start, app.language)} – '
                      '${formatDate(range.end, app.language)}'),
                  onDeleted: () => setState(() => _range = null),
                  deleteButtonTooltipMessage: s.clearFilter,
                ),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _painList(app),
                _bowelList(app),
                _sleepList(app),
                _foodList(app),
                _treatmentList(app),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- dolor
  Widget _painList(AppController app) {
    final s = app.strings;
    final records = _filtered(app.records);
    if (records.isEmpty) return _empty(app.records.isEmpty ? s.historyEmpty : s.noResultsInRange);
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final r = records[i];
        return _RecordTile(
          record: r,
          scene: _sceneFor(app.config, r),
          clock: _clock,
          onTap: () => _openPlayer(r),
          onAction: (a) => handleAction(r, a),
        );
      },
    );
  }

  // ---------------------------------------------------------- deposiciones
  Future<void> _deleteBowel(BowelEntry e) async {
    final app = AppScope.read(context);
    final s = app.strings;
    final ok = await confirmAction(
      context,
      title: s.deleteBowelQuestion,
      message: '${formatDateTime(e.dateTime, app.language)} · ${s.bowelQualityValue(e.quality)}',
      confirmLabel: s.delete,
    );
    if (!ok) return;
    final removed = await app.deleteBowel(e.id);
    if (removed == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(s.bowelDeleted),
        action: SnackBarAction(label: s.undo, onPressed: () => app.restoreBowel(removed)),
      ));
  }

  Widget _bowelList(AppController app) {
    final s = app.strings;
    final theme = Theme.of(context);
    final entries = [for (final e in app.bowelEntries) if (_inRange(e.dateTime)) e];
    if (entries.isEmpty) {
      return _empty(app.bowelEntries.isEmpty ? s.bowelEmpty : s.historyNothingInRange);
    }
    // Una fila por día con sus deposiciones.
    final days = <String, List<BowelEntry>>{};
    for (final e in entries) {
      days.putIfAbsent(e.dayKeyText, () => []).add(e);
    }
    final groups = days.values.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final list = groups[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
                  child: Text(
                    '${bowelDayLabel(app, list.first.day)} · ${s.bowelCount(list.length)}',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                for (final e in list)
                  ListTile(
                    dense: true,
                    leading: BowelQualityBadge(quality: e.quality, size: 32),
                    title: Text('${formatTime(e.dateTime)} · ${s.bowelQualityName(e.quality)}'),
                    subtitle: e.note.isEmpty ? null : Text(e.note),
                    trailing: IconButton(
                      tooltip: s.delete,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteBowel(e),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => BowelScreen(editing: e)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------------- sueño
  Widget _sleepList(AppController app) {
    final s = app.strings;
    final nights = [for (final e in app.sleepEntries) if (_inRange(e.date)) e];
    if (nights.isEmpty) return _empty(app.sleepEntries.isEmpty ? s.sleepEmpty : s.historyNothingInRange);
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: nights.length,
      itemBuilder: (context, i) {
        final e = nights[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(child: Text('${e.quality}')),
            title: Text(sleepNightLabel(app, e.date)),
            subtitle: Text([
              s.sleepQualityName(e.quality),
              if (e.withPain == true) s.withPain,
              if (e.withPain == false) s.withoutPain,
              if (e.note.isNotEmpty) e.note,
            ].join(' · ')),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => SleepScreen(initialDate: e.date)),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------- alimentación
  Future<void> _openFoodDay(FoodDay day) async {
    final result = await Navigator.of(context).push<FoodDayResult>(
      MaterialPageRoute(builder: (_) => FoodDayScreen(date: day.date)),
    );
    if (result == null || !mounted) return;
    final app = AppScope.read(context);
    final s = app.strings;
    switch (result.action) {
      case FoodDayAction.edit:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => FoodScreen(initialDay: result.day.date)),
        );
      case FoodDayAction.deleted:
        final removed = result.day;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(s.foodDayDeleted),
            action: SnackBarAction(label: s.undo, onPressed: () => app.restoreFoodDay(removed)),
          ));
    }
  }

  Widget _foodList(AppController app) {
    final s = app.strings;
    final theme = Theme.of(context);
    final days = [for (final d in app.foodDays) if (_inRange(d.date)) d];
    if (days.isEmpty) return _empty(app.foodDays.isEmpty ? s.foodEmpty : s.historyNothingInRange);
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: days.length,
      itemBuilder: (context, i) {
        final d = days[i];
        final lines = [
          for (final slot in MealSlot.values)
            if (d.isSkipped(slot))
              s.mealSkippedLine(s.meal(slot))
            else if (d.slot(slot).isNotEmpty)
              s.mealLine(s.meal(slot), d.meal(slot).time, d.slot(slot).map(app.foodName).join(', ')),
        ];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.restaurant),
            title: Text(formatDayLong(d.date, app.language)),
            subtitle: Text(lines.join('\n'), style: theme.textTheme.bodySmall),
            isThreeLine: lines.length > 1,
            onTap: () => _openFoodDay(d),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------ medicación
  Widget _treatmentList(AppController app) {
    final s = app.strings;
    final lang = app.language;
    final theme = Theme.of(context);
    final list = [for (final t in app.treatments) if (_treatmentInRange(t)) t];
    if (list.isEmpty) return _empty(app.treatments.isEmpty ? s.noTreatments : s.historyNothingInRange);
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final t = list[i];
        final dates = t.end == null
            ? '${formatDateTime(t.start, lang)} · ${s.punctual}'
            : '${formatDate(t.start, lang)} – ${formatDate(t.end!, lang)}';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.medication_outlined),
            title: Text(
              '${app.treatmentMedicationName(t)} · ${formatDose(t.dose, app.config.unitName(t.unit, lang), lang)}',
            ),
            subtitle: Text(
              '${app.config.routeName(t.route, lang)}\n$dates',
              style: theme.textTheme.bodySmall,
            ),
            isThreeLine: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => TreatmentEditorScreen(editing: t)),
            ),
          ),
        );
      },
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.record,
    required this.scene,
    required this.clock,
    required this.onTap,
    required this.onAction,
  });

  final PainRecord record;
  final PainScene scene;
  final Animation<double>? clock;
  final VoidCallback onTap;
  final ValueChanged<RecordAction> onAction;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final theme = Theme.of(context);
    final types = record.eventTypes
        .map((t) => app.config.eventTypeById[t]?.name(app.language) ?? t)
        .join(', ');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 52,
                height: 120,
                child: BodyFigure(
                  scene: scene,
                  sex: sexFromString(record.sex),
                  view: BodyView.front,
                  clock: clock,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatDateTime(record.dateTime, app.language),
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(s.painLine(record.painIntensity, record.zoneCount,
                        formatPct(record.surfacePct, app.language))),
                    Text(s.eventsLine(record.eventIntensity, record.eventFrequency)),
                    if (types.isNotEmpty && record.eventIntensity > 0)
                      Text(types, style: theme.textTheme.bodySmall),
                    if (record.note.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          record.note,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<RecordAction>(
                onSelected: onAction,
                itemBuilder: (_) => [
                  PopupMenuItem(value: RecordAction.edit, child: Text(s.edit)),
                  PopupMenuItem(value: RecordAction.duplicate, child: Text(s.duplicate)),
                  PopupMenuItem(value: RecordAction.share, child: Text(s.share)),
                  PopupMenuItem(value: RecordAction.delete, child: Text(s.delete)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
