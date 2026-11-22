// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../charts/full_report.dart';
import '../charts/full_report_text.dart';
import '../data/backup.dart';
import '../data/merge.dart';
import '../services/reminders.dart';
import '../state/app_controller.dart';
import '../utils/format.dart';
import '../widgets/dialogs.dart';
import 'full_export_html.dart';
import 'share_service.dart';

/// Todos los datos del dispositivo, como en la copia de seguridad.
BackupData currentData(AppController app) => BackupData(
      records: app.records,
      treatments: app.treatments,
      medications: app.medicationEntries,
      settings: app.settings,
      foods: app.foodEntries,
      foodDays: app.foodDays,
      sleep: app.sleepEntries,
      bowel: app.bowelEntries,
    );

/// Exporta todos los datos a un archivo JSON y lo comparte o guarda.
Future<void> exportBackup(BuildContext context) async {
  final app = AppScope.read(context);
  final s = app.strings;
  if (!await confirmHealthDataShare(context)) return;
  final text = encodeBackup(currentData(app));
  final file = await writeExportFile('HOPE_copia_${isoDate(DateTime.now())}.json', utf8.encode(text));
  if (!context.mounted) return;
  await deliverFile(context, file, mimeType: 'application/json', subject: 'HOPE · ${s.backup}');
}

/// Escribe el informe completo en HTML (legible y con los datos para
/// importarlos en otro dispositivo).
String buildFullExport(AppController app, {DateTime? now}) {
  final at = now ?? DateTime.now();
  final summary = ReportWriter(
    report: buildFullReport(
      records: app.records,
      foodDays: app.foodDays,
      sleep: app.sleepEntries,
      bowel: app.bowelEntries,
      config: app.config,
      periodDays: fullExportSummaryDays,
      now: at,
    ),
    s: app.strings,
    lang: app.language,
    config: app.config,
    foodName: app.foodName,
  );
  return fullExportHtml(FullExportInput(
    data: currentData(app),
    config: app.config,
    s: app.strings,
    lang: app.language,
    foodName: app.foodName,
    medicationName: app.treatmentMedicationName,
    summary: summary,
    now: at,
  ));
}

/// Exporta el informe completo (un solo archivo .html) y lo comparte o
/// guarda: sirve para el médico y para cargarlo en otro dispositivo.
Future<void> exportFullReport(BuildContext context) async {
  final app = AppScope.read(context);
  final s = app.strings;
  if (!await confirmHealthDataShare(context)) return;
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    final now = DateTime.now();
    final html = buildFullExport(app, now: now);
    final file = await writeExportFile(fullExportFileName(now), utf8.encode(html));
    if (!context.mounted) return;
    await deliverFile(context, file, mimeType: 'text/html', subject: s.fullReportTitle);
  } catch (_) {
    messenger?.showSnackBar(SnackBar(content: Text(s.exportFailed)));
  }
}

/// Cómo cargar un archivo importado.
enum ImportMode { merge, replace }

