// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/treatment.dart';
import '../utils/format.dart';
import 'aggregation.dart';
import 'chart_model.dart';
import 'params.dart';

/// Forma del marcador de cada parámetro.
enum MarkerShape { circle, square, triangle, diamond }

/// Cada parámetro se distingue por color, por estilo de línea y por marcador,
/// para que la gráfica se entienda también con daltonismo.
const Map<Param, MarkerShape> seriesMarker = {
  Param.pain: MarkerShape.circle,
  Param.surface: MarkerShape.square,
  Param.eventIntensity: MarkerShape.triangle,
  Param.eventFrequency: MarkerShape.diamond,
};

const Map<Param, List<double>> seriesDash = {
  Param.pain: <double>[],
  Param.surface: <double>[9, 5],
  Param.eventIntensity: <double>[2, 4],
  Param.eventFrequency: <double>[11, 4, 2, 4],
};

/// Colores y tamaños de la gráfica.
class ChartStyle {
  const ChartStyle({
    required this.background,
    required this.text,
    required this.subtleText,
    required this.grid,
    required this.cursor,
    required this.laneBackground,
    required this.series,
    required this.laneColors,
    this.fontSize = 12,
    this.fontFamily,
  });

  final Color background;
  final Color text;
  final Color subtleText;
  final Color grid;
  final Color cursor;
  final Color laneBackground;
  final Map<Param, Color> series;
  final List<Color> laneColors;
  final double fontSize;
  final String? fontFamily;

  Color laneColor(int k) => laneColors[k % laneColors.length];

  ChartStyle withFont(double size, {String? family}) => ChartStyle(
        background: background,
        text: text,
        subtleText: subtleText,
        grid: grid,
        cursor: cursor,
        laneBackground: laneBackground,
        series: series,
        laneColors: laneColors,
        fontSize: size,
        fontFamily: family ?? fontFamily,
      );

  /// El rojo se reserva para el dolor; el resto usa una paleta apta para
  /// daltonismo (Okabe-Ito).
  static ChartStyle of(Brightness b, {double fontSize = 12, String? fontFamily}) {
    final dark = b == Brightness.dark;
    return ChartStyle(
      background: dark ? const Color(0xFF121212) : const Color(0xFFFAF8F5),
      text: dark ? const Color(0xFFEDEAE6) : const Color(0xFF1A1A1A),
      subtleText: dark ? const Color(0xFFB3ADA6) : const Color(0xFF6B655F),
      grid: dark ? const Color(0xFF34312E) : const Color(0xFFE3DED8),
      cursor: dark ? const Color(0xFFEDEAE6) : const Color(0xFF3D5A80),
      laneBackground: dark ? const Color(0xFF1E1C1A) : const Color(0xFFF1EDE8),
      series: dark
          ? const {
              Param.pain: Color(0xFFFF6E6E),
              Param.surface: Color(0xFF56B4E9),
              Param.eventIntensity: Color(0xFFF0B33A),
              Param.eventFrequency: Color(0xFF3CC79F),
            }
          : const {
              Param.pain: Color(0xFFD50000),
              Param.surface: Color(0xFF0072B2),
              Param.eventIntensity: Color(0xFFD68A00),
              Param.eventFrequency: Color(0xFF009E73),
            },
      laneColors: dark
          ? const [Color(0xFF9D8DF1), Color(0xFF8FB3D9), Color(0xFFC9A27E), Color(0xFF7FC8BE)]
          : const [Color(0xFF5E548E), Color(0xFF3D5A80), Color(0xFF8A6A4F), Color(0xFF2A7F75)],
      fontSize: fontSize,
      fontFamily: fontFamily,
    );
  }
}

/// Máximo «redondo» del eje para valores reales.
double niceMax(double maxValue, double minimum) {
  final v = math.max(maxValue, minimum);
  for (final step in const <double>[5, 10, 20, 25, 30, 40, 50, 60, 80, 100, 150, 200, 250, 300, 400, 500]) {
    if (v <= step) return step;
  }
  return (v / 100).ceil() * 100.0;
}

