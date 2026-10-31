import 'package:flutter_test/flutter_test.dart';
import 'package:hope/animation/pain_scene.dart';
import 'package:hope/core/body_geometry.dart';
import 'package:hope/core/config.dart';
import 'package:hope/core/frequency_scale.dart';
import 'package:hope/core/rng.dart';

import 'helpers.dart';

void main() {
  final config = loadConfig();
  final geometry = loadGeometry();

  List<Spark> gen({int seed = 42, int freq = 120, List<String>? types}) => generateSparks(
        config: config,
        seed: seed,
        zones: const ['pies', 'manos', 'muslos'],
        frequency: freq,
        eventIntensity: 7,
        eventTypes: types ?? const ['pinchazo', 'quemazon', 'golpe'],
      );

  test('el generador aleatorio es determinista', () {
    final a = Mulberry32(1234);
    final b = Mulberry32(1234);
    for (var i = 0; i < 1000; i++) {
      expect(a.nextUint32(), b.nextUint32());
    }
    final c = Mulberry32(99);
    for (var i = 0; i < 1000; i++) {
      final v = c.nextDouble();
      expect(v >= 0 && v < 1, isTrue);
    }
  });

  test('misma semilla → mismas chispas; otra semilla → otras chispas', () {
    final a = gen();
    final b = gen();
    expect(a.length, b.length);
    for (var i = 0; i < a.length; i++) {
      expect(a[i].start, b[i].start);
      expect(a[i].zone, b[i].zone);
      expect(a[i].type, b[i].type);
      expect(a[i].subSeed, b[i].subSeed);
    }
    final c = gen(seed: 43);
    expect(c.map((s) => s.start).toList(), isNot(a.map((s) => s.start).toList()));
  });

  test('número de chispas por bucle = frecuencia × 10 / 60', () {
    expect(gen(freq: 120).length, 20);
    expect(gen(freq: 500).length, 83);
    expect(gen(freq: 10).length, 2);
  });

  test('sin zonas, sin intensidad o sin tipos no hay chispas', () {
    expect(
        generateSparks(
            config: config,
            seed: 1,
            zones: const [],
            frequency: 100,
            eventIntensity: 5,
            eventTypes: const ['golpe']),
        isEmpty);
    expect(
        generateSparks(
            config: config,
            seed: 1,
            zones: const ['pies'],
            frequency: 100,
            eventIntensity: 0,
            eventTypes: const ['golpe']),
        isEmpty);
    expect(
        generateSparks(
            config: config,
            seed: 1,
            zones: const ['pies'],
            frequency: 100,
            eventIntensity: 5,
            eventTypes: const []),
        isEmpty);
  });

  test('los tipos de evento se reparten a partes iguales', () {
    final sparks = gen(freq: 360, types: const ['pinchazo', 'quemazon', 'golpe']);
    final counts = <String, int>{};
    for (final s in sparks) {
      counts[s.type] = (counts[s.type] ?? 0) + 1;
    }
    expect(counts.values.every((c) => c == 20), isTrue, reason: '$counts');
  });

  test('todas las chispas empiezan dentro del bucle', () {
    for (final s in gen(freq: 500)) {
      expect(s.start >= 0 && s.start < config.loopSeconds, isTrue);
    }
  });

  test('las posiciones caen dentro de su zona y se repiten', () {
    final scene = PainScene(
      config: config,
      painIntensity: 6,
      zones: const ['pies', 'pecho'],
      eventIntensity: 5,
      eventTypes: const ['pinchazo'],
      frequency: 300,
      seed: 7,
    );
    final front = geometry.view(Sex.female, BodyView.front);
    final pos = scene.positionsFor(front);
    for (var i = 0; i < scene.sparks.length; i++) {
      final p = pos[i];
      expect(p, isNotNull);
      expect(front.zones[scene.sparks[i].zone]!.contains(p!), isTrue);
    }
    final again = PainScene(
      config: config,
      painIntensity: 6,
      zones: const ['pecho', 'pies'],
      eventIntensity: 5,
      eventTypes: const ['pinchazo'],
      frequency: 300,
      seed: 7,
    ).positionsFor(front);
    expect(again, pos);
  });

  test('el pulso encaja un número entero de latidos en el bucle', () {
    for (var i = 1; i <= 10; i++) {
      final hz = pulseHz(i, false);
      expect(hz, inInclusiveRange(0.5, 1.5));
      final beats = hz * config.loopSeconds;
      expect((beats - beats.round()).abs() < 1e-9, isTrue, reason: 'intensidad $i');
      // Mismo valor al principio y al final del bucle: empalme sin saltos.
      expect(pulseAlpha(i, 0, false), closeTo(pulseAlpha(i, config.loopSeconds, false), 1e-9));
    }
    expect(pulseAlpha(0, 3, false), 0);
  });

  test('la chispa aparece, se mantiene y desaparece', () {
    expect(SparkTiming.alpha(0, 5, false), 0);
    expect(SparkTiming.alpha(0.2, 5, false), 1);
    expect(SparkTiming.alpha(SparkTiming.life(5, false) + 0.01, 5, false), 0);
  });

  group('escala de frecuencia', () {
    const scale = FrequencyScale(10, 500);
    test('extremos', () {
      expect(scale.fromPosition(0), 10);
      expect(scale.fromPosition(1), 500);
      expect(scale.toPosition(10), 0);
      expect(scale.toPosition(500), 1);
    });
    test('ida y vuelta', () {
      for (final f in [10, 25, 60, 120, 250, 500]) {
        expect((scale.fromPosition(scale.toPosition(f)) - f).abs() <= 1, isTrue);
      }
    });
    test('valores fuera de rango se ajustan', () {
      expect(scale.fromPosition(-1), 10);
      expect(scale.fromPosition(2), 500);
      expect(scale.toPosition(1000), 1);
    });
  });
}
