// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Vista de la silueta.
enum BodyView { front, back }

/// Lado del cuerpo (siempre el del paciente).
enum Side { izq, der }

/// Convierte "#RRGGBB" o "#AARRGGBB" en un [Color].
Color parseHexColor(String hex) {
  var h = hex.replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  return Color(int.parse(h, radix: 16));
}

Map<String, String> _names(Map<String, dynamic> j) => {
      'es': j['es'] as String,
      'en': (j['en'] as String?) ?? (j['es'] as String),
    };

/// Elemento de una lista configurable con nombre en varios idiomas.
class Labeled {
  const Labeled({required this.id, required this.names});

  final String id;
  final Map<String, String> names;

  String name(String lang) => names[lang] ?? names['es'] ?? id;

  factory Labeled.fromJson(Map<String, dynamic> j) =>
      Labeled(id: j['id'] as String, names: _names(j));
}

/// Una zona corporal configurable (nombre, % de superficie y vistas).
///
/// Las zonas pares (pies, manos...) tienen [sides]: cada lado se marca por
/// separado y suma la mitad de la superficie de la zona.
class ZoneDef {
  const ZoneDef({
    required this.id,
    required this.names,
    required this.pct,
    required this.views,
    this.sides,
  });

  final String id;
  final Map<String, String> names;
  final double pct;
  final Set<BodyView> views;

  /// Nombres de cada lado («Pie izquierdo»...), solo en zonas pares.
  final Map<Side, Map<String, String>>? sides;

  bool get paired => sides != null;

  String name(String lang) => names[lang] ?? names['es'] ?? id;

  String sideName(Side side, String lang) {
    final n = sides?[side];
    if (n == null) return name(lang);
    return n[lang] ?? n['es'] ?? name(lang);
  }

  /// Identificadores de las partes seleccionables de esta zona.
  List<String> get parts => paired ? [partId(id, Side.izq), partId(id, Side.der)] : [id];

  factory ZoneDef.fromJson(Map<String, dynamic> j) {
    final rawViews = j['views'] as List<dynamic>?;
    final views = rawViews == null
        ? {BodyView.front, BodyView.back}
        : rawViews.map((v) => v == 'back' ? BodyView.back : BodyView.front).toSet();
    final rawSides = j['sides'] as Map<String, dynamic>?;
    return ZoneDef(
      id: j['id'] as String,
      names: _names(j),
      pct: (j['pct'] as num).toDouble(),
      views: views,
      sides: rawSides == null
          ? null
          : {
              Side.izq: _names(rawSides['izq'] as Map<String, dynamic>),
              Side.der: _names(rawSides['der'] as Map<String, dynamic>),
            },
    );
  }
}

/// Identificador de una parte: «pies_izq», «pies_der» o el de la zona.
String partId(String zoneId, Side side) => '${zoneId}_${side.name}';

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
        names: _names(j),
        color: parseHexColor(j['color'] as String),
      );
}

/// Presentación habitual de un medicamento (vía y unidad por defecto).
class Presentation {
  const Presentation({required this.medication, required this.route, required this.unit});

  final String medication;
  final String route;
  final String unit;

