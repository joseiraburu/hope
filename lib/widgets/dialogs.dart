// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../core/version.dart';
import '../models/pain_record.dart';
import '../state/app_controller.dart';
import 'logo.dart';

/// Pide confirmación. Devuelve true si se acepta.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
}) async {
  final s = AppScope.read(context).strings;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(s.cancel)),
        FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(confirmLabel)),
      ],
    ),
  );
  return ok ?? false;
}

/// Edita la nota de un registro.
Future<void> editRecordNote(BuildContext context, PainRecord record) async {
  final app = AppScope.read(context);
  final s = app.strings;
  final controller = TextEditingController(text: record.note);
  final text = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s.note),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 500,
        maxLines: 4,
        minLines: 2,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: s.noteHint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(s.cancel)),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
          child: Text(s.save),
        ),
      ],
    ),
  );
  controller.dispose();
  if (text == null) return;
  final current = app.recordById(record.id) ?? record;
  await app.updateRecord(current.copyWith(note: text));
}

/// Ventana «Acerca de» con el aviso médico y la licencia.
void showHopeAbout(BuildContext context) {
  final s = AppScope.read(context).strings;
  showAboutDialog(
    context: context,
    applicationName: 'HOPE',
    applicationVersion: '${s.version} $appVersion',
    applicationIcon: const HopeLogo(size: 56),
    applicationLegalese: s.license,
    children: [
      const SizedBox(height: 16),
      Text(s.medicalDisclaimer),
      const SizedBox(height: 12),
      Text(s.dataLocal),
      const SizedBox(height: 12),
      Text(s.photosensitivity),
      const SizedBox(height: 12),
      const SelectableText(repositoryUrl),
    ],
  );
}
