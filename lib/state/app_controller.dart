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

/// Estado global: configuración, histórico y preferencias.
class AppController extends ChangeNotifier {
  AppController({
    required this.config,
    required this.geometry,
    required this.recordStore,
    required this.settingsStore,
  });

  final AppConfig config;
  final BodyGeometry geometry;
  final RecordStore recordStore;
  final SettingsStore settingsStore;

  List<PainRecord> _records = [];
  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;

  /// Registros ordenados del más reciente al más antiguo.
  List<PainRecord> get records => List.unmodifiable(_records);

  PainRecord? get latest => _records.isEmpty ? null : _records.first;

  Future<void> init() async {
    _records = await recordStore.load();
    _sort();
    _settings = await settingsStore.load();
  }

  void _sort() => _records.sort((a, b) => b.dateTime.compareTo(a.dateTime));

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

  Future<void> deleteAll() async {
    _records = [];
    notifyListeners();
    await recordStore.saveAll(_records);
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
