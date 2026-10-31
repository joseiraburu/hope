// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores.
//
// Este programa es software libre: puedes redistribuirlo y/o modificarlo
// bajo los términos de la Licencia Pública General de GNU publicada por la
// Free Software Foundation, ya sea la versión 3 de la Licencia o (a tu
// elección) cualquier versión posterior. Se distribuye con la esperanza de
// que sea útil, pero SIN NINGUNA GARANTÍA. Consulta el archivo LICENSE.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/body_geometry.dart';
import 'core/config.dart';
import 'data/stores.dart';
import 'state/app_controller.dart';

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
  );
  await controller.init();
  runApp(HopeApp(controller: controller));
}
