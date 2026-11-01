// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../data/backup.dart';
import '../state/app_controller.dart';
import '../utils/format.dart';
import '../widgets/dialogs.dart';
import 'share_service.dart';

/// Exporta todos los datos a un archivo JSON y lo comparte o guarda.
Future<void> exportBackup(BuildContext context) async {
  final app = AppScope.read(context);
  final s = app.strings;
  if (!await confirmHealthDataShare(context)) return;
  final text = encodeBackup(BackupData(
    records: app.records,
    treatments: app.treatments,
    medications: app.medicationEntries,
    settings: app.settings,
  ));
  final file = await writeExportFile('HOPE_copia_${isoDate(DateTime.now())}.json', utf8.encode(text));
  if (!context.mounted) return;
  await deliverFile(context, file, mimeType: 'application/json', subject: 'HOPE · ${s.backup}');
}

/// Importa una copia de seguridad (sustituye los datos tras confirmarlo).
Future<void> importBackup(BuildContext context) async {
  final app = AppScope.read(context);
  final s = app.strings;
  final messenger = ScaffoldMessenger.maybeOf(context);
  const group = XTypeGroup(
    label: 'JSON',
    extensions: ['json'],
    mimeTypes: ['application/json', 'text/plain', 'application/octet-stream'],
    uniformTypeIdentifiers: ['public.json'],
  );
  final XFile? picked;
  try {
    picked = await openFile(acceptedTypeGroups: const [group]);
  } catch (_) {
    messenger?.showSnackBar(SnackBar(content: Text(s.backupInvalid)));
    return;
  }
  if (picked == null) return;
  final data = decodeBackup(await picked.readAsString());
  if (data == null) {
    messenger?.showSnackBar(SnackBar(content: Text(s.backupInvalid)));
    return;
  }
  if (!context.mounted) return;
  final ok = await confirmAction(
    context,
    title: s.backupImport,
    message: s.backupImportQuestion,
    confirmLabel: s.continueLabel,
  );
  if (!ok) return;
  await app.replaceAll(
    records: data.records,
    treatments: data.treatments,
    medications: data.medications,
    settings: data.settings?.copyWith(firstRunDone: true),
  );
  messenger?.showSnackBar(SnackBar(content: Text(s.backupImported(data.records.length, data.treatments.length))));
}
