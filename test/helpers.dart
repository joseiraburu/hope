// HOPE – utilidades para las pruebas.

import 'dart:io';

import 'package:hope/core/body_geometry.dart';
import 'package:hope/core/config.dart';
import 'package:hope/data/stores.dart';
import 'package:hope/models/app_settings.dart';
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
  AppSettings settings = const AppSettings(firstRunDone: true, language: 'es'),
}) async {
  final c = AppController(
    config: loadConfig(),
    geometry: loadGeometry(),
    recordStore: MemoryRecordStore(records),
    settingsStore: MemorySettingsStore(settings),
    treatmentStore: MemoryTreatmentStore(TreatmentData(treatments: treatments ?? const [])),
  );
  await c.init();
  return c;
}