  factory Presentation.fromJson(Map<String, dynamic> j) => Presentation(
        medication: j['medication'] as String,
        route: j['route'] as String,
        unit: j['unit'] as String,
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
    this.medications = const [],
    this.presentations = const [],
    this.routes = const [],
    this.units = const [],
    this.adverseEffects = const [],
  })  : zoneById = {for (final z in zones) z.id: z},
        eventTypeById = {for (final t in eventTypes) t.id: t} {
    for (final z in zones) {
      for (final p in z.parts) {
        _partZone[p] = z;
        _partOrder[p] = _partOrder.length;
      }
    }
  }

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
  final List<Labeled> medications;
  final List<Presentation> presentations;
  final List<Labeled> routes;
  final List<Labeled> units;
  final List<Labeled> adverseEffects;

  final Map<String, ZoneDef> _partZone = {};
  final Map<String, int> _partOrder = {};

  factory AppConfig.fromJsonString(String source) {
    final j = jsonDecode(source) as Map<String, dynamic>;
    final freq = j['frequency'] as Map<String, dynamic>;
    final colors = j['colors'] as Map<String, dynamic>;
    List<Labeled> labeled(String key) => [
          for (final e in (j[key] as List<dynamic>? ?? const []))
            Labeled.fromJson(e as Map<String, dynamic>)
        ];
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
      medications: labeled('medications'),
      presentations: [
        for (final p in (j['presentations'] as List<dynamic>? ?? const []))
          Presentation.fromJson(p as Map<String, dynamic>)
      ],
      routes: labeled('routes'),
      units: labeled('units'),
      adverseEffects: labeled('adverseEffects'),
    );
  }

  // ---------------------------------------------------------------- partes
  /// Todas las partes seleccionables, en el orden de la configuración.
  List<String> get allParts => [for (final z in zones) ...z.parts];

  /// Zona a la que pertenece una parte (null si no existe).
  ZoneDef? zoneOfPart(String part) => _partZone[part];

  bool isPart(String part) => _partZone.containsKey(part);

  /// Lado de una parte (null si es una zona central).
  Side? sideOfPart(String part) {
    final z = _partZone[part];
    if (z == null || !z.paired) return null;
    return part.endsWith('_izq') ? Side.izq : Side.der;
  }

  /// Superficie corporal (%) de una parte.
  double partPct(String part) {
    final z = _partZone[part];
    if (z == null) return 0;
    return z.paired ? z.pct / 2 : z.pct;
  }

  /// Porcentaje de superficie corporal estimado para un conjunto de partes.
  double surfacePct(Iterable<String> parts) {
    var total = 0.0;
    for (final p in parts.toSet()) {
      total += partPct(p);
    }
    return (total * 10).round() / 10;
  }

  /// Devuelve las partes válidas en el orden de la configuración.
  List<String> orderedParts(Iterable<String> ids) {
    final list = [for (final p in ids.toSet()) if (_partZone.containsKey(p)) p];
    list.sort((a, b) => _partOrder[a]!.compareTo(_partOrder[b]!));
    return list;
  }

  /// Nombre de una parte: «Pie izquierdo», «Pecho»...
  String partName(String part, String lang) {
    final z = _partZone[part];
    if (z == null) return part;
    final side = sideOfPart(part);
    return side == null ? z.name(lang) : z.sideName(side, lang);
  }

  /// Describe una selección agrupando los dos lados: «Pies (ambos)»,
  /// «Mano izquierda», «Pecho»...
  List<String> describeParts(Iterable<String> parts, String lang) {
    final set = parts.toSet();
    final both = lang == 'en' ? 'both' : 'ambos';
    final out = <String>[];
    for (final z in zones) {
      if (z.paired) {
        final l = set.contains(partId(z.id, Side.izq));
        final r = set.contains(partId(z.id, Side.der));
        if (l && r) {
          out.add('${z.name(lang)} ($both)');
        } else if (l) {
          out.add(z.sideName(Side.izq, lang));
        } else if (r) {
          out.add(z.sideName(Side.der, lang));
        }
      } else if (set.contains(z.id)) {
        out.add(z.name(lang));
      }
    }
    return out;
  }

  /// ¿Se ve esta parte en la vista indicada?
  bool partVisibleIn(String part, BodyView view) =>
      _partZone[part]?.views.contains(view) ?? false;

  /// Devuelve los tipos de evento en el orden de la configuración.
  List<String> orderedEventTypes(Iterable<String> ids) {
    final set = ids.toSet();
    return [for (final t in eventTypes) if (set.contains(t.id)) t.id];
  }

  int clampFrequency(int f) => math.max(freqMin, math.min(freqMax, f));

  // ------------------------------------------------------- tratamientos
  Labeled? routeById(String id) => _find(routes, id);
  Labeled? unitById(String id) => _find(units, id);
  Labeled? adverseEffectById(String id) => _find(adverseEffects, id);

  String routeName(String id, String lang) => routeById(id)?.name(lang) ?? id;
  String unitName(String id, String lang) => unitById(id)?.name(lang) ?? id;
  String adverseEffectName(String id, String lang) =>
      adverseEffectById(id)?.name(lang) ?? id;

  List<Presentation> presentationsFor(String medicationId) =>
      [for (final p in presentations) if (p.medication == medicationId) p];

  static Labeled? _find(List<Labeled> list, String id) {
    for (final e in list) {
      if (e.id == id) return e;
    }
    return null;
  }
}
