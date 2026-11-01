// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import '../widgets/dialogs.dart';

/// Lista de medicamentos: añadir, cambiar el nombre y ocultar.
class MedicationsScreen extends StatelessWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.medications)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final name = await askText(context, title: s.addMedication, label: s.medicationName);
          if (name != null && name.trim().isNotEmpty) await app.addMedication(name);
        },
        icon: const Icon(Icons.add),
        label: Text(s.addMedication),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(s.medicationsHelp, style: theme.textTheme.bodySmall),
          ),
          for (final m in app.medications)
            ListTile(
              leading: Icon(
                Icons.medication_outlined,
                color: m.hidden ? theme.disabledColor : theme.colorScheme.primary,
              ),
              title: Text(
                app.medicationName(m.id),
                style: m.hidden ? TextStyle(color: theme.disabledColor) : null,
              ),
              subtitle: m.hidden ? Text(s.hiddenLabel) : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: s.renameMedication,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () async {
                      final name = await askText(
                        context,
                        title: s.renameMedication,
                        label: s.medicationName,
                        initial: app.medicationName(m.id),
                      );
                      if (name != null && name.trim().isNotEmpty) {
                        await app.renameMedication(m.id, name);
                      }
                    },
                  ),
                  IconButton(
                    tooltip: m.hidden ? s.showMedication : s.hideMedication,
                    icon: Icon(m.hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => app.setMedicationHidden(m.id, !m.hidden),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
