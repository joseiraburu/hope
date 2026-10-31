import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope/app.dart';
import 'package:hope/animation/body_painter.dart';
import 'package:hope/models/app_settings.dart';

import 'helpers.dart';

Future<void> setScreen(WidgetTester tester, Size logical) async {
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = logical * 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  for (final size in const [Size(360, 740), Size(412, 915), Size(1280, 800)]) {
    testWidgets('la pantalla principal cabe sin desbordarse en ${size.width}×${size.height}',
        (tester) async {
      await setScreen(tester, size);
      final controller = await testController();
      await tester.pumpWidget(HopeApp(controller: controller));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('HOPE'), findsWidgets);
      expect(find.text('Registrar'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Registrar guarda un registro en el histórico', (tester) async {
    await setScreen(tester, const Size(412, 915));
    final controller = await testController();
    await tester.pumpWidget(HopeApp(controller: controller));
    await tester.pump(const Duration(milliseconds: 100));

    // Sube el dolor de fondo dos puntos con el botón +.
    await tester.tap(find.byTooltip('Subir · Dolor de fondo'));
    await tester.pump();
    await tester.tap(find.byTooltip('Subir · Dolor de fondo'));
    await tester.pump();

    await tester.tap(find.text('Registrar'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(controller.records.length, 1);
    expect(controller.records.first.painIntensity, 2);
    expect(find.text('Registrado'), findsOneWidget);
  });

  testWidgets('la bienvenida aparece la primera vez y guarda la silueta', (tester) async {
    await setScreen(tester, const Size(412, 915));
    final controller = await testController(
      settings: const AppSettings(firstRunDone: false, language: 'es'),
    );
    await tester.pumpWidget(HopeApp(controller: controller));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Te damos la bienvenida a HOPE'), findsOneWidget);
    await tester.tap(find.text('Hombre').last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(controller.settings.firstRunDone, isTrue);
    expect(controller.settings.sex, 'male');
  });

  testWidgets('el histórico muestra los registros', (tester) async {
    await setScreen(tester, const Size(412, 915));
    final controller = await testController();
    await tester.pumpWidget(HopeApp(controller: controller));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Registrar'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Histórico'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Dolor 0/10'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('las paletas clara y oscura son distintas', () {
    expect(BodyPalette.light.fill, isNot(BodyPalette.dark.fill));
  });
}
