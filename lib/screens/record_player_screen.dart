// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../animation/pain_scene.dart';
import '../core/body_geometry.dart';
import '../core/config.dart';
import '../export/record_share.dart';
import '../models/pain_record.dart';
import '../state/app_controller.dart';
import '../state/pain_state.dart';
import '../utils/format.dart';
import '../widgets/body_figure.dart';
import '../widgets/dialogs.dart';
import 'history_screen.dart';

/// Reproduce a pantalla completa la animación de un registro guardado.
///
/// Devuelve una [RecordAction] si el usuario elige editar, usar como punto
/// de partida o borrar.
class RecordPlayerScreen extends StatefulWidget {
  const RecordPlayerScreen({super.key, required this.recordId});

  final String recordId;

  @override
  State<RecordPlayerScreen> createState() => _RecordPlayerScreenState();
}

class _RecordPlayerScreenState extends State<RecordPlayerScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _clock;
  BodyView _view = BodyView.front;
  PainRecord? _sceneRecord;
  PainScene? _scene;

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

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final theme = Theme.of(context);
    final record = app.recordById(widget.recordId);
    if (record == null) {
      return Scaffold(appBar: AppBar());
    }
    if (!identical(record, _sceneRecord)) {
      _sceneRecord = record;
      _scene = sceneForRecord(app.config, record);
    }
    final scene = _scene!;
    final sex = sexFromString(record.sex);
    final types = record.eventTypes
        .map((t) => app.config.eventTypeById[t]?.name(app.language) ?? t)
        .join(', ');

    Widget figure(BodyView v) =>
        BodyFigure(scene: scene, sex: sex, view: v, clock: _clock);

    return Scaffold(
      appBar: AppBar(
        title: Text(formatDateTime(record.dateTime, app.language)),
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 700;
          return Column(
            children: [
              if (!wide)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SegmentedButton<BodyView>(
                    segments: [
                      ButtonSegment(value: BodyView.front, label: Text(s.front)),
                      ButtonSegment(value: BodyView.back, label: Text(s.back)),
                    ],
                    selected: {_view},
                    showSelectedIcon: false,
                    onSelectionChanged: (v) => setState(() => _view = v.first),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: wide
                      ? Row(
                          children: [
                            Expanded(child: figure(BodyView.front)),
                            Expanded(child: figure(BodyView.back)),
                          ],
                        )
                      : figure(_view),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      s.painLine(record.painIntensity, record.zoneCount,
                          formatPct(record.surfacePct, app.language)),
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      s.eventsLine(record.eventIntensity, record.eventFrequency),
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (types.isNotEmpty && record.eventIntensity > 0)
                      Text(types, textAlign: TextAlign.center),
                    if (record.note.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          record.note,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => editRecordNote(context, record),
                      icon: const Icon(Icons.edit_note),
                      label: Text(s.note),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(RecordAction.edit),
                      icon: const Icon(Icons.tune),
                      label: Text(s.edit),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(RecordAction.duplicate),
                      icon: const Icon(Icons.content_copy),
                      label: Text(s.duplicate),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => showRecordShareSheet(context, record),
                      icon: const Icon(Icons.share_outlined),
                      label: Text(s.share),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(RecordAction.delete),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(s.delete),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
