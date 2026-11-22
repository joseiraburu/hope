// Importar/Exportar: el informe completo en HTML (legible e importable),
// combinar o reemplazar datos y archivos de versiones anteriores.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hope/data/backup.dart';
import 'package:hope/data/merge.dart';
import 'package:hope/export/backup_flow.dart';
import 'package:hope/export/full_export_html.dart';
import 'package:hope/l10n/strings.dart';
import 'package:hope/models/bowel.dart';
import 'package:hope/models/food.dart';
import 'package:hope/models/pain_record.dart';
import 'package:hope/models/sleep.dart';
import 'package:hope/models/treatment.dart';

import 'helpers.dart';

PainRecord pain(String id, DateTime at, int intensity, {String note = ''}) => PainRecord(
      id: id,
      dateTime: at,
      sex: 'female',
      painIntensity: intensity,
      zones: const ['pies_izq', 'pies_der'],
      zoneCount: 1,
      surfacePct: 7,
      eventIntensity: 3,
      eventTypes: const ['pinchazo'],
      eventFrequency: 60,
      seed: 5,
      note: note,
    );

void main() {
  final treatment = Treatment(
    id: 't1',
    medicationId: 'lidocaina',
    medicationName: 'Lidocaína',
    route: 'iv',
    dose: 300,
    unit: 'mg',
    start: DateTime(2026, 11, 3, 10),
  );

  Future<String> exportHtml() async {
    final c = await testController(
      records: [
        pain('r1', DateTime(2026, 11, 20, 9), 6, note: 'Nota con <script>alert(1)</script> & «comillas»'),
        pain('r2', DateTime(2026, 11, 21, 9), 4),
      ],
      treatments: [treatment],
      bowel: [
        BowelEntry(id: 'b1', dateTime: DateTime(2026, 11, 20, 8), quality: 5, note: '</script><b>x</b>'),
        BowelEntry(id: 'b2', dateTime: DateTime(2026, 11, 21, 8), quality: 3),
      ],
    );
    await c.saveSleep(SleepEntry(date: DateTime(2026, 11, 21), quality: 2, withPain: true));
    await c.saveFoodDay(FoodDay(date: DateTime(2026, 11, 21), meals: {
      MealSlot.breakfast: const MealLog(foods: ['bread'], time: '08:00'),
      MealSlot.dinner: const MealLog(skipped: true),
    }));
    return buildFullExport(c, now: DateTime(2026, 11, 22, 12));
  }

  group('informe completo en HTML', () {
    test('se lee como informe y lleva todos los datos para importarlos', () async {
      final html = await exportHtml();
      saveSample('informe_completo.html', utf8.encode(html));
      expect(html, startsWith('<!DOCTYPE html>'));
      expect(html, contains('HOPE · Informe completo'));
      expect(html, contains('Registros de dolor (2)'));
      expect(html, contains('Deposiciones (2)'));
      expect(html, contains('Diarrea líquida'));
      expect(html, contains('Lidocaína'));
      expect(html, contains('No realizada'));
      expect(html, contains('Resumen de los últimos 30 días'));
      expect(fullExportFileName(DateTime(2026, 11, 22)), 'Hope_informe_2026-11-22.html');

      final data = decodeExportFile(html)!;
      expect(data.records.map((r) => r.id).toSet(), {'r1', 'r2'});
      expect(data.bowel!.map((e) => e.id).toSet(), {'b1', 'b2'});
      expect(data.sleep!.single.quality, 2);
      expect(data.foodDays!.single.isSkipped(MealSlot.dinner), isTrue);
      expect(data.treatments.single.id, 't1');
      expect(data.records.firstWhere((r) => r.id == 'r1').note, contains('<script>'));
      expect(data.bowel!.firstWhere((e) => e.id == 'b1').note, '</script><b>x</b>');
    });

    test('los textos del usuario no pueden romper el HTML', () async {
      final html = await exportHtml();
      // En la parte visible, escapados.
      expect(html, contains('&lt;script&gt;alert(1)&lt;/script&gt; &amp; «comillas»'));
      expect(html, isNot(contains('<script>alert(1)')));
      // Solo hay un bloque <script> y es el de los datos.
      expect('<script'.allMatches(html).length, 1);
      expect('</script>'.allMatches(html).length, 1);
      expect(html, contains('<script type="application/json" id="$backupHtmlScriptId">'));
    });

    test('una copia .json (también de versiones anteriores) se sigue leyendo', () {
      const v3 = '{"formato": "hope-copia", "version": 3, "registros": [], '
          '"medicamentos": [], "tratamientos": [], "dias_alimentacion": []}';
      final data = decodeExportFile(v3)!;
      expect(data.sleep, isNull);
      expect(data.bowel, isNull);
      expect(data.foodDays, isEmpty);
      // Con marca de orden de bytes y espacios delante.
      expect(decodeExportFile('﻿  $v3'), isNotNull);
    });

    test('lo que no es de HOPE se rechaza sin cargar nada', () {
      expect(decodeExportFile('<html><body>Hola</body></html>'), isNull);
      expect(decodeExportFile('<script type="application/json" id="hope-datos">{"formato": "otro"}</script>'),
          isNull);
      expect(decodeExportFile('<script type="application/json" id="hope-datos">{roto</script>'), isNull);
      expect(decodeExportFile(''), isNull);
    });
  });

  group('combinar', () {
    final mine = BackupData(
      records: [pain('r1', DateTime(2026, 11, 1, 9), 5), pain('r2', DateTime(2026, 11, 2, 9), 6)],
      treatments: [treatment],
      medications: const [MedicationDef(id: 'med_a', customName: 'Pregabalina')],
      sleep: [
        SleepEntry(date: DateTime(2026, 11, 2), quality: 4, updatedAt: DateTime(2026, 11, 2, 8)),
        SleepEntry(date: DateTime(2026, 11, 3), quality: 3, updatedAt: DateTime(2026, 11, 3, 8)),
      ],
      foodDays: [
        FoodDay.withFoods(DateTime(2026, 11, 2), {MealSlot.lunch: const ['pasta']})
            .copyWith(updatedAt: DateTime(2026, 11, 2, 15)),
      ],
      bowel: [BowelEntry(id: 'b1', dateTime: DateTime(2026, 11, 2, 8), quality: 3)],
    );
    final file = BackupData(
      records: [
        // r2 también está en el archivo, con otro valor: queda el del dispositivo.
        pain('r2', DateTime(2026, 11, 2, 9), 9),
        pain('r3', DateTime(2026, 11, 3, 9), 2),
      ],
      treatments: [treatment, treatment.copyWith(id: 't2', start: DateTime(2026, 11, 10))],
      medications: const [MedicationDef(id: 'med_a', customName: 'Otro nombre'), MedicationDef(id: 'med_b')],
      sleep: [
        // Más reciente que la del dispositivo: la sustituye.
        SleepEntry(date: DateTime(2026, 11, 2), quality: 1, updatedAt: DateTime(2026, 11, 5, 8)),
        // Más antigua: se conserva la del dispositivo.
        SleepEntry(date: DateTime(2026, 11, 3), quality: 5, updatedAt: DateTime(2026, 11, 1, 8)),
        SleepEntry(date: DateTime(2026, 11, 4), quality: 4),
      ],
      foodDays: [
        FoodDay.withFoods(DateTime(2026, 11, 4), {MealSlot.dinner: const ['fish']}),
      ],
      bowel: [
        BowelEntry(id: 'b1', dateTime: DateTime(2026, 11, 2, 8), quality: 5),
        BowelEntry(id: 'b2', dateTime: DateTime(2026, 11, 4, 8), quality: 2),
      ],
    );

    test('añade lo nuevo sin duplicar y respeta lo del dispositivo', () {
      final result = mergeBackup(mine, file);
      final m = result.data;
      expect(m.records.map((r) => r.id).toSet(), {'r1', 'r2', 'r3'});
      expect(m.records.firstWhere((r) => r.id == 'r2').painIntensity, 6);
      expect(m.treatments.map((t) => t.id).toSet(), {'t1', 't2'});
      expect(m.medications.firstWhere((x) => x.id == 'med_a').customName, 'Pregabalina');
      expect(m.medications.map((x) => x.id).toSet(), {'med_a', 'med_b'});
      final nights = {for (final e in m.sleep!) e.key: e.quality};
      expect(nights, {'2026-11-02': 1, '2026-11-03': 3, '2026-11-04': 4});
      expect(m.foodDays!.map((d) => d.key).toSet(), {'2026-11-02', '2026-11-04'});
      // Sin fecha de guardado en el archivo: se conserva la del dispositivo.
      expect(m.bowel!.firstWhere((e) => e.id == 'b1').quality, 3);
      expect(m.bowel!.length, 2);

      expect(result.added.pain, 1);
      expect(result.added.treatments, 1);
      expect(result.added.sleep, 1);
      expect(result.added.foodDays, 1);
      expect(result.added.bowel, 1);
      expect(result.added.total, 5);
      expect(result.updated, 1);
    });

    test('combinar dos veces el mismo archivo no añade nada', () {
      final once = mergeBackup(mine, file).data;
      final twice = mergeBackup(once, file);
      expect(twice.added.total, 0);
      expect(twice.updated, 0);
      expect(twice.data.records.length, once.records.length);
    });

    test('se aplica al dispositivo y se ordena', () async {
      final c = await testController(
        records: mine.records,
        treatments: mine.treatments,
        bowel: mine.bowel,
      );
      final merged = mergeBackup(currentData(c), file).data;
      await c.replaceAll(
        records: merged.records,
        treatments: merged.treatments,
        medications: merged.medications,
        foods: merged.foods,
        foodDays: merged.foodDays,
        sleep: merged.sleep,
        bowel: merged.bowel,
      );
      expect(c.records.map((r) => r.id), ['r3', 'r2', 'r1']);
      expect(c.bowelEntries.map((e) => e.id), ['b2', 'b1']);
      expect(c.treatments.first.id, 't2');
      expect(c.settings.firstRunDone, isTrue);
    });
  });

  test('el resumen de lo que contiene un archivo', () {
    const s = DataCounts(pain: 3, bowel: 2, sleep: 1, foodDays: 4, treatments: 0);
    expect(s.total, 10);
    final text = const S('es').dataCounts(s);
    expect(text, 'Dolor: 3 registros · Deposiciones: 2 · Sueño: 1 noche · Alimentación: 4 días · '
        'Tratamientos: 0');
  });
}
