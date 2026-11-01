// Copia de seguridad: exportar e importar todos los datos.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hope/data/backup.dart';
import 'package:hope/models/app_settings.dart';
import 'package:hope/models/pain_record.dart';
import 'package:hope/models/treatment.dart';

import 'helpers.dart';

void main() {
  final record = PainRecord(
    id: 'r1',
    dateTime: DateTime(2026, 10, 30, 9, 15),
    sex: 'male',
    painIntensity: 5,
    zones: const ['pies_izq', 'pies_der', 'cuello_delante'],
    zoneCount: 2,
    surfacePct: 7.5,
    eventIntensity: 4,
    eventTypes: const ['pinchazo'],
    eventFrequency: 60,
    seed: 77,
    note: 'Después de caminar',
  );
  final treatment = Treatment(
    id: 't1',
    medicationId: 'lidocaina',
    medicationName: 'Lidocaína',
    route: 'iv',
    dose: 300,
    unit: 'mg',
    start: DateTime(2026, 10, 15, 10),
    adverseEffects: const ['mareo'],
    notes: 'Unidad del dolor',
  );

  test('la copia se lee igual que se escribió', () {
    const settings = AppSettings(firstRunDone: true, language: 'en', hideDateInExports: true);
    final text = encodeBackup(
      BackupData(
        records: [record],
        treatments: [treatment],
        medications: const [MedicationDef(id: 'med_abcd1234', customName: 'Pregabalina')],
        settings: settings,
      ),
      now: DateTime(2026, 11, 1, 12),
    );
    final json = jsonDecode(text) as Map<String, dynamic>;
    expect(json['formato'], 'hope-copia');
    expect(json['app'], isNotEmpty);

    final back = decodeBackup(text)!;
    expect(back.records.single.toJson(), record.toJson());
    expect(back.treatments.single.toJson(), treatment.toJson());
    expect(back.medications.single.customName, 'Pregabalina');
    expect(back.settings!.language, 'en');
    expect(back.settings!.hideDateInExports, isTrue);
  });

  test('un archivo que no es una copia de HOPE se rechaza', () {
    expect(decodeBackup('no es json'), isNull);
    expect(decodeBackup('{"formato": "otro"}'), isNull);
    expect(decodeBackup('[1, 2, 3]'), isNull);
  });

  test('importar sustituye los datos', () async {
    final source = await testController(records: [record], treatments: [treatment]);
    await source.addMedication('Gabapentina');
    final text = encodeBackup(BackupData(
      records: source.records,
      treatments: source.treatments,
      medications: source.medicationEntries,
      settings: source.settings,
    ));

    final target = await testController(records: [
      PainRecord(
        id: 'otro',
        dateTime: DateTime(2026, 1, 1),
        sex: 'female',
        painIntensity: 2,
        zones: const ['pecho'],
        surfacePct: 13,
        eventIntensity: 0,
        eventTypes: const [],
        eventFrequency: 10,
        seed: 1,
      ),
    ]);
    final data = decodeBackup(text)!;
    await target.replaceAll(
      records: data.records,
      treatments: data.treatments,
      medications: data.medications,
      settings: data.settings,
    );
    expect(target.records.map((r) => r.id), ['r1']);
    expect(target.treatments.map((t) => t.id), ['t1']);
    expect(target.visibleMedications.map((m) => target.medicationName(m.id)), contains('Gabapentina'));
  });
}