/// Importa un archivo exportado por HOPE (informe completo .html o copia de
/// seguridad .json, de esta versión o de las anteriores).
///
/// 1. Se elige el archivo y se comprueba antes de cargar nada.
/// 2. Se muestra lo que contiene y se pregunta si combinarlo con los datos
///    del dispositivo o reemplazarlos.
/// 3. Para reemplazar se pide una confirmación más.
/// 4. Se indica cuántos registros se han cargado, o el error.
Future<void> importBackup(BuildContext context) async {
  final app = AppScope.read(context);
  final s = app.strings;
  final messenger = ScaffoldMessenger.maybeOf(context);
  const group = XTypeGroup(
    label: 'HOPE',
    extensions: ['html', 'htm', 'json'],
    mimeTypes: ['text/html', 'application/json', 'text/plain', 'application/octet-stream'],
    uniformTypeIdentifiers: ['public.html', 'public.json', 'public.plain-text', 'public.data'],
  );
  final XFile? picked;
  try {
    picked = await openFile(acceptedTypeGroups: const [group]);
  } catch (_) {
    messenger?.showSnackBar(SnackBar(content: Text(s.importReadError)));
    return;
  }
  if (picked == null) return;

  BackupData? decoded;
  try {
    decoded = decodeExportFile(await picked.readAsString());
  } catch (_) {
    decoded = null;
  }
  if (decoded == null) {
    messenger?.showSnackBar(SnackBar(content: Text(s.importInvalid)));
    return;
  }
  final data = decoded;
  final fileName = picked.name;
  if (!context.mounted) return;

  final mode = await showDialog<ImportMode>(
    context: context,
    builder: (_) => _ImportChoiceDialog(data: data, fileName: fileName),
  );
  if (mode == null || !context.mounted) return;

  if (mode == ImportMode.replace) {
    final ok = await confirmAction(
      context,
      title: s.importReplace,
      message: s.importReplaceConfirm,
      confirmLabel: s.replaceLabel,
    );
    if (!ok) return;
  }

  try {
    final String message;
    if (mode == ImportMode.replace) {
      await app.replaceAll(
        records: data.records,
        treatments: data.treatments,
        medications: data.medications,
        // La clave del servicio de IA no viaja en la copia: se conserva la del
        // dispositivo.
        settings: data.settings?.copyWith(firstRunDone: true, aiKey: app.settings.aiKey),
        foods: data.foods,
        foodDays: data.foodDays,
        sleep: data.sleep,
        bowel: data.bowel,
      );
      message = s.importDoneReplace(s.dataCounts(DataCounts.of(data)));
    } else {
      final merged = mergeBackup(currentData(app), data);
      final m = merged.data;
      await app.replaceAll(
        records: m.records,
        treatments: m.treatments,
        medications: m.medications,
        foods: m.foods,
        foodDays: m.foodDays,
        sleep: m.sleep,
        bowel: m.bowel,
      );
      message = merged.added.total == 0 && merged.updated == 0
          ? s.importNothingNew
          : s.importDoneMerge(s.dataCounts(merged.added), merged.updated);
    }
    await ReminderService.instance.reschedule(app.settings.reminders, app.strings);
    if (!context.mounted) {
      messenger?.showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline),
        title: Text(s.importDoneTitle),
        content: Text(message),
        actions: [
          FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(s.accept)),
        ],
      ),
    );
  } catch (_) {
    messenger?.showSnackBar(SnackBar(content: Text(s.importFailed)));
  }
}

/// Qué contiene el archivo y cómo cargarlo.
class _ImportChoiceDialog extends StatelessWidget {
  const _ImportChoiceDialog({required this.data, required this.fileName});

  final BackupData data;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final theme = Theme.of(context);
    final version = data.createdWith;
    final date = data.exportedAt;
    return AlertDialog(
      title: Text(s.importChooseTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fileName, style: theme.textTheme.titleSmall),
            if (version != null || date != null)
              Text(
                s.importFileFrom(version ?? '?', date == null ? '?' : formatDateTime(date, app.language)),
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            Text(s.importFileContains(s.dataCounts(DataCounts.of(data)))),
            const SizedBox(height: 16),
            _ModeButton(
              icon: Icons.merge_type,
              title: s.importMerge,
              help: s.importMergeHelp,
              primary: true,
              onTap: () => Navigator.of(context).pop(ImportMode.merge),
            ),
            const SizedBox(height: 8),
            _ModeButton(
              icon: Icons.swap_horiz,
              title: s.importReplace,
              help: s.importReplaceHelp,
              onTap: () => Navigator.of(context).pop(ImportMode.replace),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(s.cancel)),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.title,
    required this.help,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String help;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: primary ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: primary ? scheme.onPrimaryContainer : scheme.onSurface),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: primary ? scheme.onPrimaryContainer : scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      help,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: primary ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
