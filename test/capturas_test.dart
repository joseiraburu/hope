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
import 'package:hope/models/treatment.dart';
import 'package:hope/export/record_share.dart';
import 'package:hope/screens/charts_screen.dart';
import 'package:hope/screens/food_pain_screen.dart';
import 'package:hope/screens/food_screen.dart';
import 'package:hope/screens/foods_screen.dart';
import 'package:hope/screens/home_screen.dart';
import 'package:hope/screens/settings_screen.dart';
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
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
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
          FoodDay(
            date: day(1),
            morning: const ['bread', 'coffee', 'ali_kefir001'],
            afternoon: const ['pasta', 'red_meat', 'vegetable_fat'],
          ),
          FoodDay(date: day(3), morning: const ['coffee', 'fruit'], afternoon: const ['fish', 'vegetables']),
          FoodDay(
            date: day(6),
            morning: const ['bread', 'dairy'],
            afternoon: const ['fried_food', 'sugar', 'alcohol'],
          ),
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

    await tester.tap(find.byKey(const ValueKey('food-slot-morning')));
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
}