/// Geometría de la gráfica, compartida por el dibujo y los toques.
class ChartLayout {
  ChartLayout(this.size, this.data, {required this.mode, required this.showLanes, this.fontSize = 12}) {
    laneHeight = math.max(20.0, fontSize * 1.9);
    lanesHeight = showLanes && data.lanes.isNotEmpty ? data.lanes.length * laneHeight + 6 : 0;
    final axisHeight = fontSize * 2.0;
    final left = fontSize * 4.2;
    plot = Rect.fromLTRB(
      left,
      fontSize * 0.9,
      math.max(left + 10, size.width - fontSize * 1.2),
      math.max(fontSize * 2, size.height - axisHeight - lanesHeight),
    );
    axisTop = plot.bottom + fontSize * 0.4;
    lanesTop = plot.bottom + axisHeight;
  }

  final Size size;
  final ChartData data;
  final ChartMode mode;
  final bool showLanes;
  final double fontSize;
  late final double laneHeight;
  late final double lanesHeight;
  late final Rect plot;
  late final double axisTop;
  late final double lanesTop;

  double xOf(double fraction) => plot.left + fraction * plot.width;

  double fractionOfX(double x) => ((x - plot.left) / plot.width).clamp(0.0, 1.0).toDouble();

  Rect laneRect(int k) => Rect.fromLTWH(plot.left, lanesTop + 3 + k * laneHeight, plot.width, laneHeight);

  /// Cuatro gráficas apiladas (vista por parámetro).
  List<Rect> get paramRects {
    final gap = fontSize * 0.9;
    final h = (plot.height - gap * 3) / 4;
    return [
      for (var k = 0; k < 4; k++) Rect.fromLTWH(plot.left, plot.top + k * (h + gap), plot.width, h)
    ];
  }

  /// Tratamiento que hay bajo un punto de la zona de franjas.
  Treatment? treatmentAt(Offset p) {
    if (!showLanes) return null;
    for (var k = 0; k < data.lanes.length; k++) {
      final lane = laneRect(k);
      if (p.dy < lane.top || p.dy > lane.bottom) continue;
      Treatment? best;
      var bestDist = double.infinity;
      for (final t in data.lanes[k].treatments) {
        final x0 = xOf(data.fractionOf(t.start));
        final x1 = xOf(data.fractionOf(t.lastMoment));
        final d = p.dx < x0 ? x0 - p.dx : (p.dx > x1 ? p.dx - x1 : 0.0);
        if (d < bestDist) {
          bestDist = d;
          best = t;
        }
      }
      if (best != null && bestDist <= math.max(18, fontSize * 1.6)) return best;
    }
    return null;
  }
}

TextStyle _ts(ChartStyle style, Color color, {double scale = 1, FontWeight? weight}) => TextStyle(
      color: color,
      fontSize: style.fontSize * scale,
      fontWeight: weight,
      fontFamily: style.fontFamily ?? 'Roboto',
      height: 1.15,
    );

/// Dibuja un texto. [anchor] indica qué punto del texto queda en [at]
/// (por ejemplo, Alignment.centerRight).
Size paintText(
  Canvas canvas,
  String text,
  Offset at,
  TextStyle style, {
  Alignment anchor = Alignment.topLeft,
  double? maxWidth,
}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: maxWidth == null ? null : 1,
    ellipsis: maxWidth == null ? null : '…',
  )..layout(maxWidth: maxWidth ?? double.infinity);
  final dx = at.dx - (anchor.x + 1) / 2 * tp.width;
  final dy = at.dy - (anchor.y + 1) / 2 * tp.height;
  tp.paint(canvas, Offset(dx, dy));
  final size = tp.size;
  tp.dispose();
  return size;
}

double measureText(String text, TextStyle style) {
  final tp = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)
    ..layout();
  final w = tp.width;
  tp.dispose();
  return w;
}

/// Dibuja un trazo discontinuo siguiendo [path].
void drawDashedPath(Canvas canvas, Path path, Paint paint, List<double> dash) {
  if (dash.isEmpty) {
    canvas.drawPath(path, paint);
    return;
  }
  for (final metric in path.computeMetrics()) {
    var distance = 0.0;
    var k = 0;
    var draw = true;
    while (distance < metric.length) {
      final len = dash[k % dash.length];
      if (draw) {
        canvas.drawPath(metric.extractPath(distance, math.min(distance + len, metric.length)), paint);
      }
      distance += len;
      draw = !draw;
      k++;
    }
  }
}

