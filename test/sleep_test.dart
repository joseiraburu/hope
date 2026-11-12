// Sueño: modelo, guardado, copia de seguridad y borrado.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hope/data/backup.dart';
import 'package:hope/data/stores.dart';
import 'package:hope/models/app_settings.dart';
import 'package:hope/models/sleep.dart';
import 'package:hope/state/app_controller.dart';

import 'helpers.dart';

Future<AppController> sleepController([List<SleepEntry>? nights]) async {
  final c = AppController(
    config: loadConfig(),
    geometry: loadGeometry(),
    recordStore: MemoryRecordStore(),
    settingsStore: MemorySettingsStore(const AppSettings(firstRunDone: true, language: 'es')),
    sleepStore: MemorySleepStore(nights),
  );
  await c.init();
  return c;
}

void main() {
  test('una noche se guarda y se recupera igual (JSON)', () {
    final night = SleepEntry(
      date: DateTime(2026, 11, 12, 7, 30),
      quality: 2,
      withPain: true,
      note: 'Me desperté tres veces',
      updatedAt: DateTime(2026, 11, 12, 8),
    );
    expect(night.date, DateTime(2026, 11, 12));
    expect(night.nightStart, DateTime(2026, 11, 11));
    final json = night.toJson();
    expect(json['fecha'], '2026-11-12');
    expect(json['calidad'], 2);
    expect(json['con_dolor'], isTrue);
    final back = SleepEntry.fromJson(jsonDecode(jsonEncode(json)) as Map<String, dynamic>);
    expect(back.key, '2026-11-12');
    expect(back.quality, 2);
    expect(back.withPain, isTrue);
    expect(back.note, 'Me desperté tres veces');
    expect(back.updatedAt, isNotNull);
  });

  test('la calidad queda entre 1 y 5 y «con dolor» es opcional', () {
    expect(SleepEntry(date: DateTime(2026, 11, 1), quality: 9).quality, 5);
    expect(SleepEntry(date: DateTime(2026, 11, 1), quality: 0).quality, 1);
    final plain = SleepEntry(date: DateTime(2026, 11, 1), quality: 3);
    expect(plain.withPain, isNull);
    expect(plain.toJson().containsKey('con_dolor'), isFalse);
    expect(plain.copyWith(withPain: false).withPain, isFalse);
    expect(plain.copyWith(withPain: true).copyWith(clearPain: true).withPain, isNull);
  });

  test('una noche por día: guardar otra vez la actualiza', () async {
    final c = await sleepController();
    await c.saveSleep(SleepEntry(date: DateTime(2026, 11, 12), quality: 2));
    await c.saveSleep(SleepEntry(date: DateTime(2026, 11, 12, 9), quality: 4, note: '  bien  '));
    await c.saveSleep(SleepEntry(date: DateTime(2026, 11, 10), quality: 3));
    expect(c.sleepEntries.length, 2);
    expect(c.sleepFor(DateTime(2026, 11, 12))!.quality, 4);
    expect(c.sleepFor(DateTime(2026, 11, 12))!.note, 'bien');
    expect(c.sleepEntries.map((e) => e.key), ['2026-11-12', '2026-11-10']);
  });

  test('borrar una noche se puede deshacer', () async {
    final c = await sleepController();
    await c.saveSleep(SleepEntry(date: DateTime(2026, 11, 12), quality: 1, withPain: true));
    final removed = await c.deleteSleep(DateTime(2026, 11, 12));
    expect(c.sleepEntries, isEmpty);
    await c.restoreSleep(removed!);
    expect(c.sleepFor(DateTime(2026, 11, 12))!.withPain, isTrue);
  });

  test('se guarda en su propio archivo y un archivo dañado se aparta', () async {
    final dir = await Directory.systemTemp.createTemp('hope_sueno');
    addTearDown(() => dir.delete(recursive: true));
    final store = JsonFileSleepStore(dir);
    expect(await store.load(), isEmpty);
    await store.saveAll([SleepEntry(date: DateTime(2026, 11, 12), quality: 4, withPain: false)]);
    final back = await store.load();
    expect(back.single.quality, 4);
    expect(back.single.withPain, isFalse);
    expect(File('${dir.path}/hope_sueno.json').existsSync(), isTrue);

    store.file.writeAsStringSync('{ dañado');
    expect(await store.load(), isEmpty);
    expect(dir.listSync().any((f) => f.path.contains('.danado-')), isTrue);
  });

  test('la copia de seguridad incluye el sueño', () async {
    final c = await sleepController([SleepEntry(date: DateTime(2026, 11, 12), quality: 5)]);
    final text = encodeBackup(BackupData(
      records: c.records,
      treatments: c.treatments,
      medications: c.medicationEntries,
      settings: c.settings,
      sleep: c.sleepEntries,
    ));
    expect((jsonDecode(text) as Map<String, dynamic>)['version'], 4);
    final back = decodeBackup(text)!;
    expect(back.sleep!.single.quality, 5);

    final target = await sleepController();
    await target.replaceAll(
      records: back.records,
      treatments: back.treatments,
      medications: back.medications,
      sleep: back.sleep,
    );
    expect(target.sleepFor(DateTime(2026, 11, 12))!.quality, 5);
  });

  test('una copia anterior a la 0.4 conserva el sueño del dispositivo', () async {
    const oldBackup = '{"formato": "hope-copia", "version": 3, "registros": [], '
        '"medicamentos": [], "tratamientos": []}';
    final data = decodeBackup(oldBackup)!;
    expect(data.sleep, isNull);
    final c = await sleepController([SleepEntry(date: DateTime(2026, 11, 12), quality: 3)]);
    await c.replaceAll(
      records: data.records,
      treatments: data.treatments,
      medications: data.medications,
      sleep: data.sleep,
    );
    expect(c.sleepEntries.length, 1);
  });

  test('borrar todos los datos borra también el sueño', () async {
    final c = await sleepController([SleepEntry(date: DateTime(2026, 11, 12), quality: 3)]);
    await c.deleteAll();
    expect(c.sleepEntries, isEmpty);
  });
}
