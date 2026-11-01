// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import '../core/body_geometry.dart';
import '../core/config.dart';
import '../data/stores.dart';
import '../l10n/strings.dart';
import '../models/app_settings.dart';
import '../models/pain_record.dart';
import '../models/treatment.dart';

/// Estado global: configuración, histórico, tratamientos y preferencias.
class AppController extends ChangeNotifier {
  AppController({
    required this.config,
    required this.geometry,
    required this.recordStore,
    required this.settingsStore,
    TreatmentStore? treatmentStore,
  }) : treatmentStore = treatmentStore ?? MemoryTreatmentStore();

  final AppConfig config;
  final BodyGeometry geometry;
  final RecordStore recordStore;
  final SettingsStore settingsStore;
  final TreatmentStore treatmentStore;

  List<PainRecord> _records = [];
  AppSettings _settings = const AppSettings();
  List<Treatment> _treatments = [];

  /// Cambios del usuario a los medicamentos predefinidos y los que añade.
  List<MedicationDef> _medicationEntries = [];

  AppSettings get settings => _settings;

  /// Registros ordenados del más reciente al más antiguo.
  List<PainRecord> get records => List.unmodifiable(_records);

  PainRecord? get latest => _records.isEmpty ? null : _records.first;

  /// Tratamientos ordenados del más reciente al más antiguo (por inicio).
  List<Treatment> get treatments => List.unmodifiable(_treatments);

  Future<void> init() async {
    _records = await recordStore.load();
    _sort();
    _settings = await settingsStore.load();
    final data = await treatmentStore.load();
    _medicationEntries = [...data.medications];
    _treatments = [...data.treatments];
    _sortTreatments();
  }

  void _sort() => _records.sort((a, b) => b.dateTime.compareTo(a.dateTime));

  void _sortTreatments() => _treatments.sort((a, b) => b.start.compareTo(a.start));

  // -------------------------------------------------------------- registros
  Future<void> addRecord(PainRecord record) async {
    _records.add(record);
    _sort();
    notifyListeners();
    await recordStore.saveAll(_records);
  }

  Future<void> updateRecord(PainRecord record) async {
    final i = _records.indexWhere((r) => r.id == record.id);
    if (i < 0) {
      _records.add(record);
    } else {
      _records[i] = record;
    }
    _sort();
    notifyListeners();
    await recordStore.saveAll(_records);
  }

