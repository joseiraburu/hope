// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../data/merge.dart';
import '../export/backup_flow.dart';
import '../state/app_controller.dart';
import '../widgets/home_action.dart';

/// Importar / Exportar: el informe completo en un solo archivo (para el
/// médico y para otro dispositivo), la importación y la copia de seguridad.
class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final theme = Theme.of(context);
    final counts = DataCounts.of(currentData(app));

    return Scaffold(
      appBar: AppBar(title: Text(s.tileData), actions: const [HomeAction()]),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _Section(
                icon: Icons.ios_share,
                title: s.exportFullTitle,
                help: s.exportFullHelp,
                child: FilledButton.icon(
                  key: const ValueKey('export-full'),
                  onPressed: () => exportFullReport(context),
                  icon: const Icon(Icons.description_outlined),
                  label: Text(s.exportFullButton),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                icon: Icons.download_outlined,
                title: s.importTitle,
                help: s.importHelp,
                child: FilledButton.tonalIcon(
                  key: const ValueKey('import-file'),
                  onPressed: () => importBackup(context),
                  icon: const Icon(Icons.folder_open_outlined),
                  label: Text(s.importButton),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                icon: Icons.backup_outlined,
                title: s.backupExport,
                help: s.backupExportHelp,
                child: OutlinedButton.icon(
                  onPressed: () => exportBackup(context),
                  icon: const Icon(Icons.data_object),
                  label: Text(s.backupJsonButton),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ),
              const SizedBox(height: 20),
              Text(s.onThisDevice, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(s.dataCounts(counts), style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, size: 18, color: theme.colorScheme.outline),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.exportPrivacy, style: theme.textTheme.bodySmall)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.help, required this.child});

  final IconData icon;
  final String title;
  final String help;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(help, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