void drawMarker(Canvas canvas, MarkerShape shape, Offset c, double r, Paint fill, {Paint? stroke}) {
  final path = Path();
  switch (shape) {
    case MarkerShape.circle:
      path.addOval(Rect.fromCircle(center: c, radius: r));
    case MarkerShape.square:
      path.addRect(Rect.fromCircle(center: c, radius: r * 0.85));
    case MarkerShape.triangle:
      path
        ..moveTo(c.dx, c.dy - r * 1.1)
        ..lineTo(c.dx + r, c.dy + r * 0.75)
        ..lineTo(c.dx - r, c.dy + r * 0.75)
        ..close();
    case MarkerShape.diamond:
      path
        ..moveTo(c.dx, c.dy - r * 1.15)
        ..lineTo(c.dx + r, c.dy)
        ..lineTo(c.dx, c.dy + r * 1.15)
        ..lineTo(c.dx - r, c.dy)
        ..close();
  }
  canvas.drawPath(path, fill);
  if (stroke != null) canvas.drawPath(path, stroke);
}

/// Valor que se dibuja de un parámetro en un periodo, en 0–1 del eje.
double? _plotValue(ChartData data, int i, Param p, ChartMode mode, double realMax) {
  final mean = data.periods[i].stats[p]?.mean;
  if (mean == null) return null;
  if (mode == ChartMode.combined) return relativeValue(p, mean, data.scale);
  return (mean / realMax).clamp(0.0, 1.0).toDouble();
}

/// Máximo del eje real de un parámetro (vista por parámetro).
double realAxisMax(ChartData data, Param p) {
  if (p == Param.pain || p == Param.eventIntensity) return 10;
  var maxValue = 0.0;
  for (final i in data.dataIndices) {
    final st = data.periods[i].stats[p];
    if (st?.max != null) maxValue = math.max(maxValue, st!.max!);
  }
  return niceMax(maxValue, p == Param.surface ? 10 : 50);
}

String _axisLabel(Param p, double v, String lang) => switch (p) {
      Param.surface => formatPct(v, lang),
      Param.eventFrequency => '${v.round()}',
      _ => formatNumber(v, lang),
    };

