// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores.
//
// Este programa es software libre: puedes redistribuirlo y/o modificarlo
// bajo los términos de la Licencia Pública General de GNU publicada por la
// Free Software Foundation, ya sea la versión 3 de la Licencia o (a tu
// elección) cualquier versión posterior. Se distribuye con la esperanza de
// que sea útil, pero SIN NINGUNA GARANTÍA. Consulta el archivo LICENSE.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/body_geometry.dart';
import 'core/config.dart';
import 'data/stores.dart';
import 'export/share_service.dart';
import 'services/reminders.dart';
import 'state/app_controller.dart';
import 'state/navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromJsonString(
    await rootBundle.loadString('assets/config/hope_config.json'),
  );
  final geometry = BodyGeometry.fromJsonString(
    await rootBundle.loadString('assets/config/body_geometry.json'),
  );
  final dir = await getApplicationSupportDirectory();
  final controller = AppController(
    config: config,
    geometry: geometry,
    recordStore: JsonFileRecordStore(dir),
    settingsStore: JsonFileSettingsStore(dir),
    treatmentStore: JsonFileTreatmentStore(dir),
    foodStore: JsonFileFoodStore(dir),
    sleepStore: JsonFileSleepStore(dir),
  );
  await controller.init();
  // Recordatorios «Completa HOPE»: se preparan (y se atiende el aviso que
  // haya abierto la app) y se renuevan los de los próximos días.
  final reminders = controller.settings.reminders;
  if (controller.settings.anyReminderEnabled) {
    await ReminderService.instance.init();
  }
  runApp(HopeApp(controller: controller));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ReminderService.instance.onOpen = openReminderMeal;
  });
  if (controller.settings.anyReminderEnabled) {
    unawaited(ReminderService.instance.reschedule(reminders, controller.strings));
  }
  // Archivos que quedaran de exportaciones anteriores.
  unawaited(cleanExportFiles());
}
