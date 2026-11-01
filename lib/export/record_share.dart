// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../models/pain_record.dart';
import '../state/app_controller.dart';

/// Hoja para compartir un registro como imagen, GIF o vídeo.
Future<void> showRecordShareSheet(BuildContext context, PainRecord record) async {
  final s = AppScope.read(context).strings;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(s.generating)));
}
