// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/pain_record.dart';
import '../state/app_controller.dart';
import '../utils/format.dart';
import 'record_card.dart';
import 'record_export.dart';
import 'share_service.dart';

/// Formatos para compartir un registro.
enum RecordFormat { png, gif, mp4 }

RecordFormat _formatFrom(String id) => switch (id) {
      'gif' => RecordFormat.gif,
      'mp4' => RecordFormat.mp4,
      _ => RecordFormat.png,
    };

/// Hoja para compartir un registro como imagen, GIF o vídeo.
Future<void> showRecordShareSheet(BuildContext context, PainRecord record) async {
  final format = await showModalBottomSheet<RecordFormat>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _RecordShareSheet(record: record),
  );
  if (format == null || !context.mounted) return;
  await shareRecord(context, record, format);
}

class _RecordShareSheet extends StatelessWidget {
  const _RecordShareSheet({required this.record});

  final PainRecord record;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final theme = Theme.of(context);
    final last = _formatFrom(app.settings.lastShareFormat);

    Widget option(RecordFormat f, IconData icon, String title, String help) {
      final selected = f == last;
      return ListTile(
        leading: Icon(icon, color: selected ? theme.colorScheme.primary : null),
        title: Text(title, style: selected ? TextStyle(color: theme.colorScheme.primary) : null),
        subtitle: Text(help),
        selected: selected,
        onTap: () => Navigator.of(context).pop(f),
      );
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(s.shareRecordTitle, style: theme.textTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(formatDateTime(record.dateTime, app.language), style: theme.textTheme.bodyMedium),
          ),
          option(RecordFormat.png, Icons.image_outlined, s.formatImage, s.formatImageHelp),
          option(RecordFormat.gif, Icons.gif_box_outlined, s.formatGif, s.formatGifHelp),
          option(RecordFormat.mp4, Icons.movie_outlined, s.formatVideo, s.formatVideoHelp),
          SwitchListTile(
            title: Text(s.hideDate),
            value: app.settings.hideDateInExports,
            onChanged: (v) => app.updateSettings(app.settings.copyWith(hideDateInExports: v)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Genera el archivo del registro y lo comparte.
Future<void> shareRecord(BuildContext context, PainRecord record, RecordFormat format) async {
  final app = AppScope.read(context);
  final s = app.strings;
  if (!await confirmHealthDataShare(context)) return;
  if (!context.mounted) return;
  await app.updateSettings(app.settings.copyWith(lastShareFormat: format.name));
  if (!context.mounted) return;
  final input = RecordCardInput(
    record: record,
    config: app.config,
    geometry: app.geometry,
    s: s,
    lang: app.language,
    hideDate: app.settings.hideDateInExports,
    reducedMotion: app.reducedMotion(context),
  );
  final messenger = ScaffoldMessenger.maybeOf(context);
  final progress = ExportProgress()..show(context, cancellable: format != RecordFormat.png);
  File? file;
  String mime = 'image/png';
  try {
    switch (format) {
      case RecordFormat.png:
        {
          final bytes = await recordPng(input);
          file = await writeExportFile('${input.baseName}.png', bytes);
        }
      case RecordFormat.gif:
        {
          final bytes =
              await recordGif(input, onProgress: progress.set, isCancelled: () => progress.cancelled);
          if (bytes != null) file = await writeExportFile('${input.baseName}.gif', bytes);
          mime = 'image/gif';
        }
      case RecordFormat.mp4:
        final path = await prepareExportPath('${input.baseName}.mp4');
        final ok = await recordMp4(input, path, onProgress: progress.set, isCancelled: () => progress.cancelled);
        if (ok) {
          file = File(path);
          mime = 'video/mp4';
        } else if (!progress.cancelled) {
          // Si el vídeo no es posible en este equipo, se ofrece el GIF.
          messenger?.showSnackBar(SnackBar(content: Text(s.videoFallbackToGif)));
          progress.set(0);
          final Uint8List? bytes =
              await recordGif(input, onProgress: progress.set, isCancelled: () => progress.cancelled);
          if (bytes != null) file = await writeExportFile('${input.baseName}.gif', bytes);
          mime = 'image/gif';
        }
    }
  } catch (_) {
    file = null;
    if (!progress.cancelled) messenger?.showSnackBar(SnackBar(content: Text(s.exportFailed)));
  }
  final cancelled = progress.cancelled;
  progress.close();
  if (cancelled || file == null || !context.mounted) return;
  await deliverFile(context, file, mimeType: mime, subject: 'HOPE · ${formatDateTime(record.dateTime, app.language)}');
}
