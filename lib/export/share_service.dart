// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../state/app_controller.dart';
import '../widgets/dialogs.dart';

/// Carpeta temporal de las exportaciones.
Future<Directory> _exportDir() async {
  final base = await getTemporaryDirectory();
  return Directory('${base.path}${Platform.pathSeparator}hope_export');
}

/// Borra los archivos temporales de exportaciones anteriores.
Future<void> cleanExportFiles() async {
  try {
    final dir = await _exportDir();
    if (await dir.exists()) await dir.delete(recursive: true);
  } catch (_) {
    // No es grave: se intentará en la siguiente exportación.
  }
}

/// Guarda un archivo exportado en la carpeta temporal (vaciándola antes).
Future<File> writeExportFile(String name, List<int> bytes) async {
  await cleanExportFiles();
  final dir = await _exportDir();
  await dir.create(recursive: true);
  final file = File('${dir.path}${Platform.pathSeparator}$name');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

/// La primera vez que se comparte algo, avisa de que son datos de salud.
/// Devuelve false si el usuario cancela.
Future<bool> confirmHealthDataShare(BuildContext context) async {
  final app = AppScope.read(context);
  if (app.settings.shareNoticeShown) return true;
  final s = app.strings;
  final ok = await confirmAction(
    context,
    title: s.healthDataTitle,
    message: s.healthDataBody,
    confirmLabel: s.continueLabel,
  );
  if (ok) await app.updateSettings(app.settings.copyWith(shareNoticeShown: true));
  return ok;
}

bool get _isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

/// Entrega un archivo al usuario: en el móvil abre la hoja de compartir del
/// sistema (WhatsApp, correo, Drive...); en el escritorio ofrece «Guardar
/// como…», «Compartir» y «Abrir carpeta».
Future<void> deliverFile(
  BuildContext context,
  File file, {
  required String mimeType,
  required String subject,
}) async {
  if (!_isDesktop) {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: mimeType)],
      subject: subject,
      sharePositionOrigin: box != null && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : null,
    ));
    return;
  }
  final messenger = ScaffoldMessenger.maybeOf(context);
  await showDialog<void>(
    context: context,
    builder: (_) => _DesktopFileDialog(
      file: file,
      mimeType: mimeType,
      subject: subject,
      messenger: messenger,
    ),
  );
}

class _DesktopFileDialog extends StatelessWidget {
  const _DesktopFileDialog({
    required this.file,
    required this.mimeType,
    required this.subject,
    required this.messenger,
  });

  final File file;
  final String mimeType;
  final String subject;
  final ScaffoldMessengerState? messenger;

  String get _name => file.uri.pathSegments.last;

  Future<void> _saveAs(BuildContext context) async {
    final s = AppScope.read(context).strings;
    final ext = _name.contains('.') ? _name.split('.').last : '';
    final location = await getSaveLocation(
      suggestedName: _name,
      acceptedTypeGroups: [
        if (ext.isNotEmpty) XTypeGroup(label: ext.toUpperCase(), extensions: [ext]),
      ],
    );
    if (location == null) return;
    var path = location.path;
    if (ext.isNotEmpty && !path.toLowerCase().endsWith('.$ext')) path = '$path.$ext';
    await file.copy(path);
    if (context.mounted) Navigator.of(context).pop();
    messenger?.showSnackBar(SnackBar(
      content: Text(s.savedAt(path)),
      action: Platform.isWindows
          ? SnackBarAction(
              label: s.openFolder,
              onPressed: () => Process.run('explorer.exe', ['/select,', path]),
            )
          : null,
    ));
  }

  Future<void> _share(BuildContext context) async {
    final s = AppScope.read(context).strings;
    try {
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: mimeType)],
        subject: subject,
      ));
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(s.exportFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).strings;
    return AlertDialog(
      icon: const Icon(Icons.check_circle_outline),
      title: Text(s.fileReady),
      content: Text(_name),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(s.close)),
        OutlinedButton.icon(
          onPressed: () => _share(context),
          icon: const Icon(Icons.share_outlined),
          label: Text(s.share),
        ),
        FilledButton.icon(
          onPressed: () => _saveAs(context),
          icon: const Icon(Icons.save_alt),
          label: Text(s.saveAs),
        ),
      ],
    );
  }
}

/// Diálogo de progreso con botón de cancelar.
class ExportProgress {
  ExportProgress();

  final ValueNotifier<double?> value = ValueNotifier<double?>(null);
  bool cancelled = false;

  void set(double v) => value.value = v.clamp(0.0, 1.0).toDouble();

  /// Muestra el diálogo; se cierra llamando a [close].
  void show(BuildContext context, {bool cancellable = true}) {
    final s = AppScope.read(context).strings;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(s.generating),
          content: ValueListenableBuilder<double?>(
            valueListenable: value,
            builder: (_, v, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: v),
                const SizedBox(height: 8),
                if (v != null) Text('${(v * 100).round()} %'),
              ],
            ),
          ),
          actions: [
            if (cancellable)
              TextButton(
                onPressed: () {
                  cancelled = true;
                  Navigator.of(ctx).pop();
                },
                child: Text(s.cancel),
              ),
          ],
        ),
      ),
    );
    _context = context;
  }

  BuildContext? _context;

  /// Cierra el diálogo (si no lo cerró ya el usuario al cancelar).
  void close() {
    final ctx = _context;
    if (!cancelled && ctx != null && ctx.mounted) Navigator.of(ctx).pop();
    _context = null;
  }
}
