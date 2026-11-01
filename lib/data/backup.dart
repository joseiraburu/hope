// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:convert';

import '../core/version.dart';
import '../models/app_settings.dart';
import '../models/pain_record.dart';
import '../models/treatment.dart';

/// Contenido de una copia de seguridad.
class BackupData {
  const BackupData({
    required this.records,
    required this.treatments,
    required this.medications,
    this.settings,
  });

  final List<PainRecord> records;
  final List<Treatment> treatments;
  final List<MedicationDef> medications;
  final AppSettings? settings;
}

/// Convierte los datos en el texto JSON de la copia.
String encodeBackup(BackupData data, {DateTime? now}) {
  return const JsonEncoder.withIndent(' ').convert({
    'formato': 'hope-copia',
    'version': 2,
    'app': appVersion,
    'fecha': isoWithOffset(now ?? DateTime.now()),
    if (data.settings != null) 'ajustes': data.settings!.toJson(),
    'registros': [for (final r in data.records) r.toJson()],
    'medicamentos': [for (final m in data.medications) m.toJson()],
    'tratamientos': [for (final t in data.treatments) t.toJson()],
  });
}

/// Lee una copia. Devuelve null si el texto no es una copia de HOPE.
BackupData? decodeBackup(String text) {
  try {
    final j = jsonDecode(text);
    if (j is! Map<String, dynamic> || j['formato'] != 'hope-copia') return null;
    final settings = j['ajustes'];
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
    );
  } catch (_) {
    return null;
  }
}
