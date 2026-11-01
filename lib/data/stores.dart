// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:convert';
import 'dart:io';

import '../models/app_settings.dart';
import '../models/pain_record.dart';
import '../models/treatment.dart';

/// Almacén del histórico de registros.
abstract class RecordStore {
  Future<List<PainRecord>> load();
  Future<void> saveAll(List<PainRecord> records);
}

/// Almacén de las preferencias.
abstract class SettingsStore {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}

/// Tratamientos y lista de medicamentos del usuario.
class TreatmentData {
  const TreatmentData({this.medications = const [], this.treatments = const []});

  /// Medicamentos añadidos por el usuario y cambios a los predefinidos.
  final List<MedicationDef> medications;
  final List<Treatment> treatments;
}

/// Almacén de los tratamientos.
abstract class TreatmentStore {
  Future<TreatmentData> load();
  Future<void> save(TreatmentData data);
}

/// Versiones en memoria (para pruebas).
class MemoryTreatmentStore implements TreatmentStore {
  MemoryTreatmentStore([this._data = const TreatmentData()]);
  TreatmentData _data;

  @override
  Future<TreatmentData> load() async => _data;

  @override
  Future<void> save(TreatmentData data) async => _data = data;
}

class MemoryRecordStore implements RecordStore {
  MemoryRecordStore([List<PainRecord>? initial]) : _records = [...?initial];
  List<PainRecord> _records;

  @override
  Future<List<PainRecord>> load() async => [..._records];

  @override
  Future<void> saveAll(List<PainRecord> records) async => _records = [...records];
}

class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore([this._settings = const AppSettings()]);
  AppSettings _settings;

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<void> save(AppSettings settings) async => _settings = settings;
}

/// Escribe un archivo de forma segura: primero en un temporal y luego lo
/// renombra, para no dejar nunca un archivo a medias.
Future<void> writeFileAtomic(File file, String contents) async {
  await file.parent.create(recursive: true);
  final tmp = File('${file.path}.tmp');
  await tmp.writeAsString(contents, flush: true);
  try {
    await tmp.rename(file.path);
  } on FileSystemException {
    if (await file.exists()) await file.delete();
    await tmp.rename(file.path);
  }
}

/// Si un archivo está dañado, lo aparta en lugar de sobrescribirlo.
Future<void> _setAsideCorrupt(File file) async {
  try {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await file.rename('${file.path}.danado-$stamp');
  } catch (_) {}
}

/// Histórico guardado en un archivo JSON local.
class JsonFileRecordStore implements RecordStore {
  JsonFileRecordStore(this.directory);

  final Directory directory;
  Future<void> _queue = Future<void>.value();

  File get file => File('${directory.path}${Platform.pathSeparator}hope_registros.json');

  @override
  Future<List<PainRecord>> load() async {
    if (!await file.exists()) return [];
    try {
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final list = data['registros'] as List<dynamic>? ?? const [];
      return [
        for (final r in list) PainRecord.fromJson(r as Map<String, dynamic>)
      ];
    } catch (_) {
      await _setAsideCorrupt(file);
      return [];
    }
  }

  @override
  Future<void> saveAll(List<PainRecord> records) {
    final text = const JsonEncoder.withIndent(' ').convert({
      'formato': 'hope-registros',
      'version': 1,
      'registros': [for (final r in records) r.toJson()],
    });
    // Las escrituras se encadenan para que nunca se pisen entre sí. Si una
    // falla, las siguientes se siguen intentando.
    final next = _queue.then((_) => writeFileAtomic(file, text));
    _queue = next.catchError((Object _) {});
    return next;
  }
}

/// Preferencias guardadas en un archivo JSON local.
class JsonFileSettingsStore implements SettingsStore {
  JsonFileSettingsStore(this.directory);

  final Directory directory;

  File get file => File('${directory.path}${Platform.pathSeparator}hope_ajustes.json');

  @override
  Future<AppSettings> load() async {
    if (!await file.exists()) return const AppSettings();
    try {
      return AppSettings.fromJson(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>);
    } catch (_) {
      await _setAsideCorrupt(file);
      return const AppSettings();
    }
  }

  @override
  Future<void> save(AppSettings settings) =>
      writeFileAtomic(file, jsonEncode(settings.toJson()));
}

/// Tratamientos guardados en un archivo JSON local.
class JsonFileTreatmentStore implements TreatmentStore {
  JsonFileTreatmentStore(this.directory);

  final Directory directory;
  Future<void> _queue = Future<void>.value();

  File get file => File('${directory.path}${Platform.pathSeparator}hope_tratamientos.json');

  @override
  Future<TreatmentData> load() async {
    if (!await file.exists()) return const TreatmentData();
    try {
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return TreatmentData(
        medications: [
          for (final m in (data['medicamentos'] as List<dynamic>? ?? const []))
            MedicationDef.fromJson(m as Map<String, dynamic>)
        ],
        treatments: [
          for (final t in (data['tratamientos'] as List<dynamic>? ?? const []))
            Treatment.fromJson(t as Map<String, dynamic>)
        ],
      );
    } catch (_) {
      await _setAsideCorrupt(file);
      return const TreatmentData();
    }
  }

  @override
  Future<void> save(TreatmentData data) {
    final text = const JsonEncoder.withIndent(' ').convert({
      'formato': 'hope-tratamientos',
      'version': 1,
      'medicamentos': [for (final m in data.medications) m.toJson()],
      'tratamientos': [for (final t in data.treatments) t.toJson()],
    });
    final next = _queue.then((_) => writeFileAtomic(file, text));
    _queue = next.catchError((Object _) {});
    return next;
  }
}
