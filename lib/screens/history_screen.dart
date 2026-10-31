// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../animation/pain_scene.dart';
import '../core/body_geometry.dart';
import '../core/config.dart';
import '../models/pain_record.dart';
import '../state/app_controller.dart';
import '../state/pain_state.dart';
import '../utils/format.dart';
import '../widgets/body_figure.dart';
import '../widgets/dialogs.dart';
import 'home_screen.dart';
import 'record_player_screen.dart';

/// Acciones posibles sobre un registro del histórico.
enum RecordAction { edit, duplicate, delete }

/// Lista de registros, del más reciente al más antiguo.
///
/// Si el usuario elige «usar como punto de partida», la pantalla se cierra
/// devolviendo ese registro.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  AnimationController? _clock;
  DateTimeRange? _range;
  final Map<PainRecord, PainScene> _scenes = Map.identity();

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
    _clock?.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final records = _filtered(app.records);
    final range = _range;

    // Libera escenas de registros que ya no existen o han cambiado.
    final alive = Set<PainRecord>.identity()..addAll(app.records);
    _scenes.removeWhere((r, _) => !alive.contains(r));

    return Scaffold(
      appBar: AppBar(
        title: Text(s.history),
        actions: [
          IconButton(
            tooltip: s.filterDates,
            icon: const Icon(Icons.date_range),
            onPressed: _pickRange,
          ),
          IconButton(
            tooltip: s.addPastRecord,
            icon: const Icon(Icons.more_time),
            onPressed: _addPastRecord,
          ),
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
            child: records.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        app.records.isEmpty ? s.historyEmpty : s.noResultsInRange,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  )
                : ListView.separated(
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
                  ),
          ),
        ],
      ),
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
