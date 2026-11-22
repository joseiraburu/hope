// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../charts/bowel_stats.dart';
import '../l10n/strings.dart';
import '../models/food.dart' show dayOf;
import '../state/app_controller.dart';
import '../utils/format.dart';
import 'bowel_style.dart';

/// Periodos que se pueden elegir en la gráfica de deposiciones, en días.
const List<int> bowelChartPeriods = [7, 14, 30, 90];

/// Gráficas de las deposiciones: la calidad de cada una (con la media del
/// día) y el número de deposiciones por día, o la misma información en una
/// tabla.
class BowelChartView extends StatefulWidget {
  const BowelChartView({super.key, this.now});

  /// «Hoy» (para las pruebas).
  final DateTime? now;

  @override
  State<BowelChartView> createState() => _BowelChartViewState();
}

class _BowelChartViewState extends State<BowelChartView> {
  int _days = 30;
  bool _table = false;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final lang = app.language;
    final theme = Theme.of(context);
    final today = dayOf(widget.now ?? DateTime.now());
    final from = DateTime(today.year, today.month, today.day - (_days - 1));
    final days = bowelDays(app.bowelEntries, from, today);
    final summary = BowelSummary.of(days);

    final controls = Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<int>(
            segments: [
              for (final d in bowelChartPeriods) ButtonSegment<int>(value: d, label: Text(s.days(d))),
            ],
            selected: {_days},
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            onSelectionChanged: (v) => setState(() => _days = v.first),
          ),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment<bool>(value: false, label: Text(s.viewChart)),
              ButtonSegment<bool>(value: true, label: Text(s.viewTable)),
            ],
            selected: {_table},
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            onSelectionChanged: (v) => setState(() => _table = v.first),
          ),
        ],
      ),
    );

    final summaryText = summary.total == 0
        ? s.bowelChartEmpty
        : s.bowelChartSummary(
            summary.total,
            summary.daysWith,
            summary.days,
            formatNumber(summary.perDay, lang),
            formatNumber(summary.mean!, lang),
          );

    final Widget body;
    if (summary.total == 0) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(s.bowelChartEmpty, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
        ),
      );
    } else if (_table) {
      body = _BowelTable(days: days.reversed.where((d) => d.count > 0).toList());
    } else {
      body = Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 12, 4),
        child: Semantics(
          label: s.bowelChartTitle,
          value: summaryText,
          child: CustomPaint(
            size: Size.infinite,
            painter: _BowelChartPainter(
              days: days,
              s: s,
              lang: lang,
              text: theme.colorScheme.onSurface,
              muted: theme.colorScheme.onSurfaceVariant,
              grid: theme.colorScheme.outlineVariant,
              accent: theme.colorScheme.primary,
              normalBand: bowelQualityColor(3).withValues(alpha: 0.12),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        controls,
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            '${formatDayRange(from, today, lang)} · $summaryText',
            style: theme.textTheme.bodySmall,
          ),
        ),
        Expanded(child: body),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            s.bowelScaleText,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// Dibuja arriba la calidad (1–5) de cada deposición y la media de cada día,
/// y abajo las barras con el número de deposiciones por día.
class _BowelChartPainter extends CustomPainter {
  _BowelChartPainter({
    required this.days,
    required this.s,
    required this.lang,
    required this.text,
    required this.muted,
    required this.grid,
    required this.accent,
    required this.normalBand,
  });

  final List<BowelDay> days;
  final S s;
  final String lang;
  final Color text;
  final Color muted;
  final Color grid;
  final Color accent;
  final Color normalBand;

  static const double _left = 34;
  static const double _bottomLabels = 22;
  static const double _gap = 26;
  static const double _titleH = 18;

  void _label(Canvas canvas, String value, Offset at, Color color,
      {double size = 11, TextAlign align = TextAlign.left, FontWeight weight = FontWeight.w400}) {
    final tp = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight, fontFamily: 'Roboto'),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();
    var dx = at.dx;
    if (align == TextAlign.center) dx -= tp.width / 2;
    if (align == TextAlign.right) dx -= tp.width;
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
    tp.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty || size.width < 80 || size.height < 120) return;
    final n = days.length;
    final plotW = size.width - _left;
    final step = plotW / n;
    double xOf(int i) => _left + step * (i + 0.5);

    final usable = size.height - _bottomLabels - _gap - 2 * _titleH;
    final qualityH = usable * 0.58;
    final countH = usable - qualityH;
    final qTop = _titleH;
    final qBottom = qTop + qualityH;
    final cTop = qBottom + _gap + _titleH;
    final cBottom = cTop + countH;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;

    // ---- Calidad (1–5).
    _label(canvas, s.bowelChartQuality, Offset(_left, qTop - _titleH / 2), text, size: 12, weight: FontWeight.w600);
    double yOfQ(double q) => qBottom - (q - 1) / 4 * qualityH;
    // Franja de la deposición normal (3).
    canvas.drawRect(
      Rect.fromLTRB(_left, yOfQ(3.5), size.width, yOfQ(2.5)),
      Paint()..color = normalBand,
    );
    for (var q = 1; q <= 5; q++) {
      final y = yOfQ(q.toDouble());
      canvas.drawLine(Offset(_left, y), Offset(size.width, y), gridPaint);
      _label(canvas, '$q', Offset(_left - 8, y), bowelQualityColor(q), align: TextAlign.right, weight: FontWeight.w700);
    }
    // Media del día: línea que no rellena los días sin deposiciones.
    final meanPaint = Paint()
      ..color = accent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    Offset? previous;
    for (var i = 0; i < n; i++) {
      final m = days[i].mean;
      if (m == null) {
        previous = null;
        continue;
      }
      final p = Offset(xOf(i), yOfQ(m));
      if (previous != null) canvas.drawLine(previous, p, meanPaint);
      previous = p;
    }
    // Cada deposición, en el color de su calidad.
    final r = math.max(2.5, math.min(6.0, step * 0.28));
    for (var i = 0; i < n; i++) {
      final entries = days[i].entries;
      for (var k = 0; k < entries.length; k++) {
        final q = entries[k].quality;
        // Varias el mismo día con la misma calidad: se separan un poco.
        final same = entries.where((e) => e.quality == q).toList();
        final idx = same.indexOf(entries[k]);
        final offset = (idx - (same.length - 1) / 2) * math.min(r * 1.6, step * 0.3);
        canvas.drawCircle(Offset(xOf(i) + offset, yOfQ(q.toDouble())), r, Paint()..color = bowelQualityColor(q));
      }
    }

    // ---- Número por día.
    _label(canvas, s.bowelChartCount, Offset(_left, cTop - _titleH / 2), text, size: 12, weight: FontWeight.w600);
    final maxCount = math.max(3, days.map((d) => d.count).fold<int>(0, math.max));
    double yOfC(int c) => cBottom - c / maxCount * countH;
    for (final c in {0, (maxCount / 2).round(), maxCount}) {
      final y = yOfC(c);
      canvas.drawLine(Offset(_left, y), Offset(size.width, y), gridPaint);
      _label(canvas, '$c', Offset(_left - 8, y), muted, align: TextAlign.right);
    }
    final barW = math.max(1.5, step * 0.6);
    for (var i = 0; i < n; i++) {
      final c = days[i].count;
      if (c == 0) continue;
      final m = days[i].mean ?? 3;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(xOf(i) - barW / 2, yOfC(c), xOf(i) + barW / 2, cBottom),
          const Radius.circular(2),
        ),
        Paint()..color = bowelQualityColor(m.round()).withValues(alpha: 0.85),
      );
    }

    // ---- Fechas.
    final labelEvery = math.max(1, (n / math.max(1, (plotW / 64).floor())).ceil());
    for (var i = 0; i < n; i += labelEvery) {
      _label(canvas, formatShortDate(days[i].day, lang), Offset(xOf(i), size.height - _bottomLabels / 2), muted,
          align: TextAlign.center, size: 10);
    }
  }

  @override
  bool shouldRepaint(_BowelChartPainter old) => true;
}

/// La misma información en una tabla (alternativa accesible).
class _BowelTable extends StatelessWidget {
  const _BowelTable({required this.days});

  final List<BowelDay> days;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final lang = app.language;
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 44,
            dataRowMinHeight: 40,
            dataRowMaxHeight: 72,
            columns: [
              DataColumn(label: Text(s.foodDay)),
              DataColumn(label: Text(s.bowelChartCountShort), numeric: true),
              DataColumn(label: Text(s.bowelChartMeanShort), numeric: true),
              DataColumn(label: Text(s.bowelChartEntries)),
            ],
            rows: [
              for (final d in days)
                DataRow(cells: [
                  DataCell(Text(formatDayLong(d.day, lang))),
                  DataCell(Text('${d.count}')),
                  DataCell(Text(d.mean == null ? '—' : formatNumber(d.mean!, lang))),
                  DataCell(Text(
                    d.entries.map((e) => '${formatTime(e.dateTime)} ${s.bowelQualityValue(e.quality)}').join('\n'),
                  )),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}
