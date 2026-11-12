// Capturas de pantalla para revisar el diseño (se guardan en build/capturas).
//
// No comparan nada: solo generan imágenes con la tipografía real (Roboto y
// los iconos de Material del SDK de Flutter) para revisarlas a simple vista.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope/app.dart';
import 'package:hope/data/stores.dart';
import 'package:hope/models/app_settings.dart';
import 'package:hope/models/food.dart';
import 'package:hope/models/pain_record.dart';
import 'package:hope/models/reminder.dart';
import 'package:hope/models/sleep.dart';
import 'package:hope/models/treatment.dart';
import 'package:hope/export/record_share.dart';
import 'package:hope/screens/ai_settings_screen.dart';
import 'package:hope/screens/charts_screen.dart';
import 'package:hope/screens/food_pain_screen.dart';
import 'package:hope/screens/food_screen.dart';
import 'package:hope/screens/foods_screen.dart';
import 'package:hope/screens/home_screen.dart';
import 'package:hope/screens/reminders_screen.dart';
import 'package:hope/screens/report_screen.dart';
import 'package:hope/screens/settings_screen.dart';
import 'package:hope/screens/sleep_screen.dart';
import 'package:hope/screens/treatment_editor_screen.dart';
import 'package:hope/screens/treatments_screen.dart';
import 'package:hope/widgets/compare_sheet.dart';
import 'package:hope/state/app_controller.dart';

import 'helpers.dart';

final _shotKey = GlobalKey();

Future<void> setScreen(WidgetTester tester, Size logical, {double dpr = 2.0}) async {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = logical * dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> capture(WidgetTester tester, String name) async {
  final boundary = _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  });
  final file = File('build/capturas/$name.png');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!);
}

