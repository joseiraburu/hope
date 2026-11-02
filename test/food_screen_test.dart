// Pantallas de Alimentación: registrar, historial, detalle y relación con
// el dolor, en español y en inglés.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope/app.dart';
import 'package:hope/data/stores.dart';
import 'package:hope/models/app_settings.dart';
import 'package:hope/models/food.dart';
import 'package:hope/models/pain_record.dart';
import 'package:hope/screens/food_pain_screen.dart';
import 'package:hope/screens/food_screen.dart';
import 'package:hope/screens/foods_screen.dart';
import 'package:hope/screens/record_player_screen.dart';
import 'package:hope/state/app_controller.dart';

import 'helpers.dart';

Future<void> setScreen(WidgetTester tester, Size logical) async {
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = logical * 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<AppController> controllerWith({
  String language = 'es',
  List<PainRecord>? records,
  List<FoodDay> days = const [],
}) async {
  final c = AppController(
    config: loadConfig(),
    geometry: loadGeometry(),
    recordStore: MemoryRecordStore(records),
    settingsStore: MemorySettingsStore(AppSettings(firstRunDone: true, language: language)),
    treatmentStore: MemoryTreatmentStore(),
    foodStore: MemoryFoodStore(FoodData(days: days)),
  );
  await c.init();
  return c;
}

/// Muestra una pantalla suelta con el mismo entorno que la app.
Future<void> pumpScreen(WidgetTester tester, AppController c, Widget screen) async {
  await tester.pumpWidget(AppScope(
    controller: c,
    child: MaterialApp(
      locale: Locale(c.language),
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

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

PainRecord pain(DateTime at, int intensity, {String note = ''}) => PainRecord(
      id: newUuid(),
      dateTime: at,
      sex: 'female',
      painIntensity: intensity,
      zones: const ['pies_izq', 'pies_der'],
      zoneCount: 1,
      surfacePct: 7,
      eventIntensity: 3,
      eventTypes: const ['pinchazo'],
      eventFrequency: 60,
      seed: 7,
      note: note,
    );

/// Elige un alimento en la hoja abierta buscándolo por su nombre.
Future<void> pickFood(WidgetTester tester, String query, String name) async {
  await tester.enterText(find.byType(TextField).last, query);
  await tester.pump();
  await tester.tap(find.text(name).last);
  await tester.pump();
}

void main() {
  testWidgets('se abre desde el menú y registra la mañana y la tarde', (tester) async {
    await setScreen(tester, const Size(412, 915));
    final controller = await testController();
    await tester.pumpWidget(HopeApp(controller: controller));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Ajustes'));
    await settle(tester);
    await tester.tap(find.text('Alimentación'));
    await settle(tester);
    expect(find.byType(FoodScreen), findsOneWidget);
    expect(find.textContaining('Hoy ·'), findsOneWidget);

    // Mañana: pan, café y un alimento nuevo.
    await tester.tap(find.text('Mañana'));
    await settle(tester);
    await pickFood(tester, 'pan', 'Pan');
    await pickFood(tester, 'caf', 'Café');
    // Con la búsqueda, la opción «Añadir alimento…» queda a la vista.
    await tester.tap(find.text('Añadir alimento…'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Kéfir');
    await tester.tap(find.text('Aceptar'));
    await settle(tester);
    expect(find.textContaining('«Kéfir» se ha añadido'), findsOneWidget);

    // Un duplicado no se crea: se marca el que ya existe.
    final foodsBefore = controller.foods.length;
    await tester.enterText(find.byType(TextField).last, 'zzz');
    await tester.pump();
    await tester.tap(find.text('Añadir alimento…'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, ' PAN ');
    await tester.tap(find.text('Aceptar'));
    await settle(tester);
    expect(find.textContaining('ya existe'), findsOneWidget);
    expect(controller.foods.length, foodsBefore);

    await tester.tap(find.text('Listo'));
    await settle(tester);
    expect(find.text('Kéfir'), findsOneWidget);
    expect(find.text('3 alimentos'), findsOneWidget);

    // Tarde: pasta.
    await tester.tap(find.text('Tarde'));
    await settle(tester);
    await pickFood(tester, 'past', 'Pasta');
    await tester.tap(find.text('Listo'));
    await settle(tester);

    await tester.tap(find.text('Guardar'));
    await settle(tester);
    final saved = controller.foodDayFor(DateTime.now())!;
    final kefir = controller.findFoodByName('kefir')!.id;
    expect(saved.morning, ['bread', 'coffee', kefir]);
    expect(saved.afternoon, ['pasta']);
    expect(find.text('Guardado'), findsOneWidget);

    // Historial → detalle del día → relación con el dolor.
    await tester.tap(find.text('Historial'));
    await settle(tester);
    expect(find.text('Mañana: Pan, Café, Kéfir'), findsOneWidget);
    expect(find.text('Tarde: Pasta'), findsOneWidget);
    await tester.tap(find.text('Mañana: Pan, Café, Kéfir'));
    await settle(tester);
    await tester.tap(find.text('Ver relación con el dolor'));
    await settle(tester);
    expect(find.byType(FoodPainScreen), findsOneWidget);
    expect(find.text('Día 1'), findsOneWidget);
    expect(find.text('Día 4'), findsOneWidget);
    expect(find.text('Sin registro de dolor'), findsOneWidget);
    expect(find.text('Aún no disponible'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('al cambiar de día con cambios sin guardar se pide confirmación', (tester) async {
    await setScreen(tester, const Size(412, 915));
    final controller = await controllerWith();
    await pumpScreen(tester, controller, const FoodScreen());

    await tester.tap(find.text('Mañana'));
    await settle(tester);
    await pickFood(tester, 'arro', 'Arroz');
    await tester.tap(find.text('Listo'));
    await settle(tester);

    await tester.tap(find.byType(DropdownButton<String>));
    await settle(tester);
    await tester.tap(find.textContaining('Ayer ·').last);
    await settle(tester);
    expect(find.text('Tienes cambios sin guardar. ¿Descartarlos?'), findsOneWidget);
    await tester.tap(find.text('Descartar'));
    await settle(tester);
    expect(find.textContaining('Ayer ·'), findsOneWidget);
    expect(find.text('Arroz'), findsNothing);
    expect(controller.foodDays, isEmpty);
  });

  testWidgets('relaciona las comidas con el dolor de los días 1 a 4', (tester) async {
    // Pantalla alta para que las cuatro tarjetas estén construidas a la vez.
    await setScreen(tester, const Size(412, 1500));
    final now = DateTime.now();
    final d0 = DateTime(now.year, now.month, now.day - 10);
    DateTime at(int day, int hour) => DateTime(d0.year, d0.month, d0.day + day, hour);
    final controller = await controllerWith(
      records: [
        pain(at(0, 9), 4),
        pain(at(0, 21), 6, note: 'Después de cenar'),
        pain(at(2, 12), 8),
        pain(at(-3, 12), 3),
      ],
      days: [
        FoodDay(date: d0, morning: const ['bread'], afternoon: const ['red_meat']),
        FoodDay(date: at(2, 0), morning: const ['coffee']),
        FoodDay(date: at(-5, 0), afternoon: const ['fish']),
      ],
    );
    await pumpScreen(tester, controller, FoodPainScreen(date: d0));

    expect(find.text('Pan'), findsOneWidget);
    expect(find.text('Carne roja'), findsOneWidget);
    expect(find.text('Máx. 6 · media 5 · 2 registros'), findsOneWidget);
    expect(find.text('↑ +2 frente a tu media previa'), findsOneWidget);
    expect(find.text('Tu media de los 7 días previos: 3'), findsOneWidget);
    expect(find.text('Sin registro de dolor'), findsNWidgets(2));
    expect(find.text('Comidas de ese día (1 alimento)'), findsOneWidget);

    // Desde la tarjeta se abre el registro de dolor de ese día.
    await tester.ensureVisible(find.textContaining('Después de cenar'));
    await tester.pump();
    await tester.tap(find.textContaining('Después de cenar'));
    await settle(tester);
    expect(find.byType(RecordPlayerScreen), findsOneWidget);
    expect(find.text('Usar como punto de partida'), findsNothing);
    await tester.pageBack();
    await settle(tester);

    // Día anterior con comidas.
    await tester.tap(find.byTooltip('Día anterior con comidas'));
    await settle(tester);
    expect(find.text('Pescado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en inglés', (tester) async {
    await setScreen(tester, const Size(412, 915));
    final controller = await controllerWith(language: 'en');
    await pumpScreen(tester, controller, const FoodScreen());
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Log'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Morning'), findsOneWidget);
    expect(find.text('Afternoon'), findsOneWidget);
    expect(find.textContaining('Today ·'), findsOneWidget);
    await tester.tap(find.text('Morning'));
    await settle(tester);
    await pickFood(tester, 'brea', 'Bread');
    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(find.text('Bread'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(360, 740), Size(1280, 800)]) {
    testWidgets('las pantallas caben sin desbordarse en ${size.width}×${size.height}',
        (tester) async {
      await setScreen(tester, size);
      final now = DateTime.now();
      final d0 = DateTime(now.year, now.month, now.day - 1);
      final controller = await controllerWith(
        records: [pain(d0.add(const Duration(hours: 10)), 7), pain(now, 2)],
        days: [
          FoodDay(
            date: d0,
            morning: const ['bread', 'coffee', 'dairy', 'fruit'],
            afternoon: const ['vegetable_fat', 'animal_fat', 'ultra_processed'],
          ),
        ],
      );
      await pumpScreen(tester, controller, const FoodScreen());
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Historial'));
      await settle(tester);
      expect(tester.takeException(), isNull);
      await pumpScreen(tester, controller, FoodPainScreen(date: d0));
      expect(tester.takeException(), isNull);
      await pumpScreen(tester, controller, const FoodsScreen());
      expect(find.text('Alimentos básicos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
