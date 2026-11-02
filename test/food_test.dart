// Alimentación: modelo, catálogo, duplicados, guardado y relación con el dolor.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hope/charts/food_pain.dart';
import 'package:hope/data/backup.dart';
import 'package:hope/data/stores.dart';
import 'package:hope/models/app_settings.dart';
import 'package:hope/models/food.dart';
import 'package:hope/models/pain_record.dart';
import 'package:hope/state/app_controller.dart';

import 'helpers.dart';

PainRecord pain(DateTime at, int intensity, {String? id}) => PainRecord(
      id: id ?? newUuid(),
      dateTime: at,
      sex: 'female',
      painIntensity: intensity,
      zones: const ['pies_izq'],
      surfacePct: 3.5,
      eventIntensity: 0,
      eventTypes: const [],
      eventFrequency: 60,
      seed: 1,
    );

Future<AppController> foodController({
  List<PainRecord>? records,
  FoodData food = const FoodData(),
  String language = 'es',
}) async {
  final c = AppController(
    config: loadConfig(),
    geometry: loadGeometry(),
    recordStore: MemoryRecordStore(records),
    settingsStore: MemorySettingsStore(AppSettings(firstRunDone: true, language: language)),
    treatmentStore: MemoryTreatmentStore(),
    foodStore: MemoryFoodStore(food),
  );
  await c.init();
  return c;
}

