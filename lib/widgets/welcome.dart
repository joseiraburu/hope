// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../core/body_geometry.dart';
import '../state/app_controller.dart';
import 'logo.dart';

/// Bienvenida de la primera vez: qué es HOPE, el aviso médico y la elección
/// de la silueta. Guarda la silueta y que ya se ha mostrado.
Future<void> showWelcome(BuildContext context) async {
  final app = AppScope.read(context);
  final s = app.strings;
  final chosen = await showDialog<Sex>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      icon: const HopeLogo(size: 56),
      title: Text(s.welcomeTitle, textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.welcomeIntro),
            const SizedBox(height: 12),
            Text(s.medicalDisclaimer, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(s.photosensitivity),
            const SizedBox(height: 16),
            Text(s.chooseSilhouette),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton.tonalIcon(
          onPressed: () => Navigator.of(ctx).pop(Sex.female),
          icon: const Icon(Icons.female),
          label: Text(s.female),
        ),
        FilledButton.tonalIcon(
          onPressed: () => Navigator.of(ctx).pop(Sex.male),
          icon: const Icon(Icons.male),
          label: Text(s.male),
        ),
      ],
    ),
  );
  await app.updateSettings(app.settings.copyWith(
    sex: sexToString(chosen ?? Sex.female),
    firstRunDone: true,
  ));
}
