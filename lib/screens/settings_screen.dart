// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../core/version.dart';
import '../export/backup_flow.dart';
import '../state/app_controller.dart';
import '../widgets/dialogs.dart';
import '../widgets/logo.dart';
import 'food_screen.dart';
import 'foods_screen.dart';

/// Ajustes: perfil, apariencia, movimiento, datos y «Acerca de».
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final settings = app.settings;
    final theme = Theme.of(context);

    Widget section(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(title, style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          )),
        );

    Widget choice(String label, Widget control) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 6),
              SizedBox(width: double.infinity, child: control),
            ],
          ),
        );

    SegmentedButton<String> segmented(
      String value,
      List<(String, String)> options,
      ValueChanged<String> onChanged,
    ) {
      return SegmentedButton<String>(
        segments: [
          for (final (v, label) in options) ButtonSegment(value: v, label: Text(label)),
        ],
        selected: {value},
        showSelectedIcon: false,
        onSelectionChanged: (v) => onChanged(v.first),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          section(s.profile),
          choice(
            s.silhouette,
            segmented(settings.sex, [('female', s.female), ('male', s.male)],
                (v) => app.updateSettings(settings.copyWith(sex: v))),
          ),
          section(s.appearance),
          choice(
            s.theme,
            segmented(
              settings.themeMode,
              [('system', s.themeSystem), ('light', s.themeLight), ('dark', s.themeDark)],
              (v) => app.updateSettings(settings.copyWith(themeMode: v)),
            ),
          ),
          choice(
            s.language,
            segmented(
              settings.language,
              [('system', s.themeSystem), ('es', 'Español'), ('en', 'English')],
              (v) => app.updateSettings(settings.copyWith(language: v)),
            ),
          ),
          choice(
            s.motion,
            segmented(
              settings.reducedMotion,
              [('system', s.themeSystem), ('on', s.yes), ('off', s.no)],
              (v) => app.updateSettings(settings.copyWith(reducedMotion: v)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(s.motionHelp, style: theme.textTheme.bodySmall),
          ),
          section(s.sharingSection),
          SwitchListTile(
            title: Text(s.hideDate),
            value: settings.hideDateInExports,
            onChanged: (v) => app.updateSettings(settings.copyWith(hideDateInExports: v)),
          ),
          section(s.food),
          ListTile(
            leading: const Icon(Icons.restaurant),
            title: Text(s.food),
            subtitle: Text('${s.foodLogTab} · ${s.foodHistoryTab}'),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => const FoodScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: Text(s.myFoods),
            subtitle: Text(s.myFoodsHelp),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => const FoodsScreen())),
          ),
          section(s.data),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(s.dataLocal),
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: Text(s.backupExport),
            subtitle: Text(s.backupExportHelp),
            onTap: () => exportBackup(context),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text(s.backupImport),
            onTap: () => importBackup(context),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
            title: Text(s.deleteAll, style: TextStyle(color: theme.colorScheme.error)),
            onTap: () async {
              final ok = await confirmAction(
                context,
                title: s.deleteAll,
                message: s.deleteAllQuestion,
                confirmLabel: s.delete,
              );
              if (!ok) return;
              await app.deleteAll();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(s.allDeleted)));
            },
          ),
          section(s.about),
          ListTile(
            leading: const HopeLogo(size: 36),
            title: Text('HOPE · ${s.version} $appVersion'),
            subtitle: Text(s.license),
            onTap: () => showHopeAbout(context),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(s.medicalDisclaimer, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
