// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_screen.dart';
import 'state/app_controller.dart';

/// Aplicación HOPE.
class HopeApp extends StatelessWidget {
  const HopeApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: Builder(builder: (context) {
        final app = AppScope.of(context);
        return MaterialApp(
          title: 'HOPE',
          debugShowCheckedModeBanner: false,
          themeMode: app.themeMode,
          theme: buildHopeTheme(app, Brightness.light),
          darkTheme: buildHopeTheme(app, Brightness.dark),
          locale: Locale(app.language),
          supportedLocales: const [Locale('es'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const HomeScreen(),
        );
      }),
    );
  }
}

/// Tema visual: fondo cálido y acento azul pizarra. El rojo se reserva para
/// representar el dolor.
ThemeData buildHopeTheme(AppController app, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: app.config.accent,
    brightness: brightness,
  ).copyWith(
    surface: dark ? app.config.backgroundDark : app.config.backgroundLight,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.surface,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );
}