/// Dibuja la gráfica completa (rejilla, series, eje de fechas, franjas de
/// tratamientos y cursor). La usan la pantalla y las exportaciones.
void paintChart(
  Canvas canvas,
  Size size, {
  required ChartData data,
  required ChartStyle style,
  required ChartMode mode,
  required Set<Param> enabled,
  required bool showLanes,
  required S s,
  required String lang,
  int? cursor,
  double? cursorFraction,
}) {
  final layout = ChartLayout(size, data, mode: mode, showLanes: showLanes, fontSize: style.fontSize);
  final plot = layout.plot;
  final gridPaint = Paint()
    ..color = style.grid
    ..strokeWidth = 1;
  final small = _ts(style, style.subtleText, scale: 0.9);

  // ---------------------------------------------------- rejilla y series
  final areas = <(Rect, List<Param>, double?)>[];
  if (mode == ChartMode.perParam) {
    final rects = layout.paramRects;
    for (var k = 0; k < Param.values.length; k++) {
      final p = Param.values[k];
      areas.add((rects[k], [p], realAxisMax(data, p)));
    }
  } else {
    areas.add((plot, [for (final p in Param.values) if (enabled.contains(p)) p], null));
  }

  for (final (rect, params, realMax) in areas) {
    final steps = realMax == null ? 4 : 2;
    for (var j = 0; j <= steps; j++) {
      final y = rect.bottom - rect.height * j / steps;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
    }
    if (realMax == null) {
      for (final j in const [0, 2, 4]) {
        final y = rect.bottom - rect.height * j / 4;
        paintText(canvas, formatPct(j * 25.0, lang), Offset(rect.left - 6, y), small,
            anchor: Alignment.centerRight);
      }
    } else {
      final p = params.single;
      paintText(canvas, _axisLabel(p, 0, lang), Offset(rect.left - 6, rect.bottom), small,
          anchor: Alignment.centerRight);
      paintText(canvas, _axisLabel(p, realMax, lang), Offset(rect.left - 6, rect.top), small,
          anchor: Alignment.centerRight);
      paintText(
        canvas,
        paramName(p, s),
        Offset(rect.left + 6, rect.top + 2),
        _ts(style, style.series[p]!, scale: 0.92, weight: FontWeight.w600),
      );
    }
  }

  // Líneas discontinuas de las administraciones puntuales.
  if (showLanes) {
    for (var k = 0; k < data.lanes.length; k++) {
      final color = style.laneColor(k);
      final paint = Paint()
        ..color = color.withValues(alpha: 0.55)
        ..strokeWidth = 1.2;
      for (final t in data.lanes[k].treatments) {
        if (!t.isPunctual) continue;
        final x = layout.xOf(data.fractionOf(t.start));
        final line = Path()
          ..moveTo(x, plot.top)
          ..lineTo(x, layout.lanesTop + 3 + k * layout.laneHeight + layout.laneHeight / 2);
        drawDashedPath(canvas, line, paint, const [4, 4]);
      }
    }
  }

  final markerR = math.max(2.6, style.fontSize * 0.28);
  for (final (rect, params, realMax) in areas) {
    if (mode == ChartMode.perParam && !enabled.contains(params.single)) continue;
    for (final p in params) {
      final color = style.series[p]!;
      final line = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = p == Param.pain ? 2.6 : 2.0
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      final path = Path();
      var open = false;
      final points = <Offset>[];
      for (var i = 0; i < data.periods.length; i++) {
        final v = _plotValue(data, i, p, mode, realMax ?? 1);
        if (v == null) {
          open = false;
          continue;
        }
        final pt = Offset(layout.xOf(data.fractionOfPeriod(i)), rect.bottom - v * rect.height);
        if (open) {
          path.lineTo(pt.dx, pt.dy);
        } else {
          path.moveTo(pt.dx, pt.dy);
          open = true;
        }
        points.add(pt);
      }
      drawDashedPath(canvas, path, line, seriesDash[p]!);
      if (points.length <= 120) {
        final fill = Paint()..color = color;
        final ring = Paint()
          ..color = style.background
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        for (final pt in points) {
          drawMarker(canvas, seriesMarker[p]!, pt, markerR, fill, stroke: ring);
        }
      }
    }
  }

  // -------------------------------------------------------- eje de fechas
  _paintTimeAxis(canvas, layout, data, style, lang);

  // ---------------------------------------------------------- tratamientos
  if (showLanes) {
    for (var k = 0; k < data.lanes.length; k++) {
      final lane = data.lanes[k];
      final rect = layout.laneRect(k);
      final color = style.laneColor(k);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(4)),
        Paint()..color = style.laneBackground,
      );
      for (final t in lane.treatments) {
        final x0 = layout.xOf(data.fractionOf(t.start));
        if (t.isPunctual) {
          drawMarker(canvas, MarkerShape.diamond, Offset(x0, rect.center.dy), rect.height * 0.28,
              Paint()..color = color);
        } else {
          final x1 = math.max(x0 + 3, layout.xOf(data.fractionOf(t.end!)));
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTRB(x0, rect.center.dy - rect.height * 0.22, x1, rect.center.dy + rect.height * 0.22),
              const Radius.circular(3),
            ),
            Paint()..color = color.withValues(alpha: 0.8),
          );
        }
      }
      paintText(
        canvas,
        lane.name,
        Offset(rect.left + 4, rect.center.dy),
        _ts(style, color, scale: 0.85, weight: FontWeight.w600),
        anchor: Alignment.centerLeft,
        maxWidth: rect.width * 0.4,
      );
    }
  }

  // ---------------------------------------------------------------- cursor
  final f = cursorFraction ?? (cursor == null ? null : data.fractionOfPeriod(cursor));
  if (f != null) {
    final x = layout.xOf(f);
    final cursorPaint = Paint()
      ..color = style.cursor
      ..strokeWidth = 1.6;
    canvas.drawLine(Offset(x, plot.top), Offset(x, layout.lanesTop + layout.lanesHeight), cursorPaint);
    final idx = cursor ?? data.nearestDataIndex(f);
    if (idx != null) {
      for (final (rect, params, realMax) in areas) {
        for (final p in params) {
          if (!enabled.contains(p)) continue;
          final v = _plotValue(data, idx, p, mode, realMax ?? 1);
          if (v == null) continue;
          final pt = Offset(layout.xOf(data.fractionOfPeriod(idx)), rect.bottom - v * rect.height);
          drawMarker(canvas, seriesMarker[p]!, pt, markerR * 1.8, Paint()..color = style.series[p]!,
              stroke: Paint()
                ..color = style.background
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2);
        }
      }
    }
  }
}

