// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../animation/pain_scene.dart';
import '../charts/food_pain.dart';
import '../core/config.dart';
import '../models/food.dart';
import '../models/pain_record.dart';
import '../state/app_controller.dart';
import '../utils/format.dart';
import '../widgets/dialogs.dart';
import '../widgets/food_picker.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'record_player_screen.dart';

/// En una sola pantalla: lo que se comió el Día 1 y el dolor de fondo del
/// Día 1 y de los tres días siguientes.
class FoodPainScreen extends StatefulWidget {
  const FoodPainScreen({super.key, required this.date});

  /// Día de la comida (Día 1).
  final DateTime date;

  @override
  State<FoodPainScreen> createState() => _FoodPainScreenState();
}

class _FoodPainScreenState extends State<FoodPainScreen> {
  late DateTime _date = dayOf(widget.date);

  /// Días con comidas más cercanos: el anterior (más antiguo) y el siguiente.
  (FoodDay?, FoodDay?) _neighbours(List<FoodDay> days) {
    final key = dayKey(_date);
    FoodDay? older;
    FoodDay? newer;
    // [days] va del más reciente al más antiguo.
    for (final d in days) {
      final cmp = d.key.compareTo(key);
      if (cmp > 0) {
        newer = d;
      } else if (cmp < 0) {
        older ??= d;
      }
    }
    return (older, newer);
  }

  void _go(FoodDay? day) {
    if (day == null) return;
    setState(() => _date = day.date);
  }

