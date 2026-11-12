// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import '../core/body_geometry.dart';
import '../core/config.dart';
import '../data/stores.dart';
import '../l10n/strings.dart';
import '../models/app_settings.dart';
import '../models/food.dart';
import '../models/pain_record.dart';
import '../models/sleep.dart';
import '../models/treatment.dart';

/// Estado global: configuración, histórico, tratamientos, alimentación y
/// preferencias.
class AppController extends ChangeNotifier {
  AppController({
    required this.config,
    required this.geometry,
    required this.recordStore,
    required this.settingsStore,
    TreatmentStore? treatmentStore,
    FoodStore? foodStore,
    SleepStore? sleepStore,
  })  : treatmentStore = treatmentStore ?? MemoryTreatmentStore(),
        foodStore = foodStore ?? MemoryFoodStore(),
        sleepStore = sleepStore ?? MemorySleepStore();

  final AppConfig config;
  final BodyGeometry geometry;
  final RecordStore recordStore;
  final SettingsStore settingsStore;
  final TreatmentStore treatmentStore;
  final FoodStore foodStore;
  final SleepStore sleepStore;

  List<PainRecord> _records = [];
  AppSettings _settings = const AppSettings();
  List<Treatment> _treatments = [];

  /// Cambios del usuario a los medicamentos predefinidos y los que añade.
  List<MedicationDef> _medicationEntries = [];

  /// Alimentos añadidos por el usuario y básicos ocultos.
  List<FoodDef> _foodEntries = [];

  /// Días con comidas, del más reciente al más antiguo.
  List<FoodDay> _foodDays = [];

  /// Noches registradas, de la más reciente a la más antigua.
  List<SleepEntry> _sleep = [];

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
    final food = await foodStore.load();
    _foodEntries = [...food.foods];
    _foodDays = _uniqueDays(food.days);
    _sleep = _uniqueNights(await sleepStore.load());
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

  /// Borra todos los registros, tratamientos, medicamentos añadidos y la
  /// alimentación.
  Future<void> deleteAll() async {
    _records = [];
    _treatments = [];
    _medicationEntries = [];
    _foodEntries = [];
    _foodDays = [];
    _sleep = [];
    notifyListeners();
    await recordStore.saveAll(_records);
    await _saveTreatments();
    await _saveFood();
    await sleepStore.saveAll(_sleep);
  }

