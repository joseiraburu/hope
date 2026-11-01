import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hope/core/body_geometry.dart';
import 'package:hope/core/config.dart';

import 'helpers.dart';

void main() {
  final config = loadConfig();
  final geometry = loadGeometry();

  test('hay 16 zonas (7 pares), 23 partes y 6 tipos de evento', () {
    expect(config.zones.length, 16);
    expect(config.zones.where((z) => z.paired).length, 7);
    expect(config.allParts.length, 23);
    expect(config.eventTypes.length, 6);
  });

  test('con el cuello, todas las partes suman el 100 %', () {
    expect(config.surfacePct(config.allParts), 100.0);
  });

  test('superficie por lado', () {
    expect(config.surfacePct(['pies_izq']), 3.5);
    expect(config.surfacePct(['pies_izq', 'pies_der']), 7.0);
    expect(config.surfacePct(['manos_der', 'pecho']), 9.0);
    expect(config.surfacePct(['cuello_delante', 'cuello_detras']), 2.0);
    expect(config.surfacePct([]), 0.0);
    // Las partes repetidas o desconocidas no suman.
    expect(config.surfacePct(['pies_izq', 'pies_izq', 'pies', 'desconocida']), 3.5);
  });

  test('las partes se ordenan como en la configuración', () {
    expect(config.orderedParts(['cabeza', 'pies_der', 'muslos_izq', 'pies_izq', 'otra']),
        ['pies_izq', 'pies_der', 'muslos_izq', 'cabeza']);
  });

  test('descripción de la selección con lateralidad', () {
    expect(config.describeParts(['manos_izq', 'pies_der', 'pies_izq', 'pecho'], 'es'),
        ['Pies (ambos)', 'Pecho', 'Mano izquierda']);
    expect(config.describeParts(['pantorrillas_der'], 'en'), ['Right calf']);
    expect(config.partName('gluteos_izq', 'es'), 'Glúteo izquierdo');
    expect(config.sideOfPart('pies_der'), Side.der);
    expect(config.sideOfPart('pecho'), isNull);
  });

  test('cada parte aparece dibujada en las vistas que declara, en ambas siluetas', () {
    for (final sex in Sex.values) {
      for (final zone in config.zones) {
        for (final part in zone.parts) {
          for (final view in BodyView.values) {
            final drawn = geometry.view(sex, view).zones.containsKey(part);
            expect(drawn, zone.views.contains(view),
                reason: '$part en ${sex.name}/${view.name}');
          }
        }
      }
    }
  });

  test('izquierda y derecha son las del paciente', () {
    for (final sex in Sex.values) {
      final front = geometry.view(sex, BodyView.front);
      final back = geometry.view(sex, BodyView.back);
      // Pie situado a la izquierda de la pantalla.
      expect(front.zoneAt(const Offset(77, 500)), 'pies_der', reason: sex.name);
      expect(back.zoneAt(const Offset(77, 500)), 'pies_izq', reason: sex.name);
      // Pie situado a la derecha de la pantalla.
      expect(front.zoneAt(const Offset(123, 500)), 'pies_izq', reason: sex.name);
      expect(back.zoneAt(const Offset(123, 500)), 'pies_der', reason: sex.name);
    }
  });

  test('el cuello se puede tocar por delante y por detrás', () {
    final front = geometry.view(Sex.female, BodyView.front);
    final back = geometry.view(Sex.male, BodyView.back);
    expect(front.zoneAt(const Offset(100, 74)), 'cuello_delante');
    expect(back.zoneAt(const Offset(100, 74)), 'cuello_detras');
    expect(front.zoneAt(const Offset(100, 50)), 'cara');
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
