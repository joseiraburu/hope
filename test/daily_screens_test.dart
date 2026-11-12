// Pantallas nuevas: sueño, tomas «No realizada», recordatorios, informe
// completo y análisis con IA, en español e inglés y en móvil y escritorio.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope/app.dart';
import 'package:hope/data/stores.dart';
import 'package:hope/models/app_settings.dart';
import 'package:hope/models/food.dart';
import 'package:hope/models/pain_record.dart';
import 'package:hope/models/sleep.dart';
import 'package:hope/screens/ai_settings_screen.dart';
import 'package:hope/screens/food_screen.dart';
import 'package:hope/screens/reminders_screen.dart';
import 'package:hope/screens/report_screen.dart';
import 'package:hope/screens/sleep_screen.dart';
import 'package:hope/state/app_controller.dart';

import 'helpers.dart';

Future<void> setScreen(WidgetTester tester, Size logical) async {
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = logical * 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

PainRecord pain(DateTime at, int intensity) => PainRecord(
      id: newUuid(),
      dateTime: at,
      sex: 'female',
      painIntensity: intensity,
      zones: const ['pies_izq', 'pies_der'],
      zoneCount: 1,
      surfacePct: 7,
      eventIntensity: 2,
      eventTypes: const ['quemazon'],
      eventFrequency: 60,
      seed: 3,
    );

/// Un controlador con [days] días de dolor, sueño y comidas hasta hoy.
Future<AppController> dailyController({int days = 0, String language = 'es'}) async {
  final today = DateTime.now();
  final records = <PainRecord>[];
  final foodDays = <FoodDay>[];
  final nights = <SleepEntry>[];
  for (var ago = days - 1; ago >= 0; ago--) {
    final day = DateTime(today.year, today.month, today.day - ago);
    final coffee = ago % 3 == 0;
    final quality = ago % 4 == 0 ? 2 : 4;
    records.add(pain(day.add(const Duration(hours: 9)), (coffee ? 6 : 3) + (quality == 2 ? 1 : 0)));
    nights.add(SleepEntry(date: day, quality: quality, withPain: quality == 2));
    foodDays.add(FoodDay(date: day, meals: {
      MealSlot.breakfast: MealLog(foods: coffee ? const ['bread', 'coffee'] : const ['bread'], time: '08:00'),
      MealSlot.midMorning: ago.isEven ? const MealLog(skipped: true) : const MealLog(foods: ['fruit']),
      MealSlot.lunch: const MealLog(foods: ['rice', 'vegetables']),
      MealSlot.dinner: const MealLog(foods: ['fish']),
    }));
  }
  final c = AppController(
    config: loadConfig(),
    geometry: loadGeometry(),
    recordStore: MemoryRecordStore(records),
    settingsStore: MemorySettingsStore(AppSettings(firstRunDone: true, language: language)),
    foodStore: MemoryFoodStore(FoodData(days: foodDays)),
    sleepStore: MemorySleepStore(nights),
  );
  await c.init();
  return c;
}

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

void main() {
  testWidgets('sueño: calidad 1 a 5, con dolor y guardar', (tester) async {
    await setScreen(tester, const Size(412, 915));
    final c = await dailyController();
    await pumpScreen(tester, c, const SleepScreen());
    expect(find.text('Elige la calidad del sueño (1 a 5)'), findsOneWidget);
    expect(find.textContaining('Hoy · Noche del'), findsOneWidget);

    await tester.tap(find.text('2'));
    await tester.pump();
    expect(find.text('2 · Malo'), findsOneWidget);
    await tester.tap(find.text('Con dolor'));
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await settle(tester);

    final saved = c.sleepFor(DateTime.now())!;
    expect(saved.quality, 2);
    expect(saved.withPain, isTrue);
    expect(find.text('Noche guardada'), findsOneWidget);
    expect(find.text('Malo · Con dolor'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('alimentación: marcar una toma como «No realizada»', (tester) async {
    await setScreen(tester, const Size(412, 915));
    final c = await dailyController();
    await pumpScreen(tester, c, const FoodScreen());
    final skip = find.byKey(const ValueKey('food-skip-almuerzo'));
    await tester.ensureVisible(skip);
    await tester.pump();
    await tester.tap(skip);
    await tester.pump();
    await tester.ensureVisible(find.text('Guardar'));
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await settle(tester);
    final day = c.foodDayFor(DateTime.now())!;
    expect(day.isSkipped(MealSlot.midMorning), isTrue);
    expect(day.eatenSlots, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un recordatorio abre la toma y la tarjeta «Completa HOPE»', (tester) async {
    await setScreen(tester, const Size(412, 915));
    final c = await dailyController();
    await pumpScreen(tester, c, const FoodScreen(initialSlot: MealSlot.dinner));
    await settle(tester);
    // La toma del recordatorio queda a la vista.
    expect(find.byKey(const ValueKey('food-slot-cena')), findsOneWidget);
    final list = find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.textContaining('Recordatorio: Cena'), -300, scrollable: list);
    expect(find.textContaining('Recordatorio: Cena'), findsOneWidget);
    expect(find.text('Evaluar el dolor'), findsOneWidget);
    expect(find.text('Registrar el sueño'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recordatorios: activar una alarma la guarda', (tester) async {
    await setScreen(tester, const Size(412, 915));
    final c = await dailyController();
    await pumpScreen(tester, c, const RemindersScreen());
    expect(find.text('Aviso 1 · 08:00'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reminder-switch-0')));
    await settle(tester);
    expect(c.settings.reminders[0].enabled, isTrue);
    expect(c.settings.anyReminderEnabled, isTrue);
    expect(find.text('Añadir al calendario (.ics)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('informe completo sin datos: «Datos insuficientes»', (tester) async {
    await setScreen(tester, const Size(412, 915));
    final c = await dailyController(days: 3);
    await pumpScreen(tester, c, const ReportScreen(initialDays: 7));
    expect(find.text('Datos insuficientes'), findsWidgets);
    expect(find.textContaining('Hacen falta al menos 7 días con registro de dolor'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Este informe no sustituye la valoración de un profesional sanitario.'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Todavía no hay datos suficientes para sacar conclusiones. Registra el dolor, el '
        'sueño y las comidas cada día.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('informe completo con 30 días de datos', (tester) async {
    await setScreen(tester, const Size(412, 915));
    final c = await dailyController(days: 30);
    await pumpScreen(tester, c, const ReportScreen(initialDays: 30));
    expect(find.text('Evolución del dolor'), findsOneWidget);
    expect(find.textContaining('Dolor de fondo: media'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Conclusiones'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('Los días con Café coincidieron con más dolor'), findsOneWidget);
    // Cambiar de periodo recalcula el informe.
    await tester.scrollUntilVisible(find.text('7 días'), -300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('7 días'));
    await settle(tester);
    expect(find.textContaining('Últimos 7 días'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('análisis con IA: pide consentimiento antes de activarse', (tester) async {
    await setScreen(tester, const Size(412, 915));
    final c = await dailyController();
    await pumpScreen(tester, c, const AiSettingsScreen());
    await tester.tap(find.byKey(const ValueKey('ai-switch')));
    await settle(tester);
    expect(find.text('¿Activar el análisis con IA?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await settle(tester);
    expect(c.settings.aiEnabled, isFalse);
    await tester.tap(find.byKey(const ValueKey('ai-switch')));
    await settle(tester);
    await tester.tap(find.text('Acepto y lo activo'));
    await settle(tester);
    expect(c.settings.aiEnabled, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el menú de la pantalla principal abre Sueño e Informe completo', (tester) async {
    await setScreen(tester, const Size(412, 915));
    final c = await dailyController(days: 2);
    await tester.pumpWidget(HopeApp(controller: c));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byTooltip('Ajustes'));
    await settle(tester);
    await tester.tap(find.text('Informe completo'));
    await settle(tester);
    expect(find.byType(ReportScreen), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    await tester.tap(find.byTooltip('Ajustes'));
    await settle(tester);
    await tester.tap(find.text('Sueño'));
    await settle(tester);
    expect(find.byType(SleepScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final language in const ['es', 'en']) {
    for (final size in const [Size(360, 740), Size(1280, 800)]) {
      testWidgets('caben sin desbordarse ($language, ${size.width}×${size.height})', (tester) async {
        await setScreen(tester, size);
        final c = await dailyController(days: 30, language: language);
        for (final screen in const [
          SleepScreen(),
          FoodScreen(initialSlot: MealSlot.snack),
          RemindersScreen(),
          ReportScreen(initialDays: 30),
          ReportScreen(initialDays: 7),
          AiSettingsScreen(),
        ]) {
          await pumpScreen(tester, c, screen);
          expect(tester.takeException(), isNull, reason: '${screen.runtimeType}');
        }
      });
    }
  }
}