  /// Sustituye todos los datos (al importar una copia de seguridad).
  ///
  /// Las copias anteriores a la versión 0.3 no tienen alimentación
  /// ([foods] y [foodDays] nulos) y las anteriores a la 0.4 no tienen sueño
  /// ([sleep] nulo): entonces se conserva lo que haya en el dispositivo.
  Future<void> replaceAll({
    required List<PainRecord> records,
    required List<Treatment> treatments,
    required List<MedicationDef> medications,
    AppSettings? settings,
    List<FoodDef>? foods,
    List<FoodDay>? foodDays,
    List<SleepEntry>? sleep,
  }) async {
    _records = [...records];
    _sort();
    _treatments = [...treatments];
    _sortTreatments();
    _medicationEntries = [...medications];
    if (settings != null) _settings = settings;
    final hasFood = foods != null || foodDays != null;
    if (hasFood) {
      _foodEntries = [...?foods];
      _foodDays = _uniqueDays(foodDays ?? const []);
    }
    if (sleep != null) _sleep = _uniqueNights(sleep);
    notifyListeners();
    await recordStore.saveAll(_records);
    await _saveTreatments();
    if (hasFood) await _saveFood();
    if (sleep != null) await sleepStore.saveAll(_sleep);
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

  // ------------------------------------------------------------ alimentación
  Future<void> _saveFood() => foodStore.save(FoodData(foods: _foodEntries, days: _foodDays));

  /// Un registro por día (si hubiera dos, queda el último guardado), del más
  /// reciente al más antiguo.
  static List<FoodDay> _uniqueDays(List<FoodDay> days) {
    final byKey = <String, FoodDay>{};
    for (final d in days) {
      final previous = byKey[d.key];
      final newer = previous == null ||
          (d.updatedAt != null &&
              (previous.updatedAt == null || !d.updatedAt!.isBefore(previous.updatedAt!)));
      if (newer) byKey[d.key] = d;
    }
    final list = [for (final d in byKey.values) if (!d.isEmpty) d];
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Días con comidas, del más reciente al más antiguo.
  List<FoodDay> get foodDays => List.unmodifiable(_foodDays);

  /// Entradas de alimentos tal como se guardan (para la copia de seguridad).
  List<FoodDef> get foodEntries => List.unmodifiable(_foodEntries);

  /// Comidas guardadas de un día (null si no hay).
  FoodDay? foodDayFor(DateTime day) {
    final key = dayKey(day);
    for (final d in _foodDays) {
      if (d.key == key) return d;
    }
    return null;
  }

  /// Guarda las comidas de un día y sustituye las que hubiera. Un día sin
  /// ningún alimento se borra.
  Future<void> saveFoodDay(FoodDay day) async {
    bool known(String id) => foodById(id) != null;
    final clean = FoodDay(
      date: day.date,
      meals: {
        for (final e in day.meals.entries)
          e.key: e.value.copyWith(
            foods: [...{for (final id in e.value.foods) if (known(id)) id}],
          ),
      },
      updatedAt: DateTime.now(),
    );
    _foodDays.removeWhere((d) => d.key == clean.key);
    if (!clean.isEmpty) _foodDays.add(clean);
    _foodDays.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    await _saveFood();
  }

  /// Borra las comidas de un día y las devuelve (para poder deshacer).
  Future<FoodDay?> deleteFoodDay(DateTime day) async {
    final key = dayKey(day);
    final i = _foodDays.indexWhere((d) => d.key == key);
    if (i < 0) return null;
    final removed = _foodDays.removeAt(i);
    notifyListeners();
    await _saveFood();
    return removed;
  }

  /// Vuelve a poner un día borrado tal como estaba.
  Future<void> restoreFoodDay(FoodDay day) async {
    _foodDays.removeWhere((d) => d.key == day.key);
    if (!day.isEmpty) _foodDays.add(day);
    _foodDays.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    await _saveFood();
  }

  /// Todos los alimentos: los básicos (en el orden de la configuración) y
  /// después los añadidos por el usuario.
  List<FoodDef> get foods {
    final byId = {for (final f in _foodEntries) f.id: f};
    final out = <FoodDef>[
      for (final b in config.foods)
        FoodDef(id: b.id, hidden: byId[b.id]?.hidden ?? false, builtIn: true),
    ];
    for (final f in _foodEntries) {
      if (config.foodById(f.id) != null) continue;
      out.add(f);
    }
    return out;
  }

  FoodDef? foodById(String id) {
    for (final f in foods) {
      if (f.id == id) return f;
    }
    return null;
  }

  /// Nombre visible: el de la configuración en el idioma de la app para los
  /// básicos; el que escribió el usuario para los demás.
  String foodName(String id) {
    final builtIn = config.foodById(id);
    if (builtIn != null) return builtIn.name(language);
    for (final f in _foodEntries) {
      if (f.id == id) {
        final name = f.customName;
        if (name != null && name.trim().isNotEmpty) return name;
      }
    }
    return id;
  }

  /// Ordena alfabéticamente en el idioma de la app (sin tener en cuenta
  /// mayúsculas ni tildes).
  List<FoodDef> sortFoods(Iterable<FoodDef> list) {
    final sorted = [...list];
    sorted.sort((a, b) =>
        normalizeFoodName(foodName(a.id)).compareTo(normalizeFoodName(foodName(b.id))));
    return sorted;
  }

  /// Alimentos para elegir: los visibles y los ya elegidos aunque estén
  /// ocultos, en orden alfabético.
  List<FoodDef> pickableFoods([Iterable<String> selected = const []]) {
    final chosen = selected.toSet();
    return sortFoods([for (final f in foods) if (!f.hidden || chosen.contains(f.id)) f]);
  }

  /// ¿Aparece este alimento en algún día guardado?
  bool isFoodUsed(String id) => _foodDays.any((d) => d.contains(id));

  /// Alimentos que aparecen en algún día guardado, en orden alfabético.
  List<FoodDef> get usedFoods {
    final used = <String>{for (final d in _foodDays) ...d.foods};
    return sortFoods([for (final f in foods) if (used.contains(f.id)) f]);
  }

  /// Busca un alimento con ese nombre, sin distinguir mayúsculas, tildes ni
  /// espacios, y en los dos idiomas para los básicos («Pan» y «Bread» son el
  /// mismo). [except] se ignora (al cambiar el nombre de un alimento).
  FoodDef? findFoodByName(String name, {String? except}) {
    final wanted = normalizeFoodName(name);
    if (wanted.isEmpty) return null;
    for (final f in foods) {
      if (f.id == except) continue;
      final builtIn = config.foodById(f.id);
      if (builtIn != null) {
        if (builtIn.names.values.any((n) => normalizeFoodName(n) == wanted)) return f;
      } else if (normalizeFoodName(f.customName ?? '') == wanted) {
        return f;
      }
    }
    return null;
  }

  /// Añade un alimento a la lista. Si ya existe uno con ese nombre, no se
  /// duplica: se devuelve el existente ([existed] = true) y, si estaba
  /// oculto, se vuelve a mostrar.
  Future<({FoodDef food, bool existed})> addFood(String name) async {
    final existing = findFoodByName(name);
    if (existing != null) {
      if (existing.hidden) await setFoodHidden(existing.id, false);
      return (food: foodById(existing.id) ?? existing, existed: true);
    }
    final food = FoodDef(id: 'ali_${newUuid().substring(0, 8)}', customName: cleanFoodName(name));
    _foodEntries.add(food);
    notifyListeners();
    await _saveFood();
    return (food: food, existed: false);
  }

  Future<void> _upsertFood(FoodDef f) async {
    final i = _foodEntries.indexWhere((e) => e.id == f.id);
    if (i < 0) {
      _foodEntries.add(f);
    } else {
      _foodEntries[i] = f;
    }
    notifyListeners();
    await _saveFood();
  }

  /// Cambia el nombre de un alimento añadido por el usuario. Devuelve false
  /// si ya hay otro alimento con ese nombre (o si es un alimento básico).
  Future<bool> renameFood(String id, String name) async {
    final current = foodById(id);
    if (current == null || current.builtIn) return false;
    final clean = cleanFoodName(name);
    if (clean.isEmpty || findFoodByName(clean, except: id) != null) return false;
    await _upsertFood(current.copyWith(customName: clean));
    return true;
  }

  Future<void> setFoodHidden(String id, bool hidden) async {
    final current = foodById(id);
    if (current == null) return;
    await _upsertFood(current.copyWith(hidden: hidden));
  }

  /// Borra un alimento añadido por el usuario. Si ya se ha usado algún día
  /// (o es un alimento básico), solo se oculta para conservar el historial.
  /// Devuelve true si se ha borrado y false si se ha ocultado.
  Future<bool> deleteFood(String id) async {
    final current = foodById(id);
    if (current == null) return false;
    if (current.builtIn || isFoodUsed(id)) {
      await setFoodHidden(id, true);
      return false;
    }
    _foodEntries.removeWhere((f) => f.id == id);
    notifyListeners();
    await _saveFood();
    return true;
  }

  // ------------------------------------------------------------------ sueño
  /// Una entrada por noche (si hubiera dos, queda la última guardada), de la
  /// más reciente a la más antigua.
  static List<SleepEntry> _uniqueNights(List<SleepEntry> entries) {
    final byKey = <String, SleepEntry>{};
    for (final e in entries) {
      final previous = byKey[e.key];
      final newer = previous == null ||
          (e.updatedAt != null &&
              (previous.updatedAt == null || !e.updatedAt!.isBefore(previous.updatedAt!)));
      if (newer) byKey[e.key] = e;
    }
    final list = byKey.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Noches registradas, de la más reciente a la más antigua.
  List<SleepEntry> get sleepEntries => List.unmodifiable(_sleep);

  /// La noche que termina el día [day] (null si no se registró).
  SleepEntry? sleepFor(DateTime day) {
    final key = dayKey(day);
    for (final e in _sleep) {
      if (e.key == key) return e;
    }
    return null;
  }

  /// Guarda una noche y sustituye la que hubiera ese día.
  Future<void> saveSleep(SleepEntry entry) async {
    final clean = entry.copyWith(note: entry.note.trim(), updatedAt: DateTime.now());
    _sleep.removeWhere((e) => e.key == clean.key);
    _sleep.add(clean);
    _sleep.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    await sleepStore.saveAll(_sleep);
  }

  /// Borra una noche y la devuelve (para poder deshacer).
  Future<SleepEntry?> deleteSleep(DateTime day) async {
    final key = dayKey(day);
    final i = _sleep.indexWhere((e) => e.key == key);
    if (i < 0) return null;
    final removed = _sleep.removeAt(i);
    notifyListeners();
    await sleepStore.saveAll(_sleep);
    return removed;
  }

  /// Vuelve a poner una noche borrada tal como estaba.
  Future<void> restoreSleep(SleepEntry entry) async {
    _sleep.removeWhere((e) => e.key == entry.key);
    _sleep.add(entry);
    _sleep.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    await sleepStore.saveAll(_sleep);
  }

  // ------------------------------------------------------- «Completa HOPE»
  /// Registros de dolor de un día (del más reciente al más antiguo).
  List<PainRecord> recordsOn(DateTime day) {
    final key = dayKey(day);
    return [for (final r in _records) if (dayKey(r.dateTime) == key) r];
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
