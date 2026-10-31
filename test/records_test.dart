import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hope/data/stores.dart';
import 'package:hope/models/app_settings.dart';
import 'package:hope/models/pain_record.dart';
import 'package:hope/state/pain_state.dart';
import 'package:hope/utils/format.dart';

import 'helpers.dart';

PainRecord sample({String? id, DateTime? at}) => PainRecord(
      id: id ?? newUuid(),
      dateTime: at ?? DateTime(2026, 10, 31, 14, 24),
      sex: 'female',
      painIntensity: 6,
      zones: const ['pies', 'manos'],
      surfacePct: 12,
      eventIntensity: 7,
      eventTypes: const ['pinchazo', 'quemazon'],
      eventFrequency: 120,
      seed: 12345,
      note: 'Dormí mal',
    );

void main() {
  test('un registro se guarda y se recupera igual (JSON)', () {
    final r = sample();
    final back = PainRecord.fromJson(r.toJson());
    expect(back.id, r.id);
    expect(back.dateTime, r.dateTime);
    expect(back.zones, r.zones);
    expect(back.zoneCount, 2);
    expect(back.surfacePct, 12);
    expect(back.eventTypes, r.eventTypes);
    expect(back.eventFrequency, 120);
    expect(back.seed, 12345);
    expect(back.note, 'Dormí mal');
  });

  test('la fecha se guarda en ISO 8601 con zona horaria', () {
    final iso = isoWithOffset(DateTime(2026, 10, 31, 14, 24, 5));
    expect(RegExp(r'^2026-10-31T14:24:05[+-]\d\d:\d\d$').hasMatch(iso), isTrue, reason: iso);
  });

  test('UUID v4 con formato correcto y sin repetirse', () {
    final ids = {for (var i = 0; i < 200; i++) newUuid()};
    expect(ids.length, 200);
    expect(
      RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')
          .hasMatch(ids.first),
      isTrue,
    );
  });

  test('el estado actual se convierte en un registro completo', () {
    final config = loadConfig();
    final state = PainState(config: config, seed: 9)
      ..intensity = 8
      ..eventIntensity = 4
      ..frequency = 999; // se ajusta al máximo
    state.setZones(['cabeza', 'pies']);
    state.setEventTypes(['golpe']);
    final r = state.toRecord(sex: 'male', dateTime: DateTime(2026, 1, 1));
    expect(r.zones, ['pies', 'cabeza']);
    expect(r.surfacePct, 10.5);
    expect(r.eventFrequency, 500);
    expect(r.seed, 9);
    expect(r.sex, 'male');
    state.dispose();
  });

  test('los valores fuera de 0–10 se ajustan', () {
    final state = PainState(config: loadConfig())..intensity = 15;
    expect(state.intensity, 10);
    state.intensity = -3;
    expect(state.intensity, 0);
    state.dispose();
  });

  test('el archivo de registros guarda y lee el histórico', () async {
    final dir = await Directory.systemTemp.createTemp('hope_test');
    try {
      final store = JsonFileRecordStore(dir);
      expect(await store.load(), isEmpty);
      await store.saveAll([sample(id: 'a'), sample(id: 'b')]);
      final loaded = await store.load();
      expect(loaded.map((r) => r.id), ['a', 'b']);

      final settings = JsonFileSettingsStore(dir);
      await settings.save(const AppSettings(sex: 'male', firstRunDone: true));
      final s = await settings.load();
      expect(s.sex, 'male');
      expect(s.firstRunDone, isTrue);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('un archivo dañado no se pierde: se aparta y se empieza de cero', () async {
    final dir = await Directory.systemTemp.createTemp('hope_test');
    try {
      final store = JsonFileRecordStore(dir);
      await store.file.writeAsString('{esto no es json');
      expect(await store.load(), isEmpty);
      final aside = dir.listSync().where((f) => f.path.contains('danado'));
      expect(aside, isNotEmpty);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('el histórico se ordena del más reciente al más antiguo', () async {
    final c = await testController(records: [
      sample(id: 'viejo', at: DateTime(2025, 1, 1)),
      sample(id: 'nuevo', at: DateTime(2026, 1, 1)),
    ]);
    expect(c.records.map((r) => r.id), ['nuevo', 'viejo']);
    final removed = await c.deleteRecord('nuevo');
    expect(removed?.id, 'nuevo');
    expect(c.records.map((r) => r.id), ['viejo']);
    await c.addRecord(removed!);
    expect(c.records.first.id, 'nuevo');
  });

  test('formato de porcentajes y fechas', () {
    expect(formatPct(32, 'es'), '32 %');
    expect(formatPct(32.5, 'es'), '32,5 %');
    expect(formatPct(32.5, 'en'), '32.5%');
    expect(formatDateTime(DateTime(2026, 10, 31, 14, 24), 'es'), 'sáb 31 oct 2026 · 14:24');
  });
}