  PainRecord? recordById(String id) {
    for (final r in _records) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Borra un registro y lo devuelve (para poder deshacer).
  Future<PainRecord?> deleteRecord(String id) async {
    final i = _records.indexWhere((r) => r.id == id);
    if (i < 0) return null;
    final removed = _records.removeAt(i);
    notifyListeners();
    await recordStore.saveAll(_records);
    return removed;
  }

  /// Borra todos los registros, tratamientos y medicamentos añadidos.
  Future<void> deleteAll() async {
    _records = [];
    _treatments = [];
    _medicationEntries = [];
    notifyListeners();
    await recordStore.saveAll(_records);
    await _saveTreatments();
  }

  /// Sustituye todos los datos (al importar una copia de seguridad).
  Future<void> replaceAll({
    required List<PainRecord> records,
    required List<Treatment> treatments,
    required List<MedicationDef> medications,
    AppSettings? settings,
  }) async {
    _records = [...records];
    _sort();
    _treatments = [...treatments];
    _sortTreatments();
    _medicationEntries = [...medications];
    if (settings != null) _settings = settings;
    notifyListeners();
    await recordStore.saveAll(_records);
    await _saveTreatments();
    if (settings != null) await settingsStore.save(settings);
  }

  /// Entradas de medicamentos tal como se guardan (para la copia de seguridad).
  List<MedicationDef> get medicationEntries => List.unmodifiable(_medicationEntries);

  // ----------------------------------------------------------- tratamientos
  Future<void> _saveTreatments() => treatmentStore.save(
        TreatmentData(medications: _medicationEntries, treatments: _treatments),
      );

  Treatment? treatmentById(String id) {
    for (final t in _treatments) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> addTreatment(Treatment t) async {
    _treatments.add(t);
    _sortTreatments();
    notifyListeners();
    await _saveTreatments();
  }

  Future<void> updateTreatment(Treatment t) async {
    final i = _treatments.indexWhere((x) => x.id == t.id);
    if (i < 0) {
      _treatments.add(t);
    } else {
      _treatments[i] = t;
    }
    _sortTreatments();
    notifyListeners();
    await _saveTreatments();
  }

  /// Borra un tratamiento y lo devuelve (para poder deshacer).
  Future<Treatment?> deleteTreatment(String id) async {
    final i = _treatments.indexWhere((t) => t.id == id);
    if (i < 0) return null;
    final removed = _treatments.removeAt(i);
    notifyListeners();
    await _saveTreatments();
    return removed;
  }

  // ------------------------------------------------------------ medicamentos
  /// Todos los medicamentos: los predefinidos primero y luego los añadidos.
  List<MedicationDef> get medications {
    final byId = {for (final m in _medicationEntries) m.id: m};
    final out = <MedicationDef>[];
    for (final m in config.medications) {
      final entry = byId[m.id];
      out.add(MedicationDef(
        id: m.id,
        customName: entry?.customName,
        hidden: entry?.hidden ?? false,
        builtIn: true,
      ));
    }
    for (final m in _medicationEntries) {
      if (config.medications.any((b) => b.id == m.id)) continue;
      out.add(m);
    }
    return out;
  }

  List<MedicationDef> get visibleMedications => [for (final m in medications) if (!m.hidden) m];

  MedicationDef? medicationById(String id) {
    for (final m in medications) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Nombre visible de un medicamento.
  String medicationName(String id, {String? fallback}) {
    final m = medicationById(id);
    if (m == null) return fallback ?? id;
    final custom = m.customName;
    if (custom != null && custom.trim().isNotEmpty) return custom;
    for (final b in config.medications) {
      if (b.id == id) return b.name(language);
    }
    return fallback ?? id;
  }

  /// Nombre del medicamento de un tratamiento.
  String treatmentMedicationName(Treatment t) =>
      medicationName(t.medicationId, fallback: t.medicationName);

  Future<MedicationDef> addMedication(String name) async {
    final m = MedicationDef(id: 'med_${newUuid().substring(0, 8)}', customName: name.trim());
    _medicationEntries.add(m);
    notifyListeners();
    await _saveTreatments();
    return m;
  }

  Future<void> _upsertMedication(MedicationDef m) async {
    final i = _medicationEntries.indexWhere((e) => e.id == m.id);
    if (i < 0) {
      _medicationEntries.add(m);
    } else {
      _medicationEntries[i] = m;
    }
    notifyListeners();
    await _saveTreatments();
  }

  Future<void> renameMedication(String id, String name) async {
    final current = medicationById(id);
    if (current == null) return;
    await _upsertMedication(current.copyWith(customName: name.trim()));
  }

  Future<void> setMedicationHidden(String id, bool hidden) async {
    final current = medicationById(id);
    if (current == null) return;
    await _upsertMedication(current.copyWith(hidden: hidden));
  }

  // --------------------------------------------------------------- ajustes
  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    notifyListeners();
    await settingsStore.save(settings);
  }

  Sex get sex => sexFromString(_settings.sex);

  String get language {
    final chosen = _settings.language;
    if (S.supported.contains(chosen)) return chosen;
    final system = PlatformDispatcher.instance.locale.languageCode;
    return S.supported.contains(system) ? system : 'es';
  }

  S get strings => S(language);

  ThemeMode get themeMode => switch (_settings.themeMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  bool reducedMotion(BuildContext context) {
    switch (_settings.reducedMotion) {
      case 'on':
        return true;
      case 'off':
        return false;
      default:
        return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    }
  }
}

/// Da acceso al [AppController] desde cualquier pantalla.
class AppScope extends InheritedNotifier<AppController> {
  const AppScope({super.key, required AppController controller, required super.child})
      : super(notifier: controller);

  /// Acceso que se actualiza cuando cambia el estado.
  static AppController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Acceso puntual (para acciones), sin suscribirse a cambios.
  static AppController read(BuildContext context) {
    final element = context.getElementForInheritedWidgetOfExactType<AppScope>();
    return (element!.widget as AppScope).notifier!;
  }
}
