// Pantalla de inicio: los nueve cuadros, su orden, que ocupan toda la
// pantalla y que cada uno abre su sección.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope/app.dart';
import 'package:hope/screens/bowel_screen.dart';
import 'package:hope/screens/charts_screen.dart';
import 'package:hope/screens/data_screen.dart';
import 'package:hope/screens/food_screen.dart';
import 'package:hope/screens/history_screen.dart';
import 'package:hope/screens/home_screen.dart';
import 'package:hope/screens/report_screen.dart';
import 'package:hope/screens/sleep_screen.dart';
import 'package:hope/screens/start_screen.dart';
import 'package:hope/screens/treatments_screen.dart';

import 'helpers.dart';

Future<void> setScreen(WidgetTester tester, Size logical) async {
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = logical * 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

const tileKeys = [
  'tile-pain',
  'tile-food',
  'tile-sleep',
  'tile-bowel',
  'tile-medication',
  'tile-history',
  'tile-report',
  'tile-charts',
  'tile-data',
];

void main() {
  for (final size in const [Size(360, 740), Size(412, 915), Size(740, 360), Size(1280, 800)]) {
    testWidgets('los 9 cuadros llenan la pantalla en orden (${size.width}×${size.height})', (tester) async {
      await setScreen(tester, size);
      final c = await testController();
      await tester.pumpWidget(HopeApp(controller: c));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);

      final rects = [for (final k in tileKeys) tester.getRect(find.byKey(ValueKey(k)))];
      // 3 × 3: tres filas de tres, de izquierda a derecha y de arriba abajo.
      for (var row = 0; row < 3; row++) {
        for (var col = 0; col < 3; col++) {
          final r = rects[row * 3 + col];
          if (col > 0) {
            expect(r.left, greaterThan(rects[row * 3 + col - 1].right - 0.5));
            expect(r.top, closeTo(rects[row * 3].top, 0.5));
          }
          if (row > 0) expect(r.top, greaterThan(rects[(row - 1) * 3 + col].bottom - 0.5));
        }
      }
      // Todos del mismo tamaño (reparto proporcional).
      for (final r in rects) {
        expect(r.width, closeTo(rects.first.width, 0.5));
        expect(r.height, closeTo(rects.first.height, 0.5));
      }
      // Ocupan casi toda la pantalla: solo quedan la barra superior y los márgenes.
      final covered = rects.last.bottom - rects.first.top;
      expect(covered, greaterThan(size.height - 80));
      expect(rects[2].right - rects[0].left, greaterThan(size.width - 24));
    });
  }

  testWidgets('los nombres de los cuadros', (tester) async {
    await setScreen(tester, const Size(412, 915));
    final c = await testController();
    await tester.pumpWidget(HopeApp(controller: c));
    await tester.pump(const Duration(milliseconds: 300));
    for (final name in const [
      'Dolor',
      'Alimentación',
      'Sueño',
      'Deposiciones',
      'Medicación',
      'Historial',
      'Generar informe',
      'Gráficos',
      'Importar/Exportar',
    ]) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    expect(find.byTooltip('Ajustes'), findsOneWidget);
  });

  testWidgets('cada cuadro abre su sección y se vuelve al inicio', (tester) async {
    await setScreen(tester, const Size(412, 915));
    final c = await testController();
    await tester.pumpWidget(HopeApp(controller: c));
    await tester.pump(const Duration(milliseconds: 300));
    final screens = <String, Type>{
      'tile-pain': HomeScreen,
      'tile-food': FoodScreen,
      'tile-sleep': SleepScreen,
      'tile-bowel': BowelScreen,
      'tile-medication': TreatmentsScreen,
      'tile-history': HistoryScreen,
      'tile-report': ReportScreen,
      'tile-charts': ChartsScreen,
      'tile-data': DataScreen,
    };
    for (final e in screens.entries) {
      await tester.tap(find.byKey(ValueKey(e.key)));
      await settle(tester);
      expect(find.byType(e.value), findsOneWidget, reason: e.key);
      // Botón «Inicio» visible en todas las secciones.
      await tester.tap(find.byTooltip('Inicio'));
      await settle(tester);
      expect(find.byType(e.value), findsNothing, reason: e.key);
      expect(find.byType(StartScreen), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('el estado de cada cuadro refleja lo registrado hoy', (tester) async {
    await setScreen(tester, const Size(412, 915));
    final c = await testController();
    await tester.pumpWidget(HopeApp(controller: c));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Sin evaluar hoy'), findsOneWidget);
    expect(find.text('Hoy: ninguna'), findsOneWidget);
    expect(find.text('Anoche: sin registrar'), findsOneWidget);
  });
}
