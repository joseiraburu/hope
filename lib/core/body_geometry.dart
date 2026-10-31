// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:convert';
import 'dart:ui';

import 'config.dart';

/// Silueta elegida en el perfil.
enum Sex { female, male }

Sex sexFromString(String? value) => value == 'male' ? Sex.male : Sex.female;

String sexToString(Sex sex) => sex == Sex.male ? 'male' : 'female';

/// Geometría de una vista (frontal o posterior) de una silueta.
class ViewGeometry {
  ViewGeometry({
    required this.base,
    required this.zones,
    required this.decor,
  });

  /// Partes no seleccionables (cuello).
  final List<Path> base;

  /// Zonas seleccionables, por identificador.
  final Map<String, Path> zones;

  /// Líneas de detalle (pectorales, ingles, columna...).
  final List<List<Offset>> decor;

  late final List<Path> allShapes = [...base, ...zones.values];

  /// Zona que contiene el punto (en coordenadas de la silueta), si la hay.
  String? zoneAt(Offset point) {
    final entries = zones.entries.toList().reversed;
    for (final e in entries) {
      if (e.value.contains(point)) return e.key;
    }
    return null;
  }
}

/// Geometría de las siluetas (assets/config/body_geometry.json).
class BodyGeometry {
  BodyGeometry._(this.viewBox, this._views);

  final Size viewBox;
  final Map<Sex, Map<BodyView, ViewGeometry>> _views;

  ViewGeometry view(Sex sex, BodyView view) => _views[sex]![view]!;

  factory BodyGeometry.fromJsonString(String source) {
    final j = jsonDecode(source) as Map<String, dynamic>;
    final vb = j['viewBox'] as List<dynamic>;
    final views = <Sex, Map<BodyView, ViewGeometry>>{};
    for (final sex in Sex.values) {
      final sexJson = j[sexToString(sex)] as Map<String, dynamic>;
      views[sex] = {
        BodyView.front: _parseView(sexJson['front'] as Map<String, dynamic>),
        BodyView.back: _parseView(sexJson['back'] as Map<String, dynamic>),
      };
    }
    return BodyGeometry._(
      Size((vb[0] as num).toDouble(), (vb[1] as num).toDouble()),
      views,
    );
  }

  static ViewGeometry _parseView(Map<String, dynamic> j) {
    final zonesJson = j['zones'] as Map<String, dynamic>;
    return ViewGeometry(
      base: [
        for (final poly in j['base'] as List<dynamic>)
          _pathFromPolygons([poly]),
      ],
      zones: {
        for (final e in zonesJson.entries)
          e.key: _pathFromPolygons(e.value as List<dynamic>),
      },
      decor: [
        for (final line in j['decor'] as List<dynamic>)
          _points(line as List<dynamic>),
      ],
    );
  }

  static List<Offset> _points(List<dynamic> flat) {
    final pts = <Offset>[];
    for (var i = 0; i + 1 < flat.length; i += 2) {
      pts.add(Offset((flat[i] as num).toDouble(), (flat[i + 1] as num).toDouble()));
    }
    return pts;
  }

  static Path _pathFromPolygons(List<dynamic> polygons) {
    final path = Path();
    for (final poly in polygons) {
      path.addPolygon(_points(poly as List<dynamic>), true);
    }
    return path;
  }
}
