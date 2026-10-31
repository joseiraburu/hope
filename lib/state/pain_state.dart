// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../animation/pain_scene.dart';
import '../core/config.dart';
import '../models/pain_record.dart';

/// Valores que el usuario está ajustando en la pantalla principal.
class PainState extends ChangeNotifier {
  PainState({
    required this.config,
    int intensity = 0,
    Set<String>? zones,
    int eventIntensity = 0,
    Set<String>? eventTypes,
    int? frequency,
    int? seed,
  })  : _intensity = intensity,
        _zones = {...?zones},
        _eventIntensity = eventIntensity,
        _eventTypes = eventTypes ?? {'pinchazo'},
        _frequency = config.clampFrequency(frequency ?? config.freqDefault),
        _seed = seed ?? newSeed();

  factory PainState.fromRecord(AppConfig config, PainRecord r) => PainState(
        config: config,
        intensity: r.painIntensity,
        zones: r.zones.toSet(),
        eventIntensity: r.eventIntensity,
        eventTypes: r.eventTypes.isEmpty ? {'pinchazo'} : r.eventTypes.toSet(),
        frequency: r.eventFrequency,
        seed: r.seed,
      );

  final AppConfig config;
  int _intensity;
  Set<String> _zones;
  int _eventIntensity;
  Set<String> _eventTypes;
  int _frequency;
  int _seed;

  int get intensity => _intensity;
  Set<String> get zones => Set.unmodifiable(_zones);
  int get eventIntensity => _eventIntensity;
  Set<String> get eventTypes => Set.unmodifiable(_eventTypes);
  int get frequency => _frequency;
  int get seed => _seed;

  double get surfacePct => config.surfacePct(_zones);

  static int _clamp10(int v) => math.max(0, math.min(10, v));

  set intensity(int v) {
    v = _clamp10(v);
    if (v == _intensity) return;
    _intensity = v;
    notifyListeners();
  }

  set eventIntensity(int v) {
    v = _clamp10(v);
    if (v == _eventIntensity) return;
    _eventIntensity = v;
    notifyListeners();
  }

  set frequency(int v) {
    v = config.clampFrequency(v);
    if (v == _frequency) return;
    _frequency = v;
    notifyListeners();
  }

  void toggleZone(String id) {
    if (!_zones.remove(id)) _zones.add(id);
    notifyListeners();
  }

  void setZones(Iterable<String> ids) {
    _zones = ids.toSet();
    notifyListeners();
  }

  void toggleEventType(String id) {
    if (!_eventTypes.remove(id)) _eventTypes.add(id);
    notifyListeners();
  }

  void setEventTypes(Iterable<String> ids) {
    _eventTypes = ids.toSet();
    notifyListeners();
  }

  /// Carga los valores de un registro (p. ej. «usar como punto de partida»).
  void loadFrom(PainRecord r) {
    _intensity = r.painIntensity;
    _zones = r.zones.toSet();
    _eventIntensity = r.eventIntensity;
    _eventTypes = r.eventTypes.isEmpty ? {'pinchazo'} : r.eventTypes.toSet();
    _frequency = config.clampFrequency(r.eventFrequency);
    _seed = r.seed;
    notifyListeners();
  }

  PainScene toScene() => PainScene(
        config: config,
        painIntensity: _intensity,
        zones: _zones.toList(),
        eventIntensity: _eventIntensity,
        eventTypes: _eventTypes.toList(),
        frequency: _frequency,
        seed: _seed,
      );

  /// Crea (o actualiza) un registro con los valores actuales.
  PainRecord toRecord({
    required String sex,
    required DateTime dateTime,
    PainRecord? existing,
  }) {
    final zones = config.orderedZones(_zones);
    final types = config.orderedEventTypes(_eventTypes);
    if (existing != null) {
      return existing.copyWith(
        dateTime: dateTime,
        sex: sex,
        painIntensity: _intensity,
        zones: zones,
        surfacePct: config.surfacePct(zones),
        eventIntensity: _eventIntensity,
        eventTypes: types,
        eventFrequency: _frequency,
        seed: _seed,
      );
    }
    return PainRecord(
      id: newUuid(),
      dateTime: dateTime,
      sex: sex,
      painIntensity: _intensity,
      zones: zones,
      surfacePct: config.surfacePct(zones),
      eventIntensity: _eventIntensity,
      eventTypes: types,
      eventFrequency: _frequency,
      seed: _seed,
    );
  }
}

/// Escena animada de un registro guardado.
PainScene sceneForRecord(AppConfig config, PainRecord r) => PainScene(
      config: config,
      painIntensity: r.painIntensity,
      zones: r.zones,
      eventIntensity: r.eventIntensity,
      eventTypes: r.eventTypes,
      frequency: r.eventFrequency,
      seed: r.seed,
    );
