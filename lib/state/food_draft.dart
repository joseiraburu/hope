// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/foundation.dart';

import '../models/food.dart';

/// Comidas de un día mientras se editan en la pantalla Alimentación, antes
/// de guardarlas.
class FoodDraft extends ChangeNotifier {
  FoodDraft(DateTime day) : _day = dayOf(day);

  DateTime _day;
  List<String> _morning = [];
  List<String> _afternoon = [];
  bool _dirty = false;

  /// Día que se está editando (medianoche local).
  DateTime get day => _day;

  /// Hay cambios sin guardar.
  bool get dirty => _dirty;

  bool get isEmpty => _morning.isEmpty && _afternoon.isEmpty;

  List<String> slot(MealSlot s) =>
      List.unmodifiable(s == MealSlot.morning ? _morning : _afternoon);

  List<String> _list(MealSlot s) => s == MealSlot.morning ? _morning : _afternoon;

  /// Carga un día con lo que ya tenga guardado (o vacío).
  void load(DateTime day, FoodDay? saved) {
    _day = dayOf(day);
    _morning = [...?saved?.morning];
    _afternoon = [...?saved?.afternoon];
    _dirty = false;
    notifyListeners();
  }

  bool contains(MealSlot s, String id) => _list(s).contains(id);

  void toggle(MealSlot s, String id) {
    final list = _list(s);
    if (!list.remove(id)) list.add(id);
    _dirty = true;
    notifyListeners();
  }

  void add(MealSlot s, String id) {
    final list = _list(s);
    if (list.contains(id)) return;
    list.add(id);
    _dirty = true;
    notifyListeners();
  }

  void remove(MealSlot s, String id) {
    if (!_list(s).remove(id)) return;
    _dirty = true;
    notifyListeners();
  }

  void clear(MealSlot s) {
    final list = _list(s);
    if (list.isEmpty) return;
    list.clear();
    _dirty = true;
    notifyListeners();
  }

  FoodDay toFoodDay() => FoodDay(date: _day, morning: [..._morning], afternoon: [..._afternoon]);

  /// Tras guardar: ya no hay cambios pendientes.
  void markSaved() {
    _dirty = false;
    notifyListeners();
  }
}
