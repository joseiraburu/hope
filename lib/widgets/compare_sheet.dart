// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../charts/compare.dart';
import '../charts/params.dart';
import '../models/treatment.dart';
import '../state/app_controller.dart';
import '../utils/format.dart';

/// Hoja que compara las medias de los días anteriores y posteriores al
/// inicio de un tratamiento. Es solo descriptiva.
Future<void> showCompareSheet(BuildContext context, Treatment treatment) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => CompareSheet(treatment: treatment),
  );
}

class CompareSheet extends StatefulWidget {
  const CompareSheet({super.key, required this.treatment});

  final Treatment treatment;

  @override
  State<CompareSheet> createState() => _CompareSheetState();
}

class _CompareSheetState extends State<CompareSheet> {
  int _days = 14;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final lang = app.language;
    final theme = Theme.of(context);
    final t = widget.treatment;
    final result = compareAround(app.records, t.start, _days);

    String cell(Param p, Stat? st) =>
        st?.mean == null ? '—' : formatParam(p, st!.mean!, lang);

    TableRow row(List<String> cells, {bool header = false}) => TableRow(
          decoration: header
              ? BoxDecoration(
                  border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
                )
              : null,
          children: [
            for (var i = 0; i < cells.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Text(
                  cells[i],
                  textAlign: i == 0 ? TextAlign.start : TextAlign.end,
                  style: header
                      ? theme.textTheme.labelLarge
                      : (i == 0 ? theme.textTheme.bodyMedium : theme.textTheme.bodyLarge),
                ),
              ),
          ],
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.compareBeforeAfter, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '${app.treatmentMedicationName(t)} · '
              '${formatDose(t.dose, app.config.unitName(t.unit, lang), lang)} · '
              '${formatDateTime(t.start, lang)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: [
                for (final d in const [7, 14, 28]) ButtonSegment(value: d, label: Text(s.days(d))),
              ],
              selected: {_days},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() => _days = v.first),
            ),
            const SizedBox(height: 12),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.2),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.1),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                row([s.parameter, s.before, s.after, s.change], header: true),
                for (final p in Param.values)
                  row([
                    paramName(p, s),
                    cell(p, result.before[p]),
                    cell(p, result.after[p]),
                    result.change(p) == null ? '—' : formatParamChange(p, result.change(p)!, lang),
                  ]),
                row([s.records, '${result.recordsBefore}', '${result.recordsAfter}', '']),
              ],
            ),
            const SizedBox(height: 12),
            Text(s.compareWindow(_days), style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.causalDisclaimer, style: theme.textTheme.bodySmall)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
