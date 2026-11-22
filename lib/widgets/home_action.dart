// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../state/app_controller.dart';

/// Vuelve a la pantalla de inicio (los cuadros).
///
/// Cierra las pantallas abiertas de una en una y se detiene en la primera
/// que tenga cambios sin guardar, para que esta pregunte si se descartan
/// (igual que al pulsar «Atrás»).
void goHome(BuildContext context) {
  final nav = Navigator.of(context);
  var blocked = false;
  nav.popUntil((route) {
    if (route.isFirst) return true;
    if (route.popDisposition == RoutePopDisposition.doNotPop) {
      blocked = true;
      return true;
    }
    return false;
  });
  if (blocked) nav.maybePop();
}

/// Botón «Inicio» para la barra superior de cada sección. No se muestra si
/// la pantalla ya es la primera.
class HomeAction extends StatelessWidget {
  const HomeAction({super.key});

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route == null || route.isFirst) return const SizedBox.shrink();
    final s = AppScope.of(context).strings;
    return IconButton(
      tooltip: s.home,
      icon: const Icon(Icons.home_outlined),
      onPressed: () => goHome(context),
    );
  }
}
