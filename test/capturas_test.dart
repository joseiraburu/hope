// Capturas de pantalla para revisar el diseño (se guardan en build/capturas).
//
// No comparan nada: solo generan imágenes con la tipografía real (Roboto y
// los iconos de Material del SDK de Flutter) para revisarlas a simple vista.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope/app.dart';
import 'package:hope/models/app_settings.dart';
import 'package:hope/models/pain_record.dart';
import 'package:hope/models/treatment.dart';
import 'package:hope/screens/treatment_editor_screen.dart';
import 'package:hope/screens/treatments_screen.dart';
import 'package:hope/widgets/compare_sheet.dart';
import 'package:hope/state/app_controller.dart';

import 'helpers.dart';

final _shotKey = GlobalKey();

Future<void> loadRealFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;
  Future<ByteData> read(File f) async => ByteData.view((await f.readAsBytes()).buffer);
  final roboto = FontLoader('Roboto');
  final icons = FontLoader('MaterialIcons');
  for (final f in dir.listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last;
    if (name.startsWith('Roboto-') && name.endsWith('.ttf')) roboto.addFont(read(f));
    if (name.startsWith('MaterialIcons-Regular')) icons.addFont(read(f));
  }
  await roboto.load();
  await icons.load();
}

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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await capture(tester, '10_tratamientos');

    showCompareSheet(tester.element(find.byType(TreatmentsScreen)), treatments.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await capture(tester, '11_antes_despues');
    nav.pop();
    await tester.pump(const Duration(milliseconds: 600));

    nav.push(MaterialPageRoute(builder: (_) => TreatmentEditorScreen(editing: treatments[1])));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await capture(tester, '12_editor_tratamiento');
  });
}
