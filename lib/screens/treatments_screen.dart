// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../state/app_controller.dart';

/// Lista de tratamientos.
class TreatmentsScreen extends StatelessWidget {
  const TreatmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).strings;
    return Scaffold(appBar: AppBar(title: Text(s.treatments)));
  }
}
