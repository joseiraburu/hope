// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/foundation.dart';

import '../models/food.dart';

/// Comidas de un día mientras se editan en la pantalla Alimentación, antes
/// de guardarlas: los alimentos de cada toma, las tomas «No realizada» y su
/// hora.
class FoodDraft extends ChangeNotifier {
  FoodDraft(DateTime day, {DateTime Function()? clock})
      : _day = dayOf(day),
        _clock = clock ?? DateTime.now;

  DateTime _day;
  final DateTime Function() _clock;
  final Map<MealSlot, List<String>> _foods = {for (final s in MealSlot.values) s: <String>[]};
  final Set<MealSlot> _skipped = {};
  final Map<MealSlot, String> _times = {};
  bool _dirty = false;

  /// Día que se está editando (medianoche local).
  DateTime get day => _day;

  /// Hay cambios sin guardar.
  bool get dirty => _dirty;

  /// Ninguna toma tiene alimentos ni está marcada como «No realizada».
  bool get isEmpty =>
      MealSlot.values.every((s) => _foods[s]!.isEmpty && !_skipped.contains(s));

  /// ¿El día que se edita es hoy?
  bool get isToday => dayKey(_day) == dayKey(_clock());

  List<String> slot(MealSlot s) => List.unmodifiable(_foods[s]!);

  bool isSkipped(MealSlot s) => _skipped.contains(s);

  /// Hora de la toma («HH:mm») o null si no tiene.
  String? time(MealSlot s) => _times[s];

  /// Carga un día con lo que ya tenga guardado (o vacío).
  void load(DateTime day, FoodDay? saved) {
    _day = dayOf(day);
    _skipped.clear();
    _times.clear();
    for (final s in MealSlot.values) {
      final meal = saved?.meal(s) ?? const MealLog();
      _foods[s] = [...meal.foods];
      if (meal.skipped) _skipped.add(s);
      final t = meal.time;
      if (t != null) _times[s] = t;
    }
    _dirty = false;
    notifyListeners();
  }

  bool contains(MealSlot s, String id) => _foods[s]!.contains(id);

  /// Al elegir alimentos, la toma deja de estar «No realizada» y, si no tenía
  /// hora, toma la actual (hoy) o la habitual de la toma (otros días).
  void _changed(MealSlot s) {
    if (_foods[s]!.isNotEmpty) {
      _skipped.remove(s);
      _times.putIfAbsent(s, () => isToday ? timeOfDayText(_clock()) : s.defaultTime);
    }
    _dirty = true;
    notifyListeners();
  }

  void toggle(MealSlot s, String id) {
    final list = _foods[s]!;
    if (!list.remove(id)) list.add(id);
    _changed(s);
  }

  void add(MealSlot s, String id) {
    final list = _foods[s]!;
    if (list.contains(id)) return;
    list.add(id);
    _changed(s);
  }

  void remove(MealSlot s, String id) {
    if (!_foods[s]!.remove(id)) return;
    _changed(s);
  }

  void clear(MealSlot s) {
    final list = _foods[s]!;
    if (list.isEmpty) return;
    list.clear();
    _changed(s);
  }

  /// Marca o desmarca la toma como «No realizada». Al marcarla se quitan sus
  /// alimentos y su hora.
  void setSkipped(MealSlot s, bool skipped) {
    if (skipped == _skipped.contains(s)) return;
    if (skipped) {
      _skipped.add(s);
      _foods[s]!.clear();
      _times.remove(s);
    } else {
      _skipped.remove(s);
    }
    _dirty = true;
    notifyListeners();
  }

  /// Cambia la hora de una toma («HH:mm»; null la quita).
  void setTime(MealSlot s, String? time) {
    final clean = normalizeMealTime(time);
    if (clean == _times[s]) return;
    if (clean == null) {
      _times.remove(s);
    } else {
      _times[s] = clean;
    }
    _dirty = true;
    notifyListeners();
  }

  FoodDay toFoodDay() => FoodDay(
        date: _day,
        meals: {
          for (final s in MealSlot.values)
            s: MealLog(
              foods: [..._foods[s]!],
              skipped: _skipped.contains(s),
              time: _skipped.contains(s) ? null : _times[s],
            ),
        },
      );

  /// Tras guardar: ya no hay cambios pendientes.
  void markSaved() {
    _dirty = false;
    notifyListeners();
  }
}