void main() {
  group('catálogo', () {
    test('cada alimento básico tiene clave única y nombre en español e inglés', () {
      final config = loadConfig();
      expect(config.foods.length, greaterThanOrEqualTo(20));
      final ids = config.foods.map((f) => f.id).toSet();
      expect(ids.length, config.foods.length);
      for (final f in config.foods) {
        expect(f.names['es'], isNotEmpty, reason: f.id);
        expect(f.names['en'], isNotEmpty, reason: f.id);
        expect(RegExp(r'^[a-z_]+$').hasMatch(f.id), isTrue, reason: f.id);
      }
      for (final id in ['bread', 'pasta', 'red_meat', 'white_meat', 'fish', 'vegetable_fat', 'sugar']) {
        expect(ids, contains(id));
      }
    });

    test('los nombres de los alimentos básicos cambian con el idioma', () async {
      final es = await foodController();
      final en = await foodController(language: 'en');
      expect(es.foodName('red_meat'), 'Carne roja');
      expect(en.foodName('red_meat'), 'Red meat');
    });
  });

  group('modelo', () {
    test('un día de comidas se guarda y se recupera igual (JSON)', () {
      final day = FoodDay(
        date: DateTime(2026, 11, 2, 18, 30),
        morning: const ['bread', 'coffee'],
        afternoon: const ['pasta'],
        updatedAt: DateTime(2026, 11, 2, 19),
      );
      expect(day.date, DateTime(2026, 11, 2));
      expect(day.key, '2026-11-02');
      final json = day.toJson();
      expect(json['fecha'], '2026-11-02');
      final back = FoodDay.fromJson(jsonDecode(jsonEncode(json)) as Map<String, dynamic>);
      expect(back.date, DateTime(2026, 11, 2));
      expect(back.morning, ['bread', 'coffee']);
      expect(back.afternoon, ['pasta']);
      expect(back.foods, {'bread', 'coffee', 'pasta'});
      expect(back.updatedAt, isNotNull);
    });

    test('la clave del día es la fecha local de calendario', () {
      expect(dayKey(DateTime(2026, 1, 5, 23, 59)), '2026-01-05');
      expect(parseDayKey('2026-03-29'), DateTime(2026, 3, 29));
      expect(dayOf(DateTime(2026, 10, 25, 2, 30)), DateTime(2026, 10, 25));
    });

    test('los nombres se comparan sin mayúsculas, tildes ni espacios', () {
      expect(normalizeFoodName('  PAN '), 'pan');
      expect(normalizeFoodName('Café'), 'cafe');
      expect(normalizeFoodName('Café'), 'cafe');
      expect(normalizeFoodName('Frutos   secos'), 'frutos secos');
      expect(normalizeFoodName('Piñones'), 'pinones');
      expect(cleanFoodName('  pan   integral '), 'pan integral');
      expect(cleanFoodName('x' * 60).length, foodNameMaxLength);
    });
  });

  group('lista de alimentos', () {
    test('no se pueden crear duplicados, tampoco en otro idioma', () async {
      final c = await foodController();
      final before = c.foods.length;
      for (final name in ['pan', 'Pan', ' PAN ', 'Bread']) {
        final r = await c.addFood(name);
        expect(r.existed, isTrue, reason: name);
        expect(r.food.id, 'bread', reason: name);
      }
      final kefir = await c.addFood('Kéfir');
      expect(kefir.existed, isFalse);
      expect((await c.addFood('kefir')).food.id, kefir.food.id);
      expect(c.foods.length, before + 1);
    });

    test('un alimento añadido no se traduce y aparece en las listas', () async {
      final c = await foodController();
      final added = await c.addFood('Pan de espelta');
      expect(c.foodName(added.food.id), 'Pan de espelta');
      expect(c.pickableFoods().map((f) => f.id), contains(added.food.id));
      // Orden alfabético sin tener en cuenta las tildes.
      final names = c.pickableFoods().map((f) => normalizeFoodName(c.foodName(f.id))).toList();
      expect(names, [...names]..sort());

      await c.updateSettings(c.settings.copyWith(language: 'en'));
      expect(c.foodName(added.food.id), 'Pan de espelta');
      expect(c.foodName('bread'), 'Bread');
    });

    test('cambiar el nombre no permite duplicar otro alimento', () async {
      final c = await foodController();
      final a = await c.addFood('Avena');
      expect(await c.renameFood(a.food.id, 'Arroz'), isFalse);
      expect(await c.renameFood(a.food.id, 'Copos de avena'), isTrue);
      expect(c.foodName(a.food.id), 'Copos de avena');
      expect(await c.renameFood('bread', 'Pan blanco'), isFalse);
    });

    test('un alimento usado se oculta en lugar de borrarse', () async {
      final c = await foodController();
      final used = await c.addFood('Tofu');
      final unused = await c.addFood('Quinoa');
      await c.saveFoodDay(FoodDay(date: DateTime(2026, 11, 1), morning: [used.food.id]));

      expect(await c.deleteFood(unused.food.id), isTrue);
      expect(c.foodById(unused.food.id), isNull);

      expect(await c.deleteFood(used.food.id), isFalse);
      expect(c.foodById(used.food.id)!.hidden, isTrue);
      expect(c.pickableFoods().map((f) => f.id), isNot(contains(used.food.id)));
      // Sigue en el historial con su nombre.
      expect(c.foodName(used.food.id), 'Tofu');
      expect(c.pickableFoods([used.food.id]).map((f) => f.id), contains(used.food.id));

      // Añadirlo otra vez lo vuelve a mostrar en lugar de duplicarlo.
      final again = await c.addFood('tofu');
      expect(again.existed, isTrue);
      expect(c.foodById(used.food.id)!.hidden, isFalse);
    });
  });

  group('días de comidas', () {
    test('un registro por día: guardar otra vez lo actualiza', () async {
      final c = await foodController();
      final day = DateTime(2026, 11, 2);
      await c.saveFoodDay(FoodDay(date: day, morning: const ['bread']));
      await c.saveFoodDay(FoodDay(date: day.add(const Duration(hours: 20)), morning: const ['bread', 'coffee']));
      expect(c.foodDays.length, 1);
      expect(c.foodDayFor(day)!.morning, ['bread', 'coffee']);
    });

    test('el historial va del más reciente al más antiguo', () async {
      final c = await foodController();
      await c.saveFoodDay(FoodDay(date: DateTime(2026, 10, 30), afternoon: const ['fish']));
      await c.saveFoodDay(FoodDay(date: DateTime(2026, 11, 2), morning: const ['bread']));
      await c.saveFoodDay(FoodDay(date: DateTime(2026, 11, 1), morning: const ['eggs']));
      expect(c.foodDays.map((d) => d.key), ['2026-11-02', '2026-11-01', '2026-10-30']);
    });

    test('borrar un día se puede deshacer y un día vacío no se guarda', () async {
      final c = await foodController();
      final day = DateTime(2026, 11, 2);
      await c.saveFoodDay(FoodDay(date: day, morning: const ['bread'], afternoon: const ['pasta']));
      final removed = await c.deleteFoodDay(day);
      expect(c.foodDays, isEmpty);
      await c.restoreFoodDay(removed!);
      expect(c.foodDayFor(day)!.afternoon, ['pasta']);
      await c.saveFoodDay(FoodDay(date: day));
      expect(c.foodDayFor(day), isNull);
    });

    test('los alimentos repetidos o desconocidos no se guardan', () async {
      final c = await foodController();
      await c.saveFoodDay(FoodDay(
        date: DateTime(2026, 11, 2),
        morning: const ['bread', 'bread', 'no_existe'],
      ));
      expect(c.foodDayFor(DateTime(2026, 11, 2))!.morning, ['bread']);
    });

    test('se guarda en su propio archivo y se recupera', () async {
      final dir = await Directory.systemTemp.createTemp('hope_food');
      addTearDown(() => dir.delete(recursive: true));
      final store = JsonFileFoodStore(dir);
      expect((await store.load()).days, isEmpty);
      await store.save(FoodData(
        foods: const [FoodDef(id: 'ali_12345678', customName: 'Kéfir')],
        days: [FoodDay(date: DateTime(2026, 11, 2), morning: const ['ali_12345678', 'bread'])],
      ));
      final back = await store.load();
      expect(back.foods.single.customName, 'Kéfir');
      expect(back.days.single.morning, ['ali_12345678', 'bread']);
      expect(File('${dir.path}/hope_alimentacion.json').existsSync(), isTrue);
    });

    test('un archivo dañado se aparta y la app arranca sin alimentación', () async {
      final dir = await Directory.systemTemp.createTemp('hope_food');
      addTearDown(() => dir.delete(recursive: true));
      final store = JsonFileFoodStore(dir);
      store.file.writeAsStringSync('{ dañado');
      expect((await store.load()).days, isEmpty);
      expect(dir.listSync().any((f) => f.path.contains('.danado-')), isTrue);
    });
  });

  group('alimentación y dolor (días 1 a 4)', () {
    final records = [
      // Día 1 = 30 oct; los registros cerca de medianoche quedan en su día.
      pain(DateTime(2026, 10, 30, 8), 4),
      pain(DateTime(2026, 10, 30, 23, 50), 6),
      pain(DateTime(2026, 10, 31, 0, 10), 7),
      // Día 3 = 1 nov (cambio de mes). Día 2 y Día 4: sin registros.
      pain(DateTime(2026, 11, 1, 12), 3),
      // Fuera de la ventana.
      pain(DateTime(2026, 11, 3, 0, 5), 9),
      // 7 días anteriores: medias diarias 2 y 4 → referencia 3.
      pain(DateTime(2026, 10, 23, 9), 2),
      pain(DateTime(2026, 10, 29, 9), 3),
      pain(DateTime(2026, 10, 29, 21), 5),
      // Hace 8 días: no cuenta.
      pain(DateTime(2026, 10, 22, 9), 10),
    ];

    test('cada registro cae en su día local', () {
      final w = foodPainWindow(DateTime(2026, 10, 30, 15), records, now: DateTime(2026, 11, 10));
      expect(w.days.map((d) => dayKey(d.day)), ['2026-10-30', '2026-10-31', '2026-11-01', '2026-11-02']);
      expect(w.days.map((d) => d.count), [2, 1, 1, 0]);
      expect(w.days[0].max, 6);
      expect(w.days[0].min, 4);
      expect(w.days[0].mean, 5);
      expect(w.days[1].max, 7);
      expect(w.days[3].hasData, isFalse);
      expect(w.days[3].mean, isNull);
      expect(w.days.any((d) => d.isFuture), isFalse);
    });

    test('la media de referencia es la de los 7 días anteriores', () {
      final w = foodPainWindow(DateTime(2026, 10, 30), records, now: DateTime(2026, 11, 10));
      expect(w.baselineDaysWithData, 2);
      expect(w.baseline, 3);
      expect(w.deltaFor(w.days[0]), 2);
      expect(w.deltaFor(w.days[3]), isNull);
    });

    test('sin registros previos no hay media de referencia', () {
      final w = foodPainWindow(DateTime(2026, 1, 1), records, now: DateTime(2026, 11, 10));
      expect(w.baseline, isNull);
      expect(w.deltaFor(w.days[0]), isNull);
    });

    test('los días que aún no han llegado se marcan', () {
      final w = foodPainWindow(DateTime(2026, 11, 1), records, now: DateTime(2026, 11, 2, 10));
      expect(w.days.map((d) => d.isFuture), [false, false, true, true]);
    });

    test('cambio de año y cambio de horario', () {
      final w = foodPainWindow(DateTime(2026, 12, 30), const [], now: DateTime(2027, 2, 1));
      expect(w.days.map((d) => dayKey(d.day)), ['2026-12-30', '2026-12-31', '2027-01-01', '2027-01-02']);
      final spring = foodPainWindow(DateTime(2026, 3, 28), const [], now: DateTime(2027, 2, 1));
      expect(spring.days.map((d) => dayKey(d.day)), ['2026-03-28', '2026-03-29', '2026-03-30', '2026-03-31']);
      final autumn = foodPainWindow(DateTime(2026, 10, 24), const [], now: DateTime(2027, 2, 1));
      expect(autumn.days.map((d) => dayKey(d.day)), ['2026-10-24', '2026-10-25', '2026-10-26', '2026-10-27']);
      for (final d in [...spring.days, ...autumn.days]) {
        expect(d.day.hour, 0);
      }
    });
  });

  group('copia de seguridad', () {
    test('incluye la alimentación', () async {
      final c = await foodController();
      final kefir = await c.addFood('Kéfir');
      await c.saveFoodDay(FoodDay(date: DateTime(2026, 11, 2), morning: [kefir.food.id]));
      final text = encodeBackup(BackupData(
        records: c.records,
        treatments: c.treatments,
        medications: c.medicationEntries,
        settings: c.settings,
        foods: c.foodEntries,
        foodDays: c.foodDays,
      ));
      final back = decodeBackup(text)!;
      expect(back.foods!.single.customName, 'Kéfir');
      expect(back.foodDays!.single.morning, [kefir.food.id]);

      final target = await foodController();
      await target.replaceAll(
        records: back.records,
        treatments: back.treatments,
        medications: back.medications,
        foods: back.foods,
        foodDays: back.foodDays,
      );
      expect(target.foodName(kefir.food.id), 'Kéfir');
      expect(target.foodDays.length, 1);
    });

    test('una copia anterior a la 0.3 conserva la alimentación del dispositivo', () async {
      const oldBackup = '{"formato": "hope-copia", "version": 2, "registros": [], '
          '"medicamentos": [], "tratamientos": []}';
      final data = decodeBackup(oldBackup)!;
      expect(data.foods, isNull);
      expect(data.foodDays, isNull);

      final c = await foodController();
      await c.saveFoodDay(FoodDay(date: DateTime(2026, 11, 2), morning: const ['bread']));
      await c.replaceAll(
        records: data.records,
        treatments: data.treatments,
        medications: data.medications,
        foods: data.foods,
        foodDays: data.foodDays,
      );
      expect(c.foodDays.length, 1);
    });

    test('borrar todos los datos borra también la alimentación', () async {
      final c = await foodController();
      await c.addFood('Kéfir');
      await c.saveFoodDay(FoodDay(date: DateTime(2026, 11, 2), morning: const ['bread']));
      await c.deleteAll();
      expect(c.foodDays, isEmpty);
      expect(c.foodEntries, isEmpty);
    });
  });
}
