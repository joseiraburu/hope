// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Vista de la silueta.
enum BodyView { front, back }

/// Convierte "#RRGGBB" o "#AARRGGBB" en un [Color].
Color parseHexColor(String hex) {
  var h = hex.replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  return Color(int.parse(h, radix: 16));
}

/// Una zona corporal configurable (nombre, % de superficie y vistas).
class ZoneDef {
  const ZoneDef({
    required this.id,
    required this.names,
    required this.pct,
    required this.views,
  });

  final String id;
  final Map<String, String> names;
  final double pct;
  final Set<BodyView> views;

  String name(String lang) => names[lang] ?? names['es'] ?? id;

  factory ZoneDef.fromJson(Map<String, dynamic> j) {
    final rawViews = j['views'] as List<dynamic>?;
    final views = rawViews == null
        ? {BodyView.front, BodyView.back}
        : rawViews
            .map((v) => v == 'back' ? BodyView.back : BodyView.front)
            .toSet();
    return ZoneDef(
      id: j['id'] as String,
      names: {'es': j['es'] as String, 'en': j['en'] as String},
      pct: (j['pct'] as num).toDouble(),
      views: views,
    );
  }
}

/// Un tipo de evento (pinchazo, quemazón...).
class EventTypeDef {
  const EventTypeDef({
    required this.id,
    required this.names,
    required this.color,
  });

  final String id;
  final Map<String, String> names;
  final Color color;

  String name(String lang) => names[lang] ?? names['es'] ?? id;

  factory EventTypeDef.fromJson(Map<String, dynamic> j) => EventTypeDef(
        id: j['id'] as String,
        names: {'es': j['es'] as String, 'en': j['en'] as String},
        color: parseHexColor(j['color'] as String),
      );
}

/// Configuración general de la app (assets/config/hope_config.json).
class AppConfig {
  AppConfig({
    required this.loopSeconds,
    required this.freqMin,
    required this.freqMax,
    required this.freqDefault,
    required this.zones,
    required this.eventTypes,
    required this.painLight,
    required this.painDeep,
    required this.accent,
    required this.backgroundLight,
    required this.backgroundDark,
  })  : zoneById = {for (final z in zones) z.id: z},
        eventTypeById = {for (final t in eventTypes) t.id: t};

  final double loopSeconds;
  final int freqMin;
  final int freqMax;
  final int freqDefault;
  final List<ZoneDef> zones;
  final List<EventTypeDef> eventTypes;
  final Map<String, ZoneDef> zoneById;
  final Map<String, EventTypeDef> eventTypeById;
  final Color painLight;
  final Color painDeep;
  final Color accent;
  final Color backgroundLight;
  final Color backgroundDark;

  factory AppConfig.fromJsonString(String source) {
    final j = jsonDecode(source) as Map<String, dynamic>;
    final freq = j['frequency'] as Map<String, dynamic>;
    final colors = j['colors'] as Map<String, dynamic>;
    return AppConfig(
      loopSeconds: (j['loopSeconds'] as num).toDouble(),
      freqMin: (freq['min'] as num).toInt(),
      freqMax: (freq['max'] as num).toInt(),
      freqDefault: (freq['default'] as num).toInt(),
      zones: (j['zones'] as List<dynamic>)
          .map((z) => ZoneDef.fromJson(z as Map<String, dynamic>))
          .toList(),
      eventTypes: (j['eventTypes'] as List<dynamic>)
          .map((t) => EventTypeDef.fromJson(t as Map<String, dynamic>))
          .toList(),
      painLight: parseHexColor(colors['painLight'] as String),
      painDeep: parseHexColor(colors['painDeep'] as String),
      accent: parseHexColor(colors['accent'] as String),
      backgroundLight: parseHexColor(colors['backgroundLight'] as String),
      backgroundDark: parseHexColor(colors['backgroundDark'] as String),
    );
  }

  /// Porcentaje de superficie corporal estimado para un conjunto de zonas.
  double surfacePct(Iterable<String> zoneIds) {
    var total = 0.0;
    for (final id in zoneIds.toSet()) {
      total += zoneById[id]?.pct ?? 0;
    }
    return (total * 10).round() / 10;
  }

  /// Devuelve las zonas en el orden de la configuración.
  List<String> orderedZones(Iterable<String> ids) {
    final set = ids.toSet();
    return [for (final z in zones) if (set.contains(z.id)) z.id];
  }

  /// Devuelve los tipos de evento en el orden de la configuración.
  List<String> orderedEventTypes(Iterable<String> ids) {
    final set = ids.toSet();
    return [for (final t in eventTypes) if (set.contains(t.id)) t.id];
  }

  int clampFrequency(int f) => math.max(freqMin, math.min(freqMax, f));
}
