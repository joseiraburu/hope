// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/food.dart' show dayOf;
import '../models/pain_record.dart';
import '../state/app_controller.dart';
import '../widgets/logo.dart';
import '../widgets/welcome.dart';
import 'bowel_screen.dart';
import 'charts_screen.dart';
import 'data_screen.dart';
import 'food_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import 'sleep_screen.dart';
import 'treatments_screen.dart';

/// Los cuadros de la pantalla de inicio, en orden (de izquierda a derecha
/// y de arriba abajo).
enum StartTile { pain, food, sleep, bowel, medication, history, report, charts, data }

/// Pantalla de inicio: nueve cuadros que ocupan toda la pantalla, en una
/// cuadrícula de 3 × 3, y que abren cada sección.
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool _welcomeShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.read(context);
    if (!_welcomeShown && !app.settings.firstRunDone) {
      _welcomeShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showWelcome(context);
      });
    }
  }

  Future<void> _push(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

  /// El Historial devuelve un registro si se elige «Usar como punto de
  /// partida»: se abre Dolor con ese registro cargado.
  Future<void> _openHistory() async {
    final chosen = await Navigator.of(context).push<PainRecord>(
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
    if (chosen == null || !mounted) return;
    await _push(HomeScreen(startFrom: chosen));
  }

  void _open(StartTile tile) {
    switch (tile) {
      case StartTile.pain:
        _push(const HomeScreen());
      case StartTile.food:
        _push(const FoodScreen());
      case StartTile.sleep:
        _push(const SleepScreen());
      case StartTile.bowel:
        _push(const BowelScreen());
      case StartTile.medication:
        _push(const TreatmentsScreen());
      case StartTile.history:
        _openHistory();
      case StartTile.report:
        _push(const ReportScreen());
      case StartTile.charts:
        _push(const ChartsScreen());
      case StartTile.data:
        _push(const DataScreen());
    }
  }

  static IconData _icon(StartTile tile) => switch (tile) {
        StartTile.pain => Icons.accessibility_new,
        StartTile.food => Icons.restaurant,
        StartTile.sleep => Icons.bedtime_outlined,
        StartTile.bowel => Icons.wc,
        StartTile.medication => Icons.medication_outlined,
        StartTile.history => Icons.history,
        StartTile.report => Icons.summarize_outlined,
        StartTile.charts => Icons.show_chart,
        StartTile.data => Icons.import_export,
      };

  static String _key(StartTile tile) => switch (tile) {
        StartTile.pain => 'tile-pain',
        StartTile.food => 'tile-food',
        StartTile.sleep => 'tile-sleep',
        StartTile.bowel => 'tile-bowel',
        StartTile.medication => 'tile-medication',
        StartTile.history => 'tile-history',
        StartTile.report => 'tile-report',
        StartTile.charts => 'tile-charts',
        StartTile.data => 'tile-data',
      };

  String _label(AppController app, StartTile tile) {
    final s = app.strings;
    return switch (tile) {
      StartTile.pain => s.tilePain,
      StartTile.food => s.food,
      StartTile.sleep => s.sleep,
      StartTile.bowel => s.bowel,
      StartTile.medication => s.tileMedication,
      StartTile.history => s.history,
      StartTile.report => s.tileReport,
      StartTile.charts => s.charts,
      StartTile.data => s.tileData,
    };
  }

  /// Línea de estado de cada cuadro (lo registrado hoy, lo activo...).
  String _status(AppController app, StartTile tile) {
    final s = app.strings;
    final now = DateTime.now();
    final today = dayOf(now);
    return switch (tile) {
      StartTile.pain => s.tilePainStatus(app.recordsOn(today).length),
      StartTile.food => s.tileFoodStatus(_mealsLogged(app, today)),
      StartTile.sleep => s.tileSleepStatus(app.sleepFor(today)?.quality),
      StartTile.bowel => s.tileBowelStatus(app.bowelOn(today).length),
      StartTile.medication => s.tileMedicationStatus(_ongoingTreatments(app, now)),
      StartTile.history =>
        s.nRecords(app.records.length + app.bowelEntries.length + app.sleepEntries.length),
      StartTile.report => s.tileReportStatus,
      StartTile.charts => s.tileChartsStatus,
      StartTile.data => s.tileDataStatus,
    };
  }

  /// Tomas de hoy con algo registrado (alimentos o «No realizada»).
  static int _mealsLogged(AppController app, DateTime today) {
    final day = app.foodDayFor(today);
    return day == null ? 0 : day.eatenSlots.length + day.skippedSlots.length;
  }

  /// Tratamientos con periodo que están en curso ahora.
  static int _ongoingTreatments(AppController app, DateTime now) {
    final soon = now.add(const Duration(minutes: 1));
    return app.treatments.where((t) => !t.isPunctual && t.overlaps(now, soon)).length;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final theme = Theme.of(context);
    final tiles = StartTile.values;

    // Teclado (Windows): del 1 al 9, un cuadro cada número.
    const digits = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ];

    return Scaffold(
      body: SafeArea(
        child: CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            for (var i = 0; i < tiles.length; i++) SingleActivator(digits[i]): () => _open(tiles[i]),
          },
          child: Focus(
            autofocus: true,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 4, 0),
                  child: Row(
                    children: [
                      const HopeLogo(size: 30),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'HOPE',
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: s.settings,
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () => _push(const SettingsScreen()),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var row = 0; row < 3; row++) ...[
                          if (row > 0) const SizedBox(height: 8),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (var col = 0; col < 3; col++) ...[
                                  if (col > 0) const SizedBox(width: 8),
                                  Expanded(
                                    child: _Tile(
                                      key: ValueKey(_key(tiles[row * 3 + col])),
                                      icon: _icon(tiles[row * 3 + col]),
                                      label: _label(app, tiles[row * 3 + col]),
                                      status: _status(app, tiles[row * 3 + col]),
                                      primary: tiles[row * 3 + col] == StartTile.pain,
                                      onTap: () => _open(tiles[row * 3 + col]),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Un cuadro de la pantalla de inicio. El icono y el texto se adaptan al
/// tamaño del cuadro; la línea de estado solo se muestra si cabe.
class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.icon,
    required this.label,
    required this.status,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final String status;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = primary ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = primary ? scheme.onPrimary : scheme.onSurface;
    return Semantics(
      button: true,
      label: '$label. $status',
      excludeSemantics: true,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: LayoutBuilder(builder: (context, c) {
            final shortest = c.biggest.shortestSide;
            final iconSize = (shortest * 0.34).clamp(22.0, 64.0).toDouble();
            final showStatus = c.maxHeight >= 120 && c.maxWidth >= 90;
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: iconSize, color: fg),
                  SizedBox(height: shortest < 90 ? 2 : 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (showStatus) ...[
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        status,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: fg.withValues(alpha: 0.8)),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
