// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../models/food.dart';
import '../screens/food_screen.dart';

/// Navegador de la app, para abrir pantallas desde fuera de ellas (al pulsar
/// un recordatorio).
final GlobalKey<NavigatorState> hopeNavigatorKey = GlobalKey<NavigatorState>();

/// Abre Alimentación en la toma de un recordatorio «Completa HOPE».
void openReminderMeal(MealSlot slot) {
  final nav = hopeNavigatorKey.currentState;
  if (nav == null) return;
  nav.push(MaterialPageRoute<void>(builder: (_) => FoodScreen(initialSlot: slot)));
}
