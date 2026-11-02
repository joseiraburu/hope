// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:convert';

import '../core/version.dart';
import '../models/app_settings.dart';
import '../models/food.dart';
import '../models/pain_record.dart';
import '../models/treatment.dart';

/// Contenido de una copia de seguridad.
class BackupData {
  const BackupData({
    required this.records,
    required this.treatments,
    required this.medications,
    this.settings,
    this.foods,
    this.foodDays,
  });

  final List<PainRecord> records;
  final List<Treatment> treatments;
  final List<MedicationDef> medications;
  final AppSettings? settings;

  /// Alimentación (desde la versión 0.3). Nulo en copias anteriores.
  final List<FoodDef>? foods;
  final List<FoodDay>? foodDays;
}

/// Convierte los datos en el texto JSON de la copia.
String encodeBackup(BackupData data, {DateTime? now}) {
  return const JsonEncoder.withIndent(' ').convert({
    'formato': 'hope-copia',
    'version': 3,
    'app': appVersion,
    'fecha': isoWithOffset(now ?? DateTime.now()),
    if (data.settings != null) 'ajustes': data.settings!.toJson(),
    'registros': [for (final r in data.records) r.toJson()],
    'medicamentos': [for (final m in data.medications) m.toJson()],
    'tratamientos': [for (final t in data.treatments) t.toJson()],
    if (data.foods != null) 'alimentos': [for (final f in data.foods!) f.toJson()],
    if (data.foodDays != null) 'dias_alimentacion': [for (final d in data.foodDays!) d.toJson()],
  });
}

/// Lee una copia. Devuelve null si el texto no es una copia de HOPE.
BackupData? decodeBackup(String text) {
  try {
    final j = jsonDecode(text);
    if (j is! Map<String, dynamic> || j['formato'] != 'hope-copia') return null;
    final settings = j['ajustes'];
    final foods = j['alimentos'];
    final foodDays = j['dias_alimentacion'];
    return BackupData(
      records: [
        for (final r in (j['registros'] as List<dynamic>? ?? const []))
          PainRecord.fromJson(r as Map<String, dynamic>)
      ],
      medications: [
        for (final m in (j['medicamentos'] as List<dynamic>? ?? const []))
          MedicationDef.fromJson(m as Map<String, dynamic>)
      ],
      treatments: [
        for (final t in (j['tratamientos'] as List<dynamic>? ?? const []))
          Treatment.fromJson(t as Map<String, dynamic>)
      ],
      settings: settings is Map<String, dynamic> ? AppSettings.fromJson(settings) : null,
      foods: foods is List<dynamic>
          ? [for (final f in foods) FoodDef.fromJson(f as Map<String, dynamic>)]
          : null,
      foodDays: foodDays is List<dynamic>
          ? [for (final d in foodDays) FoodDay.fromJson(d as Map<String, dynamic>)]
          : null,
    );
  } catch (_) {
    return null;
  }
}
