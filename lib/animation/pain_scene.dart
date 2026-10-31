// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:math' as math;
import 'dart:ui';

import '../core/body_geometry.dart';
import '../core/config.dart';
import '../core/rng.dart';

/// Una chispa (evento) dentro del bucle de animación.
class Spark {
  const Spark({
    required this.start,
    required this.zone,
    required this.type,
    required this.angle,
    required this.subSeed,
  });

  /// Segundo del bucle en el que aparece.
  final double start;
  final String zone;
  final String type;

  /// Orientación de la chispa (radianes).
  final double angle;

  /// Semilla propia para calcular su posición dentro de la zona.
  final int subSeed;
}

/// Tiempos de vida de una chispa.
class SparkTiming {
  static double fadeIn(bool reduced) => reduced ? 0.25 : 0.08;
  static double fadeOut(bool reduced) => reduced ? 0.30 : 0.15;
  static double hold(int eventIntensity) => 0.1 + 0.3 * eventIntensity / 10;
  static double life(int eventIntensity, bool reduced) =>
      fadeIn(reduced) + hold(eventIntensity) + fadeOut(reduced);

  /// Opacidad (0–1) de la chispa [tau] segundos después de aparecer.
  static double alpha(double tau, int eventIntensity, bool reduced) {
    final fi = fadeIn(reduced);
    final h = hold(eventIntensity);
    final fo = fadeOut(reduced);
    double a;
    if (tau < 0) {
      a = 0;
    } else if (tau < fi) {
      a = tau / fi;
    } else if (tau < fi + h) {
      a = 1;
    } else if (tau < fi + h + fo) {
      a = 1 - (tau - fi - h) / fo;
    } else {
      a = 0;
    }
    return reduced ? a * 0.75 : a;
  }
}

/// Genera la lista determinista de chispas de un bucle.
///
/// Misma semilla y mismos parámetros → exactamente las mismas chispas.
List<Spark> generateSparks({
  required AppConfig config,
  required int seed,
  required List<String> zones,
  required int frequency,
  required int eventIntensity,
  required List<String> eventTypes,
}) {
  if (zones.isEmpty || eventIntensity <= 0 || eventTypes.isEmpty) return const [];
  final loop = config.loopSeconds;
  final count = (frequency * loop / 60).round();
  if (count <= 0) return const [];

  final rng = Mulberry32(seed);
  final weights = [for (final z in zones) config.zoneById[z]?.pct ?? 1.0];
  final totalWeight = weights.fold<double>(0, (a, b) => a + b);

  // Reparto de tipos a partes iguales y en orden aleatorio.
  final types = List<String>.generate(count, (i) => eventTypes[i % eventTypes.length]);
  for (var i = types.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final tmp = types[i];
    types[i] = types[j];
    types[j] = tmp;
  }

  final sparks = <Spark>[];
  for (var i = 0; i < count; i++) {
    // Tiempos estratificados: repartidos por el bucle, sin amontonarse.
    final start = (i + rng.nextDouble()) * loop / count;
    var pick = rng.nextDouble() * totalWeight;
    var zone = zones.last;
    for (var k = 0; k < zones.length; k++) {
      pick -= weights[k];
      if (pick <= 0) {
        zone = zones[k];
        break;
      }
    }
    sparks.add(Spark(
      start: start,
      zone: zone,
      type: types[i],
      angle: rng.nextDouble() * 2 * math.pi,
      subSeed: rng.nextUint32(),
    ));
  }
  return sparks;
}

/// Punto aleatorio (determinista) dentro de una zona.
Offset? samplePointInPath(Path? path, int seed) {
  if (path == null) return null;
  final bounds = path.getBounds();
  if (bounds.isEmpty) return null;
  final rng = Mulberry32(seed ^ 0x5BD1E995);
  for (var i = 0; i < 80; i++) {
    final p = Offset(
      bounds.left + rng.nextDouble() * bounds.width,
      bounds.top + rng.nextDouble() * bounds.height,
    );
    if (path.contains(p)) return p;
  }
  return bounds.center;
}

/// Hz del pulso del dolor de fondo. Siempre un múltiplo de 0,1 Hz, para que
/// quepa un número entero de latidos en el bucle de 10 s y el empalme no se
/// note.
double pulseHz(int intensity, bool reduced) {
  if (reduced || intensity <= 1) return 0.5;
  final steps = ((intensity - 1) * 10 / 9).round();
  return (5 + steps) / 10;
}

/// Opacidad del color del dolor de fondo en el instante [t] del bucle.
double pulseAlpha(int intensity, double t, bool reduced) {
  if (intensity <= 0) return 0;
  final base = 0.18 + 0.72 * intensity / 10;
  final amp = reduced ? 0.12 : 0.15 + 0.35 * intensity / 10;
  final phase = 0.5 - 0.5 * math.cos(2 * math.pi * pulseHz(intensity, reduced) * t);
  return base * (1 - amp * phase);
}

/// Color del dolor de fondo según la intensidad (0–10).
Color painColor(AppConfig config, int intensity) =>
    Color.lerp(config.painLight, config.painDeep, intensity / 10)!;

/// Todo lo necesario para dibujar un estado de dolor animado.
class PainScene {
  PainScene({
    required this.config,
    required this.painIntensity,
    required List<String> zones,
    required this.eventIntensity,
    required List<String> eventTypes,
    required this.frequency,
    required this.seed,
  })  : zones = config.orderedZones(zones),
        eventTypes = config.orderedEventTypes(eventTypes) {
    sparks = generateSparks(
      config: config,
      seed: seed,
      zones: this.zones,
      frequency: frequency,
      eventIntensity: eventIntensity,
      eventTypes: this.eventTypes,
    );
  }

  final AppConfig config;
  final int painIntensity;
  final List<String> zones;
  final int eventIntensity;
  final List<String> eventTypes;
  final int frequency;
  final int seed;
  late final List<Spark> sparks;

  final Map<ViewGeometry, List<Offset?>> _positions = Map.identity();

  double get loopSeconds => config.loopSeconds;

  double get surfacePct => config.surfacePct(zones);

  /// Posición de cada chispa en una vista concreta (null si la zona no se ve).
  List<Offset?> positionsFor(ViewGeometry geometry) {
    return _positions.putIfAbsent(geometry, () {
      return [
        for (final s in sparks) samplePointInPath(geometry.zones[s.zone], s.subSeed)
      ];
    });
  }
}