/// Avanza varios fotogramas para que terminen las transiciones.
Future<void> settle(WidgetTester tester, {int frames = 8}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget shot(AppController controller) =>
    RepaintBoundary(key: _shotKey, child: HopeApp(controller: controller));

PainRecord sampleRecord({
  required DateTime at,
  int pain = 6,
  List<String> zones = const ['pies_izq', 'pies_der', 'pantorrillas_izq', 'manos_der'],
  int events = 7,
  int freq = 120,
  List<String> types = const ['pinchazo', 'quemazon', 'punzada'],
  String sex = 'female',
}) {
  final config = loadConfig();
  return PainRecord(
    id: newUuid(),
    dateTime: at,
    sex: sex,
    painIntensity: pain,
    zones: zones,
    zoneCount: config.describeParts(zones, 'es').length,
    surfacePct: config.surfacePct(zones),
    eventIntensity: events,
    eventTypes: types,
    eventFrequency: freq,
    seed: 4242,
  );
}

void main() {
  setUpAll(loadRealFonts);

  testWidgets('captura: pantalla principal en móvil', (tester) async {
    await setScreen(tester, const Size(393, 852));
    final controller = await testController(records: [
      sampleRecord(at: DateTime(2026, 11, 1, 10)),
    ]);
    await tester.pumpWidget(shot(controller));
    await tester.pump(const Duration(milliseconds: 2300));
    await capture(tester, '01_principal_movil');

    await tester.tap(find.text('Detrás'));
    await tester.pump(const Duration(milliseconds: 1700));
    await capture(tester, '02_principal_movil_detras');
  });

  testWidgets('captura: hoja de zonas', (tester) async {
    await setScreen(tester, const Size(393, 852));
    final controller = await testController(records: [
      sampleRecord(at: DateTime(2026, 11, 1, 10)),
    ]);
    await tester.pumpWidget(shot(controller));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Zonas'));
    await settle(tester);
    await capture(tester, '03_hoja_zonas');
  });

  testWidgets('captura: móvil pequeño (360 px)', (tester) async {
    await setScreen(tester, const Size(360, 740));
    final controller = await testController(records: [
      sampleRecord(at: DateTime(2026, 11, 1, 10), sex: 'male'),
    ], settings: const AppSettings(firstRunDone: true, language: 'es', sex: 'male'));
    await tester.pumpWidget(shot(controller));
    await tester.pump(const Duration(milliseconds: 1300));
    await capture(tester, '04_principal_360');
  });

  testWidgets('captura: escritorio', (tester) async {
    await setScreen(tester, const Size(1280, 800), dpr: 1.0);
    final controller = await testController(records: [
      sampleRecord(at: DateTime(2026, 11, 1, 10)),
    ]);
    await tester.pumpWidget(shot(controller));
    await tester.pump(const Duration(milliseconds: 2600));
    await capture(tester, '05_principal_escritorio');
  });

  testWidgets('captura: compartir un registro y ajustes', (tester) async {
    await setScreen(tester, const Size(393, 852));
    final record = sampleRecord(at: DateTime(2026, 11, 1, 10));
    final controller = await testController(records: [record]);
    await tester.pumpWidget(shot(controller));
    await tester.pump(const Duration(milliseconds: 300));
    showRecordShareSheet(tester.element(find.byType(HomeScreen)), record);
    await settle(tester);
    await capture(tester, '06_compartir');
    expect(find.text('Vídeo MP4'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await settle(tester);

    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
    await settle(tester);
    await capture(tester, '07_ajustes');
    await tester.scrollUntilVisible(
      find.text('Exportar copia de seguridad'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await settle(tester);
    await capture(tester, '08_ajustes_datos');
    expect(find.text('Exportar copia de seguridad'), findsOneWidget);
  });

  testWidgets('captura: tratamientos', (tester) async {
    await setScreen(tester, const Size(393, 852));
    final records = [
      for (var d = 0; d < 40; d++)
        sampleRecord(
          at: DateTime(2026, 9, 25).add(Duration(days: d, hours: 9)),
          pain: d < 20 ? 7 - (d % 3) : 4 - (d % 2),
          freq: d < 20 ? 180 : 90,
        ),
    ];
    final treatments = [
      Treatment(
        id: 't1',
        medicationId: 'lidocaina',
        medicationName: 'Lidocaína',
        route: 'iv',
        dose: 300,
        unit: 'mg',
        start: DateTime(2026, 10, 15, 10),
        notes: 'Perfusión en la unidad del dolor',
        adverseEffects: const ['mareo'],
      ),
      Treatment(
        id: 't2',
        medicationId: 'fentanilo',
        medicationName: 'Fentanilo',
        route: 'transdermica',
        dose: 25,
        unit: 'ug_h',
        start: DateTime(2026, 9, 20, 9),
        end: DateTime(2026, 10, 30, 9),
        schedule: 'cada 72 h',
      ),
    ];
    final controller = await testController(records: records, treatments: treatments);
    await tester.pumpWidget(shot(controller));
    await tester.pump(const Duration(milliseconds: 300));
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute(builder: (_) => const TreatmentsScreen()));
    await settle(tester);
    await capture(tester, '10_tratamientos');

    showCompareSheet(tester.element(find.byType(TreatmentsScreen)), treatments.first);
    await settle(tester);
    await capture(tester, '11_antes_despues');
    nav.pop();
    await settle(tester);

    nav.push(MaterialPageRoute(builder: (_) => TreatmentEditorScreen(editing: treatments[1])));
    await settle(tester);
    await capture(tester, '12_editor_tratamiento');
  });

  List<PainRecord> recentRecords() {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day - 59, 9);
    return [
      for (var d = 0; d < 60; d++)
        if (d % 5 != 4)
          sampleRecord(
            at: start.add(Duration(days: d)),
            pain: d < 32 ? 7 - (d % 3) : 4 - (d % 2),
            freq: d < 32 ? 200 - (d % 4) * 10 : 90 + (d % 3) * 10,
            events: d < 32 ? 7 : 5,
            zones: d < 32
                ? const ['pies_izq', 'pies_der', 'pantorrillas_izq', 'pantorrillas_der', 'manos_der']
                : const ['pies_izq', 'pies_der'],
          ),
    ];
  }

  List<Treatment> recentTreatments() {
    final today = DateTime.now();
    return [
      Treatment(
        id: 'lido1',
        medicationId: 'lidocaina',
        medicationName: 'Lidocaína',
        route: 'iv',
        dose: 300,
        unit: 'mg',
        start: DateTime(today.year, today.month, today.day - 27, 10),
      ),
      Treatment(
        id: 'lido2',
        medicationId: 'lidocaina',
        medicationName: 'Lidocaína',
        route: 'iv',
        dose: 300,
        unit: 'mg',
        start: DateTime(today.year, today.month, today.day - 6, 10),
      ),
      Treatment(
        id: 'fent',
        medicationId: 'fentanilo',
        medicationName: 'Fentanilo',
        route: 'transdermica',
        dose: 12.5,
        unit: 'ug_h',
        start: DateTime(today.year, today.month, today.day - 50, 9),
        end: DateTime(today.year, today.month, today.day - 15, 9),
      ),
    ];
  }

  testWidgets('captura: gráficos en el móvil', (tester) async {
    await setScreen(tester, const Size(393, 852));
    final controller = await testController(records: recentRecords(), treatments: recentTreatments());
    await tester.pumpWidget(shot(controller));
    await tester.pump(const Duration(milliseconds: 300));
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute(builder: (_) => const ChartsScreen()));
    await settle(tester);
    await capture(tester, '20_graficos');

    // En el móvil los controles van en filas deslizables.
    await tester.ensureVisible(find.text('Por parámetro'));
    await settle(tester);
    await tester.tap(find.text('Por parámetro'));
    await settle(tester);
    await capture(tester, '21_graficos_por_parametro');

    await tester.ensureVisible(find.text('Tabla'));
    await settle(tester);
    await tester.tap(find.text('Tabla'));
    await settle(tester);
    await capture(tester, '22_graficos_tabla');
  });

  testWidgets('captura: gráficos en el escritorio', (tester) async {
    await setScreen(tester, const Size(1280, 800), dpr: 1.0);
    final controller = await testController(records: recentRecords(), treatments: recentTreatments());
    await tester.pumpWidget(shot(controller));
    await tester.pump(const Duration(milliseconds: 300));
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute(builder: (_) => const ChartsScreen()));
    await settle(tester);
    await tester.tap(find.text('Semana'));
    await settle(tester);
    await capture(tester, '23_graficos_escritorio');
  });

  Future<AppController> foodController(String language) async {
    final today = DateTime.now();
    DateTime day(int ago) => DateTime(today.year, today.month, today.day - ago);
    final c = AppController(
      config: loadConfig(),
      geometry: loadGeometry(),
      recordStore: MemoryRecordStore(recentRecords()),
      settingsStore: MemorySettingsStore(AppSettings(firstRunDone: true, language: language)),
      treatmentStore: MemoryTreatmentStore(),
      foodStore: MemoryFoodStore(FoodData(
        foods: const [FoodDef(id: 'ali_kefir001', customName: 'Kéfir')],
        days: [
          FoodDay.withFoods(day(1), {MealSlot.breakfast: const ['bread', 'coffee', 'ali_kefir001'], MealSlot.lunch: const ['pasta', 'red_meat', 'vegetable_fat']}),
          FoodDay.withFoods(day(3), {MealSlot.breakfast: const ['coffee', 'fruit'], MealSlot.lunch: const ['fish', 'vegetables']}),
          FoodDay.withFoods(day(6), {MealSlot.breakfast: const ['bread', 'dairy'], MealSlot.lunch: const ['fried_food', 'sugar', 'alcohol']}),
        ],
      )),
    );
    await c.init();
    return c;
  }

  testWidgets('captura: alimentación', (tester) async {
    await setScreen(tester, const Size(393, 852));
    final controller = await foodController('es');
    await tester.pumpWidget(shot(controller));
    await tester.pump(const Duration(milliseconds: 300));
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute(builder: (_) => const FoodScreen()));
    await settle(tester);
    await capture(tester, '30_alimentacion_registrar');

    await tester.ensureVisible(find.byKey(const ValueKey('food-slot-desayuno')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('food-slot-desayuno')));
    await settle(tester);
    await capture(tester, '31_alimentacion_hoja_manana');
    await tester.tap(find.text('Listo'));
    await settle(tester);

    await tester.tap(find.text('Historial'));
    await settle(tester);
    await capture(tester, '32_alimentacion_historial');

    final today = DateTime.now();
    nav.push(MaterialPageRoute(
      builder: (_) => FoodPainScreen(date: DateTime(today.year, today.month, today.day - 6)),
    ));
    await settle(tester);
    await capture(tester, '33_alimentacion_y_dolor');

    nav.push(MaterialPageRoute(builder: (_) => const FoodsScreen()));
    await settle(tester);
    await capture(tester, '34_mis_alimentos');
  });

  testWidgets('captura: alimentación y dolor en inglés', (tester) async {
    await setScreen(tester, const Size(393, 852));
    final controller = await foodController('en');
    await tester.pumpWidget(shot(controller));
    await tester.pump(const Duration(milliseconds: 300));
    final today = DateTime.now();
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute(
      builder: (_) => FoodPainScreen(date: DateTime(today.year, today.month, today.day - 3)),
    ));
    await settle(tester);
    await capture(tester, '35_food_pain_en');
  });

  /// 30 días con dolor, sueño y las cinco tomas. Los días con alcohol en la
  /// cena y las noches malas tienen más dolor; los últimos 10 días, algo menos.
  Future<AppController> dailyController(String language, {bool empty = false}) async {
    final today = DateTime.now();
    DateTime day(int ago, [int hour = 0]) => DateTime(today.year, today.month, today.day - ago, hour);
    final records = <PainRecord>[];
    final days = <FoodDay>[];
    final nights = <SleepEntry>[];
    for (var ago = 29; ago >= 1 && !empty; ago--) {
      final alcohol = ago % 4 == 1;
      final quality = ago % 5 == 0 ? 2 : (ago % 3 == 0 ? 3 : 4);
      final value = 4 + (alcohol ? 2 : 0) + (quality <= 2 ? 2 : 0) - (ago < 10 ? 1 : 0);
      records.add(sampleRecord(at: day(ago, 10), pain: value.clamp(0, 10).toInt()));
      nights.add(SleepEntry(date: day(ago), quality: quality, withPain: quality <= 2));
      days.add(FoodDay(date: day(ago), meals: {
        MealSlot.breakfast: const MealLog(foods: ['bread', 'coffee'], time: '08:10'),
        MealSlot.midMorning:
            ago % 3 == 0 ? const MealLog(skipped: true) : const MealLog(foods: ['fruit'], time: '11:15'),
        MealSlot.lunch: const MealLog(foods: ['pasta', 'vegetables'], time: '14:20'),
        MealSlot.snack: const MealLog(foods: ['dairy'], time: '17:40'),
        MealSlot.dinner: MealLog(foods: alcohol ? const ['fish', 'alcohol'] : const ['fish'], time: '21:15'),
      }));
    }
    if (!empty) {
      // Hoy: dolor registrado, sueño y desayuno; faltan el resto de tomas.
      records.add(sampleRecord(at: day(0, 9), pain: 4));
      nights.add(SleepEntry(date: day(0), quality: 4, withPain: false));
      days.add(FoodDay(date: day(0), meals: {
        MealSlot.breakfast: const MealLog(foods: ['bread', 'coffee'], time: '08:05'),
      }));
    }
    final reminders = [
      for (final r in defaultReminders) r.copyWith(enabled: r.slot != MealSlot.midMorning),
    ];
    final c = AppController(
      config: loadConfig(),
      geometry: loadGeometry(),
      recordStore: MemoryRecordStore(records),
      settingsStore: MemorySettingsStore(
        AppSettings(firstRunDone: true, language: language, reminders: reminders),
      ),
      treatmentStore: MemoryTreatmentStore(),
      foodStore: MemoryFoodStore(FoodData(days: days)),
      sleepStore: MemorySleepStore(nights),
    );
    await c.init();
    return c;
  }

  testWidgets('captura: completa HOPE, sueño y recordatorios', (tester) async {
    await setScreen(tester, const Size(393, 852));
    final controller = await dailyController('es');
    await tester.pumpWidget(shot(controller));
    await tester.pump(const Duration(milliseconds: 300));
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute(builder: (_) => const FoodScreen()));
    await settle(tester);
    await capture(tester, '36_completa_hope');
    nav.pop();
    await settle(tester);

    nav.push(MaterialPageRoute(builder: (_) => const FoodScreen(initialSlot: MealSlot.dinner)));
    await settle(tester);
    await capture(tester, '37_recordatorio_cena');
    nav.pop();
    await settle(tester);

    nav.push(MaterialPageRoute(builder: (_) => const SleepScreen()));
    await settle(tester);
    await capture(tester, '38_sueno');
    nav.pop();
    await settle(tester);

    nav.push(MaterialPageRoute(builder: (_) => const RemindersScreen()));
    await settle(tester);
    await capture(tester, '39_recordatorios');
  });

  testWidgets('captura: informe completo', (tester) async {
    await setScreen(tester, const Size(393, 852));
    final controller = await dailyController('es');
    await tester.pumpWidget(shot(controller));
    await tester.pump(const Duration(milliseconds: 300));
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute(builder: (_) => const ReportScreen(initialDays: 30)));
    await settle(tester);
    await capture(tester, '40_informe');
    await tester.scrollUntilVisible(
      find.text('Relación con el dolor'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -250));
    await settle(tester);
    await capture(tester, '41_informe_relaciones');
    await tester.scrollUntilVisible(
      find.text('Conclusiones'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await settle(tester);
    await capture(tester, '42_informe_conclusiones');
    nav.pop();
    await settle(tester);

    nav.push(MaterialPageRoute(builder: (_) => const AiSettingsScreen()));
    await settle(tester);
    await capture(tester, '43_ia');
  });

  testWidgets('captura: informe con datos insuficientes y en el escritorio', (tester) async {
    await setScreen(tester, const Size(393, 852));
    final empty = await dailyController('es', empty: true);
    await tester.pumpWidget(shot(empty));
    await tester.pump(const Duration(milliseconds: 300));
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute(builder: (_) => const ReportScreen(initialDays: 7)));
    await settle(tester);
    await capture(tester, '44_informe_insuficiente');
  });

  testWidgets('captura: informe en el escritorio (inglés)', (tester) async {
    await setScreen(tester, const Size(1280, 800), dpr: 1.0);
    final controller = await dailyController('en');
    await tester.pumpWidget(shot(controller));
    await tester.pump(const Duration(milliseconds: 300));
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute(builder: (_) => const ReportScreen(initialDays: 14)));
    await settle(tester);
    await capture(tester, '45_report_desktop_en');
  });
}
