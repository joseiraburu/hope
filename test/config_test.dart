import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hope/core/body_geometry.dart';
import 'package:hope/core/config.dart';

import 'helpers.dart';

void main() {
  final config = loadConfig();
  final geometry = loadGeometry();

  test('hay 14 zonas y 6 tipos de evento', () {
    expect(config.zones.length, 14);
    expect(config.eventTypes.length, 6);
  });

  test('la superficie de todas las zonas suma 98 % (sin el cuello)', () {
    expect(config.surfacePct(config.zones.map((z) => z.id)), 98.0);
  });

  test('superficie de combinaciones concretas', () {
    expect(config.surfacePct(['pies', 'manos']), 12.0);
    expect(config.surfacePct(['pecho', 'abdomen', 'cara']), 16.5);
    expect(config.surfacePct([]), 0.0);
    // Las zonas repetidas o desconocidas no suman dos veces.
    expect(config.surfacePct(['pies', 'pies', 'desconocida']), 7.0);
  });

  test('las zonas se ordenan como en la configuración', () {
    expect(config.orderedZones(['cabeza', 'pies', 'muslos']), ['pies', 'muslos', 'cabeza']);
  });

  test('cada zona aparece dibujada en las vistas que declara, en ambas siluetas', () {
    for (final sex in Sex.values) {
      for (final zone in config.zones) {
        for (final view in BodyView.values) {
          final drawn = geometry.view(sex, view).zones.containsKey(zone.id);
          expect(drawn, zone.views.contains(view),
              reason: '${zone.id} en ${sex.name}/${view.name}');
        }
      }
    }
  });

  test('tocar el centro del pecho selecciona «pecho» en la vista frontal', () {
    final front = geometry.view(Sex.male, BodyView.front);
    expect(front.zoneAt(const Offset(100, 130)), 'pecho');
    expect(front.zoneAt(const Offset(100, 230)), 'abdomen');
    final back = geometry.view(Sex.female, BodyView.back);
    expect(back.zoneAt(const Offset(100, 130)), 'espalda');
    expect(back.zoneAt(const Offset(100, 240)), 'lumbar');
    expect(front.zoneAt(const Offset(2, 2)), isNull);
  });
}
