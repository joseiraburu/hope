// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../models/treatment.dart';
import '../state/app_controller.dart';
import '../utils/format.dart';
import '../widgets/compare_sheet.dart';
import '../widgets/dialogs.dart';
import 'medications_screen.dart';
import 'treatment_editor_screen.dart';

/// Acciones sobre un tratamiento.
enum TreatmentAction { edit, duplicate, compare, delete }

/// Lista de tratamientos, del más reciente al más antiguo.
class TreatmentsScreen extends StatefulWidget {
  const TreatmentsScreen({super.key});

  @override
  State<TreatmentsScreen> createState() => _TreatmentsScreenState();
}

class _TreatmentsScreenState extends State<TreatmentsScreen> {
  /// Medicamento por el que se filtra (null = todos).
  String? _filter;

  Future<void> _openEditor({Treatment? editing, Treatment? template}) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TreatmentEditorScreen(editing: editing, template: template),
    ));
  }

  Future<void> _handle(Treatment t, TreatmentAction action) async {
    final app = AppScope.read(context);
    final s = app.strings;
    switch (action) {
      case TreatmentAction.edit:
        await _openEditor(editing: t);
      case TreatmentAction.duplicate:
        await _openEditor(template: t);
      case TreatmentAction.compare:
        await showCompareSheet(context, t);
      case TreatmentAction.delete:
        final ok = await confirmAction(
          context,
          title: s.deleteTreatmentQuestion,
          message: '${app.treatmentMedicationName(t)} · ${formatDateTime(t.start, app.language)}',
          confirmLabel: s.delete,
        );
        if (!ok) return;
        final removed = await app.deleteTreatment(t.id);
        if (removed == null || !mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(s.treatmentDeleted),
            action: SnackBarAction(label: s.undo, onPressed: () => app.addTreatment(removed)),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final all = app.treatments;
    final usedIds = {for (final t in all) t.medicationId};
    final filter = usedIds.contains(_filter) ? _filter : null;
    final list = filter == null ? all : [for (final t in all) if (t.medicationId == filter) t];

    return Scaffold(
      appBar: AppBar(
        title: Text(s.treatments),
        actions: [
          IconButton(
            tooltip: s.medications,
            icon: const Icon(Icons.medication_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MedicationsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: Text(s.addTreatment),
      ),
      body: Column(
        children: [
          if (usedIds.length > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(s.allMedications),
                    selected: filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                  for (final m in app.medications)
                    if (usedIds.contains(m.id)) ...[
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(app.medicationName(m.id)),
                        selected: filter == m.id,
                        onSelected: (_) => setState(() => _filter = m.id),
                      ),
                    ],
                ],
              ),
            ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        s.noTreatments,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => TreatmentCard(
                      treatment: list[i],
                      onTap: () => _handle(list[i], TreatmentAction.edit),
                      onAction: (a) => _handle(list[i], a),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta con el resumen de un tratamiento.
class TreatmentCard extends StatelessWidget {
  const TreatmentCard({
    super.key,
    required this.treatment,
    this.onTap,
    this.onAction,
  });

  final Treatment treatment;
  final VoidCallback? onTap;
  final ValueChanged<TreatmentAction>? onAction;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final lang = app.language;
    final theme = Theme.of(context);
    final t = treatment;
    final effects = [
      for (final e in t.adverseEffects) app.config.adverseEffectName(e, lang),
      if (t.adverseOther.trim().isNotEmpty) t.adverseOther.trim(),
    ];
    final when = t.isPunctual
        ? '${s.punctual} · ${formatDateTime(t.start, lang)}'
        : '${formatDateTime(t.start, lang)} – ${formatDateTime(t.end!, lang)}';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${app.treatmentMedicationName(t)} · ${formatDose(t.dose, app.config.unitName(t.unit, lang), lang)}',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(app.config.routeName(t.route, lang), style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(when, style: theme.textTheme.bodySmall),
                    if (t.schedule.trim().isNotEmpty)
                      Text('${s.schedule}: ${t.schedule.trim()}', style: theme.textTheme.bodySmall),
                    if (effects.isNotEmpty)
                      Text('${s.adverseEffects}: ${effects.join(', ')}',
                          style: theme.textTheme.bodySmall),
                    if (t.notes.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          t.notes.trim(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              ),
              if (onAction != null)
                PopupMenuButton<TreatmentAction>(
                  onSelected: onAction,
                  itemBuilder: (_) => [
                    PopupMenuItem(value: TreatmentAction.edit, child: Text(s.edit)),
                    PopupMenuItem(value: TreatmentAction.duplicate, child: Text(s.duplicateTreatment)),
                    PopupMenuItem(value: TreatmentAction.compare, child: Text(s.compareBeforeAfter)),
                    PopupMenuItem(value: TreatmentAction.delete, child: Text(s.delete)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