void _paintTimeAxis(Canvas canvas, ChartLayout layout, ChartData data, ChartStyle style, String lang) {
  final start = data.domainStart;
  final end = data.domainEnd;
  final days = end.difference(start).inHours / 24;
  final ticks = <DateTime>[];
  final bool monthly;
  if (days > 130 || data.grouping == Grouping.month) {
    monthly = true;
    var d = DateTime(start.year, start.month);
    if (d.isBefore(start)) d = DateTime(d.year, d.month + 1);
    while (!d.isAfter(end)) {
      ticks.add(d);
      d = DateTime(d.year, d.month + 1);
    }
  } else if (days > 16) {
    monthly = false;
    var d = DateTime(start.year, start.month, start.day + ((8 - start.weekday) % 7));
    while (d.isBefore(end)) {
      ticks.add(d);
      d = DateTime(d.year, d.month, d.day + 7);
    }
  } else {
    monthly = false;
    var d = start;
    while (d.isBefore(end)) {
      ticks.add(d);
      d = DateTime(d.year, d.month, d.day + 1);
    }
  }
  final textStyle = _ts(style, style.subtleText, scale: 0.88);
  final tickPaint = Paint()
    ..color = style.grid
    ..strokeWidth = 1;
  var lastRight = -double.infinity;
  for (final t in ticks) {
    final x = layout.xOf(data.fractionOf(t));
    final label = monthly ? formatShortMonth(t, lang) : formatShortDate(t, lang);
    final w = measureText(label, textStyle);
    final left = x - w / 2;
    canvas.drawLine(Offset(x, layout.plot.bottom), Offset(x, layout.plot.bottom + 4), tickPaint);
    if (left < lastRight + 8 || left < 0 || x + w / 2 > layout.size.width) continue;
    paintText(canvas, label, Offset(x, layout.axisTop), textStyle, anchor: Alignment.topCenter);
    lastRight = left + w;
  }
}

/// Muestra de la leyenda de un parámetro (línea con su marcador).
void paintLegendSample(Canvas canvas, Rect rect, Param p, ChartStyle style) {
  final color = style.series[p]!;
  final y = rect.center.dy;
  final line = Paint()
    ..color = color
    ..strokeWidth = p == Param.pain ? 2.6 : 2.0
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  drawDashedPath(canvas, Path()..moveTo(rect.left, y)..lineTo(rect.right, y), line, seriesDash[p]!);
  drawMarker(canvas, seriesMarker[p]!, Offset(rect.center.dx, y), math.min(rect.height * 0.32, 5),
      Paint()..color = color);
}

/// Pinta la muestra de la leyenda en un widget.
class LegendSample extends StatelessWidget {
  const LegendSample({super.key, required this.param, required this.style});

  final Param param;
  final ChartStyle style;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(28, 14),
        painter: _LegendPainter(param, style),
      );
}

class _LegendPainter extends CustomPainter {
  _LegendPainter(this.param, this.style);

  final Param param;
  final ChartStyle style;

  @override
  void paint(Canvas canvas, Size size) => paintLegendSample(canvas, Offset.zero & size, param, style);

  @override
  bool shouldRepaint(_LegendPainter old) => old.param != param || old.style != style;
}

/// Imagen de la gráfica para exportar (no se usa en pantalla).
typedef ChartImage = ui.Image;
