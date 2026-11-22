// HOPE – utilidades para las pruebas.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope/core/body_geometry.dart';
import 'package:hope/core/config.dart';
import 'package:hope/data/stores.dart';
import 'package:hope/models/app_settings.dart';
import 'package:hope/models/bowel.dart';
import 'package:hope/models/pain_record.dart';
import 'package:hope/models/treatment.dart';
import 'package:hope/state/app_controller.dart';

AppConfig loadConfig() =>
    AppConfig.fromJsonString(File('assets/config/hope_config.json').readAsStringSync());

BodyGeometry loadGeometry() =>
    BodyGeometry.fromJsonString(File('assets/config/body_geometry.json').readAsStringSync());

Future<AppController> testController({
  List<PainRecord>? records,
  List<Treatment>? treatments,
  List<BowelEntry>? bowel,
  AppSettings settings = const AppSettings(firstRunDone: true, language: 'es'),
}) async {
  final c = AppController(
    config: loadConfig(),
    geometry: loadGeometry(),
    recordStore: MemoryRecordStore(records),
    settingsStore: MemorySettingsStore(settings),
    treatmentStore: MemoryTreatmentStore(TreatmentData(treatments: treatments ?? const [])),
    bowelStore: MemoryBowelStore(bowel),
  );
  await c.init();
  return c;
}

/// Desde la pantalla de inicio (los cuadros), entra en la sección Dolor.
Future<void> openPainScreen(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('tile-pain')));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Guarda un archivo generado en build/muestras para validarlo en la CI.
void saveSample(String name, List<int> bytes) {
  final f = File('build/muestras/$name');
  f.parent.createSync(recursive: true);
  f.writeAsBytesSync(bytes);
}

/// Carga Roboto y los iconos de Material del SDK para que las capturas y
/// las muestras se vean con la tipografía real.
Future<void> loadRealFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;
  Future<ByteData> read(File f) async => ByteData.view((await f.readAsBytes()).buffer);
  final roboto = FontLoader('Roboto');
  final icons = FontLoader('MaterialIcons');
  for (final f in dir.listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last;
    if (name.startsWith('Roboto-') && name.endsWith('.ttf')) roboto.addFont(read(f));
    if (name.startsWith('MaterialIcons-Regular')) icons.addFont(read(f));
  }
  await roboto.load();
  await icons.load();
}
