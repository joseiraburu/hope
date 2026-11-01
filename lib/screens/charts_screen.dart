// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../charts/aggregation.dart';
import '../charts/chart_model.dart';
import '../charts/chart_painter.dart';
import '../charts/params.dart';
import '../core/body_geometry.dart';
import '../core/config.dart';
import '../core/frequency_scale.dart';
import '../export/chart_export.dart';
import '../export/share_service.dart';
import '../l10n/strings.dart';
import '../models/treatment.dart';
import '../state/app_controller.dart';
import '../state/pain_state.dart';
import '../utils/format.dart';
import '../widgets/body_figure.dart';
import '../widgets/compare_sheet.dart';
import 'treatment_editor_screen.dart';

enum _ExportKind { png, gif, xlsx, pdf }

/// Gráfica de evolución con cursor, agrupación y tratamientos.
class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  ChartRange _range = ChartRange.d30;
  DateTime? _customFrom;
  DateTime? _customTo;
  Grouping _grouping = Grouping.day;
  ChartMode _mode = ChartMode.combined;
  final Set<Param> _enabled = Param.values.toSet();
  bool _showTreatments = true;
  int? _cursor;
  Timer? _player;
  final FocusNode _chartFocus = FocusNode(debugLabel: 'grafica');

  @override
  void dispose() {
    _player?.cancel();
    _chartFocus.dispose();
    super.dispose();
  }

  static Grouping _defaultGrouping(ChartRange r) => switch (r) {
        ChartRange.d7 || ChartRange.d30 => Grouping.day,
        ChartRange.m3 || ChartRange.m6 => Grouping.week,
        _ => Grouping.month,
      };

  ChartData _buildData(AppController app) {
    DateTime? earliest;
    for (final r in app.records) {
      if (earliest == null || r.dateTime.isBefore(earliest)) earliest = r.dateTime;
    }
    final dates = rangeDates(
      _range,
      DateTime.now(),
      earliest: earliest,
      customFrom: _customFrom,
      customTo: _customTo,
    );
    return buildChartData(
      records: app.records,
      treatments: app.treatments,
      from: dates.from,
      to: dates.to,
      grouping: _grouping,
      scale: FrequencyScale(app.config.freqMin, app.config.freqMax),
      medicationName: app.treatmentMedicationName,
    );
  }

  int? _validCursor(ChartData data) {
    final c = _cursor;
    if (c != null && c < data.periods.length && data.periods[c].hasData) return c;
    return data.isEmpty ? null : data.dataIndices.last;
  }

  Future<void> _setRange(ChartRange r) async {
    if (r == ChartRange.custom) {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(now.year, now.month, now.day),
        initialDateRange: _customFrom == null || _customTo == null
            ? null
            : DateTimeRange(start: _customFrom!, end: _customTo!),
      );
      if (picked == null || !mounted) return;
      setState(() {
        _customFrom = picked.start;
        _customTo = picked.end;
        _range = r;
        _cursor = null;
        final days = picked.end.difference(picked.start).inDays;
        _grouping = days <= 45 ? Grouping.day : (days <= 200 ? Grouping.week : Grouping.month);
      });
      return;
    }
    setState(() {
      _range = r;
      _cursor = null;
      _grouping = _defaultGrouping(r);
    });
  }

  void _togglePlay(ChartData data) {
    if (_player != null) {
      _stop();
      return;
    }
    if (data.isEmpty) return;
    final indices = data.dataIndices;
    var k = 0;
    final stepMs = (8000 / indices.length).clamp(120, 700).round();
    setState(() => _cursor = indices.first);
    _player = Timer.periodic(Duration(milliseconds: stepMs), (t) {
      k++;
      if (!mounted || k >= indices.length) {
        _stop();
        return;
      }
      setState(() => _cursor = indices[k]);
    });
  }

  void _stop() {
    _player?.cancel();
    _player = null;
    if (mounted) setState(() {});
  }

  void _moveCursor(ChartData data, int delta) {
    if (data.isEmpty) return;
    final indices = data.dataIndices;
    final current = _validCursor(data);
    var pos = current == null ? indices.length - 1 : indices.indexOf(current);
    pos = (pos + delta).clamp(0, indices.length - 1);
    setState(() => _cursor = indices[pos]);
  }

  Future<void> _export(_ExportKind kind, ChartData data) async {
    final app = AppScope.read(context);
    final s = app.strings;
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.noDataInRange)));
      return;
    }
    if (!await confirmHealthDataShare(context)) return;
    if (!mounted) return;
    _stop();
    final input = ChartExportInput(
      data: data,
      mode: _mode,
      enabled: Set.of(_enabled),
      showLanes: _showTreatments,
      s: s,
      lang: app.language,
      config: app.config,
      medicationName: app.treatmentMedicationName,
    );
    final progress = ExportProgress()..show(context, cancellable: kind == _ExportKind.gif);
    try {
      final Uint8List? bytes;
      final String ext;
      final String mime;
      switch (kind) {
        case _ExportKind.png:
          bytes = await chartPng(input);
          ext = 'png';
          mime = 'image/png';
        case _ExportKind.gif:
          bytes = await chartGif(input, onProgress: progress.set, isCancelled: () => progress.cancelled);
          ext = 'gif';
          mime = 'image/gif';
        case _ExportKind.xlsx:
          bytes = chartXlsx(input);
          ext = 'xlsx';
          mime = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        case _ExportKind.pdf:
          bytes = await chartPdf(input);
          ext = 'pdf';
          mime = 'application/pdf';
      }
      final cancelled = progress.cancelled;
      progress.close();
      if (cancelled || bytes == null || !mounted) return;
      final file = await writeExportFile('${input.baseName}.$ext', bytes);
      if (!mounted) return;
      await deliverFile(context, file, mimeType: mime, subject: 'HOPE · ${s.chartTitle}');
    } catch (_) {
      progress.close();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.exportFailed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final lang = app.language;
    final theme = Theme.of(context);
    final data = _buildData(app);
    final cursor = _validCursor(data);
    final style = ChartStyle.of(theme.brightness, fontSize: 12);

    String rangeName(ChartRange r) => switch (r) {
          ChartRange.d7 => s.range7d,
          ChartRange.d30 => s.range30d,
          ChartRange.m3 => s.range3m,
          ChartRange.m6 => s.range6m,
          ChartRange.y1 => s.range1y,
          ChartRange.all => s.rangeAll,
          ChartRange.custom => s.rangeCustom,
        };

    return Scaffold(
      appBar: AppBar(
        title: Text(s.charts),
        actions: [
          IconButton(
            tooltip: s.addTreatment,
            icon: const Icon(Icons.medication_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TreatmentEditorScreen()),
            ),
          ),
          PopupMenuButton<_ExportKind>(
            tooltip: s.export,
            icon: const Icon(Icons.ios_share),
            onSelected: (k) => _export(k, data),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _ExportKind.png,
                child: ListTile(leading: const Icon(Icons.image_outlined), title: Text(s.exportPng)),
              ),
              PopupMenuItem(
                value: _ExportKind.gif,
                child: ListTile(leading: const Icon(Icons.gif_box_outlined), title: Text(s.exportGif)),
              ),
              PopupMenuItem(
                value: _ExportKind.xlsx,
                child: ListTile(leading: const Icon(Icons.table_chart_outlined), title: Text(s.exportExcel)),
              ),
              PopupMenuItem(
                value: _ExportKind.pdf,
                child: ListTile(leading: const Icon(Icons.picture_as_pdf_outlined), title: Text(s.exportPdf)),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final controls = _Controls(
            rangeLabel: rangeName(_range),
            rangeText: formatDayRange(data.from, data.to, lang),
            ranges: {for (final r in ChartRange.values) r: rangeName(r)},
            onRange: _setRange,
            grouping: _grouping,
            onGrouping: (g) => setState(() {
              _grouping = g;
              _cursor = null;
            }),
            mode: _mode,
            onMode: (m) => setState(() => _mode = m),
            enabled: _enabled,
            onToggleParam: (p) => setState(() {
              if (!_enabled.remove(p)) _enabled.add(p);
            }),
            showTreatments: _showTreatments,
            onShowTreatments: (v) => setState(() => _showTreatments = v),
            style: style,
          );
          final Widget body;
          if (data.isEmpty) {
            body = Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(s.noDataInRange, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
              ),
            );
          } else if (_mode == ChartMode.table) {
            body = _ChartTable(data: data);
          } else {
            body = _chartArea(context, data, cursor, style);
          }
          final panel = data.isEmpty || _mode == ChartMode.table
              ? null
              : _CursorPanel(
                  data: data,
                  index: cursor,
                  enabled: _enabled,
                  playing: _player != null,
                  onPlay: () => _togglePlay(data),
                );
          final notes = Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              _mode == ChartMode.combined ? '${s.relativeScaleNote} ${s.causalDisclaimer}' : s.causalDisclaimer,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          );
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 340, child: SingleChildScrollView(child: controls)),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: body),
                      if (panel != null) panel,
                      notes,
                    ],
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              controls,
              Expanded(child: body),
              if (panel != null) panel,
              notes,
            ],
          );
        }),
      ),
    );
  }

  String _describe(ChartData data, int? i, S s, String lang) => i == null
      ? ''
      : '${data.periodLabel(i, s, lang)}. ${periodValuesText(data, i, s, lang, _enabled)}';

  int? _neighbour(ChartData data, int? i, int delta) {
    if (i == null) return null;
    final indices = data.dataIndices;
    final pos = indices.indexOf(i) + delta;
    return pos < 0 || pos >= indices.length ? i : indices[pos];
  }

  Widget _chartArea(BuildContext context, ChartData data, int? cursor, ChartStyle style) {
    final app = AppScope.of(context);
    final s = app.strings;
    final lang = app.language;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 4),
      child: LayoutBuilder(builder: (context, c) {
        final size = c.biggest;
        final layout = ChartLayout(size, data,
            mode: _mode, showLanes: _showTreatments, fontSize: style.fontSize);
        void pick(Offset p) {
          final idx = data.nearestDataIndex(layout.fractionOfX(p.dx));
          if (idx != null && idx != _cursor) setState(() => _cursor = idx);
        }

        return Focus(
          focusNode: _chartFocus,
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _moveCursor(data, -1);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _moveCursor(data, 1);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.space) {
              _togglePlay(data);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Semantics(
            label: s.chartTitle,
            value: _describe(data, cursor, s, lang),
            increasedValue: _describe(data, _neighbour(data, cursor, 1), s, lang),
            decreasedValue: _describe(data, _neighbour(data, cursor, -1), s, lang),
            onIncrease: () => _moveCursor(data, 1),
            onDecrease: () => _moveCursor(data, -1),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                _chartFocus.requestFocus();
                final t = layout.treatmentAt(d.localPosition);
                if (t != null) {
                  showCompareSheet(context, t);
                  return;
                }
                _stop();
                pick(d.localPosition);
              },
              onHorizontalDragStart: (d) {
                _stop();
                pick(d.localPosition);
              },
              onHorizontalDragUpdate: (d) => pick(d.localPosition),
              child: CustomPaint(
                size: size,
                painter: _ChartPainter(
                  data: data,
                  style: style,
                  mode: _mode,
                  enabled: Set.of(_enabled),
                  showLanes: _showTreatments,
                  cursor: cursor,
                  s: s,
                  lang: lang,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.data,
    required this.style,
    required this.mode,
    required this.enabled,
    required this.showLanes,
    required this.cursor,
    required this.s,
    required this.lang,
  });

  final ChartData data;
  final ChartStyle style;
  final ChartMode mode;
  final Set<Param> enabled;
  final bool showLanes;
  final int? cursor;
  final S s;
  final String lang;

  @override
  void paint(Canvas canvas, Size size) => paintChart(
        canvas,
        size,
        data: data,
        style: style,
        mode: mode,
        enabled: enabled,
        showLanes: showLanes,
        s: s,
        lang: lang,
        cursor: cursor,
      );

  @override
  bool shouldRepaint(_ChartPainter old) => true;
}

/// Controles: fechas, agrupación, vista, parámetros y tratamientos.
class _Controls extends StatelessWidget {
  const _Controls({
    required this.rangeLabel,
    required this.rangeText,
    required this.ranges,
    required this.onRange,
    required this.grouping,
    required this.onGrouping,
    required this.mode,
    required this.onMode,
    required this.enabled,
    required this.onToggleParam,
    required this.showTreatments,
    required this.onShowTreatments,
    required this.style,
  });

  final String rangeLabel;
  final String rangeText;
  final Map<ChartRange, String> ranges;
  final ValueChanged<ChartRange> onRange;
  final Grouping grouping;
  final ValueChanged<Grouping> onGrouping;
  final ChartMode mode;
  final ValueChanged<ChartMode> onMode;
  final Set<Param> enabled;
  final ValueChanged<Param> onToggleParam;
  final bool showTreatments;
  final ValueChanged<bool> onShowTreatments;
  final ChartStyle style;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).strings;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PopupMenuButton<ChartRange>(
                tooltip: s.dateRange,
                onSelected: onRange,
                itemBuilder: (_) => [
                  for (final e in ranges.entries) PopupMenuItem(value: e.key, child: Text(e.value)),
                ],
                child: Chip(
                  avatar: const Icon(Icons.date_range, size: 18),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Text(rangeLabel), const Icon(Icons.arrow_drop_down, size: 20)],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(rangeText,
                    style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<Grouping>(
                segments: [
                  ButtonSegment(value: Grouping.day, label: Text(s.byDay)),
                  ButtonSegment(value: Grouping.week, label: Text(s.byWeek)),
                  ButtonSegment(value: Grouping.month, label: Text(s.byMonth)),
                ],
                selected: {grouping},
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                onSelectionChanged: (v) => onGrouping(v.first),
              ),
              SegmentedButton<ChartMode>(
                segments: [
                  ButtonSegment(value: ChartMode.combined, label: Text(s.viewCombined)),
                  ButtonSegment(value: ChartMode.perParam, label: Text(s.viewPerParam)),
                  ButtonSegment(value: ChartMode.table, label: Text(s.viewTable)),
                ],
                selected: {mode},
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                onSelectionChanged: (v) => onMode(v.first),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final p in Param.values)
                FilterChip(
                  avatar: LegendSample(param: p, style: style),
                  label: Text(paramName(p, s)),
                  selected: enabled.contains(p),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => onToggleParam(p),
                ),
              FilterChip(
                avatar: const Icon(Icons.medication_outlined, size: 18),
                label: Text(s.showTreatments),
                selected: showTreatments,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                onSelected: onShowTreatments,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Valores del periodo bajo el cursor, con la minisilueta del registro.
class _CursorPanel extends StatelessWidget {
  const _CursorPanel({
    required this.data,
    required this.index,
    required this.enabled,
    required this.playing,
    required this.onPlay,
  });

  final ChartData data;
  final int? index;
  final Set<Param> enabled;
  final bool playing;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final lang = app.language;
    final theme = Theme.of(context);
    final i = index;
    final style = ChartStyle.of(theme.brightness);
    final period = i == null ? null : data.periods[i];
    final record = period?.latest;
    final List<Treatment> active = i == null ? const [] : data.treatmentsIn(i);
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (record != null)
              SizedBox(
                width: 44,
                height: 112,
                child: BodyFigure(
                  scene: sceneForRecord(app.config, record),
                  sex: sexFromString(record.sex),
                  view: BodyView.front,
                  showSideLetters: false,
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (i != null) ...[
                      Text(data.periodLabel(i, s, lang), style: theme.textTheme.titleSmall),
                      Text(s.nRecords(period!.count), style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      for (final p in Param.values)
                        if (enabled.contains(p))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              children: [
                                LegendSample(param: p, style: style),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _valueText(p, period, s, lang),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      if (active.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '${s.activeTreatments}: ${active.map(app.treatmentMedicationName).toSet().join(', ')}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: playing ? s.pause : s.play,
              icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              onPressed: onPlay,
            ),
          ],
        ),
      ),
    );
  }

  static String _valueText(Param p, Period period, S s, String lang) {
    final st = period.stats[p];
    final name = paramName(p, s);
    if (st == null || st.mean == null) return '$name: —';
    final mean = formatParam(p, st.mean!, lang);
    if (st.n > 1 && st.min != st.max) {
      return '$name: $mean (${formatParam(p, st.min!, lang)} – ${formatParam(p, st.max!, lang)})';
    }
    return '$name: $mean';
  }
}

/// Vista de tabla (alternativa accesible a la gráfica).
class _ChartTable extends StatelessWidget {
  const _ChartTable({required this.data});

  final ChartData data;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final lang = app.language;
    final rows = [for (final i in data.dataIndices) i];
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 44,
            dataRowMinHeight: 40,
            dataRowMaxHeight: 56,
            columns: [
              DataColumn(label: Text(s.period)),
              DataColumn(label: Text(s.records), numeric: true),
              for (final p in Param.values) DataColumn(label: Text(paramName(p, s)), numeric: true),
              DataColumn(label: Text(s.activeTreatments)),
            ],
            rows: [
              for (final i in rows)
                DataRow(cells: [
                  DataCell(Text(data.periodLabel(i, s, lang))),
                  DataCell(Text('${data.periods[i].count}')),
                  for (final p in Param.values)
                    DataCell(Text(data.periods[i].stats[p]?.mean == null
                        ? '—'
                        : formatParam(p, data.periods[i].stats[p]!.mean!, lang))),
                  DataCell(Text(data.treatmentsIn(i).map(app.treatmentMedicationName).toSet().join(', '))),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}
