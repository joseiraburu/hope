import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope/app.dart';
import 'package:hope/charts/compare.dart';
import 'package:hope/charts/params.dart';
import 'package:hope/data/stores.dart';
import 'package:hope/models/pain_record.dart';
import 'package:hope/models/treatment.dart';
import 'package:hope/utils/format.dart';

import 'helpers.dart';

Treatment lido({String id = 't1', DateTime? start, DateTime? end}) => Treatment(
      id: id,
      medicationId: 'lidocaina',
      medicationName: 'Lidocaína',
      route: 'iv',
      dose: 300,
      unit: 'mg',
      start: start ?? DateTime(2026, 10, 10, 10),
      end: end,
      schedule: '',
      notes: 'Unidad del dolor',
      adverseEffects: const ['mareo'],
      adverseOther: 'Sabor metálico',
    );

PainRecord rec(DateTime at, int pain, {int events = 5, int freq = 100, double surface = 10}) =>
    PainRecord(
      id: newUuid(),
      dateTime: at,
      sex: 'female',
      painIntensity: pain,
      zones: const ['pies_izq'],
      surfacePct: surface,
      eventIntensity: events,
      eventTypes: events > 0 ? const ['pinchazo'] : const [],
      eventFrequency: freq,
      seed: 1,
    );

void main() {
  test('un tratamiento se guarda y se recupera igual (JSON)', () {
    final t = lido(end: DateTime(2026, 10, 13, 10));
    final back = Treatment.fromJson(t.toJson());
    expect(back.id, 't1');
    expect(back.medicationId, 'lidocaina');
    expect(back.dose, 300);
    expect(back.unit, 'mg');
    expect(back.start, t.start);
    expect(back.end, t.end);
    expect(back.adverseEffects, ['mareo']);
    expect(back.adverseOther, 'Sabor metálico');
    final punctual = Treatment.fromJson(lido().toJson());
    expect(punctual.isPunctual, isTrue);
    expect(punctual.end, isNull);
  });

  test('un tratamiento puntual se solapa solo con su momento', () {
    final t = lido(start: DateTime(2026, 10, 10, 10));
    expect(t.overlaps(DateTime(2026, 10, 10), DateTime(2026, 10, 11)), isTrue);
    expect(t.overlaps(DateTime(2026, 10, 11), DateTime(2026, 10, 12)), isFalse);
    final period = lido(start: DateTime(2026, 10, 1), end: DateTime(2026, 10, 20));
    expect(period.overlaps(DateTime(2026, 10, 15), DateTime(2026, 10, 16)), isTrue);
    expect(period.overlaps(DateTime(2026, 10, 21), DateTime(2026, 10, 22)), isFalse);
  });

  test('tratamientos y medicamentos en el estado de la app', () async {
    final c = await testController();
    expect(c.medications.map((m) => m.id), ['lidocaina', 'fentanilo', 'oxicodona']);
    expect(c.medicationName('fentanilo'), 'Fentanilo');

    await c.addTreatment(lido(id: 'a', start: DateTime(2026, 1, 1)));
    await c.addTreatment(lido(id: 'b', start: DateTime(2026, 3, 1)));
    expect(c.treatments.map((t) => t.id), ['b', 'a']);
    await c.updateTreatment(lido(id: 'a', start: DateTime(2026, 5, 1)));
    expect(c.treatments.map((t) => t.id), ['a', 'b']);
    final removed = await c.deleteTreatment('b');
    expect(removed?.id, 'b');
    expect(c.treatments.length, 1);

    final m = await c.addMedication('Pregabalina');
    expect(c.medicationName(m.id), 'Pregabalina');
    await c.renameMedication('oxicodona', 'Oxicodona LP');
    expect(c.medicationName('oxicodona'), 'Oxicodona LP');
    await c.setMedicationHidden('fentanilo', true);
    expect(c.visibleMedications.map((m) => m.id), isNot(contains('fentanilo')));
    expect(c.medications.length, 4);
  });

  test('el archivo de tratamientos guarda y lee', () async {
    final dir = await Directory.systemTemp.createTemp('hope_trat');
    try {
      final store = JsonFileTreatmentStore(dir);
      expect((await store.load()).treatments, isEmpty);
      await store.save(TreatmentData(
        medications: const [MedicationDef(id: 'med_1', customName: 'Capsaicina')],
        treatments: [lido()],
      ));
      final data = await store.load();
      expect(data.treatments.single.id, 't1');
      expect(data.medications.single.customName, 'Capsaicina');
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('comparar antes y después: medias descriptivas', () {
    final pivot = DateTime(2026, 10, 10, 10);
    final records = [
      rec(DateTime(2026, 10, 1), 8, surface: 20),
      rec(DateTime(2026, 10, 5), 6, surface: 10),
      rec(DateTime(2026, 10, 12), 4, events: 0),
      rec(DateTime(2026, 10, 15), 2, freq: 50),
      rec(DateTime(2026, 9, 1), 10), // fuera de la ventana
    ];
    final r = compareAround(records, pivot, 14);
    expect(r.recordsBefore, 2);
    expect(r.recordsAfter, 2);
    expect(r.before[Param.pain]!.mean, 7);
    expect(r.after[Param.pain]!.mean, 3);
    expect(r.change(Param.pain), -4);
    expect(r.before[Param.surface]!.mean, 15);
    // Sin eventos, la frecuencia no cuenta en la media.
    expect(r.after[Param.eventFrequency]!.n, 1);
    expect(r.after[Param.eventFrequency]!.mean, 50);
    expect(formatParamChange(Param.pain, -4, 'es'), '−4');
    expect(formatParam(Param.surface, 15, 'es'), '15 %');
  });

  test('formatos de números y dosis', () {
    expect(formatNumber(12.5, 'es'), '12,5');
    expect(formatNumber(12.5, 'en'), '12.5');
    expect(formatNumber(300, 'es'), '300');
    expect(formatDose(12.5, 'µg/h', 'es'), '12,5 µg/h');
    expect(parseDecimal('12,5'), 12.5);
    expect(parseDecimal(' 300 '), 300);
    expect(parseDecimal('abc'), isNull);
  });

  testWidgets('añadir un tratamiento desde el menú', (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(412, 915) * 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = await testController();
    await tester.pumpWidget(HopeApp(controller: c));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Tratamientos').last);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Todavía no hay tratamientos'), findsOneWidget);
    await tester.tap(find.text('Añadir tratamiento').last);
    await tester.pump(const Duration(milliseconds: 600));
    // Sin dosis no se guarda.
    await tester.tap(find.widgetWithText(TextButton, 'Guardar'));
    await tester.pump();
    expect(find.text('Escribe una dosis mayor que 0'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Dosis'), '300');
    await tester.tap(find.widgetWithText(TextButton, 'Guardar'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(c.treatments.length, 1);
    expect(c.treatments.single.medicationId, 'lidocaina');
    expect(c.treatments.single.route, 'iv');
    expect(find.textContaining('Lidocaína · 300 mg'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
