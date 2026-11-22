// Deposiciones: modelo, guardado, estado, copia de seguridad, informe,
// gráficas y pantalla.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope/charts/bowel_stats.dart';
import 'package:hope/charts/full_report.dart';
import 'package:hope/charts/full_report_text.dart';
import 'package:hope/data/backup.dart';
import 'package:hope/data/stores.dart';
import 'package:hope/l10n/strings.dart';
import 'package:hope/models/bowel.dart';
import 'package:hope/screens/bowel_screen.dart';
import 'package:hope/state/app_controller.dart';

import 'helpers.dart';

Future<void> pumpBowel(WidgetTester tester, AppController c, Widget screen) async {
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = const Size(412, 915) * 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(AppScope(
    controller: c,
    child: MaterialApp(
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: screen,
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  final config = loadConfig();
  const es = S('es');
  String foodName(String id) => config.foodById(id)?.name('es') ?? id;

  group('modelo', () {
    test('se guarda y se lee igual', () {
      final e = BowelEntry(
        id: 'b1',
        dateTime: DateTime(2026, 11, 20, 8, 30),
        quality: 2,
        note: 'Con esfuerzo',
        updatedAt: DateTime(2026, 11, 20, 8, 31),
      );
      final back = BowelEntry.fromJson(jsonDecode(jsonEncode(e.toJson())) as Map<String, dynamic>);
      expect(back.toJson(), e.toJson());
      expect(back.dayKeyText, '2026-11-20');
    });

    test('la calidad queda entre 1 y 5', () {
      expect(BowelEntry(id: 'a', dateTime: DateTime(2026), quality: 0).quality, 1);
      expect(BowelEntry(id: 'b', dateTime: DateTime(2026), quality: 9).quality, 5);
    });

    test('los nombres de la escala', () {
      expect(es.bowelQualityName(1), 'Estreñimiento total');
      expect(es.bowelQualityName(3), 'Normal');
      expect(es.bowelQualityName(5), 'Diarrea líquida');
      expect(const S('en').bowelQualityName(5), 'Liquid diarrhoea');
    });
  });

  test('el archivo de deposiciones se guarda aparte y se vuelve a leer', () async {
    final dir = await Directory.systemTemp.createTemp('hope_dep');
    addTearDown(() => dir.delete(recursive: true));
    final store = JsonFileBowelStore(dir);
    expect(await store.load(), isEmpty);
    await store.saveAll([BowelEntry(id: 'x', dateTime: DateTime(2026, 11, 1, 9), quality: 3)]);
    expect(File('${dir.path}/hope_deposiciones.json').existsSync(), isTrue);
    final again = await JsonFileBowelStore(dir).load();
    expect(again.single.id, 'x');
    // Un archivo dañado se aparta y no se pierde.
    File('${dir.path}/hope_deposiciones.json').writeAsStringSync('{roto');
    expect(await JsonFileBowelStore(dir).load(), isEmpty);
    expect(dir.listSync().any((f) => f.path.contains('hope_deposiciones.json.danado-')), isTrue);
  });

  group('estado', () {
    test('guardar, editar, borrar y deshacer', () async {
      final c = await testController();
      final e = BowelEntry.create(dateTime: DateTime(2026, 11, 21, 9), quality: 3);
      await c.saveBowel(e);
      await c.saveBowel(BowelEntry.create(dateTime: DateTime(2026, 11, 21, 20), quality: 5));
      await c.saveBowel(BowelEntry.create(dateTime: DateTime(2026, 11, 20, 8), quality: 1));
      expect(c.bowelEntries.length, 3);
      // De la más reciente a la más antigua.
      expect(c.bowelEntries.first.quality, 5);
      expect(c.bowelOn(DateTime(2026, 11, 21)).length, 2);

      await c.saveBowel(c.bowelById(e.id)!.copyWith(quality: 2));
      expect(c.bowelById(e.id)!.quality, 2);
      expect(c.bowelEntries.length, 3);
      expect(c.bowelById(e.id)!.updatedAt, isNotNull);

      final removed = await c.deleteBowel(e.id);
      expect(c.bowelEntries.length, 2);
      await c.restoreBowel(removed!);
      expect(c.bowelEntries.length, 3);

      await c.deleteAll();
      expect(c.bowelEntries, isEmpty);
    });
  });

  group('copia de seguridad', () {
    test('incluye las deposiciones (formato 5)', () async {
      final c = await testController(bowel: [
        BowelEntry(id: 'b1', dateTime: DateTime(2026, 11, 12, 9), quality: 4, note: 'Blanda'),
      ]);
      final text = encodeBackup(BackupData(
        records: c.records,
        treatments: c.treatments,
        medications: c.medicationEntries,
        bowel: c.bowelEntries,
      ));
      final json = jsonDecode(text) as Map<String, dynamic>;
      expect(json['version'], 5);
      expect((json['deposiciones'] as List).length, 1);
      final back = decodeBackup(text)!;
      expect(back.bowel!.single.note, 'Blanda');
      expect(back.createdWith, isNotEmpty);
    });

    test('una copia anterior a la 0.5 conserva las deposiciones del dispositivo', () async {
      const old = '{"formato": "hope-copia", "version": 4, "registros": [], '
          '"medicamentos": [], "tratamientos": [], "sueno": []}';
      final data = decodeBackup(old)!;
      expect(data.bowel, isNull);
      final c = await testController(bowel: [
        BowelEntry(id: 'b1', dateTime: DateTime(2026, 11, 12, 9), quality: 3),
      ]);
      await c.replaceAll(
        records: data.records,
        treatments: data.treatments,
        medications: data.medications,
        sleep: data.sleep,
        bowel: data.bowel,
      );
      expect(c.bowelEntries.length, 1);
    });
  });

  group('informe completo', () {
    final now = DateTime(2026, 11, 14, 20);

    test('sin deposiciones registradas, el apartado no aparece', () {
      final r = buildFullReport(
        records: const [],
        foodDays: const [],
        sleep: const [],
        config: config,
        periodDays: 7,
        now: now,
      );
      final w = ReportWriter(report: r, s: es, lang: 'es', config: config, foodName: foodName);
      expect(r.tracksBowel, isFalse);
      expect(w.blocks().map((b) => b.title), isNot(contains(es.reportBowelTitle)));
    });

    test('con deposiciones solo fuera del periodo, «Datos insuficientes»', () {
      final r = buildFullReport(
        records: const [],
        foodDays: const [],
        sleep: const [],
        bowel: [BowelEntry(id: 'old', dateTime: DateTime(2026, 10, 1, 9), quality: 3)],
        config: config,
        periodDays: 7,
        now: now,
      );
      final w = ReportWriter(report: r, s: es, lang: 'es', config: config, foodName: foodName);
      final block = w.blocks().firstWhere((b) => b.title == es.reportBowelTitle);
      expect(block.insufficient, isTrue);
      expect(block.missing.single, es.missingBowel);
      expect(r.allInsufficient, isTrue);
    });

    test('describe número, calidad y días', () {
      // Del 8 al 14 de noviembre: 3 el día 8 (1, 3, 5), 1 el 10 (3) y 2 el 14
      // (2 y 3). Ninguna los días 9, 11, 12 y 13.
      final bowel = [
        BowelEntry(id: 'a', dateTime: DateTime(2026, 11, 8, 8), quality: 1),
        BowelEntry(id: 'b', dateTime: DateTime(2026, 11, 8, 13), quality: 3),
        BowelEntry(id: 'c', dateTime: DateTime(2026, 11, 8, 20), quality: 5),
        BowelEntry(id: 'd', dateTime: DateTime(2026, 11, 10, 9), quality: 3),
        BowelEntry(id: 'e', dateTime: DateTime(2026, 11, 14, 7), quality: 2),
        BowelEntry(id: 'f', dateTime: DateTime(2026, 11, 14, 19), quality: 3),
        // Fuera del periodo.
        BowelEntry(id: 'g', dateTime: DateTime(2026, 11, 7, 23, 59), quality: 5),
      ];
      final r = buildFullReport(
        records: const [],
        foodDays: const [],
        sleep: const [],
        bowel: bowel,
        config: config,
        periodDays: 7,
        now: now,
      );
      final b = r.bowel!;
      expect(b.total, 6);
      expect(b.days, 3);
      expect(b.daysWithout, 4);
      expect(b.distribution, [1, 1, 3, 0, 1]);
      expect(b.mean, closeTo(17 / 6, 1e-9));
      expect(b.hardDays, 2);
      expect(b.looseDays, 1);
      expect(b.mostCommon, 3);
      expect(r.bowelCount, 6);
      expect(r.allInsufficient, isFalse);

      final w = ReportWriter(report: r, s: es, lang: 'es', config: config, foodName: foodName);
      final blocks = w.blocks();
      final block = blocks.firstWhere((x) => x.title == es.reportBowelTitle);
      expect(block.insufficient, isFalse);
      expect(block.lines.first, 'Total: 6 deposiciones · media de 0,9 al día');
      expect(blocks.first.lines, contains('Deposiciones: 6 en 3 días'));
      // Las relaciones siguen siendo el último apartado.
      expect(blocks.last.title, es.reportRelationsTitle);
      expect(w.conclusions(), contains(es.cBowel(6, '0,9', 'Normal')));
      expect(w.aiSummary(), contains('Deposiciones'));
    });
  });

  test('estadística por día de las gráficas', () {
    final days = bowelDays(
      [
        BowelEntry(id: 'a', dateTime: DateTime(2026, 11, 2, 20), quality: 4),
        BowelEntry(id: 'b', dateTime: DateTime(2026, 11, 2, 8), quality: 2),
        BowelEntry(id: 'c', dateTime: DateTime(2026, 11, 4, 9), quality: 3),
      ],
      DateTime(2026, 11, 1),
      DateTime(2026, 11, 4, 18),
    );
    expect(days.length, 4);
    expect(days.map((d) => d.count), [0, 2, 0, 1]);
    expect(days[1].mean, 3);
    expect(days[1].entries.first.quality, 2); // De la más temprana a la más tardía.
    expect(days[0].mean, isNull);
    final summary = BowelSummary.of(days);
    expect(summary.total, 3);
    expect(summary.daysWith, 2);
    expect(summary.perDay, 0.75);
    expect(summary.mean, 3);
  });

  group('pantalla', () {
    testWidgets('registra una deposición con un toque en la calidad y Guardar', (tester) async {
      final c = await testController();
      await pumpBowel(tester, c, const BowelScreen());
      expect(find.text('Aún no has registrado ninguna deposición.'), findsOneWidget);
      // Sin calidad no se puede guardar.
      final save = find.byKey(const ValueKey('bowel-save'));
      expect(tester.widget<FilledButton>(save).onPressed, isNull);

      await tester.tap(find.byKey(const ValueKey('bowel-quality-5')));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Tras la cena');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(c.bowelEntries.length, 1);
      expect(c.bowelEntries.single.quality, 5);
      expect(c.bowelEntries.single.note, 'Tras la cena');
      expect(find.text('Deposición guardada'), findsOneWidget);
      expect(find.textContaining('Diarrea líquida'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('desde la lista se edita y se borra con deshacer', (tester) async {
      final now = DateTime.now();
      final c = await testController(bowel: [
        BowelEntry(id: 'b1', dateTime: DateTime(now.year, now.month, now.day, 7, 15), quality: 2),
      ]);
      await pumpBowel(tester, c, const BowelScreen());
      final list = find.byType(Scrollable).first;
      const tile = '07:15 · Heces duras / con esfuerzo';
      await tester.scrollUntilVisible(find.text(tile), 200, scrollable: list);
      await tester.tap(find.text(tile));
      await tester.pump();
      expect(find.textContaining('Editando la deposición'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('bowel-quality-3')));
      await tester.pump();
      final save = find.byKey(const ValueKey('bowel-save'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(c.bowelEntries.single.quality, 3);
      expect(c.bowelEntries.single.id, 'b1');
      expect(find.text('Deposición actualizada'), findsOneWidget);

      await tester.scrollUntilVisible(find.byTooltip('Borrar'), 200, scrollable: list);
      await tester.tap(find.byTooltip('Borrar').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Borrar').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(c.bowelEntries, isEmpty);
      // El aviso sustituye al anterior: primero sale uno y luego entra el otro.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
      await tester.tap(find.text('Deshacer'));
      await tester.pump();
      expect(c.bowelEntries.length, 1);
      expect(tester.takeException(), isNull);
    });
  });
}
