// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.
//
// Combinar los datos de un archivo exportado con los del dispositivo, sin
// duplicar nada.

import '../models/bowel.dart';
import '../models/food.dart';
import '../models/sleep.dart';
import 'backup.dart';

/// Cuántos elementos hay (o se han añadido) de cada tipo.
class DataCounts {
  const DataCounts({
    this.pain = 0,
    this.bowel = 0,
    this.sleep = 0,
    this.foodDays = 0,
    this.treatments = 0,
  });

  /// Lo que contiene una copia.
  factory DataCounts.of(BackupData d) => DataCounts(
        pain: d.records.length,
        bowel: d.bowel?.length ?? 0,
        sleep: d.sleep?.length ?? 0,
        foodDays: d.foodDays?.length ?? 0,
        treatments: d.treatments.length,
      );

  final int pain;
  final int bowel;
  final int sleep;
  final int foodDays;
  final int treatments;

  int get total => pain + bowel + sleep + foodDays + treatments;
}

/// Resultado de combinar: los datos que quedan y lo que se ha añadido.
class MergeResult {
  const MergeResult({required this.data, required this.added, required this.updated});

  final BackupData data;

  /// Elementos que no estaban en el dispositivo.
  final DataCounts added;

  /// Días, noches o deposiciones que estaban en los dos y se han sustituido
  /// por la versión del archivo, por ser más reciente.
  final int updated;
}

/// ¿[incoming] es más reciente que [current]? Sin fecha de guardado no se
/// puede saber, y entonces se conserva lo del dispositivo.
bool _newer(DateTime? incoming, DateTime? current) =>
    incoming != null && (current == null || incoming.isAfter(current));

/// Combina [incoming] (el archivo) con [current] (el dispositivo).
///
/// Reglas:
/// * Lo que solo está en el archivo se añade.
/// * Lo que solo está en el dispositivo se conserva.
/// * Registros de dolor, tratamientos, medicamentos y alimentos con el mismo
///   identificador: se conserva el del dispositivo.
/// * Noches (una por fecha), días de comidas (uno por fecha) y deposiciones
///   (por identificador) que estén en los dos: queda la versión guardada
///   más recientemente.
/// * Los ajustes del dispositivo no cambian.
MergeResult mergeBackup(BackupData current, BackupData incoming) {
  var updated = 0;

  // Registros de dolor.
  final records = [...current.records];
  final recordIds = {for (final r in records) r.id};
  var addedPain = 0;
  for (final r in incoming.records) {
    if (recordIds.add(r.id)) {
      records.add(r);
      addedPain++;
    }
  }

  // Tratamientos.
  final treatments = [...current.treatments];
  final treatmentIds = {for (final t in treatments) t.id};
  var addedTreatments = 0;
  for (final t in incoming.treatments) {
    if (treatmentIds.add(t.id)) {
      treatments.add(t);
      addedTreatments++;
    }
  }

  // Medicamentos añadidos por el usuario (o cambios a los predefinidos).
  final medications = [...current.medications];
  final medicationIds = {for (final m in medications) m.id};
  for (final m in incoming.medications) {
    if (medicationIds.add(m.id)) medications.add(m);
  }

  // Alimentos añadidos por el usuario (o básicos ocultos).
  List<FoodDef>? foods;
  if (current.foods != null || incoming.foods != null) {
    foods = [...?current.foods];
    final ids = {for (final f in foods) f.id};
    for (final f in incoming.foods ?? const <FoodDef>[]) {
      if (ids.add(f.id)) foods.add(f);
    }
  }

  // Días de comidas: uno por fecha.
  List<FoodDay>? foodDays;
  var addedFoodDays = 0;
  if (current.foodDays != null || incoming.foodDays != null) {
    final byKey = <String, FoodDay>{for (final d in current.foodDays ?? const <FoodDay>[]) d.key: d};
    for (final d in incoming.foodDays ?? const <FoodDay>[]) {
      final mine = byKey[d.key];
      if (mine == null) {
        byKey[d.key] = d;
        addedFoodDays++;
      } else if (_newer(d.updatedAt, mine.updatedAt)) {
        byKey[d.key] = d;
        updated++;
      }
    }
    foodDays = byKey.values.toList();
  }

  // Noches: una por fecha.
  List<SleepEntry>? sleep;
  var addedSleep = 0;
  if (current.sleep != null || incoming.sleep != null) {
    final byKey = <String, SleepEntry>{for (final e in current.sleep ?? const <SleepEntry>[]) e.key: e};
    for (final e in incoming.sleep ?? const <SleepEntry>[]) {
      final mine = byKey[e.key];
      if (mine == null) {
        byKey[e.key] = e;
        addedSleep++;
      } else if (_newer(e.updatedAt, mine.updatedAt)) {
        byKey[e.key] = e;
        updated++;
      }
    }
    sleep = byKey.values.toList();
  }

  // Deposiciones: por identificador.
  List<BowelEntry>? bowel;
  var addedBowel = 0;
  if (current.bowel != null || incoming.bowel != null) {
    final byId = <String, BowelEntry>{for (final e in current.bowel ?? const <BowelEntry>[]) e.id: e};
    for (final e in incoming.bowel ?? const <BowelEntry>[]) {
      final mine = byId[e.id];
      if (mine == null) {
        byId[e.id] = e;
        addedBowel++;
      } else if (_newer(e.updatedAt, mine.updatedAt)) {
        byId[e.id] = e;
        updated++;
      }
    }
    bowel = byId.values.toList();
  }

  return MergeResult(
    data: BackupData(
      records: records,
      treatments: treatments,
      medications: medications,
      settings: current.settings,
      foods: foods,
      foodDays: foodDays,
      sleep: sleep,
      bowel: bowel,
    ),
    added: DataCounts(
      pain: addedPain,
      bowel: addedBowel,
      sleep: addedSleep,
      foodDays: addedFoodDays,
      treatments: addedTreatments,
    ),
    updated: updated,
  );
}