  /// Abre un registro de dolor y atiende lo que se elija en él.
  Future<void> _openRecord(PainRecord record) async {
    final action = await Navigator.of(context).push<RecordAction>(
      MaterialPageRoute(
        builder: (_) => RecordPlayerScreen(recordId: record.id, allowDuplicate: false),
      ),
    );
    if (action == null || !mounted) return;
    final app = AppScope.read(context);
    final s = app.strings;
    final current = app.recordById(record.id) ?? record;
    switch (action) {
      case RecordAction.edit:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => HomeScreen(editing: current)),
        );
      case RecordAction.delete:
        final ok = await confirmAction(
          context,
          title: s.deleteRecordQuestion,
          message: formatDateTime(current.dateTime, app.language),
          confirmLabel: s.delete,
        );
        if (!ok) return;
        final removed = await app.deleteRecord(current.id);
        if (removed == null || !mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(s.recordDeleted),
            action: SnackBarAction(label: s.undo, onPressed: () => app.addRecord(removed)),
          ));
      case RecordAction.duplicate:
      case RecordAction.share:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final theme = Theme.of(context);
    final window = foodPainWindow(_date, app.records);
    final (older, newer) = _neighbours(app.foodDays);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.foodPainTitle),
        actions: [
          IconButton(
            tooltip: s.previousFoodDay,
            icon: const Icon(Icons.chevron_left),
            onPressed: older == null ? null : () => _go(older),
          ),
          IconButton(
            tooltip: s.nextFoodDay,
            icon: const Icon(Icons.chevron_right),
            onPressed: newer == null ? null : () => _go(newer),
          ),
        ],
      ),
      body: GestureDetector(
        // Deslizar hacia la derecha: día anterior; hacia la izquierda: siguiente.
        onHorizontalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0;
          if (v > 300) _go(older);
          if (v < -300) _go(newer);
        },
        // Pocas tarjetas: se construyen todas a la vez (no hace falta una
        // lista perezosa) y el lector de pantalla las recorre enteras.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FoodHeader(date: _date, foodDay: app.foodDayFor(_date)),
              const SizedBox(height: 12),
              _ChartCard(window: window),
              const SizedBox(height: 12),
              for (var i = 0; i < window.days.length; i++) ...[
                _PainDayCard(index: i, window: window, onOpenRecord: _openRecord),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(child: Text(s.foodPainDisclaimer, style: theme.textTheme.bodySmall)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cabecera: fecha del Día 1 y sus alimentos.
class _FoodHeader extends StatelessWidget {
  const _FoodHeader({required this.date, required this.foodDay});

  final DateTime date;
  final FoodDay? foodDay;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${s.dayN(1)} · ${formatDayLong(date, app.language)}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            for (final slot in MealSlot.values) ...[
              Row(
                children: [
                  Icon(mealSlotIcon(slot), size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(mealSlotName(app, slot), style: theme.textTheme.labelLarge),
                ],
              ),
              const SizedBox(height: 6),
              FoodChips(ids: foodDay?.slot(slot) ?? const [], dense: true),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

/// Gráfica de los cuatro días con su leyenda.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.window});

  final FoodPainWindow window;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final lang = app.language;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final days = window.days;
    final baseline = window.baseline;
    final labels = [
      for (var i = 0; i < days.length; i++) '${s.dayN(i + 1)}\n${formatShortDate(days[i].day, lang)}'
    ];
    String describe(PainDay d) {
      if (d.isFuture) return s.notAvailableYet;
      final mean = d.mean;
      if (mean == null) return s.noPainLogged;
      return s.chartValueSemantics(formatNumber(mean, lang), '${d.max}', d.count);
    }

    final semantics = [
      s.painChartTitle,
      for (var i = 0; i < days.length; i++)
        s.chartDaySemantics('${s.dayN(i + 1)}, ${formatDayLong(days[i].day, lang)}', describe(days[i])),
      if (baseline != null) s.baselineValue(formatNumber(baseline, lang)),
    ].join('. ');
    final fontScale = (MediaQuery.textScalerOf(context).scale(10) / 10).clamp(1.0, 1.4).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(s.painChartTitle, style: theme.textTheme.titleSmall),
            ),
            const SizedBox(height: 8),
            Semantics(
              container: true,
              label: semantics,
              child: ExcludeSemantics(
                child: SizedBox(
                  height: 190 + 30 * fontScale,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: FoodPainChartPainter(
                      window: window,
                      labels: labels,
                      meanLabels: [
                        for (final d in days) d.mean == null ? null : formatNumber(d.mean!, lang)
                      ],
                      config: app.config,
                      textColor: scheme.onSurface,
                      mutedColor: scheme.onSurfaceVariant,
                      gridColor: scheme.outlineVariant,
                      maxColor: scheme.onSurface,
                      baselineColor: scheme.primary,
                      fontScale: fontScale,
                      fontFamily: theme.textTheme.bodySmall?.fontFamily,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _LegendItem(
                  swatch: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: painColor(app.config, 6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  label: s.mean,
                ),
                _LegendItem(
                  swatch: Container(width: 18, height: 3, color: scheme.onSurface),
                  label: s.maximum,
                ),
                _LegendItem(
                  swatch: CustomPaint(
                    size: const Size(22, 3),
                    painter: _DashPainter(color: scheme.primary),
                  ),
                  label: s.baselineLabel,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              baseline == null ? s.noBaseline : s.baselineValue(formatNumber(baseline, lang)),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.swatch, required this.label});

  final Widget swatch;
  final String label;

  @override
  Widget build(BuildContext context) {
    // El texto puede pasar a otra línea (pantallas estrechas o letra grande).
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
      ],
    );
  }
}

/// Tarjeta de un día: resumen y registros de dolor.
class _PainDayCard extends StatelessWidget {
  const _PainDayCard({required this.index, required this.window, required this.onOpenRecord});

  final int index;
  final FoodPainWindow window;
  final ValueChanged<PainRecord> onOpenRecord;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final lang = app.language;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final day = window.days[index];
    // Las comidas del Día 1 ya están en la cabecera.
    final foodThatDay = index == 0 ? null : app.foodDayFor(day.day);

    final Widget body;
    final mean = day.mean;
    if (day.isFuture) {
      body = Text(s.notAvailableYet, style: muted);
    } else if (mean == null) {
      body = Text(s.noPainLogged, style: muted);
    } else {
      final delta = window.deltaFor(day);
      Widget? deltaRow;
      if (delta != null) {
        final signed = formatSigned(delta, lang);
        // Flecha como icono: las fuentes no siempre tienen «↑» y «↓».
        final icon = signed == '0'
            ? Icons.remove
            : (delta > 0 ? Icons.arrow_upward : Icons.arrow_downward);
        deltaRow = Row(
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Expanded(child: Text(s.vsBaseline(signed), style: theme.textTheme.bodySmall)),
          ],
        );
      }
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.painDayStats('${day.max}', formatNumber(mean, lang), day.count),
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (deltaRow != null) deltaRow,
          const SizedBox(height: 4),
          for (final r in day.records)
            ListTile(
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              leading: _PainBadge(value: r.painIntensity),
              title: Text(
                '${formatTime(r.dateTime)} · '
                '${s.painLine(r.painIntensity, r.zoneCount, formatPct(r.surfacePct, lang))}',
              ),
              subtitle: Text(
                r.note.isEmpty
                    ? s.eventsLine(r.eventIntensity, r.eventFrequency)
                    : '${s.eventsLine(r.eventIntensity, r.eventFrequency)}\n${r.note}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onOpenRecord(r),
            ),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  s.dayN(index + 1),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(formatDayLong(day.day, lang), style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
            const SizedBox(height: 6),
            body,
            if (foodThatDay != null)
              Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  leading: const Icon(Icons.restaurant, size: 20),
                  title: Text(s.foodsThatDay(foodThatDay.foods.length), style: theme.textTheme.bodyMedium),
                  children: [
                    for (final slot in MealSlot.values)
                      if (foodThatDay.slot(slot).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(mealSlotName(app, slot), style: theme.textTheme.labelMedium),
                              const SizedBox(height: 4),
                              FoodChips(ids: foodThatDay.slot(slot), dense: true),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Círculo con la intensidad del dolor de fondo, en su color.
class _PainBadge extends StatelessWidget {
  const _PainBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return CircleAvatar(
      radius: 16,
      backgroundColor: painColor(app.config, value),
      child: Text(
        '$value',
        style: TextStyle(
          color: value >= 5 ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Línea discontinua corta para la leyenda.
class _DashPainter extends CustomPainter {
  _DashPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height;
    final y = size.height / 2;
    drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), paint, dash: 6, gap: 4);
  }

  @override
  bool shouldRepaint(covariant _DashPainter oldDelegate) => oldDelegate.color != color;
}

/// Dibuja una línea discontinua de [a] a [b].
void drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint,
    {double dash = 6, double gap = 4}) {
  final total = (b - a).distance;
  if (total <= 0) return;
  final dir = (b - a) / total;
  var pos = 0.0;
  while (pos < total) {
    final end = math.min(pos + dash, total);
    canvas.drawLine(a + dir * pos, a + dir * end, paint);
    pos = end + gap;
  }
}

enum _Anchor { rightCenter, bottomCenter, topCenter }

/// Gráfica de barras de los días 1 a 4: la barra es la media del dolor de
/// fondo del día, la raya horizontal el máximo y la línea discontinua la
/// media de los 7 días anteriores. Un día sin registros es un hueco, nunca 0.
class FoodPainChartPainter extends CustomPainter {
  FoodPainChartPainter({
    required this.window,
    required this.labels,
    required this.meanLabels,
    required this.config,
    required this.textColor,
    required this.mutedColor,
    required this.gridColor,
    required this.maxColor,
    required this.baselineColor,
    this.fontScale = 1,
    this.fontFamily,
  });

  final FoodPainWindow window;
  final List<String> labels;
  final List<String?> meanLabels;
  final AppConfig config;
  final Color textColor;
  final Color mutedColor;
  final Color gridColor;
  final Color maxColor;
  final Color baselineColor;
  final double fontScale;

  /// Tipografía de la app (la misma que el resto de textos).
  final String? fontFamily;

  @override
  void paint(Canvas canvas, Size size) {
    final left = 24.0 * fontScale;
    const right = 8.0;
    final top = 20.0 * fontScale;
    final bottom = 12.0 + 28.0 * fontScale;
    final plot = Rect.fromLTRB(left, top, size.width - right, size.height - bottom);
    if (plot.width <= 0 || plot.height <= 0) return;
    double y(num v) => plot.bottom - plot.height * (v / 10);

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final v in const [0, 5, 10]) {
      canvas.drawLine(Offset(plot.left, y(v)), Offset(plot.right, y(v)), grid);
      _text(canvas, '$v', Offset(plot.left - 6, y(v)), mutedColor, 11, _Anchor.rightCenter);
    }

    final days = window.days;
    final column = plot.width / days.length;
    final barWidth = math.min(column * 0.42, 44.0);
    for (var i = 0; i < days.length; i++) {
      final d = days[i];
      final cx = plot.left + column * (i + 0.5);
      final mean = d.mean;
      final max = d.max;
      if (mean != null && max != null) {
        final bar = RRect.fromRectAndCorners(
          Rect.fromLTRB(cx - barWidth / 2, y(mean), cx + barWidth / 2, plot.bottom),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        );
        canvas.drawRRect(bar, Paint()..color = painColor(config, mean.round()));
        final maxPaint = Paint()
          ..color = maxColor
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(cx - barWidth / 2 - 4, y(max)),
          Offset(cx + barWidth / 2 + 4, y(max)),
          maxPaint,
        );
        final label = meanLabels[i];
        if (label != null) {
          _text(canvas, label, Offset(cx, y(max) - 5), textColor, 12, _Anchor.bottomCenter,
              bold: true);
        }
      } else {
        _text(canvas, '—', Offset(cx, plot.bottom - 3), mutedColor, 14, _Anchor.bottomCenter);
      }
      _text(canvas, labels[i], Offset(cx, plot.bottom + 5), d.isFuture ? mutedColor : textColor,
          11, _Anchor.topCenter);
    }

    final b = window.baseline;
    if (b != null) {
      final paint = Paint()
        ..color = baselineColor
        ..strokeWidth = 2;
      drawDashedLine(canvas, Offset(plot.left, y(b)), Offset(plot.right, y(b)), paint,
          dash: 8, gap: 5);
    }
  }

  void _text(Canvas canvas, String text, Offset anchor, Color color, double size, _Anchor at,
      {bool bold = false}) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontFamily: fontFamily ?? 'Roboto',
          fontSize: size * fontScale,
          height: 1.2,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = at == _Anchor.rightCenter ? anchor.dx - painter.width : anchor.dx - painter.width / 2;
    final dy = switch (at) {
      _Anchor.rightCenter => anchor.dy - painter.height / 2,
      _Anchor.bottomCenter => anchor.dy - painter.height,
      _Anchor.topCenter => anchor.dy,
    };
    painter.paint(canvas, Offset(dx, dy));
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant FoodPainChartPainter oldDelegate) => true;
}
