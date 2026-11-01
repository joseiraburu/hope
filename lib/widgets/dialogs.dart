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

/// Diálogo con un campo de texto. Guarda su propio controlador para no
/// liberarlo mientras el diálogo aún se está cerrando.
class TextInputDialog extends StatefulWidget {
  const TextInputDialog({
    super.key,
    required this.title,
    this.label,
    this.hint,
    this.initial = '',
    this.maxLength,
    this.multiline = false,
    this.numeric = false,
    this.helper,
  });

  final String title;
  final String? label;
  final String? hint;
  final String initial;
  final int? maxLength;
  final bool multiline;
  final bool numeric;
  final String? helper;

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    final s = AppScope.read(context).strings;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: widget.maxLength,
        minLines: widget.multiline ? 2 : 1,
        maxLines: widget.multiline ? 4 : 1,
        keyboardType: widget.numeric ? TextInputType.number : null,
        textCapitalization:
            widget.numeric ? TextCapitalization.none : TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          helperText: widget.helper,
        ),
        onSubmitted: widget.multiline ? null : (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(s.cancel)),
        FilledButton(onPressed: _submit, child: Text(s.accept)),
      ],
    );
  }
}

/// Pide un texto. Devuelve null si se cancela.
Future<String?> askText(
  BuildContext context, {
  required String title,
  String? label,
  String? hint,
  String initial = '',
  int? maxLength,
  bool multiline = false,
  bool numeric = false,
  String? helper,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => TextInputDialog(
      title: title,
      label: label,
      hint: hint,
      initial: initial,
      maxLength: maxLength,
      multiline: multiline,
      numeric: numeric,
      helper: helper,
    ),
  );
}

/// Edita la nota de un registro.
Future<void> editRecordNote(BuildContext context, PainRecord record) async {
  final app = AppScope.read(context);
  final s = app.strings;
  final text = await askText(
    context,
    title: s.note,
    hint: s.noteHint,
    initial: record.note,
    maxLength: 500,
    multiline: true,
  );
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
